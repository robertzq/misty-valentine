extends Area3D

# 允许在编辑器里为每个碎片单独拖图片
@export var texture: Texture2D

# 获取你的模型 (用来换图)
@onready var mesh = $MeshInstance3D

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
	
	# 调用管家加分 (这一步我们马上做)
	if GameManager:
		GameManager.add_score()
	
	# 销毁自己
	queue_free()
