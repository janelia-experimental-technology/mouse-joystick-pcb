# Encoder Analog Output

**Rev 0 scope:** deferred to rev 1. The rescope of 2026-08-13 removed the analog
angle output from Rev 0; see `docs/rev0-plan.md`.

**Status:** the design block exists and is validated in `kicad-libs`; it has not
been placed on this board and has not been on a bench.
**Date:** 2026-08-26 (supersedes the 2026-08-12 draft)
**Requirement:** joystick encoder angle as a **0-3.3 V** analog voltage on a BNC
connector. One joystick, one output.

## The Requirement Changed From 0-5 V

The original researcher request was 0-5 V and this document was written against
it. The contract became **0-3.3 V** on 2026-08-20 in
`../kicad-libs/docs/onebox-analog-interface.md`, from the acquisition side rather
than the board side: the Neuropixels OneBox ADC runs its +/-5 V range at
152.6 uV/code, which gives about 14.40 ideal bits across 0-3.3 V against 15.00
across 0-5 V. The 0.60-bit cost was accepted there, with the reasoning recorded.

**Anywhere this repository still says the analog output is 0-5 V, it is stale.**
Several documents did on 2026-08-26 and were corrected together with this file:
the README, `docs/rev0-plan.md`, `docs/power.md`, `docs/validation-plan.md`,
`docs/uart-protocol.md`, `docs/instrument-strategy.md`, and
`docs/interface-map.md`.

## Why It Is The First Thing Rev 1 Adds

This is an explicit researcher request and it is what lets the rest of the rig's
acquisition chain be tested. An analog angle signal goes straight into whatever
ephys or DAQ system already records the rig, without waiting on the pyControl
device class, the UART protocol, or a firmware release. It is the cheapest thing
on this board that produces immediate scientific value.

It was cut from Rev 0 only because Rev 0's purpose narrowed to proving the
interfaces, not because the value argument weakened. Of the rev 1 additions it is
the one with the shortest path from silicon to a number the researcher cares
about, and `docs/rev0-plan.md` lists it first for that reason.

## The Block

`orb_weaver_private:analog_output_0_3v3_dac80501`, built and validated
2026-08-26. Sixteen parts in the 35xxx designator range, all stocked. Seven
boundary ports: `+5V`, `+3.3V`, `GND`, `SCK`, `SDI`, `~{CS}`, `AOUT`.

```text
+5V_SW ─FB─┬─ DAC80501ZDGSR ──> OPA197 (gain 1.32) ──> 249R ──> ESD ──> BNC
           │  internal 2.5 V ref        │
           │  GAIN = 0x0101             └── 100k to GND
           │  0-2.5 V out
           └─ decoupling
```

| Property | Value |
| --- | --- |
| DAC | `DAC80501ZDGSR`, `OW-SENS-DAC80501ZDGSR`, VSSOP-10 |
| Resolution | 16-bit over the full span, **50.4 uV/LSB** |
| Reference | Internal 2.5 V, +/-0.1% initial, **5 ppm/C max** |
| DAC span | 0-2.5 V (`GAIN` register 4h = `0x0101`) |
| Gain stage | `OPA197IDBVR`, non-inverting **1.32**, 10 kohm / 3.2 kohm 0.1% 25 ppm/C |
| Full scale | **3.300 V** |
| Interface | SPI, write-only, 3 wires, up to 50 MHz |
| Supply | `+5V_SW` for the analog section |
| `+3.3V` port | `~{CS}` pull-up reference only — **must bind to `+3.3V_SW`** |

Full block documentation — layout constraints, firmware ordering, failure modes
— lives in the block's own description in `kicad-libs`, which is the copy that
travels with a placed instance. This section records only what the board needs
to know.

## What Changed From The 2026-08-12 Draft

That draft specified a `DAC8563`, hardware `~LDAC` and `~CLR` on `GP12`/`GP17`,
and an open "blocking question" about logic levels. All three are resolved, and
not in the direction the draft expected.

| Draft | Built | Why |
| --- | --- | --- |
| `DAC8563`, dual, 0-5 V native | `DAC80501`, single | `DAC8563` `VIH` is **`0.7 x AVDD`** = 3.5 V at 5 V, so 3.3 V logic is out of spec. `DAC80501` `VIH` is **1.62 V flat** across `VDD` 2.7-5.5 V and connects directly |
| Level translator likely needed | **None** | Follows from the line above. `LSF0102DCUR` stays reserved for other 5 V paths, not this one |
| `~LDAC` on `GP12`, `~CLR` on `GP17` | **Neither pin exists** | Software LDAC via `DAC_SYNC_EN` + `TRIGGER`; soft reset writes `0x1010` to `TRIGGER`. **Two GPIOs released** |
| Reduced range "not acceptable" | 0-2.5 V DAC + 1.32 gain | Outcome 3 of the old blocking question was rejected because it broke a 0-5 V requirement that no longer exists. With a gain stage it is now the best answer |
| Channel B for AUX | Second block instance | See below |

The draft's outcome 1 ("`VIH` is specified low enough — connect directly") turned
out to be correct, but only for a part it did not name. Its instruction not to
assume outcome 1 was sound; the answer was checked, not assumed.

**The 0-3.3 V range is enforced in hardware.** The DAC cannot exceed its own
reference, so the output cannot exceed 3.300 V once the `GAIN` register is
written. The earlier plan of code-limiting a 0-5 V DAC left that as a firmware
promise on a signal that reaches a researcher's dataset and a OneBox ADC input.

## Pins

**Three GPIOs, not five.** `docs/interface-map.md` is the authority.

| Signal | GPIO | Note |
| --- | --- | --- |
| `DAC_SPI_SCK` | `GP10` | `SPI1 SCK` |
| `DAC_SPI_COPI` | `GP11` | `SPI1 TX` |
| `~{DAC_CS}` | `GP13` | The DAC's `SYNC` |

`GP12` and `GP17` return to the spare pool. That takes full scope to 24 of 30
with six spares and voids reclaim-order item 1 — see the interface map.

The DAC sits on `SPI1`, separate from the TMC bus on `SPI0`, so an angle update
cannot queue behind a motor register access.

## What The Board Owns

Mostly the block does not contain these; they are board-level and belong in a
board-authored wrapper sheet, so a block re-place cannot lose them. The one
exception is called out below.

**Before anything else: bind the block's `+3.3V` port to `+3.3V_SW`.** It exists
only to reference `R35005`, the `~{CS}` pull-up. On `+3.3V_MCU` that resistor
holds `~{CS}` at 3.3 V while the DAC's `VDD` is dead and pushes roughly 260 uA
through the DAC's input clamp into `+5V_SW` — back-powering the switched domain
from inside a block, where the isolation bus switch cannot intervene. This is
the same rule the board already applies to its buffer terminations, and it is
the easiest thing on this page to get wrong.

1. **Two termination resistors — the third is in the block.** The DAC's digital
   pins sit on the switched side of the isolation bus switch and float when it is
   open.
   - `~{DAC_CS}` — 10 kohm pull-up, **already fitted inside the block as
     `R35005`**. This is the required one: the DAC blocks `SCLK` and `SDIN`
     entirely while `SYNC` is high, which is what makes a floating bus harmless.
     Because it is functional rather than board-dependent, the block owns it.
   - `DAC_SPI_SCK`, `DAC_SPI_COPI` — 10 kohm to GND, **board-level**. Hygiene
     against floating CMOS inputs, not a functional requirement.

   **Never pull any of them to the DAC's 5 V rail.** The `SN74CB3Q3245` is a
   symmetric FET pass gate, so a 5 V pull-up on the DAC side lands on an RP2040
   pad and exceeds its `IOVDD + 0.3 V` limit. This takes the board's nine 10 kohm
   terminations to eleven.

2. **`+5V_SW`, not `+5V_MCU`.** The `OPA197` needs 4.5 V minimum and the ORed
   MCU rail can sit at 4.0-4.9 V. The switched rail is also semantically right:
   no motor rail means no valid angle, and the output section goes dark with its
   data source rather than holding a stale value. See `docs/power.md`.

3. **The connector.** `J7`, and placement — see below.

4. **Three isolation bus-switch channels.** `U603`/`U604` currently have their
   MCU-side pins tied to GND, so rev 1 edits that block regardless. Three
   channels fit in `U601`/`U602`'s spare capacity with six left over.

## Placement Is A Constraint, Not A Preference

`R35004` and `D35001` are inside the block but `J7` is not. **The block must sit
at the connector.** `D35001`'s ground via has to land on the connector ground
pin, or its clamping voltage is dominated by connection inductance — the same
argument this repository already makes for the `USBLC6` on `usb2`.

On this board that is no conflict: the analog section wants to be near the BNC
and away from the motor section anyway. Keep the analog return to the BNC shell
clean and off the motor return path.

## Signal Chain

```text
encoder ──> TMC5130A X_ENC counter ──> RP2040 reads over SPI0
                                              │
                                              v
                                  angle-to-code mapping
                                              │
                                              v
              DAC80501 ──> OPA197 x1.32 ──> 249R ──> ESD ──> BNC "ANGLE"
```

- The MCU reads the encoder position, maps it to a DAC code using the configured
  `ANGSCALE` range, and writes the DAC. The output updates on the rising edge of
  `~{DAC_CS}` in asynchronous mode.
- **The load must be 100 kohm or more.** 249 ohm of source resistance costs
  0.25% into 100 kohm and 0.025% into 1 Mohm; a 50-ohm terminated input reads a
  fraction of the correct voltage. The OneBox manual does not specify its ADC
  input impedance, so measure it — see the checklist in
  `../kicad-libs/docs/onebox-analog-interface.md`.
- **The output cannot reach a true 0 V.** The `OPA197`'s output stage sits about
  25 mV off the negative rail at light load. Map the valid angle range to start
  at 50 mV or above.
- Update rate is an open decision. Settling is 5 us and a 24-bit frame at even
  1 MHz takes 24 us, so the DAC is not the limit. Choose the rate against the
  mouse's actual pull dynamics, and document the achieved rate and latency as a
  **measured** claim, not a target.
- The DAC bus and `~{DAC_CS}` are on InstrumentPort-40 (`DIG9`, `DIG10`,
  `DIG6`), and `ANGLE_OUT` is on `AIN0`, so one capture recovers the commanded
  code, the analog output, and the encoder together. Use that at Gate D rather
  than trusting a firmware log. **Those three digital taps need a fourth
  `SN74LVC125A` package** — the three placed ones carry 12 of 12 channels.

## The Second Channel Is A Second Instance

The block is single-channel. `AUX_ANALOG_OUT` is now a second copy of it, not a
spare channel of a dual DAC — one more `DAC80501`, one more `OPA197`, and the
passives, against the previous cost of a footprint and two passives.

Two consequences:

- **If two instances land on the same hierarchical sheet their internal labels
  merge** — `+5V_FILT`, `AMP_VOUT`, `AMP_FB`, `DAC_VOUT`, `VREFIO` — the
  ferrites parallel and the `PWR_FLAG`s conflict. Give each instance its own
  sheet.
- **The dual BNC is no longer free.** `J7` is a `DOSIN-801-0095` dual jack
  chosen when the second channel cost almost nothing. If `AUX_ANALOG_OUT` is not
  populated, the stocked single `DOSIN-801-0050` is now the honest choice.
  Decide before layout.

This weakens but does not kill the case for a validity output on channel B; see
below.

## Calibration And Semantics

Document and store on the board:

- the angle range mapped to 0.05-3.300 V, and which end is low;
- the encoder zero and its relationship to the homed position;
- the update rate and worst-case latency from joystick motion to output voltage;
- what the output does when unhomed, disarmed, or faulted;
- **the board serial the calibration belongs to.** With two interchangeable
  single-axis boards in a rig, a board swapped between joysticks carries its
  calibration with it. That is the failure mode this form factor introduces.

Uncalibrated full-scale accuracy is about +/-0.4% worst case — reference
+/-0.1%, DAC full-scale error +/-0.07%, resistor ratio +/-0.2% — drifting near
55 ppm/C, with about +/-2 mV of offset. Calibrate once per board and the
remaining drift is negligible against the encoder.

The fault behavior needs an explicit decision. A faulted board that keeps
outputting its last angle looks identical on a scope to a working board holding
still. **Recommendation:** drive 0 V on fault, which the ~25 mV floor makes a
naturally out-of-band level once the valid range starts at 50 mV. Do not leave it
ambiguous, because this signal ends up in a researcher's recorded dataset with no
other indication of board state.

Two hardware failure modes produce 0 V and must not be confused with the fault
level in analysis: an unpowered output section, held at 0 V by `R35003`, and a
reference alarm from a misconfigured `REF-DIV`. Both read as a legitimate end of
travel. `STATUS` must report the output as invalid in either case.

## Open Decisions

- Whether `AUX_ANALOG_OUT` is populated, and what it carries — validity, a second
  derived quantity, or nothing. Now costs a full second instance.
- Whether `J7` stays a dual BNC or becomes a single, which follows from the above.
- DAC update rate and the resulting latency budget.
- Output behavior when unhomed, disarmed, or faulted.
- Measured OneBox ADC input impedance, which sets the loading error.

**Closed since the 2026-08-12 draft:** the `DAC8563` `VIH` question, whether a
level translator is required, whether to buffer the output, and how the output is
protected. All four are settled in the block.
