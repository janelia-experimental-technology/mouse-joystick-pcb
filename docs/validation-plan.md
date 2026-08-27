# Validation Plan

**Rev 0 scope:** gates that exercise the analog angle output, the pyControl TTL
event lines, or an independent encoder cross-check do not apply. The cross-check
is not deferred — it was deleted on 2026-08-16 and those gates should be struck,
not postponed. Run them when rev 1 adds the circuits. Everything covering
power, the driver, the encoder-to-driver path, homing, and the serial link
applies as written. Note that `ENCODER_MISMATCH` is retired — there is no
second count to disagree with and there never will be.

**InstrumentPort-40 gates apply to Rev 0 as of 2026-08-16**, but only for the
eleven live Strands and the three fitted buffer packages `U1601`/`U1701`/`U1801`.
Do not fail a gate on the seven unrouted Strands. **Corrected 2026-08-17:** the
board carries **three** `SN74LVC125A` packages, not five — `U_C` and `U_D` do not
exist, so there is nothing to check for DNP. Check instead that no input on the
three fitted packages floats.

**No test points exist anywhere on the board** (verified 2026-08-17). Any step
below that assumes a probe pad currently has nowhere to land; those steps are
flagged individually rather than quietly left in place. Either add pads before
fabrication or accept that the signal is only reachable at a component pin or
through InstrumentPort-40.

**Reference designators were annotated on 2026-08-17.** Where this document still
uses a pre-placement name, the as-built name is given alongside it: `J1501`
(InstrumentPort, was `J4`), `J1102` (motor, was `J5` then `J1101`), `J1103` (encoder, was `J6` then `J1102`), `J1101` (analog BNC, was the `J7` placeholder),
`J1901` (pyControl RJ-45, was `J3`), `U201` (high-side switch, was `U27001`),
`U1201` (TMC5130A, was `U4001`). Net names are `+3.3V_MCU`/`+3.3V_SW` (not
`+3V3_*`), `HV_RAW` (not `VAA`), and `~{BUS_SW_EN}` (not `~{BUS_SW_OE}`).

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
  **Reversed 2026-08-17: no TVS is populated.** The rationale above is unchanged,
  so the hot-plug and transient measurements in Gate B are now the only evidence
  that the unprotected rail survives — treat them as blocking, not informational.
- **Bulk capacitance is downstream of the high-side switch**, so plugging the
  terminal block in does not ring against it, and is **capped at tens of µF** —
  the switch dissipates ½CV² = 0.65 mJ per µF charging it, and the datasheet
  requires the design not reach thermal shutdown while doing so.
  **Corrected 2026-08-17:** as built, `+36V_SW` carries **~208 µF**
  (`C1213` + `C1214` at 100 µF each plus the ceramics), well past "tens of µF". The
  position is right — it is downstream of the switch — but the cap is not met, so
  the cold-start and warm-start turn-on checks in Gate B are a real measurement
  rather than a formality.

### Power — the 36 V input block edits

The block has never been placed. **Corrected 2026-08-17: the block is placed** as
`U201` / `J201` / `D201`, and the resistors were renumbered in the process. The
`R2700x` names below are the pre-placement library numbering; the as-built name
follows each one. Every item is a resistor value or a single wire; see the audit in
`docs/power.md`.

- `R27001` — as built **`R201`** — changed from 10 k to **1 kΩ**, so `EN` sees
  3.0 V rather than 1.65 V against a 1.5 V `VIH`. Done, with `R204` 10 kΩ pulling
  `EN` down.
- `DIAG_EN` tied to `+3.3V`. **Without this the `SNS` output is dead** and
  `HV_SNS` reads nothing. **Reversed 2026-08-17: `DIAG_EN` is driven from `GP14`
  (`HV_DIAG_EN`) through `R202` 1 kΩ, not tied high.** Tying it high keeps the
  TPS1HTC100's OFF-state open-load detection permanently enabled, which puts an
  internal 150 kΩ pull-up from `VS` to `VOUT` across the switch and creeps
  `+36V_SW` upward while the rail is supposed to be off — see the Gate B check
  below. `DIAG_EN` has an internal pull-down, so with `GP14` high-Z at reset
  diagnostics are off and `+36V_SW` sits at true zero. The consequence stated above
  still holds and is now firmware's responsibility: **`HV_SNS` and `~{HV_FAULT}`
  mean nothing until firmware raises `GP14`.** Per the datasheet's Table 7-1,
  current limit and thermal shutdown are unaffected by `DIAG_EN` — only reporting
  is gated.
- `~FAULT` routed to `GP29` with a pull-up to `+3.3V_MCU`.
- `LATCH` tied to `+3.3V_MCU` through a 1 kΩ `RPROT` (`R203`) for **latch-off**. Left floating
  the device auto-retries every 2 ms, which cycles the motor rail at ~500 Hz into a
  persistent fault. Clearing is by toggling `EN`, which firmware owns on `GP19`.
- `R27003` (`ILIM`) — as built **`R206`** — changed from 10 kΩ to **40 kΩ** (`OW-PASS-SCR0603F40K`,
  stocked), so the limit is ~1.2 A rather than the present **5.3 A typ (4-6.3 A)**.
  Confirmed against the identified motor, and able to pass the `+36V` inrush. Must
  never float — floating is a fault state. If more headroom is needed, 2 × 49.9 kΩ
  in parallel gives the tabulated 25 kΩ / 1.96 A row.
- `R27004` (`R_SNS`) — as built **`R207`** — changed from 1 kΩ to **249 Ω**
  (`OW-PASS-CRCW0402249RFKED`, stocked), so the fault indication lands at
  1.29-1.59 V instead of 3.3-4.4 V, well under the RP2040 ADC's `VDD + 0.3 V`
  limit. No divider required. Confirmed 2026-08-17 against the datasheet:
  `ISNSFLT` is a 5.2-6.4 mA current source, so a fault reads 1.3-1.6 V against the
  RP2040's `VPIN` absolute maximum of `IOVDD` + 0.5 = 3.8 V, and stays clearly
  distinct from the ≤0.37 V maximum normal-current reading. The safe upper bound is
  about 594 Ω; ~470 Ω would use more ADC range if resolution ever matters.
- `DIAG_EN` and `LATCH` each driven through a 1 kΩ `RPROT` series resistor
  (`R202`, `R203`), per the datasheet's Table 4-2.
- **`R27005` — as built `R205` — pulls `~FAULT` UP to `+3.3V_MCU`, not down to `GND`.** As originally
  wired it was a pulldown on an open-drain output, which idles low and reads as a
  permanent fault.
- **`HV_IN` and `SNS` are hierarchical labels**, not local ones. Without `HV_IN`
  the board cannot feed the buck from the unswitched node or place the TVS; without
  `SNS` the current sense cannot reach `GP28`. `ILIM` stays local.
- `C27002` — as built **`C202`**, 22 nF — is a **100 V** part, matching `C27001`
  (as built **`C201`**, 220 nF). 50 V gives only 1.4× margin on a
  36 V rail and does not cover the −60 V `VOUT` excursion during inductive turn-off.
  Both confirmed 100 V on 2026-08-17. The same standard is **not** met by
  `C1213`/`C1214` on `+36V_SW`, which are 50 V — see the Gate B transient check.
- The block's 3.3 V hierarchical label resolves to the board's `+3.3V_MCU` net.
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
  explicitly about ringing from stray inductance. As built that bulk is
  `C1213`/`C1214`, 100 µF **50 V** each — 72% of rating on a 36 V rail, with no TVS
  above them. Acceptable on paper; it is the Gate B transient measurement that
  decides it.
- **`C1209`/`C1210`, the TMC `VS` ceramics, are rated correctly by vendor mapping
  rather than by requirement.** `OW-CAP-100N-0402-X5R-16V` declares
  `ReqMinVoltage = 16V` but resolves to LCSC C162178, a 100 V part. Move them to a
  part whose requirement states the rail voltage — `OW-PASS-GRM188R72A104KA35D`
  (100 V) is already catalogued — so a future vendor remap cannot silently drop
  them to 16 V on a 36 V net.
- An RC snubber footprint exists across `VS`/`GND` at the driver, populated or
  not, so a bad Gate B transient measurement is a populate decision rather than a
  respin.
- Exactly one `PWR_FLAG` per net, on input and entry nets only. The 36 V block
  and the `usb2` block each carry one; do not add a second to either.

### Power — multi-source logic rail

- **The ORing diodes are at the `TPS73733` input, not on `+5V`.** ORing onto
  `+5V` drops it below the TMC5130A's 4.6 V `VCC` minimum, and below the rev 1
  `OPA197`'s 4.5 V minimum. (**Corrected 2026-08-26**: it does not "truncate the
  DAC's full-scale output" — that failure mode belonged to the `DAC8563` plan,
  where full scale was `VDD`-referenced.)
- `+5V` is single-sourced from the `TPSM365R6V5`.
- Diode orientation blocks current back into the USB host and into pyControl.
- The `SW_RAIL_SENSE` ÷2 divider off `+3.3V_SW` is fitted on `GP26`, and firmware
  refuses to deassert `~{BUS_SW_EN}` until it reads valid. Firmware refuses to drive the 5 V
  domain when `+5V` is absent. As built the divider is `R401`/`R402`, 1 kΩ/1 kΩ,
  inside the `mcu` sheet; the sheet pin named `SW_RAIL_SENSE` carries the **raw**
  `+3.3V_SW` rail in, and the divided node on `GP26` is **`SW_RAIL_SENSE_DIV_2`**.
  That same 2 kΩ to GND is what holds `+3.3V_SW` at 0 V when the domain is off, so
  it is load-bearing twice over: **if the divider is ever removed, `R1404`,
  `R1101`, `R1102` and `R1103` stop defining their nets.**
- Series resistors are present on every 3.3 V line driving a 5 V-domain input,
  as a hardware backstop independent of firmware.
- **`hv_to_5v_tpsm365r6` is fed from the switched `+36V_SW`**, so `VSA` (which the
  `tmc5130` block ties to `+5V_SW`) can never exceed the `V_VS` + 0.5 V absolute
  maximum, and `VCC` can never arrive after `VCC_IO`. Both orderings hold by
  construction with no sequencing logic. Recorded as a deliberate deviation: the
  datasheet says `VSA` is "normally tied to `VS`", and this board does not, to keep
  36 V off the analog supply.
- **`+3.3V_MCU` is a separate always-on rail fed only from USB `VBUS` or
  pyControl pin 6**, through two ORing diodes, with no tap on `HV_IN`. The
  board's inability to boot from 36 V alone is accepted and silkscreened.
- **The TMC5130A's `VCC_IO` is on `+3.3V_SW`, not on `+3.3V_MCU`.** An always-on
  `VCC_IO` with a switched `VCC` is the sequencing order the datasheet forbids.
- **Two `5v_to_3v3_tps73733` instances exist, one per domain**, and the two 5 V
  rails are separate nets that never meet.
- **Every MCU line reaching the switched domain passes through a
  `SN74CB3Q3245` channel**, and the pyControl UART, `HV_EN`, `SW_RAIL_SENSE`,
  `HV_SNS`, `~{HV_FAULT}` and the `FW_TRIG` markers do not. Series resistors
  back up the bus switch on those crossings.
- **The bus switch is powered from `+3.3V_MCU`**, so firmware can isolate before
  dropping `HV_EN`. **Record this as a deliberate divergence from the block's
  intent:** the `kicad-libs` note says `rp2040_gpio_isolation_sn74cb3q3245` was meant
  to run from the switched target-domain rail so the part's own `Ioff` provides the
  isolation. As built, all four `VCC` pins are on `+3.3V_MCU` and isolation depends
  on the MCU holding `~{BUS_SW_EN}` high, which `R601` 7.87 kΩ makes the reset
  default. Also note **A side = TMC / switched side, B side = MCU side** — the
  opposite of what `docs/interface-map.md` says. Unused B-side pins are tied to GND
  and the A-side pins are open, so the rev-1 DAC channels are *not* pre-wired.
- **`+3.3V_MCU` is never switched.** The MCU runs on it and drives `ENABLE`;
  switching it off cannot be undone by firmware.
- `R4002` — as built **`R1202`** — in the `tmc5130` block, between `VCC` and
  `5VOUT`, is 10 Ω where the datasheet recommends 2.2 or 3.3 Ω. Confirm or change.
  **Signed off 2026-08-17 as benign:** as built the 10 Ω sits between `+5V_SW` and
  `5VOUT`, and because `VCC` is supplied externally the internal regulator idles, so
  the resistor carries almost nothing. The datasheet's sequencing rule — `VCC` comes
  up before or in parallel with `5VOUT` and `VCC_IO` — is satisfied. Keep 10 Ω.
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
  **Corrected 2026-08-17:** `GP14` is no longer spare — it drives `HV_DIAG_EN`
  through `R202`. The remaining spares are **`GP15`, `GP16`, `GP18`, `GP27`** —
  four, not five. `GP9` is `~{BUS_SW_EN}` with `R601` 7.87 kΩ pulling it up to
  `+3.3V_MCU`, so the bus switch is isolated at reset.
- **`RUN` and `SWCLK`/`SWDIO` are unconnected and NC-flagged, by decision.** There
  is no SWD header in Rev 0 and no reset button. `RUN`'s internal 50-80 kΩ pull-up
  and the datasheet's permission to leave it make the missing reset an access
  limitation rather than an electrical defect; both are deferred to a future
  revision. Gate steps that assume SWD access do not apply to Rev 0.
- The `EXT_FAULT_IN` decision is made: reserved and routed, or explicitly
  declined.

### Driver

- Current sense is **0.15 Ω** (`OW-PASS-RLH12FTCR150`, 1206, 1 W) on both
  positions, as built `R1203` and `R1204`. **The `tmc5130` block ships 0.12 Ω as its
  default — confirm the placed value, not the block default.** **This is the one
  place the board and `kicad-libs` disagree, and the board is right** (verified
  2026-08-17): the library moved to 0.12 Ω in commit `a8dca31`, so **re-placing the
  `tmc5130` design block will silently revert the sense resistors** and put roughly
  25% over the intended current. Either fix the library back to 0.15 Ω or never
  re-place that block. Verify the fitted parts on the physical board, not the
  schematic value, before first motion.
- The schematic and any firmware configuration table record **`vsense = 1`** and
  **`IRUN = 28`**. With 0.15 Ω installed, `vsense = 0` — the chip's reset default
  — drives roughly 1.8× the motor's rated current.
- Firmware **sets and reads back** `vsense = 1` and `IRUN = 28` from CHOPCONF and
  refuses to raise `DRV_ENN` unless both are confirmed **against the 0.15 Ω
  shunts**, raising an `INTERNAL` fault instead. Read-back, not write-and-hope: the
  write can be lost with the bus switch isolated and nothing else on the board
  reports it.
- The motor supply envelope is sized from the identified motor.
- `SWSEL` is strapped for SPI and brought to a pad. **Corrected 2026-08-17:**
  `SWSEL` (pin 28) is tied to GND, which is SPI — correct — but **there is no pad**,
  because the board has no test points at all. `SPI_MODE` (pin 12) is left
  no-connect and its internal pull-up selects SPI, which is also correct.
- `DRV_ENN` is pulled to the disabled state. As built this is `R1103`, 10 kΩ from
  `~{TMC_DRV_EN}` to **`+3.3V_SW`** — the switched rail, deliberately, so it
  collapses with the domain rather than injecting current into a dead rail. See the
  Gate B measurement of `U1201` pin 29.
- **The TMC's `DIAG0`/`DIAG1` pull-ups are `R1101`/`R1102`, 10 kΩ to `+3.3V_SW`.**
  Both pins are open-drain at reset and the datasheet requires ≤47 kΩ.
- **The TMC SPI and `LIMIT_SW` taps into the instrumentation buffers are terminated
  at 10 kΩ, not 100 kΩ** (`R1401`-`R1405`). 100 kΩ against the TMC's `(tpu)` inputs
  — `RPU` = 132/166/200 kΩ on `CSN`/`SCK`/`SDI`/`SDO` — parks the node at ~1.9 V,
  straddling the `SN74LVC125A`'s 2.0 V `VIH`. Do not "improve" these to 100 kΩ.

### Sensors and outputs

- The encoder is identified, and the input path is single-ended or differential
  accordingly. **Settled 2026-08-17: single-ended 5 V push-pull, received through
  `quadrature_encoder_input_5v_sn74lvc2g17`, which is placed.** The chain is
  `J1103` → `R801`/`R802` 100 kΩ harness-side pull-downs → `R803`/`R804` 4.7 kΩ
  series → `C802`/`C803` 470 pF → `U801` SN74LVC2G17 dual Schmitt on `+3.3V_SW` →
  `R805`/`R806` 100 kΩ output pull-downs → `ENC_A`/`ENC_B`.
- **The push-pull assumption is in the hardware, not just the prose.** `R801`/`R802`
  are pull-**downs**, which only work with a push-pull encoder. **An open-collector
  or open-drain encoder will not work without changing them to pull-ups**, so
  confirm the output stage of the chosen part before fabrication. This is one of the
  two things the encoder decision can still invalidate.
- **Confirm `J1103`'s pin order against the chosen encoder's harness:** pin 1 =
  `GND`, pin 2 = **reserved index, no-connect**, pin 3 = `ENC_A_RAW`, pin 4 =
  `+5V_SW`, pin 5 = `ENC_B_RAW`. Note that supply sits between the two channels, so
  a harness wired to a different convention will put 5 V onto a signal pin.
- **There is no ESD device anywhere in the encoder path.** Other documents in this
  repo say the encoder input has ESD protection; **corrected 2026-08-17 — it does
  not.** Decide whether the cable run justifies adding one.
- **Peak encoder channel frequency is measured during the fastest
  motor-commanded move** (homing or recentering — not the animal's pull, which is
  the slow case), and `C802`/`C803` are confirmed. **Confirmed 2026-08-17** against
  the as-built netlist: the fitted filter is `R803`/`R804` **4.7 kΩ** × `C802`/`C803`
  **470 pF**, a **71.4 kHz corner** (τ = 2.2 µs). Note the two numbers in the sizing
  table in `.agents/PLANS.md` mean different things and are both correct: 71.4 kHz
  is the −3 dB corner, and **44.9 kHz is the maximum usable channel frequency**,
  about 0.63 × f_c, which is the figure to compare against. Confirm the encoder's
  `f_ch = CPR × RPM / 60` against **44.9 kHz**. If chopper hash rides on the line,
  step the capacitors up using that table — it is computed for the fitted 4.7 kΩ.
  Both channels must keep the same value so A/B delay stays matched. The node to
  probe is the block's internal `EA_FILT`/`EB_FILT` at the `U801` inputs, **for
  which no test pad exists** — reach it at the `U801` pin or add a pad.
- `ENC_N` is wired to the TMC5130A `ENCN` and a test pad, and **to no GPIO**.
  **Corrected 2026-08-17: there is no `ENC_N` net and no test pad.** `ENCN` is
  **tied to GND through `R1201` (10 kΩ)**, which satisfies the TMC5130A
  requirement to pull `ENCN` to GND or `VCC_IO` when unused. `J1103` pin 2 is
  reserved for the index channel if the chosen encoder has one, but it is a
  no-connect today, so adopting an index channel is a schematic change.
- The limit switch is identified and the debounce path is reviewed. As built the
  path is `J1301` → `U1301` MAX6816 → `LIMIT_SW` → TMC `REFL` (pin 8), with
  `R1405` 10 kΩ to GND defining the `U1801` buffer input.
- ~~A test point exists on the `REFL` net, and `GP9` drives it through a series
  resistor weak enough that the real switch always wins.~~ **Struck 2026-08-17** —
  `GP9` is `~{BUS_SW_EN}`, the stimulus net was deleted on 2026-08-13, and the board
  has no test points. Replaced by: `REFL` is exercised by closing the real switch
  and observed on InstrumentPort `DIG11`.
- ~~DAC8563 `VIH` at `VDD = 5 V` is checked; a dual-supply level translator is
  added or explicitly ruled out.~~ **Closed 2026-08-26.** The part is a
  `DAC80501`, whose `VIH` is 1.62 V minimum flat across `VDD` = 2.7-5.5 V. No
  translator. The warning that an `SN74LVC125A` is **not** a valid translator
  stands for any other 5 V path.
- ~~`~LDAC` is wired for synchronous update.~~ **Void 2026-08-26** — the part has
  no `LDAC` pin. Replaced by a firmware check: synchronous update uses
  `DAC_SYNC_EN` plus the `TRIGGER` register.
- **The `GAIN` register is written to `0x0101` before the first DAC data write.**
  Reset is `0x0001`, which is the 0-5 V range; until that write lands the 3.3 V
  hardware bound does not hold. This is the single most important firmware
  ordering check on the analog output.
- `VREFIO` measures 2.500 V, and the gain from `DAC_VOUT` to `AMP_VOUT` measures
  1.32. Both have block-level test pads.
- The analog output's fault and reset behavior is decided and documented.
- ~~Whether `AUX_ANALOG_OUT` is populated is decided, and `J7` is a dual or single
  BNC to match.~~ **Closed 2026-08-27:** a single vertical `HL-BNC-KHDA` is placed
  as `J1101`, `AUX_ANALOG_OUT` is not populated, and `AIN1_P/N` stay no-connect.
- The DAC bus terminations are fitted — **all three inside the block** as of
  2026-08-27: `~{DAC_CS}` 10 kΩ to `+3.3V_SW` (`R2006`), `DAC_SPI_COPI` 10 kΩ to
  GND (`R2009`), `DAC_SPI_SCK` 10 kΩ to GND (`R2010`) — and **none of them to
  5 V**. This item used to say the two pull-downs were board-level. **Add no
  board-level copies when the `DIG9`/`DIG10`/`DIG6` taps go in**; they would
  parallel these and halve them.
- **The block's `+3.3V` port is bound to `+3.3V_SW`, not `+3.3V_MCU`.** On the
  always-on rail the `~{DAC_CS}` pull-up back-powers `+5V_SW` through the DAC's
  input clamp whenever the switched domain is down. **Verified on the netlist
  2026-08-27**; still measure `+5V_SW` with `HV_EN` low at Gate B.
- **The 987 Hz output filter is verified.** Measure the corner and the group delay
  rather than assuming them: expect −3 dB at about 827 Hz and 266 µs of DC group
  delay from `R2001` 20 kΩ / `R2002` 13 kΩ / `C2003` and `C2007` 10 nF C0G. Record
  both as measured numbers, because every latency measured through `AIN0` and every
  latency the researcher sees at the BNC includes the delay.
- **`C2003` and `C2007` are C0G, not X7R.** Confirm on the assembled board. A
  class-2 substitution puts a ±15% tempco on the corner and the reported delay, and
  adds a dielectric-absorption tail that reads as hysteresis in the angle channel.
- **The chopper-alias check.** Sweep the TMC chopper frequency while recording the
  angle channel. If a periodic artifact moves with it, it is aliasing of the
  16-30 kHz chopper into 0-15 kHz past the OneBox's fixed 30.3 kHz sampler, not
  joystick motion. This is the measurement that says whether 987 Hz was the right
  corner.
- A fourth `SN74LVC125A` package is placed for the `DIG6`/`DIG9`/`DIG10` taps.

### pyControl and instrument

- The RJ-45 — as built **`J1901`** — is wired per `docs/pycontrol-port-pinout.md`:
  pin 1 `DIO-A` to
  `UART0 RX`, pin 4 `DIO-B` to `UART0 TX`, pin 2 `GND`. Pins 3, 5, 7 not
  connected. No Ethernet magnetics.
- **`PYC_UART_RX` (`GP1`) has a 10 kΩ pull-up to `+3.3V_MCU` (`R403`).** All RP2040
  GPIOs reset with the internal pull-**down** enabled, so without `R403` the idle
  UART line reads low and firmware sees a permanent break. Check the pull-up before
  blaming the cable at Gate B.
- **`R1903` on the pyControl 5 V branch is a polyfuse position, not protection.**
  The path is `J1901` pin 6 → `PYC_CONN_5V` → `R1903` → `PYC_5V_FUSED` → `D1901` →
  `+5V_MCU`, and the 0.36 Ω part currently fitted is a jumper. Port 5 V is a shared
  1.0 A that also feeds the pyControl controller's own logic regulator with no
  per-port fuse, so a fault here can reset the controller. Populate a 1206 PPTC,
  250-500 mA hold, or record the jumper as an accepted risk. **There are no test
  points either side of `R1903`, so a tripped PPTC could not be diagnosed in
  circuit.** The on-sheet note still names `R29003`, which is not this board's
  designator — fix the text when the part is decided.
- The assigned pyControl port is confirmed UART-capable on the deployed breakout.
- Three event lines have a confirmed physical home, and the breakout has enough
  BNCs for **all boards in the rig**, not just this one.
- The InstrumentPort-40 overlay is reviewed against `board-interfaces` and not
  redefined here.
- **`J1501`'s cable orientation is documented before fabrication** (`J4` in earlier
  drafts) — connector
  reference, physical pin-1 marker location, contact side, expected cable type and
  orientation, and whether the mating board sees the logical pin order mirrored.
  The profile requires this of every board that uses it, and it is an open
  decision in the profile itself.
- The **eleven live** `DIG*`/`TRIG*` signals are buffered; `~OE` defaults to high-Z
  in hardware — `R1601`/`R1701`/`R1801`, 10 kΩ each to `+3.3V_MCU` — and firmware
  enables it at startup. The remaining seven Strands are no-connect at `J1501` and
  have no buffer channel behind them.
- **The pyControl serial Strands are tapped at the board-side nets `PYC_UART_RX` /
  `PYC_UART_TX`**, which are the same nodes as the block's `PYC_DIO_A`/`PYC_DIO_B`
  pins, so the block's 100 Ω (`R1901`/`R1902`) sits between the buffer input and the
  cable. The block is unmodified at five boundary pins.
- **No `SN74LVC125A` input floats.** **Corrected 2026-08-17: there are three
  packages, `U1601`/`U1701`/`U1801`, and no `U_C`/`U_D`/`U_E`.** The termination as
  built is: `R1401`/`R1402`/`R1403` 10 kΩ to GND on `TMC_SPI_SCK`/`COPI`/`CIPO`;
  `R1404` 10 kΩ to **`+3.3V_SW`** on `~{TMC_CS}`, because a pull-down there would
  assert chip select; `R1405` 10 kΩ to GND on `LIMIT_SW`; `R805`/`R806` 100 kΩ to
  GND inside the encoder block on `ENC_A`/`ENC_B`; and `U1801`'s fourth, spare
  channel with its input tied straight to GND. Note that `~OE` does **not** gate the
  input stage — `ΔICC` is 500 µA typ / 5000 µA max per partially biased input
  regardless of `OE`, against 40 µA max for the whole device with valid levels — so
  disabling the buffers is not a substitute for terminating the inputs.
- **`ENC_A`/`ENC_B` are tapped on the driver side of the encoder input filter**,
  so the capture shows what the TMC5130A's pins receive rather than what the cable
  delivers. As built they are the `U801` Schmitt outputs.
- **The instrumentation taps sit on the A / switched side of the bus switch**, not
  the MCU side. `docs/interface-map.md` says A is the MCU side; it is wrong and the
  board is the authority. The consequence is that every tapped TMC signal reads 0 V
  whenever `HV_EN` is low, which is why the terminations above exist.
- `AOUT0`/`AOUT1` are no-connect, and no divided motor rail reaches any `AIN*`.
  `AGND` (pins 31, 34, 37, 40) is **tied to `GND`** as of 2026-08-17; it was
  previously an isolated four-pin island.
- **The documented "buffered static low on `DIG12`" is not delivered.** `U1801`'s
  spare channel has its input grounded but its output stops at `R1805`, and `J1501`
  pin 20 is a no-connect. Do not write a gate step that expects to see it.
- ~~Labelled test points exist for the 10 signals not carried by InstrumentPort-40,
  including `ENC_N` and `LIMIT_SW`, **plus `ENC_A`/`ENC_B`**, which lose their
  port slots at rev 2 and fall back to the pads.~~ **Struck 2026-08-17 — no test
  points exist anywhere on the board.** The rationale stands and the need is real:
  `ENC_A`/`ENC_B` lose their port slots at rev 2 and have no fallback access today.
  Either add the pads before fabrication or record that those signals become
  unreachable at rev 2.

### Mechanical and process

- Board outline and mounting are decided. `../mouse-joysticks-mech` describes the
  two-joystick assembly; how a per-axis board mounts in it is a decision, not a
  derivation.
- A unit-identifier field is on the silkscreen if the rig will hold two boards.
- Layout zoning separates the motor section and the switching supply from the
  encoder path and the analog output.
- ERC and DRC pass. **ERC recorded clean 2026-08-17: 0 violations across all
  severities**, 142 components, no duplicate reference designators, and every part
  footprinted. Re-run and re-record after any schematic edit; a clean ERC is only
  evidence at the commit it was taken on.
- **Netclass patterns were extended on 2026-08-17, 108 → 124 patterns**, because
  146 of 156 nets were falling through to `Default` and would have routed at
  0.2 mm. The 36 V rail, both 5 V rails, both 3.3 V rails, the four motor phases and
  `BRA`/`BRB` no longer do. As assigned: `*/HV_RAW` and `*/HV_IN` → `PWR_HV_ENTRY`
  1.5 mm; `/+36V_SW` → `PWR_HV_BUS` 1.2 mm; `/motor_encoder_limit/OA*`, `OB*` and
  `*/tmc5130/BRA`, `BRB` → `MOTOR_2A` 0.8 mm; `/+5V_*`, `*/VBUS`, `*/PYC_CONN_5V`,
  `*/PYC_5V_FUSED` → `PWR_5V` 0.5 mm; `/+3.3V_*` → `PWR_3V3` 0.3 mm; `*/5VOUT` and
  `*/tpsm365r6/VCC` → `PWR_5V_LOCAL` 0.2 mm; `*/tmc5130/VCP`, `CPO`, `CPI` →
  `BOOTSTRAP` 0.3 mm. Verified that no net matches more than one netclass. Note
  **`BRA`/`BRB` are not Kelvin sense nets** on the TMC5130A — they carry full coil
  current into the sense resistor, so they are sized with the motor phases.
  `MOTOR_2A` at 0.8 mm was chosen over `MOTOR_LOW` at 0.3 mm because the motor part
  is still open; downgrade it once the motor is fixed. **DRC has not yet been run
  against a routed board.**

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
- **`+36V_SW` sits at true 0 V with `HV_EN` low.** With 36 V applied, `GP14`
  (`HV_DIAG_EN`) low and `GP19` (`HV_EN`) low, `+36V_SW` must read 0 V and must
  **not creep upward**. This is the newest and least obvious defect class on the
  board, so measure it before anything else on this list. If the rail creeps at
  roughly **1.2 V/s** and the 5 V rail starts hiccupping every few seconds, the
  TPS1HTC100's OFF-state open-load pull-up — **150 kΩ from `VS` to `VOUT`** — is
  enabled, meaning `DIAG_EN` is high when it should not be. The arithmetic: ~240 µA
  into the ~208 µF on `+36V_SW` crosses the TPSM365R6's 3.6 V minimum `VIN` in about
  3 s, at which point the buck starts, collapses and hiccups, and the switched
  domain never cleanly powers off. That would break the "`HV_EN` power-cycles every
  resettable chip" property the whole reset architecture rests on, and corrupt
  `SW_RAIL_SENSE` with it. **Derived from the TPS1HTC100 datasheet on 2026-08-17,
  not yet bench-verified** — this measurement is what converts it.
- **`SW_RAIL_SENSE` reads zero when the switched domain is off.** `GP26` sees
  `+3.3V_SW` through the `R401`/`R402` 1 kΩ/1 kΩ divider, so the ADC node is
  `SW_RAIL_SENSE_DIV_2`. Expect **~0 V with `HV_EN` low** and **~1.65 V with the
  rail up**. This is the guard firmware uses before enabling the bus switch, so it
  has to be trustworthy in both directions — a reading that is merely low is not the
  same as zero, and the difference decides whether the isolation sequence is safe.
- **`~{TMC_DRV_EN}` is high at boot.** With the switched domain powered and the bus
  switch still isolated, measure `U1201` **pin 29**: it must be **≥2.31 V**, the
  TMC5130A's `V_INHI` = 0.7 × `VCC_IO`. `R1103` 10 kΩ to `+3.3V_SW` guarantees
  ≥2.75 V worst case, even against the RP2040's strongest 50 kΩ reset pull-down
  passed through the bus switch. **If it sits near 1 V the pull-up is missing or on
  the wrong rail, and the power stage can enable itself.** Measure this before a
  motor is attached.
- **`~{TMC_CS}` idles high and the other three SPI taps idle low.** With the
  switched domain on and the bus isolated: `~{TMC_CS}` ≈ **3.4 V** (deasserted), and
  `TMC_SPI_SCK`, `TMC_SPI_COPI`, `TMC_SPI_CIPO` ≈ **0.28 V**. With the domain off,
  **all five nets at 0 V**. This confirms `R1401`-`R1405`. A reading near 1.9 V on
  the SCK/COPI/CIPO group means 100 kΩ was fitted instead of 10 kΩ and the taps
  straddle the `SN74LVC125A`'s 2.0 V `VIH`.
- **Back-power check.** With 36 V applied and **both USB and pyControl unplugged**,
  measure `+3.3V_MCU` and `+3.3V_SW`. **Both should be 0 V.** The `SN74LVC125A` has
  no `Ioff` and no partial-power-down support, its `VI` absolute maximum is
  −0.5 to 6.5 V and is **not** `VCC`-referenced, and TI does not specify leakage at
  `VCC` = 0 — so this case is **unspecified rather than guaranteed** by the
  datasheet. This measurement is what closes it. Anything other than 0 V means a
  path exists from the switched domain back into the always-on rail, and the
  `HV_EN` power-cycle stops being a power-cycle.
- **Each power source works alone**, and the board behaves sanely in each state:
  USB only; **pyControl only, which is now a required mode, not an optional
  one**; 36 V only, which must be confirmed *not* to boot; and every combination,
  including plugging and unplugging each source while the others are live.
  Measure `+3.3V_MCU` in each case.
- **Measure pyControl pin 6's available current** under the board's real load.
  This is the item that decides whether pyControl-only operation works, and it is
  unmeasured today.
- With the switched domain down, confirm no current flows into `+5V_SW` or
  `+3.3V_SW` through any device's input clamps, and that `SW_RAIL_SENSE` reads
  zero. Note that the pulls to `+3.3V_SW` (`R1101`, `R1102`, `R1103`, `R1404`) are
  deliberately on the switched rail so they collapse with it; a pull to `+3.3V_MCU`
  in any of those positions would back-power `+3.3V_SW` to roughly 1.3 V through the
  TMC's protection diodes, defeat the `HV_EN` power-cycle and corrupt
  `SW_RAIL_SENSE`. If this measurement shows a residual voltage on `+3.3V_SW`, check
  those four first.
- **Exercise the reset sequence with a scope**: isolate (`~{BUS_SW_EN}` high), drop
  `HV_EN`, confirm
  `+3.3V_SW` collapses with no MCU pin driving into it; then raise `HV_EN`,
  confirm `SW_RAIL_SENSE`, and connect. Getting this order wrong is the failure the
  architecture exists to prevent, so prove it rather than assuming it. Note that
  isolation here is **not** provided by the bus switch's `Ioff` — `U601`-`U604` run
  from `+3.3V_MCU` and stay powered — but by the MCU holding `~{BUS_SW_EN}` high,
  with `R601` 7.87 kΩ as the reset default. That makes this a firmware-dependent
  property and therefore worth proving on the scope rather than reasoning about.
- No current flows back into the USB host or into pyControl from any other
  source.
- The analog output reaches a true **3.300 V** full scale with the 36 V supply
  present. **Updated 2026-08-26**; this used to say 5.00 V, and the diagnostic
  attached to it no longer applies — full scale now comes from the DAC's
  internal reference, so a low `+5V_SW` does not scale the output down. Check
  the rail directly instead: it must be above the `OPA197`'s 4.5 V minimum.
- Rail voltages, sequencing, and ripple are measured with the motor loaded.
- Motor-rail transient overshoot is measured at the TMC5130A `VS` pins during
  motion start, stop, and a deliberate stall. **Compare against the 46 V
  operating and 49 V absolute limits.** This is the measurement that justifies or
  condemns the 36 V choice. **It now bounds two things, not one:** no TVS is
  populated, and `C1213`/`C1214` are 100 µF **50 V** parts on a 36 V rail — 72% of
  rating — so the same capture is the only evidence that the bulk capacitors' margin
  survives the transient as well. Record the peak against 50 V, not only against
  46 V.
- Overshoot on `HV_IN` is measured while **hot-plugging the terminal block**,
  against the switch's 70 V and the buck's 65 V. This is the event the TVS is
  there for — and **no TVS is populated**, so this is now an unprotected
  measurement. Take it with a fast probe and be prepared for the answer to be a
  populate decision.
- `HV_EN` turn-on into the final `+36V_SW` capacitance — **~208 µF** — completes
  without tripping the
  switch's thermal shutdown, from both a cold and a warm start.
- `HV_SNS` tracks measured load current, and the fault level stays under 3.3 V at
  the ADC pin when a fault is provoked. **Raise `GP14` (`HV_DIAG_EN`) first** —
  `HV_SNS` and `~{HV_FAULT}` report nothing until `DIAG_EN` is high, so a "dead
  sense" reading with `GP14` low is the expected behavior, not a defect. Expect
  1.3-1.6 V at `GP28` on a fault (`ISNSFLT` 5.2-6.4 mA into `R207` 249 Ω) against
  ≤0.37 V for the maximum normal-current reading.
- `~{HV_FAULT}` asserts on a deliberate overload and the board reports
  `SUPPLY_OUT_OF_RANGE`.
- TMC5130A case temperature is measured; the internal regulator is confirmed
  offloaded.
- **Continuity confirmed against real hardware for all eight `J1901` RJ-45 pins.**
  The
  pinout is cited from a schematic, not measured. This is the check that converts
  it to verified.
- **UART idle level measured at the RP2040 pin, not only at the connector.**
  `PYC_UART_RX` must idle **high** on `R403`'s 10 kΩ to `+3.3V_MCU` with the cable
  unplugged. A low idle means `R403` is missing or on the wrong rail and every frame
  will look like a break.
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
- The analog output reaches its commanded endpoints, measured: **3.300 V at full
  scale, and within about 25 mV of ground at zero**. **Updated 2026-08-26** —
  this used to demand "0 V and 5 V". Both numbers were wrong and the first would
  have failed a correct board: the `OPA197`'s output stage sits about 5 mV
  typical and 25 mV maximum off the negative rail at light load, so a true 0.000 V
  is not achievable and is not a defect. The valid angle range starts at 50 mV;
  0 V is the out-of-band fault level.

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
- CHOPCONF read-back confirms `vsense = 1` **and `IRUN = 28`** before any sustained
  run, and before `DRV_ENN` is raised at all. The 0.679 A figure is only true
  against **0.15 Ω** shunts, so **confirm `R1203`/`R1204` on the physical board**,
  not in the schematic: the `kicad-libs` `tmc5130` block ships 0.12 Ω, and a
  re-placed block silently reverts them.
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
  now `~{BUS_SW_EN}`. Replaced by: closing the real switch produces an edge on
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

- Buffers default to high-Z at power-on, before firmware runs. All three packages
  share `~{INSTR_BUF_OE}` on `GP24`, each with its own 10 kΩ pull-up
  (`R1601`/`R1701`/`R1801`), so the default is set by hardware in triplicate.
- Firmware enables buffers at startup and reports buffer state in `ID`/`STATUS`.
- **The eleven live Strands read defined levels with the switched domain off.**
  Because the taps sit on the **A / switched** side of the bus switch, every TMC
  signal on the port collapses to 0 V when `HV_EN` is low. Confirm that this is what
  the capture shows rather than a floating trace, which is the same visual and a
  different fault.
- **`DIG12` carries nothing.** Earlier drafts describe a buffered static low there;
  `U1801`'s spare output stops at `R1805` and `J1501` pin 20 is a no-connect.
  Confirm the analyzer channel is unassigned rather than reporting a stuck low.
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
