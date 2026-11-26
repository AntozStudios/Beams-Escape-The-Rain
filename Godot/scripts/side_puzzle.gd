extends Node3D

enum Kind { PRESSURE, DRAWBRIDGE, SLUICE, SHELTER }
const DECK := preload("res://art/models/lift.obj")
const FOOTBRIDGE := preload("res://art/models/timber_footbridge.obj")
const LANDING := preload("res://art/models/terrace.obj")
const PALLET := preload("res://art/models/pallet.obj")
const STAIR := preload("res://art/models/stairs.obj")
const RAILS := preload("res://art/models/rails.obj")
const ROOF := preload("res://art/models/pavilion.obj")
const CHANNEL := preload("res://art/models/cascade.obj")
const SPACING := Vector2i.LEFT

var kind: Kind
var entrance: Vector2i
var approach := Vector2i.ZERO
var floor_level: int
var active := false
var weighted := false
var moving: MeshInstance3D
var mechanism: MeshInstance3D
var hinge: Node3D
var animation: Tween
var switch_tile: MeshInstance3D

func cell(distance: int) -> Vector2i:
	return entrance + SPACING*distance

func prop(mesh: Mesh, x: float, y: float, size := Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = Vector3(-x,y,0)
	node.scale = size
	add_child(node)
	return node

func build(number: int, origin: Vector2i, height: int, ground: float, next_edge: Vector2i) -> void:
	kind = (number-1)%4 as Kind
	entrance = origin
	floor_level = height
	approach = next_edge
	position = Vector3(origin.x,ground+height,3.5-origin.y)
	for distance in [1,2,4]:
		var depth := -1.0 if kind == Kind.SLUICE and distance == 4 else 0.0
		prop(LANDING,distance,depth,Vector3(1,0.35,1.0/3.55))
	# A second approach lets the player try the plate before moving the weight.
	for x in range(cell(2).x,approach.x):
		prop(LANDING,entrance.x-x,0,Vector3(1,0.35,1.0/3.55)).position.z = -1
	switch_tile = prop(DECK,2,0.02,Vector3(0.62,0.3,0.62))
	match kind:
		Kind.PRESSURE, Kind.SLUICE:
			var mesh: Mesh = PALLET if kind == Kind.PRESSURE else DECK
			moving = prop(mesh,1,0.08,Vector3(0.8,0.65,0.8))
			prop(RAILS,1.5,0.015,Vector3(0.65,1,0.85)).rotation.y = PI/2
			if kind == Kind.SLUICE:
				prop(STAIR,3,-1.05,Vector3(0.8,1,1)).rotation.y = PI/2
				mechanism = prop(CHANNEL,3,0.3,Vector3(0.65,0.65,1))
			else:
				mechanism = prop(FOOTBRIDGE,2,-0.015)
				mechanism.rotation.y = PI/2
		Kind.DRAWBRIDGE:
			# The deck extends along -X from its hinge on the landing edge.
			hinge = Node3D.new()
			add_child(hinge)
			hinge.position = Vector3(-2.5,0,0)
			hinge.rotation.z = -PI/2
			mechanism = prop(FOOTBRIDGE,0,0)
			mechanism.reparent(hinge,false)
			mechanism.position = Vector3(-0.5,0,0)
			mechanism.rotation.y = PI/2
		Kind.SHELTER:
			prop(DECK,3,-0.12)
			moving = prop(ROOF,2,0,Vector3(0.65,0.78,0.65))
			prop(RAILS,2.5,0.01).rotation.y = PI/2

func is_branch(at: Vector2i) -> bool:
	if at.y == approach.y:
		return at.x >= cell(2).x and at.x < approach.x
	return at.y == entrance.y and at.x < entrance.x and at.x >= entrance.x-4

func can_cross(from: Vector2i, to: Vector2i) -> bool:
	if is_branch(from) != is_branch(to) and from != entrance and to != entrance and from != approach and to != approach:
		return false
	if from == cell(2) and to == cell(3) and kind == Kind.PRESSURE and not weighted:
		return false
	if to == cell(3):
		if kind == Kind.DRAWBRIDGE and animation and animation.is_running():
			return false
		return active or kind == Kind.SHELTER
	return true

func height_at(at: Vector2i) -> int:
	return floor_level - int(kind == Kind.SLUICE and at == cell(4))

func try_push(from: Vector2i, to: Vector2i) -> bool:
	if moving == null or weighted:
		return true
	var start := 2 if kind == Kind.SHELTER else 1
	if to != cell(start):
		return true
	if from != cell(start-1):
		return false
	weighted = true
	create_tween().tween_property(moving,"position:x",-float(start+1),0.16)
	set_active(true)
	return true

func landed(at: Vector2i) -> void:
	if kind == Kind.DRAWBRIDGE and at == cell(2):
		set_active(not active)
	elif kind == Kind.PRESSURE:
		set_active(weighted or at == cell(2))

func set_active(value: bool) -> void:
	if active == value:
		return
	active = value
	switch_tile.position.y = -0.005 if active else 0.02
	if mechanism == null:
		return
	if animation:
		animation.kill()
	animation = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	match kind:
		Kind.PRESSURE:
			animation.tween_property(mechanism,"position:x",-3.0 if active else -2.0,0.22)
		Kind.DRAWBRIDGE:
			animation.tween_property(hinge,"rotation:z",0.0 if active else -PI/2,0.55)
		Kind.SLUICE:
			animation.tween_property(mechanism,"position:y",-1.45,0.4)
