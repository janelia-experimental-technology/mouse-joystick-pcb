# Four-layer fabrication package

Generated from the completed `kicad/mouse-joystick-pcb.kicad_pcb` using the
project’s `make fab` target and KiCad 10.0.6 on 2026-09-21.

**Updated after the connector access review:** the BNCs now have 24 mm centre
spacing, the motor/encoder terminals have wider housing gaps, and all four
mounting holes have 7 mm outer-copper hardware clearances. This ZIP replaces
the earlier package with 14 mm BNC spacing.

Upload `mouse-joystick-pcb-jlcpcb.zip` for PCB fabrication. Assembly files are
`jlcpcb-bom.csv` and `jlcpcb-mouse-joystick-pcb-all-pos.csv`.

**Placement rotations, updated 2026-09-21.** The first upload of this package
placed 37 of 360 parts at the wrong angle, because KiCad footprints use the
IPC-7351 body orientation and JLCPCB's placement data uses the part's carrier
tape orientation. The CPL now carries the per-footprint correction from
`kicad-libs/vendor_specs/jlcpcb/footprint-rotations.csv`; see that repository's
`docs/jlcpcb-footprint-rotations.md`. `reports/mouse-joystick-pcb-jlcpcb-rotations.txt`
lists what was corrected and which footprints still have no entry and therefore
still need an eyeball in the JLCPCB placement viewer. Rotations are now
normalised to [0, 360), so rows that were not corrected still differ from the
earlier CPL: `-90` is now written as `270`.

Board details:

- Four copper layers, ordered F.Cu / In1.Cu / In2.Cu / B.Cu.
- FR4, 1.6 mm thick; nominal outline 100 × 80 mm. KiCad's job metadata reports
  100.05 × 80.05 mm including the outline drawing's stroke width.
- The design stackup specifies 35 µm copper on each layer. Surface finish is
  unspecified in the project and remains an ordering choice.
- Minimum track width 0.10 mm; reported clearance minimum 0.1000 mm.
- Smallest through via is 0.45 mm diameter / 0.20 mm drill; no microvias or
  new filled via-in-pad requirements were introduced by the routing repair.
- Drill output contains 437 plated and 12 non-plated holes, with four plated
  slots. The combined Excellon file labels plating separately for each tool.

Validation:

- `reports/erc.rpt`: zero errors and zero warnings.
- `reports/drc-errors.rpt`: zero errors and zero unconnected pads.
- `reports/drc.rpt`: 499 advisory low-voltage clearance warnings and 20
  dangling-via warnings under the existing rules. No rule was relaxed.
- `reports/clearance-regression.txt`: passes the saved baseline, including
  `--all-track-errors`; no voltage-bearing clearance findings remain.
- `reports/schematic-parity.json`: all 1,204 numbered pad identities match the
  schematic. J1101, J1102 and J1103 moved as documented; the other 361
  footprints are unchanged. All values, rotations and library IDs are retained.
- `reports/source-sha256.json`: hashes of the exact source files used.
- `reports/board-top.svg`: top copper and silkscreen preview.
- `reports/connector-clearances.svg`: connector arrangement with the 16 mm
  BNC plug allowance and 7 mm mounting-hardware clearances.
- `reports/connector-positions.csv`: board-relative coordinates for enclosure
  work; origin at the upper-left nominal board edges, X right, Y down.
- `reports/mechanical-review.json`: dimensions and the limits of the mechanical
  review. Exact cable boots, mating plugs, latch access and lid geometry remain
  enclosure-specific checks.

All 81 BOM groups resolve in the local JLCPCB catalog, and all 360 assembly
designators have placement rows. This is catalog validation, not a live stock
reservation. No order has been placed.

See [the connector access report](../../docs/connector-access-2026-09-21.md)
for current placement and mechanical details, and
[the initial routing report](../../docs/routing-rescue-2026-09-21.md) for the
exporter corrections and original routing completion.
