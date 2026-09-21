# Autoroute Log — v1.0

**Status: not routed. Best result 111 of 269 connections left unrouted (run G,
2026-09-21), after twelve runs.** This records what has been tried so runs are not repeated. The
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

All on the same board and the same DSN unless noted. **C is the control.**

| Run | Configuration | Unrouted | Violations |
|---|---|---|---|
| A | `via_costs=10` + fanout flags | 137 | 1288 |
| D | tuned + B.Cu pour (KiCad outline plane) | 134 | 1288 |
| **C** | **stock settings — control** | **124** | 1288 |
| B | tuned + hand-relaxed netclasses | 120 | 1214 |
| F | stock + hand-relaxed netclasses + QSPI class | 113 | 1188 |
| **G** | **stock + `export_dsn.py` post-processing (best)** | **111** | **770** |

**Router tuning is harmful here: A (137) against the control (124) is a loss of
13 connections.** Every gain came from correcting the DSN, not the router. See
[the reference doc](../../kicad-libs/docs/freerouting-autorouting.md#fix-the-export-not-the-router).

What each 2026-09-21 run established:

- **A vs C** — `via_costs=10` plus the fanout escape-length changes cost 13
  connections. It does shift work off F.Cu (75% → 65% of new segments) and the
  fanout runs 4× faster, but the extra vias cost more than the layer access buys.
- **B vs A** — relaxing the four pitch-limited netclasses gained 17 and routed
  `+36V_SW`→`U1201-40`/`-21`, `+5V_SW`→`U1201-34`/`-39` and `BRB`→`R1204-1`,
  every one of which had failed in all five earlier runs.
- **F** — the same netclass fix without the harmful router flags: best result.
- **D** — a B.Cu pour exported as KiCad's zone *outline* produced four
  `NullPointerException`s from Freerouting's search tree, because 164 signal
  segments sit inside the rectangle it was told is solid GND.
- **G** — the same pour with the real fill plus all the export post-processing:
  **zero exceptions**, escape **78.3%** from 73.4%, items entering routing
  **269** from 302, and the best final result at **111**. Its 770 violations
  against everyone else's 1288 matter too: the fixes removed real geometry
  conflicts rather than masking them, so its score is not dominated by an
  unfixable constant.

## The Three Structural Problems

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

## Next, In Order

1. **`MCU_FINE` netclass at 0.15 / 0.15 for the rest of the RP2040.** The
   escape-margin scan (`../../kicad-libs/scripts/dsn_escape_margin.py`) found
   **43 U601 signals at exactly 0.000 mm** — the whole QFN-56 pin field, not just
   QSPI. Largest single block of marginal geometry on the board. **QSPI is
   already done** (class `QSPI`, pattern `*QSPI_*`, 0.15/0.15, verified
   resolving all six nets).
2. **Local power pours**, `+3.3V_MCU` around `U601` first. Nine of its failures
   are U601-pin-to-U601-pin, which want copper, not traces threaded between
   0.4 mm-pitch pins.
3. **Keep the B.Cu GND pour** — with the real-fill export it is clean, and it is
   the layer the router will not use anyway. Motor phases and `+36V_SW` stay on
   B.Cu for the thicker outer foil; the pour flows around them.
4. **Fix the thermal arrays and the F.Cu imbalance upstream** in `../kicad-libs`
   so no board needs the export workaround, and so blocks stop arriving with
   1629 of 1786 segments on one layer.
5. **Only then consider 6 layers.** Still not supported by the evidence.

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
