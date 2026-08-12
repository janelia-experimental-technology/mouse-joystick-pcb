# mouse-joystick-pcb

Single-axis mouse joystick controller PCB for the Janelia Dudman lab joystick
rig, integrated as a native pyControl peripheral.

## Purpose

This board is the interface between **one** joystick of the rig and a pyControl
experiment controller. pyControl owns the behavioral state machine. This board
owns local motion timing, homing, bounded commands, and safe failure for its
axis.

## Board Contents

- **RP2040** controller MCU with USB-C for firmware load and a CDC debug console.
- **36 V** motor supply through a protected, electronically switched 2-position
  terminal block.
- **One TMC5130A** stepper driver section in SPI mode, with encoder input and
  limit-switch input.
- **One 0-5 V analog output on BNC**, proportional to encoder angle.
- **pyControl RJ-45** behavior port carrying the serial link, 115200 8N1.
- `PULL_EVENT`, `FAULT`, and `RSYNC` on BNC.
- **InstrumentPort-40** for a logic analyzer or ADALM2000.

Assembled from `kicad-libs` design blocks — twelve instances, thirteen if the
encoder is differential. Exactly one of them, the 36 V input, has never been
placed on a board before.

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

Both are in [Interface Map](docs/interface-map.md).

**RP2040: 27 of 30 GPIOs used, 3 spare, all ADC-capable.** Nothing is descoped
for pin budget — encoder index, `DIAG1`, the synthetic homing stimulus, and
software DAC `~LDAC`/`~CLR` are all present, unlike on the twin-axis board.

| Group | Pins |
| --- | --- |
| pyControl `UART0` | `GP0` TX, `GP1` RX |
| TMC5130A `SPI0` | `GP6` SCK, `GP7` COPI, `GP4` CIPO, `GP2` CS, `GP3` `~DRV_EN`, `GP5` `DIAG0`, `GP8` `DIAG1`, `GP9` `REF_STIM` |
| DAC `SPI1` | `GP10` SCK, `GP11` COPI, `GP13` CS, `GP12` `~LDAC`, `GP17` `~CLR` |
| Encoder PIO | `GP14` A, `GP15` B, `GP16` N — contiguous |
| Limit switch | `GP18` |
| Power control | `GP19` `HV_EN`, `GP28` `HV_SNS` (ADC2) |
| pyControl TTL | `GP20` `PULL_EVENT`, `GP22` `FAULT`, `GP23` `RSYNC` |
| Instrument | `GP24` `~INSTR_BUF_OE`, `GP25` `FW_TRIG0`, `GP21` `FW_TRIG1` |
| Spare | `GP26` (ADC0), `GP27` (ADC1, `EXT_FAULT_IN` candidate), `GP29` (ADC3) |

**InstrumentPort-40: all 18 digital slots filled**, which one axis does exactly.
`DIG0`-`DIG6` carry the pyControl UART, the TMC SPI bus with chip select, and the
DAC chip select; `DIG7`-`DIG9` the encoder A/B/N; `DIG10`-`DIG11` the DAC SPI
bus; `DIG12`-`DIG15` pull event, fault, `RSYNC`, and the limit switch; `TRIG0`/
`TRIG1` the firmware markers. `AIN0` observes the analog angle output at the BNC;
`AOUT0`/`AOUT1` are no-connect so no instrument can drive the board.

The DAC bus earns two slots here because the 0-5 V output is the researcher's
primary deliverable and "does the voltage match the encoder?" should be
answerable from a single capture.

## 36 V, And What It Costs

`hv_input_36V_terminal_2pos_5p08_protected` → `hv_to_5v_tpsm365r6` →
`5v_to_3v3_tps73733`.

36 V buys motor performance and pre-resolves the brake-rail tension the twin
board records as unresolved. It costs transient headroom: the TMC5130A operates
to 46 V and 36 V leaves 10 V, and the datasheet warns explicitly about supply
ringing from stray inductance. **The 36 V input block populates no TVS** — one has
to be added and is not in the catalog.

There is also one way to make an unbootable board out of correct blocks: feeding
the 5 V/3.3 V chain from the *switched* rail, so the MCU cannot enable its own
supply. [Power](docs/power.md) covers all of this.

## Repository Status

**Scaffolded, schematic and layout empty.** Ready to design into.

Present:

- `.guix/` — channel pin and manifests.
- `Makefile` — agent, KiCad, fabrication, and validation targets.
- `kicad/` — empty KiCad 10 project carrying the metadata: 21 netclasses, 108
  netclass patterns, the 4-layer stackup, plot/fabrication setup, the JLCPCB
  design rules, and project-local symbol, footprint, and design-block library
  tables.
- `docs/` — the design record.

Not yet done: schematic capture and layout. `kicad/mouse-joystick-pcb.kicad_sch`
and `.kicad_pcb` are intentionally empty.

A DRC run on the empty board reports exactly one violation, `invalid_outline` —
no edges on `Edge.Cuts`. Expected until an outline is drawn.

## Blocking Items Before Ordering

1. The joystick motor part number. The current sense is already decided —
   0.15 Ω, `vsense = 1`, `IRUN = 28`.
2. The encoder part, and therefore single-ended versus differential receive.
3. DAC8563 `VIH` at `VDD = 5 V`, and whether a level translator is needed.
4. A 36 V-rated TVS part. Purchase item, `SMBJ40A`/`SMBJ43A` class.
5. Whether the regulator chain is fed pre- or post-high-side-switch.

Everything else can be resolved during layout.

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
