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
**Date:** 2026-08-14
**Derived from:** `../mouse-joysticks-pcb/docs/pycontrol-port-pinout.md`. The
pinout is a property of pyControl, not of either board, so it is identical in
both repositories. **If it changes, change it in both.** The 2026-08-14 findings
below are not yet mirrored there.
**Destined for:** `board-interfaces`, once bench-verified.

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

| Breakout board | UART-capable ports |
| --- | --- |
| Breakout board 1.2 | ports **1, 3, 4** |
| D-series Breakout Board 1.6 | ports **8, 10, 11, 12** |
| **H7 breakout (10 ports)** | **unknown — see below** |

**The H7 breakout is a third design and neither list covers it.** It has ten
ports, and which of them pyControl exposes as a UART cannot be read out of the
netlist: every port's `DIO-A`/`DIO-B` reaches an STM32H743 GPIO, and UART
capability depends on the H743's alternate-function mapping *and* on what
pyControl's firmware chooses to instantiate. Deriving it from LQFP-100 pin
numbers alone would be a guess.

**So "which port is assigned" is still an open item if the lab deploys the H7
breakout**, and it is a firmware question for the pyControl discussion thread,
not something the schematic can settle. It does not block fabrication — this
board's end of the link is the same on any port.

**Consequence for a two-board rig.** On the 1.2 and 1.6 breakouts, three or four
UART-capable ports means two single-axis boards both fit with one or two left
over. The H7 breakout's ten ports make this comfortably easier if even a few are
UART-capable. UART availability is therefore not an argument against the
two-board form factor. Total I/O across the whole rig still is — see
`docs/relationship-to-twin-axis-board.md`.

Confirm which breakout the lab deploys and which ports are assigned, and record
it. The device class asserts on this:

```python
assert port.UART is not None, "! Pump needs port with UART."
```

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
- **Which H7 breakout ports expose a UART**, if that is the deployed controller.
  A firmware question, not a schematic one.
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
