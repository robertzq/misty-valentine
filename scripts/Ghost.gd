extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
@onready var anim_player = $AnimationPlayer # 如果模型自带动画
var speed = 2.0
var player = null

func _ready():
	# 从组里找到玩家 (比直接写路径更安全)
	player = get_tree().get_first_node_in_group("Player")
	
	# 播放走路/漂浮动画
	if anim_player:
		anim_player.play("Idle") # 或者 Walk

func _physics_process(delta):
	if not player: return
	
	# 1. 设置目标位置
	nav_agent.target_position = player.global_position
	
	# 2. 获取下一步怎么走
	var next_pos = nav_agent.get_next_path_position()
	var current_pos = global_position
	
	# 3. 计算方向
	var direction = (next_pos - current_pos).normalized()
	velocity = direction * speed
	
	# 4. 面朝玩家 (平滑旋转)
	if direction.length() > 0.1:
		var target_angle = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 5 * delta)
	
	move_and_slide()

# --- 受伤逻辑 ---
func take_damage(amount):
	print("怪物被打中了！")
	purify()

func purify():
	# 播放死亡动画，或者变成花朵
	# 这里简单处理：直接变没
	queue_free()
