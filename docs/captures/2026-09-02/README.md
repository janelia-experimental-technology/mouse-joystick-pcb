# Captures, 2026-09-02

Board `mouse-joystick-pcb` rev 0 (PCB tag `v0.2`; `v0.1`→`v0.2` is layout-only,
so the pad-to-net map is identical), serial `E4654C159F2C2534`.
Firmware `mouse-joystick-firm`, uncommitted working tree on top of `a7995da`,
`examples/TMC5130Communication` on env `mouse_joystick`.

36 V applied to `J201`, **not** current-limited (supply capable of 4 A). USB
powers the MCU domain. LA5032 attached to `J1501` but not used for these —
InstrumentPort-40 carries no rail information by design.

Everything came over USB CDC at 115200. Voltages are already scaled: `+3.3V_SW`
is undivided (the raw `R401`/`R402` node × 2) and `HV_SNS` is the voltage across
`R207` 249 Ω.

| File | Command | What it shows |
| --- | --- | --- |
| `hv-diagnostics-en-low.txt` | `d` | `HV_EN` low, `HV_DIAG_EN` pulsed high. **No fault.** Establishes that the fault seen 1 ms after enable is caused by turning on, not by the diagnostics |
| `hv-powerup-profile-1.txt` | `p` | First single-shot attempt after boot, bulk cold. Rail up at 4 ms, leaves 3.30 V at 38 ms |
| `hv-powerup-profile-burst-{1..4}.txt` | `p` ×4 | Four back-to-back attempts. 47-48 ms hold, ±1 ms. Longer than the cold attempt because the bulk keeps its charge between attempts |
| `staircase-softstart.txt` | `c` | 30 bursts of 1200 µs on / 800 µs off, then `HV_EN` held. **Rail up and held for the full 1000 ms, `~{HV_FAULT}` high.** The workaround |
| `bus-close.txt` | `b` | GPIO isolation bus closed and SPI0 started, rail live |
| `tmc5130-registers.txt` | `r` | TMC5130A `VERSION` = 0x11, `GSTAT.drv_err` = 0, `uv_cp` = 0, `DRV_STATUS` clean. Driver disabled throughout |
| `hv-powerup-profile-after-staircase.txt` | `p` | Single-shot again after a successful staircase, to confirm the failure had not simply gone away. It had not — fault at t = 1 ms, 65 ms hold |
| `power-down.txt` | `x` | Bus open, `HV_EN` low, `HV_DIAG_EN` low |

## `latch-released/`

Everything above was taken with `R203` **fitted** — `LATCH` strapped to
`+3.3V_MCU`, so the switch latches off. `latch-released/` is the same board
minutes later with `R203` **removed**, which selects auto-retry and makes a
plain `HV_EN` assertion work. See the README there.

Read these against
`../../bringup-log.md` →
[The Rail Comes Up And Then Collapses — RESOLVED](../../bringup-log.md#the-rail-comes-up-and-then-collapses--resolved-2026-09-02).

**The one measurement still missing is a scope on `+36V_SW`** at `C1213` pad 1.
The ~10-13 V turn-on peak is inferred from energy accounting across six
attempts, not measured, and it is a ~2 ms event that a DMM will not catch.
