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
var pad := HBoxContainer.new()
var navigation := VBoxContainer.new()
var start := Button.new()
var map_button := Button.new()
var life := Label.new()
var score := Label.new()
var star_score := Label.new()
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
	for state in ["normal","hover","pressed","disabled"]:
		var style := StyleBoxFlat.new()
		var fills := {"normal":"524b69","hover":"665d7c","pressed":"403c55","disabled":"726e81"}
		style.bg_color = Color(fills[state])
		style.set_corner_radius_all(10)
		root.theme.set_stylebox(state,"Button",style)
	root.theme.set_color("font_outline_color","Label",Color("#403952"))
	root.theme.set_constant("outline_size","Label",3)
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
	start.pressed.connect(func(): game.start_level(game.campaign_level))
	root.add_child(map_button)
	map_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	map_button.offset_left = -100
	map_button.offset_right = 100
	map_button.offset_top = 78
	map_button.offset_bottom = 132
	map_button.text = "Maps"
	map_button.focus_mode = Control.FOCUS_NONE
	map_button.pressed.connect(maps)
	root.add_child(navigation)
	navigation.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	navigation.offset_left = -74
	navigation.offset_right = -10
	navigation.offset_top = 10
	button(navigation,"?",instructions).modulate = Color("#68425a")
	button(navigation,"A",items).modulate = Color("#395d56")
	button(navigation,"P",account).modulate = Color("#454968")
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
	for label: Label in [life, score, warning, star_score]:
		root.add_child(label)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size",34)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	score.offset_top = 24
	score.add_theme_font_size_override("font_size",50)
	star_score.offset_top = 76
	star_score.add_theme_font_size_override("font_size",28)
	star_score.modulate = Color("#ffda8f")
	life.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	life.modulate = Color("#b65162")
	life.add_theme_font_size_override("font_size",84)
	life.offset_left = 18
	life.offset_top = 15
	warning.offset_top = 145
	warning.add_theme_font_size_override("font_size",22)
	root.add_child(pad)
	pad.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	pad.offset_left = -130
	pad.offset_right = 130
	pad.offset_top = -84
	pad.offset_bottom = -20
	for direction: Vector2 in [Vector2.LEFT,Vector2.UP,Vector2.DOWN,Vector2.RIGHT]:
		var arrows := {Vector2.LEFT:"\u2190",Vector2.UP:"\u2191",Vector2.DOWN:"\u2193",Vector2.RIGHT:"\u2192"}
		var key := button(pad,arrows[direction],pad_move.bind(direction))
		key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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

func pad_move(direction: Vector2) -> void:
	if not modal_visible():
		game.move(game.screen_step(direction,game.camera.global_basis))

func refresh() -> void:
	pad.visible = game.armed and not game.dead and not game.level_complete and bool(game.profile.value("Direction buttons",false))
	life.text = ".".repeat(game.lives)
	life.visible = game.armed and not game.dead and not game.level_complete
	score.text = str(game.campaign_level)
	score.visible = game.started and not game.dead and not game.level_complete
	star_score.text = "\u2605 %d/3" % game.stars_collected
	star_score.visible = game.armed and not game.dead and not game.level_complete
	start.visible = not game.armed
	map_button.visible = not game.armed
	navigation.visible = not game.started
	if game.dead or game.level_complete or not game.started:
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
	frame.color = Color("#3f3b52")
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
	label(content,"Swipe or use WASD or arrow keys to roll. Climb one step at a time.\n\nMint diamonds are safe resting places. A red diamond warns of incoming rain. On sand, move before it sinks.\n\nExplore side paths for stars and reach the checkpoint to finish.")
	exit_button(close_animated)

func settings() -> void:
	panel("Settings")
	var toggle := CheckButton.new()
	toggle.text = "Direction buttons"
	toggle.button_pressed = bool(game.profile.value("Direction buttons",false))
	content.add_child(toggle)
	toggle.toggled.connect(func(enabled: bool): game.profile.save("Direction buttons",enabled); refresh())
	slider("Follow Player",10,1,1)
	slider("Vignette",0.5,0.01,0.5)
	slider("Music",0.07,0.001,0.025)
	exit_button(close_animated)

func maps() -> void:
	panel("Maps")
	for i in game.Maps.NAMES.size():
		var title: String = game.Maps.NAMES[i]
		var unlocked := maxi(int(game.profile.value("unlocked_%d" % i,game.Maps.INITIAL_UNLOCKED_LEVELS)),game.Maps.INITIAL_UNLOCKED_LEVELS)
		var difficulty := "%d/%d Level" % [mini(unlocked,game.Maps.MAX_LEVELS),game.Maps.MAX_LEVELS]
		if i == game.map_id:
			title += "  ✓"
		button(content,"%s · %s" % [title,difficulty],choose_map.bind(i))
	exit_button(close_animated)

func choose_map(id: int) -> void:
	game.select_map(id)
	levels()

func levels() -> void:
	panel(game.Maps.NAMES[game.map_id] + " Level")
	var unlocked := clampi(maxi(int(game.profile.value("unlocked_%d" % game.map_id,game.Maps.INITIAL_UNLOCKED_LEVELS)),game.Maps.INITIAL_UNLOCKED_LEVELS),1,game.Maps.MAX_LEVELS)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	content.add_child(grid)
	for level_index in range(1,game.Maps.MAX_LEVELS+1):
		var earned := int(game.profile.value("stars_%d_%d" % [game.map_id,level_index],0))
		var caption := str(level_index)
		if earned > 0:
			caption += "\n" + "\u2605".repeat(earned)
		var entry := button(grid,caption,game.start_level.bind(level_index))
		entry.custom_minimum_size = Vector2(62,58)
		entry.disabled = level_index > unlocked
		entry.modulate = Color("#ffda8f") if earned > 0 else Color.WHITE
	button(content,"Maps",maps)

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
	popup.color = Color("#3f3b5280")
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
	game.start_level(game.campaign_level)

func show_level_complete() -> void:
	panel("Level %d geschafft" % game.campaign_level)
	var stars := "\u2605".repeat(game.stars_collected) + "\u2606".repeat(3-game.stars_collected)
	label(content,stars,38).modulate = Color("#ffda8f")
	if game.campaign_level < game.Maps.MAX_LEVELS:
		button(content,"Weiter",game.continue_level)
	else:
		label(content,"Welt abgeschlossen",24)
	button(content,"Nochmal",retry)
	button(content,"Menu",game.return_to_menu)
	refresh()

func _process(_delta: float) -> void:
	if is_instance_valid(reward_button):
		reward_button.disabled = not game.mobile.reward_ready()
	if is_instance_valid(account_text):
		account_text.text = game.mobile.status
		sign_in_button.disabled = game.mobile.busy or not game.mobile.player_id.is_empty() or not game.mobile.can_login()
		sign_out_button.disabled = game.mobile.player_id.is_empty()
