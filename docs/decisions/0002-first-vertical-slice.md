# First Vertical Slice

Status: Accepted

Date: 2026-07-31

## Context

The complete campaign design contains several mutually dependent locations and
management systems. A small playable slice is needed to test whether action,
squad command, living capture and prison pressure form one coherent loop before
the wider campaign is built.

## Decision

The first slice is a Godot 4 desktop prototype using original placeholder
visuals and both keyboard and controller input.

It follows one contract from briefing through expedition, nonlethal capture,
return to the Slab, containment preparation, a prison emergency and a simplified
Memorium handoff. It contains one Department, one faction, one required target,
one optional prisoner and a two-member squad. Prototype content is stored as
data rather than embedded faction-specific rules.

The two squad members keep wider spacing during travel. After the significant
target is captured, they take positions on either side of the prisoner for the
return to camp rather than allowing the prisoner to trail the Warden directly.
The prisoner slows when necessary and cannot advance beyond the forward guard.

Messenger gameplay, playable Citadel defense and full concurrent Slab
simulation are outside this slice. Their absence is not a change to the full
game design.

## Consequences

- The slice can test the game's distinctive capture-and-consequence loop in a
  short session.
- Guard allocation creates an immediate tradeoff between cell integrity and
  available defenders.
- Losing all cell integrity visibly releases Vey, who flees alive through the
  breached east hall and ends the slice without preservation or payment.
- Optional capture visibly weakens retaliation without making capture free.
- The self-contained placeholder presentation uses repository-owned assets and
  has no third-party runtime dependencies.
- Campaign-scale persistence, content variety and remote simulation remain to
  be validated later.

## Unresolved

- How a significant prisoner who escapes from the Slab is relocated and made
  available for recapture in the full campaign.
