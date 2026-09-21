# Board 2 — `E4654C159F4D1334`, 2026-09-02

The **as-built** unit: `R203` intact, `LATCH` strapped to `+3.3V_MCU`. This is
what a v0.2 or v0.3 board does out of the box. (The captures in the parent
directory are board 1, `E4654C159F2C2534`, and `../latch-released/` is board 1
after `R203` was depopulated.)

Firmware `mouse-joystick-firm`, uncommitted working tree on top of `a7995da`,
`examples/TMC5130Communication` on env `mouse_joystick`. This is the build in
which **`PowerSequence::powerUp()` uses the staircase by default** rather than a
plain `HV_EN` assertion.

| File | Command | What it shows |
| --- | --- | --- |
| `hv-powerup-profile-no-36v.txt` | `p` | **Reference signature for "no 36 V connected."** Rail never moves (0.029-0.039 V) *and* `HV_SNS` never leaves its offset floor (0.016-0.020 V) for the full 250 ms. Below `V_S,UVLOR` (5.0-5.75 V) and `VS_ISNS` (5.9 V at `DIAG_EN` = 3.3 V) the switch does not operate and reports nothing. Compare a real fault, which pegs `HV_SNS` at 1.58 V within 1 ms |
| `latch-probe.txt` | `l` | Single-shot `HV_EN` with 36 V present: rail peaked 3.339 V, held **17 ms**, `~{HV_FAULT}` LOW. `[FAIL] this board still needs the workaround` — the expected answer for v0.1-v0.3 |
| `stage2-staircase-default.txt` | `s` | Full stage 2 on one command, staircase chosen automatically. Rail up in 132 ms, `VERSION` = 0x11, `drv_err` = 0, `uv_cp` = 0 |
| `hv-input-current.txt` | `m` | **13.7-13.8 mA** at 36 V, rails up, driver disabled |
| `power-down.txt` | `x` | Safe state |

## Two things worth knowing before reading these

**The 17 ms hold is not a different failure from board 1's 34 ms.** Both boards
latch off 1-2 ms into charging 208 µF; board 2's switch trips slightly earlier
and so reaches a lower `+36V_SW` peak, which leaves less stored charge to hold
the downstream rails up. Part-to-part variation in `T_REL` and die thermal
impedance.

**The 13.7 mA vs board 1's 8.6 mA is a 2-count difference**, on a sense ratio
(`K_SNS` = 800 A/A) specified at `I_OUT` = 1 A — 100× above where it is being
read. Do not conclude the boards draw different current. Both are "well under
20 mA"; that is the useful statement.

## `IOIN` differs between the two boards

Board 1 reads `0x11000011` (`REFL_STEP` high), board 2 reads `0x11000014`
(`ENCB` high), both with every connector empty, board 2's stable across three
consecutive reads. This is unresolved and it retracts a conclusion written
earlier the same day — see `../../../bringup-log.md` →
[the retraction](../../../bringup-log.md#the-two-rig-boards-disagree-on-refl_step-and-encb--retraction)
for the two bench tests that would settle it.
