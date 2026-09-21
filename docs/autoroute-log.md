# Autoroute Log — v1.0

**Status: not routed. Best 4-layer result 100 of ~270 unrouted (run H);
best 6-layer 98 (run N). Decision: order 4-layer and hand-route. 2026-09-21,
after eighteen runs.** This records what has been tried so runs are not repeated. The
reusable freerouting knowledge — settings surface, verified defaults, source
references, and the export post-processing — is in
[`../../kicad-libs/docs/freerouting-autorouting.md`](../../kicad-libs/docs/freerouting-autorouting.md).
Read that first; this file is only the board's own history.

Tooling: `scripts/export_dsn.py`, `scripts/import_ses.py`, freerouting **v2.4.1**
headless via `make`.

**The one-line conclusion: tune the export, not the router.** Every router
setting tried made the result worse or made no difference; every gain came from
correcting what the DSN told the router.

## Runs, 2026-09-20 (stock settings, exploratory)

| # | Configuration | Start items | Final unrouted | Escape |
|---|---|---|---|---|
| 1 | 4 signal layers, no zones, unlocked | 246 | **95** | 75.8% |
| 2 | Same, all tracks `(type fix)` | 302 | — | 73.4% |
| 3 | GND plane In1.Cu **+ track keepout** | — | — | — |
| 4 | GND plane In1.Cu, no keepout | 230 | 107 | 73.4% |
| 5 | Bigger board, blocks moved, no zones | 305 | 121 | 73.7% |

Established by these: locking costs 157 already-connected pins; a track keepout
over a plane kills fanout (zero vias placed); without a keepout the plane is cut
by 48 signal segments; and enlarging the board plus moving blocks did not change
the ~60% completion rate while destroying the inter-block copper.

## Runs, 2026-09-21 (controlled, one variable each)

All on the same board unless noted. **C is the stock-settings control.**

### Four-layer

| Run | Configuration | Unrouted | Violations |
|---|---|---|---|
| A | `via_costs=10` + fanout flags | 137 | 1288 |
| D | tuned + B.Cu pour, KiCad outline plane | 134 | 1288 |
| **C** | **stock settings — control** | **124** | 1288 |
| B | tuned + hand-relaxed netclasses | 120 | 1214 |
| F | stock + hand-relaxed netclasses + QSPI | 113 | 1188 |
| G | stock + `export_dsn.py` post-processing | 111 | 770 |
| **H** | **G + QSPI + MCU_FINE netclasses** | **100** | 870 |
| I | H + `+3.3V_MCU` pour on In2.Cu | 100 | 870 |
| J | I + GND pour on F.Cu | 100 | 870 |

### Six-layer (In1.Cu = GND plane, signal on F/In2/In3/In4, B.Cu GND pour)

| Run | Configuration | Unrouted | Violations |
|---|---|---|---|
| K | 6 layers, otherwise identical to H | **103** | 936 |
| L | K + all classes confined to 3 layers each | abandoned | — |
| M | K + INSTRUMENT confined to In3/In4 | **99** | 936 |
| N | M-style but via size: 0.45 mm signal vias | **98** | 936 |

**Six layers is not worth buying.** Plain 6-layer (103) is *worse* than 4-layer
(100): In1.Cu stops being a free signal layer when it becomes the GND plane, and
the plane adds 66 violations. Even the best 6-layer variant reaches 98 — two
connections better than 4-layer, for roughly double the bare-board cost.
**Decision 2026-09-21: order the 4-layer board.**

## What Moved The Number, And What Did Not

**Worked — 124 to 100, all of it from telling the router the truth:**

- `export_dsn.py` post-processing (real plane fill, split-pad bridging): 124 -> 111
- `QSPI` and `MCU_FINE` netclasses at 0.15 / 0.15: 111 -> 100

**Did not work, each measured:**

| Attempt | Result |
|---|---|
| `via_costs=10` + fanout escape-length flags | **-13** (137 vs 124 control) |
| GND pour on F.Cu | 0 (J = H = 100) |
| `+3.3V_MCU` pour on In2.Cu | 0 (I = H = 100) |
| Six layers alone | **-3** (103 vs 100) |
| 0.45 mm signal vias | +1 to +2 |
| Confining INSTRUMENT to its own layer pair | +1 |
| Enlarging the board and moving blocks | 0 |

## Why The Remaining ~100 Cannot Be Autorouted

The failure signature, measured rather than assumed:

- **Median failing span is 4.4 mm.** Only 2 of 111 exceed 20 mm.
- **23 of 100 are pin-to-pin on the same component.**
- `/GND` alone is 36; `+3.3V_MCU` 6.
- Zero placement violations (`validate_board`, 364 footprints).

They are overwhelmingly **adjacent GND/power pins on fine-pitch parts** —
`U606-11 -> U606-12`, `U1201-9 -> U1201-11`, `U1301-5 -> U1301-21`,
`R1105-2 -> R1104-2`.

**A copper pour cannot bridge them.** At 0.5 mm pitch the gap between adjacent
pads is ~0.2 mm, and a pour needs its clearance on both sides: 0.2 + width + 0.2
<= 0.2 has no solution. That is why pouring GND on F.Cu changed nothing. Each
such pin needs its own via to a plane, and the via needs room *beside* the pad —
the same escape bottleneck. Three independent attacks on it (more layers,
smaller vias, relaxed fanout limits) each moved the escape rate by under one
percentage point:

| Config | Escape |
|---|---|
| 4 layers, 0.6 mm vias | 77.7% |
| 6 layers, 0.6 mm vias | 78.2% |
| 6 layers, 0.45 mm vias | 78.6% |

The real fixes are upstream: via-in-pad on the fine-pitch parts, or fanning the
GND pins out inside the design-block layouts so a consuming board never has to.

## Ideas Considered And Ruled Out (with evidence)

- **Reordering the InstrumentPort channel map to minimise crossings.** Sound in
  general, useless here: **zero `_INST` nets and zero `DIGn_BUF`/`_ISO` nets
  fail.** The tap topology plus the `INSTRUMENT` class already route all 24
  cleanly. Revisit only if a future revision gets tight at the port, and do it
  at schematic-capture time — `board-interfaces` owns that contract.
- **A single blocking misplacement.** A real pattern on other boards, but not
  here: median failing span 4.4 mm and zero placement violations. A misplaced
  part produces a cluster of *long* failing connections.
- **Rotating the flash to fix QSPI.** The WSON-8 has four pins per side, so
  three QSPI signals are always on the far side. Rotation just swaps which three.

## The Three Structural Problems## The Three Structural Problems

### 1. The router uses one layer

Run 5, measured from the `.ses`:

| Layer | Input | Output | Added |
|---|---|---|---|
| F.Cu | 1629 | 2044 | **+415** |
| B.Cu | 157 | 164 | **+7** |
| In1.Cu | 0 | 56 | +56 |
| In2.Cu | 0 | 72 | +72 |

75% of new routing piled onto the saturated layer while a 96%-empty outer layer
took seven segments. Cause is the default via cost of 50 against a trace cost of
1.0–1.8.

**Tried 2026-09-21 and it is not a lever.** `via_costs=10` does shift the split
(F.Cu 75% → 65%, inner layers 128 → 196 segments) but finished 13 connections
*worse* than the control. And B.Cu takes ~7 segments no matter what, because it
carries the same outer-layer penalty as F.Cu while sitting behind two cheaper
inner layers — so treat this board as F.Cu + In1 + In2, with B.Cu free for a
pour.

### 2. Exposed-pad thermal vias are phantom work

**57 of this board's 323 GND terminals** are `@`-suffixed duplicates of a single
physical pad: `U1201` 26, `U501` 16, `U701` 4, `U1001` 4, `J301` 1. `U1201`'s
pin 49 exports as 27 terminals — one 5×5 mm `Rect[T]` pad on F.Cu, one on B.Cu,
and 25 × `Round[A]Pad_700_um` thermal vias sitting inside them.

**Fixed 2026-09-21 in `scripts/export_dsn.py --bridge-split-pads`** (on by
default), which emits 58 protected wires joining them. Escape rose 73.4% →
78.3% and items entering routing fell 302 → 269. The upstream fix — tying the
thermal arrays inside the block layouts in `../kicad-libs` — is still worth
doing so no board needs the workaround.

### 3. Block copper saturates F.Cu

1629 of 1786 pre-routed segments arrive on F.Cu. Fixing this means rebalancing
block layouts in `../kicad-libs`, which is the expensive option.

## Where The Failures Cluster

Run G's remaining 111, by net:

| Net | Unrouted | Note |
|---|---|---|
| `/GND` | **36** | still the largest single item |
| `/+3.3V_MCU` | **10** | every one U601-pin-to-U601-pin |
| `torque_bridge/+5V_FILT` | 3 | |
| `/USB_D+` | 3 | |
| `ENCB`, `RUN`, `VMID`, `REFCAP`, `TQ_SPI_SCK` | 2 each | |

GND plus the three switched rails are **~55 of 111** — half the remainder is
power distribution that wants copper pours, not traces.

Of the seven connections that failed in every pre-2026-09-21 run because their
netclass could not escape a 0.5 mm pad pitch, run G routed three
(`+36V_SW`→`U1201-40` and `-21`, `BRB`→`R1204-1`) and still fails four
(`+5V_SW`→`U1201-34`/`-39`, `BRA`→`R1203-1`, `CPI`→`C1202-2`). Run F, with
hand-picked relaxations rather than the automatic `--fit-pitch`, routed five of
the seven — so the automatic fit is slightly less aggressive than hand-tuning.

## Board State As Left, 2026-09-21

**The board is currently SIX layers** with three zones. Before ordering, decide
whether to revert to four (the evidence says yes — see the run tables).

Uncommitted in `kicad/`:

| Change | Keep? |
|---|---|
| Copper layers 4 -> 6 | **revert** — worth 2 connections for ~2x cost |
| `/GND` zone on **In1.Cu** | only exists because of the 6-layer stackup |
| `/GND` zone on **B.Cu** | **keep** — costs nothing, B.Cu is unused by the router |
| `QSPI` netclass, pattern `*QSPI_*`, 0.15/0.15 | **keep** — part of the 111->100 win |
| `MCU_FINE` netclass, 34 patterns, 0.15/0.15 | **keep** — same |

Backups of the 4-layer board and project are in the session scratchpad as
`board-before-6layer.kicad_pcb` / `pro-before-6layer.json`; if those are gone,
`git checkout kicad/` restores the last committed 4-layer state, but that also
discards the two netclasses, so re-add them.

Zones I added during experiments and already removed: `/GND` on F.Cu (no
effect), `/+3.3V_MCU` on In2.Cu (no effect).

## Next, In Order

1. **Revert to 4 layers**, keep the B.Cu GND pour and both netclasses.
2. **Re-export and re-run** to regenerate a 4-layer session matching run H
   (`make export-dsn` then freerouting with **stock settings** — no flags).
3. **Import** with `scripts/import_ses.py`, then re-fill zones.
4. **HV clearance check.** Non-negotiable: `--fit-pitch` tells the router
   `PWR_HV_BUS` needs 100 um when `.kicad_dru` says 400, so nothing has verified
   36 V spacing. Run DRC with clearance at error and read the findings on
   `PWR_HV_*`, `MOTOR_2A`, `BOOTSTRAP`, `GATE_DRIVE`, `PWR_12V*`. Two silent
   36 V spacing problems were already found on this board this session.
5. **Hand-route the remaining ~100.** They are short and local: mostly adjacent
   GND/power pins on `U1201`, `U601`, `U606`, `U604`, `U1301`, `U2002`. Expect
   to place vias beside fine-pitch pads by hand where the router could not.
6. **Upstream, for the next board:** fan the GND pins out inside the design-block
   layouts, and rebalance block copper off F.Cu (1629 of 1786 segments arrive
   there). Both are in `../kicad-libs/.agents/PLANS.md`.

## Import Cautions

- Every run so far ends `Invalid traces after autoroute: 74-78 traces not 45
  degree`.
- `scripts/import_ses.py` documents the KiCad via-drill defect: the session
  carries a via's pad diameter but not its drill, so hand-sized vias come back at
  the netclass drill. Seven vias once landed under the JLCPCB annular-ring floor.
- Re-fill zones and re-run DRC after any import; the router's new vias need
  antipads that only a re-pour creates.
- Check the `.ses` layer split before importing — if a plane layer appears in it,
  the plane has been cut.
