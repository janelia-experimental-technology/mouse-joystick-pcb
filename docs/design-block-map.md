# Design Block Map

**Retired 2026-10-13.** This map was the hand-written record of which library
block implements what and of the v1.0 rebuild; it is superseded by the pages
`make docs` generates from the board source and the library:

- [`docs/generated/blocks/README.md`](generated/blocks/README.md): every placed
  block, one page each, with its description, ports and meanings, parts as
  placed with the brief's roles and the chip pin each sits beside, the brief's
  placement and routing guidance, and the library identity (published hashes,
  whether the placed sheet is the library's).
- [`docs/generated/subsystems/README.md`](generated/subsystems/README.md): the
  four subsystem sheets from their recipes, with the blocks by role, the glue
  parts and their nets.
- [`docs/generated/gpio-allocation.md`](generated/gpio-allocation.md): the MCU
  pin allocation from `kicad/board.yaml`'s `nets`.

Since v1.0 the placed sheets are regenerated from the library with the copper
kept (`make refresh-block INSTANCE= REFRESH_BLOCK_OPTIONS=--keep-copper`), so
the warnings this map carried about re-placing blocks no longer apply: the
tmc5130 block is the family's `tmc5130_spi_r150` with 0.15 ohm shunts, the two
TPSM365R6 regulators are their family's `5v` and `12v` configurations, and the
board-level pulls live in the subsystem recipes
(`kicad/subsystems/*.subsystem.yaml` and the library's
`motor_encoder_switch`), whose notes say why each is the board's. The history
this file held is in git before this date.
