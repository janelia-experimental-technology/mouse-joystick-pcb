# Encoder Analog Output

**Rev 0 scope:** deferred to rev 1. The rescope of 2026-08-13 removed the analog
angle output from Rev 0; see `docs/rev0-plan.md`.

**Status:** the design block exists and is validated in `kicad-libs`, and a copy
with the 987 Hz output filter is **placed on this board as of 2026-08-27**
(schematic only — layout and routing are not done). It has not been on a bench.
**Date:** 2026-08-27 (supersedes the 2026-08-26 revision and the 2026-08-12 draft)
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
2026-08-26, **filter added and monitor tap added 2026-08-27**. Twenty-four parts,
all stocked. **Eight boundary ports**: `+5V`, `+3.3V`, `GND`, `SCK`, `SDI`,
`~{CS}`, `AOUT`, and `AOUT_MON`.

> **STALE FOR v1.0, AND DELIBERATELY NOT YET REWRITTEN — 2026-09-10.** This whole
> section still describes the block as built for v0.3. Three changes are specified
> and not yet made: the DAC's `VDD` moves from `+5V_FILT` to a ferrite-filtered
> **3.3 V**, the transport becomes **I2C** (`SPI2C` and `A0` strapped to
> `+3.3V_FILT`, `A0` → AGND for **0x48**, `SCK`/`SDI`/`~{CS}` → `SCL`/`SDA` with
> the `~{CS}` port deleted and the three 10 kΩ SPI-idle resistors **deleted**),
> and a **÷2 divider** lands between `AMP_VOUT` and the 249 Ω with the
> `AOUT_MON` tap moving to its midpoint — halving full scale to **1.650 V**.
> `brake_current_sink_0_49ma_dac80501` has already had the equivalent I2C and
> divider work done; use it as the worked example. Specs in
> `../kicad-libs/.agents/PLANS.md` item 5 and `.agents/handoff.local.md` there.
> **Rewrite this section when the block is re-placed, not before.**

```text
+5V_SW ─FB─┬─ DAC80501ZDGSR ──> 2-pole 987 Hz ──> OPA197 ─┬─ 249R ─┬─> AOUT ──> BNC
           │  internal 2.5 V ref   Sallen-Key    (gain     │        └─ ESD
           │  GAIN = 0x0101        20k/13k/10nF   1.32)    │
           │  0-2.5 V out           x2                    ├─ 1k ────> AOUT_MON ──> AIN0_P
           └─ decoupling                                  └─ 100k to GND
```

The `OPA197` is both the gain stage and the filter's active element, so the two
poles cost four passives and no extra amplifier.

**`AOUT` and `AOUT_MON` are not interchangeable.** `AOUT` carries the 249 Ω source
resistor *and* the ESD clamp and goes to the BNC; `AOUT_MON` carries a 1 kΩ
isolation resistor and goes to InstrumentPort `AIN0_P`. Crossing them was a real
defect on 2026-08-27, caught on the netlist and fixed the same day: it left the
BNC — the human-accessible connector, and the whole reason the clamp exists — with
**no ESD protection**, put 1 kΩ of source resistance in front of the researcher
(−0.1% into 1 MΩ instead of −0.025%), and made the block's own placement rule
unsatisfiable because the clamp was no longer on the connector's net. **ERC cannot
catch this**; both nets are validly driven and terminated either way. Check it on
the netlist, not by eye.

| Property | Value |
| --- | --- |
| DAC | `DAC80501ZDGSR`, `OW-SENS-DAC80501ZDGSR`, VSSOP-10 |
| Resolution | 16-bit over the full span, **50.4 uV/LSB** |
| Reference | Internal 2.5 V, +/-0.1% initial, **5 ppm/C max** |
| DAC span | 0-2.5 V (`GAIN` register 4h = `0x0101`) |
| Gain stage | `OPA197IDBVR`, non-inverting **1.32**, 10 kohm / 3.2 kohm 0.1% 25 ppm/C |
| **Filter** | **2-pole Sallen-Key, f0 987 Hz, Q 0.606, -3 dB at 827 Hz** |
| **Filter parts** | **20 k / 13 k 1% and two 10 nF C0G 0805, `OW-CAP-10N-0805-C0G-50V`** |
| **Group delay** | **266 us at DC, near-flat in band** |
| Full scale | **3.300 V** |
| Interface | SPI, write-only, 3 wires, up to 50 MHz |
| Supply | `+5V_SW` for the analog section |
| `+3.3V` port | `~{CS}` pull-up reference only — **must bind to `+3.3V_SW`** |
| `AOUT` port | 249 Ω source + ESD clamp — **goes to the BNC** |
| `AOUT_MON` port | 1 kΩ isolation — **goes to InstrumentPort `AIN0_P`** |

**Designators are not stable.** The project uses automatic annotation, so
inserting a part rotates everything after it. A global re-annotation happened on
2026-08-27; the analog block's board-side designators are now `R2001`-`R2010`,
`C2001`-`C2009`, `U2001` (DAC) and `U2002` (op amp) — note the two ICs swapped.
Where this document names one, treat the net and the role as the identifier and
the number as a convenience.

Full block documentation — layout constraints, firmware ordering, failure modes,
the filter's retune ladder — lives in the block's own description in `kicad-libs`,
which is the copy that travels with a placed instance. This section records only
what the board needs to know.

## The Filter Is Not Optional

Added 2026-08-27, and the reason is specific to this board rather than general
good practice.

The acquisition side is a Neuropixels OneBox, whose ADC is an **`AD7616-P`
sampling at a fixed 30.3 kHz** behind only a **first-order ~39 kHz** on-chip
antialias filter — about 1 dB of rejection at 20 kHz, so it effectively does not
antialias. The TMC5130A chopper runs at the datasheet-recommended **16-30 kHz**,
and *every* value in that range folds into 0-15 kHz, where it is
indistinguishable from real joystick motion. Nothing else in the chain band-limits
the signal, so this filter is the only thing standing between motor chopper ripple
and a researcher's dataset.

Second benefit: the DAC's code-change glitch is 4 nV-s / 7.5 mV, which is 9.9 mV
after the 1.32 gain — 65 OneBox LSBs of outlier on any sample that lands in it.
The filter reduces it to about 14 uV.

**Noise is not the reason.** Unfiltered output noise at the BNC is about 39 uV RMS
— roughly a quarter of the OneBox's 152.6 uV LSB on its +/-5 V range. Filtering
for noise would buy nothing measurable.

What it costs: **266 us of group delay**, and about 2 ms to settle a full-scale
step to one OneBox LSB. Both are small against behavioural timescales, and both
must be reported as measured numbers rather than assumed.

**The capacitors must be C0G.** Class-2 dielectric is piezoelectric and this board
is mechanically coupled to a stepper and a hand-driven joystick; the series
resistor can only bleed self-generated charge with time constant `R*C`, which is
pinned by the corner, so it cannot be filtered away. C0G also removes the +/-15%
X7R tempco from the corner and from the reported group delay, and its low
dielectric absorption removes a history-dependent settling tail that would read as
hysteresis in an angle channel. TI's DACx0501 datasheet section 9.2.2.6 asks for
NP0/C0G in exactly this position. 10 nF C0G needs an 0805 body; that is the cost
and it is worth paying.

To retune, scale **both** series resistors by the same factor and leave the
capacitors alone — `Q` depends only on their ratio. The full ladder is in the
block description.

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

**Before anything else: bind the block's `+3.3V` port to `+3.3V_SW`.** It exists
only to reference the `~{CS}` pull-up (`R2006`). On `+3.3V_MCU` that resistor
holds `~{CS}` at 3.3 V while the DAC's `VDD` is dead and pushes roughly 260 uA
through the DAC's input clamp into `+5V_SW` — back-powering the switched domain
from inside a block, where the isolation bus switch cannot intervene. This is
the same rule the board already applies to its buffer terminations, and it is
the easiest thing on this page to get wrong. **Verified correct on the placed
instance, 2026-08-27.**

1. **No termination resistors. All three are in the block.** **Changed
   2026-08-27**; this item used to say two were board-level.
   - `~{DAC_CS}` — 10 kohm pull-up to the `+3.3V` port, `R2006`. The required
     one: the DAC blocks `SCLK` and `SDIN` entirely while `SYNC` is high, which
     is what makes a floating bus harmless.
   - `DAC_SPI_COPI` — 10 kohm to GND, `R2009`.
   - `DAC_SPI_SCK` — 10 kohm to GND, `R2010`.

   The two pull-downs moved in-block because nothing about them is
   board-dependent — 10 kohm to GND is right on any board — and a block re-place
   cannot then lose them. **The board's nine 10 kohm terminations stay nine.**

   **This matters when the instrument-port taps go in.** `DIG9`/`DIG10`/`DIG6`
   tap these same nets on the switched side of the bus switch and need defined
   levels for the same reason `R1401`-`R1404` exist on the TMC taps — but these
   three resistors already provide them. Do not add board-level copies; a second
   set in parallel would halve them.

   **Never pull any of them to the DAC's 5 V rail.** The `SN74CB3Q3245` is a
   symmetric FET pass gate, so a 5 V pull-up on the DAC side lands on an RP2040
   pad and exceeds its `IOVDD + 0.3 V` limit.

2. **`+5V_SW`, not `+5V_MCU`.** The `OPA197` needs 4.5 V minimum and the ORed
   MCU rail can sit at 4.0-4.9 V. The switched rail is also semantically right:
   no motor rail means no valid angle, and the output section goes dark with its
   data source rather than holding a stale value. See `docs/power.md`.
   **Verified on the placed instance, 2026-08-27.**

3. **The connector.** A single vertical `HL-BNC-KHDA`, placed as **`J1101`**, and
   placement — see below. The dual-versus-single question is closed; see
   `docs/interface-map.md`.

4. **Three isolation bus-switch channels.** Satisfied by `U602`'s spare capacity
   (`A3`/`A4`/`A6`) as placed — no block edit was needed after all. `U603` and
   `U604` remain entirely empty, 14 channels of nothing, and are the obvious
   deletion when board area is wanted for the fourth buffer package.

5. **Route `AOUT_MON` to InstrumentPort `AIN0_P` and tie `AIN0_N` to `AGND`**, if
   the instrument port is wired. The series 1 kohm is **inside the block** as
   `R2008` — the board owns no resistor here, only the routing. A board-level
   1 kohm (`R1409`) was fitted briefly on 2026-08-27 and replaced by the in-block
   version, so the isolation resistor now travels with the thing it protects. See
   `docs/instrument-strategy.md`.

## Placement Is A Constraint, Not A Preference

The 249 ohm series resistor (`R2007`) and the ESD clamp (`D2001`) are inside the
block but the BNC (`J1101`) is not. **The block must sit at the connector.**
`D2001`'s ground via has to land on a connector ground pin, or its clamping
voltage is dominated by connection inductance — the same argument this repository
already makes for the `USBLC6` on `usb2`. The vertical `HL-BNC-KHDA` has four
ground pins at +/-5 mm around the centre pin, so that via placement is easy.

**Also keep the filter tight.** The two series resistors, the shunt capacitor and
the op amp's `+` input — nets `DAC_VOUT_FILT_MID` and `DAC_VOUT_FILT` — want short
traces guarded by analog ground. At 13 kohm the node is not fragile, but it is the
one place where board contamination becomes a gain term.

**Put the BNC on the opposite board edge from the motor and encoder terminals
(`J1102`, `J1103`) and from the FFC (`J1501`).** On a 100 x 80 mm board with the
motor section already placed, this is the first placement decision, not the last.

**The `AOUT_MON` route to `J1501` pin 32 is a long trace by construction** — the
block sits at the BNC and the FFC is elsewhere. That is fine and is what the 1 kohm
is for: crosstalk picked up along it lands on the op amp's low-impedance output
rather than on the researcher's node. Do not "improve" it by moving the block
toward the FFC; the ESD clamp's ground via has the stronger claim.

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
  fraction of the correct voltage. **Resolved 2026-08-27: the OneBox's ADC is an
  `AD7616-P` and its datasheet specifies 1 Mohm**, so the loading error is
  -0.025%, or -0.82 mV at full scale, which per-board calibration absorbs. No
  bench measurement is needed — see
  `../kicad-libs/docs/onebox-analog-interface.md`.
- **The output cannot reach a true 0 V, and the floor is 4.5 mV — not 25 mV.**
  **MEASURED 2026-09-10** on board `E4654C159F171E34`, Fluke 87 on DC volts at
  the BNC. The estimate below was wrong by 5.6x.
  ~~The `OPA197`'s output stage sits about 25 mV off the negative rail at light
  load.~~ It sits **4.5 mV** off, into a high-impedance load. Mapping the valid
  angle range to start at **50 mV or above** still holds and now has more margin
  than intended.
  **But the three-level out-of-band scheme breaks.** See "The fault behavior
  needs an explicit decision" below: the floor was doing the work of separating
  a firmware-signalled fault from a dead output section, and a 4.5 mV gap does
  not do that. v1.0's ÷2 divider halves it again to 2.25 mV.
- **Update rate: 1 kHz, MEASURED 2026-09-10, and it is no longer an open
  decision.** 835 000 updates over 14 minutes on board `E4654C159F171E34` at
  **exactly 1000.0 Hz** with zero budget overruns, worst iteration **527 µs** of
  the 1000 µs budget. `examples/MotionAndHoming` command `L` reports the achieved
  rate, which is what this bullet asked for.
  **2 kHz is not available** — a 527 µs worst case is most of a 500 µs budget —
  and 4 kHz is out of reach. The estimate below turned out to be right, and a
  bus-arithmetic estimate of 77 kHz made in the same session was wrong by 36x,
  because raw transfer time ignores the TMC51X0 library, SPI transaction setup
  and USB servicing. **Do not quote bus arithmetic as a loop rate.**
  **The staircase is visible under fast motion.** At a 5.01 rev/s flick
  (20 042 counts/s) each update steps **74 mV = 22.8 encoder counts = 485 OneBox
  codes**, against 3.25 mV for one encoder count — so at speed the update rate
  quantises 23x coarser than the encoder. The filter smooths but does not
  suppress it: settling takes ~2 ms and updates arrive every 1 ms, so each step
  is half-settled when the next lands. **Nothing aliases** — a 33 ms swing is
  roughly a 15 Hz half-cycle against a 500 Hz Nyquist — so this is visible
  quantisation, not lost information. What it does bound is **timing precision
  on the recorded trace: 1 ms.** The `PULL` event is unaffected; firmware detects
  it from the encoder and it never crosses the analog path.
- **The encoder-to-DAC loop is itself a sampling operation, and the filter is
  downstream of it.** Added 2026-09-10. The 987 Hz Sallen-Key smooths the DAC's
  output steps but cannot undo aliasing introduced by sampling the angle at
  1 kHz. Mechanical content above ~500 Hz folds into the record and nothing
  downstream removes it. Mouse limb motion should be far below that — the fastest
  hand flick measured was ~15 Hz — but this is a **distinct** issue from the
  OneBox aliasing covered elsewhere in this document, and it had not been
  written down.
- Historically, on the DAC versus the filter: **the filter is the limit, not the
  DAC**. **Corrected 2026-08-27**: this bullet used to say that the DAC's 5 us
  settling and 24 us frame meant the DAC was not the limit. The 987 Hz filter
  contributes 266 us of group delay and about 2 ms to settle a full-scale step to
  one OneBox LSB, so it dominates both figures by an order of magnitude. The
  encoder-read loop is the other limit: TMC SPI is <=4 MHz and a 40-bit `X_ENC`
  read is ~10 us plus overhead, so roughly 1 kHz of real angle bandwidth is what
  the loop can sustain alongside motor control. 10 kHz is not reachable on this
  architecture, which is a second reason not to raise the filter corner. Choose
  the rate against the mouse's actual pull dynamics, and document the achieved
  rate and latency as a **measured** claim, not a target.
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
  merge** — `+5V_FILT`, `AMP_VOUT`, `AMP_FB`, `DAC_VOUT`, `DAC_VOUT_FILT_MID`,
  `DAC_VOUT_FILT`, `VREFIO` — the ferrites parallel and the `PWR_FLAG`s conflict.
  Give each instance its own sheet. **The two filter labels were added
  2026-08-27.**
- **The dual BNC question is closed, 2026-08-27.** The board carries a single
  vertical `HL-BNC-KHDA` as `J1101` — neither the dual `DOSIN-801-0095` nor the
  single `DOSIN-801-0050` this section debated. `AUX_ANALOG_OUT` is not
  populated at rev 1 and `AIN1_P/N` stay no-connect.

This weakens but does not kill the case for a validity output on a second
channel; see below.

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
still.

**REVISED 2026-09-10, because the floor was measured at 4.5 mV and the original
recommendation depended on it being ~25 mV.**

~~**Recommendation:** drive 0 V on fault, which the ~25 mV floor makes a
naturally out-of-band level once the valid range starts at 50 mV.~~ Driving code
0 puts the output at the floor, and a **4.5 mV** floor is not meaningfully
distinguishable from the true 0 V that a dead output section produces — 4.5 mV,
halving to 2.25 mV at v1.0, against recording-chain offset and thermal drift.

**Revised recommendation: choose the fault level rather than inheriting it from
the op amp's swing limit. Drive code 497 = 25 mV.**

| Level | Volts at the BNC | Code | From true 0 V |
| --- | --- | --- | --- |
| hardware dead, or a reference alarm | 0 V | — | — |
| firmware-signalled fault | **25 mV** | **497** | 164 OneBox codes |
| lowest valid angle | 50 mV | 993 | 328 OneBox codes |

That restores the 25 mV separations this scheme was designed around,
deliberately rather than as a side effect, and survives the v1.0 halving at
12.5 mV — still 82 OneBox codes. It costs one constant. **Not yet applied: it
changes what recorded data means.** Do not leave it
ambiguous, because this signal ends up in a researcher's recorded dataset with no
other indication of board state.

Two hardware failure modes produce 0 V and must not be confused with the fault
level in analysis: an unpowered output section, held at 0 V by the 100 kohm
output pull-down (`R2005`), and a
reference alarm from a misconfigured `REF-DIV`. Both read as a legitimate end of
travel. `STATUS` must report the output as invalid in either case.

## The Angle Mapping Is Still Open, And Now It Has Numbers (2026-09-10)

The bullet above asks for "the angle range mapped to 0.05-3.300 V" to be
documented. **It has never actually been decided**, and the researcher's
2026-09-10 reply is the input that makes the choice tractable.

Geometry, from the rig rather than from assumption: gearing is **1:1** with the
encoder on the motor shaft, so 1 encoder count = **0.0900°**
(`docs/bringup-log.md`), and the lever arm at the mouse's grip is **75-76 mm**
(rig-measured 2026-09-10; the old rig's CAD gives 72-73 mm). The task's reward
threshold is a **5 mm** pull. Therefore:

| Quantity | Value |
| --- | ---: |
| 5 mm of pull | **3.77°-3.82°** |
| ↳ in encoder counts | **41.9-42.4** (≈42) |
| ↳ as a fraction of the 64.174° swing | **5.9%-6.0%** |
| 1 encoder count, in pull distance | **0.118-0.119 mm** |
| Full mechanical travel at the grip | **84-85 mm** |

**So with the full swing mapped to 0.050-3.300 V, the scientifically interesting
part of every trial lives in the bottom ~6% of the trace** — 191-193 mV
pre-divider, 96-97 mV after v1.0's ÷2. That is a mapping problem, not a divider
problem: the ÷2 costs 1 bit, the mapping costs about 3.

Narrowing it is **firmware-only and free**. Mapping 0-20 mm of pull (4× the
threshold, 25% of mechanical travel) recovers **2.0 bits** and puts the threshold
at a quarter span; 0-10 mm recovers 3.0 bits and centres the threshold but clips
at 12% of travel.

**Keep the full-swing mapping as the shipped default until the peak-pull
distribution arrives.** It is the only mapping that cannot clip a pull, and
clipping a pull peak is unrecoverable in analysis while clipping the robotic
retraction is harmless. Trial structure comes from the digital lines, not from
the analog trace, so a narrower window costs no trial boundaries. **The number
owed is the distribution of peak pull distance per trial**, which the researcher
already has in the DeepLabCut joystick trajectories.

Whichever mapping ships, record it per session and per board serial with the
other calibration constants.

## Open Decisions

- Whether `AUX_ANALOG_OUT` is ever populated, and what it would carry —
  validity, a second derived quantity, or nothing. Costs a full second instance
  plus a second jack. **Not populated at rev 1.**
- DAC update rate and the resulting latency budget, now including the filter's
  266 us.
- Output behavior when unhomed, disarmed, or faulted.
- **Whether the 987 Hz corner is right**, which only a bench measurement of the
  chopper artifact on `AIN0` can answer. Sweep the chopper frequency and see
  whether the artifact moves; if it does, it is aliasing rather than motion.
  Retune by scaling both series resistors — the ladder is in the block
  description.

**Closed 2026-08-27:** whether `J7` is dual or single (single `HL-BNC-KHDA` as
`J1101`), and the OneBox ADC input impedance (1 Mohm, from the `AD7616-P`
datasheet).

**Closed since the 2026-08-12 draft:** the `DAC8563` `VIH` question, whether a
level translator is required, whether to buffer the output, and how the output is
protected. All four are settled in the block.
