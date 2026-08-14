# UART Application Protocol

**Rev 0 scope:** the protocol is unchanged, with one hardware-imposed gap. The
`ENCODER_MISMATCH` fault compares the TMC5130A's encoder count against an
independent RP2040 PIO count, and Rev 0 routes the encoder to the driver only.
The fault code stays reserved and is not raisable until rev 1 adds the PIO tap on
`GP14`-`GP16`. Encoder integrity in Rev 0 rests on the driver's count and the
index pulse.

**Status:** Draft v0.1. Not implemented, not frozen.
**Date:** 2026-08-12
**Derived from:** `../mouse-joysticks-pcb/docs/uart-protocol.md` v0.3, with the
axis argument removed.
**Ownership:** This project owns the application protocol. `board-interfaces`
owns the physical port profile.
**Transport:** 115200 8N1, newline-terminated, over RJ-45 pins 1 and 4. See
`docs/pycontrol-port-pinout.md`.

## Align With The Lab's Existing Idiom

The syringe pump at `~/Repositories/github/syringe-pump` is a working pyControl
peripheral in this lab, documented against pyControl v2.1.1. This draft adopts
its framing conventions rather than inventing a parallel style:

| Convention | Syringe pump | Adopted here |
| --- | --- | --- |
| Field delimiter | `;` | `;` |
| Terminator | `\n` | `\n` |
| Baud | 115200 8N1 | 115200 8N1 |
| Verb position | first field | first field |
| Device parse | `msg.split(";")` | same |
| Host receive | `UART_handler` + `UART.IRQ_RXIDLE` | same |

**Where this draft deliberately differs:** the syringe pump has no sequence
numbers and no acknowledgements, which is reasonable for a request/response
dispenser. This board drives a motor against an animal under a safety heartbeat,
so it keeps sequence numbers, explicit `ack`/`nak`, and a fault model. The
framing is shared; the reliability model is stricter.

## No Axis Argument

The twin-axis protocol carries an axis field — `L`, `R`, or `B` — in every
command, and a matching field in every event. This board has one axis, so that
field is **absent**, not defaulted.

Keep the field order such that adding it back is a clean insertion after the
verb, in case this protocol is ever carried to the twin board:

```text
this board:  VERB;seq[;arg...]
twin board:  VERB;axis;seq[;arg...]
```

A device class written for one will not silently work with the other, which is
correct. `ID` reports a protocol version and an axis count so a host can tell
which it is talking to and refuse rather than guess.

## Framing

```text
command:  VERB;seq[;arg...]        \n
reply:    ack;seq[;data...]        \n
          nak;seq;reason           \n
event:    ev;EVENT;t_us[;key=value...] \n
```

Concrete examples:

```text
moveto;417;-12.5      -> ack;417
home;418              -> ack;418
cal;419;get           -> ack;419;enc_offset=1024;angle_zero=0.0
movetoo;420;-12.5     -> nak;420;badverb
moveto;421;-999       -> nak;421;outofrange
ev;PULL;18420102;angle=-3.1
ev;FAULT;18599112;code=2;detail=over_travel
```

- `seq` — decimal, wraps at 65535. The board echoes it. A repeated `seq` with
  identical content is treated as a retransmission and re-acknowledged without
  re-executing.
- Fields are `;`-separated. No embedded `;` or newline in values.
- Malformed or over-length lines produce `nak;<seq or ?>;badframe` and are
  otherwise discarded.
- Line ending is `\n`. A leading `\r` is tolerated and ignored.
- Keep the device's receive buffer at least as large as the longest command plus
  margin. The syringe pump's host side uses `rxbuf=130`; size the device side to
  match or exceed the longest line this protocol can produce.

Open decision: whether to add a checksum. This cable runs next to motor leads.
Recommendation is a two-hex-digit CRC-8 as a final field, with the host allowed
to omit it during manual terminal debugging. The syringe pump has no checksum, so
adding one is a deliberate divergence — justify it with a measured error rate on
the real cable rather than by assumption.

## Design Rules

- Newline-terminated ASCII. Human-readable at a serial terminal, greppable in a
  log, and decodable from a logic-analyzer capture without a custom plugin.
- Commands are **bounded**. There is no "set PWM" or "step N times" verb.
  Anything that could produce unbounded motion is not in the command set.
- Commands are acknowledged with the sequence number they carried, so a lost
  reply is detectable.
- Events are asynchronous and carry a local timestamp.
- Latency-critical events also assert a TTL line. The UART message is the
  description; the line is the timestamp.
- The board never requires a message in order to become safe.

## Message Rate

One axis roughly halves the message rate versus the twin board, which relieves
the pyControl constraint that task code runs on the MicroPython board and should
not poll at high rates. Two boards on two ports restores the total, but spreads
it across two links and two handlers.

Still:

- Do not stream per-sample angle over this link. That is what the board's own
  high-rate stream and `RSYNC` alignment are for.
- Keep the heartbeat rate as low as the safety timeout allows.
- Measure the achieved round-trip and event-message latency during Gate C rather
  than assuming the link is comfortable.

## Commands

| Verb | Args | Reply | Notes |
| --- | --- | --- | --- |
| `ID` | — | hw rev, **board serial**, fw version, protocol version, axis count, capabilities, buffer state | Must work before `ARM` and must never fail |
| `PING` | — | `ack` | Heartbeat; resets the host-loss watchdog |
| `STATUS` | — | state, angle, position, homed flag, limit state, fault mask | Safe at any time |
| `LIMITS` | — | configured travel, velocity, acceleration, current bounds | Reports what the board will enforce |
| `HOME` | `[timeout_ms]` | `ack` then `!HOMED` | Bounded travel and timeout, enforced locally |
| `ARM` | — | `ack` | Required before motion; refused if not homed or if faulted |
| `DISARM` | — | `ack` | Always permitted |
| `MOVETO` | `deg [profile]` | `ack` then `!TARGET` | Absolute; rejected outside travel limits |
| `MOVE` | `deg [profile]` | `ack` then `!TARGET` | Relative; rejected if the result is outside limits |
| `STOP` | — | `ack` | Controlled stop; always permitted |
| `ARMPULL` | `threshold` | `ack` | Arms pull detection; `!PULL` and the TTL line follow |
| `ANGOUT` | `ON`/`OFF` | `ack` | Enables the 0-5 V analog output |
| `ANGSCALE` | `deg_lo deg_hi` | `ack` | Maps the angle range onto 0-5 V |
| `FAULTS` | — | fault mask with per-bit detail | Readable while faulted |
| `CLRFAULT` | — | `ack` or `nak;latched` | Clears only clearable faults whose cause has gone |
| `CAL` | `get` / `set k v` | calibration values | Encoder offset, angle zero, travel limits |
| `INSTR` | `ON`/`OFF`/`STATE` | `ack` / state | Instrumentation buffer output enable |
| `HV` | `ON`/`OFF`/`STATE` | `ack` / state | Motor rail high-side switch, see `docs/power.md` |

Deliberately absent, and to stay absent: any verb that sets raw driver current,
raw PWM, a step count, or a velocity without a bounded destination.

`ID` reports the **board serial**. With two interchangeable single-axis boards in
a rig, the serial is how a task confirms it is talking to the board whose
calibration matches the joystick in front of it. Do not omit it.

`HV` exists because the 36 V input block's `ENABLE` is pulled low and the rail is
genuinely off at boot. It is a state the host can observe and should not have to
infer.

## Events

| Event | Keys | TTL line | Notes |
| --- | --- | --- | --- |
| `READY` | `fw`, `proto`, `serial` | — | Once after boot; host should reconnect and re-`ID` |
| `HOMED` | `t`, `angle` | — | |
| `TARGET` | `t`, `angle` | — | UART only; motion completion is not latency-critical |
| `PULL` | `t`, `angle` | `PULL_EVENT` | |
| `LIMIT` | `t` | — | Limit asserted outside homing |
| `FAULT` | `t`, `code`, `detail` | `FAULT` | Latched; motion already stopped before this is sent |
| `RSYNC` | `t`, `n` | — | Local timestamp and sample index of an `RSYNC` edge |

`t` is the board's local microsecond counter. It is not pyControl time;
alignment happens in post-processing via `RSYNC`.

**With two boards there are two local clocks.** Each board's stream is
internally coherent; cross-joystick ordering is a post-processing question
answered through the `RSYNC` edges both boards record. Record the alignment
uncertainty rather than assuming it is negligible — this is the cost the twin
board's shared timebase avoids.

## State Machine

```text
BOOT ──> IDLE ──HOME──> HOMED ──ARM──> ARMED ──motion──> ACTIVE
                                          ^                 |
                                          +─────completed────+
fault/STOP ──> FAULTED ──CLRFAULT──> IDLE
heartbeat loss, host reset, cable removal ──> FAULTED
```

- `BOOT` leaves the motor rail off (`HV_EN` low), the driver disabled, and emits
  `READY`.
- Motion verbs are refused outside `ARMED`.
- `FAULTED` is entered without host cooperation and exited only through
  `CLRFAULT`, and only for faults whose cause has cleared.

## Fault Codes

A bitmask, so several faults can be present at once.

| Bit | Code | Cause |
| --- | --- | --- |
| 0 | `HOST_TIMEOUT` | Heartbeat not received within the timeout |
| 1 | `DRIVER_FAULT` | TMC5130A `DIAG0` or `DIAG1` asserted |
| 2 | `OVER_TRAVEL` | Commanded or measured position outside travel limits |
| 3 | `HOME_TIMEOUT` | Homing exceeded its bound |
| 4 | `ENCODER_MISMATCH` | TMC5130A count and PIO count diverged beyond tolerance |
| 5 | `LIMIT_UNEXPECTED` | Limit switch asserted during normal motion |
| 6 | `SUPPLY_OUT_OF_RANGE` | Motor supply outside the accepted window, from `HV_SNS`, or `~{HV_FAULT}` asserted by the input switch — overload, short circuit, or its thermal shutdown |
| 7 | `INTERNAL` | Firmware assertion or self-test failure, including CHOPCONF `vsense != 1` |
| 8 | `EXT_STOP` | External fault input asserted, if the cross-board fault line is fitted |

Bit 7 is where the `vsense = 1` read-back check reports. See `docs/rev0-plan.md`
— with 0.15 Ω installed, `vsense = 0` drives ~1.8× the motor's rated current, and
`vsense = 0` is the chip's reset default.

Bit 8 is reserved whether or not the cross-board `FAULT` interconnect is fitted;
see `docs/pycontrol-interface.md`.

Reserve bits 9 onward. If this design is ever extended with a brake and a torque
sensor, their faults go there.

## Versioning

`ID` reports a protocol version and an axis count. The pyControl device class
must refuse to operate against an incompatible major version rather than
guessing. The axis count is what distinguishes this board from a twin-axis board
on the same link — do not let the class infer it from the product name.

## Host Simulator

Provide a host-side simulator or protocol fixture so both this firmware and the
pyControl device class can be tested before real hardware and a real pyControl
installation are both available.

Gate C must cover malformed, duplicated, delayed, dropped, and out-of-order
input, and must verify that timeouts and faults recover only through declared
paths. Add:

- an unrecognized verb is rejected, never partially executed;
- a repeated `seq` with identical content is re-acknowledged without re-executing;
- two simulator instances on two links do not interfere, which is the two-board
  case.
