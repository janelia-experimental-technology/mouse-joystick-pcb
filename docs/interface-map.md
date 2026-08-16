# Interface Map

**Status:** Rev 0 scope frozen for allocation, not for layout
**Date:** 2026-08-16
**Board:** single-axis, RP2040, one TMC5130A
**Source profile:** `board-interfaces/docs/instrument-port-40.md`

This document records this board's RP2040 GPIO allocation. It covers **two
scopes at once**: what Rev 0 populates, and the full scope that later revisions
grow into. The InstrumentPort-40 profile itself belongs in `board-interfaces` and
is not redefined here.

## Rev 0 Is A Strict Subset

Rev 0 was scaled back to get testable hardware in the researcher's hands sooner.
See `docs/rev0-plan.md` for what it contains and why.

The allocation below is written so that **no pin moves between Rev 0 and full
scope**. Rev 0 populates 18 of the 29 allocated GPIOs; the other 11 are reserved,
routed nowhere, and become live in later revisions without disturbing anything
Rev 0 established. Firmware written against Rev 0 keeps working.

The eighteenth is `GP24` `~{INSTR_BUF_OE}`, which became live on 2026-08-16 when
the InstrumentPort moved into Rev 0. It was already allocated and already in the
bypass group, so nothing else shifted.

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
| `GP24` | `~{INSTR_BUF_OE}` | Instrumentation buffer enable                   | **yes**  | `byp` |
| `GP25` | `FW_TRIG0`        | Firmware timing marker                          | **yes**¹ | `byp` |
| `GP26` | `V5_SENSE`        | `+5V_SW` presence and level, via divider        | **yes**  | `byp` |
| `GP27` | spare             | Reserved — `EXT_FAULT_IN` candidate, see below  | spare    | —     |
| `GP28` | `HV_SNS`          | 36 V input load-current sense, `R_SNS` = 249 Ω  | **yes**  | `byp` |
| `GP29` | `~{HV_FAULT}`     | 36 V switch fault, open-drain, pull-up to 3.3 V | **yes**  | `byp` |

¹ Rev 0 lands `FW_TRIG0`/`FW_TRIG1` on both labelled test points **and**
`TRIG0`/`TRIG1` of the InstrumentPort. They are the cheapest bring-up
instrumentation on the board and the natural trigger source for a long capture.

**Rev 0: 18 connected, 11 reserved, 1 spare.**
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
- **`GP1` needs an external 10 kΩ pull-up to `+3V3_MCU`.** See
  [`GP1` Gets A Hardware Pull-Up](#gp1-gets-a-hardware-pull-up) below. This is a
  board-level part on the MCU side of the port block's series resistor, not part
  of `pycontrol_behavior_port_rj45_boundary`.

### `GP1` Gets A Hardware Pull-Up

**Decided 2026-08-14.** Fit a **10 kΩ 0402 (`OW-RES-10K-0402`, stocked) from
`PYC_UART_RX` to `+3V3_MCU`**, on the **MCU side** of the port block's `R29001`,
placed near the RP2040.

`GP1` is the pyControl UART RX. It is driven by the host's `DIO-A`, so it floats
whenever the cable is unplugged, whenever pyControl is powered down with the
cable connected, and — the case that matters — **between this board's
power-on-reset and the instruction where firmware configures the pad**. A UART RX
line that drifts low reads as a start bit or a break, so the RX FIFO fills with
framing errors before the first line of protocol code runs.

An internal pull does not cover that window. This is the same argument that keeps
the external 10 kΩ pulldown on the 36 V block's `EN` — see `docs/power.md` — and
the same one behind `.agents/AGENTS.md`'s rule that the board must reach a safe
state without firmware's cooperation. A defined idle level on the link carrying
the safety heartbeat belongs in that category.

The floating level is genuinely indeterminate rather than merely "probably high":
the `USBLC6-2P6` on that line leaks 150 nA max, against the RP2040's own ~1 µA
input leakage.

| Choice | Why |
| --- | --- |
| 10 kΩ | 330 µA load when the host drives low, trivial for an STM32 GPIO rated 8-20 mA. Wins against a ~50 kΩ internal pull-down if one is active |
| `+3V3_MCU`, not `+3V3_SW` | The pyControl UART bypasses the bus switch precisely so it works with the switched domain dark. Pulling to the switched rail would defeat that |
| MCU side of `R29001` | The point is to define the RP2040's input, so it must hold when the connector path is open — which is the unplugged-cable case. On the connector side it would only load the cable |
| Board level, not in the block | The block's boundary has no 3.3 V pin, and *which* 3.3 V domain is a board decision. Keep the block's interface at five pins |

**Keep the firmware pull enabled as well.** They parallel to ~8.3 kΩ and cost
nothing.

**`GP0` (TX) deliberately gets none.** A matching pull-up would keep the host
seeing idle-high while this board is in reset or BOOTSEL, but it fails
differently: with `+3V3_MCU` dead and the cable connected, 10 kΩ to a 0 V rail
holds the host's RX **low**, a continuous break, which is arguably worse than
floating. That needs both USB absent and the pyControl 5 V branch open, so it is
a corner — but fit TX only if host-side framing noise actually shows up at
Gate B.

**Open, and it decides how strong this recommendation is:** `docs/power.md`
states that RP2040 GPIOs are "inputs with pulls disabled at reset." That may be
wrong — RP2040 pads are believed to reset with the pull-**down** enabled
(`PDE` set in `PADS_BANK0`). The RP2040 datasheet is not in `kicad-libs/tmp/`,
so confirm it.

| If pulls are disabled at reset | If a pull-down is enabled at reset |
| --- | --- |
| The external pull-up is belt-and-braces | The external pull-up is **required** — `GP1` is otherwise actively held low until firmware runs |

10 kΩ is the right value either way: against a ~50 kΩ internal pull-down it gives
3.3 × 50/60 ≈ **2.75 V**, comfortably over a 2.31 V `VIH`. The same claim is
load-bearing in `docs/power.md` for the `EN` divider, where it is harmless — the
external pulldown pulls the same direction — but the document should still say
the right thing.

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
belongs to pyControl. Rev 0's other rich observation path is the InstrumentPort,
which carries the TMC SPI bus and both directions of the pyControl link; the
event BNCs are still rev 1.

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
- **`GP1` has a hardware pull-up, and firmware should still enable its own.**
  The external 10 kΩ defines RX before firmware runs; the internal pull is the
  second layer. Do not treat the hardware part as permission to skip it. See
  [`GP1` Gets A Hardware Pull-Up](#gp1-gets-a-hardware-pull-up).
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
| `J4` | 40-pin 0.5 mm FFC, `OW-CONN-5051104091` | InstrumentPort-40 | **yes** |
| `J5` | 4-pos 3.5 mm terminal, `OW-CONN-1844236` | Stepper coils | **yes** |
| `J6` | 5-pos 3.5 mm terminal, `OW-CONN-1844249` | Encoder: supply, return, `A`, `B`, `N`, single-ended | **yes** |
| `J7` | Dual BNC, `DOSIN-801-0095` | `ANGLE_OUT`, `AUX_ANALOG_OUT` | rev 1 |
| `J8` | Dual BNC, `DOSIN-801-0095` | `PYC_PULL_EVENT`, `PYC_FAULT` | rev 1 |
| `J9` | Dual BNC, `DOSIN-801-0095` | `PYC_RSYNC_IN`, spare | rev 1 |
| `J10` | SWD header | Debug | **yes** |
| `J11` | 2-pos 3.5 mm terminal, `OW-CONN-1844210` | Limit switch, inside the debounced input block | **yes** |

**Eight connectors in Rev 0, three deferred.** `J4` moved into Rev 0 on
2026-08-16 with the InstrumentPort.

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
  the driver's own count plus the index pulse. **The InstrumentPort narrows this**
  — `ENC_A` and `ENC_B` are captured alongside the SPI reads of `X_ENC`, so the
  driver's decoding can be checked by hand even though firmware cannot check it
  automatically. That is a bench capability, not a runtime fault.
- **No analog angle output.** The researcher-facing 0-5 V BNC is rev 1. Angle is
  available over the UART only.
- **Eight of the eighteen InstrumentPort digital Strands are unrouted**, and two
  of the five instrumentation buffer packages are DNP. Rev 0 captures the TMC SPI
  bus, both directions of the pyControl serial link, the two firmware triggers,
  and the two encoder channels — enough for firmware development, which is why
  the port was pulled forward, but not the event, DAC, brake, or torque groups.
- **No pyControl TTL event lines.** `PULL_EVENT`, `FAULT`, and `RSYNC` are rev 1,
  so there is no hardware-timed event or fault path and no time-alignment signal.
  Everything is in UART time, with UART latency, for Rev 0.
- **No synthetic homing stimulus.** Permanently, not deferred — homing is
  exercised with the real switch.

None of these block the stated Rev 0 purpose, which is to exercise the
interfaces. All of them matter for experiments with animals, and none of that is
in Rev 0's scope either.

## InstrumentPort-40 Overlay — In Rev 0

**Moved into Rev 0 on 2026-08-16**, so firmware development can watch the
pyControl link and the TMC5130A bus in one capture. Ten of the eighteen digital
Strands are live at fabrication; the rest are allocated now and routed when their
circuits arrive.

Two of those ten — `ENC_A` and `ENC_B` on `DIG0`/`DIG1` — are **temporary
tenants**. They are there to confirm the TMC5130A is decoding the encoder
correctly, and they hand their slots to the rev 2 torque front end. See below.

The profile provides 18 digital slots (`DIG0`-`DIG15`, `TRIG0`, `TRIG1`), two
differential analog inputs, and two analog outputs. Pin numbers are the DUT-side
connector pins from the v0.3 profile. The allocation below fills all 18 exactly
and follows the profile's own Preferred Digital Overlays table much more closely
than the superseded rev-1 allocation did: the TMC bus lands on the SPI overlay,
the pyControl serial pair on the first UART pair, the brake's PWM and fault on
the slots the profile names for PWM and fault, and the torque front end on the
I2C overlay.

| DUT pin | Strand | Board signal | Live | Why |
| --- | --- | --- | --- | --- |
| 2 | `DIG0(I2C_SCL)` | `ENC_A` → `TQ_I2C_SCL` | **Rev 0**, swaps at rev 2 | Encoder quadrature now; torque front-end bus later, on the profile's own I2C overlay |
| 3 | `DIG1(I2C_SDA)` | `ENC_B` → `TQ_I2C_SDA` | **Rev 0**, swaps at rev 2 | |
| 5 | `DIG2(SPI_SCK)` | `TMC_SPI_SCK` | **Rev 0** | Driver transactions; correctness and fault diagnosis |
| 7 | `DIG3(SPI_MOSI)` | `TMC_SPI_COPI` | **Rev 0** | |
| 8 | `DIG4(SPI_MISO)` | `TMC_SPI_CIPO` | **Rev 0** | Also the witness for bus-switch state — see below |
| 10 | `DIG5(SPI_CS0)` | `~{TMC_CS}` | **Rev 0** | Frames each driver transaction |
| 11 | `DIG6(SPI_CS1)` | `~{DAC_CS}` | rev 1 | Frames each DAC write |
| 13 | `DIG7` | `PYC_DIO_A` | **Rev 0** | Host link, both directions, on the profile's first UART pair |
| 14 | `DIG8` | `PYC_DIO_B` | **Rev 0** | |
| 16 | `DIG9` | `DAC_SPI_SCK` | rev 1 | Lets a capture recover the commanded angle code |
| 17 | `DIG10` | `DAC_SPI_COPI` | rev 1 | |
| 19 | `DIG11` | `BRAKE_DIM` | rev 2 | Brake PWM, on the slot the profile names for PWM |
| 20 | `DIG12` | `~{BRAKE_FAULT}` | rev 2 | Brake overcurrent latch, on the slot the profile names for fault |
| 22 | `DIG13` | `PYC_PULL_EVENT` | rev 1 | Behavioral event |
| 23 | `DIG14` | `PYC_FAULT` | rev 1 | Fault, experiment-critical |
| 24 | `DIG15` | `PYC_RSYNC_IN` | rev 1 | Time alignment; places everything else in pyControl time |
| 26 | `TRIG0` | `FW_TRIG0` | **Rev 0** | Firmware timing marker |
| 28 | `TRIG1` | `FW_TRIG1` | **Rev 0** | Firmware timing marker |
| 32/33 | `AIN0_P` / `AIN0_N` | `ANGLE_OUT` at the BNC centre / `AGND` | rev 1 | Verifies the researcher-facing BNC against the driver's own count in one capture |
| 35/36 | `AIN1_P` / `AIN1_N` | `AUX_ANALOG_OUT` **or** `BRAKE_ISENSE` / `AGND` | rev 1-2 | Contested; see below |
| 38, 39 | `AOUT0`, `AOUT1` | **No-connect** | never | No stimulus path into a board used with animals |
| 1, 4, 6, 9, 12, 15, 18, 21, 25, 27, 29, 30 | `GND` | Digital return | — | Per profile |
| 31, 34, 37, 40 | `AGND` | Analog return | — | Per profile |

**Ten Strands live in Rev 0**: the four TMC SPI signals, the two pyControl serial
lines, the two firmware triggers, and the two encoder channels. Eight more are
allocated and unrouted.

### `DIG0`/`DIG1` Are The Swap Slots

**Decided 2026-08-16.** `ENC_A` and `ENC_B` occupy the two slots reserved for the
rev 2 torque front-end bus, and give them up when it arrives.

**What they buy in Rev 0.** Rev 0 wires the encoder to the TMC5130A only — there
is no PIO cross-check — so the driver's `X_ENC`/`XACTUAL` register is the *only*
count anything on this board has. With the raw quadrature edges and the SPI reads
of that register in the same capture, the driver's decoding is checkable directly:
count the edges, read the register, compare. Without them, a driver that is
miscounting looks exactly like a driver that is counting correctly. That question
is at its most urgent when the board is new, which is precisely when the port is
now present.

**Why these two slots and not others.** `DIG0`/`DIG1` belong to buffer package
`U_E`, the rev 2 package. `U_C` and `U_D` fill at rev 1. So the encoder survives
Rev 0 *and* rev 1 untouched and is evicted only at rev 2 — the latest eviction any
pair of slots offers.

**`ENC_N` stays off the port.** The index fires once per revolution; `ENC_A` and
`ENC_B` are what a decode check needs. It goes to a test pad.

**When the torque front end lands**, reassign `DIG0`/`DIG1` to `TQ_I2C_SCL` and
`TQ_I2C_SDA` and drop the encoder taps to test pads. By then the PIO cross-check
in rev 1 gives firmware a second count of its own, so the port no longer has to
provide the comparison.

**Two 100 kΩ pull-downs to GND on the encoder taps**, at the buffer inputs. The
encoder is on the **switched** domain, so `ENC_A`/`ENC_B` float whenever `HV_EN`
is low — the board's normal idle state — while `U_E` stays powered from
`+3V3_MCU`. Pull-*down* works whether the encoder turns out push-pull or
open-collector, which matters because the encoder part is still an open blocking
item; against a 2.2 kΩ pull-up to `+3V3_SW` a 100 kΩ pull-down still reads 3.2 V.

### If Brake And Torque Need More Than Four Slots

The torque front end is unchosen — `PGA305` is I2C and needs the two swap slots,
`ADS1220` is SPI and would need three or four. Note that the encoder taps are
**not** additional room: they are already sitting in the two slots the torque bus
expects, so evicting them buys nothing beyond what the reservation assumed. The
reclaim order for real extra room, cheapest loss first:

1. **`DAC_SPI_SCK` and `DAC_SPI_COPI`** (frees 2). `AIN0` observes the analog
   output itself, which is better evidence than the code that produced it, and
   `~{DAC_CS}` on `DIG6` still timestamps every write.
2. **`PYC_FAULT`** (frees 1). It also arrives in the captured UART stream on
   `DIG7`/`DIG8`, one protocol latency later.

Do not reclaim `PYC_RSYNC_IN`. It is the only signal that places the board's local
time in pyControl's frame, and nothing else in the capture substitutes for it.

### Test Points

`TMC_DIAG0` did not earn a slot because a driver fault reaches the capture
through `PYC_FAULT` anyway, one firmware latency later. It goes to a test point.

Labelled test pads, not bare vias: `ENC_N`, `LIMIT_SW`, `TMC_DIAG0`,
`TMC_DIAG1`, `~{TMC_DRV_EN}`, `HV_EN`, `HV_SNS`, `REFL`, `SWSEL`,
`~{INSTR_BUF_OE}`, and in later revisions `~{DAC_LDAC}`, `~{DAC_CLR}`, and
`TQ_DRDY`. `TQ_DRDY` has no slot because the I2C capture already shows when the
host reads a conversion.

**Also pad `ENC_A` and `ENC_B`**, even though Rev 0 carries them on the port.
They lose their slots at rev 2 and the pads are what they fall back to, so
placing them now costs nothing and saves a layout change later.

### Where Each Signal Is Tapped

Two tap points are decisions, not details, and getting either wrong makes the
capture answer a different question than the one being asked.

**pyControl serial: the block's existing `PYC_DIO_A`/`PYC_DIO_B` pins, the MCU
side of `R29001`/`R29002`.** No block change, no new boundary pins.

An earlier draft of this section put the tap on the connector side of those
resistors. **That was wrong and is recorded here so it does not get re-proposed.**
On a digital instrument channel the two nodes are indistinguishable by
construction. The only current in the resistor is the 330 µA the 10 kΩ `GP1`
pull-up sinks when the host drives low, so the drop across 100 Ω is **33 mV** —
three orders of magnitude below any logic threshold. The two sides differ only
when the resistor is open or something is actively fighting on the line, and both
of those are hard faults a meter finds faster than a capture does. A logic
analyzer cannot resolve the distinction the extra pin would expose.

Three reasons the MCU side is the better tap, not merely the cheaper one:

1. **It answers the question actually being asked.** "Is what the RP2040 receives
   what the breakout board sent?" is a question about the signal presented to the
   pin. That is the MCU-side node. The capture is still fully independent of
   firmware — it is hardware observation, not a log — which is what "observe the
   link directly" needs to mean.
2. **The 100 Ω becomes series protection for the buffer.** Tapping the connector
   side would put the `SN74LVC125A` input on the unprotected node, between the
   `USBLC6-2P6` and the resistor, with no series element between it and the cable.
3. **It keeps the ESD node short.** The block deliberately routes each line in one
   `USBLC6` I/O pad and out the other so the clamp connection stays short. Hanging
   a stub off that node to reach a buffer elsewhere on the board adds capacitance
   and antenna to the one node that most wants neither.

Exposing both sides of the resistor would also present the board with a
distinction it cannot use, which is the opposite of the discipline the rest of
that block's interface follows. If a future board genuinely needs the raw cable
node — a bias network, a different clamp, a transceiver — add the pin then, when
there is a consumer to define it against.

**TMC5130A: the A side of the bus switch, not the chip pins.** When the bus
switch is enabled, A and B are the same node through a few ohms, so the capture
shows what the chip sees. When it is isolated, the capture shows MCU traffic with
`TMC_SPI_CIPO` silent — which *diagnoses* the bus-switch state instead of hiding
it, and that is exactly the failure mode a firmware author needs to recognise.

This looks like the opposite of the pyControl decision above and is not. A 100 Ω
resistor cannot make its two nodes read differently on a digital channel; a bus
switch that can be *open* absolutely can. Where the series element has two
distinguishable states, which side you tap is a real choice — and the near side is
the one that stays in the always-on domain and stays driven.

Tapping the B side would put always-on buffer inputs on switched-domain nets that
float whenever `HV_EN` is low, which is this board's normal idle state. That is
the floating-CMOS-input problem the design avoids everywhere else, arriving by a
new route.

**Fit a 100 kΩ pull-down on `TMC_SPI_CIPO`**, A side, near the buffer. The
TMC5130A tri-states `SDO` between transactions even in normal operation, so that
net floats regardless of the instrument port; the buffer input just makes it
matter. An internal pull on `GP4` does not cover the window before firmware runs
— the same argument that put an external pull-up on `GP1`.

**Encoder: between the input filter and the TMC5130A.** `ENC_A` and `ENC_B` are
tapped on the board-local encoder section — connector `J6`, then filtering and
ESD, then the driver — on the driver side of the filter, so the capture shows what
the TMC5130A's `ENCA`/`ENCB` pins actually receive. That is the point of having
them: the comparison is against the driver's own decoded count, so the tap belongs
where the driver sees the signal, not where the cable delivers it. Each tap gets
its own 100 kΩ pull-down, as above.

**Three pull-downs total**, then: `TMC_SPI_CIPO`, `ENC_A`, `ENC_B`. They are the
only new passives the instrument port adds.

### AIN Assignment Keeps 36 V Off The Connector

`AIN1_P/N` observes a ground-referenced 0-5 V board node rather than a
divided-down motor rail. A resistive divider from a 36 V rail into an instrument
input is a plausible-looking way to destroy an ADALM2000 if a resistor is
misplaced or a divider node is probed while the rail is live.

**`AIN1_P/N` is contested and does not need resolving for Rev 0**, since neither
candidate exists yet:

- `AUX_ANALOG_OUT`, DAC channel B — the rev-1 assignment, and it survives only if
  the researcher wants a second analog output. That is the same question that
  decides dual versus quad DAC; see `../mouse-joysticks-pcb/docs/encoder-analog-output.md`.
- `BRAKE_ISENSE`, the rev-2 brake current monitor — a natural use for a
  differential input, and the measurement that verifies commanded against actual
  brake current.

If `BRAKE_ISENSE` wins, it must be a **low-side shunt or a ground-referenced
current-monitor output**. A high-side sense on the brake rail would put that
rail's common-mode voltage on the instrument connector, which is the thing this
section exists to prevent.

Motor-supply monitoring uses the onboard ADC instead: `GP28` for load current
through the smart switch's `SNS` pin, and `GP26` for the `+5V` rail. Both stay
inside the board's own 3.3 V domain, and both are live in Rev 0.

### Digital Instrumentation Buffering — Three Packages In Rev 0

Every `DIG*` and `TRIG*` signal above is buffered with
`orb_weaver_private:instrumentation_signal_buffer_sn74lvc125a`
(`SN74LVC125A`, `OW-MISC-SN74LVC125ARGYR`), already composed five times into
`tmc51x0-driver-dev-pcb`.

- `VCC = +3V3_MCU`, the always-on domain. The catalog part's absolute maximum
  supply is 3.6 V.
- Unidirectional, board-side to instrument-side only. `PYC_DIO_A` and
  `PYC_RSYNC_IN` are inputs to this board; they are *tapped* and buffered
  outward. The buffer never drives back into the pyControl cable — and because
  the tap is on the MCU side of `R29001`, the block's own 100 Ω sits between the
  buffer and the cable as a second line of defence.
- The block provides ~33 Ω series source termination on each output.
- 18 signals at 4 channels per package = **5 packages**, 2 channels spare.

**The grouping is chosen so each revision populates whole packages**, so a
deferred group never leaves a powered CMOS input undriven.

| Package | Channels | Zone | Fitted |
| --- | --- | --- | --- |
| `U_A` | `DIG2`, `DIG3`, `DIG4`, `DIG5` | TMC SPI bus and chip select | **Rev 0** |
| `U_B` | `DIG7`, `DIG8`, `TRIG0`, `TRIG1` | pyControl serial and firmware markers | **Rev 0** |
| `U_C` | `DIG6`, `DIG9`, `DIG10`, + 1 spare | DAC group | rev 1 |
| `U_D` | `DIG13`, `DIG14`, `DIG15`, + 1 spare | pyControl event lines | rev 1 |
| `U_E` | `DIG0`, `DIG1` (encoder now, torque later), `DIG11`, `DIG12` | Encoder in Rev 0; brake and torque at rev 2 | **Rev 0** |

**Place all five footprints in Rev 0 and populate `U_A`, `U_B`, and `U_E`.** `U_C`
and `U_D` are DNP with their inputs unrouted, which costs board area now and saves
a placement pass later. Reserving the area is the whole point — see
`docs/design-block-map.md` on leaving room for the rev 1 and rev 2 additions.

`U_E` is the one package that does carry a mix, because the encoder taps sit in it
and the brake does not exist yet. **Tie its `DIG11` and `DIG12` inputs directly to
GND in Rev 0** — a net, not a part. Those two channels drive a static low onto
their `DIG` pins, which reads as a dead channel at the analyzer and is the correct
thing for an unused LVC125A input. At rev 2 the ties are removed and the brake
signals routed in their place, at the same time the encoder taps hand `DIG0`/`DIG1`
to the torque bus — one package, one change.

The two spare channels in `U_C` and `U_D` also need their inputs tied to GND when
those packages are fitted at rev 1.

All five `~OE` nets tie into one board-wide `~{INSTR_BUF_OE}` driven by `GP24`,
which is in the bus-switch bypass group. Wire all five even though three are
unpopulated.

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
