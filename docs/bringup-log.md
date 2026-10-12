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

**Seven units are now known, across three PCB revisions.**
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
| **Board 4** | `E4654C159F171E34` | **First `v0.3` unit, added 2026-09-09.** `LATCH` strap intact — on this revision that is **`R1903`**, not `R203`. **Drives the RIGHT joystick.** **The angle output is characterised as of 2026-09-10** — unity gain to 0.03%, 4.5 mV floor, `VREFIO` 2.500 V, no motor coupling, and a live 1 kHz encoder-to-analog loop measured at exactly 1000.0 Hz over 835 000 updates. **Stages 1, 2 and 3 all passed 2026-09-09** — stage 1 on USB alone (24 checks, 0 failed), then stage 2 and stage 3 with everything connected: rail up in 132 ms, TMC5130A alive, encoder follow ratio **1.0000**, homing repeatable to **2.0 encoder counts**. See [stage 1](#board-4--e4654c159f171e34--v03-stage-1), [stage 2](#stage-2-passed-on-board-4--2026-09-09-36-v-on-nothing-else-connected), [stage 3](#stage-3-passed-on-board-4--2026-09-09-everything-connected). Stage 4 not run on this unit |
| **Board 5** | `E465C0164B30612D` | **Second `v0.3` unit**, `MJ_BOARD_REV=1`, named board 5 in the firmware handoff of 2026-10-02. Carries a `mouse_joystick_qp_rev1_usb` build from that morning; **stages 1–3 have never run on it.** Not on the bench 2026-10-05 |
| **Board 6 (v1.0 unit A)** | `E4654C159F274534` | **First `v1.0` unit**, `MJ_BOARD_REV=2`. Arrived with a wrong green, banded part at every `C2858031` position; dead until `C1301` was removed on 2026-10-05, then `C1208` refitted with a genuine 4.7 µF and `C1501` removed. **Stages 1, 2, A3, A6 and the QP protocol session passed 2026-10-05; stages A4 (brake sink) and A5 (torque bridge) passed 2026-10-06** — brake 0–48.80 mA linear, full-scale step overshoots to 62 mA with no `~{BRAKE_FAULT}`; ADS8689 alive, 95–112 µV rms, shunt-cal switch inert. Drives the replacement joystick unit. See [v1.0 unit A](#v10-unit-a--e4654c159f274534--stage-1-passed-2026-10-05-1504-after-removing-c1301) and [A4/A5](#v10-unit-a--stages-a4-and-a5-brake-sink-and-torque-bridge-2026-10-06-08480855) |
| **Board 7 (v1.0 unit B)** | `E4654C159F404534` | **Second `v1.0` unit**, `MJ_BOARD_REV=2`. Arrived with the same wrong part at `C1301`, `C1208`, `C1501`; reworked by Peter 2026-10-07 (`C1208` refitted, `C1301` and `C1501` removed). **Stage 1 passed 2026-10-07, 09:08: 20 checks, 0 failed.** For the LEFT joystick of Rig 1 (Breakout port 1). See [v1.0 unit B](#v10-unit-b-board-7--e4654c159f404534--stage-1-passed-2026-10-07-0908) |

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
harness examples in this file and in `mouse-joystick-firm/docs/` that name
`/dev/ttyACM0` were written when that was board 2. With boards 2 and 3 attached,
`/dev/ttyACM0` is board 3. **Address boards by `/dev/serial/by-id/`**, which
carries the serial, and never by `ttyACM` number.

Everything from here to [Board 2](#board-2--e4654c159f4d1334) is **board 1**
unless a line says otherwise.

## v1.0 Boards — arriving 2026-10-05 (nothing measured yet)

**Two v1.0 units ordered from the fabrication package committed in `646b8f4`
(2026-09-21); the board file has been unchanged since `d5ae4b0`.** No `v1.0`
tag exists at the time of writing; tag the fabricated commit before recording
the first measurement so this section can cite it. Add one row per unit to the
table above as each serial is read from `RP2040SelfTest`, and keep one section
set per serial below this one, as for boards 1–4.

v1.0 is **`MJ_BOARD_REV=2`** in firmware (`env:mouse_joystick_rev2`,
`mouse_joystick_qp_rev2*`), written 2026-10-04 from the pad-to-net map of
footprint **`U601`** — the RP2040 moved into the combined MCU block
(`rp2040_with_gpio_isolation_sn74cb3q3245`) and **`U501` is now the 36 V
switch**. Every designator below is v1.0's, read off the `.kicad_pcb`; most of
them collide with v0.3 names that meant something else.

### First power-up of the first v1.0 unit — 2026-10-05, 13:30: not alive on USB, instrument port silent

Bench: joystick, motor, encoder, limit switch, brake and torque sensor cabled,
USB connected, 36 V connected, Digital-50 to the LA5032 through the v2.0
adapter and a Molex 15020 FFC. Serial not yet known: **the board did not
enumerate at all** — no `2e8a:0003` RP2040 bootloader (a blank flash would
show one) and no CDC device, while the LA5032 on the same host enumerated
normally. A 5 s capture of all 32 channels at 100 kSa/s
(`mouse-joystick-firm/evidence/2026-10-05-1142-board4-regression/v1/v1_quiet_all32.sr`) read
**every channel low with no edges**. With `+3.3V_MCU` up the always-on
buffers would hold `DIG3` (`R401`), `DIG26` (`R507`) and `DIG27` (`R607`) high
in either cable orientation (CH3/26/27 straight, CH28/5/4 reversed); none was.
Two independent symptoms with one common cause: **the MCU domain is not
powered**, or the FFC is not making contact *and* USB fails separately. The
netlist is not the reason: `J201` has `R201`/`R202` 5.1 kΩ on CC1/CC2, `D201`
Schottky feeds `+5V_MCU`, `U701` TPS73733 makes `+3.3V_MCU`. No test points
exist; probe `C201` 100 nF (VBUS), `C701` 1 µF (`+5V_MCU`) and the `U701`
output. Nothing was energised by firmware: `HV_EN` floats low with the MCU
unpowered, so the switched domain stayed off (`PG_5V`/`PG_12V` low).
**13:36, USB cable swapped: unchanged** — still no `2e8a` device, all 32
channels still low (`v1/v1_quiet2_all32.sr`). Meter readings owed at `C201`
(VBUS), `C701` (`+5V_MCU`) and `C1301` (`+3.3V_MCU`).
**13:42, second v1.0 unit swapped in: identical** — no `2e8a` device, all 32
channels low (`v1/v1b_quiet_all32.sr`). Two units failing the same way points
at the design, the assembly or the bench feed rather than one bad board.

**Prime suspect, 13:50: the v1.0 fabrication package's placement rotations.**
The v0.3 package carried the KiCad rotation unchanged for every footprint
and assembled correctly. The v1.0 package applied a `kicad-libs` rotation table
that adds **+270°** to footprints the two boards share and that were right at
v0.3 without any offset: the flash `U602` (WSON-8), the bus switches
`U603`–`U606` (RGY VQFN-20), the USB ESD array `U201` (SOT-666), the 36 V
switch `U501` (HTSSOP-14), plus the new `U1301`–`U1304`, `U801`/`U1801`,
`U2002`. At most one of the two conventions is right, and v0.3 works. A
SOT-666 USBLC6 placed off its pads shorts `VBUS` to `GND`, which removes
the host's 5 V and matches both symptoms on both units. **Check the pin-1
marks of `U201`, `U602` and `U501` against the v0.3 board before anything
else, and keep the 36 V supply off until `U501`'s orientation is confirmed.**
`U701`, `U601`, `D201`, `J201`, `SW601`/`SW602` and `Y601` carry no offset,
and the USB-C receptacle, the tactile switch and the crystal footprints have the
same rotation on both orders, so they are not suspects. The table's rows are
"verified" in the sense that the corrected v1.0 CPL looked right in the JLCPCB
placement viewer before the order; the v0.3 CPL copied KiCad verbatim and those
boards nevertheless came out right, so one of the two orders has `U201`
(`USBLC6-2P6`, pin 5 = VBUS, pin 2 = GND) and the other rotated parts 270° off.
A rotated `U201` or a rotated `+3.3V_MCU` load (`U1301`–`U1304`, `U603`–`U606`)
is the one fault that explains **both** symptoms on **both** units without a
second one: the host's 5 V is shorted, the always-on domain never rises, and
the port buffers stay dark. Decisive checks, in order: pin-1 mark of `U201`,
`U602` and `U1301` against the same parts on a v0.3 board; VBUS at `C201` with
the board plugged in (≈0 V means the host port has folded back); `sudo dmesg`
for an over-current message.

**14:05, by eye and thermal camera (Peter): no chip is rotated, and `U701`,
the always-on `+5V_MCU` → `+3.3V_MCU` TPS73733, runs very hot with no visible
pin short.** That retires the placement-rotation suspect and says what the
fault is: the always-on 3.3 V rail is shorted or grossly overloaded, so the
regulator sits in current limit (up to ~5 W in a 3×3 mm VSON) and the rail
never rises — the RP2040's ROM never runs USB and the port buffers stay dark,
one cause for both symptoms on both units. `U1001`, the switched-domain twin,
cannot be the hot one with `HV_EN` low. Nothing in the netlist ties
`+3.3V_MCU` to `GND` except capacitors; the DRC saw no `+3.3V_MCU`-to-`GND`
proximity (its seven `+3.3V_MCU` clearance warnings are against signal tracks:
the buffer `~{OE}` nets at `U1302`/`U1304` pad 20, which tie to `GND` only
through 10 kΩ, and GPIO tracks at `C607`/`C614`). Owed measurements: `+3.3V_MCU`
at `C1301` and `+5V_MCU` at `C701` powered; resistance `+3.3V_MCU` to `GND`
unpowered (a healthy board reads kΩ); a slow thermal pass over the whole board
for a second hot spot (a cracked 0402 on the rail or a bridged QFN pad heats
at 1 A, a copper short does not). The BOM is clean for every part on
`VBUS`, `+5V_MCU` and `+3.3V_MCU` (right MLCCs, right resistor values, right
ICs), the DRC's closest copper on those rails is 0.100 mm to signal tracks and
none to `GND`, and `U701` is the same LCSC part (`C523768`) that works on v0.3.
Two regulators share the description "5 V to 3.3 V": `U701` (always-on, at
board (108.9, 97) mm beside the RP2040) and `U1001` (switched domain, at
(123.4, 96.8) mm); only `U701` can be live with `HV_EN` low. A healthy
always-on domain draws ~0.2 A, which already makes `U701` the warmest part on
the board, so heat alone does not prove an overload: the voltage does.
Side note, not the cause: v1.0 has **no pull-down on `HV_EN`** (v0.3 had
`R1904` 10 kΩ); `U501`'s EN relies on the RP2040 pad's default pull-down and
on the part's internal pull-down while the MCU is unpowered.

**14:30, prime suspect found by eye (Peter): `C1301` is not a ceramic
capacitor.** With only USB connected and `U701` hot, the part at `C1301`
(`+3.3V_MCU` to `GND`, board (151.4, 121) mm beside the Digital-50 buffers) has
a **green body with a black band at the `+3.3V_MCU` end**. The BOM position is
LCSC `C2858031`, Murata `GRM155R61E475ME15D`, 4.7 µF 25 V X5R 0402: a plain
grey ceramic with unmarked metal ends and no polarity. A banded green 0402 is
a polarised part, so the reel at that position was substituted or mis-picked.
The same reel feeds **`C1208`** (TMC5130A `5VOUT` to `GND`) and **`C1501`**
(`+5V_SW` to `GND`), both in the switched domain and not yet energised; on
v0.3 the same LCSC number sits at `C1208` and `C801` as the genuine Murata
part. A diode-like part across the always-on rail clamps it below the
RP2040's USB minimum, holds `U701` in current limit (hot) and keeps the port
buffers dark: one cause, both units, every symptom. Plan: measure across
`C1301` as mounted, remove it (the TPS737 is stable without it; `C702`,
`C603` and fifteen 100 nF remain), retry USB, test the removed part in diode
mode, then inspect and replace `C1208` and `C1501` before the first `HV_EN`.

**14:40, confirmed by eye (Peter): `C1208` and `C1501` carry the same green,
black-banded part on v1.0, and the `C1208` on a v0.3 board, same LCSC
number, is a normal unmarked ceramic.** So the v1.0 assembly run placed a
wrong reel at every `C2858031` position, on both units. Rework for both
boards: remove all three; `C1301` may stay empty for bring-up; **`C1208`
must be refitted with a real 2.2–4.7 µF ceramic** because it is the TMC5130A's
`5VOUT` regulator capacitor, which the driver needs for stability; `C1501`
(`+5V_SW` local bulk) may stay empty or take any 1–10 µF ≥ 10 V ceramic.
This is a quality claim against the assembler: the BOM line, the three
positions and a photo of a green part beside the v0.3 ceramic are the
evidence.

### v1.0 unit A (board 6) — `E4654C159F274534` — Stage 1 passed 2026-10-05, 15:04, after removing `C1301`

**The dead-board fault was the wrong part at `C1301`.** With it removed and
USB alone connected, the board enumerated as the RP2040 ROM bootloader
(`2e8a:0003`, blank flash), took `RP2040SelfTest` for `mouse_joystick_rev2`
by UF2 copy, and came back as `2e8a:f00a` with the serial above. **20
checks, 0 failed** — the count derived on 2026-10-04 is now observed.
Console log: `mouse-joystick-firm/evidence/2026-10-05-1142-board4-regression/v1/s1_selftest_rev2_boardA.log`.
`C1208` and `C1501` still carry the wrong part on this unit; the 36 V supply
stays off until they are replaced.

| Check | Result |
| --- | --- |
| reset reason | `software (3)` (the UF2 reboot) |
| `clk_sys` against `clk_ref` | 133000 kHz; `clk_ref` 12000, `clk_peri`/`clk_usb`/`clk_adc` 48000 kHz |
| flash | unique id read, 16 MiB declared, no aliasing at +2/+4/+8 MiB |
| heap | 252224 total, 16 KiB allocation and pattern walk ok |
| `GP9` `~{BUS_SW_EN}` | high — `R607` 7.87 kΩ holds the bus isolated |
| `GP24` `HV_LATCH` | **low** (informational: switch unpowered; low = auto-retry) |
| `GP16`/`GP17` `DAC_SDA`/`DAC_SCL` | high — `R403`/`R402` 4.7 kΩ |
| `GP1` `PYC_UART_RX` | high — `R401` 10 kΩ |
| `GP23` `~{HV_FAULT}` | high — `R507` 10 kΩ, no latched fault |
| spare pads `GP20`, `GP22` | both move both ways |
| `GP26` `SW_RAIL_SENSE_DIV_2` | 11 counts = 0.0089 V divided = **0.0177 V on `+3.3V_SW`**, off |
| `GP28` `HV_SNS` | 9–10 counts = 0.0073–0.0081 V across `R509` 249 Ω |
| `GP27` `BRAKE_ISENSE` | 7–11 counts = 0.0056–0.0089 V (0–1.006 V is 0–48.78 mA with the rail up) |
| `GP29` `ANGLE_OUT_MON` | 12–14 counts = 0.0097–0.0113 V (0–1.650 V with the rail up) |
| die temperature | 30.9 °C at boot, 32.3 °C a minute later |

**Digital-50 through the v2.0 adapter, 15:10 — straight mapping, markers and
beacon good.** With the LA5032 back: `R401`/`R507`/`R607` put `DIG3`/`DIG26`/
`DIG27` on **CH3/CH26/CH27** (a reversing cable would have given CH28/CH5/CH4),
so `CHn` observes `DIGn`; the four `GND`-tied strands and every switched-domain
tap read low as their biases predict with the rail off. Boot signature on a
commanded reboot: **CH1 (`FW_TRIG1`) 10.135, 10.005, 10.001 ms; CH0 (`FW_TRIG0`)
8 × 1.001–1.008 ms**, 1.18 s after the last heartbeat edge; heartbeat half-period
500.25 ms. The `I` beacon's three frames (50.0 ms start, 64 clocks) each decode
to **`E4654C159F274534`**, the flash id above. Captures
`mouse-joystick-firm/evidence/2026-10-05-1142-board4-regression/v1/v1a_boot_all32.sr` (all 32
channels, 100 kSa/s) and `v1a_signature.sr` (1 MSa/s). Owned by the adapter's
log; recorded there too. Not yet done on this unit: the `k` crystal check
against the host clock, the cold power-on reset reason.

**Firmware finding from the same capture: `~{BUS_SW_EN}` (CH27) drops low for
34 µs at every firmware boot**, 182 µs before the first signature pulse.
`SafeState::driveOutput()` calls `pinMode(OUTPUT)` before `digitalWrite(HIGH)`,
and the RP2040's output register is 0 after reset, so the pad drives low
until the second call: the bus switch closes for 34 µs at each boot. The MCU
pins are still inputs at that moment, so nothing drives into the switched
domain and today it is harmless; it is still the one thing the firmware
contract says must never happen. Fix is to set the level before the
direction. Not applied.

### v1.0 unit A — Stage 2 passed 2026-10-05, 15:34, direct LATCH-GPIO power-up, after a firmware fix

`C1208` refitted with a genuine 4.7 µF and `C1501` removed (Peter), 36 V on,
everything cabled but the RJ-45. `TMC5130Communication` on
`mouse_joystick_rev2`, Digital-50 taps CH1/8–11/14/24/26/27/30/31 at 10 MSa/s
(`mouse-joystick-firm/evidence/2026-10-05-1142-board4-regression/v1/v1a_s2_tmc.sr`, `v1a_s2b_tmc.sr`).

**First attempt, firmware `ec3b36d`: the rail came up and the firmware then
armed latch-off too early.** The tap timeline of the failed `s`: `HV_EN` high
for 116 ms; **`PG_5V` up at +6.6 ms, `PG_12V` at +10.9 ms** — the bucks run
from a few volts of `+36V_SW`, so `+3.3V_SW` read live while the switch was
still charging 208 µF in current limit; `powerUp()` saw the rail up, waited
10 ms and drove `HV_LATCH` high; `PG_12V` fell at +36.7 ms and `PG_5V` at
+59.6 ms (the switch tripped on the remaining inrush with latch-off armed and
stayed off); the fault check at +114 ms read `~{HV_FAULT}` low. The `m`
measurement a few seconds later, same code, survived by timing luck: rail
held 3.15 s, no fault, **51.3 mA** of 36 V input current with the bus open.
The LATCH probe's first half (LATCH driven high on purpose) failed as
designed: came up, held 13 ms, peak 3.293 V, fault latched, started cold.
`p` then also collapsed because `powerDown()` left LATCH high after the probe;
its table shows `HV_SNS` at the ISNSFLT level (1.65 V) throughout the charge.

**Fix (firmware, `PowerSequence`):** with LATCH on a GPIO, keep it low until
`HV_SNS` has read below the fault level for 20 ms running (the bulk is charged
when the switch leaves current limit), then arm latch-off; give up after 1 s
and report a short; `powerDown()` returns LATCH to low; the report carries
`charge_ms`. **Two passes after the fix, both clean:**

| Quantity | run 1 | run 2 |
| --- | --- | --- |
| method | LATCH held low, direct `HV_EN` | same |
| `+3.3V_SW` up | 4 ms, peak 3.2927 V | 3 ms, peak 3.2927 V |
| bulk charged, latch-off armed | **34 ms** | **33 ms** |
| `PG_5V` / `PG_12V` after `HV_EN` (tap) | +6.4 / +8.4 ms, never fell | +6.0 / +8.3 ms, never fell |
| `~{HV_FAULT}` (tap, DIAG_EN high) | one low edge at +4.2 ms during the inrush retry, then high | one at +3.1 ms |
| `HV_SNS` right after power-up / later | 0.0395 V = 126.9 mA (charging tail) / 0.0193 V floor | 0.0193 V floor |
| bus closed (`~{BUS_SW_EN}` low, tap) | +140 ms | +139 ms |
| `IOIN` | 0x1100001C: `VERSION` 0x11, `DRV_ENN` 1, `SD_MODE` 0, `REFL_STEP` 0, `ENCA` 1, `ENCB` 1 | same |
| `GSTAT` / `CHOPCONF` / `DRV_STATUS` / `XACTUAL` / `X_ENC` | 0x1 then 0 / 0 (`vsense` 0 at reset) / 0x80000000 / 0 / 0 | same |
| register checks | 5, 0 failed | 5, 0 failed; `r` re-read 5, 0 failed |
| `m` from a cold rail | | **43.6 mA** idle, rail live |

So on v1.0 the staircase is retired: a plain `HV_EN` with LATCH low gets
through the inrush by the part's own retry, and latch-off is armed 33 ms
later. `~{BUS_SW_EN}` also shows the 34 µs boot glitch at every
`disconnectBus()` call (the `driveOutput()` order, above).

### v1.0 unit A — Stage A3, the angle DAC over I2C, 2026-10-05, 15:38

`AngleOutput` on `mouse_joystick_rev2`, I2C taps `DIG22`/`DIG23` on CH22/CH23 at
10 MSa/s (`mouse-joystick-firm/evidence/2026-10-05-1142-board4-regression/v1/v1a_a3_dac.sr`).
Rail up in 3 ms (direct method), bus closed, I2C0 on GP17/GP16 to **0x48**.
Every transaction ACKed on the tap: soft reset (`0x05` ← 0x000A), `CONFIG`
(`0x03` ← 0x0000), **`GAIN` (`0x04` ← 0x0101)**, `SYNC` (`0x02` ← 0x0000), then
`GAIN` read back **0x0101, matched** — the first time this board family could
verify its DAC gain — and **`DEVID` 0x115**, `REF-ALARM` clear, twice. Codes
0x8000, 0xFFFF and 0 were commanded (0.825, 1.650, 0 V expected at the BNC
after the v1.0 ÷2). 13 writes and 5 reads to 0x48 in the capture, no NACK
except the terminal one of each read.

**15:49, measured at the BNC node through `ANGLE_OUT_MON` (GP29, 16-sample
average), after adding the readback to `AngleOutput` and setting I2C to
400 kHz** (`v1/a3b_angleoutput_rev2_boardA.log`). The RP2040 ADC against its
3.3 V supply is the reference here, so ±1 % is the instrument, not the board;
a meter on the BNC is still owed for the fit.

| DAC code | expected at the BNC | `ANGLE_OUT_MON` | difference |
| --- | --- | --- | --- |
| 0 | 0 V (floor) | **0.0121–0.0129 V** (15.3–15.7 counts) | the v1.0 output floor, ~12 mV after the ÷2 (v0.3 measured 4.5 mV before it) |
| 497 (25 mV at the DAC) | 0.0125 V | 0.0226 V | floor plus the step |
| 0x8000 | 0.8250 V | **0.8236 V** (1021.9 counts) | −1.4 mV, −0.17 % |
| 0xFFFF | 1.6500 V | **1.6415 V** (2036.8 counts) | −8.5 mV, −0.5 % |

`DEVID` 0x115 and `REF-ALARM` clear again after the sweep. The 12 mV floor
means the out-of-band "unhomed" level needs the same thought as on v0.3
(code 497 reads 22.6 mV here, only 10 mV above the floor).

### v1.0 unit A — Stage A6 (stage 3 on v1.0) passed 2026-10-05, 15:41, replacement joystick unit

`MotionAndHoming` on `mouse_joystick_rev2`, taps CH1/14/15/24/26/28/29 at
1 MSa/s (`mouse-joystick-firm/evidence/2026-10-05-1142-board4-regression/v1/v1a_a6_motion.sr`).
`b`: rail up 3 ms (direct method), bulk charged 34 ms, TMC5130A 0x11, `uv_cp`
0, encoder scaled, DAC over I2C at 0x48 with `GAIN 0x101`. `c`: `vsense` read
back 1, IRUN 8 = 0.211 A RMS. `e`: enabled.

| Measurement | Result |
| --- | --- |
| `W` switch found from where it rested | engaged at 6271 µsteps (44.09°), released 6015, throw 256, active high |
| `g` out −1280 / back +1280 | encoder −1203 / +1100 (0.9398 / 0.8594), residual −103 µsteps (−8.0 counts) |
| `h` approach 0.200 rev/s, creep 0.010 | stopped by the switch (328 → 397, 1.21), closing 6343, release edge 5978, closing-to-release 365 µsteps, 1454 ms |
| `H` 5 runs | **5 of 5, spread 25 µsteps = 2.0 counts (0.176°)** |
| reversal dead band (IRUN 8) | continuing jogs 1.0102 / 1.0000 / 1.0195; every reversal **1191 of 1280 (0.9305), 89 µsteps = 7 counts**; `g` residual −102 µsteps |
| second `h` from 4667 µsteps away | approach follow 0.9927, closing-to-release 702 µsteps, 2784 ms |
| `L` live encoder → I2C DAC | **1000.1 Hz achieved, worst loop 1082 µs of 1000** at the 100 kHz I2C default (v0.3 over SPI: 386–527 µs), code 7190 static; **732 µs worst after setting I2C to 400 kHz** (15:50, 10019 updates, 1000.1 Hz, `v1/a6b_liveloop_rev2_boardA.log`) |
| `p` after | `DRV_STATUS` 0x81020034, `ot`/`otpw` 0 |

The reversal dead band is the same 89–90 µsteps this joystick unit measured on
board 4 earlier today, so it travels with the mechanism and motor, not with the
board or the driver. Homing repeatability is unchanged at 2.0 counts. **The
live loop's worst iteration exceeded the millisecond for the first time**: the
bench consoles left `Wire` at its 100 kHz default (the QP build already ran
400 kHz), where one three-byte DAC write costs ~400 µs. At 400 kHz the worst
iteration is 732 µs, still above v0.3's SPI figure; the remaining cost is the
I2C transaction itself (~90 µs) plus the same polling as before.

### v1.0 unit A — QP protocol session on `mouse_joystick_qp_rev2_usb`, 2026-10-05, 15:51–16:05

Phases a–e of the board-4 session on the v1.0 build (protocol over USB CDC,
QS trace on `FW_TRIG1` = CH1, TICK level on `FW_TRIG0` = CH0, tick probe on
the UART0 TX pad = CH2, TMC SPI on CH8–CH11), no stops, no meter, no hand.
Files: `mouse-joystick-firm/evidence/2026-10-05-1142-board4-regression/v1/qp/`. `ID`: `hw=rev2`,
caps `motion+home+instr+hv+watch+fetch+stream+cfg+angout`. No `ASSERT` in any
trace; trace buffer never full; line pool min free 3 of 8 (rev 1 had 1).

| Phase | Result |
| --- | --- |
| b | `hv on` acked (the direct power-up inside `TmcMotion`; `DAC_STATE` 1 then 2, 5.2 ms apart), HOMED, `angscale`, `angout on`, TARGET at −7.566 / −5.766 / −3.15 for −7.59 / −5.06 / −2.53, park −0.541, `angout off`, disarm |
| c | 20 of 20 moves, ack→TARGET p50 435.1 ms; `brake 0` → RELEASED at −0.816°; `watch` with no hand: first motion at 713 ms (drift to −0.9°), `TRIAL outcome=NONE` on leaving RELEASED; FETCH 500 samples `lost=0` in 153 ms; `stream on 50` 100 lines in 2 s; host-loss FAULT after **105.7 ms**; `clrfault` |
| d | 300 of 300 moves, ack→TARGET p50 433.7 / max 473.7 ms, no naks |
| e | `hv off` → `hv=0`, `DAC_STATE 0` |

Tick cost on v1.0 (`SAMPLE_STAT`, p50 last / p50 worst-per-second, µs):
holding with the angle output on **305 / 357** (rev 1 on v0.3: 158 / 379 — the
I2C DAC write at 400 kHz replaces the SPI one); idle with it off **15 / 52**;
moving back to back **116 / 1081** (the command tick, one per `moveto`, as on
v0.3). TICK level on CH0 p50 106–117 µs, max 1.46–1.75 ms; tick period
1000.0 µs, none missed; 92–96 back-to-back levels per 90 s. TMC SPI 3.33 MHz,
2 datagrams per tick p50, 10 p99. Ping round trip over USB CDC p50 3.1–3.4 ms.

**Rev 2 is now exercised end to end on hardware**: stages 1, 2, A3, A6 and the
QP protocol build, all on unit A; A4 and A5 followed on 2026-10-06 (next
section). Still owed on v1.0: a meter fit of the angle output, the UART0 path
with a pyboard (Gate E), the brake and torque paths in the protocol build, and
unit B.

### v1.0 unit A — Stages A4 and A5, brake sink and torque bridge, 2026-10-06, 08:48–08:55

Bench as left on 2026-10-05: replacement joystick, motor, encoder, limit
switch, brake and torque sensor cabled, 36 V supply on, RJ-45 unplugged,
Digital-50 to the LA5032 through the v2.0 adapter (straight, `CHn` = `DIGn`).
Firmware: the new `examples/BrakeAndTorque` on `mouse_joystick_rev2`
(`mouse-joystick-firm` HEAD `80fdf3b` plus that day's uncommitted ADS8689
driver, console and `SafeState` fix). Driven non-interactively by
`mouse-joystick-firm/evidence/bench-scripts/unitA_brake_torque.sh` and
`unitA_brake_steps.sh`; console transcripts and captures in
`mouse-joystick-firm/evidence/2026-10-06-0848-unitA-brake-torque/` and
`…-0853-unitA-brake-steps/`. **The motor driver was never enabled.** No meter:
every brake number is the RP2040's ADC against its 3.3 V supply (0.806 mV =
39 µA of coil current per count through the 20.625 V/A monitor) and every
torque number the ADS8689's own 4.096 V reference (78.125 µV per code on the
0–5.12 V range). The design values compared against are in
`mouse-joystick-firm/src/Conversions.hpp` (from `kicad-libs`
`docs/brake-current-sink-design.md` and `docs/torque-sensor-interface-design.md`).

**Bring-up (`b`).** Rail up in 4 ms, peak 3.2895 V, bulk charged and latch-off
armed at 36 ms; bus closed. I2C0 at 400 kHz: **0x48 ACK, 0x49 ACK** (rig plan
A1b). Brake DAC `U1801` at 0x49: soft reset, `CONFIG` 0, **`GAIN` 0x0101
written and read back 0x0101**, `SYNC` 0, **`DEVID` 0x115** (DAC80501**Z**,
zero-scale reset), `REF-ALARM` clear — decoded byte for byte from CH22/CH23
(`captures/p1_bringup.sr`). `BRAKE_ISENSE` at code 0: **0.0113 V**
(14.0–14.3 counts), the monitor amplifier's floor (design ~12.5 mV after the
÷2), reported as 0.55 mA-equivalent; `~{BRAKE_FAULT}` high. SPI1 at 2 MHz,
mode 0, CONVST/CS on GP15: ADS8689 `U2002` `SDI_CTL` 0, `SDO_CTL` 0,
`DATAOUT_CTL` 0, **`RANGE_SEL` 0x000B written and read back 0x000B**,
loopback `DATA_VAL` all-ones **0xFFFF**, all-zeros **0x0000**,
`DEVICE_ID[15:0]` 0x0010 (datasheet: reserved, reads 0), `RST_PWRCTL` 0 —
decoded from CH16–CH19 as 32-bit words (`D0080000`, `D00C0000`, `D0100000`,
`D014000B`, `C8140000` → `000B0000`, `D0100005` → `FFFF0000`, …). The
conversion results shifted out *during* the configuration writes, before
`RANGE_SEL` took effect, were 0x909E–0x90B2 (37022–37042): in the reset
±12.288 V range (375 µV per code, 0 V at 0x8000) that is 1.595–1.603 V, the
same node the 0–5.12 V range then read at 1.5956 V, so the two ranges agree and
the datasheet's straight-binary coding of the bipolar ranges is confirmed on
the wire.

**A4, brake sweep** (`s`: every point approached from code 0, 100 ms settle,
64-sample average; `captures/p2_brake.sr` at 1 MSa/s):

| % | code | commanded | `BRAKE_ISENSE` | measured | error, % of FS |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 0 | 0.000 mA | 0.0113 V | 0.547 mA | +1.12 (the floor) |
| 10 | 6553 | 4.878 mA | 0.1096 V | 5.314 mA | +0.89 |
| 20 | 13107 | 9.756 mA | 0.2087 V | 10.120 mA | +0.75 |
| 30 | 19660 | 14.634 mA | 0.3103 V | 15.043 mA | +0.84 |
| 40 | 26214 | 19.512 mA | 0.4102 V | 19.888 mA | +0.77 |
| 50 | 32767 | 24.390 mA | 0.5029 V | 24.381 mA | −0.02 |
| 60 | 39321 | 29.268 mA | 0.6036 V | 29.265 mA | −0.01 |
| 70 | 45874 | 34.145 mA | 0.7035 V | 34.110 mA | −0.07 |
| 80 | 52428 | 39.024 mA | 0.8042 V | 38.994 mA | −0.06 |
| 90 | 58981 | 43.901 mA | 0.9050 V | 43.878 mA | −0.05 |
| 100 | 65535 | 48.780 mA | **1.0065 V** | **48.801 mA** | +0.04 |

**Full scale reads 1.0065 V against the 1.006 V design**: the pass device
reaches 48.78 mA and the 12 V gate drive is sufficient (firmware contract
item 7). Above 50 % the chain is within ±0.07 % of full scale; below it the
monitor floor adds its ~0.4–0.5 mA-equivalent to every reading, which is the
floor and not coil current (the RP2040 ADC's own ~1 % is on top of all of it).
`~{BRAKE_FAULT}` was never low: in the console and on CH21 for the whole
sweep and every step below.

**Brake step response** (`S`: 0 → code → 0, `BRAKE_ISENSE` at 5 kHz for 25 ms
each way; `FW_TRIG1` on CH1 marks each step, 125.5 ms wide;
`…-0853-unitA-brake-steps/consoles/p1_steps.log`):

| target | rise t10 / t50 / t90 | peak | overshoot | fall t10 / t50 / t90 |
| --- | --- | --- | ---: | --- |
| 48.78 mA (100 %) | 1.4 / 3.0 / 6.0 ms (one of three runs 4.0 / 5.6 / 8.6 — a 3 ms late start, see below) | **61.5–62.1 mA** at 11.8–14.4 ms | **+26–27 %** | 0.4 / 1.2 / 3.0 ms |
| 43.90 mA (90 %) | 1.4 / 2.8 / 5.2 ms | 55.2 mA at 9.0 ms | +26 % | 0.4 / 1.2 / 3.2 ms |
| 36.59 mA (75 %) | 1.6 / 2.8 / 4.4 ms | 42.1 mA at 6.0 ms | +15 % | 0.4 / 1.2 / 3.4 ms |
| 29.27 mA (60 %) | 1.8 / 2.8 / 4.2 ms | 29.7 mA | +1 % | 0.4 / 1.2 / 3.6 ms |
| 24.39 mA (50 %) | 2.0 / 3.0 / 4.6 ms | 24.6 mA | +1 % | 0.6 / 1.4 / 3.8 ms |

The first millisecond of every rise slews at 8–14 mA/ms regardless of the
target: the coil's inductance against the pass device's drain headroom sets
it (at full scale 36 V − 22.8 V ≈ 13 V across the coil's `L di/dt`, which
puts the B5Z's unspecified inductance near 1–1.5 H). The command filter
reaches 90 % in about 2 ms, so above ~60 % the current cannot follow it, the
loop integrator winds up, and the current **overshoots** — by 27 % at full
scale, for about 5 ms above the setpoint, settling by 16–17 ms. The
full-scale peak, 62 mA = 1.28 V at `BRAKE_ISENSE`, is above the **56.4 mA
ceiling**, yet **`~{BRAKE_FAULT}` stayed high** at 5 kHz in the console and on
CH21 at 1 MSa/s. One of three things is true: the ceiling amplifier's
integrator is slower than the excursion; it limits but `LIMIT_OUT` does not
fall below the `SN74LVC2G17`'s threshold while the gate sits near the FET's
threshold; or the monitor path overshoots and the coil current does not. A
scope on `V_SENSE` (top of `R1816`) and on `LIMIT_OUT` during a full-scale
step settles it — **owed, needs a hand and a scope**. The firmware
consequence is independent of which: **`BRAKE` must ramp the setpoint over at
least ~6 ms (or stage it below 60 % first) rather than step it**, or the brake
applies up to 127 % of the commanded torque for ~5 ms at every release.
Falls are clean: 48.8 → 1.4 mA in 8 ms, then a 15 ms tail from 1.4 to 0.6 mA
that is the monitor floor settling, not current. The one late-starting
full-scale rise (3 ms at 0.5 mA before moving) was the first step after `b`
in that session and did not recur; unexplained, noted.

**A5, torque bridge.** At rest, the joystick where the 2026-10-05 session left
it: **20424–20448 codes = 1.5956–1.5975 V at `AMP_VOUT`**, 0.798–0.799 V at
the BNC, i.e. **69–71 mV below the ideal 1.6667 V zero** — −0.255 N·cm on the
nominal 0.2715 V/N·cm scale. That is 7× the sensor's ±1 % R.O. zero balance
(±9.6 mV at `AMP_VOUT`), so it includes the mechanism's rest torque through
the coupling (the joystick against its stop) and the front end's own
offsets; separating them needs the joystick freed by hand, or a meter on
`VEXC` and `VMID`. **Noise: sd 1.22–1.43 codes = 95–112 µV rms at `AMP_VOUT`
= 0.35–0.41 mN·cm rms**, span 8–11 codes over 1000 and 10000 samples at
1 kHz — the ADS8689's own LSB dominates, and it is 10× below the lightest
training load (1 gf ≈ 21 mV at the BNC = 540 codes). **Shunt calibration
(`k`, `TQ_CAL_EN` low / high / low, 500 samples each; CH20 shows the 549 ms
high): step 0.0 codes = 0.00 mV against a design step of 0.744 V (9522
codes). The calibration switch does nothing on the as-built v1.0**, as the
2026-10-04 design review predicted: the N-channel enhancement MOSFET's source
sits at ~5 V (`SIG_N`) against a 3.3 V gate. Board finding, filed in
`.agents/PLANS.md`; the firmware's `TQ cal` verb stays, and a calibration is
not a measurement until the switch is fixed. `ALARM` read **0x0041** the first
time (`OVW_ALARM` + `TRP_VDD_H_FLAG`, a tripped high-AVDD flag from the
`+5V_FILT` ramp) and **0x0000** the second: the tripped flags clear on read,
no active alarm. The other registers sat at their reset values with
`RANGE_SEL` 0x000B.

**Live loop (`L 10`)**: 10000 ticks in 9999 ms = **1000.1 Hz**, one ADS8689
conversion (CONVST pulse, 6 µs wait, one 32-bit NOP frame at 2 MHz: ~22 µs)
and one `BRAKE_ISENSE` read per tick, **worst iteration 295 µs**, 0 overruns,
torque mean within 1 code of the tare. **Coupling (`X`)**: torque mean with
the brake at 0 / 24.38 / 48.80 / 0 mA = 20446.4 / 20447.7 / 20446.6 /
20446.4 codes: **1.3 codes (0.1 mV, 0.4 mN·cm) between the extremes**, inside
the sd. No brake-current-to-torque coupling at the 0.1 mV level, electrical or
mechanical, with the joystick untouched.

**The `~{BUS_SW_EN}` boot glitch is fixed.** With `SafeState::driveOutput()`
writing the level before the direction (SDK calls, no `gpio_init()`), CH27
showed **no transition at all across a warm reboot** (`…-0853-…/captures/
p0_reboot.sr`, 10 MSa/s; the boot signature on CH1 10.139 / 10.010 /
10.008 ms and CH0 8 × 1.01 ms places the boot at 2.54–2.62 s of the capture),
where 2026-10-05 saw a 34 µs low at every boot and every `disconnectBus()`.
Power-down (`x`): `~{BUS_SW_EN}` high at 39750.049 ms and `HV_EN` low at
39750.088 ms — the bus opened 39 µs before the rail dropped, the ordering the
power sequence requires.

### v1.0 unit A — brake and torque in the protocol build, 2026-10-06, 09:20–09:35

`examples/PyControlLinkQp` on `mouse_joystick_qp_rev2_usb` with the day's
protocol work: `caps` gains `brake` and `torque`, `BRAKE` ramps the brake
DAC and releases the drive once the coil current has settled, `TQ` answers,
torque rides in every field. Driven by
`qp-arduino-example/tools/brake_torque_steps.py` (new) over USB CDC with a
40 ms heartbeat; Digital-50 CH0/CH1 and CH16–CH27 at 10 MSa/s. Three runs:
`mouse-joystick-firm/evidence/2026-10-06-0920-…` (the host script's
heartbeat starved itself and the board faulted `host_timeout` 100 ms after the
last ping, correctly), `…-0925-…` and `…-0931-…` (complete). Numbers below are
the 0931 run unless said; the 0925 run agrees within a few percent.

| Step | Result |
| --- | --- |
| `id` | `caps=motion+home+instr+hv+watch+fetch+stream+cfg+angout+brake+torque`, `hw=rev2` |
| `hv on` | ack 181 ms (host round trip); the switched-domain peripherals then came up one tick each: `DAC_STATE` 1 (angle DAC reset) at +173 ms after the command, 2 at +4.4 ms, **3 (brake DAC reset) +1.0 ms, 4 (brake DAC `GAIN` 0x0101 read back) +3.7 ms, 5 (ADS8689 range read back, loopback) +3.4 ms** |
| torque before/after the tare | `torque=-0.301` on the nominal zero (as the bench console read, −0.26 to −0.31 N·cm); `tq get` → `torque=-0.301;raw=-0.301;cal=0`; after `tq zero` → `torque=-0.001;raw=-0.302`; `tq cal;on` → `cal=1`, reading unchanged (the inert switch) |
| `brake 1.0` | ack; **`ev;RELEASED` 11.6 ms after the command reached the board** (`LINK_RX` → the event's `t`: 9119149 → 9130786 µs; 10.7 and 12.4 ms in the other runs) = the 8 ms-to-full-scale ramp (18809 codes, three 1 ms steps) plus the 6 ms settle; `RELEASED` carried `torque=0.051;brake=1.0` |
| `brake 3.4` | **`RELEASED` 15.1–16.7 ms** after arrival (63950 codes, eight steps, plus the settle); `brake=3.4` in `STATUS` while held |
| the held joystick | `STATUS` in `RELEASED` at the two levels: angle 0.267 → 0.267 (1.0 N·cm) and 0.176 → 0.176 (3.4 N·cm) over 300 ms, torque −0.03 to +0.02 N·cm; after `stop` the drive re-engaged first, then the brake off: `state=ARMED;brake=0.0`, angle resynced |
| `watch` without a hand | `pull=5;push=5;timeout=3000;touch=0.3` → **`ev;NOMOVE` 3000.1 ms after the command**, no `TOUCH` (torque stayed within ±0.08 N·cm), `ev;TRIAL` exactly 1 s later with `tq_peak=-0.075;tq_out=-0.028;a_peak=0.0` |
| `fetch;0;4` | `n=4;k0=0;t0=13132801;dt_us=1000;pre=500;lost=0`, lines `cap;k;0.176;-0.028` — the torque in the capture's third field |
| `moveto 0.0`, `disarm`, `hv off` | `TARGET`, then `HOMED`, `hv=0`, `torque=0.0` with the rail down (the dying bridge's last sample is discarded, fixed between the 0920 and 0925 runs), `faults=0` — no spurious range fault from the collapse |
| trace | no `ASSERT`; `BRAKE_STATE` records at each engage, release and brake-off |

**The brake DAC writes on the I2C tap (0925 run, CH22/CH23)** show the ramp
with coarse steps: for 1.0 N·cm a single write of 18809, for 3.4 N·cm three
writes 25550 → 53541 → 63950 at 3.0 and 2.0 ms intervals, instead of eight
1 ms steps. The ramp is slew-limited per unit time (6.1 mA/ms), so a late
poll takes a proportionally larger step; the polls were late because the
**1 kHz sampler was in its decimated mode the whole time the rail was up**
(`SAMPLE_STAT` `last` 1.2 ms in `RELEASED` with a `WATCH` armed, 0.26–1.1 ms
otherwise, `max` 2.1–2.5 ms every second, `decimated=1`). Yesterday's run of
the same build without the brake and torque paths was already decimated with
the rail up (`last` 110–750 µs, `max` 0.9–1.5 ms), so this is the standing
tick-budget problem with ~50 µs more per poll on top (the console's `M`
measured the ADS8689 sample at 37 µs, `BRAKE_ISENSE` at 4.8 µs, a DAC write
at 110 µs); the first suspicion, `delayMicroseconds()` in the ADS8689
transport, was changed to a busy wait and made no difference (0925 → 0931).
A `POLL_STAT` trace record (per-backend poll cost, per primitive; run
`…-0942-unitA-qp-brake-torque/`) then showed **every bus primitive inflated
to 100–500 µs maxima with the rail up** — the TMC X_ENC read, the
five-register snapshot, the ADS8689 sample and even the 5 µs `BRAKE_ISENSE`
`analogRead` (110–230 µs) — which is interrupt time landing inside the
transactions, not the transactions themselves; the bench build's USB CDC
protocol port (serviced at interrupt level by the Arduino core) is the
suspect, and the budget is to be judged on the UART0 delivery build. The
finding and its follow-up live in the firmware plan. Even in that state
every protocol step above behaved as specified, and the ramp's largest single
step (19 mA) is below the ~60 % of full scale where the coil was seen to
overshoot.

### v1.0 unit A — first contact over the RJ-45 and the delivery build's tick budget, 2026-10-06, 09:59–10:05

Peter plugged the Breakout 1.2 into the board's RJ-45 and the pyboard into
USB (PYBV11, MicroPython 1.26.1, serial `397734803233`, pyControl framework
on its flash). The board runs `examples/PyControlLinkQp` on
**`mouse_joystick_qp_rev2`**, the delivery build: protocol on UART0, QS trace
on `FW_TRIG1`, USB CDC only a banner. Driven from the pyboard's REPL with
`machine.UART` directly (`tools/pyboard_repl.py`), as on 2026-09-03: first
contact should not have the framework as a second unknown. Digital-50
CH0–CH3, CH24, CH27 at 10 MSa/s. Evidence
`mouse-joystick-firm/evidence/2026-10-06-0959-unitA-uart0-first-contact/`
and `…-1001-unitA-uart0-protocol/`.

**Which port.** `id` on `UART(4)` (port 1) and `UART(1)` (port 3): nothing.
On **`UART(3)` = Breakout 1.2 port 4**: `ack;2;hw=rev2;serial=E4654C159F274534;
fw=9b6d2ef;proto=2;axes=1;caps=motion+home+instr+hv+watch+fetch+stream+cfg+angout+brake+torque;rxbuf=200;boot=reboot;crumb=0`.
Port 4 is the RIGHT joystick's port in `mouse_joystick_bringup.py`, which is
the joystick unit A drives. The same bytes decoded on the taps: `id;2` on CH3
(`PYC_UART_RX`) and the 170-character reply on CH2 (`PYC_UART_TX`), so the
adapter's CH2 is verified for the first time and the UART wiring and polarity
on v1.0 are as on rev 0 (`R401` 10 kΩ holds RX idle high; `DIO-A` → RX,
TX → `DIO-B`).

**The protocol over the real link, 36 V on** (`…-1001-…/repl/protocol_session.txt`):

| Step | Over UART0 |
| --- | --- |
| `status` cold | `state=IDLE;…;torque=0.0;brake=0.0;hv=0` |
| `hv on` | `ack`; then `torque=-0.262` live, `tq get` −0.261, `tq zero`, `tq get` → `torque=0.001;raw=-0.26` |
| `home` | `HOMED` within the 3 s read window |
| `arm`, `brake 1.0` | `ev;RELEASED;…;angle=0.084;torque=0.016;brake=1.0`; `STATUS` in `RELEASED` with `brake=1.0` under 60 ms pings |
| `watch pull=5;push=5;timeout=1500;touch=0.3` | `ev;NOMOVE` 1500.0 ms after the command (205679784 − 204179… µs), `ev;TRIAL` exactly 1 s later with `tq_peak=-0.009;tq_out=-0.007;a_peak=0.183` |
| `fetch;0;3` | `n=3;…;pre=500;lost=0`, three `cap;k;0.267;-0.007` lines, `cap;end` |
| then | **`ev;FAULT;…;code=0;detail=host_timeout`**: the REPL script waited 150 ms on the fetch with no command in between — the host's fault, and the board did what the spec says: `hv=0`, `brake=0.0`, `FAULTED`, `brake;68;3.4` → `nak;faulted`, pings still answered, `clrfault` afterwards → `IDLE` |

**The tick budget on the delivery build** (`SAMPLE_STAT`/`POLL_STAT` from the
trace, compare the USB bench build earlier today):

| State | USB bench build | UART0 delivery build |
| --- | --- | --- |
| rail down, idle: last tick | 35–60 µs | 50–79 µs |
| rail up, `ARMED`/`HOMED`: last / max | 260–1080 / 2100–2500 µs | **273–344 / 533–795 µs** |
| rail up, `RELEASED` + `WATCH`: last / max | 1170–2260 / 2160–3410 µs | **1167–1440 / 2264–3414 µs** |
| worst X_ENC read / five-register snapshot | 350–555 / 400–670 µs | **161–167 / 308–317 µs** |
| worst ADS8689 sample / `BRAKE_ISENSE` read | 230–480 / 110–230 µs | **103–107 / 57–137 µs** |
| decimated from `hv on` to `hv off` | yes | yes |

So the USB protocol port was inflating every primitive two- to fourfold (its
servicing runs at interrupt level in the Arduino core), and over UART0 the
primitives sit at 3× their bench-console cost (interrupt time from the tick
alarm, the UART and the trace's PIO ISR). What is left is structural and the
same on both builds: `ProtocolBoard` polls both hardware backends at every
scheduler stop, the classifier's 1 kHz ring adds one stop per millisecond in
`RELEASED`, and the sampler's decimated mode — entered during the `hv on`
transient (one 3.9 ms tick plus the four peripheral phases) — is only left
when the rail goes down, so a decimated tick covers 2 ms of ring stops: three
polls of ~300 µs each is the 1.2 ms. Both are firmware fixes (a once-per-tick
rate limit on the hardware polls; hysteresis on the decimation) and are in
the firmware plan.

### v1.0 unit A — Gate E through pyControl, and the tick budget after the poll fixes, 2026-10-06, 10:17–10:45

The Breakout 1.2 on the RJ-45, the pyboard on USB, 36 V on; pyControl 2.1.1
running the bring-up task `mouse_joystick_check` on the pyboard
(`mouse-joystick-firm/tools/pycontrol_run.py`, the GUI's `Pycboard` path).
Three runs of the same 50 s task against three builds of
`mouse_joystick_qp_rev2`, each under a Digital-50 capture (CH0–CH3, CH24,
CH27 at 10 MSa/s) with the QS trace decoded. Evidence
`mouse-joystick-firm/evidence/2026-10-06-1019-unitA-gate-e/`, `-1037-`,
`-1043-`. The pyControl side is in "pyControl Integration" below; this
section is the board's tick.

**The sequence, from the board's clock (run 1043, booted 30 s earlier):**
`hv on` acked in 185 ms; `home` → `HOMED` 836 ms; `arm` → `ARMED` 23 ms;
`moveto -5` → `TARGET` 338 ms at −5.041°; `brake 1.0` → `RELEASED` 12 ms
(the ramp and the 6 ms settle); `watch` 17 ms later; `TOUCH` 20 ms after
`RELEASED` at −0.349 N·cm (the rest offset, nobody touching); `NOMOVE` at
the 10 s timeout; `TRIAL` 1.000 s after; park → `TARGET` 338 ms at −0.991°;
`stop`, `disarm`, `hv off` from the task's `run_end`. Identical in all three
runs to the millisecond, and to run 1019's (rail already up from the
crashed run before it, so `hv on` acked in 6 ms there).

**The tick, three builds** (`SAMPLE_STAT`/`POLL_STAT` per second; `last` is
a typical handled tick, `max` the worst in that second; the sampler was
decimated — every other tick — from `hv on` to `hv off` in every run):

| Build (hardware-poll rate limit) | `RELEASED`+`WATCH`, 10 s: bus polls/s | handled ticks/s | overrun skips/s | coalesced/s | handler last / max | `ARMED` idle: last / max |
| --- | --- | --- | --- | --- | --- | --- |
| 1019: once per 500 µs of **protocol** time | 1000 | ≈380 | ≈310 | ≈65 | 1050–1750 / 2100–2450 µs | 284–625 / 785–898 µs |
| 1037: once per 500 µs of **wall-clock** time | 720–734 | ≈400 | ≈145 | ≈55 | 600–1460 / 1800–2800 µs | 310–630 / 760–960 µs |
| 1043: **once per advance** of the protocol clock, plus the 500 µs guard | **487–489** | ≈488 | **≈30** | ≈40 | **550–1040 / 1150–1270 µs** | 290–670 / 820–950 µs |

Why three tries: `ProtocolBoard::advance()` services once per scheduled
stop, and in `RELEASED` the classifier's ring schedules a stop every
millisecond, so one late tick runs two or three services. Keyed to the
protocol clock the limit let every one of them read the bus (the stops are
1 ms apart on that clock). Keyed to the wall clock it still let the second
one through whenever the first poll had itself taken longer than 500 µs —
which, with the primitives inflated as below, it had. One read per advance
(`MotionBackend::beginAdvance()`) is what the design meant.

**What one poll costs on this board, in the link build, rail up** (worst
per second; the bench console measured the same primitives without the QP
link at 2026-10-06 09:00: X_ENC read ≈ 70 µs, five-register snapshot
≈ 340 µs, ADS8689 sample 37 µs, `BRAKE_ISENSE` `analogRead` 4.8 µs, DAC
write 110 µs):

| Primitive | `RELEASED`+`WATCH` (run 1043) | `ARMED` idle (run 1043) |
| --- | --- | --- |
| X_ENC read (2 datagrams, 4 MHz) | 240–345 µs | 277–308 µs |
| five-register snapshot (10 datagrams, every 10th poll) | 400–566 µs | 375–495 µs |
| motion poll (one of the two above plus the ramp logic) | 430–600 µs | 407–529 µs |
| ADS8689 sample (CONVST, wait, one 32-bit frame) | 150–270 µs | 160–263 µs |
| `BRAKE_ISENSE` `analogRead` | 105–200 µs | 70–160 µs |
| brake/torque poll | 220–400 µs | 230–330 µs |
| handled tick, rail down (no bus) | — | 57–73 µs (max 144–319) |

Every primitive is 2–4× its console cost, the 5 µs `analogRead` 20–40×:
the inflation is time stolen from inside the transactions, not the
transactions. The candidates are interrupt time (the 1 kHz tick alarm with
its QS records, UART0 RX/TX for the host lines, the trace's PIO UART ISR,
TinyUSB's housekeeping with the CDC enumerated) and XIP cache misses on a
code path that is much larger in the link build than in the console. Not
attributed yet; the firmware plan has the experiments. As it stands the
sampler holds **500 Hz in `RELEASED` with ~6 % of its ticks lost** (skips
plus coalesced), and 1 kHz is not reached with the rail up. The angle DAC
write is now skipped when the value is unchanged (−110 µs on a resting
tick), which did not move the typical `ARMED` tick: the inflation
dominates.

**Two observations for the rig, both runs:** (1) the torque reading at rest
after `RELEASED` is −0.2 to −0.35 N·cm (the third A4/A5 finding), so a
`watch` with `touch=0.3` reports `TOUCH` 20 ms after release with nobody
there — `tq zero` before the trial, or a higher touch level; (2) parking at
0° after the trial ends with the encoder at −0.991° and the driver
satisfied, in all three runs — the lost degree is on the reversal from the
−5° presentation, so coupling backlash, and a home before a trial whose
park position matters.

### v1.0 unit A — the tick budget attributed on the bus and on the pin, 2026-10-06, 11:04–11:45

Peter's call after Gate E: the sampler should hold 1 kHz with the rail up if
bugs are what stop it. Measured with the LA5032 on the Digital-50 taps rather
than with the firmware's own clock, so the numbers below are what the bus
and the pin did, not what the stalled CPU thought.

**The TMC5130 SPI bus** (CH8 `TMC_SPI_SCK`, CH9 `~{TMC_CS}`, CH10 COPI, CH11
CIPO at 50 MSa/s, 1 s in the task's `ARMED` idle; evidence
`mouse-joystick-firm/evidence/2026-10-06-1104-unitA-tmc-spi-timing/`):

| TMC51X0 library | per datagram (CS low) | between datagrams | X_ENC read (2 datagrams) | snapshot | polls/s |
| --- | --- | --- | --- | --- | --- |
| 4.1.0: five `transfer(byte)` calls, two datagrams per register | 17.1 µs (40 clocks at 3.85 MHz in 14.8 µs: four 1.5 µs byte gaps) | 11.6 µs | **60 µs** | 10 datagrams, **269 µs** | 511 (decimated) |
| working copy: in-place `transfer(buf, 5)` (still a byte loop on this core), pipelined `readMany` | 17.3 µs | 3.5 µs | 38 µs | 6 datagrams, 167 µs | 513 |
| working copy: two-buffer `transfer(tx, rx, 5)` (one SDK call, clocks back to back) | **12.0 µs** (9.8 µs of clocks, no gaps) | 3.2 µs | **27 µs** | **134 µs** | 515 |
| the same, trace off (`instr off`) | 17.3 | 3.5 | 38 | 166 | 515 |
| the same, host heartbeat 2.5/s instead of 25/s (`cfg wdt_ms=500`) | 17.3 | 3.5 | 38 | 144 | **1004 — the sampler at 1 kHz** |

The SCK is 3.85 MHz (the 4 MHz request through the PL022 divider), CS lead
and trail 1.2 and 1.0 µs. The 4.1.0 library's datagrams were also stretched
on the bus itself (CS low p90 31.6 µs against a 17.1 µs median, one at
201 µs): the CPU stalled mid-datagram between the byte transfers. With the
single buffer transfer the p90 equals the median; the rare long stall
remains (max 96–142 µs, one or two per second).

**What the firmware thinks the same operations cost** (`POLL_STAT` maxima
per second, rail up): X_ENC read 240–430 µs, snapshot 400–570 µs, ADS8689
sample 150–270 µs, `BRAKE_ISENSE` `analogRead` 100–200 µs — 2–8× the bus,
and **unchanged by the 37 % bus-time cut**. A `LINK_WORK` record per host
line says the same from the other side: a `ping` costs the active object
1.2–1.9 ms (advance ≈ 450 µs, parse-dispatch-reply ≈ 650 µs, queueing the
6-byte `ack` ≈ 300 µs). The trace off changes nothing; fewer host lines let
the sampler recover to 1 kHz in the `ARMED` idle but not in `RELEASED`.

**The TICK handler on the pin** (`MJ_TICK_LEVEL` build, `FW_TRIG0` high for
the whole handler, CH0–CH3 at 2 MSa/s for 30 s, 14 303 handlers; evidence
`…/2026-10-06-1132-unitA-tick-attribution/tick_level/`):

| State | handlers/s | median | p90 | max |
| --- | --- | --- | --- | --- |
| `RELEASED` + `WATCH` (first 7 s) | 440 | **758 µs** | 1090 µs | 1.5–2.3 ms |
| `ARMED` idle | 488 | **268 µs** | 465 µs | 0.7–0.9 ms |
| the tick within 3 ms after a host line (650 of 14 303) | — | 568 µs | 820 µs | 1.25 ms |
| every other tick | — | 279 µs | 764 µs | 2.27 ms |

So a host line adds ~300 µs to the tick that follows it, but at 24 lines/s
that is 5 % of the ticks; the other 95 % cost 268 µs in `ARMED` for ~70 µs
of bus work, and 758 µs in `RELEASED` for the same bus work plus the
classifier and the capture ring — a few hundred instructions. The time is
in executing code. The board runs its code from the W25Q128JVZPIQ through
the RP2040's 16 KB XIP cache, and every build so far has used the generic
single-lane 03h stage 2 (`boot2_generic_03h_4`, a command and address per
word), kept since the first article "until stage 1 passes"; the quad-lane
stage 2 matched to this flash (`boot2_w25q128jvxq_4`) was never tried on
hardware. That is the experiment that follows.

**The quad-lane stage 2** (`env:mouse_joystick_qp_rev2_fastflash`, 11:40;
the board enumerated and ran the whole task sequence first time; the QE bit
the stage 2 sets is non-volatile, so the generic stage 2 still boots the
board afterwards). The same probe, same task, same host:

| | generic 03h stage 2 | quad-lane stage 2 |
| --- | --- | --- |
| TICK handler, `RELEASED`+`WATCH`: median / p90 / max (pin) | 758 / 1090 / 1500–2300 µs | **346 / 450 / 610–760 µs** |
| TICK handler, `ARMED` idle: median / p90 / max (pin) | 268 / 465 / 700–900 µs | **146 / 235 / 310–370 µs** |
| handlers per second, `ARMED` idle (pin) | 488 (decimated) | **1000** |
| the tick after a host line vs the rest (median) | 568 vs 279 µs | 186 vs 147 µs |
| a `ping`, `LINK_WORK`: advance / feed / after (mean) | 450 / 650 / 300 µs | **183 / 236 / 94 µs** |
| `POLL_STAT` maxima: X_ENC / snapshot / ADS8689 / `analogRead` | 240–430 / 400–570 / 150–270 / 100–200 µs | **100–147 / 175–231 / 61–125 / 28–92 µs** |
| on the bus: X_ENC read / snapshot (two-buffer transfer) | 27 / 134 µs | 27 / **101 µs** (the gaps between datagrams halved too) |
| trace run (run 8, `…-1140-unitA-gate-e-fastflash/`): sampler | decimated from `hv on` to `hv off` | 1 kHz in `ARMED` (1003–1008 polls/s, max 330–370 µs); decimated in `RELEASED` only, 68 overrun skips and 45 coalesced ticks in the whole run (from ≈1900 and ≈1500) |

Everything the CPU does got two to three times faster; the bus did not
change, which is the proof that the inflation was instruction fetch. What
was left in run 8 is the budget constant: the `RELEASED` handler's p90 of
450 µs crosses the declared 400 µs three ticks in a row and decimates the
sampler for the trial; the firmware raises the budget to 700 µs (measured
headroom: the worst handler 760 µs, the idle loop keeps ≥ 240 µs of the
millisecond) and run 9 below measures the result. Evidence
`…/2026-10-06-1132-unitA-tick-attribution/tick_level_fastflash/`,
`…-1104-unitA-tmc-spi-timing/captures/after_fastflash.sr`.

**Run 9, quad-lane stage 2 and the 700 µs budget**
(`…/2026-10-06-1147-unitA-gate-e-fastflash/`, 11:47): **the sampler held
1 kHz for the whole run** — never decimated, not even through the `hv on`
transient (one 2.6 ms tick, no longer three in a row), 988–1013 bus polls
per second in `RELEASED` as in `ARMED`. Handler maxima 553–798 µs in
`RELEASED` (typical 290–460), 310–371 µs in `ARMED` (typical 140–160),
19–26 µs with the rail down. In 50 s: 79 overrun skips, 47 coalesced ticks,
almost all inside the rail-up, home and brake transients; the previous
morning's runs lost ≈1900 and ≈1500 respectively. `POLL_STAT` maxima: X_ENC
91–186 µs, snapshot 171–208, ADS8689 sample 70–132, `analogRead` 30–113. A
`ping` 485 µs of handler time. The task sequence itself is unchanged to the
millisecond (`hv on` 180 ms, `HOMED` +850 ms, `RELEASED` 12 ms after
`brake`, park 338 ms); the tare leaves the torque at +0.08 to +0.12 N·cm
with no `TOUCH`. This is the configuration the board was left in.

### v1.0 unit A — the park error measured, 2026-10-06, 14:07–14:25

Every trial today parked at 0° with the ramp generator satisfied and the
encoder at −0.99°. Peter asked whether that could be the quadrature encoder
block or the firmware. Measured with the bring-up task's `park` knob
(`mouse_joystick_check.py`; evidence
`mouse-joystick-firm/evidence/2026-10-06-1407-unitA-park-error/`), on
the delivery build:

| Probe | encoder `angle` | ramp generator `xactual` |
| --- | --- | --- |
| at `RELEASED`, 20 ms after the drive let go under the brake | −4.774 | −4.999 (the rotor relaxed 0.27° when the drive let go; the ramp generator is frozen) |
| `stop` instead of a move (re-engage, resync, brake off), 40 ms later | −4.774 | −4.774 after the resync |
| 300 ms later, brake fully off | −4.866 / −4.774 (two runs) | −4.774 |
| then `moveto 0`, 300 ms after the `stop` | **−0.991** | 0.0 |

So the release, the resync and the brake are not it: with both frames equal
and the brake off for 300 ms, the move still arrives 0.99° short. A chain of
six moves after the park, encoder at each `TARGET` (error = angle − target):

| move | direction | IRUN 8 (0.21 A RMS, the bring-up current) | IRUN 17 (0.42 A RMS, one probe build) |
| --- | --- | --- | --- |
| home → −5 | − | −0.04 | +0.05 |
| park → 0 | **+ (reversal)** | **−0.99** | **−0.63** |
| → −5 | − (reversal) | −0.22 | −0.32 |
| → −2.5 | + (reversal) | −0.83 | −0.65 |
| → 0 | + (same direction) | −0.82 | −0.63 |
| → −2.5 | − (reversal) | −0.47 | −0.29 |
| → −5 | − (same direction) | −0.40 | −0.40 |
| → 0 | + (reversal) | −0.90 | −0.63 |

The loss happens only on a change of direction (0.35–0.77° per reversal at
IRUN 8) and not at all on a move in the same direction (≤ 0.07°); it does
not grow with distance (a 2.5° reversal loses as much as a 4.8° one) and
does not accumulate. That rules out the encoder (a missed-edge or scaling
error grows with distance and is not direction-symmetric) and the firmware
(the frames agree before the move, and the ramp generator's count is what
the driver executed). It is lost motion between the electrical angle and
the joystick: at twice the run current the "after a positive move" state
became −0.633° three times out of three (from −0.82…−0.99) and the
hysteresis between directions shrank by about a third, so roughly 0.3° is
the stepper's own torque angle under the mechanism's friction at the low
bring-up current (the rotor settles short of its electrical position in the
direction it came from), and the remaining 0.3–0.6° is in the drive train
(coupling slack or torsional compliance against pivot friction) — not felt
by hand, which is consistent with a few tenths of a degree at the lever.

**What to do about it (rig plan):** the bring-up task and the rig's trial
task home before every trial for now (0.9 s). Three real fixes, any of
which the firmware can own: approach every target from the same direction
(overshoot and return, the CNC backlash convention); raise `IRUN` toward
the 0.42 A conservative figure once the thermal survey allows (it halves the
torque-angle share and makes the error repeatable); or settle on the
encoder after `TARGET` with one or two correction moves of the residual,
which removes both shares and is what an encoder is for. The last is the
one to implement; it belongs with the `TARGET` semantics in
`uart-protocol.md` (does `TARGET` mean "ramp generator arrived" or "encoder
arrived"?).

### v1.0 unit A — the encoder settle after a move (protocol V1.13), 2026-10-07, 08:07–08:12

The fix for yesterday's park error, measured. Firmware `examples/PyControlLinkQp`
on `mouse_joystick_qp_rev2` (quad-lane stage 2, TMC51X0 4.2.0, IRUN 8), working
tree `bd9bcbb`-dirty: `TmcMotion` commands each move relative to the encoder
(`XTARGET = XACTUAL + (target − X_ENC)`), waits after `position_reached` for
`X_ENC` to stand still (within one count for 10 ms, bounded at 100 ms) and
corrects a residual above one count (13 microsteps, 0.09°) with a further move,
at most twice; `TARGET` then carries the encoder's angle (`uart-protocol.md`
V1.13). The same probe chain as yesterday (`mouse_joystick_check`, `park=3`:
present −5°, brake and release, 2 s watch, park to 0°, then −5, −2.5, 0, −2.5,
−5, 0), run twice, the second with the QS trace on the LA5032 (`MOVE_SETTLE`:
the residual between encoder and target when the ramp generator first
arrived and at `TARGET`, the corrections, the time between). Evidence
`mouse-joystick-firm/evidence/2026-10-07-0807-unitA-encoder-settle/`.

**`TARGET` error (encoder angle − target), degrees:**

| move | direction | 2026-10-06, before | run 1, 08:08 | run 2, 08:11 |
| --- | --- | --- | --- | --- |
| home → −5 | − | −0.04 | +0.05 | +0.05 |
| park → 0 | + (reversal) | **−0.99** | **0.00** | **+0.08** |
| → −5 | − (reversal) | −0.22 | −0.04 | +0.05 |
| → −2.5 | + (reversal) | −0.83 | −0.02 | −0.12 |
| → 0 | + (same direction) | −0.82 | +0.18 | +0.18 |
| → −2.5 | − (reversal) | −0.47 | −0.12 | −0.02 |
| → −5 | − (same direction) | −0.40 | +0.05 | +0.05 |
| → 0 | + (reversal) | −0.90 | 0.00 | −0.09 |

Every one of sixteen moves within 0.18° (two encoder counts); eleven within one
count. Before: eight of eight short by 0.22–0.99°.

**`MOVE_SETTLE`, run 2** (residual = target − `X_ENC` in microsteps, 12.8 per
encoder count; settle = from the ramp generator's first `position_reached` to
`TARGET`; move = `OP_START` to `OP_DONE`):

| move | residual at first arrival | residual at `TARGET` | corrections | settle ms | move ms |
| --- | --- | --- | --- | --- | --- |
| home → −5 | −7 (−0.05°) | −7 | 0 | 11 | 351 |
| park → 0 | +141 (+0.99°) | −12 (−0.08°) | 1 | 177 | 515 |
| → −5 | −96 (−0.68°) | −7 | 2 | 217 | 563 |
| → −2.5 | +119 (+0.84°) | +17 (+0.12°) | 2 | 258 | 496 |
| → 0 (same direction) | −51 (−0.36°, past the target) | −25 (−0.18°) | 2 | 218 | 472 |
| → −2.5 | +4 | +4 | 0 | 10 | 263 |
| → −5 (same direction) | −19 (−0.13°) | −7 | 1 | 79 | 326 |
| → 0 | +90 (+0.63°) | +13 (+0.09°) | 1 | 149 | 485 |

Reading it:

- The reversal error is yesterday's: +141 microsteps = 0.99° on the park,
  0.63–0.84° on the probe reversals, with the ramp generator satisfied. **One
  correction removes most of it** (the park: 0.99° → 0.08° in one leg).
- **What the budget leaves is one to two counts** (−25…+17 microsteps). A
  correction of 13–25 microsteps advances the electrical angle by 5–10 % of a
  full step, a torque increment of a few per cent of the holding torque at
  IRUN 8, and that does not break the mechanism's static friction: the ramp
  generator moves, the rotor does not. The stuck correction then surfaces on
  the **next same-direction move as an overshoot** — probe 3 arrived 0.36°
  past its target after probe 2's two corrections had advanced the ramp frame
  without moving the rotor, and needed two corrections of its own. The
  mechanism is the same one the reversal shows, seen from the other side.
- **Cost.** A move without a correction gains only the 10 ms stand-still wait
  (263 ms for 2.5°, 351 ms for 5°, within the 10 ms snapshot latency of the
  old `TARGET`); a correction leg costs 70–110 ms plus its wait; **a reversal
  costs 150–260 ms more than before**. `settle_us` of 10–11 ms on the
  uncorrected moves says the encoder was already still when the ramp generator
  reported arrival: the rotor does not go on moving after `position_reached`
  at this current.
- **The settled park is at least as good as a home.** Homing repeatability was
  2–5 counts (2026-09-02); the park now lands within 0–1 count. The rig task's
  home-before-every-trial (0.9 s a trial) is no longer needed for the park
  position.

**Open, for the firmware (`.agents/PLANS.md`):** the tolerance. At IRUN 8 a
one- or two-count correction rarely moves the rotor, so the second correction
mostly spends ~100 ms and over-advances the ramp frame; a two-count tolerance
(26 microsteps, 0.18°) would skip it at the price of the last count. At
IRUN 17 the torque increment per microstep doubles and the question changes;
decide it with the thermal survey. Lost motion between the motor shaft the
encoder reads and the joystick lever (gear pair, coupling) is invisible to
the board either way.

### v1.0 unit A — the rig's trial task, dry run without homing between trials, 2026-10-07, 08:40–08:45

The rig's own files, not the bring-up ones: `joystick-rig` branch
`feat/mouse-joystick`, `hardware_definition_joystick.py` (`left` on port 1,
unpopulated; `right` on port 4; solenoid on port 5; rsync on `DAC_2`; camera
trigger on `BNC_1`) and `tasks/rig1/joystick_trial.py` with
`home_each_trial = 0`, run headlessly through pyControl 2.1.1's board API
from the checkouts (`mouse-joystick-firm/tools/pycontrol_run.py
--hwd-path/--task-dir`, added today) against unit A on the right joystick,
nobody at the rig: `n_trials=8`, `watch_timeout_ms=2000`, `iti_ms=1000`,
the rest the task's defaults. Firmware as the previous section. Evidence
`mouse-joystick-firm/evidence/2026-10-07-0840-unitA-rig-trial-dryrun/`.

| trial | present `TARGET` (−5.0 commanded) | park `TARGET` (0.0 commanded) |
| --- | --- | --- |
| 1 | −4.95 | +0.084 |
| 2 | −5.041 | 0.0 |
| 3 | −4.95 | 0.0 |
| 4 | −4.95 | +0.084 |
| 5 | −4.95 | +0.084 |
| 6 | −4.95 | +0.084 |
| 7 | −4.95 | +0.084 |
| 8 | −4.95 | +0.084 |

One home at the start (1.05 s), then eight trials of identify-free
present → `BRAKE 1.0` → `RELEASED` ~20 ms later → tare → `WATCH` → `NOMOVE`
at 2 s → `TRIAL` 1 s later → park → 1 s ITI, 5.1 s a trial, **every
present and every park within one encoder count (0.09°) of its command, no
home between trials**; `a0` −4.95 in every `TRIAL` summary, the torque at
rest after the tare 0.03–0.06 N·cm, no `TOUCH`, no `nak`, no `FAULT`; the
40 ms heartbeat ran throughout (1072 link events in 41 s), the rsync pulses
and the 150 Hz camera trigger alongside. The present move takes 0.36 s when
the park landed within a count and 0.58 s after the one park that needed a
correction; the park 0.55 s.

**pyControl finding, the pyboard's flash:** the first attempt failed with
"Insufficient space on pyboard filesystem" — `statvfs` showed 0 blocks free.
pyControl never removes device files it has uploaded
(`transfer_device_files` runs with `remove_files=False`): `MCP.py` (9 KB) and
`rotary_encoder.py` (2.5 KB), dragged along by a comment on 2026-10-06's first
Gate E attempt, were still there, and the aborted transfer had left a
512-byte `frame_trigger.py` (the file is 1093 bytes) that would have failed
to import. Only "Load framework" wipes the folder. After removing the four
files, 16.9 KB were free; the rig's hardware definition is 15.5 KB of mostly
comments and its task 10.2 KB, so the comment-free copies went up (706 bytes
and 5.2 KB, `tools/pycontrol_lean.py`'s function on the rig's files; the
copies are in the evidence directory). Through the GUI the files go up
verbatim: load the framework first, and the budget after the devices is
about 3 KB. Written up in `mouse-joystick-firm/pycontrol/README.md`.

### v1.0 unit A — the reward path and the pull sign, 2026-10-07, 08:53–08:59

The solenoid cable moved to Breakout 1.2 port 5 (`POW_A`) by Peter at
~08:50, then the rig's trial task (as the dry run above) on the right
joystick with Peter pulling the lever by hand during the watch. Evidence
`mouse-joystick-firm/evidence/2026-10-07-0855-unitA-solenoid-pull/`.

| run | window | what the board saw | outcome |
| --- | --- | --- | --- |
| `pull2`, 08:53 | 2 × 25 s | trial 1: `TOUCH` 0.31 N·cm 15 ms before the timeout, `NOMOVE`; trial 2: nothing | the pull came after each window closed |
| `pull1_60s`, 08:55 | 60 s | `TOUCH` 0.30 N·cm at 9.4 s, then the lever from −4.95 to **−9.991** in 0.26 s: **`PUSH`**, `TRIAL a_peak=-5.041 outcome=PUSH`; the park then faulted **`not_following`** 0.48 s in (the hand still on the lever), rail off | pull sign +1 was wrong for this board; no reward |
| `pull1_60s_signed`, 08:59 | 60 s | `TOUCH` 0.32 N·cm at 7.9 s, the lever to **−10.083** 93 ms later: **`PULL`**, the task's 50 ms solenoid pulse, `TRIAL a_peak=5.041 outcome=PULL dur_thr=0`, park `TARGET` 0.0, `session complete: pull 1` | **the reward path works end to end** |

Findings:

- **Unit A's pull is the decreasing-angle direction**, away from the home
  switch and further into the travel, like board 4's on 2026-09-02:
  `BoardCalibration.hpp` now carries `{"E4654C159F274534", -1.0}` and the
  board was flashed with it at 08:58. A pull-positive excursion of 5.04°
  from the presented −4.95° reaches the travel's far end (−10.0°); the
  `pull` threshold of 5° therefore means "all the way".
- **Two direct 50 ms pulses on `port_5.POW_A`** through the pyboard's REPL
  at 08:58 (`hardware_definition.solenoid.on()/off()`), before the signed
  run, for the ear.
- **A lever held through the park faults the board, correctly.** The TRIAL
  summary comes one second after the outcome and the task parks at once; at
  IRUN 8 the drive cannot move a held lever, the ramp generator advances
  while the encoder does not, and the follow check faults `not_following`
  (bit 2) and drops the rail — the stall detector doing its job, and the end
  of a session if a mouse does it. The protocol or the task needs a rule
  for it: wait for the lever to be free (torque below a level, angle still)
  before the park, or recover with `CLRFAULT` → `HV ON` → `HOME`. Open in
  the firmware plan and `uart-protocol.md` V1.9.
- **One refused command, unexplained:** 5 ms after that `FAULT` event the
  task's first `faults` request was answered `nak;326;badverb`; the task
  re-entered its faulted state and the second `faults` was acknowledged
  (`mask=4`, `over_travel: not_following`). The verb is dispatched by exact
  match and was accepted a few milliseconds later, so a byte of the first
  line was most likely corrupted on its way in, around the switched domain
  collapsing; the LA5032 was not capturing. Next fault, capture CH3 (board
  RX). No other `nak` in 1 500 lines today.

### v1.0 unit B (board 7) — `E4654C159F404534` — Stage 1 passed 2026-10-07, 09:08

First power-on of the second v1.0 unit, after Peter's rework (the wrong
green banded part: `C1208` next to the TMC5130A refitted, `C1301` and
`C1501` removed, as on unit A). USB alone: the board enumerated as the
RP2040 ROM bootloader (`2e8a:0003`, `RPI-RP2`), took `RP2040SelfTest` for
`mouse_joystick_rev2` by UF2 copy and came back as `2e8a:f00a` with the
serial above on `/dev/ttyACM2`, beside unit A. **result: 20 checks, 0 failed.** Console log:
`mouse-joystick-firm/evidence/2026-10-07-0908-unitB-bringup/s1_selftest_rev2_boardB.log`.

| Check | Result |
| --- | --- |
| reset reason | `software (3)` (the UF2 reboot) |
| `clk_sys` against `clk_ref` | 133000 kHz; `clk_ref` 12000, `clk_peri`/`clk_usb`/`clk_adc` 48000 kHz |
| flash | unique id read, 16 MiB declared, no aliasing at +2/+4/+8 MiB |
| heap | 252224/96/252128 |
| `GP9` `~{BUS_SW_EN}` | high — `R607` holds the bus isolated |
| `GP24` `HV_LATCH` | low (informational: switch unpowered) |
| `GP16`/`GP17` `DAC_SDA`/`DAC_SCL` | high — `R403`/`R402` |
| `GP1` `PYC_UART_RX` | high — `R401` |
| `GP23` `~{HV_FAULT}` | high — `R507`, no latched fault |
| spare pads `GP20`, `GP22` | both move both ways |
| `GP26` `SW_RAIL_SENSE_DIV_2` | 17 counts = 0.0137 V divided = **0.0274 V on `+3.3V_SW`**, off |
| `GP28` `HV_SNS` | 15 counts = 0.0121 V across `R509` |
| `GP27` `BRAKE_ISENSE` | 13 counts = 0.0105 V |
| `GP29` `ANGLE_OUT_MON` | 18 counts = 0.0145 V |
| die temperature | 29.0 C at boot |

The floors are 4–8 counts above unit A's (9–14 counts there): ADC offset,
nothing more at the rail-off level. Not done on this unit: the Digital-50
check (the adapter is on unit A), the `k` crystal check, the cold power-on
reset reason. Next: 36 V with nothing else connected (stage 2,
`TMC5130Communication`), then the left joystick's cables.

### v1.0 unit B — Stage 2 passed 2026-10-07, 09:12, direct LATCH-GPIO power-up

36 V connected to `J501` by Peter (nothing else on the board: no joystick,
no RJ-45), `TMC5130Communication` on `mouse_joystick_rev2` (firmware
`51322e7`-dirty) over USB, the timed key sequence `v d s i d x s r x m x l x`
(`mouse-joystick-firm/evidence/2026-10-07-0908-unitB-bringup/s2_tmc_rev2_boardB.log`).

| Step | Result |
| --- | --- |
| `v`, `d` before | `+3.3V_SW` 0.0274 V off; `HV_SNS` 14 counts, offset floor; `~{HV_FAULT}` high |
| `s`, first pass | method **LATCH held low, direct HV_EN assertion**; `+3.3V_SW` up in 4 ms, peak 3.3008 V; bulk charged (HV_SNS below the fault level 20 ms running) at 34 ms, latch-off armed; live 3.3040 V; `HV_SNS` 51 counts = 132 mA during the charge; bus closed with `~{TMC_DRV_EN}` high; `VERSION` 0x11, `DRV_ENN` 1, `SD_MODE` 0, IOIN invariants ok; **register checks 5, 0 failed** |
| `s`, second pass after `x` | identical, bulk at 30 ms, `+3.3V_SW` 3.3008 V; 5/0; `r` re-read 5/0 |
| `m` | zero 13.94 counts, live 25.50, delta 11.56 → **36 V input current 29.9 mA** idle with the bus open (unit A read 43.6–51.3 mA on 2026-10-05; one count is 2.6 mA) |
| `l` LATCH probe | strapped half (GP24 driven high through `R503`): rail up, held 32 of 250 ms, peak 3.306 V, `~{HV_FAULT}` LOW, fault latched — **FAIL as designed**, as on unit A; the direct method of the `s` passes is the GPIO half passing |

Same behaviour as unit A on 2026-10-05 to the millisecond; the refitted
`C1208` (TMC `5VOUT`) is doing its job since the chip answers. Not done: the
Digital-50 taps (the adapter is on unit A). Next: A3 (the I2C angle DAC and
`ANGLE_OUT_MON`) with the same connections, then the left joystick's cables.

### v1.0 unit B — Stage A3, the angle DAC over I2C, 2026-10-07, 09:14

Same connections as stage 2 (36 V, USB, nothing else), `AngleOutput` on
`mouse_joystick_rev2` (`51322e7`-dirty; the uploader's 1200-baud touch left
the board in BOOTSEL with "RP2040 device returned an error", the UF2 copy
finished it), keys `b d q z m f z d x`
(`mouse-joystick-firm/evidence/2026-10-07-0908-unitB-bringup/a3_angleoutput_rev2_boardB.log`).

| Step | Result |
| --- | --- |
| `b` | `+3.3V_SW` up in 3 ms, bus closed, I2C on GP17/GP16 to 0x48, `GAIN 0x101` written and **read back matched** (2.5 V at the DAC, 1.650 V at the BNC) |
| `d` | `DEVID 0x115`, `REF-ALARM` clear, before and after the codes |
| `z` code 0 | `ANGLE_OUT_MON` **0.0161 / 0.0153 V** (19–20 counts): the floor (unit A 12 mV) |
| `m` code 32768 | expected 0.8250 V at the BNC node, **measured 0.8292 V** (unit A 0.8236) |
| `f` code 65535 | expected 1.6500 V, **measured 1.6488 V** (unit A 1.6415) |

Within the RP2040 ADC's accuracy of the design values, as unit A; a meter
fit at the BNC is still owed on both units. Next: the left joystick's
cables (motor, encoder, limit switch, brake, torque sensor) for A6, A4
and A5.

### v1.0 unit B — Stage A6 (stage 3 on v1.0) passed 2026-10-07, 09:22–09:25, the LEFT joystick

The left joystick's motor, encoder, limit switch, brake and torque sensor
cabled by Peter, the second LA5032 on the Digital-50 (straight cable, see
the adapter's log), `MotionAndHoming` on `mouse_joystick_rev2`
(`51322e7`-dirty) over USB; the key sequences `b c e p W p` and then
`g h H k k j k j k g h L p x`, as unit A's on 2026-10-05
(`mouse-joystick-firm/evidence/2026-10-07-0908-unitB-bringup/a6a_gates_unitB.log`,
`a6b_motion_unitB.log`, captures `a6a_gates_unitB.sr`, `a6b_motion_unitB.sr`
at 1 MSa/s on CH0/1, CH8–11, CH14, CH15, CH24, CH27, CH28/29).

| Gate | Result on unit B | Unit A, 2026-10-05 |
| --- | --- | --- |
| `b` | `+3.3V_SW` 4 ms, bulk 33 ms, direct method; bus closed; `VERSION` 0x11; converter, driver, controller, encoder configured; `GAIN 0x101` | same |
| `c` | `CHOPCONF` 0x10030153, `vsense` read back 1 | same |
| `e`, `p` | enabled; `X_ENC` 38 microsteps (0.27°) against `XACTUAL` 0: the enable snap | same order |
| `W` | the switch found **toward the POSITIVE end** after 3583 microsteps (25.19°) of travel, throw 256 microsteps, **active high**, `pol_stop` 0; `XACTUAL` 3327 / `X_ENC` 3392 afterwards | same end, same polarity |
| `g` | follow ratios 0.93 / 0.89, residual −52 microsteps (−4.1 counts) after the round trip, within 7 % | 0.94 / 0.86, −103 (−8 counts) |
| `h` | approach stopped by the switch (390 commanded, 422 measured); closing latch 3717, release edge 3326, closing-to-release 391 microsteps (2.75°); backed off to −1401; **homed**, 1741 ms | same structure |
| `H` | **5 of 5; release `ENC_LATCH` 115, 102, 0, 12, 12 microsteps → spread 115 microsteps (0.81°, 9.0 counts)**; runs 3–5 agree within one count, runs 1–2 sit 100 microsteps away | spread 25 microsteps (2 counts) |
| jogs `k k j k j k` | follow ratios 0.93–1.01 | same |
| `g` again | residual −77 microsteps (−6 counts), within 1 % | −102 |
| `h` again | homed | |
| `L` | live angle output at 1 kHz, **worst loop 350 µs** of the 1000 µs budget | 1082 µs (before the 400 kHz I2C) |
| `p` after the back-off | `XACTUAL` −1404 / `X_ENC` −1229 microsteps | −1346 / −1229 |

Same geometry as the right joystick: the switch at the positive end, active
high, the encoder counting with the ramp generator, the motor direction as
configured — no `o`, `m` or `y` flip needed, so one `AppConfig` serves both
boards. **The one difference is the homing repeatability**: the left
joystick's first two counted homes landed 8 counts from the last three,
which agreed to one count. Whether that is the switch bedding in after a
day's rest or play in this joystick's mechanism, a second `H` series later
will say; the settled figure matters because the rig task no longer homes
every trial (V1.13 settles on the encoder instead).

### v1.0 unit B — Stages A4 and A5, brake sink and torque bridge, 2026-10-07, 09:27–09:31, the LEFT joystick

`BrakeAndTorque` on `mouse_joystick_rev2` (`51322e7`-dirty) over USB, the
left joystick's brake and torque sensor cabled, joystick untouched; the key
sequences `b i r s S "S 32768" 0 i` and `t "T 1000" d k z t "L 10" X i x`,
as unit A's on 2026-10-06; the second LA5032 on CH16–CH23 (torque SPI,
`TQ_CAL_EN`, `~{BRAKE_FAULT}`, DAC I2C) at 10 MSa/s
(`mouse-joystick-firm/evidence/2026-10-07-0908-unitB-bringup/a4_brake_unitB.log`,
`a5_torque_unitB.log`, captures `a4_brake_unitB.sr`, `a5_torque_unitB.sr`).

**A4, the brake sink:**

| Step | Result on unit B | Unit A |
| --- | --- | --- |
| `b` | both DACs ACK (0x48, 0x49); brake `GAIN 0x101` read back, `DEVID` 0x115; ADS8689 `RANGE_SEL` 0xB read back, SDO loopback all-ones/all-zeros ok | same |
| floor | `BRAKE_ISENSE` 0.0145 V (18 counts) = 0.70 mA at code 0, `~{BRAKE_FAULT}` high | |
| `s` sweep 0–100 % | linear: 5.51, 10.35, 15.28, 19.97, 24.62, 29.54, 34.42, 39.31, 44.23, **49.11 mA at full scale** (1.0130 V), error 0.5–1.4 % FS, the floor included; no fault at any point | 48.80 mA, ±0.07 % FS above half scale |
| `S` full-scale step | rise to 49.1 mA, **peak 62.67 mA (128.5 %) at 13 ms**, settled by 16 ms; `~{BRAKE_FAULT}` never asserted; fall to 0.7 mA in ~4 ms | 62 mA (127 %), the same silent ceiling |
| `S 32768` half-scale step | peak 24.93 mA (51.1 %), settled by 7 ms, no overshoot | same |

**A5, the torque bridge:**

| Step | Result on unit B | Unit A |
| --- | --- | --- |
| `t`, `T 1000` | rest **26718 codes = 2.0873 V at `AMP_VOUT`, 1.0437 V at the BNC = +1.5495 N·cm on the nominal scale**; sd 1.31 codes = **102.6 µV rms** (0.38 mN·cm), span 8 codes | 1.5956 V rest, 95–112 µV rms |
| `d` | `DEVICE_ID` 0x0010, `RANGE_SEL` 0x000B, `ALARM` 0x0041 | same |
| `k` shunt-cal | step **−0.1 codes** of the 9522 designed: the switch is inert on this unit too | inert |
| `z`, `t` | tared at code 26721; **the nominal zero is 21333, 5388 codes = 420.9 mV off** (the sensor's zero balance is ±1 % R.O. = ±9.6 mV); tared reading 0.0003 N·cm | 69 mV off |
| `L 10` | **1000.1 Hz, worst iteration 137 µs**, 0 overruns; 114 µV rms over 10 000 samples | 295 µs worst |
| `X` coupling | torque mean 26725.9 → 26713.9 → 26703.9 → 26724.6 codes at brake 0 → 24.6 → 49.1 → 0 mA: **−22 codes = −1.7 mV = −0.006 N·cm at full brake current**, reversible | none at 0.1 mV |

Two things for the left joystick, both the mechanism's rather than the
board's: **the torque sensor rests 1.55 N·cm from its nominal zero**, forty
times the sensor's zero-balance tolerance, so the bridge is under a
mechanical preload (the lever resting against something, or the sensor
mounted under strain) — the tare hides it and the range still has 3 V of
headroom above and 2 V below, but it is worth a look at the sensor's
mounting before trusting absolute torque; and **a small brake-to-torque
coupling** (−0.006 N·cm at 49 mA), fifty times below the 0.3 N·cm touch
level and reversible, which unit A's joystick did not show. The rest
reading's sign (+1.55 on the nominal scale) and the pull direction are to
be put together once a hand pull has been classified through the protocol.

### v1.0 unit B — Gate E through pyControl on Breakout port 1, 2026-10-07, 09:37

RJ-45 from unit B to Breakout 1.2 port 1 (`UART(4)`), the PYBV11 on
`/dev/ttyACM1`, unit A still on port 4; `examples/PyControlLinkQp` on
`mouse_joystick_qp_rev2` (`51322e7`-dirty, UF2 copy) on unit B;
`pixi run -e pycontrol pycontrol-run` with `mouse_joystick_bringup` and
`mouse_joystick_check --set board=left --set watch_timeout_ms=2000`, nobody
at the joystick; the second LA5032 on CH0–CH3 at 2 MSa/s
(`mouse-joystick-firm/evidence/2026-10-07-0908-unitB-bringup/pilot/gate_e_left.txt`,
`captures/gate_e_left.sr`).

| Task time | What happened |
| --- | --- |
| 0.023 s | `id`: `serial E4654C159F404534 fw 51322e7-dirty hw rev2 proto 2 caps …+angout+brake+torque` |
| 0.193 s | `hv on` acked (170 ms) |
| 1.312 s | `HOMED` at 0.0° (1.12 s) |
| 1.697 s | `TARGET` −4.95° (358 ms after `arm`) |
| 1.719 s | `brake 1.0` → `RELEASED` 21 ms later, **torque 1.524 N·cm untared** (the left sensor's rest offset, A5) |
| 1.741 s | `status`: angle −4.774, xactual −4.999 (the rotor relaxed 0.23° under the brake), torque 1.672 |
| 3.737 s | `NOMOVE` at the 2 s timeout, torque −0.118 after the tare, **no `TOUCH`** |
| 4.750 s | `TRIAL outcome=NOMOVE a_peak=0.176 tq_peak=-0.211` |
| 5.278 s | park → `TARGET` −0.091° (one count) |
| 30 s | `run_end`: stop, disarm, rail off |

The same sequence as unit A's Gate E to within tens of milliseconds, over
the other port and the other UART, with unit A idle on port 4 (nothing
printed as "other board"). The park within one count is V1.13 at work on
the second mechanism.

**The left joystick's pull direction, 09:34–09:38** (`pilot/pull_left_60s.txt`,
`pull_left_60s_signed.txt`): a hand pull during a 60 s watch took the lever
from −5.041 to **−10.174°** and was classified **`PUSH`** with the default
pull sign +1 (`TRIAL a_peak=-5.133`), the lever released in time and the
park landed at 0.0. `BoardCalibration.hpp` gained `{"E4654C159F404534", -1.0}`,
the board was flashed with it (UF2 copy, 09:36), and the same pull was
**`PULL`** at −10.083 (`TRIAL a_peak=5.041 outcome=PULL`), park 0.0, sequence
complete. So **both joysticks pull toward decreasing angle**, away from the
home switch. **The left torque sensor reads the pull NEGATIVE** (−0.55 N·cm
at the outcome, −0.33 at `TOUCH`) where the right one reads positive
(+0.49); `TOUCH` uses the magnitude, `tq_peak` carries the sign, so the
rig's analysis must not assume one torque sign for both joysticks. The
untared rest reading at `RELEASED` was 1.524–1.529 N·cm every run (A5's
preload), and the tare before `watch` removed it each time.

**Both v1.0 boards now pass Gate E on their own Breakout ports (unit A on
4, unit B on 1) under one hardware definition**, with the pull signs of both
measured; a task that drives both in one session is the researcher's.

### v1.0 unit A — both analog outputs on an oscilloscope with the joystick in the hand, 2026-10-07, 09:50–10:10

Peter's scope on the right board's `ANGLE_OUT` and `TQ_AOUT` BNCs; the
bring-up task's new `hold` knob (`mouse_joystick_check`: `hold=1 angout=1`
presents at −5°, sets the brake to `brake_ncm` 1.0, releases the drive and
stays `RELEASED` with no watch, printing `status` every 2 s until the run
ends; `angscale ang_lo ang_hi` and `angout on` are sent behind the present
move). Evidence
`mouse-joystick-firm/evidence/2026-10-07-0950-unitA-scope-hold/pilot/`.

- **Run 1 (`hold.txt`), angle scale −10.125..0°:** the angle BNC stayed at
  0 V — the `angout` line, queued behind `home` with `angscale`, was lost to
  a `nak;;badframe` (`home` blocks the board ~130 ms; three lines behind it
  were one too many, see the firmware's `pycontrol/README.md`). The torque
  BNC moved with the hand regardless. `status` showed the hand taking the
  lever from −4.77° to **−20.07°** and back, so the −10.125° scale would
  have pinned the output anyway. The run ended `FAULTED host_timeout` when
  its host process was killed: the pyboard stalls on USB backpressure and
  stops pinging — the board did what it is for (rail off within 100 ms).
- **Run 2 (`hold2.txt`), the lines behind the move, scale −28.125..0°,
  `clrfault` before `id`:** no refusal; `angle output on`, `TARGET` −5.041,
  `RELEASED` with the brake at 1.0 N·cm, `holding`. **Peter: both traces
  follow the joystick** — the angle BNC through the encoder at 1 kHz on the
  full-travel scale (−5° ≈ 1.36 V, −20° ≈ 0.49 V), the torque BNC from the
  bridge amplifier (pull positive on this joystick). Resistance felt is the
  brake's 1.0 N·cm (14 mA). The run ended cleanly at 600 s (`run_end`: stop,
  disarm, rail off), 299 `status` samples, no `nak`, no fault; over the ten
  minutes the hand took the encoder from **−48.24° to +0.90°** (torque
  −0.175 to +0.563 N·cm), so the mechanism's free swing on this joystick is
  about 49°, far past both the firmware's commandable travel (−10.125..0°)
  and the 28° "measured travel" constant, which the open issue below
  already calls a hard-stop setting rather than a mechanism property; the
  angle BNC pins at its floor beyond the scale's −28.125°.

Not measured: voltages against a meter, the angle output's step response
or the filter group delay on the scope; this was a look, not a
characterisation (A3 and the 2026-09-10 board-4 section have those).

### v1.0 unit A — 400 trials unattended, the soak before the researcher session, 2026-10-07, 10:40–11:14

The rig's own `joystick_trial.py` (the slimmed file, uploaded verbatim as
the GUI would) on the right joystick through Breakout port 4, nobody at the
lever: `n_trials=400`, `watch_timeout_ms=2000`, `iti_ms=1000`,
`home_each_trial=0`, the 40 ms heartbeat, one home at the start. Firmware
`51322e7`-dirty `mouse_joystick_qp_rev2` (unit A's 08:58 build). Evidence
`mouse-joystick-firm/evidence/2026-10-07-1040-unitA-soak/pilot/soak400.txt`.

| Quantity | Over 400 trials |
| --- | --- |
| outcome | 400 `NOMOVE`, 0 `TOUCH`, **0 `nak`, 0 `FAULT`**, `session complete` at 33 min 53 s |
| present `TARGET` (−5.0 commanded) | −4.95 × 358, −5.041 × 42: always one of the two encoder counts beside the command; mean −4.960, sd 0.028 |
| park `TARGET` (0.0 commanded) | **0.0 × 399, −0.091 × 1**: within one count every time, no homing between trials |
| trial period | 5.081 s mean, sd 0.023 s, min 4.95, max 5.16; first ten 5.068, last ten 5.084 — no drift |
| torque at `RELEASED`, untared | 0.132 N·cm mean, sd 0.026 (0.015–0.181); after the tare, `tq_out` 0.044 ± 0.025 |
| link | 53 190 lines in 2029 s (26/s: the heartbeat acks and the events), none lost |

So the delivery firmware, the device class and the trial loop hold for half
an hour and four hundred reversals without a park drifting, a tick budget
problem surfacing on the link, or a fault: the position stays on the
encoder count, the timing on the millisecond. What this does not exercise:
a hand or an animal on the lever (`PULL`/`PUSH`, the reward, the held-lever
case), the second board at the same time, or an hour-long session; a longer
run can be left overnight when the rig is otherwise idle.

### What stage 1 (USB only, 36 V unplugged) touches on v1.0

| Net | v1.0 part | Value | Firmware expects at reset |
| --- | --- | --- | --- |
| `~{BUS_SW_EN}` (GP9) | `R607` | 7.87 kΩ to `+3.3V_MCU` | high — bus isolated |
| `PYC_UART_RX` (GP1) | `R401` | 10 kΩ to `+3.3V_MCU` | high |
| `~{HV_FAULT}` (**GP23**, moved from GP29) | `R507` via `R504` | 10 kΩ to `+3.3V_MCU`, 10 kΩ series | high — no fault |
| `DAC_SDA_BYP` / `DAC_SCL_BYP` (GP16/GP17, MCU side) | `R403` / `R402` | 4.7 kΩ to `+3.3V_MCU` | high |
| `HV_LATCH` (**GP24**, was `~{INSTR_BUF_OE}`) | `R503` | 10 kΩ series to `U501` LATCH | recorded, not judged: the switch is unpowered |
| `FW_TRIG0` / `FW_TRIG1` (GP25/GP21) | `R404` / `R405` | 10 kΩ to GND | driven by firmware; markers reach Digital-50 `DIG0`/`DIG1` |
| `SW_RAIL_SENSE_DIV_2` (GP26) | `R408` / `R409` | 1 kΩ / 1 kΩ | ≈ 0 V, rail off |
| `HV_SNS` (GP28) | `R509` behind `R505` | 249 Ω to GND, 1 kΩ series | ≈ 0 V (`DIAG_EN` low) |
| `BRAKE_ISENSE` (GP27, new) | `R1819`, `R1818` | 249 Ω series, 110 kΩ to GND | ≈ 0 V, rail off |
| `ANGLE_OUT_MON` (GP29, new) | `R810`, `R805` | 1 kΩ series, 100 kΩ to GND | ≈ 0 V, rail off |
| spare pads | — | GP20, GP22 only | pull both ways |

Expected result line: **20 checks** (24 on v0.3, less seven spare pads and the
buffer-enable strap, plus the two I2C straps and the two monitors). The count
is derived, not yet observed; the first run settles it.

### What stage 1 cannot see on v1.0, and why the rig plan's A1 was wrong

Both DAC80501Z parts (`U801` angle at I2C 0x48 via `R806`; `U1801` brake at
0x49 via `R1807`) run from `+3.3V_FILT`; the ADS8689 (`U2002`) runs from
`+3.3V_SW` and `+5V_FILT`; and every one of their bus lines — `DAC_SDA`/`DAC_SCL`,
`TQ_SPI_*`, `TQ_CONVST_CS`, `TQ_CAL_EN`, `~{BRAKE_FAULT}` — is on the ISO side of
the bus switch. **Nothing on I2C or SPI1 can answer on USB power alone.** The
"I2C sees 0x48 and 0x49, SPI1 sees the ADS8689" checks belong to A2/A3 with the
rail up and the bus closed; the rig plan was corrected on 2026-10-04.

### v1.0 facts firmware relies on (from the netlist, to be confirmed here)

- `LATCH` is a GPIO for the first time. `PowerSequence::powerUp()` holds GP24
  low through the ramp and raises it once `+3.3V_SW` is up; the latch probe in
  `TMC5130Communication` should **PASS** on this revision and the power-up
  method should read "LATCH held low, direct HV_EN assertion". Record both.
- The DAC80501**Z** resets its data register to zero code, so the brake sink
  commands 0 mA from the instant the switched domain comes up until firmware
  writes it. `GAIN` must be `0x0101` (REF-DIV 1, BUFF-GAIN 1) on both DACs; at
  3.3 V supply a wrong GAIN forces the output to 0 V, not full scale.
- Angle output: 2.5 V at the DAC → ×1.32 (`U802`, `R804`/`R803`) → ÷2
  (`R807`/`R811`) → **1.650 V full scale** at the BNC (`R809` 249 Ω) and at
  `ANGLE_OUT_MON` (`R810` 1 kΩ).
- Brake monitor: 10 Ω shunt `R1816`, ×4.125 (`U1804`, `R1817`/`R1821`), ÷2
  (`R1808`/`R1810`) → **0–1.006 V for 0–48.78 mA** at `BRAKE_ISENSE`; the
  ceiling `V_LIMIT` = 5 V × 6.34/56.24 ≈ 0.564 V across 10 Ω ≈ **56 mA**, and
  `~{BRAKE_FAULT}` (`U1803`) is low only while limiting.
- Torque: `VEXC` 10.000 V (`U2004` REF5010A, `U2003`, `Q2002`), `VMID` 5.000 V
  (`U2006`), INA821 gain with `R2001` + `R2002` = 259 Ω, ÷3 (`R2006`–`R2008`),
  filter `R2010` 13 kΩ, buffer `U2005`; the ADS8689 sees `AMP_VOUT` through
  `R2023` 249 Ω **before** the ÷2 (`R2016`/`R2020`) that feeds the BNC and
  `TQ_AOUT_MON`. `R2003` 75 kΩ is the shunt-cal resistor switched by `TQ_CAL_EN`.
  **No pull-up on `TQ_CONVST_CS`** (the design note claims one): firmware
  drives it high in the safe state.
- The RUN pin is connected for the first time (`C615`); SWD still is not.

### Instrument port on v1.0

InstrumentPort-Digital-50 (`J1301`, FH12-50S), four `SN74LV541A` (`U1301`–`U1304`)
on `+3.3V_MCU`, always enabled. Mates the `la5032-instrument-port-adapter`
**v2.0** through a Molex Premo-Flex 15020 FFC — both on hand, **neither
continuity-checked nor permutation-checked** as of 2026-10-04. The boot
signature is the first thing to look for: three 10 ms pulses on `FW_TRIG1`
(`DIG1`, CH1) then eight 1 ms pulses on `FW_TRIG0` (`DIG0`, CH0); on CH30/CH31
instead if the cable reverses. Record the outcome in the adapter's bring-up
log, not here.

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

Fixed in `mouse-joystick-firm`: `probeLatchBehaviour()` and
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
`classifyRoundTrip()` in `mouse-joystick-firm/src/Conversions.hpp`. It lives
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

`mouse-joystick-firm/src/DAC80501.hpp` + `src/DAC80501Registers.hpp` +
`src/DAC80501/`, with `examples/AngleOutput` as its bring-up console. Every
register address, reset value, field position and I2C address came out of TI
SBAS794E rather than from memory; a local copy is at
`kicad-libs/tmp/dac60501.pdf`, which despite the filename is the family
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

### ANGLE OUTPUT CHARACTERISED — 2026-09-10, board 4. The fit is essentially unity.

**Fluke 87 True RMS on DC volts, at the BNC, centre to shell.** This is the
measurement v0.3 was ordered for. `examples/AngleOutput` over SPI1, `GAIN`
`0x0101`, 2.5 V DAC full scale into the `OPA197`'s 1.32 gain.

| Code | Ideal at the BNC | **Measured** | Residual vs the model |
| --- | --- | --- | --- |
| 0 | 0.000 mV | **4.5 mV** | clamped, see below |
| 993 | 50.002 mV | **50.2 mV** | −0.00 mV |
| 32768 | 1650.000 mV | **1.650 V** | −0.20 mV |
| 65535 | 3299.950 mV | **3.300 V** | −0.15 mV |

**One model fits all four points: unity gain, a +0.2 mV offset, and a hard clamp
at 4.5 mV.** Every residual is inside the meter's own resolution at that range.

- **Gain error is under 0.03%**, which is the display resolution rather than a
  measured error. Span, full minus midscale, is **1.650 V against 1.650
  expected**. There is no meaningful per-board gain to calibrate out.
- **Offset is +0.2 mV.** Visible only at code 993; at midscale and full scale it
  is below the fourth digit.
- **The 4.5 mV floor is a CLAMP, not an offset.** If it were additive, midscale
  would read 1.6545 V. It reads 1.650. So the `OPA197` simply cannot swing below
  4.5 mV, and the transfer function is linear above that.
- **Linearity holds at the design's valid-range boundary.** Code 993 is the
  50 mV valid-range start, and it reads 0.4% high — the clamp's influence has
  decayed from 4.5 mV at code 0 to 0.2 mV by 50 mV. So starting the valid range
  at 50 mV is sound.

#### What this does to the plan

**The `Fit gain and offset per board serial` item is answered, and it turned out
to be nearly a no-op.** The plan warned that "every one of these endpoints halves
at v1.0 and the fit must be redone rather than rescaled" — true, but if the fit
is unity to the meter's resolution there is very little to redo. The only
per-board number worth carrying is the clamp.

**It also sharpens measurement 1, the ÷2 divider decision.** That question was
whether halving the span costs anything beyond the predicted one bit. Half of it
is now settled: **there is no span error to preserve**, so the divider costs
exactly one bit and nothing more. The other half — whether the recorded trace is
already OneBox-quantisation-limited — is a *noise* question and needs a
recording, not a meter. The Fluke cannot answer it.

#### The floor is 5.6x smaller than designed, and it breaks the three-level scheme

`docs/encoder-analog-output.md` assumes "the `OPA197`'s output stage sits about
25 mV off the negative rail at light load" and builds an out-of-band scheme on
it. **Measured: 4.5 mV.** The three levels the design wants:

| Level | Means | Intended | Actual |
| --- | --- | --- | --- |
| true 0 V | output section unpowered, or a reference alarm | 0 V | 0 V |
| the floor at code 0 | firmware-signalled fault | ~25 mV | **4.5 mV** |
| >= 50 mV | valid angle | 50 mV | 50 mV |

The valid-range gap is fine — better than designed, 45.5 mV instead of 25. **The
gap that broke is the other one: a firmware fault and a dead output section are
now 4.5 mV apart instead of 25 mV**, and v1.0's ÷2 divider halves that to
**2.25 mV**. Both hardware failures read as a legitimate end of travel in a
researcher's dataset, and the doc's stated mitigation is that `STATUS` reports
the output invalid — which, over SPI, it cannot do for a reference alarm. The
analog level was the backup and it just got 5.6x weaker.

**Recommended fix, firmware-only and free: stop inheriting the fault level from
the op amp's swing limit and choose it.** Drive **code 497 = 25 mV** as the
fault level instead of code 0:

| Level | Volts | Code | Distance from 0 V |
| --- | --- | --- | --- |
| hardware dead | 0 V | — | — |
| firmware fault | 25 mV | 497 | 164 OneBox codes |
| lowest valid angle | 50 mV | 993 | 328 OneBox codes |

That restores the 25 mV separations deliberately rather than by luck, and
survives the v1.0 halving at 12.5 mV, still 82 OneBox codes. **Not applied — it
changes what recorded data means, so it is Peter's call.** The reasoning in
`encoder-analog-output.md` about the "~25 mV floor" needs correcting either way.

### Earlier the same day, before the meter: what the scope could and could not do

First real measurements of `ANGLE_OUT`, board 4, `examples/AngleOutput` over
SPI1. Scope on the BNC directly, no probe.

| Code | DAC commanded | BNC expected | **BNC measured** |
| --- | --- | --- | --- |
| `0x0000` | 0.000000 V | the output floor | **at 0 V to the display's resolution** |
| `0x8000` | 1.250000 V | 1.650000 V | **1.66 V** |
| `0xFFFF` | 2.499962 V | 3.299950 V | **3.29 V** |

**The signal chain is proven.** The `DAC80501`, the 2-pole filter, the `OPA197`
and the 249 Ω output resistor all work, `GAIN` `0x0101` really is producing a
2.5 V DAC full scale, and there is no gross error — no wrong gain field, no
missing stage, no factor of two. That was the safety question and it is answered.

#### It is NOT the gain and offset fit, and the scope cannot make it one

Midscale came in **+10 mV** and full scale **−10 mV** — opposite directions, so
neither a fixed offset nor a clean gain error. The span, full minus midscale,
reads **1.63 V against 1.650 expected**, about 1.2% low.

That is inside the instrument. A DSO's vertical accuracy is typically ±1.5-3% of
full scale, so ±66 mV at a setting spanning 3.3 V, and the readings are quoted
to three digits which is ±5 mV each and ±10 mV on the difference. The board's
own span tolerance is the same order: the gain-setting resistors are 1% parts and
the DAC has its own reference and gain error, so a genuine ~1% span error is
expected and is exactly what per-board calibration absorbs.

**So the scope confirmed the span to about 1% and could not do better.** A
gain/offset fit for a 16-bit converter needs 0.01-0.1%. **Superseded the same
day by the Fluke 87 readings above**, which put the true values at 1.650 and
3.300 — so the scope was off by +10 mV and -10 mV respectively, its own vertical
accuracy, and the board was right both times. Do not read the scope table as a
calibration; the Fluke table is the calibration.

#### The output floor: small, and that is the right direction

At code 0 the scope showed no difference between the BNC connected and
disconnected, both sitting at 0 V to the display's resolution. **The vertical
setting was 500 mV/div**, so a 25 mV floor is one twentieth of a division and a
50 mV floor is a tenth — neither is reliably visible. **This bounds the floor
below roughly 100 mV and no better.**

That is enough to kill the 150 mV, and not enough to establish the criterion
that matters. The floor *is* the out-of-band fault level, and the valid angle
range is mapped to start at 50 mV above it, so what has to be shown is
`floor < 50 mV` with margin — and a 500 mV/div reading cannot show it. **The
design's ~25 mV estimate is neither confirmed nor contradicted.** Corrected
2026-09-10: an earlier version of this entry claimed a 50 mV bound, which the
vertical setting does not support.

**Worth carrying into v1.0:** the ÷2 divider halves the floor along with the
span, so whatever the floor turns out to be, v1.0 sees half of it and the
out-of-band margin halves with it.

#### RESOLVED: yesterday's 150 mV was the instrument, twice over

The 150 mV "output floor" recorded on 2026-09-09 does not reproduce on a
correctly configured channel. Two separate instrument errors were in play, and
both are worth recognising by their signature:

1. **The channel's own baseline.** It read 150 mV with the BNC cable
   *unplugged*, which is what finally condemned it.
2. **A 50 Ω input termination.** With the channel on 50 Ω, midscale read
   **270 mV** where 1.650 V was expected. That is not a mystery — the 249 Ω
   series output resistor (`R2007`) forms a divider with the termination:
   `1.650 × 50/(249+50) = 0.276 V`, against 270 mV measured, agreeing to 2%.
   Switching to 1 MΩ moved it straight to 1.66 V.

The second one is the more useful lesson: **a reading that is low by almost
exactly 5.98× on this output is a 50 Ω termination, not a board fault.** The
agreement to 2% also independently confirmed that `R2007` is fitted and close to
value.

#### The monitor tap, traced in copper

`ANGLE_OUT_MON` on `J1501` **pad 32 is wired on v0.3** — confirmed against the
`v0.3` `.kicad_pcb`, not the docs. The topology around the op-amp output node:

| Part | From | To |
| --- | --- | --- |
| `R2007` 249 Ω | `AMP_VOUT` | `ANGLE_OUT` — the BNC |
| `R2008` 1 kΩ | `AMP_VOUT` | `ANGLE_OUT_MON` — `J1501` pad 32 |
| `R2005` 100 kΩ | `AMP_VOUT` | `GND` — the output pull-down |

So the monitor taps the **op-amp side** of the series resistor, through 1 kΩ.
Into a high-impedance instrument that is a 0.1% divider, negligible. This closes
the topology half of the *Confirm `ANGLE_OUT_MON` tracks `ANGLE_OUT`* plan item;
the "tracks" half still wants a simultaneous measurement.

**A consequence with practical value:** the monitor reads the true op-amp output
regardless of what loads the BNC. An instrument on pad 32 during the 50 Ω
episode would have read 1.65 V while the BNC read 0.27 V, and the disagreement
would have named the loading error immediately instead of it taking a
calculation to spot.

### MEASUREMENT 2 CLOSED — `+36V_SW` peak stayed below 37 V, 2026-09-10

**Owed since August, and this is the bound rather than an impression.** Scope on
`+36V_SW`, **single-shot trigger armed at 37 V rising** — only 1 V above the
nominal rail — through a full transient burst at **`IRUN` 17 = 0.421 A RMS**:

- 7 approaches at 0.200 rev/s, each ending in a **hard stop at the limit
  switch** — the fastest decelerations this rig can produce
- 6 direction reversals plus a `g` round trip at jog velocity
- the `HV_EN` staircase turn-on, twice

**The scope never triggered.** So the peak stayed under 37 V for the whole armed
window.

| Limit | Value | Margin from 37 V |
| --- | --- | --- |
| TMC5130A absolute max, inductive load | **49 V** | **12 V** |
| TMC5130A operating max | 46 V | 9 V |
| Brake pass device (future) | 60 V | 23 V |

**The TVS is not needed for the motor-driven case.** That was the populate
question, and it is answered with evidence.

A bonus from the trigger sitting only 1 V above nominal: **switching ripple on
`+36V_SW` is under 1 V**, which is the 200 µF of `C1213`/`C1214` doing its job.

This matches the energy argument recorded on 2026-09-09 rather than merely being
consistent with it: 200 µF at 36 V holds 130 mJ against roughly 2.2 mJ in both
motor phases, so even dumping every joule of coil energy into the bulk with no
loss predicts a ~0.4 V rise. Prediction and measurement agree.

#### Two things this does NOT cover

- **Supply-side events.** The probe was on `+36V_SW`, downstream of the
  high-side switch. Hot-plugging the 36 V supply and cable-inductance ringing on
  insertion are a different energy source, and the TMC5130A datasheet's own
  warning is about supply ringing from stray inductance — an input-side
  phenomenon. **The entry TVS position covers that case and this test says
  nothing about it.** Both the entry TVS and the driver's `VS`/`GND` RC snubber
  footprints exist, so either stays a populate decision rather than a respin.
- **Single-shot captures the FIRST excursion and stops.** Nothing fired, so
  there was no first excursion and the bound holds — but had it triggered, the
  captured event would not necessarily have been the worst one.

### `VREFIO` = 2.500 V, measured 2026-09-10

Fluke 87 at the DAC's VSSOP-10 pin 10. Exactly nominal, so the internal
reference is good and `REF-DIV` is not misconfigured. Over SPI this is the only
check on the reference that exists — `STATUS.REF-ALARM` is unreadable — which is
why it is worth taking with a meter rather than inferring.

### Motor coupling into the angle channel: none detectable, 2026-09-10

Plan item 1c's real question — does motor switching get into the analog output —
tested with a **static setpoint**, which is the sensitive way to do it: the angle
output was parked at a fixed **1.650 V** (code 0x8000) so the intended signal is
pure DC and anything AC is coupling. `IRUN` 17 = 0.421 A RMS throughout.

Scope on the BNC, **AC coupled, 1 MΩ, 10 mV/div, 1 ms/div**, peak-to-peak
measurement.

| Condition | pk-pk |
| --- | --- |
| driver **off**, chopper stopped | **3.54 mV** |
| driver **on**, motor stationary (chopper running, `cs_actual` 2, `stst` 1) | **3.55 mV** |
| 8 alternating jogs at jog velocity | **no increase observed** |
| 6 fast approaches at 0.200 rev/s, each into a hard stop | **no increase observed** |
| **BNC cable disconnected** | **same value** |

**The 3.5 mV is the scope's own noise floor, not the board.** Confirmed two
ways: it is identical with the chopper running and stopped (a 10 µV difference,
which is a thirtieth of one scope LSB), and identical with the cable
disconnected. Recorded explicitly because the same trap produced a phantom
150 mV "output floor" the day before — a number that turned out to belong to the
instrument.

**No gross motor coupling exists.** That is what 1c was for: the plan's own words
are that a chopper-correlated artefact "would be far larger than one bit and
makes the span question academic until fixed." Nothing of that size is present,
at standstill or under the fastest motion this rig produces.

#### What is bounded, and what is not

A scope cannot see the noise this design actually cares about:

| | |
| --- | --- |
| predicted board noise | **19 µV RMS** |
| `AD7616-P` quantisation | 44 µV RMS |
| scope LSB at 10 mV/div | **312 µV** |
| scope LSB at 1 mV/div | 31 µV |

**Even at 1 mV/div the scope's quantisation alone exceeds the predicted board
noise**, so no scope result can confirm the 19 µV figure. Taking the observed
floor as ~590 µV RMS and assuming a detectable change of a few percent, this
bounds board noise plus coupling at roughly **< 200 µV RMS** — about 4x the
`AD7616-P`'s own quantisation. Useful, and not the same as the prediction.

**So measurement 1's noise half remains open and needs the OneBox itself**, or
another 16-bit capture. The span half is settled (see the unity-gain fit), so
what is left is specifically: is the recorded trace quantisation-limited with
margin to spare? Only the recording instrument can answer that.

#### Chopper frequency was not swept

Plan item 1c also asks to "sweep the motor chopper frequency while recording the
angle channel". **Not done** — this was at the driver's default chopper
configuration only. The null result above therefore covers the operating point,
not the whole sweep. Worth revisiting only if a chopper artefact ever appears.

#### Firmware change this needed

Neither example could run this test: `examples/AngleOutput` has the DAC and no
motion, `examples/MotionAndHoming` had the motion and no DAC. The DAC is now in
`MotionAndHoming` behind `#if MJ_BOARD_REV != 0`, on SPI1 with GP12 as the
unused RX, configured in the `b` gate **after** the rail and bus so the chip
select is never driven into an unpowered part. New commands `A`/`Z`/`F` park the
output at midscale, zero and full scale. `x` calls `dac.invalidate()`, because
cycling the rail resets `GAIN` to its 5.0 V full scale.

### LIVE ANGLE OUTPUT WORKING — 1 kHz measured, 2026-09-10, board 4

The encoder now drives the analog output continuously. `examples/MotionAndHoming`
command `L`, DAC on SPI1, homed against the switch first so the angle has a
datum. Driver **disabled** so the motor freewheels and the joystick moves by
hand; `X_ENC` still counts because the TMC5130A reads the encoder independently
of its output stage.

Mapping: **0 to 90° of excursion onto 0.050 to 3.300 V**, so one encoder count
(0.09°) is **3.25 mV** at the BNC. The 90° span is deliberately wider than the
~60° mechanism — the hard stops are movable and the travel is not settled, so a
span fitted to one measured swing would silently misreport a re-adjusted stop.

#### The rate is measured, not assumed

`docs/encoder-analog-output.md` asked for the achieved rate as "a **measured**
claim, not a target". Two runs:

| Run | Updates | Elapsed | Achieved | Worst loop |
| --- | --- | --- | --- | --- |
| 1 | 202 496 | 202.5 s | **1000.0 Hz** | 473 µs |
| 2 | 632 485 | 632.5 s | **1000.0 Hz** | 527 µs |

**835 000 updates over 14 minutes with zero budget overruns.** Worst iteration
527 µs against the 1000 µs budget, so 47% headroom on the worst case.

**1 kHz is the right rate and 2 kHz is not available.** A 527 µs worst case is
already most of a 500 µs budget, and 4 kHz is out of reach. That vindicates the
design doc's original "roughly 1 kHz of real angle bandwidth is what the loop can
sustain alongside motor control" — and it **corrects an estimate made earlier the
same day** in this session, which computed a 77 kHz ceiling from 10 µs of encoder
read plus 3 µs of DAC write. **Measured worst case is 36x that**: raw bus time
ignores the TMC51X0 library's overhead, SPI transaction setup, and USB servicing.
Do not quote bus arithmetic as a loop rate.

**A useful consequence for the SPI-vs-I2C decision:** the loop is dominated by
things that are not the DAC write, so I2C at 1 MHz would add ~33 µs to a 527 µs
worst case — about 6%. **The bandwidth objection to the I2C strap is now measured
to be negligible**, not merely argued away.

#### The fast-flick capture, and the staircase is real

At hand speed the output looks smooth. Under a deliberate fast flick, captured
DC-coupled at 10 ms/div:

```
rise      2.130 V over 32.7 ms  ->  59.0 deg at 1804 deg/s = 5.01 rev/s
                                ->  20 042 counts/s, one count every 50 us
staircase 74 mV per step, 1.07 ms apart
```

Three cross-checks, all independent:

- **The 1.07 ms step interval is the 1 kHz update measured from the analog
  output itself**, not from firmware reporting its own rate.
- **74 mV per step is 22.8 encoder counts**, and the velocity independently
  predicts 20.0 counts per update — agreement to 14%, measured mid-flick where
  velocity peaks, so slightly steeper than the mean is correct.
- **Local slope 69.2 V/s against a 65.1 V/s mean** says the same thing.

**A prediction made in this session was wrong and is corrected here.** It was
predicted that the 987 Hz filter would smooth consecutive updates into each
other and leave no visible staircase. It does not: the filter needs **~2 ms to
settle a step** while updates arrive every **1 ms**, so each step is roughly
half-settled when the next arrives. Partial smoothing, not suppression. The
staircase is visible, faintly, and that is the correct expectation.

#### What the staircase costs, and why it is cosmetic

| | mV at the BNC | OneBox codes |
| --- | --- | --- |
| one encoder count | 3.25 | 21 |
| one update at 5 rev/s | **74** | **485** |

**During fast motion the update rate is the dominant quantiser, 23x coarser than
the encoder.** At rest and at hand speed the encoder dominates; at 5 rev/s the
1 kHz sampling does.

**Nothing is aliasing, though.** A 32.7 ms half-swing is roughly a half-cycle of
a **15 Hz** component, so the motion's real bandwidth is tens of Hz against the
500 Hz Nyquist of a 1 kHz sampler. The information is present and the steps are
visible quantisation of a signal that is itself smooth and slow.

Where it does bite is **timing precision on a fast trajectory: the recorded
analog trace resolves a pull to 1 ms.** Note this does **not** affect the `PULL`
event, which firmware detects from the encoder directly and which never goes
through the analog path. If finer rendering of fast pulls turns out to matter,
the options are a faster encoder read path or accepting 1 ms — **not** turning up
a constant, because 2 kHz does not fit in the measured loop budget.

#### Travel, as a by-product

The code range across both runs topped out at **2.1496 V**, which is **58.1° of
excursion** from the switch release edge on the RIGHT joystick. Consistent with
the ~60° estimate and with the left joystick's 64.174° full swing. **This is not
the deliberate hard-stop survey** that plan item still wants — it is a
measurement of where the right joystick's stop happens to sit today.

### Regression of the HEAD firmware on board 4 — 2026-10-05, stages 1–3, AngleOutput, QP session

Firmware `ec3b36d` (`mouse-joystick-firm` HEAD after the 2026-10-04 v1.0
preparation refactor), every example built for `mouse_joystick_rev1`; the QP
build pulls qp-arduino from its GitHub tag `v7.3.4`. Purpose: run the tools
that v1.0 bring-up will use on known-good v0.3 hardware first, so a different
result on v1.0 is the board. Driven non-interactively over USB CDC: no meter,
no hand pull, no pyboard (none on the bench). 36 V supply on throughout, rail
switched by firmware. Evidence, captures and console logs:
`mouse-joystick-firm/evidence/2026-10-05-1142-board4-regression/`.

| Stage | Build | Result |
| --- | --- | --- |
| 1 `RP2040SelfTest` | `mouse_joystick_rev1` | **24 checks, 0 failed** (as 2026-09-09) |
| 2 `TMC5130Communication` | `mouse_joystick_rev1` | rail up **133 ms**, **5 register checks, 0 failed** |
| 3 `MotionAndHoming` | `mouse_joystick_rev1` | switch witnessed, homed, **5 of 5 repeats, spread 2.0 counts** (as 2026-09-09); encoder follow 1.0000 continuing, **0.93–0.96 on every reversal**: the stepper's dead band against friction, present in September too, same on a replacement joystick unit; see below |
| 5 `AngleOutput` | `mouse_joystick_rev1` | rail, bus, SPI1, `GAIN 0x101` written; commanded codes only, no meter |
| QP `PyControlLinkQp` | `mouse_joystick_qp_rev1_usb` | see below |

#### Stage 1, USB only, 36 V connected but `HV_EN` low

Serial `E4654C159F171E34`, built Oct 5 2026 11:29:57, reset reason
`software (3)` (the picotool reboot after the flash). `clk_sys` 133000 kHz
measured against `clk_ref`; flash 16 MiB with no aliasing at +2/+4/+8 MiB;
heap 252228 bytes. Straps at reset: `R601` bus isolated, `GP24` OE high,
`R403` RX high, `R1905` `~{HV_FAULT}` high. Nine spare pads move both ways.

| Reading | Value |
| --- | --- |
| `+3.3V_SW` via `GP26` | 12 counts = 0.0193 V, off |
| `HV_SNS` via `GP28` | 10 counts = 0.0081 V (13 counts on the `a` re-read) |
| die temperature | 28.5 °C |
| `k` 10 s tick stream | 1000166 … 10000094 µs on the RP2040 clock (host timestamps not taken) |

LA5032 through the v1.0 adapter, capture `captures/s1_selftest_boot.sr`
(100 kSa/s, CH16/CH17, started before the reflash):

| Marker | Measured |
| --- | --- |
| `FW_TRIG1` boot signature | 3 pulses: 10.140, 10.010, 10.000 ms |
| `FW_TRIG0` boot signature | 8 pulses: 1.000–1.010 ms |
| `FW_TRIG0` heartbeat | half-period 500.25 ms, period 1000.52 ms (56 pulses) |
| `t` burst | 1001 pulses of 0.1 ms on CH16, 503 of 0.2 ms on CH17 |
| `I` beacon | 3 frames, 50 ms start on CH17, 64 clocks each on CH16, 134.3 ms apart |
| reflash gap | 2.88 s from the last QP tick pulse of the old firmware to the signature |

#### Stage 2, 36 V on, driver disabled

`s`: `+3.3V_SW` 0.0177 V before; method `firmware staircase (R1903 straps
LATCH high)`; up in **133 ms, peak 3.2944 V**, live 3.2895 V; `HV_SNS`
0.0137 V (17 counts, offset floor); `~{HV_FAULT}` high; bus closed with
`~{TMC_DRV_EN}` high. Registers: `IOIN` 0x11000018 (`REFL_STEP` 0, `ENCA` 1,
`ENCB` 0, `VERSION` 0x11, `DRV_ENN` 1, `SD_MODE` 0), `GSTAT` 0x1 then cleared,
`GCONF` 0, `CHOPCONF` 0 (`vsense` 0 at reset, reported not written),
`DRV_STATUS` 0x80000000, `XACTUAL` 0, `X_ENC` 0. **5 checks, 0 failed.**

SPI taps CH2–CH5 at 10 MSa/s (`captures/s2_tmc_spi.sr`): 16 datagrams of
40 bits decoded, **every MOSI/MISO byte equal to what the console printed**
(`04 00 00 00 00` → `39 11 00 00 18`, …), SCK 1.00 MHz, the `FW_TRIG1` burst
marker 14.30 ms high.

**`m` (36 V input current) fails whenever the rail was live, and works from
a cold rail.** `PowerSequence::measureHvCurrent()` calls `powerDown()`, waits
50 ms, then `powerUp()`, which refuses while `+3.3V_SW` still reads live; the
208 µF `+36V_SW` bulk bleeds down in ~700 ms, so straight after `s` it reports
`rail: NOT UP` with a 0.00 live count. Re-run after `x` and a 4 s wait it
measured **zero 11.77 counts, live 16.76, delta 4.98 counts = 12.9 mA** of
36 V input current with the bus open and the driver disabled (`KSNS` 800,
`R1907` 249 Ω, 2.6 mA per count). Firmware fix: wait for the rail to read
dead before `powerUp()`. The ordering is right: the bus opens before `HV_EN`
drops.

#### Stage 3, motor, encoder, limit switch, correct gate order `b c e W g h H t L`

`b`: rail up 133 ms, peak 3.298 V; TMC5130A 0x11; `uv_cp` 0; DAC `GAIN 0x101`.
`c`: `CHOPCONF` 0x10030153, **`vsense` reads back 1**, `IRUN` 8 = 0.211 A RMS,
`IHOLD` 2. `e`: driver enabled.

| Measurement | 2026-10-05 | 2026-09-09 |
| --- | --- | --- |
| `W` switch found from the negative hard stop | engaged at 8319 µsteps (58.49°), released 8063, throw 256 µsteps, active high | engaged 28.8° from where it stood, throw 1.80° |
| `g` out −1280 / back +1280 | encoder −1203 / +1126, follow **0.9398 / 0.8797**, residual **−77 µsteps (−6.0 counts)** | follow **1.0000** |
| `h` approach 0.200 rev/s, creep 0.010 rev/s | stopped by the switch at 8415 (follow 1.1278), release edge 8020, closing-to-release 395 µsteps, 1721 ms | — |
| `H` 5 runs | 5 of 5, `ENC_LATCH` 51/38/51/64/38, **spread 26 µsteps = 2.0 counts (0.183°)**, closing-to-release 708–746 µsteps | 2.0 counts |
| `t` switch reporting delay | **FAIL**: the slow approach ended without a latch | 8.74 ms |
| `L` live encoder→DAC loop | **1000.1 Hz**, 8009 updates in 8008.2 ms, worst loop **386 µs** of 1000, code 4805 static | 1000.0 Hz, worst 527 µs |
| `p` after | `DRV_STATUS` 0x8102003B, `ot`/`otpw` 0, `ola`/`olb` 0 | — |

**The lost motion is a direction-reversal dead band of the stepper against
the mechanism's friction. It is in neither the TMC5130A nor the encoder
signals, it is not a defect of the joystick unit, and it was already there in
September.** Settled the same afternoon with the encoder taps on the
instrument port (CH0/CH1), a jog series at two currents on the original unit
(`consoles/s6_irun_rev1.log`, `captures/s6_irun.sr`) and the same series on a
**replacement joystick unit** (`consoles/s7_newjoy_rev1.log`,
`captures/s7_newjoy.sr`):

- The raw quadrature on the taps agrees with the driver's `X_ENC` to within
  2 counts on every move (`g`: taps +94/−88 counts, `X_ENC` 1203/1126 µsteps
  = 94.0/88.0 counts). The chip counts what the encoder sends.
- A move continuing in the previous direction follows at **0.99–1.02**. Every
  reversal loses a fixed amount: **77–90 µsteps (6–7 counts, 0.54–0.63°) at
  IRUN 8**, **52–64 µsteps (4–5 counts) at IRUN 17**; the round-trip residual
  is one reversal (−77/−90 at 8, −52/−77 at 17). **The replacement unit
  measured the same: 90 µsteps on every reversal at IRUN 8.**
- On the taps a reversal's first encoder count comes **52 ms later** than a
  same-direction move's (63 vs 11 ms after the move marker), about 50 µsteps
  of ramp travel with the shaft still; the shaft stops 25–35 ms *before* the
  firmware declares the move done and does not creep afterwards, so the
  reading is of a settled shaft, not a premature one.
- Doubling the current shrinks the band by about a third, which a loose
  coupling or hub could not do. The lag each way, ~45 µsteps = 16° electrical
  at IRUN 8, says the static friction torque is about 0.27 of the holding
  torque at 0.211 A (sin 16°); at 0.421 A the same friction predicts a
  ~45 µstep band, measured 52–64.
- It is not new: board 2's stage 3 on 2026-09-02 left a round-trip residual of
  **−51 µsteps (−4 counts)** at IRUN 8, recorded as "unexplained", and board
  4's `g` return on 2026-09-09 read **0.9195**; the 1.0000 figures were
  same-direction legs. Today's band is one to two counts wider.

| Move (1280 µsteps = 9°) | IRUN 8, original unit | IRUN 17, original unit | IRUN 8, replacement unit | IRUN 17, replacement unit |
| --- | --- | --- | --- | --- |
| continuing in the previous direction | −1280, −1280 (1.0000) | −1280 (1.0000), +1292 | −1306 (1.0203), −1267 (0.9898) | −1293 (1.0102) |
| reversal | 1190 ×4 (0.9297), 1203 (0.9398) | 1216 ×2, 1228 ×2 (0.9500–0.9594) | 1190 ×5 (0.9297), 1177 (0.9195) | 1242, 1177, 1165, 1216 (0.91–0.97) |
| `g` round-trip residual | −77 (−6.0 counts) | −52 (−4.1) | −90 (−7.0) | −77 (−6.0) |

Motor and encoder both turn 1:1 with the joystick axis (`ENC_CONST` 12.8
µsteps per count at 4000 counts/rev), so 0.4–0.6° of *commanded* joystick
position is lost at each reversal. The encoder, the angle output and WATCH
read the true angle and are unaffected; the follow rule's 1° grace tolerates
it; homing re-zeroes at the switch, which is why the repeatability is 1–2
counts on either unit (replacement unit: **5 of 5, spread 13 µsteps = 1.0
count**; switch found 21.65° from where it rested, throw 256 µsteps, active
high). IRUN 17 roughly halves the band if commanded positioning ever needs it.
`MotionSetup.cpp` is unchanged since September, so the firmware is not a
suspect.

**`t` (switch reporting delay) fails on both units for a related reason.**
After its fast approach stops hard on the switch, its 1280-µstep move away
produced only 14 counts on the taps and left the switch engaged (tap 77.44 to
92.47 s, `LIMIT_SW` high), so the slow approach was never attempted; the code
ignores the away move's report. A reversal straight off a full-speed switch
stop shows a wider dead band than a free reversal, and the blocking
`MotionSetup::moveTo()` judges its first 200-µstep window against 0.25 with
**no grace distance and no second window**, unlike `TmcMotion`'s rule (142
µsteps of grace, two failing windows), so it ended the move. Firmware nits:
give the bench console the delivery firmware's follow rule, and have `t`
check the away report and jog clear before judging, as `W` learned to.

**Tool notes from the first, mis-ordered pass** (`W` before `e`): `W` ran the
ramp generator 21760 µsteps (153°) with the driver disabled and reported "the
sweep ran out of time"; the encoder tap confirms zero motion. `W` should
refuse, or enable the driver itself, when `~{TMC_DRV_EN}` is high. `g` from
rest against the hard stop then failed exactly as its own text predicts.

Encoder and switch taps (`captures/s3b_motion.sr`, 1 MSa/s, CH0/CH1/CH11/CH17):
3184 A/B edges, **0 invalid quadrature transitions**; raw count decreases for
positive motion, as documented; `LIMIT_SW` showed 18 transitions matching `W`,
`h`, the six `H` homes (throwaway plus five) and `t`'s fast approach.

#### Stage 5 `AngleOutput`, no meter

`b`: rail 132 ms, bus closed, SPI1 on GP10/GP11/GP13, `GAIN 0x101` written
(not readable over SPI). `q`: 2.5000 V full scale at the DAC, 3.3000 V at the
BNC, 38.15 µV/LSB. `m`, `f`, `t` (step on `FW_TRIG1`), `z`, `x` all ran. No
voltage was measured; the 2026-09-10 characterisation stands.

#### QP protocol session, `PyControlLinkQp` on `mouse_joystick_qp_rev1_usb` (protocol over USB CDC)

Phases a–e of `mouse-joystick-firm/evidence/bench-scripts/board4_session.sh`
run without stops, meter prompts unanswered, no hand pull. `ID`: `hw=rev1`,
`fw=ec3b36d`, `proto=2`, caps `motion+home+instr+hv+watch+fetch+stream+cfg+angout`,
`boot=reboot;crumb=0`. `LIMITS`: travel −10.125 … 0.0°, `v_max` 36.0 °/s,
`a_max` 180.0 °/s², `i_max` 0.421 A.

| Phase | Result |
| --- | --- |
| b | `hv on` acked (one tick of 1346 µs; `DAC_STATE` 1 then 2, 7.0 ms apart); `HOMED angle=0.0`; `angscale −10.12 0.00`; `angout on`; TARGET at −7.474 / −5.674 / −3.066 for −7.59 / −5.06 / −2.53 commanded, park at −0.541 for 0.00; `angout off`; disarm. The TARGET offsets of 0.1–0.6° are the lost motion below plus the rotor snap, as on 2026-10-02 |
| c | 20 of 20 moves, ack→TARGET p50 434.8 ms; `cfg get` `wdt_ms=100;deadband_deg=0.5;stream_hz=10;pre_ms=500;post_ms=500`; `brake 0` → `RELEASED angle=−0.816`; `watch pull=5 push=5 timeout=6000 hold=100`: the released joystick drifted to +0.9° (first motion at 712 ms) so neither `NOMOVE` nor `ABORT` (`maxdur` off) could fire, per spec; `moveto 0` left RELEASED with `TRIAL outcome=NONE a0=−0.816 a_peak=0.9 a_end=0.9` and the resync (`angle=−0.183 xactual=0.0`); FETCH 500 samples in 16 chunks, 125 ms, `lost=0`; `stream on 50` delivered 100 `ev;S` in 2 s; host-loss `FAULT code=0 host_timeout` **124.7 ms** after the last heartbeat, rail dropped (`hv=0`, `DAC_STATE 0`); `clrfault` → IDLE |
| d | 300 of 300 moves, ack→TARGET p50 434.5 / max 473.9 ms, no naks |
| e | `hv off` acked, `status` `hv=0`, `DAC_STATE 0` |

Tick cost (`SAMPLE_STAT`, 1 kHz sampler, 400 µs budget): holding with the
angle output on **158 µs light / 379 µs snapshot** (p50 last / p50 worst per
second); holding without it **46 / 88 µs**; during back-to-back moves the
command-handling tick costs **1081 µs p50, 1328 max**, one per `moveto`, so
every second of phase d is over budget while the sampler itself is not; 738
of 80003 ticks coalesced, 0 dropped, 96 back-to-back TICK levels on CH16 out
of 90035; tick period on CH8 1000.0 µs, stdev 12.4 µs, none missed. TMC SPI
taps during d: 123948 datagrams, SCK 3.33 MHz, 2 per tick p50 (10 p99),
intra-tick gap 5.3 µs p50. Trace buffer high-water 548, never full; line pool
min free 1 of 8, queue 9. On 2026-10-02 the rev 1 build holding measured
201 / 387 µs and the rev 0 build moving p50 444 / p99 1138 / max 2065; today
moving is p50 146 / p99 542 / max 1490. Full tables in the evidence README.

**Not run today:** the UART0 path with a pyboard (none on the bench), the
meter readings of phase b, the hand pull.

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
`tools/identify_boards.py` in `instrument-control`.

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
`board-interfaces/docs/instrument-port-identity-beacon.md`.

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

First filled 2026-10-06 (Gate E on v1.0 unit A; details in
`mouse-joystick-firm/pycontrol/README.md`, "Gate E Passed On v1.0 Unit A").

- pyControl version: **2.1.1** (`pycontrol-code`
  checkout, GUI not used: `tools/pycontrol_run.py` drives the same `Pycboard`
  API headlessly), pyboard **PYBV11, MicroPython 1.26.1**, serial
  `397734803233`, Breakout 1.2 **port 4** (`machine.UART(3)`) → the board's
  RJ-45.
- Task file used: `mouse-joystick-firm/pycontrol/tasks/mouse_joystick_check.py`
  with `hardware_definitions/mouse_joystick_bringup.py` (`right` = port 4),
  both uploaded as the comment-free copies `tools/pycontrol_lean.py`
  generates (the pyboard's 95 KB flash had 36 KB free).
- Events received and logged: `id` reply, `HOMED`, `TARGET` (twice),
  `RELEASED` (23 ms after `brake 1.0`), `TOUCH`, `NOMOVE`, `TRIAL`, the
  heartbeat replies at 25/s (1236 lines in 50 s, none lost), through
  pyControl's data log as `print` and `input` events; runs
  `mouse-joystick-firm/evidence/2026-10-06-1019-unitA-gate-e/` and `-1037-`.
- Timestamp agreement after Rsync alignment, with uncertainty: **not yet** —
  the bring-up task does not send `rsync`; the board's `t_us` and the
  pyboard's ms clock were only compared by eye (sequence and spacing agree).
- If two boards: **not yet** (unit B is not on the bench).
- Failure and recovery behavior from the task's perspective: two cases seen.
  (1) A host that stops talking: the REPL session of 10:01 waited 150 ms
  during a `fetch` and the board faulted `host_timeout`, dropped the rail
  and the brake, answered pings and `clrfault` — as specified. (2) A task
  that dies **between `hv on` and its first heartbeat** (run 10:17, a
  `NameError` in the task): the board's host watchdog was not armed yet, so
  the rail stayed up, idle, until the next run's `hv on`/`hv off`. Harmless
  here; a task should send its first heartbeat (or arm the watchdog) right
  after `hv on`, and `run_end` must always `stop`/`disarm`/`hv off`, which
  `mouse_joystick_check` does.
- Observation for the rig: parking at 0° after a trial ended with the
  encoder at −0.9/−0.99° while the driver reported its target reached (both
  runs). The resync at the trial's close had made the two agree, so the
  degree was lost in the park move itself, a direction reversal after the
  move to −5°: coupling backlash, most likely. Home before a trial that
  needs the park position exact.

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
knowing before anyone wires the second joystick, or `mouse-joysticks-pcb`,
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

