# Power

**Status:** Draft. The 36 V input block has been audited against
`tps1htc100-q1.pdf` and needs six edits when placed; see below.
**Date:** 2026-08-14
**Input:** 36 V through a 2-position 5.08 mm pluggable terminal block

**Updated 2026-08-14:** the pyControl 5 V supply was traced from the host side in
`~/Repositories/github/pycontrol-h7-breakout`. Pin 6 is a shared **1.0 A** rail
that also feeds the controller's own logic regulator, with no per-port fuse — so
this board now **requires a polyfuse on its pin 6 branch**. See
[What Pin 6 Can Actually Supply](#what-pin-6-can-actually-supply). One open
decision closed, one new part.

**Rev 0 scope:** the power chain is unchanged by the 2026-08-13 rescope. `+5V`
is still required — the TMC5130A's `VCC` minimum is 4.6 V — even though the
DAC8563 that also needed it is deferred to rev 1. The argument against diode-ORing
onto `+5V` therefore still holds, and `V5_SENSE` on `GP26` is still populated.
One Rev 0 addition affects this document: `HV_EN` bypasses the new GPIO isolation
bus switch, so the MCU can drive the 36 V enable regardless of bus state, while
`HV_SNS` and `~{HV_FAULT}` sit behind it and cannot be read until firmware
enables the bus. See `docs/interface-map.md`.

## Input Block Review Status

Reviewed against the block's netlist and `tps1htc100-q1.pdf` on 2026-08-12, after
the first round of edits. Reference designators were renumbered during those
edits; the list below uses the current ones.

**Done and verified correct:**

| Element | Value / connection | Check |
| --- | --- | --- |
| `R27001` + `R27004` | 1 kΩ series + 10 kΩ pulldown on `EN` | `EN` = 3.0 V from 3.3 V logic, well over the 1.5 V `VIH` |
| `R27002` | 1 kΩ, `+3V3_MCU` → `DIAG_EN` | Diagnostics enabled; `RPROT` per Table 4-2 |
| `R27003` | 1 kΩ, `+3V3_MCU` → `LATCH` | Latch-off rather than 2 ms auto-retry |
| `R27006` | 40 kΩ on `ILIM` | `I_CL` ≈ 1.2 A; correctly left as a local label |
| `R27007` | 249 Ω on `SNS` | Fault level 1.29-1.59 V, under the ADC limit |
| `C27001` | 220 nF **100 V** on `HV_IN` | `VS` bypass, correctly placed and correctly derated |
| `C27002` | 22 nF on `+36V` | `VOUT` bypass, correctly placed — but see the rating issue below |
| `D27001` | Anode to `VAA`, cathode to `HV_IN` | Correct series blocking direction |
| `U27001` pin 11 `NC` | Unconnected | Correct |
| `U27001` pin 15 | Thermal pad to `GND` | Correct — internally shorted to ground |
| `PWR_FLAG` | On `HV_IN` | Right net: only driver is a passive diode cathode and `VS` is `power_in`. Exactly one. |
| Footprint | `Texas_HTSSOP-14-1EP_4.4x5mm_P0.65mm_EP3.4x5mm` | Matches the PWP package: 4.4 × 5 mm body, 6.4 mm lead span, 0.65 mm pitch |

**Three defects, fix before layout:**

| # | Defect | Fix |
| --- | --- | --- |
| 1 | **`R27005` pulls `~FAULT` to `GND`.** `~FAULT` is open-drain; the datasheet requires a pull-**up** "to match the microcontroller supply level". As wired the net idles low, so it reads as a permanent fault and never presents a valid high. | Move `R27005`'s ground end to **`+3V3_MCU`**, matching `R27002`/`R27003`. 10 kΩ is the right value. |
| 2 | **`HV_IN` is a plain local label**, so the board cannot reach it. This board needs it to place the TVS at the entry point. (It no longer needs a second tap there: `+3V3_MCU` comes from USB/pyControl, not from `HV_IN`.) | Promote `HV_IN` to a **hierarchical label**. Schematic-only — the net name does not change, so there is no PCB impact. |
| 3 | **`SNS` is a plain local label**, so the board cannot read the current sense at all. | Promote `SNS` to a **hierarchical label**. Leave `ILIM` local — that one is correct. Schematic-only, no PCB impact. |

The block's board-facing interface is currently only `+3V3_MCU`, `+36V`,
`ENABLE`, `GND`, `~{FAULT}`. It needs `HV_IN` and `SNS` as well.

**Three concerns, cheap to fix now:**

| # | Concern | Fix |
| --- | --- | --- |
| 4 | **`C27002` is 50 V on a 36 V rail** while `C27001` is 100 V. 1.4× margin; X7R in an 0402 at 72% of rated voltage loses most of its capacitance to DC bias; and the internal `V_DS` clamp can drive `VOUT` to roughly −43 V, which is 86% of a 50 V rating. Marginal rather than illegal, but inconsistent with `C27001`. | **`OW-PASS-GCM188R72A223KA37D`** — 22 nF 100 V X7R, stocked and already promoted. **Note it is 0603, not 0402, so this one does change the footprint and therefore the layout.** |
| 5 | ~~`+3V3_MCU` should be renamed `+3.3V`.~~ **Withdrawn.** The pull-ups on `DIAG_EN`, `LATCH` and `~FAULT` must reference the same rail the MCU uses, or the logic levels do not match and the MCU's clamps become a back-power path. Naming the rail by its domain is the right call and is more precise than `+3.3V`. | Keep `+3V3_MCU`. Only consequence: `5v_to_3v3_tps73733` emits `+3.3V`, so either label the board's rail `+3V3_MCU` too or tie the two at board level — and add a netclass pattern for whichever name wins. |
| 6 | **`VAA` is a misleading net name.** The TPS1HTC100-Q1 has no `VAA` pin — its pins are `GND`, `EN`, `DIAG_EN`, `~FAULT`, `LATCH`, `SNS`, `ILIM`, `VOUT`, `NC`, `VS`. It reads like a chip supply that does not exist. It is the raw connector node ahead of the reverse-polarity diode. | Rename to **`HV_RAW`** or `VIN_RAW`. Also affects netclass pattern matching. |

**ERC:** 32 violations, none of them defects. 13 `lib_symbol_issues` and 12
`footprint_link_issues` come from running `kicad-cli` outside the project's
library tables. The remaining 7 are the expected isolated-fragment set: 5
`pin_not_connected` for hierarchical labels with no parent sheet, 1
`power_pin_not_driven` on `GND` which the board supplies, and 1
`isolated_pin_label` on `ENABLE`.

### Notes For The Block's PCB Layout

- **Thermal vias: use `orb_weaver_smd:Texas_HTSSOP-14-1EP_4.4x5mm_P0.65mm_EP3.4x5mm_Mask3.155x3.255mm_ThermalVias_JLCPCB`.**
  The thermal *pad* is already correct in the stock footprint — 3.4 × 5 mm on
  `F.Cu`, flagged `pad_prop_heatsink`, tied to `GND`. What was missing is the via
  array, and the pad is both the heat path and the ground connection, so it needs
  one: the switch dissipates `½CV²` on every `+36V` turn-on.
  KiCad ships an official `..._ThermalVias` variant, but it **fails this project's
  DRU with 15 `drill_out_of_range` errors** — its drills are 0.2 mm against a
  `min_through_hole_diameter` of 0.3 mm. Enlarging the drill alone drops the
  annular ring to 0.10 mm, below the DRU's 0.18 mm PTH annular rule, so the pads
  have to grow too. The local variant in `kicad-libs/footprints/orb_weaver_smd.pretty`
  does that: **15 vias, 0.7 mm pad / 0.3 mm drill (0.20 mm annular), 1.1 mm x-pitch
  and 1.0 mm y-pitch** so the outer via pads stay inside the 5 mm pad. Verified
  DRC-clean against `mouse-joystick-pcb.kicad_dru`.
  Note the variant also brings a **2.7 × 4.9 mm `B.Cu` land** — keep bottom-side
  copper clear under the part so the vias have somewhere to dump heat.
  **Assigned at source, 2026-08-12.** `OW-PWR-TPS1HTC100QPWPRQ1` and catalog part
  `C41558366` now point at it in `kicad-libs/db/source/library_map.csv`,
  `parts.csv`, and `internal_parts.csv`, plus the symbol default in
  `symbols/orb_weaver_power.kicad_sym`. `make build-db` regenerated the SQLite and
  both tables report the new footprint. The `ki_fp_filters` wildcard already
  matched, so it was left alone.

  **Placed instances do not update themselves** — design blocks are copies. Run
  Update Symbols from Library, then refresh footprints, in each of:

  - `kicad-libs/design_blocks/.../hv_input_36V_terminal_2pos_5p08_protected.kicad_block/`
    — the one being routed now
  - `kicad-libs/design_blocks/.../hv_input_24V_barrel_jack_2p1x5p5_protected.kicad_block/`
  - `kicad-libs/examples/design_block_mining_project/` — both hv_input sheets
  - **`tmc51x0-driver-dev-pcb`** — it places the 24 V barrel-jack block, so it
    picks up thermal vias on its next update. Confirmed its `fp-lib-table` already
    carries `orb_weaver_smd`, so the footprint resolves. Re-run DRC there before
    fabrication.
- `VAA`, `HV_IN`, and `+36V` carry the full motor current through `D27001`
  (PowerDI-5, 15 A) and the switch. Wide pours, short loop, no necking.
- `C27001` sits right at the `VS` pins 12/13/14; `C27002` right at `VOUT`
  8/9/10.
- `R27006` (`ILIM`) and `R27007` (`SNS`) are small-signal. Keep them off the
  power path and reference them to quiet ground — `SNS` feeds an ADC.
- **Silkscreen the terminal block polarity: `J27001` pin 1 = `GND`, pin 2 =
  positive input.** This is the one that bites people.
- `D27001` is rated 50 V reverse against a 36 V rail — 1.4×. Fine here, but note
  it in the block description, because the block is advertised for reuse on
  "HV/VMOT entry rails" and at 48 V that margin is gone.

Neither 470 Ω nor 24.9 kΩ — the arithmetically ideal values — is stocked. 249 Ω
and 40 kΩ are, and both land in a better place than the ideal values would have.

Both capacitors are in the right places and neither should move: `C27001` on
`HV_IN` is the switch's `VS` bypass, `C27002` on `+36V` is the output bypass.

## The High-Side Switch Is A Reset Button

Decided 2026-08-13, and it is the organising principle for everything below.

The `TPS1HTC100-Q1` is not only inrush and fault protection. Its job is to let
the researcher **power-cycle every chip on the board to a known state without
unplugging anything**, while the MCU stays alive and reachable over USB or
pyControl. If the driver or the encoder wedges, firmware drops `HV_EN`, waits,
and raises it again; the researcher never touches a connector.

Three requirements fall straight out of that:

1. **Everything resettable hangs off the switched rail** — including the 5 V and
   3.3 V derived from it. Dropping `HV_EN` must drop all of it.
2. **The MCU does not.** It runs from USB `VBUS` or pyControl 5 V, so it survives
   the reset it is performing.
3. **The MCU must not back-power what it just switched off.** That is the entire
   job of `rp2040_gpio_isolation_sn74cb3q3245`: any MCU line that reaches a chip
   on the switched rail goes through the bus switch, and lines that do not —
   the pyControl UART above all — bypass it. See `docs/interface-map.md`.

## Rail Chain

```text
36 V in ─> hv_input_36V_terminal_2pos_5p08_protected
             │
             ├─ HV_IN (unswitched) ──> TVS, and the TPS1HTC100-Q1's own supply
             │
             └─ +36V_SW (switched by HV_EN) ─┬─> TMC5130A VS
                                             └─> hv_to_5v_tpsm365r6 ─> +5V_SW
                                                   ├─> TMC5130A VSA, VCC, 5VOUT
                                                   ├─> encoder supply (if 5 V)
                                                   ├─> DAC8563 VDD (rev 1)
                                                   └─> 5v_to_3v3_tps73733 #2 ─> +3V3_SW
                                                         ├─> TMC5130A VCC_IO
                                                         ├─> MAX6816 limit-switch debouncer
                                                         └─> encoder supply (if 3.3 V)

USB-C VBUS ──────────────|>|── D1 ──┬─> +5V_MCU ─> 5v_to_3v3_tps73733 #1 ─> +3V3_MCU
pyControl RJ-45 pin 6 ───|>|── D2 ──┘                                        ├─> RP2040
                                                                             ├─> SN74CB3Q3245 ×4 VCC
                                                                             ├─> input block DIAG_EN / LATCH / ~FAULT pull-ups
                                                                             └─> 5× SN74LVC125A (rev 1)
```

### Rail Names

| Net | Domain | Source | Dies when |
| --- | --- | --- | --- |
| `HV_IN` | unswitched | 36 V terminal, after the reverse diode | 36 V supply unplugged |
| `+36V_SW` | switched | `TPS1HTC100-Q1` output | `HV_EN` low |
| `+5V_SW` | switched | `TPSM365R6V5` from `+36V_SW` | `HV_EN` low |
| `+3V3_SW` | switched | `TPS73733` #2 from `+5V_SW` | `HV_EN` low |
| `+5V_MCU` | always-on | USB `VBUS` OR pyControl pin 6, two diodes | USB and pyControl both absent |
| `+3V3_MCU` | always-on | `TPS73733` #1 from `+5V_MCU` | USB and pyControl both absent |

Older passages in this document say `+5V` and `+3.3V` from before the split; read
those as `+5V_SW` and `+3V3_SW` unless the surrounding text is about the MCU.

**Two independent domains, and the split is the point.**

Everything the TMC5130A needs is downstream of the switch, so `VSA` never exceeds
`VS`, `VCC` never arrives after `VCC_IO`, and all three fall together when
`HV_EN` drops. The MCU sits on a rail the switch cannot reach, so it can drive
`ENABLE`, talk to pyControl, and report what it just did.

**The MCU rail is not fed from the 36 V chain at all.** That was previously an
open decision — "either a small always-on converter taps `HV_IN`, or the board
only boots with USB or pyControl present" — and it is now settled in favour of
the second. The consequence is explicit and accepted:

> **With only the 36 V supply connected, the board does not boot.** It needs USB
> or pyControl present. That is a usability property, not a safety one, and it
> buys a genuinely always-on MCU domain with no extra converter, no extra part on
> `HV_IN`, and no path by which a 36 V fault reaches the MCU.

Silkscreen it near the terminal block. A rig board that looks dead with its motor
supply plugged in will otherwise be reported as broken.

**The bus switch is powered from `+3V3_MCU`, not the switched rail.** It has to
be: the MCU must be able to isolate *before* dropping `HV_EN` and reconnect only
*after* the rails are confirmed up. Powering it from `+3V3_SW` would give
automatic isolation through the `SN74CB3Q3245`'s powered-off `Ioff` behaviour and
cost no GPIO, but it would also hand control of the sequencing to a rail ramp
instead of to firmware. Rejected deliberately; see the sequencing rule in
`docs/interface-map.md`.

| Stage | Block | Part | Range | Headroom at 36 V |
| --- | --- | --- | --- | --- |
| Input protection and switching | `hv_input_36V_terminal_2pos_5p08_protected` | `TPS1HTC100-Q1` | 6-60 V operating | comfortable |
| 36 V → 5 V | `hv_to_5v_tpsm365r6` | `TPSM365R6V5`, 600 mA | 3-65 V, 70 V transient | comfortable |
| 5 V → 3.3 V | `5v_to_3v3_tps73733` | `TPS73733`, 1 A LDO | — | comfortable |
| Motor bridge | `tmc5130` | `TMC5130A-TA` | **46 V operating, 49 V absolute** | **10 V** |

## 36 V Is The Tightest Constraint On The TMC5130A, Not On The Regulators

The two regulators are unbothered by 36 V. The driver is the part to watch, and
there are three distinct consequences.

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
it differs from both 24 V variants in exactly this way.

**Fit a TVS on `HV_IN`** — but understand that it protects the switch and the
buck, **not** the driver. The two jobs are separate and only one of them has a
TVS-shaped answer:

| Event | Exposed parts | Clamped by a 40 V TVS? |
| --- | --- | --- |
| Hot-plugging the terminal block | `TPS1HTC100-Q1` (70 V, 81 V transient) and `TPSM365R6V5` (65 V, 70 V transient) on `HV_IN`. The switch is **off**, so the TMC5130A is disconnected. | **Yes.** This is the dominant transient event and the TVS handles it. |
| Supply-side transient with the switch on | `TMC5130A` (49 V) as well | **No.** Clamp is ~64 V. Handled by bulk and layout instead. |
| Chopper ringing on `VS` | `TMC5130A` | No. Layout only. |
| Motor inductive turn-off | `TMC5130A`, plus the switch's own integrated `V_DS` clamp | No. Bulk absorbs it. |

The hot-plug case is why a TVS is needed on `HV_IN` and why it belongs *there*
rather than on `+36V_SW`. At hot-plug the high-side switch is off, so what sits
on `HV_IN` is the `TPS1HTC100-Q1`'s own `VS` pin and the reverse-polarity diode
— and, deliberately, **very little capacitance**, because the regulator chain now
taps post-switch. Cable inductance of a couple of µH ringing into a lightly
loaded node overshoots toward twice the supply, and at 36 V that reaches into the
60s of volts, close to the switch's 70 V rating with nothing local to damp it.

**Moving the buck behind the switch strengthened this argument rather than
weakening it.** The buck's 65 V rating is no longer exposed at hot-plug, which is
good, but the few µF of ceramic that used to sit on `HV_IN` and absorb some of
the ringing went with it. The TVS is now the only thing clamping that node.

Part choice:

| Part | Standoff | Conducts from | Clamp | Verdict |
| --- | --- | --- | --- | --- |
| `SMBJ40A` | 40 V | 44.4-49.1 V | ≤64.5 V @ 9.3 A, 600 W | **Preferred.** Order it. |
| `SMF48A` (stocked, `C1509577`, 120 on hand) | 48 V | ~53-59 V | 77.4 V @ 2.6 A, 200 W | **Usable now.** Stands off 36 V and holds `HV_IN` inside both parts' transient ratings at hot-plug currents. Prototype with this rather than waiting. |
| `SMBJ28A` (stocked) | 28 V | — | — | No. Would conduct at the 36 V working voltage. |

So: order `SMBJ40A`, and if the first boards need to go out before it arrives,
build with the stocked `SMF48A` and swap later. **This is not a fabrication
blocker either way** — it is one SMB/SMA footprint.

What separately protects the driver, since the TVS does not:

- Keep bulk electrolytic close to the driver's `VS` pins, not only at the input
  terminal, and keep the `VS`/`GND` loop small.
- Follow the datasheet's sense-resistor layout rules strictly. Sense-resistor
  stray inductance is named in the same footnote.
- **Put the bulk capacitance downstream of the high-side switch.** The switch is
  off when the connector is plugged in, so the classic hot-plug LC ring — cable
  inductance against bulk capacitance, which overshoots to roughly twice the
  supply voltage — never happens. The bulk is charged afterwards through the
  switch's soft-start instead. This is the single most important layout decision
  on the 36 V rail and it is worth more than any TVS.
- Do not disconnect the motor connector while the driver is energized. Say so in
  silkscreen and in the bring-up procedure.
- Measure it at Gate B rather than arguing about it.

### Why No TVS Protects The Driver

A TVS has to stand off the working rail and clamp below the protected part's
absolute maximum. For the driver, those two numbers do not leave room.

| Part on the 36 V rail | Absolute maximum | Protectable by a 40 V TVS? |
| --- | --- | --- |
| `TPS1HTC100-Q1` | 70 V continuous, **81 V transient (<100 µs)** | Yes |
| `TPSM365R6V5` | 65 V, 70 V transient | Yes |
| **`TMC5130A`** | **49 V** | **No** |

Standard SMBJ-class TVS parts clamp at roughly **1.6× their standoff voltage** at
rated peak pulse current. A 36 V rail at +5% supply tolerance is 37.8 V, so the
standoff has to be at least 40 V, which puts the clamp at about 64 V — 15 V above
the driver's absolute maximum.

Working the constraint backwards: for the clamp to land under 49 V, the standoff
must be under about 30 V, so the DC rail must be under about 29 V. **At 36 V it
is arithmetically impossible for a standard TVS to protect a 49 V part.**

An `SMBJ40A` does help the driver at very low surge energy, where it clamps near
its breakdown voltage rather than its rated clamp voltage. But its breakdown
spread is 44.4-49.1 V, so whether it conducts before or after the driver's
absolute maximum depends on which part came off the reel. Treat that as a bonus,
not as protection by design.

This is also why the 24 V variants of the input block are built the way they are:
they are passive, always-on, and carry an `SMBJ28A` clamping at 45.4 V, safely
under the driver's 49 V. At 24 V a TVS protects everything on the rail, so the
block needs nothing else. At 36 V it cannot, so the 36 V variant substitutes an
active switch with soft-start and current limit. **The two blocks are coherent
designs of different philosophies, not one with a missing part** — but the 36 V
one still wants a clamp on `HV_IN` for the switch and the buck, which is the part
its description does not tell you.

### If The Margin Turns Out To Be Too Thin

Measured overshoot at the `VS` pins at Gate B decides this. If it is
uncomfortable, in increasing order of cost:

1. More bulk closer to the driver, tighter loop, an RC snubber across `VS`/`GND`
   at the driver. Lay out a snubber footprint now so this is a populate decision,
   not a respin.
2. **Run the 36 V input block from a lower supply.** The `TPS1HTC100-Q1` works
   from 6 V and the `TPSM365R6V5` from 3 V, so the block is perfectly happy at
   24 V or 30 V — it is named for its intended rail, not limited to it. At 24 V
   the stocked `SMBJ28A` becomes usable and the whole problem disappears, while
   the smart switch, `HV_EN`, `HV_SNS`, current limit, and soft-start are all
   retained. **Check the block's `EN` divider and `ILIM` values against the lower
   input before doing this**, and rename the `+36V` net.
3. Accept 24 V and match the twin-axis board.

Option 2 is the escape hatch worth knowing about, because it costs a resistor
value change and a net rename rather than a new block or a new board.

### Is 36 V Actually Needed Here?

Worth asking once, now, rather than after the transient measurement.

The two reasons for 36 V were motor performance and Rev-1 brake-rail headroom.
**Only the first applies to this board** — there is no brake on it. And the
previous-generation rig ran the same class of joystick motor at 24 V and produced
the published work, so 24 V is demonstrably adequate for the application.

36 V is still defensible: a 0.67 A/phase stepper has high winding inductance, and
a higher rail means faster coil current rise and better torque at speed. But a
joystick is not a high-speed positioner, so the benefit is smaller here than the
number suggests.

The decision stands as 36 V. This section exists so that if the Gate B transient
measurement is bad, the fallback is already reasoned rather than a panic.

### 2. Supply Sequencing — And Why It Is `VSA`, Not `VCC`

The instinct that the TMC5130A must not be powered without `VM` is right, but the
offending pin is **`VSA`, not `VCC`**, and the datasheet's rule on `VCC` runs the
other way.

**`VCC` must come up EARLY, not late.** Pin 34's description:

> When using an external supply, make sure, that VCC comes up before or in
> parallel to 5VOUT or VCC_IO, whichever comes up later!

`5VOUT` is generated from `VSA`, so it rises with the motor rail. `VCC` present
while `VS` = 0 is therefore the **permitted** direction — `VCC` came up first. The
violation would be `5VOUT` or `VCC_IO` up first with `VCC` arriving later.

This board satisfies that automatically: `+5V` comes from the buck and `+3.3V`
comes from an LDO fed by that `+5V`, so `VCC` (5 V) is always up before `VCC_IO`
(3.3 V) by construction. Nothing to do.

**`VSA` is the real problem.** Absolute Maximum Ratings, chapter 29:

| Parameter | Symbol | Min | Max |
| --- | --- | --- | --- |
| Supply voltage operating with inductive load (`V_VS` ≥ `V_VSA`) | `V_VS`, `V_VSA` | −0.5 V | 49 V |
| **`VSA` when different from `VS`** | `V_VSA` | **−0.5 V** | **`V_VS` + 0.5 V** |

The `tmc5130` design block ties **`VSA` (pin 39) to `+5V`**, not to `VM`:

```text
/+5V   -> U4001.34 VCC,  U4001.39 VSA,  R4002 (10R) -> 5VOUT,  C4005 0.47uF
/5VOUT -> U4001.33,      R4002,          C4008 4.7uF
/VM    -> U4001.21 VS,   U4001.40 VS,   bulk + decoupling
```

Feeding the regulator chain **pre**-switch would leave `+5V` alive while `+36V`
is off. That would put `VSA` at 5 V with `VS` at 0 V — **4.5 V above the `V_VS` +
0.5 V absolute maximum** — every time the board sat with the motor rail disabled,
which is its boot state and its idle state. This is one of the two reasons the
board feeds the chain post-switch instead; see the rail chain above.

There is a second, milder problem even when the rail *is* on: Recommended
Operating Conditions give `V_VS`, `V_VSA` a **minimum of 5.5 V**, so `VSA` at
5.0 V is marginally below the recommended range regardless of `VS`.

**`VSA` stays on the external 5 V, and the external 5 V is switched with `VM`.**
Tying `VSA` to `VM` would satisfy the constraint but throws away the thermal
benefit the external 5 V exists for, and that benefit is real:

- The datasheet explicitly sanctions a lower `VSA` supply for this purpose:
  "To minimize linear voltage regulator power dissipation of the internal 5 V
  voltage regulator in applications where VM is high, a different (lower) supply
  voltage can be used for VSA, if available" — its example is a 12 V `VSA` on a
  24 V motor rail, cutting regulator dissipation to about 37%.
- Taking `VSA` to 5 V goes further and bypasses the regulator outright, which is
  why the block also feeds `5VOUT` from `+5V` through `R4002`.
- The magnitude matters. The datasheet warns the internal regulator "will
  contribute with up to 1 W" at 46 V. Even with `VCC` fed externally, `VSA` on
  `VM` would leave the regulator carrying its analog load plus whatever flows
  through `R4002`'s 10 Ω — a few hundred mW in a package already dissipating
  roughly 0.45 W of bridge `I²R` at 0.67 A/phase. Doubling the driver's
  dissipation to save a load switch is a bad trade.

Note `VSA` = 5.0 V is marginally below the 5.5 V Recommended Operating minimum
for `V_VS`/`V_VSA`. Since the regulator is fully bypassed this is cosmetic, but
record it as a deliberate deviation rather than an oversight.

### Consequence: `VCC_IO` Cannot Be The Always-On MCU Rail

This is the part that is easy to miss. The same pin-34 note cuts both ways: if the
TMC's `VCC_IO` sits on an always-on 3.3 V rail while `VCC` is switched, then `VCC`
arrives **after** `VCC_IO` — the prohibited order.

So switching `+5V` with `+36V` forces the TMC's `VCC_IO` to be switched too, which
means **two 3.3 V domains and therefore two `5v_to_3v3_tps73733` instances**:

| Rail | Source | Powers |
| --- | --- | --- |
| `+3V3_MCU` | Always on, from the ORed USB / pyControl 5 V | RP2040, the four `SN74CB3Q3245` bus switches, the input block's `DIAG_EN`/`LATCH`/`~FAULT` pull-ups, instrumentation buffers (rev 1) |
| `+3V3_SW` | Downstream of the switched `+5V_SW` | TMC5130A `VCC_IO`, the MAX6816 debouncer, encoder supply if 3.3 V |

Far from being a nuisance, this is what makes the switch a usable reset: the
TMC's three supplies rise and fall together, so the sequencing rules hold by
construction in both directions and there is no ordering logic to get wrong.

**It also dissolves an old blocking question.** "Whether the TMC5130A tolerates
`VCC_IO` present with `VCC` and `VS` absent" no longer needs an answer, because
that state cannot occur — all three come from `+36V_SW`.

One consequence remains, and it now has a real mechanism rather than a mitigation:

- **MCU outputs would otherwise drive TMC digital inputs whose `VCC_IO` is 0 V**
  whenever the motor rail is off, which is the normal idle state of this board.
  Series resistors are a backstop, not a solution. The solution is
  `rp2040_gpio_isolation_sn74cb3q3245`: every MCU line reaching a chip on the
  switched rail passes through a `SN74CB3Q3245` channel that is high-Z until
  firmware enables it, and high-Z again before firmware drops `HV_EN`. Keep the
  series resistors anyway — they cost nothing and they cover the window where
  firmware gets the order wrong.

### Turn-On Ordering Comes Free If The Buck Is Fed Post-Switch

Feed `hv_to_5v_tpsm365r6` from the **switched `+36V`**, not from `HV_IN`. Then all
three orderings are satisfied by construction with no sequencing logic:

| Requirement | Why it holds |
| --- | --- |
| `VSA` ≤ `VS` + 0.5 V | `+36V` rises first; the buck cannot output before its input |
| `VCC` before or with `VCC_IO` | The 3.3 V LDO is downstream of the `+5V` buck |
| `VSA`, `VCC` never up with `VS` = 0 | Both derive from `+36V` |

**This reverses the earlier recommendation in this document to feed the regulator
chain pre-switch.** That recommendation existed so the MCU could boot and drive
`ENABLE`; the separate always-on `+3V3_MCU` rail now does that job instead. The
underlying warning still stands: *something* must power the MCU independently of
the switch, or the board cannot enable its own motor supply.

Do **not** switch `+3V3_MCU`. The MCU runs on it and drives `ENABLE`, so
switching it off is a deadlock.

Note also that `R4002` in the `tmc5130` block is 10 Ω where the datasheet
recommends **2.2 or 3.3 Ω** between `VCC` and `5VOUT`.

### 3. Internal 5 V Regulator Dissipation

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

## Multiple Logic Power Sources

**Two** sources feed the MCU domain: USB-C `VBUS` and pyControl RJ-45 pin 6,
diode-ORed so the MCU runs from whichever is present. The onboard `TPSM365R6V5`
is deliberately **not** one of them — it lives on the switched rail, which is the
thing the MCU has to survive switching off.

**pyControl pin 6 is 5 V, confirmed on two independent designs.** Read out of the
reference design's own netlist — in
`~/Repositories/github/syringe-pump/ecad/module_pycontrol.kicad_sch` the RJ-45
pin 6 net is `5VDC` and pin 8 is `Vmotor` at 12 V — and confirmed again from the
host side in `~/Repositories/github/pycontrol-h7-breakout` (see below). So both
ORed sources are nominal 5 V and the OR happens at 5 V, upstream of the MCU's own
LDO. There is no 3.3 V pin on the port to worry about.

**The current budget is now known at the source, and it comes with a hazard.**
See [What Pin 6 Can Actually Supply](#what-pin-6-can-actually-supply) immediately
below. The short version: 1.0 A shared with everything else in the rig *including
the pyControl controller's own logic rail*, with no per-port fuse — so **this
board must fuse its own pin 6 branch.** USB-only operation is unaffected either
way.

### What Pin 6 Can Actually Supply

Traced from `~/Repositories/github/pycontrol-h7-breakout` PCB v0.7 by netlist
export on 2026-08-14. This resolves the third open decision in this document and
the corresponding Gate A row. Full detail in `docs/pycontrol-port-pinout.md`.

```text
12 V barrel in ──> SW1 ──> +12V ──┬──> RECOM R-78E5.0-1.0  ──> +5V ──┬──> 10× RJ-45 pin 6
                                  │      (5 V, 1.0 A)                ├──> J8 pin 2 (16-pos terminal block)
                                  ├──> 10× RJ-45 pin 8               └──> U2 AMS1117-3.3 ──> the breakout's
                                  └──> 3× TBD62083APG COM                                    own 3.3 V rail
```

| Fact | Value |
| --- | --- |
| Port 5 V source | `U1`, RECOM `R-78E5.0-1.0` — **5 V, 1.0 A total** |
| Shared by | all 10 behavior ports' pin 6, the 16-position terminal block, **and `U2`, the `AMS1117-3.3` that makes the controller's own 3.3 V** |
| Per-port fuse | **none** — `+5V` runs straight from the module to every pin 6 |

The `AMS1117` is **linear**, so every milliamp the controller's 3.3 V rail draws
is a milliamp off the same 5 V budget. An STM32H743 at 480 MHz with 32 MB of QSPI
flash and indicator LEDs is perhaps 200-400 mA, leaving roughly **600-800 mA** for
ten ports plus the terminal block. The 1.0 A ceiling is firm; that split is the
estimate still worth measuring.

Against this board's ~100 mA MCU domain:

| Scenario | Draw | Verdict |
| --- | --- | --- |
| One board, pyControl-only | ~100 mA | Comfortable |
| Two boards in a rig, pyControl-only | ~200 mA | Fits, but a quarter to a third of the whole breakout's 5 V budget for two peripherals |
| Either, with a fault or inrush on this board | unbounded | **Can brown out the `AMS1117` and reset the pyControl controller mid-experiment** |

That third row is the new finding. The board's supply and the experiment
controller's own logic supply are the same 1 A rail, with nothing in between.

**Requirement: a resettable polyfuse on the pin 6 branch, holding roughly
250-500 mA, upstream of `D2`.** It confines a fault on this board to this board.

It fails in the right direction, which is why it is cheap insurance rather than a
new failure mode: if the polyfuse trips, `D2` simply stops conducting and the
board falls back to USB power, or goes dark if USB is absent. Nothing is damaged
and nothing is back-fed — the same fail-safe behavior already described for a
starved pyControl branch.

#### No Fuse Of Any Kind Is In The Parts Database

Checked 2026-08-14: `db/source/internal_parts.csv` and `parts.csv` contain **zero**
fuses, polyfuses, or PPTCs. So this is a new internal part plus a vendor mapping,
not a value change — unlike every other edit this document recommends.

**That must not hold up a fab order.** Use the same pattern this document already
applies to the `HV_IN` TVS and the `VS` snubber — lay out the footprint, populate
a stocked stand-in, make the protection a populate decision rather than a respin:

| Rev 0 | Later |
| --- | --- |
| **1206 footprint**, populated with a stocked 1206 resistor as a jumper — `OW-PASS-RL1206FR-070R36L` (0.36 Ω, 250 mW; 54 mV and 8 mW at 150 mA) | Swap in a 1206 PPTC once one is added to the catalog. No layout change |

1206 is the choice because it is the most widely available PPTC size; a 0603 or
0805 footprint would narrow the options later for no gain now. **The position must
be populated in Rev 0** — leaving it empty opens the pyControl branch entirely and
the board goes dark whenever USB is absent, which is the operating mode this whole
arrangement exists to support.

Do **not** read the stand-in as protection. A 0.36 Ω series resistor limits
nothing at these voltages; it is a jumper that happens to be stocked in the right
package. Until a PPTC is fitted, the hazard above stands, and Gate B's
"pyControl-only, USB absent" test should be run with the controller's 5 V rail on
a scope.

**Consequence for the load budget below:** size the MCU domain to stay well under
the polyfuse hold current, not merely under 1.0 A. That is the binding number now.

**Reinforces "keep USB as the normal power path."** pyControl-only was always
intended for reaching a board whose switched domain is deliberately off, not as
the everyday supply. This gives that a second, independent reason.

### Do Not OR Onto `+5V_SW`

Under the two-domain split this is now structurally impossible rather than merely
inadvisable — the ORed node and `+5V_SW` are different nets that never meet. The
reasoning is kept because it is *why* they are different nets, and because the
obvious "simplification" of merging them would reintroduce it.

`+5V_SW` has consumers that need a real, in-spec 5 V:

| Consumer | Requirement |
| --- | --- |
| `DAC8563` `VDD` | 5 V, because full-scale output is `VDD`. A 4.6 V rail silently makes the "0-5 V" output a 0-4.6 V output. |
| `TMC5130A` `VCC` | **4.6 V to 5.25 V** operating range, per rev 1.21 chapter 30 |
| Encoder, if 5 V | Per its datasheet |

USB `VBUS` is 4.75-5.25 V at the source and sags further over the cable — call it
4.4-5.25 V at the connector. Subtract a Schottky drop of 0.3-0.4 V and the ORed
rail is **4.0-4.9 V**.

That is out of spec for the TMC5130A's `VCC` and it quietly truncates the analog
angle output, which is this board's headline deliverable. A researcher would see
a full-scale output of 4.6 V instead of 5.0 V and have no indication why. **This
is the trap in the obvious implementation.**

### OR The Two Host Sources At `+5V_MCU`

Both sources are 5 V, so the OR is a plain two-diode wired-OR feeding the MCU
domain's own LDO. The `TPS73733` regulates away both the diode drop and the
difference between sources, and it only needs its input above roughly 3.8 V.

```text
36 V in ─[reverse diode]─[TPS1HTC100 switch]─ +36V_SW ─┬─> TMC5130A VS
                                                       └─> TPSM365R6V5 ─> +5V_SW ─> TMC VCC, encoder, DAC (rev 1)
                                                                             │
                                                                             └─> TPS73733 #2 ─> +3V3_SW ─> TMC VCC_IO, MAX6816

USB-C VBUS ──────────────|>|── D1 ──┬──> +5V_MCU ──> TPS73733 #1 ──> +3V3_MCU
pyControl RJ-45 pin 6 ───|>|── D2 ──┘
```

`+5V_SW` stays single-sourced and in spec. `+5V_MCU` is the ORed node and feeds
only the MCU domain's LDO. **The two 5 V rails never touch.**

Notes:

- **Diodes:** Schottky, low `Vf` at 150-250 mA. 20-30 V reverse rating is ample.
  A P-FET ideal-diode arrangement is overkill for a logic rail at this current.
  Stocked candidate: `OW-MISC-MBR120VLSFT1G` (`D_SCHOTTKY_20V_1A`, SOD-123FL,
  300 mV at 1 A, so well under 200 mV at this load). `OW-MISC-NSR20F40NXT5G`
  (40 V, 2 A, 0603) is the smaller option if area is tight.
- **Priority is undefined and that is fine.** With plain diodes the highest
  source wins, sources sag under load, and two nearly-equal sources may share
  unpredictably. Behind an LDO on a logic rail this has no consequence. Do not
  build a priority mux to fix a non-problem.
- **The diodes are what stop back-powering.** They prevent the board from
  feeding current into the USB host or into pyControl, and they prevent USB from
  powering pyControl through the board. Check the orientation deliberately — it
  is the entire reason the diodes are there.
- **Both branches are populated.** The pyControl branch is no longer optional:
  it is one of only two ways to power this board, and powering the board from
  pyControl with USB unplugged and the 36 V rail off is an explicitly wanted
  operating mode. What remains conditional is whether the port can actually
  supply the current — measure it.
- **Polyfuse on the pyControl branch, ~250-500 mA hold, upstream of `D2`.** Not
  on the USB branch — a USB host already current-limits and will simply drop the
  port. pyControl does not: its 5 V has no per-port protection and shares a
  regulator with the controller's own logic. See
  [What Pin 6 Can Actually Supply](#what-pin-6-can-actually-supply).
- Each ORed source is a power-input net and needs exactly one `PWR_FLAG`. The
  `usb2` block already carries one (`#FLG011001`) on `VBUS`, pre-diode; the 36 V
  block carries one. Add one for the RJ-45 5 V branch.
- **`+5V_MCU` itself needs a `PWR_FLAG`, at board level.** Every driver on it is
  a diode cathode — passive — and its only consumer is the LDO's `power_in`, so
  ERC reports `power_pin_not_driven` without one. It must **not** live inside
  either source block: two blocks each carrying a flag would put two `power_out`
  pins on one net and ERC would report a power-output conflict.
- Never tie `VBUS` directly to `+5V_SW`.

### MCU Alive, Switched Rails Dead — The Normal Idle State

USB-only or pyControl-only operation puts the board in a state the earlier
architecture treated as an edge case: **the MCU is running at 3.3 V while
`+36V_SW`, `+5V_SW`, and `+3V3_SW` are all at 0 V.**

Under the reset-button architecture this is no longer an edge case. It is the
board's **normal idle state**, reached three ways:

| How | Frequency |
| --- | --- |
| 36 V supply not connected | Bench and firmware work |
| 36 V connected, `HV_EN` low at boot | Every power-up — the block pulls `ENABLE` low |
| 36 V connected, firmware deliberately cycling `HV_EN` | Every recovery from a wedged chip |

In that state, MCU outputs would drive into parts whose supply is 0 V,
forward-biasing their input ESD clamps and back-powering dead rails through them.
Affected: every TMC5130A digital input, the MAX6816, the encoder path if the
encoder is supplied from a switched rail, and the DAC control lines in rev 1.

**The primary mechanism is the GPIO isolation bus switch**, not series
resistors. `rp2040_gpio_isolation_sn74cb3q3245` puts a `SN74CB3Q3245` channel in
every MCU line that reaches the switched domain; disabled, those channels are
high-Z and no clamp current flows regardless of what firmware does with the pin.
The bus switch runs from `+3V3_MCU` so it is controllable in exactly the state
that needs controlling.

Three supporting measures, and use all of them:

1. **Sequencing.** Isolate before switching off, reconnect only after the rails
   are confirmed up. Firmware rule and ordering in `docs/interface-map.md`.
2. **Series resistors on every 3.3 V line that crosses into the switched
   domain.** Cheap backstop covering the window where firmware gets the order
   wrong, or where the bus switch itself fails. They cost nothing; fit them.
3. **A `+5V_SW` presence sense on `GP26` (`ADC0`)** through a divider, so
   firmware can confirm the switched domain is actually up before enabling the
   bus, refuse `ARM` with a meaningful reason when it is not, and report it.
   `GP26` therefore **bypasses the bus switch** — sensing the rail through the
   thing you are trying to decide whether to enable would be circular.

**Two open questions this architecture closed.** Whether the `TMC5130A` tolerates
`VCC_IO` present with `VCC` and `VS` absent no longer matters — all three are on
`+36V_SW` and fall together. And the dual-supply level translator that was one
candidate fix for the DAC case is now needed only if the DAC's own `VIH` demands
it, which is a rev 1 question.

### Taking pyControl's 5 V Is No Longer Optional

**Reversed 2026-08-13. Populate both diodes.**

The earlier recommendation was to lay out the pyControl 5 V branch and leave it
unpopulated, on the grounds that USB alone delivers the whole development
benefit. That reasoning assumed the board had an always-on rail of its own. It
does not: `+3V3_MCU` comes from USB or pyControl and from nowhere else, so an
unpopulated pyControl branch means **the board is dark whenever USB is
unplugged**, no matter what else is connected.

Being reachable from pyControl with USB absent and the motor rail off is an
explicitly wanted operating mode — it is how the researcher talks to a board
that is deliberately powered down. So both diodes go in.

The objections were real and survive as verification items rather than as reasons
not to fit it:

- ~~The port's 5 V current budget is **unknown**~~ — **answered 2026-08-14: a
  shared 1.0 A**, and the controller's own 3.3 V regulator is one of the loads on
  it. See [What Pin 6 Can Actually Supply](#what-pin-6-can-actually-supply). This
  board's ~100 mA fits comfortably, and two boards in a rig still fit; what the
  finding changed is not the feasibility but the **failure mode** — with no
  per-port fuse, a fault here can reset the experiment controller. Hence the
  polyfuse. Still measure the controller's own draw at Gate A to know the true
  spare fraction.
- It adds a second ground path between pyControl and the board, which interacts
  with the grounding-topology decision that is still open.
- It adds a power state to test at Gate B: "board powered by pyControl only,
  USB absent, `HV_EN` low". That is now a required test, not an optional one.
- **New at Gate B:** confirm the polyfuse does not trip on the MCU domain's
  cold-start inrush. A polyfuse sized near the operating current is the classic
  way to build an intermittent board.

If the spare budget turns out to be too small, the fallback is USB-only
operation with the pyControl branch fitted but starved — which fails safe, since
the diode simply never conducts. The polyfuse tripping produces the same
behavior. Nothing about the layout changes.

### USB ESD Protection Is Missing And Should Be Added

Netlist export of the `usb2` block, 2026-08-12, shows it contains **only** the
USB-C receptacle and two 5.1 kΩ `CC1`/`CC2` `Rd` pulldowns:

```text
J11001 (USB-C) ── VBUS, GND, USB_D+, USB_D-
R11001 5.1k ── CC1 to GND
R11002 5.1k ── CC2 to GND
SBU1, SBU2, SHIELD S1/S2 ── unconnected
```

**No ESD protection.** The 27 Ω `D+`/`D-` series resistors RP2040 requires are
*not* missing — they live in the `rp2040` block as `R10001`/`R10002`, between the
chip's `D+`/`D-` and the block's `USB_D+`/`USB_D-` boundary labels. That part is
covered; the block description's mention of series resistors refers to those.

Add ESD protection. It matters more on this board than it would otherwise,
because **`VBUS` is now a power source** feeding the diode-OR into the logic rail,
and the USBLC6 clamps `VBUS` as well as both data lines.

| Part | Package | Status |
| --- | --- | --- |
| **`USBLC6-2P6`** | SOT-666-6 | **Stocked (`C2827693`, 20 on hand) and already in the parts database** — symbol `Power_Protection:USBLC6-2P6`, footprint `Package_TO_SOT_SMD:SOT-666`. Placeable now. |
| `USBLC6-2SC6` | SOT-23-6 | Same die, larger and far easier to hand-solder. Not stocked, **not in the parts database** — would need an internal part and vendor mapping added. |

**Recommendation: use the stocked `USBLC6-2P6`.** No purchase, no database work.
Buy `USBLC6-2SC6` only if these boards will be hand-assembled or reworked —
SOT-666 is 1.6 × 1.2 mm on 0.5 mm pitch, which is unpleasant with an iron, while
SOT-23-6 is trivial. If JLCPCB assembles, the package makes no difference. Twenty
pieces is also thin if more than a handful of boards are planned.

Placement details that are easy to get wrong:

- Put it on the **connector side** of the 27 Ω series resistors, on `USB_D+`/
  `USB_D-`, as close to the receptacle as routing allows. Between the resistors
  and the RP2040 it protects nothing.
- 0.35 pF of added capacitance is irrelevant for USB 2.0 full speed.
- The receptacle's `SHIELD` pins are unconnected in the block. Decide the shield
  grounding — direct to `GND`, or through an RC — since it is an ESD path in its
  own right. Note this interacts with the RJ-45 shield decision.

### Current Budget For The ORed Rail

The MCU domain is the only thing on it: RP2040, the four `SN74CB3Q3245` bus
switches, the input block's pull-ups, and the five `SN74LVC125A` buffers in
rev 1. Roughly **100-150 mA typical**, up to ~250 mA with the rev 1 buffers
switching. Rev 0 without the buffers is nearer 100 mA.

Comfortable on USB's 500 mA default. The `usb2` block presents `Rd` pulldowns
only, so assume default USB power rather than a negotiated higher current.

**On pyControl pin 6 it is comfortable but not free.** The port supplies a shared
1.0 A with the controller's own logic rail as one of the consumers, so ~100 mA is
a small fraction and two boards in a rig still fit — but there is no per-port
fuse, so the polyfuse recommended above is what keeps a fault on this board from
propagating. Nothing on the switched domain draws from this rail, which is what
keeps the number small enough to be plausible on a shared port supply in the
first place.

**Size the MCU domain against the polyfuse hold current, not against 1.0 A.**
At ~100 mA typical in Rev 0 and ~250 mA with the rev 1 buffers switching, a
500 mA hold leaves room for both; a 250 mA hold does not leave much for rev 1.
Pick the value with rev 1 in mind, since changing it later is a rework on an
assembled board.

## Load Budget

Fill in measured values at Gate B. Estimates for sizing only.

| Domain | Rail | Load | Estimate |
| --- | --- | --- | --- |
| switched | `+36V_SW` | Motor, 0.67 A/phase RMS, two phases | Sized from the identified motor; see below |
| switched | `+36V_SW` | TMC5130A quiescent and gate drive | tens of mA |
| switched | `+5V_SW` | TMC5130A `VCC` | ~20-30 mA |
| switched | `+5V_SW` | Encoder, if 5 V | **Unknown — the encoder part is not identified.** A Broadcom `HEDR-5421` class part draws 40-85 mA |
| switched | `+5V_SW` | DAC8563 `VDD` (rev 1) | ~1 mA |
| switched | `+5V_SW` | Level translator, if fitted (rev 1) | few mA |
| switched | `+3V3_SW` | TMC5130A `VCC_IO` | few mA |
| switched | `+3V3_SW` | MAX6816 debouncer | tens of µA |
| switched | `+3V3_SW` | Differential encoder receiver, if fitted | ~10 mA |
| always-on | `+3V3_MCU` | RP2040 | ~50 mA |
| always-on | `+3V3_MCU` | 4× `SN74CB3Q3245` | µA static; charge transfer only when switching |
| always-on | `+3V3_MCU` | Input block `DIAG_EN`/`LATCH`/`~FAULT` pull-ups | < 1 mA |
| always-on | `+3V3_MCU` | 5× `SN74LVC125A` (rev 1) | few mA static, more when switching |

The 5 V rail's 600 mA is comfortable unless the encoder is unusually hungry.

**Read the table by domain, not by voltage.** The `+5V_SW`/`+3V3_SW` column is
what the 36 V chain must supply and what disappears when `HV_EN` drops; the
`+3V3_MCU` column is what USB or pyControl must supply continuously. Sizing them
against the wrong source is the mistake this split exists to prevent.
**Check the encoder's supply current once the part is identified** — it is the
only line item here that could plausibly matter.

The 3.3 V LDO dissipates `(5 - 3.3) × I`. At 300 mA that is 0.51 W, which the
`TPS73733` in its `kicad-libs` footprint handles, but confirm the thermal pad
arrangement rather than assuming.

**Motor supply current is an open item** until the motor is identified. Size
input protection, bulk capacitance, and the `ILIM` resistor from the real part.
One motor rather than two means roughly half the twin board's supply current,
which is one more reason this board is easier.

## Audit Of The 36 V Input Block

Traced from `kicad-cli sch export netlist` on the block, 2026-08-12, against
`tps1htc100-q1.pdf`. The block has never been placed on a board, and this is what
that shows.

### Actual Topology

```text
J27001.2 ── VAA ── D27001 (SBRT15U50SP5, anode→cathode) ── HV_IN ──┬── U27001 VS (12,13,14)
                                                                   └── C27001 220nF ── GND
J27001.1 ── GND

U27001 VOUT (8,9,10) ── +36V ──┬── C27002 22nF ── GND
                               └── (board load)

ENABLE ──R27001 10k──┬── U27001 EN (2)        DIAG_EN (3)  no-connect
                     └──R27002 10k── GND      ~FAULT  (4)  no-connect
                                              LATCH   (5)  no-connect
U27001 ILIM (7) ──R27003 10k── GND            NC     (11)  no-connect
U27001 SNS  (6) ──R27004  1k── GND
```

So: `VAA` is the raw connector node, `HV_IN` is post-reverse-polarity-diode, and
`+36V` is the switched output.

### The Capacitors Are Correct Where They Are

- **`C27001` 220 nF sits on `HV_IN`, at the switch's `VS` pins. Leave it there.**
  It is the switch IC's supply bypass, not bulk. Moving it to `+36V` would leave
  `VS` unbypassed.
- **`C27002` 22 nF sits on `+36V`, the switch output. Leave it there too.** The
  switch has a fixed internal output slew rate, `SRR` = 0.47 V/µs typical, so
  22 nF draws only about 10 mA during turn-on — it cannot interfere with the
  soft-start ramp.

Neither is bulk, and neither should move. The "bulk downstream of the switch"
recommendation elsewhere in this document is about **additional** bulk
electrolytic placed near the TMC5130A's `VS` pins, not about relocating these
ceramics.

### How Much Bulk Can Go On `+36V`

Bounded, and worth knowing before choosing a capacitor.

Above about 10 µF the ramp stops being slew-rate-limited and becomes
current-limited, so the switch dissipates the charging energy:

```
E_FET ≈ ½ · C · V²  =  0.65 mJ per µF at 36 V
P_avg  ≈ V · I_LIM / 2  ≈ 36 W at the recommended 2 A limit, 95 W at the block's present 5.3 A
```

Note that **lowering `ILIM` does not reduce the energy** — it only stretches the
same joules over a longer time. The datasheet is explicit that "the system must
be designed so that the TPS1HTC100-Q1 does not hit thermal shutdown while
charging the capacitor," and refers to TI's *How to Drive Resistive, Inductive,
Capacitive, and Lighting Loads* application note for the thermal model rather
than giving a closed-form limit.

Practical guidance: **tens of µF, not hundreds.** A 470 µF electrolytic on `+36V`
is 305 mJ into an HTSSOP-14 and will likely trip thermal shutdown. Verify a clean
`HV_EN` turn-on into the final capacitance at Gate B, from a cold and a hot
start.

### Four Things The Block Gets Wrong Or Leaves Undone

| # | Issue | Fix |
| --- | --- | --- |
| 1 | **`R27001`/`R27002` form a ÷2 divider on `EN`.** Both are 10 k, so a 3.3 V GPIO presents **1.65 V** at `EN` against a `VIH` of **1.5 V max** — 150 mV of margin, less at low `VDD` and with resistor tolerance. | Change `R27001` to **1 kΩ**, keeping `R27002` at 10 k. `EN` becomes 3.0 V. Keeps the external pulldown, which is genuinely wanted because RP2040 GPIOs are inputs with pulls disabled at reset. **Done 2026-08-12.** |
| 2 | **`DIAG_EN` is left no-connect with a 200-500 kΩ internal pulldown, so diagnostics are off.** Table 4-2: "With DIAG_EN unused, the analog sense, open-load, and short-to-battery diagnostics are not available." Every `ISNS` specification is conditioned on `VEN = VDIAG_EN = 5V`. **With the block as-is, the `SNS` output does nothing and `HV_SNS` on `GP28` reads zero.** | Tie `DIAG_EN` to `+3.3V` through a 1 kΩ `RPROT`. Needs no GPIO. Safe with `VS` absent — see below. |
| 3 | **`~FAULT` is left no-connect.** It is the open-drain global fault output for overload, short-circuit, and thermal shutdown — thrown away on a board that has spare pins. | Route to **`GP29`** with a pull-up to `+3.3V`. The datasheet notes an external pull-up is required to match the MCU supply. |
| 4 | **`LATCH` is left no-connect**, so the device **auto-retries every 2 ms** after a fault. | Tie to `+3.3V` through a 1 kΩ `RPROT` for latch-off. See below. |

Items 2 and 3 are the ones that matter most: as placed, the block gives no load
current reading and no fault signal, which is most of what the smart switch was
chosen for.

### Driving `DIAG_EN` And `LATCH` With `VS` Unpowered Is Fine

The board can run from USB with the 36 V supply absent, so these pins will sit at
3.3 V while the switch's `VS` is at 0 V. That is in spec, not merely survivable:

| Pin | Recommended operating | Absolute max |
| --- | --- | --- |
| `VEN`, `VDIAG_EN`, `VLATCH`, `VSNS`, `VFAULT` | −1 V to **5.5 V** | −1 V to 7 V |
| `VS` | 6 V to 60 V | −0.7 V to 70 V |

The Recommended Operating Conditions footnote is the key line: "**All operating
voltage conditions are measured with respect to device GND.**" The logic pins are
referenced to `GND`, not to `VS`, and they have their own independent limits. The
part also lists "loss of GND, loss of supply protection" as a feature.

The only current path is the pin's internal pulldown — 200-500 kΩ on `DIAG_EN`,
0.7-1.3 MΩ on `LATCH` — so about 10 µA at 3.3 V, matching the spec'd
`IIH, DIAG_EN` of 14 µA at 5 V. Nothing is injected into the unpowered `VS`
domain.

**This is unavoidable anyway:** `GP19` drives `EN` whenever the MCU is alive,
including with the 36 V supply absent. Any USB-only operation already applies
3.3 V logic to this IC with `VS` at 0 V. `DIAG_EN` and `LATCH` add nothing new.

**Do not confuse this with the `DAC8563` back-powering hazard** described later in
this document. They look similar and are not. TI specifies these pins against
`GND` with their own limits, which is a deliberate design choice for a switch that
must survive losing its supply. The `DAC8563`'s digital inputs are specified
relative to *its* `VDD`, so driving them with `VDD` at 0 V forward-biases clamps
into a dead rail. The difference is what the datasheet promises, not the topology.

Use a 1 kΩ series `RPROT` on both pins regardless. Table 4-2 names `RPROT` for
exactly these two pins.

### `ILIM` Is One Resistor To Ground — Just Change Its Value

`ILIM` takes a single resistor to `GND` and nothing else. No divider is involved;
that recommendation was about the `SNS` pin, which is a different pin with a
different job. The datasheet is explicit that "ILIM pin must be connected with
device GND", and Table 4-2 warns that **leaving it floating selects the internal
default and "is considered a fault state for the device."**

`R27003` = 10 kΩ today. The datasheet tabulates the resulting limit directly:

| `R_ILIM` | `I_CL` min | typ | max |
| --- | --- | --- | --- |
| **10 kΩ (present)** | 4.0 A | **5.3 A** | 6.3 A |
| 16.7 kΩ | 2.3 A | 3.0 A | 3.5 A |
| **25 kΩ (recommended)** | 1.5 A | **1.96 A** | 2.3 A |
| 50 kΩ | 0.73 A | 0.92 A | 1.11 A |
| Open or GND | 6.1 A | 7.3 A | 8.6 A |

The block's present setting is therefore **5.3 A typical, up to 6.3 A** — higher
than the 4.6 A quoted in an earlier draft of this document, which used the wrong
`K_CL` row. The table above is authoritative.

**24.9 kΩ is not stocked.** Two stocked, already-promoted options:

| Choice | `R_ILIM` | `I_CL` typ | Internal part |
| --- | --- | --- | --- |
| **Starting point** | 40 kΩ, one 0603 resistor | **~1.2 A** | `OW-PASS-SCR0603F40K` |
| More headroom | 2 × 49.9 kΩ in parallel = 24.95 kΩ | **1.96 A** (tabulated row) | `OW-PASS-RC0402FR-0749K9L` ×2 |
| Tightest | 49.9 kΩ, one 0402 resistor | 0.92 A | same |

**Use 40 kΩ.** A 0.67 A/phase stepper holding position draws roughly 0.2-0.3 A
from a 36 V rail — coil `I²R` plus driver losses divided by 36 V — so ~1.2 A is
around 4× headroom over normal operation while still being a limit worth having.
The parallel-49.9 kΩ option is there if the identified motor's acceleration
current turns out higher than that.

Whichever is chosen must also pass the inrush into the `+36V` bulk. At 1.2 A,
charging 22 µF to 36 V takes 0.66 ms and puts 14 mJ into the switch — untroubling.

Two constraints on going lower:

- The limit must pass the inrush into whatever bulk sits on `+36V`, since
  charging is current-limited above ~10 µF.
- Hitting the limit is an overload event and will assert `~FAULT`, so a limit set
  close to normal operating current produces nuisance faults.

Headroom for transients is built in: at `R_ILIM` = 25 kΩ, `I_CL_LINPK` is
**1.5 × I_CL**, so brief peaks to about 2.9 A are tolerated.

Finalise the value once the motor is identified.

### `SNS` — Also One Resistor, And A Different One

`SNS` also takes a single resistor to ground. **Change `R27004` from 1 kΩ to
249 Ω and no divider is needed** — `OW-PASS-CRCW0402249RFKED`, 0402, 1%, stocked.
This supersedes the 2:1 divider suggested earlier; changing the resistor is
simpler, adds no parts, and gives a better ADC source impedance. 470 Ω would have
been the arithmetic ideal but is not stocked, and 249 Ω is strictly safer.

The problem being solved: the `SNS` pin reports faults by driving to a defined
high level — the datasheet's "integrated fault sense voltage scaling for ADC"
feature. In fault the pin sources `I_SNSFLT` = 5.2-6.4 mA into `R_SNS`, and the
node settles at whichever is lower, `I_SNSFLT × R_SNS` or the clamp `V_SNSFH`:

| `R_SNS` | Normal scaling, `K_SNS` = 800 | Fault level | Under the RP2040's `VDD + 0.3 V` = 3.6 V? |
| --- | --- | --- | --- |
| 1 kΩ (present) | 1.25 V/A, full scale at 2.6 A | 5.2-6.4 V, clamped to `V_SNSFH` ≈ 3.3-4.4 V | **No** |
| 604 Ω (stocked) | 0.76 V/A | 3.14-3.87 V | **No** — top of range exceeds 3.6 V |
| **249 Ω (recommended, stocked)** | **0.311 V/A**, full scale at 10.6 A | **1.29-1.59 V** | **Yes, with wide margin** |

At 249 Ω the pin never reaches its clamp, so the fault level is set by
`I_SNSFLT × R_SNS` and is bounded by design rather than by tolerance.

Ambiguity is not a concern: with `I_CL` at about 1.2 A the largest legitimate
reading is around 0.37 V, against a fault level of at least 1.29 V — a 3.5×
separation. `~{HV_FAULT}` on `GP29` reports the same condition independently
anyway.

Cost of the change: about a quarter of the signal, using ~11% of the ADC range in
normal operation. That does not matter here, and the reason is in the datasheet:
`I_SNS` accuracy is **±25% to ±30% below 60 mA** and ±5-6% only above about 0.5 A.
This is a coarse supply monitor by construction, so amplitude was never the
binding constraint. 0.311 V/A still gives about 386 ADC counts per amp at 12 bits.

All `SNS` timing and accuracy specifications are characterised at `R_SNS` = 1 kΩ.
If that fidelity matters more than simplicity, keep 1 kΩ and add a 100 k / 100 k
divider tap, which loads the 1 kΩ by about 2%. **249 Ω is the recommended
choice** — one stocked part, no divider, and the widest ADC margin.

### Does `R_SNS` Have To Change When `R_ILIM` Does?

**Not below `I_CL` = 3.4 A.** The two resistors do independent jobs, but `R_SNS`
has two ceilings and only one of them scales with the current limit:

| Ceiling | Formula, 3.3 V ADC | Depends on `I_CL`? |
| --- | --- | --- |
| Fault level — the pin sources 5.2-6.4 mA into `R_SNS` | `R_SNS` ≤ 515 Ω | **No** |
| Current range — `1.5 × I_CL` must still fit | `R_SNS` ≤ 1760 / `I_CL` | Yes |

The two cross at `I_CL` ≈ 3.4 A. Below that the fault ceiling binds and `R_SNS`
is the same on every board regardless of the limit; above it, `R_SNS` must shrink.

Since this board sits at ~1.2 A and 249 Ω satisfies both ceilings across the
part's whole 1-7.3 A adjustable range, **249 Ω is a safe single value for any
board using this block**.

A schematic note carrying both tables, for placing next to the block the way the
TMC5130 sense-resistor note travels with that block, is in
`docs/hv-input-block-schematic-note.txt`. It belongs in the `kicad-libs` design
block itself once this board proves it.

### `LATCH` — Tie It High For Latch-Off

Table 4-2 settles it: "With LATCH unused, the device performs an auto-retry after
a fault," and `t_RETRY` is **2 ms**. The internal 0.7-1.3 MΩ pulldown means the
block as placed gets auto-retry.

**On this board that is the wrong behavior.** Auto-retry into a persistent fault
cycles the motor rail at roughly 500 Hz: the TMC5130A repeatedly browns out and
recovers, and a joystick held by an animal twitches while it does. Nothing
upstream stops it.

**Tie `LATCH` to `+3.3V` through a 1 kΩ `RPROT`.** That selects latch-off, and the
clearing mechanism fits the board's existing design: "the device does not enable
the channel until either the LATCH pin OR the EN pin is toggled." Firmware already
owns `EN` on `GP19`, so the sequence is:

1. Fault occurs; the switch latches off and the motor rail drops.
2. `~{HV_FAULT}` asserts on `GP29`; firmware latches `SUPPLY_OUT_OF_RANGE`, stops
   motion, and reports it over UART.
3. Recovery requires an explicit `CLRFAULT` followed by toggling `HV_EN`.

That is exactly the "latch faults, require explicit clearing" model in
`.agents/AGENTS.md`, achieved with one resistor and no GPIO.

Driving `LATCH` from a GPIO instead would let firmware choose between behaviors,
but there is no reason to want auto-retry here. Rev 0 has pins free, so the
argument is now purely that auto-retry is the wrong behavior — not that the pin
budget forbids it. Full scope returns to 29 of 30, so spending one there would
cost the `GP27` spare.

### Reverse-Polarity Protection Is The Series Diode, Not The Device Feature

The datasheet says of pin 1: "Ground of device. Connect to resistor-diode ground
network to have reverse battery protection." The block ties `GND` straight to
board ground, so that feature is **not** configured. Reverse protection comes
solely from `D27001`, the `SBRT15U50SP5` series diode.

That is a valid and simpler choice. Consequences to accept: a forward drop in the
motor current path, and its dissipation. The part is rated 410 mV at 15 A, so
expect roughly 150-250 mV at this board's current. It also means `HV_IN` sits
that much below the supply, which is irrelevant at 36 V.

A useful side effect: because `VIL`/`VIH` on `EN` and `DIAG_EN` are specified "No
GND Network", the logic thresholds above apply directly and 3.3 V drive is in
spec once the `EN` divider is fixed.

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
- `hv_to_5v_tpsm365r6` **is** fed from the switched `+36V_SW` output, on
  purpose, so that dropping `HV_EN` resets the whole switched domain. That would
  make the board unbootable if the MCU were also on that chain — which is exactly
  why the MCU is not: `+3V3_MCU` comes from USB or pyControl through two ORing
  diodes and never touches the 36 V chain. Verify **both halves** during
  schematic capture. Feeding the MCU from the switched rail is the single most
  likely way to make an unbootable board out of otherwise correct blocks.
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

1. **Motor part number**, which sets supply current, `ILIM`, bulk capacitance,
   and the motor connector.
2. **Encoder supply voltage and current**, which sets the 5 V budget and the
   harness conductor count.
3. **The polyfuse hold current on the pyControl branch** — 250 mA or 500 mA. A
   layout-time decision, not a fabrication blocker, but pick it against rev 1's
   ~250 mA rather than Rev 0's ~100 mA.
4. `SNS` scaling and whether the block already populates the sense resistor.
5. Whether the DAC gets a dual-supply level translator (rev 1), now needed only
   if the DAC's own `VIH` demands it rather than as a back-powering fix.

**Resolved 2026-08-14 from the pyControl H7 breakout netlist:**

- **pyControl pin 6's 5 V current budget** is a shared **1.0 A** from a RECOM
  `R-78E5.0-1.0`, and yes, it is shared across all ports — and with the
  controller's own `AMS1117-3.3` logic rail, and with the 16-position terminal
  block. There is no per-port fuse. pyControl-only operation works for this
  board's ~100 mA; the finding's real consequence is the polyfuse requirement.
  See [What Pin 6 Can Actually Supply](#what-pin-6-can-actually-supply).
- Pin 6 is 5 V — now confirmed from the **host** side, not only from another
  peripheral.

**Resolved 2026-08-13 by the reset-button architecture:**

- The regulator chain is fed **post-switch**. Previously open, and previously
  recommended the other way; see the rail chain above for why it reversed.
- `+3V3_MCU` comes from USB or pyControl only. No always-on converter taps
  `HV_IN`, and the board does not boot on 36 V alone.
- Both ORing diodes are populated. The pyControl branch is no longer conditional.
- Whether the `TMC5130A` tolerates `VCC_IO` present with `VCC` and `VS` absent no
  longer needs an answer: all three are on the switched domain and fall together.
- **Exactly two `5v_to_3v3_tps73733` instances**, one per domain. Decided
  2026-08-13. The switched domain's 3.3 V is not split into analog and digital,
  and `+3V3_SW` is not subdivided if rev 1 loads grow — a third instance would be
  a new decision, not a pre-approved option.

**Resolved, and no longer a purchase item:** the 36 V TVS. No standard TVS can
protect the `TMC5130A` on a 36 V rail, and the other two parts on that rail do
not need one. Protection comes from the soft-start switch, bulk placement, and
layout. See above.
