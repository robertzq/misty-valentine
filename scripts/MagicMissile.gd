extends Area3D

var speed = 15.0 # 辉石魔法通常很快
var damage = 1

func _ready():
	# 3秒后自动销毁，防止子弹飞到天边占内存
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta):
	# 向前飞行 (Z轴负方向)
	position -= transform.basis.z * speed * delta

func _on_body_entered(body):
	# 碰到墙壁
	if body.is_in_group("Wall") or body.name == "BigFloor": 
		explode()
	
	# 碰到敌人 (假设敌人有 take_damage 方法)
	if body.has_method("take_damage"):
		body.take_damage(damage)
		explode()

func explode():
	# 这里以后可以加一个“爆炸特效”场景
	# var explosion = load("res://scenes/Explosion.tscn").instantiate()
	# get_parent().add_child(explosion)
	# explosion.global_position = global_position
	
	queue_free() # 立即销毁自己
