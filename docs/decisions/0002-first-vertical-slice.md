# First Vertical Slice

Status: Accepted

Date: 2026-07-31

## Context

The complete campaign design contains several mutually dependent locations and
management systems. A small playable slice is needed to test whether action,
squad command, living capture and prison pressure form one coherent loop before
the wider campaign is built.

## Decision

The first slice is a Godot 4 desktop prototype using original geometric
placeholder visuals and both keyboard and controller input.

It follows one contract from briefing through expedition, nonlethal capture,
return to the Slab, containment preparation, a prison emergency and a simplified
Memorium handoff. It contains one Department, one faction, one required target,
one optional prisoner and a three-member squad. Prototype content is stored as
data rather than embedded faction-specific rules.

Messenger gameplay, playable Citadel defense and full concurrent Slab
simulation are outside this slice. Their absence is not a change to the full
game design.

## Consequences

- The slice can test the game's distinctive capture-and-consequence loop in a
  short session.
- Guard allocation creates an immediate tradeoff between cell integrity and
  available defenders.
- Optional capture visibly weakens retaliation without making capture free.
- The code-first placeholder presentation has no external asset dependencies.
- Campaign-scale persistence, content variety and remote simulation remain to
  be validated later.
