# Mission 4: Arrays — Claude Code Build Instructions

**File to create:** `res://scripts/mission_4.gd`
**Run with:** `--dangerously-skip-permissions`

---

## Concept Being Taught
Arrays store multiple values in one named list. Access items by index (starting at 0).

CodeCity syntax:
```
var types = ["house", "shop", "park"]
place_building(types[0], 0, 0)   # places "house"
place_building(types[1], 1, 0)   # places "shop"
```

Key insight: arrays + loops = process an entire list automatically.

---

## Mission Narrative
**Mayor Maple:** "The city needs a mixed street — houses, shops, and parks in order. Instead of keeping track of each one separately, we'll put the whole plan in a LIST. Coders call that an ARRAY!"

---

## Architecture Pattern
Identical structure to `mission_1.gd`. Class name `Mission4`.

---

## The 10 Steps

```gdscript
const steps: Array = [
    {
        "id": 1,
        "type": "explain",
        "title": "What's an Array?",
        "mayor_dialogue": "Imagine a blueprint with a list of buildings to place: house, shop, park, tree. Instead of four separate variables, we put them all in one list — an ARRAY!",
        "instruction": "An array holds multiple values in order:\n\nvar plan = [\"house\", \"shop\", \"park\"]\n\nAccess each item by its position number, starting at 0:\n  plan[0]  → \"house\"\n  plan[1]  → \"shop\"\n  plan[2]  → \"park\"\n\nPress NEXT to try it.",
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
        "title": "Access Item 0",
        "mayor_dialogue": "Arrays start counting at ZERO. So the first item is index 0. Run this code and see which building appears!",
        "instruction": "Run this code. The array has 3 buildings — this code places the FIRST one (index 0).",
        "show_grid_diagram": false,
        "starter_code": "var plan = [\"house\", \"shop\", \"park\"]\nplace_building(plan[0], 3, 3)",
        "hint": "Just press Run — index 0 is the first item: house.",
        "success_condition": "code_runs",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["var", "place_building"],
    },
    {
        "id": 3,
        "type": "guided",
        "title": "Access by Index",
        "mayor_dialogue": "Now change the index from 0 to 1 to place the second item in the array — the shop!",
        "instruction": "Change plan[0] to plan[1] and run.\nThe shop should appear instead of the house.",
        "show_grid_diagram": false,
        "starter_code": "var plan = [\"house\", \"shop\", \"park\"]\nplace_building(plan[0], 3, 3)",
        "hint": "Change the second line to: place_building(plan[1], 3, 3)",
        "success_condition": "specific_buildings",
        "required_buildings": [
            {"type": "shop", "col": 3, "row": 3},
        ],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["var", "place_building"],
    },
    {
        "id": 4,
        "type": "guided",
        "title": "Place All Three",
        "mayor_dialogue": "Let's place all three buildings from the array — each at a different column.",
        "instruction": "Run this code. It places each item in the array at a different column.\n\nNotice: index 0 → column 0, index 1 → column 2, index 2 → column 4.",
        "show_grid_diagram": false,
        "starter_code": "var plan = [\"house\", \"shop\", \"park\"]\nplace_building(plan[0], 0, 0)\nplace_building(plan[1], 2, 0)\nplace_building(plan[2], 4, 0)",
        "hint": "Just press Run — the code places all 3 buildings from the array.",
        "success_condition": "code_runs",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["var", "place_building"],
    },
    {
        "id": 5,
        "type": "do_it",
        "title": "Build Your Own Plan",
        "mayor_dialogue": "Create your own array with 3 building types and place them in a row at columns 1, 3, and 5 on row 5.",
        "instruction": "Declare an array called 'plan' with any 3 building types.\nPlace plan[0] at (1, 5), plan[1] at (3, 5), plan[2] at (5, 5).",
        "show_grid_diagram": false,
        "starter_code": "var plan = [",
        "hint": "var plan = [\"house\", \"tree\", \"shop\"]\nplace_building(plan[0], 1, 5)\nplace_building(plan[1], 3, 5)\nplace_building(plan[2], 5, 5)",
        "success_condition": "count",
        "required_buildings": [],
        "required_count": 3,
        "required_types": 0,
        "available_commands": ["var", "place_building"],
    },
    {
        "id": 6,
        "type": "guided",
        "title": "Array + Loop",
        "mayor_dialogue": "Here's where arrays get POWERFUL — combine them with a loop to place every item automatically!",
        "instruction": "Run this code. The loop goes through each index and places every building in the array.",
        "show_grid_diagram": false,
        "starter_code": "var plan = [\"house\", \"shop\", \"park\", \"tree\"]\nfor i in range(4):\n    place_building(plan[i], i * 2, 0)",
        "hint": "Just press Run — the loop places all 4 buildings from the array.",
        "success_condition": "code_runs",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["var", "for", "place_building"],
    },
    {
        "id": 7,
        "type": "do_it",
        "title": "Your Array Street",
        "mayor_dialogue": "Design a street of 5 buildings using an array and a loop. You choose the building types!",
        "instruction": "Create an array called 'street' with 5 building types.\nUse a loop to place them at columns 0-4, all on row 3.",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "var street = [\"house\", \"shop\", \"house\", \"tree\", \"park\"]\nfor i in range(5):\n    place_building(street[i], i, 3)",
        "success_condition": "count",
        "required_buildings": [],
        "required_count": 5,
        "required_types": 0,
        "available_commands": ["var", "for", "place_building"],
    },
    {
        "id": 8,
        "type": "challenge",
        "title": "Two-Zone Plan",
        "mayor_dialogue": "The city planner wants TWO streets — a residential zone and a commercial zone. Use two arrays!",
        "instruction": "Create two arrays:\n  var residential = [\"house\", \"house\", \"park\"]\n  var commercial = [\"shop\", \"shop\", \"shop\"]\n\nLoop to place residential on row 1 and commercial on row 5.",
        "show_grid_diagram": false,
        "starter_code": "var residential = [\"house\", \"house\", \"park\"]\nvar commercial = [\"shop\", \"shop\", \"shop\"]",
        "hint": "var residential = [\"house\", \"house\", \"park\"]\nvar commercial = [\"shop\", \"shop\", \"shop\"]\nfor i in range(3):\n    place_building(residential[i], i, 1)\nfor i in range(3):\n    place_building(commercial[i], i, 5)",
        "success_condition": "type_count",
        "required_buildings": [],
        "required_count": 6,
        "required_types": 2,
        "available_commands": ["var", "for", "place_building"],
    },
    {
        "id": 9,
        "type": "challenge",
        "title": "Change the Plan",
        "mayor_dialogue": "The city council changed their minds — they want the 3rd building in the plan to be a park, not a shop. Change just the array and run again!",
        "instruction": "Start with this array:\nvar plan = [\"house\", \"house\", \"shop\", \"house\"]\n\nChange index 2 from shop to park.\nThen loop to place all 4 on row 7.",
        "show_grid_diagram": false,
        "starter_code": "var plan = [\"house\", \"house\", \"shop\", \"house\"]\n# Change index 2 to park, then place them all",
        "hint": "var plan = [\"house\", \"house\", \"park\", \"house\"]\nfor i in range(4):\n    place_building(plan[i], i, 7)",
        "success_condition": "specific_buildings",
        "required_buildings": [
            {"type": "house", "col": 0, "row": 7},
            {"type": "house", "col": 1, "row": 7},
            {"type": "park", "col": 2, "row": 7},
            {"type": "house", "col": 3, "row": 7},
        ],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["var", "for", "place_building"],
    },
    {
        "id": 10,
        "type": "mastery",
        "title": "Master Planner",
        "mayor_dialogue": "You're thinking in arrays now! Design a full city block using at least one array with 5+ items and a loop to place them all. At least 3 different building types.",
        "instruction": "Free build using arrays!\n- Array with at least 5 items\n- Loop to place them\n- At least 3 different building types\n- At least 8 buildings total",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "var block = [\"house\", \"shop\", \"house\", \"park\", \"tree\", \"house\", \"shop\", \"tree\"]\nfor i in range(8):\n    place_building(block[i], i, 0)",
        "success_condition": "type_count",
        "required_buildings": [],
        "required_count": 8,
        "required_types": 3,
        "available_commands": ["var", "for", "place_building"],
    },
]
```

---

## CodeRunner DSL Note
Array literals `["a", "b", "c"]` and index access `arr[i]` must be supported. If CodeRunner uses a Lua-style parser, arrays may need to be expressed as tables. Adapt the DSL as needed, but keep the student-facing syntax identical to above.

---

## Autotype Solutions
```gdscript
func _get_solution_for_step(step: Dictionary) -> String:
    match step.id:
        3: return "var plan = [\"house\", \"shop\", \"park\"]\nplace_building(plan[1], 3, 3)"
        5: return "var plan = [\"house\", \"tree\", \"shop\"]\nplace_building(plan[0], 1, 5)\nplace_building(plan[1], 3, 5)\nplace_building(plan[2], 5, 5)"
        7: return "var street = [\"house\", \"shop\", \"house\", \"tree\", \"park\"]\nfor i in range(5):\n    place_building(street[i], i, 3)"
        8: return "var residential = [\"house\", \"house\", \"park\"]\nvar commercial = [\"shop\", \"shop\", \"shop\"]\nfor i in range(3):\n    place_building(residential[i], i, 1)\nfor i in range(3):\n    place_building(commercial[i], i, 5)"
        9: return "var plan = [\"house\", \"house\", \"park\", \"house\"]\nfor i in range(4):\n    place_building(plan[i], i, 7)"
        10: return "var block = [\"house\", \"shop\", \"house\", \"park\", \"tree\", \"house\", \"shop\", \"tree\"]\nfor i in range(8):\n    place_building(block[i], i, 0)"
    return ""
```

---

## DO NOT MODIFY
- `code_runner.gd`, `builder.gd`, `mission_manager.gd`, `mission_1.gd`, `mission_2.gd`, `mission_3.gd`
