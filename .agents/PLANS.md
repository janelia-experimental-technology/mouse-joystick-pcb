# Mouse Joystick PCB Plan

Use this file for work that is multi-step, risky, or likely to span multiple
sessions.

## Current Goal

**Rev 0, rescoped 2026-08-13: get the interfaces on a board and send it to
fabrication.** RP2040 with GPIO isolation, one TMC5130A on a 4-pin motor
terminal, one single-ended encoder on a 5-pin terminal read by the driver only,
one debounced limit switch on a 2-pin terminal, a pyControl UART on RJ-45, and a
36 V switched supply input that doubles as a chip-reset button.

Rev 0 also carries **InstrumentPort-40**, moved back in on 2026-08-16 for
firmware development — see Resolved below.

Deferred to rev 1: the 0-5 V analog angle output, the pyControl TTL event lines,
and the PIO encoder cross-check. Their pins are reserved and no Rev 0 pin moves
when they arrive. **The PIO cross-check was since deleted outright** — see
2026-08-16 below.

**Session-level detail lives in `.agents/handoff.local.md`.** Read it first.

The rig's two-joystick form factor question stays open. This board is the fast
path to a testable system, not a commitment against `../mouse-joysticks-pcb`.

## Context

Source-of-truth sibling repositories:

- `../mouse-joysticks-pcb` — the twin-axis board for the same rig; most of this
  repository's documentation derives from it
- `../orb-weaver-context` — cross-project context and the PCB development plan
- `../board-interfaces` — InstrumentPort-40 and, later, the pyControl connector
  profile
- `../kicad-libs` — symbols, footprints, database libraries, design blocks,
  vendor mappings, KiCad helper tooling
- `../tmc51x0-driver-dev-pcb` — the validated RP2040 + TMC5130A predecessor
- `../mouse-joysticks-mech` — the new-rig mechanical assembly, two joysticks
- `~/Repositories/github/syringe-pump` — pyControl module reference design
- `~/Repositories/kicad/mouse-joystick-pcb` — previous-generation prior art

## Direction History

- **2026-08-10:** `mouse-joystick-pcb` created as one PCB per joystick, RP2040.
- **2026-08-11:** renamed to `mouse-joysticks-pcb` and rescoped to one board for
  both joysticks; Rev 0 descoped back to RP2040 to be buildable now.
- **2026-08-12:** this repository created to carry the single-axis design in
  parallel, because it can be finished sooner. 36 V input instead of 24 V, and
  nothing descoped for pin budget. Both repositories are live.

## Resolved

- **Rev 0 scope, 2026-08-13, amended 2026-08-16.** Interfaces plus the means to
  observe them; DAC and event lines deferred to rev 1, PIO encoder tap deleted.
  `docs/rev0-plan.md`.
- **RP2040 GPIO allocation.** Rev 0 connects 17 of 30 and reserves 8 more at
  fixed numbers; full scope is 25 of 30 with five spares. **No pin moves between
  Rev 0 and rev 1.** `TMC_REF_STIM` was deleted permanently and its pin pays for
  the bus-switch enable on `GP9`. `docs/interface-map.md`.
- **Two power domains, 2026-08-13.** The high-side switch is a reset button:
  everything resettable is on `+36V_SW` → `+5V_SW` → `+3V3_SW`, and the MCU is on
  `+5V_MCU` → `+3V3_MCU` fed from USB `VBUS` or pyControl pin 6 through two ORing
  diodes. The board does not boot on 36 V alone, accepted. Exactly two
  `5v_to_3v3_tps73733` instances, one per domain. `docs/power.md`.
- **GPIO isolation rule.** A GPIO goes through the bus switch if and only if its
  far end is on the switched domain — 7 channels in Rev 0, 12 at full scope. The
  pyControl UART bypasses, so the board stays reachable with the motor rail off.
  The oversized 4-package block is accepted as-is for schedule.
- **pyControl pin 6 is 5 V**, confirmed from the syringe-pump module netlist. Its
  current budget is still unmeasured and is a Gate A item.
- **InstrumentPort-40 is in Rev 0, re-allocated 2026-08-16.** Moved back in for
  firmware development: the port carries both directions of the pyControl serial
  link *tapped at the RJ-45*, the TMC5130A SPI bus, the two firmware triggers, and
  `ENC_A`/`ENC_B`/`LIMIT_SW` — 11 of 18 digital Strands live. The other 7 are
  allocated and unrouted, **4 reserved for the rev 2 brake and torque sensor** so
  those circuits inherit a pinout instead of renegotiating one. The overlay now
  follows the profile's own Preferred Digital Overlays table: TMC bus on the SPI
  slots, pyControl serial on the first UART pair, brake PWM and fault on the
  PWM/fault slots, torque front end on the I2C slots.
  - **`DIG0`, `DIG1`, and `DIG11` are swap slots.** `ENC_A`, `ENC_B`, and
    `LIMIT_SW` hold three of the rev 2 brake/torque slots through Rev 0 and rev 1
    and hand them over at rev 2. They earn the space because none of those signals
    reaches a GPIO in any revision, so the TMC5130A's own registers are firmware's
    entire account of position and homing and nothing can contradict them —
    capturing the raw signals beside the SPI traffic is the only check. These
    slots were chosen because they sit in the rev 2 buffer package, making the
    eviction as late as possible. `ENC_N` stays on a test pad.
  - **No new boundary pins on `pycontrol_behavior_port_rj45_boundary`.** An
    earlier draft called for two, so the port could tap the connector side of
    `R29001`/`R29002`. Rejected 2026-08-16: 330 µA through 100 Ω is 33 mV, so a
    digital channel cannot tell the two sides apart, and the connector-side tap
    would put the buffer input on the unprotected side of the ESD clamp. The port
    uses the existing `PYC_DIO_A`/`PYC_DIO_B` pins at five boundary pins.
  - **But change those two pins from `passive` to `bidirectional`.** It is the
    only connector boundary block in the library with no driving pin — `usb2` and
    `instrument_port_40_dut_ffc_boundary` both use bidirectional for logic — and
    left passive, `PYC_UART_RX` reaches the board with no driver on the net.
  - **Signal directions are now in the allocation table**, as a `Dir` column, and
    every `mcu` sheet pin is listed with its KiCad shape and what it mates with.
    The `DIO-A` → RX / `DIO-B` → TX crossover is drawn explicitly; it is the one
    place on this board where the naming reverses. `~{BUS_SW_OE}` is the only Rev
    0 connected GPIO needing no `mcu` sheet pin — the bus switch is inside that
    sheet.
  - `GP24` `~{INSTR_BUF_OE}` is now live. No pin moved.
  - **Four 100 kΩ pull-downs plus the `SW_RAIL_SENSE` divider are the only new
    passives** — `TMC_SPI_CIPO`, `ENC_A`, `ENC_B`, `LIMIT_SW`. Buffer packages
    `U_A`, `U_B`, `U_E` are fitted; `U_C` and `U_D` are DNP with unrouted inputs.
    `U_E`'s one remaining brake channel has its input tied to GND until rev 2.
  - **It costs layout schedule** — a 40-pin FFC, five buffer footprints, and 18
    more routed nets on the board whose layout was already the long pole.
  - `docs/interface-map.md`, `docs/instrument-strategy.md`.
- **Event-line routing.** Three lines on BNC, two dual jacks plus one. Rev 1.
- **The pyControl port pinout**, from the syringe pump. Cited, not bench-verified.
- **Current sense**, inherited: 0.15 Ω, `vsense = 1`, `IRUN = 28`.
- **Supply voltage:** 36 V, using the existing
  `hv_input_36V_terminal_2pos_5p08_protected` block.
- **TVS on `HV_IN`, for the switch and the buck — not for the driver.** A standard
  TVS cannot clamp under the TMC5130A's 49 V on a 36 V rail, but the switch (70 V)
  and the buck (65 V) are the parts exposed at hot-plug, and they are clampable.
  `SMBJ40A` preferred, stocked `SMF48A` usable now. The driver is protected by
  construction — bulk downstream of the soft-start switch, capped at tens of µF,
  tight `VS` loop — and verified at Gate B.
- **The 36 V input block is clean.** The six edits were verified by netlist review
  on 2026-08-12 — `EN` divider, `DIAG_EN`, `LATCH`, `ILIM` = 40 kΩ, `SNS` = 249 Ω,
  and the `~FAULT` route. **The three defects below were fixed and verified in the
  block on 2026-08-16**: `R27005` now pulls `~{FAULT}` up to `+3.3V_MCU`, and
  `HV_IN` and `SNS` are hierarchical. Kept for the record only — historically,
  `~FAULT` was pulled down
  to `GND` instead of up to `+3V3_MCU`, and `HV_IN` and `SNS` are local labels
  rather than hierarchical, so the board can reach neither. Plus two cheap
  concerns — `C27002`'s 50 V rating on a 36 V rail, and the misleading `VAA` net
  name. The `+3V3_MCU` naming concern was **withdrawn**; naming the rail by its
  domain is correct. All in `docs/power.md`; fix before the block's PCB layout is
  finished.
- **Multi-source logic power, superseded 2026-08-13.** Now two sources only —
  USB `VBUS` and pyControl pin 6 — ORed at `+5V_MCU`, upstream of the MCU
  domain's own LDO. The onboard buck is **not** one of them; it lives on the
  switched domain. The two 5 V rails are separate nets, which is what keeps
  `+5V_SW` in spec for the TMC's `VCC`.

## Blocking Items

**Two remain, and only the second can actually invalidate the board.** Ranked.

1. **Joystick motor part number.** Sets the motor connector, supply envelope,
   `ILIM`, and confirms whether 0.67 A is RMS or peak. Owner: Peter. Also settles
   the `tmc5130` block's bulk-capacitance question, restated here so it survives a
   clone: the block ships **200 µF on `VM`** (`C1213`+`C1214`, 2× 100 µF 50 V,
   `OW-PASS-EEEHAH101UAP`, D8×10.2 mm) sitting on switched `+36V_SW`, where
   `docs/power.md` bounds bulk at "tens of µF, not hundreds". 200 µF at 36 V is
   **130 mJ** per `HV_EN` turn-on into an HTSSOP-14. **Unresolved.** Options:
   depopulate `C1214` (65 mJ), keep both and verify a clean turn-on cold and hot
   at Gate B, or decide once the motor is identified. 50 V on 36 V is 1.39×, and
   110 mA ripple each is thin for motor bulk.
2. **Encoder part.** **Largely resolved 2026-08-17 — no longer gates the
   schematic, and no longer gates fabrication.** The receive path is decided and
   built: single-ended 5 V push-pull, conditioned by the new
   `quadrature_encoder_input_5v_sn74lvc2g17` block. Confirmed against the
   encoder's own spec (4.5-5.5 V supply, 25-42 mA, `VOH` ≥ 2.4 V at −8/−5 mA,
   `VOL` ≤ 0.4 V, tr 100 ns / tf 50 ns), which closes against the SN74LVC2G17's
   `VT+` ≤ 2.0 V and `VT−` ≥ 0.8 V with 400 mV of margin on both rails.

   What still needs the part number, and **only** this: **CPR and maximum shaft
   RPM**, to confirm the `C802`/`C803` filter value. They are fitted at 470 pF,
   which covers a channel frequency up to 44.9 kHz — `f_ch = CPR × RPM / 60`.
   Note the number to size against is the fastest **motor-commanded** move
   (homing, recentering), not how fast the mouse pulls; the animal is the slow
   case. A low-pass has no lower limit, so slower motion never requires a
   different value — only a faster axis would. Sizing table with `R = 4.7 kΩ`:

   | Cap | f_c | max `f_ch` | atten @10 MHz |
   | --- | --- | --- | --- |
   | 27 pF | 1.09 MHz | 685 kHz | −19 dB |
   | **470 pF (fitted)** | 71.4 kHz | **44.9 kHz** | −43 dB |
   | 1 nF | 33.7 kHz | 21.2 kHz | −49 dB |
   | 2.2 nF | 15.3 kHz | 9.7 kHz | −56 dB |

   Verify at bring-up by scoping `ENC_A_FILT` during the fastest commanded move.
   Both channels must keep the same value so A/B propagation delay stays matched.
   Still open from the part choice: whether the encoder has an index channel —
   `J1102` pin 2 is reserved for it, and `ENCN` is currently tied to GND through
   `R1201`. Also confirm the 25-42 mA draw lands in `docs/power.md` (it is ~7% of
   the TPSM365R6's 600 mA).
3. Board outline and mounting. `../mouse-joysticks-mech` is a two-joystick
   assembly, so how a per-axis board mounts is a decision — but pick a rectangle
   and move on rather than blocking the fab order on it.

**Not blocking, but do not lose:** netclass patterns match none of this board's
rail names, and the `rp2040` block exposes no `RUN`/`SWD`. Both are carried as
findings B and G in **Open Schematic Findings** below, which is the tracked
record. (`.agents/handoff.local.md` is gitignored and will not be present on a
fresh clone — do not rely on it.)

**Resolved 2026-08-13, no longer blocking:**

- DAC8563 `VIH` — deferred with the DAC to rev 1.
- Where `+3V3_MCU` comes from — USB or pyControl only, two diodes, no always-on
  converter on `HV_IN`.
- The TMC's switched `VCC_IO` — it is on `+3V3_SW` from the second LDO, so all
  three TMC supplies fall together and the pin-34 ordering holds by construction.
- `D3`, the pyControl 5 V branch — populated. It is one of only two sources that
  power the board, so it is no longer conditional.
- `EXT_FAULT_IN` on `GP27` — rev 1, since Rev 0 has no `FAULT` output to
  cross-wire.
- The regulator feed point — post-switch, deliberately.

Items 1-2 are shared with `../mouse-joysticks-pcb`. Answer them once and record
the answer in both.

**Reopened and narrowed, 2026-08-12: the 36 V TVS.** It belongs on `HV_IN` to
protect the switch and the buck at hot-plug, not on the motor rail to protect the
driver — nothing can do the latter at 36 V. `SMBJ40A` is the part to order, and
the stocked `SMF48A` works for first boards, so it is **not a fabrication
blocker**. See `docs/power.md`.

## Open Schematic Findings — re-reviewed 2026-08-17 (pre-layout)

Second full review, run after the `quadrature_encoder_input_5v_sn74lvc2g17` block
was integrated. This section is **self-contained on purpose** — it is the tracked
record, and `.agents/handoff.local.md` is gitignored and will not survive a clone
onto another machine. Everything needed to act is here.

### Current verification state

**ERC is clean: 0 violations at every severity** (was 9 errors + 129 warnings).
133 components, no duplicate refdes, every part has a footprint assigned.

Reproduce:

```sh
export ORB_WEAVER_KICAD_LIBS=$HOME/Repositories/orb-weaver/kicad-libs
kicad-cli sch erc -o /tmp/mj-all.rpt kicad/mouse-joystick-pcb.kicad_sch
kicad-cli sch export netlist --format kicadxml -o /tmp/mj.xml \
  kicad/mouse-joystick-pcb.kicad_sch
```

**ERC cannot see the two blockers below.** Both were found by walking the
flattened netlist, and both will still pass ERC after any edit — re-check them by
netlist, not by ERC.

### Blockers — do not route with these open

- [ ] **A. `TMC_DIAG1` does not cross the isolation barrier, and is shorted to
  GND.** The two halves land on different bus-switch channels:
  - `/TMC_DIAG1` (`U1201.27`) → `U603.2` (A1). U603's mating **B1 is pin 18 =
    `/GND`**, so with `~BUS_SW_EN` asserted the TMC's DIAG1 output drives into a
    hard ground.
  - `/mcu/TMC_DIAG1_` (`U501.11`, `GPIO8`) → `U602.18` (B1). U602's mating **A1
    is pin 2 = net `A17`, dangling.**

  Root cause is in `kicad-libs`, not this repo: in
  `design_blocks/orb_weaver_private.kicad_blocks/rp2040_gpio_isolation_sn74cb3q3245.kicad_block`
  the A-side and B-side label numbering are crossed on the two middle switches.
  The four SN74CB3Q3245 sit in a 2x2 grid:

  | Chip | position | A labels | B labels | |
  | --- | --- | --- | --- | --- |
  | U601 | top-left | A1–A8 | B1–B8 | consistent |
  | U603 | top-right | A9–A16 | **B17–B24** | crossed |
  | U602 | bottom-left | A17–A24 | **B9–B16** | crossed |
  | U604 | bottom-right | A25–A32 | B25–B32 | consistent |

  So for every channel 9–24, `An` and `Bn` are on different physical chips and
  never connect. Fix the block labels in `kicad-libs` and re-place, **or** rewire
  `TMC_DIAG1` at board level onto a matched pair on U601 (which is wired
  correctly). If you fix the block, audit every other `An`/`Bn` pair on this board
  before trusting it.

- [ ] **B. Netclass patterns match none of this board's rails.** All 26 power and
  bus nets fall to `Default`, including `/+36V_SW` (the motor rail), `/+5V_SW`,
  `/+3.3V_SW`, `/+5V_MCU`, `/+3.3V_MCU`, `/HV_RAW`. Only `/GND` and one nested
  `HV_IN` match any of the 108 inherited patterns. DRC will **not** complain; it
  will simply route the 36 V motor rail at Default width. Add glob patterns to
  `kicad/mouse-joystick-pcb.kicad_pro` before routing — suggested shape in
  `.agents/handoff.local.md` section 3 if present, otherwise: `+5V*` → `PWR_5V`,
  `+3.3V*` → `PWR_3V3`, `+36V*` → `PWR_HV_BUS`, `HV_IN`/`HV_RAW` →
  `PWR_HV_ENTRY`, with `*/+5V*`-style variants for the nested local copies.

### Fix before layout

- [ ] **C. `GP1` pull-up still missing.** `/PYC_UART_RX` = `R1901` (100 Ω series,
  inside the port block) + `U1601.9` + `U501.3`. There is no 10 kΩ to
  `+3.3V_MCU`, so `GP1` floats whenever no pyControl cable is plugged in. Board
  level part, near the RP2040: **10 kΩ 0402, `OW-RES-10K-0402`, from
  `PYC_UART_RX` to `+3.3V_MCU`.** Rationale in `docs/interface-map.md` →
  "`GP1` Gets A Hardware Pull-Up".

- [ ] **D. Five instrumentation buffer inputs float when the switched domain is
  off.** `U1601`/`U1701`/`U1801` are all supplied from `+3.3V_MCU` (always on),
  but these five sources are on the switched domain:

  | Input | Net | Source |
  | --- | --- | --- |
  | `U1701.1A/2A/3A/4A` | `TMC_SPI_SCK` / `COPI` / `CIPO` / `~TMC_CS` | TMC (switched) + bus-switch A side |
  | `U1801.1A` | `LIMIT_SW` | `U1301` MAX6816 on `+3.3V_SW` |

  The SPI four are the worse case — they float in **two** states: switched domain
  off, and bus switch isolated (the A side goes high-Z). Either add 100 kΩ
  pull-downs (`OW-PASS-RC0402JR-07100KL`) the way the encoder block does, or move
  `U1701`/`U1801` to `+3.3V_SW`. The encoder pair is already covered by
  `R805`/`R806` inside the new block.

- [ ] **E. `X1201` pin 1 (`Tri-State`) floating.** 16 MHz oscillator output
  enable, left open. Tie to `+3.3V_SW`.

- [ ] **F. `PMC_UART_TX_BUF` / `PMC_UART_RX_BUF` typo — still present.** Four
  labels in `kicad/instrument_port.kicad_sch` at lines 594, 624, 734, 804. Should
  be `PYC`. Confirmed still in the exported netlist.

- [ ] **G. No reset and no SWD.** `U501` `RUN` (26), `SWCLK` (24), `SWD` (25) are
  all unconnected, because the `rp2040` block never exposed them. `J10`, listed as
  a Rev 0 connector in `docs/interface-map.md`, is therefore not buildable, and
  the only way into BOOTSEL is unplugging both USB and pyControl. Decide
  deliberately: edit the block to expose them, or accept and record the
  limitation.

- [ ] **H. Bus switch direction versus the docs.** A = TMC/switched side, B = MCU
  side, which is inverted from `docs/interface-map.md`. The encoder taps no longer
  care (they now come off the block's buffered 3.3 V output), but the SPI and
  `LIMIT_SW` instrument taps still sit on the switched A side — which is what
  finding D is about. Pick a direction and make the doc agree.

- [ ] **I. Buffer grouping differs from the documented one.** Actual grouping is
  `U1601` = ENC_A / ENC_B / PYC_UART_RX / PYC_UART_TX, `U1701` = SPI SCK / COPI /
  CIPO / ~CS, `U1801` = LIMIT_SW / FW_TRIG0 / FW_TRIG1 / spare-to-GND. Not a
  defect — accept and update the doc, or regroup.

### Resolved since the first 2026-08-17 review — do not re-derive

- **Sense resistors.** `R1203`/`R1204` are now 0.15 Ω. Still record `vsense = 1`,
  `IRUN = 28` alongside.
- **TMC `SWSEL`** tied to GND (`U1201.28` → `/GND`); `REFR` carries an explicit
  no-connect.
- **Off-grid wire endpoints** and both `pin_not_connected` errors cleared.
- **`PWR_FLAG` on `+5V_MCU`** — no `power_pin_not_driven` remains.
- **Encoder input conditioned.** `quadrature_encoder_input_5v_sn74lvc2g17` is
  placed: `U801` (SN74LVC2G17 dual Schmitt) on `+3.3V_SW`, `R801`/`R802` 100 kΩ
  harness-side pull-downs, `R803`/`R804` 4.7 kΩ series, `C802`/`C803` **470 pF**
  filters, `R805`/`R806` 100 kΩ output pull-downs. `ENC_A`/`ENC_B` now reach both
  the TMC and the instrument tap as clean 3.3 V logic. Connector `J1102` is a
  5-position terminal with **pin 2 reserved for a future index channel**.
- **`ENCN` tied.** `R1201` 10 kΩ from `U1201.23` to GND, satisfying the TMC5130A
  datasheet requirement to pull it to GND or `VCC_IO` when unused.
- **`SW_RAIL_SENSE` divider.** `R401`/`R402` 1 kΩ/1 kΩ from `+3.3V_SW` to GND with
  the tap on `GP26`/`ADC0`. 500 Ω source impedance is well inside the RP2040 ADC
  requirement. Draws 1.65 mA continuously from the switched rail — acceptable.
- **Shadow labels deleted** — no `multiple_net_names` warnings remain.
- **All 125 `lib_symbol_mismatch` warnings cleared.**

### Verified correct — do not re-derive

InstrumentPort mapping (all 11 Rev 0 Strands); the two-domain power architecture
(`+5V_MCU` ORed from USB `D301` and pyControl `D1901` into `U701`; `+5V_SW` from
`U901`; `+36V_SW` from `U201`; four distinct rails, one source each, the two 5 V
rails never meeting); the `DIO-A`→RX / `DIO-B`→TX crossover; buffer supply and
enable wiring; per-instance annotation; no global power symbol that could merge
domains; and `R601` (7.87 kΩ) pulling `~BUS_SW_EN` high to `+3.3V_MCU` so the bus
switches **default to isolated at reset**.

Checked and explicitly **not** defects — do not chase these: `U901` `BOOT`/`SW`
unconnected (the TPSM365R6 bootstrap capacitor is internal, per its pin table);
`U1201` `SPI_MODE` pin 12 floating (internal 166 kΩ pull-up defaults it HIGH =
SPI, which matches `SD_MODE`=0 and `SWSEL`=0); `U1201` `AIN_IREF` pin 30 floating
(`GCONF.I_scale_analog` resets to 0, so the internal reference is used);
`R1805.2` dangling (spare 12th buffer channel, its input grounded); `J1102` pin 2
(reserved index, NC-flagged); `J301` SBU1/SBU2; `J1901` pins 3/5/7/8; the TMC
`DNC` pins; spare RP2040 GPIOs; and the LDO `NR` pins.

## Milestones

1. ~~Scaffold the repository and write the design record.~~ **Done 2026-08-12.**
2. Answer blocking items 1-5.
3. Prove `hv_input_36V_terminal_2pos_5p08_protected` in a scratch project with
   ERC. It has never been placed on any board.
4. Compose the schematic from existing `kicad-libs` blocks, in the order in
   `docs/rev0-plan.md`.
5. ~~Design the two sections Rev 0 needs that do not exist as blocks: the
   pyControl port boundary and the debounced limit input.~~ **Done 2026-08-15
   and 2026-08-16**, both with saved PCB layouts, both still project-local
   pending bench verification. The event BNC group and the DAC output section
   move to rev 1 with the functions they serve.
6. Freeze the GPIO allocation and the instrument overlay against the schematic.
7. Run ERC/DRC, generate fabrication outputs, order.
8. Bench bring-up against Gates B through D. The 36 V transient measurement at
   the TMC5130A `VS` pins is the one that justifies or condemns the supply
   choice.
9. Native pyControl integration against Gate E, adapting
   `pump_controller.py` as the device-class template.
10. Record results in `docs/bringup-log.md`, against the board serial.

## Verification

Ready for active PCB work when:

- the motor and encoder parts are identified;
- ~~the DAC logic-level question is settled~~ **deferred to rev 1**;
- the bulk-capacitance placement and snubber footprint are decided;
- ~~the `+3V3_MCU` source and the switched `VCC_IO` rail are decided~~
  **done 2026-08-13**;
- ~~the Guix pin, Makefile, and KiCad scaffold exist~~ **done**; `make validate-db`
  still to be run once in the managed shell;
- Gate A items in `docs/validation-plan.md` have explicit status.

## Progress Log

- 2026-08-17 (later): **Re-reviewed the schematic after integrating the new
  encoder block. ERC is now clean at every severity — 0 violations, down from 9
  errors and 129 warnings.** 133 components, no duplicate refdes, every part
  footprinted. Ten of the twelve original findings are closed, including the
  encoder input, which is now conditioned by
  `quadrature_encoder_input_5v_sn74lvc2g17` (SN74LVC2G17 dual Schmitt on
  `+3.3V_SW`, 4.7 kΩ series, 470 pF filters, 100 kΩ pull-downs on both the harness
  and output sides) with `ENCN` tied to GND through `R1201`. The rail-sense divider,
  sense resistors, `SWSEL`, shadow labels, off-grid endpoints, `PWR_FLAG`, and all
  125 symbol mismatches are resolved.
  **Two blockers remain and neither is visible to ERC** — both were found by
  walking the flattened netlist and both will keep passing ERC after any edit.
  First, `TMC_DIAG1` never crosses the isolation barrier and is shorted to GND:
  its two halves land on different bus-switch channels because the
  `rp2040_gpio_isolation_sn74cb3q3245` block in `kicad-libs` cross-maps its A and
  B labels on the two middle switches. Second, netclass patterns still match none
  of this board's rails, so the 36 V motor rail would route at Default width.
  Then seven pre-layout items: the `GP1` pull-up, five floating buffer inputs on
  the switched domain, `X1201`'s floating enable, the `PMC`/`PYC` typo, no
  reset/SWD, bus-switch direction versus the docs, and buffer grouping. Full
  detail with refdes, pin numbers, and repro commands in **Open Schematic
  Findings** above — written self-contained because `handoff.local.md` does not
  travel between machines. Sharpened Blocking Item 2: the encoder part no longer
  gates the schematic, only the `C802`/`C803` filter value.

- 2026-08-17: **Reviewed the completed Rev 0 schematic.** Ran `kicad-cli sch erc`
  plus a flattened-netlist check against `docs/interface-map.md`. **The
  InstrumentPort mapping is exactly right** — all 11 Rev 0 Strands where the
  allocation says — and the power architecture verifies clean: `+5V_MCU` fed only
  by `+5V_USB` and `+5V_PYC`, `hv_to_5v_tpsm365r6` on `+36V_SW`, the MCU LDO on
  `+5V_MCU`, the two 5 V rails never meeting, and the `DIO-A`→RX / `DIO-B`→TX
  crossover the right way round. Annotation is per-instance distinct across the
  twice-placed LDO sheet, and there are no global power symbols, so no
  cross-domain name collision is possible.
  **Twelve findings, five of them blockers**, all recorded in
  `.agents/handoff.local.md` with reproduction steps: sense resistors still
  0.12 Ω; TMC `SWSEL` floating; two `pin_not_connected` errors caused by
  off-grid wire endpoints; no `PWR_FLAG` on `+5V_MCU`; and the encoder input bare
  with `ENC_N` unwired and a 5 V-supplied encoder feeding 3.3 V TMC inputs.
  Then: `SW_RAIL_SENSE` tied bare to `GP26`, the bus switch wired A/B inverted so
  the instrument taps sit on the switched side, no pull resistors anywhere yet,
  `+3.3V`/`+5V` local labels shadowing the hierarchical names, a `PMC`/`PYC`
  typo, a buffer grouping that differs from the documented one, and 127
  `lib_symbol_mismatch` warnings.
  Corrected two design-record items that the review found the board disagreeing
  with, rather than leaving the docs lying — see Resolved.

- 2026-08-16 (later): **Cut the encoder and limit switch off the MCU, and
  retargeted the rail sense.** `ENC_A`/`ENC_B`/`ENC_N` and `LIMIT_SW` now reach
  the TMC5130A and nothing else, in every revision — the driver owns them and
  firmware reads position and homing from its registers over SPI. That frees
  `GP14`, `GP15`, `GP16`, and `GP18`, taking Rev 0 to **17 of 30** and full scope
  to **25 of 30 with five spares**. It **deletes rather than defers** the PIO
  encoder cross-check, `ENCODER_MISMATCH`, and the `GP14`-`GP16` contiguity
  constraint; the fault code is retired and its bit left permanently reserved.
  Isolated channels dropped from 8/16 to **7/12**, which makes the four-package
  bus-switch block twice the size it needs rather than a bit over — still
  accepted on schedule grounds, now recorded as a larger waste.
  **`LIMIT_SW` joined the InstrumentPort** on `DIG11`, a third swap slot
  alongside `ENC_A`/`ENC_B`, taking Rev 0 to **11 of 18 Strands** and three fitted
  buffer packages. With no GPIO copies, those taps are the board's only
  independent witnesses to what the driver is being fed; they are also the last
  ones, since nothing replaces them at rev 2. Fourth 100 kΩ pull-down added for
  `LIMIT_SW`.
  **`GP26` went from `V5_SENSE` on divided `+5V_SW` to `SW_RAIL_SENSE` on a ÷2
  divider off `+3V3_SW`** — same two resistors, end of the chain, so one reading
  confirms 36 V, 5 V, and 3.3 V. It is *not* redundant with the TMC answering
  SPI, which was the tempting argument: SPI reaches the driver through the bus
  switch the sense exists to gate, so that check is circular. `~{HV_FAULT}` does
  not cover it either — with no 36 V the switch is unpowered and its open-drain
  output reads as no fault. `HV_SNS` does cover most of it, and that is recorded
  as the fallback if the pin is ever wanted elsewhere.
  **Rev 2 may now fit on RP2040** — five spares against roughly six needed for
  brake and torque on one axis, five if `TQ_DRDY` is dropped. Recorded as an
  observation to check, not a commitment.
  Updated `interface-map`, `rev0-plan`, `power`, `uart-protocol`,
  `instrument-strategy`, `design-block-map`, `validation-plan`, `bringup-log`,
  `README`, `.agents/AGENTS.md`, the handoff, and this file.

- 2026-08-16: **Moved InstrumentPort-40 into Rev 0 and re-allocated all 18 digital
  Strands.** The port is now justified by firmware development rather than by
  experiments — both directions of the pyControl serial link, tapped at the
  RJ-45, plus the TMC5130A SPI bus in one capture. **10 Strands live at
  fabrication, 8 allocated and unrouted, 4 reserved for the rev 2 brake and torque
  sensor** so those circuits inherit a pinout. `ENC_A`/`ENC_B` borrow two of the
  reserved slots — `DIG0`/`DIG1`, in the rev 2 buffer package so the eviction is
  as late as possible — because the driver's `X_ENC` register is the only encoder
  count Rev 0 has and the raw edges are the only way to check it decodes
  correctly. `ENC_N` went to a test pad. The new allocation also follows the v0.3
  profile's own Preferred Digital Overlays table much more closely than the
  superseded one did. Decided the three tap points — the existing
  `PYC_DIO_A`/`PYC_DIO_B` pins for the pyControl serial, A side of the bus switch
  for the TMC, driver side of the filter for the encoder — and the three 100 kΩ
  pull-downs they need, on `TMC_SPI_CIPO`, `ENC_A`, and `ENC_B`. **Proposed and
  then rejected** a connector-side pyControl tap needing two new boundary pins: a
  digital channel cannot resolve 33 mV across the block's 100 Ω, and the tap would
  have sat on the unprotected side of the ESD clamp. Regrouped the five buffer packages so each
  revision populates whole packages and no CMOS input floats: `U_A`/`U_B`/`U_E`
  fitted, `U_C`/`U_D` DNP, `U_E`'s two brake inputs GND-tied until rev 2. `GP24`
  went live with no pin moved. Corrected the
  old claim that six slots carried signals Rev 0 does not have — only the three
  DAC wires were genuinely absent. Updated `interface-map`, `design-block-map`,
  `instrument-strategy`, `rev0-plan`, `validation-plan`, `bringup-log`, `README`,
  `.agents/AGENTS.md`, the handoff, and this file. Then added a `Dir` column to
  the GPIO table and a "Signal Direction And Sheet Pin Types" section giving every
  `mcu` sheet pin its KiCad shape, what it mates with, and the far side's declared
  shape — surveyed from the blocks rather than assumed. **`kicad-libs` needs one
  small change:** `PYC_DIO_A`/`PYC_DIO_B` from `passive` to `bidirectional`. Not
  yet done: that, and every bit of the schematic and layout work itself.
- 2026-08-14: **Built three `kicad-libs` blocks and closed the pin 6 budget
  question.** Added the ORing diode to `usb2` exposing both `VBUS` and
  `+5V_USB`; created `limit_switch_debounced_input` and
  `pycontrol_behavior_port_rj45_boundary`. Traced the pyControl 5 V supply from
  the **host** side in `~/Repositories/github/pycontrol-h7-breakout`: a shared
  **1.0 A** RECOM `R-78E5.0-1.0` feeding all ten ports, the terminal block, and
  the controller's own `AMS1117-3.3`, with no per-port fuse — so blocking item 3
  is answered, and its real consequence is a **new polyfuse requirement** on this
  board's pin 6 branch. Also corrected the pinout: pin 5 is `DIO-C` on eight of
  ten ports and a `POW-C` sink driver on two, not "`SPECIAL`", and pins 3/7 are
  driver outputs, which kills the "use `POW-A`/`POW-B` for event lines"
  fallback. Decided a **hardware 10 kΩ pull-up on `GP1`** rather than relying on
  firmware. Mirrored the pinout findings into `../mouse-joysticks-pcb`.
  **Rev 0 was not finished and not ordered.** A netlist audit found the schematic
  much less connected than `README.md` claims — the `mcu` sheet has no sheet pins
  at root, so there are three separate GND nets, the isolation block is entirely
  unwired, and all 30 GPIOs are unwired. Full state and a ranked action list are
  in `.agents/handoff.local.md`, which did not exist before today despite being
  referenced here and in `.agents/AGENTS.md`.
- 2026-08-13: **Rescoped Rev 0 to the interfaces only** and rewrote the design
  record around it — `interface-map`, `rev0-plan`, `design-block-map`, `README`,
  plus scope banners on the eight docs describing deferred subsystems. Rev 0
  connects 17 of 30 GPIOs and reserves the rest at fixed numbers, so rev 1 adds
  the DAC, the PIO encoder tap, the event lines, and the InstrumentPort without
  *(counts superseded 2026-08-16)*
  moving a pin. Dropped `TMC_REF_STIM` permanently to pay for the bus-switch
  enable on `GP9`. Confirmed the whole Rev 0 connector complement is stocked in
  one 3.5 mm terminal family, and flagged that it is screw, not locking.
- 2026-08-13: **Adopted the two-domain power architecture.** The high-side switch
  is a researcher-facing reset button, so the regulator chain is fed
  *post*-switch and the MCU is fed from USB `VBUS` or pyControl pin 6 through two
  ORing diodes, never from the 36 V chain. Exactly two `5v_to_3v3_tps73733`, one
  per domain. This **reversed the pre-switch guidance** in `power.md` and
  `.agents/AGENTS.md`, and dissolved three open items at once: the `+3V3_MCU`
  source, the switched `VCC_IO`, and whether the TMC tolerates `VCC_IO` without
  `VCC`/`VS`. Confirmed pyControl pin 6 is 5 V from the syringe-pump netlist; its
  current budget stays unmeasured.
- 2026-08-13: **Rewrote the GPIO isolation rule** to follow the far end's power
  domain rather than an ad-hoc list. The pyControl UART now bypasses the bus
  switch, so the board stays reachable with the motor rail off — the earlier
  write-up had it isolated, which defeated the purpose. 8 isolated channels in
  Rev 0, 16 at full scope. Accepted the oversized 4-package block for schedule.
- 2026-08-12: Created the repository. Seeded `.guix/`, `Makefile`, agent shims,
  and an empty KiCad 10 project from `../mouse-joysticks-pcb`, renamed
  throughout. Wrote the design record: `rev0-plan`, `interface-map`, `power`,
  `design-block-map`, `relationship-to-twin-axis-board`, `pycontrol-port-pinout`,
  `pycontrol-interface`, `uart-protocol`, `encoder-analog-output`,
  `instrument-strategy`, `validation-plan`, `bringup-log`, `prior-art`.
- 2026-08-12: Derived the RP2040 allocation — 27 of 30, 3 ADC-capable spares,
  nothing descoped — and the InstrumentPort-40 overlay, which fills all 18
  digital slots. Gave the DAC SPI bus two slots so the analog angle output can be
  verified against the encoder from a single capture.
- 2026-08-12: Added `orb_weaver_smd:Texas_HTSSOP-14-1EP_..._ThermalVias_JLCPCB` to
  `kicad-libs`. The stock footprint's thermal *pad* was already correct; the via
  array was missing, and KiCad's official `_ThermalVias` variant fails this
  project's DRU with 15 `drill_out_of_range` errors (0.2 mm drills vs a 0.3 mm
  `min_through_hole_diameter`). Enlarging only the drill would breach the 0.18 mm
  PTH annular rule, so the local variant uses 0.7 mm pads / 0.3 mm drills
  (0.20 mm annular) with the y-pitch tightened to 1.0 mm to keep the outer pads
  inside the 5 mm pad. DRC-verified clean, and **assigned at source** on
  Peter's instruction: three `db/source/` CSVs plus the symbol default, then
  `make build-db`. Placed instances are copies and still carry the old footprint —
  Update Symbols from Library is needed in the two hv_input blocks, the mining
  example project, and **`tmc51x0-driver-dev-pcb`**, which places the 24 V
  barrel-jack block and will gain thermal vias on its next update. Its
  `fp-lib-table` already carries `orb_weaver_smd`.
- 2026-08-12: **Reversed the `VSA` → `VM` recommendation.** The external 5 V on
  `VSA` exists to bypass the internal linear regulator, which the datasheet
  explicitly sanctions ("a different (lower) supply voltage can be used for VSA")
  and which matters thermally: the regulator can contribute up to 1 W at 46 V, and
  even with `VCC` external it would add a few hundred mW to a package already
  dissipating ~0.45 W of bridge `I²R`. So `VSA` stays on `+5V` and **`+5V` is
  switched with `+36V`**. Cheapest way to get every ordering right: feed
  `hv_to_5v_tpsm365r6` from the **switched `+36V`**, which reverses the earlier
  pre-switch recommendation for that buck. **Consequence to plan for:** the TMC's
  `VCC_IO` cannot sit on the always-on MCU rail, because an always-on `VCC_IO` with
  a switched `VCC` is the order pin 34 forbids — so there are two 3.3 V domains,
  `+3V3_MCU` always on and a switched 3.3 V for `VCC_IO` alone. That makes the
  `+3V3_MCU` name load-bearing rather than merely descriptive. **New open item:**
  where `+3V3_MCU` comes from when only the 36 V supply is connected.
- 2026-08-12: Settled the "do not power the TMC5130A without VM" question against
  rev 1.21, and it lands on a different pin than expected. **`VCC` must come up
  EARLY**, not late — pin 34: "make sure, that VCC comes up before or in parallel to
  5VOUT or VCC_IO, whichever comes up later". So `VCC` alive with `VS` = 0 is the
  permitted direction, and the buck→LDO cascade guarantees `VCC` before `VCC_IO` by
  construction. **The real violation is `VSA`:** the `tmc5130` block ties `VSA`
  (pin 39) to `+5V` while `VS` goes to `VM`, and the absolute maximum is
  `V_VSA` ≤ `V_VS` + 0.5 V. With the buck fed pre-switch, `VSA` sits 4.5 V over that
  limit every time the motor rail is off — the boot state and the safe state. Fix is
  to tie `VSA` to `VM`, the datasheet's "normally tied to VS"; costs ~0.15 W in the
  internal regulator because `VCC` is fed externally. **Rejected switching the 3.3 V
  rail**: the MCU runs on it and drives `ENABLE`, so that is a deadlock. Also noted
  `R4002` is 10 Ω where the datasheet recommends 2.2-3.3 Ω between `VCC` and
  `5VOUT`. This is a shared change to the `tmc5130` block.
- 2026-08-12: **Withdrew the `+3V3_MCU` rename recommendation.** The pull-ups on
  `DIAG_EN`, `LATCH` and `~FAULT` must reference the rail the MCU itself uses, so
  naming the rail by its domain is correct and more precise than `+3.3V`. Only
  consequence: `5v_to_3v3_tps73733` emits `+3.3V`, so the two names need reconciling
  at board level and a netclass pattern added.
- 2026-08-12: Reviewed `hv_input_36V_terminal_2pos_5p08_protected` after the first
  round of edits (refdes renumbered; a `.kicad_pcb` now exists). **Correct:** the
  `EN` divider is now 1 kΩ series + 10 kΩ pulldown giving 3.0 V; `DIAG_EN` and
  `LATCH` are pulled to `+3V3_MCU` through 1 kΩ `RPROT`; `ILIM` = 40 kΩ;
  `SNS` = 249 Ω; diode orientation, both capacitor placements, thermal pad to
  `GND`, `NC` left open, `PWR_FLAG` on `HV_IN`, and the HTSSOP-14 PowerPAD
  footprint all check out. **Three defects:** `R27005` pulls `~FAULT` to `GND`
  instead of `+3V3_MCU`, so the open-drain output idles low and never presents a
  valid high; `HV_IN` is a local label, so the board cannot tap the unswitched node
  for the buck feed or the TVS; and `SNS` is a local label, so the current sense
  cannot reach `GP28`. **Three concerns:** `C27002` is 50 V on a 36 V rail where
  `C27001` is 100 V, and `VOUT` is specified to −60 V during inductive turn-off;
  `+3V3_MCU` will not connect to the board's `+3.3V`; and `VAA` names a pin the
  part does not have. ERC is clean — 32 violations, all library-path or
  isolated-fragment artifacts.
- 2026-08-12: Checked the six input-block edits against actual stock and the parts
  database. **Neither 470 Ω nor 24.9 kΩ is stocked**, so the values changed again:
  `R27004` → **249 Ω** (`OW-PASS-CRCW0402249RFKED`, fault level 1.29-1.59 V, even
  safer than 470 Ω would have been) and `R27003` → **40 kΩ**
  (`OW-PASS-SCR0603F40K`, `I_CL` ~1.2 A), with 2 × 49.9 kΩ in parallel as the
  25 kΩ / 1.96 A fallback. Every value now in use is stocked and already promoted,
  so the block edits carry no lead time. Confirmed the SNS amplitude loss is
  irrelevant because `I_SNS` accuracy is ±25-30% below 60 mA anyway.
- 2026-08-12: Netlist export of the `usb2` block shows it has **no ESD
  protection** — only the receptacle and two 5.1 kΩ `CC` pulldowns, with `SHIELD`
  unconnected. The 27 Ω `D+`/`D-` series resistors RP2040 needs are not missing;
  they are `R10001`/`R10002` inside the `rp2040` block. Decided to add the
  **stocked `USBLC6-2P6`** (already in the parts database as
  `Power_Protection:USBLC6-2P6` / `Package_TO_SOT_SMD:SOT-666`, 20 on hand) on the
  connector side of those resistors, rather than purchasing `USBLC6-2SC6`, which is
  the same die in SOT-23-6 and would also need a new internal part. Buy the SC6
  only if boards are hand-assembled. This matters more than usual because `VBUS`
  now feeds the logic rail and the USBLC6 clamps `VBUS` as well as the data lines.
- 2026-08-12: Resolved the four follow-up questions on the 36 V input block against
  `tps1htc100-q1.pdf`. `DIAG_EN` and `LATCH` at 3.3 V with `VS` unpowered is within
  Recommended Operating Conditions, because those pins are specified −1 to 5.5 V
  **with respect to GND** and independently of `VS`; this is unlike the `DAC8563`
  case, whose inputs are specified relative to its own `VDD`. `ILIM` and `SNS` are
  each a single resistor to ground, so the earlier "2:1 divider" advice is
  withdrawn: change `R27003` 10 kΩ → 24.9 kΩ (limit 5.3 A typ → ~2 A) and
  `R27004` 1 kΩ → 470 Ω (fault level 3.3-4.4 V → 2.44-3.01 V, under the ADC
  limit). **Both values were superseded later the same day** by the stock check
  recorded in the entry above — 24.9 kΩ and 470 Ω are not stocked; the values in
  use are 40 kΩ and 249 Ω. Corrected the current-limit figure from 4.6 A to **5.3 A typ (4-6.3 A)**;
  the earlier number used the wrong `K_CL` row instead of the datasheet's tabulated
  `I_CL` values. `LATCH` floating gives **auto-retry every 2 ms**, so tie it high
  for latch-off; clearing is by toggling `EN`, which firmware already owns on
  `GP19`. `R27001` → 1 kΩ done.
- 2026-08-12: Audited `hv_input_36V_terminal_2pos_5p08_protected` by exporting its
  netlist and checking it against `tps1htc100-q1.pdf`. Confirmed the 220 nF is the
  `VS` bypass on `HV_IN` and the 22 nF is the output bypass on `+36V`, both
  correctly placed. Found six things to change when the block is placed: the
  `EN` divider (10 k/10 k) gives only 1.65 V against a 1.5 V `VIH`; `DIAG_EN` is
  left unconnected with an internal pulldown, which disables the `SNS` current
  sense that `GP28` was allocated to read; `~FAULT` and `LATCH` are unconnected;
  `ILIM` is set to ~4.6 A; and the `SNS` fault level of 3.3-4.4 V would
  overvoltage the RP2040 ADC. Allocated `GP29` to `~{HV_FAULT}` and specified a
  2:1 divider on `SNS`. Also bounded output bulk capacitance at tens of µF, since
  the switch dissipates ½CV² charging it and the datasheet requires the design not
  reach thermal shutdown while doing so.
- 2026-08-12: **Corrected the previous "no TVS" conclusion.** It was right that no
  standard TVS protects the TMC5130A at 36 V and wrong to conclude none was
  needed: because the regulator chain taps pre-switch, `HV_IN` carries the buck's
  input capacitance, so hot-plug rings against it while the switch is off and the
  driver is disconnected. The exposed parts at that moment are the 70 V switch and
  the 65 V buck, both clampable by a 40 V-standoff part. TVS goes on `HV_IN`.
- 2026-08-12: Ran the TVS arithmetic against the actual stocked parts and
  **reversed the earlier "add a board-level TVS" recommendation.** Standard SMBJ
  parts clamp at ~1.6× standoff, so a 36 V rail needs 40 V standoff and clamps
  near 64 V, against the TMC5130A's 49 V absolute maximum; the `SMBJ40A`
  breakdown spread of 44.4-49.1 V straddles that limit. The `TPS1HTC100-Q1`
  (70 V / 81 V transient) and `TPSM365R6V5` (65 V / 70 V) need no clamp. Recorded
  that the stocked `SMBJ28A` works only on a 24 V rail, which is why the 24 V
  input block is passive-with-TVS while the 36 V block is active-with-soft-start —
  two coherent designs, not one with a missing part. Also recorded that the 36 V
  block runs happily from 24 V or 30 V as an escape hatch.
- 2026-08-12: Added the multi-source logic rail — onboard buck, USB `VBUS`, and
  optional pyControl 5 V, diode-ORed at the `TPS73733` input rather than at
  `+5V`, because ORing onto `+5V` violates the TMC5130A's 4.6 V `VCC` minimum and
  truncates the DAC's full-scale output. Allocated `GP26`/`ADC0` to a switched-rail
  sense *(retargeted from `+5V_SW` to `+3V3_SW` on 2026-08-16)* so
  firmware can detect the MCU-alive/`+5V`-dead state that USB-only power creates,
  and recorded the input-clamp back-powering hazard it introduces.
- 2026-08-12: Worked the 36 V consequences from `TMC5130A_datasheet_rev1.21.pdf`
  chapter 29: 46 V operating, 49 V absolute with inductive load, and the
  datasheet's own warning about supply ringing from stray inductance. Recorded
  that the internal 5 V regulator's 1 W limit is reached at 32 mA when
  `VM = 36 V`, so `VCC` must be supplied externally, and that the 36 V input
  block populates no TVS. Also flagged the pre-/post-switch feed point as the one
  way to make an unbootable board out of correct blocks.
