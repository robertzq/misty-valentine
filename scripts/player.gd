extends CharacterBody3D

# --- 变量区 ---
# ⚠️ 确保你的场景里真的有一个子节点叫 AnimationPlayer
@onready var nav_agent = $NavigationAgent3D
@onready var camera = get_viewport().get_camera_3d()
@onready var anim_player = $Mage/AnimationPlayer
const SPEED = 5.0

# --- 1. 这里是你漏掉的关键部分：初始化 ---
func _ready():
	print("我的动画列表: ", anim_player.get_animation_list())

func _physics_process(delta):
	# 检测鼠标输入
	if Input.is_action_pressed("move_to"):
		update_target_location()
		
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
		
		# --- 2. 这里是你漏掉的关键部分：播放动画 (走路) ---
		# 如果正在移动，且还没开始播 walk，就播 walk
		if anim_player.current_animation != "Running_A":
			anim_player.play("Running_A")
			
	else:
		# 到了或者没目标，停下来
		velocity = Vector3.ZERO
		
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
