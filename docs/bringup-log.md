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

## Board

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
- Firmware commit / image hash: `mouse-joystick-firm`, uncommitted working tree,
  `examples/RP2040SelfTest` on env `mouse_joystick`, built `Sep  1 2026 13:31:32`.
  Flashed and byte-verified by `picotool`.
- Protocol version: n/a — no pyControl protocol implemented yet.
- Notes: **Stage 1 (RP2040 subsystem) passed 2026-09-01: 27 checks, 0 failed.**
  USB power only; 36 V has never been connected to this board. Full record under
  [Controller](#controller).

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
- Rework:

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

- Input voltage / current limit used: **36 V not yet connected.** Everything in
  this section is outstanding.
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
- `+36V_SW` bulk capacitance measured or confirmed (design value ~208 µF,
  `C1213` + `C1214` 100 µF **50 V** each plus ceramics; no TVS populated):
- Inrush:
- `HV_EN` assertion behavior, rail rise time:
- `ILIM` resistor `R206` value and measured current limit: **`R206` = 40 kΩ** in
  the `v0.1` netlist, design I_CL ≈ 1.2 A. Not measured.
- `HV_SNS` reading versus measured load current, **with `GP14` (`HV_DIAG_EN`)
  raised** — `HV_SNS` and `~{HV_FAULT}` report nothing while `DIAG_EN` is low:
- `HV_SNS` reading at `GP28` during a provoked fault (expect 1.3-1.6 V from
  `ISNSFLT` 5.2-6.4 mA into `R207` 249 Ω; RP2040 `VPIN` absolute max is 3.8 V):
- 5 V rail, measured:
- 3.3 V rail, measured:
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
  pin 5 = `ENC_B_RAW`; supply sits between the two channels):
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
- Captures archived at:

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

### No test points remains the binding constraint

Every stage 1 result above came from the RP2040's own ADC and GPIOs or from the
InstrumentPort. No independent meter reading was taken anywhere, so the ADC
figures confirm self-consistency rather than absolute accuracy — and `ADC_AVDD` is
tied straight to `+3.3V_MCU`, so the ADC cannot measure its own reference. A
single meter reading of `+3.3V_MCU` and `+5V_MCU` would close that gap.

## Changes Recommended For The Next Revision
