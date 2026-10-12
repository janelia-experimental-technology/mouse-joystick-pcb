# Power

**Status:** Draft. The 36 V input block was audited against
`tps1htc100-q1.pdf` and needed six edits when placed; **at least five of them are
now in place on the board and verified against the flattened netlist on
2026-08-17**; see below.
**Date:** 2026-08-14
**Input:** 36 V through a 2-position 5.08 mm pluggable terminal block

**Updated 2026-08-14:** the pyControl 5 V supply was traced from the host side in
`pycontrol-h7-breakout`. Pin 6 is a shared **1.0 A** rail
that also feeds the controller's own logic regulator, with no per-port fuse — so
this board now **requires a polyfuse on its pin 6 branch**. See
[What Pin 6 Can Actually Supply](#what-pin-6-can-actually-supply). One open
decision closed, one new part.

**Updated 2026-08-17, from the flattened as-built netlist.** Five things in this
document changed:

- **`DIAG_EN` is now driven from `GP14`** (net `HV_DIAG_EN`), not tied high.
  **Reversed 2026-08-17**; earlier guidance in this document said to tie it to
  `+3.3V_MCU` through a 1 kΩ `RPROT` and that it "needs no GPIO". It does need
  one, and the reason is a leakage path this document's own analysis missed. See
  [`DIAG_EN` Must Be A GPIO](#diag_en-must-be-a-gpio-not-a-fixed-pull-up).
- **Reference designators were renumbered on placement.** `U27001`→`U201`,
  `J27001`→`J201`, `D27001`→`D201`, `R27001`–`R27007`→`R501`–`R509`,
  `U4001`→`U1201`, `R1202`→`R1202`, `D11001`→`D301`, `D29001`→`D1901`,
  `R29001`/`R29002`→`R1901`/`R1902`, `R29003`→`R1903`. The two ORing diodes this
  document calls `D1` and `D2` are `D301` (USB) and `D1901` (pyControl).
- **The rails are spelled `+3.3V_MCU` and `+3.3V_SW`**, not `+3V3_*`, and `VAA`
  is now `HV_RAW`. Both renames are done; see concerns 5 and 6 below.
- **No TVS is populated.** The two passages that disagreed about this are
  reconciled under [Transient Headroom](#1-transient-headroom).
- **The instrumentation buffers are Rev 0 and there are three of them**
  (`U1601`, `U1701`, `U1801`), not five in rev 1.

**Rev 0 scope:** the power chain is unchanged by the 2026-08-13 rescope. `+5V`
is still required — the TMC5130A's `VCC` minimum is 4.6 V — even though the
analog output that also needs it is deferred to rev 1. The argument against diode-ORing
onto `+5V` therefore still holds, and the switched-rail sense on `GP26` is still
populated — though as of 2026-08-16 it reads `+3.3V_SW`, not `+5V_SW`. The `mcu`
sheet pin that carries the raw rail into the sheet is named `SW_RAIL_SENSE`;
`R401`/`R402` divide it inside the sheet, and the divided node actually on `GP26`
is `SW_RAIL_SENSE_DIV_2`.
One Rev 0 addition affects this document: `HV_EN` bypasses the new GPIO isolation
bus switch, so the MCU can drive the 36 V enable regardless of bus state, while
`HV_SNS` and `~{HV_FAULT}` sit behind it and cannot be read until firmware
enables the bus. See `docs/interface-map.md`.

## Input Block Review Status

Reviewed against the block's netlist and `tps1htc100-q1.pdf` on 2026-08-12, after
the first round of edits. Reference designators were renumbered during those
edits, and renumbered again when the block was placed on this board; the list
below uses the **board's** designators — `U201`, `J201`, `D201`, `R501`–`R509`.
Re-verified against the flattened as-built netlist on 2026-08-17.

**Done and verified correct:**

| Element | Value / connection | Check |
| --- | --- | --- |
| `R501` + `R506` | 1 kΩ series + 10 kΩ pulldown on `EN` | `EN` = 3.0 V from 3.3 V logic, well over the 1.5 V `VIH`. **Done, verified 2026-08-17** |
| `R502` | **10 kΩ**, **`GP14`** (`HV_DIAG_EN`) → `DIAG_EN` | `RPROT` per Table 4-2, but the far end is a GPIO, not the rail. **Reversed 2026-08-17** — see [`DIAG_EN` Must Be A GPIO](#diag_en-must-be-a-gpio-not-a-fixed-pull-up) |
| `R503` | 1 kΩ, `+3.3V_MCU` → `LATCH` | Latch-off rather than 2 ms auto-retry. Verified 2026-08-17 — and **shown to be the wrong choice on the bench 2026-09-02.** It prevents the switch from ever charging this board's 208 µF. See [`LATCH` — Tie It High For Latch-Off](#latch--tie-it-high-for-latch-off) |
| `R507` | 10 kΩ, `+3.3V_MCU` → `~FAULT` | Open-drain pull-up at the MCU supply level. **Done, verified 2026-08-17** |
| `R508` | 40 kΩ on `ILIM` | `I_CL` ≈ 1.2 A; correctly left as a local label. **Done, verified 2026-08-17** |
| `R509` | 249 Ω on `SNS` | Fault level 1.3-1.6 V, well under the RP2040's `VPIN` absolute maximum. **Done, verified 2026-08-17**; arithmetic in [`SNS` — Also One Resistor](#sns--also-one-resistor-and-a-different-one) |
| `C201` | 220 nF **100 V** on `HV_IN` | `VS` bypass, correctly placed and correctly derated |
| `C202` | 22 nF on `+36V` | `VOUT` bypass, correctly placed — but see the rating issue below |
| `D201` | Anode to `HV_RAW`, cathode to `HV_IN` | Correct series blocking direction. Re-verified 2026-08-17 |
| `U201` pin 11 `NC` | Unconnected | Correct |
| `U201` pin 15 | Thermal pad to `GND` | Correct — internally shorted to ground |
| `PWR_FLAG` | On `HV_IN` | Right net: only driver is a passive diode cathode and `VS` is `power_in`. Exactly one. |
| Footprint | `Texas_HTSSOP-14-1EP_4.4x5mm_P0.65mm_EP3.4x5mm` | Matches the PWP package: 4.4 × 5 mm body, 6.4 mm lead span, 0.65 mm pitch |

**Three defects, fix before layout.** All three were raised against the unplaced
block; the board's copy has been checked against them on 2026-08-17:

| # | Defect | Fix |
| --- | --- | --- |
| 1 | **`R507` pulled `~FAULT` to `GND`.** `~FAULT` is open-drain; the datasheet requires a pull-**up** "to match the microcontroller supply level". As wired the net idled low, so it read as a permanent fault and never presented a valid high. | Move `R507`'s ground end to **`+3.3V_MCU`**, matching `R502`/`R503`. 10 kΩ is the right value. **Done, verified 2026-08-17:** `R507` = 10 kΩ to `+3.3V_MCU`. |
| 2 | **`HV_IN` is a plain local label**, so the board cannot reach it. This board needs it to place the TVS at the entry point. (It no longer needs a second tap there: `+3.3V_MCU` comes from USB/pyControl, not from `HV_IN`.) | Promote `HV_IN` to a **hierarchical label**. Schematic-only — the net name does not change, so there is no PCB impact. **Still open, but no longer urgent:** no TVS is populated as built, so nothing on the board needs to reach `HV_IN` yet. The `PWR_HV_ENTRY` netclass reaches it by pattern (`*/HV_RAW`, `*/HV_IN`) either way. |
| 3 | **`SNS` is a plain local label**, so the board cannot read the current sense at all. | Promote `SNS` to a **hierarchical label**. Leave `ILIM` local — that one is correct. Schematic-only, no PCB impact. **Done, verified 2026-08-17:** `U201` `SNS` reaches `GP28` as `HV_SNS`. |

The block's board-facing interface was originally only `+3.3V_MCU`, `+36V`,
`ENABLE`, `GND`, `~{FAULT}`. As placed it also exposes `SNS`, and it gained
`DIAG_EN` when that pin moved to `GP14`.

**Three concerns, cheap to fix now — all three are now closed, 2026-08-17:**

| # | Concern | Fix |
| --- | --- | --- |
| 4 | ~~**`C202` is 50 V on a 36 V rail** while `C201` is 100 V. 1.4× margin; X7R in an 0402 at 72% of rated voltage loses most of its capacitance to DC bias; and the internal `V_DS` clamp can drive `VOUT` to roughly −43 V, which is 86% of a 50 V rating. Marginal rather than illegal, but inconsistent with `C201`.~~ | **Done, verified 2026-08-17.** `C202` is now `OW-PASS-GCM188R72A223KA37D` — 22 nF **100 V** X7R **0603** — and `C201` is 220 nF 100 V X7R 0805. Both confirmed from the flattened netlist. The footprint change this fix implied is already carried in the block, so it costs the layout nothing now. |
| 5 | ~~The rail should be renamed `+3.3V`.~~ **Withdrawn.** The pull-ups on `DIAG_EN`, `LATCH` and `~FAULT` must reference the same rail the MCU uses, or the logic levels do not match and the MCU's clamps become a back-power path. Naming the rail by its domain is the right call and is more precise than `+3.3V`. | Keep a domain-suffixed name. **Closed 2026-08-17: the board spells them `+3.3V_MCU` and `+3.3V_SW`,** not `+3V3_MCU`/`+3V3_SW` as earlier drafts of this document wrote them. The netclass patterns match that spelling (`/+3.3V_*` → `PWR_3V3`), so the decision is settled in the schematic and in the DRU together. |
| 6 | **`VAA` is a misleading net name.** The TPS1HTC100-Q1 has no `VAA` pin — its pins are `GND`, `EN`, `DIAG_EN`, `~FAULT`, `LATCH`, `SNS`, `ILIM`, `VOUT`, `NC`, `VS`. It reads like a chip supply that does not exist. It is the raw connector node ahead of the reverse-polarity diode. | Rename to **`HV_RAW`** or `VIN_RAW`. Also affects netclass pattern matching. **Done, verified 2026-08-17:** the net is `HV_RAW`, and `*/HV_RAW` now matches the `PWR_HV_ENTRY` netclass at 1.5 mm. |

**Capacitor voltage ratings, board-wide, checked 2026-08-17.** Every capacitor on
the board sits at **≤80% of its rated voltage**, so concern 4 is the worst case
rather than the only case. Two things are worth writing down because neither is
visible from the schematic:

- **`OW-CAP-100N-0402-X5R-16V` declares only `ReqMinVoltage = 16V`** while
  resolving to LCSC `C162178` — a Murata `GRM155R62A104KE14D`, **100 V** X5R
  0402. So the TMC5130A's `VS` bypass caps `C1209`/`C1210` are rated correctly
  **by vendor mapping, not by requirement**. That is a latent trap: a future
  re-map of the internal part to a genuinely 16 V component would silently put
  16 V ceramics on a 36 V rail with nothing in the schematic to catch it. Prefer
  a part whose requirement states the rail voltage —
  `OW-PASS-GRM188R72A104KA35D` (100 V) is already catalogued.
- **`C1213`/`C1214` are 100 µF 50 V on the 36 V rail** — 72%, the same ratio
  concern 4 objects to. Acceptable, but **with no TVS fitted this is a
  bench-measurement item**, not a settled one. Measure the `+36V_SW` excursion at
  Gate B before calling it closed.

**ERC:** 32 violations, none of them defects. 13 `lib_symbol_issues` and 12
`footprint_link_issues` come from running `kicad-cli` outside the project's
library tables. The remaining 7 are the expected isolated-fragment set: 5
`pin_not_connected` for hierarchical labels with no parent sheet, 1
`power_pin_not_driven` on `GND` which the board supplies, and 1
`isolated_pin_label` on `ENABLE`. **The board as a whole reports 0 ERC violations
at every severity (2026-08-17).**

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
- `HV_RAW`, `HV_IN`, and `+36V_SW` carry the full motor current through `D201`
  (PowerDI-5, 15 A) and the switch. Wide pours, short loop, no necking. On this
  board `*/HV_RAW` and `*/HV_IN` are on `PWR_HV_ENTRY` (1.5 mm) and `/+36V_SW` on
  `PWR_HV_BUS` (1.2 mm), so the widths are enforced by netclass rather than by
  hand.
- `C201` sits right at the `VS` pins 12/13/14; `C202` right at `VOUT`
  8/9/10.
- `R508` (`ILIM`) and `R509` (`SNS`) are small-signal. Keep them off the
  power path and reference them to quiet ground — `SNS` feeds an ADC.
- **Silkscreen the terminal block polarity: `J201` pin 1 = `GND`, pin 2 =
  positive input.** This is the one that bites people.
- `D201` is rated 50 V reverse against a 36 V rail — 1.4×. Fine here, but note
  it in the block description, because the block is advertised for reuse on
  "HV/VMOT entry rails" and at 48 V that margin is gone.

Neither 470 Ω nor 24.9 kΩ — the arithmetically ideal values — is stocked. 249 Ω
and 40 kΩ are, and both land in a better place than the ideal values would have.

Both capacitors are in the right places and neither should move: `C201` on
`HV_IN` is the switch's `VS` bypass, `C202` on `+36V` is the output bypass.

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
36 V in ─> hv_input_36V_terminal_2pos_5p08_protected  (J201, D201, U201)
             │
             ├─ HV_IN (unswitched) ──> TPS1HTC100-Q1's own supply. NO TVS FITTED.
             │
             └─ +36V_SW (switched by HV_EN) ─┬─> TMC5130A VS (21, 40)
                                             └─> hv_to_5v_tpsm365r6 ─> +5V_SW
                                                   ├─> TMC5130A VCC (34), VSA (39),
                                                   │     and 5VOUT (33) via R1202 10R
                                                   ├─> encoder supply (J1103 pin 4)
                                                   ├─> analog output block (rev 1)
                                                   └─> 5v_to_3v3_tps73733 #2 ─> +3.3V_SW
                                                         ├─> TMC5130A VCC_IO
                                                         ├─> MAX6816 limit-switch debouncer
                                                         ├─> U801 encoder Schmitt
                                                         ├─> X1201 16 MHz oscillator
                                                         └─> SW_RAIL_SENSE divider (R401/R402)

USB-C VBUS ──────────────|>|── D301 ──┬─> +5V_MCU ─> 5v_to_3v3_tps73733 #1 ─> +3.3V_MCU
pyControl RJ-45 pin 6 ──|>|── D1901 ──┘                                       ├─> RP2040
                                                                              ├─> SN74CB3Q3245 ×4 VCC
                                                                              ├─> input block LATCH / ~FAULT pull-ups
                                                                              ├─> 3× SN74LVC125A (U1601/U1701/U1801)
                                                                              └─> board-level pull resistors
```

**There is no `+5V_USB` or `+5V_PYC` net.** Both ORing-diode cathodes land
directly on `+5V_MCU`. The pyControl-side nets are `PYC_CONN_5V` (`J1901` pin 6
to `R1903`) and `PYC_5V_FUSED` (`R1903` to `D1901`); `R1903` is the polyfuse
position, currently jumpered. See
[No Fuse Of Any Kind Is In The Parts Database](#no-fuse-of-any-kind-is-in-the-parts-database).

### Rail Names

| Net | Domain | Source | Dies when |
| --- | --- | --- | --- |
| `HV_RAW` | unswitched | 36 V terminal `J201` pin 2, *before* the reverse diode | 36 V supply unplugged |
| `HV_IN` | unswitched | 36 V terminal, after the reverse diode `D201` | 36 V supply unplugged |
| `+36V_SW` | switched | `TPS1HTC100-Q1` output | `HV_EN` low |
| `+5V_SW` | switched | `TPSM365R6V5` from `+36V_SW` | `HV_EN` low |
| `+3.3V_SW` | switched | `TPS73733` #2 from `+5V_SW` | `HV_EN` low |
| `+5V_MCU` | always-on | USB `VBUS` OR pyControl pin 6, two diodes | USB and pyControl both absent |
| `+3.3V_MCU` | always-on | `TPS73733` #1 from `+5V_MCU` | USB and pyControl both absent |

Older passages in this document say `+5V` and `+3.3V` from before the split; read
those as `+5V_SW` and `+3.3V_SW` unless the surrounding text is about the MCU.
Older passages also spelled the 3.3 V rails `+3V3_MCU`/`+3V3_SW`; **the board
spells them `+3.3V_MCU`/`+3.3V_SW`** and the netclass patterns match that.

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

**The bus switch is powered from `+3.3V_MCU`, not the switched rail.** It has to
be: the MCU must be able to isolate *before* dropping `HV_EN` and reconnect only
*after* the rails are confirmed up. Powering it from `+3.3V_SW` would give
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

**Current decision, 2026-08-17: no TVS is populated on this board either.** This
document previously said both "fit a TVS on `HV_IN`, order `SMBJ40A`" here and
"the 36 V TVS is resolved and no longer a purchase item" under Open Decisions.
Those contradicted each other; the second is what the board implements. The
reasoning below is kept in full because it is the argument for *where* a TVS
would go and *what* it could protect, and because it is what the Gate B
measurement will be read against. **It is a bench-measurement item, not a
fabrication blocker:** one SMB/SMA footprint decides it, and the `+36V_SW` bulk
(`C1213`/`C1214`, 100 µF 50 V, 72% of rating) is the part with the least margin
if the measurement comes back badly.

**If a TVS is fitted, fit it on `HV_IN`** — but understand that it protects the
switch and the buck, **not** the driver. The two jobs are separate and only one
of them has a TVS-shaped answer:

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

As built, **nothing** clamps that node. That is the specific risk the Gate B
hot-plug measurement exists to size.

Part choice, if the measurement says one is needed:

| Part | Standoff | Conducts from | Clamp | Verdict |
| --- | --- | --- | --- | --- |
| `SMBJ40A` | 40 V | 44.4-49.1 V | ≤64.5 V @ 9.3 A, 600 W | **Preferred, if any.** Not ordered — no TVS is populated. |
| `SMF48A` (stocked, `C1509577`, 120 on hand) | 48 V | ~53-59 V | 77.4 V @ 2.6 A, 200 W | **Usable now.** Stands off 36 V and holds `HV_IN` inside both parts' transient ratings at hot-plug currents. Prototype with this rather than waiting. |
| `SMBJ28A` (stocked) | 28 V | — | — | No. Would conduct at the 36 V working voltage. |

~~So: order `SMBJ40A`, and if the first boards need to go out before it arrives,
build with the stocked `SMF48A` and swap later.~~ **Superseded 2026-08-17: no TVS
is populated and none is on order.** The rest of the sentence still holds — **this
is not a fabrication blocker either way**, it is one SMB/SMA footprint, and it
stays a bench-measurement item rather than a purchase item until Gate B says
otherwise.

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

**Reinforced 2026-08-31, and now with numbers.** The second reason applies at
rev 2 and it is decisive there, so do not drop to 24 V on this outline. The
settled brake sink needs, at 48.8 mA and a worst-case 605 Ω hot winding, a rail of
at least `29.5 V + 0.49 V + 1 V ≈ 31 V`. A 36 V rail at −5% is 34.2 V, leaving
**4.2 V** of pass-device compliance; a 24 V rail cannot maintain rated current at
all. Choosing 36 V here was the right call and rev 2 collects the benefit.

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

The `tmc5130` design block ties **`VSA` (pin 39) to `+5V`**, not to `VM`. As
placed on this board (`U1201`, verified from the flattened netlist 2026-08-17):

```text
+5V_SW  -> U1201.34 VCC,  U1201.39 VSA,  R1202 (10R) -> 5VOUT,  C1205 0.47uF
5VOUT   -> U1201.33,      R1202,                                C1208 4.7uF
+36V_SW -> U1201.21 VS,   U1201.40 VS,   bulk + decoupling
```

**`VSA` on `+5V_SW` is a deliberate deviation.** The datasheet says `VSA` is
"normally tied to VS"; this board does not, in order to keep 36 V off the analog
supply pin. It is harmless because `VCC` is supplied externally, so the internal
regulator idles and `VSA` is not being asked to feed it. Recorded here so it is
not read as an oversight, and so the next board that copies the block knows the
deviation is intentional.

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
  why the block also feeds `5VOUT` from `+5V` through `R1202`.
- The magnitude matters. The datasheet warns the internal regulator "will
  contribute with up to 1 W" at 46 V. Even with `VCC` fed externally, `VSA` on
  `VM` would leave the regulator carrying its analog load plus whatever flows
  through `R1202`'s 10 Ω — a few hundred mW in a package already dissipating
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
| `+3.3V_MCU` | Always on, from the ORed USB / pyControl 5 V | RP2040, the four `SN74CB3Q3245` bus switches, the input block's `LATCH`/`~FAULT` pull-ups (`DIAG_EN` is now a GPIO, not a pull-up), the three `SN74LVC125A` instrumentation buffers `U1601`/`U1701`/`U1801`, and the board-level pull resistors listed under [Supporting Measure 2](#mcu-alive-switched-rails-dead--the-normal-idle-state) |
| `+3.3V_SW` | Downstream of the switched `+5V_SW` | TMC5130A `VCC_IO`, the MAX6816 debouncer, encoder supply if 3.3 V |

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
`ENABLE`; the separate always-on `+3.3V_MCU` rail now does that job instead. The
underlying warning still stands: *something* must power the MCU independently of
the switch, or the board cannot enable its own motor supply.

Do **not** switch `+3.3V_MCU`. The MCU runs on it and drives `ENABLE`, so
switching it off is a deadlock.

Note also that `R1202` in the `tmc5130` block is 10 Ω where the datasheet
recommends **2.2 or 3.3 Ω** between `VCC` and `5VOUT`, and that it sits between
`+5V_SW` and `5VOUT` rather than in the datasheet's position. **Decided
2026-08-17: keep it** — reasoning under
[Internal 5 V Regulator Dissipation](#3-internal-5-v-regulator-dissipation).

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

~~**Confirm during schematic capture** that the block ties `VCC` to the external
`+5V` and leaves `5VOUT` as a decoupled local net rather than bridging them. If
it bridges them, the external supply back-drives the internal regulator.~~

**Confirmed 2026-08-17: the board bridges them, deliberately, and it is signed
off.** `+5V_SW` feeds `VCC` (pin 34) directly and reaches `5VOUT` (pin 33)
through `R1202` = 10 Ω. That is the state the sentence above warned about, so it
needs a recorded reason rather than a silent contradiction:

- The back-drive the warning was about is benign here because **`VCC` is supplied
  externally, so the internal regulator idles.** It is not being asked to source
  current into a rail that is already held up; there is no fight, only a resistor
  between two nodes at nearly the same potential.
- The datasheet's sequencing requirement — "make sure that VCC comes up before or
  in parallel to 5VOUT or VCC_IO, whichever comes up later" — **is satisfied**,
  because `VCC_IO` is derived from `+5V_SW` through the switched-domain LDO and
  therefore cannot precede `VCC`.
- **The value and the position both differ from the datasheet.** The datasheet
  recommends **2.2 or 3.3 Ω** for a resistor between `5VOUT` and `VCC`; `R1202`
  is **10 Ω** and sits between `+5V_SW` and `5VOUT` instead. This document has
  flagged the 10 Ω value twice without ever recording a decision. **The decision
  is: keep it.** With the regulator idling the resistor carries only the `5VOUT`
  decoupling and the analog load, so the extra drop is negligible; changing it
  means editing the `kicad-libs` block, which is a bigger change than the benefit.
  Revisit if the Gate D driver-temperature measurement is unexpected.

`VSA` may also be supplied from a lower rail than `VS` to reduce dissipation
further; the datasheet notes this reduces regulator dissipation to about 37% when
a 12 V rail is used instead of 24 V. ~~This board has no intermediate rail, so
`VSA` ties to `VS` per the block default.~~ **Corrected 2026-08-17: `VSA` is on
`+5V_SW`, not on `VS`** — see [Supply Sequencing](#2-supply-sequencing--and-why-it-is-vsa-not-vcc)
above, which says the same thing and which this passage contradicted. Revisit
only if driver temperature measurements at Gate D say to.

## Why 36 V At All

Recorded so the decision is not re-litigated later, and so the cost above is
attributed to a benefit:

- **Motor performance.** Higher rail voltage means faster current rise in the
  coil, so the same motor holds torque to a higher step rate. On a joystick that
  has to feel responsive to a mouse, that is the whole point.
- **Rev-2 brake headroom.** `kicad-libs/docs/brake-current-sink-design.md`
  requires a **36 V** input as constant-current compliance, because a 24 V rail
  cannot force 49 mA through a 605 Ω hot coil. **Quantified 2026-08-31:** the
  settled design has 4.2 V of pass-device compliance at 36 V −5% with the hot
  winding, and 0.71 W of pass-device dissipation at 36 V +5% with the cold
  winding. The twin-axis board records this as an unresolved tension between its
  24 V plan and the brake note. Choosing 36 V here removes it in advance:
  whatever this board learns about a 36 V rail transfers directly to the brake
  design — **including the ringing.** The pass device sees the *full* rail
  whenever the brake is off, so this document's own warning about TMC5130A-induced
  ringing on `+36V_SW` matters to the brake too.
  **Measure it at the future brake stage's location, with the driver running.**
  **Sharpened 2026-08-31:** that measurement does *not* choose the brake pass
  device — that is settled at 60 V. **This document's own TMC5130A limit is the
  binding one:** 49 V absolute maximum with an inductive load is 80% of the brake
  FET's 60 V rating, so the brake FET can never be the weakest thing on the rail.
  What the measurement decides is whether the board needs a **TVS at the 36 V
  entry** — currently not populated — which would protect the driver and the brake
  stage together.

## Multiple Logic Power Sources

**Two** sources feed the MCU domain: USB-C `VBUS` and pyControl RJ-45 pin 6,
diode-ORed so the MCU runs from whichever is present. The onboard `TPSM365R6V5`
is deliberately **not** one of them — it lives on the switched rail, which is the
thing the MCU has to survive switching off.

**pyControl pin 6 is 5 V, confirmed on two independent designs.** Read out of the
reference design's own netlist — in
`syringe-pump/ecad/module_pycontrol.kicad_sch` the RJ-45
pin 6 net is `5VDC` and pin 8 is `Vmotor` at 12 V — and confirmed again from the
host side in `pycontrol-h7-breakout` (see below). So both
ORed sources are nominal 5 V and the OR happens at 5 V, upstream of the MCU's own
LDO. There is no 3.3 V pin on the port to worry about.

**The current budget is now known at the source, and it comes with a hazard.**
See [What Pin 6 Can Actually Supply](#what-pin-6-can-actually-supply) immediately
below. The short version: 1.0 A shared with everything else in the rig *including
the pyControl controller's own logic rail*, with no per-port fuse — so **this
board must fuse its own pin 6 branch.** USB-only operation is unaffected either
way.

### What Pin 6 Can Actually Supply

Traced from `pycontrol-h7-breakout` PCB v0.7 by netlist
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

**Requirement: a resettable polyfuse on the pin 6 branch, upstream of the ORing
diode.** It confines a fault on this board to this board. **The position is
`R303` and it is fitted with a jumper — no PPTC is populated**, so this
requirement is stated but not yet met.

**Decided for v1.0, 2026-09-18: ship the jumper. The PPTC is deferred to a later
revision.** This is a deliberate, recorded choice rather than an oversight, taken
with the schematic otherwise complete and going to layout. What it means in
practice: **the pyControl pin 6 branch has no overcurrent protection on v1.0** —
`R303` is a 0.36 Ω resistor, so a fault on this board is a fault on the pyControl
module's 1.0 A supply, which also powers that controller's own logic regulator.
Nothing about layout changes, because `1206L035/16YR` drops into the same 1206
land; fitting it later is a parts swap, not a respin. The two test points this
section asks for further down are worth adding **now** for exactly that reason —
without them a fitted-versus-jumpered PPTC is undiagnosable.

**Part selected 2026-09-16: Littelfuse `1206L035/16YR`, LCSC `C126817`.** 0.35 A
hold, 0.75 A trip at 20 °C, 16 Vdc, 100 A I_max, R_min 0.300 Ω / R_1max 1.20 Ω,
0.10 s maximum time to trip at 8 A. Hold derates to 0.30 A at 40 °C and 0.24 A
at 60 °C. **It is not in stock — this is an order**, re-verified against
`kicad-libs/db/source/jlc_inventory_export.csv` and the JLCPCB inventory export
on 2026-09-16: still zero fuses, polyfuses or PPTCs of any kind.

**Why 0.35 A and not the 0.5 A this document used to lean toward.** The trip
current is what has to fit inside the *source's* headroom, not the hold current.
Port 5 V is a 1.0 A module that also feeds the controller's own AMS1117 at
200-400 mA, leaving 600-800 mA. A `1206L050/15` trips at 1.00 A — at or above the
module's entire rating, so the module sags and resets the pyControl controller
*before* the fuse ever opens, which is precisely the failure this part exists to
prevent. 0.75 A sits inside the headroom, and 0.30 A of hold at 40 °C is still
about twice the board's worst-case always-on draw. The 1.20 Ω worst-case
resistance costs 240 mV at 200 mA, leaving ~4.36 V into the 3.3 V LDO after the
ORing diode — ample. If the bigger part is wanted anyway it is
`1206L050/15YR-A`, LCSC `C315893` (0.50 A hold, 1.00 A trip, 15 V, R_1max
0.75 Ω), with that caveat understood.

It still needs an internal part, a vendor mapping and a symbol in `kicad-libs`;
the 1206 land already exists because `R303` occupies it. **Add the two test
points across it in the same revision** — see the note below on why a tripped
PPTC is otherwise undiagnosable.

It fails in the right direction, which is why it is cheap insurance rather than a
new failure mode: if the polyfuse trips, `D1901` simply stops conducting and the
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

**Verified as-built 2026-08-17; designator corrected 2026-09-16.** The position
is **`R303`**, between `PYC_CONN_5V` and `PYC_5V_FUSED` — re-annotation moved it
out of the 19xx band, so every earlier reference to `R1903` in this document
means `R303`. **Nothing is fitted yet** — the jumper is what is on the board. The
block's own on-sheet note says the same thing in stronger terms:

> `R29003` IS A POLYFUSE POSITION, NOT PROTECTION. The 0.36R part is a jumper.
> Port 5 V is a shared 1.0 A that also feeds the pyControl controller's own logic
> regulator, with no per-port fuse — a fault here can reset the controller.
> Populate a 1206 PPTC, 250-500 mA hold.

Two things that note does not tell you. First, it still names `R29003`, which is
the design block's designator, **not this board's** — on the board it is `R1903`.
Second, **there are no test points on either side of it**, so a tripped PPTC
could not be diagnosed in circuit; it would present as a board that has gone dark
on pyControl-only power, indistinguishable from a dead diode or an unplugged
cable without lifting a probe onto the resistor's own pads. If a PPTC is ever
fitted, add the two test points in the same revision.

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
| Analog output `OPA197` (rev 1) | **4.5 V minimum supply.** Below that the gain stage is out of spec — this is now the analog section's binding 5 V requirement |
| Analog output `DAC80501` `VDD` (rev 1) | ≥ the 2.5 V reference with `REF-DIV=1`; 5 V gives ample margin |
| Brake block, 3× `OPA197` (rev 2) | **4.5 V minimum**, same binding requirement. The loop amplifier must reach the pass device's `V_GS` plus the 0.49 V shunt drop, about 3.2 V worst case, which a 5 V RRIO output clears comfortably |
| Brake block `DAC80501` `VDD` (rev 2) | **3.3 V, deliberately not 5 V.** `+3.3V_SW`, not this rail. At 3.3 V the reset `REF-DIV = 0` is out of spec, and the datasheet forces all outputs to 0 V on improper reference-divider configuration, so the 0-2.5 V span becomes a hardware property and a wrong-`GAIN` write is fail-safe. It also removes the 5 V back-powering path the angle block had to reason about. See `kicad-libs/docs/brake-current-sink-design.md` |
| `TMC5130A` `VCC` | **4.6 V to 5.25 V** operating range, per rev 1.21 chapter 30 |
| Encoder, if 5 V | Per its datasheet |

**Corrected 2026-08-26.** This table used to read *"`DAC8563` `VDD` | 5 V,
because full-scale output is `VDD`. A 4.6 V rail silently makes the '0-5 V'
output a 0-4.6 V output."* That was true of the part originally planned and is
false of the one built. The `DAC80501`'s full scale is set by its **internal
2.5 V reference and the gain resistors**, not by `VDD`, so a sagging rail does
not truncate the output. The 5 V requirement did not go away — it moved to the
`OPA197`, which simply stops working correctly below 4.5 V rather than degrading
gracefully. See `docs/encoder-analog-output.md`.

USB `VBUS` is 4.75-5.25 V at the source and sags further over the cable — call it
4.4-5.25 V at the connector. Subtract a Schottky drop of 0.3-0.4 V and the ORed
rail is **4.0-4.9 V**.

That is out of spec for the TMC5130A's `VCC`, and at the bottom of that range it
is also out of spec for the rev 1 analog output's `OPA197`. **This is the trap in
the obvious implementation.**

**Restated 2026-08-26.** The analog half of this argument used to be that a
4.6 V rail would silently truncate a 0-5 V output to 0-4.6 V, so a researcher
would see a wrong full scale with no indication why. That failure mode no longer
exists — the built output's full scale comes from a reference, not the rail. The
replacement is less tidy but not weaker: an `OPA197` below its 4.5 V minimum is
simply operating outside its datasheet, with no specified behaviour to reason
about, and the ORed rail's 4.0 V floor is well inside that region. The
conclusion is unchanged and now rests on two independent parts rather than one.

### OR The Two Host Sources At `+5V_MCU`

Both sources are 5 V, so the OR is a plain two-diode wired-OR feeding the MCU
domain's own LDO. The `TPS73733` regulates away both the diode drop and the
difference between sources, and it only needs its input above roughly 3.8 V.

```text
36 V in ─[D201 reverse diode]─[U201 switch]─ +36V_SW ─┬─> TMC5130A VS
                                                      └─> TPSM365R6V5 ─> +5V_SW ─> TMC VCC/VSA/5VOUT, encoder, analog output (rev 1)
                                                                            │
                                                                            └─> TPS73733 #2 ─> +3.3V_SW ─> TMC VCC_IO, MAX6816,
                                                                                                           U801, X1201

USB-C VBUS ─────────────|>|── D301 ──┬──> +5V_MCU ──> TPS73733 #1 ──> +3.3V_MCU
pyControl RJ-45 pin 6 ──|>|── D1901 ─┘
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
- **Polyfuse on the pyControl branch: `1206L035/16YR`, 0.35 A hold / 0.75 A trip,
  LCSC `C126817`, upstream of the ORing diode.** Not on the USB branch — a USB
  host already current-limits and will simply drop the port. pyControl does not:
  its 5 V has no per-port protection and shares a regulator with the
  controller's own logic. See
  [What Pin 6 Can Actually Supply](#what-pin-6-can-actually-supply). **As built
  the position is `R303` and it is jumpered, not fused — the part is on order,
  not in stock.**
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
`+36V_SW`, `+5V_SW`, and `+3.3V_SW` are all at 0 V.**

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
The bus switch runs from `+3.3V_MCU` so it is controllable in exactly the state
that needs controlling.

Three supporting measures, and use all of them:

1. **Sequencing.** Isolate before switching off, reconnect only after the rails
   are confirmed up. Firmware rule and ordering in `docs/interface-map.md`.
2. **Series resistors on every 3.3 V line that crosses into the switched
   domain.** Cheap backstop covering the window where firmware gets the order
   wrong, or where the bus switch itself fails. They cost nothing; fit them.

   **How this is actually satisfied, verified 2026-08-17.** Only two cross-domain
   nets carry a literal series resistor — `HV_EN` through `R501` 1 kΩ (with
   `R506` 10 kΩ to ground at `U201`), and `SW_RAIL_SENSE` through the
   `R401`/`R402` 1 kΩ/1 kΩ divider. Every *other* cross-domain net is terminated
   instead, by one of nine board-level pull resistors added on 2026-08-17. They
   live in the board-authored `mcu` and `motor_encoder_switch` sheets, **not**
   inside a design block, so re-placing a block cannot lose them. **Rehomed and
   renumbered 2026-09-16** — the five that were `R1104`-`R1601` in
   `instrument_port` are now `R1104`-`R1601`, and nine more are owed by the v1.0
   I2C and torque buses (see `docs/interface-map.md`):

   | Ref | Value | Net | To | Sheet | Why |
   |---|---|---|---|---|---|
   | `R401` | 10 kΩ | `PYC_UART_RX` | `+3.3V_MCU` | `mcu` | UART RX must idle **high**; the RP2040's default pull-down would look like a permanent break |
   | `R1104` | 10 kΩ | `TMC_SPI_SCK` | GND | `motor_encoder_switch` | define the TMC input, and the tap, when the switched domain is off |
   | `R1105` | 10 kΩ | `TMC_SPI_COPI` | GND | `motor_encoder_switch` | as above |
   | `R1106` | 10 kΩ | `TMC_SPI_CIPO` | GND | `motor_encoder_switch` | as above; also gives the instrument tap a clean idle-low |
   | `R1107` | 10 kΩ | `~{TMC_CS}` | `+3.3V_SW` | `motor_encoder_switch` | CSN must idle **deasserted** — a pull-down would assert chip select |
   | `R1601` | 100 kΩ | `LIMIT_SW` | GND | limit-switch **block** | define the debounced limit input |
   | `R1101` | 10 kΩ | `TMC_DIAG0` | `+3.3V_SW` | `motor_encoder_limit` | DIAG is open-drain at reset; the datasheet requires ≤47 kΩ |
   | `R1102` | 10 kΩ | `TMC_DIAG1` | `+3.3V_SW` | `motor_encoder_limit` | as above |
   | `R1103` | 10 kΩ | `~{TMC_DRV_EN}` | `+3.3V_SW` | `motor_encoder_limit` | guarantees the power stage is **disabled** in hardware |

   **Why some reference `+3.3V_SW` and some GND.** Pulls that must read HIGH while
   the driver is powered (`~TMC_CS`, both `DIAG`, `~TMC_DRV_EN`) reference
   `+3.3V_SW`, so they collapse to 0 V with the domain instead of injecting
   current into a dead rail. Pulls that may read LOW go straight to GND.
   Referencing `+3.3V_MCU` would be the same mistake this whole section is about:
   it would back-power `+3.3V_SW` to roughly 1.3 V through the TMC's protection
   diodes, defeating the `HV_EN` power-cycle and corrupting `SW_RAIL_SENSE`.

   Note the dependency this creates: **`+3.3V_SW` is held at 0 V when off by
   `R401`/`R402`, 2 kΩ to ground** — the rail-sense divider of measure 3. That is
   what makes a pull-up to `+3.3V_SW` a valid LOW in the off state. Remove the
   divider and `R1107`/`R1101`/`R1102`/`R1103` stop defining their nets.
3. **A `+3.3V_SW` presence sense on `GP26` (`ADC0`)** through a ÷2 divider, so
   firmware can confirm the switched domain is actually up before enabling the
   bus, refuse `ARM` with a meaningful reason when it is not, and report it.
   `GP26` therefore **bypasses the bus switch** — sensing the rail through the
   thing you are trying to decide whether to enable would be circular.

   **Changed 2026-08-16 from `+5V_SW` to `+3.3V_SW`**, same two resistors. It is
   the end of the chain, so one reading confirms 36 V, 5 V, and 3.3 V together,
   and it is the rail that actually gates the decision because it powers the far
   side of the bus switch.

   **This circularity is the whole reason the sense exists.** It is tempting to
   argue the sense is redundant, since the TMC5130A only answers SPI when all
   three of its supplies are present — but SPI reaches the driver *through the bus
   switch*, so it cannot confirm anything before the switch is enabled. Note also
   that `~{HV_FAULT}` does not cover the gap: with no 36 V present the
   `TPS1HTC100-Q1` is itself unpowered, its open-drain output floats, and the
   pull-up reads it as no fault. `HV_SNS` on `GP28` does cover most of it, since
   the buck and LDO draw quiescent current whenever the rail is genuinely up.
   See `docs/interface-map.md`, "What The Rail Sense Is Actually For".

**Two open questions this architecture closed.** Whether the `TMC5130A` tolerates
`VCC_IO` present with `VCC` and `VS` absent no longer matters — all three are on
`+36V_SW` and fall together. And the dual-supply level translator that was one
candidate fix for the DAC case is not needed at all: **closed 2026-08-26**, the
`DAC80501` specifies `VIH` at 1.62 V minimum flat across `VDD` = 2.7-5.5 V, so
3.3 V logic drives it directly at `VDD` = 5 V. The isolation bus switch remains
the back-powering fix; the translator was only ever the alternative.

### Taking pyControl's 5 V Is No Longer Optional

**Reversed 2026-08-13. Populate both diodes.**

The earlier recommendation was to lay out the pyControl 5 V branch and leave it
unpopulated, on the grounds that USB alone delivers the whole development
benefit. That reasoning assumed the board had an always-on rail of its own. It
does not: `+3.3V_MCU` comes from USB or pyControl and from nowhere else, so an
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
switches, the input block's pull-ups, the board-level pull resistors, and the
`SN74LVC125A` buffers. **Corrected 2026-08-17: the buffers are Rev 0, not rev 1,
and there are three of them** — `U1601`, `U1701`, `U1801` — not five. `U_C` and
`U_D` do not exist. Roughly **100-150 mA typical**, up to ~250 mA with the
buffers switching.

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

**Resolved 2026-09-16 with `1206L035/16YR`, 0.35 A hold / 0.75 A trip.** The
earlier reasoning here preferred 500 mA for rev-1 headroom; the v1.0 circuit
shows that headroom was never needed and the trip current is the binding
constraint instead. The always-on domain did not grow: the three
`SN74LVC125A` buffers became four `SN74LV541A` in the digital-50 block, which is
roughly a wash, and the only real correction is upward by a few milliamps for
the bus switches. Reckon **~60-70 mA typical and 150-200 mA with the port
switching hard**, against 0.30 A of hold at 40 °C. See
[What Pin 6 Can Actually Supply](#what-pin-6-can-actually-supply) for why 0.75 A
of trip beats 1.00 A here.

## Load Budget

Fill in measured values at Gate B. Estimates for sizing only.

| Domain | Rail | Load | Estimate |
| --- | --- | --- | --- |
| switched | `+36V_SW` | Motor, 0.67 A/phase RMS, two phases | Sized from the identified motor; see below |
| switched | `+36V_SW` | TMC5130A quiescent and gate drive | tens of mA |
| switched | `+5V_SW` | TMC5130A `VCC` | ~20-30 mA |
| switched | `+5V_SW` | Encoder, if 5 V | **Unknown — the encoder part is not identified.** A Broadcom `HEDR-5421` class part draws 40-85 mA |
| switched | `+5V_SW` | Analog output block, `DAC80501` + `OPA197` + output load (rev 1) | **~3 mA** |
| switched | `+36V_SW` | **Brake coil, rev 2** | **48.8 mA maximum, DC and constant** — a linear current sink, so no switching component and no bulk capacitance needed. Negligible against the 1.2 A `ILIM` |
| switched | `+5V_SW` | **Brake block, 3× `OPA197`, rev 2** | **~3 mA** |
| switched | `+3.3V_SW` | **Brake block `DAC80501` `VDD` + optional `SN74LVC2G17`, rev 2** | **~2 mA** |
| switched | `+3.3V_SW` | TMC5130A `VCC_IO` | few mA |
| switched | `+3.3V_SW` | `U1301` MAX6816 debouncer | tens of µA |
| switched | `+3.3V_SW` | **`U801` SN74LVC2G17 encoder Schmitt** | µA static; charge transfer when switching |
| switched | `+3.3V_SW` | **`X1201` 16 MHz oscillator, ECS-2520S33** | **~7 mA** |
| switched | `+3.3V_SW` | **`SW_RAIL_SENSE` divider `R401`/`R402`, 2 kΩ to GND** | **1.65 mA continuous whenever the rail is up** |
| switched | `+3.3V_SW` | **`R1107`/`R1101`/`R1102`/`R1103` pull-ups, 4 × 10 kΩ** | **~0.33 mA typical** — a 10 kΩ pull-up only conducts while its net is held low, and normally at most one is |
| switched | `+3.3V_SW` | Differential encoder receiver, if fitted | ~10 mA |
| always-on | `+3.3V_MCU` | RP2040 | ~50 mA |
| always-on | `+3.3V_MCU` | 4× `SN74CB3Q3245` | **~4 mA typ, 8 mA max, continuous** — corrected 2026-09-16 |
| always-on | `+3.3V_MCU` | Input block `LATCH`/`~FAULT` pull-ups (`DIAG_EN` is now a GPIO) | < 1 mA |
| always-on | `+3.3V_MCU` | **4× `SN74LV541A` in the digital-50 DUT block, v1.0** | µA static; 32 × 50 pF × 3.3 V × f when switching |
| switched | `+12V` | **Torque block, v1.0** | INA821 and its front end, few mA |
| switched | `+12V` | **Brake block gate drive, v1.0** | few mA |
| switched | `+3.3V_SW` | **Two I2C pull-up pairs, 4 × 4.7 kΩ, v1.0** | ~0.7 mA per line held low |
| always-on | `+3.3V_MCU` | **`R401` 10 kΩ and `R606` 7.87 kΩ** (the `R1601`/`R1701`/`R1801` trio belonged to the retired `~{INSTR_BUF_OE}`; those designators now name unrelated parts) | same ~0.33 mA-per-conducting-resistor arithmetic; sub-mA in every normal state |

**v1.0 adds a rail this document does not otherwise describe: `+12V`, switched.**
Both `brake_current_sink_0_49ma_dac80501` and `torque_bridge_0_3v3_ina821` take
`+12V` as an input port, and this board has never had it, so
`hv_to_12v_tpsm365r6` has to be placed alongside the existing
`hv_to_5v_tpsm365r6`. It belongs post-switch like every other derived rail, for
the ordering reason in [Turn-On Ordering Comes Free If The Buck Is Fed
Post-Switch](#turn-on-ordering-comes-free-if-the-buck-is-fed-post-switch).

**The `SN74CB3Q3245` line was wrong and the correction matters for the
polyfuse.** The datasheet (SCDS124, rev C) gives I_CC as 1 mA typ and 2 mA max
per package **with the switch ON or OFF**, because the charge pump runs
regardless of `~OE`. Four packages therefore draw ~4 mA typ and ~8 mA max from
the always-on rail continuously, even with every channel isolated — not the
"µA static" this table claimed. It is small, but it is the floor of the
always-on domain rather than a switching-dependent term, and it is the one line
that does not go away when the board is idle.

The 5 V rail's 600 mA is comfortable unless the encoder is unusually hungry.

**The `SW_RAIL_SENSE` divider's 1.65 mA is a permanent load and that is
deliberate.** 2 kΩ across `+3.3V_SW` is more than the MAX6816 and the encoder
Schmitt draw together, which looks wasteful until you notice it is also what
holds `+3.3V_SW` at a true 0 V when the domain is off — the property the
`+3.3V_SW`-referenced pull-ups depend on. Do not "optimise" it to 100 kΩ without
re-reading [Supporting Measure 2](#mcu-alive-switched-rails-dead--the-normal-idle-state).

**Read the table by domain, not by voltage.** The `+5V_SW`/`+3.3V_SW` column is
what the 36 V chain must supply and what disappears when `HV_EN` drops; the
`+3.3V_MCU` column is what USB or pyControl must supply continuously. Sizing them
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
`tps1htc100-q1.pdf`, when the block had never been placed on a board.

**Read this section as the pre-fix state except where a subsection says
otherwise.** Everything from here to
[Reverse-Polarity Protection](#reverse-polarity-protection-is-the-series-diode-not-the-device-feature)
describes the block *as the library shipped it*, which is what makes the
arithmetic worth keeping. **The board's placed copy no longer looks like this** —
it has all of the fixes, and its designators are `U201`, `J201`, `D201`,
`R501`–`R509`. The as-built topology is immediately below; the pre-fix audit
follows it; and the `DIAG_EN` and `SNS` subsections carry the 2026-08-17
decisions.

### Actual Topology

As built on this board, verified from the flattened netlist 2026-08-17. The two
input-block ceramics keep the block's own designators here because this document
has never recorded their board-level numbers:

```text
J201.2 ── HV_RAW ── D201 (SBRT15U50SP5, anode→cathode) ── HV_IN ──┬── U201 VS (12,13,14)
                                                                  ├── 220nF VS bypass ── GND
J201.1 ── GND                                                     └── (no TVS fitted)

U201 VOUT (8,9,10) ── +36V_SW ──┬── 22nF VOUT bypass ── GND
                                └── TMC5130A VS, TPSM365R6 VIN, C1213/C1214 100uF

HV_EN ─────R201  1k──┬── U201 EN (2)         DIAG_EN (3) ──R202 1k── HV_DIAG_EN (GP14)
                     └──R204 10k── GND       ~FAULT  (4) ──R205 10k── +3.3V_MCU, and GP23
                                             LATCH   (5) ──R203 1k── +3.3V_MCU
U201 ILIM (7) ──R206 40k── GND               NC     (11)  no-connect
U201 SNS  (6) ──R207 249R── GND, and GP28
```

And as the block shipped, before any of the fixes — this is the state the audit
below is written against:

```text
ENABLE ──R27001 10k──┬── U27001 EN (2)        DIAG_EN (3)  no-connect
                     └──R27002 10k── GND      ~FAULT  (4)  R27005 10k to GND
                                              LATCH   (5)  no-connect
U27001 ILIM (7) ──R27003 10k── GND            NC     (11)  no-connect
U27001 SNS  (6) ──R27004  1k── GND
```

So: `HV_RAW` (formerly `VAA`) is the raw connector node, `HV_IN` is
post-reverse-polarity-diode, and `+36V_SW` is the switched output.

### The Capacitors Are Correct Where They Are

- **`C201` 220 nF sits on `HV_IN`, at the switch's `VS` pins. Leave it there.**
  It is the switch IC's supply bypass, not bulk. Moving it to `+36V` would leave
  `VS` unbypassed.
- **`C202` 22 nF sits on `+36V`, the switch output. Leave it there too.** The
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
| 2 | **`DIAG_EN` is left no-connect with a 200-500 kΩ internal pulldown, so diagnostics are off.** Table 4-2: "With DIAG_EN unused, the analog sense, open-load, and short-to-battery diagnostics are not available." Every `ISNS` specification is conditioned on `VEN = VDIAG_EN = 5V`. **With the block as-is, the `SNS` output does nothing and `HV_SNS` on `GP28` reads zero.** | ~~Tie `DIAG_EN` to `+3.3V_MCU` through a 1 kΩ `RPROT`. Needs no GPIO.~~ **Reversed 2026-08-17.** `R502` 1 kΩ now goes to **`GP14`** (`HV_DIAG_EN`). Tying it high is wrong for a reason this table missed — see [`DIAG_EN` Must Be A GPIO](#diag_en-must-be-a-gpio-not-a-fixed-pull-up). **Done, verified 2026-08-17.** Still safe with `VS` absent — see below. |
| 3 | **`~FAULT` is left no-connect.** It is the open-drain global fault output for overload, short-circuit, and thermal shutdown — thrown away on a board that has spare pins. | Route to **`GP23`** with a pull-up to `+3.3V_MCU` — **`GP29` until 2026-09-18**, when it moved to free ADC3. The datasheet notes an external pull-up is required to match the MCU supply. **Done, verified 2026-08-17:** `R507` = 10 kΩ to `+3.3V_MCU`, net `~{HV_FAULT}` on `GP29`. |
| 4 | **`LATCH` is left no-connect**, so the device **auto-retries every 2 ms** after a fault. | Tie to `+3.3V_MCU` through a 1 kΩ `RPROT` for latch-off. **Done, verified 2026-08-17:** `R503` = 1 kΩ to `+3.3V_MCU`. **Reversed on the bench 2026-09-02** — the block as originally placed was right and this "fix" broke power-up. `LATCH` belongs on a GPIO. See below. |

Items 2 and 3 were the ones that mattered most: as the block shipped, it gave no
load current reading and no fault signal, which is most of what the smart switch
was chosen for. **All four are now in place on the board**, with item 2 landing on
a GPIO rather than on the rail.

### `DIAG_EN` Must Be A GPIO, Not A Fixed Pull-Up

**Reversed 2026-08-17**; earlier guidance in this document said to tie `DIAG_EN`
to `+3.3V_MCU` through a 1 kΩ `RPROT` and that it "needs no GPIO". As built,
`R502` **10 kΩ** runs from `DIAG_EN` to **`GP14`**, net `HV_DIAG_EN`. `GP14` was a
spare; it is not any more, and the spares are now `GP15`, `GP16`, `GP18`, `GP27`
— four, not five.

The reason is a leakage path the earlier analysis missed, and it defeats the
organising principle of this entire document. Holding `DIAG_EN` high keeps the
`TPS1HTC100-Q1`'s **OFF-state open-load detection permanently enabled**, and that
detection works by switching in an internal pull-up from `VS` to `VOUT`.
Datasheet §7.3.4.2:

> TI implemented a switch in series with the pullup resistor controlled by the
> DIAG_EN pin. The pull up resistor value is Rpu = 150 kΩ

`ROL_OFF` is specified 110-166 kΩ. So with `DIAG_EN` high and the channel off,
**36 V drives ~240 µA into `+36V_SW` through the part**. The consequences follow
directly from the board's own numbers:

| Step | Number |
| --- | --- |
| Injected current at 36 V through 150 kΩ | ~240 µA |
| `+36V_SW` bulk (`C1213` + `C1214` + ceramics) | ~208 µF |
| Rail slew, `I/C` | ~1.2 V/s |
| Time to cross the `TPSM365R6`'s 3.6 V minimum `VIN` | **~3 s** |

At that point the buck starts, draws far more than 240 µA, collapses the rail,
and hiccups — forever. **The switched domain never cleanly powers off.** That
breaks the "`HV_EN` power-cycles every resettable chip" property that
[The High-Side Switch Is A Reset Button](#the-high-side-switch-is-a-reset-button)
depends on, and it corrupts `SW_RAIL_SENSE`, which is the one reading firmware
uses to decide whether the domain is up.

**With `DIAG_EN` on a GPIO the failure disappears at reset, not merely under
firmware control.** `DIAG_EN` has an internal pull-down (200-500 kΩ), so with
`GP14` high-Z at RP2040 reset — which is every GPIO's reset state on this part —
diagnostics are off and `+36V_SW` sits at a true zero.

**What is *not* gated.** Per Table 7-1, `DIAG_EN` gates **reporting only**:
current limit and thermal shutdown are unaffected. Dropping `DIAG_EN` does not
make the switch less safe, it makes it quieter. So the firmware rule is simply:
**raise `GP14` when you want current sense or fault reporting**, and drop it
otherwise. In particular raise it before reading `HV_SNS`, since every `ISNS`
specification is conditioned on `VDIAG_EN` being high.

**The alternative that was considered and not taken:** a 10-15 kΩ bleeder on
`+36V_SW`, which would sink the 240 µA and hold the rail down with `DIAG_EN`
still tied high. It works, but it burns ~100 mW continuously whenever the rail
*is* up, it adds a part, and it leaves the board depending on a resistor value to
preserve a safety property. Spending a spare GPIO is cheaper and the failure mode
is better: a missing GPIO drive means no diagnostics, not a rail that will not
switch off.

### Driving `DIAG_EN` And `LATCH` With `VS` Unpowered Is Fine

The board can run from USB with the 36 V supply absent, so these pins will sit at
3.3 V while the switch's `VS` is at 0 V — `LATCH` permanently, `DIAG_EN` whenever
firmware raises `GP14`. That is in spec, not merely survivable:

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

**Do not confuse this with the analog output DAC's back-powering hazard** described later in
this document. They look similar and are not. TI specifies these pins against
`GND` with their own limits, which is a deliberate design choice for a switch that
must survive losing its supply. The `DAC80501`'s digital inputs are specified
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

The block shipped with 10 kΩ here. **On this board it is `R508` = 40 kΩ, done and
verified 2026-08-17.** The datasheet tabulates the resulting limit directly:

| `R_ILIM` | `I_CL` min | typ | max |
| --- | --- | --- | --- |
| **10 kΩ (as the block shipped)** | 4.0 A | **5.3 A** | 6.3 A |
| 16.7 kΩ | 2.3 A | 3.0 A | 3.5 A |
| **25 kΩ (recommended)** | 1.5 A | **1.96 A** | 2.3 A |
| 50 kΩ | 0.73 A | 0.92 A | 1.11 A |
| Open or GND | 6.1 A | 7.3 A | 8.6 A |

The block's shipped setting was therefore **5.3 A typical, up to 6.3 A** — higher
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

`SNS` also takes a single resistor to ground. The block shipped with 1 kΩ; **on
this board it is `R509` = 249 Ω, done and verified 2026-08-17** —
`OW-PASS-CRCW0402249RFKED`, 0402, 1%, stocked. This supersedes both the 2:1
divider suggested earlier and the "change `R27004` from 1 kΩ to 249 Ω" framing
that appeared elsewhere in this document: there is nothing left to change.
470 Ω would have been the arithmetic ideal but is not stocked, and 249 Ω is
strictly safer.

**Why 249 Ω is right, in numbers.** This document asserted the value without ever
writing the arithmetic down, so here it is:

| Quantity | Value | Where it comes from |
| --- | --- | --- |
| `ISNSFLT` | **5.2-6.4 mA**, a *current source* | `tps1htc100-q1.pdf` |
| Fault reading across `R509` | 5.2-6.4 mA × 249 Ω = **1.3-1.6 V** | arithmetic |
| RP2040 `VPIN` absolute maximum | `IOVDD` + 0.5 = **3.8 V** | RP2040 datasheet |
| Maximum normal-current reading, `KSNS` = 800 A/A, `I_CL` ≈ 1.2 A | **≤0.37 V** | arithmetic |
| `VSNSFH` at `VDIAG_EN` = 3.3 V | **3.3 / 3.95 / 4.4 V** min/typ/max | `tps1htc100-q1.pdf` |

Two conclusions fall out. First, 1.3-1.6 V is comfortably under 3.8 V *and*
comfortably clear of the ≤0.37 V normal reading, so a fault is unambiguous
without needing `~{HV_FAULT}` to confirm it. Second — and this is the part that
mattered — **the original 1 kΩ would have driven `GP28` past its absolute
maximum.** At 1 kΩ the pin hits its clamp rather than `ISNSFLT × RSNS`, and that
clamp is `VSNSFH`, whose *typical* value at 3.3 V `DIAG_EN` is 3.95 V and whose
maximum is 4.4 V. Both exceed 3.8 V. The 1 kΩ recommendation was not merely
suboptimal; it was out of spec for this MCU.

The safe upper bound is about **594 Ω** (3.8 V ÷ 6.4 mA). ~470 Ω would use more
of the ADC range and is still safe, if resolution ever turns out to matter; 249 Ω
trades that for margin, which is the right trade for a coarse supply monitor.

**No series resistor is needed between `SNS` and `GP28`.** `SNS` is a current
source, not a voltage driver — it cannot force a node harder than
`ISNSFLT × R207` once `R509` sets the impedance to ground, so there is nothing
for a series resistor to limit. Adding one would only add ADC source impedance.

The problem being solved: the `SNS` pin reports faults by driving to a defined
high level — the datasheet's "integrated fault sense voltage scaling for ADC"
feature. In fault the pin sources `I_SNSFLT` = 5.2-6.4 mA into `R_SNS`, and the
node settles at whichever is lower, `I_SNSFLT × R_SNS` or the clamp `V_SNSFH`:

| `R_SNS` | Normal scaling, `K_SNS` = 800 | Fault level | Under the RP2040's `VPIN` maximum of `IOVDD + 0.5` = 3.8 V? |
| --- | --- | --- | --- |
| 1 kΩ (as the block shipped) | 1.25 V/A, full scale at 2.6 A | 5.2-6.4 V, clamped to `V_SNSFH` = 3.3 / 3.95 / 4.4 V | **No** — typical and maximum both exceed 3.8 V |
| 604 Ω (stocked) | 0.76 V/A | 3.14-3.87 V | **Marginal** — top of range just exceeds 3.8 V |
| **249 Ω (fitted as `R509`)** | **0.311 V/A**, full scale at 10.6 A | **1.3-1.6 V** | **Yes, with wide margin** |

At 249 Ω the pin never reaches its clamp, so the fault level is set by
`I_SNSFLT × R_SNS` and is bounded by design rather than by tolerance.

Ambiguity is not a concern: with `I_CL` at about 1.2 A the largest legitimate
reading is around 0.37 V, against a fault level of at least 1.29 V — a 3.5×
separation. `~{HV_FAULT}` on `GP23` reports the same condition independently
anyway.

Cost of the change: about a quarter of the signal, using ~11% of the ADC range in
normal operation. That does not matter here, and the reason is in the datasheet:
`I_SNS` accuracy is **±25% to ±30% below 60 mA** and ±5-6% only above about 0.5 A.
This is a coarse supply monitor by construction, so amplitude was never the
binding constraint. 0.311 V/A still gives about 386 ADC counts per amp at 12 bits.

All `SNS` timing and accuracy specifications are characterised at `R_SNS` = 1 kΩ.
~~If that fidelity matters more than simplicity, keep 1 kΩ and add a 100 k / 100 k
divider tap, which loads the 1 kΩ by about 2%.~~ **That option is off the table:**
1 kΩ puts the un-divided node above the RP2040's absolute maximum, so it is only
usable *with* a divider, and a divider costs the two parts and the source
impedance that 249 Ω avoids. **249 Ω is the choice and it is fitted** — one
stocked part, no divider, and the widest ADC margin.

Note also that the `SNS` readings only exist while `DIAG_EN` is high, which on
this board means while firmware is holding `GP14` high. See
[`DIAG_EN` Must Be A GPIO](#diag_en-must-be-a-gpio-not-a-fixed-pull-up).

### Does `R_SNS` Have To Change When `R_ILIM` Does?

**Not below `I_CL` = 3.4 A.** The two resistors do independent jobs, but `R_SNS`
has two ceilings and only one of them scales with the current limit:

| Ceiling | Formula, 3.3 V ADC | Depends on `I_CL`? |
| --- | --- | --- |
| Fault level — the pin sources 5.2-6.4 mA into `R_SNS` | `R_SNS` ≤ 515 Ω to stay inside the 3.3 V ADC range; ≤ **594 Ω** to stay inside the 3.8 V `VPIN` absolute maximum | **No** |
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

> **SUPERSEDED ON THE BENCH, 2026-09-02. `LATCH` must go to a GPIO.**
>
> This section's reasoning about *steady-state* fault behaviour is still right
> and is why the answer is not simply "tie it low". What it missed is that
> latch-off and **power-up** are in direct conflict on this board: the switch
> trips its relative thermal shutdown 1-2 ms into charging `+36V_SW`'s 208 µF,
> at only ~10-12 V, so **auto-retry is the only mechanism that can bring the
> rail up at all**. With `R503` fitted the rail comes up on stored charge and
> collapses 17-68 ms later, every time, on both rig boards.
>
> Depopulating `R503` on board `E4654C159F2C2534` fixed it outright: a plain
> `HV_EN` assertion then works, with a 10-12 ms retry window. Full evidence in
> `docs/bringup-log.md` →
> [The Rail Comes Up And Then Collapses — RESOLVED](bringup-log.md#the-rail-comes-up-and-then-collapses--resolved-2026-09-02).
>
> **v0.4: `LATCH` on a spare GPIO through the same 1 kΩ `RPROT`.** Low for the
> power-up ramp, high once the rail is established. That gets retry-based
> soft-start *and* the latch-off behaviour argued for below, and it defaults to
> auto-retry when the MCU is unpowered or at reset — which is the safe default,
> because that is exactly when the rail has to be able to charge. Until then
> firmware emulates the retry: `PowerSequence::staircaseStart()`.
>
> **Allocated 2026-09-16: `HV_LATCH` on `GP24`**, in the bypass group with the
> rest of the switch's signals, taking the pin that `~{INSTR_BUF_OE}` freed. The
> 1 kΩ `RPROT` is **`R503` inside the vertical HV input block**, whose port is
> plain `LATCH`, so the board owes only the wiring — a sheet pin on `mcu` and
> the root-level net. It was the last spare but one; see
> `docs/interface-map.md`. **The pin had been owed since 2026-09-02 and no
> allocation existed** — this document recorded the fix while the interface map
> still showed `LATCH` strapped, which is how it stayed unallocated for two
> weeks.
>
> Do **not** simply tie `LATCH` low. Read the paragraph below about a joystick
> twitching in an animal's paw — that hazard is real and a permanent tie
> reintroduces it.

Table 4-2 settles it: "With LATCH unused, the device performs an auto-retry after
a fault," and `t_RETRY` is **2 ms**. The internal 0.7-1.3 MΩ pulldown means the
block as placed gets auto-retry.

**On this board that is the wrong behavior _in steady state_.** Auto-retry into a
persistent fault cycles the motor rail at roughly 500 Hz: the TMC5130A repeatedly
browns out and recovers, and a joystick held by an animal twitches while it does.
Nothing upstream stops it. (It is the *right* behaviour during power-up, which is
the conflict this section originally missed.)

**Tie `LATCH` to `+3.3V_MCU` through a 1 kΩ `RPROT`.** Done as `R503`, verified
2026-08-17, **and superseded 2026-09-02 — see the box above.** That selects
latch-off, and the
clearing mechanism fits the board's existing design: "the device does not enable
the channel until either the LATCH pin OR the EN pin is toggled." Firmware already
owns `EN` on `GP19`, so the sequence is:

1. Fault occurs; the switch latches off and the motor rail drops.
2. `~{HV_FAULT}` asserts on `GP23`; firmware latches `SUPPLY_OUT_OF_RANGE`, stops
   motion, and reports it over UART.
3. Recovery requires an explicit `CLRFAULT` followed by toggling `HV_EN`.

That is exactly the "latch faults, require explicit clearing" model in
`.agents/AGENTS.md`, achieved with one resistor and no GPIO — **and it is worth
one GPIO after all**, because the same resistor that buys the model also
prevents the rail from ever coming up. The three-step recovery sequence above is
unchanged by moving `LATCH` to a GPIO; firmware simply drives the pin instead of
relying on a strap.

Driving `LATCH` from a GPIO instead would let firmware choose between behaviors,
but there is no reason to want auto-retry here. Rev 0 has pins free, so the
argument is now purely that auto-retry is the wrong behavior — not that the pin
budget forbids it. **Updated 2026-08-17: the spares are `GP15`, `GP16`, `GP18`
and `GP27` — four, not five,** because `GP14` went to `HV_DIAG_EN`. The budget is
still not the binding argument, but it is one pin tighter than this paragraph
originally claimed, and `LATCH` is the right pin to have spent a resistor on
rather than a GPIO.

### Reverse-Polarity Protection Is The Series Diode, Not The Device Feature

The datasheet says of pin 1: "Ground of device. Connect to resistor-diode ground
network to have reverse battery protection." The block ties `GND` straight to
board ground, so that feature is **not** configured. Reverse protection comes
solely from `D201`, the `SBRT15U50SP5` series diode — anode on `HV_RAW`, cathode
on `HV_IN`, orientation verified 2026-08-17.

That is a valid and simpler choice. Consequences to accept: a forward drop in the
motor current path, and its dissipation. The part is rated 410 mV at 15 A, so
expect roughly 150-250 mV at this board's current. It also means `HV_IN` sits
that much below the supply, which is irrelevant at 36 V.

A useful side effect: because `VIL`/`VIH` on `EN` and `DIAG_EN` are specified "No
GND Network", the logic thresholds above apply directly and 3.3 V drive is in
spec once the `EN` divider is fixed — which it is, `R501` 1 kΩ with `R506` 10 kΩ
to ground.

## Enable, Current Limit, And Sense

The `hv_input_36V_terminal_2pos_5p08_protected` block is not a passive input. It
is a `TPS1HTC100-Q1` smart high-side switch, and as placed it brings **four**
board-level signals — three plus `DIAG_EN`, which was added on 2026-08-17:

| Block label | Board connection | Note |
| --- | --- | --- |
| `ENABLE` | `HV_EN`, RP2040 `GP19`, through `R501` 1 kΩ | Pulled low in the block by `R506` 10 kΩ — **the rail is off until firmware drives it** |
| `DIAG_EN` | `HV_DIAG_EN`, RP2040 **`GP14`**, through `R502` 10 kΩ | **New 2026-08-17.** Internal pull-down, so diagnostics are off at reset and `+36V_SW` sits at true zero. Firmware raises it to read `HV_SNS` or `~{HV_FAULT}`. See [`DIAG_EN` Must Be A GPIO](#diag_en-must-be-a-gpio-not-a-fixed-pull-up) |
| `ILIM` | `R508` 40 kΩ to ground, local to the block | Sets the adjustable current limit, `I_CL` ≈ 1.2 A. Finalise from the motor's stall and inrush behavior |
| `SNS` | `HV_SNS`, RP2040 `GP28` (`ADC2`), `R509` 249 Ω to ground | Analog load-current sense, 0.311 V/A, fault at 1.3-1.6 V. The block **does** populate the sense resistor and the scaling is settled |

Consequences worth stating plainly:

- **The board boots with the motor rail off.** That is the correct safe state
  and it is free. Firmware must raise `HV_EN` deliberately, after configuring the
  driver, and must drop it on fault. Add this to the boot sequence and to the
  fault table.
- `hv_to_5v_tpsm365r6` **is** fed from the switched `+36V_SW` output, on
  purpose, so that dropping `HV_EN` resets the whole switched domain. That would
  make the board unbootable if the MCU were also on that chain — which is exactly
  why the MCU is not: `+3.3V_MCU` comes from USB or pyControl through two ORing
  diodes and never touches the 36 V chain. Verify **both halves** during
  schematic capture. Feeding the MCU from the switched rail is the single most
  likely way to make an unbootable board out of otherwise correct blocks.
- **Diagnostics are off until firmware asks for them.** `GP14` is high-Z at
  reset and `DIAG_EN` has an internal pull-down, so `HV_SNS` reads nothing and
  `~{HV_FAULT}` reports nothing until firmware raises `GP14`. That is deliberate
  — see [`DIAG_EN` Must Be A GPIO](#diag_en-must-be-a-gpio-not-a-fixed-pull-up) —
  and it must be in the boot sequence next to raising `HV_EN`. Current limit and
  thermal shutdown are **not** gated by it; only reporting is.
- The block carries a `PWR_FLAG` (`#FLG027001`), unlike the 24 V terminal
  variant. Do not add a second one on the same net. Exactly one `PWR_FLAG` per
  net, on input and entry nets only.

## Grounding

- One solid ground plane. Analog return for the DAC output and the BNC shell
  kept away from the motor return path. **Added 2026-08-26:** the rev 1 analog
  block must sit **at** its connector — its ESD clamp's ground via has to land
  on the connector ground pin — and the ground pour must be pulled back from
  under the `AMP_FB` summing node, where stray capacitance changes the
  amplifier's compensation. Both are recorded in the block's own description.
- Kelvin connections at the sense resistors, no shared ground path between the
  two shunts, per the TMC5130A datasheet. The project already has a
  `SENSE_KELVIN` netclass — but **note it does not apply here.** On the TMC5130A,
  `BRA`/`BRB` carry the full coil current into `R1203`/`R1204`, so they are sized
  with the motor phases (`MOTOR_2A`, 0.8 mm) rather than as sense nets.
  `SENSE_KELVIN` exists for the TMC5160's separate `SRA`/`SRB` pins. Verified
  2026-08-17.
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
   ~250 mA rather than Rev 0's ~100 mA. **Note the position `R1903` is fitted with
   a jumper as built; no PPTC exists in the parts database yet.**
4. ~~`SNS` scaling and whether the block already populates the sense resistor.~~
   **Closed 2026-08-17.** It populates it: `R509` = 249 Ω, 0.311 V/A, fault at
   1.3-1.6 V. Arithmetic in
   [`SNS` — Also One Resistor](#sns--also-one-resistor-and-a-different-one).
5. ~~Whether the DAC gets a dual-supply level translator (rev 1).~~ **Closed
   2026-08-26: no.** The `DAC80501` specifies `VIH` at 1.62 V minimum flat
   across `VDD` = 2.7-5.5 V, so 3.3 V logic drives it directly at `VDD` = 5 V.
   The bus switch remains the back-powering fix.
6. **Whether a TVS is ever fitted on `HV_IN`** — a bench-measurement item, not a
   purchase item and not a fabrication blocker. None is populated. Decided by the
   Gate B hot-plug measurement; see
   [Transient Headroom](#1-transient-headroom).

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
- `+3.3V_MCU` comes from USB or pyControl only. No always-on converter taps
  `HV_IN`, and the board does not boot on 36 V alone.
- Both ORing diodes are populated. The pyControl branch is no longer conditional.
- Whether the `TMC5130A` tolerates `VCC_IO` present with `VCC` and `VS` absent no
  longer needs an answer: all three are on the switched domain and fall together.
- **Exactly two `5v_to_3v3_tps73733` instances**, one per domain. Decided
  2026-08-13. The switched domain's 3.3 V is not split into analog and digital,
  and `+3.3V_SW` is not subdivided if rev 1 loads grow — a third instance would be
  a new decision, not a pre-approved option.

**Resolved, and no longer a purchase item:** the 36 V TVS. No standard TVS can
protect the `TMC5130A` on a 36 V rail, and the other two parts on that rail do
not need one. Protection comes from the soft-start switch, bulk placement, and
layout. **As built, no TVS is populated** — this and the "order `SMBJ40A`"
passage under [Transient Headroom](#1-transient-headroom) used to contradict each
other; this is the one the board implements. What remains is the bench
measurement, kept as open decision 6 above.

**Resolved 2026-08-17 against the flattened as-built netlist:**

- **`DIAG_EN` is a GPIO (`GP14`), not a fixed pull-up.** The reversal and its
  reason are in [`DIAG_EN` Must Be A GPIO](#diag_en-must-be-a-gpio-not-a-fixed-pull-up).
  Spares drop to four: `GP15`, `GP16`, `GP18`, `GP27`.
- **The 3.3 V rails are spelled `+3.3V_MCU` and `+3.3V_SW`**, and the netclass
  patterns match. Concern 5 is closed.
- **`VAA` is renamed `HV_RAW`.** Concern 6 is closed.
- **`VSA` is on `+5V_SW`, not on `VS`** — a deliberate deviation from the
  datasheet's "normally tied to VS", taken to keep 36 V off the analog supply
  pin, and harmless because `VCC` is external so the internal regulator idles.
- **`+5V_SW` bridges `VCC` and `5VOUT` through `R1202` 10 Ω** — also a deliberate
  deviation, signed off under
  [Internal 5 V Regulator Dissipation](#3-internal-5-v-regulator-dissipation).
  The datasheet's value for that resistor is 2.2 or 3.3 Ω and its position is
  between `5VOUT` and `VCC`; both differ here and both are accepted.
- **The instrumentation buffers are Rev 0 and there are three of them**, not five
  in rev 1.
