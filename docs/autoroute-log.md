# Autoroute Log — v1.0

**Status: not routed. Best result 95 of 246 connections left unrouted.** This
records what has been tried on this board so runs are not repeated. The reusable
freerouting knowledge — settings surface, verified defaults, source references —
is in
[`../../kicad-libs/docs/freerouting-autorouting.md`](../../kicad-libs/docs/freerouting-autorouting.md).
Read that first; this file is only the board's own history.

Tooling: `scripts/export_dsn.py`, `scripts/import_ses.py`, freerouting **v2.4.1**
headless via `make`. All runs used **default router settings** — none of the
tuning in the reference doc has been tried yet.

## Runs, 2026-09-20

| # | Configuration | Start items | Final unrouted | Escape | Notes |
|---|---|---|---|---|---|
| 1 | 4 signal layers, no zones, unlocked | 246 | **95** | 75.8% | Best so far |
| 2 | Same, all tracks `(type fix)` | 302 | — | 73.4% | Locking cost 157 already-connected pins |
| 3 | GND plane In1.Cu **+ track keepout** | — | — | — | Fanout placed **0 vias**; abandoned |
| 4 | GND plane In1.Cu, no keepout | 230 | 107 | 73.4% | Plane cut by 48 signal segments |
| 5 | Bigger board, blocks moved, no zones | 305 | 121 | 73.7% | Rearranging did not help |

Completion rate sits at 53–61% regardless. Runs 2–5 are all worse than run 1.

### What each run established

- **Locking is harmful.** `(type fix)` made 157 pins stop counting as connected
  (371 → 214, exactly complementary with 799 → 956 needing fanout) and pushed
  `normalizeTraces` stagnation from 7 nets to 10, adding `/GND` and `/+36V_SW`.
- **A track keepout over the plane kills fanout.** Fanout pass 1 went from
  526 fanouted / 40 not routed / +55 vias to **445 / 143 / +0**. The zone was set
  `vias: allowed` and exported as `wire_keepout`; it broke anyway.
- **Without a keepout the plane gets cut.** 48 non-GND segments landed on
  In1.Cu across 41 nets — `+5V_SW`, `+3.3V_SW`, `+3.3V_MCU`, `+12V`, and 37
  single-segment signal crossings. Freerouting does no island analysis.
- **The plane cost more than it gained.** Autoroute start fell only 246 → 230
  (16 items) because the blocks already route GND locally, while In1.Cu stopped
  being available for signals.
- **Enlarging the board and moving blocks did not help.** It destroyed
  inter-block copper, so run 5 started with 305 items instead of 246 and finished
  at the same ~60% rate.

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
1.0–1.8. This is the largest single lever and it has **not been tried yet**.

### 2. Exposed-pad thermal vias are phantom work

**51 of this board's 323 GND terminals** are `@`-suffixed duplicates of a single
physical pad: `U1201` 26, `U501` 16, `U701` 4, `U1001` 4, `J301` 1. `U1201`'s
pin 49 exports as 27 terminals — one 5×5 mm `Rect[T]` pad on F.Cu, one on B.Cu,
and 25 × `Round[A]Pad_700_um` thermal vias sitting inside them.

With `zones=0` nothing can satisfy these. GND failures went 26 (with the plane)
→ 39 (no zones). **Never export this board without a GND pour.**

### 3. Block copper saturates F.Cu

1629 of 1786 pre-routed segments arrive on F.Cu. Fixing this means rebalancing
block layouts in `../kicad-libs`, which is the expensive option.

## Where The Failures Cluster

From run 5's 121 unrouted connections:

| Region | Count | Character |
|---|---|---|
| RP2040 `U601` | ~22 | `+3.3V_MCU` ×9 **all U601-pin-to-U601-pin**, QSPI to `U602` ×6, USB ×6, XIN/XOUT, RUN, GPIO12/13/15 |
| TMC5130 `U1201` | ~13 | Motor phase escapes OA1/OA2/OB1/OB2, BRA/BRB, CPI, ENCN |
| Brake block | ~10 | GATE, V_SENSE, ISENSE_OUT/FB/DIV, VSET_RAW, LIMIT_OUT |
| Torque block | ~9 | REFCAP ×2, REFIO, VMID ×2, +5V_FILT ×3, +12V_FILT |
| GND | 39 | ~11 involve thermal-pad instances |

The `+3.3V_MCU` group is the clearest signal: nine failures, every one between
two pins of the same QFN-56. Those want a local copper pour, not traces threaded
between 0.4 mm-pitch pins.

## Next, In Order

Nothing below has been tried.

1. **Pour GND on B.Cu** rather than an inner layer. It carries 157 segments, so
   almost nothing is given up, both inner layers stay free for signals, and an
   outer GND pour is better for EMI than a buried one. Also makes
   `plane_via_costs = 5` apply to the board's largest net.
2. **Add local power pours** — `+3.3V_MCU` around `U601` first, then `+3.3V_SW`,
   `+5V_SW`, `+3.3V_MCU`. Power distribution was 35% of the remaining unconnected
   when last measured.
3. **Tune the router.** Start with `--router.scoring.via_costs=10` and the fanout
   escape-length floor; see the reference doc for the full command. Change one
   flag per run.
4. **Fix the thermal arrays upstream** in `../kicad-libs` so no board sees the
   phantom terminals.
5. **Only then consider 6 layers.** The evidence does not yet support it — this
   is a board using one layer out of four, not a board out of copper.

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
