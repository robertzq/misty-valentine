extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# 获取重力设置 (Project Settings -> Physics -> 3D -> Default Gravity)
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	# 1. 应用重力 (如果在空中，就往下掉)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. 处理跳跃 (按下空格键)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. 获取输入方向 (WASD 或 箭头键)
	# ui_left, ui_right 等是 Godot 内置的映射
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# 如果没按键，慢慢停下来
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# 4. 执行移动 (这是 CharacterBody3D 的核心函数)
	move_and_slide()
