# Mission 3: Variables — Claude Code Build Instructions

**File to create:** `res://scripts/mission_3.gd`
**Run with:** `--dangerously-skip-permissions`

---

## Concept Being Taught
Variables store a value and let you reuse it. Declare with `var name = value`, then use the name anywhere you'd use the value.

CodeCity syntax:
```
var col = 3
place_building("house", col, 0)
```

Key insight for students: if you change `col`, every line using it changes too.

---

## Mission Narrative
**Mayor Maple:** "What if we could give a location a NAME? Instead of remembering 'column 4, row 2', we could call it 'park_spot'. That's what variables are — named boxes that hold values!"

---

## Architecture Pattern
Identical structure to `mission_1.gd` and `mission_2.gd`. Class name `Mission3`.

---

## The 10 Steps

```gdscript
const steps: Array = [
    {
        "id": 1,
        "type": "explain",
        "title": "What's a Variable?",
        "mayor_dialogue": "Imagine you're planning where to build the town park. Instead of remembering 'column 4', you could write it down and give it a name. That note with a name is a VARIABLE!",
        "instruction": "A variable stores a value so you can use it by name.\n\nExample:\nvar spot = 4\nplace_building(\"park\", spot, 0)\n\nNow 'spot' means 4. Change spot to 7 and the park moves!\n\nPress NEXT to try it.",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "",
        "success_condition": "explain",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["var", "place_building"],
    },
    {
        "id": 2,
        "type": "guided",
        "title": "Use a Variable",
        "mayor_dialogue": "Here's code that uses a variable called 'col'. Run it and watch where the house appears!",
        "instruction": "Press Run. The variable 'col' holds the value 3 — so the house goes to column 3.",
        "show_grid_diagram": false,
        "starter_code": "var col = 3\nplace_building(\"house\", col, 0)",
        "hint": "Just press Run — the code is correct!",
        "success_condition": "code_runs",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["var", "place_building"],
    },
    {
        "id": 3,
        "type": "guided",
        "title": "Change the Variable",
        "mayor_dialogue": "Now change the value of 'col' to move the house to column 7. You only change ONE number — and the house moves!",
        "instruction": "Change the value of col from 3 to 7.\nRun the code — the house should appear at column 7.",
        "show_grid_diagram": false,
        "starter_code": "var col = 3\nplace_building(\"house\", col, 0)",
        "hint": "Change the first line to: var col = 7",
        "success_condition": "specific_buildings",
        "required_buildings": [
            {"type": "house", "col": 7, "row": 0},
        ],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["var", "place_building"],
    },
    {
        "id": 4,
        "type": "guided",
        "title": "Two Variables",
        "mayor_dialogue": "You can have as many variables as you need! Here we use 'col' and 'row' together to pinpoint any spot on the grid.",
        "instruction": "Run this code. Then change both col and row to different numbers and run again.",
        "show_grid_diagram": false,
        "starter_code": "var col = 2\nvar row = 4\nplace_building(\"park\", col, row)",
        "hint": "Just press Run first to see it work. Then try changing the numbers!",
        "success_condition": "code_runs",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["var", "place_building"],
    },
    {
        "id": 5,
        "type": "do_it",
        "title": "Place It Yourself",
        "mayor_dialogue": "Your turn! Use two variables to place a shop at column 5, row 3.",
        "instruction": "Declare a variable for the column and another for the row.\nUse them to place a shop at column 5, row 3.",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "var col = 5\nvar row = 3\nplace_building(\"shop\", col, row)",
        "success_condition": "specific_buildings",
        "required_buildings": [
            {"type": "shop", "col": 5, "row": 3},
        ],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["var", "place_building"],
    },
    {
        "id": 6,
        "type": "guided",
        "title": "Variables in Loops",
        "mayor_dialogue": "Variables and loops are best friends! Watch how we use a variable to control where a whole row of houses starts.",
        "instruction": "Run this code. The variable 'start' controls where the row begins. Try changing start to 2 and run again.",
        "show_grid_diagram": false,
        "starter_code": "var start = 0\nfor i in range(4):\n    place_building(\"house\", start + i, 0)",
        "hint": "Change 'var start = 0' to 'var start = 2' and press Run.",
        "success_condition": "code_runs",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["var", "for", "place_building"],
    },
    {
        "id": 7,
        "type": "do_it",
        "title": "Move the Whole Street",
        "mayor_dialogue": "The city wants the shopping district to start at column 3. Use a variable to set the starting column and build 4 shops.",
        "instruction": "Use a variable called 'start' set to 3.\nLoop to place 4 shops starting at column 3, all on row 5.",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "var start = 3\nfor i in range(4):\n    place_building(\"shop\", start + i, 5)",
        "success_condition": "count",
        "required_buildings": [],
        "required_count": 4,
        "required_types": 0,
        "available_commands": ["var", "for", "place_building"],
    },
    {
        "id": 8,
        "type": "challenge",
        "title": "Named Zones",
        "mayor_dialogue": "Great planners name their zones! Use variables called 'house_row' and 'park_row' to build two distinct areas.",
        "instruction": "Declare:\n  var house_row = 1\n  var park_row = 5\n\nThen place:\n- 3 houses on house_row (any columns)\n- 3 parks on park_row (any columns)",
        "show_grid_diagram": false,
        "starter_code": "var house_row = 1\nvar park_row = 5",
        "hint": "var house_row = 1\nvar park_row = 5\nfor i in range(3):\n    place_building(\"house\", i, house_row)\nfor i in range(3):\n    place_building(\"park\", i, park_row)",
        "success_condition": "type_count",
        "required_buildings": [],
        "required_count": 6,
        "required_types": 2,
        "available_commands": ["var", "for", "place_building"],
    },
    {
        "id": 9,
        "type": "challenge",
        "title": "Reuse Your Variables",
        "mayor_dialogue": "Here's a real test: use a single variable to place 3 different buildings in a diagonal line — each one one column and one row further than the last.",
        "instruction": "Place 3 buildings diagonally:\n- house at (1, 1)\n- shop at (2, 2)\n- park at (3, 3)\n\nUse a variable and try to avoid repeating numbers.",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "var pos = 1\nplace_building(\"house\", pos, pos)\npos = pos + 1\nplace_building(\"shop\", pos, pos)\npos = pos + 1\nplace_building(\"park\", pos, pos)",
        "success_condition": "specific_buildings",
        "required_buildings": [
            {"type": "house", "col": 1, "row": 1},
            {"type": "shop", "col": 2, "row": 2},
            {"type": "park", "col": 3, "row": 3},
        ],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["var", "for", "place_building"],
    },
    {
        "id": 10,
        "type": "mastery",
        "title": "Variable Planner",
        "mayor_dialogue": "You're thinking like a real city planner! Use variables to design and build a neighborhood of your own. At least 6 buildings, 3 types — and use at least 2 named variables.",
        "instruction": "Free build!\n- At least 6 buildings\n- At least 3 different types\n- Use at least 2 variables in your code",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "var main_row = 2\nvar side_row = 5\nfor i in range(3):\n    place_building(\"house\", i, main_row)\nfor i in range(2):\n    place_building(\"shop\", i + 4, main_row)\nfor i in range(3):\n    place_building(\"tree\", i, side_row)",
        "success_condition": "type_count",
        "required_buildings": [],
        "required_count": 6,
        "required_types": 3,
        "available_commands": ["var", "for", "repeat", "place_building"],
    },
]
```

---

## CodeRunner DSL Note
`var name = value` declares a variable. `name = value` reassigns it. Both must be supported by CodeRunner. Variables should persist for the full run of a single code execution, then reset.

---

## Autotype Solutions
```gdscript
func _get_solution_for_step(step: Dictionary) -> String:
    match step.id:
        3: return "var col = 7\nplace_building(\"house\", col, 0)"
        5: return "var col = 5\nvar row = 3\nplace_building(\"shop\", col, row)"
        7: return "var start = 3\nfor i in range(4):\n    place_building(\"shop\", start + i, 5)"
        8: return "var house_row = 1\nvar park_row = 5\nfor i in range(3):\n    place_building(\"house\", i, house_row)\nfor i in range(3):\n    place_building(\"park\", i, park_row)"
        9: return "var pos = 1\nplace_building(\"house\", pos, pos)\npos = pos + 1\nplace_building(\"shop\", pos, pos)\npos = pos + 1\nplace_building(\"park\", pos, pos)"
        10: return "var main_row = 2\nvar side_row = 5\nfor i in range(3):\n    place_building(\"house\", i, main_row)\nfor i in range(2):\n    place_building(\"shop\", i + 4, main_row)\nfor i in range(3):\n    place_building(\"tree\", i, side_row)"
    return ""
```

---

## DO NOT MODIFY
- `code_runner.gd`, `builder.gd`, `mission_manager.gd`, `mission_1.gd`, `mission_2.gd`
