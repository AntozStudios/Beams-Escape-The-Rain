extends Node3D

const Section := preload("res://scripts/section.gd")
const Maps := preload("res://scripts/maps.gd")
const Profile := preload("res://scripts/profile.gd")
const Mobile := preload("res://scripts/mobile.gd")
const ROLL_TIME := 90.0 / 800.0
const START := Vector3(0,-3.5,3.5)
const CAMERA_OFFSET := Vector3(-19.61,24.5,24.5)
const DOWNHILL_VIEW := deg_to_rad(65.0)
var profile := Profile.new()
var mobile := Mobile.new()
var player: MeshInstance3D
var lamp := OmniLight3D.new()
var environment := Environment.new()
var sections: Array[Section] = []
var map_id := Maps.CLASSIC
var sunlight := DirectionalLight3D.new()
var level := 0
var lives := 3
const MAX_LIVES := 3
var revivals := 0
var armed := false
var started := false
var dead := false
var cell := Vector2i.ZERO
var idle := 0.0
var locked_until := 0.0
var roll_elapsed := ROLL_TIME
var origin: Vector3
var direction: Vector3
var rise := 0.0
var move_time := ROLL_TIME
var touch_origin: Vector2
var touch_view: Basis
var touch_index := -1
var music: AudioStreamPlayer
var ambience: AudioStreamPlayer
@onready var ui = $Interface
@onready var camera: Camera3D = $Camera
@onready var home_yaw := camera.rotation.y
@onready var camera_focus := camera.position - CAMERA_OFFSET
var orbit := 0.0
var target_orbit := 0.0
var occlusion_timer := 0.0

func _ready() -> void:
	add_child(mobile)
	mobile.reward.connect(revive)
	mobile.initialize(profile)
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	environment.background_mode = Environment.BG_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.212,0.227,0.259)
	environment.ambient_light_energy = 1
	player = Section.box(self,START,Vector3.ONE,Color.WHITE)
	player.add_child(lamp)
	lamp.light_energy = 1.47
	lamp.omni_range = 6.44
	create_stars()
	map_id = clampi(int(profile.value("map",Maps.CLASSIC)),0,Maps.NAMES.size()-1)
	add_child(sunlight)
	sunlight.rotation_degrees = Vector3(-55,-30,0)
	sunlight.light_energy = 0.85
	sunlight.visible = map_id != Maps.CLASSIC
	add_section()
	player.position.y = sections.back().surface_y(cell) + 0.5
	update_descent_view()
	music = play("Harmony in Space",float(profile.value("Music",0.025)),true)
	ambience = play("rain1",0.5,true)
	apply_settings()
	ui.setup(self)

func create_stars() -> void:
	var stars := CPUParticles3D.new()
	camera.add_child(stars)
	var viewport_aspect := float(get_viewport().size.x) / maxf(1.0,float(get_viewport().size.y))
	stars.position = Vector3(0,0,-100)
	stars.amount = 100
	stars.lifetime = 8
	stars.gravity = Vector3.ZERO
	stars.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	stars.emission_box_extents = Vector3(camera.size*viewport_aspect*0.58,camera.size*0.58,0.1)
	stars.scale_amount_min = 0.2
	stars.scale_amount_max = 0.55
	var sprite := QuadMesh.new()
	sprite.size = Vector2.ONE*0.1
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.material = material
	stars.mesh = sprite

func play(clip: String, volume: float, loop: bool = false) -> AudioStreamPlayer:
	var voice := AudioStreamPlayer.new()
	voice.stream = load("res://audio/%s.wav" % clip)
	voice.volume_db = linear_to_db(volume)
	add_child(voice)
	if loop:
		voice.finished.connect(voice.play)
	else:
		voice.finished.connect(voice.queue_free)
	voice.play()
	return voice

func apply_settings() -> void:
	var skin := profile.color("playerSkin",0)
	var material := player.mesh.material as StandardMaterial3D
	material.albedo_color = skin
	material.emission_enabled = true
	material.emission = skin
	lamp.light_color = skin
	environment.background_color = profile.color("skyColor",3)
	music.volume_db = linear_to_db(float(profile.value("Music",0.025)))
	ui.set_vignette(float(profile.value("Vignette",0.5)))

func add_section() -> void:
	var surface: int = Maps.SURFACES[map_id]
	if map_id == Maps.CLASSIC and not sections.is_empty():
		surface = (sections.back().rng.next_word() % 4) % 3
	var section := Section.new()
	add_child(section)
	section.build(level,surface,player,map_id)
	if not sections.is_empty():
		section.position.z = sections.back().position.z - sections.back().length
		section.position.y = sections.back().surface_y(Vector2i(0,sections.back().length-1)) - section.surface_y(Vector2i.ZERO)
	section.hit.connect(on_hit)
	section.heart_collected.connect(on_heart_collected)
	sections.append(section)
	if sections.size() > 3:
		sections.pop_front().queue_free()

func select_map(id: int) -> void:
	if started or dead or id == map_id or id < 0 or id >= Maps.NAMES.size():
		return
	map_id = id
	profile.save("map",id)
	var previous: Section = sections.pop_back()
	remove_child(previous)
	previous.queue_free()
	add_section()
	player.position.y = sections.back().surface_y(cell) + 0.5
	sunlight.visible = id != Maps.CLASSIC
	update_descent_view()

func _unhandled_input(event: InputEvent) -> void:
	if not armed or dead or ui.modal_visible():
		return
	if event is InputEventKey and not event.pressed and not event.echo:
		var keys := {KEY_LEFT:Vector2.LEFT,KEY_RIGHT:Vector2.RIGHT,KEY_UP:Vector2.UP,KEY_DOWN:Vector2.DOWN}
		if keys.has(event.keycode):
			move(screen_step(keys[event.keycode],camera.global_basis))
	elif event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			touch_origin = event.position
			touch_view = camera.global_basis
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			var swipe: Vector2 = event.position - touch_origin
			if get_viewport().get_screen_transform().basis_xform(swipe).length() >= 100:
				move(screen_step(swipe,touch_view))

# Match the input to the on-screen direction of each horizontal grid edge.
func screen_step(input_direction: Vector2, view: Basis) -> Vector2i:
	var best := Vector2i.ZERO
	var best_alignment := -INF
	for step: Vector2i in [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT]:
		var edge := Vector3(step.x,0,-step.y)
		var screen_edge := Vector2(edge.dot(view.x),-edge.dot(view.y)).normalized()
		var alignment := input_direction.dot(screen_edge)
		if alignment > best_alignment:
			best_alignment = alignment
			best = step
	return best

func move(step: Vector2i) -> void:
	if dead or not armed or locked_until > 0 or roll_elapsed < move_time:
		return
	if absi(step.x)+absi(step.y) != 1:
		return
	var next := cell + step
	if absi(next.x) > 3 or (step.y != 0 and (next.y < 0 or next.y >= sections.back().length)):
		return
	var target_section: Section = sections.back()
	if next.y == -1:
		if sections.size() < 2:
			return
		target_section = sections[-2]
	var target_row := target_section.length-1 if next.y == -1 else next.y
	rise = target_section.surface_y(Vector2i(next.x,target_row)) + 0.5 - player.position.y
	if absf(rise) > 1.01:
		return
	var current_roll_time := maxf(0.075,ROLL_TIME*pow(0.97,float(level)))
	move_time = current_roll_time if is_zero_approx(rise) else current_roll_time * 2
	cell = next
	direction = Vector3(step.x,0,-step.y)
	origin = player.position
	roll_elapsed = 0
	started = true
	# Hold the preview while the cube rolls down the step it revealed.
	if not (step == Vector2i.DOWN and rise < 0):
		update_descent_view()
	idle = 0
	play("player",0.11)
	ui.refresh()

func _physics_process(delta: float) -> void:
	if dead:
		return
	locked_until = maxf(0,locked_until-delta)
	if roll_elapsed < move_time:
		roll_elapsed = minf(move_time,roll_elapsed+delta)
		var current_roll_time := maxf(0.075,ROLL_TIME*pow(0.97,float(level)))
		var roll_phase := roll_elapsed / current_roll_time
		var lift := 0.0
		if rise > 0:
			lift = rise * smoothstep(0,1,roll_phase)
			roll_phase -= 1
		elif rise < 0:
			lift = rise * smoothstep(1,2,roll_phase)
		var pivot := origin + (direction + Vector3.DOWN)*0.5
		var rotation_axis := Vector3.UP.cross(direction)
		var rotation_basis := Basis(rotation_axis,PI*0.5*clampf(roll_phase,0,1))
		player.transform = Transform3D(rotation_basis,pivot+rotation_basis*(origin-pivot)+Vector3.UP*lift)
		if roll_elapsed >= move_time:
			player.transform = Transform3D(Basis.IDENTITY,origin+direction+Vector3.UP*rise)
			if cell == Vector2i(0,sections.back().length-1):
				sections.back().consume_checkpoint()
				level += 1
				cell.y = -1
				locked_until = 0.6
				play("checkPoint",0.11)
				add_section()
				ui.refresh()
			update_descent_view()
	if started:
		idle += delta
		var grace: float = Section.GRACE[sections.back().terrain]
		ui.warning.text = "Move or Die: %.1f" % maxf(0,3+grace-idle) if idle >= 3 else ""
		if idle >= 3 + grace:
			die()

func update_descent_view() -> void:
	var section: Section = sections.back()
	var ahead := cell + Vector2i.DOWN
	if map_id == Maps.CLASSIC or cell.y < 0 or ahead.y >= section.length:
		target_orbit = 0.0
		return
	if section.elevation(cell) - section.elevation(ahead) != 1:
		target_orbit = 0.0
		return

	# Inspect the two approaches to the landing. Nearer columns obstruct more.
	var obstruction := 0
	for distance in range(1,4):
		for row in range(cell.y,ahead.y+1):
			for side in [-1,1]:
				var probe := Vector2i(cell.x + side*distance,row)
				if absi(probe.x) > 3:
					continue
				var relief := section.elevation(probe) - section.elevation(ahead)
				obstruction += side * (4-distance) * maxi(0,relief+1)
	var view_side := -signi(obstruction)
	if view_side == 0:
		view_side = signi(cell.x)
		if view_side == 0:
			view_side = 1 if section.mirrored else -1
	target_orbit = view_side * DOWNHILL_VIEW - home_yaw

func _process(delta: float) -> void:
	var target := player.position
	if map_id == Maps.CLASSIC:
		target.y = START.y
	var follow := float(profile.value("Follow Player",1))
	camera_focus = camera_focus.lerp(target,clampf(delta*follow,0,1)) if follow > 0 else target
	orbit = lerp_angle(orbit,target_orbit,1.0-exp(-5.0*delta))
	camera.position = camera_focus + CAMERA_OFFSET.rotated(Vector3.UP,orbit)
	camera.rotation.y = home_yaw + orbit
	occlusion_timer -= delta
	if occlusion_timer <= 0:
		occlusion_timer = 0.04
		update_occluded_mountain_parts(delta+0.04)

func update_occluded_mountain_parts(delta: float) -> void:
	var occluded: Dictionary = {}
	if map_id != Maps.CLASSIC and player.visible:
		var ray := player.global_position-camera.global_position
		var distance_to_player := ray.length()-0.55
		if distance_to_player > 0:
			for section: Section in sections:
				for node: Node in section.find_children("*","MeshInstance3D",true,false):
					if not node.is_in_group("mountain_wall"):
						continue
					var wall := node as MeshInstance3D
					var bounds: AABB = wall.global_transform * wall.mesh.get_aabb()
					if bounds.end.y <= player.global_position.y-0.45:
						continue
					var hit: Variant = bounds.intersects_ray(camera.global_position,ray.normalized())
					if hit != null and camera.global_position.distance_to(hit) < distance_to_player:
						occluded[wall.get_instance_id()] = wall

	for section: Section in sections:
		for node: Node in section.find_children("*","MeshInstance3D",true,false):
			if not node.is_in_group("mountain_wall"):
				continue
			var wall := node as MeshInstance3D
			var alpha: float = float(wall.get_meta("occlusion_alpha"))
			var target_alpha := 0.06 if occluded.has(wall.get_instance_id()) else 1.0
			alpha = move_toward(alpha,target_alpha,delta*7.0)
			wall.set_meta("occlusion_alpha",alpha)
			wall.transparency = 1.0-alpha

func burst(point: Vector3, color: Color, count: int) -> void:
	var particles := CPUParticles3D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1
	particles.amount = count
	particles.lifetime = 0.65
	particles.direction = Vector3.UP
	particles.spread = 100
	particles.initial_velocity_min = 1
	particles.initial_velocity_max = 4
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE*0.12
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material = material
	particles.mesh = mesh
	add_child(particles)
	particles.position = point
	particles.finished.connect(particles.queue_free)
	particles.emitting = true

func on_hit(harmful: bool, point: Vector3) -> void:
	if dead:
		return
	burst(point, Color.RED if harmful else profile.color("playerSkin",0),12)
	if harmful:
		play("hissing",0.11)
		lives -= 1
		if lives <= 0:
			die()
		ui.refresh()

func on_heart_collected(heart: Node3D) -> void:
	if lives >= MAX_LIVES:
		return
	lives += 1
	heart.set_meta("collected",true)
	heart.queue_free()
	play("checkPoint",0.11)
	burst(player.position,Color(1,0.12,0.25),18)
	ui.refresh()

func die() -> void:
	if dead:
		return
	dead = true
	lives = 0
	player.hide()
	burst(player.position,profile.color("playerSkin",0),48)
	play("explosion",0.11)
	if level > profile.record():
		profile.save("HighScore",level)
		mobile.sync_score()
	ui.refresh()
	ui.show_death()
	mobile.banner(true)

func revive(amount: int) -> void:
	if not dead or amount < 1 or revivals >= 3:
		return
	revivals += 1
	dead = false
	lives = amount
	cell = Vector2i.ZERO
	player.transform = Transform3D(Basis.IDENTITY,START + sections.back().position)
	player.position.y = sections.back().surface_y(cell) + 0.5
	roll_elapsed = move_time
	update_descent_view()
	locked_until = 0
	idle = 0
	player.show()
	mobile.banner(false)
	ui.close()
	ui.refresh()
