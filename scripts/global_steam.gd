extends Node

# 你的 Steam App ID (在 Steamworks 后台可以看到)
# 测试时可以用 480 (这是 Steam 的官方测试用 ID，叫 Spacewar)
# 正式上线前一定要改成你自己的！
const APP_ID: int = 480 

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
