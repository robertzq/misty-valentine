extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
@onready var anim_player =  $Skeleton_Rogue/AnimationPlayer
# 预加载特效 (把刚才做的场景拖进来)
var purify_effect_scene = preload("res://scenes/PurifyEffect.tscn")
var speed = 2.0 # 怪物速度，如果觉得太慢可以改成 3.0 或 4.0
var player = null

func _ready():
	player = get_tree().get_first_node_in_group("Player")

	# 刚出来的时候先播 Idle
	if anim_player:
		anim_player.play("Idle")

func _physics_process(delta):
	if not player: return
	
	# 1. 寻路逻辑
	nav_agent.target_position = player.global_position
	var next_pos = nav_agent.get_next_path_position()
	var current_pos = global_position
	var direction = (next_pos - current_pos).normalized()
	
	# 2. 赋值速度
	velocity = direction * speed
	
	# 3. 旋转逻辑
	if direction.length() > 0.1:
		var target_angle = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 5 * delta)
	
	# 4. 执行移动
	move_and_slide()
	
	# --- 5. 新增：动画状态切换 ---
	if anim_player:
		# 判断当前的实际速度 (velocity.length())
		if velocity.length() > 0.1:
			# 如果正在跑，但当前播放的不是 Running_A，就切换
			if anim_player.current_animation != "Walking_A":
				anim_player.play("Walking_A")
		else:
			# 如果停下了，且没播 Idle，就切换
			if anim_player.current_animation != "Idle":
				anim_player.play("Idle")

# --- 受伤逻辑 ---
func take_damage(amount):
	print("怪物被打中了！")
	purify()

func purify():
	# 1. 生成特效
	var effect = purify_effect_scene.instantiate()
	get_parent().add_child(effect) # 加到世界上，别加给自己(因为自己马上要没了)
	effect.global_position = global_position # 位置对齐
	
	# 2. (可选) 掉落奖励？
	# 比如有几率掉个回血的爱心
	
	# 3. 销毁自己
	queue_free()
