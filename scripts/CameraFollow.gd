extends Camera3D

# 拖入你的主角节点 (CharacterBody3D)
@export var target_character: Node3D

# --- 🔧 参数区 ---
# 这里保持你觉得舒服的高度
@export var offset: Vector3 = Vector3(0, 20, 12) 

# 跟随速度。⚠️ 注意：如果你用 lerp 配合 delta，这个值建议在 5.0 到 10.0 之间
@export var smooth_speed: float = 5.0

func _ready():
	if target_character:
		# 1. 游戏开始瞬间，先把摄像机瞬移到正确位置
		global_position = target_character.global_position + offset
		
		# 2. 👁️ 关键修改：只在开始时“看”一次主角！
		# 确定好俯视的角度后，就锁死这个角度，之后移动时绝对不旋转。
		look_at(target_character.global_position)

func _physics_process(delta):
	if not target_character:
		return

	# 1. 计算理想位置
	var desired_position = target_character.global_position + offset
	
	# 2. 平滑移动过去 (只改变位置)
	global_position = global_position.lerp(desired_position, smooth_speed * delta)
	
	# ❌ 删掉了这里的 look_at()
	# 这样摄像机就会像一个安在滑轨上的镜头，极其平稳，绝对不晕。
