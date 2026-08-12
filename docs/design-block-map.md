# Design Block Map

**Status:** Documentation only; KiCad project scaffolded and empty
**Date:** 2026-08-12

This board is assembled from `kicad-libs` design blocks wherever practical.
Board-specific work should mostly be block composition, connector placement,
mechanical decisions, and validation notes.

Design blocks in KiCad 10 are **copies, not links**. Editing a library block does
not propagate to placed instances. Propagate symbol and footprint changes with
Update Symbols/Footprints from Library; topology changes need a re-place.

## Blocks To Place

| Board function | Design block | Instances | Status |
| --- | --- | --- | --- |
| Controller core | `rp2040` | 1 | available, proven on `tmc51x0-driver-dev-pcb` |
| Motor supply input, protected and switched | `hv_input_36V_terminal_2pos_5p08_protected` | 1 | available, **never placed anywhere** |
| 5 V rail | `hv_to_5v_tpsm365r6` | 1 | available, proven |
| 3.3 V logic rail | `5v_to_3v3_tps73733` | 1 | available, proven |
| Stepper driver section | `tmc5130` | 1 | available, proven ×2 |
| Differential encoder receive | `differential_encoder_receiver` | 0-1 | available, proven ×3; needed only if the encoder is differential |
| InstrumentPort-40 DUT boundary | `instrument_port_40_dut_ffc_boundary` | 1 | available, proven |
| Instrumentation signal buffers | `instrumentation_signal_buffer_sn74lvc125a` | 5 | available, proven ×5 |
| USB device connection | `usb2` | 1 | available, proven |
| Logic-rail reference sense | `vtref_sense` | 0 | available but never placed; skip |

Total: **12 block instances**, or 13 if the encoder turns out to be differential.
The twin board's list is 15 or 17.

## The 36 V Input Block Is The One Unproven Block

`hv_input_36V_terminal_2pos_5p08_protected` was added to `kicad-libs` on
2026-08-11 and has **not been placed on any board**. Everything else on this
board's list is proven by `tmc51x0-driver-dev-pcb`.

What it contains, from its metadata and schematic:

| Element | Part |
| --- | --- |
| Connector | Phoenix `1757242`, 2-pos 5.08 mm right-angle pluggable, `OW-CONN-1757242` |
| Reverse polarity | `SBRT15U50SP5` super-barrier series diode |
| Switch and protection | `TPS1HTC100-Q1` smart high-side switch |
| Support | 10 k and 1 k resistors, 220 nF and 22 nF capacitors |
| Power flag | One `PWR_FLAG` (`#FLG027001`) |

Board-facing labels: `HV_IN`, `+36V`, `GND`, `EN`/`ENABLE`, `ILIM`, `SNS`,
`VAA`.

Three things to check before trusting it, in priority order:

1. **Where the regulator chain taps in.** If `hv_to_5v_tpsm365r6` is fed from the
   *switched* `+36V` output, the MCU cannot enable its own supply and the board
   never boots. See `docs/power.md`.
2. **No TVS is populated.** Its own description says so, and says this is the
   difference from both 24 V variants. Add a board-level 36 V TVS.
3. **`ENABLE` is pulled low**, so the rail is off until driven. Correct, but it
   is a firmware requirement, not a free behavior.

Place it in a scratch project and run ERC before committing, exactly as the twin
board's notes recommend for the unproven 24 V terminal variant.

Unlike the 24 V terminal variant, this block **does** carry a `PWR_FLAG`, so it
does not need a board-level flag added. Do not add a second one.

## Blocks Not Yet Existing

| Board function | Candidate block | Notes |
| --- | --- | --- |
| pyControl behavior-port boundary | `pycontrol_behavior_port_rj45_boundary` | **Needed.** Pinout established (`docs/pycontrol-port-pinout.md`): pin 1 `DIO-A` → UART RX, pin 4 `DIO-B` → UART TX, pin 2 `GND`. Needs series/ESD protection. Stocked RJ-45 candidates: `OW-CONN-J1B1211CCD` (shielded, right-angle, LEDs) and `OW-CONN-438600001` (unshielded, right-angle, official footprint). **No Ethernet magnetics.** Keep it project-local until bench-verified. |
| Event-line BNC group | `pycontrol_event_bnc_group` | **Needed.** Three lines: `PULL_EVENT`, `FAULT`, `RSYNC`. Stocked `DOSIN-801-0095` dual right-angle BNC jack, so two jacks cover three lines with one spare. |
| Analog angle output | `dac8563_analog_output` | **Needed.** `DAC8563SDSCR`, channel A to BNC, channel B spare, protection, and any level translation. See `docs/encoder-analog-output.md`. |
| Limit switch input conditioning | `limit_switch_debounced_input` | **Needed**, 1 instance. `MAX6816`-class debouncer plus ESD and series protection. Prior art on the previous-generation board. |
| Joystick harness connector | `joystick_harness_connector` | 1 instance. Encoder conductors, encoder supply, limit switch, return. |

Do not create these speculatively, and do not promote any of them to `kicad-libs`
until this board verifies them and a second use shows the abstraction is real.

**The twin-axis board needs the same four new sections.** Whichever board is
built first should design them so the other can reuse them, which is a real
argument for building this one first: it produces the pyControl port boundary,
the BNC group, the DAC section, and the debounced limit input as verified
circuits, all of which the twin board then inherits rather than invents.

## Reuse Risk

`tmc51x0-driver-dev-pcb` composes 16 blocks with board ERC at **0 violations**,
so block composability is demonstrated for the blocks it uses.

Proven and reused here: `tmc5130`, `differential_encoder_receiver`,
`instrument_port_40_dut_ffc_boundary`,
`instrumentation_signal_buffer_sn74lvc125a`, `hv_to_5v_tpsm365r6`,
`5v_to_3v3_tps73733`, `usb2`, `rp2040`.

Not proven: `hv_input_36V_terminal_2pos_5p08_protected` only. That is a
materially smaller reuse risk than the twin board carries.

## Board-Specific Glue

- Board outline, mounting, and enclosure constraints. `../mouse-joysticks-mech`
  describes the two-joystick assembly, so decide how a per-axis board mounts in
  it before fixing the outline.
- Motor connector placement, orientation, and a locking type suitable for a rig
  that gets handled.
- **If two of these boards end up in one rig, silkscreen a unit identifier
  field** — a blank box, a set of jumper-selectable ID pads, or both. Two
  identical boards with swapped harnesses is a plausible and confusing failure,
  and it is the failure mode this form factor introduces that the twin board does
  not have.
- pyControl RJ-45 and BNC placement with strain relief. Analog BNC in the analog
  zone, event BNCs in the digital zone.
- InstrumentPort-40 FFC placement, considering permanent in-rig attachment. See
  `docs/instrument-strategy.md`.
- Labelled test points for the 8 signals not carried by InstrumentPort-40, plus
  `HV_SNS` and the TMC `SWSEL` strap.
- Exactly one `PWR_FLAG` per net, on input and entry nets only.

## Source Material To Mine

- `../mouse-joysticks-pcb/docs/` — the twin-axis treatment of the same rig. Most
  of this repository's documentation derives from it; read it before concluding
  something here is novel.
- `../tmc51x0-driver-dev-pcb` for the validated TMC5130A composition,
  current-sense choices, and instrumentation buffering pattern.
- `~/Repositories/kicad/mouse-joystick-pcb` for joystick-specific circuits:
  `joystick-motor`, `microcontroller`, `power`. See `docs/prior-art.md`.

## Pre-Commit Reminder

KiCad re-adds LCSC, Vendor SKU, and MPN fields whenever parts are placed or
edited from the database library. When editing blocks in `kicad-libs`, run
`scrub-private-vendor-fields` **then** `validate` — validate inspects
`.kicad_sch` only, so a passing validate does not prove the `.kicad_pcb` side is
clean.
