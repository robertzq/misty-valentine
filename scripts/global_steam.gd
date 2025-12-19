extends Node

# 你的 Steam App ID (在 Steamworks 后台可以看到)
# 测试时可以用 480 (这是 Steam 的官方测试用 ID，叫 Spacewar)
# 正式上线前一定要改成你自己的！
const APP_ID: int = 4267110 

var is_on_steam: bool = false

func _ready() -> void:
	_initialize_steam()

func _initialize_steam() -> void:
	# 1. 检查是否是 Steam 环境
	# 如果初始化失败（比如玩家没开 Steam 客户端），这里会返回非 1 的状态
	var init_response = Steam.steamInitEx(false, APP_ID)
	
	if init_response['status'] == 0:
		is_on_steam = true
		print("[Steam] 连接成功！状态: %s" % str(init_response['verbal']))
		
		# 获取并打印当前玩家的名字，确认连接对了
		var steam_name = Steam.getPersonaName()
		print("[Steam] 当前玩家: %s" % steam_name)
	else:
		is_on_steam = false
		printerr("[Steam] 初始化失败: %s" % str(init_response['verbal']))
		# 商业游戏策略：如果初始化失败（说明没开Steam或盗版），通常选择直接退出游戏
		# get_tree().quit() 

	# 2. DRM 验证 (防盗版核心代码)
	# 检查玩家是否真的拥有这个游戏。
	# 如果玩家直接双击 exe 打开游戏，而没有通过 Steam 库启动，
	# 这个函数会告诉 Steam 客户端：“嘿，重新用 Steam 启动我！”并返回 true。
	if Steam.restartAppIfNecessary(APP_ID):
		print("[Steam] 正在通过 Steam 重启游戏...")
		get_tree().quit() # 立即关闭当前进程，等待 Steam 重新唤醒

func _process(_delta: float) -> void:
	if is_on_steam:
		# 3. 极其重要：运行回调
		# Steam 是异步的（比如成就解锁的弹窗、云存档上传），
		# 必须每一帧都“拉取”一下 Steam 的消息，否则成就弹窗出不来。
		Steam.run_callbacks()

# 解锁成就的通用函数
# 调用方法: unlock_achievement("ACH_GAME_START")
func unlock_achievement(api_name: String) -> void:
	if not is_on_steam:
		return

	# 1. 检查这个成就以前是否已经解锁过了（避免重复弹窗）
	# getAchievement 返回一个字典，里面有 'achieved' (bool) 字段
	var ach_data = Steam.getAchievement(api_name)
	
	if ach_data.has("ret") and ach_data["ret"]: # 确保查询成功
		if ach_data["achieved"]:
			print("[Steam] 成就已存在，跳过解锁: %s" % api_name)
			return
	
	# 2. 标记成就为已获得
	var set_result = Steam.setAchievement(api_name)
	
	if set_result:
		# 3. 极其重要！必须上传数据，否则 Steam 界面不会弹窗
		var store_result = Steam.storeStats()
		if store_result:
			print("[Steam] 成就解锁成功！弹窗即将出现: %s" % api_name)
		else:
			printerr("[Steam] 统计数据上传失败")
	else:
		printerr("[Steam] 无法设置成就（可能是 API Name 写错了）: %s" % api_name)

# --- 开发者测试专用工具 ---

# 重置所有成就（测试时很有用，不然你解锁一次就没法测第二次了）
func _debug_reset_all_stats() -> void:
	if not is_on_steam: return
	Steam.resetAllStats(true) # true 表示同时也清除成就
	Steam.storeStats()
	print("[Steam] 已重置所有成就和统计数据")
