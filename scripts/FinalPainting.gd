extends Node3D

# --- 节点引用 ---
@onready var parts_container = $Parts
@onready var full_painting = $FullPaintingSprite 
@onready var letter_ui = $CanvasLayer/Panel 

# 记录碎片归位的数据
var original_transforms = []
# 记录画框最终停留的位置（编辑器里摆放的位置）
var final_position: Vector3

func _ready():
	# 0. 初始设置：隐藏 UI 和完整画作
	if letter_ui:
		letter_ui.visible = false
		letter_ui.modulate.a = 0
	full_painting.visible = false
	
	# 1. 记录“最终位置”（就是你在场景里把画放在宝箱上的那个位置）
	final_position = global_position
	
	# 2. 初始时把画框瞬移到天上 (比如高 20 米)，藏起来
	global_position.y += 20.0 
	
	# 3. 记录碎片拼好时的相对位置
	save_original_transforms()
	
	# 4. 把碎片先隐藏，或者打散在半空
	# (这里我们先藏起来，等画框落地了再把它们变出来做飞入效果)
	parts_container.visible = false 

	# 5. 监听信号
	if GameManager:
		GameManager.all_collected.connect(start_performance)

# 保存碎片的正确位置（本地坐标）
func save_original_transforms():
	for part in parts_container.get_children():
		original_transforms.append({
			"pos": part.position,
			"rot": part.rotation,
			"node": part
		})

# 开始演出
func start_performance():
	print("🎬 电影级终局演出开始！")
	
	# --- 🎥 第1步：接管摄像机 (Cinematic Camera) ---
	var camera = get_viewport().get_camera_3d()
	if camera:
		# 1. 停止摄像机跟随主角 (假设你的相机脚本有这个属性)
		# 如果没有 target_character 属性，可以用 set_physics_process(false) 暴力停止它
		if "target_character" in camera:
			camera.target_character = null 
		else:
			camera.set_physics_process(false) # 暂停相机脚本
			camera.set_process(false)
		
		# 2. 运镜：摄像机飞到画框正前方，稍微俯视一点
		var cam_tween = create_tween().set_parallel(true)
		# 目标位置：画框最终位置的前方 6米，高 3米 (根据你的场景大小微调)
		# 0 3 6 ，3 height 6 远近
		var cam_target_pos = final_position + Vector3(0, 1, 4) 
		
		# 平滑移动相机
		cam_tween.tween_property(camera, "global_position", cam_target_pos, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# 让相机看着画框中心 (final_position)
		# look_at 需要每帧更新，Tween 很难直接做 look_at 动画，这里我们用一个小技巧：
		# 直接让相机看过去，或者你可以写一个简单的 _process 来一直 look_at
		camera.look_at(final_position + Vector3(0, 1, 0)) # 简单处理：直接看过去
	
	# --- 🖼️ 第2步：画框神圣降临 ---
	var drop_tween = create_tween()
	# 5秒钟缓慢降落 (神圣感)
	drop_tween.tween_property(self, "global_position", final_position, 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 等待画框降落到位
	await drop_tween.finished
	print("画框就位，碎片准备汇聚...")
	
	# --- ✨ 第3步：碎片半空汇聚 (汇聚特效) ---
	parts_container.visible = true
	
	# 先把碎片随机散布在画框周围的“球形区域”里 (模拟从四面八方飞来)
	for part in parts_container.get_children():
		# 在半径 5-8 米的球体内随机分布
		var random_dir = Vector3(randf()-0.5, randf()-0.5, randf()-0.5).normalized()
		part.position = random_dir * randf_range(5.0, 8.0)
		part.rotation = Vector3(randf()*PI, randf()*PI, randf()*PI) # 乱转
		part.visible = true

	# 开始飞回动画
	var assemble_tween = create_tween().set_parallel(true)
	for data in original_transforms:
		var part = data["node"]
		# 2.5秒内飞回原位，使用 BACK (回弹) 效果，增加一点冲击力
		assemble_tween.tween_property(part, "position", data["pos"], 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		assemble_tween.tween_property(part, "rotation", data["rot"], 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 等待拼合完成
	await assemble_tween.finished
	
	# --- 🌟 第4步：闪光融合 ---
	# (这里如果你有简单的闪光粒子特效，可以 play 一下)
	parts_container.visible = false
	full_painting.visible = true
	
	# --- 📜 第5步：信件浮现 ---
	await get_tree().create_timer(1.0).timeout
	if letter_ui:
		letter_ui.visible = true
		var ui_tween = create_tween()
		ui_tween.tween_property(letter_ui, "modulate:a", 1.0, 2.0)
