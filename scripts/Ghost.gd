extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
@onready var anim_player = $Skeleton_Rogue/AnimationPlayer
var purify_effect_scene = preload("res://scenes/PurifyEffect.tscn")

# --- 配置参数 ---
@export var speed = 2.0 
@export var detection_range = 8.0  # 警戒范围
@export var give_up_range = 12.0   # 脱战范围
@export var attack_range = 1.5     # ⚔️ 攻击范围 (必须很近才能打到)
@export var attack_cooldown = 1.2  # ⚔️ 攻击冷却 (几秒咬一口)

var player = null
var is_chasing = false
var time_since_last_attack = 0.0 # 计时器
@export var ghost_blood = 2

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	if anim_player: anim_player.play("Idle")

func _physics_process(delta):
	# 计时器累加
	time_since_last_attack += delta
	
	if not player: return
	
	var dist = global_position.distance_to(player.global_position)
	
	# --- 1. 状态机 (追还是不追) ---
	if is_chasing:
		if dist > give_up_range:
			is_chasing = false
			velocity = Vector3.ZERO
	else:
		if dist < detection_range:
			is_chasing = true

	# --- 2. 行为逻辑 ---
	if is_chasing:
		# ⚔️ 新增：攻击逻辑
		# 如果距离足够近，并且冷却时间到了
		if dist <= attack_range:
			# 到了攻击范围，先停下，别穿过玩家身体
			velocity = Vector3.ZERO 
			
			if time_since_last_attack > attack_cooldown:
				attack_player()
		else:
			# 距离不够，继续追
			move_towards_player(delta)
	else:
		velocity = Vector3.ZERO
		# 这里如果不动，也可以加个自动回血之类的

	move_and_slide()
	update_animation()

# 封装的移动函数，保持代码整洁
func move_towards_player(delta):
	nav_agent.target_position = player.global_position
	var next_pos = nav_agent.get_next_path_position()
	var dir = (next_pos - global_position).normalized()
	velocity = dir * speed
	
	# 面向玩家
	if dir.length() > 0.1:
		var target_angle = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 5 * delta)

# ⚔️ 攻击动作
func attack_player():
	time_since_last_attack = 0.0 # 重置冷却
	
	print("幽灵发动攻击！")
	
	# 1. 播放攻击动画 (如果有的话，KayKit通常叫 Attack(1h) 或 Attack)
	if anim_player and anim_player.has_animation("Block_Attack"):
		anim_player.play("Block_Attack")
	
	# 2. 扣主角的血
	if player.has_method("take_damage"):
		player.take_damage(1)

# 动画管理
func update_animation():
	if not anim_player: return
	
	# 如果正在播放攻击动画，就别切成走路了，等它播完
	if anim_player.current_animation == "Block_Attack":
		return

	if velocity.length() > 0.1:
		if anim_player.current_animation != "Walking_A":
			anim_player.play("Walking_A")
	else:
		if anim_player.current_animation != "Idle":
			anim_player.play("Idle")

# --- 受伤与死亡 ---
func take_damage(_amount):
	ghost_blood-=1
	if(ghost_blood <= 0):
		purify()

func purify():
	var effect = purify_effect_scene.instantiate()
	get_parent().add_child(effect)
	effect.global_position = global_position 
	queue_free()
