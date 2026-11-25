extends Node3D

const Section := preload("res://scripts/section.gd")
const Profile := preload("res://scripts/profile.gd")
const Mobile := preload("res://scripts/mobile.gd")
const ROLL_TIME := 90.0 / 800.0
const START := Vector3(0,-3.5,3.5)
var profile := Profile.new()
var mobile := Mobile.new()
var player: MeshInstance3D
var lamp := OmniLight3D.new()
var environment := Environment.new()
var sections: Array[Section] = []
var level := 0
var lives := 3
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
var touch_origin: Vector2
var touch_index := -1
var music: AudioStreamPlayer
var ambience: AudioStreamPlayer
@onready var ui = $Interface
@onready var camera: Camera3D = $Camera

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
	add_section()
	music = play("Harmony in Space",float(profile.value("Music",0.025)),true)
	ambience = play("rain1",0.5,true)
	apply_settings()
	ui.setup(self)

func create_stars() -> void:
	var stars := CPUParticles3D.new()
	camera.add_child(stars)
	stars.position = Vector3(-3.18966,3.10597,-42.15969)
	stars.amount = 50
	stars.lifetime = 5
	stars.gravity = Vector3.ZERO
	stars.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	stars.emission_box_extents = Vector3.ONE*5
	stars.scale_amount_min = 0.3
	stars.scale_amount_max = 1
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
	var surface := 2
	if not sections.is_empty():
		surface = (sections.back().rng.next_word() % 4) % 3
	var section := Section.new()
	add_child(section)
	section.build(level,surface,player)
	section.hit.connect(on_hit)
	sections.append(section)
	if sections.size() > 3:
		sections.pop_front().queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not armed or dead or ui.modal_visible():
		return
	if event is InputEventKey and not event.pressed and not event.echo:
		var keys := {KEY_LEFT:Vector2i.LEFT,KEY_RIGHT:Vector2i.RIGHT,KEY_UP:Vector2i.DOWN,KEY_DOWN:Vector2i.UP}
		if keys.has(event.keycode):
			move(keys[event.keycode])
	elif event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			touch_origin = event.position
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			var swipe: Vector2 = event.position - touch_origin
			if get_viewport().get_screen_transform().basis_xform(swipe).length() >= 100:
				if absf(swipe.x) > absf(swipe.y):
					move(Vector2i(signi(int(swipe.x)),0))
				else:
					move(Vector2i(0,-signi(int(swipe.y))))

func move(step: Vector2i) -> void:
	if dead or not armed or locked_until > 0 or roll_elapsed < ROLL_TIME:
		return
	var next := cell + step
	if absi(next.x) > 3 or (step.y != 0 and (next.y < 0 or next.y > 7)):
		return
	cell = next
	direction = Vector3(step.x,0,-step.y)
	origin = player.position
	roll_elapsed = 0
	started = true
	idle = 0
	play("player",0.11)
	ui.refresh()

func _physics_process(delta: float) -> void:
	if dead:
		return
	locked_until = maxf(0,locked_until-delta)
	if roll_elapsed < ROLL_TIME:
		roll_elapsed = minf(ROLL_TIME,roll_elapsed+delta)
		var pivot := origin + (direction + Vector3.DOWN)*0.5
		var rotation_axis := Vector3.UP.cross(direction)
		var rotation_basis := Basis(rotation_axis,PI*0.5*roll_elapsed/ROLL_TIME)
		player.transform = Transform3D(rotation_basis,pivot+rotation_basis*(origin-pivot))
		if roll_elapsed >= ROLL_TIME:
			player.transform = Transform3D(Basis.IDENTITY,origin+direction)
			if cell == Vector2i(0,7):
				sections.back().consume_checkpoint()
				level += 1
				cell.y = -1
				locked_until = 1.28333
				play("checkPoint",0.11)
				add_section()
				ui.refresh()
	if started:
		idle += delta
		var grace: float = Section.GRACE[sections.back().terrain]
		ui.warning.text = "Move or Die: %.1f" % maxf(0,3+grace-idle) if idle >= 3 else ""
		if idle >= 3 + grace:
			die()

func _process(delta: float) -> void:
	var target := Vector3(player.position.x-19.61,21,player.position.z+24.5)
	var follow := float(profile.value("Follow Player",1))
	camera.position = camera.position.lerp(target,clampf(delta*follow,0,1)) if follow > 0 else target

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
	roll_elapsed = ROLL_TIME
	locked_until = 0
	idle = 0
	player.show()
	mobile.banner(false)
	ui.close()
	ui.refresh()
