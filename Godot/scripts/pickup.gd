extends Node3D

signal collected(pickup: Node3D)

enum Kind { HEART, STAR }

const Maps := preload("res://scripts/maps.gd")
const VISUAL_SIZE := 0.55
const HEART_ROWS := [".###.###.", "#########", "#########", ".#######.", "..#####..", "...###..."]
const STAR_ROWS := ["....##....", "....##....", "...####...", "##########", ".########.", "..######..", "..######..", ".###..###.", ".##....##."]

static var star_mesh: ArrayMesh
static var heart_mesh: ArrayMesh

var kind: int
var player: MeshInstance3D
var origin_y := 0.0
var spin_angle := 0.0

func configure(pickup_kind: int, target: MeshInstance3D) -> void:
	kind = pickup_kind
	player = target
	set_meta("kind",kind)
	var model := MeshInstance3D.new()
	if kind == Kind.HEART:
		if heart_mesh == null:
			heart_mesh = block_mesh(HEART_ROWS,Maps.RAIN_RED)
		model.mesh = heart_mesh
	else:
		if star_mesh == null:
			star_mesh = block_mesh(STAR_ROWS,Color("#ffce65"))
		model.mesh = star_mesh
	model.rotation_degrees = Vector3(-8,14,0)
	add_child(model)

static func block_mesh(rows: Array, color: Color) -> ArrayMesh:
	var width: int = rows[0].length()
	var unit := VISUAL_SIZE / width
	var bar := BoxMesh.new()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	surface.set_material(material)
	# Merge each horizontal run into a bar; cache the whole silhouette as one mesh.
	for y in rows.size():
		var row: String = rows[y]
		var x := 0
		while x < width:
			if row[x] != "#":
				x += 1
				continue
			var start := x
			while x < width and row[x] == "#":
				x += 1
			bar.size = Vector3((x-start)*unit,unit,unit*2)
			var center := Vector3((start+x-width)*0.5,(rows.size()-1)*0.5-y,0)*unit
			surface.append_from(bar,0,Transform3D(Basis.IDENTITY,center))
	return surface.commit()

func place(world_position: Vector3) -> void:
	position = world_position
	origin_y = world_position.y

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	position.y = origin_y + sin(Time.get_ticks_msec()*0.004+position.x)*0.12
	var camera := get_viewport().get_camera_3d()
	if camera:
		spin_angle = fmod(spin_angle + delta*0.65,TAU)
		var tilt := spin_angle if kind == Kind.STAR else 0.12*sin(spin_angle*2)
		global_basis = camera.global_basis.orthonormalized() * Basis(Vector3.BACK,tilt)
	var relative := player.to_local(global_position)
	if not get_meta("collected",false) and player.visible and absf(relative.x) < 0.7 and absf(relative.z) < 0.7 and absf(relative.y) < 1.1:
		collected.emit(self)
