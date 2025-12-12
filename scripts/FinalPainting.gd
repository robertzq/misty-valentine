extends Node3D

# --- 节点引用 ---
@onready var parts_container = $Parts
@onready var full_painting = $FullPaintingSprite 
@onready var letter_ui = $CanvasLayer/Panel 

# 记录碎片归位的数据
var original_transforms = []
# 记录画框最终停留的位置
var final_position: Vector3

func _ready():
	# 0. 初始设置：隐藏 UI 和完整画作
	if letter_ui:
		letter_ui.visible = false
		letter_ui.modulate.a = 0
	full_painting.visible = false
	
	# 1. 记录“最终位置”
	final_position = global_position
	
	# 2. 初始时把画框瞬移到天上 (比如高 20 米)
	global_position.y += 20.0 
	
	# 3. 记录碎片拼好时的相对位置
	save_original_transforms()
	
	# 4. 把碎片先隐藏
	parts_container.visible = false 

	# 5. 监听信号
	if GameManager:
		GameManager.all_collected.connect(start_performance)

func save_original_transforms():
	for part in parts_container.get_children():
		original_transforms.append({
			"pos": part.position,
			"rot": part.rotation,
			"node": part
		})

func start_performance():
	print("🎬 电影级终局演出开始！")
	
	# --- 🛡️ 第0步：让主角无敌 ---
	var player = get_tree().current_scene.find_child("Player", true, false)
	if player:
		player.is_invincible = true 
		player.velocity = Vector3.ZERO 
		# 可选：把主角隐藏，或者移到画框后面，防止他挡住镜头
		# player.visible = false 

	# --- 🌤️ 第0.5步：云开雾散 ---
	var world_env = get_tree().current_scene.find_child("WorldEnvironment", true, false)
	if world_env and world_env.environment:
		var fog_tween = create_tween()
		fog_tween.tween_property(world_env.environment, "volumetric_fog_density", 0.0, 6.0).set_trans(Tween.TRANS_SINE)
		fog_tween.parallel().tween_property(world_env.environment, "background_energy_multiplier", 1.2, 6.0)

	# --- 🎥 第1步：接管摄像机 (修正版) ---
	var camera = get_viewport().get_camera_3d()
	if camera:
		# 停止跟随
		if "target_character" in camera:
			camera.target_character = null 
		else:
			camera.set_physics_process(false)
			camera.set_process(false)
		
		# --- 📐 核心修正：计算正对画框的完美机位 ---
		var cam_tween = create_tween().set_parallel(true)
		
		# 1. 寻找画框的"正前方"：利用 basis.z (蓝色轴)
		# 如果你的模型是反的，可能需要改成 -global_basis.z，可以先试这个
		var forward_direction = global_basis.z.normalized() 
		
		# 2. 设定高度 (Y)：想要"更低、更正"，就把高度设为和画框中心一致
		# 假设画框在宝箱上，中心大概在地面上 1.0 到 1.2 米处
		var target_height = 1.3 
		
		# 3. 设定距离：离画框 3.5 米
		var target_distance = 8
		
		# 4. 组合最终坐标：落地位置 + 前方距离 + 高度偏移
		# final_position 是地面的点 (Y=0)，所以我们要加 Vector3(0, target_height, 0)
		var cam_target_pos = final_position + (forward_direction * target_distance) + Vector3(0, target_height, 0)
		
		# 5. 计算这一刻摄像机应该看向哪里 (画框中心)
		var look_target = final_position + Vector3(2, target_height, 0)

		# 6. 执行动画
		cam_tween.tween_property(camera, "global_position", cam_target_pos, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# 7. 平滑旋转摄像机 (为了防止 look_at 瞬间跳变，我们用 Tween 来转头)
		# 这是一个小技巧：先计算出"看着目标"时的理想旋转角度
		var temp_transform = camera.global_transform.looking_at(look_target, Vector3.UP)
		cam_tween.tween_property(camera, "global_rotation", temp_transform.basis.get_euler(), 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# --- 🖼️ 第2步：画框神圣降临 ---
	var drop_tween = create_tween()
	drop_tween.tween_property(self, "global_position", final_position, 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await drop_tween.finished
	print("画框就位，碎片准备汇聚...")
	
	# --- ✨ 第3步：碎片半空汇聚 ---
	parts_container.visible = true
	
	# 先打散
	for part in parts_container.get_children():
		var random_dir = Vector3(randf()-0.5, randf()-0.5, randf()-0.5).normalized()
		part.position = random_dir * randf_range(5.0, 8.0)
		part.rotation = Vector3(randf()*PI, randf()*PI, randf()*PI)
		part.visible = true

	# 飞回
	var assemble_tween = create_tween().set_parallel(true)
	for data in original_transforms:
		var part = data["node"]
		assemble_tween.tween_property(part, "position", data["pos"], 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		assemble_tween.tween_property(part, "rotation", data["rot"], 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	await assemble_tween.finished
	
	# --- 🌟 第4步：融合瞬间 ---
	parts_container.visible = false
	full_painting.visible = true
	
	# --- 📜 第5步：信件浮现 ---
	await get_tree().create_timer(1.0).timeout
	if letter_ui:
		letter_ui.visible = true
		var ui_tween = create_tween()
		ui_tween.tween_property(letter_ui, "modulate:a", 1.0, 2.0)
