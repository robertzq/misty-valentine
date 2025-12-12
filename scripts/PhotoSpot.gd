extends Area3D

var used = false # 只能用一次

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not used and body.has_method("heal"):
		body.heal(2) # 回2滴血
		used = true
		
		# 变暗或者消失，表示已经用过了
		$Sprite3D.modulate = Color(0.5, 0.5, 0.5) 
		
		# --- 🧭 指引功能 (简易版) ---
		show_guide_arrow()

func show_guide_arrow():
	# 找到所有的碎片
	var shards = get_tree().get_nodes_in_group("Shard") # 记得把你的碎片设为 "Shard" 组
	if shards.size() > 0:
		var nearest = shards[0]
		# 简单的寻找最近逻辑...
		# 然后在玩家头顶生成一个临时的箭头指向 nearest.global_position
		print("照片背面写着：下一个碎片在那个方向...")
