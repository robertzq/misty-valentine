extends CanvasLayer

@onready var hp_bar = $ProgressBar # 假设你加了个进度条
@onready var player = get_tree().get_first_node_in_group("Player") # 确保给 Player 节点加个组叫 "Player"

func _ready():
	if player:
		hp_bar.max_value = player.max_hp
		hp_bar.value = player.current_hp
		# 连接玩家的信号
		player.hp_changed.connect(_on_hp_changed)

func _on_hp_changed(val):
	# 使用 Tween 做平滑扣血效果
	var tween = create_tween()
	tween.tween_property(hp_bar, "value", val, 0.3)
