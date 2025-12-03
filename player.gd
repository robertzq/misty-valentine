extends CharacterBody3D

# --- 变量区 ---
@onready var nav_agent = $NavigationAgent3D
@onready var camera = get_viewport().get_camera_3d() # 获取主摄像机

const SPEED = 5.0

func _physics_process(delta):
	# 1. 检测输入：如果按住了鼠标左键 (或者点击)
	if Input.is_action_pressed("move_to"):
		update_target_location()
		
	# 2. 如果当前有路径，且还没到达终点
	if not nav_agent.is_navigation_finished():
		var current_location = global_position
		var next_location = nav_agent.get_next_path_position()
		
		# 计算这一帧该往哪个方向走
		var direction = (next_location - current_location).normalized()
		
		# 设置速度
		velocity = direction * SPEED
		
		# --- 平滑旋转 (复制之前的逻辑) ---
		if direction.length() > 0.1:
			var target_angle = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_angle, 10 * delta)
		
		# 真正移动
		move_and_slide()
		
	else:
		# 到了或者没目标，停下来
		velocity = Vector3.ZERO

# --- 核心函数：把鼠标点击转换成 3D 坐标 ---
func update_target_location():
	# 获取鼠标在屏幕上的 2D 坐标
	var mouse_pos = get_viewport().get_mouse_position()
	
	# 射线检测三件套
	var ray_length = 1000
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	
	# 发射射线！
	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.create(from, to)
	
	# 这里的 collision_mask = 1 表示只检测第1层的物体（通常地板在第1层）
	# 建议后面确保地板有 CollisionShape3D
	var result = space.intersect_ray(ray_query)
	
	if result:
		# result.position 就是鼠标点中的 3D 地面坐标
		nav_agent.target_position = result.position
