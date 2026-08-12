# Power

**Status:** Draft; two items need a purchase decision before fabrication
**Date:** 2026-08-12
**Input:** 36 V through a 2-position 5.08 mm pluggable terminal block

## Rail Chain

```text
36 V in ──> hv_input_36V_terminal_2pos_5p08_protected ──> +36V (VM)
                                                            ├──> TMC5130A VS / VSA
                                                            └──> hv_to_5v_tpsm365r6 ──> +5V
                                                                                          ├──> TMC5130A VCC
                                                                                          ├──> DAC8563 VDD
                                                                                          ├──> encoder supply (if 5 V)
                                                                                          └──> 5v_to_3v3_tps73733 ──> +3.3V
                                                                                                                       ├──> RP2040
                                                                                                                       ├──> TMC5130A VCC_IO
                                                                                                                       ├──> 5× SN74LVC125A
                                                                                                                       └──> encoder receiver
```

| Stage | Block | Part | Range | Headroom at 36 V |
| --- | --- | --- | --- | --- |
| Input protection and switching | `hv_input_36V_terminal_2pos_5p08_protected` | `TPS1HTC100-Q1` | 6-60 V operating | comfortable |
| 36 V → 5 V | `hv_to_5v_tpsm365r6` | `TPSM365R6V5`, 600 mA | 3-65 V, 70 V transient | comfortable |
| 5 V → 3.3 V | `5v_to_3v3_tps73733` | `TPS73733`, 1 A LDO | — | comfortable |
| Motor bridge | `tmc5130` | `TMC5130A-TA` | **46 V operating, 49 V absolute** | **10 V** |

## 36 V Is The Tightest Constraint On The TMC5130A, Not On The Regulators

The two regulators are unbothered by 36 V. The driver is the part to watch, and
there are two distinct consequences.

### 1. Transient Headroom

TMC5130A rev 1.21 chapter 29:

| Parameter | Value |
| --- | --- |
| `V_VS`, `V_VSA` operating | 5.5 V to **46 V** |
| `V_VS` absolute maximum with inductive load | **49 V** |
| `V_VMAX` supply and bridge maximum | **50 V** |

At 36 V nominal that leaves 10 V to the operating limit. The datasheet's own
footnote is the relevant warning:

> Stray inductivity of GND and VS connections will lead to ringing of the supply
> voltage when driving an inductive load. … Even small trace inductivities as
> well as stray inductivity of sense resistors can easily generate a few volts of
> ringing leading to temporary voltage overshoot. This should be considered when
> working near the maximum voltage.

A few volts of ringing on a 24 V rail is uninteresting. On a 36 V rail it is a
third of the remaining margin.

**The 36 V input block populates no TVS.** Its description says so explicitly —
it differs from both 24 V variants in exactly this way. So:

- **Add a board-level TVS on the 36 V rail.** Working voltage above 36 V plus
  supply tolerance, clamping below 46 V. `SMBJ40A` or `SMBJ43A` class. The
  `kicad-libs` note on the brake controller already records that **the stocked
  TVS parts are unsuitable for a 36 V rail**, so this is a purchase item, not a
  catalog pick.
- Keep bulk electrolytic close to the driver's `VS` pins, not only at the input
  terminal, and keep the `VS`/`GND` loop small.
- Follow the datasheet's sense-resistor layout rules strictly. Sense-resistor
  stray inductance is named in the same footnote.

### 2. Internal 5 V Regulator Dissipation

The TMC5130A's internal linear regulator drops `VM - 5 V`. Its limits:

| Parameter | Limit |
| --- | --- |
| `I_5VOUT`, internal plus external load | 50 mA |
| `P_5VOUT` continuous, `(V_VM - 5 V) × I_5VOUT` | **1 W** |

At `VM = 36 V` the drop is 31 V, so the 1 W limit is reached at **32 mA** —
below the part's own 50 mA current rating. The regulator, not the current limit,
is the binding constraint.

The fix is the datasheet's Figure 3.4 arrangement: **supply `VCC` from the
external 5 V rail** so the internal regulator carries almost nothing. The
`tmc5130` design block already exposes `+5V` as a boundary input separate from
its internal `5VOUT` net, which is exactly this arrangement — so connecting the
block's `+5V` to the `hv_to_5v_tpsm365r6` output is not an optimization, it is a
requirement at 36 V.

**Confirm during schematic capture** that the block ties `VCC` to the external
`+5V` and leaves `5VOUT` as a decoupled local net rather than bridging them. If
it bridges them, the external supply back-drives the internal regulator.

`VSA` may also be supplied from a lower rail than `VS` to reduce dissipation
further; the datasheet notes this reduces regulator dissipation to about 37% when
a 12 V rail is used instead of 24 V. This board has no intermediate rail, so
`VSA` ties to `VS` per the block default. Revisit only if driver temperature
measurements at Gate D say to.

## Why 36 V At All

Recorded so the decision is not re-litigated later, and so the cost above is
attributed to a benefit:

- **Motor performance.** Higher rail voltage means faster current rise in the
  coil, so the same motor holds torque to a higher step rate. On a joystick that
  has to feel responsive to a mouse, that is the whole point.
- **Rev-1 brake headroom.** `kicad-libs/docs/b5z-magnetic-particle-brake-controller.md`
  assumes a **36 V** input as constant-current compliance, because a 24 V rail
  cannot force 49 mA through a 560 Ω hot coil. The twin-axis board records this
  as an unresolved tension between its 24 V plan and the brake note. Choosing
  36 V here removes it in advance: whatever this board learns about a 36 V rail
  transfers directly to the brake design.

## Load Budget

Fill in measured values at Gate B. Estimates for sizing only.

| Rail | Load | Estimate |
| --- | --- | --- |
| `+36V` | Motor, 0.67 A/phase RMS, two phases | Sized from the identified motor; see below |
| `+36V` | TMC5130A quiescent and gate drive | tens of mA |
| `+5V` | TMC5130A `VCC` | ~20-30 mA |
| `+5V` | DAC8563 `VDD` | ~1 mA |
| `+5V` | Encoder, if 5 V | **Unknown — the encoder part is not identified.** A Broadcom `HEDR-5421` class part draws 40-85 mA |
| `+5V` | Level translator, if fitted | few mA |
| `+3.3V` | RP2040 | ~50 mA |
| `+3.3V` | TMC5130A `VCC_IO` | few mA |
| `+3.3V` | 5× `SN74LVC125A` | few mA static, more when switching |
| `+3.3V` | Differential encoder receiver, if fitted | ~10 mA |

The 5 V rail's 600 mA is comfortable unless the encoder is unusually hungry.
**Check the encoder's supply current once the part is identified** — it is the
only line item here that could plausibly matter.

The 3.3 V LDO dissipates `(5 - 3.3) × I`. At 300 mA that is 0.51 W, which the
`TPS73733` in its `kicad-libs` footprint handles, but confirm the thermal pad
arrangement rather than assuming.

**Motor supply current is an open item** until the motor is identified. Size
input protection, bulk capacitance, and the `ILIM` resistor from the real part.
One motor rather than two means roughly half the twin board's supply current,
which is one more reason this board is easier.

## Enable, Current Limit, And Sense

The `hv_input_36V_terminal_2pos_5p08_protected` block is not a passive input. It
is a `TPS1HTC100-Q1` smart high-side switch, and it brings three board-level
signals:

| Block label | Board connection | Note |
| --- | --- | --- |
| `ENABLE` | `HV_EN`, RP2040 `GP19` | Pulled low in the block — **the rail is off until firmware drives it** |
| `ILIM` | Resistor to ground | Sets the adjustable current limit. Size from the motor's stall and inrush behavior |
| `SNS` | `HV_SNS`, RP2040 `GP28` (`ADC2`) | Analog load-current sense. Confirm whether the block populates the sense resistor; scale so full-scale lands below 3.3 V |

Consequences worth stating plainly:

- **The board boots with the motor rail off.** That is the correct safe state
  and it is free. Firmware must raise `HV_EN` deliberately, after configuring the
  driver, and must drop it on fault. Add this to the boot sequence and to the
  fault table.
- The 3.3 V and 5 V logic rails are downstream of the same switch, so **the MCU
  cannot enable its own supply**. Verify this during schematic capture: if
  `hv_to_5v_tpsm365r6` is fed from the *switched* `+36V` output, the board never
  boots. Feed the regulator chain from the **protected but unswitched** node —
  after the reverse-polarity diode, before the high-side switch — and switch only
  the motor rail. This is the single most likely way to make an unbootable board
  out of otherwise correct blocks.
- The block carries a `PWR_FLAG` (`#FLG027001`), unlike the 24 V terminal
  variant. Do not add a second one on the same net. Exactly one `PWR_FLAG` per
  net, on input and entry nets only.

## Grounding

- One solid ground plane. Analog return for the DAC output and the BNC shell
  kept away from the motor return path.
- Kelvin connections at the sense resistors, no shared ground path between the
  two shunts, per the TMC5130A datasheet. The project already has a
  `SENSE_KELVIN` netclass.
- Establish the analog / digital / power zoning now even though this board has no
  torque bridge. If this design is ever carried into the twin-axis Rev 1 with
  brakes and bridges, retrofitting zoning means moving everything.
- Decide explicitly where the RJ-45 shield ties, if a shielded jack is used.

## Open Decisions

1. **The 36 V TVS part.** Not stocked. `SMBJ40A`/`SMBJ43A` class. Purchase item.
2. **Motor part number**, which sets supply current, `ILIM`, bulk capacitance,
   and the motor connector.
3. **Encoder supply voltage and current**, which sets the 5 V budget and the
   harness conductor count.
4. Whether the regulator chain is fed pre- or post-switch. Recommendation above:
   pre-switch, so logic survives a motor-rail shutdown.
5. `SNS` scaling and whether the block already populates the sense resistor.
6. Whether a rail-voltage divider onto `GP26` is wanted in addition to the
   current sense.
