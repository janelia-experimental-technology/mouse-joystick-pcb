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
- **One single-ended encoder** on a 5-pin terminal, level-translated through a
  Schmitt buffer and read by the TMC5130A only. No index channel.
- **One limit switch** on a 2-pin terminal through a hardware debouncer, to
  `REFL`, and to no MCU GPIO.
- **pyControl RJ-45** behavior port carrying the serial link, 115200 8N1, plus
  the port's 5 V, which is one of the board's two power sources. No TTL event
  lines in Rev 0.

- **InstrumentPort-40** on a 40-pin FFC, so a logic analyzer sees the pyControl
  serial link at the connector and the TMC5130A SPI bus in one capture.

Deferred to rev 1: the **0-3.3 V** analog angle output and its BNC, the
`PULL_EVENT`/`FAULT`/`RSYNC` TTL lines and their BNCs. Every one of them lands on pins Rev 0 has already allocated and left
unconnected. The analog output's design block was built and validated in
`kicad-libs` on 2026-08-26, ahead of the board; it is not placed here yet.

Assembled from `kicad-libs` design blocks — **fifteen instances across fourteen
distinct block copies**, including two `5v_to_3v3_tps73733`, one per power
domain, and three instrumentation buffers. **Five of them have never been placed
on a board before:** the 36 V input, the encoder input conditioning, the
limit-switch debouncer, the pyControl RJ-45 boundary, and the InstrumentPort FFC
boundary.

Everything the board authors itself is three wrapper sheets — `mcu`,
`motor_encoder_limit`, `instrument_port` — which hold the block instances and
nine termination resistors. There is no board-local circuitry outside them.

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

**Rev 0 connects 18 of 30 GPIOs. Full scope is 24 of 30 with 6 spares.** The
allocation is written so that **no pin moves between Rev 0 and full scope** — Rev
0 leaves six reserved and routed nowhere, and rev 1 makes them live without
disturbing anything Rev 0 established. Four were freed on 2026-08-16 when the
encoder and limit switch stopped reaching the MCU, and one of those four was
taken back on 2026-08-17 for `HV_DIAG_EN`. **`GP12` and `GP17` were freed on
2026-08-26** — the analog output's DAC has no hardware `LDAC` or `CLR` pin, so
those two reservations cost nothing to return and rev 2 now fits with room.

| Group | Pins | Rev 0 |
| --- | --- | --- |
| pyControl `UART0` | `GP0` TX, `GP1` RX (10 kΩ pull-up to `+3.3V_MCU`) | yes |
| TMC5130A `SPI0` | `GP6` SCK, `GP7` COPI, `GP4` CIPO, `GP2` CS, `GP3` `~DRV_EN`, `GP5` `DIAG0`, `GP8` `DIAG1` | yes |
| GPIO isolation enable | `GP9` `~BUS_SW_EN` | yes |
| Power control | `GP19` `HV_EN`, `GP14` `HV_DIAG_EN`, `GP28` `HV_SNS` (ADC2), `GP26` `SW_RAIL_SENSE_DIV_2` (ADC0), `GP29` `~HV_FAULT` | yes |
| Firmware markers | `GP25` `FW_TRIG0`, `GP21` `FW_TRIG1` — InstrumentPort `TRIG0`/`TRIG1` in Rev 0 | yes |
| DAC `SPI1` | `GP10` SCK, `GP11` COPI, `GP13` CS | rev 1 |
| pyControl TTL | `GP20` `PULL_EVENT`, `GP22` `FAULT`, `GP23` `RSYNC` | rev 1 |
| Instrument buffer enable | `GP24` `~INSTR_BUF_OE` | yes |
| Spare | `GP12`, `GP15`, `GP16`, `GP17`, `GP18`, and `GP27` (ADC1, `EXT_FAULT_IN` candidate) | — |

**`GP14` was spare and is not any more.** It drives the high-side switch's
`DIAG_EN` through `R202` 1 kΩ. Tying `DIAG_EN` high instead — the earlier plan —
leaves the switch's OFF-state open-load detection permanently enabled, trickling
~240 µA into the ~208 µF on `+36V_SW`, so the rail creeps up and the buck hiccups
rather than the domain switching cleanly off. That would break the reset-button
property the whole two-domain architecture exists for. **Firmware must raise
`GP14` before reading `HV_SNS` or `~HV_FAULT`**; current limit and thermal
shutdown are unaffected either way.

**`GP26` reads a divider, not the rail.** The `mcu` sheet takes `+3.3V_SW` in and
`R401`/`R402` (1 kΩ/1 kΩ) halve it to `SW_RAIL_SENSE_DIV_2`. That divider is
load-bearing beyond the ADC: it is what holds `+3.3V_SW` at 0 V when the domain
is off, which is what makes the four pull-ups referenced to that rail read as
valid LOWs. Do not remove it.

**There is no SWD header and no `RUN` connection in Rev 0** — deferred to a
future board revision by explicit decision, 2026-08-17. RP2040 `RUN` has an
internal 50-80 kΩ pull-up and the datasheet permits leaving it open, so this
costs debug and reset *access*, not correct start-up. Development goes through
BOOTSEL and USB CDC.

**One pin was traded, not found.** The isolation bus switch needs an enable, and
the map was at 29 of 30 when that was decided. It is paid for by permanently dropping
`TMC_REF_STIM`, the synthetic homing stimulus that sat on `GP9` — the limit
switch now arrives through a real debouncer, so homing is exercised by closing
the actual switch. One-for-one, and `GP27` survives as the spare.

**A GPIO goes through the isolation switch if and only if its far end sits on the
switched domain.** That isolates 7 channels in Rev 0 and 10 at full scope — the
TMC bus in Rev 0, the DAC's three wires later. Everything else bypasses, including the
pyControl UART, so **the board still answers `ID`/`STATUS` with the motor rail
switched off**. That is the whole point of the arrangement. Per-signal rationale
in the interface map.

Two things about it as built. The bus switch runs from **`+3.3V_MCU`**, so
isolation is a firmware property, not a free hardware one: it defaults safe only
because `R601` pulls `~BUS_SW_EN` high at reset. And of the four packages in the
block, one carries six channels, one carries a single channel, and **two carry
nothing at all** — unused channels have their MCU-side pins grounded, so the
rev 1 DAC group is not pre-wired and rev 1 edits the block regardless.

**InstrumentPort-40 is in Rev 0** as of 2026-08-16, for firmware development
rather than for experiments. Eleven of its eighteen digital Strands are live: the
four TMC5130A SPI signals, both directions of the pyControl serial link, the two
firmware triggers, the two encoder quadrature channels, and the limit switch.
The other seven are
allocated and unrouted, **four of them reserved for the rev 2 electronic brake
and torque sensor**.

`ENC_A`, `ENC_B`, and `LIMIT_SW` are borrowing three of those reserved slots.
**None of them reaches an RP2040 pin in any revision** — the TMC5130A owns the
encoder and the limit switch, so the driver's own report over SPI is firmware's
entire picture of position and homing, and nothing can contradict it. Capturing
the raw signals beside the SPI traffic is what makes that picture checkable. They
sit in the rev 2 buffer package's slots, so they survive rev 1 and hand over only
when the brake and torque front end arrive. Full allocation in the interface map.

The three buffer packages carry these eleven signals plus one spare channel whose
input is grounded — **12 of 12 channels, so rev 1's three DAC taps need a fourth
package.** The buffers are always powered but their inputs sit on the
switched side of the bus switch, so **nine 10 kΩ resistors define every one of
those nets** when the switched domain is off: four to GND, four to `+3.3V_SW`,
and one — the pyControl UART RX pull-up, which must idle high — to `+3.3V_MCU`.
Rev 1 adds two more for the DAC bus, taking it to eleven; the third and only
required one ships inside the analog output block.
The switched-domain nets deliberately do *not* reference `+3.3V_MCU`; that would
back-power `+3.3V_SW` to roughly 1.3 V through the driver's protection diodes and
defeat the power-cycle. See the design block map.

## The High-Side Switch Is A Reset Button

The `TPS1HTC100-Q1` is not only inrush and fault protection. It lets the
researcher power-cycle every chip on the board to a known state **without
unplugging anything**, while the MCU stays alive and reachable. Everything
resettable hangs off the switched rail:

```text
HV_RAW ─|>|─ HV_IN ─[switch]─ +36V_SW ─┬─> TMC5130A VS
                                       └─> hv_to_5v_tpsm365r6 ─> +5V_SW ─> 5v_to_3v3 #2 ─> +3.3V_SW

USB VBUS ─────────|>|─┬─> +5V_MCU ─> 5v_to_3v3 #1 ─> +3.3V_MCU ─> RP2040, bus switch, buffers
pyControl pin 6 ──|>|─┘
```

**The board does not boot on 36 V alone** — it needs USB or pyControl. That is
accepted, deliberate, and worth silkscreening next to the terminal block.
pyControl pin 6 **is** 5 V, confirmed from the reference design's netlist in
`~/Repositories/github/syringe-pump`; what is still unmeasured is how much
current it can supply, which is what decides whether pyControl-only operation
works. That branch runs through `R1903`, **a polyfuse position currently holding
a 0.36 Ω jumper** — the port's 5 V is a shared 1.0 A that also feeds the
pyControl controller's own logic regulator, so a fault on this board can reset
the controller. A 1206 PPTC with a 250-500 mA hold is still to be sourced.

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
what keeps `+5V_SW` in spec for the TMC5130A's 4.6 V `VCC` minimum, and for the
rev 1 analog output's `OPA197` 4.5 V minimum. Merging them puts both out of
spec. (**Corrected 2026-08-26**: this used to say merging would "quietly
truncate the rev 1 0-5 V analog output". That failure mode belonged to the
originally planned `DAC8563`, whose full scale was `VDD`-referenced. The built
output takes its full scale from an internal reference, so a low rail does not
scale it down — it just runs the amplifier outside its datasheet.)

There is still one way to make an unbootable board out of correct blocks: putting
the **MCU** on the switched chain, so it cannot enable its own supply. Feeding
the *buck* from the switched rail is correct and intentional.
[Power](docs/power.md) covers all of this.

## Repository Status

**Schematic capture complete and ERC-clean. Layout not started.**

As of 2026-08-17: **0 ERC violations at every severity**, 142 components, no
duplicate reference designators, every part carrying a footprint.

Present:

- `.guix/` — channel pin and manifests.
- `Makefile` — agent, KiCad, fabrication, and validation targets.
- `kicad/` — KiCad 10 project carrying the schematic and the metadata: 21
  netclasses, **124** netclass patterns, the 4-layer stackup, plot/fabrication
  setup, the JLCPCB design rules, and project-local symbol, footprint, and
  design-block library tables.
- `docs/` — the design record.

**All fifteen Rev 0 block instances are placed**, under three board-authored
wrapper sheets and the root:

```text
mouse-joystick-pcb (root)
├── mcu                     rp2040, rp2040_gpio_isolation_sn74cb3q3245,
│                           5v_to_3v3_tps73733 (always-on, U701)
├── 5v_to_3v3_tps73733      (switched, U1001)
├── hv_input_36V_terminal_2pos_5p08_protected
├── hv_to_5v_tpsm365r6
├── usb2
├── pycontrol_behavior_port_rj45_boundary
├── motor_encoder_limit     tmc5130, quadrature_encoder_input_5v_sn74lvc2g17,
│                           limit_switch_debounced_input
└── instrument_port         instrument_port_40_dut_ffc_boundary,
                            instrumentation_signal_buffer_sn74lvc125a ×3
```

**The netclass patterns were rewritten on 2026-08-17**, from 108 to 124. Before
that, 146 of 156 nets fell through to `Default` at 0.2 mm — including the motor
phases and the 36 V bus. The HV entry nets are now 1.5 mm, `+36V_SW` 1.2 mm, the
motor phases and the TMC's `BRA`/`BRB` 0.8 mm, the 5 V rails 0.5 mm, and the
3.3 V rails 0.3 mm, with no net matching more than one class.

**One divergence from `kicad-libs` is deliberate and must not be "fixed".** The
`tmc5130` sense resistors `R1203`/`R1204` are 0.15 Ω here where the library moved
to 0.12 Ω. The board is correct; re-placing that block silently reverts them and
runs the motor about 25% over its intended current.

Not yet done: layout. `kicad/mouse-joystick-pcb.kicad_pcb` is empty, and a DRC
run reports exactly one violation, `invalid_outline` — no edges on `Edge.Cuts`.
Expected until an outline is drawn. **There are also no test points anywhere on
the board**, which is a layout task the design record has been assuming since
Rev 0 was scoped.

## Blocking Items Before Ordering

1. The joystick motor part number. The current sense is already decided —
   0.15 Ω, `vsense = 1`, `IRUN = 28`. `ILIM` sits at 40 kΩ (≈1.2 A) as a recorded
   assumption; it is one resistor and can change on the bench.
2. The encoder part. Rev 0 assumes single-ended; the part sets the supply
   voltage, confirms that assumption, and now also validates the placed
   conditioning block — its 100 kΩ pull-downs assume a **push-pull** output, its
   filter corner is 72 kHz, and `J1103`'s pin order depends on the answer. **This
   is the one open item that can invalidate the board.**
3. `R1903`, the pyControl 5 V polyfuse position. Source a 1206 PPTC with a
   250-500 mA hold, or accept the 0.36 Ω jumper and record it.
4. `U603` and `U604`, the two entirely unused bus-switch packages. Decide before
   placement.
5. Board outline and mounting.

Everything else can be resolved during layout.

**Resolved since this list was written.** The rescope deferred the DAC `VIH`
question, and 2026-08-26 answered it: the analog output block is built around a
`DAC80501`, whose `VIH` is 1.62 V minimum flat across `VDD` = 2.7-5.5 V, so
3.3 V logic drives it directly and no level translator is needed. See
[Encoder Analog Output](docs/encoder-analog-output.md), rewritten the same day. The two-domain power architecture settled the other two: the regulator
chain is fed **post**-switch, and whether the TMC5130A tolerates `VCC_IO` with
`VCC`/`VS` absent no longer needs an answer, because all three now fall together.

**The 36 V input block needed six edits when placed, and they are made.** It had
never been used on a board, and an audit of its netlist against the switch
datasheet found: an `EN` divider leaving only 150 mV of threshold margin from
3.3 V logic (`R201` → 1 kΩ); `DIAG_EN` unconnected, which disables the current
sense entirely; `~FAULT` unconnected (`R205` → `GP29`); `LATCH` unconnected, so
the device auto-retries every 2 ms (`R203` tied high for latch-off); `ILIM` set
to 5.3 A typ (`R206` → 40 kΩ for ~1.2 A); and an `SNS` fault level that would
overvoltage the RP2040 ADC (`R207` → 249 Ω). All were resistor values or one-wire
changes, and **every value was already stocked with an internal part** — no
purchase, no lead time. See [Power](docs/power.md).

Two of those recommendations were revised in the doing. **`DIAG_EN` goes to
`GP14`, not to a fixed pull-up** — see the pinout section above for why holding
it high stops the switched domain from ever reaching 0 V. And **`SNS` is 249 Ω,
not the 1 kΩ an earlier note gave**, which would have driven `GP28` past its
absolute maximum on a fault.

**No TVS is populated on `HV_IN`.** Still owed, and not a fab blocker: `SMBJ40A`
is preferred and the stocked `SMF48A` builds a working first board.

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
