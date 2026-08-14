# Relationship To The Twin-Axis Board

**Rev 0 scope:** this record compares the two *full-scope* designs and stays
valid as such. Rev 0 of this board was rescoped on 2026-08-13 to the interfaces
only, which widens the near-term gap and changes none of the structural
trade-offs below. See `docs/rev0-plan.md`.

**Status:** Decision record
**Date:** 2026-08-12

Two repositories exist for the same rig:

| Repository | Scope |
| --- | --- |
| `../mouse-joysticks-pcb` | One PCB controlling **both** joysticks over one pyControl UART |
| `mouse-joystick-pcb` (this one) | One PCB controlling **one** joystick; two boards per rig |

Both are live. This file records why, what each one costs, and what has to
happen if the choice is reversed.

## The Decision

**Build the single-axis board first, because it can be finished sooner.** The
form-factor question — whether one board or two fits the rig better — is
deliberately left open and is expected to be answered by the mechanical
assembly, not by this document.

This is a scheduling decision, not an architectural one. The twin-axis
architecture review of 2026-06-11 remains the reasoned position on what the rig
should eventually have. Nothing here overturns it.

## Why This One Is Faster

Not general "fewer parts" hand-waving — these are the specific items that are
gone:

| Twin-axis work item | Status here |
| --- | --- |
| Fitting two axes into 30 GPIOs, and the descope table that makes it fit | Gone. 29 of 30 at full scope, 17 of 30 in Rev 0, and pins to spend on supply diagnostics. One thing was cut, deliberately: the synthetic homing stimulus, traded for the GPIO isolation enable. |
| Deciding where four TTL event lines land — the twin board's blocking question | Reduced to three lines; four BNCs is a workable complement. Deferred out of Rev 0 entirely. |
| Axis symmetry as a layout constraint and a scientific confound | Not applicable |
| Zoning two motor sections and two encoder paths away from two analog outputs | One of each |
| Sizing supply, protection, and bulk for two motors moving at once | One motor |
| Cross-axis fault policy, `XFAULT`, cross-axis interference measurements | Not applicable |
| Axis argument in every protocol verb, and the tests that it is never defaulted | Not applicable |
| Two of every harness, connector, and calibration record | One of each |
| Gate D's cross-axis interference section | Gone entirely |

The GPIO relief is the largest single item. It removes a descope, a fallback
plan, and a class of "we need two more pins" late surprises.

## What Two Boards Cost

Stated honestly, because these are real and some of them are scientific rather
than logistical.

**Scientific:**

- **Two clocks.** Cross-axis event ordering becomes a reconciliation problem
  rather than a fact. Both boards see `RSYNC`, so alignment is possible, but it
  has an uncertainty that a shared local timebase does not.
- **Two instruments, or one instrument that cannot see both axes.** A capture
  containing both joysticks, the host link, and the sync reference in one file is
  not available. Cross-axis timing questions need two captures aligned in
  post-processing.
- **Symmetry is no longer enforced by construction.** On one board, two identical
  block instances are identical by inspection. With two boards, symmetry depends
  on both being the same revision, the same assembly lot, and the same firmware.
  **This is the risk to manage**: record the board serial, revision, and firmware
  hash against each joystick, and keep them matched.

**Logistical:**

- **Two pyControl behavior ports and six TTL lines** instead of one port and
  four. The rig also needs lickports, reward valves, cues, cameras, and sync from
  the same controller. UART-capable ports are not scarce — three on Breakout 1.2,
  four on D-series 1.6 — but total I/O is finite, and this is the resource the
  twin-axis decision was conserving.
- Two power inputs, two enclosures or one enclosure with two boards, two harness
  sets, two calibration records.

**In exchange:**

- A spare board is a spare *axis*, not a spare rig. A single failure degrades the
  rig to one joystick instead of stopping it.
- The board is small, cheap, and quick to respin.

## What Transfers, In Both Directions

Most of the engineering is shared, which is what makes running both repositories
tolerable rather than wasteful.

**Identical in both:**

- pyControl port pinout, UART parameters, and the RJ-45 part choice
- UART protocol framing, verbs, events, fault model, and heartbeat semantics —
  the twin board adds an axis field, this board omits it
- TMC5130A section, `R_SENSE` 0.15 Ω, `vsense = 1`, `IRUN = 28`
- The DAC8563 choice, the analog output design, and its calibration semantics
- InstrumentPort-40 buffering pattern, the `~OE` default, and the enable-at-startup
  rule
- Safety model: boot-safe outputs, heartbeat, bounded motion, latched faults
- The four new circuit sections neither board has yet: pyControl port boundary,
  event BNC group, DAC output section, debounced limit input

**Different:**

- GPIO allocation and InstrumentPort-40 overlay
- Supply voltage: 36 V here, 24 V on the twin board
- Everything axis-plural: symmetry rules, cross-axis fault policy, `XFAULT`,
  layout zoning

**Building this board first produces the four missing sections as verified
circuits.** The twin board then inherits them instead of designing them. That is
a genuine schedule benefit to the twin board, not just to this one.

## If The Choice Is Reversed

Switching to `../mouse-joysticks-pcb` later costs:

- A new layout. Nothing physical carries over.
- A new GPIO map and a new instrument overlay, both of which are already written
  in that repository.
- Firmware changes: an axis argument in the protocol, per-axis state, the
  cross-axis fault policy, and `XFAULT`. The low-level driver, encoder, DAC, and
  pyControl transport code carries over.
- Re-deciding 24 V versus 36 V. If this board's 36 V rail works well, the twin
  board should probably adopt it — its own notes record the 24 V/36 V tension as
  unresolved for the Rev 1 brake.

What it does **not** cost: the pyControl integration evidence, the device class,
the protocol, the calibration semantics, or the instrument tooling. Those are the
expensive unknowns, and this board resolves them either way.

## Keeping The Repositories Honest

- Documents in this repository that were derived from `../mouse-joysticks-pcb`
  say so at the top.
- **When a shared fact changes — the motor part, the encoder part, the pyControl
  pinout, the DAC logic-level answer — update both repositories.** A divergence
  in a shared fact is the failure mode of running two repositories, and it will
  not announce itself.
- When one board is abandoned, mark its repository as superseded rather than
  deleting it. The reasoning is worth keeping.
