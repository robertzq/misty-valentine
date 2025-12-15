extends Area3D

# 允许在编辑器里为每个碎片单独拖图片
@export var texture: Texture2D
@export var shard_name: String = "一个碎片" 
@export var shard_icon: Texture2D # 如果你想弹窗里显示不同的图标
# 获取你的模型 (用来换图)
@onready var mesh = $MeshInstance3D
@onready var fog_volume_node = $FogVolume # 假设碎片子节点有个FogVolume用来制造迷雾

func _ready():
	# 1. 自动连接碰撞信号
	body_entered.connect(_on_body_entered)
	
	# 2. 如果你在编辑器里配了图，就换上去
	if texture:
		# 获取材质的唯一副本 (重要！否则改一个全变了)
		var mat = mesh.get_active_material(0).duplicate()
		
		# 把图片贴上去 (既是颜色，也是发光纹理)
		mat.albedo_texture = texture
		mat.emission_texture = texture
		mat.emission_enabled = true
		mat.emission_energy = 0.5 # 亮度，觉得暗就改大点
		
		# 赋值回去
		mesh.material_override = mat

func _on_body_entered(body):
	# 只有名字叫 "Player" 的节点能捡起
	# (如果你之前的模型叫 Mage，记得去 World 场景里把根节点名字改回 Player)
	if body.name == "Player":
		collect()

func collect():
	print("✨ 捡到了碎片！")
	# 如果是简单的做法：直接让制造雾气的节点消失，或者播放一个粒子特效驱散雾气
	if fog_volume_node:
		# 比如做一个淡出的动画然后删除
		var tween = create_tween()
		tween.tween_property(fog_volume_node, "density", 0.0, 1.0)
		tween.tween_callback(fog_volume_node.queue_free)
	# 调用管家加分
	if GameManager:
		GameManager.add_score()
		GameManager.shard_collected_with_info.emit(shard_name)
	
	# 销毁自己
	queue_free()
