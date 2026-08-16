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
- **Two power domains** — a switched one carrying everything the high-side switch
  resets, and an always-on MCU domain fed from USB or pyControl.
- **GPIO isolation** — a FET bus switch between the MCU and the switched domain,
  isolated at power-on, so the MCU cannot back-power chips it just switched off.
- **36 V** motor supply through a protected, electronically switched 2-position
  terminal block.
- **One TMC5130A** stepper driver section in SPI mode, on a 4-pin motor terminal.
- **One single-ended encoder** on a 5-pin terminal, read by the TMC5130A only.
- **One limit switch** on a 2-pin terminal through a hardware debouncer, to
  `REFL` and to an MCU GPIO.
- **pyControl RJ-45** behavior port carrying the serial link, 115200 8N1 — and
  nothing else.

- **InstrumentPort-40** on a 40-pin FFC, so a logic analyzer sees the pyControl
  serial link at the connector and the TMC5130A SPI bus in one capture.

Deferred to rev 1: the 0-5 V analog angle output and its BNC, the
`PULL_EVENT`/`FAULT`/`RSYNC` TTL lines and their BNCs, and the RP2040 PIO encoder
cross-check. Every one of them lands on pins Rev 0 has already allocated and left
unconnected.

Assembled from `kicad-libs` design blocks — **fifteen instances**, including two
`5v_to_3v3_tps73733`, one per power domain, and five instrumentation buffers of
which three are fitted. Four of them have never been placed on a board before: the
36 V input, the limit-switch debouncer, the pyControl RJ-45 boundary, and the
InstrumentPort FFC boundary.

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
| Instrument buffer enable | `GP24` `~INSTR_BUF_OE` | yes |
| Spare | `GP27` (ADC1, `EXT_FAULT_IN` candidate) | — |

**One pin was traded, not found.** The isolation bus switch needs an enable, and
the map was already at 29 of 30. It is paid for by permanently dropping
`TMC_REF_STIM`, the synthetic homing stimulus that sat on `GP9` — the limit
switch now arrives through a real debouncer, so homing is exercised by closing
the actual switch. One-for-one, and `GP27` survives as the spare.

**A GPIO goes through the isolation switch if and only if its far end sits on the
switched domain.** That isolates 8 channels in Rev 0 and 16 at full scope — the
TMC bus, and the limit-switch copy. Everything else bypasses, including the
pyControl UART, so **the board still answers `ID`/`STATUS` with the motor rail
switched off**. That is the whole point of the arrangement. Per-signal rationale
in the interface map.

**InstrumentPort-40 is in Rev 0** as of 2026-08-16, for firmware development
rather than for experiments. Ten of its eighteen digital Strands are live: the
four TMC5130A SPI signals, both directions of the pyControl serial link, the two
firmware triggers, and the two encoder quadrature channels. The other eight are
allocated and unrouted, **four of them reserved for the rev 2 electronic brake
and torque sensor**.

`ENC_A` and `ENC_B` are borrowing two of those reserved slots. Rev 0 has no PIO
cross-check, so the TMC5130A's own count is the only one on the board and nothing
in firmware can contradict it — capturing the raw edges beside the SPI reads of
that register is what confirms the driver is decoding the encoder correctly. They
sit in the slots belonging to the rev 2 buffer package, so they survive rev 1 and
hand over only when the torque front end arrives. Full allocation in the
interface map.

## The High-Side Switch Is A Reset Button

The `TPS1HTC100-Q1` is not only inrush and fault protection. It lets the
researcher power-cycle every chip on the board to a known state **without
unplugging anything**, while the MCU stays alive and reachable. Everything
resettable hangs off the switched rail:

```text
36 V ─[switch]─ +36V_SW ─┬─> TMC5130A VS
                         └─> hv_to_5v_tpsm365r6 ─> +5V_SW ─> 5v_to_3v3 #2 ─> +3V3_SW

USB VBUS ─────────|>|─┬─> +5V_MCU ─> 5v_to_3v3 #1 ─> +3V3_MCU ─> RP2040, bus switch
pyControl pin 6 ──|>|─┘
```

**The board does not boot on 36 V alone** — it needs USB or pyControl. That is
accepted, deliberate, and worth silkscreening next to the terminal block.
pyControl pin 6 **is** 5 V, confirmed from the reference design's netlist in
`~/Repositories/github/syringe-pump`; what is still unmeasured is how much
current it can supply, which is what decides whether pyControl-only operation
works.

## 36 V, And What It Costs

36 V buys motor performance and pre-resolves the brake-rail tension the twin
board records as unresolved. It costs transient headroom: the TMC5130A operates
to 46 V with a 49 V absolute maximum, and the datasheet warns explicitly about
supply ringing from stray inductance.

**A TVS on `HV_IN` protects the switch, not the driver**, and the two jobs are
separate. At hot-plug the switch is off, so the exposed part is the
`TPS1HTC100-Q1` (70 V), comfortably clamped by a 40 V-standoff part. It matters
more than it used to: the buck now taps **post**-switch, so `HV_IN` no longer
carries the buck's input capacitance and there is little left to damp cable
ringing. Fit `SMBJ40A`; prototype with the stocked `SMF48A` if you don't want to
wait.

The driver is a different problem. A standard TVS clamps near 1.6× its standoff,
so nothing that stands off 36 V clamps under the TMC5130A's 49 V. Its protection
is by construction: bulk capacitance downstream of the soft-start switch — capped
at **tens of µF, since the switch dissipates ½CV² charging it** — plus a tight
`VS`/`GND` loop and a snubber footprint, verified at Gate B.

The MCU rail is diode-ORed from USB `VBUS` and pyControl pin 6 — **and never
from the onboard buck**. The two 5 V rails are structurally separate, which is
what keeps `+5V_SW` in spec for the TMC5130A's 4.6 V `VCC` minimum. Merging them
is the mistake that would quietly truncate the rev 1 "0-5 V" analog output.

There is still one way to make an unbootable board out of correct blocks: putting
the **MCU** on the switched chain, so it cannot enable its own supply. Feeding
the *buck* from the switched rail is correct and intentional.
[Power](docs/power.md) covers all of this.

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
`rp2040_gpio_isolation_sn74cb3q3245`, and one `5v_to_3v3_tps73733`; plus `usb2`
and `hv_input_36V_terminal_2pos_5p08_protected` at the root. **Five of the eight
Rev 0 block instances.** Remaining: `hv_to_5v_tpsm365r6`, `tmc5130`, and the
second `5v_to_3v3_tps73733`, then the board-local sections — encoder input,
`limit_switch_debounced_input`, the pyControl RJ-45 boundary, and the two ORing
diodes.

The placed `5v_to_3v3_tps73733` currently sits inside the `mcu` sheet, which is
the right home for the **always-on** instance. Confirm it is fed from the ORed
`+5V_MCU` node and not from the 36 V chain.

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
