# pyControl Behavior Port Pinout

**Rev 0 scope:** the pinout below is unchanged and remains the reference. Rev 0
populates pins 1, 2, 4, **and 6** — `DIO-A` to `UART0 RX`, `GND`, `DIO-B` to
`UART0 TX`, and the 5 V into the MCU domain's ORing diode.

**Pin 6 is load-bearing, not optional.** The board's MCU rail comes from USB
`VBUS` or pyControl pin 6 and from nowhere else, so with USB unplugged pin 6 is
the only thing keeping the board alive. **Confirmed 5 V, not 3.3 V, on two
independent designs** — the syringe-pump module and the pyControl H7 breakout.
The voltage is no longer a single-source claim.

**Its current budget is now known at the source and is a shared 1.0 A** — see
[The Port 5 V Supply](#the-port-5-v-supply-and-what-shares-it), which also
explains why this board should fuse its pin 6 branch. What remains unmeasured is
the controller's own draw, and therefore how much of that 1.0 A is actually
spare.

**Status:** Pinout derived from two pyControl-compatible schematics — a shipping
module and the controller breakout itself. Bench verification still required for
continuity and cable behavior.
**Date:** 2026-08-14, amended 2026-08-28.
**Derived from:** `../mouse-joysticks-pcb/docs/pycontrol-port-pinout.md`. The
pinout is a property of pyControl, not of either board, so it is identical in
both repositories. **If it changes, change it in both.** The 2026-08-14 and
2026-08-28 findings are mirrored there.
**Destined for:** `board-interfaces`, once bench-verified.
**Partially promoted 2026-08-28.** The *controller-side capability map* — which
MCU pin each port's `DIO-A`/`DIO-B`/`DIO-C` reaches on Breakout 1.0, Breakout 1.2
and the H7 breakout, and the alternate functions that follow — now lives in
`../board-interfaces/docs/pycontrol-behavior-port.md`. It went early because it
is datasheet- and vendor-source-derived and makes no claim about our physical
link. **The connector profile in this file is still not promoted** and still
waits on Gate B.

## Sources

### 1. The syringe pump module — the device side

`~/Repositories/github/syringe-pump` — a multi-axis syringe pump that ships a
pyControl module and is documented as working with pyControl v2.1.1.

| Artifact | Path |
| --- | --- |
| Module schematic | `ecad/module_pycontrol.kicad_sch` |
| RJ-45 symbol | `asl_symbols_new:RJ45_pyControl` (embedded in that schematic) |
| Module PCB | `ecad/module_pycontrol.kicad_pcb` |
| pyControl device class | `mkdocs/src/software/pycontrol/pump_controller.py` |
| Device firmware UART handling | `software/basic-firmware/code.py` |
| Port/UART documentation | `mkdocs/src/software.md` |
| Connector part | `mkdocs/src/controller.md` |

### 2. The pyControl H7 breakout — the controller side

`~/Repositories/github/pycontrol-h7-breakout`, PCB v0.7 (`pcb/h7_breakout.kicad_sch`),
an STM32H743VIT6 breakout with **10 RJ-45 behavior ports**. Traced by netlist
export on 2026-08-14.

This is the more valuable of the two, because it is the **host** side of the
connector rather than another peripheral. It independently confirms the pin
assignment, and it is the only source that shows what actually supplies pin 6.

Note it is a **work in progress** — its README links an open pyControl
discussion — so treat it as the current intent of the platform rather than as a
frozen standard.

Both are **cited** sources, not bench measurements. Together they are strong
evidence: a host design and a shipping peripheral that agree. But the pin
numbering was read out of schematics, so confirm continuity on real hardware
before trusting it with a populated board. That is Gate B.

## Pinout

Agreed by both sources. The `Signal name` column is the `RJ45_pyControl` symbol's
naming; the `H7 breakout` column is what that pin actually lands on in the
controller.

| RJ-45 pin | Signal name | H7 breakout net | What it really is |
| --- | --- | --- | --- |
| 1 | `DIO-A` | `/N_A` → MCU GPIO | Digital I/O A, direct to the STM32 |
| 2 | `GND` | `GND` | Ground |
| 3 | `POW-A` | `/N_PA` → `TBD62083APG` | **Low-side sink driver output**, not logic |
| 4 | `DIO-B` | `/N_B` → MCU GPIO | Digital I/O B, direct to the STM32 |
| 5 | ~~`SPECIAL`~~ | `/N_C` **or** `/N_PC` | **Port-dependent — see below** |
| 6 | `5V` | `+5V` | 5 V supply, **shared 1.0 A across the whole breakout** |
| 7 | `POW-B` | `/N_PB` → `TBD62083APG` | **Low-side sink driver output**, not logic |
| 8 | `12V` | `+12V` | 12 V supply, straight from the barrel input via `SW1` |

### Correction: pin 5 Is Not "`SPECIAL`"

The `RJ45_pyControl` symbol calls pin 5 `SPECIAL`, and that name is a misnomer
that this document previously carried forward. On the H7 breakout pin 5 is one of
two different things depending on the port:

| Ports | Pin 5 | Wired to |
| --- | --- | --- |
| 1, 4, 5, 6, 7, 8, 9, 10 | `DIO-C` | Straight to an STM32 GPIO, with ESD |
| **2, 3** | `POW-C` | A `TBD62083APG` channel — a driver output |

So on eight of ten ports it is a **third digital I/O**, and on two it is a
**power-driver output**. The breakout's README describes ESD protection on
"`DIO_A`, `DIO_B`, and `DIO_C`", which matches.

Two consequences:

- **Rev 0 leaves pin 5 unconnected, which is correct on every port.** Keep it
  that way. Landing anything on it would be safe on a `DIO-C` port and would
  short a driver output on ports 2 or 3.
- **Do not treat pin 5 as a spare digital line** in a later revision without
  knowing the assigned port number. This is the same class of trap as assuming
  every port has a UART.

### Confirmed: `POW-A` and `POW-B` Are Drivers, Not Logic

Previously listed as "probably not logic — needs authoritative confirmation."
**Now confirmed:** pins 3 and 7 land on `TBD62083APG` channels, a low-side
DMOS/Darlington sink array whose common pin sits on `+12V` for inductive
flyback clamping. They sink to ground; they do not source, and they are not
logic-level outputs.

**So the "use `SPECIAL`/`POW-A`/`POW-B` for extra event lines" fallback is dead.**
Strike it from the alternatives list — pins 3 and 7 are sink drivers, and pin 5
is only a DIO on some ports. If more digital lines are needed, use a second
port's `DIO-A`/`DIO-B`, or BNCs.

## How The Syringe Pump Uses It

Traced through the module schematic's nets. The net names are written from
**pyControl's** point of view.

| RJ-45 pin | Signal | Net in module | Direction | Used |
| --- | --- | --- | --- | --- |
| 1 | `DIO-A` | `pyControl_TX` | pyControl → device | **yes — serial RX at the device** |
| 2 | `GND` | `GND` | — | **yes** |
| 3 | `POW-A` | — | — | no |
| 4 | `DIO-B` | `pyControl_RX` | device → pyControl | **yes — serial TX at the device** |
| 5 | `SPECIAL`¹ | — | — | no |
| 6 | `5V` | `5VDC` | pyControl → device | **yes** |
| 7 | `POW-B` | — | — | no |
| 8 | `12V` | `Vmotor` | pyControl → device | **yes — motor power** |

So the UART is **DIO-A and DIO-B**, pins 1 and 4:

- **Pin 1 `DIO-A`** carries pyControl's transmit. On this board it is the
  **RP2040 `UART0 RX`**, `GP1`.
- **Pin 4 `DIO-B`** carries pyControl's receive. On this board it is the
  **RP2040 `UART0 TX`**, `GP0`.

¹ Names in this table are the syringe pump's own, recorded as found. `SPECIAL` is
the symbol's label for pin 5 and is a misnomer — see
[Correction: pin 5 Is Not "`SPECIAL`"](#correction-pin-5-is-not-special).

Confidence note: the mapping was confirmed by cross-checking that RJ-45 pin 2,
named `GND` in the symbol, lands on a `power:GND` symbol in the schematic. That
anchors the pin ordering rather than relying on symbol geometry alone. The H7
breakout independently agrees on all eight positions, which is stronger evidence
than either source alone.

## The Port 5 V Supply, And What Shares It

Traced from the H7 breakout netlist on 2026-08-14. This is the finding that
closes the long-standing "pin 6 current budget" open item at the source, and it
comes with a hazard the earlier write-up did not anticipate.

```text
12 V barrel in ──> SW1 ──> +12V ──┬──> RECOM R-78E5.0-1.0  ──> +5V ──┬──> 10× RJ-45 pin 6
                                  │      (5 V, 1.0 A)                ├──> J8 pin 2 (16-pos terminal block)
                                  ├──> 10× RJ-45 pin 8               └──> U2 AMS1117-3.3 ──> the breakout's
                                  └──> 3× TBD62083APG COM                                    own 3.3 V rail
```

| Element | Part | Rating |
| --- | --- | --- |
| Port 5 V source | `U1`, RECOM `R-78E5.0-1.0` switching module | **5 V, 1.0 A total** |
| Controller 3.3 V source | `U2`, `AMS1117-3.3` linear, **fed from that same `+5V`** | — |
| Per-port protection | **none** | `+5V` runs straight to every pin 6 |

Three things follow, and the third is the one that matters.

1. **The capacity is 1.0 A, shared.** Ten behavior ports, the 16-position
   terminal block's 5 V pin, and the controller's own 3.3 V regulator all draw
   from one `R-78E5.0-1.0`.
2. **The spare fraction is smaller than 1.0 A.** The STM32H743 at 480 MHz, 32 MB
   of QSPI flash, and the indicator LEDs all run off the `AMS1117-3.3`, which is
   **linear** — so every milliamp the controller's 3.3 V rail draws is a
   milliamp off the same 5 V budget. Estimate 200-400 mA, leaving roughly
   **600-800 mA** for ten ports plus the terminal block. That estimate is the
   part still worth measuring; the 1.0 A ceiling is not.
3. **The controller's own logic supply and this board's supply are the same
   rail.** There is no per-port fuse, so a fault or an inrush surge on this board
   pulls against the regulator that keeps the experiment controller alive.

### What That Means For This Board

| Scenario | Draw | Verdict |
| --- | --- | --- |
| One board, pyControl-only | ~100 mA (`docs/power.md`) | Comfortable |
| Two boards, pyControl-only | ~200 mA | Fits, but a quarter to a third of the whole breakout's 5 V budget for two peripherals |
| Either, with a fault or inrush on this board | unbounded | **Can brown out the `AMS1117` and reset pyControl mid-experiment** |

**New requirement: fuse this board's pin 6 branch.** A resettable polyfuse holding
roughly **250-500 mA** on pin 6, **upstream of the ORing diode**, so a fault on
this board cannot take down the controller. It converts "powered from pyControl"
from merely possible into safe.

It fails in the right direction: if the polyfuse trips, the diode simply stops
conducting and the board falls back to USB power, or goes dark if USB is absent.
Nothing is damaged and nothing is back-fed.

**Caveat, checked 2026-08-14: no fuse of any kind is in the `kicad-libs` parts
database** — zero PPTCs, polyfuses, or fuses. This is a new internal part plus a
vendor mapping, so it does not land as a free value change. It should not delay a
fab order: lay out a **1206** footprint and populate a stocked 1206 resistor as a
jumper for Rev 0, then swap in a PPTC with no layout change. The position **must**
be populated, or the pyControl branch is open and the board is dark without USB.
Full treatment in `docs/power.md`.

**Keep USB as the normal power path.** pyControl-only remains what it was
designed for — reaching a board whose switched domain is deliberately off — not
the everyday supply. That was already the architecture's intent; this finding
gives it a second, independent reason.

## Series Resistors And ESD, As The Controller Does It

Worth recording because this board's RJ-45 boundary has to interoperate with it.

| Aspect | H7 breakout | This board |
| --- | --- | --- |
| ESD on `DIO-A`/`DIO-B`/`DIO-C` | `D1213A-04TS-7`, 4-channel array, SOT-23-6 | `USBLC6-2P6` — the stocked equivalent for two lines plus the 5 V rail |
| Series resistance on DIO lines | **none** — the ESD array, then straight to the STM32 pin | **100 Ω recommended** on both UART lines |
| Pin 6 protection | none | polyfuse, per above |

The breakout puts nothing in series on its side, so **this board's series
resistors are the only current limit on the link in either direction.** That is
an argument for fitting them rather than relying on clamp diodes alone, and 100 Ω
is ample at 115200 baud — roughly a 30 ns RC against an 8.7 µs bit.

`D1213A-04TS-7` is not in the `kicad-libs` parts database. Do not add it; the
stocked `USBLC6-2P6` does the same job here. Note its stock is **20 pieces** and
the `usb2` block already consumes one per board, so two per board caps the build
at ten boards.

## UART Parameters

From `pump_controller.py` and the device firmware:

| Parameter | Value |
| --- | --- |
| Baud | **115200** |
| Data bits | 8 |
| Parity | None |
| Stop bits | 1 |
| Framing | newline-terminated ASCII, `;`-delimited fields |
| Host RX buffer | `rxbuf=130` |
| Host timeout | 100 ms |

## Which Ports Have A UART

> The pump must be plugged into a port that has a serial UART.

**Resolved for the H7 breakout on 2026-08-28.** The full controller-side
capability map — which MCU pin every port's `DIO-A`/`DIO-B`/`DIO-C` reaches on
each breakout, and what each of those pins can do — now lives in
`../board-interfaces/docs/pycontrol-behavior-port.md`. Read that before
assigning a port. The summary below is what this board needs.

| Breakout board | UART-capable ports | Evidence |
| --- | --- | --- |
| Breakout board 1.0 | port **1** (`UART4`) | `devices/breakout_1_0.py` |
| Breakout board 1.2 | ports **1** (`UART4`), **3** (`USART1`), **4** (`USART3`) | `devices/breakout_1_2.py` |
| D-series Breakout Board 1.6 | ports **8, 10, 11, 12** | **unverified** — see below |
| **H7 breakout (10 ports)** | **1, 2, 3, 4, 5, 9, 10** — seven of ten | `h7_breakout.kicad_sch` v0.7 |

**The H7 breakout's hardware question is answered; its firmware question is
not.** Its ten ports were traced by netlist export, and the MCU symbol's own pin
names declare the intent: ports 1–5, 9 and 10 land on `USART3`, `UART4`, `UART5`,
`USART6`, `UART7`, `USART1` and `USART2` respectively, with `DIO-A` on TX and
`DIO-B` on RX every time. Ports 7 and 8 are wired as SPI and port 6 as I2C1.

But **there is no `breakout_h7.py`** in `pycontrol/code` at v2.1.1, so pyControl
does not yet declare *any* H7 port as `UART=n`, and a device class that asserts
on `port.UART` will fail there today. That remains a firmware question for the
pyControl discussion thread. It does not block fabrication — this board's end of
the link is identical on every port and every breakout.

**The 1.6 row is carried forward unverified.** That board is not in any local
checkout of `pycontrol-hardware`, `pycontrol-docs`, or `pycontrol-code`. Treat
it as hearsay until a source turns up.

**Consequence for a two-board rig.** Three UART ports on the 1.2 and seven on
the H7 means two single-axis boards fit with room to spare on either. UART
availability is not an argument against the two-board form factor. Total I/O
across the whole rig still is — see
`docs/relationship-to-twin-axis-board.md`.

**Correction, 2026-09-03: on the deployed rig there is no room to spare.** The
paragraph above counts ports in the abstract. Counted against what Rig 1
actually uses, the 1.2's three UART ports are **exactly** enough for two boards
and nothing else, and taking them collides with a reservation. See below.

## Port Assignment On Rig 1 — Assigned 2026-09-03

**Ports 1 (`UART4`) and 4 (`USART3`)** for the two boards, with the reward
solenoid on port 5 and `LaserLickPort` keeping port 3. Port capability was
verified against the live controller rather than inferred; the allocation itself
rests on one change that is requested but not yet confirmed.

**Status of each part of this, stated separately because they are not equally
solid:**

| Claim | Status |
| --- | --- |
| Ports 1, 3, 4 have UARTs; 2, 5, 6 do not | **verified on the controller** 2026-09-03 |
| `UART4`/`USART3`/`USART1` construct at 115200 and take an `IRQ_RXIDLE` handler | **verified on the controller** |
| `LaserLickPort` needs port 3 (I2C + free `DIO_C`) | **cited** — `LaserLickPort/feature-reports/`, 2026-07-15 |
| Reward solenoid moved from `port_4.POW_A` to `port_5.POW_A` | **requested of the researcher 2026-09-03, NOT confirmed** |
| Both links working on ports 1 and 4 | **not attempted** — no board-side protocol firmware exists yet |

**Until the solenoid move is confirmed, port 4 is contested.** A solenoid cable
still in port 4 means the second board's connector is occupied. The symptom
would be a link that never answers, not an error — so check the cable and
`joystick-rig`'s `hardware_definition_joystick.py` before suspecting the
protocol.

`mouse-joystick-firm/pycontrol/hardware_definitions/mouse_joystick_bringup.py`
assigns ports 1 and 4 as of 2026-09-03. Ports 1 and 3 also work electrically and
were the earlier plan; they were given up because port 3 is the one port
`LaserLickPort` cannot do without, and because 1 + 3 exercises `USART1` rather
than the `USART3` that will ship. See [the reallocation](#the-collision-and-the-fix)
below.

### What the controller reports

Read from the connected pyboard itself, not from source:

```
b = Breakout_1_2()
b.port_1.UART = 4     b.port_2.UART = None    b.port_3.UART = 1
b.port_4.UART = 3     b.port_5.UART = None    b.port_6.UART = None
```

Both candidate UARTs were then constructed at 115200 8N1 and accepted an
`IRQ_RXIDLE` handler — the exact sequence `MouseJoystick.__init__` performs:

| Port | Peripheral | Bus | Requested | **Achieved baud** | Error |
| --- | --- | --- | --- | --- | --- |
| 1 | `UART4` | APB1 | 115200 | **115384** | +0.16% |
| 3 | `USART1` | APB2 | 115200 | **115226** | +0.02% |
| 4 | `USART3` | APB1 | 115200 | **115384** | +0.16% |

All three are far inside a UART's tolerance, so **the baud rate is not a
candidate explanation for any framing problem** found later. Recorded because it
is cheap now and unavailable once something is failing.

Note the pattern: `UART4` and `USART3` land on the same divisor because both sit
on APB1, while `USART1` is on APB2 at twice the clock and resolves finer. So the
**ports 1 + 4 pair gives both boards an identical achieved baud**, and ports
1 + 3 does not. The difference is electrically irrelevant, but this project's
premise is that the two stations are interchangeable, and a symmetric pair costs
nothing.

### Why port 4 looks unavailable, and is not

Port 4 has a UART (`USART3`) and is occupied today for a reason that is physical
rather than electrical: **the rig's reward solenoid is driven from
`port_4.POW_A`**, and `POW_A` is pin 3 of the *same eight-pin RJ-45* as
`DIO-A`/`DIO-B`. One port, one connector, one cable. Source:
`joystick-rig/pycontrol/hardware_definitions/hardware_definition_joystick.py`
on branch `source/main`.

That is a cable, not a constraint. The solenoid needs **only a driver line**,
and all six ports have `POW_A` — so it is the one device in the set that can go
anywhere, and it is currently sitting on one of only three UARTs.

**`port_4.DIO_C` is a real constraint, and it is permanent.** That pin is `X6`,
which is `DAC_2` — the live rsync output driving both cameras' Line 3 and OneBox
IO0. Two consequences:

- Rev 0 leaves RJ-45 pin 5 unconnected, which is correct. **A later revision, or
  a bench jig, must never drive or pull pin 5 on port 4**: it would fight the
  rsync DAC and corrupt the alignment fingerprint the whole recording pipeline
  depends on.
- A standard 8-conductor patch cable leaves that conductor as an unterminated
  stub on the rsync net, floating at the board end. Against 25 ms pulses and a
  2.6 V camera input threshold this is negligible; if a run wants to be
  perfectly clean, omit pin 5 in the cable.

### The full allocation this was derived from

`joystick-rig` `source/main`, which the local `main` was 37 lines behind:

| Resource | pyboard pin | Use | Status |
| --- | --- | --- | --- |
| `BNC_1` | `X12` | camera frame trigger, 150 Hz | in use |
| `BNC_2` | `X11` | opto TTL gate → Plexon LD-1 → PlexBright | in use, wired 2026-08-27 |
| `DAC_2` | `X6` | rsync — also `port_4.DIO_C` | in use |
| `port_4.POW_A` | `X8` | reward solenoid | in use |
| `DAC_1` | `X5` | free — also `port_3.DIO_C` | reserved for a port 3 lick sensor |
| `port_3` `DIO_A`/`DIO_B` | `X9`/`X10` | LaserLickPort — **not wired, driver absent** | reserved |
| `port_1` | `X1`/`X2` | nothing | free |

### The collision, and the fix

**Corrected 2026-09-03.** An earlier version of this section reasoned from
`DAC_1` alone and suggested "port 2 or 5" for the solenoid. The real constraint
on the LaserLickPort is stronger, and it names the ports exactly.

**The LaserLickPort needs I2C, not a UART.** It was deliberately converted off
UART — from `LaserLickPort/feature-reports/`, 2026-07-15:

> "Converted the controlled pyControl optical firmware and Python device layer
> **from UART to I2C**. The ATtiny optical package at 0x15 and MPR121 at 0x5A now
> share **port 3 I2C bus 1**, while ATtiny PB1 drives **port 3 `DIO_C`/`X5`** as
> an active-low optical lick event."

So it does not compete with the joysticks for a UART at all. What it needs is a
port with **I2C on `DIO_A`/`DIO_B`** *and* **a free `DIO_C`**. On Breakout 1.2:

- I2C exists only on ports **3** (`I2C1`) and **4** (`I2C2`)
- `DIO_C` exists only on ports **3** (`X5`) and **4** (`X6`)
- **port 4's `DIO_C` is `X6` = `DAC_2` = the live rsync**

**Port 3 is therefore the only port that satisfies both, and the LaserLickPort
cannot move.** Note also that I2C and UART both consume `DIO_A`/`DIO_B`, so a
port serves one or the other, never both — port 3 cannot host a lick port and a
joystick together.

That fixes the whole allocation, because the solenoid is the only device with no
special requirement:

| Port | Device | Uses | Why it must be there |
| --- | --- | --- | --- |
| **1** | joystick board | `UART4` on `DIO_A`/`DIO_B` | one of only three UARTs |
| **2** | — | | spare (keeps its `POW_C`) |
| **3** | LaserLickPort | `I2C1` + `DIO_C` (`X5`) | **only port with I2C and a free `DIO_C`** |
| **4** | joystick board | `USART3` on `DIO_A`/`DIO_B` | the remaining UART |
| **5** | reward solenoid | `POW_A` (`X21`) | needs only a driver line — **move requested 2026-09-03, unconfirmed** |
| **6** | — | | spare, but `DIO_B` is `X11` = `BNC_2` |

**Port 5 specifically**, not 2 or 6: all four of port 5's lines (`Y5`, `Y6`,
`X21`, `X22`) are untouched by anything else in the rig, whereas port 2 has a
third driver line worth preserving and port 6's `DIO_B` is electrically the same
pin as `BNC_2`, the opto TTL gate.

The firmware cost is one line in the rig's hardware definition:

```python
solenoid = Digital_output(pin=board.port_5.POW_A)   # was port_4.POW_A
```

plus moving one cable. Record the port 4 pin 5 rule next to it, so nobody later
adds a `DIO_C` device to that port.

**Requested 2026-09-03; not yet confirmed done.** This edits `joystick-rig`'s
canonical hardware definition, which this repository does not own — so the
change belongs to whoever runs the rig, and this document assumes it rather than
asserting it. Two things to check when it is reported complete:

- `hardware_definition_joystick.py` on `source/main` reads
  `board.port_5.POW_A`, and the rig's pyboard has had that definition
  **re-loaded** — editing the file on disk does not change the board.
- The solenoid still fires. Port 5's `POW_A` is `X21`, a different pyboard pin
  from port 4's `X8`, so this is a real functional change and not a relabelling.

For bench work nothing occupies any port on the bench controller, so ports 1 and
4 can be used immediately — which is the argument for using them from the start
rather than testing on 1 + 3 and migrating later.

**Alternatives checked and rejected.** The pyControl **Port Expander** runs eight
behaviour ports from one, but over I2C — so it competes for exactly the scarce
resource and does not help. The **Port Adapter** is a screw-terminal breakout,
useful for wiring the solenoid to port 5 tidily and irrelevant to the
allocation. Sharing port 3's I2C bus with a further device is electrically
possible (0x15 and 0x5A leave room) but needs a physical bus splitter that
pyControl's one-device-per-RJ-45 model does not provide.

### Also settled: BNC count

The rev-1 requirement is **six** BNC lines (`PULL_EVENT`, `FAULT`, `RSYNC` × two
boards). Breakout 1.2 has **two** BNCs and both are now in use. That is not a
shortfall to discover during integration — see
[Gate A](pycontrol-interface.md#gate-a-verification-checklist).

Confirm which breakout the lab deploys and which ports are assigned, and record
it. The device class asserts on this:

```python
assert port.UART is not None, "! Pump needs port with UART."
```

### What `DIO-A` And `DIO-B` Actually Are

Checked across every port of all three controller designs, with no exceptions on
UART, I2C or SPI:

| Line | RJ-45 pin | Controller role | This board's role |
| --- | --- | --- | --- |
| `DIO-A` | 1 | **TX** / **SCL** / **MOSI** | **RX** |
| `DIO-B` | 4 | **RX** / **SDA** / **MISO** | **TX** |

So on Breakout 1.2 port 3, `DIO-3A` is `X9` = `PB6` = `USART1_TX` **and**
`I2C1_SCL` — the controller's transmit, this board's receive. That is the
concrete case that anchors the rule.

Two traps that follow, both recorded in full in the `board-interfaces` map:

- **Analog input on a 1.2 `DIO` line works only on ports 1 and 6.** Ports 2–5
  sit on `GPIOB` pins 6–13, which have no ADC channel on the STM32F405. Not
  stated anywhere in the pyControl documentation.
- **Breakout 1.2 port 6 `DIO-B` is the same net as `BNC-2`** — both `X11`/`PC4`,
  which also has no serial and no timer at all. Port 6 and `BNC-2` are mutually
  exclusive.

## The DIO Lines Are Consumed By The UART

Both DIO lines on the assigned port are used by the serial link. That port has no
DIO left for TTL event lines.

The syringe pump does not need any — it is a pure request/response device with no
latency-critical events. This board needs three: `PULL_EVENT`, `FAULT`, and
`RSYNC`.

Those three land on BNC connectors on this board and on the pyControl breakout's
BNCs. Verify the breakout's BNC count and whether each is individually
configurable as an input or an output. With two boards in the rig, the
requirement is **six** BNC lines, which is the number to check against the
deployed breakout.

The alternatives, if the BNC count is insufficient:

1. A second behavior port's DIO lines. Two per port, so two ports for four lines.
2. Reduce the event-line count. Merging `FAULT` into the UART is the least bad
   cut, since a fault stops the session anyway and a few milliseconds of message
   latency does not change that. Do not merge `PULL_EVENT` — low latency is the
   entire reason that line exists.
3. ~~`SPECIAL`, `POW-A`, `POW-B` on the assigned port.~~ **Ruled out
   2026-08-14.** Pins 3 and 7 are `TBD62083APG` low-side sink driver outputs, and
   pin 5 is a DIO on only eight of the H7 breakout's ten ports. See the pinout
   corrections above. Use option 1 or BNCs instead.
4. Pin 5 `DIO-C`, **but only on a port that has one**, and only after the port
   assignment is fixed. This is option 1 at half the cost when it applies, and a
   short into a driver output when it does not.

## Motor Power Over The Port

The syringe pump draws `Vmotor` from **pin 8 (12 V)**. That is a real, shipping
precedent for taking motor power through the behavior port.

It does not transfer to this board. This board runs a **36 V** motor rail, which
the port does not supply at all, and a stepper positioning a joystick is a much
larger and more continuous load than a plunger advancing intermittently.

**Keep the external motor supply.** Use the port's 5 V only if a small logic-side
benefit justifies it, and do not put stepper current on a signal cable that
shares a bundle with the UART carrying the safety heartbeat.

## Connector Part

The two reference designs use different jacks, which is itself evidence that the
exact part does not matter:

| | Syringe pump module | H7 breakout (host) |
| --- | --- | --- |
| MPN | `PJ012-8P8C1` | `E5J88-00LJG2-L` |
| Manufacturer | On Shore Technology | — |
| Style | Vertical RJ-45, through-hole | Through-hole, tab on top |
| DigiKey | 6566534 | — |
| Footprint used | `asl_footprints:RJ45_TH_Vertical_PJ012` | `asl_footprints:RJ45_THP_tab_on_top` |

`kicad-libs` stocks two alternatives with existing internal parts:

| Internal part | Description |
| --- | --- |
| `OW-CONN-J1B1211CCD` | RJ-45 jack, right-angle, shielded, with LEDs, local footprint |
| `OW-CONN-438600001` | RJ-45 jack, right-angle, unshielded, official KiCad footprint `Connector_RJ:RJ45_Amphenol_54602-x08_Horizontal` |

Either stocked part is acceptable; matching the syringe pump's exact connector is
not required, only matching the pinout and orientation. **No Ethernet magnetics** —
this is not Ethernet.

Choose vertical versus right-angle from the enclosure, and shielded versus
unshielded from the cable and grounding decision. If shielded, decide explicitly
where the shield ties.

## Remaining Verification

Bench items these sources cannot settle:

- Continuity and orientation against real hardware and a real cable.
- Whether the cable is straight-through or crossover, and what happens if the
  wrong one is used.
- DIO logic level, drive strength, and 5 V tolerance.
- Startup and reset state of every line.
- **The controller's own 5 V draw**, which is what decides how much of the 1.0 A
  is spare. The ceiling itself is now known — see
  [The Port 5 V Supply](#the-port-5-v-supply-and-what-shares-it).
- **Which H7 breakout ports pyControl *firmware* exposes as a UART.** The
  hardware side is resolved — seven of ten ports are routed to a UART, see
  [Which Ports Have A UART](#which-ports-have-a-uart) — but no `breakout_h7.py`
  exists yet, so no port is declared. Firmware question, upstream.
- **The D-series Breakout Board 1.6 UART port list** (8, 10, 11, 12). Carried
  forward from an earlier source; that board is in no local checkout.
- 12 V budget on pin 8. Not used by this board, but it shares `SW1` and the
  barrel input with the 5 V regulator's supply.
- BNC count, direction configurability, and whether six lines are available.
- Grounding topology between pyControl, this board, and the rig frame — now with
  two ground paths per board, pin 2 and the pin 6 return.
- Digital-input debounce behavior and how to disable it for clean edges.
- `RSYNC` output electrical characteristics and pulse timing, and whether one
  `RSYNC` output can drive two boards' inputs.

That last item is specific to the two-board form factor: confirm the breakout can
fan `RSYNC` out to both boards, or plan a passive splitter, before assuming both
boards see the same edges.

**Resolved 2026-08-14 by the H7 breakout netlist**, and no longer bench items:

- Pin 6 is 5 V — now on two independent designs.
- The port 5 V ceiling is 1.0 A, shared across all ports, the terminal block, and
  the controller's own 3.3 V regulator, with no per-port fuse.
- Pins 3 and 7 are sink driver outputs, not logic.
- Pin 5 is `DIO-C` on eight of ten ports and `POW-C` on two.

## Promotion

Once bench-verified, the reusable physical and electrical **profile** belongs in
`board-interfaces`, alongside `instrument-port-40.md`, with this file reduced to
a reference to it. That promotion still waits on Gate B.

**Amended 2026-08-14.** The earlier form of this section also said not to create a
`pycontrol_behavior_port_rj45_boundary` design block in `kicad-libs` until the
profile is promoted. That coupling is now deliberately broken: the block is being
built in `kicad-libs` ahead of bench verification because Rev 0 needs it and
because two independent schematics now agree on the pinout. The block is an
implementation that can be revised; the `board-interfaces` profile is a contract
that should not be published on cited evidence alone. Keep those two decisions
separate.

Record the pinout's provenance in the block's own description so a future reader
knows it was schematic-derived rather than bench-verified.

**Amended 2026-08-28: the capability map went first, and on purpose.**
`../board-interfaces/docs/pycontrol-behavior-port.md` now holds the
controller-side capability map — port → MCU pin → alternate functions, for all
three breakouts. That is a *different kind of claim* from the connector profile
and it was promoted on different evidence: an ST datasheet, pyControl's own
device-definition source, and the controllers' own schematics. None of it
depends on measuring our cable, so Gate B does not gate it.

The connector profile in this file — pin numbering, the 5 V and 12 V rails and
their budgets, ESD and series-resistance conventions, the mechanical part — is
still a claim about a physical link nobody has put a meter on. **It stays here
until Gate B.** Keep the two apart; the reason the capability map could move
early is precisely that it is not the profile.
