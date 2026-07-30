# `AGENTS.md`

```markdown
# AGENTS.md

This repository contains the design and implementation of **The Warden of the Slab**, a strategy-action game set after the events of *Hollow Knight: Silksong*.

This document describes how AI coding assistants should contribute to the project.

---

# Before Writing Code

Always read the following documents first:

1. design/vision.md
2. design/gameplay.md
3. design/game_rules.md

If a requested feature appears to conflict with these documents, ask for clarification rather than silently changing the design.

The design documents are considered the source of truth.

---

# Development Philosophy

Prefer systems over scripts.

Whenever possible, implement reusable game systems rather than one-off events.

Examples:

- Prisoners should all use the same imprisonment system.
- Factions should all use the same retaliation system.
- Departments should all use the same research system.

Avoid special cases unless explicitly requested.

---

# Core Design Pillars

Every feature should reinforce at least one of the following:

- Containment rather than destruction.
- Strategic tradeoffs.
- Long-term consequences.
- A living prison.
- A living Citadel.
- Player choice with meaningful costs.

If a mechanic does not strengthen these ideas, reconsider whether it belongs.

---

# Gameplay Philosophy

The player should frequently make difficult decisions.

Avoid mechanics with obvious optimal choices.

Whenever possible, present tradeoffs instead of upgrades.

Examples:

Good:

- Send more guards on the expedition but weaken prison security.
- Spend money on food or on better equipment.
- Defend one Department while another remains vulnerable.

Less desirable:

- Strictly better weapons with no downside.
- Mechanics that always have a correct answer.

---

# World Philosophy

The world should feel alive.

NPCs should react to events.

Departments should visibly change over time.

Prison wings should reflect the prisoners they contain.

The player should feel the consequences of previous decisions.

---

# Tone

Maintain the atmosphere inspired by Hollow Knight.

Preferred qualities:

- mysterious
- melancholy
- ancient
- quiet
- understated
- hopeful despite hardship

Avoid:

- modern humor
- excessive exposition
- cartoonish dialogue
- excessive text
- obvious villains

---

# The Player

The player is the Warden.

The Warden is competent.

The Warden is not a chosen hero.

The Warden succeeds through planning, leadership and responsibility rather than destiny.

---

# The Brood Mother

The Brood Mother is the foundation of the Slab.

She should never be treated as a simple resource generator.

Mechanically she produces the workforce.

Narratively she is the heart of the prison.

Her wellbeing should matter emotionally as well as strategically.

---

# Prisoners

Prisoners are not loot.

Each prisoner is:

- an individual
- valuable
- dangerous
- worth preserving

Avoid mechanics that encourage indiscriminate killing.

---

# Factions

Each major faction is paired with exactly one Citadel Department.

Each Department requests three significant prisoners from its corresponding faction.

As captures progress:

- retaliation increases
- attacks become more organized
- the final preservation is the climax of that faction's storyline

---

# Departments

Departments are institutions, not menus.

Every Department has:

- one Curator
- one area inside the Citadel
- one research specialty
- one associated faction
- one Memorium preservation facility

Departments should feel like physical places populated by real people.

---

# Curators

Curators are scholars and leaders.

They are not frontline combatants.

If a Curator dies:

- the Department permanently closes
- contracts are permanently lost
- research permanently stops

This consequence should never be reversible unless explicitly designed later.

---

# Code Philosophy

Prefer:

- readable code
- modular systems
- composition over inheritance where practical
- data-driven content
- clear interfaces
- deterministic gameplay

Avoid:

- duplicated logic
- hidden game state
- tightly coupled systems
- magic numbers
- hard-coded faction behavior

---

# Data-Driven Design

Where practical, define game content through data rather than code.

Examples include:

- factions
- prisoners
- departments
- contracts
- officers
- enemy statistics
- prison wings
- upgrades

Adding a new faction should primarily involve creating new data rather than modifying core systems.

---

# Documentation

Whenever a significant gameplay system changes:

- update the relevant design document
- keep documentation synchronized with implementation
- avoid undocumented mechanics

---

# Decision Making

If requirements are ambiguous:

Do not invent major gameplay mechanics.

Instead:

1. Implement only what is clearly specified.
2. Leave extension points where appropriate.
3. Add TODO comments for unresolved design questions.
4. Ask the designers for clarification.

---

# Long-Term Goal

The objective is not simply to create a functional game.

The objective is to build a cohesive world whose systems naturally reinforce one another.

Every mechanic should strengthen the fantasy of being the Warden of the Slab, protecting both the prison and the Citadel while preserving the history of Pharloom.
```