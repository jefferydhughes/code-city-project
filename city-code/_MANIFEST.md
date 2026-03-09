# _MANIFEST.md
# Samurai City — Project Source of Truth
# Read this file first. Every session. No exceptions.

---

## What This Project Is

**Samurai City** is a browser-based voxel city-building educational game platform that serves as the curriculum engine for the **Skill Samurai AI Makers Academy** franchise.

Students build a virtual city by completing real coding, math, and robotics challenges. Every building is earned through demonstrated skill mastery. The city is simultaneously a game, a portfolio, and a retention engine.

**This is not an LMS with game elements bolted on. It is a fully playable world that students build, inhabit, and iterate on across their entire Skill Samurai enrolment.**

---

## Non-Negotiables (Do Not Debate These)

| Rule | Rationale |
|---|---|
| Browser-only delivery | Chromebook is the primary device at franchise locations. No install permitted. |
| 60fps on mid-range Chromebook | 4GB RAM, Intel Celeron. Test on real hardware weekly. |
| Godot 4 + Compatibility renderer | Only renderer with reliable WebGL2 on Chromebook hardware generations. |
| No in-app purchases of any kind| Upgrades are earned by completing daily challenges, and completing coding levels | Franchise compliance and parent trust. Tokens earned only through curriculum. |
| Supabase as the single database | Already used in Skill Samurai franchise management platform. One system. |
| Build tokens earned through curriculum only | Core design integrity. Never gifted for attendance, never purchased. |
| Row Level Security on all Supabase tables | Student data is franchise-scoped. Never expose cross-franchise data. |
| Export size < 40MB compressed | School WiFi constraint. Hard limit. | Curriciculum lessons are aligned to the Computer Science Teachers Association (CSTA) K-12 Computer Science Standards|

---

## Current Engine Decision: Godot 4

**Decided: March 2026**

Engine: Godot 4 (latest stable)
Renderer: Compatibility (not Forward+, not Mobile)
Export: HTML5 (Web)
Resolution: 1280×720 base, responsive scaling
Language: GDScript

See `docs/DECISIONS.md` for full rationale and rejected alternatives.

---

## Project Owner

Jeff Hughes — Head of Business & Management, Kingswood University / Founder, Skill Samurai (Canada/Australia/Egypt)

---

## Repo Structure

```
samurai-city/
├── _MANIFEST.md              ← YOU ARE HERE. Read first every session.
├── PROJECT_CONTEXT.md        ← Claude Cowork / Claude Code context file
├── docs/
│   ├── GDD.md                ← Full Game Design Document
│   ├── ARCHITECTURE.md       ← Godot 4 project architecture spec
│   ├── DECISIONS.md          ← Architecture Decision Record (all tech pivots)
│   ├── ASSET_STRATEGY.md     ← Asset pipeline, sources, budget
│   └── ROADMAP.md            ← Milestones M1–M7
└── src/                      ← Godot project (populated at M1)
```

---

## Tier 1 Files (Read First)

1. `_MANIFEST.md` — this file
2. `docs/DECISIONS.md` — why we're here and what was rejected
3. `docs/GDD.md` — what the game is

## Tier 2 Files (Read When Relevant)

4. `docs/ARCHITECTURE.md` — how to build it in Godot
5. `docs/ASSET_STRATEGY.md` — what to buy vs. build
6. `docs/ROADMAP.md` — milestone sequence

---

## Key Contacts & Integrations

| System | Detail |
|---|---|
| Franchise platform DB | Supabase (same instance as franchise management dashboard) |
| Auth | Supabase Auth (student, teacher, franchise owner roles) |
| Asset source (free) | Kenney.nl City Kit 3D — GLB format, Godot GridMap compatible |
| Asset source (paid) | itch.io (post-validation only, budget $150–300 total) |
| Competition layer | Foxfire Cup — global student leaderboard, opt-in per franchise |
| Deployment | TBD at M1 — likely static host for HTML5 export |

---

## Current Build Phase

**PRE-BUILD — Documentation & Architecture**

Next action: M1 Proof of Concept
- Godot 4 project initialized
- Kenney City Kit imported into GridMap MeshLibrary
- One district rendered, camera pan/zoom working
- HTML5 export confirmed running on Chromebook browser

---

## Document History

| Date | Change |
|---|---|
| March 2026 | Initial manifest created. GDD v1.0 and Godot Architecture v1.0 complete. |
