# Bring-Up Log

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
- Sense resistor value populated (expect 0.15 Ω, **not** the block default 0.12 Ω):
- Solder issues:
- Rework:

## Power — sources and ORing

| Source powering the board | 3.3 V rail | `+5V` rail | Board responds to `ID` | Notes |
| --- | --- | --- | --- | --- |
| USB only | | 0 V expected | | |
| pyControl only (`D3` fitted?) | | 0 V expected | | |
| 36 V only | | | | |
| 36 V + USB | | | | |
| All available | | | | |

- ORing diode part and measured `Vf` at the actual logic current:
- Current measured flowing back into the USB host (expect 0):
- Current measured flowing back into pyControl (expect 0):
- Current into the dead `+5V` rail under USB-only power (expect ~0):
- `V5_SENSE` reading versus measured `+5V`:
- Firmware refuses 5 V-domain access when `+5V` is absent:
- Behavior when each source is plugged/unplugged while others are live:
- pyControl port 5 V current drawn by this board:

## Power — 36 V

- Input voltage / current limit used:
- Board boots with motor rail off, `HV_EN` low:
- Regulator chain confirmed fed pre-switch:
- Inrush:
- `HV_EN` assertion behavior, rail rise time:
- `ILIM` resistor value and measured current limit:
- `HV_SNS` reading versus measured load current:
- 5 V rail, measured:
- 3.3 V rail, measured:
- RP2040 core rail, measured:
- Rail ripple, motor idle:
- Rail ripple, motor moving:

### Transient headroom — the 36 V measurement that matters

Limits: 46 V operating, 49 V absolute with inductive load, 50 V bridge.

| Condition | Peak `VS` at the TMC5130A pins | Margin to 46 V |
| --- | --- | --- |
| Motion start | | |
| Motion stop | | |
| Deliberate stall | | |
| Power removal under load | | |

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
- SWD access:
- Clock verified:
- PIO encoder decode functional:

## pyControl Port

- Controller / breakout model and revision:
- Port designation used:
- Event lines landed on:
- BNC lines available versus needed across the whole rig:
- Cable type and length:
- UART levels measured, both directions:
- UART idle state:
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

Expected configuration: `R_SENSE` 0.15 Ω, `vsense = 1`, `IRUN = 28`, target
0.679 A RMS. A measured current near 1.23 A means `vsense` is 0 — stop.

- Motor part:
- Motor rated current per phase, and whether RMS or peak:
- Sense resistor populated:
- `vsense` read back from CHOPCONF (expect 1):
- `IRUN` set (expect 28):
- **Coil current measured, RMS** (expect 0.679 A):
- Driver config read back over SPI:
- `DIAG0` behavior:
- `DIAG1` behavior:
- Sense resistor temperature, standstill hold at current:
- Motion smoothness / audible behavior:
- Microstep smoothness at 163 mV sense signal:
- Step-rate ceiling achieved at 36 V, versus the same motor at 24 V if available:

## Encoder

- Encoder part:
- Interface: single-ended / differential:
- Supply voltage and measured current:
- Counts per revolution:
- TMC5130A count versus PIO count agreement:
- Index (`ENC_N`) behavior:
- Angle versus independent angular measurement:
- Deliberate mismatch raises `ENCODER_MISMATCH`:

## Homing

- Limit switch part:
- Debounce behavior observed:
- Synthetic `REFL` stimulus on `GP9` exercises homing:
- Real switch overrides the synthetic stimulus:
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
- Buffer `~OE` state at power-on, before firmware, confirmed high-Z:
- Firmware enables buffers at startup:
- Buffer state reported in `ID`/`STATUS`:
- All 18 signals present and correctly mapped:
- Signal integrity at the instrument:
- `AOUT*` confirmed unpopulated:
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
