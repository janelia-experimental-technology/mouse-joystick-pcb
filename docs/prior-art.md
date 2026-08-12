# Prior Art And Existing Documentation

**Status:** Index
**Date:** 2026-08-12
**Purpose:** This project has substantial documentation scattered across many
repositories, accumulated since 2017. This file is the index so it does not get
rediscovered from scratch.

Paths are as found on the development machine. None of these are dependencies of
this repository; they are sources to read and mine.

## Read This First

`../mouse-joysticks-pcb` — the twin-axis board for the same rig, documented in
detail through 2026-08-11. **Most of this repository's documentation derives from
it.** Before concluding that something here is a new problem, check whether that
repository already solved it. Its `docs/` covers the pyControl port pinout, the
UART protocol, the analog output, the instrument strategy, the current-sense
derivation, and the deferred brake and torque-sensor subsystems.

`docs/relationship-to-twin-axis-board.md` in this repository records why both
exist and what has to be kept in sync between them.

## New-Rig Design Documentation

| What | Where |
| --- | --- |
| **pyControl system architecture.** The primary architecture source. Responsibility split, why not a second pyControl board, UART-plus-TTL interface, Rsync data alignment, ICD signal table, safety layer. Recommends the twin-axis form factor. | `orb-weaver-ai/chat/51-C-2026-06-11-pycontrol-mouse-joysticks-system-architecture-design.md` |
| **PCB development plan.** "Mouse Joystick And pyControl PCB Development Plan", 2026-07-14. Responsibility table, cross-repository ownership, six-step development sequence, Gates A-F. The governing plan. | `orb-weaver-context/context/pcb-development-plan.md` |
| **Interoperability strategy.** Section "Current External-Platform Reference: Mouse Joystick And pyControl". | `orb-weaver-context/context/experimental-system-interoperability.md` |
| **Brake controller design note.** B5Z requirements, LM3404HV topology, starting component values, stocked and to-buy parts. **Assumes a 36 V rail** — relevant to this board's supply choice. | `kicad-libs/docs/b5z-magnetic-particle-brake-controller.md` |
| **New-rig mechanical assembly.** STEP and glTF of the **two**-joystick assembly. A single-axis board's mounting is a decision, not a derivation from this. | `orb-weaver/mouse-joysticks-mech/` |
| **MBM system models.** `published-2025.mbm.yaml` for the paper-reported previous rig, `current-acquisition-2026.mbm.yaml` for the collaborator's device-and-signal map. Neither describes the upgraded rig completely. | `mechatronic-boundary-modeling/examples/joystick-rig/` |
| **Motor-control predecessor.** RP2040 plus TMC5130A/TMC5160A validation board, 16 composed blocks, board ERC at 0. The closest trustworthy source for this board's driver and instrumentation composition. | `orb-weaver/tmc51x0-driver-dev-pcb/` |
| **pyControl module reference design.** Working peripheral with a shipping device class; the source of the port pinout and UART parameters. | `~/Repositories/github/syringe-pump` |

## Previous-Generation Board

`~/Repositories/kicad/mouse-joystick-pcb`

Same name as this repository, different thing — a complete, fabricated, fully
routed board from 2017, documentation version 1.0.0, released 2026-01-14,
migrated to KiCad 10. Previously named `cluster-pcb`. Teensy 4.0 controller,
24 V 65 W supply. **It carried two motor sections on one PCB**, so its power and
grounding arrangement is closer to the twin-axis board than to this one.

Hierarchical sheets: `assembly`, `power`, `microcontroller`, `joystick-motor`,
`base-motor`, `brake`, `torque-sensor`, `audio`, `mosfet`.

Notable populated parts:

| Ref | Part | Function |
| --- | --- | --- |
| `U502`, `U702` | `TMC5130A-TA` | Two stepper drivers |
| `U501`, `U701` | `MAX6816EUS+T` | Limit switch debouncers |
| `U901` | `PGA305ARHHR` | Bridge sensor conditioner for the torque sensor |
| `U801` | `BCR421UE6327` + `R801` 30 Ω | Linear constant-current brake driver |
| `U503` | `LSF0102DCUR` | Bidirectional level translator |
| `U301` | `TPSM365R6V5RDNR` | 24 V to 5 V |
| `U601` | `TPA6204A1DRBR` | Audio amplifier |
| `R501`, `R502` | 0.36 Ω | Sense resistors, one motor section |
| `R701`, `R702` | 0.12 Ω | Sense resistors, other motor section |

Directly relevant to this board: the `MAX6816` debounce circuit, the
`LSF0102DCUR` level-translation precedent for the DAC, and the `TPSM365R6V5`
choice, which this board also uses.

Datasheets in `documentation/datasheets/`: `ads1220.pdf`,
`brake-5Z-metric-data-sheet-1.pdf`, `brake-driver.pdf`,
`driver-TMC5130A-datasheet-rev1.21.pdf`, `encoder-1930795.pdf`, `max22215.pdf`,
`pga305.pdf`, `stepper-SY42STH38-1684A.pdf`, `stepper-WO-208-13-01D.pdf`,
`torque-sensor-specs.png`, `torque-sensor-wiring.png`, `translator-lsf0102.pdf`.

Also present: full gerbers, JLCPCB BOM and placement files, `pcb.step`, rendered
images, and a `README.md` with the KiCad output-generation procedure.

## Local Datasheets

`kicad-libs/tmp/` holds working copies used for this board's calculations:

| File | Used for |
| --- | --- |
| `TMC5130A_datasheet_rev1.21.pdf` | Absolute maximum ratings, internal regulator dissipation, current-sense formula |
| `tpsm365r6.pdf` | 5 V module input range |
| `tps1htc100-q1.pdf` | 36 V input block's high-side switch |
| `sn74lvc125a.pdf` | Instrumentation buffer thresholds |
| `B5Z-metric-data-sheet-1.pdf` | Brake, for the deferred subsystem |
| `Parts Inventory on JLCPCB.csv` | Stock checks |
| `neuron-2025.pdf` | The paper on the previous rig |

Check here before fetching a datasheet from the web.

## Previous-Rig Component Identities

Useful as starting points; **confirm each against the new rig rather than
assuming continuity.**

| Role | Part |
| --- | --- |
| Joystick-axis stepper | Lin Engineering `WO-208-13-01D-RO`, 0.6 A |
| Base-axis stepper | SOYO `SY42STH38-1684A` |
| Brake | Placid Industries `B5Z-24-1R`, 0-49 mA at 24 V |
| Torque sensor | Transducer Techniques `RTS-5`, Wheatstone bridge |
| Encoder | Broadcom `HEDR-5421-EP111`, two-channel quadrature |
| Limit switch | MiSUMi `D2F-01FL` |

The new rig's motor is rated **0.67 A per phase**, so it is not the previous
rig's `WO-208-13-01D`. The part number is still unidentified.

## Older Generations

| What | Where |
| --- | --- |
| Earlier controller board, includes `torque_sensor.kicad_sch` | `~/Repositories/kicad/mouse_joystick_controller/` |
| Even earlier reach-rig board | `~/Repositories/kicad/mouse_reach_controller/` |
| Arduino/modular-device firmware for the previous rig | `~/Repositories/modular-devices/mouse_joystick_controller/` |
| Python host interface for the previous rig | `~/Repositories/python/mouse_joystick_interface_python/` |

The previous firmware implemented the experiment state machine on the MCU. That
responsibility moves to pyControl in the new rig, so the firmware is a source for
motor and sensor handling only, not for architecture.

## Science And Narrative

| What | Where |
| --- | --- |
| Park et al. 2025, the paper on the previous rig | `github/mouse-joystick-poster/paper/neuron-2025.pdf` |
| Extended version | `github/mouse-joystick-poster/paper/neuron-2025-extended.pdf` |
| Poster context: locked title and abstract, MBM and QP framing, planned modules | `github/mouse-joystick-poster/context/mouse-joystick-poster-context-latest.md` |

## Gaps

Recorded so they are not mistaken for things that exist:

- **No verified pyControl connector profile.** `board-interfaces/docs/` contains
  InstrumentPort-40, LA5032, and M2K profiles but nothing for pyControl. Gate A
  work, and the critical path.
- **No new-rig component list.** The motor, encoder, and limit switch for the new
  rig are not identified in any document found.
- **No ideal stocked TVS for a 36 V rail.** The stock is `SMBJ28A` (28 V
  standoff), `SMF48A` (48 V), `SMBJ58A` (58 V), and `USBLC6-2P6` (ESD only).
  `SMF48A` is workable on `HV_IN` and `SMBJ40A` is the part to order; neither is a
  fabrication blocker. See `docs/power.md`. Still a genuine gap for the Rev 1 brake
  supply the `kicad-libs` brake note describes.
- **No stocked dual-supply level translator identified** for the DAC, if one is
  needed. This is the board's only candidate purchase item.
- **`hv_input_36V_terminal_2pos_5p08_protected` has never been placed** on any
  board.
- **No maintained MBM model of the upgraded rig.**
- **No decision on the rig's board form factor**, which is the question this
  repository exists to keep open.
