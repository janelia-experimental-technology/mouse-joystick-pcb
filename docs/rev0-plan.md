# Mouse Joystick PCB Rev 0 Plan

**Status:** Planning, rescoped 2026-08-13
**Date:** 2026-08-13
**Purpose:** Get a manufacturable single-axis board designed and ordered as fast
as possible, so the researcher can **exercise the interfaces** — motor, encoder,
limit switch, and the pyControl serial link — while the twin-axis form factor is
still being decided.

## Rescoped 2026-08-13

Rev 0 was cut down to shorten the path to testable hardware. The board no longer
carries the analog encoder-angle output, the InstrumentPort, or the pyControl TTL
event lines. It carries the interfaces and nothing else.

The purpose changed with it. The earlier plan aimed at a board the researcher
could run experiments against. **This one aims at a board that proves the
interfaces work**, and defers everything whose value only appears once
experiments start.

| Moved out of Rev 0 | Returns in |
| --- | --- |
| DAC8563 0-5 V analog angle output and its BNC | rev 1 |
| InstrumentPort-40 FFC and five instrumentation buffers | rev 1 |
| `PULL_EVENT`, `FAULT`, `RSYNC` and their BNCs | rev 1 |
| RP2040 PIO encoder cross-check | rev 1 |
| Electronic brake, torque sensor, extra analog outputs | rev 2+ |
| Synthetic homing stimulus (`TMC_REF_STIM`) | **never** — dropped permanently |

`TMC_REF_STIM` is not deferred, it is deleted. The limit switch now arrives
through a real debouncer on its own terminal block, so homing is exercised by
closing the actual switch. Its pin pays for the GPIO isolation enable; see
`docs/interface-map.md`.

## What This Board Is

One PCB controlling **one** joystick axis:

- RP2040 controller MCU with USB-C for firmware load and a CDC debug console.
- A 32-channel GPIO isolation bus switch between the MCU and the rest of the
  board, isolated at power-on until firmware enables it.
- One TMC5130A stepper driver section in SPI mode, with a 4-pin motor terminal.
- One single-ended encoder on a 5-pin terminal, read by the **TMC5130A only**.
- One limit switch on a 2-pin terminal through a hardware debouncer, to the
  TMC5130A `REFL` input and to an MCU GPIO.
- pyControl RJ-45 behavior port carrying the serial link and nothing else.
- 36 V motor supply through a protected, electronically switched terminal-block
  input.
- Local safe-state authority: boot-safe outputs, host heartbeat, bounded motion
  limits, latched faults.

Out of scope: everything in the rescope table above, plus audio, reward and
lickport hardware, and animal-facing operation. Those are separate work and a
separate gate.

## Why This Board Instead Of The Twin-Axis Board

The rig has two joysticks, and `../mouse-joysticks-pcb` is the twin-axis design
for it. This board exists because it can be finished sooner:

| Twin-axis board | This board |
| --- | --- |
| 28 of 30 GPIOs, reached only after cutting encoder index, `DIAG1`, homing stimulus, and DAC `~LDAC`/`~CLR` | 29 of 30 at full scope with a documented reclaim order; **17 of 30 in Rev 0** |
| Event-line routing is an open blocking question: 4 lines, no home | Deferred entirely in Rev 0; 3 lines and 4 BNCs when it returns |
| Layout zoning across two motor sections, two encoder paths, two analog outputs | One motor section, one encoder path, no analog output |
| Axis symmetry is a first-class layout and scientific constraint | Not applicable |
| Two motors' supply current, doubled bulk and protection | One motor |
| Two of every harness and connector | Seven connectors total |

See `docs/relationship-to-twin-axis-board.md` for what is being traded away and
what carries forward.

## Deliberate Differences From The Twin-Axis Board

1. **36 V input instead of 24 V**, using
   `hv_input_36V_terminal_2pos_5p08_protected`. Better motor performance, and it
   pre-resolves the brake rail tension the twin board records as unresolved. It
   costs transient headroom at the TMC5130A, which at this voltage no TVS can
   restore — the driver relies on the soft-start switch and layout instead, while
   the TVS on `HV_IN` covers the switch and the buck. See `docs/power.md`.
2. **GPIO isolation.** The twin board does not carry
   `rp2040_gpio_isolation_sn74cb3q3245`. This board does, which makes every
   board-side net rest at its own local pull until firmware enables the bus.

## Controller MCU

**RP2040** (`OW-MCU-RP2040`, QFN-56) via `orb_weaver_private:rp2040`, which
provides QSPI flash, a 12 MHz ABM8 crystal, decoupling, RUN/BOOTSEL, SWD, and
debug/timing GPIO breakouts. Proven on `tmc51x0-driver-dev-pcb`.

There is no reason to consider RP2354B here. Its only motivation on the twin
board is the Rev 1 brake and torque GPIO count, and this board carries neither.

Required support:

- USB device connection via `usb2` for firmware load and diagnostics.
- Boot and reset access, SWD header.
- **Debug console over USB CDC.** `UART0` is committed to pyControl, and in Rev 0
  USB CDC is the only rich observation path on the board.
- Stable 3.3 V logic rail.
- `UART0` pyControl, `SPI0` TMC5130A. `SPI1` and PIO0 are unallocated in Rev 0
  but their pins are reserved.

Full allocation in `docs/interface-map.md`.

## GPIO Isolation

`orb_weaver_private:rp2040_gpio_isolation_sn74cb3q3245`, one instance: four
`SN74CB3Q3245` 8-channel bidirectional FET bus switches, 32 channels, one shared
active-low `~OE` with a pull-up.

- Wire the **A side of all 29 allocated GPIOs now**, including the 12 reserved
  for rev 1. Leave the B side of reserved channels unconnected so a later
  revision adds board-side wiring only.
- Four signals **bypass** the switch entirely: `~{BUS_SW_OE}` (`GP9`), `HV_EN`
  (`GP19`), `FW_TRIG0`/`FW_TRIG1` (`GP25`/`GP21`), and `~{INSTR_BUF_OE}` (`GP24`,
  rev 1). Rationale per signal is in `docs/interface-map.md`.
- Firmware must enable the bus early in boot — the pyControl UART and the ADC
  sense group are both behind it.

Proven on `tmc51x0-driver-dev-pcb`, which bypasses the same control group.

## Driver Section

One instance of `orb_weaver_private:tmc5130`, composed twice into
`tmc51x0-driver-dev-pcb` with board ERC at zero.

- TMC5130A-TA (`OW-PWR-TMC5130A-TA-T`), verified official symbol and footprint.
- Strapped and routed for SPI operation. Bring the `SWSEL` strap to a pad.
- `DIAG0` and `DIAG1` both routed to the MCU — this board has the pins.
- `DRV_ENN` pulled to the disabled state so the driver is off before firmware
  configures it, and behind the bus switch so it stays that way.
- The block includes a 16 MHz oscillator and the charge-pump and `5VOUT`
  decoupling.
- Motor connector: **4-pos 3.5 mm terminal, `OW-CONN-1844236`**, stocked.

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

Unchanged, and Rev 0's reduced scope does not reduce this hazard at all.

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

**Rev 0 decides single-ended.** `A`, `B`, and `N` route from a 5-pos 3.5 mm
terminal (`OW-CONN-1844249`, stocked) directly to the TMC5130A
`ENCA`/`ENCB`/`ENCN` pins with local filtering and ESD protection. The connector
carries encoder supply, return, and the three channels.

`differential_encoder_receiver` is **not placed in Rev 0**. If the chosen encoder
turns out to be RS-422, that block exists and is proven three times on
`tmc51x0-driver-dev-pcb`, but fitting it is a rev 1 change and the connector
conductor count changes with it.

**The encoder does not reach the MCU in Rev 0.** `GP14`/`GP15`/`GP16` are
reserved and contiguous, and the PIO cross-check arrives in rev 1. The
consequence is that `ENCODER_MISMATCH` has nothing to compare and is not
implementable; encoder integrity rests on the driver's count and the index pulse.

**Still open:** the encoder part number, and therefore the supply voltage and
whether single-ended survives contact with the real device. The previous-generation
rig used a Broadcom `HEDR-5421-EP111`.

## Limit Switch And Homing

A **new design block**, `limit_switch_debounced_input`, one instance. It owns the
connector as well as the conditioning, which is what makes the limit switch
independent of the encoder harness:

| Element | Part |
| --- | --- |
| Connector | 2-pos 3.5 mm terminal, `OW-CONN-1844210`, stocked |
| Debouncer | `MAX6816EUS+T`, `OW-MISC-MAX6816EUS-T`, stocked, `orb_weaver_misc:MAX6816` / `orb_weaver_smd:SOT192P237X122-4N` |
| Support | Local decoupling; the MAX6816 supplies its own pull-up and ±15 kV ESD protection |

- Route the debounced output to the TMC5130A `REFL` input **and** to `GP18`.
  `REFL` is the hardware-latched reference; the MCU copy allows independent state
  reporting and fault detection.
- **No synthetic stimulus.** `TMC_REF_STIM` is gone. Bring `REFL` to a labelled
  test pad so a jumper can still force a closure during bring-up.
- Homing must be deterministic and bounded: travel limit and timeout, both
  enforced locally, with a fault if either is exceeded.

Keep the block project-local until bring-up verifies it. The twin-axis board
needs the same circuit, so design it to be promotable.

## pyControl Interface

Rev 0 populates the serial link only. Pinout established from
`~/Repositories/github/syringe-pump`, a working pyControl module documented
against pyControl v2.1.1. See `docs/pycontrol-port-pinout.md`.

| RJ-45 pin | Signal | Rev 0 |
| --- | --- | --- |
| 1 | `DIO-A` | RP2040 `UART0 RX` (`GP1`) |
| 2 | `GND` | Ground |
| 4 | `DIO-B` | RP2040 `UART0 TX` (`GP0`) |
| 6 | `5V` | Footprint only; population gated on the port's 5 V budget |
| 3, 5, 7, 8 | `POW-A`, `SPECIAL`, `POW-B`, `12V` | Not connected |

115200 8N1, newline-terminated ASCII, `;`-delimited fields.

The assigned port must be UART-capable: ports 1, 3, or 4 on Breakout board 1.2,
or ports 8, 10, 11, or 12 on the D-series Breakout Board 1.6.

Add series resistors and ESD protection on every populated port signal.

`PULL_EVENT`, `FAULT`, and `RSYNC` are rev 1. Rev 0 therefore has **no
hardware-timed event path** — every event is a UART line with UART latency. That
is acceptable for interface testing and is not acceptable for behavioral data,
which is the boundary between Rev 0 and rev 1.

## Power

36 V in, switched and current-limited, then 5 V, then 3.3 V. Unchanged by the
rescope: `+5V` is still required because the TMC5130A's `VCC` minimum is 4.6 V,
even though the DAC that also needed it is deferred.

Read `docs/power.md` before drawing the power section — it contains the two
mistakes that look correct on a schematic:

- feeding the 5 V/3.3 V chain from the **switched** rail, which produces a board
  whose MCU cannot enable its own supply;
- diode-ORing USB and pyControl 5 V onto the **`+5V` rail**, which drops it below
  the TMC5130A's 4.6 V `VCC` minimum.

The board's logic rail is multi-sourced: the onboard buck, USB `VBUS`, and
optionally pyControl RJ-45 pin 6, diode-ORed at the **3.3 V regulator input**,
not at `+5V`.

**Fit a TVS on `HV_IN`, not on the motor rail.** At hot-plug the switch is off, so
the exposed parts are the `TPS1HTC100-Q1` (70 V) and the `TPSM365R6V5` (65 V).
`SMBJ40A` preferred; stocked `SMF48A` works for first boards. The TMC5130A at
49 V cannot be protected by any standard TVS at this supply voltage; it relies on
bulk capacitance downstream of the soft-start switch — **tens of µF, not
hundreds** — tight `VS`/`GND` layout, and measurement at Gate B.

**The input block needs six edits when placed**, two of them functional defects
for this board: the `EN` divider gives only 150 mV of threshold margin from 3.3 V
logic, and `DIAG_EN` left unconnected disables the `SNS` current sense entirely.
Full audit in `docs/power.md`.

## Blocks To Place

Seven instances in Rev 0. Full list and status in `docs/design-block-map.md`.

| Block | Instances |
| --- | --- |
| `rp2040` | 1 |
| `rp2040_gpio_isolation_sn74cb3q3245` | 1 |
| `hv_input_36V_terminal_2pos_5p08_protected` | 1 |
| `hv_to_5v_tpsm365r6` | 1 |
| `5v_to_3v3_tps73733` | 1 |
| `tmc5130` | 1 |
| `usb2` | 1 |

Plus two board-local sections that are not yet blocks: the pyControl RJ-45
boundary, and the new `limit_switch_debounced_input`.

## Open Decisions Before Layout Freeze

The rescope resolved or deferred five of the previous ten. What remains, ranked by
what blocks the schedule:

1. **The joystick motor part number.** The current sense is already decided
   (0.15 Ω, `vsense = 1`, `IRUN = 28`). Still needed for the supply envelope, the
   `ILIM` resistor, and to confirm whether 0.67 A is RMS or peak. It is **not**
   the previous rig's Lin Engineering `WO-208-13-01D`, which is 0.6 A.
2. **The encoder part**, which sets the encoder supply voltage and confirms that
   single-ended receive is correct. Rev 0 assumes single-ended.
3. Whether the 5 V/3.3 V chain is fed pre- or post-high-side-switch.
   Recommendation in `docs/power.md`: pre-switch.
4. **Where `+3.3V_MCU` comes from.** `VSA` stays on the external 5 V for thermal
   reasons, so that 5 V must be switched with `VM`, which forces the MCU onto a
   separate always-on rail and the TMC's `VCC_IO` onto a switched one. Either a
   small always-on converter taps `HV_IN`, or the board only boots with USB or
   pyControl present. See `docs/power.md`.
5. Whether screw terminals are acceptable for the motor and encoder harnesses, or
   whether a locking 4-pos motor connector must be sourced. Confined to `J5`.
6. Which breakout the lab deploys, and which port is assigned to this board.
7. Whether `D3`, the pyControl 5 V ORing branch, is populated. Gated on measuring
   the port's 5 V budget; the footprint goes down either way.
8. Board outline, mounting, and enclosure constraints. `../mouse-joysticks-mech`
   describes the **two**-joystick assembly, so a single-axis board's mechanical
   envelope is not derivable from it without a decision about how two of these
   boards mount in the rig.

Items 1 through 4 can stop a fabrication order. Everything else can be resolved
during layout.

**Resolved by the rescope:** the DAC8563 `VIH` question, whether `AUX_ANALOG_OUT`
gets a populated BNC, and the InstrumentPort cable and mounting arrangement — all
now rev 1 decisions. See `docs/encoder-analog-output.md` and
`docs/instrument-strategy.md`, both of which remain valid for rev 1.

**Not on this list:** the `HV_IN` TVS. `SMBJ40A` is worth ordering, but the
stocked `SMF48A` builds a working first board, so it never blocks a fab order.

## First Schematic Pass

Once the parts above are settled, in this order:

1. Insert `rp2040`.
2. Insert `rp2040_gpio_isolation_sn74cb3q3245`. Wire the A side of all 29
   allocated GPIOs; leave the B side of the 12 reserved channels unconnected.
   Route the four bypass signals directly to the MCU and leave their channels
   unused.
3. Insert `hv_input_36V_terminal_2pos_5p08_protected`, `hv_to_5v_tpsm365r6`, and
   `5v_to_3v3_tps73733`. **Decide the pre-/post-switch feed point immediately**,
   put the bulk capacitance downstream of the switch, and add the ORing diodes at
   the `TPS73733` input — not at `+5V`. Confirm exactly one `PWR_FLAG` per input
   net; the 36 V block and the `usb2` block each carry one already.
4. Insert `tmc5130`. Change both sense resistors from the block default 0.12 Ω to
   **0.15 Ω** (`OW-PASS-RLH12FTCR150`). Record `vsense = 1` and `IRUN = 28`
   alongside. Confirm `VCC` is fed from the external `+5V` rail. Land the motor
   coils on `OW-CONN-1844236`.
5. Insert `usb2`. It now carries `USBLC6-2P6` ESD protection and a shell-to-GND
   tie; confirm both are present in the placed copy.
6. Draw the encoder input: `OW-CONN-1844249` → filtering and ESD → TMC5130A
   `ENCA`/`ENCB`/`ENCN`. No MCU connection.
7. Draw `limit_switch_debounced_input`: `OW-CONN-1844210` → `MAX6816` → `REFL`
   and `GP18`, plus a `REFL` test pad.
8. Draw the pyControl RJ-45 boundary: pins 1, 2, 4 with series resistors and ESD,
   pin 6 footprint for the ORing branch.
9. Add test points for the Rev 0 test-point list in `docs/interface-map.md`.

Run per-block ERC as you go:
`kicad-cli sch erc --severity-error <block>.kicad_sch` with
`ORB_WEAVER_KICAD_LIBS` set. Expect only `pin_not_connected`, `pin_not_driven`,
and `power_pin_not_driven` on an isolated fragment; anything else is a real
defect.

## What Rev 1 Adds

Written down now so Rev 0 does not foreclose it. All of it lands on pins Rev 0
already allocated and left unconnected:

| Addition | Pins | Blocks |
| --- | --- | --- |
| DAC8563 analog angle output + dual BNC | `GP10`-`GP13`, `GP17` | `dac8563_analog_output`, new |
| PIO encoder cross-check | `GP14`-`GP16` | tap off the existing encoder nets |
| pyControl TTL event lines + two dual BNCs | `GP20`, `GP22`, `GP23` | `pycontrol_event_bnc_group`, new |
| InstrumentPort-40 + five buffers | `GP24` | `instrument_port_40_dut_ffc_boundary`, `instrumentation_signal_buffer_sn74lvc125a` ×5 |

Nothing in that table requires moving a Rev 0 pin, changing a Rev 0 connector, or
rewriting Rev 0 firmware. That is the property the Rev 0 allocation was built to
have; see `docs/interface-map.md`.
