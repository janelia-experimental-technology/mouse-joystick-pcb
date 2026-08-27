# Interface Map

**Status:** Rev 0 allocation frozen; schematic drawn and reviewed 2026-08-17,
with open findings in `.agents/handoff.local.md`. **Rev 1 allocation revised
2026-08-26** when the analog output block was built — `GP12` and `GP17` returned
to the spare pool and no Rev 0 pin moved.
**Date:** 2026-08-26
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
scope**. Rev 0 populates 18 of the 24 allocated GPIOs; the other 6 are reserved,
routed nowhere, and become live in later revisions without disturbing anything
Rev 0 established. Firmware written against Rev 0 keeps working.

`GP24` `~{INSTR_BUF_OE}` became live on 2026-08-16 when the InstrumentPort moved
into Rev 0; it was already allocated and already in the bypass group. The same
day, `GP14`-`GP16` and `GP18` left the allocation entirely when the encoder and
limit switch stopped reaching the MCU, which is why the denominator dropped from
29 to 25. **`GP14` came back on 2026-08-17** as `HV_DIAG_EN`, taking the
denominator to 26. **`GP12` and `GP17` left it on 2026-08-26** when the analog
output block was built against a part with no `LDAC` or `CLR` pin, which takes
the denominator to 24 and leaves six spares.

That property is not free, and it cost exactly one trade — see
[The Bus Switch Costs A Pin](#the-bus-switch-costs-a-pin).

## RP2040 GPIO Allocation

Checked against RP2040 peripheral pin muxing. `UART0` is the pyControl link,
`SPI0` serves the TMC5130A, `SPI1` is reserved for the rev 1 DAC and needs only
three of its pins — `SCK`, `TX`, and a GPIO chip select. Chip selects
are plain GPIO, not hardware `CSn` — RP2040's PL022 hardware chip select does not
hold `CS` low across the TMC5130A's 40-bit multi-byte datagrams.

The `rp2040` design block exposes these as labels `GPIO0` … `GPIO25` and
`GPIO26_ADC0` … `GPIO29_ADC3`.

**Iso** column: `sw` = routed through the `rp2040_gpio_isolation_sn74cb3q3245`
bus switch; `byp` = bypasses it and connects to the MCU directly. **The rule is
the powered domain of the far end**, not convenience — see
[GPIO Isolation](#gpio-isolation).

**Dir** column: direction **as seen by the RP2040**. `out` = the MCU drives it,
`in` = the MCU reads it. This is also the KiCad shape to give the matching
hierarchical pin on the `mcu` sheet — `out` → Output, `in` → Input. See
[Signal Direction And Sheet Pin Types](#signal-direction-and-sheet-pin-types).

| GPIO   | Net                   | Function                                                 | Rev 0    | Iso   | Dir    |
|--------|-----------------------|----------------------------------------------------------|----------|-------|--------|
| `GP0`  | `PYC_UART_TX`         | UART TX to pyControl (`UART0 TX`)                        | **yes**  | `byp` | `out`  |
| `GP1`  | `PYC_UART_RX`         | UART RX from pyControl (`UART0 RX`)                      | **yes**  | `byp` | `in`   |
| `GP2`  | `~{TMC_CS}`           | Driver chip select                                       | **yes**  | `sw`  | `out`  |
| `GP3`  | `~{TMC_DRV_EN}`       | Driver enable, active low                                | **yes**  | `sw`  | `out`  |
| `GP4`  | `TMC_SPI_CIPO`        | Driver SPI MISO (`SPI0 RX`)                              | **yes**  | `sw`  | `in`   |
| `GP5`  | `TMC_DIAG0`           | Driver diagnostic 0                                      | **yes**  | `sw`  | `in`   |
| `GP6`  | `TMC_SPI_SCK`         | Driver SPI clock (`SPI0 SCK`)                            | **yes**  | `sw`  | `out`  |
| `GP7`  | `TMC_SPI_COPI`        | Driver SPI MOSI (`SPI0 TX`)                              | **yes**  | `sw`  | `out`  |
| `GP8`  | `TMC_DIAG1`           | Driver diagnostic 1                                      | **yes**  | `sw`  | `in`   |
| `GP9`  | `~{BUS_SW_EN}`        | GPIO isolation enable, active low                        | **yes**  | `byp` | `out`² |
| `GP10` | `DAC_SPI_SCK`         | DAC SPI clock (`SPI1 SCK`)                               | reserved | `sw`  | `out`  |
| `GP11` | `DAC_SPI_COPI`        | DAC SPI MOSI (`SPI1 TX`)                                 | reserved | `sw`  | `out`  |
| `GP12` | spare                 | **Freed 2026-08-26** — the rev 1 DAC has no `LDAC` pin⁶  | spare    | —     | —      |
| `GP13` | `~{DAC_CS}`           | DAC chip select (`~SYNC`)                                | reserved | `sw`  | `out`  |
| `GP14` | `HV_DIAG_EN`          | 36 V switch diagnostics enable⁵                          | **yes**  | `byp` | `out`  |
| `GP15` | spare                 | **Freed 2026-08-16**                                     | spare    | —     | —      |
| `GP16` | spare                 | **Freed 2026-08-16**                                     | spare    | —     | —      |
| `GP17` | spare                 | **Freed 2026-08-26** — the rev 1 DAC has no `CLR` pin⁶   | spare    | —     | —      |
| `GP18` | spare                 | **Freed 2026-08-16** — limit switch reaches `REFL` only³ | spare    | —     | —      |
| `GP19` | `HV_EN`               | 36 V input switch enable                                 | **yes**  | `byp` | `out`  |
| `GP20` | `PYC_PULL_EVENT`      | Pull event out                                           | reserved | `byp` | `out`  |
| `GP21` | `FW_TRIG1`            | Firmware timing marker                                   | **yes**¹ | `byp` | `out`  |
| `GP22` | `PYC_FAULT`           | Latched fault out                                        | reserved | `byp` | `out`  |
| `GP23` | `PYC_RSYNC_IN`        | Rsync edges in                                           | reserved | `byp` | `in`   |
| `GP24` | `~{INSTR_BUF_OE}`     | Instrumentation buffer enable                            | **yes**  | `byp` | `out`  |
| `GP25` | `FW_TRIG0`            | Firmware timing marker                                   | **yes**¹ | `byp` | `out`  |
| `GP26` | `SW_RAIL_SENSE_DIV_2` | `+3.3V_SW` presence and level, ÷2 divider⁴               | **yes**  | `byp` | `in`   |
| `GP27` | spare                 | Reserved — `EXT_FAULT_IN` candidate, see below           | spare    | —     | —      |
| `GP28` | `HV_SNS`              | 36 V input load-current sense, `R_SNS` = 249 Ω           | **yes**  | `byp` | `in`   |
| `GP29` | `~{HV_FAULT}`         | 36 V switch fault, open-drain, pull-up to 3.3 V          | **yes**  | `byp` | `in`   |

¹ Rev 0 lands `FW_TRIG0`/`FW_TRIG1` on `TRIG0`/`TRIG1` of the InstrumentPort.
They are the cheapest bring-up instrumentation on the board and the natural
trigger source for a long capture. They were also to get labelled test points;
**as of 2026-08-17 no test points exist on the board** — see [Test Points —
Outstanding](#test-points--outstanding).

² `~{BUS_SW_EN}` **needs no hierarchical pin.** The bus switch lives inside the
`mcu` sheet, so `GP9` reaches its `~{OE}` without crossing the sheet boundary. It
is the only Rev 0 connected GPIO with no pin on the `mcu` sheet.

³ See [The Encoder And Limit Switch Do Not Reach The
MCU](#the-encoder-and-limit-switch-do-not-reach-the-mcu).

⁴ Was `V5_SENSE` on divided `+5V_SW` until 2026-08-16. See [What The Rail Sense
Is Actually For](#what-the-rail-sense-is-actually-for). The `mcu` sheet pin named
`SW_RAIL_SENSE` carries the **raw** `+3.3V_SW` rail into the sheet; `R401`/`R402`
(1 kΩ/1 kΩ) divide it inside `mcu`, and the divided node on `GP26` is
`SW_RAIL_SENSE_DIV_2`.

⁵ **Added 2026-08-17.** `GP14` drives the `TPS1HTC100-Q1`'s `DIAG_EN` through
`R202` 1 kΩ. See the note on `DIAG_EN` below.

⁶ **Freed 2026-08-26** when the rev 1 analog output block was built. The
`DAC80501` has no hardware `LDAC` and no hardware `CLR` pin at all — synchronous
update is the `DAC_SYNC_EN` bit plus the `TRIGGER` register's `LDAC` bit, and a
soft reset writes `0x1010` to `TRIGGER`. Both functions survive; they cost zero
pins instead of two. See `docs/encoder-analog-output.md`.

**Rev 0: 18 connected, 6 reserved, 6 spare.**
**Full scope: 24 connected, 6 spare (`GP12`, `GP15`, `GP16`, `GP17`, `GP18`,
`GP27`).**

**Four pins were freed on 2026-08-16** and the allocation went from comfortable to
roomy. That matters for more than tidiness — see the note on rev 2 below. One of
the four, `GP14`, was spent again on 2026-08-17.

**Two more were freed on 2026-08-26**, and unlike every earlier reclaim these
cost nothing at all. `GP12` and `GP17` were not traded away or descoped — the
part chosen for the analog output simply does not have the pins they were
reserved for. That is the difference between this reclaim and the
`TMC_REF_STIM` trade below, and it is why the rev 2 arithmetic changes sign.

`DIAG_EN` on the input block's switch is on **`GP14`, through `R202` 1 kΩ**.
**Reversed 2026-08-17**; earlier guidance said tie it to `+3.3V`, not to a GPIO,
because diagnostics have no reason to be gated and tying it costs no pin. That
reasoning was right about diagnostics and wrong about the cost. Held high, the
`TPS1HTC100-Q1`'s OFF-state open-load detection keeps an internal ~150 kΩ pull-up
from `VS` to `VOUT` permanently enabled (`ROL_OFF` 110-166 kΩ), injecting ~240 µA
into `+36V_SW`. Against that rail's ~208 µF the voltage creeps at ~1.2 V/s and
crosses the `TPSM365R6`'s 3.6 V minimum `VIN` in about 3 s, so the buck starts,
collapses, and hiccups — the switched domain never cleanly powers off. That
breaks the property that `HV_EN` power-cycles every resettable chip, and it
corrupts `SW_RAIL_SENSE`. `DIAG_EN` has an internal pull-down, so with `GP14`
high-Z at reset diagnostics are off and `+36V_SW` sits at true zero. Per the
device's Table 7-1 the current limit and thermal shutdown are unaffected by
`DIAG_EN` — only reporting is gated — so **firmware must raise `GP14` before
reading `HV_SNS` or `~{HV_FAULT}`**. Without it neither works at all; see
`docs/power.md`.

### The Encoder And Limit Switch Do Not Reach The MCU

**Decided 2026-08-16.** `ENC_A`, `ENC_B`, and `LIMIT_SW` are the TMC5130A's
business. The encoder goes from `J1103` through the board's conditioning chain to
`ENCA`/`ENCB`; the debounced limit switch goes to `REFL`. **Neither reaches an
RP2040 pin, in any revision.** Firmware gets position from the driver's
`X_ENC`/`XACTUAL` register and homing state from the driver's status, both over
SPI.

**There is no `ENC_N` net on the board.** Earlier drafts of this section listed
one alongside `ENC_A`/`ENC_B`; as built (2026-08-17) `J1103` pin 2 is a reserved
index **no-connect** and the TMC5130A's `ENCN` pin is terminated by `R1201` 10 kΩ
to GND, which is what the datasheet asks for on an unused encoder input. The
index is a rev-1 decision, not a Rev 0 signal.

This frees `GP14`, `GP15`, `GP16`, and `GP18`. `GP14` was spent again on
2026-08-17 on `HV_DIAG_EN`.

**What it deletes, permanently rather than deferring:**

- The **RP2040 PIO encoder cross-check**. It is not "rev 1" any more, it is gone.
- **`ENCODER_MISMATCH`** in `docs/uart-protocol.md`. There is no second count to
  disagree with and there never will be, so the fault code should be retired
  rather than left reserved.
- The `GP14`/`GP15`/`GP16` **contiguity constraint**. It existed only to let one
  PIO state machine read A, B, and the index with a single input mapping. Those
  three pins are now ordinary spares with no adjacency requirement — which is
  precisely what made `GP14` available for `HV_DIAG_EN` on 2026-08-17.
- The MCU's **independent copy of the limit switch**. Firmware learns a homing
  event from the driver, one SPI poll later than the hardware `REFL` latch — which
  is the same latency the design already accepted, since `REFL` was always the
  hardware path and `GP18` was always just a witness.

**What replaces the witness:** the InstrumentPort. `ENC_A`, `ENC_B`, and
`LIMIT_SW` are all on it in Rev 0, which is now the *only* way to see those
signals independently of the driver's own report. That is a stronger reason for
them to be on the port than existed when the MCU also had copies.

**Rev 2 fits on RP2040 with room, as of 2026-08-26.** Full scope is 24 of 30
with six spares, and the brake plus torque front end for a single axis needs
about six GPIOs — `BRAKE_DIM`, `~{BRAKE_FAULT}`, a brake current monitor on ADC,
two for the torque bus, and `TQ_DRDY`. That is **six wanted against six spare**
even keeping `TQ_DRDY`, with `GP27` ADC-capable for the current monitor. Drop
`TQ_DRDY`, which the bus capture already implies, and there is a pin left over.

**This reversed twice.** Until `GP14` became `HV_DIAG_EN` on 2026-08-17 it was
five for five with nothing to reclaim; that day it became five wanted against
four spare, one pin short of free, and the fix was to spend reclaim-order item 1.
On 2026-08-26 the analog output block landed on a part with no `LDAC` or `CLR`
pin and returned `GP12` and `GP17` for nothing, which closes the gap outright
rather than by trading a function away. **Reclaim-order item 1 is now void** —
see below.

**The twin-axis board needs RP2354B because it carries two of everything; this
board may not.** Do not treat that as settled — it is an observation to check
when the rev 2 circuits are actually specified, not a commitment. It is a
stronger observation than it was, but the rev 2 circuits are still unspecified.

### What The Rail Sense Is Actually For

**`GP26` senses `+3.3V_SW` through a ÷2 divider as of 2026-08-16**, replacing a
divided `+5V_SW` sense. Same two resistors, better measurement — sensing the end
of the chain confirms 36 V, 5 V, and 3.3 V in one reading, and `+3.3V_SW` is the
rail that actually gates the decision, because it is what powers the far side of
the bus switch.

**Where the divider physically sits, as built 2026-08-17.** The `mcu` sheet pin
called `SW_RAIL_SENSE` carries the **raw** `+3.3V_SW` rail across the sheet
boundary; `R401`/`R402` (1 kΩ/1 kΩ) divide it *inside* `mcu`, and the ADC pin sees
`SW_RAIL_SENSE_DIV_2`. Two consequences worth holding on to. The `mcu` sheet pin
is therefore a rail tap, not a signal, so do not expect a 1.65 V node at the sheet
boundary. And **`R401`/`R402` are also what holds `+3.3V_SW` at 0 V when the
switched domain is off** — a 2 kΩ bleed to GND — which is the property the
board-level pull-ups to `+3.3V_SW` depend on. Removing the divider would leave
`~{TMC_CS}`, both `DIAG` lines, and `~{TMC_DRV_EN}` undefined in the off state.

**Why not delete it, given the TMC answers SPI when the rails are up?** Because of
a circularity. `docs/power.md` makes the rail sense one of three supporting
measures for the isolation architecture: *reconnect only after the rails are
confirmed up*. SPI reaches the TMC5130A **through the bus switch you are deciding
whether to enable**, so it cannot confirm anything before that decision. Enabling
the bus into an unpowered driver is precisely the back-power failure the whole
architecture exists to prevent. The sense must bypass the bus switch, and `GP26`
does.

**It is substantially redundant with `HV_SNS`**, though, and that is worth knowing
if the pin is ever wanted elsewhere. `GP28` also bypasses the bus switch, and the
buck, the LDO, and the driver draw quiescent current whenever the rail is really
up, so a near-zero `HV_SNS` after raising `HV_EN` already means "the rail did not
come up." Gating on `HV_SNS` plus a timeout would be defensible.

**`~{HV_FAULT}` does not cover this**, and it is worth being explicit about why:
with no 36 V present the `TPS1HTC100-Q1` is itself unpowered, so its open-drain
fault output floats and the pull-up reads it as *no fault*. The most likely
failure on the bench — nobody plugged the supply in — is invisible to `~{HV_FAULT}`
and obvious to either `SW_RAIL_SENSE` or `HV_SNS`.

**Firmware rule:** after raising `HV_EN`, confirm `SW_RAIL_SENSE_DIV_2` reads a
valid `+3.3V_SW` before deasserting `~{BUS_SW_EN}`. Refuse `ARM` with a specific
reason when it does not, and report the reading in `STATUS`.

### Signal Direction And Sheet Pin Types

**A hierarchical pin's direction is stated from the point of view of the sheet
that owns it.** `Output` means the signal leaves this sheet; `Input` means it
enters. The same net is `Output` on the sheet that drives it and `Input` on every
sheet that reads it. Nothing about the direction is global — `TMC_SPI_SCK` is an
`Output` on `mcu` and an `Input` on the `tmc5130` sheet, and both are correct.

#### `DIO-A` Is This Board's RX. `DIO-B` Is This Board's TX.

This is the one crossover on the board that reliably gets wired backwards, and
the trap is that the alphabetical order reverses:

```
  RJ-45 pin 1   DIO-A   host TX  ──▶  PYC_DIO_A  ──▶  PYC_UART_RX  ──▶  GP1  (UART0 RX)
  RJ-45 pin 4   DIO-B   host RX  ◀──  PYC_DIO_B  ◀──  PYC_UART_TX  ◀──  GP0  (UART0 TX)
```

`A` → `RX`, `B` → `TX`. Both names are right; they are named from different ends.
The pyControl block names its pins by **connector position** on purpose, so a
board cannot mirror them by accident — that is exactly what the block's own
description warns about. This board names its nets by **MCU function**. The
crossover happens once, at the `mcu` sheet boundary, and nowhere else.

Sanity check that needs no documentation: `PYC_UART_TX` must be an `Output` on
`mcu`. If a sheet pin named `*_TX` is an `Input`, it is wrong.

#### `mcu` Sheet Pins

Everything crossing the `mcu` sheet boundary in Rev 0. The **Far side** column is
what the mating block already declares, so a mismatch here is a wiring error.

| `mcu` pin         | Type              | Mates with                                                      | Far side declares |
|-------------------|-------------------|-----------------------------------------------------------------|-------------------|
| `PYC_UART_TX`     | **Output**        | `pycontrol_behavior_port_rj45_boundary` `PYC_DIO_B`             | passive           |
| `PYC_UART_RX`     | **Input**         | `pycontrol_behavior_port_rj45_boundary` `PYC_DIO_A`             | passive           |
| `~{TMC_CS}`       | **Output**        | `tmc5130` `~{CS}`                                               | input             |
| `~{TMC_DRV_EN}`   | **Output**        | `tmc5130` `~{DRV_EN}`                                           | input             |
| `TMC_SPI_SCK`     | **Output**        | `tmc5130` `SCK`                                                 | input             |
| `TMC_SPI_COPI`    | **Output**        | `tmc5130` `SDI`                                                 | input             |
| `TMC_SPI_CIPO`    | **Input**         | `tmc5130` `SDO`                                                 | output            |
| `TMC_DIAG0`       | **Input**         | `tmc5130` `SWN_DIAG0`                                           | bidirectional     |
| `TMC_DIAG1`       | **Input**         | `tmc5130` `SWP_DIAG1`                                           | bidirectional     |
| `HV_EN`           | **Output**        | `hv_input_36V_terminal_2pos_5p08_protected` `ENABLE`            | input             |
| `HV_SNS`          | **Input**         | `hv_input_36V_terminal_2pos_5p08_protected` `SNS`               | output            |
| `~{HV_FAULT}`     | **Input**         | `hv_input_36V_terminal_2pos_5p08_protected` `~{FAULT}`          | output            |
| `SW_RAIL_SENSE`   | **Input**         | the raw `+3.3V_SW` rail; `R401`/`R402` divide it inside `mcu`   | passive           |
| `FW_TRIG0`        | **Output**        | buffer `U1801` — no test pad exists, see below                  | input             |
| `FW_TRIG1`        | **Output**        | buffer `U1801` — no test pad exists, see below                  | input             |
| `~{INSTR_BUF_OE}` | **Output**        | `~{OE}` on all three buffer instances                           | input             |
| `USB_D+`          | **Bidirectional** | `usb2` `USB_D+`                                                 | bidirectional     |
| `USB_D-`          | **Bidirectional** | `usb2` `USB_D-`                                                 | bidirectional     |
| `+5V_MCU`         | Passive           | the ORed USB / pyControl 5 V node                               | passive           |
| `+3.3V_MCU`       | Passive           | `GP1` pull-up, buffers, and the input block's `+3.3V_MCU`       | passive           |
| `HV_DIAG_EN`      | Output            | input block `DIAG_ENABLE`; `GP14` through `R202` 1 kΩ           | input             |
| `GND`             | Passive           | board ground                                                    | passive           |

**Twenty-two pins in Rev 0** — ten Output, seven Input, two Bidirectional, three
Passive. (**Corrected 2026-08-17**; the sentence used to say twenty pins and six
Input against twenty-one rows, and `HV_DIAG_EN` was added the same day.) Verified
directly against `mouse-joystick-pcb.kicad_sch`: the `mcu` sheet carries 22 pins,
and the far side is named `DIAG_ENABLE`, not `DIAG_EN`, on
`hv_input_36V_terminal_2pos_5p08_protected`. Note there is no `LIMIT_SW` and no
encoder pin on this sheet; those signals never reach the MCU.

Reserved signals get no pin until their far end exists. **Corrected 2026-08-17**:
they are *not* pre-wired inside `mcu` either. The earlier text said their A-side
channels are wired and stop at the bus switch; as built the unused bus-switch
channels have their **A pins open and their B (MCU-side) pins tied to GND**, so
rev 1 has to edit the isolation block regardless — see [The Block Is Oversized For
This Board](#the-block-is-oversized-for-this-board--accepted). When they arrive:
`DAC_SPI_SCK`, `DAC_SPI_COPI`, `~{DAC_CS}`, `PYC_PULL_EVENT`, and `PYC_FAULT`
are **Output**; `PYC_RSYNC_IN` is **Input**. (**Updated 2026-08-26**:
`~{DAC_LDAC}` and `~{DAC_CLR}` are gone from this list — the part has neither
pin.)

Rev 1 also adds three pins that are **not** GPIOs and are easy to miss when
counting: the analog output block needs `+5V_SW` and `GND`, and its `AOUT`
leaves as an **Output** on whatever sheet holds it. `AOUT` does not cross the
`mcu` boundary at all — it goes from the block to the BNC (`J1101`).

#### The Bus Switch Does Not Change Direction

Seven of the Rev 0 pins above — the `sw` group, `GP2`-`GP8` — leave
`mcu` from the **A side** of the isolation bus switch, whose A and B pins the
block correctly declares `passive`, because a FET pass gate is passive silicon.
That means the A-side net inside `mcu` has no driver of its own, and **the sheet
pin is what tells KiCad the net is driven.** Give it the MCU's direction anyway:
the switch passes the signal, it does not reverse it.

**Corrected 2026-08-17.** This paragraph used to say the pins leave from the B
side. As built the orientation is the other way round — **A is the TMC / switched
side and B is the MCU side** — so it is the A-side nets that cross the sheet
boundary. Nothing about the direction argument changes; the part is a symmetric
FET pass gate.

Do not reach for `Tri-state` to express the isolated state. It is closer to
literally true, but KiCad has no shape meaning "sometimes disconnected", it adds
no ERC value, and it would make the `sw` and `byp` groups look different for a
reason that is about the switch rather than about the signal.

#### Every Net Wants Exactly One Driver

`Output` and `Bidirectional` drive; `Input` and `Passive` do not. Three families
on this board were flagged as having **no on-board driver at all**, because the
source is off-board or a passive network, and KiCad's "input not driven" check
says so. **Two of the three are settled as of 2026-08-17; ERC now reports zero
violations at every severity.**

| Net                     | Why it has no driver                                               | What to do                                                                            |
|-------------------------|--------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| `PYC_UART_RX`           | Driven by the pyControl host through an all-passive block boundary | **Done 2026-08-17** — `PYC_DIO_A`/`PYC_DIO_B` are now `bidirectional`                 |
| `ENC_A`/`ENC_B`         | Driven on-board by `U801`'s Schmitt outputs as of 2026-08-17       | **No longer applies.** And there is no `ENC_N` net at all — see below                 |
| `SW_RAIL_SENSE_DIV_2`   | A ÷2 divider off `+3.3V_SW` is a genuinely passive net             | Accept. `HV_SNS` is fine — the input block declares `SNS` as `output`                 |

The decision was to change the source pin types rather than exclude the ERC item,
and it is recorded here. Do not lower the rule's severity board-wide — it is the
check that catches a `*_TX` pin wired as an `Input`.

**`kicad-libs` change — done 2026-08-17.** `PYC_DIO_A` and `PYC_DIO_B` on
`pycontrol_behavior_port_rj45_boundary` are now `bidirectional` in both the
library block and this board's placed copy. The reasoning is kept below because
it is the precedent for the next connector boundary that needs it. The
reasoning for leaving them undirected is right — those lines genuinely could go
either way until a board assigns them — but `bidirectional` is the KiCad shape
that *means* that, whereas `passive` means "no active device here", which is what
a resistor or a shield tab is. It also matches house precedent: `usb2` declares
`USB_D+`/`USB_D-` bidirectional and `instrument_port_40_dut_ffc_boundary`
declares all eighteen `DIG*`/`TRIG*` bidirectional. The pyControl block is the
only connector boundary in the library that is all-passive. Two shape edits, no
topology change, no PCB impact.

### The Bus Switch Costs A Pin

Rev 0 adds the `rp2040_gpio_isolation_sn74cb3q3245` block, whose shared
active-low enable needs one GPIO. The allocation was at 29 of 30 with a single
spare **when this was decided on 2026-08-13**, so the enable had to come from
somewhere. The 2026-08-16 encoder and limit-switch cut has since freed four more
pins, which makes the trade below look cheap in hindsight — it was not cheap at
the time, and `TMC_REF_STIM` is not coming back regardless.

It is paid for by **permanently dropping `TMC_REF_STIM`**, the synthetic homing
stimulus that used to sit on `GP9`. That was already item 2 in the reclaim order
below, and it is the right one to spend: the limit switch now reaches `REFL`
through a real debouncer on its own terminal block, so homing is exercised by
closing the actual switch rather than by a GPIO impersonating one. Leave a test
pad on the `REFL` net so a jumper can still force a closure — **still outstanding
as of 2026-08-17; no test pads exist anywhere on the board.**

Net effect: **the trade was one-for-one.** Full scope is now 24 of 30 with six
spares, and that headroom arrived by two later routes: four pins on 2026-08-16
from the encoder and limit-switch cut, and two more on 2026-08-26 from the
analog output part.

### Reclaim Order If More Pins Are Needed

Item 2 of the previous list has been spent on `~{BUS_SW_EN}`. **Item 1 became
void on 2026-08-26.** What remains:

1. ~~**Tie `~{DAC_CLR}` high in hardware**, freeing `GP17`.~~ **Void.** The
   `DAC80501` has no `CLR` pin, so `GP17` is already spare and there is no
   software clear to give up — the function moved into the `TRIGGER` register.
   `GP12` came back the same way. This is the only entry ever removed from this
   list without being spent.
2. **Drop `TMC_DIAG1`**, freeing `GP8`. `DIAG0` alone, configured to report what
   matters. Route `DIAG1` to a test point.

**Neither is needed today, and the list is now one item long.** Six spares exist
— `GP12`, `GP15`, `GP16`, `GP17`, `GP18`, and `GP27` — so spend a spare before
spending a function. **There were five until 2026-08-17**, four after `GP14`
became `HV_DIAG_EN`, and six from 2026-08-26: see the rev 2 arithmetic above.

Notes:

- `GP23`, `GP24`, and `GP25` are free on the bare RP2040 QFN-56. They are
  reserved on Raspberry Pi Pico modules but not on a custom board.
  `tmc51x0-driver-dev-pcb` already uses `GP23` this way.
- **`GP15`/`GP16` no longer need to be contiguous with `GP14`.** That constraint
  existed only for a single PIO input mapping, and the PIO cross-check is gone.
  They are ordinary spares — and because the constraint went away, `GP14` was free
  to take `HV_DIAG_EN` on 2026-08-17.
- **The encoder reaches the TMC5130A only, in every revision.** It does **not** go
  straight from the connector to the driver, contrary to what this note used to
  say. As built (2026-08-17) the path is `J1103` → `R801`/`R802` 100 kΩ
  harness-side pull-downs → `R803`/`R804` 4.7 kΩ series → `C802`/`C803` 470 pF →
  `U801` `SN74LVC2G17` dual Schmitt on `+3.3V_SW` → `R805`/`R806` 100 kΩ output
  pull-downs → `ENC_A`/`ENC_B` → `ENCA`/`ENCB`. See [The Encoder And Limit
  Switch Do Not Reach The MCU](#the-encoder-and-limit-switch-do-not-reach-the-mcu)
  and [Where Each Signal Is Tapped](#where-each-signal-is-tapped).
- The limit switch reaches the TMC5130A `REFL` pin through the debouncer, and
  goes nowhere else on the MCU. `REFL` is the hardware-latched homing path;
  firmware reads homing state from the driver over SPI.
- `GP19` drives the `hv_input_36V_terminal_2pos_5p08_protected` block's `ENABLE`
  input. That block pulls `ENABLE` low, so the 36 V rail is **off until firmware
  drives it** — and so the board's power-on state is the idle state, with the MCU
  up on USB or pyControl and everything switched dark. Firmware cycling `GP19` is
  also the board's chip-reset mechanism; see `docs/power.md`.
- `GP28` reads the TPS1HTC100-Q1 `SNS` output. **Done 2026-08-17: the block's
  `R_SNS` is `R207` = 249 Ω** (`OW-PASS-CRCW0402249RFKED`, stocked), down from the
  1 kΩ the block shipped with — the pin signals faults by sourcing 5.2-6.4 mA into
  `R_SNS`, which at 1 kΩ lands at 3.3-4.4 V, above the RP2040's `VDD + 0.3 V`
  limit. At 249 Ω the fault level is 1.29-1.59 V and current reads 0.311 V/A. No
  divider needed. The safe upper bound is about 594 Ω, so ~470 Ω is available if
  ADC resolution ever matters. See `docs/power.md`.
- `GP29` reads the switch's `~FAULT` open-drain output: overload, short-circuit,
  and thermal shutdown. Needs an external pull-up to `+3.3V`; **fitted 2026-08-17
  as `R205` 10 kΩ to `+3.3V_MCU`.** The design block leaves this pin unconnected;
  this board routes it because it has the pin and because the motor rail can shut
  itself off. Note it reads *nothing useful* until `GP14` raises `DIAG_EN`.
- `GP26` senses **`+3.3V_SW`** through a divider — **corrected 2026-08-17**; this
  note still said `+5V_SW`, which the 2026-08-16 change had already superseded.
  That rail is dead whenever `HV_EN` is
  low or the 36 V supply is absent, which is the board's normal idle state, so
  this is the MCU's primary evidence that the switched domain is actually up.
  It gates step 3 of the sequencing rule above. `+5V_SW` is still required in
  Rev 0 — the TMC5130A's `VCC` minimum is 4.6 V — even though the analog output
  that also needs it is deferred to rev 1. **Updated 2026-08-26:** when it
  arrives, its `OPA197` needs 4.5 V minimum, so `+5V_SW` acquires a second
  independent reason to be a real regulated rail rather than the ORed MCU one.
  See `docs/power.md`.
- **`GP1` needs an external 10 kΩ pull-up to `+3.3V_MCU`; fitted 2026-08-17 as
  `R403`.** See
  [`GP1` Gets A Hardware Pull-Up](#gp1-gets-a-hardware-pull-up) below. This is a
  board-level part on the MCU side of the port block's series resistor, not part
  of `pycontrol_behavior_port_rj45_boundary`.

### `GP1` Gets A Hardware Pull-Up

**Decided 2026-08-14; fitted 2026-08-17 as `R403`.** A **10 kΩ 0402
(`OW-RES-10K-0402`, stocked) from `PYC_UART_RX` to `+3.3V_MCU`**, on the **MCU
side** of the port block's `R29001`, placed near the RP2040, in the board-authored
`mcu` sheet so a design-block re-place cannot lose it.

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

| Choice                        | Why                                                                                                                                                                                |
|-------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 10 kΩ                         | 330 µA load when the host drives low, trivial for an STM32 GPIO rated 8-20 mA. Wins against a ~50 kΩ internal pull-down if one is active                                           |
| `+3.3V_MCU`, not `+3.3V_SW`   | The pyControl UART bypasses the bus switch precisely so it works with the switched domain dark. Pulling to the switched rail would defeat that                                     |
| MCU side of `R29001`          | The point is to define the RP2040's input, so it must hold when the connector path is open — which is the unplugged-cable case. On the connector side it would only load the cable |
| Board level, not in the block | The block's boundary has no 3.3 V pin, and *which* 3.3 V domain is a board decision. Keep the block's interface at five pins                                                       |

**Keep the firmware pull enabled as well.** They parallel to ~8.3 kΩ and cost
nothing.

**`GP0` (TX) deliberately gets none.** A matching pull-up would keep the host
seeing idle-high while this board is in reset or BOOTSEL, but it fails
differently: with `+3.3V_MCU` dead and the cable connected, 10 kΩ to a 0 V rail
holds the host's RX **low**, a continuous break, which is arguably worse than
floating. That needs both USB absent and the pyControl 5 V branch open, so it is
a corner — but fit TX only if host-side framing noise actually shows up at
Gate B.

**Resolved 2026-08-17, and it made this recommendation mandatory rather than
prudent.** `docs/power.md` used to state that RP2040 GPIOs are "inputs with pulls
disabled at reset." That is **wrong**: every RP2040 GPIO resets with its internal
pull-**down** enabled — `PUE` = 0, `PDE` = 1 in `PADS_BANK0`. So the right-hand
column below is the one that applies, and `docs/power.md` needs the correction.
The same fact is why the bus switch's MCU (B) side needs no termination of its
own, and why `GP1` is the one pin that needs a hardware pull the other way.

| If pulls are disabled at reset          | If a pull-down is enabled at reset — **this one**                                               |
|-----------------------------------------|-------------------------------------------------------------------------------------------------|
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

| Peripheral | Use                                                                  | Pins                                            | Rev 0 |
|------------|----------------------------------------------------------------------|-------------------------------------------------|-------|
| `UART0`    | pyControl link, 115200 8N1                                           | `GP0`, `GP1`                                    | yes   |
| `SPI0`     | TMC5130A                                                             | `GP6` SCK, `GP7` TX, `GP4` RX, `GP2` CS as GPIO | yes   |
| `SPI1`     | DAC80501, write-only                                                 | `GP10` SCK, `GP11` TX, `GP13` CS as GPIO        | rev 1 |
| PIO0       | **Unallocated** — the encoder cross-check was deleted                | —                                               | —     |
| ADC        | `SW_RAIL_SENSE_DIV_2`, `HV_SNS`, `~{HV_FAULT}` as digital, one spare | `GP26`-`GP29`                                   | yes   |
| USB        | Debug console, CDC                                                   | dedicated USB pins                              | yes   |
| QSPI       | External flash                                                       | dedicated QSPI pins                             | yes   |

There is no second UART. The debug console is **USB CDC**, because `UART0`
belongs to pyControl. Rev 0's other rich observation path is the InstrumentPort,
which carries the TMC SPI bus and both directions of the pyControl link; the
event BNCs are still rev 1.

## GPIO Isolation

Rev 0 places `orb_weaver_private:rp2040_gpio_isolation_sn74cb3q3245` between the
RP2040 and the switched half of the board. It is four `SN74CB3Q3245` 8-channel
bidirectional FET bus switches — 32 channels, one shared active-low `~OE`, pulled
up by `R601` 7.87 kΩ to `+3.3V_MCU` so the bus is **isolated at power-on until
firmware enables it**.

**Corrected 2026-08-17: there is no `Ioff` second line of defence.** All four
`VCC` pins are on `+3.3V_MCU`, the always-on rail, so the packages are never
unpowered and `Ioff` never engages. Isolation rests entirely on the MCU holding
`~{BUS_SW_EN}` high, which `R601` makes the reset default. That is the deliberate
consequence of [The Bus Switch Runs From
`+3.3V_MCU`](#the-bus-switch-runs-from-33v_mcu) below — it is the price of being
able to isolate *before* switching off — but it means the enable is the only
mechanism, not the outer of two.

**Orientation, as built 2026-08-17: `A` is the TMC / switched side and `B` is the
MCU side.** This is inverted from what this document said before, and it matters
in two places — which side the sheet pins leave from, and which side the
instrument taps sit on. Channel pairing on the RGY-20 package is `A_n` = pin
(n+1), `B_n` = pin (19−n).

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
> switched domain** (`+36V_SW`, `+5V_SW`, `+3.3V_SW`). Everything else bypasses.

| Iso   | Applies to                                                                                                                                                               | Because                                                  |
|-------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------|
| `sw`  | TMC5130A SPI, enable, and diagnostics; the 3-wire DAC bus in rev 1                                                                                                       | All of them are parts that lose power when `HV_EN` drops |
| `byp` | pyControl UART; the pyControl TTL event lines; `HV_EN`, `HV_DIAG_EN`, `HV_SNS`, `~{HV_FAULT}`; `SW_RAIL_SENSE`; `FW_TRIG0`/`FW_TRIG1`; `~{BUS_SW_EN}`; `~{INSTR_BUF_OE}` | Nothing at the far end is ever unpowered by `HV_EN`      |

**Rev 0 isolates 7 channels; full scope isolates 10.** Both dropped by four on
2026-08-16, when the encoder and limit switch stopped reaching the MCU — those
were `sw` entries, which is why the `sw` row above no longer names the debouncer
copy or the encoder PIO tap. Full scope dropped by two more on **2026-08-26**,
when the analog output turned out to need three channels rather than five: the
`DAC80501` has no `LDAC` and no `CLR` pin. The as-built netlist confirms the 7:
six channels on `U601` and one on `U602`. The bypass group is **14** at full
scope — 13 until `HV_DIAG_EN` arrived on 2026-08-17 — which is larger than a
first pass suggests, and each entry earns it:

| Net                                                   | Why it bypasses                                                                                                                                                                                              |
|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `PYC_UART_TX`, `PYC_UART_RX`                          | The whole point of the architecture. pyControl is externally powered and must stay reachable when the switched domain is off — that is how the researcher talks to a board that is deliberately powered down |
| `~{BUS_SW_EN}`                                        | Circular otherwise — the enable cannot be behind the switch it enables                                                                                                                                       |
| `HV_EN`                                               | The `TPS1HTC100-Q1` runs from `HV_IN` and is never switched off. Rail control must not depend on bus state, and the MCU must be able to switch the rail back on while everything downstream is dark          |
| `HV_SNS`, `~{HV_FAULT}`, `HV_DIAG_EN`                 | Same device, same always-on supply, and their pull-ups sit on `+3.3V_MCU`. Fault status must be readable when the rail is off, and `DIAG_EN` has to be raisable to get it. Direct MCU connections, all three |
| `SW_RAIL_SENSE`                                       | It reports whether `+3.3V_SW` came up, which is the precondition for enabling the bus. Reading it through the bus would be circular                                                                          |
| `FW_TRIG0`, `FW_TRIG1`                                | No chip at the far end — only the InstrumentPort buffers — and they must stay observable while the bus is isolated. The test pads do not exist yet                                                           |
| `PYC_PULL_EVENT`, `PYC_FAULT`, `PYC_RSYNC_IN` (rev 1) | BNC connectors and pyControl, both outside the switched domain                                                                                                                                               |
| `~{INSTR_BUF_OE}`                                     | The `SN74LVC125A` buffers sit on `+3.3V_MCU` so the board can be observed while the switched domain is off                                                                                                   |

`tmc51x0-driver-dev-pcb` bypasses the same *kind* of set — its netlist shows
`~{BUS_SW_EN}` on `GPIO19`, `~{INSTR_BUF_OE}` on `GPIO23`, and `HV_EN` and both
`FW_TRIG` markers wired straight to the MCU, with 27 GPIO nets through the switch.
**This board bypasses considerably more**, because it has a genuinely two-domain
power tree and that board does not. Do not "align" the two.

**This board puts `~{BUS_SW_EN}` on `GP9`, not `GP19`.** The proven board uses
`GP19` because it has no 36 V enable there; here `GP19` is `HV_EN` and is already
wired into `mcu.kicad_sch`. Deliberate divergence, noted so nobody "fixes" it.

### The Block Is Oversized For This Board — Accepted

The block is four packages because it is built to isolate all 30 GPIOs. Under the
rule above this board isolates **7 in Rev 0 and 10 at full scope**, so two of
the four `SN74CB3Q3245` packages are dead weight in Rev 0 **and at full scope
too**. The 2026-08-16 encoder and limit-switch cut made this worse, not better,
and the 2026-08-26 analog output part made it worse again — **ten channels fit
in two packages with six to spare**, so `U603` and `U604` now have no path to
ever carrying a signal on this board. The decision to place the proven block
whole still stands on schedule grounds, but it is carrying twice the packages it
needs and the second half is no longer "reserved for later".

**As built 2026-08-17**, the seven live channels land on `U601` (six: `~{TMC_CS}`
A3, `~{TMC_DRV_EN}` A4, `TMC_SPI_CIPO` A5, `TMC_DIAG0` A6, `TMC_SPI_SCK` A7,
`TMC_SPI_COPI` A8) and `U602` (one: `TMC_DIAG1`, A1/B1). **`U603` and `U604` carry
no channels at all** and are an open decision before placement. The earlier
crossed-label defect that put `TMC_DIAG1` on a hard ground is fixed; all 32
channels were audited.

| Option                                                          | Cost                                                    | Benefit                                                        |
|-----------------------------------------------------------------|---------------------------------------------------------|----------------------------------------------------------------|
| **A.** Place the block whole, wire 16 channels, leave 16 unused | 3 unnecessary ICs, their decoupling, and the board area | Proven block, zero design work, obvious upgrade path           |
| **B.** Board-local section with two `SN74CB3Q3245`              | Two ICs, a new schematic section to verify              | Half the parts and area; matches what the board actually needs |

**Decided 2026-08-13: option A.** Place the proven block whole and leave the
unused channels alone — 25 of its 32 as built, not the 16 this option's row
predicted, because the encoder and limit-switch cut landed after the decision.
Two `SN74CB3Q3245` packages and their decoupling are
wasted, and that is accepted — the block is already placed, already proven, and
Rev 0 is optimising for schedule. Option B remains the right answer for a later
revision if board area becomes the binding constraint.

**Reversed 2026-08-17.** Earlier guidance said to wire the **A (MCU) side of all
16 isolated GPIOs now**, including the 8 reserved for rev 1, leave the B side of
the reserved channels unconnected, and let a later revision add board-side wiring
only — no re-place, no re-pin, no firmware change. Neither half of that is what
the board does. **A is the switched side, not the MCU side**, and the unused
channels are not pre-wired at all: their **A pins are open and their B (MCU-side)
pins are tied to GND**. Tying the MCU side down is the right treatment for an
unused FET pass gate — it leaves no floating node on the always-on rail — but it
means **rev 1 has to edit this block to reach the DAC channels**, so the
"adds them without moving anything" property was never delivered. Plan for a block
edit at rev 1, and prefer option B if that edit is happening anyway. Bypass-group
signals stay off the switch entirely, which is unchanged.

**Updated 2026-08-26 — option B is now the clear answer.** The rev 1 edit needs
only **three** channels (`DAC_SPI_SCK`, `DAC_SPI_COPI`, `~{DAC_CS}`), which fit
in `U602`'s seven free channels without touching `U603` or `U604`. Since the
block has to be edited anyway, and since the full-scope requirement is now ten
channels against thirty-two placed, the schedule argument that carried option A
has expired. Do the swap when rev 1 opens the block, not before — Rev 0 is
already ERC-clean with option A placed.

#### The DAC Bus Terminations — All Three Are In The Block

**Corrected 2026-08-27.** This section previously said one was in the block and
two were board-level. All three now live in the block, and the board owns none of
them:

| Net              | Termination                  | Where        | Required? |
|------------------|------------------------------|--------------|-----------|
| `~{DAC_CS}`      | 10 kΩ **pull-up** `+3.3V_SW` | **In block** (`R2006`) | **Yes** |
| `DAC_SPI_SCK`    | 10 kΩ pull-down to GND       | **In block** (`R2009`) | Hygiene |
| `DAC_SPI_COPI`   | 10 kΩ pull-down to GND       | **In block** (`R2008`) | Hygiene |

So the board's nine 10 kΩ terminations stay **nine**, not eleven. The two
pull-downs moved into the block on 2026-08-27 because nothing about them is
board-dependent — 10 kΩ to GND is right on any board — and a block re-place
cannot then lose them.

**Do not add board-level copies when the `DIG9`/`DIG10`/`DIG6` instrument taps go
in.** Those taps sit on the A / switched side of the bus switch and need defined
levels for exactly the reason `R1401`-`R1404` exist on the TMC taps, but these
three resistors already provide them. A second set in parallel would halve them.

Only the pull-up is load-bearing: the `DAC80501` blocks `SCLK` and `SDIN`
entirely while `SYNC` is high, and a frame interrupted before its 24th `SCLK`
falling edge is discarded with no register update. The other two prevent
floating CMOS inputs, not a functional failure. Because the required one is
functional rather than board-dependent, hosting it in the block means no board
can omit it — the trade is a seventh boundary pin.

**That seventh pin is `+3.3V`, and it must bind to `+3.3V_SW`.** Binding it to
`+3.3V_MCU` would hold `~{DAC_CS}` at 3.3 V while the DAC's own `VDD` is dead,
pushing roughly 260 µA through the DAC's input clamp into `+5V_SW` — the exact
back-power mechanism the bus switch exists to prevent, reintroduced inside a
block where the bus switch cannot see it. This is the same rule the board
already applies to the buffer terminations: *the switched-domain nets
deliberately do not reference `+3.3V_MCU`.*

**Do not pull any of the three to the DAC's 5 V rail.** The `SN74CB3Q3245` is a
symmetric FET pass gate, so a 5 V pull-up on the switched side lands on an
RP2040 pad and exceeds its `IOVDD + 0.3 V` limit. `+3.3V_SW` is correct and
sufficient — the `DAC80501`'s `VIH` is 1.62 V, so even against the RP2040's
internal pull-down the ~2.75 V divider result has margin, the same arithmetic
that justifies `R403` on `GP1`.

### The Bus Switch Runs From `+3.3V_MCU`

It has to. Powering it from `+3.3V_SW` would give free isolation through `Ioff`
whenever `HV_EN` is low and would cost no GPIO at all — but it would hand the
sequencing to a rail ramp instead of to firmware, and it would remove the ability
to isolate *before* switching off. Rejected deliberately; recorded in
`docs/power.md` so it is not rediscovered as a clever idea.

### Sequencing Rule

Falls straight out of the architecture, and firmware must follow it:

**Powering the switched domain down**

1. Assert `~{BUS_SW_EN}` high — isolate first.
2. Drive `HV_EN` low.

**Powering it back up**

1. Drive `HV_EN` high.
2. Wait for the buck and LDO to settle.
3. Confirm `+3.3V_SW` is up on `SW_RAIL_SENSE_DIV_2` — readable because it
   bypasses.
4. Assert `~{BUS_SW_EN}` low — connect last.

Isolating first and connecting last means no MCU pin is ever driving a rail that
is on its way down or not yet up. Getting this backwards is the failure this
whole arrangement exists to prevent, so **test it at Gate B** with a scope on
`+3.3V_SW` and one TMC input.

### Firmware Consequences

Properties of the hardware, not choices:

- **The pyControl link works with the bus isolated.** `GP0`/`GP1` bypass, so the
  board answers `ID`/`STATUS` in its idle state and can report *why* the motor
  rail is off. This is the behaviour the architecture is for.
- **The USB CDC console is likewise unaffected** — USB uses dedicated pins, not
  the GPIO matrix.
- **The power-monitoring group is readable at all times.** `SW_RAIL_SENSE_DIV_2`,
  `HV_SNS`, and `~{HV_FAULT}` all bypass, so firmware can diagnose the switched
  domain without enabling anything. The earlier boot-order awkwardness is gone.
  **`HV_SNS` and `~{HV_FAULT}` need `GP14` (`HV_DIAG_EN`) raised first** — the
  smart switch gates reporting on `DIAG_EN`, and `GP14` is high-Z at reset.
- **Nothing on the switched domain is reachable until the bus is enabled.** SPI to
  the driver, and in rev 1 the DAC. Firmware must treat a read from either as
  invalid while `~{BUS_SW_EN}` is high rather than returning stale or floating
  data.
- **Position and homing come only from the driver.** The encoder and the limit
  switch never reach a GPIO, so while the bus is isolated firmware has no
  position and no homing state at all — not stale data, none. Report that
  honestly in `STATUS` rather than caching the last value.
- **`GP1` has a hardware pull-up, and firmware should still enable its own.**
  The external 10 kΩ defines RX before firmware runs; the internal pull is the
  second layer. Do not treat the hardware part as permission to skip it. See
  [`GP1` Gets A Hardware Pull-Up](#gp1-gets-a-hardware-pull-up).
- Report both `~{BUS_SW_EN}` and `HV_EN` state in `ID`/`STATUS`. A session that
  silently runs isolated should be impossible to mistake for a working one.

## Connector Complement

Designators are assigned for the **full** scope and Rev 0 populates a subset.

**Renumbered 2026-08-17 to the as-built annotation.** The flat `J1`-`J11`
sequence this section used is not what the board carries; annotation is
sheet-scoped, so the 36 V terminal is `J201` and USB-C is `J301`.

**Renumbered again 2026-08-27, and the no-renumbering policy is withdrawn.** This
paragraph used to say that gaps within each sheet's hundred were deliberate and
that "renumbering later would break the silkscreen, the documentation, and the
bring-up log for no benefit." A global re-annotation then happened by choice, when
the analog output block gained its filter and the decision was taken to use
KiCad's automatic annotation rather than hand-preserving numbers. Automatic
annotation orders by sheet position, so inserting parts rotates everything after
them.

Three connectors in the `motor_encoder_switch` sheet rotated:

| Carries                       | Was            | **Now**   |
|-------------------------------|----------------|-----------|
| Analog angle out, BNC         | `J7` (placeholder) | **`J1101`** |
| Stepper coils, 4-pos 3.5 mm   | `J1101`        | **`J1102`** |
| Encoder, 5-pos 3.5 mm         | `J1102`        | **`J1103`** |
| Limit switch, 2-pos 3.5 mm    | `J1301`        | `J1301` (unchanged) |

The 4-, 5- and 2-position housings are not mechanically interchangeable, so no
harness can be plugged into the wrong terminal. The hazard is documentary, not
electrical.

**Rev-0 boards in hand carry the old silkscreen.** A technician holding a rev-0
board reads `J1101` = motor while this document says `J1101` = BNC. `docs/bringup-log.md`
keeps one section set per board serial; record the designator scheme in each
board's section rather than assuming the current table applies to older units.

**The consequence for this document, and every other one:** designator numbers are
no longer stable across revisions. Name things by role and net — "the encoder
terminal", "the `~{DAC_CS}` pull-up" — and give the designator as a
current-as-of-date convenience rather than as the identifier. Tables like the one
below are the right place for designators; prose is not.

| Ref     | Connector                                                               | Carries                                                 | Rev 0   |
|---------|-------------------------------------------------------------------------|---------------------------------------------------------|---------|
| `J201`  | 2-pos 5.08 mm pluggable terminal, Phoenix `1757242` (`OW-CONN-1757242`) | 36 V motor supply in                                    | **yes** |
| `J301`  | USB-C receptacle (`usb2` block)                                         | Firmware load, USB CDC console, logic-rail power source | **yes** |
| `J1901` | RJ-45, `OW-CONN-J1B1211CCD` or `OW-CONN-438600001`                      | pyControl port: UART + GND only in Rev 0                | **yes** |
| `J1501` | 40-pin 0.5 mm FFC, `OW-CONN-5051104091`                                 | InstrumentPort-40                                       | **yes** |
| `J1101` | Single BNC, `OW-CONN-HL-BNC-KHDA` (vertical)                             | `ANGLE_OUT` — **rev 1, placed 2026-08-27**              | rev 1   |
| `J1102` | 4-pos 3.5 mm terminal, `OW-CONN-TBH-1X04-3P5-VERT`                      | Stepper coils                                           | **yes** |
| `J1103` | 5-pos 3.5 mm terminal, `OW-CONN-TBH-1X05-3P5-VERT`                      | Encoder: supply, return, `A`, `B`; pin 2 reserved       | **yes** |
| `J8`    | Dual BNC, `DOSIN-801-0095`                                              | `PYC_PULL_EVENT`, `PYC_FAULT`                           | rev 1   |
| `J9`    | Dual BNC, `DOSIN-801-0095`                                              | `PYC_RSYNC_IN`, spare                                   | rev 1   |
| `J10`   | SWD header                                                              | Debug — **not implemented**, see below                  | no      |
| `J1301` | 2-pos 3.5 mm terminal, `OW-CONN-TBH-1X02-3P5-VERT`                      | Limit switch, inside the debounced input block          | **yes** |

**Seven connectors in Rev 0, three deferred.** `J1501` moved into Rev 0 on
2026-08-16 with the InstrumentPort. **Corrected 2026-08-17**: the count used to
say eight and three, which counted the SWD header as populated. **Updated
2026-08-27**: the analog BNC is placed as `J1101`, so four deferred becomes three
(`J8`, `J9`, `J10`). `J8` and `J9` keep placeholder numbers until their sheets
exist — expect them to renumber when they do.

The three terminals switched to the vertical `OW-CONN-TBH-*-VERT` family in the
same pass that made the other connectors vertical; the horizontal Phoenix
`OW-CONN-1844236`/`1844249`/`1844210` parts this table used to name are no longer
what the board carries.

#### `AUX_ANALOG_OUT` And The Dual BNC — Closed 2026-08-27

~~`J7` Dual Versus Single — Reopened 2026-08-26.~~ **Closed by construction.**

The board carries a **single vertical `HL-BNC-KHDA`** as `J1101` — neither of the
two options this section debated. The dual `DOSIN-801-0095` was specified when the
analog output was going to be a dual `DAC8563` and the second channel cost a
footprint and two passives. The built block is single-channel, so
`AUX_ANALOG_OUT` costs a second full instance — one more `DAC80501`, one more
`OPA197`, and the passives — and it is not populated. The stocked single
`DOSIN-801-0050` was the fallback but was not what got placed; the vertical
`HL-BNC-KHDA` matches the rest of the board's vertical connector direction and has
four ground pins at ±5 mm around the centre pin, which is what lets `D2001`'s
ground via land on a connector ground pin.

`AUX_ANALOG_OUT` is therefore **not on this board at rev 1**, and `AIN1_P/N` stay
no-connect. If it is ever wanted, it is a second block instance on its own
hierarchical sheet plus a second jack, not a stuffing option.

The related question — whether a second channel would carry a validity signal —
is in `docs/encoder-analog-output.md`. It was nearly free and is now not, so the
argument for encoding validity into the angle signal's own out-of-band levels
correspondingly got stronger.

### The SWD Header Is Deferred, By Decision

**Decided 2026-08-17.** `J10` is not on the board. `SWCLK`, `SWD`, and `RUN` on
the RP2040 are left unconnected and explicitly NC-flagged, and the header waits
for a future board revision.

**This is an access limitation, not an electrical defect.** RP2040 `RUN` has an
internal pull-up of 50-80 kΩ and the datasheet permits leaving it floating or
tying it to `IOVDD`, so the part boots correctly with nothing attached; the
NC flags are there so ERC agrees that the omission is intentional rather than an
unfinished net.

What it costs, stated plainly so bring-up does not discover it:

- **No debugger.** No SWD means no breakpoints, no single-stepping, and no
  post-mortem of a hung core. Firmware debugging is USB CDC prints and the
  InstrumentPort capture, which is exactly why the port was pulled forward.
- **No hardware reset line.** BOOTSEL recovery means holding `SW501` while power
  cycles, and with the ORing diodes that requires **both USB and pyControl
  unplugged** before power returns — pulling the USB cable alone leaves the board
  alive on pyControl 5 V. Write that into the bring-up procedure.

The motor terminal (`J1102`), the encoder terminal (`J1103`), and the limit-switch
terminal (`J1301`) are one stocked 3.5 mm screw-terminal family
(`OW-CONN-TBH-1X04-3P5-VERT`, `-1X05-`, `-1X02-`), which keeps the harness story
uniform and needs no purchase. **Updated 2026-08-27**: these are the vertical
`TBH` parts, not the horizontal Phoenix `OW-CONN-1844236`/`-1844249`/`-1844210`
this paragraph used to name, and the motor and encoder designators rotated — see
the renumbering note above.

**They are screw terminals, not locking.** The earlier plan called for a locking
motor connector because the rig gets handled. Screw terminals unblock Rev 0
today; if the rig proves that insufficient, sourcing a locking 4-pos motor
connector is a rev 1 change confined to the motor terminal. Decide before the
harness is built, not after.

## pyControl Port In Rev 0

Only the serial link is populated. See `docs/pycontrol-port-pinout.md` for the
full pinout and its provenance.

| RJ-45 pin  | Signal                             | Rev 0                                                                     |
|------------|------------------------------------|---------------------------------------------------------------------------|
| 1          | `DIO-A`                            | RP2040 `UART0 RX` (`GP1`)                                                 |
| 2          | `GND`                              | Ground                                                                    |
| 4          | `DIO-B`                            | RP2040 `UART0 TX` (`GP0`)                                                 |
| 6          | `5V`                               | Footprint for the ORing branch; population gated on the port's 5 V budget |
| 3, 5, 7, 8 | `POW-A`, `SPECIAL`, `POW-B`, `12V` | Not connected                                                             |

Series resistors and ESD protection on every populated port signal.

`PYC_PULL_EVENT`, `PYC_FAULT`, and `PYC_RSYNC_IN` are rev 1. Both DIO lines are
consumed by the UART, so when those lines arrive they still land on BNCs — that
analysis is unchanged and is why `J8` and `J9` keep their designators.

## What Rev 0 Gives Up

Stated plainly so nobody discovers it during bring-up:

- **No independent encoder cross-check, ever.** As of 2026-08-16 this is
  permanent rather than deferred: the encoder reaches the TMC5130A only, in every
  revision. `ENCODER_MISMATCH` in `docs/uart-protocol.md` has no second count to
  compare against and should be retired rather than left reserved. Encoder
  integrity rests on the driver's own count plus the index pulse. **The
  InstrumentPort narrows this** — `ENC_A` and `ENC_B` are captured alongside the
  SPI reads of `X_ENC`, so the decoding can be checked by hand. That is a bench
  capability, not a runtime fault, and it goes away at rev 2.
- **No MCU copy of the limit switch.** Firmware learns a homing event from the
  driver over SPI, not from a GPIO. `LIMIT_SW` is on the InstrumentPort in Rev 0;
  the test pad it was also meant to have does not exist yet.
- **No analog angle output.** The researcher-facing 0-5 V BNC is rev 1. Angle is
  available over the UART only.
- **Seven of the eighteen InstrumentPort digital Strands are unrouted**, and the
  two rev-1 buffer packages were never placed at all. Rev 0 captures the TMC SPI
  bus, both directions of the pyControl serial link, the two firmware triggers,
  the two encoder channels, and the limit switch — enough for firmware
  development, which is why
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
pyControl link and the TMC5130A bus in one capture. **Eleven** of the eighteen
digital Strands are live at fabrication and the remaining **seven** are allocated
now and routed when their circuits arrive. (**Corrected 2026-08-17**; this
paragraph said ten, which did not match the eleven the table itself lists.)

Two of those eleven — `ENC_A` and `ENC_B` on `DIG0`/`DIG1` — are **temporary
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

| DUT pin                                    | Strand              | Board signal                                    | Live                      | Why                                                                                  |
|--------------------------------------------|---------------------|-------------------------------------------------|---------------------------|--------------------------------------------------------------------------------------|
| 2                                          | `DIG0(I2C_SCL)`     | `ENC_A` → `TQ_I2C_SCL`                          | **Rev 0**, swaps at rev 2 | Encoder quadrature now; torque front-end bus later, on the profile's own I2C overlay |
| 3                                          | `DIG1(I2C_SDA)`     | `ENC_B` → `TQ_I2C_SDA`                          | **Rev 0**, swaps at rev 2 |                                                                                      |
| 5                                          | `DIG2(SPI_SCK)`     | `TMC_SPI_SCK`                                   | **Rev 0**                 | Driver transactions; correctness and fault diagnosis                                 |
| 7                                          | `DIG3(SPI_MOSI)`    | `TMC_SPI_COPI`                                  | **Rev 0**                 |                                                                                      |
| 8                                          | `DIG4(SPI_MISO)`    | `TMC_SPI_CIPO`                                  | **Rev 0**                 | Also the witness for bus-switch state — see below                                    |
| 10                                         | `DIG5(SPI_CS0)`     | `~{TMC_CS}`                                     | **Rev 0**                 | Frames each driver transaction                                                       |
| 11                                         | `DIG6(SPI_CS1)`     | `~{DAC_CS}`                                     | rev 1                     | Frames each DAC write                                                                |
| 13                                         | `DIG7`              | `PYC_DIO_A`                                     | **Rev 0**                 | Host link, both directions, on the profile's first UART pair                         |
| 14                                         | `DIG8`              | `PYC_DIO_B`                                     | **Rev 0**                 |                                                                                      |
| 16                                         | `DIG9`              | `DAC_SPI_SCK`                                   | rev 1                     | Lets a capture recover the commanded angle code                                      |
| 17                                         | `DIG10`             | `DAC_SPI_COPI`                                  | rev 1                     |                                                                                      |
| 19                                         | `DIG11`             | `LIMIT_SW` → `BRAKE_DIM`                        | **Rev 0**, swaps at rev 2 | Homing witness now; brake PWM later, on the slot the profile names for PWM           |
| 20                                         | `DIG12`             | `~{BRAKE_FAULT}`                                | rev 2                     | Brake overcurrent latch, on the slot the profile names for fault                     |
| 22                                         | `DIG13`             | `PYC_PULL_EVENT`                                | rev 1                     | Behavioral event                                                                     |
| 23                                         | `DIG14`             | `PYC_FAULT`                                     | rev 1                     | Fault, experiment-critical                                                           |
| 24                                         | `DIG15`             | `PYC_RSYNC_IN`                                  | rev 1                     | Time alignment; places everything else in pyControl time                             |
| 26                                         | `TRIG0`             | `FW_TRIG0`                                      | **Rev 0**                 | Firmware timing marker                                                               |
| 28                                         | `TRIG1`             | `FW_TRIG1`                                      | **Rev 0**                 | Firmware timing marker                                                               |
| 32/33                                      | `AIN0_P` / `AIN0_N` | `ANGLE_OUT` at **`AMP_VOUT` through 1 kΩ** / `AGND`, 0-3.3 V | rev 1                     | Times the analog output against the driver's own count in one capture. **Tapped before `R2007`, not at the BNC** — see below |
| 35/36                                      | `AIN1_P` / `AIN1_N` | `AUX_ANALOG_OUT` **or** `BRAKE_ISENSE` / `AGND` | rev 1-2                   | Contested; see below                                                                 |
| 38, 39                                     | `AOUT0`, `AOUT1`    | **No-connect**                                  | never                     | No stimulus path into a board used with animals                                      |
| 1, 4, 6, 9, 12, 15, 18, 21, 25, 27, 29, 30 | `GND`               | Digital return                                  | —                         | Per profile                                                                          |
| 31, 34, 37, 40                             | `AGND`              | Analog return                                   | —                         | Per profile; **tied to `GND` on this board, 2026-08-17**                             |

**Eleven Strands live in Rev 0**: the four TMC SPI signals, the two pyControl
serial lines, the two firmware triggers, the two encoder channels, and the limit
switch. Seven more are allocated and unrouted.

#### `AIN0` Taps `AMP_VOUT`, Not The Researcher's Node — Changed 2026-08-27

~~`AIN0_P` taps `ANGLE_OUT` at the BNC centre, which is the same node the
researcher's DAQ or OneBox is connected to.~~ **Struck 2026-08-27 — that is the
wrong side of `R2007`.**

Tapping the BNC centre puts a permanently DC-connected stub from the researcher's
signal onto a 40-pin unshielded 0.5 mm FFC carrying SPI and UART edges. The stub
exists whether or not an instrument is plugged in, and it is on a signal that
lands in a recorded dataset. That is a bad trade for a bench convenience.

**As specified now:** `AIN0_P` taps **`AMP_VOUT`** — the `OPA197` output, before
the 249 Ω `R2007` — through a **series 1 kΩ**, and `AIN0_N` ties to `AGND` at the
connector. Crosstalk injected on the FFC stub then lands on the op amp's
low-impedance output and never reaches the BNC. The researcher's node keeps its
249 Ω source with no stub on it.

What this gives up is verifying `R2007` and the BNC solder joint through the
port. Do that once with a DVM at build time; it is not something a capture needs
to re-answer.

**The instrument's own input impedance still matters, just less.** 1 kΩ into the
M2K's 1 MΩ ‖ 30 pF is 0.1%, negligible at its resolution. On the researcher's
side, `R2007`'s 249 Ω into the OneBox's **1 MΩ** is a −0.025% gain error, or
−0.82 mV at full scale, which calibration absorbs. That figure is now known
rather than assumed: the OneBox ADC is an `AD7616-P` and its datasheet specifies
1 MΩ. See `../kicad-libs/docs/onebox-analog-interface.md`.

**Do not fit a 50 Ω shunt anywhere on this net.** `R2007` is source isolation,
not a transmission-line termination; the signal is a joystick angle band-limited
to 987 Hz on the board.

**`AIN0` answers timing, not amplitude.** The M2K's analog inputs are 12-bit over
±25 V, and its high-gain range is ±2.5 V which clips a 3.3 V full scale — so on
the usable range it resolves about 12 mV, roughly 240 DAC codes against a 50.4 µV
LSB. Use it to confirm the output steps when the code was written and tracks the
encoder. Amplitude, gain and linearity are a 6½-digit-DMM job at the BNC.

**Every latency measured through `AIN0` includes 266 µs of filter group delay**
from the analog block's 2-pole 987 Hz Sallen-Key. Subtract it or report it
explicitly; it is not firmware latency. See `docs/encoder-analog-output.md`.

**`AGND` is bonded to `GND`, 2026-08-17.** Pins 31, 34, 37, and 40 used to be an
isolated four-pin island with no net of its own, which left four connector pins
floating and gave the rev-1 differential inputs no return reference at all. They
are now tied to board `GND`. Rev 0 has nothing analog on the port, so nothing is
lost by bonding them, and the alternative — an island waiting for a single-point
tie that no rev-0 circuit defines — is the shape that gets forgotten.

### `DIG0`, `DIG1`, And `DIG11` Are The Swap Slots

**Decided 2026-08-16.** `ENC_A`, `ENC_B`, and `LIMIT_SW` occupy three of the four
slots reserved for the rev 2 brake and torque circuits, and give them up when
those arrive. **As built 2026-08-17 they are split across two packages** —
`ENC_A` and `ENC_B` in `U1601`, `LIMIT_SW` in `U1801` — not the single package
this section assumed. See [Digital Instrumentation
Buffering](#digital-instrumentation-buffering--three-packages-in-rev-0).

**These are the board's only independent witnesses to the driver's inputs.** None
of `ENC_A`, `ENC_B`, or `LIMIT_SW` reaches an RP2040 pin in any revision
— the TMC5130A owns them — so firmware's entire picture of position and homing is
the driver's own report over SPI. If the driver miscounts, or latches `REFL` when
nothing closed, nothing in the system disagrees with it. Putting the raw signals
next to the SPI traffic in one capture is what makes that checkable:

- **Encoder:** count quadrature edges over a known sweep, read `X_ENC`, compare.
- **Limit switch:** see the edge, then see the driver react in the next SPI poll.
  Without it a homing failure cannot be attributed to the switch, the debouncer,
  or the driver.

**Why these three slots and not others.** The intent was that they belong to
`U_E`, the rev 2 buffer package, with `U_C` and `U_D` filling at rev 1, so that
all three survive Rev 0 *and* rev 1 and are evicted only at rev 2 — the latest
eviction available. **The eviction date is unchanged, but the packaging premise is
not what was built** (2026-08-17): there is no `U_E`, the three witnesses live in
`U1601` and `U1801`, and rev 1's buffers are not placed at all. The slot choice
still stands on its own — these are the profile's brake and torque slots — but the
"whole package turns over at rev 2" argument no longer holds.

**`ENC_N` stays off the port** — and, as of 2026-08-17, off the board. There is no
`ENC_N` net: `J1103` pin 2 is a reserved index no-connect and the TMC5130A's
`ENCN` is terminated by `R1201` 10 kΩ to GND. The original reasoning is
unaffected: the index fires once per revolution, and `ENC_A`/`ENC_B` are what a
decode check needs. The test pad it was to get does not exist either.

**When the brake and torque circuits land**, reassign `DIG0`/`DIG1` to the torque
bus and `DIG11` to `BRAKE_DIM`, and drop all three taps to test pads. There is no
PIO cross-check coming to replace them — that was deleted, not deferred — so this
is a real loss of observability, accepted on the grounds that by rev 2 the
encoder decode and the homing path are verified, settled behaviour rather than
open questions.

**Superseded 2026-08-17.** Earlier guidance here called for **three 100 kΩ
pull-downs to GND** at the buffer inputs, on `ENC_A`, `ENC_B`, and `LIMIT_SW`, on
the grounds that all three sit in the **switched** domain and float whenever
`HV_EN` is low — the board's normal idle state — while the buffers run from
`+3.3V_MCU`. The problem is real and the fix is now board-wide rather than local
to these three nets: see [the termination table](#where-each-signal-is-tapped).
As built, `LIMIT_SW` gets `R1405` 10 kΩ to GND at the buffer input, and `ENC_A`
and `ENC_B` are *driven* by `U801`'s Schmitt outputs, which carry their own
`R805`/`R806` 100 kΩ pull-downs inside the encoder block, so they never float.

Pull-*down*, not up, and the reasoning is still the reasoning. It works whether
the encoder turns out
push-pull or open-collector, which matters because the encoder part is still an
open blocking item; against a 2.2 kΩ pull-up to `+3.3V_SW` a 100 kΩ pull-down
still reads 3.2 V. And a pull-*up* would have to go to `+3.3V_MCU`, which would
back-power the MAX6816's and the encoder's output pins through their clamps
whenever the switched domain is dark — the exact failure the limit-switch block's
own description warns about. The board-level pulls that do need to read HIGH
solve this a different way: they reference `+3.3V_SW`, which collapses with the
domain instead of injecting into it.

`LIMIT_SW` is active low, so a pull-down makes it read as *closed* while the
switched domain is off. Harmless: the TMC5130A is unpowered in that state and
nothing else reads the net.

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

### Test Points — Outstanding

> **None of this is on the board.** As of 2026-08-17 there are **no test points
> anywhere on `mouse-joystick-pcb`**. Everything below is a requirement to
> satisfy, not a description. It is the largest single gap between this document
> and the board, and with no SWD header either it is also the board's only
> remaining bring-up access besides the InstrumentPort and USB CDC.

`TMC_DIAG0` did not earn a slot because a driver fault reaches the capture
through `PYC_FAULT` anyway, one firmware latency later. It goes to a test point.

Labelled test pads, not bare vias: `TMC_DIAG0`,
`TMC_DIAG1`, `~{TMC_DRV_EN}`, `HV_EN`, `HV_SNS`, `REFL`,
`~{INSTR_BUF_OE}`, and in later revisions `TQ_DRDY`. `TQ_DRDY` has no slot
because the I2C capture already shows when the host reads a conversion.

**Two more entries left this list on 2026-08-26.** `~{DAC_LDAC}` and
`~{DAC_CLR}` are moot for the same reason `SWSEL` is: the nets do not exist,
because the `DAC80501` has neither pin. What replaces them is better — the
analog output block exposes `VREFIO`, `AMP_VOUT` and `AOUT` as distinct nets, so
one probe each would verify the 2.500 V reference, the 1.32 gain, and the 249 Ω
drop.

**Corrected 2026-08-27: the block carries no test pads.** This paragraph claimed
it did. Checked against the block schematic and its layout fragment — there is no
`TestPoint` symbol or pad anywhere in `analog_output_0_3v3_dac80501`, which agrees
with `docs/bringup-log.md`'s standing note that no test points exist anywhere on
this board. The three nets are still the right ones to pad; they are simply not
padded yet, and adding them is a block change, not a board change.

**Two things are owed at board level for the analog section**, contrary to the
last sentence this paragraph used to carry: the `AIN0_P` instrument tap's series
1 kΩ from `AMP_VOUT`, and `AIN0_N` to `AGND`. Neither is in the block.

Two entries left this list on 2026-08-17. **`SWSEL` is moot**: the TMC5130A's pin
28 is tied directly to GND with no net, so there is nothing to pad and nothing a
jumper could change — SPI mode is strapped, not selected. **`ENC_N` is moot**: the
net does not exist, `J1103` pin 2 is a reserved no-connect, and `ENCN` is
terminated at `R1201`.

**Also pad `ENC_A`, `ENC_B`, and `LIMIT_SW`**, even though Rev 0 carries them on
the port. They lose their slots at rev 2 and the pads are what they fall back to,
so placing them now costs nothing and saves a layout change later. Since none of
them reaches the MCU, the pads are the only access once the port slots go.

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

**TMC5130A: the A side of the bus switch, not the chip pins.** **Corrected
2026-08-17 — the A side is the TMC / switched side and B is the MCU side**, the
reverse of what this section originally assumed. The taps are on A, so the
capture shows the driver's end of the link. When the bus switch is enabled, A and
B are the same node through a few ohms, so the capture shows what the chip sees.
When it is isolated, the taps sit at their terminated idle levels and go quiet —
which still *diagnoses* the bus-switch state instead of hiding it, and that is
exactly the failure mode a firmware author needs to recognise. It diagnoses it
from the far end rather than the near one: the earlier wording promised MCU
traffic with `TMC_SPI_CIPO` silent, and that is what a **B**-side tap would show.

This looks like the opposite of the pyControl decision above and is not. A 100 Ω
resistor cannot make its two nodes read differently on a digital channel; a bus
switch that can be *open* absolutely can. Where the series element has two
distinguishable states, which side you tap is a real choice.

**Reversed 2026-08-17**; earlier guidance said to prefer the near side, "the one
that stays in the always-on domain and stays driven", which on the as-built
orientation means the B side. The 2026-08-17 schematic review raised the
disagreement as finding 7 and offered two remediations — move the taps to the
MCU-side nets, or keep the orientation and terminate the tapped nets.
**Resolution: the taps stayed on the A side and the nets were terminated.** Three
reasons. The A side is where the driver actually sees the signal, which is the
question the capture is being asked. Termination is nine passives in
board-authored sheets against re-pinning seven channels inside a proven
`kicad-libs` design block that would then diverge from its source. And the
terminations were wanted regardless of the instrument port — the TMC's `SDO`
tri-states between transactions, its `DIAG` pins are open-drain, and its
`CSN`/`SCK`/`SDI` are only weakly pulled internally.

What the old objection got right is that tapping the switched side puts always-on
buffer inputs on nets that are dead whenever `HV_EN` is low, which is this board's
normal idle state. That is the floating-CMOS-input problem the design avoids
everywhere else, arriving by a new route — and closing it is exactly what the
table below is for.

#### Pull And Termination Resistors, As Built 2026-08-17, Updated 2026-08-27

**Superseded: this section used to call for four 100 kΩ pull-downs** on
`TMC_SPI_CIPO`, `ENC_A`, `ENC_B`, and `LIMIT_SW`. Ten resistors are fitted
instead, all in the board-authored `mcu`, `motor_encoder_limit`, and
`instrument_port` sheets, so a design-block re-place cannot lose them.

**`R1104` added 2026-08-27**, and the three DAC-bus terminations are **not** in
this table — they live inside the analog output block as `R2006`, `R2008` and
`R2009`. See "The DAC Bus Terminations" above.

| Ref     | Value | Net             | To          | Sheet                 | Why                                                                                          |
|---------|-------|-----------------|-------------|-----------------------|----------------------------------------------------------------------------------------------|
| `R403`  | 10 kΩ | `PYC_UART_RX`   | `+3.3V_MCU` | `mcu`                 | UART RX must idle **high**; the RP2040's default pull-down would look like a permanent break |
| `R1401` | 10 kΩ | `TMC_SPI_SCK`   | GND         | `instrument_port`     | Define the `U1701` buffer input when the switched domain is off                              |
| `R1402` | 10 kΩ | `TMC_SPI_COPI`  | GND         | `instrument_port`     | As above                                                                                     |
| `R1403` | 10 kΩ | `TMC_SPI_CIPO`  | GND         | `instrument_port`     | As above; also gives the instrument tap a clean idle-low                                     |
| `R1404` | 10 kΩ | `~{TMC_CS}`     | `+3.3V_SW`  | `instrument_port`     | `CSN` must idle **deasserted** — a pull-down would assert chip select                        |
| `R1405` | 10 kΩ | `LIMIT_SW`      | GND         | `instrument_port`     | Define the `U1801` buffer input                                                              |
| `R1101` | 10 kΩ | `TMC_DIAG0`     | `+3.3V_SW`  | `motor_encoder_limit` | `DIAG` is open-drain at reset; the datasheet requires ≤47 kΩ                                 |
| `R1102` | 10 kΩ | `TMC_DIAG1`     | `+3.3V_SW`  | `motor_encoder_limit` | As above                                                                                     |
| `R1103` | 10 kΩ | `~{TMC_DRV_EN}` | `+3.3V_SW`  | `motor_encoder_limit` | Guarantees the power stage is **disabled** in hardware                                       |
| `R1104` | 10 kΩ | `REFR`          | GND         | `motor_encoder_limit` | **Added 2026-08-27.** TMC5130A `REFR_DIR` (pin 9) is a plain `DI` with **no** internal pull, unlike `SD_MODE`/`SPI_MODE` (`pu`) and `SWSEL` (`pd`). It was floating; a floating right-stop input next to a 36 V bridge can trip a stop and draws ΔICC |

**Why some reference `+3.3V_SW` and some GND.** A pull that must read HIGH while
the driver is powered — `~{TMC_CS}`, both `DIAG` lines, `~{TMC_DRV_EN}` —
references `+3.3V_SW`, so it **collapses to 0 V with the domain** instead of
injecting current into a dead rail. Pulls that may read LOW go straight to GND.
Referencing `+3.3V_MCU` would be the wrong answer for the HIGH group: it would
back-power `+3.3V_SW` to roughly 1.3 V through the TMC's protection diodes,
defeating the `HV_EN` power-cycle and corrupting the rail sense.

**`+3.3V_SW` is held at 0 V when off by `R401`/`R402`** — the rail-sense divider,
2 kΩ to GND — and that is what makes a pull-up to that rail a valid LOW in the off
state. **If the `SW_RAIL_SENSE` divider is ever removed, `R1404`, `R1101`,
`R1102`, and `R1103` stop defining their nets.** Those two circuits are coupled;
treat them as one decision.

**Do not use 100 kΩ pull-downs on the TMC SPI lines.** This is why the earlier
prescription had to change rather than simply move. `CSN`, `SCK`, `SDI`, and `SDO`
are marked `(tpu)` in the TMC5130A datasheet with `RPU` = 132/166/200 kΩ. A 100 kΩ
pull-down against that parks the node at roughly **1.9 V** — straddling the
`SN74LVC125A`'s 2.0 V `VIH` and sitting between the TMC's own 0.99 V `V_INLO` and
2.31 V `V_INHI`. It is the worst available answer: an indeterminate level on both
sides. 10 kΩ gives 5 V × 10/176 = **0.28 V**, an unambiguous LOW.

**`~OE` does not gate the buffer input stage**, so disabling the buffers is not a
substitute for terminating their inputs. `SCAS290T` specifies `ΔICC` at **500 µA
typical and 5 mA maximum per partially biased input**, independent of `OE`,
against 40 µA maximum for the whole device with valid levels on every input. A
floating buffer input costs current and invites oscillation whether or not the
outputs are high-Z.

**Encoder: between the input conditioning and the TMC5130A.** `ENC_A` and `ENC_B`
are tapped on the board-local encoder section on the driver side of the chain, so
the capture shows what the TMC5130A's `ENCA`/`ENCB` pins actually receive. That is
the point of having them: the comparison is against the driver's own decoded
count, so the tap belongs where the driver sees the signal, not where the cable
delivers it. **Corrected 2026-08-17**: the chain is `J1103`, not `J6`, and it is
filtering only — **there is no ESD device anywhere in the encoder path**, contrary
to what this paragraph used to say. The taps need no pull-down of their own
because `U801` drives them and `R805`/`R806` hold them low when it does not.

**The conditioning is a real, placed design block**, not a gap:
`orb_weaver_private:quadrature_encoder_input_5v_sn74lvc2g17`. It imposes three
constraints that the still-unchosen encoder has to satisfy, and they are the
reason the encoder part remains the open decision that can invalidate the board:

1. **Push-pull, not open-collector.** `R801`/`R802` are 100 kΩ pull-**downs** on
   the harness side. An open-collector encoder needs them changed to pull-ups.
2. **72 kHz filter corner.** `R803`/`R804` 4.7 kΩ with `C802`/`C803` 470 pF gives
   τ = 2.2 µs. Check it against the encoder's maximum output frequency at the
   fastest sweep the rig will command.
3. **The 5-position pin order is fixed by the block.** `J1103` pin 1 = GND, pin 2
   = reserved index no-connect, pin 3 = `ENC_A_RAW`, pin 4 = `+5V_SW`, pin 5 =
   `ENC_B_RAW`. A 5 V encoder is assumed. If the chosen part wants a different
   order or a different supply, the harness or the block changes.

**Limit switch: the `LIMIT_SW` net between the debouncer and the TMC5130A
`REFL` pin.** Same reasoning — the capture should show what the driver's homing
input receives. `R1405` defines the buffer input.

With the ÷2 divider on `SW_RAIL_SENSE`, the nine resistors above are the whole
passive cost of the instrumentation and of the isolation architecture's off-state
behaviour together.

### AIN Assignment Keeps 36 V Off The Connector

`AIN1_P/N` observes a ground-referenced 0-5 V board node rather than a
divided-down motor rail. A resistive divider from a 36 V rail into an instrument
input is a plausible-looking way to destroy an ADALM2000 if a resistor is
misplaced or a divider node is probed while the rail is live.

**`AIN1_P/N` is contested and does not need resolving for Rev 0**, since neither
candidate exists yet:

- `AUX_ANALOG_OUT` — the rev-1 assignment, and it survives only if the
  researcher wants a second analog output. **Weakened 2026-08-26:** this used to
  be "DAC channel B", nearly free on a dual `DAC8563`. The built block is
  single-channel, so a second output is a second full instance and a second BNC
  position. The question is no longer "does anyone object" but "is it worth a
  second DAC and amplifier"; see `docs/encoder-analog-output.md` and the
  `AUX_ANALOG_OUT` note above. **As of 2026-08-27 it is not populated**, so
  `AIN1_P/N` stay no-connect at rev 1.
- `BRAKE_ISENSE`, the rev-2 brake current monitor — a natural use for a
  differential input, and the measurement that verifies commanded against actual
  brake current.

If `BRAKE_ISENSE` wins, it must be a **low-side shunt or a ground-referenced
current-monitor output**. A high-side sense on the brake rail would put that
rail's common-mode voltage on the instrument connector, which is the thing this
section exists to prevent.

Motor-supply monitoring uses the onboard ADC instead: `GP28` for load current
through the smart switch's `SNS` pin, and `GP26` for the **`+3.3V_SW`** rail —
**corrected 2026-08-17**, this said `+5V`, which the 2026-08-16 move to the end of
the chain had already superseded. Both stay inside the board's own 3.3 V domain,
and both are live in Rev 0.

### Digital Instrumentation Buffering — Three Packages In Rev 0

Every `DIG*` and `TRIG*` signal above is buffered with
`orb_weaver_private:instrumentation_signal_buffer_sn74lvc125a`
(`SN74LVC125A`, `OW-MISC-SN74LVC125ARGYR`), already composed five times into
`tmc51x0-driver-dev-pcb`.

- `VCC = +3.3V_MCU`, the always-on domain. The catalog part's absolute maximum
  supply is 3.6 V. Note the part has **no `Ioff` and no partial-power-down
  support** — `VI` absolute maximum is −0.5 to 6.5 V and is *not*
  `VCC`-referenced, and `IIK` is specified only for `VI` < 0, so there is no
  input clamp to `VCC`.
  TI does not specify leakage at `VCC` = 0, so the powered-off case is unspecified
  rather than guaranteed. Measure `+3.3V_MCU` with 36 V applied and both USB and
  pyControl unplugged at Gate B.
- Unidirectional, board-side to instrument-side only. `PYC_DIO_A` and
  `PYC_RSYNC_IN` are inputs to this board; they are *tapped* and buffered
  outward. The buffer never drives back into the pyControl cable — and because
  the tap is on the MCU side of `R29001`, the block's own 100 Ω sits between the
  buffer and the cable as a second line of defence.
- The block provides ~33 Ω series source termination on each output.
- 18 signals at 4 channels per package would be **5 packages**, 2 channels spare,
  at full scope. **Rev 0 places three** — `U1601`, `U1701`, `U1801` — covering the
  eleven live Strands with one channel spare.
- **Rev 1 needs a fourth package.** The three placed ones carry 12 of 12
  channels, so the analog output's three digital taps — `~{DAC_CS}` on `DIG6`,
  `DAC_SPI_SCK` on `DIG9`, `DAC_SPI_COPI` on `DIG10` — have nowhere to go.
  Budget one more `SN74LVC125A`, its decoupling, and three 33 Ω resistors when
  the analog output lands, and note that it leaves one channel spare rather than
  filling the package.

  **This is a new placement, not a stuffing change** — no fourth footprint was
  drawn in Rev 0, so board area has to be reserved deliberately. `U603` and
  `U604` are two entirely empty `SN74CB3Q3245` packages (all B-side pins tied to
  GND, all A-side pins no-connect, 14 channels of nothing); removing them frees
  roughly the area the fourth buffer needs. See `docs/design-block-map.md`.

  **The three taps need no new terminations.** They sit on the A / switched side
  of the bus switch, but `R2006`/`R2008`/`R2009` inside the analog output block
  already define all three. Do not add board-level copies.

- **`AIN0` needs no buffer; it is a direct analog tap** — `AMP_VOUT` through a
  series 1 kΩ to `AIN0_P`, with `AIN0_N` to `AGND`. That 1 kΩ is the only new part
  on the analog side of the port.

**Superseded 2026-08-17.** The intent was that **the grouping is chosen so each
revision populates whole packages**, so a deferred group never leaves a powered
CMOS input undriven. The as-built grouping does not do that: it mixes zones.

| Package | Channels                                                                         | Zone                                                                 | Fitted    |
|---------|----------------------------------------------------------------------------------|----------------------------------------------------------------------|-----------|
| `U1601` | `ENC_A`, `ENC_B`, `PYC_UART_RX`, `PYC_UART_TX` — `DIG0`, `DIG1`, `DIG7`, `DIG8`  | Encoder witnesses **and** pyControl serial: two zones in one package | **Rev 0** |
| `U1701` | `TMC_SPI_SCK`, `TMC_SPI_COPI`, `TMC_SPI_CIPO`, `~{TMC_CS}` — `DIG2`-`DIG5`       | TMC SPI bus and chip select                                          | **Rev 0** |
| `U1801` | `LIMIT_SW`, `FW_TRIG0`, `FW_TRIG1`, spare — `DIG11`, `TRIG0`, `TRIG1`, (`DIG12`) | Homing witness, firmware markers, one unused channel                 | **Rev 0** |

**There are three packages, not five. `U_C` and `U_D` do not exist and no
footprints are placed for them.** The earlier plan — place all five footprints in
Rev 0, populate three, leave two DNP with their inputs unrouted so the board area
is reserved — was not carried out. Reserving the area was the whole point, so
adding the rev 1 buffers is now a placement pass with no room set aside; see
`docs/design-block-map.md`.

**Accept the consequence this section used to deny: the rev-2 swap touches two
packages, not one.** `ENC_A` and `ENC_B` are in `U1601` alongside the pyControl
serial pair, while `LIMIT_SW` is in `U1801` alongside the firmware markers. When
the brake and torque circuits land, `DIG0`/`DIG1` move to the torque bus in
`U1601` and `DIG11` moves to `BRAKE_DIM` in `U1801`. Neither package turns over
cleanly, and each retains channels that must keep working across the change. Plan
the rev-2 edit as two package edits.

**The buffers are Rev 0 parts, not rev 1.** Earlier text listed
`~{INSTR_BUF_OE}` and the buffer packages as rev 1; they moved into Rev 0 with the
InstrumentPort on 2026-08-16 and are populated.

**The documented buffered static low on `DIG12` is not delivered.** The plan was
to tie the spare channel's input directly to GND — a net, not a part — so the
channel drives a static low that reads as a dead channel at the analyzer, which is
the correct treatment for an unused LVC125A input. The input *is* grounded, but
the **output stops at `R1805` and `J1501` pin 20 is a no-connect**, so nothing
reaches the port. It is a one-wire change: connect `R1805`'s far end to `DIG12`.
Until that is done, do not describe `DIG12` as driven. At rev 2 the ground tie is
removed and `~{BRAKE_FAULT}` routes in its place either way.

Any spare channel in the rev-1 packages will need its input tied to GND when those
packages are fitted — and its output actually routed, which is the lesson from
`R1805`.

All three `~OE` pins tie into one board-wide `~{INSTR_BUF_OE}` driven by `GP24`,
which is in the bus-switch bypass group, with `R1601`/`R1701`/`R1801` 10 kΩ
pull-ups. Wire the rev-1 packages' `~OE` into the same net when they are placed.

**Enable default:** the block pulls `~OE` up, so buffers are high-Z until
firmware enables them — the same power-on posture as the bus switch, for the same
reason. Firmware should enable them during normal startup and report buffer state
in `ID`/`STATUS`. See `docs/instrument-strategy.md`. **It does not follow that a
disabled buffer tolerates a floating input**; `~OE` gates the output stage only.
See [the termination table](#pull-and-termination-resistors-as-built-2026-08-17).

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
