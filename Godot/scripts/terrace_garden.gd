extends Node3D

const SHORE := preload("res://art/models/lakeshore.obj")
const TERRACE := preload("res://art/models/terrace.obj")
const PAVILION := preload("res://art/models/pavilion.obj")
const BLOSSOM := preload("res://art/models/tree_blossom.obj")
const SAGE := preload("res://art/models/tree_sage.obj")
const ROCK := preload("res://art/models/meadow_rock.obj")
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
	build_meadows(level,middle,plan.centers.size()+20.0)
	lake.material_override = wash
	lake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	place(TERRACE,islet,Vector3(2.8,0.35,0.84))
	place(BLOSSOM if earth else PAVILION,islet,Vector3.ONE)
	# Offset the flooded gateway along the coast from the existing island.
	var ruin := place(RUIN,Vector3(6.5,0.0,plan.centers.size()*0.36),Vector3.ONE)
	ruin.rotation.y = deg_to_rad(-18 if level % 2 else 12)

func build_meadows(level: int, middle: float, span: float) -> void:
	var phase := float(level)*0.57
	var rng := RandomNumberGenerator.new()
	rng.seed = level+901
	var flowers: Array[Transform3D] = []
	var transforms: Array[Transform3D] = []
	var rocks: Array[Transform3D] = []
	for side: int in [-1,1]:
		for group in 4:
			var z := middle + (float(group)+0.5)*span/4.0 + sin(float(group)*2.1+float(side))*0.65
			var bank := -8.8+2.7*sin(z*0.21+phase)+0.9*cos(z*0.46) if side < 0 else 10.8+3.4*cos(z*0.16-phase)
			var tree_mesh: Mesh = BLOSSOM if posmod(group+level+side,3) == 0 else SAGE
			var tree := MeshInstance3D.new()
			tree.mesh = tree_mesh
			tree.position = Vector3(bank+side*(3.0+0.35*posmod(group,2)),0.05,z-middle)
			tree.scale = Vector3.ONE*(1.0+0.16*posmod(group+level,4))
			tree.rotation.y = float(posmod(group*3+level,8))*PI/4.0
			tree.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			add_child(tree)
	var spacing := 0.23
	var meadow_start := 1.65
	var meadow_width := 34.0
	var field_span := maxf(span,42.0)
	var columns := ceili(meadow_width/spacing)
	var rows := ceili(field_span/spacing)
	for side: int in [-1,1]:
		for row in rows:
			var along := middle-field_span*0.5+(float(row)+0.5+rng.randf_range(-0.38,0.38))*spacing
			var bank := -8.8+2.7*sin(along*0.21+phase)+0.9*cos(along*0.46)
			if side > 0:
				bank = 10.8+3.4*cos(along*0.16-phase)
			for column in columns:
				var inland := meadow_start+(float(column)+0.5+rng.randf_range(-0.38,0.38))*spacing
				var point := Vector2(bank+side*inland,along)
				var basis := Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*rng.randf_range(0.78,1.3))
				transforms.append(Transform3D(basis,Vector3(point.x,0.015,point.y-middle)))
				if row % 19 == 0 and column % 23 == 0:
					flowers.append(Transform3D(basis,Vector3(point.x+0.08,0.015,point.y-middle)))
	for side: int in [-1,1]:
		for cluster in 18:
			var cluster_z := middle+rng.randf_range(-field_span*0.46,field_span*0.46)
			var cluster_inland := rng.randf_range(3.0,meadow_width-1.0)
			for stone in 3:
				var along := cluster_z+rng.randfn(0.0,0.42)
				var inland := cluster_inland+rng.randfn(0.0,0.48)
				var bank := -8.8+2.7*sin(along*0.21+phase)+0.9*cos(along*0.46)
				if side > 0:
					bank = 10.8+3.4*cos(along*0.16-phase)
				var scale_factor := rng.randf_range(0.28,0.56)
				var rock_size := Vector3(scale_factor*rng.randf_range(0.8,1.4),scale_factor*rng.randf_range(0.72,1.2),scale_factor*rng.randf_range(0.8,1.3))
				var rock_basis := Basis(Vector3.UP,rng.randf()*TAU).scaled(rock_size)
				var rock_x := bank+side*clampf(inland,meadow_start,meadow_width-0.4)
				rocks.append(Transform3D(rock_basis,Vector3(rock_x,rock_size.y*0.30+0.01,along-middle)))
	var wind := ShaderMaterial.new()
	wind.shader = preload("res://art/meadow_grass.gdshader")
	plant_batch(preload("res://art/models/coastal_grass.obj"),transforms,wind)
	plant_batch(preload("res://art/models/coastal_daisy.obj"),flowers)
	plant_batch(ROCK,rocks)

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
