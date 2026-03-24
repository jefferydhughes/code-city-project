# Mission 7: Conditional Expressions (if) — Claude Code Build Instructions

**File to create:** `res://scripts/mission_7.gd`
**Run with:** `--dangerously-skip-permissions`

---

## Concept Being Taught
`if` statements let code make decisions. If a condition is true, run a block. If false, skip it (or run an `else` block).

CodeCity syntax:
```
var pop = 8
if pop > 5:
    place_building("shop", 3, 3)
```

Also covers `if / else`:
```
if pop > 5:
    place_building("shop", 3, 3)
else:
    place_building("house", 3, 3)
```

Key insight: the city reacts to data. Different values → different buildings. This is where code starts feeling intelligent.

---

## Mission Narrative
**Mayor Maple:** "A smart city doesn't just build the same thing every time — it checks the situation first! High population? Build a shop. Low happiness? Plant a park. That's a conditional — code that DECIDES!"

---

## Architecture Pattern
Identical structure to `mission_1.gd`. Class name `Mission7`.

**New API function required:** `api_get_city_stat(args, line_num)` — returns mock city data (population, happiness) so students can write conditionals against it. See implementation note below.

---

## The 10 Steps

```gdscript
const steps: Array = [
    {
        "id": 1,
        "type": "explain",
        "title": "The City Decides",
        "mayor_dialogue": "What if the city could build different things depending on the situation? If the population is high, build a shop. If it's low, build a house. That 'if' is a conditional — and it's how code gets smart!",
        "instruction": "A conditional checks a condition and decides what to do:\n\nif population > 5:\n    place_building(\"shop\", 3, 3)\n\nIf population is greater than 5 → the shop gets placed.\nIf not → nothing happens.\n\nPress NEXT to try it.",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "",
        "success_condition": "explain",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["if", "var", "place_building"],
    },
    {
        "id": 2,
        "type": "guided",
        "title": "Your First If",
        "mayor_dialogue": "Run this code. The variable 'pop' is 8 — bigger than 5 — so the condition is TRUE and the shop appears!",
        "instruction": "Run this code. pop = 8, which IS greater than 5, so the shop is placed.",
        "show_grid_diagram": false,
        "starter_code": "var pop = 8\nif pop > 5:\n    place_building(\"shop\", 3, 3)",
        "hint": "Just press Run — pop is 8, the condition is true, shop appears.",
        "success_condition": "code_runs",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["if", "var", "place_building"],
    },
    {
        "id": 3,
        "type": "guided",
        "title": "Make It False",
        "mayor_dialogue": "Now change pop to 3. The condition becomes FALSE — so nothing gets placed. Run it and see!",
        "instruction": "Change 'var pop = 8' to 'var pop = 3'.\nRun — the shop should NOT appear because 3 is not greater than 5.",
        "show_grid_diagram": false,
        "starter_code": "var pop = 8\nif pop > 5:\n    place_building(\"shop\", 3, 3)",
        "hint": "Change to: var pop = 3\nThe condition 3 > 5 is false, so nothing is placed.",
        "success_condition": "count",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["if", "var", "place_building"],
    },
    {
        "id": 4,
        "type": "guided",
        "title": "If / Else",
        "mayor_dialogue": "What if we want something to happen EITHER WAY? Use 'else' — if the condition is true, do one thing; otherwise, do another!",
        "instruction": "Run this code. pop = 3, so the 'else' branch runs and a house is placed.\nThen change pop to 8 and run again — now the shop appears instead!",
        "show_grid_diagram": false,
        "starter_code": "var pop = 3\nif pop > 5:\n    place_building(\"shop\", 3, 3)\nelse:\n    place_building(\"house\", 3, 3)",
        "hint": "Run first with pop = 3 (house appears). Then change to pop = 8 (shop appears).",
        "success_condition": "code_runs",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["if", "else", "var", "place_building"],
    },
    {
        "id": 5,
        "type": "do_it",
        "title": "Write Your Own If",
        "mayor_dialogue": "The city happiness is low — only 3. If happiness is less than 5, build a park at (4, 4) to cheer people up!",
        "instruction": "Declare: var happiness = 3\nWrite an if statement: if happiness < 5, place a park at (4, 4).",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "var happiness = 3\nif happiness < 5:\n    place_building(\"park\", 4, 4)",
        "success_condition": "specific_buildings",
        "required_buildings": [
            {"type": "park", "col": 4, "row": 4},
        ],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["if", "var", "place_building"],
    },
    {
        "id": 6,
        "type": "guided",
        "title": "If Inside a Loop",
        "mayor_dialogue": "Here's where it gets exciting — put an if INSIDE a loop and each building decides its own type based on its position!",
        "instruction": "Run this code. Even columns get houses, odd columns get parks — the if checks whether col is even using the % operator (remainder).",
        "show_grid_diagram": false,
        "starter_code": "for col in range(6):\n    if col % 2 == 0:\n        place_building(\"house\", col, 0)\n    else:\n        place_building(\"park\", col, 0)",
        "hint": "Just press Run — the % 2 check alternates between houses and parks.",
        "success_condition": "code_runs",
        "required_buildings": [],
        "required_count": 0,
        "required_types": 0,
        "available_commands": ["if", "else", "for", "place_building"],
    },
    {
        "id": 7,
        "type": "do_it",
        "title": "Alternating Street",
        "mayor_dialogue": "Design a 6-building street that alternates between shops and trees!",
        "instruction": "Write a loop for 6 columns on row 3.\nIf the column is even → shop.\nIf the column is odd → tree.",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "for col in range(6):\n    if col % 2 == 0:\n        place_building(\"shop\", col, 3)\n    else:\n        place_building(\"tree\", col, 3)",
        "success_condition": "type_count",
        "required_buildings": [],
        "required_count": 6,
        "required_types": 2,
        "available_commands": ["if", "else", "for", "place_building"],
    },
    {
        "id": 8,
        "type": "challenge",
        "title": "Zone by Column",
        "mayor_dialogue": "Smart zoning! Columns 0-3 are residential (houses), columns 4-6 are commercial (shops). Use if to enforce the zone rules.",
        "instruction": "Write a loop for 7 columns on row 0.\nIf col < 4 → place a house.\nElse → place a shop.",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "for col in range(7):\n    if col < 4:\n        place_building(\"house\", col, 0)\n    else:\n        place_building(\"shop\", col, 0)",
        "success_condition": "type_count",
        "required_buildings": [],
        "required_count": 7,
        "required_types": 2,
        "available_commands": ["if", "else", "for", "place_building"],
    },
    {
        "id": 9,
        "type": "challenge",
        "title": "Border vs Interior",
        "mayor_dialogue": "Fill a 4×4 grid. Border cells get roads, interior cells get parks.",
        "instruction": "Nested loop: 4 rows × 4 columns.\nIf row==0 or row==3 or col==0 or col==3 → place a road.\nElse → place a park.",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "for row in range(4):\n    for col in range(4):\n        if row == 0 or row == 3 or col == 0 or col == 3:\n            place_building(\"road\", col, row)\n        else:\n            place_building(\"park\", col, row)",
        "success_condition": "type_count",
        "required_buildings": [],
        "required_count": 16,
        "required_types": 2,
        "available_commands": ["if", "else", "for", "place_building"],
    },
    {
        "id": 10,
        "type": "mastery",
        "title": "Smart City",
        "mayor_dialogue": "Build a SMART city — one where the code decides what to build based on conditions. Use at least one if/else, one loop, and place at least 10 buildings with at least 3 types.",
        "instruction": "Free build using conditionals!\n- At least one if or if/else\n- At least one loop\n- At least 10 buildings\n- At least 3 different building types",
        "show_grid_diagram": false,
        "starter_code": "",
        "hint": "var density = 6\nfor row in range(3):\n    for col in range(4):\n        if density > 5:\n            place_building(\"shop\", col, row)\n        else:\n            place_building(\"house\", col, row)\nfor i in range(4):\n    place_building(\"tree\", i, 4)",
        "success_condition": "type_count",
        "required_buildings": [],
        "required_count": 10,
        "required_types": 3,
        "available_commands": ["if", "else", "for", "var", "place_building"],
    },
]
```

---

## CodeRunner Implementation Notes

### New operators to support:
- `>`, `<`, `>=`, `<=`, `==`, `!=` — comparison operators returning bool
- `%` — modulo/remainder operator
- `and`, `or` — logical operators
- `if condition:` / `else:` — conditional blocks using same indentation rules as loops

### `api_get_city_stat` (optional helper for future steps):
```gdscript
func api_get_city_stat(args: Array, line_num: int) -> Variant:
    # Returns mock city stat for use in conditionals
    # args[0] = stat name: "population", "happiness", "buildings"
    if args.size() < 1:
        return 0
    match str(args[0]).to_lower():
        "population": return placed_buildings.size() * 3
        "happiness": return 5 if placed_buildings.size() < 3 else 9
        "buildings": return placed_buildings.size()
    return 0
```

This is optional for M7 — the 10 steps above use local variables instead. Add it so future missions can use dynamic city data in conditionals.

---

## Autotype Solutions
```gdscript
func _get_solution_for_step(step: Dictionary) -> String:
    match step.id:
        3: return "var pop = 3\nif pop > 5:\n    place_building(\"shop\", 3, 3)"
        5: return "var happiness = 3\nif happiness < 5:\n    place_building(\"park\", 4, 4)"
        7: return "for col in range(6):\n    if col % 2 == 0:\n        place_building(\"shop\", col, 3)\n    else:\n        place_building(\"tree\", col, 3)"
        8: return "for col in range(7):\n    if col < 4:\n        place_building(\"house\", col, 0)\n    else:\n        place_building(\"shop\", col, 0)"
        9: return "for row in range(4):\n    for col in range(4):\n        if row == 0 or row == 3 or col == 0 or col == 3:\n            place_building(\"road\", col, row)\n        else:\n            place_building(\"park\", col, row)"
        10: return "var density = 6\nfor row in range(3):\n    for col in range(4):\n        if density > 5:\n            place_building(\"shop\", col, row)\n        else:\n            place_building(\"house\", col, row)\nfor i in range(4):\n    place_building(\"tree\", i, 4)"
    return ""
```

---

## DO NOT MODIFY
- `code_runner.gd` existing dispatch logic — extend it, don't replace it
- `builder.gd`, `mission_manager.gd`, `mission_1.gd` through `mission_6.gd`
