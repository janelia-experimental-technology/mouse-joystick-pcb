# Mouse joystick observability development plan

**Workstream:** `OBS-HW-JOYSTICK` (board slice of `OBS-HW`).
**Status:** Planned, updated 2026-09-30. All new work below is pending.

The system architecture (`orb-weaver-context/context/experimental-system-observability.md`)
and development roadmap (`orb-weaver-context/context/experimental-system-observability-plan.md`)
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

As of the adapter's 2026-09-28 bring-up record (`la5032-instrument-port-adapter/docs/bringup-log.md`),
the v1.0 companion target was ordered and awaited. Confirm receipt and the
actual unit before scheduling its electrical tests. Existing v0.x measurements
remain evidence for their identified units and assemblies. They do not qualify
the new Digital-50 path.

The board has one joystick axis and one pyControl UART. pyControl retains
experiment sequencing; firmware retains bounded motion and local fault
responses. Encoder and limit inputs reach the TMC5130A, not MCU GPIOs; the
InstrumentPort provides independent electrical witnesses to those signals.
Analog amplitude and physical motion require their own measurements.

## Direction update, 2026-09-30

Retain Digital-50 as the read-only, 32-signal observation interface. Evaluate a
separate optional debug/trace connector on a future board revision for a
reusable external RP2040 probe. Defer a combined 60-pin observation/debug
connector and a permanently on-board debug MCU until a demonstrated need
justifies reconsidering them. This reopens future separate-connector planning
from the 2026-09-08 rejection; it does not add SWD access to a manufactured board
or reopen its completed layout.

Keep the researcher's USB connection direct to the DUT and the probe's USB
connection separate. Preserve the pyControl UART's existing responsibility.
Two USB connectors do not establish galvanic isolation: review shared grounds,
reference levels, power sequencing and unpowered-pin behavior, and prevent
VBUS tying or back-powering through either power or signal connections. No
connector pinout, pin mux, voltage compatibility, cable assembly or power
arrangement is qualified by this decision.

OBS-PROBE (`instrument-control/docs/probe-development-plan.md`) owns the
external probe/host evaluation; `OBS-IF` owns the
candidate physical/electrical contract (`board-interfaces/docs/debug-trace-interface.md`). The upstream RP2040
`debugprobe` candidate typically offers SWD and one UART bridge. A second
independent UART, simultaneous command/trace capture, or additional probe
functionality must be demonstrated rather than assumed. Choose the actual
command and QS paths with those owners before allocating board pins.

A qualified future interface may permit a probe to remain attached for a
specified monitoring session. Attachment alone does not authorize halting,
reset, programming, memory/register writes or command injection during an
experiment. The current manufactured-board and bench-only restrictions remain
in force; future attached-monitoring conditions need explicit scope and
electrical/behavioral evidence, including probe reset and disconnect cases.

## Debug-Trace-20 and future MCU budget

The user accepted the separate
20-pin FFC logical pinout (`board-interfaces/docs/debug-trace-interface.md#debug-trace-20-logical-pinout`).
Exact parts, power/reset/inhibit circuits, cable behavior and this board's MCU
allocation remain open. Keep the current manufactured revision unchanged. A future
overlay can observe buffered trace TX, SYNC, reset and useful UART nets through
Digital-50; it must not create a drive path or carry raw VTref there.

The current v1.0 interface map allocates 28 GPIOs and reserves GP20/GP22 for
unconnected pyControl event/fault functions. Those are not automatically available
or a usable hardware UART pair. Full command/trace UARTs plus SYNC use five
general GPIOs, with SYNC potentially reusing a marker and bench trace RX optional.
RP2040 USB, SWD and RUN use dedicated pins. Observation taps mostly reuse existing
nets, so 32 analyzer channels do not imply 32 additional MCU GPIOs.

RP2354B, already cataloged in the inventory, is a candidate for a future board
with more I/O headroom: 48 GPIO rather than 30 and 520 kB SRAM rather than 264 kB.
It still has only two hardware UARTs, so pyControl plus separate command and trace
UARTs needs a deliberate USB/PIO/external-UART or reduced-profile choice. See the
shared assessment (`orb-weaver-context/context/experimental-system-observability.md#mcu-choice-and-pin-budget--assessment-2026-09-30`)
for sources and scope. The detailed
stocked MCU comparison (`orb-weaver-context/context/instrument-controller-mcu-selection.md`)
also evaluates STM32G0B1CEU6: six USART plus two LPUART engines, a static three-UART
allocation with USB/SWD, 144 kB SRAM and up to 44 GPIO including USB/SWD/reset
pads. Compare it with RP2354B under a complete joystick pin/peripheral budget.
PIO adds serial engines, not pins, so it cannot by itself solve the current
RP2040 allocation. An occasional PIO command UART is a future RP-board candidate;
driver buffering, IRQ cost and loss visibility need measurement.
An MCU change needs a new power/boot/layout and firmware qualification;
it is not approved by the connector decision. RP2040 remains the
active QP target and external-probe candidate. Do not reassign current pins,
revise the board, or edit library blocks under this documentation task.

## Independent execution paths

| Path | Ready now | Waiting condition and exit evidence |
| --- | --- | --- |
| `OBS-HW-JOYSTICK.1`: qualification preparation | Review actual v1.0 overlay, tap points, switched-domain states and existing acceptance limits; prepare channel checklist and evidence manifest with `OBS-IF` and `OBS-FW` | G0: versioned overlay and fixture expectations agreed with their owners; unknowns listed, no guessed pinout |
| `OBS-HW-JOYSTICK.2`: current-board electrical qualification | Prepare procedures independently of QP and future debug hardware | Physical v1.0 unit and qualified `OBS-HW-ADAPTER` cable path; G1: measured continuity, levels, loading, pulse fidelity, delay/skew, and operating envelope in the bring-up record |
| `OBS-HW-JOYSTICK.3`: correlated control operation | Select one existing bounded operation and list its command, bus, encoder/limit, and physical witnesses with `OBS-FW`/`OBS-HOST` | G1/G2 and relevant firmware readiness; G4: synchronized capture with stated uncertainty and explicit missing-data results; adding QS also requires the separately validated QP/target path |
| `OBS-HW-JOYSTICK.4`: future debug/trace revision | Inventory separate-connector needs and pin/peripheral/power budget with `OBS-PROBE` without altering the current board | `OBS-IF` contract decision, `OBS-PROBE` capability evidence and local revision decision; reviewed interface proposal first, subsequent implementation and bench evidence on its own revision |

The first two paths can proceed independently of `OBS-QP`. Its primary G3
qualification target is now RP2040 with Earle Philhower's Arduino core, using
QP/C++ v7.3.4 and QV only. Previous Teensy 4.1 build evidence is preserved;
Teensy hardware validation is deferred and does not block this RP2040 path.
STM32G0B1CEU6 is a later, separately qualified target. Neither target is declared
supported by this planning update. Both RP2040 and STM32G0B1CEU6 use Cortex-M0+
and lack SWO/ITM trace; QS needs a separately qualified TX transport.

Keep current firmware operational while `OBS-FW` evaluates application adoption.
`OBS-QP` target qualification does not establish this board's connector, pin
assignment or probe behavior, and `OBS-PROBE` qualification does not establish
QP scheduling, tracing overhead or application behavior.

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
- [ ] `.4` Propose a future revision with a separate optional debug/trace
      connector, external SWD access and a dedicated TX trace path. Add a
      command UART only for a defined need and demonstrated probe capability.
      Audit actual pin mux, UART allocation, reset access, reference voltage,
      grounding, power domains and connector space with `OBS-PROBE`. No new pin
      assignment is frozen by this plan.
- [ ] `.4` Resolve the proposal with `OBS-IF`, `OBS-FW` and `OBS-PROBE` before
      schematic work. Keep all 32 Digital-50 signals read-only and separate from
      drive-capable debug/control. Defer combined-60 and a permanently on-board
      debug MCU. An optional second command ingress must use the firmware's
      command ownership rules; one UART bridge does not imply two simultaneous
      independent UART channels.
- [ ] `.4` Preserve direct researcher-to-DUT USB and separate probe USB in the
      proposal. Review both hosts' grounds and power domains, prevent VBUS tying
      and signal-pin back-powering, and define powered/unpowered and probe-reset
      behavior. Qualify any isolation claim separately.
- [ ] `.4` After a revision is selected and implemented, retain its own build,
      inspection and bench evidence. Qualify the TX path, trace bandwidth, loss
      reporting and stopped-reader behavior with `OBS-FW`/`OBS-QP`/`OBS-PROBE`
      before using QS as evidence. SWD is not a replacement for the QS transport
      on these Cortex-M0+ targets.
- [ ] `.4` If attached experiment monitoring is proposed, document the permitted
      read-only/receive-only functions and enforceable limits with `OBS-RUN` and
      `OBS-PROBE`. Demonstrate reset/disconnect behavior and absence of unwanted
      drive actions; retain the current board's bench-only restrictions until
      a separately scoped arrangement is qualified. Halting, reset, programming
      and writes are not authorized by monitoring permission.

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
contracts; `OBS-HOST` owns decoding and deterministic checks; `OBS-PROBE` owns
external probe firmware/interface/host evaluation in `instrument-control`.
Future schematic work is a separately claimed revision task. `kicad-libs` is
excluded from this documentation work and is not assigned to any parallel agent here.

Close a step only with its result, limits and evidence link, then report the
result to the central roadmap owner. For these documentation changes, check
relative links, `git diff --check`, and `make test`; preserve README generated
blocks and all KiCad/fabrication artifacts. Those checks do not pass any
hardware gate.
