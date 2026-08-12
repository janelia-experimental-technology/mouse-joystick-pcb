# Interface Map

**Status:** Draft allocation, not frozen
**Date:** 2026-08-12
**Board:** single-axis, RP2040, one TMC5130A
**Source profile:** `board-interfaces/docs/instrument-port-40.md`

This document records this board's RP2040 GPIO allocation and its use of
InstrumentPort-40. The InstrumentPort-40 profile itself belongs in
`board-interfaces` and is not redefined here.

## One Axis Removes The Pin Pressure

The twin-axis board (`../mouse-joysticks-pcb`) fits two axes into 28 of RP2040's
30 GPIOs only after cutting the encoder index, the synthetic homing stimulus,
`DIAG1`, and software control of the DAC's `~LDAC` and `~CLR`.

One axis needs **29 of 30**, with everything the twin board cut restored plus a
`+5V` presence sense and the input switch's fault and current-sense outputs, and
leaves **1 spare**. There is no descope in this allocation, and a documented
reclaim order exists if that changes.

That is the single largest reason this board is faster to build: no GPIO budget
argument, no descope table, no fallback plan for finding two more pins.

## RP2040 GPIO Allocation

Checked against RP2040 peripheral pin muxing. `UART0` is the pyControl link,
`SPI0` serves the TMC5130A, `SPI1` serves the DAC. Chip selects are plain GPIO,
not hardware `CSn` — RP2040's PL022 hardware chip select does not hold `CS` low
across the TMC5130A's 40-bit multi-byte datagrams.

The `rp2040` design block exposes these as labels `GPIO0` … `GPIO25` and
`GPIO26_ADC0` … `GPIO29_ADC3`.

| GPIO | Net | Function | Mux note |
| --- | --- | --- | --- |
| `GP0` | `PYC_UART_TX` | UART TX to pyControl | `UART0 TX` |
| `GP1` | `PYC_UART_RX` | UART RX from pyControl | `UART0 RX` |
| `GP2` | `~{TMC_CS}` | Driver chip select | GPIO |
| `GP3` | `~{TMC_DRV_EN}` | Driver enable, active low | GPIO |
| `GP4` | `TMC_SPI_CIPO` | Driver SPI MISO | `SPI0 RX` |
| `GP5` | `TMC_DIAG0` | Driver diagnostic 0 | GPIO |
| `GP6` | `TMC_SPI_SCK` | Driver SPI clock | `SPI0 SCK` |
| `GP7` | `TMC_SPI_COPI` | Driver SPI MOSI | `SPI0 TX` |
| `GP8` | `TMC_DIAG1` | Driver diagnostic 1 | GPIO |
| `GP9` | `TMC_REF_STIM` | Synthetic reference stimulus into `REFL` | GPIO |
| `GP10` | `DAC_SPI_SCK` | DAC SPI clock | `SPI1 SCK` |
| `GP11` | `DAC_SPI_COPI` | DAC SPI MOSI | `SPI1 TX` |
| `GP12` | `~{DAC_LDAC}` | DAC synchronous load | GPIO |
| `GP13` | `~{DAC_CS}` | DAC chip select (`~SYNC`) | GPIO |
| `GP14` | `ENC_A` | Encoder A | PIO, contiguous with `GP15`/`GP16` |
| `GP15` | `ENC_B` | Encoder B | PIO |
| `GP16` | `ENC_N` | Encoder index | PIO |
| `GP17` | `~{DAC_CLR}` | DAC clear | GPIO |
| `GP18` | `LIMIT_SW` | Limit switch, MCU copy | GPIO |
| `GP19` | `HV_EN` | 36 V input switch enable | GPIO |
| `GP20` | `PYC_PULL_EVENT` | Pull event out | GPIO |
| `GP21` | `FW_TRIG1` | Firmware timing marker | GPIO |
| `GP22` | `PYC_FAULT` | Latched fault out | GPIO |
| `GP23` | `PYC_RSYNC_IN` | Rsync edges in | GPIO |
| `GP24` | `~{INSTR_BUF_OE}` | Instrumentation buffer enable | GPIO |
| `GP25` | `FW_TRIG0` | Firmware timing marker | GPIO |
| `GP26` | `V5_SENSE` | `+5V` rail presence and level, via divider | `ADC0` |
| `GP27` | spare | Reserved — `EXT_FAULT_IN` candidate, see below | `ADC1` |
| `GP28` | `HV_SNS` | 36 V input load-current sense, `R_SNS` = 249 Ω | `ADC2` |
| `GP29` | `~{HV_FAULT}` | 36 V switch fault, open-drain, pull-up to 3.3 V | `ADC3` |

**29 used, 1 spare** (`GP27`). If `EXT_FAULT_IN` is fitted there, none remain.

`DIAG_EN` on the input block's switch is **tied to `+3.3V`, not to a GPIO** —
diagnostics have no reason to be gated, and tying it costs no pin. Without it
neither `HV_SNS` nor `~{HV_FAULT}` works at all; see `docs/power.md`.

### Reclaim Order If More Pins Are Needed

Documented so a late change does not have to re-derive it, in order of least loss
first:

1. **Tie `~{DAC_CLR}` high in hardware**, freeing `GP17`. Costs software clear;
   the twin-axis board already accepts this. Mandatory anyway if a 4-bit level
   translator is fitted.
2. **Drop `TMC_REF_STIM`**, freeing `GP9`. Costs synthetic homing stimulus, a
   development convenience. The twin board cut this too. Leave a test pad on the
   `REFL` net so a jumper can still simulate a switch closure.
3. **Drop `TMC_DIAG1`**, freeing `GP8`. `DIAG0` alone, configured to report what
   matters. Route `DIAG1` to a test point.

Do not reclaim by moving an encoder pin — `GP14`/`GP15`/`GP16` contiguity is
worth more than any of the above.

Notes:

- `GP23`, `GP24`, and `GP25` are free on the bare RP2040 QFN-56. They are
  reserved on Raspberry Pi Pico modules but not on a custom board.
  `tmc51x0-driver-dev-pcb` already uses `GP23` this way.
- `GP14`/`GP15`/`GP16` are contiguous so one PIO state machine reads A, B, and
  the index with a single input mapping. **Preserve that contiguity if the
  allocation is edited.**
- The encoder also connects directly to the TMC5130A `ENCA`/`ENCB`/`ENCN` pins.
  The PIO decode is an independent second count, and the disagreement between
  them is the `ENCODER_MISMATCH` fault.
- The limit switch also connects directly to the TMC5130A `REFL` pin. `REFL`
  is the hardware-latched homing path; `GP18` is the MCU's independent copy.
- `GP9` drives the `REFL` net through a series resistor so homing can be tested
  without touching the real switch. Keep the drive weak enough that the real
  switch always wins.
- `GP19` drives the `hv_input_36V_terminal_2pos_5p08_protected` block's `ENABLE`
  input. That block pulls `ENABLE` low, so the 36 V rail is **off until firmware
  drives it**. See `docs/power.md`.
- `GP28` reads the TPS1HTC100-Q1 `SNS` output. **Change the block's `R_SNS` from
  1 kΩ to 249 Ω** (`OW-PASS-CRCW0402249RFKED`, stocked) — the pin signals faults by
  sourcing 5.2-6.4 mA into `R_SNS`, which at 1 kΩ lands at 3.3-4.4 V, above the
  RP2040's `VDD + 0.3 V` limit. At 249 Ω the fault level is 1.29-1.59 V and current
  reads 0.311 V/A. No divider needed. See `docs/power.md`.
- `GP29` reads the switch's `~FAULT` open-drain output: overload, short-circuit,
  and thermal shutdown. Needs an external pull-up to `+3.3V`. The design block
  leaves this pin unconnected; this board routes it because it has the pin and
  because the motor rail can shut itself off.
- `GP26` senses the `+5V` rail through a divider. The board can be powered from
  USB or pyControl with the 36 V supply absent, in which case `+5V` is dead while
  the MCU is running. Firmware must not drive the DAC or any other 5 V-domain
  input in that state. See `docs/power.md`.
- If the DAC needs a 4-bit level translator (see `docs/encoder-analog-output.md`),
  `~{DAC_CLR}` is tied high in hardware instead and `GP17` becomes a second spare.

### `EXT_FAULT_IN` — Decide Before Layout

If the rig runs **two** of these boards, one board's fault should be able to stop
the other without depending on the pyControl task to notice. Reserving `GP27` as
`EXT_FAULT_IN` and bringing it out — cross-wired to the other board's `FAULT`
output, or to a rig-level disable line — costs one GPIO and one connector
position, and reports as fault bit 8 `EXT_STOP`.

This is cheap now and a flying wire later. See the cross-board fault discussion in
`docs/pycontrol-interface.md`. If it is fitted, put it on a screw terminal or a
keyed 2-pin header, not a bare pad.

### Peripheral Summary

| Peripheral | Use | Pins |
| --- | --- | --- |
| `UART0` | pyControl link, 115200 8N1 | `GP0`, `GP1` |
| `SPI0` | TMC5130A | `GP6` SCK, `GP7` TX, `GP4` RX, `GP2` CS as GPIO |
| `SPI1` | DAC8563, write-only | `GP10` SCK, `GP11` TX, `GP13` CS as GPIO |
| PIO0 SM0 | Encoder A/B/N quadrature decode | `GP14`-`GP16` |
| ADC | `V5_SENSE`, `HV_SNS`, `~{HV_FAULT}` as digital, one spare | `GP26`-`GP29` |
| USB | Debug console, CDC | dedicated USB pins |
| QSPI | External flash | dedicated QSPI pins |

There is no second UART. The debug console is **USB CDC**, because `UART0`
belongs to pyControl. That constraint is unchanged from the twin-axis board even
though this board has pins to spare — a second physical UART is not worth a
connector and a cable when USB is already present.

## InstrumentPort-40 Overlay

The profile provides 18 digital slots (`DIG0`-`DIG15`, `TRIG0`, `TRIG1`), two
differential analog inputs, and two analog outputs. Pin numbers below are the
DUT-side connector pins from the v0.3 profile.

On a single-axis board the signal count fits the profile almost exactly: **18
signals for 18 slots**, with none of the twin board's crowding.

| DUT pin | Strand | Board signal | Why |
| --- | --- | --- | --- |
| 2 | `DIG0(I2C_SCL)` | `PYC_UART_TX` | Host link, both directions, is the primary record |
| 3 | `DIG1(I2C_SDA)` | `PYC_UART_RX` | |
| 5 | `DIG2(SPI_SCK)` | `TMC_SPI_SCK` | Driver transactions; correctness and fault diagnosis |
| 7 | `DIG3(SPI_MOSI)` | `TMC_SPI_COPI` | |
| 8 | `DIG4(SPI_MISO)` | `TMC_SPI_CIPO` | |
| 10 | `DIG5(SPI_CS0)` | `~{TMC_CS}` | Frames each driver transaction |
| 11 | `DIG6(SPI_CS1)` | `~{DAC_CS}` | Frames each DAC write |
| 13 | `DIG7` | `ENC_A` | Joystick motion |
| 14 | `DIG8` | `ENC_B` | |
| 16 | `DIG9` | `ENC_N` | Index; homing and count-integrity checks |
| 17 | `DIG10` | `DAC_SPI_SCK` | Lets a capture recover the commanded angle code |
| 19 | `DIG11` | `DAC_SPI_COPI` | |
| 20 | `DIG12` | `PYC_PULL_EVENT` | Behavioral event |
| 22 | `DIG13` | `PYC_FAULT` | Fault, experiment-critical |
| 23 | `DIG14` | `PYC_RSYNC_IN` | Time alignment; places everything else in pyControl time |
| 24 | `DIG15` | `LIMIT_SW` | Homing witness |
| 26 | `TRIG0` | `FW_TRIG0` | Firmware timing marker |
| 28 | `TRIG1` | `FW_TRIG1` | Firmware timing marker |
| 32/33 | `AIN0_P` / `AIN0_N` | `ANGLE_OUT` at the BNC centre / `AGND` | Verifies the researcher-facing BNC against the encoder in one capture |
| 35/36 | `AIN1_P` / `AIN1_N` | `AUX_ANALOG_OUT` at its pad / `AGND` | DAC channel B, spare |
| 38, 39 | `AOUT0`, `AOUT1` | **No-connect** | No stimulus path into a board used with animals |
| 1, 4, 6, 9, 12, 15, 18, 21, 25, 27, 29, 30 | `GND` | Digital return | Per profile |
| 31, 34, 37, 40 | `AGND` | Analog return | Per profile |

**Why the DAC bus earns two slots here and does not on the twin board.** The
0-5 V angle output is the researcher's primary deliverable and the first thing
that will be doubted. With `DAC_SPI_SCK`, `DAC_SPI_COPI`, `~{DAC_CS}`, the
encoder channels, and the analog output itself all in one capture, "does the
voltage match the encoder?" is answerable from a single file with no firmware
cooperation. On the twin board those slots go to the second axis instead.

`TMC_DIAG0` did not earn a slot because a driver fault reaches the capture
through `PYC_FAULT` anyway, one firmware latency later. It goes to a test point.

Dropped to labelled test points — 8 signals: `TMC_DIAG0`, `TMC_DIAG1`,
`~{TMC_DRV_EN}`, `TMC_REF_STIM`, `~{DAC_LDAC}`, `~{DAC_CLR}`, `HV_EN`,
`~{INSTR_BUF_OE}`. Also bring `HV_SNS` and the TMC `SWSEL` strap to pads.

Provide labelled test points, not bare vias.

### AIN Assignment Keeps 36 V Off The Connector

`AIN1_P/N` observes the second DAC channel rather than a divided-down motor
rail. A resistive divider from a 36 V rail into an instrument input is a
plausible-looking way to destroy an ADALM2000 if a resistor is misplaced or a
divider node is probed while the rail is live.

Motor-supply monitoring uses the onboard ADC instead: `GP28` for load current
through the smart switch's `SNS` pin, and `GP26` reserved for a rail-voltage
divider if one is wanted. Both stay inside the board's own 3.3 V domain.

## Digital Instrumentation Buffering

Every `DIG*` and `TRIG*` signal above is buffered with
`orb_weaver_private:instrumentation_signal_buffer_sn74lvc125a`
(`SN74LVC125A`, `OW-MISC-SN74LVC125ARGYR`), already composed five times into
`tmc51x0-driver-dev-pcb`.

- `VCC = 3.3 V`. The catalog part's absolute maximum supply is 3.6 V.
- Unidirectional, board-side to instrument-side only. `PYC_UART_RX` and
  `PYC_RSYNC_IN` are inputs to this board; they are *tapped* and buffered
  outward. The buffer never drives back into the pyControl cable.
- The block provides ~33 Ω series source termination on each output.
- 18 signals at 4 channels per package = **5 packages**, 2 channels spare.

Group by physical zone so each package sits near its signals:

| Package | Channels | Zone |
| --- | --- | --- |
| `U_A` | `DIG2`, `DIG3`, `DIG4`, `DIG5` | TMC SPI bus and chip select |
| `U_B` | `DIG6`, `DIG10`, `DIG11`, + 1 spare | DAC group |
| `U_C` | `DIG7`, `DIG8`, `DIG9`, `DIG15` | Encoder and limit switch |
| `U_D` | `DIG0`, `DIG1`, `DIG12`, `DIG13` | pyControl connector group |
| `U_E` | `DIG14`, `TRIG0`, `TRIG1`, + 1 spare | Sync and firmware markers |

All five `~OE` nets tie into one board-wide `~{INSTR_BUF_OE}` driven by `GP24`.

**Enable default:** the block pulls `~OE` up, so buffers are high-Z until
firmware enables them. That is the right power-on default. Firmware should
enable them during normal startup and report buffer state in `ID`/`STATUS`, so a
session never silently produces no data. See `docs/instrument-strategy.md`.

## Connector Complement

| Ref | Connector | Carries |
| --- | --- | --- |
| `J1` | 2-pos 5.08 mm pluggable terminal, Phoenix `1757242` | 36 V motor supply in |
| `J2` | USB-C receptacle (`usb2` block) | Firmware load, USB CDC debug console, and a logic-rail power source |
| `J3` | RJ-45, `OW-CONN-J1B1211CCD` or `OW-CONN-438600001` | pyControl behavior port: UART + GND, and optionally 5 V on pin 6 |
| `J4` | 40-pin 0.5 mm FFC, `OW-CONN-5051104091` | InstrumentPort-40 |
| `J5` | Motor connector, locking, 4-pos | Stepper coils |
| `J6` | Joystick harness, locking | Encoder A/B/N (+/-), encoder supply, limit switch, return |
| `J7` | Dual BNC, `DOSIN-801-0095` | `ANGLE_OUT` (DAC ch A), `AUX_ANALOG_OUT` (DAC ch B) |
| `J8` | Dual BNC, `DOSIN-801-0095` | `PYC_PULL_EVENT`, `PYC_FAULT` |
| `J9` | Dual BNC, `DOSIN-801-0095` | `PYC_RSYNC_IN`, spare |
| `J10` | SWD header | Debug |

`J7` sits in the analog zone; `J8` and `J9` sit in the digital zone. Do not put
an analog output and a digital event line in the same connector body.

**This resolves the twin board's blocking question in miniature.** Both DIO lines
on the assigned pyControl port are consumed by the UART, so the event lines have
to land somewhere else. One axis needs three of them — `PULL_EVENT`, `FAULT`,
`RSYNC` — not four, and three BNCs plus one analog BNC is a connector complement
that fits a small board. If area gets tight, `J9` is the one to cut: land
`RSYNC` on a 2-pin header and accept an adapter cable.

## What Carries Forward To The Twin-Axis Board

If this board is later superseded by `../mouse-joysticks-pcb`, these carry over
unchanged:

- the pyControl port pinout and signal set;
- the UART protocol, with an axis argument added;
- the analog output design and its calibration semantics;
- the InstrumentPort-40 buffering pattern and the enable default;
- the power chain, sized for one motor instead of two.

What does not carry over: this GPIO table and this instrument overlay. The twin
board re-derives both, and its overlay is already written.
