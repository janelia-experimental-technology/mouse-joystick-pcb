# Validation Plan

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
- A **36 V-rated TVS is placed** on the motor rail. The
  `hv_input_36V_terminal_2pos_5p08_protected` block populates none. `SMBJ40A`/
  `SMBJ43A` class; the stocked TVS parts are unsuitable.
- The TMC5130A `VCC` is supplied from the external `+5V` rail, not left to the
  internal regulator. At `VM = 36 V` the internal regulator's 1 W limit is reached
  at 32 mA.
- `5VOUT` is a decoupled local net, not bridged to the external `+5V` rail.
- Bulk capacitance sits at the driver's `VS` pins, and the `VS`/`GND` loop is
  small. 36 V leaves 10 V to the 46 V operating limit and the datasheet warns
  explicitly about ringing from stray inductance.
- The `ILIM` resistor is sized from the identified motor's inrush and stall
  behavior.
- `SNS` scaling puts full-scale load current below 3.3 V at `GP28`.
- Exactly one `PWR_FLAG` per net, on input and entry nets only. The 36 V block
  carries one; do not add a second.

### Controller and allocation

- The RP2040 GPIO allocation is checked against RP2040 peripheral pin muxing —
  `UART0`, `SPI0`, `SPI1`, and the PIO encoder group.
- `GP14`/`GP15`/`GP16` are contiguous for a single PIO input mapping.
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
  accordingly.
- `ENC_N` is wired to `GP16` and to the TMC5130A `ENCN`.
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
- All 18 `DIG*`/`TRIG*` signals are buffered; `~OE` defaults to high-Z in
  hardware and firmware enables it at startup.
- `AOUT0`/`AOUT1` are no-connect, and no divided motor rail reaches any `AIN*`.
- Labelled test points exist for the 8 signals not carried by InstrumentPort-40,
  plus `HV_SNS` and `SWSEL`.

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
- Rail voltages, sequencing, and ripple are measured with the motor loaded.
- Motor-rail transient overshoot is measured at the TMC5130A `VS` pins during
  motion start, stop, and a deliberate stall. **Compare against the 46 V
  operating and 49 V absolute limits.** This is the measurement that justifies or
  condemns the 36 V choice.
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
- TMC5130A count and PIO count agree; a deliberate disagreement raises
  `ENCODER_MISMATCH`.
- The synthetic `REFL` stimulus on `GP9` exercises homing without the real
  switch, and the real switch still overrides it.
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
