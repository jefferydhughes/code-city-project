extends Node3D

@export var structures: Array[Structure] = []

var map:DataMap

var index:int = -1 # -1 = nothing selected

@export var selector:Node3D # The 'cursor'
@export var selector_container:Node3D # Node that holds a preview of the structure
@export var view_camera:Camera3D # Used for raycasting mouse
@export var gridmap:GridMap
@export var cash_display:Label

var plane:Plane # Used for raycasting mouse
var _selector_active := false # Selector starts hidden

func _ready():

	map = DataMap.new()
	plane = Plane(Vector3.UP, Vector3.ZERO)

	# Create new MeshLibrary dynamically
	var mesh_library = MeshLibrary.new()

	for structure in structures:
		var id = mesh_library.get_last_unused_item_id()
		mesh_library.create_item(id)
		mesh_library.set_item_mesh(id, get_mesh(structure.model))
		mesh_library.set_item_mesh_transform(id, Transform3D())

	gridmap.mesh_library = mesh_library

	# Clear any pre-placed cells (roads/tiles) on startup
	gridmap.clear()

	# Hide the selector cursor until player presses Q/E
	if selector:
		selector.visible = false

	update_cash()

func _process(delta):

	# Controls
	action_rotate()
	action_structure_toggle()

	action_save()
	action_load()
	action_load_resources()

	# Only process selector/build/demolish if selector is active
	if not _selector_active:
		return

	# Map position based on mouse
	var world_position = plane.intersects_ray(
		view_camera.project_ray_origin(get_viewport().get_mouse_position()),
		view_camera.project_ray_normal(get_viewport().get_mouse_position()))

	if world_position == null:
		return

	var gridmap_position = Vector3(round(world_position.x), 0, round(world_position.z))
	selector.position = lerp(selector.position, gridmap_position, min(delta * 40, 1.0))

	action_build(gridmap_position)
	action_demolish(gridmap_position)

func get_mesh(packed_scene):
	var scene_state:SceneState = packed_scene.get_state()
	for i in range(scene_state.get_node_count()):
		if(scene_state.get_node_type(i) == "MeshInstance3D"):
			for j in scene_state.get_node_property_count(i):
				var prop_name = scene_state.get_node_property_name(i, j)
				if prop_name == "mesh":
					var prop_value = scene_state.get_node_property_value(i, j)
					return prop_value.duplicate()

func action_build(gridmap_position):
	if index < 0:
		return
	if Input.is_action_just_pressed("build"):
		var previous_tile = gridmap.get_cell_item(gridmap_position)
		gridmap.set_cell_item(gridmap_position, index, gridmap.get_orthogonal_index_from_basis(selector.basis))

		if previous_tile != index:
			map.cash -= structures[index].price
			update_cash()
			Audio.play("sounds/placement-a.ogg, sounds/placement-b.ogg, sounds/placement-c.ogg, sounds/placement-d.ogg", -20)

func action_demolish(gridmap_position):
	if Input.is_action_just_pressed("demolish"):
		if gridmap.get_cell_item(gridmap_position) != -1:
			gridmap.set_cell_item(gridmap_position, -1)
			Audio.play("sounds/removal-a.ogg, sounds/removal-b.ogg, sounds/removal-c.ogg, sounds/removal-d.ogg", -20)

func action_rotate():
	if Input.is_action_just_pressed("rotate"):
		selector.rotate_y(deg_to_rad(90))
		Audio.play("sounds/rotate.ogg", -30)

func action_structure_toggle():
	if Input.is_action_just_pressed("structure_next"):
		if structures.size() == 0:
			return
		index = wrap(index + 1, 0, structures.size())
		_activate_selector()
		Audio.play("sounds/toggle.ogg", -30)

	if Input.is_action_just_pressed("structure_previous"):
		if structures.size() == 0:
			return
		index = wrap(index - 1, 0, structures.size())
		_activate_selector()
		Audio.play("sounds/toggle.ogg", -30)

	if _selector_active and index >= 0:
		update_structure()

func _activate_selector():
	_selector_active = true
	if selector:
		selector.visible = true

func update_structure():
	if structures.size() == 0 or index < 0:
		return

	for n in selector_container.get_children():
		selector_container.remove_child(n)

	var _model = structures[index].model.instantiate()
	selector_container.add_child(_model)
	_model.position.y += 0.25

func update_cash():
	cash_display.text = "$" + str(map.cash)

# Saving/load

func action_save():
	if Input.is_action_just_pressed("save"):
		print("Saving map...")
		map.structures.clear()
		for cell in gridmap.get_used_cells():
			var data_structure:DataStructure = DataStructure.new()
			data_structure.position = Vector2i(cell.x, cell.z)
			data_structure.orientation = gridmap.get_cell_item_orientation(cell)
			data_structure.structure = gridmap.get_cell_item(cell)
			map.structures.append(data_structure)
		ResourceSaver.save(map, "user://map.res")

func action_load():
	if Input.is_action_just_pressed("load"):
		print("Loading map...")
		gridmap.clear()
		map = ResourceLoader.load("user://map.res")
		if not map:
			map = DataMap.new()
		for cell in map.structures:
			gridmap.set_cell_item(Vector3i(cell.position.x, 0, cell.position.y), cell.structure, cell.orientation)
		update_cash()

func action_load_resources():
	if Input.is_action_just_pressed("load_resources"):
		print("Loading map...")
		gridmap.clear()
		map = ResourceLoader.load("res://sample map/map.res")
		if not map:
			map = DataMap.new()
		for cell in map.structures:
			gridmap.set_cell_item(Vector3i(cell.position.x, 0, cell.position.y), cell.structure, cell.orientation)
		update_cash()
