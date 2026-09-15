# Instrument Strategy

**New direction, 2026-09-12:** See the
[Digital InstrumentPort migration plan](digital-instrument-port-migration.md)
for 50-pin / 32-channel observation, integrated buffers enabled by hardware
default, and the v1.0 release gate. The Rev 0 allocations and analog-tail
descriptions below are legacy hardware/planning context, not the new pinout.

**Rev 0 scope: the port is in Rev 0.** Decided 2026-08-16, reversing the
2026-08-12 deferral. The reason is firmware development rather than experiments:
being able to see the pyControl serial link at the cable and the TMC5130A SPI bus
in one capture is what makes protocol and driver bring-up tractable. Rev 0
populates `J1501`, all **three** buffer packages, and **eleven of the eighteen
digital Strands** — the four TMC SPI signals, both pyControl serial directions,
both firmware triggers, `ENC_A`/`ENC_B`, and `LIMIT_SW`.

**Corrected 2026-08-17 against the as-built schematic.** The connector is `J1501`,
not `J4`. There are **three** `SN74LVC125A` packages on the board, not five:
`U1601` (`ENC_A`, `ENC_B`, `PYC_UART_RX`, `PYC_UART_TX`), `U1701` (`TMC_SPI_SCK`,
`TMC_SPI_COPI`, `TMC_SPI_CIPO`, `~TMC_CS`) and `U1801` (`LIMIT_SW`, `FW_TRIG0`,
`FW_TRIG1`, and one spare). `U_C` and `U_D` were never drawn and `U_E` does not
exist as a designator. All three run from `+3.3V_MCU`, all three take `~OE` from
`~{INSTR_BUF_OE}` with their own 10 kΩ pull-up (`R1601`/`R1701`/`R1801`), and every
output carries a 33 Ω series resistor. **The grouping mixes domains**, so the rev-2
swap of `DIG0`/`DIG1`/`DIG11` touches two packages rather than one — the
"deferred group in a whole package" property described further down was not
achieved.

`ENC_A`, `ENC_B`, and `LIMIT_SW` are temporary tenants of `DIG0`, `DIG1`, and
`DIG11`, the slots the rev 2 torque bus and brake will take. They earn Rev 0
space because **none of them reaches an RP2040 pin in any revision** — the
TMC5130A owns them — so the driver's own report is the only account firmware has
of position and homing. Capturing the raw signals next to the SPI traffic is what
makes that account checkable.

The remaining seven Strands are allocated now and routed when their circuits
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
  There is no PIO cross-check in any revision, so the TMC5130A's `X_ENC` register
  is the only count on the board and nothing in firmware can contradict it.
  Likewise `LIMIT_SW`: no GPIO copy, so the port is the only witness that the
  switch closed when the driver says homing happened. Raw edges plus
  SPI reads of that register, in one capture, make the comparison by hand.
- **Verifying the analog output.** `DAC_SPI_SCK`, `DAC_SPI_COPI`, `~{DAC_CS}`, and
  the analog output on `AIN0` are all in the capture from rev 1. "Does the voltage
  step when the code was written, and does it track the encoder?" is answerable
  from one file — against the raw edges while the encoder holds `DIG0`/`DIG1`, and
  against the driver's `X_ENC` reads after the torque bus takes those slots at
  rev 2. Nothing replaces the raw edges then — the cross-check was deleted, not
  deferred. See `docs/interface-map.md`, "`DIG0`, `DIG1`, And `DIG11` Are The Swap
  Slots". **The question the port answers is timing, not amplitude**, and the
  answer carries 266 µs of filter delay — see the `AIN0_P` bullet under "Safety
  With Animals Present".
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

**RESOLVED IN HARDWARE 2026-09-03: the rig now has two LA5032s, one per
board.** Option 2 is the physical configuration, not a proposal. What that
changes and what it does not:

- Option 1's channel arithmetic no longer binds. Note it never bound as tightly
  as written above for a *specific* question — the encoder/switch capture needs
  five channels (`DIG0`, `DIG1`, `DIG11`, `TRIG0`, `TRIG1`), not eighteen, so
  two boards' worth of that overlay would have fitted one 32-channel analyzer
  all along. The 36-against-32 problem is real only for the full overlay.
- **Cross-joystick timing is still blocked**, on exactly the condition option 2
  names: the `RSYNC` fan-out question in `docs/pycontrol-port-pinout.md`. Two
  captures cannot be aligned until one `RSYNC` output is known to be able to
  drive both boards.
- A new problem arrives with the second analyzer, and it is a bookkeeping one:
  **an LA5032 reports no USB serial number**, so two of them are
  indistinguishable in USB descriptor space. libsigrok can only address them as
  `conn=<busnum>.<devnum>`, which changes when the firmware upload re-enumerates
  the device — observed going 21,22 → 23,24 across a single `--scan` with no
  cable touched, *with the relative order inverting*. A capture attributed to the
  wrong joystick is worse than a missing one, and nothing in a `.sr` file would
  reveal it later.

  The fix is the **identity beacon**: each board clocks its own serial out of
  `FW_TRIG0`/`FW_TRIG1` on command, so a capture identifies its own source.
  It needs no 36 V, because `U1801` is on `+3.3V_MCU`. The current mapping and
  the procedure are in [`docs/bringup-log.md`](bringup-log.md) under "Instruments
  Attached To This Rig"; the frame contract is
  `../board-interfaces/docs/instrument-port-identity-beacon.md`; the host tools
  are in `../instrument-control`.

  This also settles, in passing, the "agent-accessible observation" goal listed
  above: an agent can now establish which instrument is on which board without
  physical access to the rig.

- The question the option list leaves open is unchanged and still wants
  answering: **whether cross-joystick timing is a question the rig actually
  needs.** Two analyzers being present is not the same as two analyzers being
  needed during experiments.

**Do not solve this by widening InstrumentPort-40 in this repository.** If the
profile is genuinely too narrow, raise it in `board-interfaces`.

Note also that the analyzer count question does not arise at all if only one
joystick is instrumented during experiments and the other is instrumented only
during bring-up. Decide which regime the rig is actually in before buying a
second analyzer.

## What Changes Versus Bench-Only Use

### Buffer Enable Default

**Legacy hardware:** `instrumentation_signal_buffer_sn74lvc125a` pulls `~OE`
up, so its outputs are high-Z until firmware drives `~{INSTR_BUF_OE}` low.
That remains an accurate description of existing boards, not the recommendation
for the new read-only port.

**New direction, 2026-09-12, settled 2026-09-15:** enable the digital port by
hardware default on valid `+3.3V_MCU`, and provide **no disable at all**. Both
active-low OE inputs on all four SN74LV541ARKSR packages are held low by
pull-down; there is no manual jumper, no firmware link and no GPIO. A defined
pull-down is a hardware default, not an undefined power-on state. Capture must
not require successful MCU boot or new firmware. See the
[migration plan](digital-instrument-port-migration.md) and the
[rationale](../../kicad-libs/docs/digital-instrument-port-design-blocks.md#no-disable-control-and-why).

This retires `~{INSTR_BUF_OE}` and returns `GP24` to the spare pool: it existed
only because the legacy LVC125A port was default-off and needed firmware to
switch it on. Firmware has no buffer state to report, so the old requirement to
distinguish requested state from actual output availability no longer applies.

The trade accepted is that output switching cannot be muted for a noise
investigation. Detaching the cable is the substitute, and it bounds the cable's
contribution rather than the buffers' — they keep switching into their
board-side traces and 100 ohm damping resistors. Use target-power-off cable
handling unless the actual assembly is qualified for hot plugging.

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

An instrument attached during animal work must have no stimulus authority into
the rig. The following legacy design choices remove intended drive paths, but
they do not prove immunity to cable faults, shared-ground disturbances, or
buffer-supply noise. Validate those effects for the actual rig:

- The buffers are unidirectional, board-side to instrument-side only.
- The LA5032 has only digital-observation channels; it provides no stimulus into
  these lines.
- `AOUT0` and `AOUT1` are **no-connect** on this board. There is no analog
  stimulus path.
- No target power is injected through the connector.
- `AIN1_P/N` observes a ground-referenced board node no wider than 0-5 V, not a
  divided 36 V rail. The motor rail never reaches the instrument connector.
  **Settled 2026-08-31: `AIN1_P/N` is `BRAKE_ISENSE`**, and it satisfies this
  constraint by construction rather than by promise — the brake driver is a
  low-side current sink, so its sense node is a 10 Ω shunt referenced to `PGND`
  and buffered to 0-2.01 V. There is no high-side node in the design to put on
  the connector. `AUX_ANALOG_OUT` loses the slot; it was already down to "is a
  second DAC and amplifier worth it" and is not populated at rev 1, so nothing
  that exists is given up. See `docs/interface-map.md`. **In Rev 0 as built,
  `AIN0_P/N` and `AIN1_P/N` are no-connect** — the constraint is forward-looking,
  not something to verify on this board. `AIN0_P/N` are wired at rev 1;
  `AIN1_P/N` at rev 2 with the brake.
- **`AIN0_P` taps `AMP_VOUT`, not the BNC centre.** **Added 2026-08-26, tap point
  changed 2026-08-27.** The 2026-08-26 version of this bullet put `AIN0_P` on the
  BNC centre node, on the far side of the analog block's 249 Ω source resistor
  (`R2007`) and on the *same node* as the researcher's instrument. **That is the
  wrong side.** It creates a permanently DC-connected stub from the researcher's
  signal onto a 40-pin unshielded 0.5 mm FFC carrying SPI and UART edges, present
  whether or not an instrument is plugged in, on a signal that lands in a recorded
  dataset.

  As specified now: `AIN0_P` taps **`AMP_VOUT`** — the `OPA197` output, *before*
  `R2007` — through a **series 1 kΩ**, and `AIN0_N` ties to `AGND` at the
  connector. Crosstalk injected on the FFC stub then lands on the op amp's
  low-impedance output and never reaches the BNC, while the researcher's node
  keeps its clean 249 Ω source with no stub on it. What this gives up is
  verifying `R2007` and the BNC joint through the port; do that once with a DVM
  at build time, not on every capture.

  The instrument input must still be high impedance: 1 kΩ into the M2K's 1 MΩ is
  0.1%, which is nothing at its resolution. Do not fit a 50 Ω shunt on this net;
  `R2007` is source isolation, not a termination.

- **`AIN0` is for timing, not amplitude.** **Added 2026-08-27.** The M2K's analog
  inputs are 12-bit over ±25 V — and its high-gain range is ±2.5 V, which clips a
  3.3 V full scale — so on the range that fits this signal it resolves about
  12 mV, roughly 240 DAC codes against a 50.4 µV LSB. It can confirm that the
  voltage steps when the code was written and that it tracks the encoder; it
  cannot verify the ±0.4% accuracy claim. Amplitude and linearity are a
  6½-digit-DMM job at the BNC.

  Note also that the analog block carries a **2-pole 987 Hz Sallen-Key** ahead of
  its output as of 2026-08-27, so **every latency measured through `AIN0` includes
  266 µs of filter group delay**. Subtract it or report it; do not attribute it to
  firmware. See `docs/encoder-analog-output.md`.

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

The allocation in this section is the legacy 40-pin overlay. For digital-50,
create a new explicit board map as described in the
[migration plan](digital-instrument-port-migration.md); do not apply the old
slot-eviction or analog-tail rules to the new connector.

All 18 digital slots are allocated — **11 live in Rev 0**, 6 more at rev 1, and 4
reserved for the rev 2 brake and torque sensor, **three** of which the encoder and
the limit switch occupy
meanwhile. The mapping, the buffer grouping, the tap-point rules, and the reclaim
order if brake and torque need a fifth slot are all in `docs/interface-map.md`.
~~Ten signals sit on labelled test pads, not vias, plus `ENC_A`/`ENC_B`/`LIMIT_SW`,
which are padded as well because the pads become their only access at rev 2.~~
**Struck 2026-08-17 — no test points exist anywhere on the board.** The reasoning
is still right and the need is unmet: `ENC_A`/`ENC_B` lose their port slots at
rev 2 and today have no fallback access at all. Either add the pads before
fabrication or accept that those signals become unreachable at rev 2.

The eleven live Strands as built: `DIG0` = `ENC_A_BUF` (`J1501` pin 2), `DIG1` =
`ENC_B_BUF` (3), `DIG2` = `TMC_SPI_SCK_BUF` (5), `DIG3` = `TMC_SPI_COPI_BUF` (7),
`DIG4` = `TMC_SPI_CIPO_BUF` (8), `DIG5` = `~TMC_CS_BUF` (10), `DIG7` =
`PYC_UART_RX_BUF` (13), `DIG8` = `PYC_UART_TX_BUF` (14), `DIG11` = `LIMIT_SW_BUF`
(19), `TRIG0` = `FW_TRIG0_BUF` (26), `TRIG1` = `FW_TRIG1_BUF` (28). `DIG6`, `DIG9`,
`DIG10`, `DIG12`-`DIG15`, `AIN0_P/N`, `AIN1_P/N`, `AOUT0` and `AOUT1` are
no-connect.

**Rev 1 adds four Strands, and they need a fourth buffer package.** Confirmed
against the netlist on 2026-08-27: `DIG6`, `DIG9`, `DIG10`, `AIN0_P` and `AIN0_N`
are still 1-node no-connects at `J1501` pins 11, 16, 17, 32 and 33. The rev 1
wiring is `DIG9` = `DAC_SPI_SCK_BUF` (16), `DIG10` = `DAC_SPI_COPI_BUF` (17),
`DIG6` = `~DAC_CS_BUF` (11), and `AIN0_P` = `ANGLE_OUT` tapped at `AMP_VOUT`
through 1 kΩ (32) with `AIN0_N` to `AGND` (33).

The three digital taps need a **fourth `SN74LVC125A`** — `U1601`/`U1701`/`U1801`
carry 12 of 12 channels, so this is a new placement, not a stuffing change, and
board area has to be reserved for it deliberately. `U603`/`U604` are two entirely
empty `SN74CB3Q3245` packages whose removal frees roughly the area needed; see
`docs/design-block-map.md`.

**These three taps need no new terminations.** They sit on the A / switched side
of the bus switch like the TMC taps, but the analog block now owns all three
defining resistors internally — `R2006` 10 kΩ pull-up on `~{DAC_CS}` to
`+3.3V_SW`, and `R2009`/`R2010` 10 kΩ pull-downs on `DAC_SPI_COPI`/`DAC_SPI_SCK`
to GND. Do **not** add board-level copies; that would halve them.

**`AGND` (pins 31, 34, 37, 40) is tied to `GND`** as of 2026-08-17. It was
previously an isolated four-pin island, which would have left the analog returns
without a reference when rev 1 populates `AIN*`.

### No Buffer Input May Float

~~`U_C` and `U_D` are DNP in Rev 0 with their inputs unrouted.~~ **Struck
2026-08-17 — `U_C` and `U_D` do not exist.** Rev 0 has exactly three packages and
all three are fitted, so there is no deferred group to protect. The grouping in
`docs/interface-map.md` puts each revision's signals in whole packages precisely
so a deferred group never leaves a powered CMOS input undriven; **as built the
grouping mixes domains instead** — `U1601` carries both encoder channels and both
pyControl serial directions, `U1701` carries all four TMC SPI signals, `U1801`
carries `LIMIT_SW` and the two firmware triggers. Preserve the intent when rev 1
adds packages, but do not assume it holds today.

`U1801` is the package with a spare — three signals in Rev 0 while its fourth
channel waits for the brake. **Its fourth input is tied to GND**, which is a net
rather than a part and is the correct treatment for an unused LVC125A input.
**Note that this does not produce a buffered static low on `DIG12`:** that
channel's output stops at `R1805` and `J1501` pin 20 is a no-connect, so nothing
reaches the connector.

**The taps sit on the A / switched side of the bus switch.** `docs/interface-map.md`
says A is the MCU side; **it is wrong and the board is the authority** — A is the
TMC / switched side, B is the MCU side. That is why the terminations below matter:
every tapped TMC signal goes to 0 V with the switched domain, not to whatever the
MCU is driving.

Five inputs need defined levels rather than ties, and **as built they are 10 kΩ,
not 100 kΩ** (`R1401`-`R1405`, in the board-authored `instrument_port` sheet so a
design-block re-place cannot lose them):

- `TMC_SPI_SCK`, `TMC_SPI_COPI`, `TMC_SPI_CIPO` — 10 kΩ to GND. `TMC_SPI_CIPO`
  needs it because the TMC5130A tri-states `SDO` between transactions; all three
  need it because they float whenever the switched domain is off while `U1701` runs
  from `+3.3V_MCU`.
- `~{TMC_CS}` — 10 kΩ to **`+3.3V_SW`**, not to GND. A pull-down here would assert
  chip select. Referencing the switched rail means it collapses with the domain
  rather than injecting current into a dead rail, and `R401`/`R402` hold `+3.3V_SW`
  at 0 V when the domain is off, so the pull-up still reads as a valid low.
- `LIMIT_SW` — 10 kΩ to GND, defining the `U1801` input.

**Do not "improve" these to 100 kΩ.** The TMC's `CSN`/`SCK`/`SDI`/`SDO` are marked
`(tpu)` with `RPU` = 132/166/200 kΩ; 100 kΩ against that parks the node at ~1.9 V,
straddling the `SN74LVC125A`'s 2.0 V `VIH`. 10 kΩ gives 0.28 V, a clean low.

`ENC_A` and `ENC_B` are the exception: they keep 100 kΩ, because their pull-downs
are `R805`/`R806` inside the encoder block on the Schmitt outputs rather than new
passives at the buffer.

Pull-down rather than up on the GND-referenced group for the original reason: a
pull-up would have to go to `+3.3V_MCU` and would back-power those chips through
their output clamps while the domain is dark.

Note that `~OE` does **not** gate the input stage. `ΔICC` is 500 µA typ / 5000 µA
max per partially biased input regardless of `OE`, against 40 µA max for the whole
device with valid levels — so disabling the buffers is not a substitute for
terminating their inputs.

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
