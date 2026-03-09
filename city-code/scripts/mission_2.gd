extends Node

# Mission 2: A Row of Homes
# Curriculum concept: For Loops
# The student must use a for loop to build 5 houses in a row.

signal mission_completed
signal mission_feedback(message: String)
signal mission_hint(hint_text: String, hint_number: int)
signal bonus_complete

const GRID_MIN := 0
const GRID_MAX := 9
const HOUSE_INDEX := 7  # building-small-a
const REQUIRED_HOUSES := 5

var gridmap: GridMap = null
var completed := false
var _idle_timer := 0.0
var _hints_shown := 0
var _code_has_run := false
var _placed_houses: Array = []  # Array of Vector2i
var _bonus_completed := false

var building_names := {
	"house": HOUSE_INDEX,
}

var hints := [
	"The ??? is where your house goes left-right! Try replacing ??? with the letter [b]i[/b]",
	"Type the letter [b]i[/b] where the ??? is. Each time the loop runs, i gets bigger: 1, 2, 3, 4, 5!",
	"Here, let me type it for you..."
]

var _hint_thresholds := [30.0, 60.0, 90.0]

var mission_title := "Mission 2: A Row of Homes"
var mission_description := "Builder Bob needs 5 houses in a row! Use a loop to build them."
var character := "Builder Bob"
var starter_code := """-- Mayor Maple needs 5 houses in a row!
-- A loop builds things over and over.
-- Change the ??? to make houses appear!

for i = 1, 5 do
    place_building("house", ???, 2)
end
"""


func setup(gm: GridMap) -> void:
	gridmap = gm


func _process(delta: float) -> void:
	if completed:
		return

	_idle_timer += delta

	for i in range(_hints_shown, _hint_thresholds.size()):
		if _idle_timer >= _hint_thresholds[i]:
			_hints_shown = i + 1
			mission_hint.emit(hints[i], _hints_shown)


func reset_idle_timer() -> void:
	_idle_timer = 0.0


func on_code_run() -> void:
	_code_has_run = true
	reset_idle_timer()
	_placed_houses.clear()


func api_place_building(args: Array, line_num: int) -> String:
	if args.size() != 3:
		return "Line %d: place_building needs 3 things: a name, x, and y. Example: place_building(\"house\", 5, 2)" % line_num

	var building_name = args[0]
	var x = args[1]
	var y = args[2]

	# Validate building name is a string
	if not building_name is String:
		return "Line %d: The first thing should be a building name in quotes, like \"house\"" % line_num

	var bname_lower: String = building_name.to_lower()
	if bname_lower not in building_names:
		return "Line %d: I don't know how to build a \"%s\". Try \"house\"!" % [line_num, building_name]

	# Validate x and y are numbers
	if not x is int and not x is float:
		return "Line %d: The x position should be a number (0-9), not \"%s\"" % [line_num, str(x)]
	if not y is int and not y is float:
		return "Line %d: The y position should be a number (0-9), not \"%s\"" % [line_num, str(y)]

	var xi: int = int(x)
	var yi: int = int(y)

	# Validate bounds
	if xi < GRID_MIN or xi > GRID_MAX:
		return "Line %d: The x position %d is off the map! Use a number between %d and %d." % [line_num, xi, GRID_MIN, GRID_MAX]
	if yi < GRID_MIN or yi > GRID_MAX:
		return "Line %d: The y position %d is off the map! Use a number between %d and %d." % [line_num, yi, GRID_MIN, GRID_MAX]

	if not gridmap:
		return "Line %d: Oops, the city grid isn't ready yet. Try again in a moment!" % line_num

	# Check for overlapping houses
	var pos := Vector2i(xi, yi)
	for placed in _placed_houses:
		if placed == pos:
			return "Line %d: The houses are piling up! Make sure each house has a different spot. Try using i for the x position!" % line_num

	# Place the building
	var structure_index: int = building_names[bname_lower]
	var cell_pos := Vector3i(xi, 0, yi)
	gridmap.set_cell_item(cell_pos, structure_index)
	_placed_houses.append(pos)

	mission_feedback.emit("Placed a %s at (%d, %d)! [%d/%d]" % [bname_lower, xi, yi, _placed_houses.size(), REQUIRED_HOUSES])

	# Check main completion: 5+ houses at unique x positions
	if not completed and _placed_houses.size() >= REQUIRED_HOUSES:
		var unique_x := {}
		for p in _placed_houses:
			unique_x[p.x] = true
		if unique_x.size() >= REQUIRED_HOUSES:
			completed = true
			mission_completed.emit()

	return ""


func check_bonus() -> bool:
	# Bonus: 10 houses in 2 rows (y=2 and y=4)
	if _placed_houses.size() >= 10:
		var rows := {}
		for p in _placed_houses:
			if not rows.has(p.y):
				rows[p.y] = []
			rows[p.y].append(p.x)
		if rows.size() >= 2:
			var valid_rows := 0
			for row_y in rows:
				if rows[row_y].size() >= 5:
					valid_rows += 1
			if valid_rows >= 2:
				_bonus_completed = true
				bonus_complete.emit()
				return true
	return false
