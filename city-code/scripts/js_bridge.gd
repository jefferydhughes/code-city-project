extends Node
## JSBridge — communicates between Godot and the Blockly editor in the browser.
## Only active on web exports. On non-web platforms (editor, desktop), all methods
## are no-ops so the rest of the codebase can call them freely.

signal code_changed(code: String)
signal run_pressed(code: String)

var _is_web: bool = false


func _ready() -> void:
	_is_web = OS.has_feature("web")
	if not _is_web:
		return

	# Register Godot callable that JS will call via godot_js_wrapper
	JavaScriptBridge.create_callback(_on_js_message)


## Called by JS: godot_js_wrapper.send(event, data)
func _on_js_message(args: Array) -> void:
	if args.size() < 2:
		return
	var event: String = str(args[0])
	var data: String = str(args[1])

	match event:
		"code_changed":
			code_changed.emit(data)
		"run_pressed":
			run_pressed.emit(data)


## Sends the current step's starter blocks XML to Blockly
func set_starter_blocks(xml_string: String) -> void:
	if not _is_web:
		return
	JavaScriptBridge.eval("window.codecity.setStarterBlocks(%s)" % JSON.stringify(xml_string))


## Sends a restricted toolbox XML for the current mission step
func set_toolbox(xml_string: String) -> void:
	if not _is_web:
		return
	JavaScriptBridge.eval("window.codecity.setToolbox(%s)" % JSON.stringify(xml_string))


## Updates the status bar text in the HTML panel
func set_status(text: String, is_error: bool = false) -> void:
	if not _is_web:
		return
	JavaScriptBridge.eval(
		"window.codecity.setStatusText(%s, %s)" % [
			JSON.stringify(text),
			"true" if is_error else "false"
		]
	)
