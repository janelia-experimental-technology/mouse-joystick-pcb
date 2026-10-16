# Converting The BNC Voltages

What the angle and torque BNC outputs of a v1.0 board mean in degrees and
newton-centimetres, for whoever records them on the OneBox. The circuits are
described in `docs/onebox-analog-interface.md` and
`docs/encoder-analog-output.md`; this page is only the conversion and its
provenance. Measurements are in `docs/bringup-log.md`.

## Angle

The firmware maps the angle range given by the session's `ANGSCALE` command
(`docs/uart-protocol.md`) onto the DAC's 0.05 to 3.300 V, and the v1.0 output
divider halves that at the BNC:

```
V_angle  =  0.025 V  +  (angle − lo) / (hi − lo)  ×  1.625 V
angle    =  lo  +  (V_angle − 0.025) / 1.625  ×  (hi − lo)
```

The rig's task sends `ANGSCALE −10.125 0.0`, the board's travel, so 0.025 V
is −10.125° and 1.650 V is 0°, and the output is 0.160 V per degree. Record
the `ANGSCALE` values with every session; they are the only thing the formula
depends on.

Provenance: the DAC-to-BNC transfer measured unity to 0.03 % with a +0.2 mV
offset on board 4 (bring-up log, 2026-09-10) and within 0.5 % through the
boards' own monitor on v1.0 units A and B (2026-10-05 and 2026-10-07). One
encoder count is 0.09°, or 14 mV at the BNC on the rig's scale, so the
hardware error is under half a count. Below about 12 mV the output is at its
floor and means the output is off, unhomed or faulted, not an angle.

## Torque

Zero torque sits at the midpoint of the chain and torque is the departure from
it. With the sensors' certificate sensitivity, the mean of the two certificates
at 1.5605 mV/V:

```
V_torque  =  V_rest  +  0.141 V per N·cm  ×  torque
torque    =  (V_torque − V_rest) / 0.141
```

**Take `V_rest` from the trace itself, per trial**, from the segment before the
brake releases the lever or from the released lever at rest. The rest level is
a mechanical preload that differs by station and sign (−0.25 V on one desk
station, +0.08 V on the other, against a nominal 0.833 V), moves by 0.04 V or
more after a hard load, and is not the nominal midpoint. The firmware tares
the same way before every watch.

Sign: on the right stations a pull reads positive, on the left stations
negative. The firmware's events use the magnitude.

Provenance: the chain's gain is in the firmware's conversion header
(`mouse-joystick-firm/src/Conversions.hpp`), and since 2026-10-16 the firmware
converts on the same certificate mean, so the torques in pyControl's log (the
`RELEASED`, `TOUCH` and `TRIAL` events, the `FETCH` capture) and the torques
from the trace through the formula above agree. A board still on firmware
`v1.0.0` reports on the nominal 1.5 mV/V, 4 % high; the `ID` reply names the
build. On 2026-10-16 a force gauge on a string, with the gear train removed,
read the right desk station's sensor at 0.965 of the torque through the brake
against 0.961 expected from the certificate on that nominal scale, so the
constant above is confirmed to a few percent.

## The torque the mouse works against

The trace reads the torque through the brake. The mouse also pays the lever's
friction, which the sensor never sees, and the brake does not deliver the
torque it was commanded. Both are properties of each station, measured with a
force gauge and kept in [`station-torque-table.csv`](station-torque-table.csv)
by rig, station and board serial; the two desk stations are filled in and the
Rig 1 rows wait for their measurement. With `tau_b` the trace's torque from
the formula above and the table's values for the station:

| Situation | Load on the mouse |
| --- | --- |
| The lever is moving (the brake slipping) | `tau_b + friction` for the direction of motion; `tau_b` itself sits at the brake's delivered torque for the session's setting, the `delivered_at_*` column |
| The lever is held by the brake and the mouse is loading it | about `tau_b / static_share`, and never more than `tau_b + friction` |
| The brake is off | `friction + brake_drag`; the trace shows only the drag |

The lever's inertia is small enough to ignore at the speeds a mouse moves it.
At the 75 mm grip, 1 N·cm is 13.6 gF, so a desk station's friction of
0.25 to 0.46 N·cm is 3.4 to 6.3 gF before any brake is applied, and the
task's commanded 1.0 N·cm delivered 0.42 on one desk brake and 0.6 on the
other.

Columns of the table: `torque_sign_of_pull` is the sign the trace takes when
the mouse pulls; `friction_*` is the kinetic friction at the lever for each
direction, N·cm; `brake_drag_coil_off_ncm` the brake's own drag with no
current, which does appear on the trace; `static_share` the fraction of a
static load that reaches the sensor; `delivered_at_*` the torque the brake
actually produced when commanded 0.5, 1.0, 2.0 and 3.5 N·cm; `rest_offset_ncm`
the typical raw rest reading, for recognising the station in a trace. Blank
means not measured. The procedure that fills a row is
`mouse-joystick-firm/docs/torque-calibration.md`.

## What the torque trace means

The sensor sits behind the brake and reads the torque passing through the
brake, nothing else.

- While the brake holds the lever, that is the mouse's torque less a share
  taken by static friction in the lever axis, 15 to 20 % on the desk stations.
- Once the lever slips, the reading flattens at the brake's slip torque
  however hard the mouse pulls. The angle channel, not the torque channel,
  describes the movement.
- The lever's own friction, 0.25 to 0.5 N·cm per station as measured on the
  desk rig, is paid by the mouse and never appears on the torque trace.
- The brake does not deliver its commanded torque at the low end: the task's
  1.0 N·cm setting delivered 0.4 to 0.7 N·cm on the desk stations, full
  current 3.0 on one and 4.0 on the other. Per-station numbers are in the
  table above and in the bring-up log; Rig 1's stations are not yet measured.

Noise on the torque channel is about 0.4 mN·cm rms, far below any of this.
