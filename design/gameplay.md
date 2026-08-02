# Core Gameplay Loop

1. Receive contracts from a Citadel Department.
2. Recruit expedition members.
3. Feed the Brood Mother to grow the workforce.
4. Organize an expedition.
5. Personally lead the expedition into Pharloom.
6. Locate and capture the target.
7. Return the prisoner to the Slab.
8. Defend the prison while preparing transport.
9. Escort the prisoner to the Citadel.
10. Defend the appropriate Department during the faction's retaliation.
11. Preserve the prisoner within the Memorium.
12. Receive payment and research rewards.
13. Expand both the Slab and future expeditions.

---

# Expedition Phase

The player directly controls the Warden.

The primary objective is to locate and capture one designated contract target.
The expedition may also pursue optional prisoners.

Every expedition corresponds to one Citadel contract.

---

# Prison Phase

While expeditions occur, the Slab must continue functioning.

The player manages:

- Guards
- Prison wings
- Workforce
- Prison security
- Food
- Brood Mother
- Prison expansion

---

# Escort Phase

Captured prisoners cannot be preserved immediately.

They must first be transported safely to the Citadel.

The prisoner remains alive throughout transport.

---

# Citadel Defense

Each Department specializes in studying one faction.

When prisoners are transported, that faction launches attacks against its corresponding Department.

The objective of these attacks is to destroy the Department and kill its Curator before preservation can be completed.

The player must protect:

- the convoy
- the Department
- the Curator

Successful preservation permanently removes that prisoner from the world.

# Player Control

The game uses a 2D side-view perspective.

The player directly controls the Warden through fast action-platforming combat.
Movement, combat and visual presentation should feel close to Hollow Knight:
Silksong.
The Warden commands expedition members as a squad rather than controlling each
member individually.

The core squad commands are:

- Follow
- Hold position
- Attack
- Defend the Warden
- Restrain the target
- Retreat

Squad members interpret commands according to their roles, abilities and current
situation.

## Warden Combat

The Warden is a defensive battlefield controller with access to biological
abilities and containment tools. The Warden's attacks should help control space,
protect the squad and create opportunities for capture.

For the first prototype, the Warden has a single uniform punch. The punch is
visibly directed forward and briefly stops the Warden's movement. It causes a
small amount of knockback, with smaller enemies pushed farther than larger
enemies. Its initial recovery time is 0.5 seconds and should be fine-tuned
through playtesting.

The Warden can punch while airborne. Doing so commits the Warden to falling
toward the ground rather than allowing them to remain airborne.

### Spit Attack

The Warden's spit attack is a biological ability. The Warden briefly stops and
spits along a fixed forward arc. If the spit lands on the ground, it creates a
puddle. Enemies standing in the puddle build toward a stunned state. Larger
enemies must remain in the puddle longer before being stunned. This buildup
gradually decreases after an enemy leaves the puddle.

Overlapping puddles do not increase the rate of stun buildup. If the spit
strikes an enemy directly before landing, the spit is consumed and immediately
stuns that enemy for three seconds instead of creating a puddle.

After either outcome, the spit attack has a 10-second cooldown.

## Guard Combat

Guards do not leave their current position to initiate an attack unless they
have received the Attack command. A guard struck by an enemy may retaliate
against that enemy until the enemy is dead or captured. More detailed guard
engagement and command behavior remains to be designed.

The prototype includes two distinct guard types with separate combat roles.

### Needle Guard

The Needle Guard is a melee guard that uses a swinging needle attack. The swing
normally targets one enemy, but damages every enemy overlapping its attack
area. It deals damage without applying knockback.

### Acid Spitter

The Acid Spitter is a ranged guard whose biological spit has been trained with
acid. Its spit travels in a fixed arc and only affects an enemy on direct
impact. A missed shot disappears when it hits the ground and does not create a
puddle.

A hit deals a small amount of immediate damage, followed by low damage over
time for one second. Further hits extend the remaining duration of this effect,
up to a maximum of eight seconds, but do not increase its damage per tick.

When given the Attack command, an Acid Spitter moves until it reaches an
effective spitting distance from its target. It falls back if the target gets
too close. When given the Defend command, it remains at its assigned position
and fires at enemies that enter spitting range.

### Tiny Brood Mother

The Tiny Brood Mother is an explosive guard unit that follows the Warden as a
normal member of the squad. She begins each expedition with a brood of nine
Fresh Flies. This brood cannot be replenished during the expedition.

When the Tiny Brood Mother receives the Attack command, she launches one Fresh
Fly toward the commanded enemy. While that order remains active, she launches
another fly after a three-second delay whenever a field slot is available. No
more than three Fresh Flies may be active at once. Each fly is consumed when it
reaches its target and explodes.

If the Tiny Brood Mother is attacked, she retaliates by immediately launching
up to three available Fresh Flies at the attacker, subject to the same limit of
three active flies.

A Fresh Fly explosion damages every enemy within its area. Its damage is
nonlethal to capturable enemies and cannot reduce them below their capture
threshold. Once a targeted enemy reaches that threshold, the Tiny Brood Mother
stops launching flies at it. Fresh Flies already pursuing that enemy return to
the Tiny Brood Mother and rejoin her remaining brood instead of exploding.

# Living World During Expeditions

The Slab continues operating while the Warden is away. Threats and prison events
develop concurrently with the expedition.

A messenger accompanies the Warden and reports significant events at the Slab.
During exploration or light danger, a messenger report slows time. During a
large battle, it pauses the game completely.

The player may:

- Continue the expedition.
- Withdraw to the Slab.
- Dismiss the report and accept the developing consequences.

Withdrawing advances the contract deadline. Injured squad members must recover
before they can be assigned again.

# Capture

Important targets cannot be killed accidentally.

After a target has been sufficiently weakened, a capture icon appears. The
Warden may then issue the Restrain command. Available squad members attempt to
pin the target while the Warden performs a short, interruptible capture action.
Poor timing or positioning may allow the target to escape the attempt.

Further attacks against a capturable target may incapacitate it or make
transport more difficult, but do not kill it.

# Expedition Camps

Each expedition establishes a temporary camp. Captured prisoners must be carried
back to this camp before they can be transported to the Slab.

An expedition has one primary contracted target and may also capture optional
prisoners encountered in the region.

The player assigns squad members to transport a prisoner from camp to the Slab.
This allows the Warden to continue the expedition, but leaves fewer people in
the field. Transport squads may be attacked, with rescue forces focusing their
efforts on the primary contracted target.

When transporting the primary target, the player may instead end the expedition
and accompany the transport personally.

If a primary target escapes during transport:

- The contract remains active and its deadline continues.
- The target returns to the region with stronger protection or in a new
  location.
- Surviving transport members return injured and require recovery.

# Optional Prisoners

Optional prisoners provide additional payment and reduce the strength of their
faction's subsequent attacks.

They remain in the Slab unless a secondary contract specifically requests them.
They consume cells, food and security while imprisoned.

Optional prisoners may be treated with the aim of reconciliation. After time
and appropriate treatment, an individual may voluntarily join the Slab. The
player chooses the recruit's role, including:

- Guard
- Prison staff
- Expedition member
- Scout
- Messenger
- Specialist, where appropriate

Recruitment is likely rather than automatic. Prisoners remain individuals whose
behavior can be affected by their treatment and conditions.

# The Slab

The Slab is a physical, side-view location through which the player directly
controls the Warden.

The player visits prison wings, the Brood Mother, staff and command stations.
Focused interfaces at appropriate stations support workforce assignments,
construction and other management tasks without turning the Slab into a
disembodied menu.

# Warden's Office and Surveillance

The Warden may visit the Warden's office to monitor specific rooms through the
Slab's camera system.

The Slab begins with two camera-equipped prison cells intended for optional
prisoners. Cameras for additional cells and important rooms must be purchased
individually.

Purchasing a camera does not install it immediately. The player must assign a
building team to carry the equipment to the selected room and complete the
installation. Until the work is finished, the room has no camera coverage.
Blocked routes, unrest or danger along the way can delay the team and therefore
delay access to surveillance.

From the office, the Warden can use installed cameras to observe covered rooms
in real time and prepare orders for guards or staff.

Basic cameras do not generate alerts. The player must visit the office and
inspect camera feeds manually to discover incidents in monitored rooms. A later
surveillance upgrade enables automatic alerts.

Automatic detection reaches the Warden's office immediately, but does not notify
the Warden globally. If the Warden is elsewhere, a messenger must carry the
alert. During an expedition, the expedition messenger delivers it through the
same reporting system used for other Slab emergencies.

The Warden cannot view camera feeds remotely. After receiving an alert, the
Warden may send a messenger to investigate the affected room and report what
happened rather than returning to the office personally. The report is delayed
by the messenger's physical journey and may be outdated by the time it arrives.

Cameras can be damaged and disabled by prisoners or attackers. A building team
must be assigned to reach and repair a disabled camera. Repairs cost no money,
and the repaired camera retains all of its installed upgrades; the cost is the
team's time and the risk of entering the affected room.

Remote orders require messengers. The player must purchase or recruit messengers
and assign an available messenger to deliver each order. Messengers physically
travel through the prison, so distance, locked or damaged routes, riots and
escaped prisoners can delay or prevent delivery. An order is not acted upon
until its messenger reaches the intended recipient.

Orders available from the Warden's office include:

- Dispatch guards to a room.
- Evacuate staff.
- Lock or unlock doors.
- Send a building team.
- Move a prisoner.
- Summon staff or messengers.
- Sound a local alarm.
- Declare High Alert.

High Alert is a prison-wide emergency state. While it is active:

- Nonessential doors lock.
- Staff move toward safe rooms.
- Guards abandon routine duties and respond to threats.
- Messengers prioritize emergency orders.
- Construction and ordinary work stop.

Maintaining High Alert causes guard fatigue, delays work and increases prisoner
tension. It is therefore an emergency measure rather than a safe default.

Once declared at the Warden's office, High Alert activates immediately through a
central mechanical alarm. Detailed follow-up instructions still require
messengers to reach the appropriate guards or staff.

If the Warden is away from the office, the Warden may send a messenger with
authority to declare High Alert. Activation is delayed until that messenger
physically reaches the office.

Serious incidents may still require the Warden to leave the office and intervene
personally.

# First Vertical Slice

The first playable prototype validates one short end-to-end contract using one
Department, one faction and one significant target. It includes direct Warden
control, two distinct guard types in the AI squad, all six squad orders,
nonlethal capture, an optional prisoner, return transport, a physical Slab,
basic preparation and a containment emergency.

During ordinary travel, the two squad members maintain readable spacing behind
the Warden. Once the primary target is bound, the squad forms around the
prisoner, with one member ahead and one behind, and escorts them back to camp.
The prisoner's pace is limited by the forward escort so that the formation
cannot leave the prisoner walking unguarded at its front.

The emergency tests the central tradeoff directly. Guards assigned to the
prisoner's cell protect containment but are unavailable to fight attackers.
Capturing an optional faction prisoner reduces the attacking force, while also
demonstrating the long-term value and burden of additional captures.

If the cell loses all integrity during the emergency, its bars visibly break
and the significant prisoner escapes alive through the breach. The slice ends
without payment or preservation. How an escaped Slab prisoner re-enters the
full campaign remains an unresolved campaign-scale rule.

Messenger delivery, concurrent off-screen Slab simulation and playable Citadel
defense are deliberately deferred. The slice ends with a simplified handoff to
the Memorium and reports payment, research and retaliation progress. These are
prototype boundaries rather than changes to the intended full game loop.
