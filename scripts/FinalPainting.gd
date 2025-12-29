extends Node3D

# --- 节点引用 ---
@onready var parts_container = $Parts
@onready var full_painting = $FullPaintingSprite
@onready var back_content = $BackContent
@onready var card_mesh = $BackContent/PaintingMesh
@onready var message_label = $BackContent/Label3D
@onready var bgmPlayer = $"../bgmPlayer"

# --- 数据记录 ---
var original_transforms = []
var final_position: Vector3
var is_performance_finished = false
var is_flipping = false
var current_side = "back"

# --- ✅ 核心修改1：专属乱码池 ---
# 所有的“乱码”都会从这句话里随机抽取
# 这意味着情书还没成型时，看到的是满屏的“乌拉”、“社死”、“RBT”
const SCRAMBLE_CHARS = "乌拉With社死的RBT"

# --- ✅ 核心修改2：放慢节奏 ---
# 我把 speed (耗时) 加大了，让她能看清乱码内容
var text_blocks = [
	{
		"text": "To 鱿鱼小姐:\n有时候常想\n如果能早点遇到你就好了",
		"pause": 2.0,
		"speed": 5.0  # 原来3.0 -> 改成 5.0秒，慢慢浮现
	},
	{
		"text": "\n但你说\n起码，我们还是遇到了\n",
		"pause": 4.0, # 读完停顿 4秒
		"speed": 6.0  # 原来2.5 -> 改成 6.0秒。
					  # 这一句最重要，让“社死的RBT”多跳一会，
					  # 仿佛是过去的回忆慢慢凝聚成了这句话。
	},
	{
		"text": "\n我很珍惜这一点\n                        —— 赵先生",
		"pause": 0.0,
		"speed": 4.0  # 原来2.5 -> 改成 4.0秒
	}
]

# 用于记录已经显示出来的“清晰文本”
var current_stable_text = ""

func _ready():
	# 0. 初始状态设置
	full_painting.visible = false
	parts_container.visible = false
	
	if back_content: back_content.visible = true
	if card_mesh: card_mesh.visible = true
	if message_label:
		message_label.visible = false
		message_label.text = ""
		message_label.modulate.a = 0

	# 1. 记录位置
	final_position = global_position
	
	# 2. 瞬移上天
	global_position.y += 20.0
	
	# 3. 记录碎片位置
	save_original_transforms()
	
	# 4. 监听信号
	if get_tree().root.has_node("GameManager"):
		var gm = get_tree().root.get_node("GameManager")
		if gm.has_signal("all_collected"):
			gm.all_collected.connect(start_performance)

# --- 交互逻辑 ---
func _input(event):
	if not is_performance_finished: return
	if is_flipping: return

	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
		flip_card_interactive()

# --- 辅助函数 ---
func save_original_transforms():
	for part in parts_container.get_children():
		original_transforms.append({
			"pos": part.position,
			"rot": part.rotation,
			"node": part
		})

# --- 🎬 演出主流程 (保持你的运镜不动) ---
func start_performance():
	print("🎬 最终演出开始...")
	
	# 隐藏 UI
	var hud = get_tree().current_scene.find_child("UI", true, false)
	if hud: hud.visible = false
	
	# 主角控制
	var player = get_tree().current_scene.find_child("Player", true, false)
	if player:
		if "is_watching_cutscene" in player:
			player.trigger_final_cutscene()
		else:
			player.velocity = Vector3.ZERO
			player.is_invincible = true

	# 📷 摄像机运镜 (完全保留)
	var camera = get_viewport().get_camera_3d()
	if camera:
		if "target_character" in camera: camera.target_character = null
		
		var cam_tween = create_tween().set_parallel(true)
		
		var camera_height = 1.0
		var painting_center_y = 1.5
		var distance = 3.5
		
		var flat_forward = global_basis.z
		flat_forward.y = 0
		flat_forward = flat_forward.normalized()
		
		var cam_target_pos = final_position + (flat_forward * distance)
		cam_target_pos.y = final_position.y + camera_height
		
		var look_target = final_position + Vector3(0, painting_center_y, 0)
	
		cam_tween.tween_property(camera, "global_position", cam_target_pos, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		var target_transform = camera.global_transform.looking_at(look_target, Vector3.UP)
		cam_tween.tween_property(camera, "global_rotation", target_transform.basis.get_euler(), 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	
	play_deep_bgm()
	# 画框降落
	var drop_tween = create_tween()
	drop_tween.tween_property(self, "global_position", final_position, 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await drop_tween.finished
	
	# 碎片动画
	parts_container.visible = true
	for part in parts_container.get_children():
		part.position = Vector3(randf()-0.5, randf()-0.5, randf()-0.5).normalized() * 5.0
		part.rotation = Vector3(randf()*PI, randf()*PI, randf()*PI)
	
	var assemble_tween = create_tween().set_parallel(true)
	for data in original_transforms:
		var part = data["node"]
		assemble_tween.tween_property(part, "position", data["pos"], 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		assemble_tween.tween_property(part, "rotation", data["rot"], 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	await assemble_tween.finished
	
	# 融合
	await get_tree().create_timer(0.5).timeout
	parts_container.visible = false
	full_painting.visible = true
	
	# 欣赏
	await get_tree().create_timer(3.0).timeout
	# --- ✅ 修正点：ID 必须和网页后台一模一样 ---
	print("尝试触发成就：ACH_PIC_COLLECT")
	
	# 安全调用：防止因为 GlobalSteam 没加载导致游戏卡死
	if get_tree().root.has_node("GlobalSteam"):
		# 调用你 GlobalSteam.gd 里定义的 unlock_achievement 函数
		get_tree().root.get_node("GlobalSteam").unlock_achievement("ACH_PIC_COLLECT")
	else:
		printerr("⚠️ 警告：找不到 GlobalSteam 节点！")
	
	# 无论成就成不成功，强制继续流程！(防止卡住)
	play_final_reveal_sequence()
	

# --- 🎬 后半段：翻转与信件 ---
func play_final_reveal_sequence():
	var tween = create_tween()
	
	# 1. 旋转露出背面
	tween.tween_property(self, "rotation_degrees:y", 180.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# 2. 停留
	tween.chain().tween_interval(3.0)
	
	# 3. 准备消散照片
	tween.chain().tween_callback(func():
		var photo_mat = card_mesh.get_active_material(0)
		if photo_mat:
			photo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	)
	
	# 4. 照片消散
	var fade_step = tween.chain().set_parallel(true)
	var photo_mat = card_mesh.get_active_material(0)
	if photo_mat:
		fade_step.tween_property(photo_mat, "albedo_color:a", 0.0, 2.0).set_trans(Tween.TRANS_SINE)
		fade_step.tween_property(card_mesh, "scale", Vector3(0.8, 0.8, 0.8), 2.0)
	else:
		fade_step.tween_property(card_mesh, "scale", Vector3.ZERO, 2.0)
	
	# 5. 显示文字
	tween.chain().tween_callback(func():
		card_mesh.visible = false
		message_label.visible = true
		message_label.modulate.a = 1.0
		start_text_sequence()
	)

# --- 📝 文字演出逻辑 ---
func start_text_sequence():
	current_stable_text = ""
	
	for block in text_blocks:
		var line_text = block["text"]
		var duration = block["speed"]
		var pause_time = block["pause"]
		
		var line_tween = create_tween()
		line_tween.tween_method(
			update_single_line_scramble.bind(line_text),
			0.0,
			3.0,
			duration
		)
		
		await line_tween.finished
		
		current_stable_text += line_text
		message_label.text = current_stable_text
		
		if pause_time > 0:
			await get_tree().create_timer(pause_time).timeout
			
	finish_performance()

# --- 📝 乱码计算 (你的专属定制版) ---
func update_single_line_scramble(progress: float, target_line: String):
	var active_text = ""
	var total_chars = target_line.length()
	
	for i in range(total_chars):
		var char_threshold = float(i) / float(total_chars)
		var target_char = target_line[i]
		
		# 换行和空格保持原样
		if target_char == "\n" or target_char == " " or target_char == "\t":
			active_text += target_char
			continue
			
		if progress > char_threshold:
			active_text += target_char
		else:
			# ✅ 这里会随机跳出：乌、社、R、死、B、T...
			active_text += SCRAMBLE_CHARS[randi() % SCRAMBLE_CHARS.length()]
	
	message_label.text = current_stable_text + active_text

# --- 结束处理 ---
func finish_performance():
	is_performance_finished = true
	print("✅ 演出结束")
	# --- ✅ 修正点：ID 必须和网页后台一模一样 ---
	print("尝试触发成就：ACH_THE_MOMENT")
	
	if get_tree().root.has_node("GlobalSteam"):
		get_tree().root.get_node("GlobalSteam").unlock_achievement("ACH_THE_MOMENT")

# --- 翻转 ---
func flip_card_interactive():
	is_flipping = true
	var tween = create_tween()
	
	if current_side == "back":
		tween.tween_property(self, "rotation_degrees:y", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		current_side = "front"
	else:
		tween.tween_property(self, "rotation_degrees:y", 180.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		current_side = "back"
	
	tween.tween_callback(func(): is_flipping = false)
	
func play_deep_bgm():
	# 1. 确保音量是正常的 (0 dB)
	bgmPlayer.volume_db = 0.0
	bgmPlayer.play()
	
	# 2. 先播放 75 秒 (留 5 秒给淡出)
	await get_tree().create_timer(75.0).timeout
	
	# 3. 创建 Tween 动画来实现淡出
	var tween = create_tween()
	
	# 在 5 秒内，将 volume_db 属性从当前值变成 -80 dB (静音)
	# TRANS_SINE 和 EASE_IN 能让淡出听起来更自然
	tween.tween_property(bgmPlayer, "volume_db", -80.0, 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# 4. 等淡出动画播放完
	await tween.finished
	
	# 5. 彻底停止播放
	bgmPlayer.stop()
	# 可以在这里触发“游戏结束”或“退出”按钮的显示
