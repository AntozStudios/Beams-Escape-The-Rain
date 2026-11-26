extends Node3D

signal collected(pickup: Node3D)

enum Kind { HEART, STAR }

const VISUAL_SIZE := 0.55

var kind: int
var player: MeshInstance3D
var origin_y := 0.0

func configure(pickup_kind: int, target: MeshInstance3D) -> void:
	kind = pickup_kind
	player = target
	set_meta("kind",kind)
	if kind == Kind.HEART:
		build_heart()
	else:
		build_star()

func build_heart() -> void:
	var color := Color(1,0.12,0.25)
	for side in [-1,1]:
		var lobe := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.16
		sphere.height = 0.32
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color
		sphere.material = material
		lobe.mesh = sphere
		add_child(lobe)
		lobe.position = Vector3(side*0.11,0.10,0)
	var point := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.23
	cone.bottom_radius = 0
	cone.height = 0.42
	cone.material = (get_child(0).mesh as SphereMesh).material
	point.mesh = cone
	add_child(point)
	point.position.y = -0.08
	point.rotation.z = PI

func build_star() -> void:
	var glyph := Label3D.new()
	glyph.text = "\u2605"
	glyph.font_size = 128
	glyph.pixel_size = VISUAL_SIZE / 128.0
	glyph.modulate = Color(1.0,0.82,0.12)
	glyph.outline_size = 4
	glyph.outline_modulate = Color(0.32,0.18,0.0)
	glyph.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(glyph)

func place(world_position: Vector3) -> void:
	position = world_position
	origin_y = world_position.y

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	position.y = origin_y + sin(Time.get_ticks_msec()*0.004+position.x)*0.12
	rotate_y(delta*1.8)
	var relative := player.to_local(global_position)
	if not get_meta("collected",false) and player.visible and absf(relative.x) < 0.7 and absf(relative.z) < 0.7 and absf(relative.y) < 1.1:
		collected.emit(self)
