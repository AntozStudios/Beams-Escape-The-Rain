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
var sky_wash := ShaderMaterial.new()
var sections: Array[Section] = []
var map_id := Maps.CLASSIC
var campaign_level := 1
var stars_collected := 0
var level_complete := false
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
	var backdrop := CanvasLayer.new()
	backdrop.layer = -100
	add_child(backdrop)
	var sky := ColorRect.new()
	backdrop.add_child(sky)
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky_wash.shader = preload("res://art/sky_wash.gdshader")
	sky.material = sky_wash
	environment.background_mode = Environment.BG_CANVAS
	environment.background_canvas_max_layer = backdrop.layer
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#c5bed9")
	environment.ambient_light_energy = 0.68
	player = Section.box(self,START,Vector3.ONE,Color.WHITE)
	player.add_child(lamp)
	lamp.light_energy = 1.47
	lamp.omni_range = 6.44
	camera.size = 16
	create_stars()
	map_id = clampi(int(profile.value("map",Maps.CLASSIC)),0,Maps.NAMES.size()-1)
	campaign_level = clampi(int(profile.value("current_level_%d" % map_id,1)),1,Maps.MAX_LEVELS)
	level = campaign_level-1
	add_child(sunlight)
	sunlight.rotation_degrees = Vector3(-55,-30,0)
	sunlight.light_energy = 0.85
	sunlight.light_color = Color("#ffead1")
	add_section()
	player.position.y = sections.back().surface_y(cell) + 0.5
	update_descent_view()
	music = play("Harmony in Space",float(profile.value("Music",0.025)),true)
	ambience = play("rain1",0.18,true)
	apply_settings()
	ui.setup(self)

func create_stars() -> void:
	var stars := CPUParticles3D.new()
	camera.add_child(stars)
	var viewport_aspect := float(get_viewport().size.x) / maxf(1.0,float(get_viewport().size.y))
	stars.position = Vector3(0,0,-100)
	stars.amount = 24
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
	var sky_tint := profile.color("skyColor",3)
	var default_sky: bool = sky_tint == profile.ITEMS[3][3]
	sky_wash.set_shader_parameter("upper", Color("#a4b7dc") if default_sky else sky_tint.lightened(0.16))
	sky_wash.set_shader_parameter("lower", Color("#f6d8cd") if default_sky else sky_tint.lightened(0.48))
	music.volume_db = linear_to_db(float(profile.value("Music",0.025)))
	ui.set_vignette(float(profile.value("Vignette",0.5)))

func add_section() -> void:


	var section := Section.new()
	add_child(section)
	section.build(campaign_level,player,map_id)
	section.hit.connect(on_hit)
	section.heart_collected.connect(on_heart_collected)
	section.star_collected.connect(on_star_collected)
	sections.append(section)

func select_map(id: int) -> void:
	if started or dead or id < 0 or id >= Maps.NAMES.size():
		return
	map_id = id
	profile.save("map",id)
	campaign_level = clampi(int(profile.value("current_level_%d" % map_id,1)),1,Maps.MAX_LEVELS)
	profile.save("current_level_%d" % map_id,campaign_level)
	level = campaign_level-1
	reset_level()
	

func start_level(selected_level: int) -> void:
	if selected_level < 1 or selected_level > Maps.MAX_LEVELS:
		return
	var unlocked := clampi(maxi(int(profile.value("unlocked_%d" % map_id,Maps.INITIAL_UNLOCKED_LEVELS)),Maps.INITIAL_UNLOCKED_LEVELS),1,Maps.MAX_LEVELS)
	if selected_level > unlocked:
		return
	campaign_level = selected_level
	profile.save("current_level_%d" % map_id,campaign_level)
	level = campaign_level-1
	reset_level()
	armed = true
	ui.close()
	ui.refresh()

func reset_level() -> void:
	for section in sections:
		section.queue_free()
	sections.clear()
	cell = Vector2i.ZERO
	stars_collected = 0
	level_complete = false
	dead = false
	started = false
	armed = false
	lives = MAX_LIVES
	revivals = 0
	idle = 0
	locked_until = 0
	roll_elapsed = ROLL_TIME
	move_time = ROLL_TIME
	player.transform = Transform3D(Basis.IDENTITY,START)
	player.show()
	add_section()
	player.position.y = sections.back().surface_y(cell)+0.5
	update_descent_view()

func _unhandled_input(event: InputEvent) -> void:
	if not armed or dead or ui.modal_visible():
		return
	if event is InputEventKey and not event.pressed and not event.echo:
		var keys := {KEY_LEFT:Vector2.LEFT,KEY_RIGHT:Vector2.RIGHT,KEY_UP:Vector2.UP,KEY_DOWN:Vector2.DOWN,KEY_A:Vector2.LEFT,KEY_D:Vector2.RIGHT,KEY_W:Vector2.UP,KEY_S:Vector2.DOWN}
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
	if dead or level_complete or not armed or locked_until > 0 or roll_elapsed < move_time:
		return
	var platform: Section = sections.back()
	if platform.ride and platform.ride.is_running():
		return
	if absi(step.x)+absi(step.y) != 1:
		return
	var next := cell + step
	if not platform.plan.contains(next) and not platform.puzzle.is_branch(next):
		return
	if not platform.puzzle.can_cross(cell,next):
		return
	var roll_duration := maxf(0.075,ROLL_TIME*pow(0.97,float(level)))
	if not platform.puzzle.try_push(cell,next) or not platform.push_pallet(cell,next,roll_duration):
		return
	rise = platform.surface_y(next) + 0.5 - player.position.y
	if absf(rise) > 1.01:
		return
	move_time = roll_duration if is_zero_approx(rise) else roll_duration * 2
	cell = next
	direction = Vector3(step.x,0,-step.y)
	origin = player.position
	roll_elapsed = 0
	started = true
	# Hold the preview while the cube rolls down the step it revealed.
	if not (step == Vector2i.DOWN and rise < 0):
		update_descent_view()
	idle = 0
	play("player",0.075)
	ui.refresh()

func _physics_process(delta: float) -> void:
	if dead or level_complete:
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
			var current: Section = sections.back()
			if cell.y == current.plan.lift_row:
				current.ride_lift(cell)
			current.puzzle.landed(cell)
			if current.activate_seal(cell):
				play("checkPoint",0.06)
				ui.refresh()
			if cell == current.checkpoint_cell and current.opened == current.seals.size():
				sections.back().consume_checkpoint()
				level_complete = true
				locked_until = 0.0
				var unlocked := maxi(int(profile.value("unlocked_%d" % map_id,Maps.INITIAL_UNLOCKED_LEVELS)),Maps.INITIAL_UNLOCKED_LEVELS)
				profile.save("unlocked_%d" % map_id,mini(Maps.MAX_LEVELS,maxi(unlocked,campaign_level+1)))
				var star_key := "stars_%d_%d" % [map_id,campaign_level]
				profile.save(star_key,maxi(stars_collected,int(profile.value(star_key,0))))
				if campaign_level < Maps.MAX_LEVELS:
					profile.save("current_level_%d" % map_id,campaign_level+1)
				play("checkPoint",0.11)
				ui.show_level_complete()
				return
			update_descent_view()
	if started:
		var active: Section = sections.back()
		if cell in active.rest_cells or active.terrain_at(cell) != 0:
			ui.warning.text = ""
			idle = 0
			return
		idle += delta
		var grace: float = Section.GRACE[sections.back().terrain_at(cell)]
		ui.warning.text = "Sand sinks in %.1f" % maxf(0,10+grace-idle) if idle >= 8 else ""
		if idle >= 10 + grace:
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
	sunlight.light_energy = 0.85 + 0.045*sin(Time.get_ticks_msec()*0.00018)
	var target := player.position
	if map_id == Maps.CLASSIC:
		target.y = START.y if not started else player.position.y
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
	var forward := -camera.global_basis.z
	for wall in sections.back().tiles:
		var bounds: AABB = wall.global_transform * wall.mesh.get_aabb()
		var blocked := bounds.end.y > player.position.y-0.45 and bounds.grow(0.25).intersects_segment(player.position-forward*60,player.position-forward*0.6) != null
		wall.transparency = move_toward(wall.transparency,0.94 if blocked else 0.0,delta*7)

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
	if dead or level_complete:
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
	burst(player.position,Maps.RAIN_RED,18)
	ui.refresh()

func on_star_collected(star: Node3D) -> void:
	if level_complete or star.get_meta("collected",false):
		return
	stars_collected = mini(3,stars_collected+1)
	star.set_meta("collected",true)
	star.queue_free()
	var chime := play("checkPoint",0.065)
	chime.pitch_scale = 1.0 + 0.08*stars_collected
	burst(player.position,Color(1.0,0.82,0.12),6)
	ui.refresh()

func continue_level() -> void:
	if campaign_level >= Maps.MAX_LEVELS:
		return
	start_level(campaign_level+1)

func return_to_menu() -> void:
	reset_level()
	ui.close()
	ui.refresh()

func die() -> void:
	if dead or level_complete:
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
	sections.back().reset_lift()
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
