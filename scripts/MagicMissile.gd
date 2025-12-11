extends Area3D

var speed = 1.0 # 辉石魔法通常很快
var damage = 1

func _ready():
	# 3秒后自动销毁，防止子弹飞到天边占内存
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta):
	# 向前飞行 (Z轴负方向)
	position += transform.basis.z * speed * delta
	# --- 暴力手动检测 ---
	# 获取当前重叠的所有 Body
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.name == "Player": continue # 忽略自己
		
		if body.has_method("take_damage"):
			print("暴力检测打中了: ", body.name)
			body.take_damage(1)
			explode()
			break # 打中一个就销毁，别穿透

func _on_body_entered(body):
	if body.name == "Player": 
		return
	# 调试：看看撞到了谁
	print("子弹撞到了: ", body.name)
	
	
	# 碰到敌人 (假设敌人有 take_damage 方法)
	if body.has_method("take_damage"):
		body.take_damage(damage)
		explode()
	else:
		explode()

func explode():
	# 这里以后可以加一个“爆炸特效”场景
	# var explosion = load("res://scenes/Explosion.tscn").instantiate()
	# get_parent().add_child(explosion)
	# explosion.global_position = global_position
	
	queue_free() # 立即销毁自己
