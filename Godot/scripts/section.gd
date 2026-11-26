extends Node3D

signal hit(harmful: bool, point: Vector3)
signal heart_collected(heart: Node3D)
signal star_collected(star: Node3D)


const SPAWN_HEIGHT := 25.0
const GROUND := -4.0
const Maps := preload("res://scripts/maps.gd")
const Pickup := preload("res://scripts/pickup.gd")
var plan := Maps.new()
var tiles: Array[MeshInstance3D] = []
const GRACE := [2.0, 4.0, 6.0]
const HEART := Pickup.Kind.HEART
const STAR := Pickup.Kind.STAR
var lift_deck: MeshInstance3D
var lift_high := false
var ride: Tween
var mirrored: bool

var length := 8
var landing_heights := PackedFloat32Array()
var player: MeshInstance3D
var checkpoint: MeshInstance3D
var rest_cells: Array[Vector2i] = []
var seals: Array[Vector2i] = []
var seal_marks: Array[Label3D] = []
var opened := 0
var warnings: Dictionary = {}
var checkpoint_cell := Vector2i.ZERO
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
	if cell.y == plan.lift_row and plan.contains(cell):
		return plan.heights[cell.y + (1 if lift_high else -1)]
	return plan.heights[cell.y] if plan.contains(cell) else -3

func surface_y(cell: Vector2i) -> float:
	return GROUND + elevation(cell)

func terrain_at(cell: Vector2i) -> int:
	return plan.surfaces[cell.y]

func build(index: int, actor: MeshInstance3D, world: int) -> void:
	player = actor
	plan.generate(world,index)
	length = plan.centers.size()
	mirrored = index%2 == 1
	rng.reset(index)
	var base := self
	checkpoint_cell = plan.center_at(length-1)
	rest_cells.assign([Vector2i.ZERO,plan.center_at(length/2),checkpoint_cell])
	var meshes: Array[BoxMesh] = []
	for kind in Maps.COLORS.size():
		var mesh := BoxMesh.new()
		var material := StandardMaterial3D.new()
		material.albedo_color = Maps.COLORS[kind]
		if kind == 1:
			var water := ShaderMaterial.new()
			water.shader = preload("res://art/water.gdshader")
			mesh.material = water
		else:
			mesh.material = material
		meshes.append(mesh)
	for row in length:
		var center := plan.center_at(row)
		if row == plan.lift_row:
			var dock := Vector3(center.x,surface_y(center),3.5-row)
			lift_deck = box(base,dock-Vector3.UP*0.12,Vector3(1,0.24,1),Color("#8275a6"))
			for side in [-1,1]:
				box(lift_deck,Vector3(side*0.38,0.13,0),Vector3(0.08,0.025,0.85),Color("#ffda8f"))
			box(base,dock-Vector3.UP*1.7,Vector3(0.32,3,0.32),Color("#ad98ad"))
			continue
		for x in range(center.x-1,center.x+2):
			var tile := MeshInstance3D.new()
			tile.mesh = meshes[plan.surfaces[row]]
			base.add_child(tile)
			var depth := 1.5 + plan.heights[row]
			tile.scale = Vector3(0.99,depth,0.99)
			tile.position = Vector3(x,surface_y(center)-depth/2,3.5-row)
			tiles.append(tile)
	for i in range(4):
		var cell := plan.center_at((i+1)*(length-1)/5)
		cell.x += 1 if i%2 == 0 else -1
		create_pickup(base,HEART if i == 1 else STAR,cell,0.85)
	if index%3 == 2:
		for row: int in [length-3,2]:
			var cell := plan.center_at(row)
			seals.append(cell)
			rest_cells.append(cell)
			var mark := Label3D.new()
			mark.text = str(seals.size())
			mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			base.add_child(mark)
			mark.position = Vector3(cell.x,surface_y(cell)+0.6,3.5-row)
			seal_marks.append(mark)
	for cell in rest_cells:
		if cell != checkpoint_cell and cell.y != plan.lift_row:
			var plate := box(base,Vector3(cell.x,surface_y(cell)+0.025,3.5-cell.y),Vector3(0.62,0.05,0.62),Color("#b5f3de"))
			plate.rotation.y = PI/4
	build_scenery(base)
	var rain_meshes: Array[BoxMesh] = []
	for rain_color: Color in [Color("#8595b4"),Maps.RAIN_RED]:
		var rain_mesh := BoxMesh.new()
		rain_mesh.size = Vector3(0.2,0.5,0.2)
		var material := StandardMaterial3D.new()
		material.albedo_color = rain_color
		material.emission_enabled = true
		material.emission = rain_color
		material.emission_energy_multiplier = 0.25
		rain_mesh.material = material
		rain_meshes.append(rain_mesh)
	for x in range(-3,4):
		for row in length:
			var point := Vector3(x, GROUND - 0.5, 3.5 - row)
			if not plan.contains(Vector2i(x,row)) or Vector2i(x,row) in rest_cells or rng.next_word() % 5 != 0:
				continue
			var red := rng.next_word() % 2

			var drop := MeshInstance3D.new()
			drop.mesh = rain_meshes[red]
			drop.position = Vector3(x,SPAWN_HEIGHT,point.z)
			add_child(drop)
			if red:
				var marker := box(base,Vector3(x,GROUND+elevation(Vector2i(x,row))+0.025,point.z),Vector3(0.35,0.018,0.35),Color("#bd394c"))
				marker.rotation.y = PI/4
				marker.hide()
				warnings[drops.size()] = marker
			drops.append(drop)
			landing_heights.append(GROUND + elevation(Vector2i(x,row)))
			harmful.append(red)
			speeds.append(rng.rain_speed())
			velocities.append(0)
	checkpoint = box(base, Vector3(checkpoint_cell.x, GROUND+elevation(checkpoint_cell)+0.025,3.5-checkpoint_cell.y), Vector3(1,0.025,1), Color.WHITE)
	if not seals.is_empty():
		checkpoint.mesh.material.albedo_color = Color("#766689")
	checkpoint.mesh.material.albedo_texture = preload("res://art/EndTop.png")

func ride_lift(cell: Vector2i) -> void:
	lift_high = not lift_high
	var top := surface_y(cell)
	ride = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	ride.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ride.tween_property(lift_deck,"position:y",top-0.12,0.85)
	ride.tween_property(player,"position:y",top+0.5,0.85)

func reset_lift() -> void:
	if ride:
		ride.kill()
	lift_high = false
	lift_deck.position.y = surface_y(plan.center_at(plan.lift_row))-0.12

func activate_seal(cell: Vector2i) -> bool:
	if opened >= seals.size() or cell != seals[opened]:
		return false
	seal_marks[opened].text = "\u2713"
	opened += 1
	if opened == seals.size():
		checkpoint.mesh.material.albedo_color = Color.WHITE
	return true

func build_scenery(base: Node3D) -> void:
	for i in range(2):
		var island := Node3D.new()
		base.add_child(island)
		island.position = Vector3(8 + (i%2)*3,GROUND-2,2-i*10)
		box(island,Vector3.DOWN*2,Vector3(2.7,4,2.4),Color("#b5a2b5"))
		box(island,Vector3.ZERO,Vector3(2.8,0.22,2.5),Color("#c5d6af"))
		if (i == 0) == mirrored:
			box(island,Vector3.UP*0.6,Vector3(0.23,1.2,0.23),Color("#a77d72"))
			var crown := MeshInstance3D.new()
			var leaves := SphereMesh.new()
			leaves.radial_segments = 6
			leaves.rings = 3
			var leaf_material := StandardMaterial3D.new()
			leaf_material.albedo_color = Color("#eeb5ab")
			leaves.material = leaf_material
			crown.mesh = leaves
			crown.scale = Vector3(1.8,2.1,1.8)
			island.add_child(crown)
			crown.position.y = 1.6
		else:
			for x in [-0.7,0.7]:
				box(island,Vector3(x,1,0),Vector3(0.38,2,1.2),Color("#f0cda8"))
			box(island,Vector3.UP*2.1,Vector3(2.2,0.32,1.65),Color("#c7919b"))
			box(island,Vector3.UP*2.38,Vector3(1.65,0.24,1.2),Color("#ddacaa"))

func create_pickup(base: Node3D, kind: int, cell: Vector2i, height_offset: float) -> void:
	var pickup := Pickup.new()
	pickup.configure(kind,player)
	base.add_child(pickup)
	pickup.place(Vector3(cell.x,GROUND+elevation(cell)+height_offset,3.5-cell.y))
	pickup.collected.connect(_on_pickup_collected)

func _on_pickup_collected(pickup: Node3D) -> void:
	if int(pickup.get_meta("kind")) == HEART:
		heart_collected.emit(pickup)
	else:
		star_collected.emit(pickup)

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
		if warnings.has(i):
			warnings[i].visible = drop.position.y - landing_heights[i] < velocities[i]*0.8 + 1.0
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
		if warnings.has(i):
			warnings[i].hide()
		waiting += 1
	if waiting == drops.size():
		for i in drops.size():
			drops[i].position.y = SPAWN_HEIGHT
			velocities[i] = 0
			drops[i].show()
		waiting = 0
