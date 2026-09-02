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

Two units, both **rev 0**. `v0.1`→`v0.2` is layout-only — same schematic,
byte-identical pad-to-net map — so measurements transfer between the tags but
**not between the units**. Keep them apart; that is what the serials are for.

| Unit | RP2040 flash unique ID | State |
| --- | --- | --- |
| **Board 1** | `E4654C159F2C2534` | Stage 1 + stage 2 passed. **`R203` DEPOPULATED 2026-09-02** — `LATCH` released, so a plain `HV_EN` assertion works on this unit and it no longer represents an as-built board |
| **Board 2** | `E4654C159F4D1334` | `R203` intact, i.e. as-built. **Stages 2 and 3 passed 2026-09-02** — motor turns, encoder tracks, homing repeats to 4 encoder counts. Stage 1 has never been run on it. See [Board 2](#board-2--e4654c159f4d1334) |

Everything from here to [Board 2](#board-2--e4654c159f4d1334) is **board 1**
unless a line says otherwise.

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

- TMC5130A case temperature, 30 min idle:
- TMC5130A case temperature, 30 min continuous motion:
- Confirmed `VCC` fed externally, internal regulator offloaded:
- 3.3 V LDO temperature:
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

Expected configuration: `R1203`/`R1204` 0.15 Ω, `vsense = 1`, `IRUN = 28`, target
0.679 A RMS. A measured current near 1.23 A means `vsense` is 0 — stop.

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
- `IRUN` read back (expect 28):
- **Coil current measured, RMS** (expect 0.679 A):
- Driver config read back over SPI:
- `DIAG0` behavior (`R1101` 10 kΩ pull-up to `+3.3V_SW`; open-drain, idles high):
- `DIAG1` behavior (`R1102` 10 kΩ pull-up to `+3.3V_SW`):
- Sense resistor temperature, standstill hold at current:
- Motion smoothness / audible behavior:
- Microstep smoothness at 163 mV sense signal:
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
- Nothing was strained finding it. At `IRUN` 8 the motor simply stalls, and the
  follow check ends the move within one 200-ustep window.

**Not yet measured on this unit:** coil current RMS, sense-resistor
temperature, `DIAG0`/`DIAG1` behaviour, microstep smoothness, step-rate ceiling,
encoder supply current, and any of it at a current above `IRUN` 8.

## Open Issues Found During Bring-Up

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

