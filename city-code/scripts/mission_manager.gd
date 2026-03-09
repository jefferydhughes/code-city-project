extends Node

# MissionManager — Autoload that manages active missions, connects CodeRunner
# to the mission, and routes signals to the UI.

signal feedback(message: String)
signal error(message: String, line_num: int)
signal mission_complete(mission_name: String)
signal hint_available(hint_text: String, hint_number: int)
signal mission_loaded(mission: Node)
signal mission_2_unlocked
signal bonus_complete
signal step_advanced(step_id: int)
signal autotype_solution(code_string: String)

const GRASS_INDEX := 12  # Mesh library index for grass tile

# Mission script registry
var MISSION_SCRIPTS := {
	"m1_first_house": preload("res://scripts/mission_1.gd"),
	"m2_row_of_homes": preload("res://scripts/mission_2.gd"),
}

# Mission metadata
var MISSION_META := {
	"m2_row_of_homes": {
		"title": "Mission 2: A Row of Homes",
		"character": "Builder Bob",
	},
}

var active_mission: Node = null
var gridmap: GridMap = null
var current_mission_id := ""


func setup(gm: GridMap) -> void:
	gridmap = gm
	_fill_grass()
	load_mission("m1_first_house")


func _fill_grass() -> void:
	if not gridmap:
		return
	for x in range(10):
		for z in range(10):
			# Only place grass if cell is empty
			if gridmap.get_cell_item(Vector3i(x, 0, z)) == -1:
				gridmap.set_cell_item(Vector3i(x, 0, z), GRASS_INDEX)


func load_mission(mission_id: String) -> void:
	if active_mission:
		active_mission.queue_free()
		active_mission = null

	if mission_id not in MISSION_SCRIPTS:
		push_error("Unknown mission: " + mission_id)
		return

	current_mission_id = mission_id
	var script_res = MISSION_SCRIPTS[mission_id]
	var mission: Node = script_res.new()
	mission.name = "ActiveMission"
	add_child(mission)

	active_mission = mission
	mission.setup(gridmap)

	# Connect mission signals
	mission.connect("mission_completed", _on_mission_completed)
	mission.connect("mission_feedback", _on_mission_feedback)
	mission.connect("mission_hint", _on_mission_hint)

	# Connect step_advanced signal if available (Mission 1 curriculum)
	if mission.has_signal("step_advanced"):
		mission.connect("step_advanced", _on_step_advanced)
	if mission.has_signal("autotype_solution"):
		mission.connect("autotype_solution", _on_autotype_solution)

	# Connect bonus signal if mission 2
	if mission_id == "m2_row_of_homes" and mission.has_signal("bonus_complete"):
		mission.connect("bonus_complete", _on_bonus_complete)

	# Connect CodeRunner to mission
	if CodeRunner:
		CodeRunner.set_mission(mission)
		if not CodeRunner.code_error.is_connected(_on_code_error):
			CodeRunner.code_error.connect(_on_code_error)
		if not CodeRunner.code_output.is_connected(_on_code_output):
			CodeRunner.code_output.connect(_on_code_output)
		if not CodeRunner.code_started.is_connected(_on_code_started):
			CodeRunner.code_started.connect(_on_code_started)

	mission_loaded.emit(mission)


# Legacy helper — still called from main.gd initially
func load_mission_1() -> void:
	load_mission("m1_first_house")


func load_mission_2() -> void:
	# Clear grid and refill with grass
	if gridmap:
		gridmap.clear()
		_fill_grass()
		# Place 1 starter house at (0,0) as starting state
		gridmap.set_cell_item(Vector3i(0, 0, 0), 7)  # HOUSE_INDEX = 7

	load_mission("m2_row_of_homes")


func _on_mission_completed() -> void:
	mission_complete.emit(active_mission.mission_title)

	# If mission 1 just completed, queue mission 2 unlock
	if current_mission_id == "m1_first_house":
		_schedule_mission_2_unlock()


func _schedule_mission_2_unlock() -> void:
	await get_tree().create_timer(2.0).timeout
	mission_2_unlocked.emit()


func _on_mission_feedback(message: String) -> void:
	feedback.emit(message)


func _on_mission_hint(hint_text: String, hint_number: int) -> void:
	hint_available.emit(hint_text, hint_number)


func _on_code_error(message: String, line_num: int) -> void:
	error.emit(message, line_num)


func _on_code_output(message: String) -> void:
	feedback.emit(message)


func _on_code_started() -> void:
	if active_mission and active_mission.has_method("on_code_run"):
		active_mission.on_code_run()


func _on_step_advanced(step_id: int) -> void:
	step_advanced.emit(step_id)


func _on_autotype_solution(code_string: String) -> void:
	autotype_solution.emit(code_string)


func _on_bonus_complete() -> void:
	bonus_complete.emit()


func get_starter_code() -> String:
	if active_mission and "starter_code" in active_mission:
		return active_mission.starter_code
	return ""


func get_mission_title() -> String:
	if active_mission and "mission_title" in active_mission:
		return active_mission.mission_title
	return ""


func get_mission_description() -> String:
	if active_mission and "mission_description" in active_mission:
		return active_mission.mission_description
	return ""


func get_character_name() -> String:
	if active_mission and "character" in active_mission:
		return active_mission.character
	return "Mayor Maple"
