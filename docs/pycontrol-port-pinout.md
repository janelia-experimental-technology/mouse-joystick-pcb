# pyControl Behavior Port Pinout

**Rev 0 scope:** the pinout below is unchanged and remains the reference, but Rev
0 populates pins 1, 2, and 4 only — `DIO-A` to `UART0 RX`, `GND`, `DIO-B` to
`UART0 TX` — plus an unpopulated footprint for the pin 6 `5V` ORing branch.

**Status:** Derived from a working pyControl-compatible module schematic.
Bench verification still required.
**Date:** 2026-08-12
**Derived from:** `../mouse-joysticks-pcb/docs/pycontrol-port-pinout.md`. The
pinout is a property of pyControl, not of either board, so it is identical in
both repositories. **If it changes, change it in both.**
**Destined for:** `board-interfaces`, once bench-verified.

## Source

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

This is a **cited** source, not a bench measurement. It is strong evidence — a
shipping design with a matching device class — but the pin numbering was read out
of a schematic symbol, so confirm continuity on real hardware before trusting it
with a populated board. That is Gate B.

## Pinout

From the `RJ45_pyControl` symbol pin definitions:

| RJ-45 pin | Signal name | Notes |
| --- | --- | --- |
| 1 | `DIO-A` | Digital I/O A |
| 2 | `GND` | Ground |
| 3 | `POW-A` | Power driver line A |
| 4 | `DIO-B` | Digital I/O B |
| 5 | `SPECIAL` | Special-function pin |
| 6 | `5V` | 5 V supply from pyControl |
| 7 | `POW-B` | Power driver line B |
| 8 | `12V` | 12 V supply from pyControl |

## How The Syringe Pump Uses It

Traced through the module schematic's nets. The net names are written from
**pyControl's** point of view.

| RJ-45 pin | Signal | Net in module | Direction | Used |
| --- | --- | --- | --- | --- |
| 1 | `DIO-A` | `pyControl_TX` | pyControl → device | **yes — serial RX at the device** |
| 2 | `GND` | `GND` | — | **yes** |
| 3 | `POW-A` | — | — | no |
| 4 | `DIO-B` | `pyControl_RX` | device → pyControl | **yes — serial TX at the device** |
| 5 | `SPECIAL` | — | — | no |
| 6 | `5V` | `5VDC` | pyControl → device | **yes** |
| 7 | `POW-B` | — | — | no |
| 8 | `12V` | `Vmotor` | pyControl → device | **yes — motor power** |

So the UART is **DIO-A and DIO-B**, pins 1 and 4:

- **Pin 1 `DIO-A`** carries pyControl's transmit. On this board it is the
  **RP2040 `UART0 RX`**, `GP1`.
- **Pin 4 `DIO-B`** carries pyControl's receive. On this board it is the
  **RP2040 `UART0 TX`**, `GP0`.

Confidence note: the mapping was confirmed by cross-checking that RJ-45 pin 2,
named `GND` in the symbol, lands on a `power:GND` symbol in the schematic. That
anchors the pin ordering rather than relying on symbol geometry alone.

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

**Consequence for a two-board rig.** Three or four UART-capable ports means two
single-axis boards both fit, with one or two ports left over. UART availability
is therefore not an argument against the two-board form factor. Total I/O across
the whole rig still is — see `docs/relationship-to-twin-axis-board.md`.

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
3. `SPECIAL`, `POW-A`, `POW-B` on the assigned port. Unused by the syringe pump.
   `POW-A`/`POW-B` are power-driver outputs, not logic, so probably not. Needs
   authoritative confirmation; do not assume.

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

The syringe pump module uses:

| Field | Value |
| --- | --- |
| MPN | `PJ012-8P8C1` |
| Manufacturer | On Shore Technology |
| Description | Vertical RJ-45, through-hole |
| DigiKey | 6566534 |
| Footprint used | `asl_footprints:RJ45_TH_Vertical_PJ012` |

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

Bench items this source cannot settle:

- Continuity and orientation against real hardware and a real cable.
- Whether the cable is straight-through or crossover, and what happens if the
  wrong one is used.
- DIO logic level, drive strength, and 5 V tolerance.
- Startup and reset state of every line.
- Port 5 V and 12 V current budgets, and the shared regulator limit.
- BNC count, direction configurability, and whether six lines are available.
- Grounding topology between pyControl, this board, and the rig frame.
- Digital-input debounce behavior and how to disable it for clean edges.
- `RSYNC` output electrical characteristics and pulse timing, and whether one
  `RSYNC` output can drive two boards' inputs.

That last item is specific to the two-board form factor: confirm the breakout can
fan `RSYNC` out to both boards, or plan a passive splitter, before assuming both
boards see the same edges.

## Promotion

Once bench-verified, the reusable physical and electrical profile belongs in
`board-interfaces`, alongside `instrument-port-40.md`, with this file reduced to
a reference to it. Do not create a `pycontrol_behavior_port_rj45_boundary` design
block in `kicad-libs` until that promotion happens.
