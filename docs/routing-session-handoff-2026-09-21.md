# Routing session handoff, 2026-09-21

## Resume from the completed board

The current four-layer PCB and fabrication package are committed in
`d5ae4b0` (`Move connectors to make room for cables`), following `fd3dd93`
(`Routing success`). Start from `kicad/mouse-joystick-pcb.kicad_pcb`.
The routing task is complete; no order has been placed by this session.

- BNC pitch is **24 mm**, with board-relative centres (42, 55) and (66, 55) mm.
  The 16 mm plug envelope leaves an 8 mm gap. Motor/encoder terminal gaps were
  widened, and each mounting hole has a 7 mm outer-copper hardware allowance.
- Project-environment ERC: **0 errors, 0 warnings**. DRC: **0 errors,
  0 unconnected pads**. All 1,204 numbered schematic pad identities match.
- The **499 advisory clearances and 20 dangling vias** are recorded remaining
  warnings. Clearance regression passes with no voltage-bearing findings.
  Rules were not relaxed to obtain this result.
- Use the regenerated
  [fabrication package](../fab/routing-rescue-4layer/README.md), including its
  ZIP, 81-group assembly BOM, 360-row placement file and source hashes.
  It supersedes the earlier package with 14 mm BNC spacing.
- The [mechanical report](connector-access-2026-09-21.md) records connector
  coordinates and remaining mating-plug/enclosure allowances. The vertical
  FH12 requires its specified straight-ended FFC; the previously owned eared
  Molex cable is not qualified for it.

Older Rev 0 planning and routing notes contain obsolete component counts,
pin assignments and claims that the board is empty or needs six layers.
For the current routing/placement state, use this handoff and the two completion
reports. Routing verification does not replace firmware or bench validation.

## What made routing succeed

The decisive step was importing the existing **run H** session into KiCad and
refilling copper zones. Freerouting's **100 unrouted** became **five actual
missing connections**. Many router residuals were representations of copper
already joined in KiCad, including filled zones and overlapping thermal pads.

The five remaining connections were two short ground joins, two supply
branches and `TQ_SPI_COPI`. Local repairs used existing ground copper, B.Cu
routes and staggered signal fanout with ordinary through vias. Imported shorts,
HV clearances and an undersized QSPI segment were also repaired. See the
[routing completion report](routing-rescue-2026-09-21.md).

The DSN exporter was corrected to preserve filled-zone contours and holes with
proper plane/window nesting, bridge duplicated pads only within existing
same-net copper, and apply `protect` to both locked and unlocked prerouting
when requested. The unsafe old bridge logic had drawn BNC ground tracks through
the signal pins. Existing QSPI/MCU_FINE signal classes at 0.15/0.15 mm also
helped the historical run escape fine-pitch packages.

**This is a verified routed board with local completion, not a demonstrated
fully automatic cold-start recipe.** The corrected exporter passed its five
regression tests and loaded in Freerouting, but its exploratory runs were
stopped after run H proved nearly complete. The later connector moves were
repaired locally too; no fresh full-board Freerouting run was needed.

## Measured runtime

The preserved [run H timing excerpt](evidence/freerouting-run-h-timing.txt)
records Freerouting v2.4.1 on this workstation, 2026-09-21:

| Interval | Elapsed |
| --- | --- |
| Startup through final optimization message | **21 min 43.702 s** |
| Fanout and routing together | **18 min 1.13 s** |
| Fanout within that interval | 1 min 22.91 s |
| Optimization, including its setup | 3 min 35.56 s |

The log's reported 1081.13-second "Auto-routing stage" interval starts at the
beginning of routing **before fanout**. Do not add the 82.91-second fanout time
again. Timestamped maze-routing alone is about 16 min 38 s.

This run used the older exporter and **31 configured threads**. It stopped with
100 router residuals and still required import/refill and the repairs above.
Export, import, zone refill, local repairs, mechanical edits and fabrication
checks are excluded from the 21 min 44 s. A separate reproducible total for
that engineering work was not recorded. There is **no measured completion
time for a fresh run with the corrected exporter and recommended one thread**.

## Future edits and optional routing experiments

Preserve the finished board and make a separate candidate before further
routing. There is no need to reroute it merely to close or reopen a session.
The next requested work can start with ordering, enclosure design or bring-up.

If new changes need autorouting, use the project's KiCad environment:

1. Refill/export with `python3 scripts/export_dsn.py --refill --protect-prerouted`.
2. Use Freerouting v2.4.1 with stock costs/fanout and
   `--router.max_threads=1`. The historical combined lower-via-cost/fanout
   experiment performed worse; raising pass limits did not resolve the stall.
3. Import with `python3 scripts/import_ses.py --refill`, inspect actual KiCad
   opens and DRC, and run `make clearance-check`. The DSN does not carry KiCad's
   scoped custom rules. `--fit-pitch` is not a clearance waiver.
4. Verify schematic parity and regenerate fabrication outputs after PCB edits.
   The known working fabrication command is in the
   [completion report](routing-rescue-2026-09-21.md#order-files).

These are starting settings, not a benchmarked guarantee of automatic
completion. To establish one, time export, routing, import/refill and DRC
separately on a saved unfinished candidate, retaining the DSN, settings, session
and log. Check the imported result even when the router counter stalls.

The reusable guidance lives in
[`kicad-libs/docs/freerouting-autorouting.md`](../../kicad-libs/docs/freerouting-autorouting.md).
Local repair scripts and diagnostic snapshots remain under
`tmp/routing-rescue/` and `tmp/connector-access/`; these ignored scratch files
are not needed to use the committed PCB or order package. Future promotion of
the proven local escapes into their owning design blocks is optional follow-up.

One existing library divergence was rechecked during handoff: the reusable
`tmc5130` block still contains 0.12 ohm R4003/R4004, while this board correctly
uses 0.15 ohm R1203/R1204 (`OW-PASS-RLH12FTCR150`). An older checked item in the
board plan incorrectly implied the library was fixed. Do not replace the board's
driver block from that source without preserving its required shunts. The
library correction is separate follow-up; the current board and order BOM
already contain the correct values. Keep the firmware's `vsense = 1` decision
paired with the 0.15 ohm shunts.
