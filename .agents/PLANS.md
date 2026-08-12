# Mouse Joystick PCB Plan

Use this file for work that is multi-step, risky, or likely to span multiple
sessions.

## Current Goal

Get a **single-axis** board designed, reviewed, and fabricated as quickly as
possible: RP2040, one TMC5130A, one encoder, one limit switch, one 0-5 V analog
angle output on BNC, one pyControl UART on RJ-45, InstrumentPort-40, and a 36 V
switched supply input.

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

- **RP2040 GPIO allocation.** 27 of 30, 3 spare, all ADC-capable, with encoder
  index, `DIAG1`, the synthetic homing stimulus, and software DAC
  `~LDAC`/`~CLR` all present. `docs/interface-map.md`.
- **InstrumentPort-40 overlay.** All 18 digital slots filled. Same document.
- **Event-line routing.** Three lines on BNC, two dual jacks plus one. This is
  the twin board's blocking question, and one axis makes it answerable.
- **The pyControl port pinout**, from the syringe pump. Cited, not bench-verified.
- **Current sense**, inherited: 0.15 Ω, `vsense = 1`, `IRUN = 28`.
- **Supply voltage:** 36 V, using the existing
  `hv_input_36V_terminal_2pos_5p08_protected` block.

## Blocking Items

Ranked. Items 1-5 can stop a fabrication order.

1. **Joystick motor part number.** Sets the motor connector, supply envelope,
   `ILIM`, and confirms whether 0.67 A is RMS or peak. Owner: Peter.
2. **Encoder part.** Sets single-ended versus differential receive, the encoder
   supply voltage and current, and the harness conductor count. Owner: Peter.
3. **DAC8563 `VIH` at `VDD = 5 V`.** Datasheet check. If translation is needed it
   must be a dual-supply part — an `SN74LVC125A` will not do it.
4. **A 36 V-rated TVS.** Not stocked; `SMBJ40A`/`SMBJ43A` class. Purchase item.
5. **Pre- or post-switch feed for the regulator chain.** Post-switch produces an
   unbootable board. Recommendation in `docs/power.md`: pre-switch.
6. `EXT_FAULT_IN` on `GP27`: fitted or explicitly declined. Cheap now, a flying
   wire later.
7. Board outline and mounting. `../mouse-joysticks-mech` is a two-joystick
   assembly, so how a per-axis board mounts is a decision.

Items 1-3 are shared with `../mouse-joysticks-pcb`. Answer them once and record
the answer in both.

## Milestones

1. ~~Scaffold the repository and write the design record.~~ **Done 2026-08-12.**
2. Answer blocking items 1-5.
3. Prove `hv_input_36V_terminal_2pos_5p08_protected` in a scratch project with
   ERC. It has never been placed on any board.
4. Compose the schematic from existing `kicad-libs` blocks, in the order in
   `docs/rev0-plan.md`.
5. Design the four sections that do not exist as blocks: pyControl port
   boundary, event BNC group, DAC output section, debounced limit input. **Design
   them so `../mouse-joysticks-pcb` can reuse them** — that is a real schedule
   benefit to the other board and an argument for building this one first.
6. Freeze the GPIO allocation and the instrument overlay against the schematic.
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
- the DAC logic-level question is settled;
- the TVS part is chosen;
- the pre-/post-switch feed point is decided;
- ~~the Guix pin, Makefile, and KiCad scaffold exist~~ **done**; `make validate-db`
  still to be run once in the managed shell;
- Gate A items in `docs/validation-plan.md` have explicit status.

## Progress Log

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
- 2026-08-12: Worked the 36 V consequences from `TMC5130A_datasheet_rev1.21.pdf`
  chapter 29: 46 V operating, 49 V absolute with inductive load, and the
  datasheet's own warning about supply ringing from stray inductance. Recorded
  that the internal 5 V regulator's 1 W limit is reached at 32 mA when
  `VM = 36 V`, so `VCC` must be supplied externally, and that the 36 V input
  block populates no TVS. Also flagged the pre-/post-switch feed point as the one
  way to make an unbootable board out of correct blocks.
