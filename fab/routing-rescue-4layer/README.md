# Four-layer fabrication package

Generated from the completed `kicad/mouse-joystick-pcb.kicad_pcb` using the
project's `make fab` target and KiCad 10.0.6 on 2026-09-21.

Upload `mouse-joystick-pcb-jlcpcb.zip` for PCB fabrication. Assembly files are
`jlcpcb-bom.csv` and `jlcpcb-mouse-joystick-pcb-all-pos.csv`.

Board details:

- Four copper layers, ordered F.Cu / In1.Cu / In2.Cu / B.Cu.
- FR4, 1.6 mm thick; nominal outline 100 × 80 mm. KiCad's job metadata reports
  100.05 × 80.05 mm including the outline drawing's stroke width.
- The design stackup specifies 35 µm copper on each layer. Surface finish is
  unspecified in the project and remains an ordering choice.
- Minimum track width 0.10 mm; reported clearance minimum 0.1000 mm.
- Smallest through via is 0.45 mm diameter / 0.20 mm drill; no microvias or
  new filled via-in-pad requirements were introduced by the routing repair.
- Drill output contains 438 plated and 12 non-plated holes, with four plated
  slots. The combined Excellon file labels plating separately for each tool.

Validation:

- `reports/erc.rpt`: zero errors and zero warnings.
- `reports/drc-errors.rpt`: zero errors and zero unconnected pads.
- `reports/drc.rpt`: 499 advisory low-voltage clearance warnings and 20
  dangling-via warnings under the existing rules. No rule was relaxed.
- `reports/clearance-regression.txt`: passes the saved baseline, including
  `--all-track-errors`; no voltage-bearing clearance findings remain.
- `reports/schematic-parity.json`: all 1,204 numbered pad identities match the
  schematic; all 364 footprints retain their placement and identity.
- `reports/source-sha256.json`: hashes of the exact source files used.
- `reports/board-top.svg`: top copper and silkscreen preview.

All 81 BOM groups resolve in the local JLCPCB catalog, and all 360 assembly
designators have placement rows. This is catalog validation, not a live stock
reservation. No order has been placed.

See [the routing report](../../docs/routing-rescue-2026-09-21.md) for the five
completed connections, exporter corrections and remaining advisory findings.
