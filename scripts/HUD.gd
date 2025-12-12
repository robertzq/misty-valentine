extends CanvasLayer

@onready var health_container = $HealthContainer # 对应刚才创建的容器
@onready var player = get_tree().get_first_node_in_group("Player")

# 定义两个颜色，分别代表"有血"和"没血"
# 比如：鲜红色 vs 暗灰色 (或者半透明)
var color_full = Color(1, 0.2, 0.2, 1) # 鲜红
var color_empty = Color(0.2, 0.2, 0.2, 0.5) # 暗灰半透明

func _ready():
	if player:
		# 连接信号
		player.hp_changed.connect(_on_hp_changed)
		
		_on_hp_changed(player.current_hp)

	

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
