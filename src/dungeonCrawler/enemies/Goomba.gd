extends KinematicBody2D

export(PackedScene) var drop_scene
var fallback_drop_scenes = [
	preload("res://src/dungeonCrawler/items/Coin.tscn")
	]

onready var anim = $AnimatedSprite

func hit():
	kill()

func kill():
	anim.animation = "death"
	yield(get_tree().create_timer(0.4), "timeout")
	emit_drops()
	queue_free()


func emit_drop(scene):
	var drop = scene.instance()
	drop.position = transform.origin
	Navi.current_scene.call_deferred("add_child", drop)

	# eh? particles?
	# drop.apply_impulse(Vector2.ZERO, impulse_dir * arrow_impulse)

func emit_drops():
	if drop_scene:
		emit_drop(drop_scene)
	else:
		# todo choose one, more than one, randomly
		if fallback_drop_scenes.size():
			var drop = fallback_drop_scenes[0]
			emit_drop(drop)


var dir = Vector2.LEFT
var speed = 50
var velocity = dir * speed
func _physics_process(delta):
	var collision_info = move_and_collide(velocity * delta)
	if collision_info:
		velocity = velocity.bounce(collision_info.normal)
