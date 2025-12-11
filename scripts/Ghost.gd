extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
@onready var anim_player = $Skeleton_Rogue/AnimationPlayer
# 预加载特效
var purify_effect_scene = preload("res://scenes/PurifyEffect.tscn")

# --- ⚙️ 新增配置区域 ---
@export var speed = 2.0 
@export var detection_range = 8.0  # 警戒距离：小于这个距离开始追
@export var give_up_range = 12.0   # 放弃距离：大于这个距离就不追了
# --------------------

var player = null
var is_chasing = false # 记录当前状态：是不是正在追人

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	
	if anim_player:
		anim_player.play("Idle")

func _physics_process(delta):
	if not player: return
	
	# 1. 计算和玩家的距离
	var dist = global_position.distance_to(player.global_position)
	
	# 2. 状态判断机
	if is_chasing:
		# 如果正在追，但这人跑得太远了 (超过放弃距离)，就不追了
		if dist > give_up_range:
			is_chasing = false
			velocity = Vector3.ZERO # 立刻停下
	else:
		# 如果没在追，但这人走得太近了 (进入警戒距离)，开始追！
		if dist < detection_range:
			is_chasing = true

	# 3. 根据状态执行动作
	if is_chasing:
		# --- 只有在追的时候才寻路 ---
		nav_agent.target_position = player.global_position
		var next_pos = nav_agent.get_next_path_position()
		var current_pos = global_position
		var direction = (next_pos - current_pos).normalized()
		
		velocity = direction * speed
		
		# 旋转面向
		if direction.length() > 0.1:
			var target_angle = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_angle, 5 * delta)
	else:
		# 如果不追，速度归零 (或者你可以在这里写巡逻逻辑)
		velocity = Vector3.ZERO

	# 4. 执行移动
	move_and_slide()
	
	# 5. 动画状态切换 (逻辑不变，velocity 为 0 时自动播 Idle)
	if anim_player:
		if velocity.length() > 0.1:
			if anim_player.current_animation != "Walking_A":
				anim_player.play("Walking_A")
		else:
			if anim_player.current_animation != "Idle":
				anim_player.play("Idle")

# --- 受伤逻辑 ---
func take_damage(_amount): # 加了下划线，消除未使用参数的警告
	print("怪物被打中了！")
	purify()

func purify():
	var effect = purify_effect_scene.instantiate()
	get_parent().add_child(effect)
	effect.global_position = global_position 
	queue_free()
