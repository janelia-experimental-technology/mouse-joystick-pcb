# Mouse Joystick PCB Plan

Use this file for work that is multi-step, risky, or likely to span multiple
sessions.

## Current Goal

**Rev 0, rescoped 2026-08-13: get the interfaces on a board and send it to
fabrication.** RP2040 with GPIO isolation, one TMC5130A on a 4-pin motor
terminal, one single-ended encoder on a 5-pin terminal read by the driver only,
one debounced limit switch on a 2-pin terminal, a pyControl UART on RJ-45, and a
36 V switched supply input that doubles as a chip-reset button.

Rev 0 also carries **InstrumentPort-40**, moved back in on 2026-08-16 for
firmware development — see Resolved below.

Deferred to rev 1: the 0-5 V analog angle output, the pyControl TTL event lines,
and the PIO encoder cross-check. Their pins are reserved and no Rev 0 pin moves
when they arrive.

**Session-level detail lives in `.agents/handoff.local.md`.** Read it first.

The rig's two-joystick form factor question stays open. This board is the fast
path to a testable system, not a commitment against `../mouse-joysticks-pcb`.

## Context

Source-of-truth sibling repositories:

- `../mouse-joysticks-pcb` — the twin-axis board for the same rig; most of this
  repository's documentation derives from it
- `../orb-weaver-context` — cross-project context and the PCB development plan
- `../board-interfaces` — InstrumentPort-40 and, later, the pyControl connector
  profile
- `../kicad-libs` — symbols, footprints, database libraries, design blocks,
  vendor mappings, KiCad helper tooling
- `../tmc51x0-driver-dev-pcb` — the validated RP2040 + TMC5130A predecessor
- `../mouse-joysticks-mech` — the new-rig mechanical assembly, two joysticks
- `~/Repositories/github/syringe-pump` — pyControl module reference design
- `~/Repositories/kicad/mouse-joystick-pcb` — previous-generation prior art

## Direction History

- **2026-08-10:** `mouse-joystick-pcb` created as one PCB per joystick, RP2040.
- **2026-08-11:** renamed to `mouse-joysticks-pcb` and rescoped to one board for
  both joysticks; Rev 0 descoped back to RP2040 to be buildable now.
- **2026-08-12:** this repository created to carry the single-axis design in
  parallel, because it can be finished sooner. 36 V input instead of 24 V, and
  nothing descoped for pin budget. Both repositories are live.

## Resolved

- **Rev 0 scope, 2026-08-13, amended 2026-08-16.** Interfaces plus the means to
  observe them; DAC, event lines, and the PIO encoder tap deferred to rev 1.
  `docs/rev0-plan.md`.
- **RP2040 GPIO allocation.** Rev 0 connects 17 of 30 and reserves 12 more at
  fixed numbers; full scope is 29 of 30 with `GP27` spare. **No pin moves between
  Rev 0 and rev 1.** `TMC_REF_STIM` was deleted permanently and its pin pays for
  the bus-switch enable on `GP9`. `docs/interface-map.md`.
- **Two power domains, 2026-08-13.** The high-side switch is a reset button:
  everything resettable is on `+36V_SW` → `+5V_SW` → `+3V3_SW`, and the MCU is on
  `+5V_MCU` → `+3V3_MCU` fed from USB `VBUS` or pyControl pin 6 through two ORing
  diodes. The board does not boot on 36 V alone, accepted. Exactly two
  `5v_to_3v3_tps73733` instances, one per domain. `docs/power.md`.
- **GPIO isolation rule.** A GPIO goes through the bus switch if and only if its
  far end is on the switched domain — 8 channels in Rev 0, 16 at full scope. The
  pyControl UART bypasses, so the board stays reachable with the motor rail off.
  The oversized 4-package block is accepted as-is for schedule.
- **pyControl pin 6 is 5 V**, confirmed from the syringe-pump module netlist. Its
  current budget is still unmeasured and is a Gate A item.
- **InstrumentPort-40 is in Rev 0, re-allocated 2026-08-16.** Moved back in for
  firmware development: the port carries both directions of the pyControl serial
  link *tapped at the RJ-45*, the TMC5130A SPI bus, the two firmware triggers, and
  `ENC_A`/`ENC_B` — 10 of 18 digital Strands live at fabrication. The other 8 are
  allocated and unrouted, **4 reserved for the rev 2 brake and torque sensor** so
  those circuits inherit a pinout instead of renegotiating one. The overlay now
  follows the profile's own Preferred Digital Overlays table: TMC bus on the SPI
  slots, pyControl serial on the first UART pair, brake PWM and fault on the
  PWM/fault slots, torque front end on the I2C slots.
  - **`DIG0`/`DIG1` are swap slots.** `ENC_A` and `ENC_B` hold the torque bus's
    two slots through Rev 0 and rev 1, and hand them over at rev 2. They earn the
    space because Rev 0 has no PIO cross-check, so the TMC5130A's `X_ENC` register
    is the only encoder count on the board and nothing can contradict it —
    capturing the raw edges beside the SPI reads of that register is the only
    check that the driver decodes correctly. `DIG0`/`DIG1` were chosen over any
    other pair because they sit in the rev 2 buffer package, which makes the
    eviction as late as possible. `ENC_N` stays on a test pad.
  - **Two new boundary pins are needed on
    `pycontrol_behavior_port_rj45_boundary`** — `PYC_DIO_A_CONN` and
    `PYC_DIO_B_CONN` on the connector side of `R29001`/`R29002`. Topology change,
    must land before the block is placed. Free right now; it has not been placed.
  - `GP24` `~{INSTR_BUF_OE}` is now live, taking Rev 0 to 18 connected GPIOs. No
    pin moved.
  - **Three 100 kΩ pull-downs are the only new passives** — `TMC_SPI_CIPO`,
    `ENC_A`, `ENC_B`. Buffer packages `U_A`, `U_B`, `U_E` are fitted; `U_C` and
    `U_D` are DNP with unrouted inputs. `U_E`'s two brake channels have their
    inputs tied to GND until rev 2.
  - **It costs layout schedule** — a 40-pin FFC, five buffer footprints, and 18
    more routed nets on the board whose layout was already the long pole.
  - `docs/interface-map.md`, `docs/instrument-strategy.md`.
- **Event-line routing.** Three lines on BNC, two dual jacks plus one. Rev 1.
- **The pyControl port pinout**, from the syringe pump. Cited, not bench-verified.
- **Current sense**, inherited: 0.15 Ω, `vsense = 1`, `IRUN = 28`.
- **Supply voltage:** 36 V, using the existing
  `hv_input_36V_terminal_2pos_5p08_protected` block.
- **TVS on `HV_IN`, for the switch and the buck — not for the driver.** A standard
  TVS cannot clamp under the TMC5130A's 49 V on a 36 V rail, but the switch (70 V)
  and the buck (65 V) are the parts exposed at hot-plug, and they are clampable.
  `SMBJ40A` preferred, stocked `SMF48A` usable now. The driver is protected by
  construction — bulk downstream of the soft-start switch, capped at tens of µF,
  tight `VS` loop — and verified at Gate B.
- **The 36 V input block's six edits are applied**, verified by netlist review on
  2026-08-12. `EN` divider, `DIAG_EN`, `LATCH`, `ILIM` = 40 kΩ, `SNS` = 249 Ω, and
  the `~FAULT` route are all in. **Three defects remain**: `~FAULT` is pulled down
  to `GND` instead of up to `+3V3_MCU`, and `HV_IN` and `SNS` are local labels
  rather than hierarchical, so the board can reach neither. Plus two cheap
  concerns — `C27002`'s 50 V rating on a 36 V rail, and the misleading `VAA` net
  name. The `+3V3_MCU` naming concern was **withdrawn**; naming the rail by its
  domain is correct. All in `docs/power.md`; fix before the block's PCB layout is
  finished.
- **Multi-source logic power, superseded 2026-08-13.** Now two sources only —
  USB `VBUS` and pyControl pin 6 — ORed at `+5V_MCU`, upstream of the MCU
  domain's own LDO. The onboard buck is **not** one of them; it lives on the
  switched domain. The two 5 V rails are separate nets, which is what keeps
  `+5V_SW` in spec for the TMC's `VCC`.

## Blocking Items

**Two remain, and only the second can actually invalidate the board.** Ranked.

1. **Joystick motor part number.** Sets the motor connector, supply envelope,
   `ILIM`, and confirms whether 0.67 A is RMS or peak. Owner: Peter. Also settles
   the `tmc5130` block's 200 µF bulk question — see `.agents/handoff.local.md`.
2. **Encoder part.** Sets single-ended versus differential receive, the encoder
   supply voltage and current, and the harness conductor count. Owner: Peter.
3. Board outline and mounting. `../mouse-joysticks-mech` is a two-joystick
   assembly, so how a per-axis board mounts is a decision — but pick a rectangle
   and move on rather than blocking the fab order on it.

**Not blocking, but do not lose:** the schematic is far less connected than
`README.md` states, netclass patterns match none of this board's rail names, and
the `rp2040` block exposes no `RUN`/`SWD`. All in `.agents/handoff.local.md`.

**Resolved 2026-08-13, no longer blocking:**

- DAC8563 `VIH` — deferred with the DAC to rev 1.
- Where `+3V3_MCU` comes from — USB or pyControl only, two diodes, no always-on
  converter on `HV_IN`.
- The TMC's switched `VCC_IO` — it is on `+3V3_SW` from the second LDO, so all
  three TMC supplies fall together and the pin-34 ordering holds by construction.
- `D3`, the pyControl 5 V branch — populated. It is one of only two sources that
  power the board, so it is no longer conditional.
- `EXT_FAULT_IN` on `GP27` — rev 1, since Rev 0 has no `FAULT` output to
  cross-wire.
- The regulator feed point — post-switch, deliberately.

Items 1-2 are shared with `../mouse-joysticks-pcb`. Answer them once and record
the answer in both.

**Reopened and narrowed, 2026-08-12: the 36 V TVS.** It belongs on `HV_IN` to
protect the switch and the buck at hot-plug, not on the motor rail to protect the
driver — nothing can do the latter at 36 V. `SMBJ40A` is the part to order, and
the stocked `SMF48A` works for first boards, so it is **not a fabrication
blocker**. See `docs/power.md`.

## Milestones

1. ~~Scaffold the repository and write the design record.~~ **Done 2026-08-12.**
2. Answer blocking items 1-5.
3. Prove `hv_input_36V_terminal_2pos_5p08_protected` in a scratch project with
   ERC. It has never been placed on any board.
4. Compose the schematic from existing `kicad-libs` blocks, in the order in
   `docs/rev0-plan.md`.
5. ~~Design the two sections Rev 0 needs that do not exist as blocks: the
   pyControl port boundary and the debounced limit input.~~ **Done 2026-08-15
   and 2026-08-16**, both with saved PCB layouts, both still project-local
   pending bench verification. The event BNC group and the DAC output section
   move to rev 1 with the functions they serve.
6. Add `PYC_DIO_A_CONN`/`PYC_DIO_B_CONN` boundary pins to the pyControl block, so
   the InstrumentPort can tap the serial link at the cable. Must land before the
   block is placed.
7. Freeze the GPIO allocation and the instrument overlay against the schematic.
7. Run ERC/DRC, generate fabrication outputs, order.
8. Bench bring-up against Gates B through D. The 36 V transient measurement at
   the TMC5130A `VS` pins is the one that justifies or condemns the supply
   choice.
9. Native pyControl integration against Gate E, adapting
   `pump_controller.py` as the device-class template.
10. Record results in `docs/bringup-log.md`, against the board serial.

## Verification

Ready for active PCB work when:

- the motor and encoder parts are identified;
- ~~the DAC logic-level question is settled~~ **deferred to rev 1**;
- the bulk-capacitance placement and snubber footprint are decided;
- ~~the `+3V3_MCU` source and the switched `VCC_IO` rail are decided~~
  **done 2026-08-13**;
- ~~the Guix pin, Makefile, and KiCad scaffold exist~~ **done**; `make validate-db`
  still to be run once in the managed shell;
- Gate A items in `docs/validation-plan.md` have explicit status.

## Progress Log

- 2026-08-16: **Moved InstrumentPort-40 into Rev 0 and re-allocated all 18 digital
  Strands.** The port is now justified by firmware development rather than by
  experiments — both directions of the pyControl serial link, tapped at the
  RJ-45, plus the TMC5130A SPI bus in one capture. **10 Strands live at
  fabrication, 8 allocated and unrouted, 4 reserved for the rev 2 brake and torque
  sensor** so those circuits inherit a pinout. `ENC_A`/`ENC_B` borrow two of the
  reserved slots — `DIG0`/`DIG1`, in the rev 2 buffer package so the eviction is
  as late as possible — because the driver's `X_ENC` register is the only encoder
  count Rev 0 has and the raw edges are the only way to check it decodes
  correctly. `ENC_N` went to a test pad. The new allocation also follows the v0.3
  profile's own Preferred Digital Overlays table much more closely than the
  superseded one did. Decided the three tap points — connector side for the
  pyControl serial, A side of the bus switch for the TMC, driver side of the
  filter for the encoder — and the three 100 kΩ pull-downs they need, on
  `TMC_SPI_CIPO`, `ENC_A`, and `ENC_B`. Regrouped the five buffer packages so each
  revision populates whole packages and no CMOS input floats: `U_A`/`U_B`/`U_E`
  fitted, `U_C`/`U_D` DNP, `U_E`'s two brake inputs GND-tied until rev 2. `GP24`
  went live, taking Rev 0 to 18 connected GPIOs with no pin moved. Corrected the
  old claim that six slots carried signals Rev 0 does not have — only the three
  DAC wires were genuinely absent. Updated `interface-map`, `design-block-map`,
  `instrument-strategy`, `rev0-plan`, `validation-plan`, `bringup-log`, `README`,
  `.agents/AGENTS.md`, the handoff, and this file. **Not yet done:** the two new
  boundary pins on the pyControl block, and every bit of the schematic and layout
  work itself.
- 2026-08-14: **Built three `kicad-libs` blocks and closed the pin 6 budget
  question.** Added the ORing diode to `usb2` exposing both `VBUS` and
  `+5V_USB`; created `limit_switch_debounced_input` and
  `pycontrol_behavior_port_rj45_boundary`. Traced the pyControl 5 V supply from
  the **host** side in `~/Repositories/github/pycontrol-h7-breakout`: a shared
  **1.0 A** RECOM `R-78E5.0-1.0` feeding all ten ports, the terminal block, and
  the controller's own `AMS1117-3.3`, with no per-port fuse — so blocking item 3
  is answered, and its real consequence is a **new polyfuse requirement** on this
  board's pin 6 branch. Also corrected the pinout: pin 5 is `DIO-C` on eight of
  ten ports and a `POW-C` sink driver on two, not "`SPECIAL`", and pins 3/7 are
  driver outputs, which kills the "use `POW-A`/`POW-B` for event lines"
  fallback. Decided a **hardware 10 kΩ pull-up on `GP1`** rather than relying on
  firmware. Mirrored the pinout findings into `../mouse-joysticks-pcb`.
  **Rev 0 was not finished and not ordered.** A netlist audit found the schematic
  much less connected than `README.md` claims — the `mcu` sheet has no sheet pins
  at root, so there are three separate GND nets, the isolation block is entirely
  unwired, and all 30 GPIOs are unwired. Full state and a ranked action list are
  in `.agents/handoff.local.md`, which did not exist before today despite being
  referenced here and in `.agents/AGENTS.md`.
- 2026-08-13: **Rescoped Rev 0 to the interfaces only** and rewrote the design
  record around it — `interface-map`, `rev0-plan`, `design-block-map`, `README`,
  plus scope banners on the eight docs describing deferred subsystems. Rev 0
  connects 17 of 30 GPIOs and reserves the rest at fixed numbers, so rev 1 adds
  the DAC, the PIO encoder tap, the event lines, and the InstrumentPort without
  moving a pin. Dropped `TMC_REF_STIM` permanently to pay for the bus-switch
  enable on `GP9`. Confirmed the whole Rev 0 connector complement is stocked in
  one 3.5 mm terminal family, and flagged that it is screw, not locking.
- 2026-08-13: **Adopted the two-domain power architecture.** The high-side switch
  is a researcher-facing reset button, so the regulator chain is fed
  *post*-switch and the MCU is fed from USB `VBUS` or pyControl pin 6 through two
  ORing diodes, never from the 36 V chain. Exactly two `5v_to_3v3_tps73733`, one
  per domain. This **reversed the pre-switch guidance** in `power.md` and
  `.agents/AGENTS.md`, and dissolved three open items at once: the `+3V3_MCU`
  source, the switched `VCC_IO`, and whether the TMC tolerates `VCC_IO` without
  `VCC`/`VS`. Confirmed pyControl pin 6 is 5 V from the syringe-pump netlist; its
  current budget stays unmeasured.
- 2026-08-13: **Rewrote the GPIO isolation rule** to follow the far end's power
  domain rather than an ad-hoc list. The pyControl UART now bypasses the bus
  switch, so the board stays reachable with the motor rail off — the earlier
  write-up had it isolated, which defeated the purpose. 8 isolated channels in
  Rev 0, 16 at full scope. Accepted the oversized 4-package block for schedule.
- 2026-08-12: Created the repository. Seeded `.guix/`, `Makefile`, agent shims,
  and an empty KiCad 10 project from `../mouse-joysticks-pcb`, renamed
  throughout. Wrote the design record: `rev0-plan`, `interface-map`, `power`,
  `design-block-map`, `relationship-to-twin-axis-board`, `pycontrol-port-pinout`,
  `pycontrol-interface`, `uart-protocol`, `encoder-analog-output`,
  `instrument-strategy`, `validation-plan`, `bringup-log`, `prior-art`.
- 2026-08-12: Derived the RP2040 allocation — 27 of 30, 3 ADC-capable spares,
  nothing descoped — and the InstrumentPort-40 overlay, which fills all 18
  digital slots. Gave the DAC SPI bus two slots so the analog angle output can be
  verified against the encoder from a single capture.
- 2026-08-12: Added `orb_weaver_smd:Texas_HTSSOP-14-1EP_..._ThermalVias_JLCPCB` to
  `kicad-libs`. The stock footprint's thermal *pad* was already correct; the via
  array was missing, and KiCad's official `_ThermalVias` variant fails this
  project's DRU with 15 `drill_out_of_range` errors (0.2 mm drills vs a 0.3 mm
  `min_through_hole_diameter`). Enlarging only the drill would breach the 0.18 mm
  PTH annular rule, so the local variant uses 0.7 mm pads / 0.3 mm drills
  (0.20 mm annular) with the y-pitch tightened to 1.0 mm to keep the outer pads
  inside the 5 mm pad. DRC-verified clean, and **assigned at source** on
  Peter's instruction: three `db/source/` CSVs plus the symbol default, then
  `make build-db`. Placed instances are copies and still carry the old footprint —
  Update Symbols from Library is needed in the two hv_input blocks, the mining
  example project, and **`tmc51x0-driver-dev-pcb`**, which places the 24 V
  barrel-jack block and will gain thermal vias on its next update. Its
  `fp-lib-table` already carries `orb_weaver_smd`.
- 2026-08-12: **Reversed the `VSA` → `VM` recommendation.** The external 5 V on
  `VSA` exists to bypass the internal linear regulator, which the datasheet
  explicitly sanctions ("a different (lower) supply voltage can be used for VSA")
  and which matters thermally: the regulator can contribute up to 1 W at 46 V, and
  even with `VCC` external it would add a few hundred mW to a package already
  dissipating ~0.45 W of bridge `I²R`. So `VSA` stays on `+5V` and **`+5V` is
  switched with `+36V`**. Cheapest way to get every ordering right: feed
  `hv_to_5v_tpsm365r6` from the **switched `+36V`**, which reverses the earlier
  pre-switch recommendation for that buck. **Consequence to plan for:** the TMC's
  `VCC_IO` cannot sit on the always-on MCU rail, because an always-on `VCC_IO` with
  a switched `VCC` is the order pin 34 forbids — so there are two 3.3 V domains,
  `+3V3_MCU` always on and a switched 3.3 V for `VCC_IO` alone. That makes the
  `+3V3_MCU` name load-bearing rather than merely descriptive. **New open item:**
  where `+3V3_MCU` comes from when only the 36 V supply is connected.
- 2026-08-12: Settled the "do not power the TMC5130A without VM" question against
  rev 1.21, and it lands on a different pin than expected. **`VCC` must come up
  EARLY**, not late — pin 34: "make sure, that VCC comes up before or in parallel to
  5VOUT or VCC_IO, whichever comes up later". So `VCC` alive with `VS` = 0 is the
  permitted direction, and the buck→LDO cascade guarantees `VCC` before `VCC_IO` by
  construction. **The real violation is `VSA`:** the `tmc5130` block ties `VSA`
  (pin 39) to `+5V` while `VS` goes to `VM`, and the absolute maximum is
  `V_VSA` ≤ `V_VS` + 0.5 V. With the buck fed pre-switch, `VSA` sits 4.5 V over that
  limit every time the motor rail is off — the boot state and the safe state. Fix is
  to tie `VSA` to `VM`, the datasheet's "normally tied to VS"; costs ~0.15 W in the
  internal regulator because `VCC` is fed externally. **Rejected switching the 3.3 V
  rail**: the MCU runs on it and drives `ENABLE`, so that is a deadlock. Also noted
  `R4002` is 10 Ω where the datasheet recommends 2.2-3.3 Ω between `VCC` and
  `5VOUT`. This is a shared change to the `tmc5130` block.
- 2026-08-12: **Withdrew the `+3V3_MCU` rename recommendation.** The pull-ups on
  `DIAG_EN`, `LATCH` and `~FAULT` must reference the rail the MCU itself uses, so
  naming the rail by its domain is correct and more precise than `+3.3V`. Only
  consequence: `5v_to_3v3_tps73733` emits `+3.3V`, so the two names need reconciling
  at board level and a netclass pattern added.
- 2026-08-12: Reviewed `hv_input_36V_terminal_2pos_5p08_protected` after the first
  round of edits (refdes renumbered; a `.kicad_pcb` now exists). **Correct:** the
  `EN` divider is now 1 kΩ series + 10 kΩ pulldown giving 3.0 V; `DIAG_EN` and
  `LATCH` are pulled to `+3V3_MCU` through 1 kΩ `RPROT`; `ILIM` = 40 kΩ;
  `SNS` = 249 Ω; diode orientation, both capacitor placements, thermal pad to
  `GND`, `NC` left open, `PWR_FLAG` on `HV_IN`, and the HTSSOP-14 PowerPAD
  footprint all check out. **Three defects:** `R27005` pulls `~FAULT` to `GND`
  instead of `+3V3_MCU`, so the open-drain output idles low and never presents a
  valid high; `HV_IN` is a local label, so the board cannot tap the unswitched node
  for the buck feed or the TVS; and `SNS` is a local label, so the current sense
  cannot reach `GP28`. **Three concerns:** `C27002` is 50 V on a 36 V rail where
  `C27001` is 100 V, and `VOUT` is specified to −60 V during inductive turn-off;
  `+3V3_MCU` will not connect to the board's `+3.3V`; and `VAA` names a pin the
  part does not have. ERC is clean — 32 violations, all library-path or
  isolated-fragment artifacts.
- 2026-08-12: Checked the six input-block edits against actual stock and the parts
  database. **Neither 470 Ω nor 24.9 kΩ is stocked**, so the values changed again:
  `R27004` → **249 Ω** (`OW-PASS-CRCW0402249RFKED`, fault level 1.29-1.59 V, even
  safer than 470 Ω would have been) and `R27003` → **40 kΩ**
  (`OW-PASS-SCR0603F40K`, `I_CL` ~1.2 A), with 2 × 49.9 kΩ in parallel as the
  25 kΩ / 1.96 A fallback. Every value now in use is stocked and already promoted,
  so the block edits carry no lead time. Confirmed the SNS amplitude loss is
  irrelevant because `I_SNS` accuracy is ±25-30% below 60 mA anyway.
- 2026-08-12: Netlist export of the `usb2` block shows it has **no ESD
  protection** — only the receptacle and two 5.1 kΩ `CC` pulldowns, with `SHIELD`
  unconnected. The 27 Ω `D+`/`D-` series resistors RP2040 needs are not missing;
  they are `R10001`/`R10002` inside the `rp2040` block. Decided to add the
  **stocked `USBLC6-2P6`** (already in the parts database as
  `Power_Protection:USBLC6-2P6` / `Package_TO_SOT_SMD:SOT-666`, 20 on hand) on the
  connector side of those resistors, rather than purchasing `USBLC6-2SC6`, which is
  the same die in SOT-23-6 and would also need a new internal part. Buy the SC6
  only if boards are hand-assembled. This matters more than usual because `VBUS`
  now feeds the logic rail and the USBLC6 clamps `VBUS` as well as the data lines.
- 2026-08-12: Resolved the four follow-up questions on the 36 V input block against
  `tps1htc100-q1.pdf`. `DIAG_EN` and `LATCH` at 3.3 V with `VS` unpowered is within
  Recommended Operating Conditions, because those pins are specified −1 to 5.5 V
  **with respect to GND** and independently of `VS`; this is unlike the `DAC8563`
  case, whose inputs are specified relative to its own `VDD`. `ILIM` and `SNS` are
  each a single resistor to ground, so the earlier "2:1 divider" advice is
  withdrawn: change `R27003` 10 kΩ → 24.9 kΩ (limit 5.3 A typ → ~2 A) and
  `R27004` 1 kΩ → 470 Ω (fault level 3.3-4.4 V → 2.44-3.01 V, under the ADC
  limit). **Both values were superseded later the same day** by the stock check
  recorded in the entry above — 24.9 kΩ and 470 Ω are not stocked; the values in
  use are 40 kΩ and 249 Ω. Corrected the current-limit figure from 4.6 A to **5.3 A typ (4-6.3 A)**;
  the earlier number used the wrong `K_CL` row instead of the datasheet's tabulated
  `I_CL` values. `LATCH` floating gives **auto-retry every 2 ms**, so tie it high
  for latch-off; clearing is by toggling `EN`, which firmware already owns on
  `GP19`. `R27001` → 1 kΩ done.
- 2026-08-12: Audited `hv_input_36V_terminal_2pos_5p08_protected` by exporting its
  netlist and checking it against `tps1htc100-q1.pdf`. Confirmed the 220 nF is the
  `VS` bypass on `HV_IN` and the 22 nF is the output bypass on `+36V`, both
  correctly placed. Found six things to change when the block is placed: the
  `EN` divider (10 k/10 k) gives only 1.65 V against a 1.5 V `VIH`; `DIAG_EN` is
  left unconnected with an internal pulldown, which disables the `SNS` current
  sense that `GP28` was allocated to read; `~FAULT` and `LATCH` are unconnected;
  `ILIM` is set to ~4.6 A; and the `SNS` fault level of 3.3-4.4 V would
  overvoltage the RP2040 ADC. Allocated `GP29` to `~{HV_FAULT}` and specified a
  2:1 divider on `SNS`. Also bounded output bulk capacitance at tens of µF, since
  the switch dissipates ½CV² charging it and the datasheet requires the design not
  reach thermal shutdown while doing so.
- 2026-08-12: **Corrected the previous "no TVS" conclusion.** It was right that no
  standard TVS protects the TMC5130A at 36 V and wrong to conclude none was
  needed: because the regulator chain taps pre-switch, `HV_IN` carries the buck's
  input capacitance, so hot-plug rings against it while the switch is off and the
  driver is disconnected. The exposed parts at that moment are the 70 V switch and
  the 65 V buck, both clampable by a 40 V-standoff part. TVS goes on `HV_IN`.
- 2026-08-12: Ran the TVS arithmetic against the actual stocked parts and
  **reversed the earlier "add a board-level TVS" recommendation.** Standard SMBJ
  parts clamp at ~1.6× standoff, so a 36 V rail needs 40 V standoff and clamps
  near 64 V, against the TMC5130A's 49 V absolute maximum; the `SMBJ40A`
  breakdown spread of 44.4-49.1 V straddles that limit. The `TPS1HTC100-Q1`
  (70 V / 81 V transient) and `TPSM365R6V5` (65 V / 70 V) need no clamp. Recorded
  that the stocked `SMBJ28A` works only on a 24 V rail, which is why the 24 V
  input block is passive-with-TVS while the 36 V block is active-with-soft-start —
  two coherent designs, not one with a missing part. Also recorded that the 36 V
  block runs happily from 24 V or 30 V as an escape hatch.
- 2026-08-12: Added the multi-source logic rail — onboard buck, USB `VBUS`, and
  optional pyControl 5 V, diode-ORed at the `TPS73733` input rather than at
  `+5V`, because ORing onto `+5V` violates the TMC5130A's 4.6 V `VCC` minimum and
  truncates the DAC's full-scale output. Allocated `GP26`/`ADC0` to `V5_SENSE` so
  firmware can detect the MCU-alive/`+5V`-dead state that USB-only power creates,
  and recorded the input-clamp back-powering hazard it introduces.
- 2026-08-12: Worked the 36 V consequences from `TMC5130A_datasheet_rev1.21.pdf`
  chapter 29: 46 V operating, 49 V absolute with inductive load, and the
  datasheet's own warning about supply ringing from stray inductance. Recorded
  that the internal 5 V regulator's 1 W limit is reached at 32 mA when
  `VM = 36 V`, so `VCC` must be supplied externally, and that the 36 V input
  block populates no TVS. Also flagged the pre-/post-switch feed point as the one
  way to make an unbootable board out of correct blocks.
