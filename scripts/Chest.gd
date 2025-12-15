extends Area3D

var is_opened = false

func _ready():
	# 连接 body_entered 信号到这个脚本
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if is_opened: return
	
	# 只有玩家碰到，且分数够了才触发
	if body.name == "Player" and GameManager.current_score >= GameManager.TARGET_SCORE:
		open_chest()

func open_chest():
	is_opened = true
	print("🎁 宝箱开启！")
	
	# 播放开箱动画（如果有）
	# $AnimationPlayer.play("Open")
	
	# 触发最终演出信号
	GameManager.all_collected.emit()
	
	# 让宝箱消失或变样
	# queue_free()
