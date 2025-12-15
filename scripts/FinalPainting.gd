extends Node3D

# --- 节点引用 ---
@onready var parts_container = $Parts
@onready var full_painting = $FullPaintingSprite 
# @onready var letter_ui = $CanvasLayer/Panel # 这个旧UI如果不用了可以注释掉

@onready var back_content = $BackContent
@onready var card_mesh = $BackContent/PaintingMesh  # 背面的“100天照片”
@onready var message_label = $BackContent/Label3D # 最后的“信件文字”

# --- 数据记录 ---
var original_transforms = []
var final_position: Vector3
# 用于交互的状态标记
var is_performance_finished = false
var is_flipping = false # 防止动画播放时连点
var current_side = "back" # 演出结束时停留在背面

# --- 文本内容 ---
var final_message = """To 鱿鱼小姐:
有时候会想
如果能早点遇到你就好了
但你说
起码，我们还是遇到了
我很珍惜这一点

                        —— 赵先生"""
						
# --- 乱码字符池 ---
# 用于生成随机的干扰字符
const SCRAMBLE_CHARS = "乌拉With社死的RBT"

func _ready():
	# 0. 初始状态设置
	full_painting.visible = false
	parts_container.visible = false 
	
	# 背面初始化：先显示照片，隐藏文字
	if back_content: back_content.visible = true
	if card_mesh: card_mesh.visible = true
	if message_label: 
		message_label.visible = false
		message_label.text = final_message.dedent()
		message_label.modulate.a = 0 # 透明度设为0，方便做渐变

	# 1. 记录画框在地面的“最终位置”
	final_position = global_position
	
	# 2. 初始位移：把画框瞬移到天上
	global_position.y += 20.0 
	
	# 3. 记录碎片拼好时的相对位置
	save_original_transforms()
	
	# 4. 监听收集信号
	if GameManager:
		GameManager.all_collected.connect(start_performance)

# --- 交互逻辑：按任意键/点击翻转 ---
func _input(event):
	# 只有演出完全结束后，才允许交互
	if not is_performance_finished:
		return
		
	# 防止动画正在播放时重复触发
	if is_flipping:
		return

	# 检测鼠标点击 或 键盘任意键
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
		flip_card_interactive()

func save_original_transforms():
	for part in parts_container.get_children():
		original_transforms.append({
			"pos": part.position,
			"rot": part.rotation,
			"node": part
		})

func start_performance():
	print("🎬 最终演出开始...")
	
	# --- 0. 隐藏顶部收集进度 UI (关键) ---
	# 假设你的进度UI在 GameManager 或主场景里，名字叫 "HUD" 或 "CollectionUI"
	# 这里尝试一种通用的查找方法，你需要确认一下你原来的UI节点叫什么名字
	var hud = get_tree().current_scene.find_child("UI", true, false) 
	if hud:
		hud.visible = false # 直接隐藏，防止挡镜头
	
	# --- 1. 主角控制 ---
	var player = get_tree().current_scene.find_child("Player", true, false)
	if player:
		player.is_invincible = true 
		player.velocity = Vector3.ZERO 

	# --- 2. 摄像机接管：切换到完美正面视角 ---
	var camera = get_viewport().get_camera_3d()
	if camera:
		if "target_character" in camera: camera.target_character = null
		
		var cam_tween = create_tween().set_parallel(true)
		
		# [核心修改] 计算完美的平视角度
		# 1. 参数设置（在这里微调数值）
		var camera_height = 1.0      # 摄像机离地高度（你觉得舒服的 1.0）
		var painting_center_y = 1.5  # 画框中心的视觉高度（要盯着看的地方，不要变）
		var distance = 3.5           # 离画框多远（觉得太近可以改成 4.0）
		
		# 2. 计算摄像机的位置
		# 技巧：只取画框的“水平前方”，忽略画框本身的俯仰角，防止跑偏
		var flat_forward = global_basis.z
		flat_forward.y = 0 
		flat_forward = flat_forward.normalized()
		
		# 组合：落地位置 + 水平方向距离 + 强制设定的高度
		var cam_target_pos = final_position + (flat_forward * distance)
		cam_target_pos.y = final_position.y + camera_height 
		
		# 3. 计算“看向哪里”
		# 无论机位高低，眼神永远锁定画框中心
		var look_target = final_position + Vector3(0, painting_center_y, 0)
		# 假设画框的中心点高度。如果画框原点在底部，中心大概在 Y+1.5 左右
		#var center_height_offset = Vector3(0, 1, 0)
		
	
		# 4. 执行动画
		cam_tween.tween_property(camera, "global_position", cam_target_pos, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# 计算完美的旋转角度
		var target_transform = camera.global_transform.looking_at(look_target, Vector3.UP)
		cam_tween.tween_property(camera, "global_rotation", target_transform.basis.get_euler(), 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# --- 3. 画框降落 ---
	var drop_tween = create_tween()
	drop_tween.tween_property(self, "global_position", final_position, 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await drop_tween.finished
	
	# --- 4. 碎片汇聚 ---
	parts_container.visible = true
	# (这里省略打散步骤，直接飞回，保持节奏紧凑)
	for part in parts_container.get_children():
		part.position = Vector3(randf()-0.5, randf()-0.5, randf()-0.5).normalized() * 5.0
		part.rotation = Vector3(randf()*PI, randf()*PI, randf()*PI)
	
	var assemble_tween = create_tween().set_parallel(true)
	for data in original_transforms:
		var part = data["node"]
		assemble_tween.tween_property(part, "position", data["pos"], 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		assemble_tween.tween_property(part, "rotation", data["rot"], 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	await assemble_tween.finished
	
	# --- 5. 融合变成完整画作 ---
	await get_tree().create_timer(0.5).timeout
	parts_container.visible = false
	full_painting.visible = true
	
	# --- 6. 停留欣赏一会 (1.5秒) ---
	await get_tree().create_timer(1.5).timeout
	
	# --- 7. 进入翻转展示流程 ---
	play_final_reveal_sequence()

func play_final_reveal_sequence():
	var tween = create_tween()
	
	# --- 1. 旋转 (1.5秒) ---
	tween.tween_property(self, "rotation_degrees:y", 180.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# --- 2. 等待 3 秒 ---
	# .chain() 确保旋转完才开始等
	tween.chain().tween_interval(3.0)
	
	# --- 3. 准备消散 (关键修改) ---
	# 我们插入一个回调，确保 3秒等待结束 后，才开启透明模式
	tween.chain().tween_callback(func():
		var photo_mat = card_mesh.get_active_material(0)
		if photo_mat:
			# 此时才开启透明度混合，防止提前出现渲染排序问题
			photo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	)
	
	# --- 4. 照片消散动画 (2.5秒) ---
	# 继续链式调用
	var fade_step = tween.chain().set_parallel(true)
	
	var photo_mat = card_mesh.get_active_material(0)
	if photo_mat:
		# 注意：这里只负责做动画，状态改变已经在上面的回调里做了
		fade_step.tween_property(photo_mat, "albedo_color:a", 0.0, 2.5).set_trans(Tween.TRANS_SINE)
		fade_step.tween_property(card_mesh, "scale", Vector3(0.8, 0.8, 0.8), 2.5)
	else:
		fade_step.tween_property(card_mesh, "scale", Vector3.ZERO, 2.0)
	
	# --- 5. 彻底隐藏照片 ---
	# 等上面的并行消散做完
	tween.chain().tween_callback(func(): card_mesh.visible = false)
	
	# --- 6. 开启文字显示 ---
	tween.tween_callback(func(): 
		message_label.visible = true
		message_label.modulate.a = 1.0
	)
	
	# --- 7. 乱码重组 (4.0秒) ---
	tween.tween_method(update_scramble_text, 0.0, 3.0, 4.0)
	
	# --- 8. 结束 ---
	tween.chain().tween_callback(func(): 
		is_performance_finished = true
		message_label.text = final_message 
		print("✅ 演出结束，开启交互模式")
	)

# --- 交互翻转逻辑 ---
func flip_card_interactive():
	is_flipping = true
	var tween = create_tween()
	
	if current_side == "back":
		# 从背面转回正面 (180 -> 0)
		tween.tween_property(self, "rotation_degrees:y", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		current_side = "front"
	else:
		# 从正面转回背面 (0 -> 180)
		tween.tween_property(self, "rotation_degrees:y", 180.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		current_side = "back"
	
	tween.tween_callback(func(): is_flipping = false)

# 这个函数会被 Tween 每帧调用，value 从 0.0 变到 1.0
func update_scramble_text(value: float):
	var current_text = ""
	var total_chars = final_message.length()
	
	# 遍历最终信件的每一个字符
	for i in range(total_chars):
		var target_char = final_message[i]
		
		# 特殊字符（换行、空格）不进行乱码处理，保持排版整洁
		if target_char == "\n" or target_char == " " or target_char == "\t":
			current_text += target_char
			continue
		
		# 算法逻辑：
		# value 是当前进度 (0.0 - 1.0)
		# 我们为每个字符计算一个阈值。前面的字符先变清晰，后面的后变清晰。
		# 稍微加一点 random 扰动，让边界不那么死板
		var char_threshold = float(i) / float(total_chars)
		
		if value > char_threshold:
			# 如果进度超过了这个字符的阈值，显示真字
			current_text += target_char
		else:
			# 否则，显示随机乱码
			current_text += SCRAMBLE_CHARS[randi() % SCRAMBLE_CHARS.length()]
			
	message_label.text = current_text
