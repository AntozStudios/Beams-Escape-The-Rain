extends CanvasLayer

const LINKS := {
	"Terms of Service":"https://github.com/AntozStudios/Beams.terms.of.service.io",
	"Privacy Policy":"https://github.com/AntozStudios/Beams.privacy.policy.io",
	"Unity Privacy Policy":"https://unity.com/legal/privacy-policy",
	"Unity Player Account Portal":"https://player-account.unity.com/",
	"Request Data Deletion":"https://docs.google.com/forms/d/e/1FAIpQLSfYQv577GxlfGu2-TfwO2dK1BGCBTKrdjrMRmBy1uWm6SCDrQ/viewform?usp=dialog"
}
var game
var root := Control.new()
var navigation := VBoxContainer.new()
var start := Button.new()
var map_picker := OptionButton.new()
var life := Label.new()
var score := Label.new()
var warning := Label.new()
var shade := ColorRect.new()
var popup := ColorRect.new()
var content: VBoxContainer
var frame: ColorRect
var transition: Tween
var reward_button: Button
var account_text: Label
var sign_in_button: Button
var sign_out_button: Button

func setup(owner_game) -> void:
	game = owner_game
	root.theme = Theme.new()
	root.theme.default_font = preload("res://art/gomarice_goma_block.ttf")
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.material = ShaderMaterial.new()
	shade.material.shader = preload("res://art/vignette.gdshader")
	set_vignette(float(game.profile.value("Vignette",0.5)))
	root.add_child(start)
	start.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start.text = "Tap to Start"
	start.flat = true
	start.add_theme_font_size_override("font_size",28)
	start.pressed.connect(func(): game.armed = true; refresh())
	root.add_child(map_picker)
	map_picker.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	map_picker.offset_left = -145
	map_picker.offset_right = 145
	map_picker.offset_top = 36
	map_picker.offset_bottom = 84
	for i in game.Maps.NAMES.size():
		map_picker.add_item("%s · %s" % [game.Maps.NAMES[i],game.Maps.DIFFICULTY[i]],i)
	map_picker.select(game.map_id)
	map_picker.item_selected.connect(game.select_map)
	map_picker.focus_mode = Control.FOCUS_NONE
	root.add_child(navigation)
	navigation.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	navigation.offset_left = -74
	navigation.offset_right = -10
	navigation.offset_top = 10
	button(navigation,"?",instructions).modulate = Color(1,0.241,0.241)
	button(navigation,"A",items).modulate = Color(0.545,1,0.288)
	button(navigation,"P",account).modulate = Color(0,0.524,1)
	var store := button(navigation,"",func(): OS.shell_open("https://play.google.com/store/apps/details?id=com.AntozStudios.BeamsEscapeTheRain&hl=de"))
	store.icon = preload("res://art/PlayStoreIcon.png")
	store.expand_icon = false
	store.add_theme_constant_override("icon_max_width",18)
	store.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var gear := button(navigation,"",settings)
	gear.icon = preload("res://art/512x512.png")
	gear.expand_icon = false
	gear.add_theme_constant_override("icon_max_width",18)
	gear.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for option: Button in navigation.get_children():
		option.flat = true
		option.custom_minimum_size = Vector2(62,61)
	for label: Label in [life, score, warning]:
		root.add_child(label)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size",34)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	score.offset_top = 24
	score.add_theme_font_size_override("font_size",50)
	life.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	life.modulate = Color(0.81132,0.29238,0.29238)
	life.add_theme_font_size_override("font_size",84)
	life.offset_left = 18
	life.offset_top = 15
	warning.offset_top = 145
	warning.add_theme_font_size_override("font_size",22)
	root.add_child(popup)
	popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup.color = Color.TRANSPARENT
	popup.hide()
	refresh()

func set_vignette(intensity: float) -> void:
	if shade.material:
		shade.material.set_shader_parameter("intensity",intensity)

func modal_visible() -> bool:
	return popup.visible

func refresh() -> void:
	life.text = ".".repeat(game.lives)
	life.visible = game.armed and not game.dead
	score.text = str(game.level)
	score.visible = game.started and not game.dead
	start.visible = not game.armed
	map_picker.visible = not game.armed
	navigation.visible = not game.started
	if game.dead or not game.started:
		warning.text = ""

func button(parent: Control, caption: String, action: Callable) -> Button:
	var control := Button.new()
	control.text = caption
	control.focus_mode = Control.FOCUS_NONE
	control.custom_minimum_size.y = 46
	control.pressed.connect(action)
	parent.add_child(control)
	return control

func label(parent: Control, caption: String, size: int = 21) -> Label:
	var text := Label.new()
	text.text = caption
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size",size)
	parent.add_child(text)
	return text

func panel(title: String) -> void:
	if transition:
		transition.kill()
	popup.color = Color.TRANSPARENT
	for child in popup.get_children():
		popup.remove_child(child)
		child.queue_free()
	frame = ColorRect.new()
	popup.add_child(frame)
	frame.color = Color(0.217,0.217,0.217)
	frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var panel_size := Vector2(462,667).min(root.size-Vector2(16,16))
	frame.offset_left = -panel_size.x/2
	frame.offset_right = panel_size.x/2
	frame.offset_top = -panel_size.y/2
	frame.offset_bottom = panel_size.y/2
	var scroll := ScrollContainer.new()
	frame.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 32
	scroll.offset_right = -32
	scroll.offset_top = 18
	scroll.offset_bottom = -92
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content = VBoxContainer.new()
	scroll.add_child(content)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",16)
	if not title.is_empty():
		label(content,title,32)
	popup.show()
	var resting_y := frame.position.y
	frame.position.y += root.size.y
	transition = create_tween().set_trans(Tween.TRANS_SINE)
	transition.tween_property(frame,"position:y",resting_y,0.25)

func exit_button(action: Callable) -> void:
	var control := button(frame,"Exit",action)
	control.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	control.offset_left = -113
	control.offset_right = 113
	control.offset_top = -96
	control.offset_bottom = -30

func close() -> void:
	popup.hide()

func instructions() -> void:
	panel("")
	label(content,"Movement:\nSwipe in any direction to move the player. On mountain maps you can climb or descend one block per swipe. Find a way around taller cliffs.\n\nRain:\nRed rain: Avoid it – it's deadly!\n\nGround timer:\nStanding still will kill you!\nGrass: Max 6 seconds\nIce: Max 4 seconds\nSand: Max 2 seconds\n\nRewards:\nWatch up to 3 ads per game to receive 1 life each.")
	exit_button(close_animated)

func settings() -> void:
	panel("Settings")
	slider("Follow Player",10,1,1)
	slider("Vignette",0.5,0.01,0.5)
	slider("Music",0.07,0.001,0.025)
	exit_button(close_animated)

func slider(key: String, maximum: float, step: float, fallback: float) -> void:
	var value := float(game.profile.value(key,fallback))
	var heading := label(content,"%s  %.2f" % [key,value])
	var control := HSlider.new()
	control.max_value = maximum
	control.step = step
	control.value = value
	control.custom_minimum_size.y = 36
	content.add_child(control)
	control.value_changed.connect(func(v: float):
		heading.text = "%s  %.2f" % [key,v]
		game.profile.save(key,v)
		game.apply_settings())

func items(category: String = "") -> void:
	panel("Achievments")
	var filters := HBoxContainer.new()
	content.add_child(filters)
	for filter: String in ["All items","playerSkin","skyColor"]:
		button(filters,filter,items.bind("" if filter == "All items" else filter))
	for i in game.profile.ITEMS.size():
		var entry: Array = game.profile.ITEMS[i]
		if not category.is_empty() and entry[1] != category:
			continue
		var unlocked: bool = game.profile.record() >= entry[2]
		var item := button(content,"%s   %s" % [entry[0],"Use" if unlocked else "Highscore: %d" % entry[2]],equip.bind(i))
		item.disabled = not unlocked
		item.modulate = Color.PALE_GREEN if unlocked else Color.LIGHT_CORAL
	exit_button(close_animated)

func equip(index: int) -> void:
	if game.profile.use_item(index):
		game.apply_settings()

func account() -> void:
	panel("Supported Platform: Android")
	account_text = label(content,game.mobile.status)
	sign_in_button = button(content,"Sign In",game.mobile.sign_in)
	sign_out_button = button(content,"Sign Out",sign_out)
	button(content,"More",more)
	exit_button(close_animated)

func sign_out() -> void:
	game.mobile.sign_out()
	game.apply_settings()
	account()

func more() -> void:
	panel("")
	for title: String in LINKS:
		button(content,title,OS.shell_open.bind(LINKS[title]))
	exit_button(account)

func close_animated() -> void:
	if transition:
		transition.kill()
	transition = create_tween().set_trans(Tween.TRANS_SINE)
	transition.tween_property(frame,"position:y",root.size.y,0.25)
	transition.tween_callback(close)

func show_death() -> void:
	panel("")
	frame.hide()
	popup.color = Color(0.217,0.217,0.217,0.439)
	var again := button(popup,"Try Again",retry)
	death_position(again,-182,122)
	reward_button = button(popup,"Watch an (1X Life)",game.mobile.watch)
	death_position(reward_button,1,122)
	reward_button.visible = game.revivals < 3
	var record := label(popup,"Your Record:\n%d" % game.profile.record(),38)
	death_position(record,163,150)

func death_position(control: Control, y: float, height: float) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	control.offset_left = -155
	control.offset_right = 155
	control.offset_top = y-height/2
	control.offset_bottom = y+height/2
	if control is Button:
		control.flat = true
		control.add_theme_font_size_override("font_size",23)

func retry() -> void:
	game.mobile.banner(false)
	get_tree().reload_current_scene()

func _process(_delta: float) -> void:
	if is_instance_valid(reward_button):
		reward_button.disabled = not game.mobile.reward_ready()
	if is_instance_valid(account_text):
		account_text.text = game.mobile.status
		sign_in_button.disabled = game.mobile.busy or not game.mobile.player_id.is_empty() or not game.mobile.can_login()
		sign_out_button.disabled = game.mobile.player_id.is_empty()
