class_name Mission11
extends Node

signal mission_completed
signal mission_feedback(message: String)
signal mission_hint(hint_text: String, hint_number: int)
signal autotype_solution(code_string: String)
signal step_advanced(step_id: int)

const GRID_MIN := 0
const GRID_MAX := 9

const BUILDING_INDICES := {
	"house": 7,
	"shop": 8,
	"park": 9,
	"tree": 13,
	"road": 0,
}

var gridmap: GridMap = null
var completed := false
var hint_count := 0
var _idle_timer := 0.0
var _hint_shown := false
var _autotype_fired := false
var _code_has_run := false

var current_step_index := 0
var placed_buildings: Array = []

var mission_title := "Mission 11: The Weather System"
var mission_description := "Use while loops to model ongoing city systems."
var starter_code := ""

var steps: Array = [
	{
		"id": 1,
		"type": "explain",
		"title": "The Storm Approaches",
		"mayor_dialogue": "Mayor — a storm is coming. Not today, not tomorrow. But it will come. A while loop doesn't know when it stops. It just keeps going until the condition changes. That is resilience.",
		"instruction": "A while loop runs until a condition becomes false:\n\nwhile energy > 0:\n    day += 1\n    energy -= 15",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "",
		"success_condition": "explain",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["while", "var", "if", "break"],
	},
	{
		"id": 2,
		"type": "do_it",
		"title": "Watch the Storm",
		"mayor_dialogue": "Run the starter code. The city loses 15 energy per day until energy hits 0. How many days does it survive?",
		"instruction": "Run the code. Watch energy drain each day. Check the console output!",
		"show_grid_diagram": false,
		"starter_code": "var energy = 100\nvar day = 0\nwhile energy > 0:\n    day += 1\n    energy -= 15\n    print(\"Day \" + str(day) + \": energy = \" + str(energy))\nprint(\"City went dark after \" + str(day) + \" days\")",
		"hint": "Press Run and watch the energy drain.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["while", "var", "if", "break", "print"],
	},
	{
		"id": 3,
		"type": "do_it",
		"title": "Build the Power Station",
		"mayor_dialogue": "Add: if day == 3: place_building(\"house\", 3, 3) inside the loop. On day 3, the power station comes online!",
		"instruction": "Add inside the loop:\nif day == 3:\n    place_building(\"house\", 3, 3)\n\nThe building appears when day reaches 3!",
		"show_grid_diagram": false,
		"starter_code": "var energy = 100\nvar day = 0\nwhile energy > 0:\n    day += 1\n    energy -= 15\n    print(\"Day \" + str(day) + \": energy = \" + str(energy))",
		"hint": "Add the if block inside the while loop.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["while", "var", "if", "break", "place_building"],
	},
	{
		"id": 4,
		"type": "do_it",
		"title": "Emergency Shutdown",
		"mayor_dialogue": "Add: if energy < 20: place_building(\"park\", 0, 0) then break. Emergency park, then end the loop!",
		"instruction": "Add before break:\nif energy < 20:\n    place_building(\"park\", 0, 0)\n    break",
		"show_grid_diagram": false,
		"starter_code": "var energy = 100\nvar day = 0\nwhile energy > 0:\n    day += 1\n    energy -= 15\n    print(\"Day \" + str(day) + \": \" + str(energy))",
		"hint": "Add the emergency shutdown before the loop ends.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["while", "var", "if", "break", "place_building"],
	},
	{
		"id": 5,
		"type": "do_it",
		"title": "The Repair Crew",
		"mayor_dialogue": "Add a repair event: if day % 4 == 0: energy += 25. Every 4 days the crew repairs the grid!",
		"instruction": "Add inside the loop:\nif day % 4 == 0:\n    energy += 25\n\nHow many more days does the city survive?",
		"show_grid_diagram": false,
		"starter_code": "var energy = 100\nvar day = 0\nwhile energy > 0:\n    day += 1\n    energy -= 15\n    print(\"Day \" + str(day) + \": \" + str(energy))",
		"hint": "Add the repair check inside the while loop.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["while", "var", "if", "break", "print"],
	},
	{
		"id": 6,
		"type": "challenge",
		"title": "Model the Full Storm",
		"mayor_dialogue": "Combine all elements: draining energy, power station on day 3, repair every 4 days, emergency break at energy < 10.",
		"instruction": "Build a complete storm model with:\n- Energy drains by 15 (10 after day 3)\n- Repair +25 every 4 days\n- Emergency break at energy < 10",
		"show_grid_diagram": false,
		"starter_code": "var energy = 100\nvar day = 0\nwhile energy > 0:\n    day += 1\n    energy -= 15\n    if energy < 10:\n        break",
		"hint": "Use day % 4 == 0 for repairs, day >= 3 for reduced drain.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["while", "var", "if", "break", "print"],
	},
	{
		"id": 7,
		"type": "do_it",
		"title": "Place Threshold Buildings",
		"mayor_dialogue": "Add tracking flags to place buildings when energy crosses thresholds (80, 60, 40, 20).",
		"instruction": "Add variables: placed_80, placed_60, placed_40, placed_20.\nPlace buildings when energy crosses those thresholds.",
		"show_grid_diagram": false,
		"starter_code": "var energy = 100\nvar day = 0\nvar placed_80 = false\nwhile energy > 0:\n    day += 1\n    energy -= 15",
		"hint": "Check: if energy >= 80 and not placed_80: then set placed_80 = true.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["while", "var", "if", "break", "place_building"],
	},
	{
		"id": 8,
		"type": "challenge",
		"title": "Full Weather System",
		"mayor_dialogue": "Place buildings at each energy threshold: 80, 60, 40, 20. Use flags to prevent duplicate placements!",
		"instruction": "Complete weather system with threshold buildings at rows 0, 1, 2, 3 for energy levels 80, 60, 40, 20.",
		"show_grid_diagram": false,
		"starter_code": "var energy = 100\nvar day = 0\nvar placed_80 = false\nvar placed_60 = false\nvar placed_40 = false\nvar placed_20 = false\nwhile energy > 0:\n    day += 1\n    energy -= 15\n    if energy < 10:\n        break",
		"hint": "Use flags to track which thresholds have been crossed.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 4,
		"required_types": 0,
		"available_commands": ["while", "var", "if", "break", "place_building"],
	},
	{
		"id": 9,
		"type": "guided",
		"title": "Avoid Infinite Loops",
		"mayor_dialogue": "The #1 bug with while loops: the condition never becomes false. Make sure energy ALWAYS changes inside the loop!",
		"instruction": "If your loop runs forever, energy never reaches 0. Always subtract from energy inside the loop!",
		"show_grid_diagram": false,
		"starter_code": "var count = 0\nwhile count < 5:\n    count += 1\n    print(count)",
		"hint": "The loop will stop when count reaches 5.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["while", "var", "if", "break", "print"],
	},
	{
		"id": 10,
		"type": "mastery",
		"title": "City Survival Simulator",
		"mayor_dialogue": "You've mastered while loops and state tracking! Build a complete city survival simulator with energy management and building deployment.",
		"instruction": "Create a survival system: energy starts at 100, drains by 10 per day, repairs add +20 every 5 days. Place buildings at thresholds: 80 (house), 50 (shop), 20 (park). Print the final day count.",
		"show_grid_diagram": false,
		"starter_code": "var energy = 100\nvar day = 0",
		"hint": "Use flags for threshold buildings, day % 5 for repairs.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 3,
		"required_types": 0,
		"available_commands": ["while", "var", "if", "break", "place_building", "print"],
	},
]


func setup(gm: GridMap) -> void:
	gridmap = gm


func _process(delta: float) -> void:
	if _autotype_fired or _code_has_run:
		return
	
	_idle_timer += delta
	if _idle_timer > 90.0:
		_autotype_fired = true
		_autotype_solution()


func on_code_run() -> void:
	_code_has_run = true
	placed_buildings.clear()


func _check_success() -> bool:
	var step = steps[current_step_index]
	var success_type = step.success_condition
	
	match success_type:
		"explain":
			return true
		"code_runs":
			return true
		"count":
			return _check_count(step)
	
	return false


func _check_count(step: Dictionary) -> bool:
	var required = step.get("required_count", 0) as int
	if required == 0:
		return false
	
	var children = get_tree().get_nodes_in_group("placed_building")
	return children.size() >= required


func _announce_step_complete() -> void:
	mission_feedback.emit("Step %d complete!" % (current_step_index + 1))
	await get_tree().create_timer(0.8).timeout
	advance_step()


func advance_step() -> void:
	if current_step_index < steps.size() - 1:
		current_step_index += 1
		step_advanced.emit(current_step_index)
		placed_buildings.clear()
		await get_tree().create_timer(0.5).timeout
		if gridmap:
			gridmap.clear()
			for x in range(10):
				for z in range(10):
					if gridmap.get_cell_item(Vector3i(x, 0, z)) == -1:
						gridmap.set_cell_item(Vector3i(x, 0, z), 12)
	else:
		complete_mission()


func complete_mission() -> void:
	if not completed:
		completed = true
		mission_completed.emit()


func api_place_building(args: Array, line_num: int) -> String:
	if args.size() < 3:
		return "Line %d: place_building needs type, x, and y" % line_num
	
	var type_name = str(args[0])
	var x = int(args[1])
	var z = int(args[2])
	
	if not BUILDING_INDICES.has(type_name):
		return "Line %d: Unknown building type '%s'" % [line_num, type_name]
	
	if gridmap:
		gridmap.set_cell_item(Vector3i(x, 0, z), BUILDING_INDICES[type_name])
	
	_check_and_advance()
	return ""


func _check_and_advance() -> void:
	await get_tree().create_timer(0.2).timeout
	if _check_success():
		_announce_step_complete()


func api_print(msg: String) -> void:
	mission_feedback.emit(str(msg))
