# mouse-joystick-pcb

Single-axis mouse joystick controller PCB for the Janelia Dudman lab joystick
rig, integrated as a native pyControl peripheral.

## Purpose

This board is the interface between **one** joystick of the rig and a pyControl
experiment controller. pyControl owns the behavioral state machine. This board
owns local motion timing, homing, bounded commands, and safe failure for its
axis.

## Board Contents

**Rev 0 was rescoped on 2026-08-13** to shorten the path to testable hardware. It
carries the interfaces and nothing else; see [Rev 0 Plan](docs/rev0-plan.md).

- **RP2040** controller MCU with USB-C for firmware load and a CDC debug console.
- **GPIO isolation** — a 32-channel FET bus switch between the MCU and the board,
  isolated at power-on until firmware enables it.
- **36 V** motor supply through a protected, electronically switched 2-position
  terminal block.
- **One TMC5130A** stepper driver section in SPI mode, on a 4-pin motor terminal.
- **One single-ended encoder** on a 5-pin terminal, read by the TMC5130A only.
- **One limit switch** on a 2-pin terminal through a hardware debouncer, to
  `REFL` and to an MCU GPIO.
- **pyControl RJ-45** behavior port carrying the serial link, 115200 8N1 — and
  nothing else.

Deferred to rev 1: the 0-5 V analog angle output and its BNC, InstrumentPort-40
and its five buffers, the `PULL_EVENT`/`FAULT`/`RSYNC` TTL lines and their BNCs,
and the RP2040 PIO encoder cross-check. Every one of them lands on pins Rev 0 has
already allocated and left unconnected.

Assembled from `kicad-libs` design blocks — **seven instances**. Exactly one of
them, the 36 V input, has never been placed on a board before.

## Two Repositories, One Rig

The rig has **two** joysticks. There are two board designs for it:

| Repository | Scope |
| --- | --- |
| `../mouse-joysticks-pcb` | One PCB, both joysticks, one pyControl UART |
| **this repository** | One PCB, one joystick; two boards per rig |

Both are live and the form-factor question is deliberately open. This board
exists because it can be finished sooner: no GPIO descope, no axis-symmetry
constraint, no two-motor zoning problem, no open question about where four TTL
event lines land.

What that costs — two clocks, two instruments, symmetry that is no longer
enforced by construction, and two pyControl ports — is written down in
[Relationship To The Twin-Axis Board](docs/relationship-to-twin-axis-board.md),
along with what carries forward if the choice is reversed.

Most of the expensive unknowns are shared and resolved either way: the pyControl
integration, the device class, the protocol, the analog output, and the
instrument tooling.

## Pinouts

All in [Interface Map](docs/interface-map.md).

**Rev 0 connects 17 of 30 GPIOs. Full scope is 29 of 30 with 1 spare.** The
allocation is written so that **no pin moves between Rev 0 and full scope** — Rev
0 leaves the other twelve reserved and routed nowhere, and rev 1 makes them live
without disturbing anything Rev 0 established.

| Group | Pins | Rev 0 |
| --- | --- | --- |
| pyControl `UART0` | `GP0` TX, `GP1` RX | yes |
| TMC5130A `SPI0` | `GP6` SCK, `GP7` COPI, `GP4` CIPO, `GP2` CS, `GP3` `~DRV_EN`, `GP5` `DIAG0`, `GP8` `DIAG1` | yes |
| GPIO isolation enable | `GP9` `~BUS_SW_OE` | yes |
| Limit switch | `GP18` | yes |
| Power control | `GP19` `HV_EN`, `GP28` `HV_SNS` (ADC2), `GP26` `V5_SENSE` (ADC0), `GP29` `~HV_FAULT` | yes |
| Firmware markers | `GP25` `FW_TRIG0`, `GP21` `FW_TRIG1` — test points in Rev 0 | yes |
| DAC `SPI1` | `GP10` SCK, `GP11` COPI, `GP13` CS, `GP12` `~LDAC`, `GP17` `~CLR` | rev 1 |
| Encoder PIO | `GP14` A, `GP15` B, `GP16` N — contiguous | rev 1 |
| pyControl TTL | `GP20` `PULL_EVENT`, `GP22` `FAULT`, `GP23` `RSYNC` | rev 1 |
| Instrument buffer enable | `GP24` `~INSTR_BUF_OE` | rev 1 |
| Spare | `GP27` (ADC1, `EXT_FAULT_IN` candidate) | — |

**One pin was traded, not found.** The isolation bus switch needs an enable, and
the map was already at 29 of 30. It is paid for by permanently dropping
`TMC_REF_STIM`, the synthetic homing stimulus that sat on `GP9` — the limit
switch now arrives through a real debouncer, so homing is exercised by closing
the actual switch. One-for-one, and `GP27` survives as the spare.

**Four signals bypass the isolation switch:** `~BUS_SW_OE` (circular otherwise),
`HV_EN` (rail control must not depend on bus state), and both `FW_TRIG` markers
(must stay observable while the bus is isolated). `~INSTR_BUF_OE` joins them in
rev 1. This is the same bypass group `../tmc51x0-driver-dev-pcb` uses.

**InstrumentPort-40 is deferred to rev 1**, and its overlay is retained in full
in the interface map. Six of its eighteen slots carry signals Rev 0 does not
have, so it arrives with the DAC and the PIO encoder tap rather than before them.

## 36 V, And What It Costs

`hv_input_36V_terminal_2pos_5p08_protected` → `hv_to_5v_tpsm365r6` →
`5v_to_3v3_tps73733`.

36 V buys motor performance and pre-resolves the brake-rail tension the twin
board records as unresolved. It costs transient headroom: the TMC5130A operates
to 46 V with a 49 V absolute maximum, and the datasheet warns explicitly about
supply ringing from stray inductance.

**A TVS on `HV_IN` protects the switch and the buck, not the driver**, and the two
jobs are separate. At hot-plug the switch is off, so the exposed parts are the
`TPS1HTC100-Q1` (70 V) and the `TPSM365R6V5` (65 V) — both comfortably clamped by
a 40 V-standoff part, and both genuinely exposed because the regulator chain taps
pre-switch and so `HV_IN` carries the buck's input capacitance. Fit `SMBJ40A`;
prototype with the stocked `SMF48A` if you don't want to wait.

The driver is a different problem. A standard TVS clamps near 1.6× its standoff,
so nothing that stands off 36 V clamps under the TMC5130A's 49 V. Its protection
is by construction: bulk capacitance downstream of the soft-start switch — capped
at **tens of µF, since the switch dissipates ½CV² charging it** — plus a tight
`VS`/`GND` loop and a snubber footprint, verified at Gate B.

The logic rail is diode-ORed from the onboard buck, USB `VBUS`, and optionally
pyControl's 5 V — **at the 3.3 V regulator input, not at `+5V`**. ORing onto
`+5V` would drop it below the TMC5130A's 4.6 V `VCC` minimum and quietly truncate
the "0-5 V" analog output.

There is also one way to make an unbootable board out of correct blocks: feeding
the 5 V/3.3 V chain from the *switched* rail, so the MCU cannot enable its own
supply. [Power](docs/power.md) covers all of this.

## Repository Status

**Schematic capture under way, layout not started.**

Present:

- `.guix/` — channel pin and manifests.
- `Makefile` — agent, KiCad, fabrication, and validation targets.
- `kicad/` — KiCad 10 project carrying the metadata: 21 netclasses, 108 netclass
  patterns, the 4-layer stackup, plot/fabrication setup, the JLCPCB design rules,
  and project-local symbol, footprint, and design-block library tables.
- `docs/` — the design record.

Placed so far: a `mcu` sheet containing `rp2040`,
`rp2040_gpio_isolation_sn74cb3q3245`, and `5v_to_3v3_tps73733`; plus `usb2` and
`hv_input_36V_terminal_2pos_5p08_protected` at the root. **Five of the seven Rev
0 blocks.** Remaining: `hv_to_5v_tpsm365r6` and `tmc5130`, then the three
board-local sections — encoder input, `limit_switch_debounced_input`, and the
pyControl RJ-45 boundary.

Not yet done: layout. `kicad/mouse-joystick-pcb.kicad_pcb` is empty, and a DRC
run reports exactly one violation, `invalid_outline` — no edges on `Edge.Cuts`.
Expected until an outline is drawn.

## Blocking Items Before Ordering

1. The joystick motor part number. The current sense is already decided —
   0.15 Ω, `vsense = 1`, `IRUN = 28`.
2. The encoder part. Rev 0 assumes single-ended; the part sets the supply voltage
   and confirms that assumption.
3. Whether the regulator chain is fed pre- or post-high-side-switch.
4. Whether the TMC5130A tolerates `VCC_IO` present with `VCC` and `VS` absent,
   which USB-only operation requires.

Everything else can be resolved during layout.

The rescope removed one blocking item outright: the DAC8563 `VIH` question is now
a rev 1 concern. See [Encoder Analog Output](docs/encoder-analog-output.md),
which stays valid for rev 1.

**The 36 V input block needs six edits when placed** — it has never been used on a
board, and an audit of its netlist against the switch datasheet found: an `EN`
divider leaving only 150 mV of threshold margin from 3.3 V logic (`R27001` →
1 kΩ); `DIAG_EN` unconnected, which disables the current sense entirely (tie
high); `~FAULT` unconnected (route to `GP29`); `LATCH` unconnected, so the device
auto-retries every 2 ms (tie high for latch-off); `ILIM` set to 5.3 A typ
(`R27003` → 40 kΩ for ~1.2 A); and an `SNS` fault level that would overvoltage the
RP2040 ADC (`R27004` → 249 Ω). All are resistor values or one-wire changes, and
**every value is already stocked with an internal part** — no purchase, no lead
time. See [Power](docs/power.md).

The `usb2` block **now carries ESD protection** — the stocked `USBLC6-2P6` on
`D+`/`D-` and `VBUS`, plus a shell-to-GND tie that the block previously left
floating. Both were added upstream in `kicad-libs` on 2026-08-13, so a freshly
placed copy has them. Verify the placed instance rather than assuming: the block
is copied, not linked. Place it on the connector side of the 27 Ω series
resistors, which live in the `rp2040` block, and keep the clamp's ground via hard
against pin 2 — its clamping voltage is dominated by connection inductance.

## Environment

Managed KiCad targets use `.guix/channels.scm` through `guix time-machine`. Keep
that file pinned to exact commits following
`orb-weaver-context/context/guix-channel-maintenance.md`.

During active board and library development the Makefile prefers a sibling
editable `../kicad-libs` checkout through `ORB_WEAVER_KICAD_LIBS`.

Open the board with:

```sh
make kicad-edits
```

The pinned channel carries KiCad 10.0.4. While the Guix update for 10.0.5 waits
to land upstream, `.guix/manifest-kicad-local.scm` and
`.guix/local-modules/orb-weaver/kicad-local.scm` provide an opt-in 10.0.5
overlay: `make kicad-edits-local`, `kicad-shell-local`, `kicad-version-local`,
`fab-local`. Drop the overlay once the channel pin carries it.

## Key Documents

- [Rev 0 Plan](docs/rev0-plan.md)
- [Interface Map](docs/interface-map.md) — RP2040 and InstrumentPort-40 pinouts
- [Power](docs/power.md) — the 36 V chain
- [Relationship To The Twin-Axis Board](docs/relationship-to-twin-axis-board.md)
- [Design Block Map](docs/design-block-map.md)
- [Encoder Analog Output](docs/encoder-analog-output.md)
- [pyControl Port Pinout](docs/pycontrol-port-pinout.md)
- [pyControl Interface](docs/pycontrol-interface.md)
- [UART Protocol](docs/uart-protocol.md)
- [Instrument Strategy](docs/instrument-strategy.md)
- [Prior Art](docs/prior-art.md)
- [Validation Plan](docs/validation-plan.md)
- [Bring-Up Log](docs/bringup-log.md)

## External References

- `../mouse-joysticks-pcb` — the twin-axis board for the same rig
- `../tmc51x0-driver-dev-pcb` — validated RP2040 + TMC5130A predecessor
- `../kicad-libs` — symbols, footprints, parts, design blocks
- `../board-interfaces/docs/instrument-port-40.md`
- `orb-weaver-context/context/pcb-development-plan.md`
- `~/Repositories/github/syringe-pump` — pyControl module reference design
- `~/Repositories/kicad/mouse-joystick-pcb` — previous-generation board, same
  name, different design
