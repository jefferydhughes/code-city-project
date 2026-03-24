extends Node

# CodeRunner — Parses student code line-by-line and dispatches API calls
# to the active mission node. Supports:
# - Lua-style for loops: for i = 1, 5 do ... end
# - Python-style for loops: for i in range(n): ...
# - While loops: while condition: ... (M11)
# - Dictionaries: {"key": value}, dict["key"] (M8)
# - Match statements: match var: case _: (M14)
# - Variables: var name = value
# - Arrays: ["a", "b", "c"] and arr[index]
# - If/elif/else conditionals
# - Functions with return: function name() -> int:
# - len(), str(), int() built-ins

signal code_started
signal code_finished
signal code_error(message: String, line_num: int)
signal code_output(message: String)
signal loop_iteration(var_name: String, value: int, total: int)

# Known API function names students can call
var known_functions := ["place_building", "print", "get_city_stat"]

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

# Variable storage for the current code run
var _variables := {}

# User-defined functions storage
var _user_functions := {}


func _ready() -> void:
	if JSBridge:
		JSBridge.run_pressed.connect(_on_run_pressed)
		JSBridge.code_changed.connect(_on_code_changed)


func _on_run_pressed(code: String) -> void:
	run_code(code)


func _on_code_changed(code: String) -> void:
	_last_code = code


func set_mission(mission: Node) -> void:
	active_mission = mission


func run_code(source: String) -> void:
	if _running:
		code_error.emit("Code is already running! Wait for it to finish.", 0)
		return

	code_started.emit()
	_running = true
	
	# Reset state for each run
	_variables.clear()
	_user_functions.clear()

	var lines := source.split("\n")
	var had_error := false
	var i := 0

	while i < lines.size():
		var line_num := i + 1
		var line := lines[i]
		var stripped := line.strip_edges()

		# Skip empty lines and comments
		if stripped.is_empty() or stripped.begins_with("#") or stripped.begins_with("--"):
			i += 1
			continue

		# Check for Lua-style for loop: for i = 1, 5 do
		if _is_lua_for_loop(stripped):
			var loop_result = await _execute_lua_for_loop(lines, i)
			if loop_result.error != "":
				code_error.emit(loop_result.error, loop_result.error_line)
				had_error = true
				break
			i = loop_result.end_index + 1
			continue

		# Check for Python-style for loop: for i in range(n):
		if _is_python_for_loop(stripped):
			var loop_result = await _execute_python_for_loop(lines, i)
			if loop_result.error != "":
				code_error.emit(loop_result.error, loop_result.error_line)
				had_error = true
				break
			i = loop_result.end_index + 1
			continue

		# Check for if/else conditional
		if _is_conditional_start(stripped):
			var cond_result = await _execute_conditional(lines, i)
			if cond_result.error != "":
				code_error.emit(cond_result.error, cond_result.error_line)
				had_error = true
				break
			i = cond_result.end_index + 1
			continue

		# Check for else: (must be standalone)
		if stripped.to_lower() == "else:":
			code_error.emit("Line %d: Found 'else:' without a matching 'if'!" % line_num, line_num)
			had_error = true
			break
		
		# Check for elif: (must be standalone)
		if stripped.to_lower().begins_with("elif "):
			code_error.emit("Line %d: Found 'elif' without a matching 'if'!" % line_num, line_num)
			had_error = true
			break
		
		# Check for while loop
		if _is_while_loop(stripped):
			var loop_result = await _execute_while_loop(lines, i)
			if loop_result.error != "":
				code_error.emit(loop_result.error, loop_result.error_line)
				had_error = true
				break
			i = loop_result.end_index + 1
			continue
		
		# Check for match statement
		if _is_match_statement(stripped):
			var match_result = await _execute_match(lines, i)
			if match_result.error != "":
				code_error.emit(match_result.error, match_result.error_line)
				had_error = true
				break
			i = match_result.end_index + 1
			continue
		
		# Check for stray 'end'
		if stripped.to_lower() == "end":
			code_error.emit("Line %d: Found 'end' without a matching block!" % line_num, line_num)
			had_error = true
			break

		# Check for variable declaration: var name = value
		if stripped.begins_with("var "):
			var var_result = _execute_var_declaration(stripped, line_num)
			if var_result.error != "":
				code_error.emit(var_result.error, line_num)
				had_error = true
				break
			i += 1
			continue

		# Check for function definition: function name(params):
		if stripped.begins_with("function "):
			var func_result = _execute_function_definition(lines, i)
			if func_result.error != "":
				code_error.emit(func_result.error, line_num)
				had_error = true
				break
			i = func_result.end_index + 1
			continue

		# Substitute variables in the line before parsing
		var substituted := _substitute_variables(stripped)

		# Try to parse a function call
		var result := _parse_function_call(substituted, line_num)
		if result.error != "":
			code_error.emit(result.error, line_num)
			had_error = true
			break

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


# ========================================================================
# VARIABLE SUPPORT
# ========================================================================

func _execute_var_declaration(line: String, line_num: int) -> Dictionary:
	var result := {"error": ""}
	var rest := line.substr(4).strip_edges()  # Remove "var "
	
	# Find the equals sign
	var eq_pos := rest.find("=")
	if eq_pos == -1:
		result.error = "Line %d: Variables need an equals sign. Try: var name = 5" % line_num
		return result
	
	var var_name := rest.substr(0, eq_pos).strip_edges()
	var value_str := rest.substr(eq_pos + 1).strip_edges()
	
	# Validate variable name
	if var_name.is_empty():
		result.error = "Line %d: Give your variable a name!" % line_num
		return result
	
	if not _is_valid_var_name(var_name):
		result.error = "Line %d: Variable names can't have spaces or special characters. Try: myVar" % line_num
		return result
	
	# Evaluate the value (could be a number, string, or expression)
	var value = _evaluate_expression(value_str, line_num)
	if value is Dictionary and value.has("error"):
		result.error = value.error
		return result
	
	_variables[var_name] = value
	return result


func _is_valid_var_name(name: String) -> bool:
	if name.is_empty():
		return false
	for i in name.length():
		var c := name[i]
		if i == 0:
			if not (c >= "a" and c <= "z") and not (c >= "A" and c <= "Z") and c != "_":
				return false
		else:
			if not (c >= "a" and c <= "z") and not (c >= "A" and c <= "Z") and not (c >= "0" and c <= "9") and c != "_":
				return false
	return true


func _substitute_variables(line: String) -> String:
	# Substitute variable references with their values
	var result := ""
	var i := 0
	
	while i < line.length():
		var c := line[i]
		
		# Skip strings
		if c == "\"" or c == "'":
			result += c
			i += 1
			var string_char := c
			while i < line.length() and line[i] != string_char:
				result += line[i]
				i += 1
			if i < line.length():
				result += line[i]
				i += 1
			continue
		
		# Check if this could be a variable name
		if (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_":
			var start := i
			while i < line.length() and _is_ident_char(line[i]):
				i += 1
			var name := line.substr(start, i - start)
			
			# Check if it's a variable
			if _variables.has(name):
				var value = _variables[name]
				if value is int or value is float:
					result += str(value)
				else:
					result += name  # Keep as-is for strings/arrays
			else:
				result += name
		else:
			result += c
			i += 1
	
	return result


func _evaluate_expression(expr: String, line_num: int) -> Variant:
	expr = expr.strip_edges()
	
	# Empty expression
	if expr.is_empty():
		return 0
	
	# String literal
	if (expr.begins_with("\"") and expr.ends_with("\"")) or \
	   (expr.begins_with("'") and expr.ends_with("'")):
		return expr.substr(1, expr.length() - 2)
	
	# Array literal
	if expr.begins_with("[") and expr.ends_with("]"):
		return _parse_array_literal(expr, line_num)
	
	# Dictionary literal
	if expr.begins_with("{") and expr.ends_with("}"):
		return _parse_dict_literal(expr, line_num)
	
	# Boolean
	if expr.to_lower() == "true":
		return true
	if expr.to_lower() == "false":
		return false
	
	# Simple math expression
	if _is_math_expression(expr):
		return _evaluate_math(expr, line_num)
	
	# Variable reference
	if _variables.has(expr):
		return _variables[expr]
	
	# Number
	if expr.is_valid_int():
		return expr.to_int()
	if expr.is_valid_float():
		return expr.to_float()
	
	return {"error": "Line %d: I don't understand '%s'" % [line_num, expr]}


func _parse_array_literal(expr: String, line_num: int) -> Array:
	var result := []
	var inner := expr.substr(1, expr.length() - 2)  # Remove [ and ]
	var parts := inner.split(",")
	for part in parts:
		var val = _evaluate_expression(part, line_num)
		if not (val is Dictionary and val.has("error")):
			result.append(val)
	return result


func _parse_dict_literal(expr: String, line_num: int) -> Dictionary:
	var result := {}
	var inner := expr.substr(1, expr.length() - 2).strip_edges()  # Remove { and }
	
	if inner.is_empty():
		return result
	
	var parts := _split_dict_entries(inner)
	for part in parts:
		var colon_pos := part.find(":")
		if colon_pos == -1:
			continue
		
		var key := part.substr(0, colon_pos).strip_edges()
		var value_str := part.substr(colon_pos + 1).strip_edges()
		
		if (key.begins_with("\"") and key.ends_with("\"")) or \
		   (key.begins_with("'") and key.ends_with("'")):
			key = key.substr(1, key.length() - 2)
		
		var val = _evaluate_expression(value_str, line_num)
		if not (val is Dictionary and val.has("error")):
			result[key] = val
	
	return result


func _split_dict_entries(inner: String) -> Array:
	var result := []
	var depth := 0
	var current := ""
	var in_string := false
	var string_char := ""
	
	for i in range(inner.length()):
		var c := inner[i]
		
		if not in_string and (c == "\"" or c == "'"):
			in_string = true
			string_char = c
		elif in_string and c == string_char:
			in_string = false
		elif not in_string:
			if c == "{" or c == "[":
				depth += 1
			elif c == "}" or c == "]":
				depth -= 1
			elif c == "," and depth == 0:
				result.append(current)
				current = ""
				continue
		
		current += c
	
	if not current.is_empty():
		result.append(current)
	
	return result


func _is_math_expression(expr: String) -> bool:
	for op in [" + ", " - ", " * ", " / ", "%"]:
		if expr.find(op) != -1:
			return true
	return false


func _evaluate_math(expr: String, line_num: int) -> Variant:
	# Handle operators in order: * / % + -
	var ops := [" * ", " / ", " % ", " + ", " - "]
	for op in ops:
		var pos := expr.find(op)
		if pos != -1:
			var left_str := expr.substr(0, pos).strip_edges()
			var right_str := expr.substr(pos + op.length()).strip_edges()
			
			var left = _evaluate_simple_value(left_str, line_num)
			var right = _evaluate_simple_value(right_str, line_num)
			
			if left is Dictionary and left.has("error"):
				return left
			if right is Dictionary and right.has("error"):
				return right
			
			match op:
				" * ": return int(left) * int(right)
				" / ":
					if int(right) == 0:
						return {"error": "Line %d: Can't divide by zero!" % line_num}
					return int(left) / int(right)
				" % ":
					if int(right) == 0:
						return {"error": "Line %d: Can't divide by zero!" % line_num}
					return int(left) % int(right)
				" + ": return int(left) + int(right)
				" - ": return int(left) - int(right)
	
	return {"error": "Line %d: Can't calculate '%s'" % [line_num, expr]}


func _evaluate_simple_value(expr: String, line_num: int) -> Variant:
	expr = expr.strip_edges()
	
	if _variables.has(expr):
		return _variables[expr]
	if expr.is_valid_int():
		return expr.to_int()
	if expr.is_valid_float():
		return expr.to_float()
	
	return {"error": "Line %d: Unknown value '%s'" % [line_num, expr]}


# ========================================================================
# PYTHON-STYLE FOR LOOP: for i in range(n):
# ========================================================================

func _is_python_for_loop(line: String) -> bool:
	var lower := line.to_lower().strip_edges()
	return lower.begins_with("for ") and lower.find(" in range(") != -1 and lower.ends_with(":")


func _execute_python_for_loop(lines: PackedStringArray, start_index: int) -> Dictionary:
	var result := {"error": "", "error_line": start_index + 1, "end_index": start_index}
	var line := lines[start_index].strip_edges()
	var line_num := start_index + 1

	# Parse: for VAR in range(N):
	var lower := line.to_lower()
	
	# Extract variable name
	var for_start := 4  # Skip "for "
	var in_pos := lower.find(" in range(")
	if in_pos == -1:
		result.error = "Line %d: For loops need 'in range()'. Try: for i in range(5):" % line_num
		return result
	
	var var_name := line.substr(for_start, in_pos - for_start).strip_edges()
	
	# Extract range argument
	var range_start := in_pos + 10  # Skip " in range("
	var range_end := line.rfind("):")
	if range_end == -1 or range_end < range_start:
		result.error = "Line %d: For loops need parentheses. Try: for i in range(5):" % line_num
		return result
	
	var range_arg := line.substr(range_start, range_end - range_start).strip_edges()
	
	# Evaluate range argument
	var range_val = _evaluate_expression(range_arg, line_num)
	if range_val is Dictionary and range_val.has("error"):
		result.error = range_val.error
		return result
	
	var iterations := int(range_val)
	
	if iterations > 20:
		result.error = "Line %d: That's too many loops! Keep it under 20 to avoid a traffic jam." % line_num
		return result
	
	if iterations <= 0:
		result.error = "Line %d: The range should be bigger than 0. Try range(5) for 5 items." % line_num
		return result

	# Find the indented body (lines with more indentation than the for statement)
	var base_indent := _get_line_indent(lines[start_index])
	var body_lines := []
	var body_line_nums := []
	var end_index := start_index + 1
	
	while end_index < lines.size():
		var body_line := lines[end_index]
		if body_line.strip_edges().is_empty():
			end_index += 1
			continue
		
		var body_indent := _get_line_indent(body_line)
		if body_indent <= base_indent and not body_line.strip_edges().begins_with("#"):
			break  # End of block
		
		if not body_line.strip_edges().begins_with("#") and not body_line.strip_edges().is_empty():
			body_lines.append(body_line.strip_edges())
			body_line_nums.append(end_index + 1)
		end_index += 1
	
	result.end_index = end_index - 1
	
	if body_lines.is_empty():
		result.error = "Line %d: The loop body is empty! Add some code after the for line." % line_num
		return result

	# Execute loop body for each iteration
	for iter_val in range(iterations):
		loop_iteration.emit(var_name, iter_val, iterations)
		code_output.emit("Running loop: %s = %d" % [var_name, iter_val])
		
		for bi in range(body_lines.size()):
			var body_line := body_lines[bi]
			var body_line_num := body_line_nums[bi]
			
			# Substitute loop variable
			var substituted := _substitute_loop_var(body_line, var_name, iter_val)
			substituted = _substitute_variables(substituted)
			
			# Handle nested loops and conditionals in body
			if _is_python_for_loop(substituted):
				var nested_result = await _execute_python_for_loop(body_lines, bi)
				if nested_result.error != "":
					result.error = nested_result.error
					result.error_line = nested_result.error_line
					return result
				bi = nested_result.end_index
				continue
			
			if _is_conditional_start(substituted):
				var cond_result = await _execute_conditional(body_lines, bi)
				if cond_result.error != "":
					result.error = cond_result.error
					result.error_line = cond_result.error_line
					return result
				bi = cond_result.end_index
				continue
			
			# Parse and dispatch
			var parse_result := _parse_function_call(substituted, body_line_num)
			if parse_result.error != "":
				result.error = parse_result.error
				result.error_line = body_line_num
				return result
			
			if parse_result.func_name != "" and active_mission:
				var dispatch_error := _dispatch(parse_result.func_name, parse_result.args, body_line_num)
				if dispatch_error != "":
					result.error = dispatch_error
					result.error_line = body_line_num
					return result
		
		# Delay between iterations so kids can watch
		if iter_val < iterations - 1:
			await get_tree().create_timer(0.3).timeout

	return result


# ========================================================================
# LUA-STYLE FOR LOOP: for i = 1, 5 do ... end
# ========================================================================

func _is_lua_for_loop(line: String) -> bool:
	var lower := line.to_lower().strip_edges()
	return lower.begins_with("for ") and lower.ends_with(" do")


func _execute_lua_for_loop(lines: PackedStringArray, start_index: int) -> Dictionary:
	var result := {"error": "", "error_line": start_index + 1, "end_index": start_index}
	var line := lines[start_index].strip_edges()
	var line_num := start_index + 1

	# Strip "for " prefix and " do" suffix
	var inner := line.substr(4).strip_edges()
	var lower_inner := inner.to_lower()
	var do_pos := lower_inner.rfind(" do")
	if do_pos == -1:
		result.error = "Line %d: Every 'for' needs 'do' at the end! Try: for i = 1, 5 do" % line_num
		return result
	inner = inner.substr(0, do_pos).strip_edges()

	# Parse "VAR = START, END"
	var eq_pos := inner.find("=")
	if eq_pos == -1:
		result.error = "Line %d: For loops need an equals sign: for i = 1, 5 do" % line_num
		return result

	var var_name := inner.substr(0, eq_pos).strip_edges()
	var range_str := inner.substr(eq_pos + 1).strip_edges()

	var comma_pos := range_str.find(",")
	if comma_pos == -1:
		result.error = "Line %d: For loops need a comma: for i = 1, 5 do" % line_num
		return result

	var start_str := range_str.substr(0, comma_pos).strip_edges()
	var end_str := range_str.substr(comma_pos + 1).strip_edges()

	if not start_str.is_valid_int() or not end_str.is_valid_int():
		result.error = "Line %d: The loop range should be numbers, like: for i = 1, 5 do" % line_num
		return result

	var loop_start := start_str.to_int()
	var loop_end := end_str.to_int()
	var iterations := loop_end - loop_start + 1

	if iterations > 20:
		result.error = "Line %d: That's too many loops! Keep it under 20 to avoid a traffic jam." % line_num
		return result

	if iterations <= 0:
		result.error = "Line %d: The second number should be bigger than the first: for i = 1, 5 do" % line_num
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
		result.error = "Line %d: Almost there! Every loop needs an 'end' at the bottom." % line_num
		return result

	# Execute loop body for each iteration
	for iter_val in range(loop_start, loop_end + 1):
		var iter_num := iter_val - loop_start + 1
		loop_iteration.emit(var_name, iter_val, iterations)
		code_output.emit("Running loop: %s = %d" % [var_name, iter_val])

		for bi in range(body_lines.size()):
			var substituted := _substitute_loop_var(body_lines[bi], var_name, iter_val)
			substituted = _substitute_variables(substituted)
			
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

		if iter_val < loop_end:
			await get_tree().create_timer(0.3).timeout

	return result


# ========================================================================
# WHILE LOOPS (M11)
# ========================================================================

func _is_while_loop(line: String) -> bool:
	var lower := line.to_lower().strip_edges()
	return lower.begins_with("while ") and lower.ends_with(":")


func _execute_while_loop(lines: PackedStringArray, start_index: int) -> Dictionary:
	var result := {"error": "", "error_line": start_index + 1, "end_index": start_index}
	var line := lines[start_index].strip_edges()
	var line_num := start_index + 1

	var lower := line.to_lower()
	var while_pos := lower.find("while ") + 6
	var colon_pos := line.rfind(":")
	if colon_pos == -1 or colon_pos <= while_pos:
		result.error = "Line %d: While loops need a colon. Try: while energy > 0:" % line_num
		return result
	
	var condition_str := line.substr(while_pos, colon_pos - while_pos).strip_edges()
	var base_indent := _get_line_indent(lines[start_index])
	
	var body_lines := []
	var body_line_nums := []
	var end_index := start_index + 1
	
	while end_index < lines.size():
		var body_line := lines[end_index]
		var stripped := body_line.strip_edges()
		if stripped.is_empty():
			end_index += 1
			continue
		var body_indent := _get_line_indent(body_line)
		if body_indent <= base_indent and not stripped.begins_with("#"):
			break
		if not stripped.begins_with("#"):
			body_lines.append(stripped)
			body_line_nums.append(end_index + 1)
		end_index += 1
	
	result.end_index = end_index - 1
	
	if body_lines.is_empty():
		result.error = "Line %d: The loop body is empty! Add some code after the while line." % line_num
		return result
	
	var max_iterations := 100
	var iteration := 0
	
	while iteration < max_iterations:
		iteration += 1
		
		var cond_result = _evaluate_condition(condition_str, line_num)
		if cond_result is Dictionary and cond_result.has("error"):
			result.error = cond_result.error
			return result
		
		if not (cond_result as bool):
			break
		
		for bi in range(body_lines.size()):
			var body_line := body_lines[bi]
			var body_line_num := body_line_nums[bi]
			
			body_line = _substitute_variables(body_line)
			
			if body_line.to_lower() == "break":
				return result
			
			if _is_python_for_loop(body_line):
				var loop_result = await _execute_python_for_loop(body_lines, bi)
				if loop_result.error != "":
					result.error = loop_result.error
					result.error_line = loop_result.error_line
					return result
				bi = loop_result.end_index
				continue
			
			if _is_while_loop(body_line):
				var nested_result = await _execute_while_loop(body_lines, bi)
				if nested_result.error != "":
					result.error = nested_result.error
					result.error_line = nested_result.error_line
					return result
				bi = nested_result.end_index
				continue
			
			if _is_conditional_start(body_line):
				var cond_result2 = await _execute_conditional(body_lines, bi)
				if cond_result2.error != "":
					result.error = cond_result2.error
					result.error_line = cond_result2.error_line
					return result
				bi = cond_result2.end_index
				continue
			
			if _is_match_statement(body_line):
				var match_result = await _execute_match(body_lines, bi)
				if match_result.error != "":
					result.error = match_result.error
					result.error_line = match_result.error_line
					return result
				bi = match_result.end_index
				continue
			
			var parse_result := _parse_function_call(body_line, body_line_num)
			if parse_result.error != "":
				result.error = parse_result.error
				result.error_line = body_line_num
				return result
			
			if parse_result.func_name != "" and active_mission:
				var dispatch_error := _dispatch(parse_result.func_name, parse_result.args, body_line_num)
				if dispatch_error != "":
					result.error = dispatch_error
					result.error_line = body_line_num
					return result
		
		if iteration < max_iterations:
			await get_tree().create_timer(0.2).timeout
	
	if iteration >= max_iterations:
		result.error = "Line %d: Infinite loop detected! The condition never became false." % line_num
		return result
	
	return result


# ========================================================================
# MATCH STATEMENTS (M14)
# ========================================================================

func _is_match_statement(line: String) -> bool:
	var lower := line.to_lower().strip_edges()
	return lower.begins_with("match ") and lower.ends_with(":")


func _execute_match(lines: PackedStringArray, start_index: int) -> Dictionary:
	var result := {"error": "", "error_line": start_index + 1, "end_index": start_index}
	var line := lines[start_index].strip_edges()
	var line_num := start_index + 1

	var lower := line.to_lower()
	var match_pos := lower.find("match ") + 6
	var colon_pos := line.rfind(":")
	if colon_pos == -1 or colon_pos <= match_pos:
		result.error = "Line %d: Match needs a variable. Try: match state:" % line_num
		return result
	
	var match_var := line.substr(match_pos, colon_pos - match_pos).strip_edges()
	var match_value = _evaluate_expression(match_var, line_num)
	if match_value is Dictionary and match_value.has("error"):
		result.error = match_value.error
		return result
	match_value = str(match_value)
	
	var base_indent := _get_line_indent(lines[start_index])
	var cases := []
	var current_case_value := ""
	var current_case_body := []
	var current_case_nums := []
	var end_index := start_index + 1
	
	while end_index < lines.size():
		var body_line := lines[end_index]
		var stripped := body_line.strip_edges()
		if stripped.is_empty():
			end_index += 1
			continue
		var body_indent := _get_line_indent(body_line)
		if body_indent <= base_indent and not stripped.begins_with("#"):
			break
		if stripped.begins_with("_:"):
			if current_case_value != "":
				cases.append({"value": current_case_value, "body": current_case_body, "nums": current_case_nums})
			current_case_body = []
			current_case_nums = []
			current_case_value = "_"
			end_index += 1
			continue
		if stripped.ends_with(":"):
			var case_lower := stripped.to_lower()
			if case_lower == "_:" or case_lower.begins_with("case "):
				if current_case_value != "":
					cases.append({"value": current_case_value, "body": current_case_body, "nums": current_case_nums})
				current_case_body = []
				current_case_nums = []
				if stripped.begins_with("_"):
					current_case_value = "_"
				else:
					var colon_idx := stripped.rfind(":")
					current_case_value = stripped.substr(5, colon_idx - 5).strip_edges()
					if (current_case_value.begins_with("\"") and current_case_value.ends_with("\"")) or \
					   (current_case_value.begins_with("'") and current_case_value.ends_with("'")):
						current_case_value = current_case_value.substr(1, current_case_value.length() - 2)
				end_index += 1
				continue
		if not stripped.begins_with("#"):
			current_case_body.append(stripped)
			current_case_nums.append(end_index + 1)
		end_index += 1
	
	if current_case_value != "":
		cases.append({"value": current_case_value, "body": current_case_body, "nums": current_case_nums})
	
	result.end_index = end_index - 1
	
	var matched_case = null
	for c in cases:
		if c.value == "_" or c.value == match_value:
			matched_case = c
			break
	
	if matched_case == null:
		return result
	
	for bi in range(matched_case.body.size()):
		var body_line := matched_case.body[bi]
		var body_line_num := matched_case.nums[bi]
		
		body_line = _substitute_variables(body_line)
		
		if _is_python_for_loop(body_line):
			var loop_result = await _execute_python_for_loop(matched_case.body, bi)
			if loop_result.error != "":
				result.error = loop_result.error
				result.error_line = loop_result.error_line
				return result
			bi = loop_result.end_index
			continue
		
		if _is_conditional_start(body_line):
			var cond_result = await _execute_conditional(matched_case.body, bi)
			if cond_result.error != "":
				result.error = cond_result.error
				result.error_line = cond_result.error_line
				return result
			bi = cond_result.end_index
			continue
		
		if _is_while_loop(body_line):
			var while_result = await _execute_while_loop(matched_case.body, bi)
			if while_result.error != "":
				result.error = while_result.error
				result.error_line = while_result.error_line
				return result
			bi = while_result.end_index
			continue
		
		var parse_result := _parse_function_call(body_line, body_line_num)
		if parse_result.error != "":
			result.error = parse_result.error
			result.error_line = body_line_num
			return result
		
		if parse_result.func_name != "" and active_mission:
			var dispatch_error := _dispatch(parse_result.func_name, parse_result.args, body_line_num)
			if dispatch_error != "":
				result.error = dispatch_error
				result.error_line = body_line_num
				return result
	
	return result


# ========================================================================
# IF/ELSE CONDITIONALS
# ========================================================================

func _is_conditional_start(line: String) -> bool:
	var lower := line.to_lower().strip_edges()
	return lower.begins_with("if ") and lower.ends_with(":")


func _execute_conditional(lines: PackedStringArray, start_index: int) -> Dictionary:
	var result := {"error": "", "error_line": start_index + 1, "end_index": start_index}
	var line := lines[start_index].strip_edges()
	var line_num := start_index + 1

	var lower := line.to_lower()
	var if_pos := lower.find("if ") + 3
	var colon_pos := line.rfind(":")
	if colon_pos == -1 or colon_pos <= if_pos:
		result.error = "Line %d: If statements need a colon at the end. Try: if x > 5:" % line_num
		return result
	
	var first_condition_str := line.substr(if_pos, colon_pos - if_pos).strip_edges()
	
	var base_indent := _get_line_indent(lines[start_index])
	var end_index := start_index + 1
	
	var branches := []  # Array of {condition, body_lines, body_nums}
	var current_body_lines := []
	var current_body_nums := []
	var in_else := false
	var found_any_true := false
	
	while end_index < lines.size():
		var body_line := lines[end_index]
		var stripped := body_line.strip_edges()
		
		if stripped.is_empty():
			end_index += 1
			continue
		
		var body_indent := _get_line_indent(body_line)
		var stripped_lower := stripped.to_lower()
		
		if stripped_lower == "else:" and body_indent == base_indent:
			branches.append({"condition": "else", "body": current_body_lines, "nums": current_body_nums})
			current_body_lines = []
			current_body_nums = []
			in_else = true
			end_index += 1
			continue
		
		if stripped_lower.begins_with("elif ") and body_indent == base_indent:
			branches.append({"condition": first_condition_str, "body": current_body_lines, "nums": current_body_nums})
			var elif_colon := stripped.rfind(":")
			first_condition_str = stripped.substr(5, elif_colon - 5).strip_edges()
			current_body_lines = []
			current_body_nums = []
			end_index += 1
			continue
		
		if body_indent <= base_indent and not stripped.begins_with("#"):
			break
		
		if not stripped.begins_with("#"):
			current_body_lines.append(stripped)
			current_body_nums.append(end_index + 1)
		
		end_index += 1
	
	branches.append({"condition": first_condition_str if not in_else else "else", "body": current_body_lines, "nums": current_body_nums})
	result.end_index = end_index - 1
	
	var executed := false
	for branch in branches:
		var cond_str = branch.condition
		
		if cond_str == "else":
			executed = true
			break
		
		var cond_result = _evaluate_condition(cond_str, line_num)
		if cond_result is Dictionary and cond_result.has("error"):
			result.error = cond_result.error
			return result
		
		if cond_result as bool:
			executed = true
			found_any_true = true
			break
	
	var body_to_execute: Array
	var nums_to_execute: Array
	
	if executed:
		for branch in branches:
			if branch.condition == "else":
				body_to_execute = branch.body
				nums_to_execute = branch.nums
				break
			var cond_result = _evaluate_condition(branch.condition, line_num)
			if cond_result as bool:
				body_to_execute = branch.body
				nums_to_execute = branch.nums
				break
	
	if body_to_execute.is_empty():
		return result
	
	for bi in range(body_to_execute.size()):
		var body_line := body_to_execute[bi]
		var body_line_num := nums_to_execute[bi]
		
		body_line = _substitute_variables(body_line)
		
		if _is_python_for_loop(body_line):
			var nested_result = await _execute_python_for_loop(body_to_execute, bi)
			if nested_result.error != "":
				result.error = nested_result.error
				result.error_line = nested_result.error_line
				return result
			bi = nested_result.end_index
			continue
		
		if _is_conditional_start(body_line):
			var cond_result = await _execute_conditional(body_to_execute, bi)
			if cond_result.error != "":
				result.error = cond_result.error
				result.error_line = cond_result.error_line
				return result
			bi = cond_result.end_index
			continue
		
		if _is_match_statement(body_line):
			var match_result = await _execute_match(body_to_execute, bi)
			if match_result.error != "":
				result.error = match_result.error
				result.error_line = match_result.error_line
				return result
			bi = match_result.end_index
			continue
		
		var parse_result := _parse_function_call(body_line, body_line_num)
		if parse_result.error != "":
			result.error = parse_result.error
			result.error_line = body_line_num
			return result
		
		if parse_result.func_name != "" and active_mission:
			var dispatch_error := _dispatch(parse_result.func_name, parse_result.args, body_line_num)
			if dispatch_error != "":
				result.error = dispatch_error
				result.error_line = body_line_num
				return result
	
	return result


func _evaluate_condition(cond_str: String, line_num: int) -> Variant:
	cond_str = cond_str.strip_edges()
	
	# Handle compound conditions with 'and' / 'or'
	if cond_str.find(" and ") != -1:
		var parts := cond_str.split(" and ")
		for part in parts:
			var result = _evaluate_condition(part.strip_edges(), line_num)
			if result is Dictionary and result.has("error"):
				return result
			if not (result as bool):
				return false
		return true
	
	if cond_str.find(" or ") != -1:
		var parts := cond_str.split(" or ")
		for part in parts:
			var result = _evaluate_condition(part.strip_edges(), line_num)
			if result is Dictionary and result.has("error"):
				return result
			if result as bool:
				return true
		return false
	
	# Parse comparison operators
	var ops := [" >= ", " <= ", " != ", " == ", " > ", " < "]
	for op in ops:
		var pos := cond_str.find(op)
		if pos != -1:
			var left_str := cond_str.substr(0, pos).strip_edges()
			var right_str := cond_str.substr(pos + op.length()).strip_edges()
			
			var left = _evaluate_expression(left_str, line_num)
			var right = _evaluate_expression(right_str, line_num)
			
			if left is Dictionary and left.has("error"):
				return left
			if right is Dictionary and right.has("error"):
				return right
			
			var l := int(left) if left is int else float(left)
			var r := int(right) if right is int else float(right)
			
			match op.strip_edges():
				">=": return l >= r
				"<=": return l <= r
				"!=": return l != r
				"==": return l == r
				">": return l > r
				"<": return l < r
	
	# Simple variable or number (truthy check)
	var val = _evaluate_expression(cond_str, line_num)
	if val is Dictionary and val.has("error"):
		return val
	return bool(val)


# ========================================================================
# FUNCTION DEFINITIONS
# ========================================================================

func _execute_function_definition(lines: PackedStringArray, start_index: int) -> Dictionary:
	var result := {"error": "", "error_line": start_index + 1, "end_index": start_index}
	var line := lines[start_index].strip_edges()
	var line_num := start_index + 1

	# Parse: function name(params):
	var func_start := 9  # Skip "function "
	var colon_pos := line.rfind(":")
	if colon_pos == -1 or colon_pos <= func_start:
		result.error = "Line %d: Functions need a colon. Try: function myFunc(x, y):" % line_num
		return result
	
	var signature := line.substr(func_start, colon_pos - func_start).strip_edges()
	
	# Extract function name and parameters
	var paren_open := signature.find("(")
	var paren_close := signature.rfind(")")
	
	if paren_open == -1 or paren_close == -1 or paren_close < paren_open:
		result.error = "Line %d: Functions need parentheses. Try: function myFunc():" % line_num
		return result
	
	var func_name := signature.substr(0, paren_open).strip_edges()
	var params_str := signature.substr(paren_open + 1, paren_close - paren_open - 1)
	var params := []
	for p in params_str.split(","):
		var trimmed := p.strip_edges()
		if not trimmed.is_empty():
			params.append(trimmed)
	
	# Find the function body
	var base_indent := _get_line_indent(lines[start_index])
	var body_lines := []
	var end_index := start_index + 1
	
	while end_index < lines.size():
		var body_line := lines[end_index]
		if body_line.strip_edges().is_empty():
			end_index += 1
			continue
		
		var body_indent := _get_line_indent(body_line)
		if body_indent <= base_indent and not body_line.strip_edges().begins_with("#"):
			break
		
		if not body_line.strip_edges().begins_with("#"):
			body_lines.append(body_line)
		end_index += 1
	
	result.end_index = end_index - 1
	
	# Store the function definition
	_user_functions[func_name] = {
		"params": params,
		"body": body_lines,
		"line_num": line_num
	}
	
	return result


func _execute_user_function(func_name: String, args: Array, line_num: int) -> String:
	if not _user_functions.has(func_name):
		return "Line %d: I don't know a function called '%s'. Did you define it first?" % [line_num, func_name]
	
	var func_def := _user_functions[func_name]
	var params: Array = func_def.params
	var body_lines: Array = func_def.body
	var func_line_num: int = func_def.line_num
	
	if args.size() != params.size():
		return "Line %d: Function '%s' needs %d arguments, but got %d." % [line_num, func_name, params.size(), args.size()]
	
	var saved_variables := _variables.duplicate(true)
	
	for i in range(params.size()):
		_variables[params[i]] = args[i]
	
	for bi in range(body_lines.size()):
		var body_line := body_lines[bi].strip_edges()
		if body_line.is_empty() or body_line.begins_with("#"):
			continue
		
		if body_line.to_lower().begins_with("return"):
			var return_val = null
			var return_str := body_line.substr(6).strip_edges()
			if not return_str.is_empty():
				return_val = _evaluate_expression(return_str, func_line_num)
				if return_val is Dictionary and return_val.has("error"):
					_variables = saved_variables
					return "Line %d: %s" % [func_line_num, return_val.error]
			_variables["__return_value__"] = return_val
			_variables = saved_variables
			return ""
		
		body_line = _substitute_variables(body_line)
		
		if _is_python_for_loop(body_line):
			var loop_result = await _execute_python_for_loop(body_lines, bi)
			if loop_result.error != "":
				_variables = saved_variables
				return "Line %d: %s" % [loop_result.error_line, loop_result.error]
			bi = loop_result.end_index
			continue
		
		if _is_conditional_start(body_line):
			var cond_result = await _execute_conditional(body_lines, bi)
			if cond_result.error != "":
				_variables = saved_variables
				return "Line %d: %s" % [cond_result.error_line, cond_result.error]
			bi = cond_result.end_index
			continue
		
		if _is_while_loop(body_line):
			var while_result = await _execute_while_loop(body_lines, bi)
			if while_result.error != "":
				_variables = saved_variables
				return "Line %d: %s" % [while_result.error_line, while_result.error]
			bi = while_result.end_index
			continue
		
		if _is_match_statement(body_line):
			var match_result = await _execute_match(body_lines, bi)
			if match_result.error != "":
				_variables = saved_variables
				return "Line %d: %s" % [match_result.error_line, match_result.error]
			bi = match_result.end_index
			continue
		
		var parse_result := _parse_function_call(body_line, func_line_num)
		if parse_result.error != "":
			_variables = saved_variables
			return "Line %d: %s" % [func_line_num, parse_result.error]
		
		if parse_result.func_name != "" and active_mission:
			var dispatch_error := _dispatch(parse_result.func_name, parse_result.args, func_line_num)
			if dispatch_error != "":
				_variables = saved_variables
				return "Line %d: %s" % [func_line_num, dispatch_error]
	
	_variables = saved_variables
	return ""


# ========================================================================
# UTILITY FUNCTIONS
# ========================================================================

func _get_line_indent(line: String) -> int:
	var i := 0
	while i < line.length() and (line[i] == " " or line[i] == "\t"):
		i += 1
	return i


func _is_ident_char(c: String) -> bool:
	if c.length() != 1:
		return false
	var code := c.unicode_at(0)
	return (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or (code >= 48 and code <= 57) or c == "_"


func _substitute_loop_var(line: String, var_name: String, value: int) -> String:
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


# ========================================================================
# FUNCTION CALL PARSING
# ========================================================================

func _parse_function_call(line: String, line_num: int) -> Dictionary:
	var result := {"func_name": "", "args": [], "error": ""}

	# Handle array/dict index access: arr[index] or dict["key"]
	var bracket_pos := line.find("[")
	var paren_pos := line.find("(")
	
	# If there's a bracket before paren, might be array/dict access
	if bracket_pos != -1 and (paren_pos == -1 or bracket_pos < paren_pos):
		var var_name := line.substr(0, bracket_pos).strip_edges()
		var index_part := ""
		var closing_bracket := line.find("]", bracket_pos)
		if closing_bracket != -1:
			index_part = line.substr(bracket_pos + 1, closing_bracket - bracket_pos - 1)
			
			# Check if this is followed by a function call or assignment
			var after_bracket := line.substr(closing_bracket + 1).strip_edges()
			if after_bracket.begins_with("=") and not after_bracket.begins_with("=="):
				# Dict/array assignment: dict["key"] = value
				var value_str := after_bracket.substr(1).strip_edges()
				if not _variables.has(var_name):
					result.error = "Line %d: I don't see a variable called '%s'" % [line_num, var_name]
					return result
				
				var collection = _variables[var_name]
				var key_val = _evaluate_expression(index_part.strip_edges(), line_num)
				if key_val is Dictionary and key_val.has("error"):
					result.error = key_val.error
					return result
				
				var assign_val = _evaluate_expression(value_str, line_num)
				if assign_val is Dictionary and assign_val.has("error"):
					result.error = assign_val.error
					return result
				
				if collection is Dictionary:
					collection[str(key_val)] = assign_val
				elif collection is Array:
					collection[int(key_val)] = assign_val
				
				result.func_name = "__dict_assign__"
				return result
			elif after_bracket.begins_with("("):
				# This is arr[index](args) - array index then function call
				paren_pos = closing_bracket + 1 + after_bracket.find("(")
				var_name = var_name + line.substr(bracket_pos, closing_bracket - bracket_pos + 1)
			else:
				# Simple array/dict index access
				var index_val = _evaluate_expression(index_part.strip_edges(), line_num)
				if index_val is Dictionary and index_val.has("error"):
					result.error = index_val.error
					return result
				
				if not _variables.has(var_name):
					result.error = "Line %d: I don't see a variable called '%s'" % [line_num, var_name]
					return result
				
				var collection = _variables[var_name]
				
				if collection is Dictionary:
					result.values = [collection.get(str(index_val), null)]
					result.func_name = "__dict_index__"
					return result
				elif collection is Array:
					var idx := int(index_val)
					if idx < 0 or idx >= collection.size():
						result.error = "Line %d: Index %d is out of range for array of size %d" % [line_num, idx, collection.size()]
						return result
					result.values = [collection[idx]]
					result.func_name = "__array_index__"
					return result
				else:
					result.error = "Line %d: '%s' is not an array or dictionary" % [line_num, var_name]
					return result

	# Match pattern: function_name(args)
	paren_open := paren_pos
	if paren_open == -1:
		paren_open = bracket_pos
	
	var paren_close := line.rfind(")")

	if paren_open == -1 and paren_close == -1:
		var stripped := line.replace(" ", "").to_lower()
		for known in known_functions:
			if stripped.begins_with(known.to_lower()):
				result.error = "Line %d: Oops! It looks like you forgot the parentheses (). Try: %s(\"house\", 5, 5)" % [line_num, known]
				return result
		for typo in _typo_map:
			if stripped.begins_with(typo):
				result.error = "Line %d: Almost! Did you mean '%s'? Check your spelling!" % [line_num, _typo_map[typo]]
				return result
		return result

	if paren_open == -1 or paren_close == -1 or paren_close < paren_open:
		result.error = "Line %d: Hmm, it looks like you're missing a parenthesis." % line_num
		return result

	var func_name := line.substr(0, paren_open).strip_edges().to_lower()
	var args_str := line.substr(paren_open + 1, paren_close - paren_open - 1).strip_edges()

	# Check for user-defined functions
	if _user_functions.has(func_name):
		var args := _parse_args(args_str, line_num)
		if args.error != "":
			result.error = args.error
			return result
		var exec_error := _execute_user_function(func_name, args.values, line_num)
		if exec_error != "":
			result.error = exec_error
			return result
		if _variables.has("__return_value__"):
			result.values = [_variables["__return_value__"]]
			_variables.erase("__return_value__")
		return result
	
	# Built-in functions
	if func_name == "len":
		var args := _parse_args(args_str, line_num)
		if args.error != "":
			result.error = args.error
			return result
		if args.values.size() < 1:
			result.error = "Line %d: len() needs one argument" % line_num
			return result
		var collection = args.values[0]
		if collection is Array:
			result.values = [collection.size()]
		elif collection is Dictionary:
			result.values = [collection.size()]
		else:
			result.error = "Line %d: len() only works on arrays and dictionaries" % line_num
			return result
		return result
	
	if func_name == "str":
		var args := _parse_args(args_str, line_num)
		if args.error != "":
			result.error = args.error
			return result
		if args.values.size() < 1:
			result.error = "Line %d: str() needs one argument" % line_num
			return result
		result.values = [str(args.values[0])]
		return result
	
	if func_name == "int":
		var args := _parse_args(args_str, line_num)
		if args.error != "":
			result.error = args.error
			return result
		if args.values.size() < 1:
			result.error = "Line %d: int() needs one argument" % line_num
			return result
		result.values = [int(args.values[0])]
		return result
	
	# Check for typos in function name
	if func_name not in known_functions:
		if func_name in _typo_map:
			result.error = "Line %d: Almost! Did you mean '%s'?" % [line_num, _typo_map[func_name]]
		else:
			result.error = "Line %d: I don't know a function called '%s'." % [line_num, func_name]
		return result

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

		# String argument
		if (trimmed.begins_with("\"") and trimmed.ends_with("\"")) or \
		   (trimmed.begins_with("'") and trimmed.ends_with("'")):
			var str_val := trimmed.substr(1, trimmed.length() - 2)
			result.values.append(str_val)

		# Array literal
		elif trimmed.begins_with("[") and trimmed.ends_with("]"):
			var arr := _parse_array_literal(trimmed, line_num)
			result.values.append(arr)

		# Check for ??? placeholder
		elif trimmed.find("???") != -1:
			result.error = "Line %d: Replace the ??? with a real value!" % line_num
			return result

		# Unquoted string
		elif trimmed.to_lower() in ["house", "road", "tree", "grass", "building"]:
			result.error = "Line %d: Don't forget the quotes! Write \"%s\" with quotation marks." % [line_num, trimmed]
			return result

		# Number
		elif trimmed.is_valid_int():
			result.values.append(trimmed.to_int())

		# Math expression
		elif _is_math_expression(trimmed):
			var val = _evaluate_math(trimmed, line_num)
			if val is Dictionary and val.has("error"):
				result.error = val.error
				return result
			result.values.append(val)

		# Variable reference
		elif _variables.has(trimmed):
			result.values.append(_variables[trimmed])

		# Array index access in argument
		elif trimmed.find("[") != -1:
			var bracket_pos := trimmed.find("[")
			var arr_name := trimmed.substr(0, bracket_pos)
			var closing := trimmed.rfind("]")
			if closing != -1 and _variables.has(arr_name):
				var index_str := trimmed.substr(bracket_pos + 1, closing - bracket_pos - 1)
				var index_val = _evaluate_expression(index_str.strip_edges(), line_num)
				if index_val is Dictionary and index_val.has("error"):
					result.error = index_val.error
					return result
				var arr: Array = _variables[arr_name]
				var idx := int(index_val)
				if idx >= 0 and idx < arr.size():
					result.values.append(arr[idx])
				else:
					result.error = "Line %d: Index %d is out of range" % [line_num, idx]
					return result
			else:
				result.error = "Line %d: I don't understand '%s'" % [line_num, trimmed]
				return result

		else:
			result.error = "Line %d: I don't understand '%s'. Make sure strings have \"quotes\"!" % [line_num, trimmed]
			return result

	return result


# ========================================================================
# DISPATCH
# ========================================================================

func _dispatch(func_name: String, args: Array, line_num: int) -> String:
	if not active_mission:
		return "Line %d: No mission is active right now." % line_num

	match func_name:
		"place_building":
			if active_mission.has_method("api_place_building"):
				return active_mission.api_place_building(args, line_num)
		"get_city_stat":
			if active_mission.has_method("api_get_city_stat"):
				return active_mission.api_get_city_stat(args, line_num)
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
