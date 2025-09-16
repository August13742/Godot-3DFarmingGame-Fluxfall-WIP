https://github.com/user-attachments/assets/b58662d5-b049-41d7-b72f-06d5dd804e22


# Fluxfall (WIP) — Systems Showcase (16.09.2025 Snapshot)

> **Disclaimer**
> I’m a programmer, not a game designer. This repository is a collection of modular game systems, editor tooling, and engine integration experiments. The gameplay loop is intentionally incomplete.

- **Engine:** Godot 4.5
- **License:** MIT (see `LICENSE`).

[🇦🇺 English](README.md) | [🇯🇵 日本語](README.ja.md)
---

## Contents

- [Fluxfall (WIP) — Systems Showcase (16.09.2025 Snapshot)](#fluxfall-wip--systems-showcase-16092025-snapshot)
  - [🇦🇺 English | 🇯🇵 日本語](#-english---日本語)
  - [Contents](#contents)
  - [Project Overview](#project-overview)
  - [Architecture at a Glance](#architecture-at-a-glance)
  - [Core Systems](#core-systems)
    - [Agent System](#agent-system)
    - [Items, Inventory, Crafting](#items-inventory-crafting)
    - [Crop System](#crop-system)
    - [Player \& Camera](#player--camera)
    - [Day/Night \& Time](#daynight--time)
    - [Audio](#audio)
    - [UI \& Debug](#ui--debug)
  - [Editor Tooling](#editor-tooling)
  - [Addons (`addons/augusts`)](#addons-addonsaugusts)
  - [Project Layout](#project-layout)
  - [Build \& Run](#build--run)
  - [Roadmap](#roadmap)
  - [Notes for Reviewers](#notes-for-reviewers)

---

## Project Overview

Fluxfall is a 3D farming-sim tech playground focused on:

* **Autonomous helper agents** driven by a **job board with reservation-based selection**; **utility scoring is planned** (targeting ONI/RimWorld-class behavior).
* **Capability-based items** with inventories, crafting, and editor-time databases.
* **Crops with stochastic growth** and hydration gating, decoupled visual vs calc stages.
* **Third-person ARPG camera** with aim queries and interaction controller.
* **Robust editor tooling** to accelerate authoring and QA.

This project prioritizes **clean seams between systems** and **data-driven authoring** over content breadth.

---

## Architecture at a Glance

* **Resources-as-truth:** Items, recipes, crops, SFX, jobs defined as `Resource` assets for diffability and reuse.
* **Signals + Callables:** Loose coupling between emitters, managers, and interactables.
* **Managers:** Small singletons for cross-cutting concerns (inventory, job board, time, audio).
* **Task selection:** **reservation-based** with simple filters (priority, distance, skill fit). Utility scoring is on the roadmap.
* **Editor-first:** `@tool` inspectors, bake buttons, and conditional properties to reduce iteration time.

---

## Core Systems

### Agent System

Autonomous worker NPCs that discover, reserve, and execute jobs from the world. **Current selection is reservation-based** (priority/distance/skill filters); a full utility-scoring layer is planned.

**Key Concepts**

* **Agent:** `CharacterBody3D` with `NavigationAgent3D`, animation state machine, stuck detection, and rotation/velocity targets.
* **Job Data:** `JobData` resource defines `priority`, `required_skills: Dictionary[StringName,int]`, `item_requirements`, and an ordered `task_list`.
* **Job Instance & Board:** runtime instances enqueued on a central board; agents reserve, execute, or release on failure.
* **Emitters:** domain-agnostic `JobEmitterComponent` listens to a parent signal and posts job opportunities based on a comparison rule and optional validator. This keeps interactables decoupled from agent internals.
* **Skills:** per-agent `Dictionary[StringName,int]` used to weight task suitability.
* **Inventory Integration:** agents fetch/consume items as per `ItemRequirement` (specific ID or capability-providing item).
* **Debug Taskboard:** in-engine UI to inspect **Pending/Active** queues, agents, requeue/cancel, and camera focus.

**Proposed Utility/Cost Model (WIP, partial placeholder)**  
Target design combines distance, inventory ops, skill fit, and urgency:



```
utility(job, agent) = w_d * f_distance(agent, job)
                   + w_i * f_inventory(job.requirements, agent.inventory)
                   + w_s * f_skill(job.required_skills, agent.skills)
                   + w_p * f_priority(job.priority)
                   + w_c * f_context(job, agent)  # domain modifiers
```


* Treat as cost (lower is better) or invert/normalize as needed.
* Context handles hydration criticality, harvest spoil windows, etc.

**Job Lifecycle**

1. **Opportunity posted** by emitter or manager.
2. **Discovery** via board query (TODO: filtered by spatial cell).
3. **Reservation** with token + TTL to avoid races and thrash.
4. **Execution**: ordered tasks with failure handling and retries.
5. **Completion** posts side-effects (e.g., inventory deposits) and signals.

**Movement & Robustness (Improvements Planned)**

* Navigation callbacks drive velocity; `stuck_time` triggers path refresh or fallback steering.
* Obstruction probes align with camera/interaction logic for consistency.

**Performance Hooks (planned/partial)**

* **Spatial partitioning:** grid buckets for jobs and interactables; agents query nearest eligible cell set.
* **Selection cadence:** staggered re-query and exponential backoff to reduce board churn.
* **Caching:** agent-local LRU of recent successes; board-side index by capability and tag.

### Items, Inventory, Crafting

**Capability-based** item architecture to avoid inheritance bloat.

* **ItemResource:** data-driven item with optional capability script to express behaviors (e.g., Seed, Tool).
* **ItemRequirement:**
  * **Specific item** by `StringName` ID, or
  * **By capability** (any item implementing the capability script).
* **InventoryComponent:** per-entity storage; **InventoryManager** registry for global lookup.
* **Crafting:** recipes consume items (respecting `is_consumed`) and produce outputs; workstation scenes handle UX.
* **Editor QOL:** inspector actions to spawn item instances, validate capability matches, and auto-generate item DBs from a folder.

### Crop System

Stochastic growth with tunable distribution, hydration gating, and agent hooks.

* **States:** `empty → planted → growing → harvestable`, with clear handlers per state.
* **Growth model:** growth tick probability `p = (1/I) * P_tick * P_grow`; separating **visual** vs **calc** stages for controllable mean/variance.
* **Hydration:** `hydration_changed` signals; debug override `always_hydrated` for testing.
* **Billboard plants:** `BillboardPlantResource` stores per-stage textures, baked UV rects, scale factors, vertical offsets. Editor button recomputes data; alpha threshold tunable.
* **Agent hooks:** job emitters post water/harvest tasks when thresholds are crossed.

### Player & Camera

Third-person ARPG camera with offset-aware orbiting and aim queries.


### Day/Night & Time

* Central time singleton provides in-game minutes and time scale.
* Consumers (crops, agents) subscribe to ticks. Sleep/freeze effects are time-scale adjustments.

### Audio

* `SFXResource` abstracts stream, linear volume, pitch, and loop flags.
* One-shot helpers spawn `AudioStreamPlayer3D` at nodes with selectable attenuation.
* Project includes `default_bus_layout.tres` for basic mixing.

### UI & Debug

* **Debug Taskboard** to monitor job queues and agents; focus, requeue, cancel actions.
* Minimal prompts/HUD for interactions; intended for engineering debugging rather than player UX.

---

## Editor Tooling

* `@tool` resources with **conditional inspector fields** via `_get_property_list` (e.g., weighted loot vs guaranteed drops; capability vs specific item requirement).
* **Bake buttons** to precompute billboard crop UV/scale/offset data.
* **Auto database generation** for items/recipes by scanning resource folders.
* **Job emitter inspector** exposes: signal name, argument index, comparison mode, and optional validation callable.

These tools are meant to cut authoring time and reduce human error in data entry.

---

## Addons (`addons/augusts`)

Locally maintained plugins shipped as submodules for reuse:

* `addons/augusts_audio_manager/`  
  High-level SFX/BGM helpers and **3D one-shot** utilities; resource-driven configuration, warnings for misuse (e.g., looping via one-shot).

* Other `addons/augusts_*` folders in this repo are authored for this project family and provide **debug UI** and **authoring utilities** (item/inventory QOL). Their presence can vary per checkout; they integrate without coupling to game logic.

---

## Project Layout

Top-level directories (selection):

* `AgentSystem/`, `CraftingSystem/`, `CropSystem/`, `DayNightSystem/`, `InventorySystem/`, `Items/`, `Interactables/`, `Managers/`, `Player/`, `ProceduralTerrain/`, `Shaders/`, `UI/`, `_Resources/Audio/SFX_resource/`, `addons/`.
* Root scenes/resources: `ThirdPersonObserverCamera.tscn/gd`, `WorkerAgent.tscn`, `terrain3dtest.tscn`, `default_bus_layout.tres`, `project.godot`.

---

## Build & Run

1. Install **Godot 4.5+**.
2. Clone repo with submodules if you want local addon code:

   ```bash
   git clone --recurse-submodules https://github.com/August13742/Godot-3DFarmingGame-Fluxfall-WIP.git

3. Open the folder in Godot.
4. Audio busses are set via `default_bus_layout.tres`.

> Input map and control bindings are standard third-person defaults; adjust in Project Settings as needed.

---

## Roadmap

**Immediate:**

* **Spatial Partitioning + Selection Algorithms** for Agent discovery:

  * Uniform **grid buckets** for jobs/interactables; agents query K-nearest cells.
  * Cost-aware **nearest-eligible** selection with reservation tokens and TTL.
  * Staggered re-evaluation cadence; LRU caches for last success per job tag.
* **Storage Systems & Networks:**

  * Chests/storage with capacity, filters, and access costs.
  * Agent **storage network** queries (nearest provider/consumer) with haul job synthesis.
  * Inventory deposit/withdraw tasks integrated into job pipelines.

**Short-term:**

* Agent avoidance polish; retry/backoff policies; board-side indices by capability/tag.
* More job sites with emitter hooks.

**Stretch:**

* Basic combat jobs; simple mobs for pathing stress tests.
* Town/world scenes and a thin gameplay loop to stitch the systems.

---

## Notes for Reviewers

* Systems are designed for **reuse** and **experimentation**. Expect clean seams and explicit data boundaries.
* Editor tooling is a first-class goal; most data can be authored without touching code.
