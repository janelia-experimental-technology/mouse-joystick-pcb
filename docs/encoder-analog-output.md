# Encoder Analog Output

**Status:** Draft design; one blocking component question
**Date:** 2026-08-12
**Derived from:** `../mouse-joysticks-pcb/docs/encoder-analog-output.md`
**Requirement:** The researcher asked for joystick encoder angle as a 0-5 V
analog voltage on a BNC connector. One joystick, one output.

## Why It Is In Rev 0

This is an explicit researcher request and it is what lets the rest of the rig's
acquisition chain be tested. An analog angle signal goes straight into whatever
ephys or DAQ system already records the rig, without waiting on the pyControl
device class, the UART protocol, or a firmware release. It is the cheapest thing
on this board that produces immediate scientific value.

## Part

**`DAC8563SDSCR`** — catalog part `OW-SENS-DAC8563SDSCR`, JLCPCB `C1554746`, 95
in the inventory export at the time of writing.

| Property | Value |
| --- | --- |
| Resolution | 16-bit |
| Channels | 2 |
| Supply | 2.7 V to 5.5 V |
| Reference | Internal 2.5 V, gain of 2 |
| Full-scale output | 0 to 5 V with the internal reference |
| Output | Buffered voltage, rail-to-rail |
| Interface | SPI, write-only |
| Package | WSON-10-EP, 3×3 mm |
| Symbol / footprint | `orb_weaver_sensors:DAC8563SDSCR` / `Package_SON:Texas_DSC0010J` |

The internal 2.5 V reference with gain of 2 gives 0-5 V full scale natively, with
no external reference and no gain stage. 16 bits over a joystick's angular range
is far more resolution than the encoder provides, so quantization is a non-issue.

### Why A Dual Part For One Output

This board needs one channel. Using the dual part anyway is deliberate:

- It is stocked in quantity and already specified for the twin-axis board, so the
  sourcing decision and the footprint are shared rather than duplicated.
- A single-channel sibling is not confirmed stocked, and a sourcing check costs
  more time than the unused channel costs board area.
- The stocked BNC jack, `DOSIN-801-0095`, is a **dual** right-angle part. One
  connector body carries both channels, so the second output costs a footprint
  and two passives, not a connector.

Channel A → `ANGLE_OUT`. Channel B → `AUX_ANALOG_OUT`, brought to the second BNC
position and left unpopulated unless wanted. It is the cheapest possible
provision for a later torque output, a validity signal, or a second derived
quantity.

## `~LDAC` And `~CLR` Are Driven Here

The twin-axis board ties `~LDAC` low and `~CLR` high to save two GPIOs. This
board has pins to spare, so both are driven:

| Pin | GPIO | Benefit |
| --- | --- | --- |
| `~LDAC` | `GP12` | Synchronous update of both channels. Zero inter-channel skew if the second channel is ever used. |
| `~CLR` | `GP17` | Software clear to a defined level, including on fault. |

If the level-translation question below forces a 4-bit translator, tie `~CLR`
high in hardware and reclaim `GP17`. Do not drop `~LDAC` — that is the one that
buys something.

## Blocking Question: Logic Levels

To reach 5 V full scale the DAC needs `VDD = 5 V`. Its digital input thresholds
are likely specified relative to `VDD`, which would put `VIH` around 3.5 V —
above what 3.3 V logic guarantees.

**Verify `VIH`/`VIL` in the DAC8563 datasheet at `VDD = 5 V` before schematic
freeze.** Three outcomes:

1. `VIH` is specified low enough (some parts spec a fixed 2.4 V) that 3.3 V drive
   is in spec. Connect directly.
2. `VIH` is `VDD`-relative and 3.3 V is out of spec. Add a dual-supply level
   translator on `SCLK`, `DIN`, `~SYNC`, and `~LDAC`, and tie `~CLR` high.
3. Run `VDD = 3.3 V` and accept a reduced output range. **Not acceptable** — it
   breaks the 0-5 V requirement.

Do not assume outcome 1. This is the most likely cause of a respin on this
subsystem and it costs one part to avoid.

**If a translator is needed, it must be a dual-supply part**, `VCCA = 3.3 V` and
`VCCB = 5 V` — a `74LVC4T3245` or `SN74AXC4T774` class device. Do **not** reach
for the `SN74LVC125A` already on this board for instrumentation buffering: its
`VIH` at `VCC = 5 V` is `0.7 × VCC = 3.5 V`, so a 3.3 V input is out of spec at
its input too and it solves nothing. `LSF0102DCUR` is prior art from the
previous-generation board and is also acceptable.

Check `kicad-libs` stock before choosing; if nothing suitable is stocked, this
becomes a purchase item alongside the 36 V TVS.

## Signal Chain

```text
encoder ──> TMC5130A X_ENC counter ──> RP2040 reads over SPI0
                                              │
                                              v
                                  angle-to-code mapping
                                              │
                                              v
                          DAC8563 ch A ──> series R ──> ESD ──> BNC "ANGLE"
                          DAC8563 ch B ──> series R ──> ESD ──> BNC "AUX" (DNP)
                                       (loaded on ~LDAC assertion)
```

- The MCU reads the encoder position, maps it to a DAC code using the configured
  `ANGSCALE` range, writes the channel, then asserts `~LDAC`.
- The DAC sits on `SPI1`, separate from the TMC bus on `SPI0`, so an angle update
  cannot queue behind a motor register access.
- Update rate is an open decision. It should be fast enough that the analog
  signal is a faithful record of joystick motion rather than a stepped
  approximation. Choose it against the mouse's actual pull dynamics, and document
  the achieved rate and latency as a **measured** claim, not a target.
- The DAC SPI bus and `~{DAC_CS}` are on InstrumentPort-40 (`DIG10`, `DIG11`,
  `DIG6`), so a capture can recover the commanded code and compare it against the
  analog output and the encoder in the same file. Use that at Gate D rather than
  trusting a firmware log.

## Output Protection

A user-accessible BNC on a bench, so treat the output as abusable:

- Series resistance between the DAC output and the BNC centre, sized so a short
  to ground or to another instrument's output does not exceed the DAC's output
  current rating.
- Consider a unity-gain buffer if load impedance is unknown or if cable
  capacitance destabilises the DAC's internal buffer. A 5 V rail-to-rail op amp
  with the DAC in the feedback path is the conservative choice; decide after
  checking the DAC's capacitive load tolerance.
- ESD protection at the connector.
- Clean analog return to the BNC shell, kept away from the motor return path.

## Calibration And Semantics

Document and store on the board:

- the angle range mapped to 0-5 V, and which end is 0 V;
- the encoder zero and its relationship to the homed position;
- the update rate and worst-case latency from joystick motion to output voltage;
- what the output does when unhomed, disarmed, or faulted;
- **the board serial the calibration belongs to.** With two interchangeable
  single-axis boards in a rig, a board swapped between joysticks carries its
  calibration with it. That is the failure mode this form factor introduces.

The fault behavior needs an explicit decision. A faulted board that keeps
outputting its last angle looks identical on a scope to a working board holding
still. **Recommendation:** drive a defined out-of-band level on fault — for
example 0 V when the valid angle range starts above 0 V — or use channel B as a
validity line. Do not leave it ambiguous, because this signal ends up in a
researcher's recorded dataset with no other indication of board state.

Channel B as a validity output is worth considering seriously: it costs nothing
beyond populating a BNC already on the board, and it removes the need to encode
validity into the angle signal itself.

## Open Decisions

- DAC8563 `VIH` at `VDD = 5 V`, and whether level translation is required.
- Whether `AUX_ANALOG_OUT` is populated, and what it carries — validity, a second
  derived quantity, or nothing.
- Whether to buffer the output.
- DAC update rate and the resulting latency budget.
- Output behavior when unhomed, disarmed, or faulted.
