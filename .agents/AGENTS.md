# Mouse Joystick PCB Agent Guidance

This file is the canonical project guidance for agent sessions in this
repository.

## Session Start

Read this file first.

If `AGENT_MEMORY_REPO` is set and points at a directory, read
`$AGENT_MEMORY_REPO/AGENTS.md` before planning or editing.

If sibling checkouts exist, read:

- `../mouse-joysticks-pcb/docs/` — the twin-axis board for the same rig, and the
  source of most of this repository's documentation
- `../orb-weaver-context/context/agent-index.md`
- `../orb-weaver-context/context/kicad-agent-context.md`
- `../orb-weaver-context/context/pcb-development-plan.md`
- `../board-interfaces/docs/instrument-port-40.md`
- `../kicad-libs/docs/design-blocks.md`

If `.agents/handoff.local.md` exists, read it before planning or editing.

If the task is multi-step, risky, or likely to span more than one session, read
`.agents/PLANS.md` and keep it updated as work progresses.

## Repository Purpose

This repository owns the KiCad implementation and board-specific notes for
`mouse-joystick-pcb`: a **single-axis** mouse joystick controller integrated as a
native pyControl peripheral. Two of these boards serve the rig's two joysticks.

**There is a second, live design for the same rig.** `../mouse-joysticks-pcb` is
the twin-axis board. The form-factor question is deliberately open. See
`docs/relationship-to-twin-axis-board.md`.

The predecessor motor-control validation board is `../tmc51x0-driver-dev-pcb`.
The previous-generation joystick board is `~/Repositories/kicad/mouse-joystick-pcb`
— same name, different design, prior art to mine rather than a dependency.

## Board Rules

- **One PCB, one joystick axis, one pyControl UART.** There is no axis argument
  in the protocol and no axis suffix in net names. If you find yourself adding
  one, you are working on the wrong board.
- **Do not port twin-axis complexity here.** Axis symmetry rules, cross-axis
  fault policy, `XFAULT`, and the `B`-for-both protocol argument belong in
  `../mouse-joysticks-pcb`. Their absence is the point.
- **Do not descope for pin budget.** This board uses 27 of 30 GPIOs with
  everything present. If a change needs more pins than are free, say so rather
  than quietly cutting the encoder index or `DIAG1` the way the twin board had
  to.
- **Current sense is 0.15 Ω with `vsense = 1` and `IRUN = 28`** for the 0.67 A/
  phase motor, on both shunt positions. **The `tmc5130` block ships 0.12 Ω as its
  default — change it.** `vsense` is CHOPCONF bit 17 and its reset default is 0;
  leaving it at 0 with 0.15 Ω installed drives roughly 1.8× the motor's rated
  current. Firmware must set and read back `vsense = 1` before raising
  `DRV_ENN`. The shunt value and the `vsense` setting are one decision — never
  change either independently.
- **The supply is 36 V, and that has consequences.** The TMC5130A operates to
  46 V, so 36 V leaves 10 V of transient headroom, and the 36 V input block
  populates no TVS. The TMC's internal 5 V regulator must be offloaded by
  supplying `VCC` externally. See `docs/power.md` before touching the power
  section.
- **The 36 V input block switches the rail and boots with it off.** Feed the
  5 V/3.3 V chain from the protected but **unswitched** node. Feeding it
  post-switch produces a board that cannot enable its own supply.
- pyControl owns experiment sequencing. This board owns local motion timing and
  safety. Never move experiment-level decisions into this firmware, and never
  expose unbounded trajectories or raw motor power as the normal API.
- `RJ-45` names a connector family, not an interface. Do not treat the pyControl
  behavior port as Ethernet and do not place Ethernet magnetics. The pinout and
  serial parameters in `docs/pycontrol-port-pinout.md` are **cited, not
  bench-verified**.
- The assigned pyControl port must be UART-capable: ports 1, 3, or 4 on Breakout
  board 1.2, or 8, 10, 11, or 12 on the D-series Breakout Board 1.6.
- Both DIO lines on the assigned port are consumed by the UART. The three TTL
  lines land on BNCs.
- Do not carry motor power through the pyControl behavior port. The board runs a
  36 V rail the port does not supply.
- The InstrumentPort-40 is intended for use **during scientific experiments**,
  not only on the bench. Observation must be passive, unidirectional, and unable
  to affect rig behavior. No divided motor rail reaches any `AIN*`.
- Do not redefine InstrumentPort-40 here; document only this board's overlay. If
  the profile is genuinely too narrow, raise it in `board-interfaces`.
- Do not define the reusable pyControl connector profile here. That belongs in
  `board-interfaces` once it has sufficient evidence.
- **Two interchangeable boards in one rig is a new failure mode.** Calibration
  belongs to a board serial, not to a joystick position. `ID` reports the serial.
  Silkscreen a unit identifier.
- Distinguish cited claims from bench-verified claims. Unknowns stay explicit
  unknowns with an owner.
- Use `kicad-libs` for shared symbols, footprints, internal parts, vendor
  mappings, and design blocks. Promote a circuit into `kicad-libs` only after
  this board verifies it.
- Record real board results in `docs/bringup-log.md`, per board serial.

## Keeping Two Repositories In Sync

Shared facts live in both this repository and `../mouse-joysticks-pcb`:

- the pyControl port pinout and UART parameters
- the motor part, its rating, and the current-sense decision
- the encoder part and the limit switch part
- the DAC part and the logic-level answer
- the UART protocol's framing, verbs, events, and fault model

**When one of these changes, change it in both.** A silent divergence in a shared
fact is the failure mode of running two repositories.

## Safety Rules

The board must reach a safe state without pyControl's cooperation:

- On boot: motor rail off, stepper outputs disabled, wait for an explicit `ARM`.
- During operation: require a host heartbeat; enforce current, velocity,
  acceleration, and travel limits; latch faults; assert the `FAULT` line; drop
  `HV_EN`.
- On host loss, heartbeat timeout, reset, or fault: stop motion, report the
  cause.
- With two boards in a rig, one board's fault leaves the other running. Decide
  explicitly whether that is acceptable, and prefer a hard-wired `EXT_FAULT_IN`
  over relying on the host to notice. See `docs/pycontrol-interface.md`.

## Development Environment

Prefer Makefile targets:

- `make test` — documentation and scaffold presence check
- `make codex` / `make claude` — agent sessions with sibling checkouts added
- `make agent-reflection`
- `make kicad-shell` / `make kicad-edits`
- `make validate-db` — Orb Weaver KiCad database library wiring
- `make fab` — fabrication outputs
- `make check-kicad-libs`

### Local KiCad Overlay

The pinned channel carries KiCad 10.0.4. `.guix/manifest-kicad-local.scm` and
`.guix/local-modules/orb-weaver/kicad-local.scm` provide an opt-in 10.0.5
overlay: `make kicad-version-local`, `kicad-shell-local`, `kicad-edits-local`,
`fab-local`. Delete the overlay files and the `-local` targets once the channel
pin carries 10.0.5 or newer.

### KiCad Project State

`kicad/mouse-joystick-pcb.kicad_sch` and `.kicad_pcb` are **intentionally
empty**. The project carries metadata only: 21 netclasses, 108 netclass patterns,
the 4-layer stackup, plot/fabrication setup, and the JLCPCB design rules,
inherited from `tmc51x0-driver-dev-pcb` by way of `mouse-joysticks-pcb`.

Do not populate the schematic without an explicit request. The board is to be
laid out from scratch.

A DRC run on the empty board reports exactly one violation, `invalid_outline` —
no edges on `Edge.Cuts`. That is expected and not a defect to chase.

The netclass patterns are generic rail and signal names (`+24V`, `VM`, `PGND`,
`+3V3`, `USB_HS`, encoder and instrument differential pairs). **The rail here is
`+36V`, not `+24V`** — extend the patterns rather than assuming the inherited
ones cover it.

## Validation

For documentation-only changes, review against `docs/validation-plan.md` gates.

For schematic/layout work, use KiCad ERC/DRC once the design is mature enough for
those checks to be meaningful.

`ORB_WEAVER_KICAD_LIBS` must resolve for KiCad to find the database and footprint
libraries.

When editing `kicad-libs` design blocks, run `scrub-private-vendor-fields`
**then** `validate`. Validate inspects `.kicad_sch` only, so a passing validate
does not prove the `.kicad_pcb` side is clean.
