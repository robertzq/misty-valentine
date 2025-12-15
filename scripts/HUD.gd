extends CanvasLayer

@onready var health_container = $HealthContainer # 对应刚才创建的容器
@onready var player = get_tree().get_first_node_in_group("Player")

# 定义两个颜色，分别代表"有血"和"没血"
# 比如：鲜红色 vs 暗灰色 (或者半透明)
var color_full = Color(1, 0.2, 0.2, 1) # 鲜红
var color_empty = Color(0.2, 0.2, 0.2, 0.5) # 暗灰半透明

@onready var score_panel = $ScorePanel 
@onready var score_label = $ScorePanel/Label

func _ready():
	if player:
		# 连接信号
		player.hp_changed.connect(_on_hp_changed)
		_on_hp_changed(player.current_hp)
		
	score_panel.visible = false
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.shard_collected_with_info.connect(_on_shard_collected_info)
	
func _on_score_changed(new_score):
	# 1. 如果它是第一次出现，让它显示出来
	if not score_panel.visible:
		score_panel.visible = true
		
		# (可选) 加个更有趣的弹窗动画：从很小"崩"的一下变大
		score_panel.scale = Vector2.ZERO # 先设为0大小
		# 使用 Tween 动画让它弹出来
		var tween = create_tween()
		tween.tween_property(score_panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 2. 更新文字内容
	# 拼凑出 "1 / 9" 这样的格式
	score_label.text = str(new_score) + " / " + str(GameManager.TARGET_SCORE)
	
	# 3. (可选) 给文字加个跳动效果，增加获得感
	var text_tween = create_tween()
	score_label.scale = Vector2(1.5, 1.5) # 文字瞬间变大
	text_tween.tween_property(score_label, "scale", Vector2.ONE, 0.1) # 缩回原大小
	

# 核心：更新血条显示
func _on_hp_changed(current_hp):
	var icons = health_container.get_children()
	
	for i in range(icons.size()):
		var icon = icons[i]
		
		if i < current_hp:
			# 索引小于当前血量，显示为有血
			icon.color = color_full 
			# 如果是 TextureRect，可以用 icon.modulate = color_full
		else:
			# 索引大于等于当前血量，显示为没血（背景色）
			icon.color = color_empty
func _on_shard_collected_info(shard_name):
	# 让奖杯面板弹出来
	score_panel.visible = true
	
	# 更新文字：不仅显示进度，还显示刚才获得了什么
	var current = GameManager.current_score
	var target = GameManager.TARGET_SCORE
	
	# 比如显示： "获得：快乐之碎片\n进度: 3 / 9"
	score_label.text = "获得: " + shard_name + ": " + str(current) + " / " + str(target)
	
	# 播放弹弹动画 (Boing effect)
	score_panel.pivot_offset = score_panel.size / 2 # 确保从中心缩放
	var tween = create_tween()
	tween.tween_property(score_panel, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(score_panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE)
