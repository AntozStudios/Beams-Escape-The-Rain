extends Node3D

signal collected(pickup: Node3D)

enum Kind { HEART, STAR }

const HEART_MESH := preload("res://art/models/heart.obj")
const STAR_MESH := preload("res://art/models/star.obj")

var kind: int
var player: MeshInstance3D
var origin_y := 0.0
var spin_angle := 0.0

func configure(pickup_kind: int, target: MeshInstance3D) -> void:
	kind = pickup_kind
	player = target
	set_meta("kind",kind)
	var model := MeshInstance3D.new()
	model.mesh = HEART_MESH if kind == Kind.HEART else STAR_MESH
	add_child(model)

func place(world_position: Vector3) -> void:
	position = world_position
	origin_y = world_position.y

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	position.y = origin_y + sin(Time.get_ticks_msec()*0.004+position.x)*0.12
	spin_angle = fmod(spin_angle + delta*0.65,TAU)
	rotation.y = spin_angle if kind == Kind.STAR else 0.12*sin(spin_angle*2)
	var relative := player.to_local(global_position)
	if not get_meta("collected",false) and player.visible and absf(relative.x) < 0.7 and absf(relative.z) < 0.7 and absf(relative.y) < 1.1:
		collected.emit(self)
