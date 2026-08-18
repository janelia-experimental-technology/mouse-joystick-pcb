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

- Revision:
- **Serial / unit:**
- Joystick this unit is calibrated for:
- Assembly date:
- Assembler:
- Firmware commit / image hash:
- Protocol version:
- Notes:

## Inspection

- Visual inspection:
- Connector orientation:
- Unit identifier legible on silkscreen:
- Sense resistor value populated at `R1203`/`R1204` (expect 0.15 Ω, **not** the
  `kicad-libs` block default 0.12 Ω — a re-placed `tmc5130` block reverts them):
- Solder issues:
- Rework:

## Power — sources and ORing

| Source powering the board | `+3.3V_MCU` | `+5V_SW` | `+3.3V_SW` | Responds to `ID` | Notes |
| --- | --- | --- | --- | --- | --- |
| USB only | | 0 V expected | 0 V expected | | |
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
- **Back-power: `+3.3V_MCU` and `+3.3V_SW` measured with 36 V applied and both USB
  and pyControl unplugged** (expect 0 V on both; the `SN74LVC125A` has no `Ioff` and
  TI does not specify leakage at `VCC` = 0, so this is unspecified, not guaranteed):
- Firmware refuses 5 V-domain access when `+5V` is absent:
- Behavior when each source is plugged/unplugged while others are live:
- pyControl port 5 V current drawn by this board:

## Power — 36 V

- Input voltage / current limit used:
- Board boots with motor rail off, `HV_EN` low:
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
- `ILIM` resistor `R206` value and measured current limit:
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

- RP2040 boot behavior:
- USB CDC console:
- ~~SWD access:~~ **struck** — no SWD header and no reset button in Rev 0, by
  decision; `RUN`, `SWCLK` and `SWDIO` are unconnected and NC-flagged:
- Clock verified:
- ~~PIO encoder decode functional~~ **struck** — no PIO decode exists:

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
- All five of the above measured again with the switched domain **off** (expect
  0 V on every one):

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
- `J1102` pin order confirmed against the encoder's harness (board expects pin 1 =
  `GND`, pin 2 = reserved index **NC**, pin 3 = `ENC_A_RAW`, pin 4 = `+5V_SW`,
  pin 5 = `ENC_B_RAW`; supply sits between the two channels):
- Supply voltage and measured current (from `+5V_SW`, so the encoder resets with
  the switched domain):
- Counts per revolution:
- Maximum output frequency, versus the fitted RC corner of ~72 kHz
  (`R803`/`R804` 4.7 kΩ × `C802`/`C803` 470 pF, τ = 2.2 µs):
- TMC5130A `X_ENC` versus quadrature edges captured on `DIG0`/`DIG1`:
- ~~Index (`ENC_N`) behavior:~~ **struck** — there is no `ENC_N` net; TMC `ENCN` is
  tied to GND through `R1201` 10 kΩ and `J1102` pin 2 is a no-connect:
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

- DAC part and `VDD`:
- Level translation required, and part used:
- `~LDAC` synchronous update confirmed:
- Output at commanded 0 V:
- Output at commanded 5 V:
- Linearity across range:
- Latency from motion to output voltage, **measured from the InstrumentPort
  capture** (DAC bus, encoder, and analog output in one file):
- Output at boot, before firmware runs:
- Output when unhomed / disarmed / faulted:
- Update rate achieved:
- Behavior into the researcher's actual recording input:
- `AUX_ANALOG_OUT` populated, and what it carries:

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

- Adapter used:
- `J1501` cable orientation confirmed by continuity, pin-1 to pin-1:
- Buffer `~OE` state at power-on, before firmware, confirmed high-Z
  (`R1601`/`R1701`/`R1801`, 10 kΩ each to `+3.3V_MCU`):
- Firmware enables buffers at startup:
- Buffer state reported in `ID`/`STATUS`:
- All 11 Rev 0 Strands present and correctly mapped: `DIG0` `ENC_A_BUF`, `DIG1`
  `ENC_B_BUF`, `DIG2` `TMC_SPI_SCK_BUF`, `DIG3` `TMC_SPI_COPI_BUF`, `DIG4`
  `TMC_SPI_CIPO_BUF`, `DIG5` `~TMC_CS_BUF`, `DIG7` `PYC_UART_RX_BUF`, `DIG8`
  `PYC_UART_TX_BUF`, `DIG11` `LIMIT_SW_BUF`, `TRIG0` `FW_TRIG0_BUF`, `TRIG1`
  `FW_TRIG1_BUF`:
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

## Changes Recommended For The Next Revision
