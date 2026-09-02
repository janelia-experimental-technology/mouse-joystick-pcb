# `R203` depopulated — `LATCH` released, 2026-09-02

Same board, same session, same firmware as the parent directory. The **only**
change is that `R203` (0402, `+3.3V_MCU` → `LATCH`, 1 kΩ) has been removed from
the board, so the TPS1HTC100-Q1's internal 0.7-1.3 MΩ pulldown holds `LATCH`
low and the device selects **auto-retry** (`t_RETRY` = 2 ms) instead of
latch-off.

**A plain `HV_EN` assertion now works.** No firmware staircase needed.

| File | Command | What it shows |
| --- | --- | --- |
| `hv-powerup-profile-{1..4}.txt` | `p` ×4 | Fault asserts at t = 0-1 ms, the device retries, **fault clears at t = 11-12 ms**, rail up at 3-4 ms and still up at 249 ms. 4 of 4 |
| `stage2-plain-hv-en.txt` | `s` | The full stage 2 sequence end to end on a single `HV_EN` assertion: rail up in 4 ms, no latched fault at the 105 ms check, bus closed, TMC5130A registers read |
| `hv-input-current.txt` | `m` | **36 V input current = 8.6 mA**, rails up, driver disabled, nothing plugged into the motor/encoder/limit connectors |
| `power-down.txt` | `x` | Safe state |

## The retry window is the whole story

`p` samples at 1 ms, so the retry sequence is visible directly:

```text
  t_ms  rail_V  sns_V
     1   0.031  1.583   <- fault asserts, switch trips on the first burst
     4   3.312  1.567   <- +36V_SW has already cleared the buck's threshold
    10   3.315  1.590   <- still retrying
    11   3.315  0.437   <- fault CLEARS: charging finished, no more trips
    12   3.314  0.065
    13   3.314  0.026   <- settled, and now a real load reading
```

At `I_CL` ≈ 1.15 A into 208 µF each burst adds ~8-10 V, so 36 V takes 3-4
bursts. With `t_RETRY` = 2 ms plus ~1.8 ms of conduction that is ~11-15 ms of
retrying. Measured: 10-12 ms. The model and the board agree.

## Caveat on the 8.6 mA

Repeatable to ±0.1 mA across three runs (delta 3.33-3.35 counts, zero
19.65-19.68 counts), but `K_SNS` = 800 A/A is specified at `I_OUT` = 1 A and
this is 100× below that. Read it as **"under 10 mA"**, not as 8.6 mA ± 0.1 mA.
The precision is real; the accuracy is uncharacterised at this current.

It does cross-check the energy accounting in the parent write-up: 8.6 mA × 36 V
= 310 mW, of which `U201`'s own `I_Q,VS` (1.2-1.65 mA with `DIAG_EN` high) is
drawn upstream of the bulk, leaving ~260 mW on `+36V_SW`. The write-up assumed
0.2 W. Substituting 0.26 W moves the inferred turn-on peak from ~11.8 V to
~12.2 V and the "if it had reached 36 V" hold from 650 ms to 519 ms — still an
order of magnitude above the 34-68 ms actually measured.
