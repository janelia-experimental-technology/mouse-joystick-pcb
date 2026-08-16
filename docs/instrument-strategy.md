# Instrument Strategy

**Rev 0 scope: the port is in Rev 0.** Decided 2026-08-16, reversing the
2026-08-12 deferral. The reason is firmware development rather than experiments:
being able to see the pyControl serial link at the cable and the TMC5130A SPI bus
in one capture is what makes protocol and driver bring-up tractable. Rev 0
populates `J4`, three of the five buffer packages, and **ten of the eighteen
digital Strands** — the four TMC SPI signals, both pyControl serial directions,
both firmware triggers, and `ENC_A`/`ENC_B`.

The encoder pair are temporary tenants of `DIG0`/`DIG1`, the slots the rev 2
torque front-end bus will take. They earn Rev 0 space because the TMC5130A's
`X_ENC` register is the only encoder count on the board, and capturing the raw
edges next to the SPI reads of that register is the only way to check the driver
is decoding correctly.

The remaining eight Strands are allocated now and routed when their circuits
arrive. Full allocation in `docs/interface-map.md`.

**Status:** Planning
**Date:** 2026-08-16
**Derived from:** `../mouse-joysticks-pcb/docs/instrument-strategy.md`
**Source profile:** `board-interfaces/docs/instrument-port-40.md`,
`board-interfaces/docs/la5032-instrument-port-40-mapping.md`

This board carries an InstrumentPort-40 so a logic analyzer can observe it during
**development and during scientific experiments**. That second use is a
deliberate change of intent, and it has consequences the bench-only case does
not.

## What The Port Is For Here

- **Event latency.** How long from a genuine pull to the `PULL_EVENT` edge, and
  from that edge to pyControl's logged timestamp. Software logs on either side
  cannot establish this alone.
- **Firmware development.** The Rev 0 reason, and the one that pulled the port
  forward. `PYC_DIO_A` and `PYC_DIO_B` show both directions of the pyControl link
  in hardware, independent of any firmware log, so a protocol bug can be
  attributed to the wire, to this board's parser, or to the breakout board rather
  than argued about. The TMC SPI bus in the same capture shows the driver
  transactions that resulted.
- **Checking the driver's encoder decode.** The Rev 0 reason for `ENC_A`/`ENC_B`.
  Rev 0 has no PIO cross-check, so the TMC5130A's `X_ENC` register is the only
  count on the board and nothing in firmware can contradict it. Raw edges plus
  SPI reads of that register, in one capture, make the comparison by hand.
- **Verifying the analog output.** `DAC_SPI_SCK`, `DAC_SPI_COPI`, `~{DAC_CS}`, and
  the analog output on `AIN0` are all in the capture from rev 1. "Does the voltage
  match the encoder?" is answerable from one file — against the raw edges while
  the encoder holds `DIG0`/`DIG1`, and against the driver's `X_ENC` reads after
  the torque bus takes those slots at rev 2. By then rev 1's PIO cross-check gives
  firmware its own second count. See `docs/interface-map.md`,
  "`DIG0`/`DIG1` Are The Swap Slots".
- **Time alignment.** `RSYNC` in the same capture as everything else means the
  board's local time can be placed in pyControl's frame with measured, not
  assumed, uncertainty.
- **Post-hoc fault diagnosis.** When a session misbehaves, a capture spanning the
  session is the difference between a reproducible investigation and a
  disagreement about what happened.
- **Agent-accessible observation.** An agent can drive captures and analyze them
  without physical access to the rig.

## The Two-Board Instrument Problem

This is the cost the twin-axis board does not pay, and it should be decided
rather than discovered.

The twin board's whole instrument argument is that one capture contains both
axes, the host link, and the sync reference, so cross-axis timing questions are
answerable from a single file. **Two single-axis boards cannot do that with one
LA5032 through InstrumentPort-40**, because each board has its own 40-pin FFC and
the profile carries 18 digital Strands per connector — 36 for two boards, against
the analyzer's 32 channels.

Options, in preference order:

1. **Instrument one board at a time.** Correct for bring-up and for most
   questions. Inadequate for anything cross-joystick.
2. **Two analyzers, aligned on `RSYNC`.** Both boards see the same `RSYNC` edges,
   so two captures can be aligned in post-processing with a measurable
   uncertainty. This is the honest answer for cross-joystick timing, and it needs
   the `RSYNC` fan-out question in `docs/pycontrol-port-pinout.md` answered
   first.
3. **A reduced overlay on each board so both fit one 32-channel analyzer.**
   16 channels each. Possible, but it means a second overlay definition, a
   different adapter, and captures that are not comparable to the full overlay.
   Do not do this without a specific question it answers.

**Do not solve this by widening InstrumentPort-40 in this repository.** If the
profile is genuinely too narrow, raise it in `board-interfaces`.

Note also that the analyzer count question does not arise at all if only one
joystick is instrumented during experiments and the other is instrumented only
during bring-up. Decide which regime the rig is actually in before buying a
second analyzer.

## What Changes Versus Bench-Only Use

### Buffer Enable Default

The `instrumentation_signal_buffer_sn74lvc125a` block pulls `~OE` up, so buffers
are high-Z until firmware drives `~{INSTR_BUF_OE}` low. That is correct for a
bench board and wrong for a rig: a session should not silently produce no data
because nobody enabled observation.

**Recommendation:** keep the hardware pull-up — a safe default at power-on is
worth more than convenience — and have firmware enable the buffers as part of
normal startup, then report buffer state in the `ID` and `STATUS` replies so the
host can tell whether observation is live. Do not change the pull-up to a
pull-down; that would make the power-on state depend on nothing.

### Physical Path

InstrumentPort-40 is specified around a **short bench FFC cable**. Permanent
in-rig use is a different mechanical problem:

- FFC is fragile, unshielded, and short. A rig gets cleaned, adjusted, and worked
  around by people not thinking about a ribbon cable.
- Cable length from the board to wherever the analyzer lives may exceed what a
  short FFC allows.
- Strain relief and a retention mechanism matter more than on a bench.

**Open decision.** Options: accept the FFC and mount the analyzer close; specify
a shielded transition on the adapter side; or raise a longer-cable variant in
`board-interfaces`. Do not solve this by inventing a board-specific connector
here.

Two boards means two FFC runs to route and protect, which makes this harder, not
easier.

### Safety With Animals Present

An instrument attached during animal work must not be able to affect the rig.
The current design satisfies this, and the reasons should be preserved
deliberately:

- The buffers are unidirectional, board-side to instrument-side only.
- The LA5032 has only digital-observation channels; it provides no stimulus into
  these lines.
- `AOUT0` and `AOUT1` are **no-connect** on this board. There is no analog
  stimulus path.
- No target power is injected through the connector.
- `AIN1_P/N` observes a ground-referenced 0-5 V board node, not a divided 36 V
  rail. The motor rail never reaches the instrument connector. Its assignment is
  contested between `AUX_ANALOG_OUT` and a rev 2 `BRAKE_ISENSE`; if the brake
  monitor wins it must be low-side or ground-referenced, for this reason. See
  `docs/interface-map.md`.

Anything that would add a drive path from the instrument into the board — a
bidirectional buffer, a populated `AOUT*`, an M2K used for stimulus — must be
treated as a bench-only configuration and must not be the normal experiment
arrangement.

### Capture Duration

- Continuous capture of the TMC SPI bus at motor-update rates produces a large
  amount of data with a low information density.
- `FW_TRIG0`/`FW_TRIG1` and the event lines are the natural trigger and
  segmentation sources. Firmware should emit markers that make a long capture
  navigable — trial boundaries, state entries, fault instants — rather than only
  transaction edges.

**Recommendation:** define the firmware marker semantics as part of the protocol
work, not as an afterthought during bring-up. A marker scheme decided after the
board exists tends to encode whatever was convenient rather than what a session
needs.

## Overlay

All 18 digital slots are allocated — 10 live in Rev 0, 6 more at rev 1, and 4
reserved for the rev 2 brake and torque sensor, two of which the encoder occupies
meanwhile. The mapping, the buffer grouping, the tap-point rules, and the reclaim
order if brake and torque need a fifth slot are all in `docs/interface-map.md`.
Ten signals sit on labelled test pads, not vias.

### No Buffer Input May Float

`U_C` and `U_D` are DNP in Rev 0 with their inputs unrouted. The grouping in
`docs/interface-map.md` puts each revision's signals in whole packages precisely
so a deferred group never leaves a powered CMOS input undriven; if that grouping
is edited, preserve the property.

`U_E` is the exception — it is fitted in Rev 0 for the encoder taps while its
other two channels wait for the brake. **Its `DIG11` and `DIG12` inputs are tied
to GND**, which is a net rather than a part and is the correct treatment for an
unused LVC125A input.

Three inputs need pull-downs rather than ties:

- `TMC_SPI_CIPO`, because the TMC5130A tri-states `SDO` between transactions.
- `ENC_A` and `ENC_B`, because the encoder is on the switched domain and floats
  whenever `HV_EN` is low, while `U_E` runs from `+3V3_MCU`.

100 kΩ each, at the buffer input. These are the only new passives the port adds.

## M2K Use

The M2K adapter remains a bench instrument for this board: analog verification of
the angle output and low-speed digital checks. M2K stimulus through `AOUT*` stays
unpopulated. M2K user supplies are not part of InstrumentPort-40 v0.3 and must
not be routed through this connector.

## Open Decisions

- One analyzer or two, and whether cross-joystick timing is a question the rig
  actually needs answered.
- Whether one `RSYNC` output can drive two boards, which option 2 above depends
  on.
- Whether the FFC arrangement is acceptable for permanent in-rig use.
- Firmware marker semantics for `FW_TRIG0`/`FW_TRIG1`, decided before schematic
  freeze so the trigger scheme and the pad allocation agree.
- Whether buffer state should also be a hardware indicator, so a technician can
  see that observation is live without querying the host.
- Whether captures become a retained experimental artifact with a retention
  policy, or remain engineering evidence.
