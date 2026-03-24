class_name Mission14
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

var mission_title := "Mission 14: The NPC Behavior Engine"
var mission_description := "Implement state machines for NPC behavior."
var starter_code := ""

var steps: Array = [
	{
		"id": 1,
		"type": "explain",
		"title": "Citizens with Brains",
		"mayor_dialogue": "Mayor — your citizens wander the streets without purpose. A state machine gives every NPC a brain. Not complicated. Just: what state am I in right now, and what should I do? That single idea powers every game character you have ever seen.",
		"instruction": "A state machine has:\n- STATE (what's happening now)\n- TRANSITIONS (what changes the state)\n- ACTIONS (what happens in each state)",
		"show_grid_diagram": false,
		"starter_code": "",
		"hint": "",
		"success_condition": "explain",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match"],
	},
	{
		"id": 2,
		"type": "do_it",
		"title": "Run the NPC",
		"mayor_dialogue": "Run the starter code. The citizen starts idle. The state changes based on happiness level!",
		"instruction": "Run the code. Watch the state change from idle to working to celebrating based on happiness!",
		"show_grid_diagram": false,
		"starter_code": "var state = \"idle\"\nvar happiness = 5\n\nfunction update_citizen():\n    if happiness > 7:\n        state = \"celebrating\"\n    elif happiness > 3:\n        state = \"working\"\n    else:\n        state = \"idle\"\n    print(\"State: \" + state)\n\nupdate_citizen()\nprint(\"Happiness: \" + str(happiness))",
		"hint": "Press Run to see the state machine in action.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "print"],
	},
	{
		"id": 3,
		"type": "do_it",
		"title": "State Drives Building",
		"mayor_dialogue": "Inside update_citizen(), add: if state == \"celebrating\": place_building(\"park\", day, 0). Celebrating citizens build parks!",
		"instruction": "Add to update_citizen():\nif state == \"celebrating\":\n    place_building(\"park\", 0, 0)",
		"show_grid_diagram": false,
		"starter_code": "var state = \"idle\"\nvar happiness = 5\n\nfunction update_citizen():\n    if happiness > 7:\n        state = \"celebrating\"\n    elif happiness > 3:\n        state = \"working\"\n    else:\n        state = \"idle\"",
		"hint": "Add the building action based on state.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "place_building"],
	},
	{
		"id": 4,
		"type": "do_it",
		"title": "Add Transitions",
		"mayor_dialogue": "Add rules: celebrating +1 happiness, idle -1 happiness, working stays same. Watch the pattern emerge!",
		"instruction": "Add state changes:\n- celebrating: happiness += 1\n- idle: happiness -= 1\n- working: happiness += 0",
		"show_grid_diagram": false,
		"starter_code": "var state = \"idle\"\nvar happiness = 5\n\nfunction update_citizen():\n    if happiness > 7:\n        state = \"celebrating\"\n    elif happiness > 3:\n        state = \"working\"\n    else:\n        state = \"idle\"",
		"hint": "Change happiness based on state inside the function.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "place_building"],
	},
	{
		"id": 5,
		"type": "do_it",
		"title": "Use Match Instead",
		"mayor_dialogue": "Replace the if/elif chain with a match statement. Match is cleaner for state machines!",
		"instruction": "Replace if/elif with:\nmatch state:\n    case \"celebrating\":\n        happiness += 1\n    case \"working\":\n        pass\n    case \"idle\":\n        happiness -= 1",
		"show_grid_diagram": false,
		"starter_code": "var state = \"idle\"\nvar happiness = 5\n\nfunction update_citizen():\n    if happiness > 7:\n        state = \"celebrating\"\n    elif happiness > 3:\n        state = \"working\"\n    else:\n        state = \"idle\"\n    if state == \"celebrating\":\n        happiness += 1\n    elif state == \"idle\":\n        happiness -= 1\n    print(state + \": \" + str(happiness))",
		"hint": "Use match state: with case statements.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "print"],
	},
	{
		"id": 6,
		"type": "challenge",
		"title": "Three Citizens",
		"mayor_dialogue": "Create three citizens as dictionaries. Run each through update_citizen for 8 days. Place different buildings per state!",
		"instruction": "Create array of 3 citizens. Loop 8 days, update each. Buildings: celebrating=park, working=shop, idle=house.",
		"show_grid_diagram": false,
		"starter_code": "var citizens = [\n    {\"state\": \"idle\", \"happiness\": 5},\n    {\"state\": \"working\", \"happiness\": 6},\n    {\"state\": \"celebrating\", \"happiness\": 8}\n]\n\nfunction update_citizen(c):\n    if c[\"happiness\"] > 7:\n        c[\"state\"] = \"celebrating\"\n    elif c[\"happiness\"] > 3:\n        c[\"state\"] = \"working\"\n    else:\n        c[\"state\"] = \"idle\"",
		"hint": "Loop through citizens and call update_citizen for each.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 3,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "for", "place_building"],
	},
	{
		"id": 7,
		"type": "do_it",
		"title": "Match Actions",
		"mayor_dialogue": "Use match to handle state-based actions: park for celebrating, shop for working, house for idle!",
		"instruction": "Add match in update_citizen for building placement based on state.",
		"show_grid_diagram": false,
		"starter_code": "var state = \"idle\"\nvar happiness = 5\n\nfunction update_citizen(day):\n    if happiness > 7:\n        state = \"celebrating\"\n    elif happiness > 3:\n        state = \"working\"\n    else:\n        state = \"idle\"\n    match state:\n        case \"celebrating\":\n            place_building(\"park\", day, 0)\n        case \"working\":\n            place_building(\"shop\", day, 0)\n        case \"idle\":\n            place_building(\"house\", day, 0)",
		"hint": "Use match state: with case statements for buildings.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "place_building"],
	},
	{
		"id": 8,
		"type": "challenge",
		"title": "State Machine Loop",
		"mayor_dialogue": "Run the NPC through 10 days. Watch state changes drive building placement!",
		"instruction": "Loop 10 days. Call update_citizen each day. Watch the pattern!",
		"show_grid_diagram": false,
		"starter_code": "var state = \"idle\"\nvar happiness = 5\n\nfunction update_citizen(day):\n    if happiness > 7:\n        state = \"celebrating\"\n        happiness += 1\n    elif happiness > 3:\n        state = \"working\"\n    else:\n        state = \"idle\"\n        happiness -= 1\n    match state:\n        case \"celebrating\":\n            place_building(\"park\", day, 0)\n        case \"working\":\n            place_building(\"shop\", day, 0)\n        case \"idle\":\n            place_building(\"house\", day, 0)",
		"hint": "Add: for day in range(10): update_citizen(day)",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 5,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "for", "place_building"],
	},
	{
		"id": 9,
		"type": "guided",
		"title": "Why State Machines?",
		"mayor_dialogue": "State machines are predictable, debuggable, and scalable. Instead of complex if/else chains, you have: state → action.",
		"instruction": "match state is cleaner than many if/elif branches. Easy to add new states!",
		"show_grid_diagram": false,
		"starter_code": "var state = \"idle\"\n\nfunction do_action():\n    match state:\n        case \"idle\":\n            print(\"Resting...\")\n        case \"working\":\n            print(\"Working...\")\n        case \"celebrating\":\n            print(\"Partying!\")\n        case _:\n            print(\"Unknown state\")\n\nstate = \"working\"\ndo_action()",
		"hint": "The underscore _ is the default case.",
		"success_condition": "code_runs",
		"required_buildings": [],
		"required_count": 0,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "print"],
	},
	{
		"id": 10,
		"type": "mastery",
		"title": "NPC City",
		"mayor_dialogue": "You've mastered state machines! Build a complete city of NPCs with diverse states and behaviors.",
		"instruction": "Create 5 NPCs with different starting happiness. Run 10 days. Each NPC places buildings based on their state each day. Print a final census.",
		"show_grid_diagram": false,
		"starter_code": "var npcs = [\n    {\"state\": \"idle\", \"happiness\": 2, \"id\": 0},\n    {\"state\": \"working\", \"happiness\": 5, \"id\": 1}\n]\n\nfunction update_npc(npc, day):\n    if npc[\"happiness\"] > 7:\n        npc[\"state\"] = \"celebrating\"\n    elif npc[\"happiness\"] > 3:\n        npc[\"state\"] = \"working\"\n    else:\n        npc[\"state\"] = \"idle\"",
		"hint": "Loop days and NPCs, call update_npc for each.",
		"success_condition": "count",
		"required_buildings": [],
		"required_count": 10,
		"required_types": 0,
		"available_commands": ["var", "function", "if", "elif", "match", "for", "place_building", "print"],
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
