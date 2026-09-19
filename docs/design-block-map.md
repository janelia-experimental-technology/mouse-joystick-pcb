# Design Block Map

**Status: v1.0 rebuild in progress, 2026-09-16.** Seven block sheets were
deleted from the board so they can be replaced with updated library versions,
the quadrature encoder's orphaned footprints were cleared, **all traces and vias
were deleted**, and the eight board-level TMC input biases were moved into
`motor_encoder_switch` as `R1104`-`R1601` alongside `R1101`-`R1103`. The board
currently holds 65 symbols and 69 footprints (65 + four mounting holes), 0
traces, 0 vias, 4 zones. Rev 0's reviewed, ERC-clean 142-component state is the
2026-08-17 snapshot in git, not the working tree. The v1.0 GPIO and
InstrumentPort channel maps are in
[`docs/interface-map.md`](interface-map.md).
**Date:** 2026-09-16

This board is assembled from `kicad-libs` design blocks wherever practical.
Board-specific work should mostly be block composition, connector placement,
mechanical decisions, and validation notes.

Design blocks in KiCad 10 are **copies, not links**. Editing a library block does
not propagate to placed instances. Propagate symbol and footprint changes with
Update Symbols/Footprints from Library; topology changes need a re-place.

> **Do not re-place the `tmc5130` block.** Thirteen of the fourteen placed block
> copies are byte-identical to their `kicad-libs` sources. `tmc5130` is the
> exception, and **the board is the correct one**: `R1203`/`R1204` are **0.15 Ω**
> here, where `kicad-libs` moved to 0.12 Ω in commit `a8dca31`. Re-placing the
> block silently reverts the sense resistors and puts roughly **25% over the
> intended 0.679 A RMS** through the motor. Nothing catches it — the schematic
> still looks right, ERC and DRC both pass, and the first symptom is a hot motor.
> **Either fix the library down to 0.15 Ω, or never re-place that block.**
>
> **Re-checked 2026-09-16: the library is still 0.12 Ω and the decision is still
> unmade.** The `tmc5130` sheet was deliberately left in place during the v1.0
> block removal for exactly this reason. If you want that block re-placeable in
> this pass — and you will, the next time its layout or fields change — fix the
> library value first and re-save; otherwise this warning has to survive every
> future rebuild.

**`motor_encoder_switch`, `mcu`, and `instrument_port` are board-authored wrapper
sheets, not design blocks.** Nothing re-places them, so edits made there cannot
be lost the way a block edit can. That is why the board-level termination
resistors live in them rather than inside the blocks whose pins they terminate.

**Rehomed 2026-09-16.** They are now **`R403` in `mcu`** and **`R1101`-`R1601` in
`motor_encoder_switch`**; `instrument_port` holds none. The five that moved were
`R1104`-`R1601` and they were renumbered, so **`R1104` is a reused designator** —
it previously named the `REFR_DIR` pull-down described below, which no longer
exists. The move was made because what those eight resistors actually do is keep
the TMC5130A's own inputs defined while the bus switch is open; the instrument
taps were always a secondary beneficiary, and leaving them in a sheet named for
the port invited someone to clear out that sheet during the 50-pin migration and
silently delete five required biases. Nine more are owed by the new blocks — see
[Board-Level Input Biases](interface-map.md#board-level-input-biases).

**TMC5130A `REFR_DIR` (pin 9) is tied directly to GND** as of 2026-08-27. It is a
plain `DI` with no internal pull, unlike `SD_MODE`/`SPI_MODE` (`pu`) and `SWSEL`
(`pd`), and it was floating before rev 1. A 10 kΩ pull-down (`R1104`) was fitted
first and then replaced by the hard tie, which is the more robust treatment and
what the datasheet asks for on an unused input.

**The analog output block's three DAC-bus terminations are the exception to that
rule** — they live inside the block on purpose, because 10 kΩ is right on any
board and a re-place cannot then lose them. See the DAC termination table below.

**Some placement intent exists only in the library block's `.kicad_pcb` and will
not arrive through "Update PCB from Schematic".** Two that matter on this board:
`C1201` is `X1201`'s bypass and wants 1.64 mm pad-to-pad, and `C1204` is the
TMC5130A's `VCC_IO` bypass at 3.04 mm. Open the source block's PCB and copy the
placement by hand, or the layout silently loses it.

## Blocks For v1.0

> **Seven of these blocks gain InstrumentPort tap resistors and `_TAP` pins,
> specified 2026-09-19.** The build order, including which block owns which tap
> and why the pull-resistor doubling rule does not forbid putting them inside,
> is [`docs/instrument-port-tap-resistors.md`](instrument-port-tap-resistors.md).

Fourteen instances across fourteen distinct blocks. **Eight are to place or
re-place; six stay as they are.** The Rev 0 table further down is retained as
history — its instance counts and statuses are not current.

| Board function | Design block | v1.0 status |
| --- | --- | --- |
| Controller core **and** GPIO isolation | `rp2040_with_gpio_isolation_sn74cb3q3245` | **new, to place.** Built and verified 2026-09-16; replaces the `rp2040` + `rp2040_gpio_isolation_sn74cb3q3245` pair, which were never both placed here |
| Motor supply input, protected and switched | `hv_input_36V_terminal_2pos_5p08_protected_vertical` | **to place.** Removed 2026-09-16; take the *vertical* variant to match the other connectors. `+36V_SW` has no source and the whole `HV_EN`/`HV_SNS`/`~{HV_FAULT}`/`HV_DIAG_EN` group is absent until it lands |
| **12 V rail, switched domain** | `hv_to_12v_tpsm365r6` | **not on the board and required.** Both the brake and torque blocks take `+12V` as an input port and this board has never had that rail |
| 5 V rail, switched domain | `hv_to_5v_tpsm365r6` | placed, unchanged |
| 3.3 V rails, one per domain | `5v_to_3v3_tps73733` ×2 | placed, unchanged |
| Stepper driver section | `tmc5130` | placed — **do not re-place**, see the warning above |
| USB device connection | `usb2_vertical` | placed, unchanged |
| Encoder input conditioning | `quadrature_encoder_input_5v_sn74lvc2g17` | **to re-place.** Symbols removed 2026-09-16 and the twelve orphaned footprints cleared; `ENC_A`/`ENC_B` and `ENC_A_RAW`/`ENC_B_RAW` dangle until it lands |
| Limit switch input conditioning | `limit_switch_debounced_input_vertical` | placed, unchanged |
| pyControl behavior-port boundary | `pycontrol_behavior_port_rj45_boundary_vertical` | placed. Carries the PPTC position — see `docs/power.md`. **Exposes only two signal pins**, both spent on the UART |
| InstrumentPort boundary and buffering | `instrument_port_digital_50_dut_ffc_boundary_vertical` | **new, to place.** Replaces the 40-pin DUT boundary *and* all four `instrumentation_signal_buffer_sn74lvc125a` instances |
| Analog angle output | `analog_output_0_3v3_dac80501` | **to re-place.** Rebuilt in `kicad-libs`: I2C at 0x48, ÷2 output divider, 3.3 V rail |
| Brake current sink | `brake_current_sink_0_49ma_dac80501` | **new, to place.** I2C at 0x49, needs `+12V` and `+36V_SW` |
| Torque bridge | `torque_bridge_0_3v3_ina821` | **new, to place.** `SPI1` plus `TQ_CONVST_CS`/`TQ_CAL_EN`, needs `+12V` |

Two things to expect during placement. **Library blocks use 5-digit designator
bands** (`rp2040_with_gpio_isolation` is 40xxx, analog 35xxx, brake 36xxx, torque
37xxx, digital-50 39xxx) while this board is 4-digit, so every placement gets
re-annotated — plan the bands, and never tick "Re-link footprints to schematic
symbols based on their reference designators." And **`~{BUS_SW_EN}` needs a
read-only sheet pin added to the MCU block** before placement if you want the
InstrumentPort to witness the isolation state; see `docs/interface-map.md`.

## Blocks To Place In Rev 0 — History

| Board function | Design block | Instances | Status |
| --- | --- | --- | --- |
| Controller core | `rp2040` | 1 | available, proven on `tmc51x0-driver-dev-pcb` |
| GPIO isolation | `rp2040_gpio_isolation_sn74cb3q3245` | 1 | available, proven on `tmc51x0-driver-dev-pcb` |
| Motor supply input, protected and switched | `hv_input_36V_terminal_2pos_5p08_protected` | 1 | **placed 2026-08-17**; first placement anywhere |
| 5 V rail, switched domain | `hv_to_5v_tpsm365r6` | 1 | available, proven |
| 3.3 V rails, one per domain | `5v_to_3v3_tps73733` | **2** | available, proven |
| Stepper driver section | `tmc5130` | 1 | available, proven ×2 |
| USB device connection | `usb2` | 1 | available, proven; now carries `USBLC6-2P6` ESD and a shell-to-GND tie |
| Encoder input conditioning | `quadrature_encoder_input_5v_sn74lvc2g17` | 1 | available 2026-08-17, **placed 2026-08-17**; first placement anywhere |
| Limit switch input conditioning | `limit_switch_debounced_input` | 1 | available 2026-08-15, **placed 2026-08-17**; first placement anywhere |
| pyControl behavior-port boundary | `pycontrol_behavior_port_rj45_boundary` | 1 | available 2026-08-16, **placed 2026-08-17**; no new pins, but two pin shapes should change — see below |
| InstrumentPort-40 DUT boundary | `instrument_port_40_dut_ffc_boundary` | 1 | **placed 2026-08-17**; first placement anywhere. `AGND` pins 31/34/37/40 tied to `GND`, no longer an isolated island |
| Instrumentation signal buffers | `instrumentation_signal_buffer_sn74lvc125a` | **3** | available, composed ×5 into `tmc51x0-driver-dev-pcb`; **3 placed 2026-08-17 as `U1601`/`U1701`/`U1801`** |

**Fifteen block instances across fourteen distinct block copies** — the table
sums to fifteen, and `5v_to_3v3_tps73733` is the one block placed twice from a
single sheet file. Up from eight when the InstrumentPort was pulled into Rev 0
on 2026-08-16. The earlier full-scope plan was twelve or thirteen; the twin
board's list is fifteen or seventeen.

**Corrected 2026-08-17.** The table used to claim five buffer instances and to
sum to sixteen against a stated fifteen. **Reversed 2026-08-17**; earlier
guidance said to place five buffer packages with two DNP so rev 1 and rev 2
could populate `U_C` and `U_D` without a re-place. That reservation was never
drawn — the schematic contains exactly three `SN74LVC125A` packages and there is
no `U_C` or `U_D` anywhere in it. The reasoning still stands on its own terms
(unpopulated footprints are cheap; a re-place is not), but it is now a rev 1
block placement rather than a stuffing change, and the board area for it has to
be reserved deliberately rather than by leaving footprints behind.

**Exactly two `5v_to_3v3_tps73733` instances**, decided 2026-08-13. Not one, not
three: the switched domain's 3.3 V stays a single undivided rail.

The two instances are not a duplication to tidy away. The
board has **two power domains** — a switched one that `HV_EN` turns off to reset
the chips, and an always-on MCU domain fed from USB or pyControl — and each needs
its own 3.3 V regulator. Merging them would defeat the architecture. See
`docs/power.md`.

**The two-diode MCU power OR is no longer board-local.** `usb2` now emits
`+5V_USB` through `D301` and `pycontrol_behavior_port_rj45_boundary` emits
`+5V_PYC` through `D1901`, so the board only ties the two together at `+5V_MCU`.
Both diode orientations are verified against symbol pin 1 = cathode.
See `docs/power.md`.

**The encoder input is a design block now. Reversed 2026-08-17**; earlier
guidance said it was the one board-local section that is not a block —
"`OW-CONN-1844249` → filtering and ESD → TMC5130A `ENCA`/`ENCB`/`ENCN`, still too
thin to abstract". `quadrature_encoder_input_5v_sn74lvc2g17` was built in
`kicad-libs` and placed the same day, so **every Rev 0 section is either a design
block or a board-authored wrapper sheet**, and none of the three defects that
paragraph recorded survives in the form it recorded them.

As built the chain is `J1103` → `R801`/`R802` 100 kΩ harness-side pull-downs →
`R803`/`R804` 4.7 kΩ series → `C802`/`C803` 470 pF → `U801` `SN74LVC2G17` dual
Schmitt on **`+3.3V_SW`** → `R805`/`R806` 100 kΩ output pull-downs →
`ENC_A`/`ENC_B`.

- **The 5 V-versus-3.3 V question is resolved in hardware.** `U801` is powered
  from `+3.3V_SW`, so it accepts the encoder's 5 V swing and re-emits 3.3 V logic
  before anything reaches the TMC5130A's `VCC_IO`-referenced inputs or the
  always-on instrumentation buffers. The Schmitt hysteresis also cleans the
  filtered edges. `.agents/handoff.local.md` finding 5's second half is closed,
  and it is closed by the block rather than by a board-local patch.
- **Only the "no `ENC_N`" half is still true.** There is no `ENC_N` net. `J1103`
  pin 2 is a **reserved index no-connect**, and the TMC5130A's `ENCN` is
  terminated by `R1201` 10 kΩ to GND — which is exactly what the datasheet asks
  for on an unused pin ("pull to GND or VCC_IO, if the pin is not used"). So the
  index channel is a scope decision with a defined input, not a floating pin.
- **There is no ESD device in the encoder path.** This document described the
  section as "filtering and ESD"; the filter is real and the clamp is not. The
  encoder terminal is the one harness entry on the board with no ESD part on it.
  Decide whether that is acceptable before the fab order.
- Two constraints the block imposes on the still-open encoder choice: the 100 kΩ
  **pull-downs** assume a **push-pull** 5 V encoder and would have to become
  pull-ups for an open-collector part, and the 4.7 kΩ + 470 pF filter is a 72 kHz
  corner (τ = 2.2 µs), which must be checked against the encoder's maximum output
  frequency.

### The pyControl Block Needs No New Pins, But Two Shape Edits

**No new boundary pins — considered and rejected, 2026-08-16.** An earlier draft
of the InstrumentPort plan called for `PYC_DIO_A_CONN`/`PYC_DIO_B_CONN` on the
connector side of `R1901`/`R1902`, so the port could observe the raw cable node.
**Do not do this.** On a digital instrument channel the two sides of a 100 Ω
resistor carrying 330 µA differ by 33 mV and are indistinguishable; the extra pins
would expose a distinction no board can use, and would put the buffer input on the
unprotected side of the ESD clamp. Reasoning in `docs/interface-map.md`, "Where
Each Signal Is Tapped". The port taps the existing `PYC_DIO_A`/`PYC_DIO_B` pins
and **the block stays at five boundary pins**.

**Two pin shapes should change**, though: `PYC_DIO_A` and `PYC_DIO_B` from
`passive` to `bidirectional`. All five pins are `passive` today, which makes this
the only connector boundary block in the library with no driving pin — `usb2`
declares `USB_D+`/`USB_D-` bidirectional and `instrument_port_40_dut_ffc_boundary`
declares all eighteen `DIG*`/`TRIG*` bidirectional. Left passive, `PYC_UART_RX`
reaches the board with no driver anywhere on the net and trips KiCad's
"input not driven" check. `bidirectional` is also the shape that actually means
"either direction until a board assigns one", which is the right description of a
pyControl DIO line.

Leave `PYC_5V`, `+5V_PYC`, and `GND` passive. Two attribute edits, no topology
change, no parts change, no PCB impact — but still do them before the block is
placed. It is now placed, so this is a re-place rather than a free edit — low
urgency, since the block works and only ERC driver analysis is affected. Re-run
`make design-blocks-scrub-private` then
`make design-blocks-validate`. Full reasoning in `docs/interface-map.md`,
"Signal Direction And Sheet Pin Types".

**Both pins are already `bidirectional` as placed.** Verified in the flattened
netlist 2026-08-17: `PYC_DIO_A` and `PYC_DIO_B` are `bidirectional` in the
library block *and* in the placed copy, so the edit above is already done and no
re-place is owed.

### `R1903` Is A Polyfuse Position, Not Protection

The 5 V branch as placed is `J1901` pin 6 → `PYC_CONN_5V` → `R1903` →
`PYC_5V_FUSED` → `D1901` → `+5V_MCU`. The block's own on-sheet note says what
`R1903` is for:

> R29003 IS A POLYFUSE POSITION, NOT PROTECTION. The 0.36R part is a jumper.
> Port 5 V is a shared 1.0 A that also feeds the pyControl controller's own logic
> regulator, with no per-port fuse — a fault here can reset the controller.
> Populate a 1206 PPTC, 250-500 mA hold.

Three things follow, none of them done yet:

- **Nothing is fitted.** The position still holds the 0.36 Ω jumper, so the net
  name `PYC_5V_FUSED` currently describes an intention rather than a part. A
  short on this board's 5 V rail reaches the pyControl controller's regulator.
- **There are no test points either side of it**, and there are no test points
  anywhere else on the board either. A tripped PPTC could not be diagnosed in
  circuit. If the part is populated, pad both nodes.
- **The placed on-sheet text still names `R29003`**, which is not this board's
  designator — the part annotates as `R1903` here. The text is a graphic, so
  "Update Symbols from Library" will not fix it; edit it on the sheet.

## Blocks Deferred To Rev 1

Not placed in Rev 0. Listed because the Rev 0 GPIO allocation reserves their pins
and the connector designators are already assigned; see `docs/interface-map.md`.

| Board function | Design block | Instances | Why deferred |
| --- | --- | --- | --- |
| Differential encoder receive | `differential_encoder_receiver` | 0-1 | Rev 0 assumes single-ended; fit only if the encoder turns out to be RS-422 |
| Logic-rail reference sense | `vtref_sense` | 0 | Available but never placed; still skip |

## The 36 V Input Block Is The One Unproven Block

`hv_input_36V_terminal_2pos_5p08_protected` was added to `kicad-libs` on
2026-08-11 and this board is its **first placement anywhere**. Everything else on
the Rev 0 list except the encoder block is proven by `tmc51x0-driver-dev-pcb`.

What it contains, from its metadata and schematic:

| Element | Part |
| --- | --- |
| Connector | Phoenix `1757242`, 2-pos 5.08 mm right-angle pluggable, `OW-CONN-1757242` |
| Reverse polarity | `SBRT15U50SP5` super-barrier series diode, `D201`: `HV_RAW` anode → `HV_IN` cathode, orientation verified |
| Switch and protection | `TPS1HTC100-Q1` smart high-side switch, `U201` |
| Support, as built | `R508` (`ILIM`) **40 kΩ**, `R509` (`SNS`) **249 Ω**, `R507` (`~FAULT`) 10 kΩ to `+3.3V_MCU`, `R501` (`EN`) 1 kΩ with `R506` 10 kΩ pull-down, `R503` (`LATCH`) 1 kΩ to `+3.3V_MCU`, `R502` (`DIAG_EN`) 1 kΩ to `GP14`; 220 nF and 22 nF capacitors |
| Power flag | One `PWR_FLAG` (`#FLG027001`) |

**Corrected 2026-08-17**; the support row previously read "10 k and 1 k
resistors", which was the library block's default set. The two values that are
not 10 k or 1 k are the two that were retargeted for this board: `ILIM` at 40 kΩ
(≈1.2 A, a recorded assumption pending the motor part number) and `SNS` at
249 Ω.

Board-facing labels: `HV_IN`, `+36V`, `GND`, `EN`/`ENABLE`, `ILIM`, `SNS`,
`HV_RAW`. **Corrected 2026-08-17**; this list said `VAA`, which is not a net on
this board. `HV_RAW` is the connector-side node ahead of the reverse-polarity
diode.

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
board's notes recommend for the unproven 24 V terminal variant. **Done** — it is
placed at the root of this project and the design ERCs clean.

`docs/hv-input-block-schematic-note.txt` holds a schematic text block giving
`R_ILIM` and `R_SNS` values for any current limit, so the block can be retargeted
per board the way the `tmc5130` block's sense resistors are. **That note belongs in
the `kicad-libs` block itself** once this board has proven the six edits.

**A full netlist audit of this block against the switch datasheet is in
`docs/power.md`.** It found six things to change when the block is placed,
including an `EN` divider with only 150 mV of threshold margin and a `DIAG_EN`
pin left unconnected that silently disables the current sense. Read that before
placing the block, not after.

**All six edits are made in the placed copy**, and two of the audit's
recommendations were themselves revised on the bench of the datasheet:

- **`DIAG_EN` goes to `GP14`, not to a fixed `+3.3V_MCU` pull-up. Reversed
  2026-08-17**; the audit said "tie high". Held high, the switch's OFF-state
  open-load detection keeps an internal 150 kΩ pull-up from `VS` to `VOUT`
  permanently enabled, injecting ~240 µA into the ~208 µF on `+36V_SW`. The rail
  then creeps at ~1.2 V/s, crosses the buck's 3.6 V minimum `VIN` in about three
  seconds, and the switched domain hiccups instead of switching off — which
  breaks the property the whole two-domain architecture exists for. `DIAG_EN` has
  an internal pull-down, so a high-Z `GP14` at reset means diagnostics off and
  `+36V_SW` at true zero. Table 7-1 gates only reporting; current limit and
  thermal shutdown are unaffected. **Firmware must raise `GP14` before reading
  `HV_SNS` or `~{HV_FAULT}`.**
- **`SNS` is 249 Ω, and that is deliberate. Superseded 2026-08-17**; an earlier
  1 kΩ recommendation would have driven `GP28` past its absolute maximum.
  `ISNSFLT` is a 5.2-6.4 mA current source, so a fault reads 1.3-1.6 V across
  249 Ω — clear of the ≤0.37 V normal-current reading and well under the RP2040's
  `IOVDD` + 0.5 = 3.8 V limit. The safe upper bound is about 594 Ω.

**No TVS is populated as built.** Item 2 above is still owed.

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
  and only if what it reaches loses power when `HV_EN` drops. That isolates 7
  channels in Rev 0 and 12 at full scope, and it bypasses considerably more than
  the proven board does — the pyControl UART above all, plus the whole
  power-monitoring group. Per-signal rationale in `docs/interface-map.md`.
- **The bus switch is powered from `+3.3V_MCU`**, the always-on domain — all four
  `VCC` pins. Putting it on the switched rail would isolate for free via `Ioff`
  and would also take the sequencing away from firmware.

  **This is a deliberate divergence from the block's own part note**, which says
  the block should be powered from the **switched** target-domain rail precisely
  so `Ioff` provides isolation at `VCC` = 0. As built the isolation is a firmware
  property instead: it depends on the MCU holding `~{BUS_SW_EN}` high, which
  `R601` 7.87 kΩ to `+3.3V_MCU` makes the reset default. Recorded here because
  the two documents disagree on purpose, not by accident — the board is the
  authority and the trade is sequencing control for a free hardware guarantee.
- **A side is the TMC/switched side; B side is the MCU side.** Inverted from what
  `docs/interface-map.md` describes; the board is the authority. The
  `SN74CB3Q3245` is a symmetric FET pass gate, so it functions either way.
  Channel pairing on the RGY-20 package is `A_n` = pin (n+1), `B_n` = pin (19−n).
- **Two of the four packages carry nothing at all.** `U601` carries six channels
  (`~TMC_CS` A3, `~TMC_DRV_EN` A4, `TMC_SPI_CIPO` A5, `TMC_DIAG0` A6,
  `TMC_SPI_SCK` A7, `TMC_SPI_COPI` A8), `U602` carries **one** of its eight
  (`TMC_DIAG1` on A1/B1), and **`U603` and `U604` carry none**. Unused channels
  have their A pins open and their **B (MCU-side) pins tied to GND**, so the
  rev 1 DAC channels are *not* pre-wired and rev 1 will have to edit this block
  regardless. Decide what to do with `U603`/`U604` before layout.
- **The block is oversized for this board, and that is accepted.** Four packages
  isolate 30 GPIOs; this board isolates **12 at full scope and 7 in Rev 0**, down
  from 16 and 8 when the encoder and limit switch stopped reaching the MCU on
  2026-08-16. Twelve channels fit in two packages with four to spare, so the block
  is now carrying double what it needs rather than a bit over. Decided 2026-08-13
  to place the proven block whole rather than build a smaller equivalent, and that
  still holds on schedule grounds — but it is a larger waste than when it was
  decided. Revisit in a later revision.

Wire the A side of all 12 isolated GPIOs even though Rev 0 uses 7 — the reserved
channels cost nothing now and save a re-place later. **Not done, and the saving
is gone.** As built only the seven Rev 0 channels are wired; every other channel
has its A pin open and its B pin grounded. The advice was right and it is too
late to take for free, so budget a block edit into rev 1 rather than expecting
the DAC group to drop into reserved channels.

## Blocks Not Yet Existing

All **three** Rev 0 entries were built on 2026-08-15, 2026-08-16, and 2026-08-17
and have moved to the Rev 0 placement table above. What remains here is future
work.

**The encoder row left this table on 2026-08-17. Reversed 2026-08-17**; it read
"Board-local, not a block: `OW-CONN-1844249` → filtering and ESD → TMC5130A
`ENCA`/`ENCB`/`ENCN` … Stays board-local". `quadrature_encoder_input_5v_sn74lvc2g17`
was built in `kicad-libs` and placed, so the section is a block now. Everything
else that row asserted still holds: the encoder is **nowhere near the MCU in any
revision**, its supply comes from the **switched** domain so it resets with
everything else, `ENC_A`/`ENC_B` are tapped into InstrumentPort `DIG0`/`DIG1`,
and the PIO tap that might have justified a block was deleted rather than
deferred. Three details changed: the conditioning now exists (`U801` and its
filter), the tap pull-downs are the block's own `R805`/`R806` 100 kΩ output
pull-downs rather than board-local parts, and **`ENC_N` was dropped rather than
routed to a test pad** — `J1103` pin 2 is a reserved no-connect and the TMC's
`ENCN` is held low by `R1201`. Full as-built chain above.

| Board function | Candidate block | Rev 0 | Notes |
| --- | --- | --- | --- |
| Event-line BNC group | `pycontrol_event_bnc_group` | rev 1 | Three lines: `PULL_EVENT`, `FAULT`, `RSYNC`. Stocked `DOSIN-801-0095` dual right-angle BNC jack, so two jacks cover three lines with one spare. Feeds `DIG13`-`DIG15`. |
| Brake current driver | `brake_current_sink_0_49ma_dac80501` | rev 2 | **Decided 2026-08-31**, renamed from `b5z_brake_current_driver` — nothing in the block is B5Z-specific except the connector and one divider ratio. DAC-programmed linear current sink: a second `DAC80501ZDGSR` at **3.3 V** (not the angle DAC's 5 V), a 0.19512 precision divider giving 48.78 mA full scale, three `OPA197` singles (loop error amplifier, independent 56 mA ceiling, `BRAKE_ISENSE` buffer), a `BUK7D36-60EX` pass device, a 10 Ω Kelvin shunt, and an `S115Q` flyback across the in-block connector. **`LM3404HV` and `BCR421UE6327` are both rejected, not undecided**, and there is **no alternate pass device** — the 80 V `BSC072N08NS5ATMA1` was briefly carried as a DNP option and rejected on gate-drive headroom, so only one land pattern is needed. **Schematic drawn and netlist-verified 2026-08-31**: 47 parts, 26 named nets, no floating pins. Not laid out, not bench validated. Feeds `DIG11` **`BRAKE_CS`** — not `BRAKE_DIM`; there is no PWM in this design — `DIG12` `~{BRAKE_FAULT}` (optional buffer), and `AIN1` `BRAKE_ISENSE`. Every part is in stock and in the parts DB. Full specification, values, connection table, BOM, and open items: `../kicad-libs/docs/brake-current-sink-design.md`. |
| Torque bridge front end | `torque_bridge_frontend` | rev 2 | Wheatstone bridge conditioner, `PGA305` (I2C, stocked, board precedent) versus `ADS1220` (SPI). **Takes `DIG0`/`DIG1` back from the Rev 0 encoder taps.** The I2C-versus-SPI choice decides whether two slots are enough — see `docs/interface-map.md`. |

Do not create the rev 1 and rev 2 candidates speculatively, and do not promote any
block to `kicad-libs` until this board verifies it and a second use shows the
abstraction is real.

### The Analog Output Block Exists — 2026-08-26

**`analog_output_0_3v3_dac80501` left this table on 2026-08-26.** It was listed
here as `dac8563_analog_output` — "`DAC8563SDSCR`, channel A to BNC, channel B
spare, protection, and any level translation". Three of those four clauses are
now wrong, and the block was built in `kicad-libs` ahead of the board rather
than alongside it, which is a deliberate exception to the paragraph above: the
part choice was the open question, so resolving it needed a real schematic.

| Was | Is |
| --- | --- |
| `DAC8563SDSCR`, dual | `DAC80501ZDGSR`, single, plus an `OPA197` gain stage |
| Channel B spare on the same package | A second output is a second **instance** |
| "any level translation" | None — `VIH` is 1.62 V flat |
| Protection unspecified | 249 Ω series, `TPD1E05U06` ESD, 100 kΩ output pull-down |

Feeds `DIG6`, `DIG9`, `DIG10`, and `AIN0`, unchanged — the tap count did not
move, because `~{DAC_LDAC}` and `~{DAC_CLR}` were never on the port.

**It needs three things from the board when it is placed**, none of them inside
the block: the three bus terminations below, `+5V_SW` rather than `+5V_MCU`, and
placement hard against its connector so the ESD clamp's ground via lands on the
connector ground pin. Full detail in `docs/encoder-analog-output.md` and in the
block's own description, which is the copy that travels with a placed instance.

**It is not yet placed, and it has never been on a bench.** Treat it as
unproven in the same sense the 36 V input block was before Rev 0 — an audit of
its netlist against the datasheet found six issues in that one.

### `limit_switch_debounced_input` — Built 2026-08-15

One instance. It owns the connector as well as the conditioning, which is the
change that makes the limit switch independent of the encoder harness.

| Element | Part | Catalog |
| --- | --- | --- |
| Connector | 2-pos 3.5 mm horizontal screw terminal | `OW-CONN-1844210`, stocked |
| Debouncer | `MAX6816EUS+T` | `OW-MISC-MAX6816EUS-T`, stocked, `orb_weaver_misc:MAX6816` / `orb_weaver_smd:SOT192P237X122-4N` |
| Support | Local decoupling | The MAX6816 supplies its own pull-up and ±15 kV ESD protection, so the part count stays at three |

Board-facing: `+3.3V_SW`, `GND`, and one debounced output. **It goes to the
TMC5130A `REFL` pin and nowhere else on the MCU** — decided 2026-08-16, freeing
`GP18`. Firmware learns about homing from the driver over SPI. The output is also
tapped to InstrumentPort `DIG11` in Rev 0 and to a test pad always, which are the
only independent witnesses that the switch actually closed. **`DIG11` is live;
the test pad does not exist yet** — no test point exists anywhere on the board.
So in Rev 0 the InstrumentPort is the sole witness, and it goes away at rev 2.

**Supply it from the switched domain**, not the MCU domain. Its output drives the
TMC5130A's `REFL` pin, so if the debouncer stayed powered while the driver did
not it would back-power the driver through that pin — the exact failure the bus
switch exists to prevent, arriving by a route the bus switch cannot cover. Since
2026-08-16 there is no `GP18` copy to worry about; the only always-on thing on
that net is the instrumentation buffer input, which is terminated by `R1601`
**10 kΩ** to GND in `instrument_port`. **Corrected 2026-08-17**; this said
100 kΩ, and 100 kΩ is the wrong value here — see the termination table below.

Prior art on the previous-generation board used the same debouncer with a MiSUMi
`D2F-01FL` switch. **The twin-axis board needs this circuit too**, so design it
to be promotable to `kicad-libs` once bring-up verifies it.

## Board-Level Terminations — As Built 2026-08-17, Updated 2026-08-27

**Reversed 2026-08-17**; this document previously called for **100 kΩ**
pull-downs on `ENC_A`, `ENC_B`, `LIMIT_SW`, and the SPI taps. The reasoning was
sound — an always-on buffer input must not float — but the value was wrong, and
one of the nets needed a pull-**up** rather than a pull-down. Nine resistors were
placed instead, all of them in the board-authored wrapper sheets so a block
re-place cannot lose them. **Rev 1 adds three more for the DAC bus** — see the
end of this section:

| Ref | Value | Net | To | Sheet | Why |
| --- | --- | --- | --- | --- | --- |
| `R403` | 10 kΩ | `PYC_UART_RX` | `+3.3V_MCU` | `mcu` | UART RX must idle **high**; the RP2040's default pull-down would look like a permanent break |
| `R1104` | 10 kΩ | `TMC_SPI_SCK` | GND | `motor_encoder_switch` | define the TMC input, and the instrument tap, when the switched domain is off |
| `R1105` | 10 kΩ | `TMC_SPI_COPI` | GND | `motor_encoder_switch` | as above |
| `R1106` | 10 kΩ | `TMC_SPI_CIPO` | GND | `motor_encoder_switch` | as above; also gives the instrument tap a clean idle-low |
| `R1107` | 10 kΩ | `~{TMC_CS}` | `+3.3V_SW` | `motor_encoder_switch` | CSN must idle **deasserted** — a pull-down would assert chip select |
| `R1601` | 100 kΩ | `LIMIT_SW` | GND | limit-switch **block** | define the debounced limit input — inside the block, correctly: it is that block's own output |
| `R1101` | 10 kΩ | `TMC_DIAG0` | `+3.3V_SW` | `motor_encoder_switch` | `DIAG` is open-drain at reset; the datasheet requires ≤47 kΩ |
| `R1102` | 10 kΩ | `TMC_DIAG1` | `+3.3V_SW` | `motor_encoder_switch` | as above |
| `R1103` | 10 kΩ | `~{TMC_DRV_EN}` | `+3.3V_SW` | `motor_encoder_switch` | guarantees the power stage is **disabled** in hardware |

**Designators and sheet updated 2026-09-16.** The first five were `R1104`-`R1601`
in `instrument_port`; the sheet name for the other three was written as
`motor_encoder_limit`, which has never been the file name. Nine more are owed by
the v1.0 I2C and torque buses — see
[Board-Level Input Biases](interface-map.md#board-level-input-biases).

**Two more arrive with rev 1**, taking the count from nine to **eleven** — not
three and twelve, because **the required one lives inside the block**. Same
rule; the DAC's digital pins sit on the switched side of the bus switch and float
when it is open. **Updated 2026-08-27: all three are now in the block, and the
board owns none of them.**

| Ref | Value | Net | To | Where | Why |
| --- | --- | --- | --- | --- | --- |
| `R2006` | 10 kΩ | `~{DAC_CS}` | `+3.3V_SW` | **In the block** | **The load-bearing one.** `SYNC` must idle deasserted; while it is high the `DAC80501` blocks `SCLK` and `SDIN` outright, which is what makes a floating bus harmless |
| `R2010` | 10 kΩ | `DAC_SPI_SCK` | GND | **In the block** | Hygiene — prevents a floating CMOS input, not a functional failure |
| `R2009` | 10 kΩ | `DAC_SPI_COPI` | GND | **In the block** | as above |

The two pull-downs moved in-block on 2026-08-27 because nothing about them is
board-dependent — 10 kΩ to GND is right on any board — and a block re-place cannot
then lose them. The board's nine 10 kΩ terminations stay nine.

**When the `DIG9`/`DIG10`/`DIG6` instrument taps go in, add nothing.** Those taps
sit on the same switched-side nets and need defined levels for the reason
`R1104`-`R1107` exist on the TMC taps, but these three resistors already supply
them. A board-level second set in parallel would halve them.

**The block's `+3.3V` port must bind to `+3.3V_SW`, not `+3.3V_MCU`.** On the
always-on rail, the `~{DAC_CS}` pull-up would hold `~{DAC_CS}` at 3.3 V while the
DAC's `VDD` is dead and push ~260 µA through its input clamp into `+5V_SW` —
back-powering the switched domain from inside a block, where the bus switch cannot
intervene. Verified correct on the placed instance, 2026-08-27.

**None of the three may be pulled to the DAC's 5 V rail.** The `SN74CB3Q3245` is
a symmetric FET pass gate, so a 5 V pull-up on the switched side lands on an
RP2040 pad and exceeds its `IOVDD + 0.3 V` limit. `+3.3V_SW` is sufficient: the
`DAC80501`'s `VIH` is 1.62 V, so even divided against the RP2040's internal
pull-down the ~2.75 V result has margin — the same arithmetic that justifies
`R403`.

`ENC_A` and `ENC_B` are not in this table because the encoder block terminates
them itself, with `R805`/`R806` 100 kΩ on `U801`'s outputs. 100 kΩ is correct
*there* — the driving side is a powered push-pull Schmitt output, not a
high-impedance pin against an internal pull-up.

**Why 10 kΩ and not 100 kΩ on the TMC lines.** `CSN`/`SCK`/`SDI`/`SDO` are marked
`(tpu)` with `RPU` = 132/166/200 kΩ. A 100 kΩ pull-down against that parks the
node at ~1.9 V, straddling the `SN74LVC125A`'s 2.0 V `VIH` — an indeterminate
level on an instrument tap, which is the one place it must not be. 10 kΩ gives
0.28 V, a clean LOW.

**Why some pulls go to `+3.3V_SW` and some to GND.** Anything that must read HIGH
while the driver is powered (`~{TMC_CS}`, both `DIAG`, `~{TMC_DRV_EN}`)
references `+3.3V_SW`, so it collapses to 0 V with the domain instead of
injecting current into a dead rail. Referencing `+3.3V_MCU` would be actively
wrong: it would back-power `+3.3V_SW` to roughly 1.3 V through the TMC's
protection diodes, defeating the `HV_EN` power-cycle and corrupting
`SW_RAIL_SENSE`. **`+3.3V_SW` is held at 0 V when off by `R401`/`R402`** (2 kΩ to
GND, the `SW_RAIL_SENSE` divider) — that is what makes a pull-up to that rail a
valid LOW in the off state. **If that divider is ever removed,
`R1107`/`R1101`/`R1102`/`R1103` stop defining their nets.**

Resulting levels, verified against both datasheets (TMC5130A `V_INLO` ≤ 0.99 V,
`V_INHI` ≥ 2.31 V; `SN74LVC125A` `VIL` = 0.8 V, `VIH` = 2.0 V):

| Net | Domain OFF | Domain ON, bus isolated |
| --- | --- | --- |
| `TMC_SPI_SCK`/`COPI`/`CIPO` | 0 V | 0.28 V (LOW) |
| `~{TMC_CS}` | ≤0.24 V | ≈3.4 V (HIGH, deasserted) |
| `LIMIT_SW` | 0 V | driven by `U1301` |
| `TMC_DIAG0`/`1` | 0 V | 3.3 V (open-drain idle) |
| `~{TMC_DRV_EN}` | 0 V | ≥2.75 V worst case (HIGH = power stage off) |

One thing terminating the inputs does **not** buy: `~OE` on the `SN74LVC125A`
does not gate the input stage. `ΔICC` is 500 µA typical and 5000 µA maximum per
partially biased input regardless of `OE`, against 40 µA for the whole device
with valid levels. Disabling the buffers is not a substitute for this table.

## Reuse Risk

`tmc51x0-driver-dev-pcb` composes 16 blocks with board ERC at **0 violations**,
so block composability is demonstrated for the blocks it uses.

Proven and reused in Rev 0: `rp2040`, `rp2040_gpio_isolation_sn74cb3q3245`,
`tmc5130`, `hv_to_5v_tpsm365r6`, `5v_to_3v3_tps73733` ×2, `usb2`, and
`instrumentation_signal_buffer_sn74lvc125a` ×3 — **ten of fifteen instances**.

Not proven — **five instances**, all placed for the first time on this board:
`hv_input_36V_terminal_2pos_5p08_protected`, `quadrature_encoder_input_5v_sn74lvc2g17`,
`limit_switch_debounced_input`, `pycontrol_behavior_port_rj45_boundary`, and
`instrument_port_40_dut_ffc_boundary`. **Corrected 2026-08-17**; this list said
"three instances" and then named four. The encoder block makes it five.

**Pulling the InstrumentPort into Rev 0 changed this number in both directions.**
It added three proven buffer instances, but it also added an unproven FFC boundary
block, and Rev 0 now carries the board's first-ever placement of five blocks in
one revision. `instrument_port_40_dut_ffc_boundary` is the lowest-risk of them —
it is a connector and 40 nets with no active parts — but its **cable orientation
is an open decision in the profile itself**. `board-interfaces/docs/instrument-port-40.md`
says pin-1 marking, contact side, and same-side/opposite-side cable behaviour must
be confirmed before fabrication, and that every board using the profile must
document its connector reference, pin-1 marker location, contact side, expected
cable type, and whether the mating board sees the pin order mirrored. **Do that for
`J1501` before the fab order**, not after.

The highest-risk of the five is `quadrature_encoder_input_5v_sn74lvc2g17`, not
the FFC boundary: it is new, it is the only unproven block with active parts, and
its two design assumptions — push-pull drive and a 72 kHz filter corner — are
both hostage to the still-open encoder part number.

## Board-Specific Glue

- Board outline, mounting, and enclosure constraints. `../mouse-joysticks-mech`
  describes the two-joystick assembly, so decide how a per-axis board mounts in
  it before fixing the outline.
- **Connector family.** `J1102` motor, `J1103` encoder, and `J1301` limit switch
  are one stocked 3.5 mm screw-terminal family (`OW-CONN-TBH-1X04-3P5-VERT`,
  `-1X05-`, `-1X02-`). Uniform harness story, no purchase, no lead time —
  but **screw terminals are not locking**, and the earlier plan wanted a locking
  motor connector for a rig that gets handled. Decide before the harness is
  built; the change is confined to the motor terminal.
  **Renumbered 2026-08-27**: the motor terminal was `J1101` and the encoder
  terminal was `J1102` before the analog BNC took `J1101`. These are also the
  vertical `TBH` parts now, not the horizontal Phoenix `OW-CONN-1844236`/
  `-1844249`/`-1844210` this entry used to name. See `docs/interface-map.md`,
  "Connector Complement".
- **If two of these boards end up in one rig, silkscreen a unit identifier
  field** — a blank box, a set of jumper-selectable ID pads, or both. Two
  identical boards with swapped harnesses is a plausible and confusing failure,
  and it is the failure mode this form factor introduces that the twin board does
  not have.
- pyControl RJ-45 placement with strain relief.
- **`J1501` placement and FFC strain relief.** Now a Rev 0 problem, not a reserved
  area. `docs/instrument-strategy.md` flags that InstrumentPort-40 is specified
  around a short bench FFC and that permanent in-rig use is a different mechanical
  question; Rev 0 is bench firmware development, so a short cable is acceptable —
  but place `J1501` where the cable exits cleanly and does not cross the 36 V or
  motor zone.
- Reserve board area for the remaining rev 1 additions — two dual BNCs (`J8`,
  `J9`; the analog BNC is placed as `J1101` since 2026-08-27) — and for the
  **fourth and fifth buffer packages, which are not on
  the board**. **Corrected 2026-08-17**; this said their footprints are placed in
  Rev 0 as DNP `U_C` and `U_D`. They are not, so the area must be reserved
  deliberately or rev 1 pays for it. **Removing `U603`/`U604`, two entirely empty
  `SN74CB3Q3245` packages, frees roughly the area the fourth buffer needs.** Also
  leave room for the rev 2 brake driver
  and torque front end, or accept that rev 2 is a new outline. Decide
  deliberately; it is cheaper to leave the space than to re-do mechanical work.
  **Brake area, from the drawn sheet 2026-08-31:** 47 parts — 36 small passives,
  three SOT-23-5 amplifiers, a VSSOP-10 DAC, a DFN2020 pass device, two SOD-123FL
  diodes, an X1SON ESD clamp, two 0603 ferrites, and one 2-position 3.5 mm
  vertical terminal. **No electrolytic**, because the 150 µF 63 V can was sized
  for the dropped switching fallback, and **one pass-device land pattern only** —
  the 80 V alternate was rejected, so no second footprint is needed. It must sit
  at the 36 V entry and the brake connector, at the **opposite side of the board**
  from the bridge connector, excitation, PGA/ADC, reference, and anti-alias
  filter. Leave pads for an RC snubber from the pass-device drain to GND in case
  the ringing measurement comes back badly.
- **The InstrumentPort is currently Rev 0's *only* instrumentation.** It carries
  the TMC SPI bus, both pyControl serial directions, both firmware triggers,
  `ENC_A`/`ENC_B`, and `LIMIT_SW`. **There are no test points anywhere on the
  board** — none of the pads this list has been calling for exist yet. Still
  owed, and now the whole list rather than the remainder: `TMC_DIAG0`,
  `TMC_DIAG1`, `~{TMC_DRV_EN}`, `HV_EN`, `HV_SNS`, `REFL`, `SWSEL`,
  `~{INSTR_BUF_OE}`, both sides of `R1903`, and `ENC_A`, `ENC_B`, `LIMIT_SW` —
  those three lose their port slots at rev 2 and none of them reaches the MCU, so
  the pads become the only access. Labelled pads, not bare vias. `ENC_N` has
  dropped off this list because there is no such net.
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
