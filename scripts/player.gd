extends CharacterBody3D

# --- 变量区 ---
# ⚠️ 确保你的场景里真的有一个子节点叫 AnimationPlayer
@onready var nav_agent = $NavigationAgent3D
@onready var camera = get_viewport().get_camera_3d()
@onready var anim_player = $Mage/AnimationPlayer
@onready var muzzle = $Muzzle
@onready var body_mesh = $Mage/Rig/Skeleton3D/Mage_Body # ⚠️修改：请把你主角模型的名字填在这里，用来做受伤变红闪烁

const SPEED = 5.0
# 预加载子弹场景
var bullet_scene = preload("res://scenes/MagicMissile.tscn")
var is_attacking = false # <--- 1. 新增这个变量

var max_hp = 5 # 只有3滴血，硬核一点
var current_hp = 3
var is_invincible = false # 无敌时间（防止一秒钟被咬死）

signal hp_changed(val) # 新增信号，通知UI

# --- 1. 这里是你漏掉的关键部分：初始化 ---
func _ready():
	current_hp = max_hp
	hp_changed.emit(current_hp) # 初始化时更新UI
	print("我的动画列表: ", anim_player.get_animation_list())
	
	# --- 🛡️ 关键保护代码：让这个主角的材质独立出来 ---
	if body_mesh:
		# 获取原本的材质
		var source_mat = body_mesh.get_active_material(0)
		if source_mat:
			# 复制一份新的，专门给这个主角用，随便怎么变色都不会影响源文件
			var unique_mat = source_mat.duplicate()
			body_mesh.set_surface_override_material(0, unique_mat)

func _physics_process(delta):
	# 检测鼠标输入
	if Input.is_action_pressed("move_to"):
		update_target_location()
	if Input.is_action_just_pressed("attack"): # 记得去项目设置里绑定 attack 键
		shoot()	
	# 导航逻辑
	if not nav_agent.is_navigation_finished():
		var current_location = global_position
		var next_location = nav_agent.get_next_path_position()
		var direction = (next_location - current_location).normalized()
		
		velocity = direction * SPEED
		
		# 平滑旋转
		if direction.length() > 0.1:
			var target_angle = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_angle, 10 * delta)
		
		move_and_slide()
		
		if not is_attacking:
		# --- 2. 这里是你漏掉的关键部分：播放动画 (走路) ---
		# 如果正在移动，且还没开始播 walk，就播 walk
			if anim_player.current_animation != "Running_A":
				anim_player.play("Running_A")
			
	else:
		# 到了或者没目标，停下来
		velocity = Vector3.ZERO
		
		if not is_attacking:
		# --- 3. 这里是你漏掉的关键部分：播放动画 (站立) ---
		# 如果停下了，且还没开始播 idle，就播 idle
			if anim_player.current_animation != "Idle":
				anim_player.play("Idle")

# --- 核心函数：把鼠标点击转换成 3D 坐标 ---
func update_target_location():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 1000
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(ray_query)
	
	if result:
		nav_agent.target_position = result.position
# 2. 修改：发射函数
func shoot():
	if is_attacking: return
	# --- 新增：先尝试自动瞄准 ---
	var target = get_nearest_enemy()
	
	if target:
		# 如果有敌人，就转身面向敌人
		look_at(target.global_position, Vector3.UP)
		# 修正一下 X 轴，防止主角像迈克尔杰克逊一样倾斜
		rotation.x = 0
		rotation.z = 0
		rotate_y(PI)
	# -------------------------
	
	# 原有的发射逻辑 (完全不用变)
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.global_rotation = muzzle.global_rotation
	
	is_attacking = true
	# 如果有攻击动画
	anim_player.play("1H_Melee_Attack_Chop")
	
	await anim_player.animation_finished # <--- 4. 等待
	is_attacking = false # <--- 5. 解锁
	
	# 动画播完后，显式切回 Idle，防止卡在最后一帧
	anim_player.play("Idle")
	
	
	# 4. 播放攻击动画 (如果有)
	# anim_player.play("Attack(1h)")
# 1. 新增：寻找最近敌人的函数
func get_nearest_enemy():
	# 获取所有都在 "Enemy" 组里的节点
	var enemies = get_tree().get_nodes_in_group("Enemy")
	
	if enemies.size() == 0:
		return null
		
	var nearest_enemy = null
	var min_distance = 10000.0 # 先设个很大的数
	
	for enemy in enemies:
		# 计算我和这个怪的距离
		var dist = global_position.distance_to(enemy.global_position)
		
		# 这是一个简单的“索敌范围”判断，比如只打 15 米内的怪
		if dist < 15.0 and dist < min_distance:
			min_distance = dist
			nearest_enemy = enemy
			
	return nearest_enemy

# --- ❤️ 受伤函数 ---
func take_damage(amount):
	if is_invincible: return
	current_hp -= amount
	hp_changed.emit(current_hp) # 通知UI更新 
	
	current_hp -= amount
	print("😱 乌拉受伤了！剩余血量: ", current_hp)
	
	# --- 🔴 3D 受伤变红特效 ---
	if body_mesh:
		# 获取材质
		var mat = body_mesh.get_active_material(0) # 获取第0号材质
		if mat:
			var tween = create_tween()
			# 1. 瞬间变红 (修改 albedo_color，不是 modulate)
			tween.tween_property(mat, "albedo_color", Color(1, 0, 0), 0.1) 
			# 2. 变回原色 (白色 = 正常贴图颜色)
			tween.tween_property(mat, "albedo_color", Color(1, 1, 1), 0.1) 
	
	# 死亡判定
	if current_hp <= 0:
		die()
	else:
		is_invincible = true
		await get_tree().create_timer(1.0).timeout
		is_invincible = false

func die():
	print("💀 游戏结束！")
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
	

# --- ✨ 新增：回血函数 ---
func heal(amount):
	if current_hp >= max_hp: return
	
	current_hp += amount
	if current_hp > max_hp:
		current_hp = max_hp
	
	hp_changed.emit(current_hp) # 通知UI更新
	print("💖 看到照片感到温暖，血量恢复：", current_hp)
