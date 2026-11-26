extends Node3D

signal hit(harmful: bool, point: Vector3)

const WIDTH := 7
const LENGTH := 8
const SPAWN_HEIGHT := 25.0
const GROUND := -4.0
const Maps := preload("res://scripts/maps.gd")
const TERRAIN := [Color(0.79245, 0.78217, 0.34016), Color(0, 0.93382, 1), Color(0.07954, 0.92453, 0.02180)]
const GRACE := [2.0, 4.0, 6.0]
var terrain: int
var map_id: int
var mirrored: bool
var variation: int
var landing_heights := PackedFloat32Array()
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

func elevation(cell: Vector2i) -> int:
	return Maps.elevation(map_id,cell,mirrored,variation)

func surface_y(cell: Vector2i) -> float:
	return position.y + GROUND + elevation(cell)

func build(index: int, surface: int, actor: MeshInstance3D, layout: int = Maps.CLASSIC) -> void:
	player = actor
	terrain = surface
	map_id = layout
	variation = index % 3
	mirrored = index % 2 == 1
	position.z = -index * LENGTH
	rng.reset(index)
	var base := Node3D.new()
	add_child(base)
	if map_id == Maps.CLASSIC:
		box(base, Vector3(0,-10,0), Vector3(WIDTH,10,LENGTH), Color(0.415,0.415,0.415))
		box(base,Vector3(0,GROUND-0.5,0),Vector3(WIDTH,1,LENGTH),TERRAIN[terrain])
	else:
		build_mountain(base)
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
			if map_id == Maps.RIDGE and x == 0 and row == 4:
				red = 1
			var drop := MeshInstance3D.new()
			drop.mesh = rain_meshes[red]
			drop.position = Vector3(x,SPAWN_HEIGHT,point.z)
			add_child(drop)
			drops.append(drop)
			landing_heights.append(GROUND + elevation(Vector2i(x,row)))
			harmful.append(red)
			speeds.append(rng.rain_speed())
			velocities.append(0)
	checkpoint = box(base, Vector3(0, GROUND+elevation(Vector2i(0,7))+0.025,-3.5), Vector3(1,0.025,1), Color.WHITE)
	checkpoint.mesh.material.albedo_texture = preload("res://art/EndTop.png")
	if index > 0:
		base.position.y = -10.47
		create_tween().set_trans(Tween.TRANS_SINE).tween_property(base,"position:y",0,0.5)

func build_mountain(base: Node3D) -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = TERRAIN[terrain].darkened(0.48)
	var column_mesh := BoxMesh.new()
	column_mesh.material = stone
	var cap_meshes := {}
	for row in LENGTH:
		for x in range(-3,4):
			var height := elevation(Vector2i(x,row))
			var top := GROUND + height
			var depth := top - 0.18 + 15.0
			var column := MeshInstance3D.new()
			column.mesh = column_mesh
			base.add_child(column)
			column.add_to_group("mountain_wall")
			column.scale.y = depth
			column.position = Vector3(x,top-0.18-depth/2.0,3.5-row)
			if not cap_meshes.has(height):
				var cap := BoxMesh.new()
				cap.size = Vector3(1,0.18,1)
				var material := StandardMaterial3D.new()
				var color: Color = TERRAIN[terrain].lightened(clampf(height*0.09,0,0.4))
				if height == -3:
					color = stone.albedo_color
				elif height == 6:
					color = Color.SLATE_GRAY
				material.albedo_color = color
				cap.material = material
				cap_meshes[height] = cap
			var tile := MeshInstance3D.new()
			tile.mesh = cap_meshes[height]
			base.add_child(tile)
			tile.position = Vector3(x,top-0.09,3.5-row)

func consume_checkpoint() -> void:
	checkpoint.queue_free()
	var glow := box(self, checkpoint.position, Vector3(1,0.025,1), Color.WHITE)
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
		drop.position.y -= velocities[i] * delta
		var p := player.to_local(drop.global_position)
		var contact := player.visible and absf(p.x) <= 0.60 and absf(p.z) <= 0.60 and absf(p.y) <= 0.75
		if contact:
			hit.emit(bool(harmful[i]),drop.global_position)
		elif drop.position.y <= landing_heights[i] + 0.25:
			var splash := MeshInstance3D.new()
			splash.mesh = drop.mesh
			add_child(splash)
			splash.position = Vector3(drop.position.x,landing_heights[i]+0.025,drop.position.z)
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
