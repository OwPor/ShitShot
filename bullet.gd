extends Node3D

const SPEED = 1000

@onready var mesh = $MeshInstance3D
@onready var ray = $RayCast3D
@onready var gpu = $GPUParticles3D

func _process(delta):
	position += transform.basis * Vector3(0, 0, -SPEED) * delta
	
	if ray.is_colliding():
		mesh.visible = false
		gpu.emitting = true
		await get_tree().create_timer(1.0).timeout
		queue_free()

func _on_timer_timeout():
	queue_free()
