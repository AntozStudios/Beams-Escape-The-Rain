extends Node3D

const SHORE := preload("res://art/models/lakeshore.obj")
const TERRACE := preload("res://art/models/terrace.obj")
const PAVILION := preload("res://art/models/pavilion.obj")
const BLOSSOM := preload("res://art/models/tree_blossom.obj")

func build(plan, level: int, earth: bool) -> void:
	var middle := 3.5 - float(plan.centers.size()-1)*0.5
	position = Vector3(0,-5.35,middle)
	var islet := Vector3(7.0,0.24,-2.0)
	var lake := place(SHORE,Vector3.ZERO,Vector3(100,1,100))
	var wash := ShaderMaterial.new()
	wash.shader = preload("res://art/lakeshore.gdshader")
	wash.set_shader_parameter("phase",float(level)*0.57)
	var shore_center := to_global(islet)
	wash.set_shader_parameter("islet_center",Vector2(shore_center.x,shore_center.z))
	lake.material_override = wash
	lake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	place(TERRACE,islet,Vector3(2.8,0.35,0.84))
	place(BLOSSOM if earth else PAVILION,islet,Vector3.ONE)

func place(asset: Mesh, origin: Vector3, size: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = asset
	instance.position = origin
	instance.scale = size
	add_child(instance)
	return instance
