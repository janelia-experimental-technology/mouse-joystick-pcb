# Mouse Joystick PCB Rev 0 Plan

**Status:** Rescoped 2026-08-13, InstrumentPort added back 2026-08-16;
**schematic capture complete and ERC-clean 2026-08-17** — 0 violations at every
severity, 142 components. Layout not started.
**Date:** 2026-08-17
**Purpose:** Get a manufacturable single-axis board designed and ordered as fast
as possible, so the researcher can **exercise the interfaces** — motor, encoder,
limit switch, and the pyControl serial link — while the twin-axis form factor is
still being decided.

## Rescoped 2026-08-13

Rev 0 was cut down to shorten the path to testable hardware. The board no longer
carries the analog encoder-angle output or the pyControl TTL event lines. It
carries the interfaces, the means to observe them, and nothing else.

The purpose changed with it. The earlier plan aimed at a board the researcher
could run experiments against. **This one aims at a board that proves the
interfaces work**, and defers everything whose value only appears once
experiments start.

| Moved out of Rev 0 | Returns in |
| --- | --- |
| DAC80501 0-3.3 V analog angle output and its BNC | rev 1 |
| `PULL_EVENT`, `FAULT`, `RSYNC` and their BNCs | rev 1 |
| Electronic brake, torque sensor, extra analog outputs | rev 2+ |
| Synthetic homing stimulus (`TMC_REF_STIM`) | **never** — dropped permanently |

### The InstrumentPort Came Back, 2026-08-16

It was in the table above until 2026-08-16, deferred on the grounds that six of
its eighteen digital slots carried signals Rev 0 does not have. That reasoning
was partly wrong — the encoder nets exist in Rev 0, they just do not reach the
MCU — and it weighed the wrong thing. **The port's Rev 0 value is firmware
development, not experiments:** seeing the pyControl link at the cable and the
TMC5130A SPI bus in one capture is what makes protocol and driver bring-up
tractable, and that value is highest exactly when the board is new.

Rev 0 populates `J1501`, buffer packages `U1601`, `U1701`, and `U1801`, and
**eleven of the eighteen digital Strands**. The other seven are allocated and
unrouted, four of them reserved for the rev 2 brake and torque sensor so those
circuits do not have to renegotiate the pinout.

**The buffer grouping as built is not the documented one, and that is accepted.**
`U1601` carries `ENC_A`, `ENC_B`, `PYC_UART_RX`, `PYC_UART_TX`; `U1701` the four
TMC SPI signals; `U1801` `LIMIT_SW`, `FW_TRIG0`, `FW_TRIG1`, and one spare
channel whose input is grounded. The property that matters — no buffer input
floats — holds. The cost is that the grouping mixes domains, so the rev 2 swap
touches two packages instead of one.

`ENC_A`, `ENC_B`, and `LIMIT_SW` borrow three of those reserved slots until rev 2. Rev 0 has no
cross-check at all — the encoder never reaches the MCU — so the TMC5130A's
`X_ENC` register is the only encoder count on the board; capturing the raw edges beside the SPI reads of that register is the
only way to confirm the driver is decoding correctly. The same applies to homing:
with no `GP18` copy either, `LIMIT_SW` on the port is the only witness that the
switch closed when the driver says it did. All three sit in the rev 2 package's
slots, so they survive rev 1 and are evicted as late as possible. Full allocation and reasoning in `docs/interface-map.md`.

**This costs schedule.** It adds a 40-pin FFC, **three** buffer packages, five
board-level termination resistors (`R1104`-`R1601`), and eighteen more routed
nets to a board whose layout was already the long pole — see
`.agents/handoff.local.md`. It is the researcher's call whether that is worth a
slip; the design record's job is to say plainly that it is a slip.
**Corrected 2026-08-17**; this said "five buffer footprints of which three are
populated" and "four pull-down resistors". Only three packages were ever drawn,
and the terminations came out at 10 kΩ rather than the 100 kΩ pull-downs
originally specified — see `docs/design-block-map.md`, "Board-Level Terminations".

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
- One single-ended encoder on a 5-pin terminal, read by the **TMC5130A only** —
  it reaches no GPIO in any revision.
- One limit switch on a 2-pin terminal through a hardware debouncer, to the
  TMC5130A `REFL` input **only** — it reaches no GPIO.
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
| 28 of 30 GPIOs, reached only after cutting encoder index, `DIAG1`, homing stimulus, and DAC `~LDAC`/`~CLR` | 24 of 30 at full scope with six spares; **18 of 30 in Rev 0**. The DAC `~LDAC`/`~CLR` pins cost nothing to give up here — the part chosen on 2026-08-26 does not have them |
| Event-line routing is an open blocking question: 4 lines, no home | Deferred entirely in Rev 0; 3 lines and 4 BNCs when it returns |
| Layout zoning across two motor sections, two encoder paths, two analog outputs | One motor section, one encoder path, no analog output |
| Axis symmetry is a first-class layout and scientific constraint | Not applicable |
| Two motors' supply current, doubled bulk and protection | One motor |
| Two of every harness and connector | **Seven connectors in Rev 0** — `J201` 36 V, `J301` USB-C, `J1101` analog BNC, `J1102` motor, `J1103` encoder, `J1301` limit switch, `J1501` InstrumentPort FFC, `J1901` pyControl RJ-45 |

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
- Boot access. `SW501` BOOTSEL is fitted.
- **Debug console over USB CDC.** `UART0` is committed to pyControl, and in Rev 0
  USB CDC is the only rich observation path on the board.
- Stable 3.3 V logic rail.
- `UART0` pyControl, `SPI0` TMC5130A. `SPI1` and PIO0 are unallocated in Rev 0
  but their pins are reserved.

**The SWD header and the `RUN` connection are deferred to a future board
revision. Reversed 2026-08-17**; the list above said "Boot and reset access, SWD
header", and the `rp2040` block description still names `RUN` and `SWD` among
what it provides. As built, `RUN` (pin 26) and `SWCLK`/`SWD` (pins 24, 25) are
unconnected and no-connect-flagged, **by explicit decision on 2026-08-17**, not
by oversight.

This is an **access limitation, not an electrical defect**. RP2040 `RUN` has an
internal 50-80 kΩ pull-up and the datasheet permits leaving it open or tying it
to `IOVDD`, so the part comes out of reset on its own; what is missing is a way
to force a reset without power-cycling, and a way to attach a debug probe.
Rev 0's development path is BOOTSEL plus USB CDC, which is why the trade was
judged acceptable for a bench board. Restore both in the revision that adds the
DAC — a hard reset and a probe are worth more once there is firmware complex
enough to hang.

Full allocation in `docs/interface-map.md`.

## GPIO Isolation

`orb_weaver_private:rp2040_gpio_isolation_sn74cb3q3245`, one instance: four
`SN74CB3Q3245` 8-channel bidirectional FET bus switches, 32 channels, one shared
active-low `~OE` with a pull-up.

**The rule is the far end's power domain:** a GPIO goes through the switch if and
only if what it connects to loses power when `HV_EN` drops. That is what stops
the MCU back-powering a chip it just switched off, which is the board's normal
idle state rather than an edge case.

- **Isolated in Rev 0 — 7 channels:** the TMC5130A SPI bus, enable, and
  diagnostics (`GP2`-`GP8`). **Ten** at full scope, with the rev 1 DAC bus
  (**revised 2026-08-26** from twelve; the DAC needs three wires, not five).
  As built, six of the seven are on `U601` and the seventh (`TMC_DIAG1`) is on
  `U602`; **`U603` and `U604` carry nothing at all**, and at ten channels of
  thirty-two placed they never will.
- **Bypassed:** the pyControl UART above all, plus `~{BUS_SW_EN}`, `HV_EN`,
  `HV_DIAG_EN`, `HV_SNS`, `~{HV_FAULT}`, `SW_RAIL_SENSE`, and both `FW_TRIG`
  markers. Nothing at those far ends is ever unpowered by `HV_EN`. Per-signal
  rationale in `docs/interface-map.md`.
- Wire the **A side of all 12 isolated GPIOs now**, including those reserved for
  rev 1, so a later revision adds board-side wiring only. **Not done.** Only the
  seven Rev 0 channels are wired; every unused channel has its A pin open and its
  **B (MCU-side) pin tied to GND**, so the rev 1 DAC channels are not pre-wired
  and rev 1 must edit this block regardless.
- **Sequencing:** isolate before dropping `HV_EN`, and reconnect only after
  `SW_RAIL_SENSE` confirms `+3.3V_SW` is up. Both it and `HV_EN` bypass, so
  firmware can do this with the bus isolated.
- **A side is the TMC/switched side, B side is the MCU side.** Inverted from
  `docs/interface-map.md`; the board is the authority, and the part is a
  symmetric FET pass gate so it works either way.

**Decided 2026-08-13: place the proven block whole.** Four `SN74CB3Q3245`
packages isolate 30 GPIOs and this board needs 12, so two packages and their
decoupling are dead weight — and as built they are literally empty, not merely
under-used. Accepted deliberately — schedule beats parts count for Rev 0, and the
block is already placed and proven. Revisit in a later revision if board area
gets tight, and decide what to do with `U603`/`U604` before layout.

**The block runs from `+3.3V_MCU`, which diverges from its own part note.** The
note says to power it from the switched target-domain rail so `Ioff` provides
isolation at `VCC` = 0. Here isolation is a firmware property instead, defaulting
safe because `R601` 7.87 kΩ pulls `~{BUS_SW_EN}` high at reset. Deliberate; see
`docs/design-block-map.md`.

Proven on `tmc51x0-driver-dev-pcb`, which bypasses the same *kind* of control
group — but bypasses far fewer signals, because it has no two-domain power tree.

## Driver Section

One instance of `orb_weaver_private:tmc5130`, composed twice into
`tmc51x0-driver-dev-pcb` with board ERC at zero.

- TMC5130A-TA (`OW-PWR-TMC5130A-TA-T`), verified official symbol and footprint.
  Annotated `U1201`.
- Strapped and routed for SPI operation: `SWSEL` and `SD_MODE` to GND, `SPI_MODE`
  left on its internal pull-up. Bring the `SWSEL` strap to a pad.
- `DIAG0` and `DIAG1` both routed to the MCU — this board has the pins. Both are
  open-drain and get 10 kΩ pull-ups to `+3.3V_SW` (`R1101`/`R1102`), as the
  datasheet's ≤47 kΩ requires.
- `ENCN` is unused and terminated by `R1201` 10 kΩ to GND; `REFR` and `AIN_IREF`
  are no-connects. `VSA` is fed from `+5V_SW` rather than `VS`, a deliberate
  deviation that keeps 36 V off the analog supply.
- `DRV_ENN` pulled to the disabled state so the driver is off before firmware
  configures it, and behind the bus switch so it stays that way.
- The block includes a 16 MHz oscillator and the charge-pump and `5VOUT`
  decoupling.
- Motor connector: **4-pos 3.5 mm terminal, `OW-CONN-1844236`**, stocked.

### Current Sense — Decided, Inherited

Same motor, same answer as the twin-axis board. Do not re-derive it.

> **Corrected 2026-09-08. The motor rating below was an assumption and it was
> wrong.** The motor was identified on hardware 2026-09-02 as a Lin Engineering
> **WO-208-13-01D** — NEMA 08, 1.8°/step, 4-lead bipolar, **0.6 A/phase**,
> 6.5 Ω/phase, 3 oz-in — which is the very part *Open Decisions* item 1 below
> explicitly ruled out. `R_SENSE` and `vsense` are unaffected and stay as
> tabulated; **`IRUN` changes from 28 to 17**. `docs/bringup-log.md` owns the
> finding. **Lin does not state whether 0.6 A is RMS or peak**, so two readings
> exist and firmware enforces the conservative one:
>
> - **Peak-of-sine reading (conservative, in force): 0.424 A RMS target → `IRUN` 17.**
> - Equal-heating reading: 0.600 A RMS target → `IRUN` 24-25.
>
> Settling it needs a coil-current measurement and a motor case temperature. That
> can be taken on v0.2 hardware — the motor and driver path are unchanged.

Motor rating: **0.6 A per phase** (`WO-208-13-01D`), RMS-or-peak unstated by the
vendor; the conservative peak-of-sine reading gives a **0.424 A RMS** target.

| Item | Value |
| --- | --- |
| `R_SENSE` | **0.15 Ω**, both coils — 2 positions |
| Part | `OW-PASS-RLH12FTCR150`, JLCPCB `C2683383` |
| Package / rating | 1206, 1 W, ±1%, ±100 ppm/°C |
| `vsense` (CHOPCONF bit 17) | **1** — high sensitivity, `V_FS` = 180 mV |
| `IRUN` | **17** → 0.421 A RMS (−0.7% of the 0.424 A conservative target) |
| `IRUN`, equal-heating reading if the thermal measurement supports it | 24 → 0.585 A, or 25 → 0.608 A |
| Ceiling at CS 31 | 0.749 A — **1.25× the 0.6 A rating**, and a hardware limit once `vsense` = 1 is latched |
| Peak sense voltage at IRUN 17 | 101 mV across `R_SENSE` + 20 mΩ; 89 mV across the 0.15 Ω itself |
| Peak dissipation at IRUN 17 | 53 mW = 5.3% of 1 W |
| Peak dissipation at IRUN 25 | 111 mW = 11% of 1 W |

Derived from TMC5130A rev 1.21 chapter 10:

```
I_RMS = (CS+1)/32 × V_FS/(R_SENSE + 20 mΩ) × 1/√2
```

**The `tmc5130` design block ships 0.12 Ω as its default sense value.** Change
both positions to 0.15 Ω when the block is placed, and check the placed value
before ERC rather than after fabrication.

**Done — and it is now the one place where the board diverges from `kicad-libs`,
deliberately.** `R1203`/`R1204` are 0.15 Ω on this board; `kicad-libs` ships
0.12 Ω. Thirteen of the fourteen placed block copies are byte-identical to their
sources and this is the exception, with **the board being the correct one**.

> **Resolved 2026-09-08 — do not "fix the library down to 0.15 Ω".** That earlier
> instruction is reversed. The library keeps **0.12 Ω as a deliberate
> placeholder**, because the correct shunt is a property of the *motor* rather
> than the driver, so each placing board sizes it. **The rule for this board is
> simply: never re-place `tmc5130`**, which is also why v1.0 leaves that block
> alone entirely. If it ever is re-placed, both resistors revert and — with
> firmware writing `IRUN` 17 — the coils would see **0.511 A RMS, +21.4%** over
> intent, silently: no ERC, no DRC, no fault bit. The old "roughly 25% over the
> intended 0.679 A RMS" was wrong twice; 0.679 A was never the intent.

See `docs/design-block-map.md`.

### `vsense = 1` Is A Firmware Dependency

Unchanged, and Rev 0's reduced scope does not reduce this hazard at all.

| `vsense` | Current at IRUN 17 | Ceiling at CS 31 |
| --- | --- | --- |
| **1 (required)** | 0.421 A | 0.749 A |
| 0 (chip reset default) | **0.760 A** | **1.35 A** |

Leaving `vsense = 0` with 0.15 Ω installed drives **1.80× the conservative target
and 1.27× even the equal-heating reading** — and note 0.760 A exceeds the
`vsense` = 1 ceiling of 0.749 A, so the wrong bit defeats the hardware limit
outright. *(Updated 2026-09-08 for `IRUN` 17; at the old `IRUN` 28 these were
1.23 A and roughly 1.8× a target that was itself wrong.)* Requirements:

- Firmware sets `vsense = 1` before ever raising `DRV_ENN`.
- Firmware reads CHOPCONF back and refuses to enable the driver unless
  `vsense = 1` is confirmed, raising an `INTERNAL` fault instead.
- Silkscreen the shunt group with its value and note the `vsense = 1`
  requirement on the board and in the bring-up log.
- Gate D measures actual coil current, not commanded `IRUN`.

Once `vsense = 1` is set the configuration is self-limiting: the ceiling at
CS 31 is 0.749 A, **25% above the 0.6 A rating** (and 1.78× the conservative
0.424 A target). The hazard is confined to that one register bit. *(Was "12%
above" against the wrong 0.67 A figure; corrected 2026-09-08.)*

## Encoder

**Rev 0 decides single-ended, and it is a design block now.**
`quadrature_encoder_input_5v_sn74lvc2g17` was built in `kicad-libs` and placed on
2026-08-17, so this section is no longer board-local glue. **Reversed
2026-08-17**; this paragraph read "`A`, `B`, and `N` route from a 5-pos 3.5 mm
terminal (`OW-CONN-1844249`, stocked) directly to the TMC5130A
`ENCA`/`ENCB`/`ENCN` pins with local filtering and ESD protection".

Three of those words are wrong as built. There is **no `N`** — `J1103` pin 2 is a
reserved index no-connect, there is no `ENC_N` net, and the TMC's `ENCN` is
terminated by `R1201` 10 kΩ to GND, which is what the datasheet asks for on an
unused pin. There is **no ESD device** anywhere in the encoder path. And nothing
routes **directly**: the chain is `J1103` → `R801`/`R802` 100 kΩ pull-downs →
`R803`/`R804` 4.7 kΩ → `C802`/`C803` 470 pF → `U801` `SN74LVC2G17` dual Schmitt on
**`+3.3V_SW`** → `R805`/`R806` 100 kΩ → `ENC_A`/`ENC_B`.

`J1103` is 5-position: pin 1 GND, pin 2 reserved index no-connect, pin 3
`ENC_A_RAW`, pin 4 `+5V_SW`, pin 5 `ENC_B_RAW`.

**The 5 V-encoder-against-3.3 V-inputs problem is solved in hardware.** `U801`
runs from `+3.3V_SW`, so it takes the 5 V swing and re-emits 3.3 V logic before
anything reaches the TMC's `VCC_IO`-referenced inputs or the always-on
instrumentation buffers.

`differential_encoder_receiver` is **not placed in Rev 0**. If the chosen encoder
turns out to be RS-422, that block exists and is proven three times on
`tmc51x0-driver-dev-pcb`, but fitting it is a rev 1 change and the connector
conductor count changes with it.

**The encoder does not reach the MCU, in any revision.** Decided 2026-08-16;
`GP14`/`GP15`/`GP16` went back to the spare pool and the PIO cross-check was
deleted rather than deferred. **`GP14` did not stay spare** — it was taken on
2026-08-17 for `HV_DIAG_EN`. The consequence is unchanged: `ENCODER_MISMATCH` has
nothing to compare and is never implementable; encoder integrity rests on the
driver's count. It no longer rests on the index pulse either, since there is not
one.

**Still open, and still the decision that can invalidate the board:** the encoder
part number, and therefore the supply voltage and whether single-ended survives
contact with the real device. The previous-generation rig used a Broadcom
`HEDR-5421-EP111`. Two things the placed block now has a stake in that answer:
the 100 kΩ **pull-downs** assume a **push-pull** 5 V encoder and become pull-ups
for an open-collector part, and the 4.7 kΩ + 470 pF filter is a 72 kHz corner
(τ = 2.2 µs) that must clear the encoder's maximum output frequency. The pin
order of `J1103` depends on the answer too.

## Limit Switch And Homing

A **new design block**, `limit_switch_debounced_input`, one instance. It owns the
connector as well as the conditioning, which is what makes the limit switch
independent of the encoder harness:

| Element | Part |
| --- | --- |
| Connector | 2-pos 3.5 mm terminal, `OW-CONN-1844210`, stocked |
| Debouncer | `MAX6816EUS+T`, `OW-MISC-MAX6816EUS-T`, stocked, `orb_weaver_misc:MAX6816` / `orb_weaver_smd:SOT192P237X122-4N` |
| Support | Local decoupling; the MAX6816 supplies its own pull-up and ±15 kV ESD protection |

- Route the debounced output to the TMC5130A `REFL` input only — **not** to any
  GPIO. Tap it to InstrumentPort `DIG11` and a test pad.
  `REFL` is the hardware-latched reference; the MCU copy allows independent state
  reporting and fault detection. As built the connector is `J1301`, the debouncer
  is `U1301`, `DIG11` is live — and **the test pad does not exist**, because no
  test point exists anywhere on the board yet.
- **No synthetic stimulus.** `TMC_REF_STIM` is gone. Bring `REFL` to a labelled
  test pad so a jumper can still force a closure during bring-up. Still owed.
- The always-on instrumentation buffer input on this net is defined by `R1601`
  10 kΩ to GND in `instrument_port`, so it does not float when the switched
  domain is off.
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
| 1 | `DIO-A` | RP2040 `UART0 RX` (`GP1`), with `R403` 10 kΩ pull-up to `+3.3V_MCU` |
| 2 | `GND` | Ground |
| 4 | `DIO-B` | RP2040 `UART0 TX` (`GP0`) |
| 6 | `5V` | **Populated**: `PYC_CONN_5V` → `R1903` → `PYC_5V_FUSED` → `D1901` → `+5V_MCU` |
| 3, 5, 7, 8 | `POW-A`, `SPECIAL`, `POW-B`, `12V` | Not connected |

**Reversed 2026-08-13, built 2026-08-17**; pin 6 was to be a footprint only,
gated on the port's 5 V budget. It is populated, because `+3.3V_MCU` comes from
USB or pyControl and from nowhere else — an unpopulated branch means the board is
dark whenever USB is unplugged. `R1903` is a **polyfuse position holding a 0.36 Ω
jumper**, not protection; see `docs/design-block-map.md`. The connector is
`J1901`.

`R403` exists because the RP2040 resets every GPIO with its internal pull-*down*
enabled, and a UART RX line must idle **high** — without it the port looks like a
permanent break.

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
HV_RAW ─|>|─ HV_IN ─[switch]─ +36V_SW ─┬─> TMC5130A VS
                                       └─> hv_to_5v_tpsm365r6 ─> +5V_SW ─┬─> TMC VCC, encoder
                                                                         └─> 5v_to_3v3 #2 ─> +3.3V_SW ─> TMC VCC_IO, MAX6816, SN74LVC2G17
```

**Always-on domain**, which the switch cannot reach:

```text
USB VBUS ─────────|>|─┬─> +5V_MCU ─> 5v_to_3v3 #1 ─> +3.3V_MCU ─> RP2040, bus switch, buffers, input-block pull-ups
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
- **Putting the bus switch on `+3.3V_SW`.** It would isolate for free via `Ioff`,
  and it would also take the sequencing away from firmware. It goes on
  `+3.3V_MCU`. Note that this is the opposite of what the block's own part note
  recommends; the divergence is deliberate and recorded in
  `docs/design-block-map.md`.

**Fit a TVS on `HV_IN`, not on the motor rail.** At hot-plug the switch is off, so
the exposed parts are the `TPS1HTC100-Q1` (70 V) and the `TPSM365R6V5` (65 V).
`SMBJ40A` preferred; stocked `SMF48A` works for first boards. The TMC5130A at
49 V cannot be protected by any standard TVS at this supply voltage; it relies on
bulk capacitance downstream of the soft-start switch — **tens of µF, not
hundreds** — tight `VS`/`GND` layout, and measurement at Gate B.

**Still owed: no TVS is populated as built.** Related bench item: `C1213`/`C1214`
are 100 µF **50 V** parts on a 36 V rail, 72% of rating, which is acceptable but
leans on the ringing being measured rather than assumed. The `+36V_SW` bulk comes
to roughly 208 µF.

**The input block needs six edits when placed**, two of them functional defects
for this board: the `EN` divider gives only 150 mV of threshold margin from 3.3 V
logic, and `DIAG_EN` left unconnected disables the `SNS` current sense entirely.
Full audit in `docs/power.md`.

**All six are made in the placed copy**, with two revisions to the audit itself.
`ILIM` (`R508`) is 40 kΩ and `SNS` (`R509`) is **249 Ω**, not the 1 kΩ an earlier
note suggested — 1 kΩ would have driven `GP28` past its absolute maximum on a
fault. And `DIAG_EN` (`R502`) goes to **`GP14`**, not to a fixed pull-up:
**Reversed 2026-08-17**; earlier guidance said tie it high. Held high, the
switch's OFF-state open-load detection keeps an internal 150 kΩ pull-up from `VS`
to `VOUT` enabled, trickling ~240 µA into the ~208 µF of `+36V_SW` so the rail
creeps up and the buck hiccups instead of the domain switching cleanly off. That
would break the reset-button property this whole architecture exists for.
Firmware must raise `GP14` before reading `HV_SNS` or `~{HV_FAULT}`; current
limit and thermal shutdown are unaffected either way. Full reasoning in
`docs/design-block-map.md`.

## Blocks To Place

**Fifteen instances, all placed.** Full list and status in
`docs/design-block-map.md`.

| Block | Instances |
| --- | --- |
| `rp2040` | 1 |
| `rp2040_gpio_isolation_sn74cb3q3245` | 1 |
| `hv_input_36V_terminal_2pos_5p08_protected` | 1 |
| `hv_to_5v_tpsm365r6` | 1 |
| `5v_to_3v3_tps73733` | **2** — one per power domain |
| `tmc5130` | 1 |
| `usb2` | 1 |
| `pycontrol_behavior_port_rj45_boundary` | 1 |
| `quadrature_encoder_input_5v_sn74lvc2g17` | 1 |
| `limit_switch_debounced_input` | 1 |
| `instrument_port_40_dut_ffc_boundary` | 1 |
| `instrumentation_signal_buffer_sn74lvc125a` | **3** |

**Two `5v_to_3v3_tps73733` instances**, not one: the two-domain power tree needs
a 3.3 V regulator on each side.

**Corrected 2026-08-17**; this table listed eight instances and named three
"board-local sections that are not blocks: the pyControl RJ-45 boundary, the new
`limit_switch_debounced_input`, and the two-diode OR feeding `+5V_MCU`". Three of
those became blocks — the RJ-45 boundary, the limit switch, and (added since) the
encoder input — and the two-diode OR dissolved entirely: `usb2` emits `+5V_USB`
through its own diode and `pycontrol_behavior_port_rj45_boundary` emits `+5V_PYC`
through `D1901`, so the board only ties them together at `+5V_MCU`. The
InstrumentPort and its three buffers arrived with the 2026-08-16 rescope.

**Nothing in Rev 0 is board-local circuitry any more.** What the board itself
authors is three wrapper sheets — `mcu`, `motor_encoder_limit`, and
`instrument_port` — which hold the block instances and the nine termination
resistors, and nothing else.

## Open Decisions Before Layout Freeze

The rescope resolved or deferred five of the previous ten. What remains, ranked by
what blocks the schedule:

1. ~~**The joystick motor part number.**~~ **Closed 2026-09-02, and this item had
   it backwards.** The motor *is* the previous rig's Lin Engineering
   **`WO-208-13-01D`**, 0.6 A/phase — the part this line explicitly ruled out.
   That wrong exclusion is where the 0.67 A figure above came from. Current sense
   stays 0.15 Ω with `vsense` = 1, but **`IRUN` is 17, not 28**. What remains open
   is only whether 0.6 A is RMS or peak — the vendor does not say — which is the
   `IRUN` 17 versus 24-25 choice and needs a coil current plus a case
   temperature. See `docs/bringup-log.md`.
2. **The encoder part**, which sets the encoder supply voltage, confirms that
   single-ended receive is correct, and now also validates the placed block's
   push-pull assumption, its 72 kHz filter corner, and `J1103`'s pin order. Rev 0
   assumes single-ended.
3. **pyControl pin 6's 5 V current budget**, and whether it is shared across
   ports. It is now load-bearing: with USB unplugged it is the only thing
   powering the board. Measure at Gate A. Pin 6 **is** 5 V — that part is
   confirmed from the reference design's netlist. Related: **`R1903` is a
   polyfuse position holding a 0.36 Ω jumper**; source a 1206 PPTC with a
   250-500 mA hold, or accept the jumper and record it.
4. Whether screw terminals are acceptable for the motor and encoder harnesses, or
   whether a locking 4-pos motor connector must be sourced. Confined to the motor terminal (`J1102` as of 2026-08-27).
5. Which breakout the lab deploys, and which port is assigned to this board.
6. Board outline, mounting, and enclosure constraints. `../mouse-joysticks-mech`
   describes the **two**-joystick assembly, so a single-axis board's mechanical
   envelope is not derivable from it without a decision about how two of these
   boards mount in the rig.

Items 1 through 3 can stop a fabrication order. Everything else can be resolved
during layout.

**Resolved by the rescope:** the DAC `VIH` question, whether `AUX_ANALOG_OUT`
gets a populated BNC, and the InstrumentPort cable and mounting arrangement — all
now rev 1 decisions. See `docs/encoder-analog-output.md` and
`docs/instrument-strategy.md`, both of which remain valid for rev 1.

**`VIH` was then resolved on its merits, 2026-08-26**, rather than merely
deferred: the analog output block was built around a `DAC80501`, whose `VIH` is
1.62 V minimum flat across `VDD` = 2.7-5.5 V, so 3.3 V logic drives it directly
and no level translator is needed. `AUX_ANALOG_OUT` is still open and has become
more expensive — the block is single-channel, so a second output is a second
instance.

**Also resolved:** the oversized GPIO isolation block is accepted as-is.

**Resolved by the two-domain power architecture:** exactly two
`5v_to_3v3_tps73733` instances, one per domain, with no third and no split of
`+3.3V_SW`; the regulator chain is fed **post**-switch; `+3.3V_MCU` comes from USB or pyControl only, with no always-on
converter on `HV_IN`; both ORing diodes are populated rather than one being
conditional; and whether the TMC5130A tolerates `VCC_IO` without `VCC`/`VS` no
longer needs an answer, because all three now fall together. See `docs/power.md`.

**Resolved 2026-08-17, by decision rather than by design:** no SWD header and no
`RUN` connection in Rev 0. Deferred to a future board revision — see "Controller
MCU" above. RP2040 `RUN` has an internal 50-80 kΩ pull-up, so this costs debug
access, not correct start-up.

**Not on this list:** the `HV_IN` TVS. `SMBJ40A` is worth ordering, but the
stocked `SMF48A` builds a working first board, so it never blocks a fab order.

## First Schematic Pass

**Complete as of 2026-08-17**, with steps 7 and 10 taken differently from the
plan. Kept as the record of the intended order and of where reality diverged.

Once the parts above are settled, in this order:

1. Insert `rp2040`.
2. Insert `rp2040_gpio_isolation_sn74cb3q3245`. Wire the A side of all 29
   allocated GPIOs; leave the B side of the 12 reserved channels unconnected.
   Route the four bypass signals directly to the MCU and leave their channels
   unused. **Built differently:** only the seven Rev 0 channels are wired, A is
   the TMC side rather than the MCU side, and unused **B** pins are tied to GND
   rather than left open.
3. Build the **always-on domain first**: the two ORing diodes from USB `VBUS`
   and pyControl pin 6 into `+5V_MCU`, then `5v_to_3v3_tps73733` #1 to
   `+3.3V_MCU`. This is what powers the MCU and the bus switch, so everything
   else depends on it existing. **Both diodes now live inside their own boundary
   blocks**, emitting `+5V_USB` and `+5V_PYC`; the board only joins them.
4. Build the **switched domain**: `hv_input_36V_terminal_2pos_5p08_protected`
   feeding `hv_to_5v_tpsm365r6` from the **switched** `+36V_SW`, then
   `5v_to_3v3_tps73733` #2 to `+3.3V_SW`. Put the bulk capacitance downstream of
   the switch. Confirm exactly one `PWR_FLAG` per input net — the 36 V block and
   the `usb2` block each carry one already; add one for the pyControl 5 V branch,
   and one for `+5V_MCU` itself, which is downstream of both ORing diodes and so
   has no driver without it. **The two 5 V rails must not touch.**
5. Insert `tmc5130`. Change both sense resistors from the block default 0.12 Ω to
   **0.15 Ω** (`OW-PASS-RLH12FTCR150`) — the block default is a deliberate
   per-motor placeholder, so this step is required, not a workaround. Record
   `vsense = 1` and **`IRUN = 17`** alongside *(was 28; corrected 2026-09-08)*.
   Confirm `VCC` is fed from the external `+5V` rail. Land the motor coils on
   `OW-CONN-1844236`.
6. Insert `usb2`. It now carries `USBLC6-2P6` ESD protection and a shell-to-GND
   tie; confirm both are present in the placed copy.
7. Draw the encoder input: `OW-CONN-1844249` → filtering and ESD → TMC5130A
   `ENCA`/`ENCB`/`ENCN`. No MCU connection. **Done as a block instead** —
   `quadrature_encoder_input_5v_sn74lvc2g17`, which owns the connector, and with
   no ESD part and no `ENCN` connection. See "Encoder" above.
8. Draw `limit_switch_debounced_input`: `OW-CONN-1844210` → `MAX6816` → `REFL`
   only, plus `REFL` and `LIMIT_SW` test pads. **Test pads not done.**
9. Draw the pyControl RJ-45 boundary: pins 1, 2, 4 with series resistors and ESD,
   pin 6 footprint for the ORing branch. **Done as a block**, with pin 6
   populated rather than footprint-only.
10. Add test points for the Rev 0 test-point list in `docs/interface-map.md`.
    **Not done. There are no test points anywhere on the board.** This is the
    largest single gap between the plan and the schematic, and it is a layout
    item rather than a schematic one only if the pads are added as footprints.
11. Add the board-level terminations: `R403` on `PYC_UART_RX`, `R1101`-`R1103` in
    `motor_encoder_limit`, `R1104`-`R1601` in `instrument_port`. **Not in the
    original plan**; added 2026-08-17 when it became clear that leaving the
    always-on buffer inputs and the switched-domain control lines undefined was
    not survivable. All nine sit in board-authored wrapper sheets so a block
    re-place cannot lose them. See `docs/design-block-map.md`.

Run per-block ERC as you go:
`kicad-cli sch erc --severity-error <block>.kicad_sch` with
`ORB_WEAVER_KICAD_LIBS` set. Expect only `pin_not_connected`, `pin_not_driven`,
and `power_pin_not_driven` on an isolated fragment; anything else is a real
defect. **Whole-design ERC is at 0 violations at every severity** as of
2026-08-17.

## What Rev 1 Adds

Written down now so Rev 0 does not foreclose it. All of it lands on pins Rev 0
already allocated and left unconnected:

| Addition | Pins | Blocks | InstrumentPort Strands |
| --- | --- | --- | --- |
| DAC80501 analog angle output + BNC | `GP10`, `GP11`, `GP13` | `analog_output_0_3v3_dac80501`, **built 2026-08-26** | `DIG6`, `DIG9`, `DIG10`, `AIN0`; a **fourth** buffer package |
| pyControl TTL event lines + two dual BNCs | `GP20`, `GP22`, ~~`GP23`~~ — **`GP23` was spent on `~{HV_FAULT}` 2026-09-18**, so this needs a third pin from elsewhere or drops to two lines | `pycontrol_event_bnc_group`, new | `DIG13`-`DIG15`; a **fifth** buffer package |
| Brake driver + torque front end (rev 2) | ~4 more — **revised 2026-08-31**, was ~6 | `brake_current_sink_0_49ma_dac80501` (specified, not drawn), `torque_bridge_frontend`, both new | `DIG11` (`BRAKE_CS`, **not** `BRAKE_DIM`), `DIG12`, `AIN1` (`BRAKE_ISENSE`, resolved); **takes `DIG0`/`DIG1` back from the encoder**; re-inputs `U1601` and `U1801` |

Nothing in that table requires moving a Rev 0 pin, changing a Rev 0 connector, or
rewriting Rev 0 firmware. That is the property the Rev 0 allocation was built to
have; see `docs/interface-map.md`.

**Two Rev 0 outcomes did erode that property**, and both are worth knowing before
rev 1 is scoped:

- **The rev 1 buffer packages are new placements, not stuffing changes.** The
  `U_C`/`U_D` footprints this table assumed were never drawn. Board area for them
  has to be reserved deliberately.
- **The rev 1 DAC channels are not pre-wired through the bus switch.** Unused
  channels have their MCU-side pins tied to GND, so rev 1 edits
  `rp2040_gpio_isolation_sn74cb3q3245` regardless. `U603` and `U604` are entirely
  empty and are the obvious home for it.

The pin allocation itself still holds — with the one exception that **`GP14` is
no longer spare**. It carries `HV_DIAG_EN` as of 2026-08-17, so the spare pool is
`GP15`, `GP16`, `GP18`, and `GP27`.
