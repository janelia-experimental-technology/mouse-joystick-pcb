# OneBox Analog And Timing Interface

**Moved** here from `kicad-libs/docs/` on 2026-10-07. Paths into that repository are written `../kicad-libs/…`; the datasheets it cited from its `tmp/` cache are in the private store `../kicad-libs-nonfree/datasheets/`.

**Status:** interface decision for the next `mouse-joystick-pcb` iteration. The
angle path is now built as a design block; the torque path is still a paper
design. Neither is bench-validated.

**Evidence:** `../kicad-libs-nonfree/datasheets/onebox-user-manual.pdf` (technical user manual V1.0.1) and
`../kicad-libs-nonfree/datasheets/onebox-datasheet.pdf`, reviewed 2026-08-20.

**Amended 2026-08-26.** The encoder-angle implementation changed when the block
was actually built: `DAC80501` with an analog gain stage, not `DAC8563` with a
firmware code limit. See [Encoder angle](#encoder-angle). The 0-3.3 V contract
itself is unchanged — it is the reason the block exists.

## Interface Decision

Treat **0-3.3 V** as the external torque and angle signal contract, but keep the
board's analog circuitry capable of 0-5 V operation. Do not power precision
output amplifiers from 3.3 V merely to enforce the connector range. Retaining a
quiet 5 V analog rail gives output headroom and preserves the option to restore
0-5 V later; output range is established by the DAC code mapping and a
connector-facing torque scaling network.

This does not change the separation between actuator and measurement paths:

- the brake keeps its own `DAC60501Z`, analog domain, safe-state gate, and
  current loop;
- torque remains a direct conditioned analog output plus an independent
  `ADS8699` digital acquisition path;
- encoder angle has its own DAC, not the brake DAC. As built that is a
  `DAC80501ZDGSR` in `analog_output_0_3v3_dac80501`, not the `DAC8563` this
  document originally named;
- OneBox timing I/O is a separate 5 V TTL interface. The 0-3.3 V analog choice
  does not change its logic level.

## OneBox Facts That Affect The Board

- The user-accessible ADC is an Analog Devices `AD7616-P`: 16 bits, 12 external
  channels, and a fixed 30.3 kHz sample rate per channel.
- Selectable input ranges are +/-2.5 V, +/-5 V, and +/-10 V. Use **+/-5 V** for
  0-3.3 V signals. The +/-2.5 V range clips them and the +/-10 V range doubles
  the ideal quantization step.
- Neural and ADC acquisition start from the same selected trigger. Both packet
  types receive the OneBox timestamp and SYNC status. The 30.3 kHz ADC clock is
  synchronous with the 100 kHz timestamp clock, but asynchronous with the
  neural-probe sample clocks.
- A OneBox ADC sample interval is about **33.0 us** and its timestamp clock has
  **10 us** ticks. USB packet arrival time is not the experiment timestamp.
- The rear `SMA1` synchronization interface is configurable as input or output
  and explicitly requires **5 V TTL**. When OneBox drives it, the receiving load
  must be high impedance.
- On the SDR connector, ADC inputs 0-11 share conductors with the corresponding
  OneBox DAC outputs. The matching DAC output must be disconnected in the
  OneBox GUI/API before the mouse-board signal is connected.
- **ADC input impedance is 1 Mohm.** Resolved 2026-08-27 from the `AD7616-P`
  datasheet; the OneBox manual does not state it, but the part does. Do not fit a
  50-ohm shunt at the receiver. **Loading figure updated 2026-09-11 for the /2
  dividers:** the angle BNC's source is no longer 249 ohm but 249 ohm plus the
  divider's 1.6 kohm = **1.849 kohm**, so the loading term is **-0.185% of gain,
  or -3.05 mV at the 1.650 V full scale** — not the -0.025% / -0.82 mV this
  bullet quoted against the old 3.300 V span. Still systematic, still absorbed by
  per-board calibration, still no bench measurement needed. See *The 3.3 V Output
  Bound Is A Requirement, And It Is A Divider* below.
- **The AD7616-P's on-chip antialias filter is first order at about 39 kHz**, so
  it provides roughly 1 dB of rejection at 20 kHz and effectively does not
  antialias against its own fixed 30.3 kHz sampling. **Any board feeding a OneBox
  ADC channel must band-limit its own signal.** This is the reason
  `analog_output_0_3v3_dac80501` carries a 2-pole 987 Hz Sallen-Key: a TMC5130A
  chopper at the datasheet-recommended 16-30 kHz folds into 0-15 kHz, where it is
  indistinguishable from real signal.

The preferred timing topology is for OneBox or a common experiment timing
source to be the master. Route the OneBox internal SYNC or 100 kHz timestamp
clock out through `SMA1`, receive its 5 V level with a 5.5-V-tolerant Schmitt
input such as the stocked `SN74LVC2G17DRYR` powered at 3.3 V, and hardware-capture
that edge on the mouse board. If the mouse board must instead drive `SMA1`, add
a separately enabled 5 V TTL transmitter such as `SN74AHCT1G125DBVR`. Do not
connect both drivers at once; use population options or an explicit direction
jumper.

Do not use an ADC comparator crossing as the precision synchronization source.
The manual states that comparator timing has up to one ADC period, approximately
33 us, of jitter.

## Resolution Consequences

On the OneBox +/-5 V range, the ideal ADC step is:

```text
10 V / 65536 = 152.6 uV/code
```

| External signal span | Ideal OneBox codes used | Ideal bits over that span |
| --- | ---: | ---: |
| 0-5 V | 32,768 | 15.00 |
| 0-3.3 V | 21,627 | 14.40 |
| Scaled rated torque span, 0.66-2.64 V | 12,976 | 13.66 |

Changing from 0-5 V to 0-3.3 V therefore costs **0.60 bit** and makes every
fixed input-referred noise voltage 1.515 times larger relative to signal span.
The ideal quantization-noise RMS is about 44 uV. This loss is real, but it is
not large enough to justify replacing the selected DAC or torque converter:

- the angle DAC out-resolves OneBox regardless. **Updated 2026-08-26:** the
  built block scales in hardware rather than code-limiting, so the `DAC80501`
  spends its full 16-bit range on 0-3.3 V at 50.4 uV/LSB — about 1.6 bits more
  than OneBox can distinguish over that span, where the original code-limited
  `DAC8563` plan gave about 15.4. The 0.60-bit loss above is an
  OneBox-side consequence of the narrower span and is unaffected either way;
  what disappeared is the DAC-side share of it;
- the onboard 18-bit `ADS8699` path remains independent of external-output
  scaling and can retain the higher-rate raw torque record;
- one OneBox code is about 0.0077% of the proposed 1.98 V rated-torque span, and
  ideal quantization-noise RMS is about 0.0022% of that span. Both remain below
  the RTS sensor's published 0.05% nonrepeatability and 0.1%
  nonlinearity/hysteresis figures.

The analog-noise target should nevertheless be verified over the selected
torque bandwidth with the brake operating. A useful first electronics-only
target is less than half a OneBox code, approximately 76 uV RMS, at each BNC;
then replace that screening target with an error budget based on measured
sensor, amplifier, grounding, and OneBox noise. Always report measurement
bandwidth and spectra with the RMS result.

## Output Scaling

### Encoder angle

**Rewritten 2026-08-26 against the built block.** This section previously
specified a `DAC8563` at gain of two with firmware limiting codes to
`0.66 * 65535`, plus a reserved `LSF0102DCUR` level translator. The block that
was actually built — `analog_output_0_3v3_dac80501` in `kicad-libs` — does none
of those things, and the reasons are worth keeping.

Use a **`DAC80501ZDGSR`** on the quiet 5 V analog rail with its internal 2.5 V
reference, `GAIN` register (4h) set to **`0x0101`** (`REF-DIV=1`,
`BUFF-GAIN=1`) for a 0-2.5 V DAC span, followed by an **`OPA197` at a
non-inverting gain of 1.32** into the connector. Full scale is
`2.5 V x (1 + Rf/Rg)` = 3.300 V with stocked 0.1% 25 ppm/C thin film
(10 kohm and 3.2 kohm).

Three consequences, each a reason not to revert to the earlier plan:

- **The 0-3.3 V contract becomes a hardware property.** The DAC cannot exceed
  its own reference, so the output cannot exceed 3.3 V once the `GAIN` register
  is written. A firmware fault cannot present an out-of-range voltage to the
  OneBox ADC input. Code-limiting a 0-5 V DAC left that as a software promise.
- **Full 16-bit resolution over the span**, 50.4 uV/LSB, instead of 66% of the
  code range. See [Resolution Consequences](#resolution-consequences).
- **No level translator.** The `DAC80501` specifies `VIH` at **1.62 V minimum,
  flat across `VDD` = 2.7-5.5 V**, so 3.3 V GPIO drives it directly at
  `VDD` = 5 V. This is a property of the part, not a relaxation of the rule —
  see the warning below. It also removes two GPIOs outright, because the part
  has no hardware `LDAC` and no hardware `CLR`; use `DAC_SYNC_EN` plus the
  `TRIGGER` register for synchronous update, and write `0x1010` to `TRIGGER`
  for a soft reset.

**Do not read this as permission to delete level shifting elsewhere.** Any
`0.7 x VDD` input on a 5 V rail — including the `DAC8563`, if it is ever used
for another channel — still needs a dual-supply translator driven from 3.3 V
logic. The stocked `LSF0102DCUR` reservation stands for those paths and for the
5 V TTL timing interface; it is simply not needed for the angle DAC.

**Do not use `REF-DIV=0` to reach the same 0-2.5 V span.** That configuration
puts the 2.5 V reference at exactly the `0.5 x VDD` recommended maximum, so a
sagging 5 V rail trips the reference alarm, the reference buffer shuts down, and
the output is forced to 0 V — which on an angle channel reads as a legitimate
end of travel rather than as a fault.

Retain a calibration constant and an output-range profile per board serial. The
same hardware produces a different full scale by changing two resistors, so the
option to restore 0-5 V survives; it is a stuffing change rather than a firmware
one, which is the honest trade for the hardware bound above.

### Torque

**Superseded 2026-09-04 by `../kicad-libs/docs/torque-sensor-interface-design.md`.** The
settled front end centres the internal signal at **5.000 V** and attenuates by
**1/3**, not 2.5 V and 0.66, because the ÷3 ratio makes the domain crossing
fault-containing. The INA821 is powered from the buffered 10.000 V excitation
node rather than the 12 V rail, which puts the **single-fault ceiling at
3.283 V** — below `VDDA`, so the torque output is safe on an unprotected 3.3 V
MCU pin. The connector-facing mapping is unchanged in
spirit and slightly different in numbers — zero torque at **1.6667 V**, ±rated
at **0.670-2.664 V**, ±150% overload at **0.171-3.162 V**. Excitation is
**10.000 V from a `REF5010A` plus buffer**, not an `LT3042`; the converter is a
16-bit `ADS8689`, not an 18-bit `ADS8699`; and the anti-alias filter is a
two-pole passive network with **263 µs** of group delay, deliberately matched to
the angle channel's 266 µs so the two BNCs arrive time-aligned. The paragraphs
below are kept because the reasoning about *why* torque attenuates where angle
amplifies is still correct.

Keep the internal torque chain at its existing 5 V-domain starting point:
`INA821` gain near 100, 2.5 V reference, nominal rated output about 1.0-4.0 V,
and 150% overload about 0.25-4.75 V. This keeps the onboard `ADS8699` path and
front-end headroom unchanged.

Add a low-noise, precision **0.66 ratio** before the connector buffer. It maps:

| Torque condition | Internal conditioned voltage | 0-3.3 V profile |
| --- | ---: | ---: |
| -100% to +100% rated torque | 1.0-4.0 V | 0.66-2.64 V |
| -150% to +150% safe overload | 0.25-4.75 V | 0.165-3.135 V |
| zero torque | 2.5 V | 1.65 V |

**Torque attenuates where angle amplifies, and that is deliberate — do not
"harmonise" them.** The angle path starts at a 0-2.5 V unipolar DAC span and
gains it up by 1.32; the torque path starts at a 2.5 V-centered bipolar signal
that already spans 1.0-4.0 V and must come down by 0.66. Each network is the
minimum-parts way to reach the same 0-3.3 V connector contract from a different
starting point.

Use a matched thin-film divider/network with no worse than 0.05% ratio tolerance
and 10-25 ppm/C ratio tracking, followed by the planned `OPA2197` cable buffer.
Provide a three-pad selection or stuffing option between the raw 0-5 V-capable
node and the 0.66-scaled node. Do not derive a new 1.65 V reference solely for
the BNC; scaling the existing 2.5 V-centered signal by 0.66 produces the desired
center without another reference/noise source.

The series resistor at each BNC is source isolation, not a promise to drive a
50-ohm terminated input. Label and validate the outputs for a high-impedance
receiver unless a true 50-ohm driver is deliberately added. **Sized 2026-08-26
on the angle path:** `analog_output_0_3v3_dac80501` uses **249 ohm**, not the
~50 ohm this section assumed. The value is set by the short-circuit case — 3.3 V
into a short is 13.3 mA and 43.7 mW, inside a 62.5 mW 0402, where 100 ohm would
have dissipated 109 mW — and it makes the **high-impedance receiver a hard
requirement rather than a label**.

**Revised 2026-09-11: that requirement is now 1 Mohm or better, not 100 kohm, and
the short-circuit numbers above halve.** Both changes come from the /2 dividers.
The series resistor is still 249 ohm and still sized by the short-circuit case,
but it now sees 1.650 V rather than 3.300 V, so a short of the BNC to ground is
**6.6 mA and 11 mW**. More importantly the resistor is no longer the whole source
impedance: the divider puts 3.2 kohm ∥ 3.2 kohm = 1.6 kohm ahead of it, for
**1.849 kohm** total. **The OneBox still meets the requirement** — the
`AD7616-P` is 1 Mohm, giving **-0.185%** — but at exactly 100 kohm the error
would be **-1.82%**, so the old threshold protects nothing. Apply the same sizing
logic to the torque BNC rather than copying either number, and size it against
the post-divider span.

## The 3.3 V Output Bound Is A Requirement, And It Is A Divider

**Decided 2026-09-08. Peter's requirement, stated directly: no analog output that
leaves this board may ever exceed 3.3 V, so that connecting one straight to a
pyControl MCU pin cannot damage it.** This section used to raise that as an open
question about the angle channel and list four options. It is now a rule, it
applies to **four** signals rather than one, and the method is chosen.

### Why the receiver's limits make this a hard bound rather than a preference

The 0-3.3 V contract elsewhere in this document was written against a OneBox ADC
input, which is 1 MΩ with a ±5 V range and treats an out-of-contract voltage as a
range error. The **pyControl** breakouts do not: their BNCs reach microcontroller
pins with no series resistance and no clamp, and the limits there are absolute
maximums.

| Receiver | Part | Absolute maximum on a non-5 V-tolerant pin |
| --- | --- | --- |
| Breakout 1.2 | `STM32F405` | `VSS − 0.3 V` to **4.0 V** (`../kicad-libs-nonfree/datasheets/stm32f405xx.pdf`, Table 11) |
| `pycontrol-h7-breakout` | `STM32H743VIT6` | TT-class pins are typically `VDDA + 0.3 V` ≈ **3.6 V** — **unverified** |

### Every board-exiting analog signal is bounded by its output buffer's rail, not by its signal path

**This is the finding that made the requirement bigger than the angle channel.**
Verified against the block netlists on 2026-09-08, not from the design documents:

| Signal | Destination | Output element | Fault ceiling **today** |
| --- | --- | --- | --- |
| `ANGLE_OUT` | `J1101` BNC | `U2002` `OPA197` on `+5V_FILT`, then `R2007` 249 Ω | **≈ 4.95 V** |
| `ANGLE_OUT_MON` | `J1501` pin 32 (InstrumentPort `AIN0_P`) | tapped at `AMP_VOUT` through `R2008` 1 kΩ | **≈ 4.95 V** |
| `TQ_AOUT` | BNC | `U37005` `OPA197` on `+5V_FILT`, then `R37021` 249 Ω | **≈ 4.95 V** |
| `TQ_AOUT_MON` | `J1501` | tapped through `R37022` | **≈ 4.95 V** |
| `BRAKE_ISENSE` | `J1501` pin 35 (`AIN1_P`) | `U36003` `OPA197` on `+5V_FILT`, then `R36018` 249 Ω | **≈ 4.95 V** |

**The torque channel was believed exempt and is not.** This document previously
said *"The torque channel does not have this problem: its single-fault ceiling is
3.283 V by construction."* That is true for every fault **upstream** of the
output buffer — the excitation loop, the `INA821`, the ÷3 attenuator — and it is
the reason the in-amp's `+VS` is on `VEXC` rather than `+12V_FILT`. It is **not**
true for a fault in the buffer itself. `U37005` is an `OPA197` on `+5V_FILT`, so
an output stage shorted to its rail puts about 4.95 V on the torque BNC no matter
what the bridge is doing. The same is true of the angle buffer. A supply-bounded
signal path does not bound the thing that drives the connector.

The `TPD1E05U06` on each output does not help: it is a 5.5 V working-voltage ESD
device with a breakdown near 8.5 V. It clamps ESD, not a DC fault.

### The rule: a ÷2 divider between each output buffer and its existing series resistor

**Every board-exiting analog signal gets a ÷2 resistive divider inside its block,
inserted between the output buffer and the series resistor that is already
there.** The series element (`R2007`, `R37021`, `R36018` — all 249 Ω) keeps every
property it was chosen for and is not touched.

| | |
| --- | --- |
| Worst-case rail (`+5V_SW` at +2%) | 5.10 V |
| Fault ceiling after ÷2 | **2.55 V** |
| Margin to the 3.3 V contract | 0.75 V |
| Margin to the H7's unverified 3.6 V TT limit | 1.05 V |

A sagging rail only lowers the ceiling, so the bound is safe by direction. Full
scale stays **reference**-derived — the DAC's or the bridge's number halved, not
the buck's tolerance — because the divider is a fixed ratio of two resistors from
one family rather than a rail-referenced clamp.

**Use `OW-PASS-RT0402BRD073K2L`, 3.2 kΩ 0.1% 25 ppm/°C, 2000 in stock, two per
signal.** The value matters and the first-pass answer of "shunt the existing
249 Ω with another 249 Ω" is wrong for two reasons worth recording so it is not
re-proposed:

- **Power.** A 249 Ω / 249 Ω divider draws 13.3 mA at a 3.3 V full scale and puts
  **43.7 mW continuous** into a 62.5 mW 0402. `../kicad-libs/docs/analog-output-design.md`
  already quotes that figure — as the bound on a *fault*, not as the steady state.
  At 3.2 kΩ the current is 0.52 mA and the dissipation 0.86 mW.
- **Tempco.** A divider's ratio becomes the channel's gain. Two ±1% / 100 ppm
  parts drift up to 200 ppm/°C against each other, or 330 µV/°C at a 1.65 V full
  scale — 3.7× the torque sensor's own 90 µV/°C zero drift, which would make the
  divider the dominant thermal error in the whole chain. Two 0.1% / 25 ppm parts
  from one family hold ratio drift to about 50 ppm/°C, or 82 µV/°C, which sits
  under the sensor and under the electronics offset drift already budgeted.

| Signal | Block | Buffer output | Insert ÷2 at | Then | Source Z | New full scale |
| --- | --- | --- | --- | --- | --- | --- |
| `AOUT` → `ANGLE_OUT` | `analog_output_0_3v3_dac80501` | `AMP_VOUT` (`U2002`) | 3.2 k + 3.2 k | `R2007` 249 Ω | 1.85 kΩ | 3.300 → **1.650 V** |
| `AOUT_MON` | same | tap the **divider midpoint**, not `AMP_VOUT` | — | `R2008` 1 kΩ | 2.6 kΩ | **1.650 V** |
| `TQ_AOUT` | `torque_bridge_0_3v3_ina821` | `AMP_VOUT` (`U37005`) | 3.2 k + 3.2 k | `R37021` 249 Ω | 1.85 kΩ | 3.283 → **1.642 V** |
| `TQ_AOUT_MON` | same | tap the divider midpoint | — | `R37022` | — | **1.642 V** |
| `BRAKE_ISENSE` | `brake_current_sink_0_49ma_dac80501` | `ISENSE_OUT` (`U36003`) | 3.2 k + 3.2 k | `R36018` 249 Ω | 1.85 kΩ | 2.010 → **1.005 V** |

`R2005` (100 kΩ) and `R36017` (110 kΩ) stay on their buffer outputs, upstream of
the divider, where they already define 0 V for an unpowered block.

**In-block, not board-level.** The series resistors are already in-block, and the
divider bounds the net wherever it sits on it, so putting it in the block makes
the 3.3 V ceiling a property of the circuit rather than something every placing
board has to remember. Same reasoning that moved `R2008` into
`analog_output_0_3v3_dac80501` on 2026-08-27: the protection travels with the
thing it protects. The board still owns the BNC and its ESD clamp's ground via.

**The monitor taps move to the divider midpoint rather than getting their own
dividers.** That is one fewer part pair, and it keeps the monitor and the
researcher's BNC at the same scale — `AOUT_MON` and `AOUT` then read the *same
voltage*, so the InstrumentPort capture and the OneBox record need no different
scale factors. It also does **not** reintroduce the problem that moved this tap
to `AMP_VOUT` on 2026-08-27: the midpoint is a block-internal node, so no
permanently DC-connected stub from the researcher's BNC lands on the 40-pin
unshielded FFC. See `../mouse-joystick-pcb/docs/interface-map.md`.

One real if minor cost of that: FFC-injected crosstalk previously landed on the
op amp's hard low-impedance output and now sees 1.6 kΩ back to the source.
**Consider 1 nF from the divider midpoint to analog ground** — a 100 kHz pole,
four decades above the 987 Hz signal band, purely to shunt what the FFC injects.
It is after the amplifier so it does not touch the Sallen-Key response.

**What it costs overall.** Half the span, which is half of one bit. 1.650 V
against the OneBox's 152.6 µV ideal step is 10,813 codes, about 13.4 bits. The
torque front end's own noise is 19 µV RMS at the BNC today and becomes 9.5 µV
after the divider — 0.06 of a OneBox code. Both channels were, and remain, limited
by the OneBox rather than by the board, so the halved span costs no real
resolution. Source impedance rises from 249 Ω to 1.85 kΩ, which against the
`AD7616-P`'s 1 MΩ is −0.19% instead of −0.025%; that is a fixed gain term
per-board calibration absorbs, and it is why the 0.1% / 25 ppm parts matter more
than the absolute value does.

**Calibration consequence:** every documented endpoint in this file and in
`../kicad-libs/docs/torque-sensor-interface-design.md` halves. Re-fit gain and offset per board
serial against the new endpoints; do not scale an older fit arithmetically,
because the divider's own tolerance is now part of the gain.

**The 100 kΩ-load rule still applies and gets stricter.** With a 1.85 kΩ source,
`../kicad-libs/docs/analog-output-design.md`'s "requires a high-impedance load of 100 kΩ or
more" costs 1.8% at exactly 100 kΩ. Keep the receiver at 1 MΩ or better, and a
50 Ω terminated input is still forbidden.

### The angle DAC also moves to 3.3 V, as an independent second barrier

The divider bounds a *buffer* fault. Move the angle `DAC80501`'s `VDD` from
`+5V_FILT` to a ferrite-filtered **3.3 V** rail and the *pre-firmware* hazard
disappears at its source as well, using the trick
`brake_current_sink_0_49ma_dac80501` already proves: at `VDD` = 3.3 V, the
`REF-DIV = 0` reset default requires `VREFIO ≤ 0.5 × VDD` = 1.65 V against a
2.5 V internal reference, so the reference alarm asserts, the reference buffer
shuts down and **all DAC outputs go to 0 V** until firmware writes
`GAIN = 0x0101`. The DAC's own output is then also hard-capped at `VDD`.

That retires the standing hazard in this document — *"a full-scale code would
present about 4.85 V before firmware writes a single register"* — as a hardware
property rather than a firmware promise. The `GAIN` write becomes a **span**
setting, not a safety-critical one. Item 7 of the checklist below still verifies
it, but a missed write now yields 0 V rather than an overvoltage.

### Rejected, with reasons, so they are not re-proposed

- **A low-leakage clamp to `+3.3V`.** A `BAV199` (5 nA, so microvolts across
  249 Ω rather than the millivolts a Schottky would cost) clamps near 3.8 V. That
  is inside the `STM32F405`'s 4.0 V with no margin and **outside** an H7 TT pin's
  ~3.6 V. It is a mitigation, not the bound that was asked for. It is also a new
  internal part and vendor mapping.
- **A 3.3 V rail-to-rail output stage**, which would be the cleanest answer —
  the ceiling would be the rail, exactly as the torque signal path already works.
  **Nothing in the JLCPCB inventory can do it.** `OPA197` and `OPA2210` are the
  only RRIO parts stocked and both are 4.5 V minimum; `OPA381` is a 2.7-5.5 V
  transimpedance amplifier, not a general-purpose buffer. This is a purchase, and
  worth revisiting for a later revision — an `OPA330`/`OPA377`-class precision
  RRIO part at 3.3 V would let the span go back to 0-3.3 V with the bound intact.
- **A rail-referenced divider with full scale near the rail**, which is how the
  ratio could be pushed to 0.647 and keep a 3.3 V span. It makes full scale
  depend on the buck's tolerance instead of the voltage reference, and it runs
  the buffer in its last 100 mV where offset and linearity degrade. Wrong trade
  for a scientific output.
- **Leaving `ANGLE_OUT_MON` tapped at `AMP_VOUT` with no divider.** The tap point
  itself is correct and stays — moving it to the BNC side would put a permanently
  DC-connected stub from the researcher's node onto a 40-pin unshielded FFC
  carrying SPI and UART edges, which
  `../mouse-joystick-pcb/docs/interface-map.md` rejected on 2026-08-27 for good
  reason. Adding the shunt at the *connector* end bounds it without touching the
  tap.

### This also closes torque open item 14

`../kicad-libs/docs/torque-sensor-interface-design.md` open item 14 asks for the `INA821`'s
actual light-load positive swing limit, because the 3.283 V ceiling assumes the
datasheet's 0.15 V from the rail and a real 0.05 V would make it 3.32 V — which
would have *violated* this contract by 20 mV. After the divider the upstream
ceiling is 1.65 V either way, so the measurement is no longer a safety
dependency. Keep it as a calibration item; drop it as a blocker.

## Integration And Validation Checklist

1. Set each used OneBox ADC channel to +/-5 V and disconnect its corresponding
   OneBox DAC output in the GUI/API before connecting the SDR breakout.
2. ~~Measure the actual OneBox ADC input loading before trusting any reading.~~
   **Closed 2026-08-27: the `AD7616-P` is 1 Mohm.** Record the loading as a known
   gain term in the calibration rather than measuring it. **Figure revised
   2026-09-11:** the angle BNC's source is 249 ohm **plus the divider's
   1.6 kohm = 1.849 kohm**, so the term is **-0.185%, or -3.05 mV at the 1.650 V
   full scale** — not the 0.025% / -0.82 mV this item quoted before the dividers
   landed. The rule it came from still stands and is now stricter for any *other*
   receiver: **below about 1 Mohm** the source resistance becomes a gain error
   rather than a nuisance (100 kohm costs -1.82%), and anything near 50 ohm reads
   a fraction of the correct voltage.
2b. **Verify the board's own band limit rather than relying on the OneBox.** The
   AD7616-P's antialias filter is first order at ~39 kHz against fixed 30.3 kHz
   sampling, so out-of-band content folds in almost unattenuated. Sweep the motor
   chopper frequency while recording the angle channel; if a periodic artifact
   moves with it, it is aliasing rather than signal.
3. Record torque and angle on two OneBox ADC channels under the same acquisition
   trigger as the neural probes. Preserve OneBox timestamps and SYNC status.
4. ~~Confirm the pyControl analog-input absolute maximum, input impedance, and
   sampling behavior before treating 3.3 V as a safe hard endpoint.~~ **No longer
   gating, 2026-09-08.** The ÷2 output dividers put every board-exiting analog
   signal's worst-case ceiling at 2.55 V, which is inside both the `STM32F405`'s
   4.0 V and the H7's unverified ~3.6 V. Still worth having the H743 number on
   file — it is torque open item 12 — but no design decision waits on it.
5. Decide the timing master and populate only the matching `SMA1` receive or
   transmit path. Verify 5 V TTL levels and high-impedance loading on a scope.
6. Measure the OneBox input at 0 V, **0.825 V, and 1.650 V** — halved
   2026-09-08 with the output dividers — then fit gain and offset per board
   serial. Repeat with the brake off, at steady currents, and during current
   steps. **The angle path cannot produce a true 0 V**, but the floor is far
   lower than this item assumed — **measured 4.5 mV at `AMP_VOUT`** (Fluke 87,
   board `E4654C159F171E34`, 2026-09-10), which the divider halves to **2.25 mV**
   at the BNC, not the ~25 mV / ~12 mV estimated here before. Keep the low
   endpoint at or above **25 mV** anyway: it costs nothing at the bottom of the
   span and it stays clear of the floor across parts and temperature. Reserve 0 V
   as the out-of-band unhomed/faulted/unpowered level. Do not rescale an older
   fit arithmetically — the divider's own tolerance is part of the new gain.
   **And do not lean on the analog level as the fault discriminator:** 2.25 mV of
   separation between a commanded zero and a dead output section is not a
   reliable margin, so read `STATUS` over I2C instead — that is one of the
   reasons both DAC blocks moved off SPI.
7. Verify the angle DAC's `GAIN` register reads `0x0101` before the first data
   write, and that `VREFIO` measures 2.500 V. The reset value is `0x0001`, the
   0-5 V range. **Revised 2026-09-08:** this is now a *span* check, not a safety
   check. With the DAC on 3.3 V the reference alarm holds all outputs at 0 V until
   the write lands, and the ÷2 divider bounds the output regardless — so a missed
   write reads 0 V rather than presenting an overvoltage. Confirm the alarm
   behaviour once on the bench: write a full-scale code with `GAIN` unwritten and
   measure `DAC_VOUT`; 0 V means the alarm asserted.
8. Record the angle DAC update instant, torque `CONVST`, OneBox SYNC, and local
   hardware-capture timestamps in the same timing validation. State the measured
   uncertainty; do not infer it from USB latency.
