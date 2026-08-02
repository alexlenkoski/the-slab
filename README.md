# The Warden of the Slab

A strategy-action game set after the events of Hollow Knight: Silksong.

The player assumes the role of the Warden of the Slab, the greatest prison in Pharloom. Rather than destroying dangerous creatures, the Warden captures them, imprisons them, and ultimately delivers them to the Citadel where they are preserved forever within the Memorium.

The game combines:

- Action exploration
- Tactical combat
- Prison management
- Resource management
- Base defense
- Strategic decision making

The central theme of the game is preservation.

The player is not trying to save Pharloom through conquest. They are trying to preserve its greatest beings before they disappear forever.

This repository contains both the game code and the living design documentation.

## Play the vertical-slice prototype

The repository includes a dependency-free Godot 4 desktop prototype. Open
`project.godot` in Godot 4.3 or newer and run the project.

The prototype is a short proof of the central loop: accept a contract, lead a
squad into the Hushed Galleries, weaken and restrain a living target, return it
to the Slab, prepare its containment, survive the consequences of the capture,
and send the prisoner to preservation.

### Controls

| Action | Keyboard | Controller |
| --- | --- | --- |
| Move | A/D or arrows | Left stick |
| Jump | Space | A / Cross |
| Attack | J | X / Square |
| Spit | K | Y / Triangle |
| Interact / capture | E | B / Circle |
| Select squad order | 1–6 | Left shoulder cycles |
| Cycle squad order | Q | Left shoulder |
| Pause | Escape | Start / Options |

Squad orders are Follow, Hold, Attack, Defend, Restrain, and Retreat. A
contract target becomes vulnerable to restraint at low health. Issue Restrain,
bring at least two living squad members to the target, then hold Interact while
standing close.

The Warden's punch is a short forward strike. Spit travels in a fixed arc: a
direct hit stuns an enemy, while a miss leaves a puddle that builds stun over
time. The needle guard attacks after receiving the Attack order and can strike
multiple overlapping enemies with one swing. The Acid Spitter seeks ranged
distance under the Attack order, holds position under Defend, and applies an
extendable damage-over-time effect with its fixed-arc shot. The Tiny Brood
Mother carries nine single-use Fresh Flies, with up to three circling above her.
Flies mature in the swarm for five seconds and launch in arrival order, no more
than once every five seconds under Attack. A replacement joins the swarm three
seconds after a vacancy opens. If the Tiny Brood Mother is struck, every fly in
her current swarm retaliates immediately. Their explosions damage groups
without pushing capturable enemies below their capture threshold, and unspent
flies return when their target is ready to restrain.

All visuals are original placeholders. The Warden and guards use
repository-owned PNG artwork; remaining visuals are drawn by the game code. The
prototype requires no external fonts, audio, or third-party add-ons.

### Prototype boundaries

This slice intentionally omits messenger gameplay, concurrent off-screen Slab
simulation, and Citadel defense. Preservation is represented by the concluding
handoff. Broader campaign content, construction, surveillance, recruitment,
and research trees remain future systems.
