# Captures, 2026-09-01

Board `mouse-joystick-pcb` rev 0 (PCB tag `v0.1`), serial `E4654C159F2C2534`.
Firmware from `mouse-joystick-firm`.

| File | What it is |
| --- | --- |
| `heartbeat.vcd` | LA5032 ch16/ch17, 100 kSa/s, untriggered. `FW_TRIG0` 1 Hz heartbeat, `FW_TRIG1` idle. First validation of `la5032-instrument-port-adapter` v1.0. |
| `signature.vcd` | LA5032 ch16/ch17, 1 MSa/s, `--triggers CH17=r`. Stage 1 boot signature, plus ~150 ms of pre-trigger data that caught the RP2040's reset and the ~143 ms boot latency. |
| `hv-powerup-profile-1.txt` | 1 ms samples of `SW_RAIL_SENSE_DIV_2` and `HV_SNS` through a `HV_EN` power-up attempt, 36 V connected. Rail up at 3 ms, dies at 56 ms. |
| `hv-powerup-profile-2.txt` | Repeat of the above. Dies at 57 ms. Shows `HV_SNS` starting at 0.015 V and jumping to the fault level at t=1 ms. |

Captured with `sigrok-cli` via `instrument-control`'s Guix manifest, driver
`kingst-la2016`. The profiles came over USB CDC from the stage 2 firmware's `p`
command.

Voltages in the profiles are already scaled: `+3.3V_SW` is undivided (the raw
`R401`/`R402` node times two) and `HV_SNS` is the voltage across `R207` 249 ohm.
