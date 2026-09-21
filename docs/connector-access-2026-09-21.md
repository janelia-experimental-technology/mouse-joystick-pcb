# Connector access correction, 2026-09-21

The BNC outputs now have **24 mm centre spacing**, and the board remains fully
connected on four layers. The fabrication package under
`fab/routing-rescue-4layer/` has been regenerated; it replaces the earlier
package with 14 mm BNC spacing.

## Placement changes

Coordinates below are measured from the board's upper-left nominal edges,
with X right and Y down. That origin is (87.425, 55.000) in KiCad. All connector
origins remain on whole millimetres relative to the board, and rotations are
unchanged.

| Connector | Function | Before (X, Y), mm | After (X, Y), mm |
| --- | --- | --- | --- |
| J1101 | Angle BNC | (52, 55) | **(42, 55)** |
| J901 | Torque BNC | (66, 55) | (66, 55) |
| J1102 | Motor terminal | (34, 4) | **(29, 4)** |
| J1103 | Encoder terminal | (53, 4) | **(51, 4)** |
| J1601 | Limit-switch terminal | (68, 4) | (68, 4) |

Moving the angle BNC left avoids crowding the brake circuitry to the right of
the torque BNC. Their 12.5 mm square bodies now have an 11.5 mm gap. A
**16 mm diameter cable-plug allowance** leaves **8 mm between the two plug
envelopes**. This is a design allowance, not a maximum guaranteed for every
overmoulded cable or right-angle adapter. The approximate BNC STEP proxy was
not used to certify fit.

The motor and encoder headers moved left while retaining the top-row
alignment. The drawn housing gaps increased from approximately 1.1/0.6 mm to
**4.1/2.6 mm**; courtyard gaps are 3.8/2.3 mm. This adds room around the
pluggable terminal housings. Exact mating plug variants are still an assembly
choice; the numbers are measured from the board footprints.

Connector legends moved with the connectors. The encoder GND legend sits in
the gap to its right so that the nearby conditioning components do not obscure
it. No component value, library identifier or schematic connection changed.

## Mounting and other connectors

- The four 3.2 mm mounting holes remain on a **90 × 70 mm rectangle**, at
  (5, 5), (95, 5), (95, 75), and (5, 75). New rule areas keep tracks, vias and
  copper pours off both outer faces within a **7 mm hardware diameter** around
  each hole. Existing tracks did not cross these areas; inner layers are
  unaffected. Select heads, washers and standoffs that fit that allowance.
- The USB-C and RJ45 remain vertical/top-entry. Their drawn bodies do not
  require movement. Enclosure cutouts must allow the actual plug boots, RJ45
  latch access, and vertical insertion/removal; these are not electrical DRC
  checks. The side-actuated BOOT/RESET switches also need left-edge access.
- The vertical FH12 FFC connector remains near the lower edge. Its reviewed
  manufacturer model is 3.6 ±0.2 mm high closed and 5.5 ±0.2 mm open; leave
  additional room for fingers, cable insertion and bending. Use a cable meeting
  its straight-ended FFC specification. The previously owned eared Molex cable
  is still unqualified for this connector. See the
  [FH12 asset record](../../kicad-libs/docs/fh12-50-library-assets.md) and
  [cable guide](../../kicad-libs/docs/instrument-port-50-ffc-cables.md).

This review found no further required PCB placement changes from the available
connector/body geometry. It is not a fit qualification of an unspecified lid,
cable assembly or mating terminal plug.

## Routing and verification

The angle output was rerouted to its existing via on B.Cu. Local signal runs
were detoured around the new plated holes; the rail-sense and brake-current
signals use B.Cu between existing vias. One trigger via moved clear of a shell
pin. The motor escapes retain **0.8 mm track width**, encoder connections were
restored, and an obsolete one-layer brake-sense via was removed.

Final project-environment validation:

- ERC: **0 errors, 0 warnings**.
- DRC after zone refill: **0 errors, 0 unconnected pads**.
- Clearance regression with `--all-track-errors`: passes, with no
  voltage-bearing clearance findings.
- Existing warnings: **499 advisory clearances and 20 dangling vias**, unchanged
  in count. No new dangling-track warning remains and no design rule was relaxed.
- All **1,204** numbered pad identities match the schematic. Exactly three of
  364 footprints moved; all values, rotations and library identifiers match
  the previous routed board. Surviving track net assignments also match.
- The regenerated assembly files have **81 resolved BOM groups and 360
  placement rows**. This uses the local catalog, not a live stock reservation.

The previous board and order package are preserved in
`tmp/connector-access/baseline/` and `tmp/connector-access/baseline-fab/`.
Native repair operations and candidate validation are in `tmp/connector-access/`.

## Current artifacts

- [Fabrication ZIP](../fab/routing-rescue-4layer/mouse-joystick-pcb-jlcpcb.zip)
- [Connector clearance drawing](../fab/routing-rescue-4layer/reports/connector-clearances.svg)
- [Board-relative connector coordinates](../fab/routing-rescue-4layer/reports/connector-positions.csv)
- [Package notes, assembly files and validation](../fab/routing-rescue-4layer/README.md)
