# DECISIONS.md
# Samurai City — Architecture Decision Record
# Every major tech decision, in order, with full rationale.
# If you are about to re-argue a settled decision, read this first.

---

## How to Read This File

Each entry follows this format:

- **Decision** — what was chosen
- **Date** — when it was settled
- **Status** — ACTIVE / SUPERSEDED / DEFERRED
- **Context** — what problem we were solving
- **Rationale** — why this option won
- **Rejected alternatives** — what was considered and why it lost
- **Constraints it creates** — what this decision locks in downstream

---

## ADR-001: Platform — Browser-First, No Install

**Decision:** The game runs entirely in the browser. No desktop app, no install, no app store.

**Date:** February 2026

**Status:** ACTIVE

**Context:** Skill Samurai franchise locations use Chromebooks as the primary student device. School IT policies prohibit software installation. Parents access from home on whatever device they have.

**Rationale:**
- Chromebook cannot run native desktop apps
- Zero-install means zero IT friction at franchise locations
- URL-based access works for home play, parent review, and Demo Day displays
- HTML5 export is supported by all three shortlisted engines (Godot, Unity, React/Three.js)

**Rejected alternatives:**
- Electron app — requires install, ruled out by school IT constraints
- iOS/Android app — not the primary franchise device; Phase 2 consideration only
- Roblox as host — explored briefly; vendor lock-in, revenue share, content moderation risk

**Constraints it creates:**
- Export size must stay under 40MB (school WiFi)
- Renderer must support WebGL2 reliably across Chromebook hardware generations
- No native filesystem access; all persistence via Supabase

---

## ADR-002: Initial Engine Exploration — Blip (Luau)

**Decision:** Evaluated Blip as the game platform. Not selected.

**Date:** February 2026

**Status:** SUPERSEDED by ADR-004

**Context:** Blip is a Roblox-like platform built in C/C++ using BGFX for rendering, scripted in Luau (a Lua derivative). It supports browser via WebAssembly and has a built-in multiplayer server infrastructure.

**Why it was attractive:**
- Luau is beginner-friendly — aligns with Skill Samurai's student coding curriculum
- WebAssembly browser export is mature
- Built-in multiplayer without a separate server
- Cross-platform (iOS, Android, Web, Desktop) from one codebase

**Why it was rejected:**
- Platform is early-stage; documentation incomplete
- Limited AI coding tool support for Luau (Cursor, Claude Code work poorly with GDScript; even worse with Luau)
- No existing ecosystem of educational game templates
- Vendor dependency risk — platform controlled by third party
- Luau-to-JavaScript converter would be required for LMS integration, adding complexity

**Constraints it created (now resolved):** None — decision superseded.

---

## ADR-003: Second Engine Exploration — React + Three.js (React Three Fiber)

**Decision:** Evaluated React/Three.js as the build stack. Not selected for this phase.

**Date:** February 2026

**Status:** SUPERSEDED by ADR-004

**Context:** After rejecting Blip, the team explored building the game entirely in the web stack — React + Vite frontend, Three.js for 3D rendering via React Three Fiber (R3F), Zustand for state, Node/Express backend, Supabase for data.

**Full stack that was designed:**

| Layer | Technology |
|---|---|
| Frontend | React + Vite + TypeScript |
| 3D Rendering | Three.js via React Three Fiber |
| Voxel system | InstancedMesh (single draw call for 50k+ voxels) |
| State | Zustand |
| AI Asset Generation | Meshy.ai API (text-to-3D, GLB output) |
| AI Guide | Claude Haiku (City Elder NPC) |
| Moderation | OpenAI Moderation API (free tier) |
| Backend | Node.js + Express |
| Database | Supabase (Postgres + Auth + Storage) |
| Deployment | Vercel (frontend) + Railway (backend) |

**Why it was attractive:**
- Full AI coding tool support — Cursor and Claude Code generate correct R3F code reliably
- No engine install — everything is npm packages
- Vercel/Railway deployment is zero DevOps
- Supabase already in use on Skill Samurai franchise platform
- InstancedMesh rendering approach solves Chromebook performance

**Why it was superseded:**
- Three.js has no built-in scene graph, physics system, input manager, or animation system
- 80% of developer time would be spent building engine infrastructure rather than game content
- As scope expanded (side quests, Street Mode first-person, Battle Royale island, NPC programming), the missing game engine layer became a structural liability
- Godot 4 provides all of these systems out of the box with browser export

**What carries forward into Godot build:**
- Supabase as the database (unchanged)
- Claude Haiku as the AI guide model (unchanged)
- Meshy.ai as the asset generation API (to be evaluated for Godot GLB import pipeline)
- InstancedMesh performance insight → Godot equivalent is GridMap (same batching principle)
- All GDD content, district design, token economy, and game loop

**Constraints it created (now resolved):** None — superseded. The React architecture document exists in project history for reference only.

---

## ADR-004: Current Engine Decision — Godot 4 (HTML5 Export)

**Decision:** Build Samurai City in Godot 4 with HTML5 export, using the Compatibility renderer.

**Date:** March 2026

**Status:** ACTIVE

**Context:** As the game design expanded beyond a simple city grid (Street Mode first-person, God Mode teacher dashboard, side quests, NPC programming, Battle Royale island), the lack of a real game engine in the React/Three.js stack became a structural problem. Godot 4 was evaluated as the solution.

**Rationale:**

| Factor | Detail |
|---|---|
| Browser export | Native HTML5 export. Runs on Chromebook without install. |
| Renderer | Compatibility renderer = reliable WebGL2 across all Chromebook hardware |
| Scene system | Built-in scene graph, node hierarchy, signals — all the infrastructure Three.js lacks |
| GridMap | Godot's built-in voxel city system. Takes Kenney City Kit assets directly. |
| GDScript | Beginner-readable. AI coding tools (Claude Code) support it adequately. |
| Cost | Free. Open source. No royalties. Critical for a franchise product. |
| Asset ecosystem | Godot Asset Library + itch.io + Kenney.nl all compatible |
| Export size | Smaller than Unity WebGL. Manageable under 40MB constraint. |

**Rejected alternatives at this stage:**

| Engine | Reason rejected |
|---|---|
| Unity WebGL | 5–20 min build times. 30–80MB WebGL bundles. C# has weak AI tool support. School WiFi cannot handle bundle size. |
| Unreal Engine | Not browser-viable. Overkill for this scope. Wrong audience. |
| Babylon.js | Legitimate but smaller community, less AI tool familiarity, fewer resources. Reconsider for Phase 2 Street Mode if physics demands it. |
| PlayCanvas | Visual editor workflow is hard to version-control and AI-pair-program with. |
| Godot 3.x | Godot 4 is the current stable. No reason to use the legacy version. |

**Constraints it creates:**
- Must use Compatibility renderer (not Forward+) — no SDFGI, VoxelGI, volumetric fog
- GDScript is the primary language (not C# — weaker AI tool support in Godot context)
- Supabase calls made via HTTPRequest node wrapped in GDScript
- All assets must be GLB format for Godot import
- Performance targets must be validated on actual Chromebook hardware, not MacBook

---

## ADR-005: Database — Supabase (Shared Instance)

**Decision:** Samurai City reads and writes to the same Supabase instance as the Skill Samurai franchise management platform.

**Date:** March 2026

**Status:** ACTIVE

**Context:** Skill Samurai already runs a franchise management platform on Supabase. Student records, attendance, and franchise data already exist there.

**Rationale:**
- No second database to maintain
- Student identity already exists — no new auth system
- Attendance log integration is a table write, not an API integration
- Row Level Security isolates franchise data without custom middleware

**Constraints it creates:**
- Game client must use JWT auth from existing Supabase Auth session
- API keys never stored in game client — RLS handles data access
- Any new tables must be designed to fit the existing schema conventions
- Token award logic must go through Edge Functions, not direct table writes, to prevent client-side manipulation

---

## ADR-006: Asset Strategy — Free First, Paid Post-Validation

**Decision:** Build the M1 prototype entirely with free assets (Kenney.nl). Spend money on assets only after the prototype validates on real Chromebook hardware.

**Date:** March 2026

**Status:** ACTIVE

**Context:** At concept stage, spending $500 on assets before a single line of code is written is premature. Kenney.nl provides a free, Godot-compatible voxel city kit that is sufficient for prototype validation.

**Asset budget (post-validation):**
- Modular city pack from itch.io: $20–50
- Custom Samurai Dojo district (unique IP): commissioned separately
- Total ceiling: $300

**What is never purchased:**
- Core gameplay logic
- Curriculum challenge system
- Token economy
- Any system that constitutes Skill Samurai IP

---

## ADR-007: AI Guide Character — Claude Haiku (City Elder)

**Decision:** The in-game AI guide runs on Claude Haiku. Character name: The City Elder.

**Date:** February 2026 (carried forward)

**Status:** ACTIVE

**Rationale:**
- Haiku is the fastest and cheapest Claude model — required for real-time in-game dialogue
- 60-word response cap enforced in system prompt
- Full city state passed in system prompt on every call
- Never provides direct answers — asks guiding questions only
- Character never breaks — always responds as The City Elder, never as an AI

**Constraints it creates:**
- City state payload in system prompt must stay within context limits
- Response cap must be enforced server-side, not trusted from client
- All AI guide calls go through backend — API key never in game client

---

## Open Questions (Unresolved)

| Question | Context | Target Decision Date |
|---|---|---|
| Meshy.ai for Godot? | Meshy.ai was validated for Three.js GLB import. Need to confirm GLB import pipeline works cleanly in Godot 4 GridMap MeshLibrary. | M1 milestone |
| Street Mode engine | First-person walk-through may need physics (CharacterBody3D). Evaluate at M4. | M4 milestone |
| Battle Royale island | Requires real-time multiplayer. Godot has built-in multiplayer via ENet/WebRTC. Architecture TBD. | Phase 2 |
| Foxfire Cup global sync | Score aggregation across franchises. Likely a Supabase Edge Function + scheduled job. | M6 milestone |
| Mobile browser support | Safari on iPad is a secondary target. WebGL2 support varies. Test at M2. | M2 milestone |

---

*Last updated: March 2026*
*Maintained by: Jeff Hughes / Skill Samurai*
