# Interface Map

**Status:** Rev 0 scope frozen for allocation, not for layout
**Date:** 2026-08-13
**Board:** single-axis, RP2040, one TMC5130A
**Source profile:** `board-interfaces/docs/instrument-port-40.md` (rev 1+ only)

This document records this board's RP2040 GPIO allocation. It covers **two
scopes at once**: what Rev 0 populates, and the full scope that later revisions
grow into. The InstrumentPort-40 profile itself belongs in `board-interfaces` and
is not redefined here.

## Rev 0 Is A Strict Subset

Rev 0 was scaled back to get testable hardware in the researcher's hands sooner.
See `docs/rev0-plan.md` for what it contains and why.

The allocation below is written so that **no pin moves between Rev 0 and full
scope**. Rev 0 populates 17 of the 29 allocated GPIOs; the other 12 are reserved,
routed nowhere, and become live in later revisions without disturbing anything
Rev 0 established. Firmware written against Rev 0 keeps working.

That property is not free, and it cost exactly one trade — see
[The Bus Switch Costs A Pin](#the-bus-switch-costs-a-pin).

## RP2040 GPIO Allocation

Checked against RP2040 peripheral pin muxing. `UART0` is the pyControl link,
`SPI0` serves the TMC5130A, `SPI1` is reserved for the rev 1 DAC. Chip selects
are plain GPIO, not hardware `CSn` — RP2040's PL022 hardware chip select does not
hold `CS` low across the TMC5130A's 40-bit multi-byte datagrams.

The `rp2040` design block exposes these as labels `GPIO0` … `GPIO25` and
`GPIO26_ADC0` … `GPIO29_ADC3`.

**Iso** column: `sw` = routed through the `rp2040_gpio_isolation_sn74cb3q3245`
bus switch; `byp` = bypasses it and connects to the MCU directly. **The rule is
the powered domain of the far end**, not convenience — see
[GPIO Isolation](#gpio-isolation).

| GPIO   | Net               | Function                                        | Rev 0    | Iso   |
|--------|-------------------|-------------------------------------------------|----------|-------|
| `GP0`  | `PYC_UART_TX`     | UART TX to pyControl (`UART0 TX`)               | **yes**  | `byp` |
| `GP1`  | `PYC_UART_RX`     | UART RX from pyControl (`UART0 RX`)             | **yes**  | `byp` |
| `GP2`  | `~{TMC_CS}`       | Driver chip select                              | **yes**  | `sw`  |
| `GP3`  | `~{TMC_DRV_EN}`   | Driver enable, active low                       | **yes**  | `sw`  |
| `GP4`  | `TMC_SPI_CIPO`    | Driver SPI MISO (`SPI0 RX`)                     | **yes**  | `sw`  |
| `GP5`  | `TMC_DIAG0`       | Driver diagnostic 0                             | **yes**  | `sw`  |
| `GP6`  | `TMC_SPI_SCK`     | Driver SPI clock (`SPI0 SCK`)                   | **yes**  | `sw`  |
| `GP7`  | `TMC_SPI_COPI`    | Driver SPI MOSI (`SPI0 TX`)                     | **yes**  | `sw`  |
| `GP8`  | `TMC_DIAG1`       | Driver diagnostic 1                             | **yes**  | `sw`  |
| `GP9`  | `~{BUS_SW_OE}`    | GPIO isolation enable, active low               | **yes**  | `byp` |
| `GP10` | `DAC_SPI_SCK`     | DAC SPI clock (`SPI1 SCK`)                      | reserved | `sw`  |
| `GP11` | `DAC_SPI_COPI`    | DAC SPI MOSI (`SPI1 TX`)                        | reserved | `sw`  |
| `GP12` | `~{DAC_LDAC}`     | DAC synchronous load                            | reserved | `sw`  |
| `GP13` | `~{DAC_CS}`       | DAC chip select (`~SYNC`)                       | reserved | `sw`  |
| `GP14` | `ENC_A`           | Encoder A, PIO cross-check                      | reserved | `sw`  |
| `GP15` | `ENC_B`           | Encoder B, PIO cross-check                      | reserved | `sw`  |
| `GP16` | `ENC_N`           | Encoder index, PIO cross-check                  | reserved | `sw`  |
| `GP17` | `~{DAC_CLR}`      | DAC clear                                       | reserved | `sw`  |
| `GP18` | `LIMIT_SW`        | Debounced limit switch, MCU copy                | **yes**  | `sw`  |
| `GP19` | `HV_EN`           | 36 V input switch enable                        | **yes**  | `byp` |
| `GP20` | `PYC_PULL_EVENT`  | Pull event out                                  | reserved | `byp` |
| `GP21` | `FW_TRIG1`        | Firmware timing marker                          | **yes**¹ | `byp` |
| `GP22` | `PYC_FAULT`       | Latched fault out                               | reserved | `byp` |
| `GP23` | `PYC_RSYNC_IN`    | Rsync edges in                                  | reserved | `byp` |
| `GP24` | `~{INSTR_BUF_OE}` | Instrumentation buffer enable                   | reserved | `byp` |
| `GP25` | `FW_TRIG0`        | Firmware timing marker                          | **yes**¹ | `byp` |
| `GP26` | `V5_SENSE`        | `+5V_SW` presence and level, via divider        | **yes**  | `byp` |
| `GP27` | spare             | Reserved — `EXT_FAULT_IN` candidate, see below  | spare    | —     |
| `GP28` | `HV_SNS`          | 36 V input load-current sense, `R_SNS` = 249 Ω  | **yes**  | `byp` |
| `GP29` | `~{HV_FAULT}`     | 36 V switch fault, open-drain, pull-up to 3.3 V | **yes**  | `byp` |

¹ Rev 0 lands `FW_TRIG0`/`FW_TRIG1` on labelled test points. With no
InstrumentPort they have nowhere else to go, and they are the cheapest bring-up
instrumentation on the board.

**Rev 0: 17 connected, 12 reserved, 1 spare.**
**Full scope: 29 connected, 1 spare (`GP27`).**

`DIAG_EN` on the input block's switch is **tied to `+3.3V`, not to a GPIO** —
diagnostics have no reason to be gated, and tying it costs no pin. Without it
neither `HV_SNS` nor `~{HV_FAULT}` works at all; see `docs/power.md`.

### The Bus Switch Costs A Pin

Rev 0 adds the `rp2040_gpio_isolation_sn74cb3q3245` block, whose shared
active-low enable needs one GPIO. The previous allocation was already at 29 of 30
with a single spare, so the enable had to come from somewhere.

It is paid for by **permanently dropping `TMC_REF_STIM`**, the synthetic homing
stimulus that used to sit on `GP9`. That was already item 2 in the reclaim order
below, and it is the right one to spend: the limit switch now reaches `REFL`
through a real debouncer on its own terminal block, so homing is exercised by
closing the actual switch rather than by a GPIO impersonating one. Leave a test
pad on the `REFL` net so a jumper can still force a closure.

Net effect: **the trade is one-for-one and the map still ends at 29 of 30 with
`GP27` spare.** Without it, full scope would be 30 of 30 with nothing left and
`EXT_FAULT_IN` would be impossible.

### Reclaim Order If More Pins Are Needed

Item 2 of the previous list has been spent on `~{BUS_SW_OE}`. What remains, least
loss first:

1. **Tie `~{DAC_CLR}` high in hardware**, freeing `GP17`. Costs software clear;
   the twin-axis board already accepts this. Mandatory anyway if a 4-bit level
   translator is fitted. Rev 1 concern only.
2. **Drop `TMC_DIAG1`**, freeing `GP8`. `DIAG0` alone, configured to report what
   matters. Route `DIAG1` to a test point.

Do not reclaim by moving an encoder pin — `GP14`/`GP15`/`GP16` contiguity is
worth more than either of the above, even though Rev 0 does not use them.

Notes:

- `GP23`, `GP24`, and `GP25` are free on the bare RP2040 QFN-56. They are
  reserved on Raspberry Pi Pico modules but not on a custom board.
  `tmc51x0-driver-dev-pcb` already uses `GP23` this way.
- `GP14`/`GP15`/`GP16` are contiguous so one PIO state machine can read A, B, and
  the index with a single input mapping. **Preserve that contiguity if the
  allocation is edited**, including while they are unpopulated.
- **Rev 0 routes the encoder to the TMC5130A only.** `ENCA`/`ENCB`/`ENCN` go
  straight from the 5-pin encoder connector to the driver. The PIO cross-check
  and the `ENCODER_MISMATCH` fault that depends on it are rev 1 features; see
  [What Rev 0 Gives Up](#what-rev-0-gives-up).
- The limit switch reaches the TMC5130A `REFL` pin through the debouncer.
  `REFL` is the hardware-latched homing path; `GP18` is the MCU's independent
  copy, taken from the same debounced node.
- `GP19` drives the `hv_input_36V_terminal_2pos_5p08_protected` block's `ENABLE`
  input. That block pulls `ENABLE` low, so the 36 V rail is **off until firmware
  drives it** — and so the board's power-on state is the idle state, with the MCU
  up on USB or pyControl and everything switched dark. Firmware cycling `GP19` is
  also the board's chip-reset mechanism; see `docs/power.md`.
- `GP28` reads the TPS1HTC100-Q1 `SNS` output. **Change the block's `R_SNS` from
  1 kΩ to 249 Ω** (`OW-PASS-CRCW0402249RFKED`, stocked) — the pin signals faults by
  sourcing 5.2-6.4 mA into `R_SNS`, which at 1 kΩ lands at 3.3-4.4 V, above the
  RP2040's `VDD + 0.3 V` limit. At 249 Ω the fault level is 1.29-1.59 V and current
  reads 0.311 V/A. No divider needed. See `docs/power.md`.
- `GP29` reads the switch's `~FAULT` open-drain output: overload, short-circuit,
  and thermal shutdown. Needs an external pull-up to `+3.3V`. The design block
  leaves this pin unconnected; this board routes it because it has the pin and
  because the motor rail can shut itself off.
- `GP26` senses `+5V_SW` through a divider. That rail is dead whenever `HV_EN` is
  low or the 36 V supply is absent, which is the board's normal idle state, so
  this is the MCU's primary evidence that the switched domain is actually up.
  It gates step 3 of the sequencing rule above. `+5V_SW` is still required in
  Rev 0 — the TMC5130A's `VCC` minimum is 4.6 V — even though the DAC that also
  needed it is deferred. See `docs/power.md`.

### `EXT_FAULT_IN` — Still Deferred, Still Cheap

If the rig runs **two** of these boards, one board's fault should be able to stop
the other without depending on the pyControl task to notice. Reserving `GP27` as
`EXT_FAULT_IN` and bringing it out — cross-wired to the other board's `FAULT`
output, or to a rig-level disable line — costs one GPIO and one connector
position, and reports as fault bit 8 `EXT_STOP`.

Rev 0 has no `FAULT` output to cross-wire, so this is a rev 1 decision that
arrives with the pyControl event lines. `GP27` stays unallocated until then. See
the cross-board fault discussion in `docs/pycontrol-interface.md`.

### Peripheral Summary

| Peripheral | Use | Pins | Rev 0 |
| --- | --- | --- | --- |
| `UART0` | pyControl link, 115200 8N1 | `GP0`, `GP1` | yes |
| `SPI0` | TMC5130A | `GP6` SCK, `GP7` TX, `GP4` RX, `GP2` CS as GPIO | yes |
| `SPI1` | DAC8563, write-only | `GP10` SCK, `GP11` TX, `GP13` CS as GPIO | rev 1 |
| PIO0 SM0 | Encoder A/B/N quadrature decode | `GP14`-`GP16` | rev 1 |
| ADC | `V5_SENSE`, `HV_SNS`, `~{HV_FAULT}` as digital, one spare | `GP26`-`GP29` | yes |
| USB | Debug console, CDC | dedicated USB pins | yes |
| QSPI | External flash | dedicated QSPI pins | yes |

There is no second UART. The debug console is **USB CDC**, because `UART0`
belongs to pyControl. In Rev 0 that matters more than it used to: with no
InstrumentPort and no event BNCs, USB CDC is the only rich observation path the
board has.

## GPIO Isolation

Rev 0 places `orb_weaver_private:rp2040_gpio_isolation_sn74cb3q3245` between the
RP2040 and the switched half of the board. It is four `SN74CB3Q3245` 8-channel
bidirectional FET bus switches — 32 channels, one shared active-low `~OE`, pulled
up so the bus is **isolated at power-on until firmware enables it**, with
powered-off `Ioff` isolation as a second line of defence.

### The Rule: Follow The Far End's Power Domain

The `TPS1HTC100-Q1` high-side switch exists so the researcher can power-cycle the
board's chips to a known state without unplugging anything, while the MCU stays
alive on USB or pyControl. See `docs/power.md`. That makes "MCU running, switched
rails at 0 V" the board's **normal idle state**, not an edge case — and an MCU pin
driving into an unpowered chip forward-biases its input ESD clamps and
back-powers a dead rail through them.

The bus switch exists to prevent exactly that, which gives a single mechanical
rule:

> **A GPIO goes through the bus switch if and only if its far end sits on the
> switched domain** (`+36V_SW`, `+5V_SW`, `+3V3_SW`). Everything else bypasses.

| Iso | Applies to | Because |
| --- | --- | --- |
| `sw` | TMC5130A SPI, enable, and diagnostics; the MAX6816 debouncer's output copy; the encoder PIO tap and DAC bus in rev 1 | All of them are parts that lose power when `HV_EN` drops |
| `byp` | pyControl UART; the pyControl TTL event lines; `HV_EN`, `HV_SNS`, `~{HV_FAULT}`; `V5_SENSE`; `FW_TRIG0`/`FW_TRIG1`; `~{BUS_SW_OE}`; `~{INSTR_BUF_OE}` | Nothing at the far end is ever unpowered by `HV_EN` |

**Rev 0 isolates 8 channels; full scope isolates 16.** The bypass group is 13 at
full scope, which is larger than a first pass suggests, and each entry earns it:

| Net | Why it bypasses |
| --- | --- |
| `PYC_UART_TX`, `PYC_UART_RX` | The whole point of the architecture. pyControl is externally powered and must stay reachable when the switched domain is off — that is how the researcher talks to a board that is deliberately powered down |
| `~{BUS_SW_OE}` | Circular otherwise — the enable cannot be behind the switch it enables |
| `HV_EN` | The `TPS1HTC100-Q1` runs from `HV_IN` and is never switched off. Rail control must not depend on bus state, and the MCU must be able to switch the rail back on while everything downstream is dark |
| `HV_SNS`, `~{HV_FAULT}` | Same device, same always-on supply, and their pull-ups sit on `+3V3_MCU`. Fault status must be readable precisely when the rail is off |
| `V5_SENSE` | It reports whether `+5V_SW` came up, which is the precondition for enabling the bus. Reading it through the bus would be circular |
| `FW_TRIG0`, `FW_TRIG1` | Test points only — no chip at the far end — and they must stay observable while the bus is isolated |
| `PYC_PULL_EVENT`, `PYC_FAULT`, `PYC_RSYNC_IN` (rev 1) | BNC connectors and pyControl, both outside the switched domain |
| `~{INSTR_BUF_OE}` (rev 1) | The `SN74LVC125A` buffers sit on `+3V3_MCU` so the board can be observed while the switched domain is off |

`tmc51x0-driver-dev-pcb` bypasses the same *kind* of set — its netlist shows
`~{BUS_SW_OE}` on `GPIO19`, `~{INSTR_BUF_OE}` on `GPIO23`, and `HV_EN` and both
`FW_TRIG` markers wired straight to the MCU, with 27 GPIO nets through the switch.
**This board bypasses considerably more**, because it has a genuinely two-domain
power tree and that board does not. Do not "align" the two.

**This board puts `~{BUS_SW_OE}` on `GP9`, not `GP19`.** The proven board uses
`GP19` because it has no 36 V enable there; here `GP19` is `HV_EN` and is already
wired into `mcu.kicad_sch`. Deliberate divergence, noted so nobody "fixes" it.

### The Block Is Oversized For This Board — Accepted

The block is four packages because it is built to isolate all 30 GPIOs. Under the
rule above this board isolates **8 in Rev 0 and 16 at full scope**, so three of
the four `SN74CB3Q3245` packages are dead weight in Rev 0 and two are at full
scope.

| Option | Cost | Benefit |
| --- | --- | --- |
| **A.** Place the block whole, wire 16 channels, leave 16 unused | 3 unnecessary ICs, their decoupling, and the board area | Proven block, zero design work, obvious upgrade path |
| **B.** Board-local section with two `SN74CB3Q3245` | Two ICs, a new schematic section to verify | Half the parts and area; matches what the board actually needs |

**Decided 2026-08-13: option A.** Place the proven block whole and leave 16 of
its 32 channels unused. Two `SN74CB3Q3245` packages and their decoupling are
wasted, and that is accepted — the block is already placed, already proven, and
Rev 0 is optimising for schedule. Option B remains the right answer for a later
revision if board area becomes the binding constraint.

Either way, wire the **A (MCU) side of all 16 isolated GPIOs now**, including the
8 reserved for rev 1, and leave the B side of the reserved channels unconnected.
A later revision then adds board-side wiring only — no re-place, no re-pin, no
firmware change. Leave bypass-group signals off the switch entirely.

### The Bus Switch Runs From `+3V3_MCU`

It has to. Powering it from `+3V3_SW` would give free isolation through `Ioff`
whenever `HV_EN` is low and would cost no GPIO at all — but it would hand the
sequencing to a rail ramp instead of to firmware, and it would remove the ability
to isolate *before* switching off. Rejected deliberately; recorded in
`docs/power.md` so it is not rediscovered as a clever idea.

### Sequencing Rule

Falls straight out of the architecture, and firmware must follow it:

**Powering the switched domain down**

1. Assert `~{BUS_SW_OE}` high — isolate first.
2. Drive `HV_EN` low.

**Powering it back up**

1. Drive `HV_EN` high.
2. Wait for the buck and LDO to settle.
3. Confirm `+5V_SW` is up on `V5_SENSE` — which is readable because it bypasses.
4. Assert `~{BUS_SW_OE}` low — connect last.

Isolating first and connecting last means no MCU pin is ever driving a rail that
is on its way down or not yet up. Getting this backwards is the failure this
whole arrangement exists to prevent, so **test it at Gate B** with a scope on
`+3V3_SW` and one TMC input.

### Firmware Consequences

Properties of the hardware, not choices:

- **The pyControl link works with the bus isolated.** `GP0`/`GP1` bypass, so the
  board answers `ID`/`STATUS` in its idle state and can report *why* the motor
  rail is off. This is the behaviour the architecture is for.
- **The USB CDC console is likewise unaffected** — USB uses dedicated pins, not
  the GPIO matrix.
- **The power-monitoring group is readable at all times.** `V5_SENSE`, `HV_SNS`,
  and `~{HV_FAULT}` all bypass, so firmware can diagnose the switched domain
  without enabling anything. The earlier boot-order awkwardness is gone.
- **Nothing on the switched domain is reachable until the bus is enabled.** SPI
  to the driver, the debounced limit-switch copy on `GP18`, and in rev 1 the
  encoder tap and DAC. Firmware must treat a read from any of them as invalid
  while `~{BUS_SW_OE}` is high rather than returning stale or floating data.
- **`GP18` floats while isolated.** Enable an internal pull on it so the MCU's
  limit-switch copy has a defined level in the idle state.
- Report both `~{BUS_SW_OE}` and `HV_EN` state in `ID`/`STATUS`. A session that
  silently runs isolated should be impossible to mistake for a working one.

## Connector Complement

Designators are assigned for the **full** scope and Rev 0 populates a subset.
Gaps in the sequence are deliberate: renumbering later would break the silkscreen,
the documentation, and the bring-up log for no benefit.

| Ref | Connector | Carries | Rev 0 |
| --- | --- | --- | --- |
| `J1` | 2-pos 5.08 mm pluggable terminal, Phoenix `1757242` (`OW-CONN-1757242`) | 36 V motor supply in | **yes** |
| `J2` | USB-C receptacle (`usb2` block) | Firmware load, USB CDC console, logic-rail power source | **yes** |
| `J3` | RJ-45, `OW-CONN-J1B1211CCD` or `OW-CONN-438600001` | pyControl port: UART + GND only in Rev 0 | **yes** |
| `J4` | 40-pin 0.5 mm FFC, `OW-CONN-5051104091` | InstrumentPort-40 | rev 1 |
| `J5` | 4-pos 3.5 mm terminal, `OW-CONN-1844236` | Stepper coils | **yes** |
| `J6` | 5-pos 3.5 mm terminal, `OW-CONN-1844249` | Encoder: supply, return, `A`, `B`, `N`, single-ended | **yes** |
| `J7` | Dual BNC, `DOSIN-801-0095` | `ANGLE_OUT`, `AUX_ANALOG_OUT` | rev 1 |
| `J8` | Dual BNC, `DOSIN-801-0095` | `PYC_PULL_EVENT`, `PYC_FAULT` | rev 1 |
| `J9` | Dual BNC, `DOSIN-801-0095` | `PYC_RSYNC_IN`, spare | rev 1 |
| `J10` | SWD header | Debug | **yes** |
| `J11` | 2-pos 3.5 mm terminal, `OW-CONN-1844210` | Limit switch, inside the debounced input block | **yes** |

**Seven connectors in Rev 0, four deferred.**

`J5`, `J6`, and `J11` are one stocked 3.5 mm horizontal screw-terminal family
(`OW-CONN-1844236`, `-1844249`, `-1844210`), which keeps the harness story
uniform and needs no purchase.

**They are screw terminals, not locking.** The earlier plan called for a locking
motor connector because the rig gets handled. Screw terminals unblock Rev 0
today; if the rig proves that insufficient, sourcing a locking 4-pos motor
connector is a rev 1 change confined to `J5`. Decide before the harness is built,
not after.

## pyControl Port In Rev 0

Only the serial link is populated. See `docs/pycontrol-port-pinout.md` for the
full pinout and its provenance.

| RJ-45 pin | Signal | Rev 0 |
| --- | --- | --- |
| 1 | `DIO-A` | RP2040 `UART0 RX` (`GP1`) |
| 2 | `GND` | Ground |
| 4 | `DIO-B` | RP2040 `UART0 TX` (`GP0`) |
| 6 | `5V` | Footprint for the ORing branch; population gated on the port's 5 V budget |
| 3, 5, 7, 8 | `POW-A`, `SPECIAL`, `POW-B`, `12V` | Not connected |

Series resistors and ESD protection on every populated port signal.

`PYC_PULL_EVENT`, `PYC_FAULT`, and `PYC_RSYNC_IN` are rev 1. Both DIO lines are
consumed by the UART, so when those lines arrive they still land on BNCs — that
analysis is unchanged and is why `J8` and `J9` keep their designators.

## What Rev 0 Gives Up

Stated plainly so nobody discovers it during bring-up:

- **No independent encoder cross-check.** The encoder reaches the TMC5130A only.
  The `ENCODER_MISMATCH` fault in `docs/uart-protocol.md` has no second count to
  compare against and is not implementable in Rev 0. Encoder integrity rests on
  the driver's own count plus the index pulse.
- **No analog angle output.** The researcher-facing 0-5 V BNC is rev 1. Angle is
  available over the UART only.
- **No InstrumentPort-40 and no buffered digital observation.** Bring-up
  instrumentation is USB CDC, the two `FW_TRIG` test points, and a scope on test
  pads.
- **No pyControl TTL event lines.** `PULL_EVENT`, `FAULT`, and `RSYNC` are rev 1,
  so there is no hardware-timed event or fault path and no time-alignment signal.
  Everything is in UART time, with UART latency, for Rev 0.
- **No synthetic homing stimulus.** Permanently, not deferred — homing is
  exercised with the real switch.

None of these block the stated Rev 0 purpose, which is to exercise the
interfaces. All of them matter for experiments with animals, and none of that is
in Rev 0's scope either.

## InstrumentPort-40 Overlay — Deferred To Rev 1

Retained in full because it is the expensive part of this document and the pin
allocation above is built to accept it unchanged. Nothing here is populated in
Rev 0.

The profile provides 18 digital slots (`DIG0`-`DIG15`, `TRIG0`, `TRIG1`), two
differential analog inputs, and two analog outputs. Pin numbers are the DUT-side
connector pins from the v0.3 profile. On a single-axis board the signal count fits
the profile almost exactly: **18 signals for 18 slots**.

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

**Note the dependency.** Six of the eighteen slots — `DIG6`, `DIG7`, `DIG8`,
`DIG9`, `DIG10`, `DIG11` — carry signals Rev 0 does not have. The overlay only
fills exactly when the DAC and the PIO encoder tap both exist, which is why it
arrives with them rather than before them.

`TMC_DIAG0` did not earn a slot because a driver fault reaches the capture
through `PYC_FAULT` anyway, one firmware latency later. It goes to a test point.

Dropped to labelled test points in the full scope — 7 signals: `TMC_DIAG0`,
`TMC_DIAG1`, `~{TMC_DRV_EN}`, `~{DAC_LDAC}`, `~{DAC_CLR}`, `HV_EN`,
`~{INSTR_BUF_OE}`. Also bring `HV_SNS`, the `REFL` net, and the TMC `SWSEL` strap
to pads. Provide labelled test points, not bare vias.

**In Rev 0 the test-point list is what you get**, so treat it as primary rather
than as overflow: `TMC_DIAG0`, `TMC_DIAG1`, `~{TMC_DRV_EN}`, `HV_EN`, `HV_SNS`,
`REFL`, `LIMIT_SW`, `SWSEL`, `FW_TRIG0`, `FW_TRIG1`, and the SPI bus.

### AIN Assignment Keeps 36 V Off The Connector

`AIN1_P/N` observes the second DAC channel rather than a divided-down motor
rail. A resistive divider from a 36 V rail into an instrument input is a
plausible-looking way to destroy an ADALM2000 if a resistor is misplaced or a
divider node is probed while the rail is live.

Motor-supply monitoring uses the onboard ADC instead: `GP28` for load current
through the smart switch's `SNS` pin, and `GP26` for the `+5V` rail. Both stay
inside the board's own 3.3 V domain, and both are live in Rev 0.

### Digital Instrumentation Buffering — Rev 1

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

| Package | Channels | Zone |
| --- | --- | --- |
| `U_A` | `DIG2`, `DIG3`, `DIG4`, `DIG5` | TMC SPI bus and chip select |
| `U_B` | `DIG6`, `DIG10`, `DIG11`, + 1 spare | DAC group |
| `U_C` | `DIG7`, `DIG8`, `DIG9`, `DIG15` | Encoder and limit switch |
| `U_D` | `DIG0`, `DIG1`, `DIG12`, `DIG13` | pyControl connector group |
| `U_E` | `DIG14`, `TRIG0`, `TRIG1`, + 1 spare | Sync and firmware markers |

All five `~OE` nets tie into one board-wide `~{INSTR_BUF_OE}` driven by `GP24`,
which is in the bus-switch bypass group.

**Enable default:** the block pulls `~OE` up, so buffers are high-Z until
firmware enables them — the same power-on posture as the bus switch, for the same
reason. Firmware should enable them during normal startup and report buffer state
in `ID`/`STATUS`. See `docs/instrument-strategy.md`.

## What Carries Forward To The Twin-Axis Board

If this board is later superseded by `../mouse-joysticks-pcb`, these carry over
unchanged:

- the pyControl port pinout and signal set;
- the UART protocol, with an axis argument added;
- the analog output design and its calibration semantics, once rev 1 builds it;
- the InstrumentPort-40 buffering pattern and the enable default;
- the GPIO isolation pattern, including the bypass group, which is the newest
  and most reusable thing this board contributes;
- the power chain, sized for one motor instead of two.

What does not carry over: this GPIO table and this instrument overlay. The twin
board re-derives both, and its overlay is already written.
