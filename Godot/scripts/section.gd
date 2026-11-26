extends Node3D

signal hit(harmful: bool, point: Vector3)
signal heart_collected(heart: Node3D)
signal star_collected(star: Node3D)

const WIDTH := 7
const SPAWN_HEIGHT := 25.0
const GROUND := -4.0
const Maps := preload("res://scripts/maps.gd")
const Pickup := preload("res://scripts/pickup.gd")
const TERRAIN := Maps.TERRAIN_COLORS
const GRACE := [2.0, 4.0, 6.0]
const HEART := Pickup.Kind.HEART
const STAR := Pickup.Kind.STAR
var terrain: int
var map_id: int
var campaign: int
var level_index: int
var mirrored: bool
var variation: int
var length := 8
var landing_heights := PackedFloat32Array()
var player: MeshInstance3D
var checkpoint: MeshInstance3D
var rest_cells: Array[Vector2i] = []
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
	return Maps.elevation(map_id,cell,mirrored,variation,length)

func surface_y(cell: Vector2i) -> float:
	return position.y + GROUND + elevation(cell)

func terrain_at(cell: Vector2i) -> int:
	return Maps.terrain_for_cell(campaign,level_index,cell,map_id,mirrored,length)

func build(index: int, surface: int, actor: MeshInstance3D, layout: int = Maps.CLASSIC, campaign_id: int = Maps.CLASSIC_CAMPAIGN) -> void:
	player = actor
	terrain = surface
	map_id = layout
	campaign = campaign_id
	level_index = index
	variation = index % 3
	mirrored = index % 2 == 1
	length = Maps.section_length(index)
	rng.reset(index)
	checkpoint_cell = choose_checkpoint()
	var base := Node3D.new()
	add_child(base)
	var floor_center_z := 4.0 - float(length)*0.5
	if map_id == Maps.CLASSIC:
		box(base, Vector3(0,-10,floor_center_z), Vector3(WIDTH,10,length), Color("#ab889f"))
		box(base,Vector3(0,GROUND-0.5,floor_center_z),Vector3(WIDTH,1,length),TERRAIN[terrain])
	else:
		build_mountain(base)
	var path := checkpoint_route()
	rest_cells.assign([Vector2i.ZERO, checkpoint_cell])
	for fraction in [0.33, 0.67]:
		var rest := path[roundi((path.size()-1)*float(fraction))]
		rest_cells.append(rest)
	for rest in rest_cells:
		if rest != checkpoint_cell:
			var marker := box(base,Vector3(rest.x,GROUND+elevation(rest)+0.012,3.5-rest.y),Vector3(0.48,0.02,0.48),Color("#d1ffe6"))
			marker.rotation.y = PI/4
	var rain_meshes: Array[BoxMesh] = []
	for rain_color: Color in [Color("#8595b4"),Color("#c64052")]:
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
			if Vector2i(x,row) in rest_cells:
				continue
			var red := rng.next_word() % 2
			if map_id == Maps.RIDGE and x == 0 and row == length/2:
				red = 1
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
	checkpoint.mesh.material.albedo_texture = preload("res://art/EndTop.png")
	spawn_heart(base)
	spawn_stars(base)
	if index > 1:
		base.position.y = -10.47
		create_tween().set_trans(Tween.TRANS_SINE).tween_property(base,"position:y",0,0.5)

func build_mountain(base: Node3D) -> void:
	var column_meshes: Array[BoxMesh] = []
	for terrain_id in TERRAIN.size():
		var stone := StandardMaterial3D.new()
		stone.albedo_color = Maps.TERRAIN_SIDE_COLORS[terrain_id]
		var column_mesh := BoxMesh.new()
		column_mesh.material = stone
		column_meshes.append(column_mesh)
	var cap_meshes := {}
	for row in length:
		for x in range(-3,4):
			var cell := Vector2i(x,row)
			var height := elevation(cell)
			var terrain_id := terrain_at(cell)
			var top := GROUND + height
			var depth := top - 0.18 + 15.0
			var column := MeshInstance3D.new()
			column.mesh = column_meshes[terrain_id]
			base.add_child(column)
			column.add_to_group("mountain_wall")
			column.set_meta("occlusion_alpha",1.0)
			column.scale.y = depth
			column.position = Vector3(x,top-0.18-depth/2.0,3.5-row)
			var cap_key := terrain_id * 16 + height
			if not cap_meshes.has(cap_key):
				var cap := BoxMesh.new()
				cap.size = Vector3(1,0.18,1)
				var material := StandardMaterial3D.new()
				var color: Color = TERRAIN[terrain_id].lightened(clampf(height*0.09,0,0.4))
				if height == 6:
					color = Color("#c4b2cf")
				material.albedo_color = color
				if terrain_id == 1:
					var water := ShaderMaterial.new()
					water.shader = preload("res://art/water.gdshader")
					cap.material = water
				else:
					cap.material = material
				cap_meshes[cap_key] = cap
			var tile := MeshInstance3D.new()
			tile.mesh = cap_meshes[cap_key]
			base.add_child(tile)
			tile.add_to_group("mountain_wall")
			tile.set_meta("occlusion_alpha",1.0)
			tile.position = Vector3(x,top-0.09,3.5-row)

func spawn_stars(base: Node3D) -> void:
	var cells := pickup_route_cells()
	if cells.size() < 4:
		return
	for i in [0,2,3]:
		create_pickup(base,STAR,cells[i],0.95)

func spawn_heart(base: Node3D) -> void:
	var cells := pickup_route_cells()
	if cells.size() < 4:
		return
	create_pickup(base,HEART,cells[1],0.85)

func pickup_route_cells() -> Array[Vector2i]:
	var route := checkpoint_route()
	var cells: Array[Vector2i] = []
	if route.size() < 10:
		return cells
	for i in range(4):
		var route_index := roundi(float(i)*float(route.size()-1)/3.0)
		var chosen := route[mini(route_index,route.size()-2)]
		# Allow a short, reversible detour from each star anchor.
		if i != 1:
			for step: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT]:
				var branch := chosen + step
				if absi(branch.x) <= 3 and branch != Vector2i.ZERO and not route.has(branch) and not cells.has(branch) and absi(elevation(branch)-elevation(chosen)) <= 1:
					chosen = branch
					break
		cells.append(chosen)
	return cells

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

func choose_checkpoint() -> Vector2i:
	var x_preferences := [-2,2,1,-1,0,3,-3]
	var preferred_x: int = x_preferences[posmod(level_index-1,x_preferences.size())]
	var preferred_row := length-1-posmod(level_index,2)
	var best_cell := Vector2i(0,length-1)
	var best_score := INF
	for row in range(length-2,length):
		for x in range(-3,4):
			var candidate := Vector2i(x,row)
			var route := route_to(candidate)
			if route.size() < 10:
				continue
			var score := float(absi(x-preferred_x)*3 + absi(row-preferred_row)*2) - float(route.size())*0.01
			if score < best_score:
				best_score = score
				best_cell = candidate
	return best_cell

func checkpoint_route() -> Array[Vector2i]:
	return route_to(checkpoint_cell)

func route_to(goal: Vector2i) -> Array[Vector2i]:
	var start := Vector2i.ZERO
	var frontier: Array[Vector2i] = [start]
	var parent := {start:start}
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_front()
		if cell == goal:
			var route: Array[Vector2i] = []
			while cell != start:
				route.push_front(cell)
				cell = parent[cell]
			return route
		for step: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next := cell + step
			if absi(next.x) > 3 or next.y < 0 or next.y >= length or parent.has(next):
				continue
			if absi(elevation(cell)-elevation(next)) > 1:
				continue
			parent[next] = cell
			frontier.append(next)
	return []

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
