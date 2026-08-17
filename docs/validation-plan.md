# Validation Plan

**Rev 0 scope:** gates that exercise the analog angle output, the pyControl TTL
event lines, or an independent encoder cross-check do not apply. The cross-check
is not deferred — it was deleted on 2026-08-16 and those gates should be struck,
not postponed. Run them when rev 1 adds the circuits. Everything covering
power, the driver, the encoder-to-driver path, homing, and the serial link
applies as written. Note that `ENCODER_MISMATCH` is retired — there is no
second count to disagree with and there never will be.

**InstrumentPort-40 gates apply to Rev 0 as of 2026-08-16**, but only for the ten
live Strands and the three fitted buffer packages. Do not fail a gate on the eight
unrouted Strands or on `U_C`/`U_D` being DNP; do check that they are DNP rather
than populated with floating inputs.

**Status:** Planning
**Date:** 2026-08-12
**Derived from:** `../mouse-joysticks-pcb/docs/validation-plan.md`

This plan adapts the Gates A-F sequence from
`orb-weaver-context/context/pcb-development-plan.md` to this board.

Animal-facing use is a separate gate requiring scientific, institutional,
welfare, operational, and failure-response review. Passing every gate below does
not grant that authority.

## Pre-Fabrication Checks

### Power — the 36 V items

- **The 5 V/3.3 V regulator chain is fed from the protected but unswitched node**,
  not from the high-side switch output. Otherwise the MCU cannot enable its own
  supply and the board never boots. This is the highest-consequence check on the
  list.
- **A TVS is fitted on `HV_IN`** (`SMBJ40A`, or stocked `SMF48A`). It protects
  the switch and the buck at hot-plug; it cannot protect the TMC5130A.
- **Bulk capacitance is downstream of the high-side switch**, so plugging the
  terminal block in does not ring against it, and is **capped at tens of µF** —
  the switch dissipates ½CV² = 0.65 mJ per µF charging it, and the datasheet
  requires the design not reach thermal shutdown while doing so.

### Power — the 36 V input block edits

The block has never been placed. Every item is a resistor value or a single wire;
see the audit in `docs/power.md`.

- `R27001` changed from 10 k to **1 kΩ**, so `EN` sees 3.0 V rather than 1.65 V
  against a 1.5 V `VIH`.
- `DIAG_EN` tied to `+3.3V`. **Without this the `SNS` output is dead** and
  `HV_SNS` reads nothing.
- `~FAULT` routed to `GP29` with a pull-up to `+3.3V`.
- `LATCH` tied to `+3.3V` through a 1 kΩ `RPROT` for **latch-off**. Left floating
  the device auto-retries every 2 ms, which cycles the motor rail at ~500 Hz into a
  persistent fault. Clearing is by toggling `EN`, which firmware owns on `GP19`.
- `R27003` (`ILIM`) changed from 10 kΩ to **40 kΩ** (`OW-PASS-SCR0603F40K`,
  stocked), so the limit is ~1.2 A rather than the present **5.3 A typ (4-6.3 A)**.
  Confirmed against the identified motor, and able to pass the `+36V` inrush. Must
  never float — floating is a fault state. If more headroom is needed, 2 × 49.9 kΩ
  in parallel gives the tabulated 25 kΩ / 1.96 A row.
- `R27004` (`R_SNS`) changed from 1 kΩ to **249 Ω**
  (`OW-PASS-CRCW0402249RFKED`, stocked), so the fault indication lands at
  1.29-1.59 V instead of 3.3-4.4 V, well under the RP2040 ADC's `VDD + 0.3 V`
  limit. No divider required.
- `DIAG_EN` and `LATCH` each driven through a 1 kΩ `RPROT` series resistor, per
  the datasheet's Table 4-2.
- **`R27005` pulls `~FAULT` UP to `+3V3_MCU`, not down to `GND`.** As originally
  wired it was a pulldown on an open-drain output, which idles low and reads as a
  permanent fault.
- **`HV_IN` and `SNS` are hierarchical labels**, not local ones. Without `HV_IN`
  the board cannot feed the buck from the unswitched node or place the TVS; without
  `SNS` the current sense cannot reach `GP28`. `ILIM` stays local.
- `C27002` is a **100 V** part, matching `C27001`. 50 V gives only 1.4× margin on a
  36 V rail and does not cover the −60 V `VOUT` excursion during inductive turn-off.
- The block's 3.3 V hierarchical label matches the board's `+3.3V` net name.
- The terminal block's polarity is silkscreened: pin 1 `GND`, pin 2 positive.
- The switch's thermal pad has a via array — it is both the heat path and the
  ground connection.

### Power — driver side

- The TMC5130A `VCC` is supplied from the external `+5V` rail, not left to the
  internal regulator. At `VM = 36 V` the internal regulator's 1 W limit is reached
  at 32 mA.
- `5VOUT` is a decoupled local net, not bridged to the external `+5V` rail.
- Bulk capacitance sits at the driver's `VS` pins, and the `VS`/`GND` loop is
  small. 36 V leaves 10 V to the 46 V operating limit and the datasheet warns
  explicitly about ringing from stray inductance.
- An RC snubber footprint exists across `VS`/`GND` at the driver, populated or
  not, so a bad Gate B transient measurement is a populate decision rather than a
  respin.
- Exactly one `PWR_FLAG` per net, on input and entry nets only. The 36 V block
  and the `usb2` block each carry one; do not add a second to either.

### Power — multi-source logic rail

- **The ORing diodes are at the `TPS73733` input, not on `+5V`.** ORing onto
  `+5V` drops it below the TMC5130A's 4.6 V `VCC` minimum and truncates the DAC's
  full-scale output.
- `+5V` is single-sourced from the `TPSM365R6V5`.
- Diode orientation blocks current back into the USB host and into pyControl.
- The `SW_RAIL_SENSE` ÷2 divider off `+3V3_SW` is fitted on `GP26`, and firmware
  refuses to deassert `~{BUS_SW_OE}` until it reads valid. Firmware refuses to drive the 5 V
  domain when `+5V` is absent.
- Series resistors are present on every 3.3 V line driving a 5 V-domain input,
  as a hardware backstop independent of firmware.
- **`hv_to_5v_tpsm365r6` is fed from the switched `+36V`**, so `VSA` (which the
  `tmc5130` block ties to `+5V`) can never exceed the `V_VS` + 0.5 V absolute
  maximum, and `VCC` can never arrive after `VCC_IO`. Both orderings hold by
  construction with no sequencing logic.
- **`+3V3_MCU` is a separate always-on rail fed only from USB `VBUS` or
  pyControl pin 6**, through two ORing diodes, with no tap on `HV_IN`. The
  board's inability to boot from 36 V alone is accepted and silkscreened.
- **The TMC5130A's `VCC_IO` is on `+3V3_SW`, not on `+3V3_MCU`.** An always-on
  `VCC_IO` with a switched `VCC` is the sequencing order the datasheet forbids.
- **Two `5v_to_3v3_tps73733` instances exist, one per domain**, and the two 5 V
  rails are separate nets that never meet.
- **Every MCU line reaching the switched domain passes through a
  `SN74CB3Q3245` channel**, and the pyControl UART, `HV_EN`, `SW_RAIL_SENSE`,
  `HV_SNS`, `~{HV_FAULT}` and the `FW_TRIG` markers do not. Series resistors
  back up the bus switch on those crossings.
- **The bus switch is powered from `+3V3_MCU`**, so firmware can isolate before
  dropping `HV_EN`.
- **`+3V3_MCU` is never switched.** The MCU runs on it and drives `ENABLE`;
  switching it off cannot be undone by firmware.
- `R4002` in the `tmc5130` block, between `VCC` and `5VOUT`, is 10 Ω where the
  datasheet recommends 2.2 or 3.3 Ω. Confirm or change.
- **Both ORing diodes are populated.** The pyControl 5 V branch is no longer
  optional — it is one of only two sources that power the board.
- `VBUS` is not tied to `+5V` anywhere.
- **USB ESD protection is fitted.** The `usb2` block contains none — only the
  receptacle and two 5.1 kΩ `CC` pulldowns. Use the stocked `USBLC6-2P6`, placed on
  the **connector side** of the 27 Ω series resistors that live in the `rp2040`
  block. It clamps `VBUS` too, which matters now that `VBUS` is a power source.
- The USB-C receptacle's `SHIELD` pins are terminated deliberately, not left
  unconnected as the block leaves them.

### Controller and allocation

- The RP2040 GPIO allocation is checked against RP2040 peripheral pin muxing —
  `UART0`, `SPI0`, and `SPI1`. PIO0 is unallocated.
- Chip selects are plain GPIO, not hardware `CSn`. RP2040 hardware chip select
  does not hold across the TMC5130A's multi-byte datagrams.
- Debug console is USB CDC. `UART0` is committed to pyControl.
- The allocation in `docs/interface-map.md` matches the final schematic.
- The `EXT_FAULT_IN` decision is made: reserved and routed, or explicitly
  declined.

### Driver

- Current sense is **0.15 Ω** (`OW-PASS-RLH12FTCR150`, 1206, 1 W) on both
  positions. **The `tmc5130` block ships 0.12 Ω as its default — confirm the
  placed value, not the block default.**
- The schematic and any firmware configuration table record **`vsense = 1`** and
  **`IRUN = 28`**. With 0.15 Ω installed, `vsense = 0` — the chip's reset default
  — drives roughly 1.8× the motor's rated current.
- Firmware reads CHOPCONF back and refuses to raise `DRV_ENN` unless `vsense = 1`
  is confirmed, raising an `INTERNAL` fault instead.
- The motor supply envelope is sized from the identified motor.
- `SWSEL` is strapped for SPI and brought to a pad.
- `DRV_ENN` is pulled to the disabled state.

### Sensors and outputs

- The encoder is identified, and the input path is single-ended or differential
  accordingly. **Settled 2026-08-17: single-ended 5 V push-pull, received through
  `quadrature_encoder_input_5v_sn74lvc2g17`.**
- **Peak encoder channel frequency is measured on `ENC_A_FILT` during the fastest
  motor-commanded move** (homing or recentering — not the animal's pull, which is
  the slow case), and `C802`/`C803` are confirmed. Fitted at 470 pF, which covers
  `f_ch = CPR × RPM / 60` up to 44.9 kHz. If chopper hash rides on the line, step
  to 1 nF (21.2 kHz ceiling); only a genuinely fast axis needs to go back toward
  27 pF. Both channels must keep the same value so A/B delay stays matched.
- `ENC_N` is wired to the TMC5130A `ENCN` and a test pad, and **to no GPIO**.
  **Currently tied to GND through `R1201` (10 kΩ)**, which satisfies the TMC5130A
  requirement to pull `ENCN` to GND or `VCC_IO` when unused. `J1102` pin 2 is
  reserved for the index channel if the chosen encoder has one.
- The limit switch is identified and the debounce path is reviewed.
- A test point exists on the `REFL` net, and `GP9` drives it through a series
  resistor weak enough that the real switch always wins.
- DAC8563 `VIH` at `VDD = 5 V` is checked; a dual-supply level translator is
  added or explicitly ruled out. An `SN74LVC125A` is **not** a valid translator
  here.
- `~LDAC` is wired for synchronous update.
- The analog output's fault and reset behavior is decided and documented.
- Whether `AUX_ANALOG_OUT` is populated is decided.

### pyControl and instrument

- The RJ-45 is wired per `docs/pycontrol-port-pinout.md`: pin 1 `DIO-A` to
  `UART0 RX`, pin 4 `DIO-B` to `UART0 TX`, pin 2 `GND`. Pins 3, 5, 7 not
  connected. No Ethernet magnetics.
- The assigned pyControl port is confirmed UART-capable on the deployed breakout.
- Three event lines have a confirmed physical home, and the breakout has enough
  BNCs for **all boards in the rig**, not just this one.
- The InstrumentPort-40 overlay is reviewed against `board-interfaces` and not
  redefined here.
- **`J4`'s cable orientation is documented before fabrication** — connector
  reference, physical pin-1 marker location, contact side, expected cable type and
  orientation, and whether the mating board sees the logical pin order mirrored.
  The profile requires this of every board that uses it, and it is an open
  decision in the profile itself.
- All 18 `DIG*`/`TRIG*` signals are buffered; `~OE` defaults to high-Z in
  hardware and firmware enables it at startup.
- **The pyControl serial Strands come from the block's `PYC_DIO_A`/`PYC_DIO_B`
  pins**, so the block's 100 Ω sits between the buffer input and the cable. The
  block is unmodified at five boundary pins.
- **No `SN74LVC125A` input floats.** `U_C`/`U_D` are DNP with unrouted inputs;
  `U_E`'s unused `DIG11`/`DIG12` inputs are tied to GND; and `TMC_SPI_CIPO`,
  `ENC_A`, and `ENC_B` each carry a 100 kΩ pull-down at the buffer input.
- **`ENC_A`/`ENC_B` are tapped on the driver side of the encoder input filter**,
  so the capture shows what the TMC5130A's pins receive rather than what the cable
  delivers.
- `AOUT0`/`AOUT1` are no-connect, and no divided motor rail reaches any `AIN*`.
- Labelled test points exist for the 10 signals not carried by InstrumentPort-40,
  including `ENC_N` and `LIMIT_SW`, **plus `ENC_A`/`ENC_B`**, which lose their
  port slots at rev 2 and fall back to the pads.

### Mechanical and process

- Board outline and mounting are decided. `../mouse-joysticks-mech` describes the
  two-joystick assembly; how a per-axis board mounts in it is a decision, not a
  derivation.
- A unit-identifier field is on the silkscreen if the rig will hold two boards.
- Layout zoning separates the motor section and the switching supply from the
  encoder path and the analog output.
- ERC and DRC pass.

## Gate A: Contract Review

- Authoritative pyControl connector and electrical sources are cited.
- The exact controller, breakout, hardware revision, port designations, and
  specification revision are identified.
- BNC count and configurability are established for the whole rig's line count.
- Whether one `RSYNC` output can drive two boards is answered.
- Pin numbering, orientation, cable behavior, power, ground, and signal levels
  have explicit status.
- Unknowns have owners and do not hide a fabrication risk.
- Controller scope, safe states, timebase ownership, and the cross-board fault
  policy are documented.

## Gate B: Electrical Boundary

- **Board boots with the motor rail off**, and `HV_EN` raises it. Confirm before
  a motor is attached.
- **Each power source works alone**, and the board behaves sanely in each state:
  USB only; **pyControl only, which is now a required mode, not an optional
  one**; 36 V only, which must be confirmed *not* to boot; and every combination,
  including plugging and unplugging each source while the others are live.
  Measure `+3V3_MCU` in each case.
- **Measure pyControl pin 6's available current** under the board's real load.
  This is the item that decides whether pyControl-only operation works, and it is
  unmeasured today.
- With the switched domain down, confirm no current flows into `+5V_SW` or
  `+3V3_SW` through any device's input clamps, and that `SW_RAIL_SENSE` reads
  zero.
- **Exercise the reset sequence with a scope**: isolate, drop `HV_EN`, confirm
  `+3V3_SW` collapses with no MCU pin driving into it; then raise `HV_EN`,
  confirm `SW_RAIL_SENSE`, and connect. Getting this order wrong is the failure the
  architecture exists to prevent, so prove it rather than assuming it.
- No current flows back into the USB host or into pyControl from any other
  source.
- The analog output reaches a true 5.00 V full scale with the 36 V supply
  present. If it tops out below 5 V, something is ORed onto `+5V` that should
  not be.
- Rail voltages, sequencing, and ripple are measured with the motor loaded.
- Motor-rail transient overshoot is measured at the TMC5130A `VS` pins during
  motion start, stop, and a deliberate stall. **Compare against the 46 V
  operating and 49 V absolute limits.** This is the measurement that justifies or
  condemns the 36 V choice.
- Overshoot on `HV_IN` is measured while **hot-plugging the terminal block**,
  against the switch's 70 V and the buck's 65 V. This is the event the TVS is
  there for.
- `HV_EN` turn-on into the final `+36V` capacitance completes without tripping the
  switch's thermal shutdown, from both a cold and a warm start.
- `HV_SNS` tracks measured load current, and the fault level stays under 3.3 V at
  the ADC pin when a fault is provoked.
- `~{HV_FAULT}` asserts on a deliberate overload and the board reports
  `SUPPLY_OUT_OF_RANGE`.
- TMC5130A case temperature is measured; the internal regulator is confirmed
  offloaded.
- **Continuity confirmed against real hardware for all eight RJ-45 pins.** The
  pinout is cited from a schematic, not measured. This is the check that converts
  it to verified.
- Cable type confirmed (straight-through versus crossover) and the consequence of
  the wrong one is known.
- Power and ground behavior are safe in every connection order: board first,
  pyControl first, cable inserted live, cable removed live.
- UART levels, direction, idle state, and protection are measured at 115200 8N1.
- A loopback or echo exchange with the real pyControl board succeeds before any
  motor is connected.
- Event and sync line levels and edge quality are measured.
- Reset, disconnect, and power-cycle behavior reach a safe state.
- No motor current is present on any pyControl port conductor.
- The analog output reaches 0 V and 5 V at its commanded endpoints, measured.

## Gate C: Protocol Conformance

- A host simulator or protocol fixture and the firmware agree on framing and
  versions.
- Malformed, duplicated, delayed, dropped, and out-of-order input is handled.
- Repeated sequence numbers are re-acknowledged without re-execution.
- An unrecognized verb is rejected, never partially executed.
- Timeouts and faults are observable and recover only through declared paths.
- Capability discovery reports the axis count and the **board serial**, and
  rejects incompatible versions.
- Motion verbs are refused outside `ARMED`.
- Every fault code can be provoked and observed, including the `vsense` self-test
  path in bit 7.
- Two device-class instances on two ports do not collide on event names.

## Gate D: Bench Operation

- Homing is deterministic and bounded, verified over repeated runs.
- **Actual coil current is measured, not inferred from IRUN.** Expect 0.679 A RMS
  at `vsense = 1`, IRUN 28. A reading near 1.23 A means `vsense` is 0 and the
  motor is being driven at ~1.8× its rating — stop immediately.
- CHOPCONF read-back confirms `vsense = 1` before any sustained run.
- Sense-resistor temperature rise is measured during a standstill hold at full
  current, which is this rig's normal operating condition rather than an edge
  case.
- Travel, velocity, acceleration, and current limits are verified by attempting
  to exceed them.
- Encoder angle is verified against an independent angular measurement.
- ~~TMC5130A count and PIO count agree; a deliberate disagreement raises
  `ENCODER_MISMATCH`.~~ **Struck 2026-08-16** — there is no PIO count. Replaced
  by: quadrature edges captured on InstrumentPort `DIG0`/`DIG1` agree with
  `X_ENC` read over SPI in the same capture.
- ~~The synthetic `REFL` stimulus on `GP9` exercises homing without the real
  switch.~~ **Struck** — `TMC_REF_STIM` was deleted on 2026-08-13 and `GP9` is
  now `~{BUS_SW_OE}`. Replaced by: closing the real switch produces an edge on
  InstrumentPort `DIG11`, and the driver reacts in the next SPI poll.
- Heartbeat timeout stops motion within a measured time and drops `HV_EN`.
- Cable removal during motion stops the motor and latches a fault.
- The analog output is verified against the encoder count **in the same
  InstrumentPort capture**, including latency. Do not accept a firmware log as
  evidence here — the DAC bus is on the connector precisely so this can be
  measured.
- If `EXT_FAULT_IN` is fitted, asserting it stops motion and reports `EXT_STOP`.

## Gate E: Native pyControl Operation

- An unforked upstream pyControl installation loads the device class through its
  normal supported mechanism.
- A native task commands the axis and receives status, completion, and fault
  events.
- Pull events arrive on the correct line and are attributed correctly in the
  pyControl log.
- Event line timestamps in the pyControl log agree with the board's local
  timestamps after Rsync alignment, within a stated uncertainty.
- **If two boards are deployed:** both are loaded, both report distinct serials,
  both receive `RSYNC`, and cross-joystick event ordering is reconstructed with a
  stated uncertainty. Record that uncertainty — it is the number that decides
  whether the two-board form factor is scientifically adequate.
- The pyControl I/O actually consumed matches what was budgeted.
- Scientists can use the normal pyControl workflow and native output files.
- Loom, Spiders, and Orb Weaver engineering services are absent from the live
  path.

## Gate F: Reproduction And Reflection

- The engineering build and bench validation resolve from an Orb Lock.
- A Reflection identifies inputs, versions, configurations, clocks, evidence,
  results, and remaining unknowns.
- Calibration values are recorded **against the board serial**, not against the
  joystick position.
- Native files remain usable in their normal tools.
- Another engineer can reconstruct the tested system without undocumented
  personal knowledge.

## Instrument-Specific Validation

- Buffers default to high-Z at power-on, before firmware runs.
- Firmware enables buffers at startup and reports buffer state in `ID`/`STATUS`.
- With buffers enabled, no observable effect on rig behavior: repeat a Gate D
  motion and timing check with the analyzer attached and detached, and compare.
- The instrument cannot drive any board net. Confirm `AOUT*` are unpopulated and
  the buffers are unidirectional.
- A session-length capture is demonstrated end to end.
- The physical cable arrangement survives a realistic rig session.

## Evidence Notes

Record measured values, not pass/fail marks, in `docs/bringup-log.md`. A number
with units can be re-examined later; a checkmark cannot.

For timing claims that software logs cannot support on their own, use the
InstrumentPort-40 capture path. That is what it is on the board for.
