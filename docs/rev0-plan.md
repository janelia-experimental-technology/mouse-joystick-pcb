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
- A GPIO isolation bus switch between the MCU and the **switched** half of the
  board, isolated at power-on until firmware enables it, so the MCU cannot
  back-power chips it has deliberately switched off.
- Two power domains: a switched one carrying everything resettable, and an
  always-on MCU domain fed from USB or pyControl.
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
2. **A switched domain plus GPIO isolation.** The twin board carries neither.
   Here the high-side switch doubles as a chip-reset mechanism the researcher can
   trigger without unplugging anything, and the bus switch is what makes that safe
   — the MCU survives the reset it performs, on a rail the switch cannot reach.

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

**The rule is the far end's power domain:** a GPIO goes through the switch if and
only if what it connects to loses power when `HV_EN` drops. That is what stops
the MCU back-powering a chip it just switched off, which is the board's normal
idle state rather than an edge case.

- **Isolated in Rev 0 — 8 channels:** the TMC5130A SPI bus, enable, and
  diagnostics (`GP2`-`GP8`), plus the debounced limit-switch copy (`GP18`).
  Full scope reaches 16 with the rev 1 encoder tap and DAC bus.
- **Bypassed:** the pyControl UART above all, plus `~{BUS_SW_OE}`, `HV_EN`,
  `HV_SNS`, `~{HV_FAULT}`, `V5_SENSE`, and both `FW_TRIG` markers. Nothing at
  those far ends is ever unpowered by `HV_EN`. Per-signal rationale in
  `docs/interface-map.md`.
- Wire the **A side of all 16 isolated GPIOs now**, including the 8 reserved for
  rev 1, so a later revision adds board-side wiring only.
- **Sequencing:** isolate before dropping `HV_EN`, and reconnect only after
  `V5_SENSE` confirms `+5V_SW` is up. Both `V5_SENSE` and `HV_EN` bypass, so
  firmware can do this with the bus isolated.

**Decided 2026-08-13: place the proven block whole.** Four `SN74CB3Q3245`
packages isolate 30 GPIOs and this board needs 16, so two packages and their
decoupling are dead weight. Accepted deliberately — schedule beats parts count
for Rev 0, and the block is already placed and proven. Revisit in a later
revision if board area gets tight.

Proven on `tmc51x0-driver-dev-pcb`, which bypasses the same *kind* of control
group — but bypasses far fewer signals, because it has no two-domain power tree.

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

## Power — Two Domains

Decided 2026-08-13. **The high-side switch is a reset button**: it lets the
researcher power-cycle every chip on the board to a known state without
unplugging anything, while the MCU stays alive and reachable. Everything else
follows from that. Read `docs/power.md` before drawing the power section.

**Switched domain**, all of it downstream of `HV_EN`:

```text
36 V ─[switch]─ +36V_SW ─┬─> TMC5130A VS
                         └─> hv_to_5v_tpsm365r6 ─> +5V_SW ─┬─> TMC VCC, encoder
                                                           └─> 5v_to_3v3 #2 ─> +3V3_SW ─> TMC VCC_IO, MAX6816
```

**Always-on domain**, which the switch cannot reach:

```text
USB VBUS ─────────|>|─┬─> +5V_MCU ─> 5v_to_3v3 #1 ─> +3V3_MCU ─> RP2040, bus switch, input-block pull-ups
pyControl pin 6 ──|>|─┘
```

Three consequences, all deliberate:

- **Two `5v_to_3v3_tps73733` instances**, one per domain. Not one.
- **Two ORing diodes**, both populated. `OW-MISC-MBR120VLSFT1G` is the stocked
  candidate. pyControl pin 6 **is 5 V** — confirmed from the reference design's
  netlist in `~/Repositories/github/syringe-pump`, where RJ-45 pin 6 is `5VDC`
  and pin 8 is 12 V.
- **The board does not boot on 36 V alone.** It needs USB or pyControl. That is
  accepted, and it should be silkscreened near the terminal block so a board that
  looks dead is not reported as broken.

The two mistakes that still look correct on a schematic:

- **Merging the two 5 V rails.** ORing USB and pyControl onto the rail that feeds
  the TMC would drop it below the 4.6 V `VCC` minimum. The domains keep them
  structurally separate; do not "simplify" them together.
- **Putting the bus switch on `+3V3_SW`.** It would isolate for free via `Ioff`,
  and it would also take the sequencing away from firmware. It goes on
  `+3V3_MCU`.

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

Eight instances in Rev 0. Full list and status in `docs/design-block-map.md`.

| Block | Instances |
| --- | --- |
| `rp2040` | 1 |
| `rp2040_gpio_isolation_sn74cb3q3245` | 1 |
| `hv_input_36V_terminal_2pos_5p08_protected` | 1 |
| `hv_to_5v_tpsm365r6` | 1 |
| `5v_to_3v3_tps73733` | **2** — one per power domain |
| `tmc5130` | 1 |
| `usb2` | 1 |

**Eight instances**, not seven: the two-domain power tree needs a 3.3 V regulator
on each side.

Plus three board-local sections that are not blocks: the pyControl RJ-45
boundary, the new `limit_switch_debounced_input`, and the two-diode OR feeding
`+5V_MCU`.

## Open Decisions Before Layout Freeze

The rescope resolved or deferred five of the previous ten. What remains, ranked by
what blocks the schedule:

1. **The joystick motor part number.** The current sense is already decided
   (0.15 Ω, `vsense = 1`, `IRUN = 28`). Still needed for the supply envelope, the
   `ILIM` resistor, and to confirm whether 0.67 A is RMS or peak. It is **not**
   the previous rig's Lin Engineering `WO-208-13-01D`, which is 0.6 A.
2. **The encoder part**, which sets the encoder supply voltage and confirms that
   single-ended receive is correct. Rev 0 assumes single-ended.
3. **pyControl pin 6's 5 V current budget**, and whether it is shared across
   ports. It is now load-bearing: with USB unplugged it is the only thing
   powering the board. Measure at Gate A. Pin 6 **is** 5 V — that part is
   confirmed from the reference design's netlist.
4. Whether screw terminals are acceptable for the motor and encoder harnesses, or
   whether a locking 4-pos motor connector must be sourced. Confined to `J5`.
5. Which breakout the lab deploys, and which port is assigned to this board.
6. Board outline, mounting, and enclosure constraints. `../mouse-joysticks-mech`
   describes the **two**-joystick assembly, so a single-axis board's mechanical
   envelope is not derivable from it without a decision about how two of these
   boards mount in the rig.

Items 1 through 3 can stop a fabrication order. Everything else can be resolved
during layout.

**Resolved by the rescope:** the DAC8563 `VIH` question, whether `AUX_ANALOG_OUT`
gets a populated BNC, and the InstrumentPort cable and mounting arrangement — all
now rev 1 decisions. See `docs/encoder-analog-output.md` and
`docs/instrument-strategy.md`, both of which remain valid for rev 1.

**Also resolved:** the oversized GPIO isolation block is accepted as-is.

**Resolved by the two-domain power architecture:** exactly two
`5v_to_3v3_tps73733` instances, one per domain, with no third and no split of
`+3V3_SW`; the regulator chain is fed **post**-switch; `+3V3_MCU` comes from USB or pyControl only, with no always-on
converter on `HV_IN`; both ORing diodes are populated rather than one being
conditional; and whether the TMC5130A tolerates `VCC_IO` without `VCC`/`VS` no
longer needs an answer, because all three now fall together. See `docs/power.md`.

**Not on this list:** the `HV_IN` TVS. `SMBJ40A` is worth ordering, but the
stocked `SMF48A` builds a working first board, so it never blocks a fab order.

## First Schematic Pass

Once the parts above are settled, in this order:

1. Insert `rp2040`.
2. Insert `rp2040_gpio_isolation_sn74cb3q3245`. Wire the A side of all 29
   allocated GPIOs; leave the B side of the 12 reserved channels unconnected.
   Route the four bypass signals directly to the MCU and leave their channels
   unused.
3. Build the **always-on domain first**: the two ORing diodes from USB `VBUS`
   and pyControl pin 6 into `+5V_MCU`, then `5v_to_3v3_tps73733` #1 to
   `+3V3_MCU`. This is what powers the MCU and the bus switch, so everything
   else depends on it existing.
4. Build the **switched domain**: `hv_input_36V_terminal_2pos_5p08_protected`
   feeding `hv_to_5v_tpsm365r6` from the **switched** `+36V_SW`, then
   `5v_to_3v3_tps73733` #2 to `+3V3_SW`. Put the bulk capacitance downstream of
   the switch. Confirm exactly one `PWR_FLAG` per input net — the 36 V block and
   the `usb2` block each carry one already; add one for the pyControl 5 V branch.
   **The two 5 V rails must not touch.**
5. Insert `tmc5130`. Change both sense resistors from the block default 0.12 Ω to
   **0.15 Ω** (`OW-PASS-RLH12FTCR150`). Record `vsense = 1` and `IRUN = 28`
   alongside. Confirm `VCC` is fed from the external `+5V` rail. Land the motor
   coils on `OW-CONN-1844236`.
6. Insert `usb2`. It now carries `USBLC6-2P6` ESD protection and a shell-to-GND
   tie; confirm both are present in the placed copy.
7. Draw the encoder input: `OW-CONN-1844249` → filtering and ESD → TMC5130A
   `ENCA`/`ENCB`/`ENCN`. No MCU connection.
8. Draw `limit_switch_debounced_input`: `OW-CONN-1844210` → `MAX6816` → `REFL`
   and `GP18`, plus a `REFL` test pad.
9. Draw the pyControl RJ-45 boundary: pins 1, 2, 4 with series resistors and ESD,
   pin 6 footprint for the ORing branch.
10. Add test points for the Rev 0 test-point list in `docs/interface-map.md`.

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
