# UART Application Protocol

**Rev 0 scope:** the protocol is unchanged, with one hardware-imposed gap. The
`ENCODER_MISMATCH` fault compares the TMC5130A's encoder count against an
independent RP2040 PIO count. **As of 2026-08-16 that second count is never
coming** — the encoder reaches the driver only, in every revision, and
`GP14`-`GP16` have been returned to the spare pool. Retire the fault code rather
than leaving it reserved; see `docs/interface-map.md`, "The Encoder And Limit
Switch Do Not Reach The MCU". Encoder integrity rests on the driver's count and the
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
  identical content **and a state-changing verb** is treated as a retransmission
  and re-acknowledged without re-executing. Reads and heartbeats are always
  re-executed. **Resolved 2026-09-03** — see
  [1. The retransmission rule and the heartbeat](#1-the-retransmission-rule-and-the-heartbeat-resolved-2026-09-03).
- **The retransmission cache holds the last 2 commands**, not an unbounded
  `seq`-keyed history. The case it exists for is "the host retried immediately
  because a reply was lost"; a deep window buys nothing and is the only thing
  that makes `seq` reuse across a wrap reachable.
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
- **The host-loss watchdog is reset by the arrival of any well-formed command,
  not by executing one.** Liveness is a property of the link, so it is decided
  where the frame is received, before dispatch and regardless of whether a
  retransmission cache serves the reply. A frame that fails to parse
  (`badframe`) does **not** reset it: a host with a wedged serial driver
  emitting garbage is not usefully alive and must not hold the safety timeout
  open.
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
| `PING` | — | `ack` | Heartbeat. Carries no data and has no side effect of its own — **any** well-formed command resets the host-loss watchdog, so this is simply the command to send when there is nothing else to say |
| `STATUS` | — | state, angle, position, homed flag, limit state, fault mask | Safe at any time |
| `LIMITS` | — | configured travel, velocity, acceleration, current bounds | Reports what the board will enforce |
| `HOME` | `[timeout_ms]` | `ack` then `!HOMED` | Bounded travel and timeout, enforced locally |
| `ARM` | — | `ack` | Required before motion; refused if not homed or if faulted |
| `DISARM` | — | `ack` | Always permitted |
| `MOVETO` | `deg [profile]` | `ack` then `!TARGET` | Absolute; rejected outside travel limits |
| `MOVE` | `deg [profile]` | `ack` then `!TARGET` | Relative; rejected if the result is outside limits |
| `STOP` | — | `ack` | Controlled stop; always permitted |
| `ARMPULL` | `threshold` | `ack` | Arms pull detection; `!PULL` and the TTL line follow |
| `ANGOUT` | `ON`/`OFF` | `ack` | Enables the 0-3.3 V analog output |
| `ANGSCALE` | `deg_lo deg_hi` | `ack` | Maps the angle range onto 0.05-3.300 V; see below |
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

`ANGSCALE` maps onto **0.05-3.300 V, not 0-3.300 V**, and both ends of that are
deliberate. **Updated 2026-08-26**; the range used to read 0-5 V, changed to
0-3.3 V by the OneBox acquisition contract in
`../kicad-libs/docs/onebox-analog-interface.md`.

- The **top** is a hardware limit: the DAC cannot exceed its own 2.5 V reference,
  so the gain stage cannot exceed 3.300 V. Firmware cannot overshoot it.
- The **bottom** is a hardware limit too, in the other direction: the output
  amplifier sits about 25 mV off ground at light load, so a commanded 0 V is not
  achievable. Starting the valid range at 50 mV keeps **0 V as an out-of-band
  level** meaning unhomed, disarmed, faulted, or unpowered.

**`ANGOUT OFF`, a fault, and a dead switched rail all produce the same 0 V.**
That is intended — one out-of-band level, not three — but it means the analog
signal alone cannot say which. `STATUS` must report the output as invalid in
every one of those cases, because the recorded trace will not.

**Firmware ordering, not a protocol matter but easy to get wrong here:** the
DAC's `GAIN` register must be written to `0x0101` before the first data write.
Its reset value selects a 0-5 V span, and until that write lands a full-scale
code drives roughly 4.85 V into whatever is on the BNC. `ANGOUT ON` is the
natural place to enforce it.

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
| 4 | `ENCODER_MISMATCH` | **Retired 2026-08-16** — there is no second count. Leave the bit permanently reserved so no later fault reuses it |
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

---

# Open Questions From The First Implementation

**Added 2026-09-02.** Raised by implementing both ends of this draft in
`../mouse-joystick-firm/pycontrol/` — the codec, a host simulator, a pyControl
device class and a 22-case conformance corpus, 128 host tests passing. Nothing
above this line has been changed. This section records what the draft does not
answer, so the command table can be revised deliberately rather than by whoever
implements it next.

Full detail, and the eleven smaller gaps that were filled to make the thing run,
in `../mouse-joystick-firm/pycontrol/README.md`.

## 1. The retransmission rule and the heartbeat — RESOLVED 2026-09-03

### The problem

"A repeated `seq` with identical content is treated as a retransmission and
re-acknowledged without re-executing" assumes re-execution is the harm. That is
true of `MOVE`, which would move the joystick twice. It was false of `PING`,
whose side effect **was** the command — under the original draft it had no result
other than resetting the host-loss watchdog, so serving it from cache let the
safety timeout expire while the host believed it was being answered.

**The failure was likelier than the draft argued.** The draft reached for a
65536 `seq` wrap, which a bounded cache makes unreachable. The ordinary case is
worse: the host sends `PING`, the board executes and resets, the *reply* is
lost, the host retries, and the retry is served from cache without resetting.
Repeat — which is exactly what a degraded link produces — and no retry in the
burst resets the watchdog. The watchdog then stops measuring host liveness and
starts measuring "did the first ping of a retry burst get through", diverging
most when the link is worst. The board faults while the host is receiving acks
and believes all is well, and it presents as a hardware fault.

### The decision

**This was a layering error, not a caching policy problem.** The watchdog
measures host liveness, and liveness is proven by a frame *arriving*, not by a
frame executing. Putting the reset inside `PING`'s handler placed a link-layer
fact behind an application-layer decision, after which any rule about whether
handlers run became a safety rule by accident.

Two changes, in order of importance:

1. **The watchdog is reset on receipt of any well-formed command**, before
   dispatch, cache hit or miss. Recorded as a design rule above. `PING` is no
   longer special, and the retransmission rule needs no exceptions. A `STATUS`
   poll now proves liveness, which it did not before. `badframe` does not reset
   it.

2. **The cache is restricted to state-changing commands.** Not because `PING`
   forced it, but because re-execution of a read is better than replay of one: a
   retried `STATUS` returning fresh state beats a stale one; a retried
   `CLRFAULT` re-evaluates whether the cause has gone, where a cached "cleared"
   could mask a fault latched since; a retried `STOP` is safer executed than
   acknowledged.

Deliberately *not* chosen: exempting `PING` by name. It leaves the category
error in place and invites a table of exceptions, one per verb, each of which is
a safety decision in disguise.

### Classifying a command

**Classify the parsed command, not the verb name.** Three verbs are dual-mode
and a verb-name table gets all three wrong:

| Read — re-executed, never cached | State-changing — cached |
| --- | --- |
| `ID`, `PING`, `STATUS`, `LIMITS`, `FAULTS` | `HOME`, `ARM`, `DISARM`, `MOVETO`, `MOVE`, `STOP`, `ARMPULL`, `ANGOUT`, `ANGSCALE`, `CLRFAULT` |
| `CAL get` | `CAL set k v` |
| `INSTR STATE` | `INSTR ON` / `INSTR OFF` |
| `HV STATE` | `HV ON` / `HV OFF` |

**An unrecognised or unclassified command must default to cached.**
Over-caching costs a stale ack. Under-caching moves the joystick twice. A verb
added carelessly should be merely suboptimal, not dangerous.

### What the cache is actually for

**`MOVE` is the only non-idempotent command in the set.** Everything else names
a destination or a target state, so re-executing it is harmless:

| Command | Re-executed |
| --- | --- |
| `MOVETO deg` | absolute — lands in the same place |
| `HOME` | re-parks; costs a homing cycle, no hazard |
| `ARM` / `DISARM` / `STOP` / `CLRFAULT` | naturally idempotent |
| `ARMPULL thr`, `ANGSCALE lo hi`, `CAL set k v`, `ANGOUT`/`INSTR`/`HV` `ON`/`OFF` | set a value, not a delta |
| **`MOVE deg`** | **relative — doubles the movement** |

So the cache protects exactly one verb. This is written down rather than left
implicit for two reasons: an implementer should know the mechanism guards a
specific hazard rather than being general correctness machinery, and **if the
trial only ever uses absolute positioning — park, present, release, pull,
present, which is the shape described in
[`docs/pycontrol-interface.md`](pycontrol-interface.md) — then `MOVE` and the
cache can both be deleted.** Revisit this when the researcher settles the
command set.

### Consequences elsewhere

- Open question 2 below is partly defused. With the reset on any frame, a host
  polling `STATUS` during a long move keeps the link alive, so a 100 ms timeout
  shorter than a move is no longer a guaranteed spurious fault. The real
  velocity and the real timeout still need measuring together.
- The 22-case conformance corpus is **unaffected**: it pins `PING` framing, not
  retransmission or watchdog timing. So the contract the RP2040 half will be
  held to does not move, and this decision was made before that half was
  written rather than after.

## 2. The host timeout is shorter than a long move — QUANTIFIED 2026-09-03

The cited host timeout is 100 ms (`docs/pycontrol-port-pinout.md`). The draft
asked for the real velocity and the real timeout to be confirmed *together*
rather than separately. With the firmware protocol layer now wired to real
motion, here are both:

| Quantity | Value | Source |
| --- | --- | --- |
| Host timeout | 100 ms | `docs/pycontrol-port-pinout.md` |
| Commanded velocity | 0.100 rev/s = **36 deg/s** | bench jog velocity, board `E4654C159F4D1334`, 2026-09-02 |
| Usable travel after homing | ~10 deg | ~28 deg measured, less a jog step of margin at each end |
| Full-travel move | **~280 ms** | 10 deg at 36 deg/s |
| Measured homing | **~2530 ms** | 5 of 5 runs, 2026-09-02 |

So a full-travel move spans **about three host timeouts**, and a home spans
**about twenty-five**. The host must send something during motion; this is not a
corner case, it is every move and every home.

**It is no longer a design contradiction, because of the resolution to open
question 1.** The watchdog is reset by the arrival of any well-formed command,
so a task polling `STATUS` during a move keeps the link alive and gets useful
data for doing so. Under the original draft only `PING` counted, which made a
long move a guaranteed spurious fault.

**What is still a decision, not a measurement:** 36 deg/s is the *bring-up jog*
velocity, chosen to be slow enough to watch. Presenting the joystick to an
animal may want to be faster, and a faster profile shortens every number above.
That belongs with the researcher's answer about whether move speed should be
adjustable — see the profile question in the command table — and not with this
finding.

## 3. The command set does not match the trial

The draft models a pull as a *detection* problem: `ARMPULL threshold`, watch,
report. The rig needs it as a *mechanical resistance* problem — the brake sets
the force, the motor gets out of the way, the animal moves the joystick, and
detection is just watching the encoder. `ARMPULL` survives as "tell me when the
encoder passes X while compliant", but it stops being what defines a pull.

The trial shape is: park (`HOME`) → present (`MOVETO`) → set brake and release
drive → animal pulls → present again.

### 3a. Brake-then-release cannot be two host commands

The brake must engage **before** motor drive is released, or the joystick drops
as it goes compliant; and drive must be restored before the brake releases, or
the motor fights it. Split across two commands, the host can die between them, or
the second can arrive late over a link whose entire premise is that it has
latency.

**Proposed:** one verb, `BRAKE <torque>`, with the ordering enforced in firmware
where nothing can interrupt it. This follows the existing rule that the board
never requires a message in order to become safe — and extends it: the board
should not require two messages in order to become *correct*.

`FREEWHEEL` exists in the rev-0 implementation only because there is no brake to
attach it to. It is a bring-up primitive and should be **replaced** by `BRAKE`,
not kept alongside it.

### 3b. Leaving compliance should be implicit

A `MOVETO`, `MOVE`, `HOME` or `STOP` arriving while compliant re-engages the
driver as part of the same operation. An explicit "stop freewheeling" verb would
make it two commands with a window in between, for no gain.

## 4. `STATUS`'s "position" is now two quantities

The draft lists "state, angle, position, homed flag, limit state, fault mask"
without saying whether angle and position are one quantity in two units or two
quantities. With a compliant state they are genuinely two — measured and
commanded — and after a pull they disagree by the whole pull.

**Proposed:** report both, named unambiguously. The implementation uses `angle`
(encoder; the joystick's real position) and `xactual` (ramp generator).

## 5. Resyncing position from the encoder deletes the stall detector

The board's only detector for an end stop, a stall, a slipping coupling or a dead
encoder is `XACTUAL` advancing while `X_ENC` does not. Reloading `XACTUAL` from
the encoder after a pull destroys exactly that signal.

The two cases are distinguishable by state, and by nothing else:

| State | Divergence means | Response |
| --- | --- | --- |
| driving | something is broken | fault |
| compliant | the animal pulled | resync, **on exit only** |

**Proposed:** resync only on leaving a compliant state. Never during commanded
motion, never on a timer.

**And this needs a fault code the draft does not have.** Bit 4 is retired and
permanently reserved, and it was a different comparison anyway — the driver's
encoder against an RP2040 PIO count that never existed. This is `XACTUAL` against
`X_ENC`, both inside the driver. Bits 9 onward are reserved in this document "if
this design is ever extended with a brake and a torque sensor", so allocating one
here is a decision for this document rather than for firmware. Stall detection is
**not implemented** pending it.

## 6. Which parameters should the host be able to set

Open, pending what the researcher needs. The draft already answers it in
principle and that answer looks right: `MOVETO deg [profile]` takes a **named
profile**, and raw driver current, raw PWM, step counts and unbounded velocity
are on the "deliberately absent, and to stay absent" list. Named profiles let the
answer change without a firmware change and without ever exposing raw motor
power.

## What Rev 0 Hardware Can Test

The boards in hand have no electronic brake, no torque sensor and no populated
analog outputs. Implemented and testable now:

| Testable | Absent |
| --- | --- |
| `ID` `PING` `STATUS` `LIMITS` `FAULTS` `CLRFAULT` `HV` `INSTR` `CAL` | `BRAKE`, torque reporting |
| `HOME` `ARM` `DISARM` `MOVETO` `MOVE` `STOP` | `ANGOUT` `ANGSCALE`, and the second analog channel for torque |
| `FREEWHEEL`, `ARMPULL` by moving the joystick by hand | |

Unimplemented verbs answer `badverb` rather than acking, so a host cannot believe
the analog output is live and record a trace of nothing.

---

# Protocol v1 Proposal — 2026-10-01

**Status:** signed off 2026-10-01 for implementation, with four changes from
the first draft (chunked `FETCH`, `ev;S` routing, `TRIAL` once per `WATCH`
including `outcome=NONE`, `stream_hz` ≤ 50 and the `a_peak` definition) and
the draft's eleven decisions accepted; a fifth change from the review of the
implementation the same day: the capture is a ring around the outcome
(`CFG pre_ms`/`post_ms`, `FETCH` below), not a linear buffer from `WATCH`. Transcribed from the firmware work
brief of 2026-10-01 (`../../mouse-joystick-firm/.agents/handoff-rig-system-plan-2026-10-01.md`,
section 3) and the rig system plan of record
(`../../orb-weaver-context/context/mouse-joystick-rig-system-plan.md`, section 4).
Nothing above this line changes until this section is signed off; the corpus
(`../../mouse-joystick-firm/pycontrol/tests/fixtures/protocol_cases.txt`)
changes only after that, and both implementations after the corpus.
Points the brief left open are marked **DECISION** with the value this draft
proposes; the reserved decisions of the brief's section 8 are listed at the
end rather than decided here.

Unchanged: framing, `seq`, `ack`/`nak`, the watchdog rule (any well-formed
frame resets it, before dispatch) and the retransmission rule (state-changing
commands cached, reads re-executed, two entries).

## V1.1 What the protocol is for

Two boards sit under a pyControl task that owns the experiment. pyControl sends
parameters and bounded primitives down; the board sends events and one
per-trial summary up. The board owns everything that must be ordered or timed
better than a few milliseconds: homing, moves, the brake-then-release sequence,
classifying what the animal did, and sampling angle and torque at 1 kHz. The
OneBox records the analog copies at 30 kHz; the UART is not a sample path.
One trial:

```text
MOVETO present → ev;TARGET → (pyControl cues) → BRAKE torque → ev;RELEASED
→ WATCH pull;push;timeout → exactly one of ev;PULL | ev;PUSH | ev;NOMOVE | ev;ABORT
→ MOVETO park → ev;TRIAL (summary) → ev;TARGET
```

The heartbeat is `STATUS`, not `PING`, at 10–25 Hz from the device class.

## V1.2 Protocol version and capabilities

- **DECISION:** `ID` reports `proto=2`. `FREEWHEEL` and `ARMPULL` are removed
  (not aliased), so a `proto=1` host would break; the device class refuses a
  major version it does not know, which is what the Versioning section asks
  for. The alternative, keeping `proto=1` and the two old verbs as aliases,
  carries the bring-up primitives into the experiment vocabulary for no
  benefit.
- `caps` gains tokens as implemented, and the device class gates on them,
  never on `fw`: `brake`, `torque` and `angout` are hardware facts of the
  board revision; **DECISION:** `watch`, `fetch`, `stream` and `cfg` are
  firmware facts and are present in every `proto=2` firmware, so a host may
  rely on them once `proto=2` is confirmed. `freewheel` leaves `caps`.
- `fw` is the firmware build's `git describe` string and `hw` the board
  revision from the build (`rev0`, `rev1`, …); neither is a placeholder any
  more (fixed 2026-10-01).

## V1.3 New and changed verbs

| Verb | Args | Semantics |
| --- | --- | --- |
| `BRAKE` | `torque_Ncm` | Atomic in firmware: (1) set the brake DAC to the calibrated code, (2) wait for coil current to reach the setpoint or a fixed settle time (B5Z specification about 6 ms; **to be confirmed from `BRAKE_ISENSE` at v1.0 bring-up**), (3) release the driver, (4) `ev;RELEASED;t;angle=…;torque=…;brake=…`. State → `RELEASED`. Refused unless `ARMED` (`nak;notarmed`). On boards whose `caps` lacks `brake`: accepted, `torque` ignored, steps (3)–(4) only. This is today's `FREEWHEEL` and replaces it; `FREEWHEEL` answers `badverb`. |
| `WATCH` | `pull=deg;push=deg;timeout=ms[;hold=ms][;touch=Ncm][;maxdur=ms]` | One-shot classifier, valid only in `RELEASED` (`nak;notreleased` otherwise). Thresholds are relative to the angle at `RELEASED`; `pull` is positive displacement in the pull direction, `push` positive in the push direction. Emits exactly one outcome event: `PULL` once the angle has been at or past `pull` continuously for `hold` ms (default 0); `PUSH` once the angle is at or past `push`; `NOMOVE` if no first motion (angle change above the deadband, V1.6) before `timeout`; `ABORT` if first motion occurred but no outcome within `maxdur` (default disabled; **DECISION:** measured from the `WATCH` command, like `timeout`). `TOUCH` (torque at or above `touch`, default disabled) is informational, at most once, and may precede the outcome. The classifier evaluates on every sample (the firmware's 1 kHz tick; the simulator's every service step). After the outcome the classifier is disarmed; a new `WATCH` re-arms. Replaces `ARMPULL`, which answers `badverb`. |
| `MOVETO` | `deg[;profile]` | Unchanged, plus named profiles `present`, `retract`, `slow` (constants in the firmware's `AppConfig.hpp` first; `nak;badargs` for an unknown name; the simulator accepts the names and moves every profile at its one `v_max`, so corpus timings do not depend on them). Leaving `RELEASED`: re-engage the driver, resync `XACTUAL` from `X_ENC` (exit only, finding 5), emit `ev;TRIAL`, then release the brake. |
| `MOVE` | `deg[;profile]` | Unchanged for now. Candidate for deletion together with the retransmission cache (finding 1); reserved decision. |
| `CFG` | `key=value[;key=value…]` / `get` | Bounded runtime configuration. v1 keys: `wdt_ms` (host-loss timeout, 50–500, default 100; a change applies from the next watchdog refresh), `deadband_deg` (first-motion threshold for `NOMOVE`, 0.05–10, default 0.5), `stream_hz` (default `STREAM` rate, 1–50, default 10), `pre_ms` and `post_ms` (the capture window around the `WATCH` outcome, see `FETCH`: each 0–2047 and `pre_ms + post_ms ≤ 2047` so that the window fits the 2048-sample ring; defaults 500 and 500; a change applies to the next window that freezes). A value outside its bounds → `nak;outofrange` and nothing in the line is applied; an unknown key → `nak;badargs`. `CFG get` → `ack;s;wdt_ms=…;deadband_deg=…;stream_hz=…;pre_ms=…;post_ms=…`. |
| `FETCH` | `[k0;n]` | Returns the last `WATCH` capture **in host-paced chunks**: `ack;s;n=N;k0=K;t0=T;dt_us=1000;pre=P;lost=L`, then `N` lines `cap;k;angle;torque` for `k` from `K`, then `cap;end`. `n` is capped at **32** lines per request (`FETCH` alone means `k0=0;n=32`); the host asks again with the next `k0` until a reply carries fewer lines than it asked for. Reason: a 150-line burst at 115200 lasts about 330 ms, `IRQ_RXIDLE` may not fire until it ends, and a 200-byte receive buffer overflows; the device class also raises its `rxbuf` to 2048. `T` is the board time of sample `K`; sample `k` is at `T + (k−K)·dt_us`. **The capture is a ring** (review of 2026-10-01; it replaced a linear buffer that started at `WATCH` and stopped after two seconds, which missed any outcome later than that in a trial whose `timeout` may be 10 s): the angle (and torque) is sampled on the 1 ms grid from `RELEASED` on into a ring of 2048 samples that keeps running however long the trial takes. When the outcome is decided, the window freezes `post_ms` samples later and holds the last `pre_ms` samples before the outcome sample, the outcome sample itself and the `post_ms` samples after it: `pre + 1 + post` lines, and **`k = pre` is the outcome sample**. If the host leaves `RELEASED` first the window freezes at the exit with what exists: fewer post samples, or, with no outcome yet (`TRIAL outcome=NONE`), only the samples before the exit and no outcome sample, so the line count equals `pre`. `pre` reports the samples the ring actually holds, which is fewer than `pre_ms` when `RELEASED` (or a `WATCH` re-armed after a frozen window, which restarts the ring) is younger than `pre_ms`; history from before the `WATCH` counts. `lost` (2026-10-02) is the number of samples in the whole window that the firmware did not take on time: when its 1 kHz tick is coalesced behind a longer step (a protocol line, the rail's soft start), the missed grid points are filled with the angle at the next tick so sample `k` stays at `T + k·dt_us`; `lost` says how many of the window's samples are such fills (the host-side simulator always reports 0). `nak;busy` while a `WATCH` is armed or the post window is still filling. A new `BRAKE` restarts the ring and discards the previous window, so the host fetches between trials; a `RELEASED` period in which no `WATCH` was armed leaves no window; no window → `n=0;k0=0;t0=0;pre=0` and `cap;end`. **DECISION:** the window bounds are `CFG pre_ms`/`post_ms`, each 0–2047 with `pre_ms + post_ms ≤ 2047`, defaults 500/500; the 2048-sample bound stays. **DECISION:** on boards whose `caps` lacks `torque` the `torque` field is empty (`cap;k;angle;`), so the line has the same field count everywhere. |
| `STREAM` | `on[;rate_hz]` / `off` | Optional decimated telemetry at **1 to 50 Hz at 115200 baud** (raise the bound only with the baud), for display only, off by default and off again after a fault or `DISARM`; `rate_hz` outside the bound → `nak;outofrange`, omitted → `CFG stream_hz`. Sample lines are `ev;S;t;angle=…;torque=…`, an event in framing, so the device class has no fourth message kind to decode; **the device class routes `ev;S` lines to its `AnalogChannel`s and never publishes them as framework events.** |
| `TQ` | `zero` / `cal;on` / `cal;off` / `get` | Torque tare (store the offset), shunt-calibration switch (`TQ_CAL_EN`), raw read. v1.0 boards only; `badverb` when `caps` lacks `torque`. |
| `ANGOUT`, `ANGSCALE` | as in the command table | Must work in the protocol firmware, not only in the bench console. `GAIN = 0x0101` written before the first data write; the output is 0 V, or the agreed fault code, while unhomed, faulted or disabled (reserved decision: code 0 or code 497). |
| `INSTR` | unchanged | **Found 2026-10-01:** the firmware enables the InstrumentPort buffers at boot for its proof of life, so `INSTR STATE` answers `instr=1` on a fresh board; the simulator answered `0`. The boot default is **on**. The verb now really drives the buffers (fixed 2026-10-01). On the QP build the QS trace leaves on `FW_TRIG1` through the same buffers, so **`INSTR OFF` also silences the trace**. On a v1.0 board the Digital-50 port has no enable at all; there the verb is accepted and `STATE` always reports `1`. |

**DECISION:** the retransmission classification (finding 1) extends as: cached
(state-changing) `BRAKE`, `WATCH`, `CFG k=v`, `TQ zero`, `TQ cal`, `STREAM`;
re-executed (reads) `FETCH`, `CFG get`, `TQ get`.

**DECISION:** a `WATCH` while one is already armed replaces it (one `ack`, no
event for the superseded one). A `BRAKE` while already `RELEASED` is refused
(`nak;notarmed`) as the brief states; whether the brake level should be
adjustable mid-trial is a question for the researcher.

## V1.4 Replies and events

- `STATUS` → `ack;s;state=…;angle=…;xactual=…;torque=…;brake=…;homed=…;limit=…;faults=…;hv=…;t=…`.
  `t` is the board clock in microseconds, 64-bit, decimal. The device class
  pairs it with pyControl's millisecond clock on every heartbeat; nothing else
  is needed for alignment. **DECISION:** `torque` and `brake` are always
  present and empty on boards without the capability, so field positions never
  move.
- All event timestamps are the same 64-bit clock (fixed 2026-10-01; the
  previous 32-bit `t` wrapped at 71.6 minutes).
- New events: `RELEASED;t;angle=…;torque=…;brake=…`, `TOUCH;t;angle=…;torque=…`,
  `ABORT;t;angle=…;torque=…`, and the per-trial summary:

  ```text
  ev;TRIAL;t;outcome=PULL;t_rel=…;t_touch=…;t_move=…;t_out=…;a0=…;a_peak=…;a_end=…;tq_peak=…;tq_out=…;dur_thr=…
  ```

  `outcome` is one of `PULL`, `PUSH`, `NOMOVE`, `ABORT`; `t_*` are board
  microseconds, `t_touch`/`t_move` empty if they did not occur; `a0` the angle
  at release; `a_peak`, `tq_peak` the signed extrema in the window
  (pull-positive); `a_end`, `tq_out` the values at the outcome; `dur_thr` the
  whole milliseconds spent at or past the pull threshold between `WATCH` and
  the outcome. **`a_peak` is the signed excursion of largest magnitude** from
  `a0`, pull-positive; `a_end` is likewise the excursion at the outcome (or at
  the exit for `outcome=NONE`), not an absolute angle. **`TRIAL` is emitted
  exactly once per `WATCH`**: when the board leaves `RELEASED` (`MOVETO`,
  `STOP`, `DISARM`, fault), or 1 s after the outcome if the host has not left
  `RELEASED` by then, whichever comes first; when the host leaves `RELEASED`
  before any outcome it carries `outcome=NONE` with `t_out` empty. A
  `RELEASED` period with no `WATCH` produces no `TRIAL`. On the wire the
  `TRIAL` event precedes the `ack` of the command that left `RELEASED`, as
  every event produced inside a handler does.
- `PULL`, `PUSH`, `NOMOVE` and `ABORT` carry `t;angle=…;torque=…` like
  `RELEASED`, where `angle` is the absolute angle at the event.
- `BRAKE` answers `ack` first and `ev;RELEASED` when the release has
  happened (the same service step on a board without a brake; after the
  settle on a board with one).
- Line length: a full `STATUS` is about 125 bytes. `MAX_LINE` rises from 120
  to **200**, `ID` reports `rxbuf=200`, and the device class's receive buffer
  becomes **2048** so a 32-line `FETCH` chunk cannot overflow it.
- `caps` tokens appear in a fixed order with absent ones omitted:
  `motion+home+instr+hv+watch+fetch+stream+cfg+angout+brake+torque`.

## V1.5 State machine

```text
BOOT → IDLE ─HOME→ HOMED ─ARM→ ARMED ─MOVETO→ ACTIVE → ARMED
                                 └─BRAKE→ RELEASED ─(WATCH outcome; stays RELEASED)
                                              └─MOVETO/STOP/DISARM→ re-engage → ARMED/HOMED
any fault → FAULTED ─CLRFAULT→ IDLE (homed cleared)
```

The state string `FREEWHEEL` becomes `RELEASED` everywhere it is reported.

## V1.6 Configuration defaults and the deadband

`deadband_deg` defaults to 0.5° until the bench measures the
encoder's noise and the mechanism's play on a released joystick; `wdt_ms`
defaults to 100 (today's value); `stream_hz` defaults to 10 for `STREAM on`
without a rate. The mechanism's sign (which encoder direction is "pull") is a
board-and-harness fact to be recorded once in `bringup-log.md` per board; the
firmware exposes pull-positive numbers and the device class hides nothing.

## V1.7 Fault bits (bits 9 and up are reserved for exactly this)

| Bit | Name | Cause |
| --- | --- | --- |
| 9 | `brake_fault` | `~{BRAKE_FAULT}` asserted |
| 10 | `brake_current` | `BRAKE_ISENSE` outside tolerance of the setpoint for more than N ms (N from bring-up) |
| 11 | `torque_adc` | ADS8689 not responding or conversion timeout |
| 12 | `torque_range` | bridge saturated or excitation out of range |
| 13 | `not_following` | `XACTUAL` against `X_ENC` divergence while driving only (finding 5); never in `RELEASED` |

Bit 13 is what finding 5 asked for: stall detection becomes implementable.

## V1.8 Safe state on host loss or fault

Today: abort motion, `HV` off, motor coasts. With a brake fitted the proposal
is: brake to a configurable holding level (`CFG hold_Ncm`), driver off,
`FAULTED` latched. The behaviour is selectable by configuration and the
default stays today's until the researcher decides (reserved decision).

## V1.9 Reserved decisions (brief section 8; ask, do not assume)

- Delete `MOVE` and the retransmission cache, or keep them.
- The `TRIAL` field list and names.
- `FETCH` as ASCII lines (this draft) or a binary block.
- The fault level on `ANGLE_OUT`: code 0 or code 497 (25 mV); `GAIN` 0x0101
  or 0x0000.
- Whether `WATCH` needs outcomes beyond the five above before the researcher
  answers the trial-vocabulary question.
- The default safe state on host loss once the brake exists (V1.8).

## V1.10 What changes where, once signed off

Spec (this section merged into the tables above) → corpus (new cases for every
verb, every `nak` reason, the `RELEASED`→outcome sequences with an `ANGLE`
and `TORQUE` stimulus line added to the corpus grammar, the 64-bit `t`) →
`board_sim.py` → the firmware → the device class in the same change set →
hardware last, with numbers in `bringup-log.md`.
