# Harness Pinouts — Left And Right Joystick

**The two joysticks use different harnesses so that the boards and the firmware
can be identical.** The left joystick is mechanically mirrored, so its motor
must turn the other way and its encoder must count the other way for the same
commanded direction. Both reversals are done in the **cable**, not in
configuration, which means a board carries no left/right state at all and can be
swapped between stations with nothing to set.

The cost is two cable variants that look identical once the connectors are on.
**Label them.** The consequences of getting one wrong are in
[If A Cable Is Wrong](#if-a-cable-is-wrong) below, and the firmware detects every
one of them.

## Board Side — Identical On Both Stations

Read from the `.kicad_pcb` pad-to-net map. **Verified identical at tag `v0.2`
and at HEAD**; only the designators and the connector body differ, so the same
harness fits a rev 0 board and a rev 1 board.

| | v0.2 (the assembled boards) | HEAD / rev 1 |
| --- | --- | --- |
| Motor, 4-pos 3.5 mm | `J1101`, horizontal screw | `J1102`, vertical |
| Encoder, 5-pos 3.5 mm | `J1102`, horizontal screw | `J1103`, vertical |
| Limit switch, 2-pos | `J1301` | `J1301` |

**The designators shift between revisions and the pin functions do not.** Wire
to the pin numbers below, never to a designator remembered from a document.

### Motor connector, 4 positions

| Pin | Net | TMC5130A pin |
| --- | --- | --- |
| 1 | `OB2` | coil B, second output |
| 2 | `OB1` | coil B, first output |
| 3 | `OA2` | coil A, second output |
| 4 | `OA1` | coil A, first output |

Note the ordering: **coil B is on pins 1-2 and coil A is on pins 3-4**, and each
coil's outputs run "second, first" as the pin number increases. It is not the
order anyone would guess, which is the reason this table exists.

### Encoder connector, 5 positions

| Pin | Net | Note |
| --- | --- | --- |
| 1 | `GND` | |
| 2 | *no connect* | reserved for an index channel; there is no `ENC_N` net |
| 3 | `ENC_A_RAW` | |
| 4 | `+5V_SW` | supply sits between the two channels, so a one-position slip shorts 5 V to a channel |
| 5 | `ENC_B_RAW` | |

The encoder supply is on the **switched** domain, so the encoder loses power
whenever `HV_EN` drops. That is deliberate.

### Limit switch connector, 2 positions

| Pin | Net |
| --- | --- |
| 1 | `GND` |
| 2 | `IN` — `U1301` MAX6816 input |

Normally-closed switch, both stations. `IN` has no external pull of any kind:
the MAX6816 supplies its own, so `REFL` rests **low** and goes **high** when the
switch is triggered. No harness difference between left and right.

## Part Side

**Motor — Lin Engineering WO-208-13-01D**, 4-lead bipolar. Lead numbering and
the three color codes the vendor ships, from `datasheets/motor-wiring.png`:

| Lead | Bipolar | Code 1 | Code 2 | Code 3 |
| --- | --- | --- | --- | --- |
| 1 | A | red | brown | red |
| 2 | ~A | blue | orange | red / white stripe |
| 3 | B | green | red | green |
| 4 | ~B | black | yellow | green / white stripe |

**Check which color code your motors shipped with before cutting anything** —
red means lead 1 under code 1 and lead 3 under code 2.

**Encoder — US Digital E4T-1000**, single-ended, 4-pin `MIC4`:

| Pin | Signal |
| --- | --- |
| 1 | +5 V |
| 2 | A |
| 3 | GND |
| 4 | B |

## Right Joystick Harness — The Reference

**Settled on hardware, 2026-09-02: the encoder's A and B channels are CROSSED
relative to the board's `ENC_A`/`ENC_B` pins.** Measured both ways round on the
right joystick: crossed gives a follow ratio of **+1.0102**, straight through
gives **-0.89**. The encoder tables below are the confirmed reference.

Why crossing is correct rather than a mistake: the E4T's datasheet specifies
"A leads B for clockwise shaft rotation ... **viewed from the cover side of the
encoder**". The encoder sits on the motor's **rear** shaft while the gear train
is driven from the front, so the cover side faces opposite to the end that
defines the mechanism's direction. A reversal is the expected outcome of that
geometry, and crossing the channels in the harness cancels it — which is why
firmware ships `encoder_inverted = false`.

Still run the check in [Verify It](#verify-it-do-not-trust-it) on each station.
If `follow ratio` comes out about −1.0, the channels are not crossed.

### Motor

| Board pin | Net | Motor lead | Code 1 color |
| --- | --- | --- | --- |
| 1 | `OB2` | 4 (~B) | black |
| 2 | `OB1` | 3 (B) | green |
| 3 | `OA2` | 2 (~A) | blue |
| 4 | `OA1` | 1 (A) | red |

### Encoder

| Board pin | Net | Encoder pin | Signal |
| --- | --- | --- | --- |
| 1 | `GND` | 3 | GND |
| 2 | *no connect* | — | — |
| 3 | `ENC_A_RAW` | **4** | **B** |
| 4 | `+5V_SW` | 1 | +5 V |
| 5 | `ENC_B_RAW` | **2** | **A** |

**Crossed, and confirmed on hardware.** This is what gives a follow ratio of
+1.0 with the shipped `encoder_inverted = false`.

## Left Joystick Harness — Two Swaps, And Only Two

Everything is identical to the right harness except:

1. **Swap the two leads of ONE motor coil.** Coil A is the convenient one:
   board pin 3 takes motor lead **1 (A, red)** and board pin 4 takes motor lead
   **2 (~A, blue)** — the reverse of the right harness. Leave coil B alone.
2. **Swap the encoder's A and B channels relative to the right harness.** The
   right is crossed (board pin 3 ← encoder B, pin 5 ← encoder A), so the left is
   straight through (pin 3 ← A, pin 5 ← B). Leave GND and +5 V alone.

### Motor

| Board pin | Net | Motor lead | Code 1 color | vs. right |
| --- | --- | --- | --- | --- |
| 1 | `OB2` | 4 (~B) | black | same |
| 2 | `OB1` | 3 (B) | green | same |
| 3 | `OA2` | **1 (A)** | **red** | **swapped** |
| 4 | `OA1` | **2 (~A)** | **blue** | **swapped** |

### Encoder

| Board pin | Net | Encoder pin | Signal | vs. right |
| --- | --- | --- | --- | --- |
| 1 | `GND` | 3 | GND | same |
| 2 | *no connect* | — | — | same |
| 3 | `ENC_A_RAW` | **2** | **A** | **swapped** |
| 4 | `+5V_SW` | 1 | +5 V | same |
| 5 | `ENC_B_RAW` | **4** | **B** | **swapped** |

So the left harness is the *straight-through* order and the right is crossed.
Both stations then read a positive follow ratio for the same anatomical motion.

### Limit switch

No difference. Two wires, either way round, normally closed.

## Why Exactly Two Swaps

Reversing **one** coil's leads reverses the motor's rotation for a given
commanded direction. Reversing **both** coils does not — it is the same
electrical phase order, so the shaft turns the same way. Exchanging the two
coils with each other (A pair onto B pins) also reverses, but it touches four
wires instead of two, so one coil is the better choice.

Reversing the encoder's A and B channels reverses the sign of `X_ENC` for a
given shaft rotation.

The mirrored mechanism means the same *anatomical* joystick motion needs the
opposite motor shaft rotation. So:

- swapping one motor coil makes a positive command produce the same anatomical
  motion on both sides,
- swapping the encoder then keeps `X_ENC` positive for that motion on both
  sides,
- and the limit switch needs nothing, because if it is at the same anatomical
  end on both mechanisms then it is at the same commanded-position sign on both.

Three facts made identical by two swaps.

## Verify It, Do Not Trust It

A mis-built cable is invisible. Every failure mode it can produce is detectable
in a couple of minutes with `mouse-joystick-firm` `examples/MotionAndHoming` —
see `../mouse-joystick-firm/docs/motion-bringup.md`. Run this on **each** station
after building its harness:

1. `b`, `c` — rail up, bus closed, `vsense` read back as 1.
2. `e`, then `j` and `k` — the joystick moves, and `follow ratio` is about
   **+1.0**. A ratio near **−1.0** means the encoder channels are swapped
   relative to the motor. A ratio near **0** means the mechanism is against an
   end stop; jog the other way first.
3. `W` — the sweep finds the switch and reports `triggered level = 1`.
4. `h` — homing reaches the switch and reports `[ ok ] homed`.
5. `H` — five runs, and the spread should be a couple of encoder counts.

**Both stations must produce the same signs.** If the left joystick moves the
opposite anatomical way from the right for the same jog, one motor coil swap was
missed or applied twice. If its follow ratio is negative while the right's is
positive, the encoder swap was missed.

## If A Cable Is Wrong

| Symptom | Cause |
| --- | --- |
| `follow ratio` about −1.0 | encoder A/B swapped relative to the motor. One swap too many, or one too few. |
| The joystick moves the wrong anatomical way | motor coil swap missed, or applied to both coils (which cancels). |
| Homing reports `NOT FOLLOWING -- end stop` | driving away from the switch: motor direction is reversed relative to the switch end. |
| Homing reports `travelled the whole bound` | the switch never asserted. Suspect the switch harness, not the motor. |
| `IOIN` shows `ENCA`/`ENCB` stuck | encoder unpowered or a one-position slip on the 5-pos connector. **Pin 4 is +5 V and sits between the two channels.** |
| Motor buzzes and does not turn | the two coils are cross-wired — one lead of coil A landed on a coil B pin. |

Nothing in that list can damage anything at the bring-up run current
(`IRUN` 8, 0.211 A RMS): the motor stalls and the firmware's encoder follow
check ends the move.

## If The Canonical Direction Is Wrong For The Experiment

If both joysticks work and move consistently, but positive commands drive the
*wrong* anatomical way for the protocol, swap one motor coil on **both**
harnesses. That flips both stations together and preserves the mirror. Do not
fix it in firmware — the point of doing it in the cable is that there is no
firmware difference to keep track of.
