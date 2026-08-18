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
- **RP2040 GPIO allocation.** Rev 0 connects **18 of 30** and reserves 8 more at
  fixed numbers; full scope is **26 of 30**. **Spares are now four — `GP15`,
  `GP16`, `GP18`, `GP27`**; `GP14` was consumed by `HV_DIAG_EN` on 2026-08-17.
  **No pin moves between Rev 0 and rev 1.** `TMC_REF_STIM` was deleted permanently and its
  pin pays for the bus-switch enable on `GP9`. `docs/interface-map.md`.
- **Two power domains, 2026-08-13.** The high-side switch is a reset button:
  everything resettable is on `+36V_SW` → `+5V_SW` → `+3.3V_SW`, and the MCU is on
  `+5V_MCU` → `+3.3V_MCU` fed from USB `VBUS` or pyControl pin 6 through two ORing
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
    place on this board where the naming reverses. `~{BUS_SW_EN}` is the only Rev
    0 connected GPIO needing no `mcu` sheet pin — the bus switch is inside that
    sheet.
  - `GP24` `~{INSTR_BUF_OE}` is now live. No pin moved.
  - ~~**Four 100 kΩ pull-downs plus the `SW_RAIL_SENSE` divider are the only new
    passives.**~~ **Superseded 2026-08-17.** As built there are **nine** 10 kΩ
    termination resistors plus the divider, and the 100 kΩ value would have been
    wrong on the TMC SPI lines — see **Open Schematic Findings**. Buffer packages
    are **three** (`U1601`, `U1701`, `U1801`); `U_C` and `U_D` were never placed and
    do not exist. The spare twelfth channel has its input tied to GND, but its
    output stops at `R1805` and does not reach `DIG12`.
  - **It costs layout schedule** — a 40-pin FFC, three buffer footprints, and 18
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
  tight `VS` loop — and verified at Gate B. **As built, no TVS is populated**
  (confirmed by netlist, 2026-08-17); it stays a Gate B measurement rather than a
  fabrication blocker.
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

   **Added 2026-08-17:** this bulk is also what sets the off-state creep rate in the
   `DIAG_EN` finding below. At ~208 µF the rail creeps at ~1.2 V/s; depopulating
   `C1214` would double that to ~2.4 V/s. Moving `DIAG_EN` to `GP14` removes the
   creep entirely, so the two decisions are now independent — but do not
   reintroduce a fixed `DIAG_EN` pull-up while reasoning about bulk.
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

**Both of the 2026-08-17 non-blocking carry-overs are now closed.** Netclass
patterns were extended from 108 to 124 so every rail, both motor phases and the
sense returns route at their intended widths; and the missing `RUN`/`SWD` was
resolved as a **decision** rather than a fix — deferred to a future board revision,
since RP2040 `RUN` has an internal 50–80 kΩ pull-up and needs no external part. Both
are recorded in **Open Schematic Findings** below, which is the tracked record.
(`.agents/handoff.local.md` is gitignored and will not be present on a fresh clone —
do not rely on it.)

**Resolved 2026-08-13, no longer blocking:**

- DAC8563 `VIH` — deferred with the DAC to rev 1.
- Where `+3.3V_MCU` comes from — USB or pyControl only, two diodes, no always-on
  converter on `HV_IN`.
- The TMC's switched `VCC_IO` — it is on `+3.3V_SW` from the second LDO, so all
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

**Settled 2026-08-17: no TVS is populated in Rev 0.** Confirmed against the
netlist. It stays a bench-measurement item, not a fabrication blocker — and it is
what bounds the margin on `C1213`/`C1214`, which are 50 V parts on a 36 V rail
(72% of rating). Measure the transient at the TMC5130A `VS` pins at Gate B.

## Open Schematic Findings — re-verified 2026-08-17 (cleared for layout)

Third and final pre-layout review, run after the nine board-level termination
resistors, the `DIAG_EN` rework, and the netclass patterns. This section is
**self-contained on purpose** — it is the tracked record, and
`.agents/handoff.local.md` is gitignored and will not survive a clone onto another
machine. Everything needed to act is here.

### Current verification state

**ERC is clean: 0 violations at every severity.** 142 components, no duplicate
refdes, every part has a footprint. **Zero undefined cross-domain nets.** Netclass
patterns extended from 108 to 124, so no current-carrying net routes at the 0.2 mm
`Default` width. Every capacitor sits at or below 80% of its rated voltage.

Reproduce:

```sh
export ORB_WEAVER_KICAD_LIBS=$HOME/Repositories/orb-weaver/kicad-libs
kicad-cli sch erc -o /tmp/mj-all.rpt --severity-all kicad/mouse-joystick-pcb.kicad_sch
kicad-cli sch export netlist --format kicadxml -o /tmp/mj.xml \
  kicad/mouse-joystick-pcb.kicad_sch
```

**ERC could not see most of what mattered here.** Every finding below was found by
walking the flattened netlist against manufacturer datasheets, and all of them kept
passing ERC before and after the fix. Re-check by netlist, not by ERC.

**No blockers remain. The schematic is cleared for layout.**

### Closed this session — keep the reasoning, do not re-derive

- **`TMC_DIAG1` crossed the isolation barrier onto a hard ground.** The
  `rp2040_gpio_isolation_sn74cb3q3245` block cross-mapped its A and B labels on the
  two middle switches. Fixed in `kicad-libs` and re-placed. All 32 channels were
  then audited: the pairing on the RGY-20 package is `A_n` = pin (n+1),
  `B_n` = pin (19−n), every used pair matches, unused A pins are open and unused B
  pins are tied to GND.

- **Netclass patterns matched none of this board's rails.** 146 of 156 nets fell to
  `Default` (0.2 mm / 0.2 mm), including `/+36V_SW`, both 5 V rails, both 3.3 V
  rails, all four motor phases and the `BRA`/`BRB` sense returns. The inherited
  patterns target `+24V`, `VM` and `/tmc5130_spi/OA*`, none of which exist here, and
  `*/HV_IN` was silently matching `PWR_HV_LOCAL` at 0.25 mm — worse than falling
  through. Added:

  | Pattern | Netclass | Width |
  | --- | --- | --- |
  | `*/HV_RAW`, `*/HV_IN` (retargeted) | `PWR_HV_ENTRY` | 1.5 mm |
  | `/+36V_SW` | `PWR_HV_BUS` | 1.2 mm |
  | `/motor_encoder_limit/OA*`, `/motor_encoder_limit/OB*` | `MOTOR_2A` | 0.8 mm |
  | `*/tmc5130/BRA`, `*/tmc5130/BRB` | `MOTOR_2A` | 0.8 mm |
  | `/+5V_*`, `*/VBUS`, `*/PYC_CONN_5V`, `*/PYC_5V_FUSED` | `PWR_5V` | 0.5 mm |
  | `/+3.3V_*` | `PWR_3V3` | 0.3 mm |
  | `*/5VOUT`, `*/tpsm365r6/VCC` | `PWR_5V_LOCAL` | 0.2 mm |
  | `*/tmc5130/VCP`, `*/tmc5130/CPO`, `*/tmc5130/CPI` | `BOOTSTRAP` | 0.3 mm |

  Verified that no net matches more than one netclass, so there is no precedence
  ambiguity. **`BRA`/`BRB` are not Kelvin sense nets** — on the TMC5130A they carry
  full coil current into the sense resistor, so they are sized with the motor
  phases. `SENSE_KELVIN` exists for the TMC5160's `SRA`/`SRB`, not for this part.
  `MOTOR_2A` (0.8 mm) was chosen over `MOTOR_LOW` (0.3 mm) because the motor part is
  still open; downgrade it once the motor is fixed.

- **`DIAG_EN` moved from a fixed `+3.3V_MCU` pull-up to `GP14`.** This is the
  subtlest defect found in the whole review and `docs/power.md` had analysed
  `DIAG_EN` at length without catching it. Holding `DIAG_EN` high keeps the
  TPS1HTC100's OFF-state open-load detection permanently enabled, which switches in
  an internal **150 kΩ pull-up from `VS` to `VOUT`** (`ROL_OFF` 110–166 kΩ,
  datasheet §7.3.4.2). At 36 V that injects ~240 µA into `+36V_SW`, which carries
  ~208 µF, so the rail creeps at ~1.2 V/s and crosses the TPSM365R6's 3.6 V minimum
  `VIN` in about 3 s. The buck then starts, collapses, and hiccups — so the switched
  domain never cleanly powers off, the "`HV_EN` power-cycles every resettable chip"
  property is broken, and `SW_RAIL_SENSE` reads a fluctuating value. `DIAG_EN` has an
  internal pull-down, so with `GP14` high-Z at reset diagnostics are off and
  `+36V_SW` sits at true zero. Current limit and thermal shutdown are unaffected
  (Table 7-1); only reporting is gated, so **firmware must raise `GP14` before it
  can read current sense or faults**. A 10–15 kΩ bleeder on `+36V_SW` was the
  considered alternative. Note this interacts with Blocking Item 1: halving the bulk
  by depopulating `C1214` would double the creep rate, not remove it.

- **Nine board-level termination resistors added.** All in board-authored sheets
  (`mcu`, `motor_encoder_limit`, `instrument_port`), so a design-block re-place
  cannot lose them.

  | Ref | Value | Net | To | Why |
  | --- | --- | --- | --- | --- |
  | `R403` | 10 kΩ | `PYC_UART_RX` | `+3.3V_MCU` | UART RX must idle **high**; the RP2040's default pull-down looks like a permanent break |
  | `R1401` | 10 kΩ | `TMC_SPI_SCK` | GND | define the `U1701` buffer input when the switched domain is off |
  | `R1402` | 10 kΩ | `TMC_SPI_COPI` | GND | as above |
  | `R1403` | 10 kΩ | `TMC_SPI_CIPO` | GND | as above; also gives the instrument tap a clean idle-low |
  | `R1404` | 10 kΩ | `~{TMC_CS}` | `+3.3V_SW` | CSN must idle **deasserted**; a pull-down would assert chip select |
  | `R1405` | 10 kΩ | `LIMIT_SW` | GND | define the `U1801` buffer input |
  | `R1101` | 10 kΩ | `TMC_DIAG0` | `+3.3V_SW` | DIAG is open-drain at reset; datasheet requires ≤47 kΩ |
  | `R1102` | 10 kΩ | `TMC_DIAG1` | `+3.3V_SW` | as above |
  | `R1103` | 10 kΩ | `~{TMC_DRV_EN}` | `+3.3V_SW` | guarantees the power stage is **disabled** in hardware |

  Four decisions inside that table are load-bearing and easy to get wrong later:

  1. **Pulls that must read HIGH reference `+3.3V_SW`, never `+3.3V_MCU`.**
     Referencing the always-on rail back-powers `+3.3V_SW` to roughly 1.3 V through
     the TMC's protection diodes — defeating the `HV_EN` power-cycle and corrupting
     `SW_RAIL_SENSE`, and parking the buffer inputs at ~2.0 V, exactly the
     `SN74LVC125A`'s `VIH`. This was built the wrong way once and corrected.
  2. **`+3.3V_SW` is held at 0 V when off by `R401`/`R402` (2 kΩ to GND)**, which is
     what makes a pull-up to that rail a valid LOW in the off state. If the
     `SW_RAIL_SENSE` divider is ever removed, four of these resistors stop defining
     their nets.
  3. **Do not use 100 kΩ pull-downs on the TMC SPI lines**, which is what
     `docs/interface-map.md` used to prescribe. The TMC's `CSN`/`SCK`/`SDI`/`SDO`
     are `(tpu)` with `RPU` = 132/166/200 kΩ; 100 kΩ against that parks the node at
     ~1.9 V, straddling the buffer's 2.0 V `VIH` and leaving chip select ambiguous.
     10 kΩ gives 0.28 V, a clean LOW.
  4. **`~{TMC_DRV_EN}` needed `R1103` even though `DRV_ENN` has an internal
     pull-up.** Once firmware enables the bus switch, the RP2040's reset-state
     internal pull-down (`RPD` 50–80 kΩ) passes straight through the FET switch and
     fights the TMC's 132–200 kΩ `tpu`, giving 1.00–1.89 V — never a guaranteed
     HIGH, and at the worst corner a LOW, which **enables the power stage** with
     36 V on `VS`. `R1103` makes the worst case 2.75 V against a 2.31 V `V_INHI`, so
     "drivers disabled at boot" is a hardware guarantee rather than a firmware
     ordering requirement.

  Resulting levels, verified:

  | Net | Domain OFF | Domain ON, bus isolated |
  | --- | --- | --- |
  | `TMC_SPI_SCK`/`COPI`/`CIPO` | 0 V | 0.28 V (LOW) |
  | `~{TMC_CS}` | ≤0.24 V | ≈3.4 V (HIGH, deasserted) |
  | `LIMIT_SW` | 0 V | driven by `U1301` |
  | `TMC_DIAG0`/`1` | 0 V | 3.3 V (open-drain idle) |
  | `~{TMC_DRV_EN}` | 0 V | ≥2.75 V (power stage off) |

- **`AGND` was a floating four-pin island** — `J1501` pins 31/34/37/40 connected to
  nothing, and the `instrument_port` sheet had no `AGND` pin so it never left the
  sub-block. Now tied to `GND`.

- **`PMC_UART_RX_BUF` / `PMC_UART_TX_BUF` typo** fixed to `PYC_`.

- **`GP1` pull-up fitted** (`R403`). Note the reason is *idle level*, not floating:
  every RP2040 GPIO resets with its internal pull-**down** enabled, which on a UART
  RX line reads as a permanent break, and the net leaves the board through the RJ-45
  where nothing drives it when unplugged. That is also why the bus-switch B side
  needs no termination at all — the MCU's own pull-downs define it.

### Verified correct — do not re-derive

- **Power architecture.** `+5V_MCU` is ORed from USB (`D301`) and pyControl
  (`D1901`) only; `hv_to_5v_tpsm365r6` takes `+36V_SW`; four distinct rails, one
  source each, and the two 5 V rails never meet. All three diodes verified oriented
  correctly (symbol pin 1 is the **cathode**): `HV_RAW`→`HV_IN`, `VBUS`→`+5V_MCU`,
  `PYC_5V_FUSED`→`+5V_MCU`.
- **The pyControl crossover.** `PYC_DIO_A` → `PYC_UART_RX` → `GP1`, `PYC_DIO_B` →
  `PYC_UART_TX` → `GP0`, with `TX` an `Output` and `RX` an `Input` on the `mcu`
  sheet. `PYC_DIO_A`/`_B` are `bidirectional` in both the library block and the
  placed copy.
- **InstrumentPort mapping** — all eleven Rev 0 Strands land where
  `docs/interface-map.md` says.
- **TMC5130A strapping**, every pin checked against the datasheet: `TST_MODE`,
  `SD_MODE` and `SWSEL` to GND; `SPI_MODE` left open on its internal pull-up;
  `ENCN` tied to GND through `R1201` 10 kΩ exactly as the datasheet requires when
  unused; `N.C.` pins 6/31/36 to GND as required; `DNC` pins open; `VCP`, `CPI`/`CPO`,
  `BRA`/`BRB` and `5VOUT` capacitors all per the pin table. `R1203`/`R1204` are
  **0.15 Ω**.
- **`R207` = 249 Ω on `HV_SNS` is correct and needs no series resistor.** `ISNSFLT`
  is a 5.2–6.4 mA *current source*, so a fault reads 1.3–1.6 V — safely under the
  RP2040's `VPIN` absolute maximum of `IOVDD` + 0.5 = 3.8 V, and clearly distinct
  from the ≤0.37 V maximum normal-current reading. `VSNSFH` is 3.3/3.95/4.4 V at
  `VDIAG_EN` = 3.3 V, so the 1 kΩ that `docs/power.md` originally specified **would
  have driven `GP28` past its absolute maximum**. Safe upper bound is about 594 Ω.
- **Capacitor voltage ratings**, all ≤80%. Two notes: `OW-CAP-100N-0402-X5R-16V`
  declares only `ReqMinVoltage = 16V` but resolves to LCSC C162178, a **100 V** X5R
  0402, so the TMC's `VS` bypass caps `C1209`/`C1210` are rated by vendor mapping
  rather than by requirement — worth switching to a part whose requirement states
  the rail voltage. `C1213`/`C1214` are 100 µF **50 V** on 36 V (72%), which with no
  TVS fitted is a bench-measurement item.
- **`R601` 7.87 kΩ** pulls `~{BUS_SW_EN}` high to `+3.3V_MCU`, so the bus switches
  default to isolated at reset. **`R1601`/`R1701`/`R1801` 10 kΩ** pull
  `~{INSTR_BUF_OE}` high, implementing exactly what the `SN74LVC125A` datasheet
  requires: "to ensure the high-impedance state during power up or power down, OE
  should be tied to VCC through a pull-up resistor".
- **13 of the 14 placed design-block copies are byte-identical to their library
  sources.** The exception is `tmc5130`, and the board is the correct one — see
  "Carry into layout" below.

### Checked and explicitly **not** defects — do not chase these

- **`X1201` pin 1 (`Tri-State`) left open.** The ECS-2520S pad table states
  "High or NC → Active". Datasheet-sanctioned. An earlier review called this a
  defect; it was wrong.
- **`RUN`, `SWCLK` and `SWD` unconnected.** RP2040 `RUN` has an internal 50–80 kΩ
  pull-up and the datasheet permits leaving it open or tying it to `IOVDD`, so this
  is an access limitation, not an electrical defect. **Deferred to a future board
  revision by explicit decision, 2026-08-17.** The cost is no debugger during
  bring-up and BOOTSEL recovery requiring both USB and pyControl unplugged.
- **`~{TMC_DRV_EN}` relies on `DRV_ENN`'s internal pull-up for its fail-safe
  direction** — "the power stage becomes switched off when this pin becomes driven
  to a high level". `R1103` now backs that up in hardware.
- **`U901` `BOOT`/`SW` unconnected** (bootstrap capacitor is internal);
  **`U1201` `SPI_MODE` floating** (internal pull-up = SPI, matching `SD_MODE`=0 and
  `SWSEL`=0); **`U1201` `AIN_IREF` floating** (`GCONF.I_scale_analog` resets to 0);
  **`R1805.2` dangling** (spare 12th buffer channel, input grounded); **`J1102`
  pin 2** (reserved index, NC-flagged); **`J301` SBU1/SBU2**; **`J1901` pins
  3/5/7/8**; the TMC `DNC` pins; spare RP2040 GPIOs; the LDO `NR` pins.
- **No MCU-side termination on the bus switch.** Every RP2040 GPIO resets with its
  internal pull-down enabled, and the switch's A/B ports are FET pass gates with no
  logic input, so nothing floats there.
- **`~OE` is not a substitute for terminating a buffer input.** `ΔICC` is 500 µA
  typ / 5 mA max per partially biased input, independent of `OE`, against 40 µA max
  for the whole device with valid levels. This was proposed and rejected.

### Carry into layout — decisions, not blockers

- [ ] **`U603` and `U604` are entirely unused; `U602` uses 1 of 8 channels.** Three
  QFN-20 packages plus three decoupling capacitors of board area for seven signals.
  The cheapest moment to drop them is before placement, by moving `TMC_DIAG1` onto
  one of `U601`'s two free channels. Note the counter-argument no longer holds: the
  unused channels have their **MCU-side pins tied to GND**, so the reserved rev-1
  DAC channels are not pre-wired and rev 1 must edit the block regardless.
- [ ] **Do not re-place the `tmc5130` block.** The board has `R1203`/`R1204` =
  0.15 Ω; `kicad-libs` moved to 0.12 Ω in commit `a8dca31`. A re-place silently
  reverts them and puts roughly 25% over the intended 0.679 A RMS. Fix the library
  down to 0.15 Ω, or never re-place that block.
- [ ] **Placement intent lives in the library blocks' `.kicad_pcb`, not in ours.**
  `C1201` is `X1201`'s bypass (1.64 mm pad-to-pad) and `C1204` is the TMC's
  `VCC_IO` bypass (3.04 mm). "Update PCB from Schematic" will not bring that across.
  Also keep `BRA`/`BRB` short to their sense resistors, and `VCP`/`CPI`/`CPO` tight,
  per the TMC pin table.
- [ ] **`R1903` is a polyfuse position fitted with a jumper.** The block's own note:
  "R29003 IS A POLYFUSE POSITION, NOT PROTECTION... Populate a 1206 PPTC,
  250-500 mA hold." Port 5 V is a shared 1.0 A that also feeds the pyControl
  controller's own logic regulator with no per-port fuse, so a fault here can reset
  the experiment controller. Either source the PPTC or accept the jumper and record
  it. There are no test points either side, so a tripped PPTC could not be diagnosed
  in circuit.
- [ ] **No test points exist anywhere on the board**, against roughly a dozen that
  `docs/interface-map.md` calls for. Decide whether they are schematic symbols (add
  before layout so the netlist carries them) or layout-only pads. The `SWSEL` pad it
  asks for is moot — `SWSEL` is tied directly to GND with no net.
- [ ] **The bus switches run from `+3.3V_MCU`,** whereas the `SN74CB3Q3245` part
  note in `kicad-libs` says to "power from the switched target-domain 3.3-V rail so
  Ioff provides isolation at VCC=0". As built, isolation depends on the MCU holding
  `~BUS_SW_EN` high, which `R601` makes the reset default. Deliberate divergence;
  reconcile the note or the rail.
- [ ] **Two unrecorded TMC deviations to sign off.** `R1202` = 10 Ω sits between
  `+5V_SW` and `5VOUT`, where the datasheet describes 2.2–3.3 Ω between `5VOUT` and
  `VCC`; and `VSA` is on `+5V_SW` where the datasheet says "normally tied to VS".
  Both are benign — `VCC` is supplied externally so the internal regulator idles,
  and the sequencing rule "VCC comes up before or in parallel to 5VOUT or VCC_IO" is
  satisfied — but neither is recorded as a decision.
- [ ] **The `SN74LVC125A` has no `Ioff`** and TI does not specify its leakage at
  `VCC` = 0. `VI` absolute maximum is −0.5 to 6.5 V *absolute*, not VCC-referenced,
  and `IIK` is specified only for `VI` < 0, so there is no input clamp to VCC and
  gross back-power is unlikely — but it is unspecified rather than guaranteed.
  Measure `+3.3V_MCU` with 36 V applied and both USB and pyControl unplugged at
  Gate B.
- [ ] **The encoder chain has no ESD device**, contrary to the "filtering and ESD"
  description in `docs/design-block-map.md`. The 4.7 kΩ series and 470 pF give some
  protection and the `SN74LVC2G17` has internal clamps. Decide and record.

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

- ~~the schematic is electrically sound~~ **done 2026-08-17** — ERC clean at every
  severity, zero undefined cross-domain nets, netclass patterns cover every
  current-carrying net;
- the motor part is identified, and the encoder's CPR and maximum shaft RPM are
  known well enough to confirm the `C802`/`C803` filter value;
- ~~the DAC logic-level question is settled~~ **deferred to rev 1**;
- the bulk-capacitance placement and snubber footprint are decided;
- ~~the `+3.3V_MCU` source and the switched `VCC_IO` rail are decided~~
  **done 2026-08-13**;
- ~~the Guix pin, Makefile, and KiCad scaffold exist~~ **done**; `make validate-db`
  still to be run once in the managed shell;
- Gate A items in `docs/validation-plan.md` have explicit status.

## Progress Log

- 2026-08-17 (latest): **Third pre-layout review. The schematic is cleared for
  layout.** ERC clean at every severity, 142 components, and — the check that
  actually mattered — **zero undefined cross-domain nets**, verified by walking the
  flattened netlist against the TMC5130A, RP2040, SN74LVC125A, SN74CB3Q3245,
  TPS1HTC100-Q1 and ECS-2520S datasheets. Both prior blockers are closed:
  `TMC_DIAG1` now crosses on a matched `U602` channel pair (all 32 audited), and
  netclass patterns went 108 → 124 so the 36 V rail, both 5 V rails, both 3.3 V
  rails, the four motor phases and `BRA`/`BRB` no longer route at 0.2 mm.
  Nine board-level termination resistors were added, and the reasoning behind which
  rail each references is the most transferable thing in this review — see the
  four numbered notes under "Closed this session". Three earlier findings were
  **retired as wrong** after reading the datasheets: `X1201`'s open `Tri-State` pin
  is explicitly permitted, `RUN` floating is safe on its internal pull-up, and
  `HV_SNS` needs no series resistor because `SNS` is a current source. One genuinely
  new defect was found and fixed — `DIAG_EN` held high keeps the TPS1HTC100's
  off-state open-load pull-up enabled, which stops the switched domain ever cleanly
  powering off; it now runs from `GP14`. `AGND` was tied to `GND`, the `PMC`/`PYC`
  typo fixed, and the `GP1` pull-up fitted. Decided, not fixed: no SWD header or
  `RUN` connection in Rev 0. Remaining items are layout decisions, not schematic
  defects, and are listed under "Carry into layout".

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
  observation to check, not a commitment. *(Narrowed 2026-08-17: `GP14` went to
  `HV_DIAG_EN`, so it is now **four** spares against those same six. Rev 2 no
  longer fits without dropping something — recheck before relying on it.)*
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
