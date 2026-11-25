extends Node3D

signal hit(harmful: bool, point: Vector3)

const WIDTH := 7
const LENGTH := 8
const SPAWN_HEIGHT := 25.0
const GROUND := -4.0
const TERRAIN := [Color(0.79245, 0.78217, 0.34016), Color(0, 0.93382, 1), Color(0.07954, 0.92453, 0.02180)]
const GRACE := [2.0, 4.0, 6.0]
var terrain: int
var player: MeshInstance3D
var checkpoint: MeshInstance3D
var drops: Array[MeshInstance3D] = []
var speeds := PackedFloat32Array()
var velocities := PackedFloat32Array()
var harmful := PackedByteArray()
var waiting := 0
var rng := preload("res://scripts/level_random.gd").new()

static func box(parent: Node3D, center: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = dimensions
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	shape.material = material
	body.mesh = shape
	parent.add_child(body)
	body.position = center
	return body

func build(index: int, surface: int, actor: MeshInstance3D) -> void:
	player = actor
	terrain = surface
	position.z = -index * LENGTH
	rng.reset(index)
	var base := Node3D.new()
	add_child(base)
	box(base, Vector3(0,-10,0), Vector3(WIDTH,10,LENGTH), Color(0.415,0.415,0.415))
	# Adjacent tiles share the same flat material and have no gaps.
	box(base,Vector3(0,GROUND-0.5,0),Vector3(WIDTH,1,LENGTH),TERRAIN[terrain])
	var rain_meshes: Array[BoxMesh] = []
	for rain_color: Color in [Color(0.188,0.193,0.206),Color.RED]:
		var rain_mesh := BoxMesh.new()
		rain_mesh.size = Vector3(0.2,0.5,0.2)
		var material := StandardMaterial3D.new()
		material.albedo_color = rain_color
		material.emission_enabled = true
		material.emission = rain_color
		rain_mesh.material = material
		rain_meshes.append(rain_mesh)
	for x in range(-3,4):
		for row in LENGTH:
			var point := Vector3(x, GROUND - 0.5, 3.5 - row)
			if x == 0 and (row == 0 or row == 7):
				continue
			var red := rng.next_word() % 2
			var drop := MeshInstance3D.new()
			drop.mesh = rain_meshes[red]
			drop.position = Vector3(x,SPAWN_HEIGHT,point.z)
			add_child(drop)
			drops.append(drop)
			harmful.append(red)
			speeds.append(rng.rain_speed())
			velocities.append(0)
	checkpoint = box(base, Vector3(0, GROUND+0.025,-3.5), Vector3(1,0.025,1), Color.WHITE)
	checkpoint.mesh.material.albedo_texture = preload("res://art/EndTop.png")
	if index > 0:
		base.position.y = -10.47
		create_tween().set_trans(Tween.TRANS_SINE).tween_property(base,"position:y",0,0.5)

func consume_checkpoint() -> void:
	checkpoint.queue_free()
	var glow := box(self, Vector3(0,GROUND+0.015,-3.5), Vector3(1,0.025,1), Color.WHITE)
	glow.mesh.material.albedo_texture = preload("res://art/EndTop.png")
	var pulse := create_tween().set_trans(Tween.TRANS_SINE)
	pulse.tween_property(glow,"scale",Vector3(1.5,1,1.5),0.6333)
	pulse.tween_property(glow,"scale",Vector3.ONE,0.65)
	pulse.tween_callback(glow.queue_free)

func _physics_process(delta: float) -> void:
	for i in drops.size():
		var drop := drops[i]
		if not drop.visible:
			continue
		# Unity applied acceleration multiplied by frame time before the physics step.
		velocities[i] += speeds[i] * delta / 50.0
		var previous := drop.global_position.y
		drop.position.y -= velocities[i] * delta
		var p := player.to_local(drop.global_position)
		var contact := player.visible and absf(p.x) <= 0.60 and absf(p.z) <= 0.60 and absf(p.y) <= 0.75
		if contact:
			hit.emit(bool(harmful[i]),drop.global_position)
		elif previous >= GROUND and drop.global_position.y <= GROUND + 0.25:
			var splash := MeshInstance3D.new()
			splash.mesh = drop.mesh
			add_child(splash)
			splash.position = Vector3(drop.position.x,GROUND+0.025,drop.position.z)
			splash.scale = Vector3(2.5,0.1,2.5)
			var timer := create_tween()
			timer.tween_interval(0.5)
			timer.tween_callback(splash.queue_free)
		else:
			continue
		drop.hide()
		waiting += 1
	if waiting == drops.size():
		for i in drops.size():
			drops[i].position.y = SPAWN_HEIGHT
			velocities[i] = 0
			drops[i].show()
		waiting = 0
