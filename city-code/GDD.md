# Samurai City — Game Design Document & Godot Project Architecture

**CodeCity Engine · Kitsune Learning Platform**
**Skill Samurai AI Makers Academy · Version 2.0 · Confidential**

> **Core Insight:** The thing you build becomes the place you play.

---

## Reading Order

| File | Purpose |
|---|---|
| `_MANIFEST.md` | Source of truth, non-negotiables, reading order |
| `DECISIONS.md` | Architecture decision records (ADR-001 through ADR-007) |
| `docs/GDD.md` | ← This file. Full game design + Godot architecture |
| `docs/CURRICULUM_ALIGNMENT.md` | CSTA K-12 alignment, Grades 3–8 |

---

## Table of Contents

- [Part 0 — Kitsune Platform Context](#part-0--kitsune-platform-context)
- [Part 1 — Game Design Document](#part-1--game-design-document)
- [Part 2 — Godot 4 Project Architecture](#part-2--godot-4-project-architecture)
- [Part 3 — Platform Positioning & Differentiation](#part-3--platform-positioning--differentiation)

---

## Part 0 — Kitsune Platform Context

### 0.1 What Kitsune Is

Kitsune is the Learning Management System (LMS) that hosts and orchestrates all Skill Samurai curriculum engines. It owns student identity, curriculum assignments, belt progression records, parent-facing dashboards, franchise management, and payments. Kitsune does not simulate worlds or run game logic.

Samurai City (codenamed CodeCity) is the 3D simulation engine within Kitsune. It is one of three built-in coding tools:

| Engine | Type | Primary Use | Age Range |
|---|---|---|---|
| 2D Coding Engine | Browser-based blocks / text | Fast iteration, early logic, beginner onboarding | Ages 8+ |
| CodeCity (Samurai City) | Godot 4 HTML5 3D simulation | Systems programming, city-building, persistent world | Ages 8–14 |
| Advanced 3D Worlds | Server-authoritative 3D (Phase 2) | Multiplayer, AI actors, advanced system design | Ages 11+ |

### 0.2 Integration Architecture

Kitsune and Samurai City share a single Supabase instance. The connection is seamless — students, franchisees, and parents never see a seam between the LMS and the game engine.

> **Design Rule:** Samurai City reads assignments and belt state from Kitsune-owned tables. It writes game events (tokens, buildings, attendance) back to shared tables. No direct API calls between systems — Supabase is the contract layer.

| Data Owner | Table / Schema | Direction | Description |
|---|---|---|---|
| Kitsune LMS | `students` | Samurai City reads | Student profile, belt level, enrolment status |
| Kitsune LMS | `class_enrollments` | Samurai City reads | Class roster, franchise location, teacher assignment |
| Kitsune LMS | `curriculum_assignments` | Samurai City reads | Active tasks assigned by teacher in Kitsune |
| Samurai City | `tokens` | Samurai City writes | Token awards triggered by curriculum completion |
| Samurai City | `city_buildings` | Samurai City writes | Buildings placed, district, timestamp |
| Samurai City | `city_state` | Samurai City writes | Full persistent city snapshot on session exit |
| Samurai City | `attendance_log` | Samurai City writes | Check-in events for SNAP report generation |
| Shared | `competition_scores` | Both read/write | Foxfire Cup leaderboard sync |

### 0.3 Schema Folder Convention

All Samurai City–Kitsune integration tables are organised under the `/skill-samurai-academy` schema path in Supabase. Other curriculum providers plugging into Kitsune use their own schema paths. The game client references only this path — it has no awareness of other providers.

Row Level Security is enforced on all tables. The game client receives a student-scoped JWT from Kitsune on session start. It can only read its own student record and write to its own city state and token rows.

### 0.4 Event Bus

All learning engines emit structured events to a shared event bus. Kitsune reacts to these events to update progress, award badges, trigger parent notifications, and feed analytics. The game engine never calls Kitsune directly.

| Event | Emitted By | Kitsune Reaction |
|---|---|---|
| `lesson.started` | Samurai City | Log session, start attendance timer |
| `level.completed` | Samurai City | Award belt progress, unlock next assignment |
| `badge.earned` | Samurai City | Notify parent dashboard, update portfolio |
| `session.attended` | Samurai City | Write attendance_log, trigger SNAP report |
| `code.executed` | Samurai City | Feed AI insights, update teacher view |
| `token.awarded` | Kitsune LMS | Samurai City reads and updates token balance |
| `building.placed` | Samurai City | Update city_buildings, city population score |

---

## Part 1 — Game Design Document

### 1.1 Executive Summary

Samurai City is a browser-based voxel city-building game embedded within the Skill Samurai AI Makers Academy curriculum. Students build and expand a virtual city by completing real coding, robotics, and math challenges. Every building, district, and city upgrade is earned through demonstrated skill mastery — not purchased or gifted.

The game runs entirely in the browser, is optimised for Chromebook hardware, and is built in Godot 4 with HTML5 export. It serves as the persistent motivational layer across a student's entire enrolment with Skill Samurai. The city is simultaneously their portfolio, their playground, their report card, and their reason to open the app on a Tuesday night.

### 1.2 What Makes This Uncopyable

| Property | Description |
|---|---|
| Persistent, cumulative world | A building placed in Term 1 is still there in Term 8, upgraded and scripted. Students develop real attachment. Quitting means abandoning something they built. |
| Daily pull without daily instruction | Street Mode quests, happiness events, and AI guide cliffhangers pull students back between class sessions without requiring a teacher to be present. |
| Unreplicable Demo Day moment | When a parent walks up to a screen and has a conversation with an AI-powered NPC mayor their child programmed, no other enrichment program in any category competes. |

### 1.3 Core Design Philosophy

- Progress is earned, not given — every unlock requires task completion
- The city is a visual portfolio of the student's learning journey
- Gameplay mechanics reinforce curriculum concepts, not distract from them
- Chromebook-first performance — 60fps on mid-range hardware is non-negotiable
- Franchise-safe design — the system runs identically across all Skill Samurai locations
- Seamless LMS connection — students never experience a boundary between Kitsune and the game

### 1.4 Target Audience

| Audience | Detail |
|---|---|
| Primary player | Students aged 7–14 enrolled in Skill Samurai programs |
| Secondary audience | Parents (progress visibility via Kitsune parent portal), Teachers (God Mode admin view) |
| Platform | Browser (Chrome / Chromebook primary, Firefox secondary) |
| Session length | 15–45 minutes (class context) or 5–10 minutes (home check-in) |
| Skill level | No prior gaming experience required |

### 1.5 The Player Character: AI-Prompted Hero

> **Design Decision:** Every student creates their own character from a natural language prompt in the first 15 minutes of Session 1 — before the curriculum explanation, before the parent handout. The AI generates their voxel character: unique, owned, named. This character persists for their entire Skill Samurai journey.

Character creation is not cosmetic. It is a retention and pedagogical mechanism with three layers:

| Layer | Mechanism |
|---|---|
| Identity ownership | A character the student invented in their own words creates identity investment a preset avatar never achieves. Quitting means leaving their character behind. |
| Visible upgrade arc | Belt progression is reflected in the character — White Belt hero has basic gear; Black Belt hero is visibly transformed. Parents photograph it. It ends up on the fridge. |
| First prompt engineering lesson | Before writing a single line of code, students learn that specificity of language changes outcomes. "A samurai" generates something generic. "A small fox samurai with red armour and a glowing katana" generates something specific and surprising. Day one teaches the most important AI skill without calling it a lesson. |

> **Word-of-mouth engine:** The character creation moment is engineered to cause the room to erupt. Every parent who hears "I made a robot ninja who lives in my city" is a referral.

### 1.6 Dual-Mode Architecture

Samurai City operates in two distinct but deeply connected modes. Students move fluidly between them.

#### GOD MODE — The City Builder View

Top-down isometric view. All construction, scripting, AI asset generation, and economy management happens here. This is the curriculum layer — where belt-level projects are assigned, built, and submitted.

**Key Tools:**
- AI Asset Generator — describe a building, vehicle, or character; voxel model appears
- Script Editor — in-browser code editor with AI guide suggestions (Monaco / VSCode engine)
- City Dashboard — live happiness, economy, energy, and population data
- Island Map — fogged future islands visible on horizon as pull mechanic
- Live Code Visualiser — executing lines highlight, variables animate, city effects play in real time

#### STREET MODE — The Exploration & Quest View

Ground-level third-person view. The student's AI-generated avatar walks the streets of the city they built. Buildings they scripted are live. NPCs they programmed respond. Mini-games are embedded in every zone. This is the daily engagement layer.

**Key Mechanics:**
- Zone Entry Triggers — walking into a district auto-activates available quests
- Prompt-to-Play — student prompts a vehicle or game element; it spawns and is immediately playable
- NPC Quest Givers — programmed characters assign missions tied to city needs
- Cross-Island Travel — unlockable vehicles (car, plane, helicopter) travel between islands
- Screenshot / Share — city shareable URL, parent portal reads it via Kitsune

### 1.7 City Districts

| District | Curriculum Path | Visual Theme |
|---|---|---|
| Code Quarter | Scratch / Python / JS | Neon tech towers |
| Robotics Row | Hardware / Electronics | Industrial warehouses |
| Math Market | Singapore Math | Market stalls & plazas |
| AI Avenue | Machine Learning basics | Futuristic glass structures |
| Entrepreneurship Park | Business / Pitch skills | Office towers & parks |
| Samurai Dojo | Milestone / Capstone zone | Traditional Japanese architecture |

### 1.8 City Progression Tiers

| Tier | Description |
|---|---|
| Tier 1 — Village | Starter area. Dirt paths, small wooden structures. Default on enrolment. |
| Tier 2 — Town | Paved roads, brick buildings. Unlocked at Level 2 curriculum. |
| Tier 3 — City | Multi-story buildings, parks, traffic. Unlocked at Level 4. |
| Tier 4 — Metropolis | Skyscrapers, transit lines, landmarks. End-game / long-term students. |

### 1.9 Core Game Loop

| Step | Action |
|---|---|
| 1. Attend class | Student checks in via tablet or desktop at franchise location. Kitsune logs attendance. |
| 2. Receive mission | Teacher assigns curriculum task in Kitsune. Samurai City reads the assignment from `/skill-samurai-academy` tables. |
| 3. Complete task | Student finishes coding challenge, math set, or robotics build. |
| 4. Earn build token | Kitsune writes token award to shared table. Samurai City reads it and updates balance. |
| 5. Place building | Student opens Samurai City, spends token to place a building in their district. |
| 6. City updates | Building animates into place; city stats update. Event emitted to Kitsune event bus. |
| 7. Share / show off | Student shows city on class display or sends shareable URL home via Kitsune parent portal. |

### 1.10 Build Token Economy

Build Tokens are the only currency. Earned exclusively through curriculum task completion — never purchased, never gifted for attendance alone.

| Token Type | Earned By | Unlocks |
|---|---|---|
| Code Token | Completing coding challenge | Tech buildings, data towers |
| Robo Token | Finishing robotics build | Factories, labs, workshops |
| Math Token | Completing math module | Markets, bridges, roads |
| AI Token | AI concept task | Glass towers, smart infrastructure |
| Biz Token | Pitch or business exercise | Office parks, retail |
| Samurai Token | Level milestone / capstone | Dojo, special landmarks |

### 1.11 Belt Levels & Island Progression

| Belt | Age / Grade | CSTA Level | Primary Islands | Core Concepts |
|---|---|---|---|---|
| White | 7–8 / Gr. 2–3 | Level 1A–1B | Starter Island | Algorithms, sequences, variables, loops, debugging |
| Yellow | 8–10 / Gr. 3–4 | Level 1B | Zoo Island + Commerce Island | Events, conditionals, state machines, data |
| Yellow Adv. | 10–11 / Gr. 4–5 | Level 1B–2 | Survival Island | Variables, optimisation, cause-and-effect, iteration |
| Green | 11–12 / Gr. 5–6 | Level 2 | Research Campus | Functions, parameters, nested loops, data models, AI ethics |
| Blue | 12–13 / Gr. 6–7 | Level 2 | NPC District + all unlocked | Procedures, modularity, protocols, systematic testing |
| Black | 13–15 / Gr. 7–9 | Level 2–3A | Autonomous City + multiplayer | Architecture, APIs, event-driven systems, collaboration |

### 1.12 Playable Islands

Each island maps to a Bushido virtue, a belt level, and a curriculum focus. Every island has a **scaffold layer** (prebuilt for context and playability) and a **build layer** (student-built for meaning and ownership).

> **Island Design Rule:** Prebuilt elements provide context and playability. Student-built elements provide meaning and ownership. Anything a student interacts with emotionally must be something they built or scripted.

| Island | Virtue | Belt | Curriculum Focus | Auto-Trigger Mini-Game | Build-to-Unlock Mini-Game |
|---|---|---|---|---|---|
| Starter Island — Residential | Rectitude | White | If/Then logic, sequencing | Street Racer | Custom Racer |
| Zoo Island | Benevolence | Yellow | State machines, animal behavior | Zoo Runner | Animal Tamer |
| Survival Island | Courage | Yellow Adv. | Variables, resource mgmt, optimisation | Power Surge | Sky Ferry |
| Commerce Island | Honesty | Yellow Adv. | Economy, data, variables | Market Blitz | Food Truck Frenzy |
| Research Campus | Honor | Green | AI/ML basics, bias, data models | — | NPC Duel |
| NPC District | Respect | Blue | Dialogue trees, character programming | — | Custom NPC Builder |
| Autonomous City | Loyalty | Black | Full stack, event architecture | — | — |
| Battle Royale Island (Ph.2) | Justice | Green+ | Prompt engineering, multiplayer | Battle Royale match | — |
| Border Wars Island (Ph.2) | Justice | Blue+ | NPC logic, autonomous agents | Border Wars match | — |

### 1.13 Island Profiles — Phase 1 Detail

#### Starter Island — Residential District | White Belt | Rectitude

**Prebuilt scaffold:**
- Road grid and basic terrain (gives instant sense of a city)
- Town Hall building shell (student scripts the interior and lights)
- One starter NPC: the City Elder (AI guide, embodied in world)

**Student builds:**
- All residential buildings (AI-prompted, then placed)
- Park system with happiness trigger scripts
- Lighting system (timed script — the first real code)

**Street Mode:**
- Auto-triggered: Street Racer activates on main road
- Build-to-unlock: Prompt a car → Custom Racer spawns
- NPC quest: City Elder sends student to fix the park lights (debugging tutorial disguised as a quest)

---

#### Zoo Island | Yellow Belt | Benevolence

**Prebuilt scaffold:**
- 4 enclosure zones (empty — student fills them)
- Visitor path and entrance gate with turnstile revenue script running
- Zookeeper NPC (quest giver, pre-scripted)

**Student builds:**
- All animals (AI-prompted; 2+ required per enclosure)
- All animal behavior scripts (state machines: resting → eating → pacing → performing)
- Escape containment script (boundary check — triggered by the Crisis event)

**Street Mode:**
- Auto-triggered: Zoo Runner (Temple Run-style) activates at the gate
- Build-to-unlock: Animal Tamer unlocks after student has scripted 3+ animal behaviors
- NPC quest: Zookeeper reports escaped animal → Crisis event → student debugs in Street Mode

---

#### Survival Island | Yellow Belt Advanced | Courage

> **Design Intent:** Deliberately the hardest terrain. No prebuilt structures beyond a shoreline landing dock. AI guide presence is highest here — scaffolding without removing challenge.

**Prebuilt scaffold:**
- Landing dock and resource nodes (timber, stone, solar panels — marked but unactivated)
- Weather system running (student cannot control it, only respond to it)

**Student builds:**
- Resource harvesting scripts (activates the resource nodes)
- Power station (connects to main city — the belt-level deliverable)
- Rationing logic for storm events (72-hour constraint challenge)

**Street Mode:**
- Auto-triggered: Power Surge activates once power station is built
- Build-to-unlock: Sky Ferry — prompt a plane to earn access to Research Campus

### 1.14 Mini-Game System

Mini-games are the daily engagement layer — embedded in the world as natural consequences of what the student has built, not a separate game mode.

**Two trigger types:**

| Trigger Type | Description |
|---|---|
| Auto-Triggered | Walking into a zone activates a prebuilt mini-game. No building required. Low-friction daily hooks. |
| Build-to-Unlock | Student must prompt a game element into existence before the mini-game activates. The act of prompting and placing is the lesson. The game is the reward. |

**Phase 1 Mini-Game Library:**

| Mini-Game | Type | Teaches | Deliverable |
|---|---|---|---|
| Street Racer | Auto | Loops, collision detection, timing variables | Personal best leaderboard + shareable street map |
| Custom Racer | Build | Object properties, variable tuning, comparative testing | Custom vehicle permanent in city |
| Zoo Runner | Auto | Real-time event handling, score tracking | High score in zoo trophy case |
| Animal Tamer | Build | State machines, behavior trees, object interaction | New animal permanent in zoo |
| Power Surge | Auto | Graph logic, priority queues, constraint solving | Bonus city energy for 7 days |
| Sky Ferry | Build | Physics variables (speed, altitude, fuel), user controls | Unlocked island + vehicle in hangar |
| Market Blitz | Auto | Supply/demand logic, economic variables | Commerce happiness boost + coins |
| NPC Duel | Build | Conditional behavior, reaction logic, if/else chains | Custom NPC permanent in city |
| Food Truck Frenzy | Build | Data structures (menus as arrays), event handlers | Permanent revenue boost to commerce district |

### 1.15 Prompt-a-Vehicle & Cross-Island Travel

Island travel is a curriculum milestone, not a menu selection. To reach a new island, a student must earn it through belt progression AND build the vehicle. The journey is the lesson.

**The Pipeline:**
1. Unlock condition met — student completes belt requirement for the target island
2. AI guide teases: *"I can see Survival Island from here. You'll need something to get across that water. What kind of vehicle would you design?"*
3. Student prompts — "A wooden biplane with a red propeller and a small cannon." The AI generates the voxel vehicle.
4. Student scripts basic controls — speed, steering, fuel consumption. First encounter with physics variables in context.
5. In Street Mode, the student pilots the vehicle across the water. Island fog clears on arrival. This moment is engineered to be memorable.

**Vehicle Progression by Belt:**

| Belt | Vehicle | Islands Accessible | Core Concept | Prompt Complexity |
|---|---|---|---|---|
| White | Bicycle / Skateboard | Starter Island only | Basic movement controls | Single object, 3–4 descriptors |
| Yellow | Car / Motorbike | Commerce, Zoo Islands | Speed, steering, collision | Object + properties + colour |
| Green | Boat / Hovercraft | Survival, Research Islands | Physics variables, fuel logic | Vehicle + behaviour description |
| Blue | Plane / Helicopter | All unlocked islands | 3D coordinates, altitude, controls | Full system description with constraints |
| Black | Custom AI Vehicle | All islands incl. multiplayer | Student defines all parameters | Complete spec prompt — student's choice |

### 1.16 Daily Engagement Loop

Class is twice a week. The platform must pull students back every day. These six mechanics are engineered to create daily touchpoints without requiring daily instruction.

| # | Mechanic | How It Works | Why It Pulls |
|---|---|---|---|
| 1 | Fog of War Horizon | Future islands always visible — silhouetted, labelled, animated to show life inside. | Curiosity is the most powerful pull mechanic in game design. Students know what's coming before they've earned it. |
| 2 | Happiness Events | City generates a daily complaint or event — broken park, citizen leaving, weather event. | The city feels alive between sessions. Students think about it at school. They want to fix the thing that's broken. |
| 3 | AI Guide Cliffhangers | Every session ends with the guide teasing next session: "Your animals seem restless… Come back Saturday." | Narrative cliffhangers are the oldest pull mechanic in storytelling. Kids cannot not wonder what happens next. |
| 4 | Persistent World | Nothing resets. A building placed in Term 1 is still there in Term 8, alive in the city. | Loss aversion is more powerful than reward. Students protect what they built. |
| 5 | Daily Mini-Game Streak | Street Mode tracks a daily play streak — even a 5-minute Zoo Runner session counts. | Streak mechanics (Duolingo-proven) create compulsive daily return. Fear of breaking a streak outpowers reward. |
| 6 | Public Portfolio Feed | Every build auto-added to shareable city portfolio URL. Parents follow. Classmates visit. | Social visibility creates pride, which creates effort, which creates engagement. |

### 1.17 God Mode — Teacher / Admin View

Teachers and franchise owners access a top-down SimCity-style view with additional controls. God Mode is not visible to students.

- View all students' cities in the class roster
- Force-award tokens for exceptional work or makeup sessions
- View curriculum completion vs. city progress correlation (pulled from Kitsune)
- Generate SNAP attendance reports tied to city activity
- Place class-wide seasonal decorations (holidays, competitions)
- Toggle Foxfire Cup leaderboard visibility for class competitions

### 1.18 Foxfire Cup Integration

The Foxfire Cup is Skill Samurai's global student competition. Samurai City integrates a leaderboard layer tracking city population score across franchise locations during competition windows.

- City population score = sum of all placed buildings × tier multiplier
- Leaderboard is per-class, per-franchise, and global
- Competition windows are time-boxed (e.g., 4-week term sprints)
- Franchisees can opt in or out of global leaderboard visibility

### 1.19 Phase 2 — Multiplayer Islands

> **Design Philosophy — Earned, Not Given:** Multiplayer unlocks at Green Belt. By that point a student has built 5+ islands, scripted dozens of behaviors, and spent 4+ terms in their city. They arrive at multiplayer as a builder going to war with something real to defend. That investment level is what makes Samurai City's multiplayer genuinely compelling rather than generic.

| Feature | Battle Royale Island | Border Wars Island |
|---|---|---|
| Format | Up to 20 students, shared arena, Fortnite-style | Two-player territorial control, one shared island |
| Pre-match curriculum | Each player prompts 2 weapons + 1 vehicle. Better prompts = better items. | Students script NPC soldier behavior (patrol, attack, retreat). |
| Mid-match curriculum | Prompt defensive structures using accumulated Prompt Coins. | Battle phase: scripted behaviors execute autonomously. |
| Post-match curriculum | Winner gets Victory Banner placed in city automatically. | AI guide analyzes why the NPC strategy won or lost. |
| Safety | Franchise-only lobbies; no chat; AI-moderated content. | Franchise-only lobbies; no chat; AI-moderated content. |
| Belt unlock | Green Belt minimum | Blue Belt minimum |

### 1.20 Stakeholder Value Propositions

| Stakeholder | What They See |
|---|---|
| Students | Their city. Their character. Their zoo. Their racing car. Their mayor. A world that exists because they built it — and keeps growing because they can't stop. |
| Parents | Their child built a city. It's alive. Their character walks the streets. The mayor NPC answered a question. Progress visible in Kitsune without asking the teacher. |
| Franchisees | A platform that does the daily pull for them. They teach twice a week. The game keeps students engaged on the other five days. Retention baked into the product. |
| Investors | A persistent world that compounds engagement over years. Every new belt level deepens city investment. Churn rate approaches zero after 3+ terms of builds. Genuine IP moat. |

### 1.21 Out of Scope — Version 1.0

- In-app purchases of any kind
- Mobile app (iOS / Android) — browser only
- 3D character customisation beyond belt-visible upgrades
- Multiplayer — Phase 2 only (see 1.19)

---

## Part 2 — Godot 4 Project Architecture

### 2.1 Engine & Export Configuration

| Setting | Value |
|---|---|
| Engine | Godot 4.x (latest stable) |
| Export target | HTML5 (Web) |
| Renderer | Compatibility (required for Chromebook WebGL2 support) |
| Resolution | 1280×720 base, responsive scaling |
| Physics | None — city builder does not require physics engine |
| Audio | Minimal — ambient sound only, no positional audio |
| Asset format | GLB for 3D models, PNG for UI, OGG for audio |

### 2.2 Non-Negotiables

| Constraint | Value / Rule |
|---|---|
| Browser-only | No downloads, no installs, no app stores — every classroom has a browser |
| Chromebook target | 60fps, Intel Celeron 4GB RAM class hardware |
| Renderer | Compatibility renderer only — never Forward+ or Mobile |
| Export size | < 40MB compressed |
| No IAP | Zero in-app purchases of any kind, ever |
| Token earning | Build tokens earned through curriculum only — never purchased or attendance-gifted |
| RLS enforced | Row Level Security on all Supabase tables |
| API keys | Never in the game client — student JWT only, scoped by Kitsune |

### 2.3 Folder Structure

```
res://scenes/city/          — City grid, district zones, camera rig
res://scenes/buildings/     — Individual building scenes (.tscn)
res://scenes/ui/            — HUD, token display, overlays, modal dialogs
res://scenes/god_mode/      — Teacher dashboard, roster, force-award UI
res://scenes/street_mode/   — First-person camera rig, NPC controller, screenshot UI
res://assets/models/        — GLB voxel building models (Kenney City Kit + custom)
res://assets/textures/      — Building textures, UI sprites, icons
res://assets/audio/         — Ambient loops, placement sounds, UI feedback
res://scripts/core/         — GameManager, TokenManager, PlayerData, EventBus
res://scripts/city/         — CityGrid, BuildingPlacer, DistrictManager
res://scripts/api/          — Supabase HTTP calls, auth, sync
res://data/                 — JSON config — buildings catalogue, district definitions
res://addons/               — Godot plugins (HTTP request helpers)
```

### 2.4 Core Scene Architecture

**Main.tscn (Root Scene)**
```
Node: Main (Node)
├── GameManager (autoload singleton)
├── UILayer (CanvasLayer) — always on top
├── CityViewport (SubViewport) — renders the 3D city
└── StreetModeViewport (SubViewport) — first-person view, hidden by default
```

**CityGrid.tscn**
```
Node3D: CityGrid
├── GridMap — uses Kenney City Kit MeshLibrary
├── DistrictZone nodes (one per district, Area3D with CollisionShape3D)
├── CameraRig (Node3D + Camera3D) — top-down orthographic, pan/zoom
└── BuildingPlacer — handles ghost preview + placement confirmation
```

**HUD.tscn**
```
CanvasLayer: HUD
├── TokenBar — displays current token counts per type
├── CityStatsPanel — population, tech score, unlock progress
├── DistrictUnlockNotification — animated pop-up on milestone
└── GodModeToggleButton — only visible when teacher session active
```

### 2.5 Autoload Singletons

Autoloads are registered in Project Settings → Autoload. Globally accessible across all scenes.

| Singleton | Script | Responsibility |
|---|---|---|
| GameManager | `game_manager.gd` | Scene transitions, session state, mode switching |
| TokenManager | `token_manager.gd` | Token balances, award logic, spend validation |
| PlayerData | `player_data.gd` | Local cache of student profile and city state from Kitsune |
| SupabaseClient | `supabase_client.gd` | All HTTP calls to Supabase REST API (`/skill-samurai-academy`) |
| EventBus | `event_bus.gd` | Global signal hub — decouples all systems, emits to Kitsune event bus |
| AudioManager | `audio_manager.gd` | Background music, UI sounds, placement FX |

### 2.6 EventBus Signal Map

All cross-system communication goes through EventBus signals. Direct node references between unrelated systems are prohibited.

| Signal | Emitted By | Listened By |
|---|---|---|
| `token_awarded(type, amount)` | SupabaseClient | TokenManager, HUD |
| `token_spent(type, amount)` | TokenManager | BuildingPlacer, HUD |
| `building_placed(building_id, cell)` | BuildingPlacer | CityGrid, PlayerData, HUD, SupabaseClient |
| `district_unlocked(district_id)` | DistrictManager | CityGrid, HUD, SupabaseClient |
| `mode_changed(mode)` | GameManager | All viewports, HUD |
| `student_loaded(profile)` | SupabaseClient | PlayerData, HUD, CityGrid |
| `teacher_session_started()` | GameManager | HUD, GodMode scenes |
| `lesson_event(event_type, payload)` | EventBus | SupabaseClient → Kitsune event bus |

### 2.7 Supabase Integration

Samurai City reads and writes to the Supabase instance shared with the Kitsune LMS. All tables are under the `/skill-samurai-academy` schema. The game is a front-end client — it does not own the database schema.

| Operation | Table / Endpoint | Notes |
|---|---|---|
| Load student profile + city state | `students`, `city_state` | Read on session start. Student JWT scoped by Kitsune. |
| Read current assignments | `curriculum_assignments` | Kitsune-owned. Game reads only. |
| Save city state on exit | `city_state` (upsert) | Full city snapshot. RLS: student writes own row only. |
| Award token (teacher action) | `tokens` (insert via Edge Function) | Teacher JWT required. Validated server-side. |
| Spend token (place building) | `tokens` (insert), `city_buildings` (insert) | Atomic: both writes or neither. |
| Fetch class roster (God Mode) | `class_enrollments JOIN students` | Teacher JWT required. |
| Log attendance check-in | `attendance_log` (insert) | Triggers SNAP report generation in Kitsune. |
| Foxfire Cup score sync | `competition_scores` (upsert) | Shared read/write. Franchise-scoped RLS. |

> **Security Rule:** Never store API keys in the game client. Student JWT only, issued by Kitsune on session start. Row Level Security enforced on every table. API keys live in Supabase Edge Functions only.

### 2.8 Asset Pipeline

**Phase 1 — Free Assets (Prototype)**
- Kenney.nl City Kit 3D — download GLB pack, import into Godot GridMap MeshLibrary
- Kenney.nl UI Pack — buttons, panels, icons for HUD
- OpenGameArt.org — ambient audio loops
- GDQuest demo projects — reference architecture only, strip and adapt

**Phase 2 — Paid Assets (Post-Validation)**
- Modular city asset pack from itch.io (~$20–50) if Kenney style doesn't fit brand
- Custom Samurai Dojo district assets (unique IP, not available free)
- Budget estimate: $150–300 total for full asset set including custom district

### 2.9 Chromebook Performance Targets

| Metric | Target |
|---|---|
| Frame rate | 60fps on Chromebook mid-range (4GB RAM, Intel Celeron) |
| Initial load time | < 8 seconds on school WiFi (20 Mbps) |
| Export size | < 40MB compressed |
| Draw calls | < 200 per frame (use GridMap batching) |
| Polygon budget | < 50,000 tris visible at once |
| Texture atlas | All UI on single 2048×2048 atlas |

### 2.10 Build Milestones

| Milestone | Deliverable | Effort |
|---|---|---|
| M1 — Proof of Concept | Godot project, Kenney assets in GridMap, 1 district, camera pan/zoom, browser export on Chromebook | 1–2 weeks |
| M2 — Token MVP | Token system, 5 building types placeable, Supabase read/write to `/skill-samurai-academy` | 2–3 weeks |
| M3 — God Mode Alpha | Teacher session toggle, class roster from Kitsune, force-award token | 1–2 weeks |
| M4 — Street Mode | First-person camera, NPC placement, screenshot + share via Kitsune portfolio URL | 2 weeks |
| M5 — Full District Set | All 6 districts, all token types, full building catalogue | 3–4 weeks |
| M6 — Foxfire Cup | Leaderboard API, competition window logic, global score sync | 1–2 weeks |
| M7 — Franchise Pilot | Deploy to 2 pilot locations, gather performance + UX data | 2 weeks |
| M8 — Full Platform (Months 10–18) | All 8 islands + full Street Mode mini-game library + Prompt-a-Vehicle + daily engagement loop + multiplayer | 4–6 months |

---

## Part 3 — Platform Positioning & Differentiation

### 3.1 Where Samurai City Fits in the Learning Stack

| Layer | Product | Role |
|---|---|---|
| Blocks / early text | Kitsune 2D Coding Engine | Fast onboarding, immediate feedback, beginner confidence |
| Systems programming | Samurai City (CodeCity) | Persistent world, cause-and-effect, real code controlling infrastructure |
| Advanced / multiplayer | Kitsune 3D Worlds (Phase 2) | Server-authoritative, multiplayer, AI actors, advanced system design |
| Identity + LMS | Kitsune Platform Hub | Student record, belt state, assignments, payments, parent portal, analytics |

### 3.2 Competitive Differentiation

| Capability | Samurai City | Gamefroot | CodeCombat / Ozaria |
|---|---|---|---|
| Persistent world | Core mechanic — city never resets | Level-based, no persistence | Puzzle-based, no world state |
| Systems thinking | Every script affects city state | 2D platformer context only | Puzzle logic only |
| AI integration | AI guide + AI actors in world | None | None |
| Data model refinement | City model refined across terms | Not addressed | Not addressed |
| Iterative planning | Iterative gates at every belt | Partial | Partial |
| Collaborative computing | Foxfire Cup, Portfolio Feed | Class sharing only | Leaderboards only |
| AI ethics curriculum | Research Campus module | Not addressed | Not addressed |

### 3.3 Pedagogical Progression Model

| Stage | Cognitive Shift | Samurai City Layer |
|---|---|---|
| Foundation District | Code makes things happen | Starter Island — lights, roads, if/then |
| Commerce & Services | Logic controls behavior | Zoo + Commerce Islands — state machines, data |
| Industrial / Survival | Data drives decisions | Survival Island — resource management, optimisation |
| AI & Systems | Systems interact over time | Research Campus + NPC District — agents, events, ethics |
| Autonomous City | Architecture shapes outcomes | Autonomous City + multiplayer — full-stack design |

### 3.4 Ethical Monetisation Model

New content is new capability, not cosmetic.

| Expansion Type | Examples | Why It's Ethical |
|---|---|---|
| Island Packs | Arctic Systems Island, Python Syntax Island, AI Agents Island | New learning environments with new constraints — not power, speed, or cosmetics |
| B2B Licensing | School curriculum deployment, white-label franchise tool | Sells access to a structured learning system, not individual upgrades |
| B2C Subscription | Kitsune platform access including Samurai City | Flat fee — progress earned through mastery, never purchased |

> **Rule:** No ads. No microtransactions. No pay-to-win. No pay-for-cosmetics. The only thing that unlocks a building is completing the curriculum task that earns the token.

---

*Samurai City GDD v2.0 · Skill Samurai AI Makers Academy · Confidential*
*See `_MANIFEST.md` for reading order · See `DECISIONS.md` for full ADR log*
