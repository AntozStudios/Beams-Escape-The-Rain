@tool
extends EditorPlugin

class AndroidExport extends EditorExportPlugin:
	func _get_name() -> String:
		return "BeamsAndroid"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return ["com.google.android.gms:play-services-ads:25.0.0","com.google.android.ump:user-messaging-platform:4.0.0"]

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return ["res://addons/beams_android/beams.aar"]

var exporter := AndroidExport.new()

func _enter_tree() -> void:
	add_export_plugin(exporter)

func _exit_tree() -> void:
	remove_export_plugin(exporter)
