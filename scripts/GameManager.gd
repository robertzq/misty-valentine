extends Node

# 信号：当碎片数量变化时，发出通知（方便以后UI更新）
signal score_changed(current_score)
signal all_collected # 集齐9个的信号
signal signal_chest_unlocked #开宝箱信号
signal shard_collected_with_info(name)

var current_score = 0
const TARGET_SCORE = 9

func add_score():
	current_score += 1
	print("当前收集进度: ", current_score, "/", TARGET_SCORE)
	
	# 发出信号通知全世界
	score_changed.emit(current_score)
	
	if current_score >= TARGET_SCORE:
		print("🎉 碎片集齐了！去开宝箱吧！")
		# ⚠️ 注意：这里不再自动发射 all_collected 信号了
		# 我们可以发一个新的信号通知 UI 提示玩家
		signal_chest_unlocked.emit()
