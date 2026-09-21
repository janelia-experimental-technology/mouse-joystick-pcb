# Reverting the 6-layer experiment (2026-09-21)

The board was converted to 6 copper layers late in the 2026-09-21 autoroute
session. **The evidence says revert to 4** — plain 6-layer finished at 103
unrouted against 4-layer's 100, and the best 6-layer variant reached 98. Two
connections out of ~270 for roughly double the bare-board cost.
See ../../docs/autoroute-log.md.

These two files are the board and project as they were immediately BEFORE the
6-layer conversion, i.e. 4 layers with:
  - the /GND pour on B.Cu            (keep)
  - the QSPI netclass                (keep)
  - the MCU_FINE netclass            (keep)
  - the /GND pour on F.Cu            (was already removed - no effect)
  - the /+3.3V_MCU pour on In2.Cu    (was already removed - no effect)

To revert:

    cp fab/autoroute/REVERT-to-4layer.kicad_pcb kicad/mouse-joystick-pcb.kicad_pcb
    cp fab/autoroute/REVERT-to-4layer.kicad_pro kicad/mouse-joystick-pcb.kicad_pro

Then re-export and re-run with STOCK router settings (no flags):

    make export-dsn
    freerouting -de fab/autoroute/mouse-joystick-pcb.dsn -di fab/autoroute/

That reproduces run H (100 unrouted), the best 4-layer result.

`git checkout kicad/` also restores 4 layers but discards both netclasses,
which are worth 11 connections. Prefer the copies above.
