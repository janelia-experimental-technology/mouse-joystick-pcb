# Mouse Joystick Brake And Torque Purchase Plan

**Moved** here from `kicad-libs/docs/` on 2026-10-07. Paths into that repository are written `../kicad-libs/…`; the datasheets it cited from its `tmp/` cache are in the private store `../kicad-libs-nonfree/datasheets/`.

**Status:** component-shopping recommendation; no schematic or layout has been
validated yet.

**Brake column revised 2026-08-31.** The brake driver resolved entirely to stock:
every part it needs is already in JLCPCB inventory and already in
`../kicad-libs/db/source/internal_parts.csv` with a symbol and footprint. See
`../kicad-libs/docs/brake-current-sink-design.md` for the settled circuit and its bill of
materials. Ten brake lines are **cancelled** below — `DAC60501ZDGSR`,
`OPA2197IDR`, `MJD340T4G`, `MJD122T4G`, `IXTA6N50L2`, `TLV7041DBVR`,
`TPS3431SDRBR`, the precision brake shunt, the DAC scaling network, the
default-off clamp transistors, and the brake case-temperature probe — and the
`GA63V150M10X15` brake-bulk reservation is released. The two remaining brake
lines are replenishment of parts already in use: `DAC80501ZDGSR` and
`OPA197IDBVR`. ~~**The torque column is unaffected and still needs ordering in
full.**~~ **Revised 2026-09-04 — see the next paragraph.**

**Inventory basis:** kicad-libs `tmp/Parts Inventory on JLCPCB.csv`, exported 2026-08-20,
and the five-board Rev 0 BOM in
`../mouse-joystick-pcb/fab/mouse-joystick-pcb/jlcpcb-bom.csv`.

**Datasheet audit:** the manufacturer PDFs downloaded to kicad-libs `tmp/` were checked
on 2026-08-20, including the OneBox technical user manual V1.0.1 and product
datasheet. Exact JLCPCB/LCSC availability and assembly class remain unverified.

**Torque column revised 2026-09-04.** The torque front end is now a settled
design in `../kicad-libs/docs/torque-sensor-interface-design.md`, and it removes five lines
below rather than adding any. **Cancelled:** `LT3042EMSE#PBF` and
`TPS7A4901DGNR` (excitation noise reaches the signal attenuated 667× by the
sensor's 1.5 mV/V, so ultra-low-noise regulation buys nothing, while the
`LT3042`'s ±1% initial accuracy and unspecified tempco land directly on the
gain), `REF5025EIDR` (the midpoint is a ÷2 divider off the buffered excitation,
which is one part fewer and ratiometric with it), the `BAV199` bridge-input
protection (the `INA821` protects its own inputs to ±40 V with an 8 mA internal
current limit), and the 0.66-ratio BNC scaling network (the ratio is 1/3, built
from three identical stocked `ERA2AEB103X`). **Changed:** `ADS8699IPWR` →
`ADS8689IPWR`, because 18 bits over the rated span is 16.6 ideal bits against a
sensor whose nonrepeatability is 0.05% — about 11 bits — and the parts are
pin-compatible. **Added:** `REF5010AID` and a 249 Ω 0.1% 25 ppm gain resistor.
The `INA821IDR` line stands, but its gain resistor is **249 Ω for a gain of
199.4**, not 499 Ω for 100. `OPA197IDBVR` rises to **3 per torque channel**, so
the board total is 7 per board and the replenishment target moves from 150 to
about 200.

**Every replenishment line in this document is stale, checked 2026-09-04
against `../kicad-libs/db/source/jlc_inventory_export.csv`.** The quantities below predate a
restock and the plan over-orders as a result. Actual stock, against the per-board
counts *including* the torque block: `CL05A105KL5NRNC` **9976** (not 0, so the
200-piece buy is cancelled); `OPA197IDBVR` **298** (not 100 — 7 per board now
covers 42 boards, so the 150-piece replenishment is cancelled);
`DAC80501ZDGSR` **98** (not 50, covering 49 boards, so that 50-piece buy is
cancelled too); `ERA2AEB103X` **994** against 7 per board; `TPSM365R6FRDNR`
**100** against 1 per board. **Nothing needs replenishing.** The order for the
torque block is five new lines and nothing else — three ICs and two precision
resistors. See `../kicad-libs/docs/torque-sensor-interface-design.md`, "Bill Of Materials".

The machine-friendly subset of the shopping list is in
`../kicad-libs/docs/reports/mouse_joystick_brake_torque_purchase_list.csv`.

## Decisions To Carry Into The Schematic

Do **not** use one DAC package for the brake command and the scientific analog
outputs. Sharing an SPI peripheral and a timing reference is reasonable;
sharing the package, reference, analog supply, or power-on behavior couples a
safety actuator to the recorded data.

**Clarified 2026-08-31:** this rule is about the *package*, not the part number.
Two `DAC80501ZDGSR` packages satisfy it — separate reference, separate analog
supply (5 V for the angle output, 3.3 V for the brake), separate power-on
behaviour — while collapsing two datasheets and two register maps into one. The
two DACs share `SCK` and `SDI` with independent `~{CS}`; both are write-only
3-wire devices, so bus sharing carries no contention risk.

Use these separate paths:

```text
                                        +-> ADS8699, hardware CONVST -> MCU/DMA
RTS bridge -> INA821 -> anti-alias LPF --+
                                        +-> buffer -> TORQUE BNC (high-Z DAQ)

encoder count -> DAC80501 (5 V) -> OPA197 x1.32 -> 249R -> ANGLE BNC (high-Z DAQ)

separate DAC80501 (3.3 V) -> 0.195 divider -> OPA197 loop -> BUK7D36 -> 10R shunt
                                              OPA197 ceiling at 56 mA (independent)
                                              OPA197 buffer -> BRAKE_ISENSE

hardware timer/sync input -> ADC CONVST, DAC LDAC/update, SYNC OUT
```

The researcher-facing contract is now **0-3.3 V** for both analog outputs, with
OneBox configured for its +/-5 V input range. Keep the internal 5 V analog rail
and 0-5 V-capable parts. Scale only the connector-facing torque path by 0.66 and
limit the encoder DAC code in firmware. This preserves headroom and the option
for a later 0-5 V profile without replacing the selected ICs. See
`docs/onebox-analog-interface.md` for the resolution and timing calculation.

The torque BNC should be the conditioned bridge voltage, not an
ADC-to-firmware-to-DAC reconstruction. An external neural DAQ then samples the
torque signal in its own clock domain and sees only the documented analog-filter
delay. The encoder is inherently digital, so its analog output does require a
DAC. The second channel of the stocked dual DAC may be used for a non-safety
diagnostic output, but it should not command the brake.

Putting the circuits on one PCB reduces transport and software latency, but it
does not by itself establish microsecond synchronization. OneBox starts neural
and ADC acquisition from the same trigger, appends its 100 kHz timestamp and
SYNC status to both packet types, and samples each ADC channel at 30.3 kHz. Use
that recorded timing rather than USB packet arrival. Capture a common experiment
sync in board hardware, and generate local ADC `CONVST` and encoder-DAC updates
from the same hardware timer/PIO state machine. OneBox `SMA1` is a separate 5 V
TTL interface; the 0-3.3 V analog decision does not change its logic level.
Preserve raw timestamps and calibrate analog-filter group delay.

## Why The Torque Front End Changes

The RTS manufacturer page specifies:

- 350 ohm nominal terminal resistance;
- 10 VDC excitation, or about 28.6 mA bridge current;
- 1.5 mV/V nominal rated output, or 15 mV at 10 V excitation;
- 1% of rated-output zero balance and 150% safe overload;
- 0.1% nonlinearity, 0.1% hysteresis, and 0.05% nonrepeatability.

The existing PGA305 concept cannot source this bridge: its sensor-excitation
current is limited to 1.5 mA. The stocked ADS1220/ADS122C04 family tops out at
2 kSPS, and the PGA305 measurement path is also unsuitable for a possible
10 kSPS torque stream. Keep those parts for slower sensors and calibration
work, not this path.

The preferred acquisition part is `ADS8699IPWR`: an active 18-bit SAR ADC with
an integrated input front end and reference, 100 kSPS maximum rate, 5 us
conversion, 5 us acquisition, and no digital-filter latency. Run the raw
converter at up to 100 kSPS and either retain that stream or decimate to 10 kSPS
with a documented filter. This preserves deterministic timing and moves the
anti-alias boundary well above the requested output rate. Its internal analog
front end is approximately -0.1 dB at 2.5 kHz and -3 dB at 15 kHz; an external
low-pass filter is still required and must be set from the actual scientific
torque-bandwidth requirement.

A practical 10 V starting point is an `INA821` at gain near 100, referred to a
quiet 2.5 V midpoint. Internally, rated signal then occupies approximately
1.0 V to 4.0 V, while 150% sensor overload remains approximately 0.25 V to
4.75 V. A precision 0.66 connector scaling network maps those ranges to about
0.66-2.64 V and 0.165-3.135 V respectively, centered on 1.65 V. Keep a stuffing
option for the raw 0-5 V-capable node. Verify the exact gain, sensor polarity,
input protection, filter corner, and headroom in the schematic calculation
rather than freezing these example values.

Generate 12 V from the stocked adjustable `TPSM365R6FRDNR`, placed away from
the bridge, then post-regulate locally:

- one quiet 10 V rail for bridge excitation (`LT3042` preferred);
- one quiet 5 V rail for the ADC/reference (`TPS7A4901` is adequate here);
- an enhanced-grade `REF5025E` plus buffer for the 2.5 V signal midpoint.

This follows the sensor's stated 10 V excitation instead of assuming it may be
used at 5 V. A lower excitation can be evaluated only after Transducer
Techniques confirms that it is supported and the loss in signal-to-noise ratio
is accepted.

## Quantity Policy

The **buy now** column covers a five-board revision plus bench prototypes,
rework, and one alternate population. The **program target** is stock for 25
board-equivalents: approximately 20 more boards (two five-board revisions and a
ten-board final run) plus 25% assembly/rework reserve. Do not buy all expensive
alternate ICs to the program target before the first simultaneous brake/torque
test.

Exact JLCPCB/LCSC stock, price, assembly class, and ordering suffix can change.
Search the exact preferred MPN first, then apply the electrical criteria in the
notes rather than accepting a superficially similar search result.

## Buy New: Primary Signal Path

| Priority | Function | Preferred search | Buy now | Program target | Notes |
| --- | --- | --- | ---: | ---: | --- |
| A | Torque SAR ADC | `ADS8699IPWR` | 10 | 25 | TSSOP-16, 18 bit, 100 kSPS, no latency, integrated AFE/reference. `ADS8695` is 500 kSPS but is not otherwise necessary. |
| A | Bridge instrumentation amplifier | `INA821IDR` | 10 | 25 | SOIC-8 is easier to inspect than WSON. Keep internal gain near 100 and scale only the BNC path for 0-3.3 V. |
| A | Quiet 10 V bridge regulator | `LT3042EMSE#PBF` | 10 | 25 | Feed from the local 12 V rail; 200 mA comfortably exceeds the 28.6 mA bridge load. A 10 V output uses nominal 100 kohm `RSET`; provide at least 4.7 uF ceramic at both `IN` and `OUT` and follow its unusually sensitive post-regulator layout guidance. Search `LT3045` only as a pin-incompatible higher-current alternative. |
| A | Quiet 5 V analog regulator | `TPS7A4901DGNR` | 10 | 25 | Feed ADC/reference from 12 V. Use at least 2.2 uF at the output; 10 uF input/output plus 10 nF `NR/SS` is the low-noise starting point. Keep feedback current at or above 5 uA. A second LT3042 is a lower-noise but higher-cost alternative. |
| A | Midpoint reference | `REF5025EIDR` | 10 | 25 | Retain the 2.5 V internal midpoint. A 0.66 connector scale produces 1.65 V externally, so no separate 1.65 V reference is needed. Buffer before driving INA `REF` and filter bias loads. |
| ~~A~~ **Cancelled** | Brake command DAC | ~~`DAC60501ZDGSR`~~ | 0 | 0 | **2026-08-31:** use a second stocked `DAC80501ZDGSR` package instead. Same family, same register map, one datasheet for both DACs, 50 already in stock. The rule this line existed to enforce — never share a *package* between the brake command and the scientific outputs — is satisfied by a second package of the same part number. Run it at **3.3 V**, not 5 V: `REF-DIV = 0` is the reset default and is out of spec at 3.3 V, and the datasheet forces all outputs to 0 V on improper reference-divider configuration, so the 0-2.5 V span becomes a hardware property and a wrong-`GAIN` write becomes fail-safe. See `../kicad-libs/docs/brake-current-sink-design.md`. |
| A **Replenish** | Brake and angle command DAC | `DAC80501ZDGSR` | 50 | 50 | **Added 2026-08-31.** Now 2 per board — one for the encoder angle output in `analog_output_0_3v3_dac80501`, one for the brake command. 50 in stock covers exactly 25 boards with no rework margin, which is why this is a buy. |
| ~~A~~ **Cancelled** | Brake and torque RRIO op amps | ~~`OPA2197IDR`~~ | 0 | 0 | **2026-08-31:** the dual is not stocked and the single is. Three `OPA197IDBVR` singles per brake block — loop error amplifier, independent ceiling, `BRAKE_ISENSE` buffer — give better channel isolation in SOT-23-5 and reuse a part already in the DB and already in a built block. |
| A **Replenish** | Brake, torque, and angle RRIO op amps | `OPA197IDBVR` | 150 | 150 | **Revised 2026-08-31.** About 6 per board: 3 brake, 1 angle, about 2 torque. 100 in stock covers roughly 16 boards, so this is the tighter of the two brake replenishments. RRIO, 4.5-36 V, ±100 µV maximum offset, ±65 mA output, 1 nF maximum capacitive load — the last figure is why the brake block's 1 kΩ gate resistor is not optional. |
| A | Encoder BNC gain stage and buffer | `OPA197IDBVR` | 10 | 25 | **Settled 2026-08-26.** Not a unity buffer — a non-inverting **gain of 1.32** that takes the DAC's 0-2.5 V span to the 0-3.3 V contract, which is what makes the range a hardware limit instead of a firmware promise. Single RRIO, 4.5 V minimum supply. Source resistor is **249 ohm** and output protection is a `TPD1E05U06`. Direct DAC drive is ruled out, not merely unproven. |
| B | Optional OneBox 5 V TTL transmitter | `SN74AHCT1G125DBVR` | 10 | 25 if board drives sync | Populate only if the mouse board must drive OneBox `SMA1`; `SN74AHCT1G17DBVR` is the non-tristate alternative. Prefer receiving OneBox timing with the stocked 5.5-V-tolerant `SN74LVC2G17`. |
| ~~A~~ **Cancelled** | Independent current-limit comparator | ~~`TLV7041DBVR`~~ | 0 | 0 | **2026-08-31:** replaced by a third stocked `OPA197IDBVR`, and this is an improvement rather than a substitution. This row's own warning is the reason — ±8 mV offset plus 3-25 mV internal hysteresis is ±3.3% of a 550 mV threshold, which forces the ceiling higher than wanted. The `OPA197`'s ±100 µV offset is ±0.02%, so the ceiling sits at 56 mA with 13% clear margin over the 48.78 mA command maximum. It still overrides pass-device drive without firmware, through a Schottky minimum-wins clamp on the gate node. |
| ~~A~~ **Cancelled** | Hardware watchdog/safe-state gate | ~~`TPS3431SDRBR`~~ | 0 | 0 | **2026-08-31, judgement call, reversible by purchase.** "Brake stuck at 49 mA" is the brake's *rated continuous operating condition*, not a damage mode, so the hazard is experimental and welfare-related rather than destructive. The board already gives the MCU an unconditional hardware kill: `HV_EN` drops `+36V_SW` through the `TPS1HTC100-Q1`, and `../mouse-joystick-pcb/docs/power.md` records that `HV_EN` deliberately bypasses the GPIO isolation bus switch so it works regardless of bus state. Reinstate if bench experience disagrees. |
| ~~A~~ **Cancelled** | High-voltage BJT prototype | ~~`MJD340T4G`~~ | 0 | 0 | **2026-08-31:** the base-current error this row asked to characterize is a *systematic* 0.7-3.3% shunt error across the guaranteed gain spread, varying with current and temperature. A MOSFET removes it instead of characterizing it. Use the stocked `BUK7D36-60EX`; the DC-SOA objection does not survive the numbers at 0.71 W and 49 mA — see `../kicad-libs/docs/brake-current-sink-design.md`. |
| ~~B~~ **Cancelled** | High-gain BJT comparison | ~~`MJD122T4G`~~ | 0 | 0 | **2026-08-31:** moot once the pass device is a MOSFET with zero DC gate current. |
| ~~B~~ **Cancelled** | Linear-rated MOSFET comparison | ~~`IXTA6N50L2`~~ | 0 | 0 | **2026-08-31:** no distributor purchase, and no pass-device comparison at all. The design settled on a single stocked `BUK7D36-60EX`; the 80 V `BSC072N08NS5ATMA1` was briefly carried as a DNP alternate and then rejected on gate-drive headroom the same day. See `../kicad-libs/docs/brake-current-sink-design.md`. |
| C | True 50-ohm output driver | Hold until DAQ requirements are known | 0 | Only if required | OneBox documentation does not specify its ADC termination. Do not treat `OPA810IDBVR` as a general 0-3.3 V/50-ohm driver; select a driver only if a measured/confirmed 50-ohm load requires one. |

~~The BJT comparison is intentionally a bench decision.~~ **Closed 2026-08-31 in
favour of the MOSFET**, on the accuracy argument rather than the thermal one: DC
gate-current error is eliminated by construction, and 0.71 W at 49 mA is roughly
an order of magnitude clear of any credible hot-spot instability. The bench
decision that *remains* is 60 V versus 80 V, and it turns on measured `+36V_SW`
ringing at the brake stage with the TMC5130A driving, not on SOA. A final pass
device is still not approved until hot case temperature, loop stability, safe
turn-off, and simultaneous torque-noise measurements pass.

## Datasheet Audit Findings

| Part or family | Result that affects the design |
| --- | --- |
| `ADS8699IPWR` | Exact TSSOP-16 suffix is active. Confirms 100 kSPS, 5 us conversion plus 5 us acquisition, no pipeline/digital-filter latency, and 4.75-5.25 V `AVDD`. `DVDD` can operate from 1.65 V to `AVDD`, but specified performance starts at 2.7 V; use 3.3 V. Its internal reference requires at least 4.7 uF on `REFIO` and 10 uF on `REFCAP`. |
| `INA821IDR` | Exact SOIC suffix is active. At gain 100 it has 290 kHz typical bandwidth, 7 nV/sqrt(Hz) input noise, and output swing specified to 0.15 V from either rail. The 10 V bridge common mode is comfortable on 12 V, but the final gain/reference combination still needs the TI common-mode-range calculation. |
| ~~`DAC60501ZDGSR`~~ → `DAC80501ZDGSR` | Same family, same audit. Zero-scale POR does not eliminate the specified 200 mV power-on glitch. **Reassessed 2026-08-31:** through the brake block's 0.19512 divider that glitch is 39 mV, or 3.9 mA — about 8% of rated torque, transient, on a device whose mechanical response is 6 ms. That does not warrant a dedicated clamp transistor, so the glitch is now covered by the divider's attenuation plus the gate pulldown rather than by a separate part. What *is* mandatory is the independent `OPA197` ceiling, and it is mandatory for a different reason: the DAC can reach twice its programmed full scale, up to `VDD`. |
| `DAC80501` reference alarm | **Added 2026-08-31.** `REF-DIV = 0` requires `VREFIO <= 0.5 x VDD`, which is 1.65 V at `VDD = 3.3 V` against a 2.5 V internal reference — and `REF-DIV = 0` is the reset default (`GAIN` reset `0x0001`). Section 8.3.2: improper reference-divider configuration *"triggers a reference alarm condition. In this case, the reference buffer is shut down, and all the DAC outputs go to 0 V."* Running the brake DAC at 3.3 V therefore makes the 0-2.5 V span a hardware property and makes a wrong-`GAIN` write fail-safe. The datasheet gives no numeric threshold for the alarm, so **read `STATUS` bit 0 on the bench**; the design is safe either way because the output physically clips at `VDD` and the ceiling catches the remainder. |
| `OPA2197IDR` / `OPA197IDBVR` | Exact SOIC/SOT-23 suffixes are active. RRIO behavior is appropriate for the torque and 0 V-capable encoder paths; isolate BNC cable capacitance with the source resistor. |
| `TLV7031` / `TLV7041` | Corrected the purchase target: `TLV703x` is push-pull and `TLV704x` is open-drain. Both include significant internal hysteresis that must be included in the current-threshold calculation. |
| `TPS3431SDRBR` | Exact VSON-8 suffix is active. `WDO` is open-drain but becomes high impedance when disabled; `ENOUT` supplies the missing disabled/startup-safe indication. The brake gate must use both states and must not let MCU firmware hold `SET1` low. |
| `MJD340T4G` | Exact DPAK suffix is listed. The published DC SOA comfortably contains approximately 10-15 V at 50 mA at 25 C, and minimum gain is 30 at 50 mA/10 V. Hot thermal/SOA validation and the resulting emitter-versus-collector current error remain required. |
| `MJD122T4G` | Exact DPAK suffix is listed and the SOA contains the operating point, but the guaranteed gain tests are at 4 A and 8 A rather than 50 mA. Keep it as a comparison, not an assumed accuracy fix. |
| `DAC8563SDSCR` | Exact stocked WSON suffix is active and settles in about 14 us. The `DAC8563` powers up at **midscale**, which is acceptable for a scientific encoder output but must be represented in the output-valid protocol. |
| `ADS131M02` | Remains a valid two-channel comparison: up to 64 kSPS, but typical input noise is about 2.4 uVrms at 16 kSPS/gain 128 and the sinc3 path settles in three samples. It does not replace the preferred no-latency SAR path for this design goal. |
| OneBox external ADC | The 16-bit ADC samples each channel at 30.3 kHz. On +/-5 V, the ideal step is 152.6 uV; 0-3.3 V uses about 21,627 codes or 14.4 ideal bits. Neural and ADC packets share the trigger, timestamp, and SYNC status, although their sample clocks are asynchronous. |
| OneBox `SMA1` | Synchronization I/O is 5 V TTL, independent of the 0-3.3 V analog contract. Its output requires a high-impedance load. The ADC-comparator timing path has approximately 33 us jitter and is not the preferred precision-sync source. |

## Buy New: Precision Passives And Protection

| Function | Search criteria | Buy now | Program target | Notes |
| --- | --- | ---: | ---: | --- |
| ~~Brake current shunt~~ **Optional** | 10 ohm, 0.1%, <=25 ppm/C, 0805 | 0 | 0 | **Downgraded 2026-08-31.** The stocked `KTR03EZPF10R0` (10 ohm 1% 200 ppm/C 0603, 1000 in stock) gives about 1.3% over temperature, which is invisible against the brake's own approach-direction torque hysteresis — and the torque sensor, not the shunt, is the calibration reference. Buy a precision part only if current traceability is wanted for its own sake. Kelvin routing still required; 24 mW in a 100 mW 0603. Shunt tolerance and tempco also **cancel in the command-to-ceiling ratio**, since both sides are `V/R_SENSE`, so a loose shunt cannot cause a false limit trip. |
| ~~DAC scaling/gain resistors~~ **Cancelled** | ~~0.05-0.1%, <=25 ppm/C~~ | 0 | 0 | **2026-08-31:** the divider is built from three stocked 0.1% / 25 ppm parts already in the DB — `OW-PASS-ERA2AEB103X` (10k) and two `OW-PASS-RT0402BRD073K2L` (3.2k), giving a ratio of 3.2k/16.4k = 0.19512 and a full scale of 48.78 mA, 99.6% of rated. Note that **the divider is not a hardware ceiling on its own**: a `DACx0501` in `BUFF-GAIN = 1` can reach twice its programmed full scale, up to `VDD`. Powering the DAC at 3.3 V and adding the independent `OPA197` ceiling is what closes that. |
| INA gain resistors | 499 ohm and nearby 0.05-0.1%, <=25 ppm/C values | 50/value | 75/value | 499 ohm gives nominal gain about 100.0. Include values for overload/headroom tuning. |
| Torque BNC scaling network | 0.66 ratio, <=0.05% ratio error, <=10-25 ppm/C tracking | 50 | 75 | Scale the internal 0-5 V-capable torque node to the 0-3.3 V connector profile; follow it with the buffer and retain a raw/scaled stuffing option. |
| Anti-alias network | 0.05-0.1% thin-film resistors and C0G/NP0 capacitors for 2-5 kHz prototypes | 50/value | Decide after test | Buy at least two filter corners. Freeze values only after researchers state required torque bandwidth and phase-delay limits. |
| Analog-output source resistor | 49.9 ohm, 0.1-1%, 0603/0805 | 100 | 100 | Place at each BNC driver. Label outputs for **high-Z termination** unless a true 50-ohm driver is validated. |
| Bridge input protection | `BAV199` plus symmetric series resistors; low-leakage alternatives | 100 | 100 | Leakage and capacitance must be included in bridge-error and bandwidth analysis. Do not put a noisy, high-leakage TVS directly across the millivolt inputs. |
| ~~Default-off clamp devices~~ **Cancelled** | ~~`2N7002` and `MMBT3904`~~ | 0 | 0 | **2026-08-31:** default-off comes from three places that cost nothing — the `Z`-suffix zero-code power-on reset, a 49.9 kΩ gate pulldown, and binding both `+5V_FILT` and `+3.3V_FILT` to the switched domain so the analog stage and its command source go dark together. If an independent hardware disconnect is still wanted, it is a second stocked `BUK7D36-60EX` in series, gate driven by an active-high `BRAKE_ENABLE` with a 10 kΩ pulldown — pending one datasheet check of `R_DS(on)` at `V_GS` about 2.8 V. |
| Regulator programming parts | LT3042 SET resistor/capacitor and TPS7A49 feedback network, 0.1%, low-TCR | 50/value | 75/value | Calculate output tolerance and startup. Provide rail test points and excitation-current measurement. |
| ~~Brake temperature input~~ **Cancelled** | ~~10 kohm NTC probe/harness~~ | 0 | 0 | **2026-08-31:** the thermal budget does not need it. Coil I²R at rated current is 1.11 W and is **not** slip heat; the datasheet's 2 W limit is slip heat, and at rated torque the maximum continuous slip speed is 548 RPM, which a mouse moving a joystick is nowhere near. Case temperature is therefore set by 1.11 W in an 85 g metal body, comfortably under the 75 C limit. The point that an on-board NTC cannot measure a remote case still stands if this is ever reopened. |

## Existing Stock To Reserve Or Replenish

| Action | Existing part | JLCPCB | Current qty | Assumed use | Buy now | Reason |
| --- | --- | --- | ---: | ---: | ---: | --- |
| **Replenish** | `CL05A105KL5NRNC`, 1 uF 35 V 0402 | `C307413` | 0 | Rev 0 uses 6/board | 200 | The five-board order exhausted this SKU. The mathematical 25-board-equivalent minimum is 150; 200 leaves handling/rework margin. |
| **Replenish** | `MBR120VLSFT1G` | `C223608` | 525 | Rev 0 uses 2/board, **plus 1/board in the brake block from 2026-08-31** | 0 | **Revised 2026-08-31:** stock is 525, not 25 — the earlier figure predates a replenishment, and 3/board clears 25 boards with margin, so nothing is owed. This 20 V diode is still **not** the 36 V brake flyback part (that is `S115Q`), but it *is* now the brake block's gate-clamp steering diode, where it only stands off about 5 V on the gate node. |
| Reserve | `OPA2210IDRGR` | `C2866278` | 50 | Up to 1/board | 0 | Suitable on 12 V for buffering the 2.5 V midpoint/reference loads. Its input common-mode range remains 1.5 V from either rail, so do not assign it to the torque or 0 V-capable encoder-output paths. |
| **Replenish** | `DAC80501ZDGSR` | `C1852033` | 50 | **2/board** | **50** | **Revised 2026-08-31.** Now both DACs: the encoder-angle output in `analog_output_0_3v3_dac80501` at `VDD = 5 V`, and the brake command in `brake_current_sink_0_49ma_dac80501` at `VDD = 3.3 V`. The separate `DAC60501Z` purchase is cancelled — one datasheet and one register map now cover the whole board. 16-bit, internal 2.5 V 5 ppm/C reference, zero-scale power-on reset, `VIH` 1.62 V flat. 50 in stock covers exactly 25 boards with **no rework margin**, hence the buy. |
| ~~Reserve~~ **Released** | `DAC8563SDSCR` | `C1554746` | 50 | **0/board** | 0 | **2026-08-26:** no longer the encoder-angle part. `analog_output_0_3v3_dac80501` uses a `DAC80501ZDGSR` instead — `VIH` 1.62 V flat versus this part's `0.7 x AVDD`, and a zero-scale rather than midscale power-on reset. Still stocked 50 deep and still the right choice if a **dual** scientific output is ever wanted on one package; do not use it to command the brake. |
| Reserve | `LSF0102DCUR` | `C964636` | 995 | **0-1/board** | 0 | **Reduced 2026-08-26.** The angle DAC no longer needs it — `DAC80501` `VIH` is 1.62 V flat across `VDD` 2.7-5.5 V. The reservation stands for any *other* 5 V path with a `0.7 x VDD` input, including the `DAC8563` if it is ever used, and for the OneBox 5 V TTL timing direction. The 0-3.3 V analog profile still does not, by itself, remove the requirement anywhere else. |
| Reserve | `SN74LVC2G17DRYR` | `C2675856` | 1000 | 1/board if receiving OneBox timing | 0 | Powered at 3.3 V, its inputs tolerate 5.5 V and provide the preferred OneBox-to-board `SMA1` receive path. |
| Reserve | `DOSIN-801-0095` dual BNC | `C5156335` | 50 | 1/board | 0 | Natural torque/angle connector pair; stock covers 25 board-equivalents with margin. Confirm the existing proxy 3D model against the enclosure. |
| Reserve | `DOSIN-801-0050` single BNC | `C521210` | 95 | 0-1/board | 0 | Candidate `SYNC_OUT`/sample-strobe connector if InstrumentPort is not used. |
| Reserve | `TPSM365R6FRDNR` | `C6723000` | 100 | 1/board | 0 | Existing adjustable 36 V-to-12 V block. Keep its switching loop physically remote from the bridge front end. |
| Reserve | `S115Q`, 150 V 1 A Schottky | `C5362393` | 3000 | 1/board | 0 | **Confirmed 2026-08-31** as the coil flyback, across the connector pins, cathode to the `+36V_SW` side. `V_F` about 0.35 V at 49 mA and 1 µA reverse leakage at 150 V, both negligible here. Validate the turn-off waveform. |
| ~~Reserve~~ **Released** | `DSK36`, 60 V 3 A Schottky | `C106913` | 3000 | **0/board** | 0 | **2026-08-31:** this was the `LM3404HV` catch diode, and the switching fallback is dropped. |
| ~~Reserve~~ **Released** | `GA63V150M10X15`, 150 uF 63 V | `C51018328` | 400 | **0/board** | 0 | **2026-08-31:** sized for the switching fallback. A linear sink draws constant DC, so local bypass is 100 nF plus 470 nF in 100 V ceramic. Releasing it also removes a 10 x 15 mm through-hole can from near the torque front end. |
| Reserve | `1843606` **vertical**, 2-position 3.5 mm terminal | `C3019639` | 148 | 1/board | 0 | **Changed 2026-08-31:** the drawn block uses the **vertical** `OW-CONN-TBH-1X02-3P5-VERT` (160 V / 8 A), not the horizontal `1844210`. Fine at 36 V / 49 mA, and 148 covers 25 boards with margin. It is inside the block, not board-level, because the flyback diode has to sit across its pins. Brake-body grounding is mechanical — no 3-position 3.5 mm part is in stock. |
| Reserve | `1844210`, 2-position 3.5 mm terminal, horizontal | `C3584780` | 730 | 0/board | 0 | No longer the brake connector. Retained for any board wanting a side-entry variant; the repository convention would make that a separate `_vertical`/horizontal block pair. |
| Reserve | `GRT155R6YA474KE01D`, 470 nF 35 V 0402 | — | 283 | 1/board | 0 | **Added 2026-08-31.** DAC `VREFIO` capacitor; the datasheet requires 150 nF or more, so 100 nF is not sufficient. Same part as the angle block. |
| Reserve | `CL21A106KOQNNNE`, 10 µF 0805 16 V | — | 2000 | 2/board | 0 | **Added 2026-08-31.** Bulk on the two filtered analog rails. Chosen over 1 µF / 2.2 µF for stock depth and to match the angle block. |
| Reserve | `BUK7D36-60EX` | `C3288253` | 1360 | 1/board, 2 if `BRAKE_ENABLE` is populated | 0 | **Added 2026-08-31.** The linear pass device. 60 V, 2.3 W at `Ta` (`R_thJA` about 54 C/W) against 0.71 W worst case. Confirm NXP's DC/linear SOA curve and measured case temperature. |
| ~~Reserve~~ **Not used** | `BSC072N08NS5ATMA1` | `C3278732` | 100 | **0/board** | 0 | **Reversed 2026-08-31**, same day it was added. Rejected as the brake pass device on gate-drive headroom: `V_GS(th)` 3.8 V max at 36 µA leaves about 0.25 V between the required gate node and the `OPA197`'s ceiling on a 5 V rail, and a cold start eats it. The 80 V rating is also moot — the TMC5130A's 49 V inductive-load maximum is 80% of the `BUK7D36-60EX`'s 60 V, so the brake FET cannot be the weakest thing on that rail. Stock stays reserved for the `tmc5160` alternate power stage. |
| Reserve | `KTR03EZPF10R0`, 10 ohm 0603 | — | 1000 | 1/board | 0 | **Added 2026-08-31.** Current shunt, Kelvin routed. 24 mW in a 100 mW package. |

The Rev 0 BOM versus updated inventory calculation found no other SKU below a
25-board-equivalent reserve. Re-run it after the next schematic is exported;
this is not a promise that Rev 1 will retain the Rev 0 passive counts.

## Stocked Parts Not To Design Around For This Path

| Stocked part | Why not the preferred final use |
| --- | --- |
| `PGA305ARHHx` | Cannot supply the 350 ohm bridge at 10 V and is not the selected 10 kSPS path. |
| `ADS1220IRVAR` | 2 kSPS maximum; useful for slow precision channels, not the requested torque stream. |
| `BCR421UE6327` | Useful corrected bench prototype, but 40 V margin, thermal current drift, and PWM torque control are inferior to the quiet linear stage. |
| `PCA9685BS,118` | PWM generator only; retained duty and chopped brake current do not provide the preferred safe, quiet command path. **Expanded 2026-08-31:** a `PCA9685` behind a heavy RC filter would deliver the MCU insulation originally wanted, but its output amplitude is a logic swing referenced to a switching 5 V rail, so both torque accuracy and torque noise would track that rail instead of a 5 ppm/C bandgap. The DAC provides the same insulation with none of that. |
| `MBR120VLSFT1G` | Only 20 V reverse rating, so **not** the 36 V coil flyback — that is `S115Q`. **Revised 2026-08-31:** it *is* the brake block's gate-clamp steering diode, where it stands off about 5 V. |
| `SMBJ28A`, `SMF48A`, `SMBJ58A` | Unchanged: 28 V standoff is too low for a 36 V rail, and 48 V/58 V clamp too high for the 40-60 V devices in the system. No TVS is populated on the brake stage; the 60 V pass device relies on local 100 V ceramic bypass plus the coil flyback. Revisit only if measured `+36V_SW` ringing demands it. |

## Items To Confirm Before Freezing The Design Block

1. Confirm the actual purchased sensor model/nameplate, wiring colors, torque
   polarity, and whether its calibration certificate requires exactly 10 V.
2. Confirm the OneBox breakout channel allocation, disconnect the corresponding
   OneBox DAC outputs, and bench-check ADC input impedance. Its manual specifies
   the +/-5 V range but does not specify analog-input termination.
3. Obtain the required torque signal bandwidth, not just sample rate. A 10 kSPS
   record does not automatically require a flat 5 kHz mechanical channel.
4. Define whether raw 100 kSPS torque samples, filtered 10 kSPS samples, analog
   BNC signals, or all three are recorded. Store filter coefficients and delay
   with every data format.
5. Decide the encoder wrap convention for analog output. A sawtooth wrap can
   look like an impossible high-speed event unless the DAQ also records a
   digital wrap/index marker.
6. Measure the actual 36 V maximum and transients before approving pass-device,
   flyback, TVS, and clearances. **Sharpened 2026-08-31:** measure it *at the
   brake stage with the TMC5130A driving*, because the pass device sees the full
   rail whenever the brake is off. This is the one measurement that decides 60 V
   versus 80 V for the pass device.
9. **Added 2026-08-31.** Read `STATUS` bit 0 (`REF-ALARM`) on the brake DAC at
   power-up with `VDD = 3.3 V` and `GAIN` unwritten, and record whether the
   output is forced to 0 V.
10. **Added 2026-08-31.** Obtain the NXP `BUK7D36-60EX` datasheet — `V_GS(th)`,
    `R_DS(on)` at low `V_GS`, and the DC/linear SOA curve. None of the three was in
    kicad-libs `tmp/`. This is now the highest-value open item on the pass device: the
    gate-drive argument that rejected the `BSC072N08NS5` in favour of this part
    assumes a logic-level threshold near 2 V, and the same analysis would apply
    here if it turns out to be a 3 V-class threshold.
7. Confirm pyControl analog-input absolute maximum and input impedance, and
   decide whether the valid calibrated range needs margin below 0 V and 3.3 V.
8. Decide whether OneBox/common timing drives the board or the board drives
   OneBox. Populate only one `SMA1` direction and remember that it is 5 V TTL.

## First Simultaneous Validation

Build at least one board with pass-device alternatives and filter-value DNP
positions. Measure torque noise and spectra with the brake disconnected,
connected at zero, at several DC currents, and during command steps; repeat
while the motor driver is active. Capture bridge excitation, conditioned torque,
ADC samples, brake current, `CONVST`, encoder update, and external sync in the
same oscilloscope/logic-analyzer acquisition. The deciding evidence is noise,
hot SOA/temperature, safe-state behavior, and measured timing—not standalone
datasheet resolution.

## Sources

- `../kicad-libs-nonfree/datasheets/B5Z-metric-data-sheet-1.pdf`
- `../kicad-libs-nonfree/datasheets/onebox-user-manual.pdf` (technical user manual V1.0.1)
- `../kicad-libs-nonfree/datasheets/onebox-datasheet.pdf`
- <https://www.transducertechniques.com/rts-torque-sensor.aspx>
- <https://www.ti.com/lit/ds/symlink/ads8691.pdf> (ADS8691/ADS8695/ADS8699 family)
- <https://www.ti.com/lit/ds/symlink/ina821.pdf>
- <https://www.ti.com/lit/ds/symlink/dac80501.pdf> (DAC80501/DAC70501/DAC60501 family)
- <https://www.ti.com/lit/ds/symlink/opa197.pdf>
- <https://www.ti.com/lit/ds/symlink/opa2210.pdf>
- <https://www.ti.com/lit/ds/symlink/ref50.pdf>
- `docs/b5z-magnetic-particle-brake-controller.md`
- `../kicad-libs/docs/brake-current-sink-design.md` (settled brake circuit, values, and BOM)

Local audited copies sat in kicad-libs `tmp/`; the store
`../kicad-libs-nonfree/datasheets/` now holds `ads869x.pdf`, `ina821.pdf`,
`lt3042.pdf`, `tps7a49.pdf`, `tlv7031.pdf`, `tps3431.pdf`, `MJD340-D.PDF`,
`MJD122-D.PDF`, `opa810.pdf`, `dac8563.pdf` and `ads131m02.pdf`; `ref50xx.pdf`,
`dac60501.pdf` and `opa2197.pdf` are not in it under those names.
