# Bring-Up Log

**Rev 0 scope:** Rev 0 hardware carries no analog angle output, no pyControl TTL
event lines, and no encoder cross-check — the last of those is permanent, not
deferred. Sections below covering the first two record
rev 1 measurements. See `docs/rev0-plan.md`.

**Rev 0 does carry InstrumentPort-40** (`J1501`), with 11 of 18 digital Strands
live and **all three** buffer packages fitted — `U1601`, `U1701`, `U1801`. There
are three `SN74LVC125A` packages on this board, not five. Record only the live
Strands.

**No test points exist anywhere on the board.** Fields below that name a test pad
are marked struck; reach those signals at a component pin or through
InstrumentPort-40, and record how you reached them.

Use this file to record measured behavior of real boards. Record numbers with
units, not pass/fail marks.

If the rig holds two boards, keep **one section set per board serial**. Do not
merge them — the whole point of recording a serial is that the two boards are
independently calibrated and independently suspect.

## Boards In This Rig

**Four units are now known, and they are no longer all the same PCB revision.**
`v0.1`→`v0.2` is layout-only — same schematic, byte-identical pad-to-net map — so
measurements transfer between those tags but **not between the units**. Keep them
apart; that is what the serials are for.

**Board 4 is a `v0.3` unit and is a different board.** `v0.3` adds the analog
angle output, so it is `MJ_BOARD_REV=1` in firmware, its designators have
rotated wholesale, and nothing measured on boards 1-3 past `HV_EN` should be
assumed to hold on it. Record which revision a serial is, not just the serial.

| Unit | RP2040 flash unique ID | State |
| --- | --- | --- |
| **Board 1** | `E4654C159F2C2534` | Stage 1 + stage 2 passed. **`R203` DEPOPULATED 2026-09-02** — `LATCH` released, so a plain `HV_EN` assertion works on this unit and it no longer represents an as-built board. **Not attached to the bench on 2026-09-03** |
| **Board 2** | `E4654C159F4D1334` | `R203` intact, i.e. as-built. **Stages 2 and 3 passed 2026-09-02** — motor turns, encoder tracks, homing repeats to 4 encoder counts. Stage 1 has never been run on it. See [Board 2](#board-2--e4654c159f4d1334) |
| **Board 3** | `E4654C159F591D34` | **Added to this log 2026-09-03.** `R203` intact, i.e. as-built. **Drives the LEFT joystick** (Breakout 1.2 port 1). First stage-4 result recorded 2026-09-03 — see [Board 3, stage 4](#board-3--e4654c159f591d34--stage-4-protocol). No stage 1, 2 or 3 measurements exist for this unit; treat every motion number in this file as belonging to another board until it is measured here |
| **Board 4** | `E4654C159F171E34` | **First `v0.3` unit, added to this log 2026-09-09.** `LATCH` strap intact — on this revision that is **`R1903`**, not `R203`. **Stages 1, 2 and 3 all passed 2026-09-09** — stage 1 on USB alone (24 checks, 0 failed), then stage 2 and stage 3 with everything connected: rail up in 132 ms, TMC5130A alive, encoder follow ratio **1.0000**, homing repeatable to **2.0 encoder counts**. See [stage 1](#board-4--e4654c159f171e34--v03-stage-1), [stage 2](#stage-2-passed-on-board-4--2026-09-09-36-v-on-nothing-else-connected), [stage 3](#stage-3-passed-on-board-4--2026-09-09-everything-connected). **The angle output is still untested — there is no DAC driver in firmware.** Stage 4 not run |

**Which board drives which joystick — established 2026-09-03.**

| Joystick | Breakout 1.2 port | Board serial |
| --- | --- | --- |
| **Left** | 1 (`UART4`) | `E4654C159F591D34` |
| **Right** | — | **`E4654C159F171E34`** (board 4, v0.3) — confirmed 2026-09-09 |
| ~~Right~~ | ~~4 (`USART3`)~~ | ~~`E4654C159F4D1334`~~ — displaced by board 4 |

**Updated 2026-09-09: board 4 now drives the RIGHT joystick**, so every stage 3
number recorded for board 4 belongs to the right mechanism. Board 2
(`E4654C159F4D1334`) has been displaced from that position; its own stage 3
numbers were taken on the same mechanism, which makes the two directly
comparable — board 4 homes to **2.0** encoder counts where board 2 homed to 4.
The breakout port board 4 sits on has not been recorded. **Re-establish this
with the protocol `ID` reply after any recabling rather than trusting the
table.**

This had been a standing gap: the mirrored harnesses make the boards
interchangeable, so nothing in the mechanism records which one is where, and a
per-board calibration is meaningless without it. It was closed by the protocol
`ID` reply — the board announced its own serial on the port it was wired to,
which is exactly what `ID` carries a serial for. Re-establish it the same way
after any recabling rather than trusting this table.

**On board 3.** It was found attached to the bench on 2026-09-03 and its serial
appears nowhere in any repository before that date. It is not board 1 with a
mis-transcribed id: board 1 has `R203` depopulated and board 3 has it intact,
which is a physical difference rather than a bookkeeping one. Whether it is a
newly built unit or one that predates this log is not recorded; what matters
here is that **it carries no measurement history**, and that the two boards on
the bench as of 2026-09-03 are boards 2 and 3.

A consequence worth stating because it has already caused confusion: the console
harness examples in this file and in `../mouse-joystick-firm/docs/` that name
`/dev/ttyACM0` were written when that was board 2. With boards 2 and 3 attached,
`/dev/ttyACM0` is board 3. **Address boards by `/dev/serial/by-id/`**, which
carries the serial, and never by `ttyACM` number.

Everything from here to [Board 2](#board-2--e4654c159f4d1334) is **board 1**
unless a line says otherwise.

## Board 4 — `E4654C159F171E34` — v0.3, Stage 1

**First `v0.3` unit, first power-on 2026-09-09. Stage 1 passed: 24 checks, 0
failed.** USB power only — 36 V not connected, RJ-45 not connected, nothing on
the stepper, encoder or limit-switch connectors. `HV_EN` low and the GPIO
isolation bus open throughout.

**PCB revision:** tag `v0.3` (`a3032a6`).
**Firmware:** `mouse-joystick-firm`, `examples/RP2040SelfTest`, env
**`mouse_joystick_rev1`** (`MJ_BOARD_REV=1`), built `Sep  9 2026 13:49:10`.

### `v0.3` is `MJ_BOARD_REV=1`, and that is not obvious from the env name

`platformio.ini` describes `env:mouse_joystick_rev1` as "the rev 1 board (pcb
HEAD)", which reads as if no fabricated board matches it. **A `v0.3` board
does.** Read off the `v0.3` PCB's own pad-to-net map for `U501`:

| `U501` pad | GPIO | `v0.3` net |
| --- | --- | --- |
| 13 | `GP10` | `/mcu/DAC_SPI_SCK_` |
| 14 | `GP11` | `/mcu/DAC_SPI_COPI_` |
| 16 | `GP13` | `/mcu/~{DAC_CS_}` |

All three are routed to the angle-output DAC, so **building `env:mouse_joystick`
(`MJ_BOARD_REV=0`) against a `v0.3` board would drive internal pull-ups and
pull-downs onto a live SPI bus and a chip select** in the spare-pad test. The
bus switch happens to isolate them at reset, so it would not have damaged
anything on this board — but that is luck, not the intent, and it is why the
spare-pad count is **9 on `v0.3` against 12 on `v0.2`**, and the total 24 checks
against 27.

`U501` pads 24, 25 and 26 — `SWCLK`, `SWD`, `RUN` — are **still no-connect on
`v0.3`**. There is no debugger and no reset button on this revision either.

### Designators on `v0.3`, for the parts stage 1 actually tests

**The self test prints `v0.1` designators in its own output text.** It says
`R205 10k present` and `R207 249R`; on this board those parts are `R1905` and
`R1907`. Read the net names, not the printed refdes. Mapping confirmed against
the `v0.3` schematic, not inferred:

| Net | `v0.1` | **`v0.3`** |
| --- | --- | --- |
| `~{BUS_SW_EN}` pull-up, 7.87 kΩ | `R601` | `R601` — unchanged |
| `PYC_UART_RX` pull-up, 10 kΩ | `R403` | `R403` — unchanged |
| `SW_RAIL_SENSE_DIV_2` divider, 1 kΩ/1 kΩ | `R401`/`R402` | `R401`/`R402` — unchanged |
| `~{INSTR_BUF_OE}` pull-ups, 10 kΩ | `R1601`/`R1701`/`R1801` | `R1601`/`R1701`/`R1801`/**`R2101`** |
| `~{HV_FAULT}` pull-up, 10 kΩ | `R205` | **`R1905`** |
| `HV_SNS` bottom leg, 249 Ω | `R207` | **`R1907`** |
| `HV_SNS` top leg, 40 kΩ | `R206` | **`R1906`** |
| `EN` pull-down, 10 kΩ | `R204` | **`R1904`** |
| **`LATCH` strap, 1 kΩ** | `R203` | **`R1903`** |
| 36 V high-side switch | `U201` | `U1901` |

**`R1903` is the part that was depopulated on board 1** to release `LATCH`. If
that modification is ever wanted on a `v0.3` unit, `R1903` is the resistor —
`R203` does not exist on this board.

**There are four `SN74LVC125A` buffer packages on `v0.3`, not three.**
`U1601`, `U1701`, `U1801` and `U2101`, each with its own 10 kΩ OE pull-up. The
"three packages on this board" note at the top of this file describes rev 0.

### Clocks, and the crystal

| Clock | Reported |
| --- | --- |
| `clk_ref` (xosc) | 12 000 kHz |
| `clk_sys` | 133 000 kHz, measured 133 001 kHz against `clk_ref` |
| `clk_peri` / `clk_usb` / `clk_adc` | 48 000 kHz |

**Crystal `Y501`, absolute — three 10 s `k` runs, host-timestamped.** Over the
9 s tick span: **−1.3, +42.4 and +91.6 ppm**; per-tick medians −14.6, +70.8 and
+0.8 ppm. USB CDC scheduling jitter is order 1 ms over 9 s, i.e. ~110 ppm, so
all three are **below the noise floor of the method** — consistent with a
healthy ±30 ppm part but not a measurement of it, exactly as on board 1.
Independently, USB full speed needs 48 MHz within 0.25 % derived from `Y501`,
which bounds it regardless.

**Method trap, and it produced a confident wrong answer first.** Timestamping
the tick lines with pyserial `read(512)` makes every read wait out the full
`timeout` — `read(n)` returns early only when it has `n` bytes, and one tick
line is ~45 — so each timestamp is displaced by the timeout. That yielded a
stable, repeatable, entirely fictitious **−3400 ppm**, self-consistent across
nine intervals, and it changed with the timeout value rather than with the
board. **Use blocking `readline()`.** A crystal 3400 ppm slow is 1.4× outside
what USB full speed tolerates, so "the board is enumerating and streaming CDC
fine" was already enough to reject the number before the method was found.

### QSPI flash `U502` (W25Q128JVZPIQ, 16 MiB)

Unique ID read back over QSPI (`0x4B`) plausible, so the part is present,
selected and responding. Declared size 16 MiB. Address-aliasing probe at +2, +4
and +8 MiB: none aliases offset 0, so the fitted part really is at least 16 MiB
and not a smaller part wrapping its address space. `picotool` additionally
verified the whole image byte-for-byte after each of two writes.

### RAM

Heap total 252 228 B, used 100 B, free 252 128 B. 16 KiB allocation and a
four-pattern walk over it both clean.

### Resistor-defined levels

Captured in the first instruction of `setup()`, internal pulls disabled, before
anything drove a pin. Each maps to one part, so a failure here is an assembly
defect and not firmware.

| Pin | Net | Read | Held by (`v0.3` refdes) | Verdict |
| --- | --- | --- | --- | --- |
| `GP9` | `~{BUS_SW_EN}` | high | `R601` 7.87 kΩ to `+3.3V_MCU` | ok — GPIO bus isolated at reset, which every later stage depends on |
| `GP24` | `~{INSTR_BUF_OE}` | high | `R1601`/`R1701`/`R1801`/`R2101` 10 kΩ | ok — instrument port silent before firmware, all four packages |
| `GP1` | `PYC_UART_RX` | high | `R403` 10 kΩ to `+3.3V_MCU` | ok — RJ-45 unplugged, so this is `R403` and not an idle far-end TX |
| `GP29` | `~{HV_FAULT}` | high | `R1905` 10 kΩ to `+3.3V_MCU` | ok — pull-up present, on the right rail, no latched 36 V fault |

### Spare pads

All nine unrouted GPIOs — `GP12`, `GP15`, `GP16`, `GP17`, `GP18`, `GP20`,
`GP22`, `GP23`, `GP27` — moved correctly under both an internal pull-up and an
internal pull-down. No solder defects on any of them. `GP10`, `GP11` and `GP13`
are **excluded on this revision** because they carry the DAC bus; on `v0.2` they
were testable this way and they are not any more.

### ADC

12-bit, reference is `ADC_AVDD` tied directly to `+3.3V_MCU` with no separate
reference and no filter, so absolute accuracy is bounded by that rail. Four
samples — the boot run plus three `a` reads.

| Channel | Net | Reading |
| --- | --- | --- |
| `GP26` / ADC0 | `SW_RAIL_SENSE_DIV_2` | 11-13 counts = 0.0089-0.0105 V at the pin = **0.018-0.021 V** on `+3.3V_SW` — switched domain genuinely off, `R401`/`R402` holding it there |
| `GP28` / ADC2 | `HV_SNS` | 10-12 counts = **0.008-0.010 V** across `R1907` 249 Ω. Reads zero regardless while `HV_DIAG_EN` is low, which stage 1 keeps it, so this confirms the quiet state and not the sense chain |
| ADC4 | internal temperature | **28.1, 29.9, 28.5, 29.0 °C** — proves the ADC and `ADC_AVDD` are alive |

### Reset reason, and the 1200 baud touch

Reported `software (3)` with `watchdog caused reboot: yes` after each `picotool`
upload, which is correct rather than a fault: `picotool` reboots the chip
through the watchdog. A cold power-on would read `power-on`; **not taken on this
unit**, because it needs USB unplugged and replugged.

**The 1200 baud touch reset works on this board.** The second upload was done
over `/dev/ttyACM1` with the application running — no `SW501`, no unplugging.
That is worth recording rather than assuming, because `RUN` is still
no-connect on `v0.3`, so the touch and the `B` command are the *only* ways into
BOOTSEL that do not involve the button.

### Not covered by stage 1 on this board

Everything past `HV_EN`: the switched rails, the TMC5130A, `X1201`, the motor,
the encoder, the limit switch. **The whole angle-output chain**, which is the
headline reason `v0.3` was ordered — the `DAC80501` and `OPA197` run from
`+5V_SW`, so none of it can be reached without 36 V. The pyControl link beyond
`GP1`'s idle level. Boot latency, which needs the LA5032 on `FW_TRIG0`/`FW_TRIG1`.

### Stage 2 passed on board 4 — 2026-09-09, 36 V on, nothing else connected

`examples/TMC5130Communication`, env **`mouse_joystick_rev1`**, command `s`.
36 V on `J1901`; motor, encoder and limit-switch connectors all empty, RJ-45
unplugged. Four runs, all consistent.

| Step | Result |
| --- | --- |
| rail off before `HV_EN` | 0.0161 V |
| `HV_EN` via firmware staircase (`R1903` straps LATCH high) | `+3.3V_SW` up in **132-133 ms**, peak **3.293-3.296 V**, settled 3.2911 V |
| `HV_SNS` | 0.0097-0.0113 V across `R1907` 249 Ω (12-14 counts) — at the offset floor, no measurable load |
| `~{HV_FAULT}` | high, no latched fault |
| GPIO isolation bus | closed, `~{TMC_DRV_EN}` still high |

TMC5130A, driver disabled throughout:

| Register | Value | Reading |
| --- | --- | --- |
| `IOIN` (0x04) | `0x11000011`, status `0x79` | `VERSION` = **0x11**, the TMC5130A signature |
| `IOIN.DRV_ENN` | 1 | driver disabled, and `GP3` reaches the chip through the bus switch |
| `IOIN.SD_MODE` | 0 | motion-controller mode, tied to GND |
| `IOIN` inputs | `REFL_STEP`=1, `REFR_DIR`/`ENCA`/`ENCB`/`ENCN`/`SWCOMP`=0 | `REFL_STEP` = 1 is **correct on v0.3** — see below |
| `GSTAT` (0x01) | `0x00000001` | `reset`=1 expected on the first read after power-up, `drv_err`=0, `uv_cp`=0 |
| `GCONF` (0x00) | `0x00000000` | reset default |
| `CHOPCONF` (0x6C) | `0x00000000` | **`vsense` = 0 at reset.** This board fits 0.15 Ω, so stage 3 must set `vsense` = 1 and read it back **before** lowering `~{TMC_DRV_EN}` |
| `DRV_STATUS` (0x6F) | `0x80000000` | `stst` — standstill, as it must be with the driver disabled |
| `XACTUAL` (0x21) / `X_ENC` (0x39) | 0 / 0 | |

**Register checks: 5, 1 failed** — `IOIN` against the firmware's expected
`0x11000010`. That failure is the firmware's, not the board's.

#### `REFL_STEP` = 1 with the switch unplugged is correct on v0.3 — RESOLVED for this revision

Read from the `v0.3` `.kicad_pcb`, footprint `U1301` (MAX6816):

```text
U1301 pad 2  IN   -> /motor_encoder_switch/limit_switch_debounced_input_vertical/IN
                     (reaches only J1301 pad 2 and this pin -- no external pull)
U1301 pad 3  OUT  -> /LIMIT_SW
U1301 pad 4       -> +3.3V_SW
```

The `v0.3` limit-switch block contains **only** `C1301`, `U1301` and `J1301`.
There is **no `R1405` and no `LIMIT_SW` pull-down anywhere on v0.3** — the only
10 kΩ parts on the `motor_encoder_switch` sheet are `R1101`/`R1102`/`R1103`, and
those are pull-ups to `+3.3V_SW` on `TMC_DIAG0`, `TMC_DIAG1` and
`~{TMC_DRV_EN}`.

So with the connector empty the MAX6816 must supply its own pull-up on `IN`, it
drives `OUT` high, and nothing can override a driven output. **`REFL_STEP` = 1
is the only reading v0.3 can give.** This is exactly the netlist argument
written for v0.2 on 2026-09-02 and then doubted when board 2 disagreed — on
v0.3 it is confirmed against the copper.

Board 4 agrees with **board 1** (`0x11000011`). Across three units:

| Board | PCB | `IOIN` | Odd input |
| --- | --- | --- | --- |
| `E4654C159F2C2534` | v0.1/v0.2 | `0x11000011` | `REFL_STEP` = 1 |
| `E4654C159F4D1334` | v0.1/v0.2 | `0x11000014` | `ENCB` = 1, `REFL_STEP` = 0 |
| `E4654C159F171E34` | **v0.3** | `0x11000011` | `REFL_STEP` = 1 |

Two of three read `REFL_STEP` = 1, and board 2 is now the sole outlier on that
bit. Board 2's own stage 3 showed `REFL` driving 0→1 and 1→0 with the switch
fitted, so `U1301`'s output path works there — which leaves board 2's
empty-connector 0 still unexplained. Its `ENCB` = 1 remains unique to it.

**The standing instruction in this file not to "fix" the expected `IOIN` by
flipping a bit still stands, and I have not.** The firmware's *explanatory text*
is fixed — on rev 1 it no longer names `R1405` — but the check still fails
deliberately. The real fix is to stop asserting on `REFL_STEP`, `ENCA`, `ENCB`,
`ENCN` and `SWCOMP` at all: they legitimately depend on what is plugged in, so
no fixed expectation can be right. Assert `VERSION`, `DRV_ENN` and `SD_MODE`;
report the rest. **Not done — it needs a decision.**

#### LATCH baseline — FAIL as expected, and the probe was capable of a false PASS

Cold, the `l` probe reports what the plan predicted: rail came up, held
**52-73 ms of 250 ms**, peak 3.293-3.296 V, `~{HV_FAULT}` **LOW, fault
latched** → `[FAIL] this board still needs the workaround`. `R1903` is fitted,
so v0.3 behaves exactly like v0.2 and **the firmware staircase stays required**.
That closes the *LATCH baseline* item in `.agents/PLANS.md`.

**The first run of that probe reported `[PASS]`, and it was wrong.** Run
immediately after `s` — which deliberately leaves the rail up —
`probeLatchBehaviour()` did `powerDown(); delay(50);` and then asserted `HV_EN`
into an **already-charged** 208 µF. With no inrush to supply the switch is asked
nothing, never trips, and the probe concludes the LATCH fix is present. Same
board, same firmware, minutes apart: **PASS hot, FAIL cold.**

This is the worst place in the firmware for that bug. `l` exists for exactly one
purpose — telling a new revision whether it needs the workaround — and it could
answer PASS on a board that needs it. Had it gone unnoticed it would have
removed the staircase from v1.0 planning on false evidence.

**Measured: `+36V_SW` takes 691 ms** to bleed down to where `+3.3V_SW` reads
off, with only board leakage as a load. The 50 ms delay was short by ~14×.

Fixed in `../mouse-joystick-firm`: `probeLatchBehaviour()` and
`profilePowerUp()` now call the **already-existing** `waitForRailOff()` helper
plus a 200 ms margin — the helper was written for precisely this hazard and
documented it, and these two callers simply did not use it. `LatchProbe` gained
`started_cold` and `discharge_ms`, `fix_present` now requires `started_cold`,
and the report refuses to interpret a run that could not discharge. Re-verified
on hardware: run straight after `s`, it waits 691 ms and correctly reports FAIL.

#### Bench note

`/dev/ttyACM0` is the **pyControl pyboard**; board 4 is `/dev/ttyACM1`. Omitting
the port from `pixi run upload` lets PlatformIO default to `ttyACM0` and send
the 1200 baud touch to the pyboard, which fails with *"No accessible
RP2040/RP2350 devices in BOOTSEL mode"* and looks like a flaky reset. Always
pass the port, resolved through `/dev/serial/by-id/`.

### Stage 3 passed on board 4 — 2026-09-09, everything connected

`examples/MotionAndHoming`, env **`mouse_joystick_rev1`**. Motor, encoder,
limit switch, 36 V, pyControl RJ-45, LA5032 on `J1501` and the angle BNC on a
scope all connected. Gates driven one at a time rather than through `s`, so a
failure could be caught at the gate that produced it.

| Gate | Result |
| --- | --- |
| rail and bus | `+3.3V_SW` up in **132 ms**, peak **3.301 V**, firmware staircase; bus closed, `~{TMC_DRV_EN}` high |
| TMC51X0 attached | `VERSION` = 0x11, motion-controller mode, `GSTAT` `drv_err`=0 `uv_cp`=0; `ENC_CONST` = **+12.8 µsteps per quadrature count**, decimal mode |
| `CHOPCONF.vsense` | `CHOPCONF` = `0x10030153`, **vsense reads back 1**, `TOFF` nonzero |
| current | `IRUN` = **8** → 0.211 A RMS, `IHOLD` = 2 → 0.070 A RMS. **Note this is half the settled ceiling** — the thermal survey settled `IRUN` 17 = 0.421 A, and the example still ships 8. `n` sets it |
| driver enable | accepted, gated on the vsense read-back |

#### The encoder path is good — follow ratio 1.0000 — and `g`'s failure was a starting position

`g` **failed**, and the failure is not a defect:

```
outbound  commanded -1280, encoder measured  -704,  ratio 0.5500
return    commanded +1280, encoder measured +1177,  ratio 0.9195
residual after the round trip: 473 usteps (37.0 counts)
```

`g` always jogs *away* from the switch first, which on this rig is toward the
**negative hard stop**, and the mechanism was resting near it. The outbound move
drove into the stop partway: the encoder stopped at 4.95° while the ramp
generator kept stepping, the return ran unobstructed, and the 473 µstep residual
is exactly the open-loop position the motor gained while the mechanism was
blocked.

Two plain jogs the other way settle it:

```
+1280 commanded, +1280 measured, ratio 1.0000
+1280 commanded, +1280 measured, ratio 1.0000
X_ENC - XACTUAL = 473 usteps, constant across both moves
```

**Ratio 1.0000 twice, exactly.** The CPR, the 470 pF RC corner, the coupling and
the gear mesh are all fine on this board, and `X_ENC - XACTUAL` holding at a
constant 473 confirms the offset was taken once, during the stall, rather than
accumulating.

**`g`'s failure text is misleading and should be changed.** It offers "a clean
2.0 or 0.5 means the CPR is wrong" and otherwise points at lost counts, the RC
corner and coupling slip — but it never names the most likely cause given that
the command itself jogs into the negative stop first. A ratio near 0.5 with an
*asymmetric* return and a residual matching the shortfall is a hard stop, not a
CPR error. Either home before the check, or jog positive to establish clearance
first, or name the stop as candidate one. **Not changed — it needs a decision.**

#### Limit switch witnessed with the motor, and its polarity is now settled

```
resting REFL_STEP: 0
engaged at:        4096 usteps (28.800 deg)
released at:       3840 usteps (27.000 deg)
switch throw:      256 usteps (1.80 deg)
triggered level = 1 (active high) -> SW_MODE.pol_stop = 0, non-inverted
```

The switch is **normally closed**: with the connector fitted and the mechanism
at rest it holds `IN` low and `REFL_STEP` reads **0**; actuation opens it and
`REFL_STEP` goes to **1**. That matches board 2's stage 3 exactly, and the path
`J1301` → `U1301` → TMC `REFL` works on this board.

**This closes the `IOIN` open issue.** With the switch unplugged board 4 read
`REFL_STEP` = 1; plugged in and at rest it reads 0. Both readings are correct,
and the empty-connector value is not a defect on either board:

| Connector | `IOIN` | `REFL_STEP` | Why |
| --- | --- | --- | --- |
| empty | `0x11000011` | 1 | MAX6816 supplies its own pull-up on `IN` and drives `OUT` high; no `LIMIT_SW` pull-down exists on v0.3 |
| fitted, at rest | `0x11000018` | 0 | normally-closed switch holds `IN` low |
| fitted, actuated | — | 1 | switch opens |

`ENCA`/`ENCB` behave the same way: empty they are floating CMOS inputs, fitted
they read a real quadrature state (`ENCA`=1, `ENCB`=0 at rest here). **So the
firmware's fixed expected `IOIN` is wrong by construction** — five of those bits
depend on what is plugged in. Board 2's `ENCB`=1 and `REFL_STEP`=0 with empty
connectors needs no assembly-defect explanation after all; it was a floating
input and a switch that had been left connected. The recommendation stands:
assert `VERSION`, `DRV_ENN` and `SD_MODE`, report the rest.

**A useful consequence, and it is fail-safe in the right direction:** an
unplugged or broken limit-switch cable reads as `REFL_STEP` = 1, i.e. as a
permanent limit, which refuses motion rather than allowing it.

#### Homing

Approach **0.200 rev/s**, creep **0.010 rev/s** — the repeatability figure is
meaningless without these, because the MAX6816's debounce delay scales the
offset with approach speed.

```
approach stopped by the switch at 4199 usteps (29.524 deg)
stage 1 XLATCH closing edge:  4199 usteps, overshoot past the latch 0 usteps
stage 2 XLATCH release edge:  3817 usteps (26.838 deg), creep -384 usteps
closing to release:           382 usteps (2.686 deg)
backed off to -1282 usteps, switch released
total 1467 ms
```

Position 0 is the **release** edge, taken at creep velocity, with the encoder
zeroed there.

**Repeatability, 5 counted runs after one throwaway: 5 of 5 succeeded, spread
26 µsteps = 0.183° = 2.0 encoder counts**, at the velocities above. Per-run
release `ENC_LATCH`: 25, 38, 38, 38, 51 µsteps; closing-to-release 721, 725,
726, 714, 713 µsteps; 2530-2531 ms each. That is better than board 2's 4 counts.

#### Switch reporting delay — 44.61 ms, and it validates the two-stage homing

Measured with `t`: one approach at 0.200 rev/s and one at 0.010 rev/s, both
latched by the chip at the closing edge in one position frame.

```
fast latch: 719 usteps at 10240 usteps/s
slow latch: 285 usteps at   512 usteps/s
difference: 434 usteps  ->  reporting delay = 44.61 ms
```

Debounce plus signal path. The MAX6816's own debounce is ~40 ms, so this is the
part behaving as specified rather than anything board-specific.

That delay is the whole reason homing has two stages: it costs **457 µsteps of
overshoot at the approach velocity** and only **22.8 µsteps at creep**, a 20:1
improvement, which is why the release edge taken at creep is the datum and the
closing edge is not. `kHomeCreepBoundMicrosteps` is **2560**, comfortably above
the 457 µstep approach overshoot it has to clear — 5.6× margin, so the creep
stage cannot run out of bound before it finds the release edge.

**Record any future homing repeatability figure with its velocities**, because
this delay is what makes the offset velocity-dependent.

#### Angle output, reset state — NOT YET MEASURED. The 150 mV was the scope.

There is no `DAC80501` driver in the firmware, so nothing writes the DAC. With
`+5V_SW` up and the DAC untouched the BNC shows the reset-state output, which is
a real and useful number: `DAC80501Z` has a **zero-scale** power-on reset
(datasheet confirms the `Z` suffix; `M` is midscale), so the DAC sits at code 0
and the BNC should show the `OPA197`'s output floor. Design expectation is
**~25 mV**, with the valid angle range mapped to start at 50 mV so a driven 0 V
stays out-of-band.

**A scope on the BNC read 150 mV, and that number is void.** It read **the same
150 mV with the BNC cable disconnected**, so it is the instrument's own
baseline — channel offset, or an attenuation/coupling setting — and says nothing
whatever about the board. Recorded here only so nobody later finds "150 mV" in a
note and treats it as a measured floor. **The angle output floor on this board
is still unmeasured.**

Take it with a **DMM on DC volts, centre to shell at the BNC**: no attenuation
setting, no coupling question, resolution to 0.1 mV. That is also the instrument
the per-board gain/offset fit needs, so it is not a detour. A scope is the wrong
tool for a DC level of tens of millivolts, and this is exactly how it goes
wrong.

If a scope is used anyway, three settings all shift a reading like this by
roughly the factor in question, which is why the number was ambiguous before the
cable-off check settled it: probe attenuation (10× against a 1:1 BNC cable
multiplies by ten), AC coupling (removes the DC level entirely), and 50 Ω input
termination (divides by 5.98 against the 249 Ω series output resistor, and loads
the `OPA197` besides).

Two other things produce 0 V here and must not be read as a legitimate end of
travel: an unpowered output section, held down by the 100 kΩ `R2005`, and a
reference alarm from a misconfigured `REF-DIV`.

#### Left energised deliberately

The board was left with the **driver disabled and the rail up** on purpose, so
`+5V_SW` keeps the `DAC80501`/`OPA197` section powered for that measurement.

Stage 4 over the pyControl RJ-45 has not been run on this board.


### Two stage 2/3 check defects fixed, 2026-09-09 — and a backlash figure

Both were checks that failed on a correctly working board, which is the failure
mode that costs the most time: it trains you to ignore the check.

#### `IOIN` no longer asserts on connector-dependent bits

Stage 2's register check compared the whole `IOIN` low byte against a single
expected `0x11000010`. **Five of those eight bits are driven by whatever is
plugged into the motor, encoder and limit-switch connectors**, so no fixed value
can be right, and the check failed on every board that was actually wired up.
The two v0.2 units "disagreeing" was chased as a possible pair of assembly
defects.

Now only the four board-invariant fields are asserted — `VERSION`, `DRV_ENN`,
`SD_MODE` and `REFR_DIR` (a hard GND tie, not a connector). The connector bits
are still printed, because that is how you watch a switch actuate or an encoder
turn; they are just not a verdict. **Stage 2 on board 4 fully connected is now
5 checks, 0 failed.**

The host tests were encoding the bug — they asserted that `0x11000011` and
`0x11000018` must FAIL, and both are correct readings from real hardware. They
now assert those pass, alongside board 2's `0x11000014`, plus a mask test that
every low-byte bit is either asserted or explicitly connector-dependent and
never both.

A live demonstration of why this had to change: across two runs minutes apart on
the same board, `IOIN` read `0x11000018` then `0x11000010` — `ENCA` went 1 to 0
purely because the shaft was at a different position.

#### `g` now separates the mechanism from the encoder

The round-trip check blamed the encoder for a hard stop. The `legs_clean` guard
did not catch it because **driving into an end stop open-loop still reports
`kTargetReached`** — the ramp generator only counts the steps it issued, so with
partial clearance the move "succeeds" and the encoder asymmetry is the only
witness.

The verdict now classifies the round trip first, through
`classifyRoundTrip()` in `../mouse-joystick-firm/src/Conversions.hpp`. It lives
there rather than beside `MoveReport` because `MotionSetup.hpp` needs
`Arduino.h` and `TMC51X0.hpp`, and this arithmetic has to be reachable from the
host tests — which now pin it with the real measured numbers.

**Measured backlash, which is new data.** Reversal costs a fixed amount, and
which leg pays it depends on which way the mechanism was last moving — homing
ends with a back-off, so the first leg may already be taken up. That makes
legitimate asymmetry **one-sided**, not symmetric:

| out / back (µsteps) | apart | mechanism |
| --- | --- | --- |
| 1203 / 1190 | 1.1% | free |
| 1165 / 1177 | 1.0% | free |
| 1280 / 1191 | **7.0%** | free — one backlash-worth, ~89 µsteps = 7 counts |
| 704 / 1177 | **40.2%** | outbound against the far hard stop |

So the envelope is "up to ~7% is backlash, ~40% is a stop". The threshold is
**20%**, roughly the geometric middle. A first draft used 10%, which did not
misclassify anything observed — 7.0% is inside it — but 1.4× margin over
measured backlash is thin, and a slightly stiffer gear pair would cross it.

A genuine CPR error lowers both legs equally and therefore stays symmetric,
which keeps that diagnosis reachable. That is deliberate.

`g` also now says up front that it jogs toward the far hard stop first, so run
it from mid-travel or straight after `h`.

#### Bench trap: picotool's flash write is intermittently flaky on this board

After many reflashes in one session, `picotool` began failing mid-write with
`ERROR: The RP2040 device returned an error: <unknown>`, and PlatformIO reported
it as a failed upload. **It is not a bad flash sector and not a dead board:**

```
picotool info -a  ->  RP2040, revision B2, flash size 16384K,
                      flash id 0xE4654C159F171E34
```

The bootrom reads the flash correctly, and the failures are size-independent —
in one pass a 183 KB image wrote, a 209 KB image failed, and a **251 KB image
wrote**. So it is the USB transfer, not the part. `lsblk` also showed a stale
`sdd` at **0 B** where `RPI-RP2` had been, which is the host holding a dead
block device across re-enumerations and is a good tell.

**Recovery: just retry the load, in a loop.** Driving `picotool load` directly
with a retry and then `picotool reboot` is more reliable than
`pio run -t upload`, because it skips the 1200 baud touch once the board is
already in BOOTSEL. A physical re-plug was never needed. Note that a genuine MCU
power cycle needs **both** USB and the RJ-45 out, since the MCU domain is ORed
from both.

### IRUN 17 run, 2026-09-09 — the 36 V transient burst, and a repeatability surprise

Everything above was taken at `IRUN` 8. This run set `IRUN` **17 = 0.421 A RMS**
(`n`, then `c` to re-verify), the ceiling settled by the thermal survey, with
`vsense` read back as 1 before the driver was enabled.

#### Homing repeatability at IRUN 17 is 0 encoder counts

| `IRUN` | A RMS | runs | spread | closing-to-release |
| --- | --- | --- | --- | --- |
| 8 | 0.211 | 5 of 5 | 26 µsteps = **2.0 counts** | 713-726 µsteps |
| **17** | **0.421** | 5 of 5 | **0 µsteps = 0.0 counts** | 620-628 µsteps |

Both at 0.200 rev/s approach, 0.010 rev/s creep. At `IRUN` 17 every one of the
five counted runs latched at **exactly 12 µsteps** — not a spread that rounded
to zero, an identical reading five times. The closing-to-release figure also
dropped by ~90 µsteps and tightened.

The likely reading is mechanism compliance during the creep: at twice the
holding torque the gear pair is taken up harder and the datum stops moving. It
is a reason to prefer 17 beyond the current-headroom argument, and it means
**any repeatability figure has to be quoted with its `IRUN` as well as its
velocities**.

No faults across the whole run: `ot`=0, `otpw`=0, `drv_err`=0 on every poll,
`DRV_STATUS` `stst`=1 with `cs_actual`=2 at standstill.

#### What was driven, for the scope capture

Probing `+36V_SW`. Transients generated at `IRUN` 17, in order:

- 6 single jogs alternating direction — 6 accel/decel cycles at jog velocity
- 1 `g` round trip — 2 more, with a reversal between them
- 4 further jogs closing on the switch, one ending **stopped by the switch**
- 1 `W` witness sweep — 8 short 128 µstep steps onto the switch and off
- 1 `h` plus `H`'s throwaway and 5 counted runs = **7 approaches at 0.200 rev/s,
  each ending in a hard stop at the switch** — the fastest decelerations
  available, and the ones that matter most for inductive kick

#### Trap: `H` and `W` both refuse or mislead from the wrong starting position

Two commands were silently ineffective before this was noticed, and both are the
same class of problem as `g`'s false CPR verdict:

- **`H` refuses outright after a reflash** — `Run 'b', 'c' and 'w' first.` The
  switch-polarity witness does not survive a reflash, and until it is re-run
  `h` and `H` both decline. An earlier `H` in this session was issued and did
  nothing; the transient burst it was supposed to generate never happened, and
  the only symptom was the absence of output.
- **`W` failed with `REFL_STEP never changed`** and pointed at `U1301`'s output
  joint — "the open question the two rig boards left behind". It was nothing of
  the kind. The sweep is bounded, it used 3456 µsteps (24.3°) without reaching
  the switch, and the mechanism had simply drifted ~40° away during the jog
  burst. Four `j` jogs brought it into range and `REFL_STEP` asserted normally.

**So `W`'s failure text names a hardware suspect before it names its own
bound.** Same shape as `g`: a command that fails on starting position while
blaming a component. Worth the same treatment if it bites again.

Confirmation the switch is fine, in a completely different position frame:
engaged at 7068 µsteps, released at 6812, **throw 256 µsteps** — identical to
the 256 µsteps measured earlier at a different frame offset.

### 36 V transient, 2026-09-09 — observed flat at 36 V, and theory agrees

Scope on `+36V_SW` through the whole IRUN 17 burst above. **Observed: right on
36 V throughout, no dips or spikes seen.**

The DC level reading 36 V is itself the useful half of that: it confirms the
probe scaling, which after the BNC episode the same day was the thing most worth
confirming before any peak number got recorded.

**Theory says the motor cannot lift this rail, so a flat trace is the expected
result rather than a lucky one.** The board carries `C1213`+`C1214` = **200 µF**
of bulk on `+36V_SW`:

```
bulk energy at 36 V     = 0.5 * 200e-6 * 36^2      = 130   mJ
coil energy, both phases= 0.5 * 6e-3 * 0.6^2 * 2   =   2.2 mJ   (L estimated)
worst case, all coil energy into the bulk with no loss:
  V = sqrt(2 * 132.2e-3 / 200e-6)  =  36.4 V   ->  a 0.4 V rise
```

The motor's inductance is **not recorded anywhere in this repository** — 6 mH
per phase is a NEMA-8-class estimate, so treat the 2.2 mJ as an order of
magnitude. It does not matter: the coil energy is ~1.7% of the bulk energy, so
even a 3× error in L keeps the rise around a volt. 200 µF is simply an enormous
stiffness against a NEMA 8's coils. The TMC5130A also recirculates most of that
energy through the chopper rather than returning it to the rail.

#### What this does and does not establish

**It does not yet bound the peak.** A human watching a live trace cannot see a
microsecond-scale event: a DSO in normal acquisition mode captures a small
fraction of elapsed time between acquisitions, so a narrow spike falls in the
dead time. "Watched it and saw nothing" is consistent with a flat rail and also
with a 2 µs excursion every few hundred milliseconds.

**One cheap step converts it into a bound:** arm a **single-shot trigger at
40 V, rising**, then re-run the burst. If it never triggers, the peak was below
40 V for the whole armed window — 9 V of margin to the TMC5130A's **49 V**
inductive-load absolute maximum, and the TVS populate question is answered with
evidence rather than impression. Peak-detect or min/max envelope mode does the
same job, because it uses the acquisition hardware's envelope rather than the
displayed samples.

**Do not close the TVS item on the eyeball result.** Note also that the RC
snubber footprint across the driver's `VS`/`GND` and the entry TVS position are
both already on the board, so either outcome is a populate decision, not a
respin.

**And note the scope was on `+36V_SW`, downstream of the high-side switch.** An
entry TVS also covers supply-side events this test does not produce at all —
hot-plugging the 36 V supply, and cable-inductance ringing on insertion. The
TMC5130A datasheet's own warning is about supply ringing from stray inductance,
which is an input-side phenomenon. The motor-driven case looks clear; the
supply-side case has not been tested.

### DAC80501 driver written and exercised on hardware, 2026-09-09 evening

`../mouse-joystick-firm/src/DAC80501.hpp` + `src/DAC80501Registers.hpp` +
`src/DAC80501/`, with `examples/AngleOutput` as its bring-up console. Every
register address, reset value, field position and I2C address came out of TI
SBAS794E rather than from memory; a local copy is at
`../kicad-libs/tmp/dac60501.pdf`, which despite the filename is the family
datasheet and covers the 80501 throughout.

**Supports both transports**, decided later by the `SPI2C` strap: `SpiTransport`
and `I2cTransport` behind one `Transport` interface, injected into the device
class so the second DAC80501 instance at v1.0 (the brake current setpoint) can
share a bus on its own chip select.

#### Verified on board 4 over SPI1, rail up, bus closed

```
[1] rail        +3.3V_SW up in 132 ms
[2] bus switch  closed, GP10/GP11/GP13 now reach the DAC
[3] SPI1        SCK GP10, TX GP11, SYNC GP13
[4] DAC         GAIN 0x101, full scale 2.5000 V at the DAC, 3.3000 V at the BNC
```

| Commanded | DAC | BNC expected |
| --- | --- | --- |
| code 0 | 0.000000 V | 0.000000 V |
| code 0x8000 | 1.250000 V | 1.650000 V |
| code 0xFFFF | **2.499962 V** | **3.299950 V** |

Full-scale code lands one LSB short of full scale, as it must — the denominator
is 65536, not 65535. **One LSB is 38.15 µV at the DAC and 50.35 µV at the BNC**,
against the `AD7616-P`'s 152.6 µV OneBox step, so the DAC resolves about 3×
finer than the OneBox can record. That is the number the span argument turns on.

**Nothing here is a measured output voltage.** `ANGLE_OUT` reaches no RP2040 ADC
on v0.3 — the three ADC pins are the rail sense, `HV_SNS` and a spare — and over
SPI the DAC cannot be read back either. So the whole column above is what the
board was *asked* for. **The gain and offset fit still needs a DMM on the BNC**,
and `examples/AngleOutput` has an `s` command that parks at 0, midscale and full
scale for 15 s each to make that a one-command job.

#### The ordering interlock, and it was checked rather than assumed

`GAIN` resets to `0x0001` — a **5.0 V** full scale from the 2.5 V internal
reference — while this board wants 2.5 V. A board that writes DAC data before
writing `GAIN` therefore asks for double. `Dac80501::begin()` writes `CONFIG`,
then `GAIN`, then `SYNC`, and `setCode()`/`setVolts()` refuse until it has
succeeded, so the mistake is unrepresentable rather than merely documented.

Exercised on hardware: after `r` (soft reset) the driver reports
`configured: no` and a full-scale write comes back `Run 'b' first.` The `Z`
orderable saves this from being a live hazard at power-up — it resets the data
register to zero scale — but an `M` part would sit at midscale of a possibly
wrong span, so the interlock does not lean on that.

#### `verifyConfiguration()` reports honestly, which is the point

On this board it returns **`kNotSupported`** and says so in as many words:
there is no SDO pin, nothing was checked, and the only real check on `GAIN` is
measuring the output. The result is a four-way enum — verified / mismatch /
read-failed / not-supported — rather than a bool, because "could not check" and
"checked and correct" collapsing into one `false`/`true` is how a board ends up
trusted on no evidence.

#### Left for the morning

- **A DMM on the BNC.** Three-point fit, and the output floor. Expected floor is
  ~25 mV; the 150 mV scope reading earlier the same day was the instrument's own
  baseline and is void.
- **`VREFIO` = 2.500 V** at the pin, also a DMM job.
- **`GAIN` `0x0101` against `0x0000`.** Both give a 2.5 V full scale by
  different routes and the host tests pin that they are equal in span. `0x0101`
  runs the output buffer at a gain of two, doubling that stage's offset and
  noise; `0x0000` keeps the DAC core at the full 2.5 V reference. With a meter on
  the output the quieter one is measurable, and it is a one-constant change in
  `examples/AngleOutput`. The pcb plan specifies `0x0101`, so that is what is
  built.
- The board was left **powered down** — DAC at zero scale, bus open, `HV_EN`
  low — rather than energised unattended overnight. `b` brings it all back.

## Board 3 — `E4654C159F591D34` — Stage 4, Protocol

**First protocol contact over the RJ-45, 2026-09-03. Passed, with the 36 V
supply off.** Firmware `examples/PyControlLink`. Peer was a pyControl Breakout
1.2 on port 1, driven from the pyboard's REPL with `machine.UART(4)` directly --
no pyControl framework, no hardware definition, no device class. Deliberately:
first contact should not have the framework as a second unknown, which is the
same reason stage 2 proved the SPI bus with raw datagrams before using TMC51X0.

Sent `id;11`, received:

```
ack;11;hw=rev0;serial=E4654C159F591D34;fw=0.0.0;proto=1;axes=1;caps=motion+home+freewheel+instr+hv;rxbuf=120
```

What that one line establishes, none of which had been shown on hardware before:

- **The UART wiring and polarity.** Controller `DIO-A` (pin 1) reaches this
  board's `UART0 RX`, and this board's TX reaches `DIO-B` (pin 4). A crossed
  cable would have produced silence.
- **The baud rate.** 115200 requested, `UART4` achieving 115384 (+0.16%). A
  complete 108-character reply with no framing errors.
- **The framing codec on real hardware**, byte-identical in shape to the corpus
  case `id-reports-version-serial-and-axis-count`.
- **`ID` answers before ARM and with the motor rail off**, which the protocol
  requires and which is what makes it safe to use for discovery.
- **Port 1 = `UART4`** on the deployed breakout, as `devices/breakout_1_2.py`
  says.

### The read-only surface, verified after the `STATUS` fix

Same board and port, 2026-09-03, still with the 36 V supply off. Ten commands,
deliberately with the USB mirror **not** being drained, so the mirror's
non-blocking guard was exercised at the same time.

| Sent | Received |
| --- | --- |
| `id;40` | `ack;40;hw=rev0;serial=E4654C159F591D34;fw=0.0.0;proto=1;axes=1;caps=motion+home+freewheel+instr+hv;rxbuf=120` |
| `status;41` | `ack;41;state=IDLE;angle=0.0;xactual=0.0;homed=0;limit=0;faults=0;hv=0` |
| `limits;42` | `ack;42;travel_lo=-19.125;travel_hi=-9.0;v_max=36.0;a_max=3600.0;i_max=0.421` |
| `ping;43` | `ack;43` |
| `hv;44;state` | `ack;44;hv=0` |
| `ping` (no seq) | `nak;?;badframe` |
| `wibble;45` | `nak;45;badverb` |
| `moveto;46;-12.0` | `nak;46;notarmed` |
| `freewheel;47` | `nak;47;notarmed` |
| `status;48` | `ack;48;state=IDLE;angle=0.0;xactual=0.0;homed=0;limit=0;faults=0;hv=0` |

Two of those carry more than they look like:

- **`moveto;46;-12.0` proves an ordering, not just a refusal.** -12.0 is *inside*
  the travel this board just reported, so `notarmed` rather than `outofrange`
  shows ARMED is checked before the range check on real hardware. That is the
  safety-relevant ordering the shared corpus did not pin until mutation testing
  forced a case for it.
- **`status;48` answering at all** is the fix for the hang above, confirmed after
  nine prior commands and all the mirror traffic they generated.

### `hv on` passed, 2026-09-03 — and it is board 3's first power-chain result

36 V on `J201`, supply on. `hv;51;on` answered **`ack;51`**, and `hv;52;state`
then reported `hv=1`.

That single ack covers a lot of code that had never executed, and it is more than
a protocol result: **this is the first time the 36 V chain, the GPIO isolation
bus switch and TMC5130A communications have been exercised on board
`E4654C159F591D34` at all.** The board previously had no stage 1, 2 or 3 numbers.
An `ack` is only returned if every one of these succeeded:

- `PowerSequence::powerUp()` brought `+3.3V_SW` up and the RP2040's own ADC
  **measured** it crossing threshold. So `R203` is fitted on this unit as
  expected and the firmware staircase works here, exactly as it does on board 2.
- `connectBus()` closed the isolation bus switch.
- `beginSpi()` started SPI0 and `IOIN.VERSION` read back **0x11**, the TMC5130A
  signature.
- `communicating()` true, and `stepAndDirectionMode()` false — SD_MODE is tied
  to GND as designed, so SPI motion commands will actually do something.
- `MotionSetup::configure()` ran, which zeroes `XACTUAL`, the target and `X_ENC`.

**Stability:** `status` at t+0, t+3 s and t+10 s all read
`state=IDLE;angle=0.0;xactual=0.0;homed=0;limit=0;faults=0;hv=1`, and `faults`
reported `mask=0`. No spurious fault with the rail live and the bus closed.

The zeros are expected rather than suspicious — `configure()` zeroes all three
registers — but note they do **not** prove the position cache is live, because a
broken cache would also read zero. That is the next thing to check, and it can be
checked with the driver still disabled by moving the joystick by hand.

### The encoder cache is live, and `angle`/`xactual` genuinely diverge

With the rail up and the driver still **disabled**, the joystick was moved by
hand and `status` read twice:

```
ack;80;state=IDLE;angle=-22.866;xactual=0.0;homed=0;limit=0;faults=0;hv=1
ack;81;state=IDLE;angle=-22.866;xactual=0.0;homed=0;limit=0;faults=0;hv=1
```

Four things at once, none previously shown on hardware:

- **The position cache is live.** It went from 0.0 to -22.866 with no commanded
  motion, so `poll()` really is refreshing it from the encoder every pass. The
  fix for the `STATUS` hang is correct, not merely safe -- a broken cache would
  have kept reading zero and looked identical to a working one at rest.
- **The encoder counts**, and 22.866 deg = 3252 microsteps is a plausible
  fraction of the ~4000 microsteps of measured travel.
- **`angle` and `xactual` genuinely diverge.** The encoder moved and the ramp
  generator did not. This is the concrete case behind open question 5 in
  `uart-protocol.md` -- with a compliant state, "position" is two quantities --
  demonstrated on hardware rather than argued.
- **No fault was raised**, which is correct: divergence in a non-driving state is
  the joystick being moved, not a stall. That distinction is the rule the
  protocol layer must preserve.

**Do not read -22.866 as an absolute position.** The board was unhomed, so zero
was wherever `configure()` last zeroed the registers, not the switch. The value
is meaningful as a *change* and says nothing about the travel limits.

### Two more firmware bugs of the same class, found and fixed 2026-09-03

Both were fields that could not fail loudly, which is why they needed hardware
to find.

- **`status`'s `limit` was a hardcoded 0.** `limit_asserted_` was a member that
  nothing ever assigned. A host could have used it to decide homing was safe to
  start -- and it was about to be used that way during this very bring-up. It now
  comes from `RAMP_STAT.status_stop_r/l`, chosen by which end the switch is on,
  taken from the snapshot already read rather than a second register access.
  Those bits are plain status, not read-and-clear, and reflect the pin whether or
  not the hardware stop is armed, which is what makes them usable for reporting.
- **The homing approach had no encoder follow check.** The validated
  `homeToSwitch()` runs its approach through `moveTo()`, which has one:
  `kNotFollowing` maps to `HomeOutcome::kMechanicalStopFirst`. The non-blocking
  version commanded the target directly with no such check, making it strictly
  weaker than the implementation stage 3 proved -- and weaker exactly where it
  matters, since the approach commands 102400 microsteps (720 deg at the motor
  shaft) against a mechanism with 28 deg of travel, relying entirely on the
  chip's switch stop to end it. If the switch never asserts, nothing noticed the
  mechanism had stopped and the motor pushed against it until the 8 s timeout.
  The check is now in all four motion phases, with thresholds taken from
  `Conversions.hpp` so it and `moveTo()` cannot drift apart.

`hv on` was repeated after these fixes and answered `ack` again, with
`limit=0` now a real reading.

### The full motion path, under protocol control — 2026-09-03

`hv on` -> `home` -> `arm` -> `moveto` -> `disarm`, all over the RJ-45 from the
pyboard, with the motor moving. Representative sequence:

```
ack;190                                          hv on
ack;191   ev;HOMED;66447906;angle=-7.741          home
ack;200                                          arm
ack;201   ev;TARGET;94551056;angle=-14.766        moveto -16.0, ~100 ms later
ack;202;state=ARMED;angle=-14.766;xactual=-15.996;homed=1;limit=0;faults=0;hv=1
ack;203                                          disarm
```

Established:

- **Homing repeats.** `angle` at the parked position over four homes:
  -7.741, -7.741, -7.65, -7.741. A 0.09 deg spread is about one encoder count,
  consistent with the 2-5 counts measured on board 2 in stage 3.
- **Commanded moves track.** Between the two `status` reads above, XACTUAL moved
  -6.996 deg and the encoder -6.933 deg: a **follow ratio of 0.991**. The motor
  goes where it is told.
- **The heartbeat works, including the resolved retransmission rule.** About 150
  consecutive `ping;9` -- the *same* sequence number every time, byte-identical
  -- were each answered and each refreshed the watchdog. Under the draft's
  original rule those would have been served from cache and the safety timeout
  would have expired while the host was receiving acks. This is open question 1
  demonstrated on hardware.
- **`disarm` stands the watchdog down cleanly**, so a session can end without
  provoking a fault.
- **Fault recovery works.** `clrfault` after a `host_timeout` returned `ack`,
  state went to `IDLE` with `homed=0`, and a fresh `hv on` + `home` succeeded.
  `hv on` being needed again confirms the fault really did drop the rail.

### Measured: the host must poll faster than the draft implies

At **40 ms** pings against the 100 ms timeout, the board faulted `host_timeout`
21 ms after a move completed. At **20 ms** pings the identical sequence ran
clean, 140 iterations, no fault.

The cause was an ordering defect, now fixed: the watchdog was evaluated before
the link was read, so a heartbeat that had already ARRIVED but was not yet parsed
did not count -- the board could fault on a ping sitting in the UART's receive
buffer. Reading first closes it.

Worth keeping even so: 40 ms was chosen as "comfortably inside 100 ms" and it was
not. `tasks/mouse_joystick_check.py` pings at 40 ms. **Re-measure the margin
after the fix rather than assuming it is now fine.**

### CORRECTION to existing firmware: `ENC_LATCH` is always 0 on rev 0

Found while trying to fix the datum offset below, and it applies to the
**validated** stage 3 code, not just the new protocol firmware.

`MotionSetup::moveTo()` fills `report.latch_encoder` from `ENC_LATCH`, and
`homeToSwitch()` fills `report.coarse_encoder` and `report.fine_encoder` from it.
**`ENC_LATCH` latches `X_ENC` on the encoder's N (index) event, not on the
reference-switch event that fills `XLATCH`.** Rev 0 leaves the encoder index
no-connect with `ENCN` terminated by `R1201` 10 kOhm
([`docs/interface-map.md`](interface-map.md)), so there is never an N event and
the register is permanently 0.

Every encoder-latch number those reports carry is therefore structurally zero, on
this revision, by construction. Any stage 3 report that shows one should be read
as "no data", not as a measurement. Same class as the `limit` field above: a
reported number that cannot carry information.

### RESOLVED: the position-frame offset, by zeroing both frames at the park

`STATUS` reports `angle` (encoder) and `xactual` (ramp generator). After homing
they differed by a constant ~1.2 deg / 166 microsteps, so a host commanding
-16.0 read back -14.766 on a ~10 deg usable range.

**Peter's fix: zero BOTH frames after the clearance move, not at the switch
edge.** Two earlier attempts failed -- one because `ENC_LATCH` is permanently 0
on rev 0 (below), one whose arithmetic never closed -- and this is better than
either, because it fixes more than the offset:

| | Before | After |
| --- | --- | --- |
| `moveto -8.0` reads back | -6.8 (offset ~1.2) | **-8.016** |
| `ev;HOMED` reports | `angle=-7.741` | **`angle=0.0`** |
| Is zero commandable? | no, outside travel | **yes, it is the park** |
| Travel limits | -19.125 .. -9.0 | **-10.125 .. 0.0** |

Measured after the change: `moveto -8.0` -> `angle=-8.016`, `xactual=-7.995`;
the two frames agree to 10 microsteps, under one encoder count. A `moveto 0.0`
round trip returned without fault.

Why this is the better datum, beyond removing the offset:

- **Zero means something.** It is where homing leaves the joystick, so it is a
  position a host can command rather than one the travel limits exclude, and the
  "homing parks exactly on `travel_hi`" edge noted earlier is gone.
- **The firmware and the shared corpus stop disagreeing.** The corpus expects
  `ev;HOMED;...;angle=0.0` and the hardware now reports exactly that. The
  previous datum made the two implementations differ on a corpus-pinned value.
- What is kept from the old scheme: `XACTUAL` is still re-based to `XLATCH`
  first, so the clearance move is measured from the switch EDGE rather than from
  wherever the chip stopped. The stop position varies with approach velocity (89
  microsteps at 0.200 rev/s against 4.5 at the creep); the latch does not.

### Two further firmware bugs found by the same runs

**The homing approach keyed off the wrong flag.** An approach that started ~25
deg from the switch reached it -- `status` showed `limit=1` -- and then sat until
the 8 s timeout, faulting `home_timeout` with the joystick resting on the switch.
Four earlier homes, all starting near the switch, had succeeded.

`status_latch_*` are READ-AND-CLEAR, so whether a poll catches them depends on
its timing against the edge; `status_stop_*` are plain status bits that survive
polling. The validated `homeToSwitch()` already knows this -- it keys off
`kSwitchStopped` and treats the latch as a preference, with an explicit fallback
to reading `XLATCH` later. The non-blocking version had no fallback, so a missed
flag was a hang. Now keyed off the stop bit, with `XLATCH` read afterwards, which
is safe because the chip writes it at the edge and reading does not clear it.

**`ev;HOMED` reported a stale angle.** The event carried the cached position from
*before* the datum writes -- observed as `ev;HOMED;...;angle=8.459` immediately
followed by a `status` reading `angle=0.0`. The event is the thing a host
timestamps and records, so it is the one that must not be stale. The cache is now
refreshed as part of applying the datum.

### CORRECTION: the `host_timeout` faults were the test harness, not the firmware

Earlier in this session two `host_timeout` faults were attributed to firmware --
a real ordering defect was found and fixed (the watchdog was evaluated before the
link was read, so a heartbeat already in the UART buffer did not count, and
reading first closes that race). **But the faults that were actually observed
were caused by the test harness.**

Instrumenting the loop period showed it running at **72 ms per iteration, not the
20 ms intended**: MicroPython's `UART.read()` blocks for the configured `timeout`
when the buffer is empty, so a `timeout=50` added 50 ms to every pass. The
"20 ms pings" were 72 ms and the "40 ms pings" were ~90 ms, both against a 100 ms
watchdog. With `timeout=20` the same sequence runs clean.

So the recorded claim that the host must poll faster than the draft implies is
**withdrawn as a measurement.** The ordering fix stands on its own merits, and
the real margin is unmeasured. Set the UART read timeout deliberately before
timing anything on this link -- and note `tasks/mouse_joystick_check.py` pings at
40 ms, which is fine at a 100 ms timeout if the poller is actually prompt.

### End state

`disarm`, then `hv;off` -> `ack`. Rail down, driver disabled, board left safe.
The final `status` froze mid-return-move at `angle=-0.816;xactual=-0.211`; a
0.6 deg gap there is ordinary dynamic lag of the encoder behind the ramp
generator, captured because the fault stopped the cache updating, and not a
datum error -- at rest the two agree to under one encoder count.

### `freewheel` while armed, and both ways back out — 2026-09-03

The compliant state, which is the part the actual trial depends on. Run inside a
~35 ms ping loop so the host-loss watchdog stayed fed throughout.

| Step | Reply |
| --- | --- |
| `arm` | `ack` |
| `moveto -5.0` | `ack`, then `state=ARMED;angle=-5.041;xactual=-4.999` |
| `freewheel` | `ack` |
| `status` | `state=FREEWHEEL;angle=-4.866;xactual=-4.999` |
| `moveto -3.0` | `ack`, then `state=ARMED;angle=-3.691;xactual=-2.995` |
| `freewheel` | `ack` |
| `stop` | `ack`, then `state=ARMED;angle=-3.783;xactual=-4.05` |
| `disarm` | `ack`, then `state=HOMED;angle=-3.783;xactual=-3.783` |

- **The compliant state works and the divergence is real.** In FREEWHEEL the
  encoder moved 0.133 deg and the ramp generator did not -- the joystick settled
  when the driver was released. That is the effect that makes `angle` and
  `xactual` two quantities rather than one, observed without anyone touching the
  mechanism.
- **Both exits work**: `moveto` re-engages implicitly and moves, `stop` takes the
  joystick back and holds it, `disarm` leaves it held in HOMED.
- **The resync is exact when nothing follows it.** After `disarm` both frames
  read -3.783. That isolates the resync from the discrepancies below.

### Firmware bug: leaving FREEWHEEL never re-energised the driver

`freewheel` releases the driver, and every path out of FREEWHEEL resynced and set
`ARMED` **without re-enabling it** -- despite a comment in the code claiming the
move "re-engages implicitly". The ramp generator advanced with no torque, the
encoder did not follow, and the follow check faulted `not_following` (bit 2)
after ~1.4 deg of commanded travel.

Same class as the homing driver-enable deadlock, and **the third time the follow
check has caught a state transition that forgot to energise what it was about to
use.** All three exits were separate omissions; they now share one
`leaveCompliance()` that resyncs and re-enables as one operation, because a host
must not be able to be interrupted between the two.

### OPEN: sub-degree discrepancies at the release/re-engage boundary

Two numbers above do not close. They are small but not noise:

- `freewheel` -> `moveto -3.0`: `xactual=-2.995` against `angle=-3.691`, a
  0.70 deg gap. The resync had set both to -4.866 immediately before, so the
  encoder moved 1.175 deg where the ramp generator commanded 1.866.
- `freewheel` -> `stop`: `xactual=-4.05` against `angle=-3.783`, 0.27 deg, when
  the resync should have left them equal and no motion was commanded.

**Leading hypothesis: the rotor snapping when the driver re-energises.** A
stepper's electrical angle repeats every four full steps, so re-energising pulls
the rotor to the nearest matching position -- bounded at roughly +/-3.6 deg at
this motor's shaft however far the joystick was moved while compliant. Both
figures sit inside that.

If so, the fix is an ordering change: **re-enable first, let the rotor settle,
resync after** -- so the resync captures the post-snap truth rather than a
position the snap then invalidates. Deliberately NOT done yet, because it has a
plausible failure of its own: energising against a stale `XACTUAL` derives the
driver's electrical angle from where the ramp generator *thought* the joystick
was, so the snap would be toward that rather than away from it.

Deciding it needs a measurement, not a preference: park, freewheel, move the
joystick a known distance by hand, and read both frames before the re-engage,
immediately after, and after the resync. Until then the effect is bounded,
sub-degree, and the encoder stays the trustworthy frame -- which is what `STATUS`
reports.

### `armpull` argument handling verified; `PULL` implemented but NOT confirmed

`armpull`'s validation is correct on hardware, tested from `HOMED` so no
watchdog was involved:

| Sent | Reply |
| --- | --- |
| `armpull;361;-5.0` | `ack;361` |
| `armpull;362;-50.0` | `nak;362;outofrange` |
| `armpull;363` (no argument) | `nak;363;badargs` |
| `armpull;364;abc` | `nak;364;badargs` |
| `armpull;365;0.0` | `ack` — inclusive upper bound |
| `armpull;366;-10.125` | `ack` — inclusive lower bound |

**It was a validated no-op.** Nothing checked the threshold, so `PULL` could
never fire; the Python simulator only emitted it from a test-injection hook. Both
ends now implement detection, and implementing it exposed that they had
**different rules** -- the fork the shared corpus exists to prevent, and one the
corpus could not catch because no corpus case can move an encoder.

The rule is now a **crossing**, on both ends: `ARMPULL` records which side of the
threshold the joystick is on, and `PULL` fires on crossing to the other side.
The simulator previously compared magnitudes, `abs(angle) >= abs(threshold)`,
which agreed with the firmware only because this board's travel happens to be
one-signed -- on the simulator's own default travel of -20..20 a threshold of
-5.0 also fired at +5.0, and a task that presented past the threshold got a pull
for free. Recording the side invents no sign convention, which is what lets the
mirrored left and right joysticks share one firmware.

Gated to `FREEWHEEL` only: under commanded motion a crossing means the board did
it, and reporting that as a pull would put a fabricated event into a behavioural
dataset.

**API consequence worth knowing:** re-arming while the joystick still sits past
the threshold arms from the far side, so the next pull would have to be in the
other direction. A task must present before re-arming -- which is the trial's
natural order anyway.

### OPEN: an anomalous frozen encoder reading during the pull window

The hand-pull test did **not** confirm `PULL`, because the encoder reading was
already wrong before the joystick was touched.

Sequence: home to `angle=0.0`, `arm`, `moveto -5.0`, `armpull -8.0`,
`freewheel`, then a 17 s window sampling `status` every ~0.6 s while Peter pulled
the joystick. Every one of the twelve samples read **identically**:

```
state=FREEWHEEL;angle=-40.95;xactual=-4.999;homed=1;limit=0;faults=0;hv=1
```

What that rules out and what it leaves:

- **-40.95 deg is impossible mechanically.** Travel is ~28 deg at the motor
  shaft and the commanded position was -5.0.
  **Corrected 2026-09-09: the premise is wrong.** The hard stops are movable and
  both mechanisms have ~60 deg of range, so -40.95 deg is not out of reach. The
  rest of the case against this reading — frozen across the whole window, through
  a physical pull — is unaffected and still stands on its own. See
  [The 28 deg travel figure is a hard-stop setting, not a mechanism
  property](#the-28-deg-travel-figure-is-a-hard-stop-setting-not-a-mechanism-property).
- **It was frozen across the whole window**, through a physical pull, so the
  encoder was not tracking. `xactual` being frozen is expected in FREEWHEEL --
  nothing turns the ramp generator -- but `angle` should have moved.
- **It is not a scaling error.** Three commanded moves measured immediately
  afterwards tracked at ratios 0.947, 1.127 and 0.871 -- scattered but around
  1.0, nowhere near the 8.19x that -40.95 against -5.0 implies.
- **It is not a dead encoder or a dead bus.** `hv on` re-zeroed both registers
  and a subsequent `home` worked normally, reporting `angle=0.0`.
- **No `PULL` fired, and that is consistent.** If the cache already read -40.95
  when `armpull -8.0` ran, detection armed from BELOW the threshold, so it was
  waiting for a crossing upward past -8.0 that never came. The rule behaved
  correctly on bad input.

So the fault is in how the encoder value got to -40.95 and stopped changing, and
it happened once. Candidates not yet separated: spurious counts on `ENC_A`/`ENC_B`
from motor commutation noise while the driver was energised; a `poll()` that
stopped refreshing for a reason not yet identified; or a stuck read of `X_ENC`.

**This is exactly the question the InstrumentPort's encoder taps exist for.**
`docs/instrument-strategy.md`: "There is no PIO cross-check in any revision, so
the TMC5130A's `X_ENC` register is the only count on the board and nothing in
firmware can contradict it. Raw edges plus SPI reads of that register, in one
capture, make the comparison by hand." `ENC_A`/`ENC_B` are LA5032 channels 0 and
1, `FW_TRIG1` is channel 17, and the analyzer on this board is identified
(`1-5.1.4`). Capture a freewheel pull and compare the raw quadrature against
what `STATUS` reports -- that is the measurement, and it needs no new firmware.

### Noted: the follow check is one-sided

It fires when the encoder moves LESS than commanded (`|ratio| < 0.25`) and
cannot fire when it moves more. An encoder over-reading by 8x sails through, as
this run demonstrates. That is the right bias -- under-following is the case that
means the mechanism is being pushed -- but it means over-counting has no
detector at all, and the earlier ~1.2 deg and ~0.3 deg discrepancies were all
found by reading numbers rather than by any check.

### The encoder was RIGHT: -28.083 deg is the mechanical end of travel

A second pull attempt, this time with the joystick pulled only after it went
limp, produced the trace that reframes the earlier "anomalous" readings:

| Sample | `angle` | `xactual` |
| --- | --- | --- |
| freewheel + 0.9 s | **-5.941** | -4.999 |
| + 2.3 s | -5.941 | -4.999 |
| + 3.7 s | **-6.033** | -4.999 |
| + 5.1 s | **-28.083** | -4.999 |
| + 6.5 s ... + 19 s (11 samples) | -28.083 | -4.999 |

Read it as motion rather than as corruption and it is entirely coherent:

1. **-5.0 -> -5.941 when the driver released.** The joystick settled 0.94 deg
   under its own load the moment it went compliant. `xactual` stayed at -4.999
   throughout, which is the whole point of reporting both.
2. **-5.941 -> -6.033** is the pull starting.
3. **-28.083 deg = 3994 microsteps**, which is `conversions::kMeasuredTravelMicrosteps`
   (4000) to within 6 microsteps. **The joystick was pulled to its mechanical end
   of travel.**
4. **Frozen for the next 14 s because it was resting against the stop**, which is
   the correct reading for a stationary joystick, not a stuck register.

So the encoder tracked the pull faithfully from beginning to end. The earlier
-40.95 and -48.5/-51.2 readings are best explained the same way -- real
displacement, in runs where the datum was not what I assumed -- and Peter's own
suspicion that he pulled at the wrong moment (while the driver was still
holding) fits: forcing a held motor back-drives it, and the encoder on the
motor's rear shaft reports that honestly.

**Downgrade the "anomalous frozen encoder" item above from a suspected fault to
a misreading of correct data.** What remains genuinely unexplained is nothing:
there is no evidence of an encoder or reporting fault in any of it.

### MEASURED: the travel limits are wrong by a factor of nearly three

This is the actionable finding. `examples/PyControlLink` sets
`travel_lo = -10.125` deg, derived at a desk from `kMeasuredTravelMicrosteps`
less a clearance step at each end. **The left joystick reached -28.083 deg below
the park under a hand pull**, so the mechanism has roughly 28 deg of usable
travel below the park and the firmware permits 10.

Consequences:

- Two thirds of the mechanism's range is unreachable by `moveto`. Any trial that
  wants to present the joystick further than 10 deg from the park cannot.
- `kMeasuredTravelMicrosteps` = 4000 was measured on board 2, the RIGHT joystick,
  from the switch. It does not describe this mechanism from the park, and the two
  joysticks may simply differ. **Neither joystick's travel has been measured
  through the protocol.**
- The limits should come from a measurement on each joystick -- walk to each end
  under a bounded jog, record where the follow check or the switch stops it --
  not from a constant carried across from another unit.

### Harness bug: the `PULL` event may have fired and been discarded

`PULL` is **still unconfirmed either way**, and that is my test harness rather
than the firmware. The pyboard loop filtered replies with
`if r and b'ack;9\n' not in r`, which discards any read that contains a
heartbeat ack -- and an asynchronous event arriving in the same read as a ping
ack is exactly the common case. A crossing of the armed -8.0 threshold did occur
(-6.033 to -28.083), so if detection worked the event was emitted and thrown
away by the filter.

Fix the filter to `b'ev;' in r or b'ack;9\n' not in r` and re-run. Nothing about
the firmware is implicated.

### Analyzer capture NOT obtained: both LA5032s stopped capturing

The instrumented capture could not be taken. Both analyzers enumerate and answer
`--scan` normally, reporting 34 channels, but **every capture hangs** -- including
a 2000-sample single-channel request, and including command shapes that worked
earlier in the same session for the identity beacon. `sigrok-cli` reports:

```
sr: kingst-la2016: Unexpected run state, want 0x85eX, got 0x0000.
```

`0x0000` is the FPGA not running. No stray `sigrok-cli` process is holding the
devices. The likely cause is a capture killed mid-flight leaving the device
wedged in a way that firmware re-upload on `--scan` does not clear.

**Recovery needs a USB power cycle of the analyzers.** Worth adding to
`instrument-control`'s notes: do not kill a Kingst capture with a signal; let it
reach its sample count or trigger timeout.

### CONFIRMED: `PULL` fires, and the raw encoder edges corroborate `X_ENC`

Both remaining questions answered 2026-09-03, in one instrumented run.

**`PULL` works.** Armed at -8.0 with the joystick presented at -5.0, then
released and pulled by hand:

```
ev;PULL;131490670;angle=-8.016
```

It fired at **-8.016 against a threshold of -8.0** -- one encoder count past the
crossing -- exactly once, and did not repeat as the joystick continued to
-20.166 and rested there. Reproduced in two consecutive runs. That is the whole
trial mechanism end to end: park, present, arm, go compliant, pull, detect.

**And the encoder is independently confirmed.** LA5032 on the LEFT board
(topology `1-5.2.1`, identified by beacon), capturing `ENC_A`/`ENC_B` at
200 kSa/s, bounded by `FW_TRIG1` which this firmware now holds high for the whole
compliant window:

| Source | Displacement | In counts |
| --- | --- | --- |
| Raw quadrature edges | **14.490 deg** | **161** (163 transitions, **0 invalid**) |
| `STATUS`, from -4.999 | 15.167 deg | 168.5 |
| `STATUS`, from -5.941 (first post-release sample) | 14.225 deg | 158 |

**Agreement is 3 to 8 counts on a ~15 deg pull, 2-5%.** Zero invalid transitions
means the capture was not under-sampled, so 161 is a value and not a floor. The
sign difference between the raw decode and `STATUS` is the decoder's arbitrary
A/B convention against this harness's crossed channels and a positive
`ENC_CONST` -- not a discrepancy.

This is the measurement the InstrumentPort's encoder taps were put there for.
`ENC_A`/`ENC_B` reach no RP2040 pin on any revision, so `X_ENC` is otherwise
unfalsifiable; counting the raw edges is the only thing in the system that can
contradict it, and it does not. **Every "anomalous" encoder reading earlier in
this session was real motion**, and the register can be trusted.

Practical note for future captures: `sigrok-cli`'s default capture ratio put
roughly half the buffer BEFORE the trigger -- a 17.5 s capture yielded 8.8 s of
pre-trigger data and 9.0 s inside the window. Helpful here, since it also caught
the presenting moves, but size the post-trigger half deliberately rather than
assuming the whole capture follows the trigger.

### Travel survey, LEFT joystick — 44 deg and no stop found

Method: temporarily widen `travel_lo` to -45 deg so `moveto` cannot be what ends
the walk, then step out from the park in 2 deg increments and let the **encoder
follow check** find the hard stop. That check is the only detector at that end --
there is no switch there -- and it trips within about 1.4 deg of commanded travel
that the encoder does not confirm.

**It never tripped.** All 22 steps reached target, and the walk ended only when
the survey limit itself refused the next one:

| Commanded | `angle` | `xactual` |
| --- | --- | --- |
| -2.0 | -1.891 | -1.997 |
| -10.0 | -10.083 | -9.998 |
| -20.0 | -20.074 | -19.997 |
| -28.0 | -28.083 | -27.998 |
| -36.0 | -36.091 | -36.000 |
| -44.0 | -44.100 | -43.995 |
| -46.0 | `nak;743;outofrange` | — |

The encoder tracked the ramp generator to within 0.15 deg at **every** step over
44 deg. Afterwards the mechanism homed back to `0.0` normally, so the switch was
found from -44 and the position was reachable in both directions.

**So the firmware's limit of -10.125 deg was wrong by more than a factor of four,
not three.** It was derived at a desk from `kMeasuredTravelMicrosteps` (4000 =
28.1 deg), a constant measured on board 2 from the switch, which does not
describe this mechanism from the park.

### OPEN: 44 deg of WHAT? The encoder cannot answer this one

The measurement above is 44 deg of **motor shaft** rotation. It is not
necessarily 44 deg of joystick travel, and nothing electrical on this board can
tell the difference:

- The E4T sits on the motor's **rear shaft** while the gear train is driven from
  the front ([`docs/harness-pinouts.md`](harness-pinouts.md)), so the encoder
  measures the motor, not the mechanism.
- The follow check compares `XACTUAL` against `X_ENC`, and **both are
  motor-side**. A coupling that slipped downstream of the encoder would leave
  them in perfect agreement -- which is exactly what was observed.
- `.agents/AGENTS.md` lists "a slipping coupling" among the things the
  `XACTUAL`/`X_ENC` divergence detects. On this geometry it does **not**: that
  detector only sees faults between the ramp generator and the motor shaft.

Evidence on both sides. **For it being real travel:** the mechanism homed
successfully from -44, and homing requires the MECHANISM to move far enough to
actuate the switch. **Against:** the recorded travel is 28 deg, an earlier hand
pull stopped and sat at -28.083 for 14 s as though against a stop, and homing
from a slipped position near the switch would also succeed quickly.

The homing duration would separate them -- 44 deg at the 0.200 rev/s approach is
~610 ms against ~100 ms from near the switch -- but the timing was not captured
at the resolution needed.

**This wants eyes on the mechanism, not another electrical measurement.** Does
the joystick handle actually swing through the full 44 deg, and is there a hard
stop at the negative end at all? Until that is answered the 44 deg figure should
NOT be written into the travel limits: setting them from a slipping coupling
would let a task command positions the joystick cannot reach.

The shipped limit is left at the old conservative value. It is known wrong and
known safe, which is the right way round while the question is open.

### RESOLVED: 44 deg was real, the gearing is 1:1

Peter: **the motor-to-joystick gear ratio is 1:1**, and the full swing may be as
much as 60 deg. That settles the slipping-coupling question: motor shaft angle IS
joystick angle, the encoder sits on the motor shaft, so a blocked mechanism stops
the encoder while `XACTUAL` advances -- which is exactly what the follow check
tests. The survey simply had not gone far enough.

### The negative hard stop, ONE valid measurement

Widening the survey limit to -75 deg and walking out in **2 deg** steps, the
follow check tripped:

```
state=FAULTED;angle=-55.174;xactual=-57.403;faults=4   (not_following)
```

The encoder stopped at **-55.174 deg** -- the mechanism against its stop -- while
the ramp generator pushed 2.229 deg further before the check evaluated.

With the park sitting one 9.000 deg clearance step off the switch:

| | deg | encoder counts | microsteps |
| --- | --- | --- | --- |
| 1 encoder count | 0.0900 | 1 | 12.8 |
| switch -> park | 9.000 | 100 | 1280 |
| park -> hard stop | 55.174 | 613 | 7847 |
| **FULL SWING** | **64.174** | **713** | **9127** |

64.2 deg is consistent with Peter's estimate of up to 60 deg.

**This is ONE measurement, not a repeatable figure.** Two apparent repeats were
retracted -- see below -- and later attempts gave inconsistent results. Treat
64.2 deg as a single observation of the right order, not a calibration.

### RETRACTED: the "three identical measurements" claim

Three readings of `angle=-55.174` were reported as independent repeats. They were
the **same reading three times**. `clrfault` was refusing with `latched`, so the
subsequent `home`, `arm` and `moveto` all naked, and the loop broke on the first
`status` still showing the stale fault. Byte-identical results across three runs
should have been read as suspicious rather than as precision.

### Firmware bug: a motion fault could not be cleared

`clrfault` answered `nak;latched` forever after a `not_following` fault, because
backend faults were raised with `cause_active = true`. **The remedy for being
against a stop is to move, and motion is refused while faulted** -- so the only
exit was a reset, and it silently invalidated the measurements above.

Fixed: every fault this board raises is now clearable. The draft's "clears only
faults whose cause has gone" is not implementable for causes the board cannot
probe without retrying -- whether the mechanism is still stuck, whether the rail
will come up, whether CHOPCONF reads back 1. The board clears and re-faults
instead, which is recoverable and reports just as loudly. **Raise this against
the draft's CLRFAULT wording.**

### Firmware bug: small moves had NO stall detection at all

The more serious one. `startMoveTo()` re-seeded the follow-check window on every
move, and the window only evaluates once **200 microsteps (1.4 deg)** of
commanded travel accumulate. So any move smaller than 1.4 deg reset the window
before it could ever evaluate, and **was never follow-checked**.

Observed directly: walking to the stop in 2 deg steps faulted correctly at
-55.174, while the same walk in 0.25 deg steps ran to -58 and -60 deg with no
fault at all, pushing the motor against the stop repeatedly with nothing
noticing.

**Small commanded moves are exactly what a trial does**, so this was a stall
detector that switched itself off for the normal case. Fixed by letting the
window persist across moves and re-seeding it only where `XACTUAL` is written out
from under the check: the homing datum, the park datum, a compliance resync, and
bus bring-up.

### OPEN: the mechanism may have been left jammed

After those unprotected walks, **homing now faults immediately**:

```
ack;582
ev;FAULT;35158468;code=3;detail=mechanical_stop_first
state=FAULTED;angle=0.267;xactual=1.413;homed=0;limit=0;faults=8;hv=0
```

The approach commanded 1.413 deg and the encoder returned 0.267 -- a ratio of
0.19, below the 0.25 threshold -- with the limit switch NOT asserting. So the
mechanism is not following at the POSITIVE end, and it is not the switch stopping
it.

Candidates, not separated: the mechanism is jammed against something after being
driven into the negative stop without detection; the joystick is resting at a
positive limit the switch does not cover; or the follow check is now tripping on
acceleration lag at the 0.200 rev/s homing velocity, since the window is no
longer re-seeded at the start of each move and evaluates at a different point in
the ramp.

**That last possibility is a real risk introduced by the fix and must be ruled
out before trusting it.** The original blocking `moveTo()` re-seeds per move
precisely so "acceleration from standstill and the encoder's 12.8 microstep
quantum cannot trip it".

**This wants eyes on the mechanism before any more motion.** Does the joystick
move freely by hand through its full swing, or is it caught? The board is left
safe: rail off, driver disabled.

**RIGHT joystick: not surveyed**, and should not be until the left one is
understood. It also needs `PyControlLink` flashed over the bench console.. **The motor has been
energised** — note `hv on` brings up the rail and configures the driver but
leaves `~{TMC_DRV_EN}` high; only `arm` and `home` enable it.


### ~~OPEN: the datum sits outside the permitted travel~~ — RESOLVED 2026-09-03

The first travel limits were `travel_lo=-19.125`, `travel_hi=-9.0`, with zero at
the switch edge. That made zero unreachable (driving into the switch is what the
switch exists to prevent) and parked homing exactly on the inclusive boundary.

**Both went away with the park datum.** Zero is now where homing leaves the
joystick, so it is a commandable position, and travel is `-10.125 .. 0.0`,
confirmed on hardware:

```
ack;211;travel_lo=-10.125;travel_hi=0.0;v_max=36.0;a_max=3600.0;i_max=0.421
```

Still not exercised: **walking to each end and confirming `moveto` refuses one
step past.** The limits remain constants derived from bench geometry rather than
measured through the protocol, and the margin at the negative end -- a hard
mechanical stop, which is not a sensor -- has never been approached deliberately.


### `STATUS` hung the core — firmware bug, fixed 2026-09-03

The first `status` sent after `id` produced no reply, and the board then stopped
answering the link **and** stopped honouring the 1200 baud reset touch, so it
could not be reflashed. Recovery needed `SW501` held through a power cycle with
**both USB and the RJ-45 unplugged** — the ORing diodes mean pulling USB alone
leaves the board alive on pyControl's 5 V, exactly as
[`docs/interface-map.md`](interface-map.md) warned.

Cause: `TmcMotion::angleDeg()` and `xactualDeg()` read position over SPI, and
`STATUS` calls both. `STATUS` is specified "safe at any time", so a `status`
before `hv on` reached for SPI0 before `beginSpi()` had ever run, with the GPIO
isolation bus switch still open.

**The shared corpus could not have caught this, and that is the lesson worth
keeping.** The corpus case `status-is-safe-before-anything-is-configured` passes
on the host because the host's motion backend just returns a number. A corpus
held by two implementations pins protocol **behaviour**; it says nothing about
**hardware preconditions**, because one of the two implementations has no
hardware. Do not read a green corpus as "the firmware is right", only as "the
two ends agree about the wire".

Fixed by making position a cache refreshed once per poll and forbidding any SPI
access unless the bus is up. Two side benefits: several bus transactions per
reply removed, and a pull in `FREEWHEEL` is now visible at all -- the encoder
moves there with no commanded motion, so a cache refreshed only during a move
would have reported a stale angle for the whole pull.

### Also fixed: `ID` reported a placeholder serial

The first `READY` this firmware emitted carried
`serial=0000000000000000` -- the corpus's placeholder, because the firmware never
set it from the flash unique id. Both boards would have reported the same value,
so a host confirming "am I talking to the board whose calibration matches this
joystick" would have **passed against the wrong board**. The default is now a
string that cannot be mistaken for a real id, so forgetting it fails loudly.

## Instruments Attached To This Rig

**Two LA5032s, one per board, established by identity beacon 2026-09-03.**

| Analyzer, by USB topology | Board it is probing |
| --- | --- |
| `1-5.1.4` | `E4654C159F4D1334` (board 2, RIGHT joystick) |
| `1-5.2.1` | `E4654C159F591D34` (board 3, LEFT joystick) |

**This table was WRONG for part of 2026-09-03 and the beacon is what caught it.**
The two analyzers were unplugged and power-cycled to clear a wedged capture, and
came back in the opposite USB ports -- so the topology-to-board mapping inverted
while the probe cables stayed put. A capture was taken on the wrong instrument
before Peter noticed the wrong analyzer was blinking.

That is precisely the failure `usb_topology.py` warns about: the topology path
identifies the PORT, not the instrument. **Re-run the identity beacon after any
replug rather than trusting this table** -- it settled the question in one shot,
decoding `E4654C159F4D1334` from `1-5.1.4`. The mapping above is the state after
that re-identification.

Incidental hint, not a substitute for the beacon: sysfs shows a product string of
`Kingst Logic Analyzer` only on an analyzer that has had its firmware uploaded
this session, and nothing on a freshly power-cycled one. Useful for spotting
which one has been used, useless for identity.

**Record the topology path, not the `conn=` spec.** An LA5032 reports no USB
serial number at all, so libsigrok can only address it as
`conn=<busnum>.<devnum>` — and that changes when the firmware upload
re-enumerates the device. Two analyzers were seen moving from addresses 21,22 to
23,24 across one `sigrok-cli --scan` with nothing touched, *and their relative
order inverted*. The sysfs topology path is the hub port and is stable until a
cable moves.

How the mapping was established, and how to redo it after any recabling: each
board clocks its own flash unique id out of `FW_TRIG0`/`FW_TRIG1` on command
(the `I` command, `SelfTest::emitIdentityBeacon()`), so each analyzer identifies
itself by what it recorded rather than by elimination. Both analyzers decoded
the serial of the board they were wired to in a single pass. Run
`tools/identify_boards.py` in `../instrument-control`.

**This needs no 36 V and no motion**, which is the property that makes it usable
before anything is energised: `U1801` runs from `+3.3V_MCU` and reaches `J1501`
through 33 Ω series resistors. Verified pad-to-net at tag `v0.2` — `U501`
pad 37 (`GP25`) → `FW_TRIG0` → `U1801` pad 5 → pad 6 → `R1803` → `J1501`
pin 26, and `U501` pad 32 (`GP21`) → `FW_TRIG1` → `U1801` pad 9 → pad 8 →
`R1804` → `J1501` pin 28. Both boards' rails read off throughout: 0.0161 V and
0.0355 V.

Measured incidentally, and worth having: the beacon's frame-start pulse captured
at **50.0 ms (5005 samples at 100 kSa/s)** against a firmware-specified 50 ms.
That is a check on the RP2040 timebase and on the whole buffer chain, taken
without energising anything. The frame contract is
`../board-interfaces/docs/instrument-port-identity-beacon.md`.

**Two analyzers means this rig is now in option 2 of
[`docs/instrument-strategy.md`](instrument-strategy.md)**, not option 1. Nothing
cross-joystick is possible yet — that still needs the `RSYNC` fan-out question
answered.

## Board 1 — `E4654C159F2C2534`

- Revision: **rev 0**, PCB git tag `v0.1`. Confirmed from the `.kicad_pcb` at
  that tag: three `SN74LVC125A` buffers, no analog output block, `GP10`/`GP11`/
  `GP13` unrouted. Tags `v0.1` and `v0.2` have byte-identical RP2040 pad-to-net
  maps, so which of the two was fabricated does not affect firmware.
- **Serial / unit:** `E4654C159F2C2534` — RP2040 flash unique ID, read over USB.
- **Designator scheme this board's silkscreen uses** — see the warning below:
  **rev 0 / left column.** Confirmed from the `v0.1` netlist: `J1101` is the
  4-position stepper terminal, `J1102` the 5-position encoder, `J1301` the
  2-position limit switch. The 36 V input block is `U201` with `R201`-`R207`,
  **not** `U1901`/`R1901`-`R1907` as elsewhere in this file. Note the collision:
  at `v0.1` `R1901`/`R1902` are the 100 Ω pyControl series resistors, while at
  HEAD those numbers are the 1 kΩ `HV_EN`/`HV_DIAG_EN` series resistors.
  `R1903` 0.36 Ω is the pyControl 5 V jumper in both schemes.
- Joystick this unit is calibrated for:
- Assembly date:
- Assembler:
- Firmware commit / image hash: `mouse-joystick-firm`, uncommitted working tree
  on top of `a7995da`, `examples/TMC5130Communication` on env `mouse_joystick`,
  flashed by `picotool load -x` 2026-09-02. (Stage 1 measurements below were
  taken on `examples/RP2040SelfTest`, built `Sep  1 2026 13:31:32`.)
- Protocol version: n/a — no pyControl protocol implemented yet.
- Notes: **Stage 1 (RP2040 subsystem) passed 2026-09-01: 27 checks, 0 failed.**
  **Stage 2 (36 V rails + TMC5130A SPI) passed 2026-09-02** — but only with the
  firmware staircase soft-start; a plain `HV_EN` assertion still latches the
  36 V switch off. Full record under [Controller](#controller),
  [Power — 36 V](#power--36-v) and [Motor And Driver](#motor-and-driver).

### Designators Are Not Stable Across Revisions — Read Before Wiring A Harness

The project uses KiCad automatic annotation, which orders by sheet position, so
inserting a part rotates every designator after it. A global re-annotation
happened on **2026-08-27** when the analog output block gained its filter, and
three connectors in the motor/encoder sheet rotated:

| Carries                     | Rev 0 silkscreen | Rev 1 onward |
|-----------------------------|------------------|--------------|
| Analog angle out, BNC       | *not fitted*     | **`J1101`**  |
| Stepper coils, 4-pos 3.5 mm | `J1101`          | **`J1102`**  |
| Encoder, 5-pos 3.5 mm       | `J1102`          | **`J1103`**  |
| Limit switch, 2-pos 3.5 mm  | `J1301`          | `J1301`      |

**A rev-0 board in your hand is silkscreened with the left column.** The rest of
this file, and the rest of the repository, uses the right column. The 4-, 5- and
2-position housings are not interchangeable so a harness cannot physically go into
the wrong terminal, but read the position count, not the number, when you are
working from a board rather than from a document. Record which scheme this unit
carries in the field above.

The analog output block's own designators rotated wholesale in the same pass
(`R2001`-`R2010`, `C2001`-`C2009`, and `U2001`/`U2002` swapped between the DAC and
the op amp). Where this file names one, it names the post-2026-08-27 assignment.

## Inspection

- Visual inspection:
- Connector orientation:
- Unit identifier legible on silkscreen:
- Sense resistor value populated at `R1203`/`R1204` (expect 0.15 Ω, **not** the
  `kicad-libs` block default 0.12 Ω — a re-placed `tmc5130` block reverts them):
  **0.15 Ω in the `v0.1` netlist** for both positions, so the design is correct.
  *Not* visually confirmed on the physical board — check the part marking before
  stage 3 relies on it, because the shunt value and the `vsense` bit are one
  decision.
- Solder issues:
- Rework: **`R203` (0402, `+3.3V_MCU` → `LATCH`, 1 kΩ) depopulated 2026-09-02**
  to release `LATCH` and select the switch's auto-retry. This is the fix for the
  36 V turn-on fault and it should be carried into the next revision as a GPIO
  or a hard tie low — see
  [Changes Recommended](#1-latch-must-not-be-strapped-high--this-is-the-one-that-matters).

## Power — sources and ORing

| Source powering the board | `+3.3V_MCU` | `+5V_SW` | `+3.3V_SW` | Responds to `ID` | Notes |
| --- | --- | --- | --- | --- | --- |
| USB only | not measured — `ADC_AVDD` is tied to it, so the RP2040 cannot measure its own reference | 0 V expected, not measured | **0.034 V** measured via `GP26` | no protocol yet | board boots and runs; die temperature read a plausible 26.2 °C, which weakly bounds `ADC_AVDD` |
| pyControl only | | 0 V expected | 0 V expected | | measure port current too |
| 36 V only | 0 V expected | 0 V expected | 0 V expected | **no** expected | board deliberately does not boot |
| 36 V + USB, `HV_EN` low | | 0 V expected | 0 V expected | | the normal idle state |
| 36 V + USB, `HV_EN` high | | | | | |
| All available | | | | | |

- ORing diode part and measured `Vf` at the actual logic current:
- Current measured flowing back into the USB host (expect 0):
- Current measured flowing back into pyControl (expect 0):
- Current into the dead `+5V` rail under USB-only power (expect ~0):
- `SW_RAIL_SENSE_DIV_2` on `GP26` versus measured `+3.3V_SW`, rail up and rail
  down (`R401`/`R402` 1 kΩ/1 kΩ; expect ~0 V down and ~1.65 V up):
  **rail down: 21 counts = 0.0169 V at the pin = 0.034 V undivided** (12-bit,
  `ADC_AVDD` reference), repeatable across reboots. Rail up not yet measured —
  36 V not connected. No independent meter reading taken, so this confirms the
  divider reads *something sane when off*, not its gain.
- **Back-power: `+3.3V_MCU` and `+3.3V_SW` measured with 36 V applied and both USB
  and pyControl unplugged** (expect 0 V on both; the `SN74LVC125A` has no `Ioff` and
  TI does not specify leakage at `VCC` = 0, so this is unspecified, not guaranteed):
- Firmware refuses 5 V-domain access when `+5V` is absent:
- Behavior when each source is plugged/unplugged while others are live:
- pyControl port 5 V current drawn by this board:

## Power — 36 V

- Input voltage / current limit used: **36 V, not current-limited** (supply
  capable of 4 A), 2026-09-01 and again 2026-09-02. The single-shot turn-on
  fault is diagnosed and worked around — see
  [The Rail Comes Up And Then Collapses](#the-rail-comes-up-and-then-collapses--resolved-2026-09-02).
  Everything below marked 2026-09-02 was taken with the rail brought up by the
  firmware staircase (`c`), not by a plain `HV_EN` assertion.
- Board boots with motor rail off, `HV_EN` low: **yes** — with USB only, the
  firmware's safe state drives `HV_EN` low and `+3.3V_SW` reads 0.034 V. Note
  the stage 1 firmware has no code path that can raise `HV_EN` at all.
- Regulator chain confirmed fed **post**-switch, and `+3.3V_MCU` confirmed fed
  from USB/pyControl only:
- **`+36V_SW` measured with 36 V applied, `GP14` (`HV_DIAG_EN`) low and `GP19`
  (`HV_EN`) low** (expect true 0 V, no upward creep). If it creeps at ~1.2 V/s and
  the 5 V rail hiccups every few seconds, `DIAG_EN` is high and the TPS1HTC100's
  OFF-state 150 kΩ open-load pull-up from `VS` to `VOUT` is enabled. Record the
  voltage at t = 0, 10 s and 60 s, not a yes/no:
  **`+36V_SW` not measured directly — no test point and it does not reach the
  MCU.** Measured instead on `+3.3V_SW` downstream, sampled over 60 s with 36 V
  applied and both `HV_EN` and `HV_DIAG_EN` low: **t=0 s 0.0338 V, t=10 s
  0.0338 V, t=30 s 0.0306 V, t=60 s 0.0322 V.** Range 0.0306-0.0338 V, drift
  −0.0016 V, which is ±1 ADC count. **No creep, and the 5 V rail did not hiccup.**
  Creep would have pushed `+36V_SW` past the buck's 3.6 V minimum in ~3 s and
  shown here as the rail twitching. The `DIAG_EN` leakage failure mode is ruled
  out on this board. A direct `+36V_SW` reading is still wanted.
- `+36V_SW` bulk capacitance measured or confirmed (design value ~208 µF,
  `C1213` + `C1214` 100 µF **50 V** each plus ceramics; no TVS populated):
- Inrush: **not measured directly** — needs a current probe or a monitoring
  supply. Bounded indirectly: the switch delivers `I_CL` for only 1.8-2.3 ms
  before tripping, so no attempt has ever delivered the full 7.5 mC that 208 µF
  at 36 V requires in one go.
- `HV_EN` assertion behavior, rail rise time: **single shot fails.**
  `+3.3V_SW` reaches 3.309 V in 3-4 ms, holds, then collapses at 38-68 ms and
  stays down. Six attempts, 2026-09-01 and 2026-09-02; table in the subsection
  below. **With the firmware staircase (`c`) it comes up and stays up:** rail
  live within the 60 ms train, 3.310-3.314 V, held for the full 1000 ms monitor
  window, 5 of 5 attempts, then soaked 40 s at 3.307-3.314 V, 2026-09-02.
- `ILIM` resistor `R206` value and measured current limit: **`R206` = 40 kΩ**
  in the `v0.1` netlist, design I_CL ≈ 1.15 A (`K_CL` = 46 A·kΩ at the bottom of
  the range). **Not measured** — and note 1.15 A sits near the bottom of the
  part's stated 1-5 A window, so it is the least-characterised corner of the
  current-limit spec.
- `HV_SNS` reading versus measured load current, **with `GP14` (`HV_DIAG_EN`)
  raised** — `HV_SNS` and `~{HV_FAULT}` report nothing while `DIAG_EN` is low:
  **not obtained.** Every reading taken with `DIAG_EN` raised sat at 1.56-1.63 V,
  which is `ISNSFLT` (5.2-6.4 mA into `R207` 249 Ω), i.e. the *fault* level rather
  than a load-current reading. With `K_SNS` = 800 A/A and `R207` = 249 Ω a load
  reading would be 0.311 V/A, so a legitimate reading at the 1.15 A current limit
  would be 0.37 V. No valid load-current measurement exists yet.
  **2026-09-02, rail up via the staircase and no fault asserted:** `HV_SNS` =
  **0.0153 V, 19 counts** — but the quiet-state floor with `HV_EN` low is
  18-22 counts, so this is offset, not signal. The chain resolves
  0.311 V/A → **2.6 mA of load current per ADC count**, with a ~19-count
  offset floor. **At the ~10-15 mA idle draw the sense chain cannot resolve
  anything**; all it says is "far below the 1.15 A limit". It should become
  usable at motor currents: 0.2-0.7 A is 76-270 counts above the floor.
  Firmware now carries `K_SNS` = 800 A/A (`conversions::hvLoadAmps`) and a
  fault-band guard, so it prints amps or "FAULT LEVEL", not raw volts.
  **Resolved by averaging, 2026-09-02** (`m`, `PowerSequence::measureHvCurrent`,
  2048 samples with a zero captured moments earlier at `HV_EN` low):
  **36 V input current = 8.6 mA**, rails up, driver disabled, nothing plugged
  into the motor / encoder / limit connectors. Zero 19.65-19.68 counts, live
  22.98-23.03, delta 3.33-3.35 counts, three runs. **Caveat: `K_SNS` is
  specified at `I_OUT` = 1 A and this is 100× below that — read it as "under
  10 mA", not 8.6 ± 0.1 mA.** The precision is real; the accuracy at this
  current is uncharacterised.
- 36 V input current, rails up, driver disabled: **8.6 mA** (310 mW), as above.
  `U201`'s own `I_Q,VS` is 1.2-1.65 mA of that and is drawn upstream of the
  bulk, leaving ~260 mW on `+36V_SW`. Cross-checks the energy accounting in the
  subsection below, which assumed 0.2 W.
- 36 V input current, driver enabled, motor at standstill hold:
- 36 V input current, motor moving:
- `HV_SNS` reading at `GP28` during a provoked fault (expect 1.3-1.6 V from
  `ISNSFLT` 5.2-6.4 mA into `R207` 249 Ω; RP2040 `VPIN` absolute max is 3.8 V):
- 5 V rail, measured: **still not measured with a meter.** `+5V_SW` reaches
  neither the MCU nor InstrumentPort-40, and there is no test point. Probe
  `U901` pad 4 or 9, or `U1001` pad 5 or 8 (pad→net map read from the `v0.2`
  `.kicad_pcb`, not from a document). **Proven in spec indirectly, 2026-09-02:**
  the TMC5130A answers over SPI with `GSTAT.uv_cp = 0` and
  `DRV_STATUS` reporting no fault, which needs `VCC`/`VSA` inside 4.6-5.5 V.
- 3.3 V rail, measured: **`+3.3V_SW` = 3.307-3.314 V** sustained over a 40 s
  soak with the rail up via the staircase, 2026-09-02 — 0.2-0.4% of nominal,
  read through the `R401`/`R402` divider on `GP26` at 12-bit resolution.
  (2026-09-01: 3.309 V during the 53 ms it was live.) `+3.3V_MCU` not measured
  — it is the ADC reference, so the RP2040 cannot measure it.
- RP2040 core rail, measured:
- Rail ripple, motor idle:
- Rail ripple, motor moving:

### Transient headroom — the 36 V measurement that matters

Limits: 46 V operating, 49 V absolute with inductive load, 50 V bridge. **No TVS is
populated**, and `C1213`/`C1214` are 100 µF **50 V** parts on this rail, so record
the margin to 50 V as well — this capture is the only evidence for either.

| Condition | Peak `VS` at the TMC5130A pins | Margin to 46 V | Margin to `C1213`/`C1214` 50 V |
| --- | --- | --- | --- |
| Motion start | | | |
| Motion stop | | | |
| Deliberate stall | | | |
| Power removal under load | | | |

- Bulk capacitance value and its position relative to the high-side switch:
- Snubber populated, and its values:
- Probe method and bandwidth used (a slow probe will not see this):
- If overshoot approaches 46 V, the fallback taken (snubber / lower supply /
  24 V) and why:

### Thermal

Case temperatures — TMC5130A idle and under motion, the 3.3 V LDO, the sense
resistors and the motor — are recorded in [Thermal Survey](#thermal-survey--procedure-and-results-opened-2026-09-09),
so there is one place to look and one place to fill. The rows below are the
non-thermal-camera half and stay here.

- Confirmed `VCC` fed externally, internal regulator offloaded:
- Sequencing at power-up:
- Behavior at power-down:

### The Rail Comes Up And Then Collapses — RESOLVED, 2026-09-02

**Cause: `U201` trips its own thermal shutdown 1-2 ms into charging the 208 µF
bulk, having reached only ~10-12 V, and `R203` makes it latch instead of
retrying.** This is the failure `tps1htc100-q1.pdf` §7.3.2.1 warns about
verbatim. It is a design-margin problem in the 36 V input block, not a defect
in the regulator chain, and **not a load fault**.

**FIXED IN HARDWARE, 2026-09-02: `R203` depopulated.** With `LATCH` released
the internal 0.7-1.3 MΩ pulldown selects **auto-retry** (`t_RETRY` = 2 ms) and
**a plain `HV_EN` assertion now works.** The full stage 2 sequence runs end to
end on one assertion: rail up in 4 ms, no latched fault at the 105 ms check,
bus closed, TMC5130A registers read. 4 of 4 attempts. Raw output in
`captures/2026-09-02/latch-released/`.

The retry sequence is visible directly in `p`'s 1 ms sampling:

| t | `+3.3V_SW` | `HV_SNS` | |
| --- | --- | --- | --- |
| 0-1 ms | 0.031 V | **1.583 V** | fault asserts — the switch trips on the first burst, same as before |
| 4 ms | 3.312 V | 1.567 V | `+36V_SW` has already cleared the buck's threshold |
| 10 ms | 3.315 V | 1.590 V | still retrying |
| **11-12 ms** | 3.315 V | **0.437 V → 0.065 V** | **fault clears** — charging finished, no more trips |
| 13-249 ms | 3.309-3.314 V | 0.020-0.028 V | settled, and now a genuine load reading |

Retry window 10-12 ms across four attempts. At `I_CL` ≈ 1.15 A into 208 µF each
burst adds 8-10 V, so 36 V needs 3-4 bursts; with `t_RETRY` = 2 ms plus ~1.8 ms
of conduction that predicts 11-15 ms. **The model and the board agree.**

This is the strongest confirmation of the diagnosis available: one 0402 resistor
removed, nothing else touched, and the failure disappears. It also makes
[change 1 below](#1-latch-must-not-be-strapped-high--this-is-the-one-that-matters)
a validated rework rather than a proposal.

**Firmware workaround, still available and no longer needed: a staircase
soft-start.**
`mouse-joystick-firm` `PowerSequence::staircaseStart()`, command `c` in
`examples/TMC5130Communication`. 30 bursts of 1200 µs on / 800 µs off, then
`HV_EN` held high. **5 of 5 attempts brought `+3.3V_SW` up and held it for the
full 1000 ms monitor window with `~{HV_FAULT}` high**, then soaked 40 s at
3.307-3.314 V. With the rail up, the TMC5130A answers over SPI — see
[Motor And Driver](#motor-and-driver). Raw output in
`captures/2026-09-02/`.

Why it works: the bulk **keeps its charge between bursts**. Once the buck drops
out the only load left on `+36V_SW` is the 0.87 MΩ of board leakage, so
τ ≈ 180 s and each burst starts where the last one stopped. Dropping `HV_EN`
clears the latch. Total FET energy is unchanged — it is ½CV² either way — but
delivered over ~60 ms instead of one 6.5 ms burst. `t_ON_pw` is 60-134 µs and
`t_OFF_pw` 82-175 µs, so 1200/800 µs is well inside the device's pulse rating.

The off-time is the parameter that matters. Give the buck long enough and it
bleeds the bulk back to its own dropout, every burst starts from the same
place, and the staircase never climbs. **The `w` command's 250 ms off-time is
far too long** and would have reported "not charging" — a false negative.

#### The Evidence, 2026-09-02

Five single-shot `p` attempts plus `s`, `d` and `v`, all on 36 V (not
current-limited, supply capable of 4 A).

1. **The fault is caused by turning on.** `d` — `HV_EN` low, `HV_DIAG_EN` pulsed
   high — reads `HV_SNS` 0.0153-0.0169 V and **`~{HV_FAULT}` high, no fault**,
   three times running. Under `p`, t = 0 reads 0.018 V (no fault) and
   **t = 1 ms reads 1.597 V**, in 5 of 5 runs.
   **This corrects the 2026-09-01 entry below**, which read the t = 1 ms
   assertion as an OFF-state open-load indication asserted "when firmware had
   just raised `DIAG_EN` with `EN` still low". `PowerSequence.cpp` raises
   `DIAG_EN`, waits 2 ms, and only *then* raises `EN` at t = 0 — so the flag
   appears 1 ms after the switch is enabled, during capacitive charging. The
   OFF-state open-load reading cannot happen this early anyway: with `+36V_SW`
   at 0 V the 150 kΩ pull-up needs `V_S − V_OUT < V_OL_OFF` (1.4-2.6 V), and at
   240 µA into 208 µF the node rises 1.15 V/s.
2. **`HV_SNS` is never a load-current reading during the failure.** It sits at
   1.564-1.620 V across `R207` = 249 Ω for the whole window → **6.28-6.51 mA**,
   i.e. `I_SNSFLT` (datasheet 5.2-6.4 mA), the fault current source.
3. **The device latches.** `s` reads `~{HV_FAULT}` **LOW at ~105 ms with
   `HV_EN` still high**. A downstream shutdown would look different: the
   TPSM365R6 hiccups and the TPS73733 has no latch, so both would retry. The
   rail instead sits flat at 0.047-0.053 V for 200 ms while `HV_EN` is high.
4. **Energy accounting rules out the rail ever reaching 36 V.** At 36 V the
   208 µF holds ½CV² = 135 mJ; against the ~0.2 W switched-domain load the buck
   would hold 5 V for **~650 ms**. Measured hold is 34-65 ms. This survives a
   4× error in the load estimate — even at 0.8 W the "reached 36 V" case
   predicts ≥ 170 ms. Inverting it, `½C(V_peak² − 5.5²) = P·t_hold` gives
   **V_peak ≈ 10-13 V**, and at `I_CL` ≈ 1.15 A into 208 µF (5.53 V/ms) that is
   1.8-2.3 ms of conduction — matching the t = 1 ms fault flag.

| `p` attempt | rail up | leaves 3.30 V | hold | `+36V_SW` peak, inferred |
| --- | --- | --- | --- | --- |
| first, bulk cold | 4 ms | 38 ms | 34 ms | ~10.7 V |
| back-to-back 1 | 3 ms | 51 ms | 47 ms | ~11.8 V |
| back-to-back 2 | 3 ms | 50 ms | 47 ms | ~11.8 V |
| back-to-back 3 | 3 ms | 50 ms | 47 ms | ~11.8 V |
| back-to-back 4 | 3 ms | 51 ms | 48 ms | ~11.9 V |
| after a successful `c` + `x` | 3 ms | 68 ms | 65 ms | ~12.8 V |

±1 ms across the burst, and the cold attempt holding *less*. Both follow from
the bulk retaining charge between attempts: a warm attempt starts pre-charged
at ~5 V — where the buck dropped out — and gets ~1-2 V further before tripping.
The last row is the same effect after a successful power-up.

**Still wanted: a direct `+36V_SW` capture.** The ~10-13 V peak is inferred,
not measured. It is a ~2 ms event, so it needs a scope at `C1213` pad 1
(`+36V_SW`) against pad 2 (`GND`) — a DMM's max-hold will not catch it. The
inference is consistent across six attempts and two independent arguments, but
it is still an inference.

**`R203` is the wrong choice, and now there is evidence.** It ties `LATCH` to
`+3.3V_MCU`, selecting latch-off over 2 ms auto-retry. The datasheet explicitly
sanctions retry-until-charged "with high enough load impedance"; 0.87 MΩ
qualifies, and the firmware staircase is a hand-rolled version of exactly that.
See [Changes Recommended For The Next Revision](#changes-recommended-for-the-next-revision).

#### Original 2026-09-01 Entry, Kept For The Raw Data

**Symptom.** 36 V on `J201`, not current-limited, supply capable of 4 A.
Firmware raises `HV_EN` with the GPIO isolation bus still open and the driver
disabled:

| t | `+3.3V_SW` | `HV_SNS` (`DIAG_EN` high) |
| --- | --- | --- |
| 0 ms | 0.034 V | 0.015 V — no fault |
| 1 ms | 0.032 V | **1.607 V — fault asserts, before the rail rises** |
| 3 ms | **3.309 V** | 1.608 V |
| 3-56 ms | steady 3.309 V | steady ~1.59 V |
| 57 ms | collapsing | ~1.59 V |
| 252 ms | 0.047 V | ~1.59 V |

Repeatable to ±1 ms across two runs. Raw 1 ms-resolution data in
`captures/2026-09-01/hv-powerup-profile-{1,2}.txt`.

**What this proves works.** `U201` passes, `U901` TPSM365R6 buck works, `U1001`
TPS73733 LDO works, and `+3.3V_SW` regulates to within 0.3% in 3 ms. The chain
is not broken; something shuts it down.

**Ruled out.**

- **A resistive short.** `+36V_SW` to `GND` measures **0.87 MΩ** with a DMM
  across `C1213`, board fully unpowered. Caveat: a DMM probes at 1-3 V, so this
  does not rule out a voltage-dependent load. *2026-09-02: nor was one needed —
  the 0.87 MΩ turned out to be the thing that makes the staircase work.*
- **A too-low supply current limit.** The supply was not limited.

**Leading hypothesis at the time: capacitive-charging thermal shutdown in
`U201`.** Confirmed 2026-09-02, with the correction that it trips at 1-2 ms
rather than after a full charge. Relevant numbers: charging `+36V_SW`'s ~208 µF
to 36 V costs ½CV² = **135 mJ regardless of the current limit**, `T_REL` = 60 °C
relative shutdown, `t_RETRY` = 2 ms, and `I_CL` ≈ 1.15 A from `R206` 40 kΩ.

**Do not trust `HV_SNS` to identify the fault.** Per Table 7-2, `VSNSFH` is
shared by overcurrent, overvoltage, short-to-ground and thermal shutdown, and
with `EN` low it also indicates OFF-state open-load. An earlier diagnosis of
"continuous 1.15 A load" was derived from misreading this and was wrong.
*2026-09-02: the "before the rail rises" reading in the table above was also a
misreading — see the correction under The Evidence.*
## Controller

- RP2040 boot behavior: **works.** BOOTSEL (hold `SW501`, apply USB) enumerates
  `2e8a:0003 RP2 Boot` and mounts `RPI-RP2`, bootrom `UF2 Bootloader v3.0`,
  `Board-ID: RPI-RP2`. Firmware boots and runs. **The 1200-baud touch works**, so
  reflashing needs no button and no physical access — `picotool` reported
  "Device rebooted into BOOTSEL mode successfully".
- USB CDC console: **works** at 115200. Enumerates as `2e8a:f00a`, manufacturer
  `Orb Weaver`, product `mouse-joystick-pcb`, USB serial `E4654C159F2C2534`.
  `/dev/ttyACM0`.
- ~~SWD access:~~ **struck** — no SWD header and no reset button in Rev 0, by
  decision; `RUN`, `SWCLK` and `SWDIO` are unconnected and NC-flagged:
  confirmed unconnected in the `v0.1` netlist. No debugger was used or needed.
- Clock verified: **yes.** `clk_ref` (XOSC) 12000 kHz, `clk_sys` 133000 kHz
  measured by the RP2040's own frequency counter against `clk_ref`,
  `clk_peri`/`clk_usb`/`clk_adc` 48000 kHz. For the crystal's *absolute* accuracy
  see the note below — the on-chip counter measures everything against `Y501` and
  so cannot see an error in it.
- ~~PIO encoder decode functional~~ **struck** — no PIO decode exists:

### Stage 1 Self-Test, 2026-09-01

`mouse-joystick-firm`, `examples/RP2040SelfTest`, env `mouse_joystick`
(`MJ_BOARD_REV=0`). USB power only, 36 V not connected, `HV_EN` low, GPIO
isolation bus open throughout. **27 checks, 0 failed.** Designators below are
`v0.1` designators.

**Crystal `Y501`, absolute.** −18.7 ppm apparent over 9 s, comparing the RP2040's
`micros()` against the host's `time.monotonic()` across ten 1 Hz ticks. USB CDC
scheduling jitter is order 1 ms over that span, i.e. ~110 ppm, so this is *below
the noise floor of the method* — consistent with a healthy ±30 ppm part but not a
measurement of it. Independently, USB full-speed enumeration requires 48 MHz
within 0.25 % derived from `Y501`, which bounds it regardless.

**QSPI flash `U502` (W25Q128JVZPIQ, 16 MiB).** Unique ID read back over QSPI
(`0x4B`) plausible, so the part is present and responding. Declared size 16 MiB.
Address-aliasing probe at +2, +4 and +8 MiB: none aliases offset 0, so the
fitted part really is at least 16 MiB rather than a smaller part wrapping its
address space. `picotool` additionally verified the whole 181 760-byte image
byte-for-byte after writing.

**RAM.** Heap total 252 228 B, free 252 128 B. Four-pattern walk over a 16 KiB
heap block clean.

**Resistor-defined levels**, captured in the first instruction of `setup()` with
internal pulls disabled and before anything drove a pin. Each of these maps to
one part, so a failure here is an assembly defect rather than firmware:

| Pin | Net | Read | Held by | Verdict |
| --- | --- | --- | --- | --- |
| `GP9` | `~{BUS_SW_EN}` | high | `R601` 7.87 kΩ to `+3.3V_MCU` | ok — GPIO bus isolated at reset, which every later stage depends on |
| `GP24` | `~{INSTR_BUF_OE}` | high | `R1601`/`R1701`/`R1801` 10 kΩ | ok — instrument port silent before firmware |
| `GP1` | `PYC_UART_RX` | high | `R403` 10 kΩ to `+3.3V_MCU` | ok — cable unplugged, so this is `R403` and not an idle far-end TX |
| `GP29` | `~{HV_FAULT}` | high | `R205` 10 kΩ to `+3.3V_MCU` | ok — pull-up present, on the right rail, no latched fault |

**Spare pads.** All twelve unrouted GPIOs — `GP10`, `GP11`, `GP12`, `GP13`,
`GP15`, `GP16`, `GP17`, `GP18`, `GP20`, `GP22`, `GP23`, `GP27` — moved correctly
under both an internal pull-up and an internal pull-down. No solder defects on
any of them. `GP10`/`GP11`/`GP13` are testable this way only because rev 0 leaves
them unrouted.

**ADC.** 12-bit, reference is `ADC_AVDD` tied directly to `+3.3V_MCU` with no
separate reference and no filter, so absolute accuracy is bounded by that rail.

| Channel | Net | Reading |
| --- | --- | --- |
| `GP26` / ADC0 | `SW_RAIL_SENSE_DIV_2` | 21 counts = 0.0169 V at the pin = **0.034 V** on `+3.3V_SW` — switched domain genuinely off, `R401`/`R402` holding it there |
| `GP28` / ADC2 | `HV_SNS` | 18-20 counts = **0.015 V** across `R207` 249 Ω. Reads zero regardless while `HV_DIAG_EN` is low, which stage 1 keeps it, so this confirms the quiet state and not the sense chain |
| ADC4 | internal temperature | **26.2 °C** — proves the ADC and `ADC_AVDD` are alive |

**Reset reason.** Reported `software` with `watchdog caused reboot: yes` after a
`picotool` upload, which is correct rather than a fault: `picotool` reboots the
chip through the watchdog. A cold power-on reads `power-on`.

**Boot latency.** From the RP2040 releasing `FW_TRIG0` at reset to the first
firmware-driven edge on `FW_TRIG1`: **~143 ms** (measured on the logic analyser,
6.948 ms → 149.626 ms in the same capture). That is bootrom, `boot2`, XIP setup,
C runtime and `setup()`. Relevant because `HV_EN` is held low only by `R204`
during that window.

**Not covered by stage 1.** Anything past `HV_EN`: the switched rails, the
TMC5130A, the 16 MHz oscillator `X1201` (itself on `+3.3V_SW`), the motor,
encoder and limit switch. The pyControl link beyond `GP1`'s idle level.

## pyControl Port

- Controller / breakout model and revision:
- Port designation used:
- Continuity on all eight `J1901` pins, pin-to-pin:
- Event lines landed on:
- BNC lines available versus needed across the whole rig:
- Cable type and length:
- UART levels measured, both directions:
- UART idle state, measured at the RP2040 pin with the cable unplugged (expect
  `PYC_UART_RX` **high** on `R403` 10 kΩ to `+3.3V_MCU`; a low idle means `R403` is
  missing or on the wrong rail and every frame looks like a break):
  **high**, read at `GP1` with internal pulls disabled, cable unplugged,
  2026-09-01. `R403` is present and on the correct rail.
- `R1903` populated as a jumper (0.36 Ω) or as a 1206 PPTC, and which:
- pyControl port 5 V current measured through `R1903` (shared 1.0 A port budget
  that also feeds the controller's own logic regulator; no test points either side):
- Event line edge quality and levels, `PULL_EVENT`:
- `FAULT` line behavior:
- `RSYNC` edge timing observed:
- If two boards: both receive the same `RSYNC` edges, method used:
- Behavior with board powered first:
- Behavior with pyControl powered first:
- Behavior on live insertion:
- Behavior on live removal:
- Motor current observed on any port conductor:

## Motor And Driver

Expected configuration: `R1203`/`R1204` 0.15 Ω, `vsense = 1`, `IRUN` ≤ **17**
(0.421 A RMS), with `IRUN` 24-25 (0.600 A) the open alternative. A measured
current near **0.760 A** means `vsense` is 0 — stop.

**Corrected 2026-09-09.** This paragraph read "`IRUN = 28`, target 0.679 A RMS…
near 1.23 A means `vsense` is 0", all of which predates the motor being
identified as a WO-208-13-01D. See [`IRUN` = 28 predates the motor and is above
its rating](#irun--28-predates-the-motor-and-is-above-its-rating), and settle the
number with [Thermal Survey](#thermal-survey--procedure-and-results-opened-2026-09-09).

**Stage 2 passed 2026-09-02, 5 of 6 register checks.** Rail brought up with the
firmware staircase (`c`), bus closed with `b`, `~{TMC_DRV_EN}` high throughout,
no motor / encoder / limit switch connected. Read over USB CDC; SPI datagrams
not yet cross-checked on `DIG2`-`DIG5`.

| Register | Read | Verdict |
| --- | --- | --- |
| `IOIN` (0x04) | `0x11000011`, status `0x79` | `VERSION` = **0x11**, the TMC5130A signature. The right chip, alive, on all three rails |
| `IOIN.DRV_ENN` | 1 | driver disabled, and `GP3` reaches the chip through the bus switch |
| `IOIN.SD_MODE` | 0 | motion-controller mode, `SD_MODE` tied to GND as designed |
| `IOIN.REFR_DIR` / `ENCA` / `ENCB` / `ENCN` / `SWCOMP` | all 0 | connectors empty; `ENCN` held by `R1201`, `ENCA`/`ENCB` by `R805`/`R806` |
| `IOIN.REFL_STEP` | **1** | firmware expected 0 and flagged it. **Firmware is wrong, not the board** — see [Open Issues](#refl_step-reads-1-with-no-limit-switch-and-that-is-correct) |
| `GSTAT` (0x01) | `0x00000001` | `reset` = 1 (expected on first read after power-up), **`drv_err` = 0, `uv_cp` = 0**. `uv_cp` = 0 means the charge pump is happy, which needs `VS` genuinely up |
| `GCONF` (0x00) | `0x00000000` | reset value |
| `CHOPCONF` (0x6C) | `0x00000000` | **`vsense` = 0**, the reset value. With 0.15 Ω fitted this is ~1.8× rated current. Stage 3 must set it to 1 and read it back *before* lowering `~{TMC_DRV_EN}` |
| `DRV_STATUS` (0x6F) | `0x80000000` | `stst` (standstill) only. **No `ot`, no `otpw`, no `s2ga`/`s2gb`** |
| `XACTUAL` (0x21) / `X_ENC` (0x39) | `0x00000000` | as expected, nothing attached |

SPI status byte `0x79` on the first read: `reset_flag`, `standstill`,
`velocity_reached`, `position_reached` and `status_stop_l` set, **`driver_error`
clear**. `status_stop_l` follows from `REFL_STEP` = 1 and is not a fault —
`SW_MODE` defaults to `stop_l_enable` = 0, so the input is only being reported,
not enforced.

Measure these before a motor is attached, with the switched domain up and the bus
switch still isolated:

- `~{TMC_DRV_EN}` at `U1201` pin 29 (expect ≥2.31 V, the TMC `V_INHI` of
  0.7 × `VCC_IO`; `R1103` 10 kΩ to `+3.3V_SW` should give ≥2.75 V worst case. Near
  1 V means the pull-up is missing or on the wrong rail and the power stage can
  enable itself):
- `~{TMC_CS}` idle level, domain on and bus isolated (expect ≈3.4 V, deasserted):
- `TMC_SPI_SCK` / `TMC_SPI_COPI` / `TMC_SPI_CIPO` idle levels, domain on and bus
  isolated (expect ≈0.28 V each; ~1.9 V means 100 kΩ was fitted instead of the
  10 kΩ `R1401`-`R1403` and the taps straddle the `SN74LVC125A` 2.0 V `VIH`):
- **`REFR_DIR` at `U1201` pin 9 (expect a hard 0 V).** **Added 2026-08-27**, now
  **tied directly to GND** — a 10 kΩ pull-down (`R1104`) was fitted first and
  replaced by the hard tie, which is the more robust treatment and what the
  datasheet asks for on an unused input. This pin is a plain `DI` with **no**
  internal pull — unlike `SD_MODE`/`SPI_MODE` (`pu`) and `SWSEL` (`pd`) — and it
  was floating before rev 1. Anything other than ~0 V means the tie is broken, and
  a floating right-stop input next to a 36 V bridge can trip a stop:
- `DAC_SPI_SCK` / `DAC_SPI_COPI` idle levels, domain on and bus isolated (expect
  ≈0 V from `R2010`/`R2009`, the block's own 10 kΩ pull-downs), and `~{DAC_CS}`
  idle level (expect ≈3.3 V from `R2006` to `+3.3V_SW`, deasserted — a low here
  would assert `SYNC` and let a floating bus clock data in):
- All of the above measured again with the switched domain **off** (expect
  0 V on every one, including `~{DAC_CS}`, because its pull-up references
  `+3.3V_SW` which `R401`/`R402` hold at 0 V):

- Motor part:
- Motor rated current per phase, and whether RMS or peak:
- Sense resistor populated, measured on the physical board:
- `vsense` read back from CHOPCONF (expect 1):
- `IRUN` read back (expect **17** unless a thermal run has moved it; the bench
  console's `n` refuses anything above 17):
- **Coil current measured, RMS** (expect **0.421 A** at `IRUN` 17, 0.600 A at 24):
- Driver config read back over SPI:
- `DIAG0` behavior (`R1101` 10 kΩ pull-up to `+3.3V_SW`; open-drain, idles high):
- `DIAG1` behavior (`R1102` 10 kΩ pull-up to `+3.3V_SW`):
- Sense resistor temperature, standstill hold at current — record it in
  [Thermal Survey](#thermal-survey--procedure-and-results-opened-2026-09-09)
  with the `IRUN`, `vsense` and shunt value it was taken at:
- Motion smoothness / audible behavior:
- Microstep smoothness at the **101 mV** peak sense signal (89 mV across the
  0.15 Ω itself; the old 163 mV figure came from `IRUN` 28):
- Step-rate ceiling achieved at 36 V, versus the same motor at 24 V if available:

## Encoder

- Encoder part:
- Interface: single-ended / differential:
- **Output stage: push-pull or open-collector.** The board assumes **push-pull** —
  `R801`/`R802` are 100 kΩ pull-**downs**. An open-collector part needs them changed
  to pull-ups:
- `J1103` pin order confirmed against the encoder's harness (board expects pin 1 =
  `GND`, pin 2 = reserved index **NC**, pin 3 = `ENC_A_RAW`, pin 4 = `+5V_SW`,
  pin 5 = `ENC_B_RAW`; supply sits between the two channels): **confirmed
  2026-09-02**. Left and right harness tables are in `harness-pinouts.md`,
  which is also where the two-swap mirroring for the left joystick is
  specified.
- Supply voltage and measured current (from `+5V_SW`, so the encoder resets with
  the switched domain):
- Counts per revolution:
- Maximum output frequency, versus the fitted RC corner of ~72 kHz
  (`R803`/`R804` 4.7 kΩ × `C802`/`C803` 470 pF, τ = 2.2 µs):
- TMC5130A `X_ENC` versus quadrature edges captured on `DIG0`/`DIG1`:
- ~~Index (`ENC_N`) behavior:~~ **struck** — there is no `ENC_N` net; TMC `ENCN` is
  tied to GND through `R1201` 10 kΩ and `J1103` pin 2 is a no-connect:
- Angle versus independent angular measurement:
- ~~Deliberate mismatch raises `ENCODER_MISMATCH`~~ **struck**, fault retired:

## Homing

- Limit switch part (at `J1301`, debounced by `U1301` MAX6816 onto `LIMIT_SW` →
  TMC `REFL` pin 8):
- Debounce behavior observed:
- Switch closure seen on InstrumentPort `DIG11`, and the driver's reaction in the
  next SPI poll:
- ~~`REFL` test pad jumpered to force a closure, and the driver reacts:~~
  **struck** — there is no test pad, and `GP9` is `~{BUS_SW_EN}` rather than a
  stimulus. Force the closure at the switch itself and record how:
- Homing repeatability over N runs:
- Homing time:
- Behavior when the switch is never reached:
- Hardware latch versus software position agreement:

## Analog Angle Output

Expected configuration as placed 2026-08-27: `DAC80501` (`U2001`) on its internal
2.5 V reference, `GAIN` register 4h = `0x0101`, a 2-pole 987 Hz Sallen-Key
(`R2001` 20 kΩ, `R2002` 13 kΩ, `C2003`/`C2007` 10 nF **C0G**), `OPA197` (`U2002`)
at DC gain 1.32, `R2007` 249 Ω, `D2001` ESD, out to the BNC `J1101`. Full scale
3.300 V, LSB 50.4 µV.

- DAC part and `VDD`:
- `GAIN` register read back as `0x0101` **before** any data write (reset value is
  `0x0001`, the 0-5 V range; the 3.3 V ceiling only holds after this write):
- `VREFIO` measures 2.500 V:
- Level translation required, and part used (expect **none** — `DAC80501` `VIH` is
  1.62 V flat across `VDD` 2.7-5.5 V):
- Software `LDAC` synchronous update confirmed (`DAC_SYNC_EN` plus the `TRIGGER`
  register; there is no hardware `~LDAC` or `~CLR` pin):
- Output at commanded zero code (expect ~25 mV, not 0 V — the `OPA197` light-load
  floor; the valid range should start at 50 mV or above):
- Output at commanded full scale (expect **3.300 V**, not 5 V):
- Linearity across range:
- Output at boot, before firmware runs (expect 0 V; the `Z` suffix resets to zero
  code):
- Output when unhomed / disarmed / faulted:
- Update rate achieved:
- Behavior into the researcher's actual recording input:
- ~~`AUX_ANALOG_OUT` populated, and what it carries:~~ **struck 2026-08-27** — not
  populated. `J1101` is a single BNC and a second channel would be a second full
  block instance.

### Filter — Measure It, Do Not Assume It

- **Corner measured** (expect −3 dB at ~827 Hz; `f0` 987 Hz, `Q` 0.606):
- **DC group delay measured** (expect **266 µs**, near-flat in band):
- Full-scale settling to one OneBox LSB (expect ~2 ms):
- `C2003`/`C2007` confirmed **C0G**, not X7R, on the assembled board:
- **Latency from motion to output voltage, measured from the InstrumentPort
  capture** (DAC bus, encoder, and analog output in one file). **Report the
  filter's 266 µs separately** — it is not firmware latency, and every latency
  measured through `AIN0` or seen at the BNC includes it:

### Chopper Alias Check — The Measurement That Justifies The Filter

The OneBox ADC is an `AD7616-P` at a **fixed 30.3 kHz** behind only a first-order
~39 kHz filter, and the TMC chopper runs at 16-30 kHz, so any chopper setting
folds into 0-15 kHz. Sweep the chopper frequency while recording the angle
channel:

- Artifact amplitude on the angle channel, at each chopper setting tried:
- **Does a periodic artifact move with the chopper frequency?** If it moves, it is
  aliasing, not joystick motion:
- Whether 987 Hz gave enough rejection, or the corner should be retuned (scale
  `R2001` and `R2002` by the same factor; the ladder is in the block description):

### If The Angle Channel Misbehaves, Check In This Order

1. Hysteresis after large excursions, or motor-correlated noise: **suspect
   `C2003`/`C2007` dielectric first.** They should be C0G; a class-2 substitution
   adds a dielectric-absorption tail and a piezoelectric path from the stepper.
2. A periodic artifact: run the chopper sweep above.
3. A gain error near 0.025%: that is `R2007` 249 Ω into the OneBox's 1 MΩ input.
   Expected, and calibration absorbs it.
4. Output stuck at 0 V: distinguish an unpowered output section (held there by
   `R2005` 100 kΩ) from a reference alarm caused by a misconfigured `REF-DIV`.
   Both read as a legitimate end of travel, so `STATUS` must report the output
   invalid in either case.

## Protocol

- Simulator conformance result:
- Malformed input handling:
- Duplicate sequence handling:
- Unrecognized verb rejected:
- `ID` reports board serial:
- Heartbeat timeout, measured:
- Time from heartbeat loss to `HV_EN` drop:
- Message rate observed:
- Each fault code provoked and observed:

## Safety

- State of outputs at boot, measured before firmware runs:
- Motor rail confirmed off at boot:
- Motion refused outside `ARMED`:
- Travel limit enforcement, tested by attempting to exceed:
- Velocity and acceleration limit enforcement:
- Time from cable removal to motion stop:
- Time from heartbeat loss to motion stop:
- `EXT_FAULT_IN` fitted, and its behavior:
- Emergency disable behavior:
- Recovery path from each fault:

## InstrumentPort-40

- Adapter used: **`la5032-instrument-port-adapter` v1.0** with a Kingst LA5032,
  2026-09-01. Host path: `sigrok-cli` 0.7.2 / libsigrok 0.6.0 from
  `instrument-control`'s Guix manifest, driver `kingst-la2016`, FPGA bitstream
  `kingst-la5032a0-fpga.bitstream` extracted into `instrument-nonfree`. The
  device identifies as *"Kingst LA5032 with 34 channels"*. **This was also the
  adapter's own first bench validation** — see that repository's bring-up log.
- `J1501` cable orientation confirmed by continuity, pin-1 to pin-1: **not by
  continuity — confirmed functionally, which is stronger.** `FW_TRIG0` and
  `FW_TRIG1` carry deliberately different patterns (1 Hz square wave versus three
  10 ms pulses at boot), and each appeared on its expected channel: `TRIG0` on
  LA5032 ch 16, `TRIG1` on ch 17. **The cable is not mirrored.** A pin-1-to-pin-1
  continuity check is still worth doing for the other 38 conductors.
- Buffer `~OE` state at power-on, before firmware, confirmed high-Z
  (`R1601`/`R1701`/`R1801`, 10 kΩ each to `+3.3V_MCU`): **yes** — `GP24` read
  high at boot, sampled before firmware drove any pin.
- Firmware enables buffers at startup: **yes.** `examples/RP2040SelfTest` enables
  them to emit a boot signature and then a 1 Hz heartbeat on `FW_TRIG0`. On a
  board with no LEDs, no test points and no SWD header, that is the only evidence
  of firmware execution that does not depend on USB. The `i` command toggles it.
- Buffer state reported in `ID`/`STATUS`: n/a — no protocol yet.
- All 11 Rev 0 Strands present and correctly mapped: `DIG0` `ENC_A_BUF`, `DIG1`
  `ENC_B_BUF`, `DIG2` `TMC_SPI_SCK_BUF`, `DIG3` `TMC_SPI_COPI_BUF`, `DIG4`
  `TMC_SPI_CIPO_BUF`, `DIG5` `~TMC_CS_BUF`, `DIG7` `PYC_UART_RX_BUF`, `DIG8`
  `PYC_UART_TX_BUF`, `DIG11` `LIMIT_SW_BUF`, `TRIG0` `FW_TRIG0_BUF`, `TRIG1`
  `FW_TRIG1_BUF`:
  **2 of 11 verified.** `TRIG0` (pin 26, ch 16) and `TRIG1` (pin 28, ch 17) both
  confirmed carrying the expected patterns, which also validates `U1801` and the
  `~{INSTR_BUF_OE}` enable path. The other nine are untested; `DIG2`-`DIG5` get
  exercised by stage 2 and `DIG7`/`DIG8` by stage 4. Measured timing on the two
  that work, against firmware nominals:

  | Strand | Nominal | Measured |
  | --- | --- | --- |
  | `TRIG1` boot signature | 3 pulses, 10 ms half-period | 3 pulses; 10.135, 10.018, 10.005, 10.002, 10.001 ms |
  | `TRIG0` boot signature | 8 pulses, 1 ms half-period | 8 pulses; 1.001-1.009 ms |
  | `TRIG0` heartbeat | 1 Hz | 500.26 ms half-period, jitter ±20 µs |

  The 0.26 ms on the heartbeat is `loop()` quantisation (a `delay(10)` poll), not
  clock error. Captures: `signature.vcd`, `heartbeat.vcd` — session scratch, not
  archived.
- `DIG12` confirmed **inactive**, not a stuck low — `U1801`'s spare output stops at
  `R1805` and `J1501` pin 20 is a no-connect:
- pyControl serial decodes at 115200 8N1 on `DIG7`/`DIG8`, both directions:
- Decoded bytes on `DIG7`/`DIG8` match what firmware reports receiving and
  sending, confirming the parser rather than the wire:
- TMC SPI decodes on `DIG2`-`DIG5`, and `TMC_SPI_CIPO` goes quiet when
  `~{BUS_SW_EN}` is deasserted:
- `DIG2`-`DIG5` read their idle levels with the switched domain up and the bus
  isolated (`~TMC_CS` high, the other three low, per `R1401`-`R1404`), and read 0 V
  with the domain off — the taps are on the **A / switched** side of the bus switch:
- **Encoder decode check.** Quadrature edges counted on `DIG0`/`DIG1` over a
  known joystick sweep, against `X_ENC` read over SPI in the same capture.
  Edge count, register delta, and any discrepancy:
- Direction reversal produces the expected `X_ENC` sign change:
- `DIG0`/`DIG1` read a defined low with `HV_EN` off, confirming the 100 kΩ
  pull-downs `R805`/`R806` hold the switched-domain taps:
- Signal integrity at the instrument:
- `AOUT*` confirmed unpopulated, and `AGND` (pins 31, 34, 37, 40) confirmed tied to
  `GND` rather than left as an isolated island:
- Gate D motion/timing check repeated with analyzer attached versus detached, any
  difference:
- Session-length capture demonstrated:
- Physical cable arrangement after a realistic session:
- Captures archived at: `captures/2026-09-01/` and `captures/2026-09-02/` —
  see the READMEs there.

## pyControl Integration

- pyControl version:
- Task file used:
- Events received and logged:
- Timestamp agreement after Rsync alignment, with uncertainty:
- If two boards: cross-joystick event ordering reconstructed, and the resulting
  uncertainty:
- Failure and recovery behavior from the task's perspective:

## Two-Board Rig Notes

Only relevant once a second unit exists. This is where the form-factor decision
gets its evidence.

- Serials of both units:
- Firmware hashes, confirmed matched:
- Sense resistor values, confirmed matched:
- Angle-output gain and offset, both units, and the difference:
- Homing repeatability, both units, and the difference:
- Coil current, both units, and the difference:
- Cross-joystick timing uncertainty after `RSYNC` alignment:
- Any systematic difference between units that would confound a two-joystick
  comparison:

## Board 2 — `E4654C159F4D1334`

The as-built unit: **`R203` is intact**, so this is what a v0.2 or v0.3 board
does out of the box. Arrived with blank flash (enumerated `2e8a:0003 RP2 Boot`),
flashed `examples/TMC5130Communication` on env `mouse_joystick` by
`picotool load -x`.

**Stage 1 has NOT been run on this unit.** Everything below is stage 2 only.

- 36 V input: 36 V on `J201`, not current-limited. **Note: the first `p` attempt
  on this board ran with no 36 V present** and is archived as the reference
  signature for that condition — rail never moved *and* `HV_SNS` never left its
  offset floor for the full 250 ms, because below `V_S,UVLOR` (5.0-5.75 V) the
  switch does not operate and reports nothing. Contrast board 1, where the fault
  pegged `HV_SNS` at 1.58 V within 1 ms of every enable.
- **Single-shot `HV_EN` fails here too**, confirming this is the revision and not
  board 1: rail peaked 3.339 V, held **17 ms**, `~{HV_FAULT}` **LOW, latched**.
  Board 1's cold first attempt held 34 ms. The shorter hold means board 2's
  switch trips a little earlier and so reaches a lower `+36V_SW` peak —
  part-to-part variation in `T_REL` and die thermal impedance.
- **Stage 2 passes with the firmware staircase as the default power-up path:**
  rail up in 132 ms (60 ms train + settle), peak 3.3105 V, `~{HV_FAULT}` high,
  bus closed, `VERSION` = `0x11`, `GSTAT.drv_err` = 0, `uv_cp` = 0,
  `DRV_STATUS` = `0x80000000`, `CHOPCONF.vsense` = 0.
- **36 V input current, rails up, driver disabled: 13.7-13.8 mA**, three runs,
  delta 5.29-5.33 counts against a zero of 21.10-21.21. Board 1 read 8.6 mA
  (delta 3.33-3.35). **Do not read that as a real 5 mA difference** — it is a
  2-count difference on a sense ratio specified at `I_OUT` = 1 A, which is 100×
  higher. Both boards are "well under 20 mA" and that is all this channel can
  currently support.
- `IOIN` = `0x11000014`, which differs from board 1 — see
  [the retraction](#the-two-rig-boards-disagree-on-refl_step-and-encb--retraction).
- Captures: `captures/2026-09-02/board-E4654C159F4D1334/`.

Still outstanding on this unit: the whole of stage 1, every meter measurement,
transient headroom, and thermal.

### Stage 3 — Motion, Encoder And Homing, 2026-09-02

**Passed.** First time anything downstream of the driver has been exercised on
either board. Run with `mouse-joystick-firm` `examples/MotionAndHoming` on env
`mouse_joystick`, over TMC51X0 4.0.3. Motor, encoder and limit switch all
connected, motor installed in the rig through the gear pair.

Parts, identified the same day: motor **Lin Engineering WO-208-13-01D** (NEMA
08, 1.8 deg/step, 4-lead bipolar, 0.6 A/phase, 6.5 ohm/phase, 3 oz-in, no
gearbox, rear shaft), encoder **US Digital E4T-1000** single-ended (1000 CPR,
4000 quadrature counts/rev, 5 V push-pull). Datasheets in `docs/datasheets/`.

**Rail and bus.** `+3.3V_SW` up in **132 ms**, peak **3.317 V**, firmware
staircase. Bus closed after. Note that `+3.3V_SW` reads **3.3169 V immediately
after `HV_EN` drops** and 0.033 V a few seconds later — that is `+36V_SW`'s bulk
bleeding down through the buck, not a stuck rail.

**Driver, over SPI.**

| Reading | Value | Verdict |
| --- | --- | --- |
| `IOIN.VERSION` | `0x11` | TMC5130A |
| `IOIN.SD_MODE` | 0 | motion-controller mode |
| `GSTAT` | `drv_err` 0, `uv_cp` 0 | charge pump happy, so `VS` is genuinely up |
| `CHOPCONF` written and read back | `0x10430153` | **`vsense` = 1**, `TOFF` 3, `TBL` 2, `CHM` 0 (SpreadCycle), `HSTRT` 5, `HEND` 2, `MRES` 0 (256 usteps), `intpol` 1, `SYNC` 4 |
| `IHOLD_IRUN` written | `IRUN` 8, `IHOLD` 2 | 0.211 A and 0.070 A RMS/coil. **Write-only, so as-written, not read back** |
| `DRV_STATUS` standstill, driver off | `0x80020000` | `stst` 1, `cs_actual` 2 |
| `DRV_STATUS` standstill, driver on | `0xA0020036` | `ola` 1 — expected false detection at standstill, per the datasheet |

`intpol` = 1 and `SYNC` = 4 were not chosen: TMC51X0 seeds its register mirror
with the datasheet's CHOPCONF reset default `0x10410150` and writes whole
registers, so those fields ride along. `SYNC` = 4 puts chopSync at
fCLK/(4*64) = 62.5 kHz; with `TOFF` = 3 the chopper cycle ends well before each
sync pulse, which is the arrangement the datasheet asks for. Benign, but it is
inherited rather than decided, and it fixes the chopper frequency — worth
knowing before the angle-channel alias sweep on rev 1.

**Current.** `vsense` = 1 read back before the output stage was ever enabled,
which is the whole gate. The firmware ceiling is `IRUN` 17 = 0.421 A RMS, from
reading the vendor's 0.6 A as a **sine peak** — the conservative of the two
possible readings, since Lin Engineering does not say which it is. The
equal-heating reading would allow 0.600 A RMS (`IRUN` 24-25). **Unresolved, and
it needs a coil-current measurement and a case temperature to settle.** The
`IRUN` = 28 figure that `docs/rev0-plan.md` and the firmware's AGENTS.md still
carry predates the motor being identified: it is 0.679 A RMS, above the rating
on either reading, and should be revised.

**Update 2026-09-09:** both have been. `docs/rev0-plan.md` was swept on
2026-09-08 and the firmware's AGENTS.md on 2026-09-02; each now carries `IRUN`
≤ 17 plus a note about what it used to say. The measurement that settles 17
versus 24-25 is still owed — see
[Thermal Survey](#thermal-survey--procedure-and-results-opened-2026-09-09).

**Motion.** One jog step = 1280 usteps = 9.00 deg at the motor shaft.

- `VMAX` 5368 = 5119 usteps/s = 0.100 rev/s, `AMAX` = `DMAX` = `D1` = 219 = 0.5 rev/s^2.
- Jog time **459-460 ms** for 1280 usteps, repeatably. Matches the ramp.
- Encoder follow ratio in free travel: **1.0000** and **1.0102**.
- Audible behaviour: not recorded. Coil current: not measured.

**Encoder.**

- `ENC_CONST` must be written — it resets to **zero**, so `X_ENC` does not count
  at all until firmware sets it. Scaled to 12.8 usteps per quadrature count
  (51200/4000) in **decimal** mode, since 12.8 is exact there and recurring in
  binary. `X_ENC` then reads in microsteps and compares directly with `XACTUAL`.
- **The encoder counts down as `XACTUAL` counts up.** A positive constant gave a
  follow ratio of −0.82; the negated constant gives +1.00. The negation is
  **−13 integer + 0.2 fractional**, not −12 and 0.8: `ENC_CONST` is one signed
  fixed-point value and the fraction is always added. That encoding is now
  bench-confirmed rather than inferred.
- Round trip ±1280 usteps: residual **−51 usteps = −4 quadrature counts**. That
  is about three encoder quanta, so backlash between the motor shaft and the
  encoder is at or below the measurement floor — expected, since the E4T is on
  the motor's own rear shaft and the gear pair is downstream of it.
- **1000 CPR confirmed** against 51200 usteps/rev. A ratio near 2 or 0.5 would
  have meant the fitted part was not the CPR the firmware was told about.
- Maximum output frequency versus the fitted ~72 kHz RC corner: not stressed.
  At 0.1 rev/s the A/B channels run at 100 Hz, four orders below the corner.
- `X_ENC` versus quadrature edges captured on `DIG0`/`DIG1`: not done.

**Homing.** See also the polarity finding under Open Issues.

- Resting `IOIN.REFL_STEP` = **0**, triggered = **1**, so the switch is
  **active high** and `SW_MODE.pol_stop` = 0. Consistent with a
  normally-closed switch to GND through the MAX6816.
- **The `J1301` → `U1301` → `LIMIT_SW` → TMC `REFL` path works on this board.**
  Driven by the motor, `REFL_STEP` went 0 → 1 on engage and 1 → 0 on release.
- Switch throw: **512-630 usteps** at the motor shaft between engage and
  release, from the stepped sweep and the homing creep respectively.
- **The switch is at the POSITIVE end of travel.** It is wired to `REFL`, which
  on the TMC5130A stops *negative* motion, so `SW_MODE.swap_lr` has to be set or
  the hardware stop guards the wrong direction entirely. Firmware sets it.
- **The switch's reporting delay is 8.74 ms** — debounce plus signal path,
  measured by taking two closing-edge latches at two approach velocities in one
  position frame: 85 usteps apart at 10240 and 512 usteps/s. Substantially
  shorter than the tens of milliseconds a MAX6816 might have suggested, and it
  needed no instrument. This fills the "debounce behavior observed" field.
- **Homing is two-stage**, which is what the delay above justifies. Fast
  approach at **0.200 rev/s** latching the closing edge, then a slow creep off
  the switch at **0.010 rev/s** latching the **releasing** edge, and the release
  position is the datum. `XLATCH` is written by the chip at the edge, so neither
  stage is limited by firmware's poll interval.
- `XLATCH` equalled the settled `XACTUAL` on the fast approach: **overshoot
  0 usteps**, which is what a hard stop should give.
- Closing edge to release edge: **691-728 usteps** across runs. That is the
  approach's 89-ustep debounce overshoot plus the switch's own throw.
- **Repeatability: 2 to 5 quadrature counts, in BOTH schemes.** Four series of
  five runs: single-stage at 0.050 rev/s gave 51 usteps (4 counts); two-stage
  gave 25 usteps (2 counts), then 64 (5), then 64 (5) again with a throwaway
  home first. **The rig cannot distinguish the two schemes at n = 5**, and an
  earlier entry claiming the second stage halved the scatter was reading a
  single lucky series. Retracted.
- **Why that is expected, not disappointing:** the reporting delay is 8.74 ms
  and highly repeatable, so it is a *systematic* offset. It moves where zero is;
  it does not widen run-to-run spread. What the second stage buys is that the
  datum no longer depends on approach velocity (89 usteps of offset at
  0.200 rev/s, 4.5 usteps at the creep), and that the primary approach can run
  four times faster than a single-stage home that has to be slow because it *is*
  the datum.
- **The residual 2-5 counts is unexplained.** 64 usteps is five encoder quanta,
  so it is not quantisation. Most likely the switch's own mechanical
  repeatability amplified through the gear pair — testable by homing against a
  hand-held short at `J1301` instead of the mechanism. Backlash between motor
  shaft and lever, and variation in the reporting delay, are the other
  candidates.
- **Record the velocities with any future figure** — the datum moves with
  approach speed, so a repeatability number without a velocity is meaningless.
- Homing time: **2531 ms** per two-stage run, of which the fast approach is
  365 ms and most of the rest is the creep (768 usteps at 512 usteps/s). Raising
  the creep to 0.020 rev/s would roughly halve it and still keep the creep's
  share of the delay under one encoder count. Single-stage was ~1015 ms.
- Switch throw, engage to release: **512-630 usteps**, 3.6-4.4 deg at the motor.
  (An earlier 256-ustep figure came from a coarser stepped sweep.)
- Behaviour when the switch is never reached: bounded. The approach targets a
  position two motor revolutions away, far beyond the rig's travel, so a switch
  that never asserts ends the move rather than running the mechanism.
- Hardware latch versus software position agreement: `XLATCH` and `XACTUAL`
  agree exactly. `ENC_LATCH` is latched in the same event.

**Travel, measured — this was not known before.**

- Positive end: the limit switch.
- Negative end: a **mechanical stop**, found by the firmware's encoder follow
  check. `XACTUAL` reached −4330 usteps while `X_ENC` stopped following at about
  −3276, i.e. the ramp kept going and the shaft did not.
- **Usable travel ≈ 4000 usteps ≈ 28 deg at the motor shaft**, less at the
  joystick through the gear pair. Every bring-up distance has to fit inside
  this; the first encoder round trip was written at 5120 usteps and ran straight
  off the end of the mechanism.
  **Corrected 2026-09-09, twice over.** The hard stops are movable, so 28 deg is
  where they sat that day and not the mechanism's range, which is ~60 deg on both
  joysticks; and the gearing is **1:1**, so joystick degrees equal motor degrees
  rather than being "less". See [The 28 deg travel figure is a hard-stop setting,
  not a mechanism
  property](#the-28-deg-travel-figure-is-a-hard-stop-setting-not-a-mechanism-property).
- Nothing was strained finding it. At `IRUN` 8 the motor simply stalls, and the
  follow check ends the move within one 200-ustep window.

**Not yet measured on this unit:** coil current RMS, sense-resistor
temperature, `DIAG0`/`DIAG1` behaviour, microstep smoothness, step-rate ceiling,
encoder supply current, and any of it at a current above `IRUN` 8.

## Thermal Survey — Procedure And Results (opened 2026-09-09)

Taken with a thermal imaging camera on **v0.2 hardware**, deliberately, rather
than waiting for v0.3. The motor, driver, shunts and 36 V path are identical on
the two revisions — verified by diffing `kicad/` at `v0.2` against `cab25b3` — so
waiting buys nothing on any row below.

**What it settles.** `IRUN` 17 (0.421 A RMS) versus 24-25 (0.600 A), the last
open question about the fitted motor and the one input the shunt decision needs.
That decision is a **v1.0 layout** matter: staying at 0.15 Ω keeps the present
land, and moving to 0.22 Ω 2512 changes it in both the library block and this
board, where `BRA`/`BRB` are routed tight. Take it before v1.0 placement, not
after.

It also fills four slots owed since before v0.2 shipped: TMC5130A case
temperature idle and under motion, the 3.3 V LDO, and sense-resistor temperature
under load.

### Before anything is energised

- **Hand-check the left joystick's swing.** It may have been left jammed on
  2026-09-03 and that is still open — see [OPEN: the mechanism may have been left
  jammed](#open-the-mechanism-may-have-been-left-jammed). If there is any doubt,
  take the motion runs on the **RIGHT** joystick, board `E4654C159F4D1334`, whose
  usable travel is measured at ≈4000 usteps ≈ 28 deg at the motor shaft.
- **Re-establish which board is on which port** with the `ID` reply or the
  InstrumentPort beacon. The harnesses are mirrored, and the table at the top of
  this file is only as good as the last recabling.
- **Record the board serial on every reading.** Two interchangeable boards in one
  rig is the failure mode this log exists to prevent.
- **Record ambient in the same frame as every part.** The quantity that transfers
  is rise above ambient, not absolute case temperature.

### Camera setup — this is what decides whether the numbers mean anything

- **Emissivity dominates the error.** Black plastic IC packages read acceptably
  at ~0.95. The motor's plated can, the shunts' metal element and bare copper
  read **far too low** at that setting. Put a matte black target — electrical
  tape or paint — on the motor can and beside the shunts, and read the target
  rather than the metal. Record the emissivity you set.
- **Shiny surfaces reflect you and the room.** If a hotspot moves when you move,
  it is a reflection, not a part.
- **Spot size versus distance.** A 1206 shunt is smaller than the detector spot
  at a typical working distance, so a reading there is an average of its
  neighbourhood. Get close, and mark which readings are spot averages.
- **Let it settle.** An 82 g NEMA 08 has a thermal time constant in the
  many-minutes range, so the 30-minute soaks below are not padding. A reading
  taken a minute in tells you nothing.
- Record camera model, emissivity, working distance, whether a target dot was
  used, and ambient — once per run.

### The two runs, and one firmware constraint to know first

The bench console's `n` command **refuses any run current above `IRUN` 17**:
`conv::kCurrentScaleCeiling` is derived from the conservative 0.421 A reading, so
**`IRUN` 24 needs a rebuild**, not a keystroke. `IHOLD` is likewise fixed at
`conv::kCurrentScaleHold` = 2 (0.070 A RMS), so a standstill soak *at run
current* — the true worst case for the coils, and one that needs no motion at all
— also needs a firmware change. Record which firmware and which path each run
used.

- **Run A — energised, standstill, 30 min.** Baseline. Note whether the coils sat
  at `IRUN` or dropped to `IHOLD`; at `IHOLD` = 2 this is a near-idle number and
  must be labelled as one.
- **Run B — representative continuous motion, 30 min.** Back and forth, well
  inside the measured travel. This is the number the duty-cycle question wants.

Repeat both at each `IRUN` under test. Predicted copper loss, both phases at
6.5 Ω/phase: **2.31 W at 0.421 A** (`IRUN` 17), **4.68 W at 0.600 A** (`IRUN` 24),
and **7.29 W at 0.749 A**, the `vsense` = 1 hardware ceiling.

### Results

Copy this block once per (board, run, `IRUN`). Numbers with units, not pass/fail.

- Board serial / run (A or B) / `IRUN` / `vsense` / shunt value:
- Firmware and path used (bench console or protocol):
- Ambient, emissivity, camera and working distance:

| Part | Designator | Case temp | Rise above ambient | Notes |
| --- | --- | --- | --- | --- |
| TMC5130A | `U1201` | | | |
| Sense resistor A | `R1203` | | | |
| Sense resistor B | `R1204` | | | |
| 3.3 V LDO | `U1001` | | | |
| 5 V buck | `U901` | | | |
| High-side switch | `U201` | | | |
| 36 V bulk | `C1213`/`C1214` | | | |
| Motor can | — | | | |
| Gear pair / mechanism | — | | | |
| Hottest thing in frame, whatever it turns out to be | | | | |

- `DRV_STATUS` `otpw` / `ot` at the end of the run (free over SPI, and it is the
  chip's own thermal opinion):
- Coil current measured, RMS, at this `IRUN`:
- Anything unexpected in the field of view:

#### Run B — board `E4654C159F4D1334` (RIGHT), 2026-09-09

- **Conditions:** `IRUN` 17 = 0.421 A RMS, `vsense` = 1 read back, `R1203`/`R1204`
  0.15 Ω, `IHOLD` 2. Rail up via the firmware staircase, 133 ms, peak 3.317 V.
- **Firmware and path:** `MotionAndHoming` over the USB console, repeated `g`
  (jog one step away from the switch and back, ±9 deg at the motor shaft) every
  1.2 s.
- **Duration:** 10:44 to 11:50, ~66 min, with a 50 s break at 11:14. About 1300
  cycles, 2600 legs at 459 ms each.
- **Duty:** motion occupied **72%** of wall time, but `DRV_STATUS` polled
  `cs_actual` = **15 with `stst` = 1** throughout, so the coils sat at
  essentially run current between cycles as well as during them. The firmware
  never writes `TPOWERDOWN`, so it holds the chip default (~164 ms) and the
  standstill gaps here are shorter than power-down plus ramp. **Electrical duty
  is therefore near 100%: this is the continuous case, not a duty-cycled one.**
- **Camera:** emissivity 0.95. The "ambient" column below is the **minimum pixel
  in frame**, not room air — see the caveats. Room was about 25 °C.

| Clock | t | "Ambient" | TMC5130A `U1201` | Motor can |
| --- | --- | --- | --- | --- |
| 10:47 | 3 min | 24.5 °C | 44.5 °C | 34.5 °C |
| 10:54 | 10 min | 24.3 °C | 45.3 °C | 38.7 °C |
| 11:04 | 20 min | 25.1 °C | 45.3 °C | 40.6 °C |
| 11:14 | 30 min | 23.3 °C | 46.9 °C | 42.6 °C |
| 11:27 | 43 min | 25.3 °C | 45.6 °C | 42.3 °C |
| 11:50 | 66 min | 25.2 °C | 45.5 °C | 43.3 °C |

**Plateau: TMC5130A ≈ 45.5 °C, motor can ≈ 43.3 °C**, against a room of ~25 °C,
so roughly **+20 °C and +18 °C** of rise. The motor was still creeping ~1 °C per
20 min at the end; the TMC was flat from ten minutes on.

- `DRV_STATUS`: **`ot` = 0 and `otpw` = 0 on every poll** across both runs.
  `cs_actual` = 15, `sg_result` 70-78, `stst` = 1 between cycles.
- **No follow failures in ~1300 cycles**, so the mechanism ran free throughout.
- Coil current, RMS: **not measured** — no clamp on the bench this session. The
  case temperature is the half that was taken.
- `R1203`/`R1204`, `U1001`, `U901`, `U201` and a wide board frame: **not
  measured.** Worth one shot next time the rig is warm; the shunts' ±100 ppm/°C
  tempco is a current-accuracy term, so their temperature bounds it.

**What it settles.**

- **`IRUN` stays 17.** 43.3 °C continuous leaves 16.7 °C to the motor's 60 °C
  case maximum in this room, and real use is far below continuous.
- **`IRUN` 24 is rejected without testing it.** Rise scales as
  (0.600/0.421)² = 2.03, giving ~+37 °C, i.e. **~62 °C in this room** — over the
  case maximum before any allowance for a warm day. That scaling is robust to the
  duty uncertainty, because whatever fraction of time the coils spend at run
  current applies equally to both currents and cancels.
- **`R1203`/`R1204` stay 0.15 Ω with `vsense` = 1.** Moving to 0.22 Ω 2512 needed
  `IRUN` settled at 17 **and** a reduction above ~1.7:1. The gearing is 1:1 on
  both joysticks, so the second condition fails and the 2512 land change is off
  the table in both the library block and this board.

**Three caveats that belong with the numbers.**

1. **The motor can was read at ε = 0.95.** If that frame was bare plated metal
   rather than a matte target, every motor figure here is a **floor**, and the
   `IRUN` 24 projection gets worse rather than better.
2. **The "ambient" column is the coldest pixel in frame, not room air.** It
   wandered 23.3-25.3 °C non-monotonically, and at 11:27 it moved *up* 2.0 °C
   while both parts moved *down* — it tracks framing, not the room. Rises here
   are computed against ~25 °C rather than that column. Next run: read one fixed
   matte reference away from the rig, every frame.
3. **A plateau was called at 20 min and was wrong.** A single-exponential fit to
   the first three points gave τ ≈ 3 min and +15.3 °C; the real curve has a
   second, slower constant — the joystick assembly and board copper soaking — and
   the motor gained another ~3 °C after that "plateau". Do not call steady state
   on a small-package fit when the part is bolted to something large.

### Reading the result

- **Run B bounds the design; it does not represent the experiment.** Established
  2026-09-09: real use is **low duty** — the researcher commands a motion, the
  motor depowers and waits, and there may be a rehome and another move, with
  cooling periods between. A back-to-back motion soak is therefore a worst case,
  which is the more useful thing to measure, but the margin it reports is not the
  margin a trial sees. **The one thing that would make it representative is a
  hold-against-force mode**, which is still open with the researcher — a
  sustained hold energises the coils continuously and puts the motor back on
  this curve.
- **The motor is the binding part.** Its datasheet gives a **60 °C case maximum**
  against a **50 °C ambient maximum** — a 10 °C rise budget at worst-case ambient
  — so compare rise, not absolute. That 60 °C figure is **inconsistent with the
  Class B (130 °C) winding insulation quoted on the same datasheet page**, and the
  inconsistency is worth a question to Lin Engineering whichever way the numbers
  land.
- **Record the shunt value, the `vsense` bit and `IRUN` in one place.** They are
  one decision, and a temperature without all three is uninterpretable later.
- If `IRUN` 17 sits comfortably inside the rise budget and 24 does not, 17 wins
  and the shunt stays 0.15 Ω. If 17 is already at the thermal limit, the
  motor-against-brake sweep has no overcurrent headroom to buy, which is the case
  where keeping the 23.4 mA step matters more than the 0.22 Ω 2512's extra sense
  signal.
- **The gear-teeth count is the other half of that decision and needs no power at
  all.** Count both assemblies while the rig is open: above roughly 1.7:1 the
  motor at rated current reaches the brake's full 3.5 N·cm and the sweep needs no
  headroom either way.

### What this survey cannot settle

The brake pass device. The `BUK7D36-60EX` has **no linear-mode SOA derating
curve** in its datasheet, which is precisely why its case temperature is not
optional — but that circuit does not exist until v1.0, and the 6 cm² of drain
copper it is conditioned on is a v1.0 layout obligation. Take it during v1.0
bring-up, with this camera and this procedure.

## Open Issues Found During Bring-Up

### The 28 deg travel figure is a hard-stop setting, not a mechanism property

**Established 2026-09-09, from Peter: the hard stops on both joysticks are
movable, and both mechanisms have roughly 60 deg of range.** At 1:1 gearing that
is 60 deg at the motor shaft too. **28 deg is not the travel of either
joystick** — it is where the stops happened to sit, or how far a hand pull got,
on the day it was measured.

That number is load-bearing in at least five places in this file, and in
firmware:

- `kMeasuredTravelMicrosteps` = 4000 (≈28 deg), measured on board 2 (RIGHT) and
  used since as if it described the mechanism.
- "Usable travel ≈ 4000 usteps ≈ 28 deg at the motor shaft" in board 2's stage 3
  entry. The same sentence adds "less at the joystick through the gear pair",
  which is **also wrong**: the ratio is 1:1, so joystick degrees and motor
  degrees are the same number.
- "Travel is ~28 deg at the motor shaft" in the FREEWHEEL analysis, where it is
  the premise for calling **-40.95 deg impossible mechanically**. With ~60 deg of
  range that premise no longer holds. The reading may still be an artefact — it
  was frozen across the whole window, which is independent evidence — but
  "impossible" is not the reason. **This file has already recorded one encoder
  reading dismissed as impossible that turned out to be real** (see "The encoder
  was RIGHT: -28.083 deg is the mechanical end of travel"), so the same mistake
  has now been made twice from the same bad figure.
- The travel-limit finding and the limit-switch-end argument both quote it.

What follows: **usable travel is a rig configuration to be set and recorded, not
a constant to inherit from a measurement.** Set both mechanisms' stops to the
same range deliberately, record it per joystick with the date, and derive the
firmware limit from that rather than from `kMeasuredTravelMicrosteps`. The
earlier left/right disagreement (64.174 deg full swing on the left against 28 deg
on the right) is explained by movable stops rather than by the two assemblies
differing, which also retires the "different small-gear geometry is a scientific
confound" worry — the gearing is 1:1 on both.

### `docs/power.md` is stale about `HV_SNS` and `~{HV_FAULT}`

`power.md` says both "sit behind" the GPIO isolation bus switch and cannot be
read until firmware enables it. `docs/interface-map.md` marks both `byp`, and the
pad-to-net map agrees at `v0.1` and at HEAD: `GP28`/`GP29` reach the 36 V switch
directly, with no underscore-suffixed twin net. `interface-map.md` is right —
the switch sits *upstream* of the switched domain, so the bypass rule applies.
Firmware follows the netlist. Worth correcting in `power.md`.

### Designator collision between `v0.1` and HEAD is a live hazard

`R1901`/`R1902` are the 100 Ω pyControl series resistors at `v0.1` and the 1 kΩ
`HV_EN`/`HV_DIAG_EN` series resistors at HEAD. Anyone reading a HEAD-era document
while holding a rev 0 board can probe the wrong part and draw a confident wrong
conclusion. The existing warning in this file covers the three motor/encoder
connectors but not the 36 V input block, which moved wholesale from
`U201`/`R201`-`R207` to `U1901`/`R1901`-`R1907`. Consider extending the table.

### The two rig boards disagree on `REFL_STEP` and `ENCB` — HALF RESOLVED

**Resolved for board `E4654C159F4D1334` on 2026-09-02 by stage 3, with the
switch and encoder connected.** Both of its "unexpected" readings were the
connectors being empty, not defects:

- **`REFL_STEP`.** With the limit switch fitted the resting level is **0** and
  the triggered level is **1**, and the motor drove it through both transitions.
  So `U1301`'s output path is intact on this board, and its empty-connector 0
  was simply `R1405` holding `LIMIT_SW` low with nothing driving it. The
  hand-short test proposed below was never needed.
- **`ENCB`.** With the E4T-1000 fitted, `ENCA`/`ENCB` read as a legitimate
  quadrature state and change as the shaft turns — observed going 1/1 → 1/0 →
  0/1 → 0/0 across moves. Its empty-connector 1 was a floating CMOS input.

**Still open for board `E4654C159F2C2534`**, whose empty-connector `REFL_STEP`
read 1. That is the reading the netlist argument below predicts, and it is now
the odd one out: the same net reads 0 on the other board with the connector
empty. Nothing has been connected to board 1 yet, so run stage 3 on it before
drawing any conclusion — and note that board 1 has `R203` depopulated, so it no
longer represents an as-built board for anything.

**The original entry, kept because it is the reasoning that got here:**

**Written 2026-09-02, then contradicted the same day by the second board.** The
subsection below argued from the netlist that `REFL_STEP` = 1 is correct because
the MAX6816 must supply its own pull-up. Board `E4654C159F4D1334` reads
**`REFL_STEP` = 0**, so that inference does not hold. Keep the netlist reading —
it is ground truth — but treat the conclusion as open.

With **all connectors empty on both boards**, `IOIN`'s low byte differs:

| Board | `IOIN` | Unexpected inputs high | Firmware expects |
| --- | --- | --- | --- |
| `E4654C159F2C2534` | `0x11000011` | `REFL_STEP` | `0x…10` |
| `E4654C159F4D1334` | `0x11000014` | `ENCB` | `0x…10` |

Each board has exactly one unexpected input high, and it is a **different**
input. Board 2's reading is stable across three consecutive `i` reads with the
rail up for tens of seconds, so it is not a MAX6816 debounce-settling artifact.

Two candidate explanations, and the bench can separate them in a minute:

1. **Assembly defects, one per board.** An open joint on `U1301`'s `OUT` would
   leave `LIMIT_SW` held low by `R1405` → board 2's `REFL_STEP` = 0. An open
   joint on `U801`'s channel-B input would let a CMOS input float high →
   board 2's `ENCB` = 1. Board 1 would then have the `U1301` path intact and
   board 2 would have two defects.
2. **Both nets are genuinely indeterminate with the connectors empty**, in which
   case neither board is faulty and neither reading means anything.

**Two decisive tests, both zero-risk, neither yet done:**

- **`REFL`:** short `J1301` pin 1 to pin 2 (a switch closure — pin 1 is `GND`,
  pin 2 is `IN`) and re-read `IOIN`. If `REFL_STEP` changes, `U1301` and its
  output path work. If it does not move on board 2, `U1301` or its `OUT` joint
  is the problem.
- **`ENCB`:** short the 5-position encoder terminal's pin 5 (`ENC_B_RAW`) to
  pin 1 (`GND`) and re-read. If `ENCB` goes to 0, the path works. **Do not touch
  pin 4 — it is `+5V_SW`.**

Until then, do not treat either value as a known-good baseline, and **do not
"fix" the firmware's expected `IOIN` by flipping a bit** — there is no single
correct value while the two boards disagree.

The consequence for stage 3 is unchanged and still the most important part:

### Original reasoning, kept because the netlist half of it is still ground truth

Stage 2's register check expects `IOIN.REFL_STEP` = 0 and blames `R1405`. Read
from the `v0.2` `.kicad_pcb` rather than from a document, the chain is:

```text
J1301 pad 2 ── IN ── U1301 MAX6816 pad 2 ┐
J1301 pad 1 ── GND                       ├─ pad 3 OUT ── LIMIT_SW ── U1201 pad 8 REFL
                                         └─ pad 4 = +3.3V_SW
R1405 (0402) : LIMIT_SW ── GND
```

`IN` has **no external pull of any kind** — the net reaches only `J1301` pad 2
and `U1301` pad 2. A switch debouncer with a switch-to-ground topology and no
external pull-up must supply its own, so with the connector empty `IN` sits
high, `OUT` drives high, and `REFL` reads 1. `R1405` cannot override a driven
CMOS output; its job is to define the level while `+3.3V_SW` is **down**, the
same role `R805`/`R806` play for the encoder taps.

So `R1405` cannot be what holds `LIMIT_SW` low when `U1301` is driving, and the
firmware comment that blames it is wrong on that point. **What does not follow —
and what board 2 disproves — is the conclusion that `REFL_STEP` = 1 is therefore
the correct reading.** Report `REFL_STEP` rather than asserting it: with nothing
plugged in there is no correct value to assert.

**The consequence for stage 3 is the real finding.** The switch is **active-low
at `REFL`**, and `SW_MODE` defaults to `pol_stop_l` = 0, meaning active-high. So
the moment stage 3 sets `stop_l_enable` = 1 without also setting
`pol_stop_l` = 1, an *un-triggered* switch reads as "left stop active" and
motion is blocked. Confirm against the actual switch's normally-open /
normally-closed wiring before homing.

### The USB CDC console can hang the sketch, and it did

2026-09-02, before any measurement: the board enumerated correctly —
`2e8a:f00a`, `Orb Weaver`, `mouse-joystick-pcb`, serial `E4654C159F2C2534`,
both interfaces bound to `cdc_acm` — but **answered nothing** over
`/dev/ttyACM0`. Zero bytes across repeated pokes over 10+ s, and
`SET_CONTROL_LINE_STATE` (asserting DTR) **stalled** with `EPIPE`.

The MCU was executing throughout: it was serving its own USB descriptors,
including the serial string read from flash. So this is not a power fault.

The 1200-baud touch could not rescue it — that reset is triggered by exactly
the DTR request that was stalling. `picotool` could not either: this build
exposes only the two CDC interfaces, no vendor reset interface. **A physical
USB replug was the only recovery**, and it worked first time.

Likely mechanism: arduino-pico's `SerialUSB::write()` spins until the host
drains the endpoint, and stage 2's banner plus `printMenu()` is roughly 1 kB
against a 256-byte CDC FIFO. Booting with no terminal attached parks the sketch
inside `setup()`. **Worth fixing in firmware** — guard the banner on `Serial`
being connected, or bound the write — because on a board with no LEDs, no test
points and no SWD header, a wedged console means a wedged board.

Unrelated but found the same way: **`pixi run test` clobbers `.pio/build`.**
The `build` task scopes `PLATFORMIO_BUILD_DIR` per example; the `test` task does
not, so running tests deletes every example's build output including
`firmware.uf2`. Bit once mid-session, between a `B` into BOOTSEL and the flash
that was supposed to follow it.

### The limit switch is at the positive end of travel, on the `REFL` input

**Found 2026-09-02 on board `E4654C159F4D1334`.** A firmware-level problem with
a hardware cause, so it is recorded here rather than only in the firmware
repository.

`J1301` feeds TMC pin 8, `REFL` — the **left** reference switch, which the
TMC5130A uses to stop **negative** motion (datasheet rev 1.21 section 14.4: "a
stop occurs when the velocity sign matches the reference switch position, REFL
for negative velocities, REFR for positive velocities"). The switch is
physically at the **positive** end of the joystick's travel.

So `stop_l_enable` alone arms the stop against the direction that moves *away*
from the switch, and leaves the direction that drives *into* it unguarded. The
fix is `SW_MODE.swap_lr`, which routes the `REFL` pin to the right-stop logic;
firmware now sets it from a `HomeEnd` setting and homes positive.

**Nothing to change on the board** — `swap_lr` exists for exactly this, and
`REFR` is tied to GND so the swapped-in left stop reads a harmless 0. Worth
knowing before anyone wires the second joystick, or `../mouse-joysticks-pcb`,
and assumes the switch end is a free choice. If a future revision wants the
hardware default to be the natural one, put the switch at the negative end of
travel or wire it to `REFR`.

### `IRUN` = 28 predates the motor and is above its rating

`docs/rev0-plan.md` and `mouse-joystick-firm`'s `.agents/AGENTS.md` both carry
"`vsense` = 1 with the 0.15 ohm shunts, `IRUN` = 28", against a target of
0.679 A RMS. That target was set before the motor was identified.

The fitted motor is a **WO-208-13-01D rated 0.6 A per phase**, so `IRUN` = 28 is
above the rating on either reading of that figure — 13% over the equal-heating
reading, 60% over the peak-of-sine reading. `vsense` = 1 is still correct and
still load-bearing; the current scale is what needs revising.

Firmware currently enforces `IRUN` <= 17 (0.421 A RMS, the peak-of-sine
reading) and runs bring-up at `IRUN` = 8 (0.211 A RMS). **Settle it with a coil
current measurement and a case temperature**, then change the number in one
place and record which reading won.

**SETTLED 2026-09-09 by case temperature: `IRUN` 17 wins, and the peak-of-sine
reading is the one to keep.** 66 minutes of continuous energisation at `IRUN` 17
plateaus the motor can at **43.3 °C** in a ~25 °C room, 16.7 °C below its 60 °C
case maximum, with `ot`/`otpw` clear throughout. `IRUN` 24 scales the rise by
(0.600/0.421)² = 2.03 to about **62 °C in the same room**, over the maximum
before any allowance for a warm day. Coil current was **not** measured — no clamp
on the bench — but the thermal half is decisive on its own, and the scaling is
insensitive to the duty question. Full data, method and caveats in
[Thermal Survey](#thermal-survey--procedure-and-results-opened-2026-09-09).

### No test points remains the binding constraint

Every stage 1 result above came from the RP2040's own ADC and GPIOs or from the
InstrumentPort. No independent meter reading was taken anywhere, so the ADC
figures confirm self-consistency rather than absolute accuracy — and `ADC_AVDD` is
tied straight to `+3.3V_MCU`, so the ADC cannot measure its own reference. A
single meter reading of `+3.3V_MCU` and `+5V_MCU` would close that gap.

## Changes Recommended For The Next Revision

### 1. `LATCH` must not be strapped high — this is the one that matters

`R203` (0402, `+3.3V_MCU` → `LATCH`) selects latch-off over the device's own
2 ms auto-retry, and that is what turns a survivable retry sequence into a hard
stop. The datasheet sanctions retry-until-charged "with high enough load
impedance"; `+36V_SW`'s 0.87 MΩ qualifies, and the firmware staircase that now
works is a hand-rolled version of exactly that.

**Put `LATCH` on a GPIO**, so firmware chooses latch-off for real faults and
auto-retry for power-up, or tie it low. Either way keep a `1 kΩ` `RPROT` per
Table 4-2. `LATCH` has a 0.7-1.3 MΩ internal pulldown, so on an assembled board
**depopulating `R203` alone** selects auto-retry.

**Done and validated on this board, 2026-09-02.** `R203` removed; a plain
`HV_EN` assertion brings the rail up in 4 ms after a 10-12 ms retry window, no
latched fault, 4 of 4, and the full stage 2 sequence passes. **Carry this into
v0.4.** The `RPROT` position should stay so the choice remains available; only
the far end changes from `+3.3V_MCU` to a GPIO or to `GND`.

One consequence to keep in mind: with `LATCH` low the device no longer latches
on a *genuine* fault either — it auto-retries every 2 ms indefinitely. Firmware
must therefore read `~{HV_FAULT}` and decide, rather than relying on the part to
stay off. A GPIO on `LATCH` gets both behaviours: low for power-up, high once
the rail is established.

### 2. Halve the `+36V_SW` bulk, or justify it

`C1213` + `C1214` = 200 µF of `EEEHAH101UAP` plus ~8 µF of ceramic. 208 µF at
36 V is 135 mJ per turn-on into an HTSSOP-14, and the switch demonstrably cannot
deliver it in one burst. Depopulating `C1214` halves it to 67 mJ. This finally
settles the question left open in `.agents/handoff.local.md` — 200 µF against
`docs/power.md`'s "tens of µF, not hundreds" — with a measurement instead of an
argument.

### 3. Do not raise `I_CL`

The instinct is to increase `R206`'s current limit. It does not help: the FET
absorbs ½CV² = 135 mJ regardless of the limit, just faster and into a smaller
transient thermal impedance. The levers are bulk capacitance and retry
behaviour. If anything, 1.15 A is already near the bottom of the part's 1-5 A
window, which is the least-characterised corner of the spec.

### 4. Test points, at last

`+36V_SW`, `+5V_SW`, `+3.3V_SW`, `+3.3V_MCU`, `+5V_MCU`, and both sides of
`R1903`. Every number in this file above came from the RP2040's own ADC, and the
one measurement that would have settled the 36 V question in five minutes — a
scope on `+36V_SW` — still has not been taken because it means probing the pads
of `C1213`. Usable stand-ins on `v0.2`/`v0.3`, read from the `.kicad_pcb`:

| Rail | Probe at |
| --- | --- |
| `+36V_SW` | `C1213` pad 1, GND on `C1213` pad 2 (D8×10.2 mm can, easy to clip) |
| `HV_IN` | `C201` pad 1, or `D201` pad 1 (cathode) |
| `HV_RAW` | `J201` pad 2, or `D201` pad 2 (anode) |
| `+5V_SW` | `U901` pad 4 or 9, `U1001` pad 5 or 8 |
| `+3.3V_SW` | `U1001` pad 1 |

### 5. Firmware, not hardware, but record it here

The shipping power-up path should be the staircase, not a single `HV_EN`
assertion — `PowerSequence::staircaseStart()`. 30 bursts of 1200/800 µs costs
60 ms and has worked 5 of 5 times. Whether it needs 30 or 6 has not been
measured; the arithmetic says ~6 should do it, and knowing the real margin
would be worth one rebuild.

