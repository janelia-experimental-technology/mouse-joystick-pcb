# Design Block Map

**Status:** Rev 0 rescoped 2026-08-13; KiCad project scaffolded, schematic in
progress
**Date:** 2026-08-13

This board is assembled from `kicad-libs` design blocks wherever practical.
Board-specific work should mostly be block composition, connector placement,
mechanical decisions, and validation notes.

Design blocks in KiCad 10 are **copies, not links**. Editing a library block does
not propagate to placed instances. Propagate symbol and footprint changes with
Update Symbols/Footprints from Library; topology changes need a re-place.

## Blocks To Place In Rev 0

| Board function | Design block | Instances | Status |
| --- | --- | --- | --- |
| Controller core | `rp2040` | 1 | available, proven on `tmc51x0-driver-dev-pcb` |
| GPIO isolation | `rp2040_gpio_isolation_sn74cb3q3245` | 1 | available, proven on `tmc51x0-driver-dev-pcb` |
| Motor supply input, protected and switched | `hv_input_36V_terminal_2pos_5p08_protected` | 1 | available, **never placed anywhere** |
| 5 V rail, switched domain | `hv_to_5v_tpsm365r6` | 1 | available, proven |
| 3.3 V rails, one per domain | `5v_to_3v3_tps73733` | **2** | available, proven |
| Stepper driver section | `tmc5130` | 1 | available, proven ×2 |
| USB device connection | `usb2` | 1 | available, proven; now carries `USBLC6-2P6` ESD and a shell-to-GND tie |

**Eight block instances.** The earlier full-scope plan was twelve or thirteen;
the twin board's list is fifteen or seventeen.

The two `5v_to_3v3_tps73733` instances are not a duplication to tidy away. The
board has **two power domains** — a switched one that `HV_EN` turns off to reset
the chips, and an always-on MCU domain fed from USB or pyControl — and each needs
its own 3.3 V regulator. Merging them would defeat the architecture. See
`docs/power.md`.

Plus three board-local sections that are not blocks yet — the pyControl RJ-45
boundary, `limit_switch_debounced_input`, and the two-diode OR that feeds
`+5V_MCU` from USB `VBUS` and pyControl pin 6. The first two are below; the
diodes are two parts and a net, described in `docs/power.md`.

## Blocks Deferred To Rev 1

Not placed in Rev 0. Listed because the Rev 0 GPIO allocation reserves their pins
and the connector designators are already assigned; see `docs/interface-map.md`.

| Board function | Design block | Instances | Why deferred |
| --- | --- | --- | --- |
| InstrumentPort-40 DUT boundary | `instrument_port_40_dut_ffc_boundary` | 1 | Six of its eighteen slots carry signals Rev 0 does not have |
| Instrumentation signal buffers | `instrumentation_signal_buffer_sn74lvc125a` | 5 | Arrives with the port it buffers |
| Differential encoder receive | `differential_encoder_receiver` | 0-1 | Rev 0 assumes single-ended; fit only if the encoder turns out to be RS-422 |
| Logic-rail reference sense | `vtref_sense` | 0 | Available but never placed; still skip |

## The 36 V Input Block Is The One Unproven Block

`hv_input_36V_terminal_2pos_5p08_protected` was added to `kicad-libs` on
2026-08-11 and has **not been placed on any board**. Everything else on the Rev 0
list is proven by `tmc51x0-driver-dev-pcb`.

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

1. **Where the regulator chain taps in.** `hv_to_5v_tpsm365r6` is fed from the
   **switched** `+36V_SW` output, on purpose — that is what makes `HV_EN` a reset
   for the whole switched domain. It only works because the MCU is powered from
   USB or pyControl instead; check both halves. See `docs/power.md`.
2. **No TVS is populated.** Add one on `HV_IN` — `SMBJ40A`, or the stocked
   `SMF48A` to start. It protects the switch (70 V) at hot-plug, and it matters
   more now that the buck sits behind the switch: `HV_IN` no longer carries the
   buck's input capacitance, so there is little left to damp the ringing. It
   cannot protect the TMC5130A (49 V); that is handled by bulk placement and
   layout. See `docs/power.md`.
3. **`ENABLE` is pulled low**, so the rail is off until driven. Correct, but it
   is a firmware requirement, not a free behavior — and in Rev 0 `HV_EN` bypasses
   the GPIO isolation switch, so it is drivable regardless of bus state.

Place it in a scratch project and run ERC before committing, exactly as the twin
board's notes recommend for the unproven 24 V terminal variant.

`docs/hv-input-block-schematic-note.txt` holds a schematic text block giving
`R_ILIM` and `R_SNS` values for any current limit, so the block can be retargeted
per board the way the `tmc5130` block's sense resistors are. **That note belongs in
the `kicad-libs` block itself** once this board has proven the six edits.

**A full netlist audit of this block against the switch datasheet is in
`docs/power.md`.** It found six things to change when the block is placed,
including an `EN` divider with only 150 mV of threshold margin and a `DIAG_EN`
pin left unconnected that silently disables the current sense. Read that before
placing the block, not after.

Unlike the 24 V terminal variant, this block **does** carry a `PWR_FLAG`, so it
does not need a board-level flag added. Do not add a second one.

## The GPIO Isolation Block Changes The Board's Power-On Posture

`rp2040_gpio_isolation_sn74cb3q3245` is four `SN74CB3Q3245` 8-channel FET bus
switches — 32 channels, one shared active-low `~OE` with a pull-up, so the bus is
isolated until firmware enables it.

It is proven on `tmc51x0-driver-dev-pcb`, but this board is the first to place it
alongside a switched domain that is routinely powered down while the MCU runs, so
three things need care:

- **The rule is the far end's power domain.** A GPIO goes through the switch if
  and only if what it reaches loses power when `HV_EN` drops. That isolates 8
  channels in Rev 0 and 16 at full scope, and it bypasses considerably more than
  the proven board does — the pyControl UART above all, plus the whole
  power-monitoring group. Per-signal rationale in `docs/interface-map.md`.
- **The bus switch is powered from `+3V3_MCU`**, the always-on domain. Putting it
  on the switched rail would isolate for free via `Ioff` and would also take the
  sequencing away from firmware.
- **The block is oversized for this board.** Four packages isolate 30 GPIOs; this
  board isolates 16. Either place the proven block whole and leave half unused, or
  build a two-package board-local section. **Decide before layout** — the
  trade-off is in `docs/interface-map.md`.

Wire the A side of all 16 isolated GPIOs even though Rev 0 uses 8 — the reserved
channels cost nothing now and save a re-place later.

## Blocks Not Yet Existing

| Board function | Candidate block | Rev 0 | Notes |
| --- | --- | --- | --- |
| Limit switch input conditioning | `limit_switch_debounced_input` | **yes** | See below |
| pyControl behavior-port boundary | `pycontrol_behavior_port_rj45_boundary` | **yes** | Pinout established (`docs/pycontrol-port-pinout.md`): pin 1 `DIO-A` → UART RX, pin 4 `DIO-B` → UART TX, pin 2 `GND`, pin 6 `5V` footprint. Needs series/ESD protection. Stocked RJ-45 candidates: `OW-CONN-J1B1211CCD` (shielded, right-angle, LEDs) and `OW-CONN-438600001` (unshielded, right-angle, official footprint). **No Ethernet magnetics.** Rev 0 populates the UART only. Keep project-local until bench-verified. |
| Encoder input | — | **yes** | Board-local, not a block: `OW-CONN-1844249` → filtering and ESD → TMC5130A `ENCA`/`ENCB`/`ENCN`. Encoder supply comes from the **switched** domain, so the encoder resets with everything else. Too thin to abstract until rev 1 adds the PIO tap. |
| MCU power OR | — | **yes** | Board-local: two Schottkys from USB `VBUS` and pyControl pin 6 into `+5V_MCU`. Stocked candidate `OW-MISC-MBR120VLSFT1G`. |
| Analog angle output | `dac8563_analog_output` | rev 1 | `DAC8563SDSCR`, channel A to BNC, channel B spare, protection, and any level translation. See `docs/encoder-analog-output.md`. |
| Event-line BNC group | `pycontrol_event_bnc_group` | rev 1 | Three lines: `PULL_EVENT`, `FAULT`, `RSYNC`. Stocked `DOSIN-801-0095` dual right-angle BNC jack, so two jacks cover three lines with one spare. |

Do not create the rev 1 candidates speculatively, and do not promote any block to
`kicad-libs` until this board verifies it and a second use shows the abstraction
is real.

### `limit_switch_debounced_input` — New In Rev 0

One instance. It owns the connector as well as the conditioning, which is the
change that makes the limit switch independent of the encoder harness.

| Element | Part | Catalog |
| --- | --- | --- |
| Connector | 2-pos 3.5 mm horizontal screw terminal | `OW-CONN-1844210`, stocked |
| Debouncer | `MAX6816EUS+T` | `OW-MISC-MAX6816EUS-T`, stocked, `orb_weaver_misc:MAX6816` / `orb_weaver_smd:SOT192P237X122-4N` |
| Support | Local decoupling | The MAX6816 supplies its own pull-up and ±15 kV ESD protection, so the part count stays at three |

Board-facing: `+3V3_SW`, `GND`, and one debounced output that fans out to the
TMC5130A `REFL` pin and to `GP18`.

**Supply it from the switched domain**, not the MCU domain. Its output drives the
TMC5130A's `REFL` pin, so if the debouncer stayed powered while the driver did
not it would back-power the driver through that pin — the exact failure the bus
switch exists to prevent, arriving by a route the bus switch cannot cover. The
cost is that `GP18` reads a floating pin while the switched domain is down;
firmware enables an internal pull to give it a defined level.

Prior art on the previous-generation board used the same debouncer with a MiSUMi
`D2F-01FL` switch. **The twin-axis board needs this circuit too**, so design it
to be promotable to `kicad-libs` once bring-up verifies it.

## Reuse Risk

`tmc51x0-driver-dev-pcb` composes 16 blocks with board ERC at **0 violations**,
so block composability is demonstrated for the blocks it uses.

Proven and reused in Rev 0: `rp2040`, `rp2040_gpio_isolation_sn74cb3q3245`,
`tmc5130`, `hv_to_5v_tpsm365r6`, `5v_to_3v3_tps73733` ×2, `usb2`.

Not proven: `hv_input_36V_terminal_2pos_5p08_protected` only — seven of eight Rev
0 block instances are proven. The rescope improved this, because the deferred blocks took
the two new circuits (DAC, BNC group) with them.

## Board-Specific Glue

- Board outline, mounting, and enclosure constraints. `../mouse-joysticks-mech`
  describes the two-joystick assembly, so decide how a per-axis board mounts in
  it before fixing the outline.
- **Connector family.** `J5` motor, `J6` encoder, and `J11` limit switch are one
  stocked 3.5 mm horizontal screw-terminal family (`OW-CONN-1844236`,
  `-1844249`, `-1844210`). Uniform harness story, no purchase, no lead time —
  but **screw terminals are not locking**, and the earlier plan wanted a locking
  motor connector for a rig that gets handled. Decide before the harness is
  built; the change is confined to `J5`.
- **If two of these boards end up in one rig, silkscreen a unit identifier
  field** — a blank box, a set of jumper-selectable ID pads, or both. Two
  identical boards with swapped harnesses is a plausible and confusing failure,
  and it is the failure mode this form factor introduces that the twin board does
  not have.
- pyControl RJ-45 placement with strain relief.
- Reserve board area for the rev 1 additions — the InstrumentPort FFC (`J4`) and
  three dual BNCs (`J7`-`J9`) — or accept that rev 1 is a new outline. Decide
  deliberately; it is cheaper to leave the space than to re-do mechanical work.
- **Labelled test points are Rev 0's only instrumentation.** `TMC_DIAG0`,
  `TMC_DIAG1`, `~{TMC_DRV_EN}`, `HV_EN`, `HV_SNS`, `REFL`, `LIMIT_SW`, `SWSEL`,
  `FW_TRIG0`, `FW_TRIG1`, and the SPI bus. Labelled pads, not bare vias.
- Exactly one `PWR_FLAG` per net, on input and entry nets only.
- A shield termination decision for the USB-C receptacle — **now made in the
  block**: `usb2` ties `SHIELD` S1/S2 to GND.

## Source Material To Mine

- `../mouse-joysticks-pcb/docs/` — the twin-axis treatment of the same rig. Most
  of this repository's documentation derives from it; read it before concluding
  something here is novel.
- `../tmc51x0-driver-dev-pcb` for the validated TMC5130A composition,
  current-sense choices, the GPIO isolation bypass group, and the instrumentation
  buffering pattern.
- `~/Repositories/kicad/mouse-joystick-pcb` for joystick-specific circuits:
  `joystick-motor`, `microcontroller`, `power`. See `docs/prior-art.md`.

## Pre-Commit Reminder

KiCad re-adds LCSC, Vendor SKU, and MPN fields whenever parts are placed or
edited from the database library. When editing blocks in `kicad-libs`, run
`scrub-private-vendor-fields` **then** `validate` — validate inspects
`.kicad_sch` only, so a passing validate does not prove the `.kicad_pcb` side is
clean.
