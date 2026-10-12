# B5Z Magnetic Particle Brake Controller

**Moved** here from `kicad-libs/docs/` on 2026-10-07. Paths into that repository are written `kicad-libs/…`; the datasheets it cited from its `tmp/` cache are in the private store `kicad-libs-nonfree/datasheets/`.

**Status:** topology selection and the brake purchase list in this note are
**superseded as of 2026-08-31** by `kicad-libs/docs/brake-current-sink-design.md`, which
owns the circuit, its values, and its bill of materials. What remains current
here: the brake requirements, the previous-board prior art, the brake/torque
noise-isolation rules, and the validation plan.

This note records the background for controlling a Placid Industries
`B5Z-24-1R` magnetic particle brake from the `mouse-joystick-pcb` nominal 36 V
rail. The older spelling `B5Z-24-IR` in this repository appears to confuse the
digit `1` with the letter `I`; verify the purchased brake nameplate before
freezing fields or silkscreen text.

## Recommendation Summary

The brake and the low-level torque bridge will operate simultaneously. Treat
brake-driver noise as a measurement-system requirement, not merely an EMC
cleanup item.

**Settled 2026-08-31.** The DAC-programmed linear current sink is the design, not
one of three candidates. The evaluation ladder below is retained as a record of
what was rejected and why:

1. **Chosen:** a smooth, DAC-programmed linear current sink using an external
   pass device. At only 49 mA the worst pass-element dissipation is 0.71 W, so
   the switching converter is avoided with no meaningful thermal penalty. The
   pass device is now a **stocked MOSFET, not a high-voltage NPN** — see
   `kicad-libs/docs/brake-current-sink-design.md` for the base-current argument. Full
   values, BOM, and open items live in that document.
2. **Rejected as the final design, retained as prior art:** the stocked
   `BCR421UE6327` with its 30 ohm set resistor. It programs average torque by
   PWM, has little voltage margin on a 36 V rail, and its regulated current
   drifts with self-heating. It remains a valid corrected bench prototype if one
   is ever wanted, under the conditions listed below.
3. **Dropped, not deferred:** `LM3404HV`. Total brake load is 1.76 W. Placing a
   400 kHz switch node beside a 15 mV bridge to recover 0.7 W of linear
   dissipation is a bad trade, and no thermal argument forces it. The purchases
   listed for it in [Switching Fallback
   Purchases](#switching-fallback-purchases) are cancelled.

**Two requirements consequences were missed on the first pass** and are now
recorded in `kicad-libs/docs/brake-current-sink-design.md`: coil I²R (1.11 W at rated
current) is not slip heat and is the term that sets case temperature, which makes
the NTC case probe optional rather than Priority A; and the datasheet's
approach-direction torque hysteresis is percent-level, which caps the useful
precision of the whole current path at about 1% and makes the torque sensor the
calibration reference.

Do not use the torque sensor as a substitute for a hardware current limit. The
electrical current measurement and torque measurement answer different
questions:

- current confirms the driver, wiring, and coil are behaving electrically;
- torque includes brake hysteresis, friction, mechanics, and the applied load;
- a hardware current ceiling remains necessary even if firmware closes a loop
  around measured torque.

Initially use torque feedback for calibration and supervisory observation, not
as a fast closed loop. A fast loop around the animal, mechanism, brake
hysteresis, and sensor could create dynamics that are harder to interpret than
the open-loop brake.

## Brake Requirements

Source datasheet: `kicad-libs-nonfree/datasheets/B5Z-metric-data-sheet-1.pdf`

- Winding: 24 V nominal
- Rated coil resistance: 467 ohm
- Rated current: 49 mA at 100% input current
- Rated torque: 3.5 N-cm at 100% input current
- Torque is proportional to current, with different curves when approaching a
  current from 0% and from 100%
- Recommended supply type: adjustable constant-current DC supply
- Response: 6 ms unforced, 3 ms forced
- Maximum brake case temperature: 75 C
- Continuous slip heat limit: 2 W
- Continuous slip heat formula: `W = RPM * torque_N_cm / 960`
- Always electrically ground the brake body

At 49 mA the cold 467 ohm winding needs about 22.9 V. A roughly 560-570 ohm hot
winding needs about 27.4-27.9 V. A 36 V supply therefore provides useful
current-regulator compliance. A 24 V rail cannot maintain rated current through
the hot winding.

The brake must not be driven directly from 36 V. A cold 467 ohm winding would
draw about 77 mA, well over its 49 mA rating. Supply stability does not make
fixed-voltage drive safe; the winding resistance changes with temperature.

## Previous-Board BCR421 Circuit

The fabricated previous-generation board used:

- `U801`: `BCR421UE6327`
- `R801`: 30 ohm
- `C801`: 100 uF, 50 V
- `J801`: 2-position 3.5 mm terminal

That sheet has no current monitor, external PWM generator, or visible flyback
diode. It is useful prior art but should not be copied unchanged.

The BCR421 is stocked as `OW-PWR-BCR421UE6327`, JLCPCB `C112923`, quantity 495
in the current inventory export. Its relevant characteristics are:

- low-side constant-current regulator with logic PWM input;
- 30 ohm gives approximately 49-50 mA from the typical curves;
- 40 V maximum output voltage;
- up to 1 W package dissipation only with an appropriate thermal layout;
- typical current temperature coefficient of -0.2%/K;
- PWM input rated to 10 kHz.

At 36 V and 49 mA, approximate BCR421 dissipation is:

- cold 467 ohm coil: `(36 - 22.9) * 0.049 = 0.64 W`;
- hot 560 ohm coil: `(36 - 27.4) * 0.049 = 0.42 W`.

Those values are thermally plausible, but self-heating causes the regulated
current to fall. The 40 V output rating is the larger concern. Whenever a
connected brake is off, its resistance pulls the low-side output toward the
36 V rail. A flyback diode can add a forward drop above that rail during current
decay. There is too little margin for an unspecified 36 V supply maximum,
hot-plug ringing, and cable inductance.

If the BCR421 is prototyped:

- measure the actual 36 V rail maximum and transient overshoot first;
- place a Schottky flyback diode directly across the two coil terminals,
  cathode to the 36 V side and anode to the BCR421 side;
- use substantial copper under and around all three `OUT` pins;
- add a pull-down at `EN` so reset and disconnection mean brake off;
- prohibit live connector removal unless the harness/load-side inductive
  energy has its own safe path;
- measure peak current, average current, BCR421 temperature, and torque versus
  duty after thermal equilibrium;
- do not infer production accuracy from the typical 30 ohm graph alone.

## Preferred Low-Noise Linear Current Sink

**The concept below is the chosen design. Its values are now settled in
`kicad-libs/docs/brake-current-sink-design.md`; use that document for anything you intend to
draw.** The remaining text here is the reasoning, and two of its specifics have
been revised: `R_SENSE` is 10 ohm as suggested, but the pass device is a stocked
MOSFET rather than an `MJD340`-class NPN, and the independent ceiling is a third
stocked `OPA197` rather than a `TLV7041`.

The preferred concept replaces PWM amplitude control with a continuously
adjustable analog current loop:

```text
+36V_SW ----+---- brake coil ----+---- QPASS collector/drain
            |                    |       QPASS emitter/source ---- RSENSE ---- BRAKE_PGND
            +-----|<|------------+                    ^
               flyback diode                          |
                                           op amp current loop
                                                    ^
                                                    |
                         DAC -> scaling + low-pass -+-- default-off clamp
                                                        / BRAKE_ENABLE

RSENSE -> buffer/gain -> BRAKE_ISENSE
RSENSE -> independent overcurrent comparator -> clamp + ~BRAKE_FAULT
```

The control law is simply:

`I_BRAKE = V_SET / R_SENSE`

A reasonable design start is `R_SENSE = 10 ohm`, which requires
`V_SET = 0-490 mV` and dissipates only about 24 mW at 49 mA. Scale and filter
the DAC output so its maximum possible output, not merely its programmed normal
range, cannot command more than the rated current. Use 0.1% or better and low
TCR for `R_SENSE` and the scaling network.

With a cold coil and a roughly 0.49 V sense drop, QPASS dissipates about:

`(36 - 22.9 - 0.49) * 0.049 = 0.62 W`

That is modest for a DPAK, SOT-223, or exposed-pad power package with a real
copper heat spreader. The transistor still needs a verified **DC safe operating
area** at approximately 10-15 V and 50 mA. Low `RDS(on)` and pulsed-current
ratings do not establish linear-mode suitability.

A high-voltage NPN BJT is attractive at this small current because its DC safe
operating area is explicit and it avoids the thermal-instability questions of
many switching-optimized MOSFETs. An `MJD340`-class NPN is a useful search
starting point: 300 V `VCEO`, 0.5 A continuous current, DPAK, minimum current
gain 30 at 50 mA/10 V, and published active-region SOA. A suitable rail-to-rail
op amp can supply the roughly 1.7 mA worst-case base current. A MOSFET remains
acceptable only after its DC SOA is checked at the actual board temperature.

**Reversed 2026-08-31.** The BJT is no longer the preference, and the reason is
measurement rather than thermal. A ground-referenced emitter shunt measures
`I_C + I_B`, so it reads high by `1/(hFE+1)` — 0.7% to 3.3% across the guaranteed
gain spread, varying with current and temperature. That is a *systematic* error in
a torque-calibrated system, and a MOSFET removes it rather than requiring it to be
characterized. The DC-SOA objection to a MOSFET does not survive the numbers at
0.71 W and 49 mA: see the SOA and hot-spot analysis in
`kicad-libs/docs/brake-current-sink-design.md`. The stocked `BUK7D36-60EX` is the pass
device, with the 80 V `BSC072N08NS5ATMA1` placed as a DNP alternate against the
documented `+36V_SW` ringing. No `MJD340T4G`, `MJD122T4G`, or LinearL2 MOSFET
purchase is needed.

### Safe State And Independent Current Ceiling

The DAC and main op amp must not be the only current limit.

- Select a zero-scale power-on-reset DAC variant.
- Pull the pass device off in hardware.
- Add `BRAKE_ENABLE` as an active-high arm input with a passive default-off
  state. This signal enables the analog stage; it does not modulate torque.
- Add a separate comparator at roughly 52-55 mA that overrides the op amp and
  removes pass-device drive. Give it hysteresis or a latch appropriate to the
  fault policy.
- Export the comparator state as `~BRAKE_FAULT` if that board interface is kept.
- Size the analog scaling so a full-scale DAC command is no greater than 49 mA.
- Do not rely on firmware register initialization, the torque sensor, or the
  upstream 36 V smart switch as the only protection.

**Corrected 2026-08-31 — the scaling bullet above is not a ceiling on its own.**
A DAC's absolute-maximum output is its `VDD`, which for the `DACx0501` family in
`BUFF-GAIN = 1` is twice its programmed full scale. A divider that maps 2.5 V to
49 mA therefore still permits 98 mA at `VDD = 5 V`, or 62 mA at `VDD = 3.3 V`,
under a firmware or DAC fault. Two changes close this, and both are in
`kicad-libs/docs/brake-current-sink-design.md`:

- **Power the brake DAC from 3.3 V.** `REF-DIV = 0` is the reset default and is
  out of spec at `VDD = 3.3 V`, and the datasheet states that improper
  reference-divider configuration shuts down the reference buffer and drives all
  outputs to 0 V. The 0-2.5 V span becomes a hardware property and the
  wrong-`GAIN` failure becomes fail-safe rather than fail-hot.
- **Use a third stocked `OPA197` as the independent ceiling, not a `TLV7041`.**
  This note's own audit flagged the `TLV7041`'s ±8 mV offset and 3-25 mV
  hysteresis as something that must be budgeted into the threshold — ±3.3% of a
  550 mV threshold. The `OPA197`'s ±100 µV offset is ±0.02%, so the ceiling can
  sit at 56 mA with a comfortable 13% margin over the command maximum. It is a
  better comparator here, not merely a cheaper one.

The `TPS3431` hardware watchdog is **dropped for rev 2**, reversing the guidance
in the purchase plan. "Brake stuck at 49 mA" is the brake's rated continuous
operating condition rather than a damage mode, and the board already gives the MCU
an unconditional hardware kill through `HV_EN` on the `TPS1HTC100-Q1`, which
deliberately bypasses the GPIO isolation bus switch. Reversible by purchase if
bench experience disagrees.

The current-loop bandwidth need not be high. The brake response is 6 ms
unforced, and trial-level torque commands are likely slower. Start with a
well-damped loop and a DAC-output RC filter; raise bandwidth only after measuring
step response and stability with the actual coil and cable.

### Current Feedback

The low-side sense voltage is already ground referenced and represents the
regulated current. A second channel of a dual op amp can buffer and scale
0-490 mV to a convenient 0-2.5 V or 0-3.0 V `BRAKE_ISENSE` output.

- Route `BRAKE_ISENSE` to the MCU ADC if closed-loop diagnostics are wanted.
- It is also a good candidate for InstrumentPort `AIN1` after buffering.
- Do not put raw high-side shunt nodes on InstrumentPort.
- Keep a local Kelvin test pair across `R_SENSE`, even if the amplifier is
  populated.
- Compare commanded and measured current in firmware to detect an open coil or
  a pass-stage fault.

A low-side shunt below QPASS does not measure the brief recirculating current
that flows through a diode placed directly across the coil after QPASS turns
off. Measure that decay at the coil during validation if it matters to torque
step response; do not mistake the low-side trace for all transient coil current.

The stocked `INA230` is not a comfortable high-side alternative: its 36 V
common-mode limit is exactly the nominal rail and therefore provides no useful
supply or transient margin. The analog sink does not require it.

## DAC Interface Instead Of A PWM Generator

A serial DAC provides the same MCU portability sought from a dedicated PWM
chip while avoiding chopped brake current. A 12-bit DAC gives approximately
12 uA per code over a 49 mA range, already much finer than the expected brake
accuracy and torque hysteresis. More resolution can help calibration but is not
required for basic command granularity.

Prefer a DAC with:

- I2C or SPI selected by a hardware pin;
- an internal precision reference or a well-defined external-reference input;
- zero-scale power-on reset;
- monotonic output;
- a package that can be assembled and inspected reliably;
- output range and supply rails that permit a passive, hardware-safe maximum
  current scaling network.

The PCA9685 remains a useful PWM option, but it does not create a safety
boundary. Its last duty setting persists if firmware hangs. If it is used:

- pull `OE` high for a disabled reset state;
- pull every brake `DIM` input low locally;
- lower `OE` only after all channel registers are written to off;
- arrange for reset or a hardware watchdog to return `OE` high;
- observe the actual output waveform, not only the requested duty;
- verify what happens when the 36 V switched domain is power-cycled while the
  always-on PCA9685 retains its previous state.

## LM3404HV Switching Fallback

**Dropped 2026-08-31, not deferred.** Total brake load is 1.76 W; a 400 kHz
switch node beside a 15 mV bridge is not worth 0.7 W of linear dissipation, and
the headroom analysis in `kicad-libs/docs/brake-current-sink-design.md` shows the linear
stage has 4.2 V of margin at the worst-case hot winding and low rail. The section
is retained only so that a future revision does not have to re-derive it, and the
purchases it calls for are cancelled.

Use the `HV` version for nominal 36 V. The plain LM3404 has too little practical
operating margin for supply tolerance and ringing.

Starting values from the earlier analysis remain useful for a prototype:

| Ref | Starting value | Notes |
| --- | --- | --- |
| U1 | `LM3404HV` | Prefer PowerPAD package when practical |
| RON | 430 kohm, 1% | Approximately 400 kHz near cold full-current operation |
| RSNS | 4.22 ohm, 1% | First-pass 49 mA setting; tune with real hardware |
| L1 | 2.2 mH | Also evaluate 4.7 mH for lower ripple |
| D1 | >=60 V Schottky, >=1 A | Stocked `DSK36` is a starting candidate |
| CB | 10 nF X7R, >=25 V | Bootstrap capacitor from `BOOT` to `SW` |
| CF | 100 nF X7R, >=25 V | `VCC` bypass |
| CIN | 2.2-4.7 uF X7R, 100 V | Close to `VIN` and power ground |
| Bulk | 47-150 uF, >=63 V | Local to the power entry or brake zone |
| CS resistor | 1 kohm | Datasheet-recommended protection |

Approximate predicted current with 36 V, 430 kohm, 2.2 mH, and 4.22 ohm was
49.5 mA cold and 47.8 mA hot. Buy 4.02, 4.12, 4.22, 4.32, and 4.42 ohm values
for tuning. If a 2.2 or 4.7 mH inductor cannot tolerate the controller's fault
current without saturating, document and test that fault instead of relying on
the 49 mA normal load rating.

For PWM dimming, start around 250-500 Hz only as a test point. Measure current
decay and torque ripple; the brake inductance is not specified, so average
current cannot safely be assumed to equal duty times 49 mA. If PWM remains in
the final design, consider coherent torque sampling and PWM-synchronous
averaging rather than allowing an unrelated PWM carrier to alias into the
sensor data.

## Brake And Torque-Sensor Noise Isolation

The torque sensor is a millivolt-level bridge. Tens of milliohms of shared
ground impedance carrying 49 mA can create errors comparable to its signal.
The most important isolation is control of current return paths, not an
arbitrary split in the ground plane.

### Placement And Routing

- Put the brake power stage at the board edge near the 36 V entry and brake
  connector. Put the bridge connector, excitation, PGA/ADC, reference, and
  anti-alias filter at the opposite side of the board.
- Route brake supply and return as a close pair. Return brake current directly
  to the power-entry/power-stage ground junction; never let it traverse torque
  `AGND`, bridge return, reference ground, or ADC ground copper.
- Give bridge excitation and bridge return dedicated Kelvin routes to the
  torque front end. Do not share a connector return pin or trace with the brake.
- Keep a continuous reference plane where practical, but partition placement
  and current flow. Do not create a split-plane gap that digital or analog
  signals must cross.
- Keep the brake connector and torque connector physically separated. Use a
  twisted pair for the brake coil. Use a separate shielded/twisted harness for
  the bridge signals and excitation.
- Ground the brake body through a deliberate chassis/protective path. Do not
  route case-ground current through torque-sensor analog ground.
- Do not route brake command, pass-device drive, flyback, PWM, or switch-node
  copper under the torque connector, bridge traces, reference, or ADC.
- Add grounded guard copper and a via fence between zones when it does not
  increase capacitance on a switching node.

### Supplies And Digital Coupling

- Feed the torque front end from its own low-noise LDO and local RC/ferrite
  filtering. Do not share the brake driver's local decoupling path.
- Filter the DAC/reference supply as an analog rail. A ferrite bead plus local
  bulk and ceramic bypassing may be sufficient for the op amp; verify rather
  than assuming the existing 5 V switcher is quiet.
- Slow serial clock edges with source series resistors where timing allows and
  keep I2C/SPI clocks away from bridge traces.
- Schedule DAC updates outside critical ADC conversion intervals if measured
  digital feedthrough warrants it.
- Galvanic digital isolation is not the first choice: it requires isolated
  power, often adding another switching converter. Add it only if the physical
  zoning and return-path design fail measured noise requirements.

### If A Switching Brake Driver Is Required

- Use a shielded inductor and keep the `VIN` capacitor, controller, catch diode,
  sense resistor, and switching loop in the smallest possible area.
- Keep `SW` copper minimal and entirely inside the brake zone; never use a large
  switch-node copper pour as a heat spreader.
- Give the brake zone a local input filter so switching current does not flow
  through the torque analog supply path.
- Place the torque anti-alias filter at the ADC/PGA input, not at the remote
  connector.
- Measure conducted noise on bridge excitation, bridge return, analog supply,
  and ground as well as radiated coupling from `SW`.
- Prefer a fixed carrier with known spectral lines. Synchronize acquisition or
  reject those lines digitally only after confirming the analog front end is
  not saturating.
- Do not use spread spectrum merely to make a spectrum look smoother; it can
  move interference into more torque-measurement bins.

## Stocked Supporting Parts

Based on `kicad-libs/db/source/jlc_inventory_export.csv` during this review:

| Role | Stocked part |
| --- | --- |
| Linear PWM prototype | `BCR421UE6327`, `C112923`, qty 495 |
| BCR set resistor | 30 ohm 1% 0402, `C3036820`, qty 2990 |
| PWM generator | `PCA9685BS,118`, `C5191634`, qty 95 |
| Flyback/catch diode | `DSK36`, `C106913`, 60 V 3 A, qty 3000 |
| Higher-voltage Schottky option | `S115Q`, `C5362393`, 150 V 1 A, qty 3000 |
| Input ceramic | 2.2 uF 100 V, `C2981733`, qty 105 |
| Small HV bypass | 100 nF 100 V, `C77058`, qty 4000 |
| Input bulk | 150 uF 63 V, `C51018328`, qty 400 |
| Brake connector | `1844210`, `C3584780`, 2-position 3.5 mm, qty 485 |
| **Pass device (final, 2026-08-31)** | `BUK7D36-60EX`, `C3288253`, qty 1360; 60 V, 2.3 W at `Ta`. **Sole pass device — no alternate is placed.** Linear-mode operation at 0.71 W / 49 mA analysed in `kicad-libs/docs/brake-current-sink-design.md`; confirm `V_GS(th)` and the SOA curve against NXP's datasheet and a measured case temperature |
| ~~Pass device DNP alternate~~ | ~~`BSC072N08NS5ATMA1`~~ **Rejected 2026-08-31.** Its `V_GS(th)` is 3.8 V max at 36 µA, so at 49 mA the gate node lands near 4.6 V against an `OPA197` ceiling of about 4.85 V on a 5 V rail — 0.25 V of margin, consumed by a cold start. And a 60 V part cannot be the weakest thing on the rail: the TMC5130A's inductive-load absolute maximum is 49 V, which is 80% of 60 V, so ringing that threatens the brake FET has already destroyed the driver. Fix that case with a TVS at the 36 V entry, not a bigger brake FET |
| Precision op amp on hand | `OPA2210IDRGR`, `C2866278`, qty 50; input common-mode does not make it the default low-side loop choice |

The stocked TVSs remain unsuitable as a general 36 V clamp: `SMBJ28A` has too
low a standoff voltage, while `SMF48A` and `SMBJ58A` clamp too high for the
weaker 40-60 V devices in the system.

## Parts To Search For And Purchase On JLCPCB

**Cancelled 2026-08-31.** The whole brake column resolved to stock. Every part the
brake driver needs is already in JLCPCB inventory and already in
`kicad-libs/db/source/internal_parts.csv` with a symbol and footprint — see the bill of
materials in `kicad-libs/docs/brake-current-sink-design.md`. Specifically cancelled from the
tables below: `DAC60501ZDGSR`, `OPA2197IDR`, `MJD340T4G`, `TLV7041DBVR`, the
precision current shunt, the precision DAC scaling network, the default-off clamp
transistor, and the brake case-temperature probe. `TPS3431SDRBR`, `MJD122T4G`,
and `IXTA6N50L2` are cancelled from the companion purchase plan for the same
reason.

The only two SKUs still worth ordering for the brake are **replenishment**, not
new parts: `DAC80501ZDGSR` (50 in stock, 2 per board with the angle block) and
`OPA197IDBVR` (100 in stock, about 6 per board across brake, angle, and torque).

The tables below are retained as a record of the search criteria, which remain
correct if any of these positions is ever reopened.

### Preferred Analog Linear Prototype

| Function | Search target | Selection guidance |
| --- | --- | --- |
| Zero-scale serial DAC | `DAC60501ZDGSR` (12-bit) or `DAC80501ZDGSR` (16-bit) | I2C/SPI selectable, internal reference, zero-scale POR. Prefer the `Z` zero-scale variant, not the `M` midscale variant. A cheaper monotonic 12-bit I2C DAC is adequate if its POR and full-scale behavior are explicit. |
| Dual loop/sense op amp | `OPA2197IDR` or single `OPA197IDBVR` plus a second buffer | True rail-to-rail input/output, 4.5-36 V supply, low offset, enough output current for a BJT base, and usable at ground on a 5 V supply. Verify loop stability with the pass device and coil. |
| High-voltage NPN pass device | `MJD340T4G` | 300 V, 0.5 A DPAK with published DC SOA and minimum gain at 50 mA. Search alternates by DC SOA at >=15 V/50 mA, not only voltage/current headline ratings. |
| Precision current shunt | 10 ohm, 0.1%, <=25 ppm/C, 0805 or 1206, >=0.125 W | Produces 490 mV at 49 mA and only 24 mW. Buy nearby values for calibration or use a parallel trim position. |
| Precision DAC scaling resistors | 0.1%, <=25 ppm/C matched network or discrete pair | Scale the DAC's worst-case possible output to <=490 mV. Matching and tracking matter more than absolute package size. |
| Independent overcurrent comparator | `TLV7041DBVR` or similar open-drain comparator | The audited TLV703x/704x datasheet identifies `TLV7041` as open-drain and `TLV7031` as push-pull. Its input range includes ground; include maximum offset and internal hysteresis in the current-ceiling calculation and give the output enough authority to clamp pass-device drive. |
| Low-noise DAC/reference LDO | `TPS7A2033PDBVR` or similar 3.3 V low-noise LDO | 1.6-6 V input, low output noise, high PSRR, enable pin. Feed from the board 5 V rail through appropriate local filtering. |
| Default-off clamp transistor | `2N7002` or small NPN such as `MMBT3904` | Used to force `V_SET` or pass-device drive low when `BRAKE_ENABLE` is absent or a fault occurs. Choose the polarity so an open control wire means off. |
| Brake case-temperature sensor | 10 kohm NTC probe or board-compatible NTC with harness provision | The datasheet limits case temperature to 75 C. A PCB sensor does not measure a remote brake case; plan a mechanically attached probe if temperature is safety relevant. |

Buy enough of the DAC, op amp, pass transistor, comparator, shunt, and scaling
network to build at least three independent channels or prototypes. Matching
two joysticks and retaining one instrumented spare is more useful than buying
only the exact board quantity.

### Switching Fallback Purchases

- `LM3404HV`, not plain `LM3404`;
- 4.02, 4.12, 4.22, 4.32, and 4.42 ohm 1% or better low-TCR sense resistors;
- 2.2 mH and 4.7 mH shielded inductors, with saturation/fault behavior checked;
- 36 V-rail TVS candidate in the `SMBJ40A` or `SMBJ43A` class, selected only
  after the supply maximum and TVS clamp curves are known;
- output/open-load protection parts selected from the final topology rather
  than copied from a linear sink.

## Proposed Design-Block Boundary

**Settled 2026-08-31** as `brake_current_sink_0_49ma_dac80501`, with the port list
and the boundary decisions in `kicad-libs/docs/brake-current-sink-design.md`. Three things
changed from the proposal below: the **connector is inside the block** (the flyback
diode has to sit across its pins, and separating the two invites a board that
forgets it, so this follows the `hv_input_*` blocks rather than
`analog_output_0_3v3_dac80501`); the **case-temperature connector is dropped**
because coil heat rather than slip heat sets case temperature at this duty; and
**brake-body grounding is mechanical**, because no 3-position 3.5 mm terminal
block is in stock. The proposal is otherwise intact.

For the low-noise implementation, a first private block can expose:

- `+36V_SW`, `+5V_SW` or the selected analog supply, and `BRAKE_PGND`;
- `SCL` and `SDA`, or the chosen serial DAC interface;
- active-high `BRAKE_ENABLE`, default off;
- `BRAKE_ISENSE`, ground-referenced analog output;
- `~BRAKE_FAULT`, if the independent comparator is populated;
- the two brake-coil connector pins;
- a separately documented brake-body/chassis-ground connection;
- local Kelvin current test points and optional case-temperature connector.

Join `BRAKE_PGND` to board ground once at the defined power-stage return point,
using a net tie if separate net names are needed to enforce routing. If one
continuous `GND` net is retained instead, use placement and routing constraints
that guarantee the brake return still reaches that point without crossing the
torque analog zone.

The existing mouse-board plan assigned InstrumentPort `DIG11` to `BRAKE_DIM`.
If the analog design is selected, revisit that name rather than manufacturing a
fake PWM signal. `BRAKE_ENABLE`, `~BRAKE_FAULT`, or a DAC update marker may be a
more truthful digital observation. `AIN1` remains a natural home for buffered
`BRAKE_ISENSE`.

**Resolved 2026-08-31:** `DIG11` becomes `BRAKE_CS`, the DAC frame, which lets a
capture timestamp every brake command — the DAC-update marker option above.
`DIG12` keeps `~{BRAKE_FAULT}`, and `AIN1` takes `BRAKE_ISENSE`. Propagated to
`mouse-joystick-pcb/docs/interface-map.md`.

Keep the first block private and project-specific until bench results validate
it. Promote a reusable abstraction only after the mouse board verifies it and
a second use establishes which boundary is actually reusable.

## Validation Plan

Validate the brake and torque paths together, with the motor driver operating,
because quiet standalone brake measurements do not establish simultaneous-use
performance.

Electrical and thermal:

- actual 36 V minimum, maximum, ripple, startup, shutdown, and hot-plug ringing;
- brake current accuracy at several commands, cold and after warm-up;
- current-loop step response, overshoot, stability, and decay to zero;
- pass-device, BCR421, shunt, diode, and PCB temperatures at 100% command;
- independent overcurrent threshold and latch/recovery behavior;
- boot, MCU reset, DAC communication loss, watchdog loss, and power-domain
  cycling all produce zero brake current;
- open coil, shorted connector, and intermittent harness behavior;
- brake case temperature and calculated slip power under expected operation.

Torque and noise:

- torque noise floor with brake unpowered, powered at zero, and at several DC
  currents;
- simultaneous motor motion plus brake current at worst expected operating
  points;
- spectra of raw bridge/PGA data, not only filtered torque output;
- conducted coupling on bridge excitation, bridge return, analog supply, and
  reference ground;
- increasing-current and decreasing-current torque calibration curves;
- unit-to-unit brake matching and temperature drift;
- if PWM is tested, carrier harmonics, aliasing, acoustic behavior, mechanical
  torque ripple, and synchronous-averaging effectiveness;
- verify the analog front end never saturates before applying digital filters.

Preserve current, torque, temperature, supply, command, and timing data from the
same run. That evidence is what decides whether the linear stage is sufficiently
quiet and stable or whether the LM3404HV fallback is necessary.
