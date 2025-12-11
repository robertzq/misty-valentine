extends GPUParticles3D

func _ready():
	emitting = true
	# 等粒子播完（根据 lifetime 自动计算）
	await finished 
	queue_free()
