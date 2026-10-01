# Original Gravity — Design Reference Notes

Source: official Gravity manual (full text, via Lemon Amiga / gamesdatabase.org mirrors) — now the primary source for this file — plus the Atarimania listing and ST Format review (March 1990, 93%) for anything the manual doesn't cover. Facts and paraphrase only; no manual or article text reproduced verbatim.

## Core mechanic (confirms Issues #2–4)
- Officially called the **Collapsar Jump**: a ship falls into a black hole and continues in a straight line at zero elapsed time until it reaches another black hole, re-emerging with the same velocity it entered with. Matches the ship-time/calendar-time split exactly.
- Bonus mechanic: the ship's computer can calculate which black hole a craft originated from when it emerges from a jump — a way to trace Outie ships back to their home system. Worth keeping in mind for Fleet & Conflict/Endgame (a detection/tracking system, not just travel).
- **Decision for this remake:** follow the original routing rule. Jump destination is set by the ship's heading on entry (nearest black hole within a bearing cone in the galaxy's horizontal plane), not chosen on the Holo Tank. No black hole in the cone means no jump. Calendar time advance scales with jump distance; ship time is unchanged.

## Setting, objective & loss condition
- Manual's own framing settles the earlier Outies debate: they're an unexplained, unknown-origin threat that simply appeared wanting energy, favouring "charged" black holes — not human colonisers as the ST Format preview had suggested. Treat the manual as the authoritative version; the coloniser framing was likely just ST Format's own preview-era simplification.
- Objective: eradicate the Outie fleet, or die trying. The only permanent way to remove them is to turn their home system's black hole back into a sun and destroy their base — ideally before they do the same to your home sun.
- Game over: all your forces lost to the Outies, OR your home sun turned into a black hole and home base destroyed.
- Outie behaviour pattern on entering a new system: they build a deep-space platform first, then work on turning the system's sun into a black hole — a process taking over a year. Gives the player a real window to intervene. This "platform" is likely what has the multi-stage destruction sequence noted below under Outies — visuals & damage.
- Outie tech is behind humanity's — they never get access to the Gravitic Warper drive, for instance, and take longer to re-engineer systems than the player does.

## Environment & scale
- Setting: one spiral arm of the Milky Way, 128 randomly-generated solar systems drawn from 65,536 possible permutations. (Note: this is a different, larger number than the "27 sectors" figure from an earlier StarCom order screen — likely two different scopes, sectors vs. full systems, not a contradiction to force-resolve.)
- Mission start date: 1 January 2321.

## Solar systems
- Original game (recalled): each system has multiple planets orbiting a central star, and the Grid visibly deforms as that orbit animates — not just static gravity wells. Most systems have a black hole, situated outside the main system but still attached to it; a minority don't (see Form Hole/Route Construction above).
- **Decision for this remake:** each system caps at up to 4 planets plus 1 star, no moons, alongside the system's black hole. Current build status: Issue #1 (merged) is pure flat 2D, not isometric yet, with a single gravity source — this cap is for when systems with multiple bodies actually get built.

## Fleet & ships
- **Resolved:** 16 scoutcraft total — the United Nations Scout Ship *Hawking* under direct control from the start, plus 15 others. Reconciles the earlier "8 vs 15" conflict: ST Format's preview-era "8" was simply off; the fan review's "15" was counting the others separately from Hawking.
- "UNSS" (seen on screenshots) = United Nations Scout Ship — resolves that naming question too.
- Full roster, all named after scientists, mathematicians, and explorers: Bell, Columbus, Einstein, Euclid, Hawking, Gagarin, Herschel, Lovelace, Magellan, Minkowski, Newton, Podolsky, Riemann, Rosen, Sally Ride, Tereshkova. (Podolsky + Rosen + Einstein together is a nice touch — the EPR paradox trio.)
- Ship dimensions: 1800m long, 500m tall, 100m wide — useful for relative scale against planets/black holes later.
- **Flagship — revised, not just refined:** the manual describes this as a deliberate player action, not an automatic on-death transfer. In the Holo Tank, selecting a fleet and clicking its "Flagship" icon transfers direct control to that scoutcraft, making it the new flagship. That's different from "started as Hawking, auto-transferred on death" as recalled — though the earlier review's "if your current ship is destroyed, you're moved to another" may still be a separate, real safety-net behaviour on top of this manual reassignment option. Worth keeping both in mind as possibly-coexisting mechanics rather than picking one.

## Shared "slot" design pattern
Drives, weapons, defences, and tools all use the same underlying mechanic: several slots, the top one active, contents shuffle down automatically when the active item is exhausted or damaged. Worth implementing as one generic slot-system component rather than four separate ad hoc ones — Drives (3 slots), Weapons (4 slots), Defences (4 slots), Tools (3 tubes).

## Drives
- 3 drive slots. Initial loadout: slot 1 = Ion Drive, slot 2 = Orion System, slot 3 = empty — matches the earlier Ion-primary/Orion-backup recollection closely.
- Other drive types (unlocked via colony tech level, see Tech levels): Lightsail (solar-wind pressure on a reflective sail, no internal power needed), Bussard Ramjet (common, low-quality), Gravitic Warper (advanced-tech only, and something Outies never get).
- Collapsar Jump itself counts as the long-range "drive" for black-hole travel.

## Weapons
- 4 weapon slots, same shuffle-down rule as drives. 8 spare missiles supplied standard. Initial loadout: slot 1 = Nova Gun, slots 2–4 = missiles.
- Energy weapons (3 types): Lasers (weakest, close-range), Nova Gun (starts like a laser, then the beam collapses into a small black hole that immediately evaporates in a burst of energy), Meson Cannon (ignores shields and matter entirely).
- **Missiles are fully configurable across four independent categories** — this resolves the "Shafter/Homing/Contact/Cont Thrust" screenshot mystery completely; those were one option from each category, not a single control scheme:
  - **Warhead:** Fusion Bomb (standard) or Shafter (tidal forces from an intense gravity well tear the target apart)
  - **Drive:** Short Burn (limited thrust) or Constant Acceleration
  - **Guidance:** Free Flight or Homing
  - **Detonator:** Contact or Timed
  - Not every combination is compatible — some options grey out depending on what else is selected.

## Defences & drones
- 4 defence slots, same shuffle rule. **Starting loadout is all 4 slots = Drone** — fully confirms the "up to four" drone recollection as exactly correct, not just a guess.
- Each drone: Ion drive, Laser weapon.
- Drones are programmed via **COL (Combat-Oriented-Language)**, an icon-driven system — confirms the earlier "PROGRAM grid = drone interface" reinterpretation as fact.
- 14 COL command icons exist, including Orbit, If, Fire, Hold, Approach, Lock, Flee, Mode, Do/EndDo/Exit (looping), Nop, Goto, Land — matches the icon set already logged from screenshots almost exactly.
- Up to 4 drone programs can be stored at once, but only one runs per drone at a time.
- **4 standard drone programs ship as default: FlyFree, Interdict, Local, and KamiKaze.** This corrects an earlier misreading of the screenshot storage panel as "SaveNone/FlyFree/Interdict/Loral" — it's actually these four named programs, not that list.
- Black Globe Generator: an advanced defence (see Tech levels) that absorbs all incoming energy but disables the ship's movement, weapons, and comms while active — a real risk/reward tradeoff, not a free shield.

## Tools
Fully resolved now — all four types Rob recalled are confirmed by name, count, and function:
- **Colony module ×4** — deploy near a suitable planet to found a colony
- **Cygnus ×1** — forms a black hole ("Collapsar") from any sun or gas giant
- **RED (Remote Engineering Device) ×6** — evaporates a black hole back into a sun; programmable, and the main tool for actually removing the Outie threat permanently
- **Genesis ×1** — terraforms a rocky planet; the only tool that can create a planet outright, hence only one supplied
- Confirmed: 3 launch tubes, drag-and-drop loadout, one tool active per tube, same shuffle-on-use/damage rule as drives/weapons/defences.
- Extra tools/equipment only purchasable at colonies; money is earned only through combat damage — a flat amount per hit, whether given or taken. A colony "store" screenshot confirms the shape of this directly: separate purchase lists for Weapons, Drives, Tools, and Defence, plus a Credits total and a per-item Cost box — a shop UI, not just an abstract rule.
- Every screenshot shows the same 8-icon bar along the bottom of the main screen — almost certainly the mouse-clickable equivalent of the F1–F9 module keys (Drives, Defences, Grid, Damage Control, Weapons, Holo Tank, Radar, Tools), always present regardless of which window is open.

## Colonising & planetary composition
A genuinely unifying mechanic sits behind terraforming, colonisation, and black-hole creation/removal: three adjustable properties of any stellar or planetary body, each costing energy to change —
- **Diameter** — cost scales with how much you're changing it
- **Biosphere** — flat, small cost per change
- **Composition**, on a ladder: Hydrogen (suns/gas giants) ↔ Rocky (Earth-like/asteroids) ↔ Neutronium (neutron stars) ↔ Singularity (black holes) — cost rises sharply at each step up or down the ladder, cheapest near the Hydrogen/Rocky end, most expensive at the Neutronium/Singularity end
- Genesis and Cygnus bypass these costs entirely for their specific jobs (make a planet / make a black hole); RED tools instead work within a limited energy budget per use, so bigger changes may need more than one.
- Worth treating terraforming, colonisation, and black-hole formation/removal as one system with different presets, not three separate systems, when this gets built.

## Tech levels
- Refined, not quite as recalled: a colony's tech level isn't a direct function of Terran-planet count — more Terran planets in a sector make tech level advance *faster*, but it still develops independently over time. It can also go backwards: successful Outie attacks reduce a colony's tech level.
- No hard cap of 16 confirmed by what's been found — the manual's own unlock table only goes up to T10, so the "capped at 16" recollection isn't yet supported or contradicted, just unconfirmed.
- Condensed unlock progression (T3 baseline → T10):
  - **T3:** baseline — Drones only, no other unlocks
  - **T4:** Orion Drive, Lasers, missile Drive+Guidance options, Colony tool
  - **T5:** + Bussard Ramjet, Nova Gun, missile Detonator options
  - **T6:** + Lightsail, Meson Cannon, missile Warhead options
  - **T7:** + Ion Drive (as a colony-purchasable option), Cygnus tool
  - **T8:** + Gravitic Warper, Genesis tool
  - **T9:** no new unlocks (a plateau level)
  - **T10:** + Black Globe defence
- Saving the game is itself gated by colony tech: only possible at a colony of tech level 4 or higher.

## The Grid
- Official name for the main viewport, representing Einstein-Minkowski four-space. **F3 toggles between a wireframe view and a solid/filled contour view** of the same data — two rendering modes, not just one look.
- Height still encodes gravity strength, as previously noted ("pits" terminology stands).
- Colour legend for the space surrounding each body type (distinct from the Holo Tank's own colour system below): green sun → green space, red sun → red space, Terran planet → cyan space, rocky planet → brown space, blue star → dark-blue space, gas giant → magenta space. A screenshot of a red sun confirms this directly — the surrounding grid renders in a deep red/maroon.
- Flying through a gas giant refuels the ship — matches the fuel-tank mechanic (refuel at a colony or by skimming a gas giant).
- One screenshot shows a small cube containing a visible starfield, floating above the grid on its own dais — a plausible (not confirmed) way black holes/singularities are rendered on the Grid itself: a compact "window" into another region of space, distinct from how suns and planets render as full sprites sitting on the mesh.

## The Holo Tank (the Cube)
- Controls: Roll, Magnify, Yaw, Pitch, Close via edge boxes; most functions have two directions toggled by colour (blue/orange).
- **System colour coding (separate legend from the Grid above):** green = Terran-occupied, red = Outie-occupied, amber/yellow = unknown or unoccupied (a screenshot's "STATUS: Amber" confirms amber and yellow are the same thing, just worded differently across sources). A cyan blip in a star's corner marks a black hole present in that system — resolves the earlier "blue tick" note; it's cyan, and specifically a blip on the star icon rather than a separate tick mark.
- Cyan marker = your home system; a flashing marker = the Outie home base, once discovered.
- A 3-colour marker system (red/green/amber) is used to select stars for orders, cycling priority as more are selected.
- **System Data card**, called up per system: name (real star names/catalogue designations, e.g. "Spica/Beta Bootes"), stellar type (real spectral classification, e.g. F-5), planet count, distance from StarCom in light years, status colour (as above), and an Intelligence Report giving a last-probed date plus a short activity summary. That last field is the concrete implementation of the communication-latency mechanic already noted — the report's staleness is an actual displayed date, not just an abstract "could be outdated."
- Flagship reassignment happens here — see Fleet & ships above.

## StarCom, missions & orders
- StarCom activity (the automation dial) defaults to 50%, adjustable 0–99%. Higher = more computer-issued orders; lower = more player control; the player can always override regardless of the setting. Matches the earlier automation note, now with real numbers.
- StarCom is your home base — lose it, lose the game.
- **Five official mission types, now complete:** Exploration, Terraforming, Military Action, Colony Protection, and **Route Construction** — the missing fifth type from the ST Format scan. Route Construction is the mission-level framing of the same thing the Holo Tank's "Form Hole" order does at the tactical level, which is itself carried out using the Cygnus tool — three layers (mission → order → tool) of one mechanic.
- Holo Tank order types under a basic Move command: **Colonise**, **Form Hole** (travel at sub-light speed — genuinely slow, years of real-time — then create a black hole; ties directly to Cygnus), **Terraform** (ties to Genesis), **Skirmish** (attack Outies at a location; ships retreat automatically if facing destruction), **Conquer** (like Skirmish, but ships push to fully clear the system or die trying, no retreat), **Convoy** (move colonists from one selected star to another — requires two stars selected, and results in a *better* tech-level outcome for the resulting colony than a plain Move: Colonise).
- Probe/Explore/Move (from an earlier StarCom order screen) still stand as a separate, more basic command layer — send a probe or scoutcraft, or relocate one — distinct from the fuller Holo Tank order list above.

## Communication
- All communication is speed-of-light limited. Small "jump sond" craft perform their own Collapsar jumps to relay messages between systems. Practical effect: **the Holo Tank's displayed information can be out of date** — missions that look safe when planned may not be by the time you arrive. Worth building as a real fog-of-war/latency mechanic, not just flavour text.

## Controls — fully resolved, and a good memory
Confirms almost everything recalled, near-exactly:
- **Both mouse and keyboard are real, simultaneous options** (a Help-key toggle switches which one drives the ship), not an either/or — resolves the Atarimania "Mouse"-only metadata as simply incomplete, as suspected.
- Default (re-definable) keyboard scheme:
  - Right Shift: thrust — matches "Shift: thrust" recalled
  - Caps Lock: reverse/down in the manual — resolved as a non-issue for this build: with no drag, the standard fix is rotate 180° and thrust, consistent with the pure-Newtonian physics already decided in Issue #1. Not planned as a separate reverse-thrust key.
  - Z: rotate left — exact match
  - X: rotate right — exact match
  - Space Bar: weapon slot one (primary) — exact match
  - M: weapon slot two (secondary) — exact match
  - D: activate defence, R: recall drones, T: activate tool, S: swap drive, P: pause — none of these previously recalled, all new
  - **F1–F9 each open a specific window** (Drive, Defence, Grid/wireframe toggle, Damage, Weapons, Holo Tank, Radar toggle, Tools, Computer) — confirms the "function keys open specific aspects" recollection exactly.
- Controls are rebindable in-game via an Options menu.
- Given how well this matches, Issue #1's placeholder `ui_left/ui_right/ui_up` bindings are worth replacing with this exact scheme (Z/X/Shift/Space/M) rather than inventing anything new.

## Radar
- Long-range: colour-coded by body type — grey = sun, green = planet, blue = black hole. (Distinct again from both the Grid's and Holo Tank's colour systems — three separate colour legends across the game, worth keeping straight.)
- Short-range: used mainly for combat, showing the immediate local area only.

## Outies — visuals & damage
- Recalled: Outie ships used a single static sprite each (no rotation frames like the player ship) — likely a memory-saving choice on original hardware.
- The Outie ship had 4 recalled tech-level visual stages, stepped down in descending order as it takes damage before final destruction — likely tied to the "deep space platform" the Outies build first in a system (see Setting above), rather than their combat ships specifically. Worth confirming which one this applies to once Fleet & Conflict is actually scoped.

## Further references
- Full manual text now captured into this file section by section above. Anything not yet reflected here (e.g. finer detail on the ship-board computer's Comms/Options screens) can be pulled from the same source if a specific mechanic needs nailing down further.
- Two gameplay video links, not yet reviewed (video content isn't something these notes can process directly):
  - https://youtu.be/0CusU22tSg8
  - https://youtu.be/2U562sCUnBk
