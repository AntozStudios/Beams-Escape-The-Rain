extends RefCounted

const FILE := "user://beams.cfg"
const ITEMS := [
	["Default Cube", "playerSkin", 0, Color.WHITE],
	["Red Cube", "playerSkin", 40, Color.RED],
	["Golden Cube", "playerSkin", 100, Color(1,0.60556,0)],
	["Default Sky", "skyColor", 0, Color(0.12157,0.12157,0.12157)],
	["Blue Sky", "skyColor", 25, Color(0,0.17660,0.28302)],
	["Red Sky", "skyColor", 50, Color(0.18868,0,0.00490)],
	["Purple Sky", "skyColor", 35, Color(0.30189,0,0.17331)],
	["Green Cube", "playerSkin", 75, Color(0,1,0.03742)],
	["Black Sky", "skyColor", 10, Color(0.00392,0.00392,0.00392)],
	["Yellow Sky", "skyColor", 5, Color(0.54717,0.52946,0)],
	["Green Sky", "skyColor", 15, Color(0.14418,0.40566,0)]
]
var config := ConfigFile.new()
var path: String

func _init(save_path: String = FILE) -> void:
	path = save_path
	if FileAccess.file_exists(path):
		config.load(path)

func value(key: String, fallback: Variant) -> Variant:
	return config.get_value("game",key,fallback)

func save(key: String, data: Variant) -> void:
	config.set_value("game",key,data)
	var error := config.save(path)
	if error != OK:
		push_error("Saving %s failed: %s" % [key,error_string(error)])

func record() -> int:
	return int(value("HighScore",0))

func use_item(index: int) -> bool:
	if index < 0 or index >= ITEMS.size() or record() < ITEMS[index][2]:
		return false
	save(ITEMS[index][1], index)
	return true

func color(category: String, fallback: int) -> Color:
	var index := int(value(category,fallback))
	if index < 0 or index >= ITEMS.size() or ITEMS[index][1] != category:
		index = fallback
	return ITEMS[index][3]
