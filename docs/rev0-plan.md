# Mouse Joystick PCB Rev 0 Plan

**Status:** Planning
**Date:** 2026-08-12
**Purpose:** Get a manufacturable single-axis board designed and ordered as fast
as possible, so the researcher can test the pyControl system and the analog angle
output while the twin-axis form factor is still being decided.

## What This Board Is

One PCB controlling **one** joystick axis:

- RP2040 controller MCU with USB-C for firmware load and a CDC debug console.
- One TMC5130A stepper driver section in SPI mode.
- One encoder, read by the TMC5130A encoder interface **and** independently by
  RP2040 PIO as a cross-check.
- One limit switch, routed to the TMC5130A `REFL` input and to an MCU GPIO.
- One 0-5 V analog encoder-angle output on BNC.
- pyControl RJ-45 behavior port carrying the serial link.
- `PULL_EVENT`, `FAULT`, and `RSYNC` on BNC.
- InstrumentPort-40 with buffered digital observation.
- 36 V motor supply through a protected, electronically switched terminal-block
  input.
- Local safe-state authority: boot-safe outputs, host heartbeat, bounded motion
  limits, latched faults.

Out of scope, as on the twin-axis board: electronic brake, torque sensor, audio,
reward and lickport hardware, and animal-facing operation. Those are separate
work and a separate gate.

## Why This Board Instead Of The Twin-Axis Board

The rig has two joysticks, and `../mouse-joysticks-pcb` is the twin-axis design
for it. This board exists because it can be finished sooner, and the reasons are
specific rather than general:

| Twin-axis board | This board |
| --- | --- |
| 28 of 30 GPIOs, reached only after cutting encoder index, `DIAG1`, homing stimulus, and DAC `~LDAC`/`~CLR` | 27 of 30 with **nothing cut** and 3 ADC-capable spares |
| Event-line routing is an open blocking question: 4 lines, no home | 3 lines, and 4 BNCs is a complement that fits |
| Layout zoning across two motor sections, two encoder paths, two analog outputs | One of each |
| Axis symmetry is a first-class layout and scientific constraint | Not applicable |
| Two motors' supply current, doubled bulk and protection | One motor |
| Two of every harness and connector | One of each |

None of that makes the twin board wrong. It makes this board **quicker**, which
is the thing being optimized right now. See
`docs/relationship-to-twin-axis-board.md` for what is being traded away and what
carries forward.

## Deliberate Differences From The Twin-Axis Board

Two, and both are improvements this board can afford:

1. **36 V input instead of 24 V**, using
   `hv_input_36V_terminal_2pos_5p08_protected`. Better motor performance, and it
   pre-resolves the brake rail tension the twin board records as unresolved. It
   costs transient headroom at the TMC5130A and requires a TVS the catalog does
   not stock. See `docs/power.md`.
2. **Nothing is descoped for pin budget.** Encoder index, `DIAG1`, the synthetic
   homing stimulus, and software `~LDAC`/`~CLR` are all present.

## Controller MCU

**RP2040** (`OW-MCU-RP2040`, QFN-56) via `orb_weaver_private:rp2040`, which
provides QSPI flash, a 12 MHz ABM8 crystal, decoupling, RUN/BOOTSEL, SWD, and
debug/timing GPIO breakouts. Proven on `tmc51x0-driver-dev-pcb`.

There is no reason to consider RP2354B here. Its only motivation on the twin
board is the Rev 1 brake and torque GPIO count, and this board carries neither.

Required support:

- USB device connection via `usb2` for firmware load and diagnostics.
- Boot and reset access, SWD header.
- **Debug console over USB CDC.** `UART0` is committed to pyControl.
- Stable 3.3 V logic rail.
- `UART0` pyControl, `SPI0` TMC5130A, `SPI1` DAC, one PIO state machine for the
  encoder.

Full allocation in `docs/interface-map.md`.

## Driver Section

One instance of `orb_weaver_private:tmc5130`, composed twice into
`tmc51x0-driver-dev-pcb` with board ERC at zero.

- TMC5130A-TA (`OW-PWR-TMC5130A-TA-T`), verified official symbol and footprint.
- Strapped and routed for SPI operation. Bring the `SWSEL` strap to a pad.
- `DIAG0` and `DIAG1` both routed to the MCU — this board has the pins.
- `DRV_ENN` pulled to the disabled state so the driver is off before firmware
  configures it.
- The block includes a 16 MHz oscillator and the charge-pump and `5VOUT`
  decoupling.
- Motor connector sized for the chosen motor, locking type.

### Current Sense — Decided, Inherited

Same motor, same answer as the twin-axis board. Do not re-derive it.

Motor rating: **0.67 A per phase**, treated as the RMS target.

| Item | Value |
| --- | --- |
| `R_SENSE` | **0.15 Ω**, both coils — 2 positions |
| Part | `OW-PASS-RLH12FTCR150`, JLCPCB `C2683383` |
| Package / rating | 1206, 1 W, ±1%, ±100 ppm/°C |
| `vsense` (CHOPCONF bit 17) | **1** — high sensitivity, `V_FS` = 180 mV |
| `IRUN` | **28** → 0.679 A RMS (+1.3% of target) |
| Ceiling at CS 31 | 0.749 A |
| Peak sense voltage at IRUN 28 | 163 mV |
| Peak dissipation | 135 mW = 13% of 1 W |

Derived from TMC5130A rev 1.21 chapter 10:

```
I_RMS = (CS+1)/32 × V_FS/(R_SENSE + 20 mΩ) × 1/√2
```

**The `tmc5130` design block ships 0.12 Ω as its default sense value.** Change
both positions to 0.15 Ω when the block is placed, and check the placed value
before ERC rather than after fabrication.

### `vsense = 1` Is A Firmware Dependency

Unchanged from the twin board and just as dangerous with one motor as with two.

| `vsense` | Current at IRUN 28 | Ceiling at CS 31 |
| --- | --- | --- |
| **1 (required)** | 0.679 A | 0.749 A |
| 0 (chip reset default) | **1.23 A** | **1.35 A** |

Leaving `vsense = 0` with 0.15 Ω installed drives roughly **1.8× the motor's
rated current**. Requirements:

- Firmware sets `vsense = 1` before ever raising `DRV_ENN`.
- Firmware reads CHOPCONF back and refuses to enable the driver unless
  `vsense = 1` is confirmed, raising an `INTERNAL` fault instead.
- Silkscreen the shunt group with its value and note the `vsense = 1`
  requirement on the board and in the bring-up log.
- Gate D measures actual coil current, not commanded `IRUN`.

Once `vsense = 1` is set the configuration is self-limiting: the ceiling at
CS 31 is 0.749 A, 12% above the motor rating. The hazard is confined to that one
register bit.

## Encoder

**Open decision: the encoder part is not identified.** The previous-generation
rig used a Broadcom `HEDR-5421-EP111` two-channel quadrature encoder.

- Single-ended TTL: route `A`/`B`/`N` directly to the TMC5130A
  `ENCA`/`ENCB`/`ENCN` with local filtering and ESD protection, and tap to PIO.
- Differential / RS-422: insert `orb_weaver_private:differential_encoder_receiver`,
  which converts `EA±`/`EB±`/`EN±` to `ENCA`/`ENCB`/`ENCN` and takes a `VENC`
  supply for the encoder itself. Composed three times into
  `tmc51x0-driver-dev-pcb`.

Unlike the twin board, `ENC_N` **is** wired to the MCU here (`GP16`), contiguous
with A and B so one PIO state machine reads all three.

Resolve the part before schematic freeze. It also sets the encoder supply
voltage and the harness conductor count.

## Limit Switch And Homing

- One limit switch input with hardware debouncing. The previous-generation board
  used `MAX6816EUS+T`; the rig's switch was a MiSUMi `D2F-01FL`.
- Route the debounced signal to the TMC5130A `REFL` input **and** to `GP18`.
  `REFL` is the hardware-latched reference; the MCU copy allows independent
  state reporting and fault detection.
- `GP9` drives the `REFL` net through a series resistor as a synthetic homing
  stimulus, so homing logic can be exercised without the real switch. Size the
  series resistance so the real switch always wins.
- Homing must be deterministic and bounded: travel limit and timeout, both
  enforced locally, with a fault if either is exceeded.

## Analog Encoder-Angle Output

One 0-5 V output on BNC from a `DAC8563SDSCR`. The part is a **dual** DAC and is
what the twin board specifies; using it here costs nothing extra, keeps the
sourcing decision identical across both boards, and leaves channel B available.

Route channel B to the second position of the stocked dual BNC jack as
`AUX_ANALOG_OUT`, unpopulated or populated as convenient. It is the cheapest
possible provision for a later torque or validity output.

`~LDAC` and `~CLR` are driven by the MCU here rather than tied, so a synchronous
update is available and a software clear exists. See
`docs/encoder-analog-output.md`, including the DAC8563 logic-level question,
which must be resolved before schematic freeze.

## pyControl Interface

Pinout established from `~/Repositories/github/syringe-pump`, a working pyControl
module documented against pyControl v2.1.1. See `docs/pycontrol-port-pinout.md`.

| RJ-45 pin | Signal | This board |
| --- | --- | --- |
| 1 | `DIO-A` | RP2040 `UART0 RX` (`GP1`) |
| 2 | `GND` | Ground |
| 4 | `DIO-B` | RP2040 `UART0 TX` (`GP0`) |
| 6 | `5V` | Optional; not required, the board has its own supply |
| 8 | `12V` | **Not used** — external 36 V motor supply instead |
| 3, 5, 7 | `POW-A`, `SPECIAL`, `POW-B` | Not connected |

115200 8N1, newline-terminated ASCII, `;`-delimited fields.

The assigned port must be UART-capable: ports 1, 3, or 4 on Breakout board 1.2,
or ports 8, 10, 11, or 12 on the D-series Breakout Board 1.6.

Both DIO lines are consumed by the UART, so `PULL_EVENT`, `FAULT`, and `RSYNC`
land on BNCs — three lines, not the twin board's four. See
`docs/interface-map.md` for the connector complement.

Add series resistors and ESD protection on every port signal.

## Power

36 V in, switched and current-limited, then 5 V, then 3.3 V. The full treatment
including the TMC5130A headroom analysis, the missing TVS, and the boot-order
trap is in `docs/power.md`. Read it before drawing the power section — it
contains the one mistake that produces an unbootable board.

## Instrument Port

`instrument_port_40_dut_ffc_boundary` plus five
`instrumentation_signal_buffer_sn74lvc125a` instances. Both proven on
`tmc51x0-driver-dev-pcb`. The overlay in `docs/interface-map.md` fills all 18
digital slots exactly.

## Open Decisions Before Layout Freeze

Ranked by what blocks the schedule.

1. **The joystick motor part number.** The current sense is already decided
   (0.15 Ω, `vsense = 1`, `IRUN = 28`). Still needed for the motor connector, the
   supply envelope, the `ILIM` resistor, and to confirm whether 0.67 A is RMS or
   peak. It is **not** the previous rig's Lin Engineering `WO-208-13-01D`, which
   is 0.6 A.
2. **The encoder part**, and therefore single-ended versus differential receive,
   the encoder supply voltage, and the harness conductor count.
3. **DAC8563 `VIH` at `VDD = 5 V`**, and whether a level translator is required.
4. **A 36 V-rated TVS part.** Not stocked; `SMBJ40A`/`SMBJ43A` class. Purchase
   item.
5. Whether the 5 V/3.3 V chain is fed pre- or post-high-side-switch.
   Recommendation in `docs/power.md`: pre-switch.
6. Which breakout the lab deploys, and which port is assigned to this board.
7. Whether the researcher wants a second analog output later, which decides
   whether `AUX_ANALOG_OUT` gets a populated BNC now.
8. Board outline, mounting, and enclosure constraints. `../mouse-joysticks-mech`
   describes the **two**-joystick assembly, so a single-axis board's mechanical
   envelope is not derivable from it without a decision about how two of these
   boards mount in the rig.
9. Cable and mounting arrangement for in-rig InstrumentPort-40 use.

Items 1 through 5 can stop a fabrication order. Everything else can be resolved
during layout.

## First Schematic Pass

Once the parts above are settled, in this order:

1. Insert `rp2040`.
2. Insert `hv_input_36V_terminal_2pos_5p08_protected`, `hv_to_5v_tpsm365r6`, and
   `5v_to_3v3_tps73733`. **Decide the pre-/post-switch feed point immediately**
   and add the 36 V TVS. Confirm exactly one `PWR_FLAG`; the 36 V block carries
   one already.
3. Insert `tmc5130`. Change both sense resistors from the block default 0.12 Ω to
   **0.15 Ω** (`OW-PASS-RLH12FTCR150`). Record `vsense = 1` and `IRUN = 28`
   alongside. Confirm `VCC` is fed from the external `+5V` rail.
4. Insert `instrument_port_40_dut_ffc_boundary` and five
   `instrumentation_signal_buffer_sn74lvc125a` instances, grouped per
   `docs/interface-map.md`.
5. Insert `usb2`.
6. Add the encoder and limit-switch input paths once their parts are known.
7. Add the DAC output section and the pyControl port / BNC sections.

Run per-block ERC as you go:
`kicad-cli sch erc --severity-error <block>.kicad_sch` with
`ORB_WEAVER_KICAD_LIBS` set. Expect only `pin_not_connected`, `pin_not_driven`,
and `power_pin_not_driven` on an isolated fragment; anything else is a real
defect.
