# Mouse joystick observability development plan

**Workstream:** `OBS-HW-JOYSTICK` (board slice of `OBS-HW`).
**Status:** Planned, 2026-09-29. All new work below is pending.

The [system architecture](../../orb-weaver-context/context/experimental-system-observability.md)
and [development roadmap](../../orb-weaver-context/context/experimental-system-observability-plan.md)
own the cross-repository intent, gate definitions, and workstream dependencies.
This document owns only this board's contribution. It records planned work,
not new electrical measurements, hardware validation, or deployment approval.

## Current evidence and board boundary

The [routing handoff](routing-session-handoff-2026-09-21.md) identifies the
finished v1.0 layout. The [interface map](interface-map.md) owns its actual GPIO
and Digital-50 allocation, including observation tap locations. Use its v1.0
map instead of historical InstrumentPort-40 assignments. The [validation
plan](validation-plan.md) and [bring-up log](bringup-log.md) remain the local
acceptance and measured-evidence records. Dated completion notes supersede
older unchecked layout tasks; this plan does not reopen completed routing.

As of the adapter's 2026-09-28 [bring-up record](../../la5032-instrument-port-adapter/docs/bringup-log.md),
the v1.0 companion target was ordered and awaited. Confirm receipt and the
actual unit before scheduling its electrical tests. Existing v0.x measurements
remain evidence for their identified units and assemblies. They do not qualify
the new Digital-50 path.

The board has one joystick axis and one pyControl UART. pyControl retains
experiment sequencing; firmware retains bounded motion and local fault
responses. Encoder and limit inputs reach the TMC5130A, not MCU GPIOs; the
InstrumentPort provides independent electrical witnesses to those signals.
Analog amplitude and physical motion require their own measurements.

## Independent execution paths

| Path | Ready now | Waiting condition and exit evidence |
| --- | --- | --- |
| `OBS-HW-JOYSTICK.1`: qualification preparation | Review actual v1.0 overlay, tap points, switched-domain states and existing acceptance limits; prepare channel checklist and evidence manifest with `OBS-IF` and `OBS-FW` | G0: versioned overlay and fixture expectations agreed with their owners; unknowns listed, no guessed pinout |
| `OBS-HW-JOYSTICK.2`: current-board electrical qualification | Prepare procedures independently of QP and future debug hardware | Physical v1.0 unit and qualified `OBS-HW-ADAPTER` cable path; G1: measured continuity, levels, loading, pulse fidelity, delay/skew, and operating envelope in the bring-up record |
| `OBS-HW-JOYSTICK.3`: correlated control operation | Select one existing bounded operation and list its command, bus, encoder/limit, and physical witnesses with `OBS-FW`/`OBS-HOST` | G1/G2 and relevant firmware readiness; G4: synchronized capture with stated uncertainty and explicit missing-data results; adding QS also requires the separately validated QP/target path |
| `OBS-HW-JOYSTICK.4`: future debug/trace revision | Inventory needs and pin/peripheral budget without altering the current board | `OBS-IF` contract decision and local revision decision; reviewed interface proposal first, subsequent implementation and bench evidence on its own revision |

The first two paths can proceed while `OBS-QP` validates QP 7.3.4/QV on
Teensy 4.1 at G3. That validation does not establish an RP2040 QP port. Keep
current firmware operational while the separate `OBS-FW` evaluation decides
whether QP adoption is worthwhile for this application.

## Planned tasks and acceptance

- [ ] `.1` Identify the exact v1.0 unit, overlay revision, expected signal
      polarities and rates, tap side, power state, and fixture for each test.
      Derive limits from existing board requirements and component data; give
      unresolved tolerances an owner before measuring against them.
- [ ] `.2` Complete the existing Digital-50 electrical acceptance items on the
      actual board/cable/adapter combination. Include MCU reset, switched
      domains off, supplies sequenced, and target/analyzer power-off cases.
      Report which checks need a scope or meter beyond a logic analyzer.
- [ ] `.2` Compare operation with and without the observation cable under
      representative simultaneous switching. Record waveform and analog-noise
      differences, delay/skew, minimum resolvable pulses, maximum qualified
      rates and cable length. Cable removal alone does not remove the load or
      switching of the board's fitted buffers.
- [ ] `.3` Capture one bounded command through UART, relevant SPI/I2C writes,
      independent encoder or limit activity, and the completion/fault reply.
      Record which observation establishes software intent, an electrical
      action, or physical response; firmware completion alone is insufficient.
- [ ] `.3` Provide positive and deliberately faulty bench examples for the
      deterministic host monitors. Use controlled fixture conditions; record
      resets, missing edges, capture gaps and timing ambiguity as such. Existing
      local safety behavior must remain independent of the monitor or agent.
- [ ] `.4` Propose a future revision with separate external SWD access and a
      dedicated TX trace connection, with optional command UART only if it
      meets a defined need. Audit actual pin mux, UART allocation, power-domain
      behavior, reset access, reference voltage, grounding and connector space.
      No new pin assignment is frozen by this plan.
- [ ] `.4` Resolve the proposal with `OBS-IF` and `OBS-FW` before schematic
      work. Preserve the existing decision against an on-board debug MCU;
      evaluate a reusable external probe. Keep drive-capable debug/control
      physically separate from the read-only InstrumentPort. An optional second
      command ingress must use the firmware's command ownership rules.
- [ ] `.4` After a revision is selected and implemented, retain its own build,
      inspection and bench evidence. Halting/programming is a bench diagnostic
      operation, not passive experiment monitoring. Qualify trace bandwidth,
      loss reporting and stopped-reader behavior with `OBS-FW`/`OBS-QP` before
      using that trace as evidence.

The current board's intentionally omitted SWD/debug connection is not a
fabrication defect to repair within this documentation work. G5 live
observation belongs to `OBS-RUN` after G4 and laboratory-specific acceptance.
It does not require adding a debug MCU, changing pyControl, or rewriting all
drivers.

## Evidence, ownership and handoff

For each bench session, record the board revision and unit identity, source
commit and dirty state, exact adapter and cable, connector views, instrument
identity/settings, channel-map version, stimulus, units, uncertainty, and raw
capture location/hash. Link measurements from the existing bring-up log; do not
copy another board's or revision's results into a new acceptance record.
Preserve unsuccessful and incomplete captures and state their limits.

Before measurements, claim the physical DUT, analyzer, cable, power supply,
and time window in the shared session record described by the central roadmap.
Only one agent/operator controls a claimed instrument or DUT at a time.
Offline documentation, fixture review, and saved-capture analysis may run in
parallel. A reservation records coordination; it does not authorize motion,
reset, stimulus, programming, or a change to a live experiment.

Use `docs/bringup-log.md` for per-unit measured results and the existing
`docs/captures/` hierarchy for retained raw captures and manifests. Link larger
run artifacts from the system/laboratory evidence destination chosen by
`OBS-RUN`. Reuse the existing [instrument strategy](instrument-strategy.md)
for instrument selection.

One board agent owns `docs/observability-plan.md`, this workstream's
`.agents/PLANS.md` entry, and new evidence entries. Arrange a handoff before
editing shared `docs/interface-map.md`, `docs/validation-plan.md`, or the
bring-up log concurrently. `OBS-FW` owns firmware files; `OBS-IF` owns connector
contracts; `OBS-HOST` owns decoding and deterministic checks. Future schematic
work is a separately claimed revision task. `kicad-libs` is excluded from
this documentation work and is not assigned to any parallel agent here.

Close a step only with its result, limits and evidence link, then report the
result to the central roadmap owner. For these documentation changes, check
relative links, `git diff --check`, and `make test`; preserve README generated
blocks and all KiCad/fabrication artifacts. Those checks do not pass any
hardware gate.
