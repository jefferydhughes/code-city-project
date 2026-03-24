extends Node

# MissionManager — Autoload that manages active missions, connects CodeRunner
# to the mission, and routes signals to the UI.

signal feedback(message: String)
signal error(message: String, line_num: int)
signal mission_complete(mission_name: String)
signal hint_available(hint_text: String, hint_number: int)
signal mission_loaded(mission: Node)
signal mission_2_unlocked
signal mission_3_unlocked
signal mission_4_unlocked
signal mission_5_unlocked
signal mission_6_unlocked
signal mission_7_unlocked
signal mission_8_unlocked
signal mission_9_unlocked
signal mission_10_unlocked
signal mission_11_unlocked
signal mission_12_unlocked
signal mission_13_unlocked
signal mission_14_unlocked
signal mission_15_unlocked
signal bonus_complete
signal step_advanced(step_id: int)
signal autotype_solution(code_string: String)

const GRASS_INDEX := 12  # Mesh library index for grass tile

# Mission script registry
var MISSION_SCRIPTS := {
	"m1_first_house": preload("res://scripts/mission_1.gd"),
	"m2_row_of_homes": preload("res://scripts/mission_2.gd"),
	"m3_variables": preload("res://scripts/mission_3.gd"),
	"m4_arrays": preload("res://scripts/mission_4.gd"),
	"m5_nested_loops": preload("res://scripts/mission_5.gd"),
	"m6_functions": preload("res://scripts/mission_6.gd"),
	"m7_conditionals": preload("res://scripts/mission_7.gd"),
	"m8_dictionary": preload("res://scripts/mission_8.gd"),
	"m9_function_factory": preload("res://scripts/mission_9.gd"),
	"m10_city_census": preload("res://scripts/mission_10.gd"),
	"m11_weather_system": preload("res://scripts/mission_11.gd"),
	"m12_event_planner": preload("res://scripts/mission_12.gd"),
	"m13_happiness_engine": preload("res://scripts/mission_13.gd"),
	"m14_npc_engine": preload("res://scripts/mission_14.gd"),
	"m15_autonomous_city": preload("res://scripts/mission_15.gd"),
}

# Mission metadata
var MISSION_META := {
	"m1_first_house": {
		"title": "Mission 1: Build Your First City!",
		"character": "Mayor Maple",
	},
	"m2_row_of_homes": {
		"title": "Mission 2: A Row of Homes",
		"character": "Builder Bob",
	},
	"m3_variables": {
		"title": "Mission 3: Variables",
		"character": "Mayor Maple",
	},
	"m4_arrays": {
		"title": "Mission 4: Arrays",
		"character": "Mayor Maple",
	},
	"m5_nested_loops": {
		"title": "Mission 5: Nested Loops",
		"character": "Mayor Maple",
	},
	"m6_functions": {
		"title": "Mission 6: Functions",
		"character": "Mayor Maple",
	},
	"m7_conditionals": {
		"title": "Mission 7: Conditionals",
		"character": "Mayor Maple",
	},
	"m8_dictionary": {
		"title": "Mission 8: The Dictionary District",
		"character": "City Elder",
		"island": 2,
		"belt": "Yellow",
	},
	"m9_function_factory": {
		"title": "Mission 9: The Function Factory",
		"character": "City Elder",
		"island": 2,
		"belt": "Yellow",
	},
	"m10_city_census": {
		"title": "Mission 10: The City Census",
		"character": "City Elder",
		"island": 2,
		"belt": "Yellow",
	},
	"m11_weather_system": {
		"title": "Mission 11: The Weather System",
		"character": "City Elder",
		"island": 2,
		"belt": "Yellow Advanced",
	},
	"m12_event_planner": {
		"title": "Mission 12: The Event Planner",
		"character": "City Elder",
		"island": 2,
		"belt": "Yellow Advanced",
	},
	"m13_happiness_engine": {
		"title": "Mission 13: The Happiness Engine",
		"character": "City Elder",
		"island": 2,
		"belt": "Green",
	},
	"m14_npc_engine": {
		"title": "Mission 14: The NPC Behavior Engine",
		"character": "City Elder",
		"island": 2,
		"belt": "Green",
	},
	"m15_autonomous_city": {
		"title": "Mission 15: The Autonomous City",
		"character": "City Elder",
		"island": 2,
		"belt": "Green Capstone",
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
	if gridmap:
		gridmap.clear()
		_fill_grass()
		gridmap.set_cell_item(Vector3i(0, 0, 0), 7)

	load_mission("m2_row_of_homes")


func load_mission_3() -> void:
	if gridmap:
		gridmap.clear()
		_fill_grass()
		gridmap.set_cell_item(Vector3i(0, 0, 0), 7)

	load_mission("m3_variables")


func load_mission_4() -> void:
	if gridmap:
		gridmap.clear()
		_fill_grass()
		gridmap.set_cell_item(Vector3i(0, 0, 0), 7)

	load_mission("m4_arrays")


func load_mission_5() -> void:
	if gridmap:
		gridmap.clear()
		_fill_grass()
		gridmap.set_cell_item(Vector3i(0, 0, 0), 7)

	load_mission("m5_nested_loops")


func load_mission_6() -> void:
	if gridmap:
		gridmap.clear()
		_fill_grass()
		gridmap.set_cell_item(Vector3i(0, 0, 0), 7)

	load_mission("m6_functions")


func load_mission_7() -> void:
	if gridmap:
		gridmap.clear()
		_fill_grass()
		gridmap.set_cell_item(Vector3i(0, 0, 0), 7)

	load_mission("m7_conditionals")


func load_mission_8() -> void:
	if gridmap:
		gridmap.clear()
		_fill_grass()
		gridmap.set_cell_item(Vector3i(0, 0, 0), 7)

	load_mission("m8_dictionary")


func load_mission_9() -> void:
	if gridmap:
		gridmap.clear()
		_fill_grass()
		gridmap.set_cell_item(Vector3i(0, 0, 0), 7)

	load_mission("m9_function_factory")


func load_mission_10() -> void:
	if gridmap:
		gridmap.clear()
		_fill_grass()
		gridmap.set_cell_item(Vector3i(0, 0, 0), 7)

	load_mission("m10_city_census")


func load_mission_11() -> void:
	if gridmap:
		gridmap.clear()
		_fill_grass()
		gridmap.set_cell_item(Vector3i(0, 0, 0), 7)

	load_mission("m11_weather_system")


func load_mission_12() -> void:
	if gridmap:
		gridmap.clear()
		_fill_grass()
		gridmap.set_cell_item(Vector3i(0, 0, 0), 7)

	load_mission("m12_event_planner")


func load_mission_13() -> void:
	if gridmap:
		gridmap.clear()
		_fill_grass()
		gridmap.set_cell_item(Vector3i(0, 0, 0), 7)

	load_mission("m13_happiness_engine")


func load_mission_14() -> void:
	if gridmap:
		gridmap.clear()
		_fill_grass()
		gridmap.set_cell_item(Vector3i(0, 0, 0), 7)

	load_mission("m14_npc_engine")


func load_mission_15() -> void:
	if gridmap:
		gridmap.clear()
		_fill_grass()
		gridmap.set_cell_item(Vector3i(0, 0, 0), 7)

	load_mission("m15_autonomous_city")


func _on_mission_completed() -> void:
	mission_complete.emit(active_mission.mission_title)

	match current_mission_id:
		"m1_first_house":
			_schedule_mission_2_unlock()
		"m2_row_of_homes":
			_schedule_mission_3_unlock()
		"m3_variables":
			_schedule_mission_4_unlock()
		"m4_arrays":
			_schedule_mission_5_unlock()
		"m5_nested_loops":
			_schedule_mission_6_unlock()
		"m6_functions":
			_schedule_mission_7_unlock()
		"m7_conditionals":
			_schedule_mission_8_unlock()
		"m8_dictionary":
			_schedule_mission_9_unlock()
		"m9_function_factory":
			_schedule_mission_10_unlock()
		"m10_city_census":
			_schedule_mission_11_unlock()
		"m11_weather_system":
			_schedule_mission_12_unlock()
		"m12_event_planner":
			_schedule_mission_13_unlock()
		"m13_happiness_engine":
			_schedule_mission_14_unlock()
		"m14_npc_engine":
			_schedule_mission_15_unlock()


func _schedule_mission_2_unlock() -> void:
	await get_tree().create_timer(2.0).timeout
	mission_2_unlocked.emit()


func _schedule_mission_3_unlock() -> void:
	await get_tree().create_timer(2.0).timeout
	mission_3_unlocked.emit()


func _schedule_mission_4_unlock() -> void:
	await get_tree().create_timer(2.0).timeout
	mission_4_unlocked.emit()


func _schedule_mission_5_unlock() -> void:
	await get_tree().create_timer(2.0).timeout
	mission_5_unlocked.emit()


func _schedule_mission_6_unlock() -> void:
	await get_tree().create_timer(2.0).timeout
	mission_6_unlocked.emit()


func _schedule_mission_7_unlock() -> void:
	await get_tree().create_timer(2.0).timeout
	mission_7_unlocked.emit()


func _schedule_mission_8_unlock() -> void:
	await get_tree().create_timer(2.0).timeout
	mission_8_unlocked.emit()


func _schedule_mission_9_unlock() -> void:
	await get_tree().create_timer(2.0).timeout
	mission_9_unlocked.emit()


func _schedule_mission_10_unlock() -> void:
	await get_tree().create_timer(2.0).timeout
	mission_10_unlocked.emit()


func _schedule_mission_11_unlock() -> void:
	await get_tree().create_timer(2.0).timeout
	mission_11_unlocked.emit()


func _schedule_mission_12_unlock() -> void:
	await get_tree().create_timer(2.0).timeout
	mission_12_unlocked.emit()


func _schedule_mission_13_unlock() -> void:
	await get_tree().create_timer(2.0).timeout
	mission_13_unlocked.emit()


func _schedule_mission_14_unlock() -> void:
	await get_tree().create_timer(2.0).timeout
	mission_14_unlocked.emit()


func _schedule_mission_15_unlock() -> void:
	await get_tree().create_timer(2.0).timeout
	mission_15_unlocked.emit()


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
