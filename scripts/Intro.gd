extends Control

@onready var label = $Label
var lines = [
	"这是一个被时间遗忘的角落——迷雾峡谷。",
	"传闻中，只有集齐散落的记忆碎片，才能驱散这里的迷雾。",
	"前面的路充满了未知与怪物……",
	"但如果是为了寻找那幅画，我相信你一定可以。",
	"当心脚下。勇敢地去探索吧，乌拉。"
]

func _ready():
	play_story()

func play_story():
	for line in lines:
		label.text = line
		label.visible_ratio = 0.0
		
		# 打字效果：1秒内显示完一行字
		var tween = create_tween()
		tween.tween_property(label, "visible_ratio", 1.0, 2.0)
		
		await tween.finished
		await get_tree().create_timer(1.0).timeout # 读完停顿1秒
	
	# 故事讲完，显示开始按钮或直接进入游戏
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")
