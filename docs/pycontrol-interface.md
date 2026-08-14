# pyControl Interface

**Rev 0 scope:** the serial link, plus pin 6's 5 V as one of the two sources that
power the board at all. Neither the UART nor the 5 V branch passes through the
GPIO isolation switch, so **the board stays reachable over pyControl with USB
unplugged and the motor rail switched off** — that is a deliberate property of the
power architecture, not an accident. See `docs/power.md`.

Otherwise: the serial link only. `PULL_EVENT`, `FAULT`, and `RSYNC` and
their BNCs are deferred to rev 1, so Rev 0 has **no hardware-timed event or fault
path** — every event is a UART line with UART latency. Fine for exercising the
interfaces, not fine for behavioral data, and that is the boundary between Rev 0
and rev 1. The cross-board `EXT_FAULT_IN` discussion below is also rev 1: Rev 0
has no `FAULT` output to cross-wire.

**Status:** Pinout and serial parameters established from a cited working design;
electrical properties unverified.
**Date:** 2026-08-12
**Companion:** `docs/pycontrol-port-pinout.md` holds the established pinout, UART
parameters, and UART-capable port list. Read that first; this file covers how
this board uses them.
**Derived from:** `../mouse-joysticks-pcb/docs/pycontrol-interface.md`
**Gate:** Must reach a resolved state to pass Gate A in `docs/validation-plan.md`.

## The Rule

`RJ-45` names a connector family, not an interface. It establishes nothing about
pin numbering, orientation, cable wiring, voltage, current limits, startup state,
or allowed signal use.

pyControl's behavior-port cabling is a Cat5/RJ-45 wiring convention, **not
Ethernet networking**. There is no PHY, no magnetics, and no MAC. Do not place
Ethernet magnetics, and do not let anyone describe this as an Ethernet port in a
design review.

Nothing here may be treated as verified until it cites the authoritative document
for the deployed hardware revision, or a bench measurement.

## One UART Per Board, One Board Per Joystick

This board is a single-axis peripheral. There is no axis argument in the
protocol, no axis field in events, and no cross-axis policy.

A two-board rig therefore consumes:

| | Two single-axis boards | One twin-axis board |
| --- | --- | --- |
| Behavior ports | 2 | 1 |
| UART links | 2 | 1 |
| TTL signal lines | 6 | 4 |
| Instruments to see both axes | 2 | 1 |

That comparison is the cost of this form factor, recorded in full in
`docs/relationship-to-twin-axis-board.md`. It is accepted here in exchange for
schedule.

## Signal Set

| Signal | Direction | Electrical | Where |
| --- | --- | --- | --- |
| `UART_TX` | board → pyControl | 3.3 V TTL, 115200 8N1, newline-framed | RJ-45 pin 4 `DIO-B` |
| `UART_RX` | pyControl → board | 3.3 V TTL, 115200 8N1, newline-framed | RJ-45 pin 1 `DIO-A` |
| `PULL_EVENT` | board → pyControl | clean TTL pulse | BNC |
| `FAULT` | board → pyControl | latched TTL | BNC |
| `RSYNC` | pyControl → board | TTL edges | BNC |
| `GND` | shared | — | RJ-45 pin 2, BNC shells |

Rules:

- Event lines exist because pyControl timestamps edges with lower latency than it
  can parse a UART message. Anything latency-critical is a line; anything
  descriptive is a message. `TARGET_REACHED` is a message, not a line.
- Configure pyControl digital inputs for these lines with debounce disabled;
  they are clean electrical edges, not mechanical switches.
- **Keep motor power off this connector.** The board runs a 36 V rail the port
  does not supply, and stepper current must not share a bundle with the UART
  carrying the safety heartbeat.
- Add series resistors and ESD protection on every port signal.
- Define behavior for every connection order: board powered first, pyControl
  powered first, cable inserted live, cable removed live.

## Two Boards Is A Software Question Too

The syringe pump's device class shape:

```python
from machine import UART
from devices.uart_handler import UART_handler

class PumpController:
    def __init__(self, port, event_name, pybv1=True):
        assert port.UART is not None, "! Pump needs port with UART."
        self.uart = UART(port.UART)
        self.uart.init(115200, bits=8, parity=None, stop=1, timeout=100, rxbuf=130)
        handler = UART_handler(event_name)
        self.uart.irq(trigger=UART.IRQ_RXIDLE, handler=handler.ISR)
```

For this board the natural idiom is direct — one device object per board, which
is exactly what the template does:

```python
left  = MouseJoystick(port=board.port_1, event_name="joystick_L",
                      pull_pin=board.BNC_1, fault_pin=board.BNC_2)
right = MouseJoystick(port=board.port_3, event_name="joystick_R",
                      pull_pin=board.BNC_3, fault_pin=board.BNC_4)

hw.left.home()
hw.right.move_to(-10.0)
```

**This is the one place the two-board form factor is simpler in software.** The
twin board has to answer whether one pyControl device class can present two axes
cleanly, or whether the natural idiom is two axis objects sharing one transport —
an open question in that repository. Here the answer is the template's answer,
unmodified.

Two things to verify anyway:

- Two instances of the same device class on two ports must not collide on event
  names or on the `UART_handler` registration. Give each instance a distinct
  `event_name`.
- Both instances must receive the same `RSYNC` edges. See the fan-out question in
  `docs/pycontrol-port-pinout.md`.

Tasks should read at experiment altitude, not pin altitude.

## Gate A Verification Checklist

Every row needs a status of `verified`, `cited`, or `unknown`, plus the source.

| Item | Status | Source |
| --- | --- | --- |
| RJ-45 pin assignment | **cited** | `syringe-pump/ecad/module_pycontrol.kicad_sch` |
| Which pins carry the UART (1 = pyControl TX, 4 = pyControl RX) | **cited** | same schematic, net trace |
| UART parameters (115200 8N1, newline, `;`-delimited) | **cited** | `pump_controller.py`, `basic-firmware/code.py` |
| Which ports expose a UART | **cited** | `syringe-pump/mkdocs/src/software.md` |
| Number of DIO lines per behavior port (two) | **cited** | port pin assignment |
| Native custom-device mechanism | **cited** | `pump_controller.py` uses `devices/` + `UART_handler` + `UART.IRQ_RXIDLE` |
| Exact pyControl controller model and hardware revision | unknown | |
| Which breakout the lab actually deploys | unknown | |
| Port designations assigned to the two boards | unknown | |
| BNC count and direction configurability — **six lines needed** | unknown | |
| Whether one `RSYNC` output can drive two boards | unknown | |
| Connector gender and orientation on both ends | unknown | |
| Cable wiring: straight-through or crossover | unknown | |
| DIO logic level, tolerance, and drive strength | unknown | |
| Whether DIO lines are 5 V tolerant | unknown | |
| Port +5 V current budget | unknown | |
| Shared regulator limit across all ports | unknown | |
| `SPECIAL` pin behavior, and whether it can serve as a TTL line | unknown | |
| Startup and reset state of every line | unknown | |
| Grounding topology, and whether isolation is needed | unknown | |
| Digital-input debounce behavior and how to disable it | unknown | |
| `RSYNC` output electrical characteristics and pulse timing | unknown | |
| Two device-class instances coexist without event-name collision | unknown | |

Everything marked **cited** comes from a shipping pyControl-compatible design,
which is strong evidence but not a bench measurement. Confirm continuity, levels,
and startup state on real hardware at Gate B.

Design for 3.3 V signaling unless level shifting or isolation is deliberately
added.

## Heartbeat And Safe State

The board requires a periodic host heartbeat over UART. On timeout it stops
motion, latches a fault, asserts `FAULT`, and drops `HV_EN`.

This is deliberately independent of pyControl. A task that crashes, a USB cable
that is unplugged, or a host that is put to sleep must not leave the motor
energized against a mouse. The board is the last line of defense, so its safe
state must not require a message to arrive.

**With two boards, a heartbeat failure stops one joystick, not both.** That is
this form factor's genuine safety advantage over the twin board — and also its
genuine hazard, because a half-stopped rig is a state the twin board cannot
enter.

**Decide explicitly what happens to the other joystick.** Options:

1. pyControl's task detects the fault event and stops the other board. Simple,
   but it depends on host cooperation, which is exactly what the local safe state
   exists to avoid depending on.
2. Cross-wire the two boards' `FAULT` lines so either board's fault reaches the
   other as an external stop input. This board has three ADC-capable spare GPIOs;
   spending one on an `EXT_FAULT_IN` input is cheap and does not depend on the
   host. **Recommended if the rig runs two boards.**
3. Accept single-axis degradation, with the resulting data explicitly marked.
   Only as a reviewed scientific choice.

If option 2 is chosen, decide it **before layout** — it adds a connector pin, and
retrofitting it means a flying wire on a rig board.

## Calibration Boundary

Per-rig parameters — encoder offset, angle zero, travel limits — are stored on
the board and reported to pyControl at run start.

With one board per joystick, each board holds exactly one calibration set, which
removes the twin board's risk of silently applying one axis' calibration to the
other. In exchange it introduces a new one: **a board swapped between joysticks
carries the wrong calibration with it.** Record the board serial against the
joystick it is calibrated for, and have the board report its serial in `ID` so
the task can check.

pyControl-facing values the experimenter should change per setup belong in
pyControl hardware variables instead.

## Open Questions

- Which port designations carry the two joystick UARTs, and is that recorded
  anywhere the lab can see it?
- Does the deployed pyControl version's UART handler generate a framework event
  on message receipt, or must the task poll?
- Are there six usable BNC lines on the deployed breakout?
- Can one `RSYNC` output drive two boards' inputs?
- Cross-board fault propagation: host-mediated, hard-wired, or none?
- Should the two boards' grounds be tied at the pyControl controller, at the rig
  frame, or isolated? With two boards this is a ground-loop question that the
  twin board does not have.
- Does the rig need a physical emergency-disable independent of both pyControl
  and this firmware? With two boards it must cover both.

## Promotion

Once verified, the reusable physical and electrical pyControl connector profile
belongs in `board-interfaces`, not here. This repository documents only how this
board uses that profile.
