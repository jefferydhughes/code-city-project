# Mission 5: For Loops (Nested) — Claude Code Build Instructions

**File to create:** `res://scripts/mission_5.gd`
**Run with:** `--dangerously-skip-permissions`

---

## Concept Being Taught
Nested `for` loops — a loop inside a loop — to fill a 2D grid. The outer loop controls rows, the inner loop controls columns.

CodeCity syntax:
```
for row in range(3):
    for col in range(3):
        place_building("house", col, row)
```

Key insight: the inner loop runs fully for every single iteration of the outer loop. 3×3 = 9 buildings.

Critical warning (from Skill Samurai curriculum): **inner and outer loop variables must have DIFFERENT names.** Using the same name causes the inner loop to shadow the outer variable and the total iterations collapse.

---

## Mission Narrative
**Mayor Maple:** "We need to fill an entire city block — rows AND columns. One loop gets us a line. But a loop INSIDE a loop? That fills the whole grid! Let me show you the most powerful pattern in CodeCity."

---

## Architecture Pattern
Identical structure to `mission_1.gd`. Class name `Mission5`.

---

## The 10 Steps

```gdscript
const steps: Array = [
    {
        "id": 1,
        "type": "explain",
        "title": "One Loop = One Row",
        "mayor_dialogue": "You already know a loop fills a row. But a city block is rows AND columns — a grid. To fill a grid, we need a loop inside a loop!",
        "instruction": "One loop fills a line:\nfor col in range(4):\n    place_building(\"house\", col, 0)\n\nBut what if we want 4 rows of 4 houses? We need to run that loop 4 times — which means another loop AROUND it.\n\nPress NEXT to see it in action.",
        "show_grid_diagram": true,
        "starter_code": "",
        "hint": "",
        "success_condition": "explain",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["for", "place_building"],
    },
    {
        "id": 2,
        "type": "guided",
        "title": "A Loop Inside a Loop",
        "mayor_dialogue": "Watch carefully — the outer loop moves through rows. For each row, the inner loop fills all 4 columns. Run it!",
        "instruction": "Run this code. Count the buildings — it should place 4 × 3 = 12 houses.\n\nNotice the two different variable names: 'row' and 'col'.",
        "show_grid_diagram": false,
        "starter_code": "for row in range(3):\n    for col in range(4):\n        place_building(\"house\", col, row)",
        "hint": "Just press Run — the nested loop fills 3 rows × 4 columns.",
        "success_condition": "code_runs",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["for", "place_building"],
    },
    {
        "id": 3,
        "type": "guided",
        "title": "Change the Grid Size",
        "mayor_dialogue": "Change the range numbers to make a 5×2 grid — 5 columns, 2 rows.",
        "instruction": "Change the outer range to 2 (rows) and inner range to 5 (columns).\nRun — you should get 10 houses in a 5×2 grid.",
        "show_grid_diagram": false,
        "starter_code": "for row in range(3):\n    for col in range(4):\n        place_building(\"house\", col, row)",
        "hint": "for row in range(2):\n    for col in range(5):\n        place_building(\"house\", col, row)",
        "success_condition": "count",
        "required_buildings": [],
        "required_count": 10,
        "required_types": 0,
        "available_commands": ["for", "place_building"],
    },
    {
        "id": 4,
        "type": "explain",
        "title": "⚠️ The Variable Name Warning",
        "mayor_dialogue": "Here's a trap that catches everyone! If you use the SAME variable name for both loops, the inner loop takes over and your outer loop breaks.",
        "instruction": "WRONG — both loops use 'i':\nfor i in range(3):\n    for i in range(4):   ← same name!\n        place_building(\"house\", i, i)\n\nThis gives you 4 buildings instead of 12.\n\nCORRECT — use different names:\nfor row in range(3):\n    for col in range(4):\n        place_building(\"house\", col, row)\n\nAlways use different names! Press NEXT.",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "",
        "success_condition": "explain",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["for", "place_building"],
    },
    {
        "id": 5,
        "type": "do_it",
        "title": "Fill a 4×4 Block",
        "mayor_dialogue": "Build a perfect 4×4 block of houses. That's 16 buildings — using a nested loop with just 3 lines of code!",
        "instruction": "Write a nested loop:\n- Outer loop: 4 rows\n- Inner loop: 4 columns\n- Place a house at (col, row) each time\n\nUse different variable names!",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "for row in range(4):\n    for col in range(4):\n        place_building(\"house\", col, row)",
        "success_condition": "count",
        "required_buildings": [],
        "required_count": 16,
        "required_types": 0,
        "available_commands": ["for", "place_building"],
    },
    {
        "id": 6,
        "type": "guided",
        "title": "Spacing the Grid",
        "mayor_dialogue": "Buildings right next to each other look cramped. Multiply the col and row by 2 to add spacing between each building!",
        "instruction": "Run this code. Notice the buildings are spaced out — col * 2 and row * 2 create gaps between them.",
        "show_grid_diagram": false,
        "starter_code": "for row in range(3):\n    for col in range(3):\n        place_building(\"house\", col * 2, row * 2)",
        "hint": "Just press Run — the spacing uses multiplication.",
        "success_condition": "code_runs",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["for", "place_building"],
    },
    {
        "id": 7,
        "type": "do_it",
        "title": "Spaced Park Grid",
        "mayor_dialogue": "Build a 3×3 grid of parks with one space between each. That means col×2 and row×2.",
        "instruction": "Write a nested loop:\n- 3 rows, 3 columns\n- Place parks\n- Use col * 2 and row * 2 for spacing",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "for row in range(3):\n    for col in range(3):\n        place_building(\"park\", col * 2, row * 2)",
        "success_condition": "count",
        "required_buildings": [],
        "required_count": 9,
        "required_types": 0,
        "available_commands": ["for", "place_building"],
    },
    {
        "id": 8,
        "type": "challenge",
        "title": "Mixed Grid",
        "mayor_dialogue": "Advanced challenge! Fill a 4×4 grid but make the BORDER houses and the INTERIOR parks.",
        "instruction": "Fill a 4×4 grid. The outer edges are houses, the inner 2×2 is parks.\n\nTip: the inner cells are row 1-2, col 1-2.\nAll others are border cells.",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "for row in range(4):\n    for col in range(4):\n        if row == 0 or row == 3 or col == 0 or col == 3:\n            place_building(\"house\", col, row)\n        else:\n            place_building(\"park\", col, row)",
        "success_condition": "type_count",
        "required_buildings": [],
        "required_count": 16,
        "required_types": 2,
        "available_commands": ["for", "if", "place_building"],
    },
    {
        "id": 9,
        "type": "challenge",
        "title": "Offset Grid",
        "mayor_dialogue": "The city expansion zone starts at column 3, row 3 — not at 0,0. Use a nested loop to fill a 3×3 block starting at that offset.",
        "instruction": "Build a 3×3 block of shops starting at column 3, row 3 (9 buildings total).\n\nHint: add 3 to both col and row.",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "for row in range(3):\n    for col in range(3):\n        place_building(\"shop\", col + 3, row + 3)",
        "success_condition": "count",
        "required_buildings": [],
        "required_count": 9,
        "required_types": 0,
        "available_commands": ["for", "place_building"],
    },
    {
        "id": 10,
        "type": "mastery",
        "title": "City Grid Master",
        "mayor_dialogue": "Final challenge! Design a full city district. Use at least one nested loop, at least 12 buildings, at least 3 different types. Make it look like a real neighborhood.",
        "instruction": "Free build using nested loops!\n- At least one nested loop\n- At least 12 buildings\n- At least 3 different building types",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "for row in range(3):\n    for col in range(4):\n        place_building(\"house\", col, row)\nfor col in range(4):\n    place_building(\"shop\", col, 4)\nfor col in range(4):\n    place_building(\"tree\", col, 5)",
        "success_condition": "type_count",
        "required_buildings": [],
        "required_count": 12,
        "required_types": 3,
        "available_commands": ["for", "place_building"],
    },
]
```

---

## CodeRunner DSL Note
Nested `for` loops require correct indentation parsing. Each level of indentation = one level of nesting. Tab = 4 spaces. The CodeRunner must track indentation depth correctly to know which commands belong to which loop body.

---

## Autotype Solutions
```gdscript
func _get_solution_for_step(step: Dictionary) -> String:
    match step.id:
        3: return "for row in range(2):\n    for col in range(5):\n        place_building(\"house\", col, row)"
        5: return "for row in range(4):\n    for col in range(4):\n        place_building(\"house\", col, row)"
        7: return "for row in range(3):\n    for col in range(3):\n        place_building(\"park\", col * 2, row * 2)"
        8: return "for row in range(4):\n    for col in range(4):\n        if row == 0 or row == 3 or col == 0 or col == 3:\n            place_building(\"house\", col, row)\n        else:\n            place_building(\"park\", col, row)"
        9: return "for row in range(3):\n    for col in range(3):\n        place_building(\"shop\", col + 3, row + 3)"
        10: return "for row in range(3):\n    for col in range(4):\n        place_building(\"house\", col, row)\nfor col in range(4):\n    place_building(\"shop\", col, 4)\nfor col in range(4):\n    place_building(\"tree\", col, 5)"
    return ""
```

---

## DO NOT MODIFY
- `code_runner.gd`, `builder.gd`, `mission_manager.gd`, `mission_1.gd` through `mission_4.gd`
