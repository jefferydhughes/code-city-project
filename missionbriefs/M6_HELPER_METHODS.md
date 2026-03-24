# Mission 6: Helper Methods (Functions) — Claude Code Build Instructions

**File to create:** `res://scripts/mission_6.gd`
**Run with:** `--dangerously-skip-permissions`

---

## Concept Being Taught
Functions (called "helper methods" in the Skill Samurai curriculum) are named, reusable blocks of code. Define once, call many times. Functions can accept parameters to make them flexible.

CodeCity syntax:
```
function build_house(col, row):
    place_building("house", col, row)
    place_building("tree", col + 1, row)

build_house(0, 0)
build_house(4, 0)
```

Key insight: functions make code shorter, more readable, and easier to change. Change the function once → every call updates automatically.

---

## Mission Narrative
**Mayor Maple:** "You keep writing the same three lines every time you build a neighborhood corner — house, road, tree. What if we could teach CodeCity a new command? Define it once, then call it by name anywhere. That's a FUNCTION — your own custom command!"

---

## Architecture Pattern
Identical structure to `mission_1.gd`. Class name `Mission6`.

**Additional CodeRunner requirement:** CodeRunner must support `function name(params):` definition and calling a user-defined function by name. This is a new CodeRunner feature — add it if not already present. Function bodies use the same indentation rule as loops. Functions are stored in a dictionary during code execution and called when the function name appears as a statement.

---

## The 10 Steps

```gdscript
const steps: Array = [
    {
        "id": 1,
        "type": "explain",
        "title": "What's a Function?",
        "mayor_dialogue": "You've been writing the same groups of commands over and over. A function lets you give that group a NAME — then use the name instead of repeating all those lines!",
        "instruction": "Without a function:\nplace_building(\"house\", 0, 0)\nplace_building(\"tree\", 1, 0)\nplace_building(\"house\", 4, 0)\nplace_building(\"tree\", 5, 0)\n\nWith a function:\nfunction build_plot(col, row):\n    place_building(\"house\", col, row)\n    place_building(\"tree\", col + 1, row)\n\nbuild_plot(0, 0)\nbuild_plot(4, 0)\n\nSame result, half the code. Press NEXT to try it!",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "",
        "success_condition": "explain",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["function", "place_building"],
    },
    {
        "id": 2,
        "type": "guided",
        "title": "Call a Function",
        "mayor_dialogue": "Here's a function already defined. Run the code — see how one function call places TWO buildings!",
        "instruction": "Run this code. The function 'build_plot' places a house and a tree.\nOne call = two buildings!",
        "show_grid_diagram": false,
        "starter_code": "function build_plot(col, row):\n    place_building(\"house\", col, row)\n    place_building(\"tree\", col + 1, row)\n\nbuild_plot(0, 0)",
        "hint": "Just press Run — the function places 2 buildings from one call.",
        "success_condition": "code_runs",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["function", "place_building"],
    },
    {
        "id": 3,
        "type": "guided",
        "title": "Call It Twice",
        "mayor_dialogue": "Now call the function TWICE with different locations — 4 buildings from 2 lines!",
        "instruction": "Add a second call: build_plot(4, 0)\nRun — you should have 4 buildings total.",
        "show_grid_diagram": false,
        "starter_code": "function build_plot(col, row):\n    place_building(\"house\", col, row)\n    place_building(\"tree\", col + 1, row)\n\nbuild_plot(0, 0)",
        "hint": "function build_plot(col, row):\n    place_building(\"house\", col, row)\n    place_building(\"tree\", col + 1, row)\n\nbuild_plot(0, 0)\nbuild_plot(4, 0)",
        "success_condition": "count",
        "required_buildings": [],
        "required_count": 4,
        "required_types": 0,
        "available_commands": ["function", "place_building"],
    },
    {
        "id": 4,
        "type": "guided",
        "title": "Change the Function",
        "mayor_dialogue": "The best part: change the function ONCE and every call updates. Add a shop to build_plot — all calls now get houses, trees, AND shops!",
        "instruction": "Add this line inside the function:\n    place_building(\"shop\", col + 2, row)\n\nRun — each call now places 3 buildings.",
        "show_grid_diagram": false,
        "starter_code": "function build_plot(col, row):\n    place_building(\"house\", col, row)\n    place_building(\"tree\", col + 1, row)\n\nbuild_plot(0, 0)\nbuild_plot(4, 0)",
        "hint": "function build_plot(col, row):\n    place_building(\"house\", col, row)\n    place_building(\"tree\", col + 1, row)\n    place_building(\"shop\", col + 2, row)\n\nbuild_plot(0, 0)\nbuild_plot(4, 0)",
        "success_condition": "count",
        "required_buildings": [],
        "required_count": 6,
        "required_types": 0,
        "available_commands": ["function", "place_building"],
    },
    {
        "id": 5,
        "type": "do_it",
        "title": "Write Your Own Function",
        "mayor_dialogue": "Your turn! Write a function called 'build_corner' that places a house and a park next to each other. Then call it at two different locations.",
        "instruction": "Define 'build_corner(col, row)' that places:\n- A house at (col, row)\n- A park at (col + 1, row)\n\nThen call it at (0, 0) and (5, 5).",
        "show_grid_diagram": false,
        "starter_code": "function build_corner(col, row):\n    # your code here\n\nbuild_corner(0, 0)\nbuild_corner(5, 5)",
        "hint": "function build_corner(col, row):\n    place_building(\"house\", col, row)\n    place_building(\"park\", col + 1, row)\n\nbuild_corner(0, 0)\nbuild_corner(5, 5)",
        "success_condition": "count",
        "required_buildings": [],
        "required_count": 4,
        "required_types": 0,
        "available_commands": ["function", "place_building"],
    },
    {
        "id": 6,
        "type": "guided",
        "title": "Function + Loop",
        "mayor_dialogue": "Functions and loops are an unstoppable team! Watch this — a function called inside a loop builds an entire neighborhood in just 4 lines.",
        "instruction": "Run this code. The function is called 3 times by the loop — each time at a different column.",
        "show_grid_diagram": false,
        "starter_code": "function build_plot(col, row):\n    place_building(\"house\", col, row)\n    place_building(\"tree\", col + 1, row)\n\nfor i in range(3):\n    build_plot(i * 3, 0)",
        "hint": "Just press Run — the loop calls the function 3 times.",
        "success_condition": "code_runs",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["function", "for", "place_building"],
    },
    {
        "id": 7,
        "type": "do_it",
        "title": "Loop Your Function",
        "mayor_dialogue": "Build 4 identical mini-parks using a function and a loop. Each park should have a tree and a park tile side by side.",
        "instruction": "Write a function 'build_mini_park(col, row)' that places a tree and a park.\nCall it 4 times using a loop, spacing them 3 columns apart.",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "function build_mini_park(col, row):\n    place_building(\"tree\", col, row)\n    place_building(\"park\", col + 1, row)\n\nfor i in range(4):\n    build_mini_park(i * 3, 5)",
        "success_condition": "count",
        "required_buildings": [],
        "required_count": 8,
        "required_types": 0,
        "available_commands": ["function", "for", "place_building"],
    },
    {
        "id": 8,
        "type": "challenge",
        "title": "Block Builder Function",
        "mayor_dialogue": "Now define a function that builds a full ROW of buildings — 4 houses in a line — then call it to build 3 parallel rows.",
        "instruction": "Write 'build_row(row_num)' that places 4 houses on the given row (columns 0-3).\nCall it for rows 0, 2, and 4.",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "function build_row(row_num):\n    for col in range(4):\n        place_building(\"house\", col, row_num)\n\nbuild_row(0)\nbuild_row(2)\nbuild_row(4)",
        "success_condition": "count",
        "required_buildings": [],
        "required_count": 12,
        "required_types": 0,
        "available_commands": ["function", "for", "place_building"],
    },
    {
        "id": 9,
        "type": "challenge",
        "title": "Two Functions",
        "mayor_dialogue": "The city has two zones — residential and commercial. Write one function for each and call both to build the city.",
        "instruction": "Write:\n- 'build_residential(col, row)': house + tree\n- 'build_commercial(col, row)': shop + park\n\nCall each 3 times to build 12 total buildings.",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "function build_residential(col, row):\n    place_building(\"house\", col, row)\n    place_building(\"tree\", col + 1, row)\n\nfunction build_commercial(col, row):\n    place_building(\"shop\", col, row)\n    place_building(\"park\", col + 1, row)\n\nfor i in range(3):\n    build_residential(i * 3, 0)\nfor i in range(3):\n    build_commercial(i * 3, 4)",
        "success_condition": "type_count",
        "required_buildings": [],
        "required_count": 12,
        "required_types": 3,
        "available_commands": ["function", "for", "place_building"],
    },
    {
        "id": 10,
        "type": "mastery",
        "title": "Function Architect",
        "mayor_dialogue": "You're an architect now! Design your city using at least 2 custom functions. At least 10 buildings, 3 types. Show me what custom commands can do!",
        "instruction": "Free build using functions!\n- At least 2 custom functions\n- Call each function at least twice\n- At least 10 buildings total\n- At least 3 different building types",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "function build_block(col, row):\n    place_building(\"house\", col, row)\n    place_building(\"shop\", col + 1, row)\n    place_building(\"tree\", col + 2, row)\n\nfunction build_park_row(row_num):\n    for i in range(4):\n        place_building(\"park\", i, row_num)\n\nbuild_block(0, 0)\nbuild_block(0, 2)\nbuild_block(0, 4)\nbuild_park_row(6)",
        "success_condition": "type_count",
        "required_buildings": [],
        "required_count": 10,
        "required_types": 3,
        "available_commands": ["function", "for", "place_building"],
    },
]
```

---

## CodeRunner Implementation Notes

### Function support to add to `code_runner.gd`:

CodeRunner must handle a two-pass execution:
1. **Pass 1 (scan):** collect all `function name(params):` definitions into a dictionary, storing their body lines.
2. **Pass 2 (execute):** run non-function lines. When a function call is encountered, look it up in the dictionary, bind the argument values to the parameter names, then execute the body.

Function definitions are NOT executed on the first pass — only stored. A function call without a definition should emit a feedback error: `"I don't know a function called 'X'. Did you define it above the call?"`

---

## Autotype Solutions
```gdscript
func _get_solution_for_step(step: Dictionary) -> String:
    match step.id:
        3: return "function build_plot(col, row):\n    place_building(\"house\", col, row)\n    place_building(\"tree\", col + 1, row)\n\nbuild_plot(0, 0)\nbuild_plot(4, 0)"
        4: return "function build_plot(col, row):\n    place_building(\"house\", col, row)\n    place_building(\"tree\", col + 1, row)\n    place_building(\"shop\", col + 2, row)\n\nbuild_plot(0, 0)\nbuild_plot(4, 0)"
        5: return "function build_corner(col, row):\n    place_building(\"house\", col, row)\n    place_building(\"park\", col + 1, row)\n\nbuild_corner(0, 0)\nbuild_corner(5, 5)"
        7: return "function build_mini_park(col, row):\n    place_building(\"tree\", col, row)\n    place_building(\"park\", col + 1, row)\n\nfor i in range(4):\n    build_mini_park(i * 3, 5)"
        8: return "function build_row(row_num):\n    for col in range(4):\n        place_building(\"house\", col, row_num)\n\nbuild_row(0)\nbuild_row(2)\nbuild_row(4)"
        9: return "function build_residential(col, row):\n    place_building(\"house\", col, row)\n    place_building(\"tree\", col + 1, row)\n\nfunction build_commercial(col, row):\n    place_building(\"shop\", col, row)\n    place_building(\"park\", col + 1, row)\n\nfor i in range(3):\n    build_residential(i * 3, 0)\nfor i in range(3):\n    build_commercial(i * 3, 4)"
        10: return "function build_block(col, row):\n    place_building(\"house\", col, row)\n    place_building(\"shop\", col + 1, row)\n    place_building(\"tree\", col + 2, row)\n\nfunction build_park_row(row_num):\n    for i in range(4):\n        place_building(\"park\", i, row_num)\n\nbuild_block(0, 0)\nbuild_block(0, 2)\nbuild_block(0, 4)\nbuild_park_row(6)"
    return ""
```

---

## DO NOT MODIFY
- `code_runner.gd` existing dispatch logic — extend it, don't replace it
- `builder.gd`, `mission_manager.gd`, `mission_1.gd` through `mission_5.gd`
