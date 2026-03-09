extends Node

# CodeRunner — Parses student code line-by-line and dispatches API calls
# to the active mission node. Supports Lua-style for loops.

signal code_started
signal code_finished
signal code_error(message: String, line_num: int)
signal code_output(message: String)
signal loop_iteration(var_name: String, value: int, total: int)

# Known API function names students can call
var known_functions := ["place_building", "print"]

# Typo suggestions for common mistakes
var _typo_map := {
	"placebuilding": "place_building",
	"place_bulding": "place_building",
	"place_biulding": "place_building",
	"plac_building": "place_building",
	"place_buidling": "place_building",
	"place_buildin": "place_building",
	"place_buildings": "place_building",
	"plase_building": "place_building",
	"palce_building": "place_building",
}

var active_mission: Node = null
var _running := false
var _last_code: String = ""


func _ready() -> void:
	if JSBridge:
		JSBridge.run_pressed.connect(_on_run_pressed)
		JSBridge.code_changed.connect(_on_code_changed)


func _on_run_pressed(code: String) -> void:
	run_code(code)


func _on_code_changed(code: String) -> void:
	# Store latest code for re-runs; no auto-execute
	_last_code = code


func set_mission(mission: Node) -> void:
	active_mission = mission


func run_code(source: String) -> void:
	if _running:
		code_error.emit("Code is already running! Wait for it to finish.", 0)
		return

	code_started.emit()
	_running = true

	var lines := source.split("\n")
	var had_error := false
	var i := 0

	while i < lines.size():
		var line_num := i + 1
		var line := lines[i].strip_edges()

		# Skip empty lines and comments
		if line.is_empty() or line.begins_with("#") or line.begins_with("--"):
			i += 1
			continue

		# Check for 'for' loop start
		if _is_for_loop_start(line):
			var loop_result = await _execute_for_loop(lines, i)
			if loop_result.error != "":
				code_error.emit(loop_result.error, loop_result.error_line)
				had_error = true
				break
			i = loop_result.end_index + 1
			continue

		# Check for stray 'end'
		if line.to_lower() == "end":
			code_error.emit("Line %d: Found 'end' without a matching 'for' loop!" % line_num, line_num)
			had_error = true
			break

		# Try to parse a function call
		var result := _parse_function_call(line, line_num)
		if result.error != "":
			code_error.emit(result.error, line_num)
			had_error = true
			break  # Stop on first error for kids

		# Dispatch to active mission
		if result.func_name != "" and active_mission:
			var dispatch_error := _dispatch(result.func_name, result.args, line_num)
			if dispatch_error != "":
				code_error.emit(dispatch_error, line_num)
				had_error = true
				break

		i += 1

	if not had_error:
		code_output.emit("Code finished running!")

	code_finished.emit()
	_running = false


# --- For Loop Support ---

func _is_for_loop_start(line: String) -> bool:
	var lower := line.to_lower().strip_edges()
	return lower.begins_with("for ") and lower.ends_with(" do")


func _execute_for_loop(lines: PackedStringArray, start_index: int) -> Dictionary:
	var result := {"error": "", "error_line": start_index + 1, "end_index": start_index}
	var line := lines[start_index].strip_edges()
	var line_num := start_index + 1

	# Strip "for " prefix and " do" suffix
	var inner := line.substr(4).strip_edges()
	# Find last " do" (case insensitive)
	var lower_inner := inner.to_lower()
	var do_pos := lower_inner.rfind(" do")
	if do_pos == -1:
		result.error = "Line %d: Every 'for' needs 'do' at the end! Try: for i = 1, 5 do" % line_num
		result.error_line = line_num
		return result
	inner = inner.substr(0, do_pos).strip_edges()

	# Parse "VAR = START, END"
	var eq_pos := inner.find("=")
	if eq_pos == -1:
		result.error = "Line %d: For loops need an equals sign: for i = 1, 5 do" % line_num
		result.error_line = line_num
		return result

	var var_name := inner.substr(0, eq_pos).strip_edges()
	var range_str := inner.substr(eq_pos + 1).strip_edges()

	# Check for comma
	var comma_pos := range_str.find(",")
	if comma_pos == -1:
		result.error = "Line %d: For loops need a comma: for i = 1, 5 do" % line_num
		result.error_line = line_num
		return result

	var start_str := range_str.substr(0, comma_pos).strip_edges()
	var end_str := range_str.substr(comma_pos + 1).strip_edges()

	if not start_str.is_valid_int() or not end_str.is_valid_int():
		result.error = "Line %d: The loop range should be numbers, like: for i = 1, 5 do" % line_num
		result.error_line = line_num
		return result

	var loop_start := start_str.to_int()
	var loop_end := end_str.to_int()
	var iterations := loop_end - loop_start + 1

	if iterations > 20:
		result.error = "Line %d: That's too many loops! Keep it under 20 to avoid a traffic jam." % line_num
		result.error_line = line_num
		return result

	if iterations <= 0:
		result.error = "Line %d: The second number should be bigger than the first: for i = 1, 5 do" % line_num
		result.error_line = line_num
		return result

	# Collect loop body lines until "end"
	var body_lines: Array = []
	var body_line_nums: Array = []
	var end_found := false
	var j := start_index + 1
	while j < lines.size():
		var body_line := lines[j].strip_edges()
		if body_line.to_lower() == "end":
			end_found = true
			result.end_index = j
			break
		if not body_line.is_empty() and not body_line.begins_with("#") and not body_line.begins_with("--"):
			body_lines.append(body_line)
			body_line_nums.append(j + 1)
		j += 1

	if not end_found:
		result.error = "Line %d: Almost there! Every loop needs an 'end' at the bottom. Add the word end on its own line." % line_num
		result.error_line = line_num
		return result

	# Check if loop variable is used in any body line
	if body_lines.size() > 0:
		var var_used := false
		var has_placeholder := false
		for bl in body_lines:
			if _has_variable(bl, var_name):
				var_used = true
				break
			if bl.find("???") != -1:
				has_placeholder = true
		if has_placeholder and not var_used:
			result.error = "Line %d: Replace the ??? with the letter %s — it changes each time the loop runs!" % [body_line_nums[0], var_name]
			result.error_line = body_line_nums[0]
			return result
		if not var_used and not has_placeholder:
			result.error = "Line %d: All your houses are in the same spot! Use the letter %s to move them. %s changes every time the loop runs!" % [body_line_nums[0], var_name, var_name]
			result.error_line = body_line_nums[0]
			return result

	# Execute loop body for each iteration
	for iter_val in range(loop_start, loop_end + 1):
		var iter_num := iter_val - loop_start + 1
		loop_iteration.emit(var_name, iter_val, iterations)
		code_output.emit("Running loop: %s = %d" % [var_name, iter_val])

		for bi in range(body_lines.size()):
			var substituted := _substitute_loop_var(body_lines[bi], var_name, iter_val)
			var parse_result := _parse_function_call(substituted, body_line_nums[bi])
			if parse_result.error != "":
				result.error = parse_result.error
				result.error_line = body_line_nums[bi]
				return result

			if parse_result.func_name != "" and active_mission:
				var dispatch_error := _dispatch(parse_result.func_name, parse_result.args, body_line_nums[bi])
				if dispatch_error != "":
					result.error = dispatch_error
					result.error_line = body_line_nums[bi]
					return result

		# Delay between iterations so kids can watch
		if iter_val < loop_end:
			await get_tree().create_timer(0.3).timeout

	return result


func _has_variable(line: String, var_name: String) -> bool:
	# Check if var_name appears as a standalone identifier in the line
	var idx := 0
	while idx < line.length():
		var pos := line.find(var_name, idx)
		if pos == -1:
			return false
		var before_ok := (pos == 0 or not _is_ident_char(line[pos - 1]))
		var after_pos := pos + var_name.length()
		var after_ok := (after_pos >= line.length() or not _is_ident_char(line[after_pos]))
		if before_ok and after_ok:
			return true
		idx = pos + 1
	return false


func _is_ident_char(c: String) -> bool:
	if c.length() != 1:
		return false
	var code := c.unicode_at(0)
	return (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or (code >= 48 and code <= 57) or c == "_"


func _substitute_loop_var(line: String, var_name: String, value: int) -> String:
	# Replace standalone occurrences of var_name with value (outside quotes)
	var result := ""
	var in_string := false
	var string_char := ""
	var idx := 0

	while idx < line.length():
		var c := line[idx]

		if not in_string and (c == "\"" or c == "'"):
			in_string = true
			string_char = c
			result += c
			idx += 1
		elif in_string and c == string_char:
			in_string = false
			result += c
			idx += 1
		elif not in_string and idx + var_name.length() <= line.length():
			var candidate := line.substr(idx, var_name.length())
			if candidate == var_name:
				var before_ok := (idx == 0 or not _is_ident_char(line[idx - 1]))
				var after_pos := idx + var_name.length()
				var after_ok := (after_pos >= line.length() or not _is_ident_char(line[after_pos]))
				if before_ok and after_ok:
					result += str(value)
					idx += var_name.length()
					continue
			result += c
			idx += 1
		else:
			result += c
			idx += 1

	return result


# --- Existing Parsing ---

func _parse_function_call(line: String, line_num: int) -> Dictionary:
	var result := {"func_name": "", "args": [], "error": ""}

	# Match pattern: function_name(args)
	var paren_open := line.find("(")
	var paren_close := line.rfind(")")

	if paren_open == -1 and paren_close == -1:
		# Not a function call — check if it looks like an attempt
		var stripped := line.replace(" ", "").to_lower()
		for known in known_functions:
			if stripped.begins_with(known.to_lower()):
				result.error = "Line %d: Oops! It looks like you forgot the parentheses (). Try: %s(\"house\", 5, 5)" % [line_num, known]
				return result
		# Check for typos
		for typo in _typo_map:
			if stripped.begins_with(typo):
				result.error = "Line %d: Almost! Did you mean '%s'? Check your spelling!" % [line_num, _typo_map[typo]]
				return result
		# Unknown line — skip silently
		return result

	if paren_open == -1 or paren_close == -1 or paren_close < paren_open:
		result.error = "Line %d: Hmm, it looks like you're missing a parenthesis. Make sure you have both ( and )!" % line_num
		return result

	var func_name := line.substr(0, paren_open).strip_edges().to_lower()
	var args_str := line.substr(paren_open + 1, paren_close - paren_open - 1).strip_edges()

	# Check for typos in function name
	if func_name not in known_functions:
		if func_name in _typo_map:
			result.error = "Line %d: Almost! Did you mean '%s'? Check your spelling!" % [line_num, _typo_map[func_name]]
		else:
			result.error = "Line %d: I don't know a function called '%s'. Try using place_building(\"house\", 5, 5)" % [line_num, func_name]
		return result

	# Parse arguments
	var args := _parse_args(args_str, line_num)
	if args.error != "":
		result.error = args.error
		return result

	result.func_name = func_name
	result.args = args.values
	return result


func _parse_args(args_str: String, line_num: int) -> Dictionary:
	var result := {"values": [], "error": ""}

	if args_str.is_empty():
		return result

	var parts := args_str.split(",")
	for part in parts:
		var trimmed := part.strip_edges()
		if trimmed.is_empty():
			continue

		# String argument (quoted)
		if (trimmed.begins_with("\"") and trimmed.ends_with("\"")) or \
		   (trimmed.begins_with("'") and trimmed.ends_with("'")):
			var str_val := trimmed.substr(1, trimmed.length() - 2)
			result.values.append(str_val)

		# Check for ??? placeholder
		elif trimmed.find("???") != -1:
			result.error = "Line %d: Replace the ??? with the loop variable! Try putting i there instead." % line_num
			return result

		# Check for unquoted string (common kid mistake)
		elif trimmed.to_lower() in ["house", "road", "tree", "grass", "building"]:
			result.error = "Line %d: Don't forget the quotes! Write \"%s\" with quotation marks around it." % [line_num, trimmed]
			return result

		# Number argument
		elif trimmed.is_valid_int():
			result.values.append(trimmed.to_int())

		# Simple math expression (after loop var substitution: "2 * 2", "1 + 3")
		elif _is_simple_math(trimmed):
			var val = _eval_simple_math(trimmed)
			if val != null:
				result.values.append(val)
			else:
				result.error = "Line %d: I can't solve the math in '%s'. Try simpler expressions like i + 1!" % [line_num, trimmed]
				return result

		else:
			result.error = "Line %d: I don't understand '%s'. Make sure strings have \"quotes\" and numbers are just digits!" % [line_num, trimmed]
			return result

	return result


func _is_simple_math(s: String) -> bool:
	for op in [" * ", " + ", " - "]:
		if s.find(op) != -1:
			return true
	return false


func _eval_simple_math(s: String) -> Variant:
	# Try each operator (order: *, +, -)
	for op in [" * ", " + ", " - "]:
		var pos := s.find(op)
		if pos != -1:
			var left := s.substr(0, pos).strip_edges()
			var right := s.substr(pos + op.length()).strip_edges()
			if left.is_valid_int() and right.is_valid_int():
				var l := left.to_int()
				var r := right.to_int()
				match op.strip_edges():
					"*": return l * r
					"+": return l + r
					"-": return l - r
	return null


func _dispatch(func_name: String, args: Array, line_num: int) -> String:
	if not active_mission:
		return "Line %d: No mission is active right now." % line_num

	match func_name:
		"place_building":
			if active_mission.has_method("api_place_building"):
				return active_mission.api_place_building(args, line_num)
		"print":
			if args.size() >= 1:
				var msg := str(args[0])
				if active_mission.has_method("api_print"):
					active_mission.api_print(msg)
				else:
					code_output.emit(msg)
				return ""
			return "Line %d: print needs a message. Try: print(\"Hello!\")" % line_num

	return "Line %d: Function '%s' isn't available in this mission." % [line_num, func_name]
