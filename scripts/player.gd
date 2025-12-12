extends CharacterBody3D

# --- 变量区 ---
# ⚠️ 确保你的场景里真的有一个子节点叫 AnimationPlayer
@onready var nav_agent = $NavigationAgent3D
@onready var camera = get_viewport().get_camera_3d()
@onready var anim_player = $Mage/AnimationPlayer
@onready var muzzle = $Muzzle
@onready var body_mesh = $Mage/Rig/Skeleton3D/Mage_Body 

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
const SPEED = 5.0
# 预加载子弹场景
var bullet_scene = preload("res://scenes/MagicMissile.tscn")
var is_attacking = false 

var max_hp = 5 
var current_hp = 3
@export var is_invincible = false # 无敌时间

signal hp_changed(val) # 新增信号，通知UI

func _ready():
	current_hp = max_hp
	hp_changed.emit(current_hp) 
	print("我的动画列表: ", anim_player.get_animation_list())
	
	# --- 材质保护代码 ---
	if body_mesh:
		var source_mat = body_mesh.get_active_material(0)
		if source_mat:
			var unique_mat = source_mat.duplicate()
			body_mesh.set_surface_override_material(0, unique_mat)

func _physics_process(delta):
	# 1. 应用重力 (始终运行)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. 检测攻击输入 (手动触发)
	if Input.is_action_just_pressed("attack"): 
		shoot()

	# 3. 移动逻辑状态机
	if is_attacking:
		# ⚔️ 攻击状态：强制停止水平移动 (防止滑步)
		velocity.x = 0
		velocity.z = 0
	else:
		# 🏃 正常状态：允许移动和寻路
		
		# 检测鼠标移动指令
		if Input.is_action_pressed("move_to"):
			update_target_location()
			
		if not nav_agent.is_navigation_finished():
			var current_location = global_position
			var next_location = nav_agent.get_next_path_position()
			
			# 计算水平方向 (忽略 Y 轴高度差)
			var diff = next_location - current_location
			diff.y = 0 
			var direction = diff.normalized()
			
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			
			# 平滑旋转
			if direction.length() > 0.1:
				var target_angle = atan2(direction.x, direction.z)
				rotation.y = lerp_angle(rotation.y, target_angle, 10 * delta)
				
			# 播放跑步动画
			if anim_player.current_animation != "Running_A":
				anim_player.play("Running_A")
		else:
			# 到达目的地，减速停止
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
			
			# 播放待机动画
			if anim_player.current_animation != "Idle":
				anim_player.play("Idle")
	
	# 4. 执行物理移动
	move_and_slide()

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

# --- 攻击函数 ---
func shoot():
	if is_attacking: return # 防止连点
	
	# 1. 自动瞄准逻辑
	var target = get_nearest_enemy()
	if target:
		# 如果有敌人，立即转身面向敌人
		look_at(target.global_position, Vector3.UP)
		# 修正一下 X/Z 轴，防止歪着身子
		rotation.x = 0
		rotation.z = 0
		rotate_y(PI) # 如果模型是反的，保留这个；如果是正的，删掉这行
	
	# 2. 生成子弹
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.global_rotation = muzzle.global_rotation # 子弹继承枪口的朝向(也就是指向敌人的方向)
	
	# 3. 播放动画并锁定状态
	is_attacking = true
	anim_player.play("1H_Melee_Attack_Chop")
	
	# 等待动画播完
	await anim_player.animation_finished
	
	# 4. 解锁状态
	is_attacking = false
	anim_player.play("Idle") # 播完切回待机

# --- 辅助：寻找最近敌人 ---
func get_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if enemies.size() == 0:
		return null
		
	var nearest_enemy = null
	var min_distance = 20.0 # 索敌半径，超过20米不自动瞄准
	
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_distance:
			min_distance = dist
			nearest_enemy = enemy
			
	return nearest_enemy

# --- 受伤函数 ---
func take_damage(amount):
	if is_invincible: return
	
	current_hp -= amount
	hp_changed.emit(current_hp) # 通知UI
	print("乌拉受伤了！剩余血量: ", current_hp)
	
	# 受伤变红特效
	if body_mesh:
		var mat = body_mesh.get_active_material(0)
		if mat:
			var tween = create_tween()
			tween.tween_property(mat, "albedo_color", Color(1, 0, 0), 0.1) 
			tween.tween_property(mat, "albedo_color", Color(1, 1, 1), 0.1) 
	
	if current_hp <= 0:
		die()
	else:
		is_invincible = true
		await get_tree().create_timer(1.0).timeout
		is_invincible = false

func die():
	print("💀 游戏结束！")
	# 切换到结束场景，确保你有这个场景文件
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

# --- 回血函数 ---
func heal(amount):
	if current_hp >= max_hp: return
	
	current_hp += amount
	if current_hp > max_hp:
		current_hp = max_hp
	
	hp_changed.emit(current_hp) 
	print("💖 看到照片感到温暖，血量恢复：", current_hp)
