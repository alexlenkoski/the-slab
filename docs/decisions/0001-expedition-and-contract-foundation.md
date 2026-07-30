# Expedition and Contract Foundation

Status: Accepted

Date: 2026-07-30

## Context

The original design established a campaign loop spanning expeditions, prison
management, escort and Citadel defense, but did not define the player's
moment-to-moment control or several important contract rules.

## Decision

The game is a 2D side-view action platformer whose movement, combat and aesthetic
target a feel close to Hollow Knight: Silksong. The player directly controls the
Warden and gives high-level commands to AI-controlled squad members.

Expeditions occur while the Slab continues to operate. A messenger reports
important Slab events, slowing time normally and fully pausing during large
battles. The player may continue or withdraw; withdrawal advances the contract
deadline and injured personnel require recovery.

Targets are captured alive by weakening them, commanding the squad to restrain
them and completing an interruptible capture action.

Every expedition establishes a camp and pursues one primary contract while
allowing optional captures. Prisoners are carried to camp and assigned transport
squads. The Warden may personally escort the primary target or remain in the
field at greater risk.

Each Department presents five significant faction targets. The player preserves
three: one mandatory unknown target and two of the other four. The mandatory
target unlocks after the first successful preservation.

Contract expiration lowers Department trust and therefore payment across that
Department. Success may restore trust only to its initial level.

Optional prisoners grant additional payment and reduce later faction attack
strength. They normally remain in the Slab and may, through long-term humane
treatment, voluntarily join the Warden's force in a player-selected role.

The Slab is a physical side-view location. Management interfaces are accessed
through its people and command stations.

The Warden's office contains a room-based camera system. Two optional-prisoner
cells begin with cameras; further cameras must be purchased and installed by an
assigned building team that physically travels to the room. The office can also
issue remote orders, but each order requires a messenger to carry it through the
Slab before guards or staff act on it.

## Consequences

- Squad AI and command interpretation are core technical systems.
- The Slab and expedition must share a concurrent simulation clock.
- Capture, carrying and transport require reusable prisoner state transitions.
- Continuing an expedition after capturing its primary target is a deliberate
  risk-reward decision.
- Department trust is bounded and cannot become a source of unlimited payment
  growth.
- Optional capture must remain costly through personnel, time, food, cells and
  security so that capturing everyone is not an obvious optimal strategy.
- Surveillance expansion consumes both money and building-team time.
- Information and command are separate resources: a camera can reveal an
  incident, but an available messenger and a traversable route are required to
  deliver orders.

## Unresolved

- Exact time scale and simulation rules between the Slab and expedition
- Detailed prisoner treatment and recruitment rules
- Department research rewards
- Prison construction, staffing and security mechanics
- Failure thresholds for catastrophic Slab or Citadel loss
- Exact presentation and mechanical meaning of target injuries during transport
