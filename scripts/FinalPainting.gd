extends Node3D

@onready var parts = [$Part1, $Part2, $Part3, $Part4, $Part5, $Part6, $Part7, $Part8, $Part9]
@onready var full_painting = $FullPaintingMesh # 那个完整的画芯
@onready var fireworks = $Fireworks # 还没做，先留个位

func _ready():
	# 1. 游戏刚开始，先把这9个碎片炸散到天边去（隐藏起来或者放远点）
	# 既然我们要演出“飞来”，不如先把它们藏在摄像机背面，或者随机位置
	randomize_parts()
	
	# 监听大管家的信号：集齐了就开演！
	if GameManager:
		GameManager.all_collected.connect(start_performance)

func randomize_parts():
	for part in parts:
		# 让每个碎片随机散落在周围 10-20 米的地方，高度也随机
		var random_pos = Vector3(
			randf_range(-15, 15),
			randf_range(5, 15), # 从天而降比较帅
			randf_range(-15, 15)
		)
		part.position = random_pos
		part.rotation = Vector3(randf(), randf(), randf()) # 乱转
		part.hide() # 先藏着，等演出开始再显示

func start_performance():
	print("🎬 终局演出开始！")
	
	# 1. 显示碎片
	for part in parts:
		part.show()
	
	# 2. 创建动画补间 (Tween)
	var tween = create_tween().set_parallel(true) # 并行执行（所有碎片一起飞）
	
	# 让每个碎片飞回原点 (0,0,0 是相对于父节点的，也就是拼好的位置)
	for part in parts:
		# 移动动画
		tween.tween_property(part, "position", Vector3.ZERO, 3.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		# 旋转归位
		tween.tween_property(part, "rotation", Vector3.ZERO, 3.0).set_trans(Tween.TRANS_CUBIC)
	
	# 3. 等待碎片飞到位 (3秒后)
	await tween.finished
	
	# 4. 融合！隐藏碎片，显示整画
	for part in parts:
		part.hide()
	full_painting.show()
	
	# 5. 发光特效
	var mat = full_painting.get_active_material(0)
	if mat:
		mat.emission_enabled = true
		mat.emission_energy = 5.0 # 亮瞎
		
	# 6. 放烟花 & 弹信件 UI
	spawn_fireworks()
	# show_letter_ui() # 下一步做

func spawn_fireworks():
	# 这里实例化之前的 PurifyEffect 或者新的烟花粒子
	pass
