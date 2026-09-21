# Four-layer routing completion, 2026-09-21

The board is fully connected on four copper layers. KiCad 10.0.6 reports zero
unconnected items and zero DRC errors after zone refill. All 1,204 numbered
pad identities match the exported schematic netlist (decoding KiCad's
`{slash}` escape in two no-connect names). All 364 footprints retain their
positions, rotations, values, and library identifiers. The schematic, project
netclasses, and custom design rules were not changed.

The previous Freerouting result labelled **100 unrouted** (`runH.ses`) actually
left **five KiCad connections** after import and refill. Router completion
counts were an unreliable release metric. Import the result and measure KiCad
connectivity before concluding that a board needs more layers or a redesign.

## What was repaired

- Restored the four-layer geometry from the recovery copy, with GND pours on
  F.Cu/B.Cu and the local MCU supply pour on In2.Cu. This copy actually had
  three pours, despite the recovery README describing one.
- Reused run H's routing. Removed two exporter-created diagonal GND tracks
  which shorted the BNC centre pins to their shell pads.
- Connected U1201 pin 9 and U1301's grounded input group to their existing
  exposed-pad ground copper with short front-layer traces. Neither needed
  via-in-pad or another layer.
- Connected the torque ADC's switched 3.3 V branch and the InstrumentPort's
  MCU 3.3 V branch on B.Cu.
- Completed `TQ_SPI_COPI`: adjusted the neighbouring SCK/CIPO fanout to use
  0.45/0.20 mm through vias, staggered the CIPO via, added a 0.15 mm local
  escape and a 0.20 mm bottom-layer route. These are standard drilled vias,
  not laser microvias or filled via-in-pad.
- Repaired imported HV/12 V/motor clearances with local track/via changes,
  including moving the 1.0/0.5 mm `+36V_SW` via from (149.425, 84.5) to
  (149.125, 84.5). Its power-carrying geometry is retained.
- Restored the undersized QSPI clock segment from 0.09 to the existing
  0.10 mm manufacturing floor. No design rule was relaxed.

## Export/import bugs fixed

`scripts/export_dsn.py` now:

1. Places replacement planes **inside** the DSN `structure` scope.
2. Places clearance windows **inside their owning planes**.
3. Unfractures KiCad filled polygons into contours and holes before export.
   The four-layer input has 531 windows; the old exporter emitted none.
4. Bridges duplicate-number pads only when their centres lie within the same
   convex copper pad. Shared connector pin numbers do not justify drawing
   straight lines between them: the previous BNC bridges crossed signal pins.
5. Applies `--protect-prerouted` to locked (`fix`) copper as well as `route`
   copper. The old option missed 1,992 locked items on this input.
6. Supports `--refill` without changing the source PCB. The importer also
   supports `--refill` before saving.

Five regression tests cover scope nesting, cutout nesting, BNC shell pads,
thermal-pad bridges, and different-net protection:

```sh
python3 scripts/test_export_dsn.py
```

The corrected exporter was checked structurally and loaded by Freerouting.
Exploratory runs were stopped once importing the existing session revealed
only five real missing connections. **There is no completed new benchmark
claiming that these export changes alone make Freerouting finish the board.**
The released layout uses the existing run H plus the repairs above.

## Verification and remaining warnings

- Four copper layers, 1.6 mm overall board thickness.
- Zero unconnected items and zero DRC errors in the completed candidate.
- The final `make fab` build completed successfully in the project's KiCad
  10.0.6 environment: ERC has **zero errors and zero warnings**, DRC has
  **zero errors and zero unconnected pads**.
- Full schematic-to-PCB pad/net comparison passes.
- `scripts/clearance_check.py` passes against the saved baseline: 499 advisory
  findings remain, all voltage-bearing pairs are cleared, and unconnected
  items fell from 149 to zero. This check includes `--all-track-errors`.
- Final DRC retains **499 advisory low-voltage clearance findings and 20
  dangling-via warnings**. The 199 footprint-library warnings seen in the MCP
  environment disappear in the configured fabrication environment. Reported
  clearance findings bottom out at 0.1000 mm. Existing advisory rules and all
  HV/fab constraints are unchanged.
- The remaining one-layer vias include design-block escape/stitching stubs;
  they are not unrouted connections. Blanket removal would unnecessarily
  disturb the inherited layouts.

Native reports, snapshots, and exact local repair operations are under
`tmp/routing-rescue/`; final manufacturing outputs are under
`fab/routing-rescue-4layer/`. The original six-layer PCB and project were
preserved in `tmp/routing-rescue/baseline/` before updating `kicad/`.

## Order files

- [Gerber/drill upload ZIP](../fab/routing-rescue-4layer/mouse-joystick-pcb-jlcpcb.zip)
- [Assembly BOM](../fab/routing-rescue-4layer/jlcpcb-bom.csv): 81 groups, all
  resolved against the local JLCPCB catalog, covering 360 components.
- [Assembly positions](../fab/routing-rescue-4layer/jlcpcb-mouse-joystick-pcb-all-pos.csv):
  360 rows, with BOM-to-position validation passed.
- [Package notes](../fab/routing-rescue-4layer/README.md) and
  [top copper/silkscreen preview](../fab/routing-rescue-4layer/reports/board-top.svg).

The ZIP's integrity and Gerber job file were checked: exactly four copper
layers in F/In1/In2/B order, 1.6 mm board thickness, masks, silkscreens, paste,
outline, and drill data. The drill report has 438 plated and 12 non-plated
holes, including four plated slots. Source hashes still match the checked
schematic, PCB, project and rules. Catalog resolution is not a live stock quote.

Fabrication command used:

```sh
make fab GUIX_MANIFEST_KICAD=.guix/manifest-kicad-local.scm \
  GUIX_SHELL_EXTRA_OPTIONS='-L .guix/local-modules' \
  FAB_OUTPUT_DIR=fab/routing-rescue-4layer FAB_OPTIONS=--no-clean
```

## Future routing

For future runs, refill/export, route, import/refill, then inspect KiCad DRC:

```sh
python3 scripts/export_dsn.py --refill --protect-prerouted
# Run Freerouting with one routing/optimization thread.
python3 scripts/import_ses.py --refill
make clearance-check
```

Do not use `--fit-pitch` as a fabrication clearance waiver: its DSN-only global
relaxations do not replace the scoped KiCad rules. Do not order a six-layer
board based only on Freerouting's residual count.
