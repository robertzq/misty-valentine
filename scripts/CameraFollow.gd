extends Camera3D

# 在检查器里把你的主角节点拖进去
@export var target_character: CharacterBody3D

# 记录摄像机和主角的初始距离（偏移量）
var offset: Vector3

func _ready():
	# 游戏开始时，计算一下：“哦，我应该保持站在主角右上方这么多米的地方”
	if target_character:
		offset = global_position - target_character.global_position

func _process(delta):
	# 每一帧都瞬移到：主角当前位置 + 那个固定的偏移量
	if target_character:
		global_position = target_character.global_position + offset
