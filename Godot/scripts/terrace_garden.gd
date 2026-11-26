extends Node3D

const SHORE := preload("res://art/models/lakeshore.obj")
const TERRACE := preload("res://art/models/terrace.obj")
const PAVILION := preload("res://art/models/pavilion.obj")
const BLOSSOM := preload("res://art/models/tree_blossom.obj")
const RUIN := preload("res://art/models/coastal_ruin.obj")

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
	build_meadows(wash,level,middle)
	lake.material_override = wash
	lake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	place(TERRACE,islet,Vector3(2.8,0.35,0.84))
	place(BLOSSOM if earth else PAVILION,islet,Vector3.ONE)
	# Offset the flooded gateway along the coast from the existing island.
	var ruin := place(RUIN,Vector3(6.5,0.0,plan.centers.size()*0.36),Vector3.ONE)
	ruin.rotation.y = deg_to_rad(-18 if level % 2 else 12)

func build_meadows(wash: ShaderMaterial, level: int, middle: float) -> void:
	var phase := float(level)*0.57
	var west_z := middle+2.5
	var east_z := middle-3.0
	var west := Vector2(-8.8+2.7*sin(west_z*0.21+phase)+0.9*cos(west_z*0.46)-4.4,west_z)
	var east := Vector2(10.8+3.4*cos(east_z*0.16-phase)+4.4,east_z)
	wash.set_shader_parameter("west_meadow",west)
	wash.set_shader_parameter("east_meadow",east)
	var rng := RandomNumberGenerator.new()
	rng.seed = level+901
	var flowers: Array[Transform3D] = []
	var transforms: Array[Transform3D] = []
	for patch: Vector2 in [west,east]:
		for group in 36:
			var offset := Vector2.from_angle(rng.randf()*TAU)*sqrt(rng.randf())
			var cluster := patch+offset*Vector2(3.5,7.5)
			for tuft in 5:
				var point := cluster+Vector2(rng.randfn(0,0.29),rng.randfn(0,0.44))
				var bank := -8.8+2.7*sin(point.y*0.21+phase)+0.9*cos(point.y*0.46)
				if patch == east:
					bank = 10.8+3.4*cos(point.y*0.16-phase)
				if (point.x-bank)*signf(patch.x) < 1.7:
					continue
				var basis := Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*rng.randf_range(0.62,1.15))
				transforms.append(Transform3D(basis,Vector3(point.x,0.015,point.y-middle)))
				if group % 5 == 0 and tuft < 3 and ((point-patch)/Vector2(4.5,9.0)).length() < 0.85:
					flowers.append(Transform3D(basis,Vector3(point.x+0.08,0.015,point.y-middle)))
	var wind := ShaderMaterial.new()
	wind.shader = preload("res://art/meadow_grass.gdshader")
	plant_batch(preload("res://art/models/coastal_grass.obj"),transforms,wind)
	plant_batch(preload("res://art/models/coastal_daisy.obj"),flowers)

func plant_batch(asset: Mesh, transforms: Array[Transform3D], paint: Material = null) -> void:
	if transforms.is_empty():
		return
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = asset
	batch.instance_count = transforms.size()
	for i in transforms.size():
		batch.set_instance_transform(i,transforms[i])
	var plants := MultiMeshInstance3D.new()
	plants.multimesh = batch
	plants.material_override = paint
	plants.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(plants)

func place(asset: Mesh, origin: Vector3, size: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = asset
	instance.position = origin
	instance.scale = size
	add_child(instance)
	return instance
