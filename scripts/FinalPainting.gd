extends Node3D

# 引用节点
@onready var parts_container = $Parts
@onready var full_painting = $FullPaintingSprite 

# 🛠️ 修正1: 变量名改成 letter_ui，并且指向 CanvasLayer 下面的 Panel
# 注意：请确保你的场景结构是 CanvasLayer -> Panel (用来做背景和装字的)
# 因为 CanvasLayer 本身没有 modulate 属性，没法做淡入淡出，必须控制里面的控件
@onready var letter_ui = $CanvasLayer/Panel 

# 用来存储那9个碎片的“正确位置”
var original_transforms = []

func _ready():
	# 确保 UI 一开始是藏起来的
	if letter_ui:
		letter_ui.visible = false
		
	# 1. 记录位置
	save_original_transforms()
	
	# 2. 打散
	scatter_parts()
	
	# 3. 监听信号
	if GameManager:
		GameManager.all_collected.connect(start_performance)
	
	# 👇 测试用：3秒后自动开始 (测试完记得删掉！)
	# await get_tree().create_timer(3.0).timeout
	# start_performance()

func save_original_transforms():
	for part in parts_container.get_children():
		original_transforms.append({
			"pos": part.position,
			"rot": part.rotation,
			"node": part
		})

func scatter_parts():
	for part in parts_container.get_children():
		part.position = Vector3(
			randf_range(-15, 15),
			randf_range(5, 15), 
			randf_range(-15, 15)
		)
		part.rotation = Vector3(randf() * PI, randf() * PI, randf() * PI)
		part.visible = false 

func start_performance():
	print("🎬 终局演出开始！")
	
	# 1. 显示碎片
	for part in parts_container.get_children():
		part.visible = true
	
	# 2. 创建动画 Tween (碎片飞回)
	var tween = create_tween().set_parallel(true)
	
	for data in original_transforms:
		var part = data["node"]
		tween.tween_property(part, "position", data["pos"], 4.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(part, "rotation", data["rot"], 3.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 3. 等待碎片归位
	await tween.finished
	
	# 4. 🛠️ 融合时刻 (先融合，再出信)
	parts_container.visible = false
	full_painting.visible = true
	
	# (这里可以加那个烟花特效 spawn_fireworks())
	
	# 5. 等待 1 秒
	await get_tree().create_timer(1.0).timeout
	
	# 6. 信件 UI 淡入
	if letter_ui:
		letter_ui.visible = true
		
		# UI 动画：从透明浮现，并向上飘一点
		var ui_tween = create_tween()
		
		# 初始状态设置
		letter_ui.modulate.a = 0 # 完全透明
		# 这里的 offset 是 Control 节点的属性，如果报错，可以把下面这行删掉
		# 或者把 Panel 的 Layout Mode 改为 anchors preset，单纯做透明度动画也很好看
		# letter_ui.position.y += 50 
		
		# 执行淡入
		ui_tween.tween_property(letter_ui, "modulate:a", 1.0, 2.0)
		# ui_tween.parallel().tween_property(letter_ui, "position:y", letter_ui.position.y - 50, 2.0)
