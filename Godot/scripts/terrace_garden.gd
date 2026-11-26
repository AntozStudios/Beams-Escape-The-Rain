extends Node3D

const TERRACE := preload("res://art/models/terrace.obj")
const BRIDGE := preload("res://art/models/bridge.obj")
const STAIRS := preload("res://art/models/stairs.obj")
const CASCADE := preload("res://art/models/cascade.obj")
const PAVILION := preload("res://art/models/pavilion.obj")
const SAGE := preload("res://art/models/tree_sage.obj")
const BLOSSOM := preload("res://art/models/tree_blossom.obj")

func build(plan, level: int, earth: bool) -> void:
	position = Vector3(6.4,-5.2,2.5)
	var span: float = plan.centers.size()-3
	var middle := -span/2
	var tree := BLOSSOM if earth else SAGE
	place(TERRACE,Vector3.ZERO,Vector3(4.4,1,1))
	place(TERRACE,Vector3(0,1,middle),Vector3(3.6,1,1))
	place(TERRACE,Vector3(0,2,-span),Vector3(4,1,1))
	for i in 2:
		place(BRIDGE,Vector3(0,i+1,middle*(i+0.5)),Vector3(1,1,span/2))
		place(STAIRS,Vector3(0,i,middle*i))
	for i in 3:
		place(tree,Vector3(-1.1+0.8*i,0,0.7+0.35*sin(level+i)),Vector3.ONE*(0.8+0.15*i))
	place(tree,Vector3(1.1,1,middle+0.6),Vector3.ONE*1.05)
	place(CASCADE,Vector3(0,1,middle))
	place(PAVILION,Vector3(0,2,-span))

func place(asset: Mesh, origin: Vector3, size := Vector3.ONE) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = asset
	instance.position = origin
	instance.scale = size
	add_child(instance)
