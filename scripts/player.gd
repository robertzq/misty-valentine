extends CharacterBody3D

# --- 变量区 ---
# ⚠️ 确保你的场景里真的有一个子节点叫 AnimationPlayer
@onready var nav_agent = $NavigationAgent3D
@onready var camera = get_viewport().get_camera_3d()
@onready var anim_player = $Character/AnimationPlayer
const SPEED = 5.0

# --- 1. 这里是你漏掉的关键部分：初始化 ---
func _ready():
	# 游戏一开始，必须手动运行加载函数，否则库是空的
	setup_animations()
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
		if anim_player.current_animation != "walk":
			anim_player.play("walk")
			
	else:
		# 到了或者没目标，停下来
		velocity = Vector3.ZERO
		
		# --- 3. 这里是你漏掉的关键部分：播放动画 (站立) ---
		# 如果停下了，且还没开始播 idle，就播 idle
		if anim_player.current_animation != "idle":
			anim_player.play("idle")

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

# --- 纯代码加载动画 ---
# --- 纯代码加载动画 (修正版) ---
func setup_animations():
	# 1. ⚠️ 关键步骤：先清理掉 FBX 自带的旧动画库
	# 这样我们才能保证 AnimationPlayer 是干净的，听我们指挥
	if anim_player.has_animation_library(""):
		anim_player.remove_animation_library("")
	
	# 2. 创建一个新的动画库
	var library = AnimationLibrary.new()
	
	# 3. 加载资源 (请确保这俩路径是对的！)
	# 技巧：把 .res 文件从左下角拖到引号里，确保路径没错
	var walk_anim = load("res://assets/models/anim_walk.res") 
	var idle_anim = load("res://assets/models/anim_idle.res")
	
	# 4. 检查加载结果
	if not walk_anim or not idle_anim:
		printerr("❌ 动画文件加载失败！请检查代码里的路径！")
		# 临时救急：如果加载失败，至少不要报错，但这会导致没有动画
		return
	
	# 5. 添加动画到库里
	library.add_animation("walk", walk_anim)
	library.add_animation("idle", idle_anim)
	
	# 6. 挂载新库 (使用空字符串 "" 作为默认库名)
	anim_player.add_animation_library("", library)
	
	print("✅ 动画库替换成功！现在的列表: ", anim_player.get_animation_list())
