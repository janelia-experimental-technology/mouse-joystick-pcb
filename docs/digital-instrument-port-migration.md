# Digital InstrumentPort migration plan

**Status:** New direction documented 2026-09-12. Updated 2026-09-15: **both
KiCad blocks are built** in `../kicad-libs` — DUT and adapter, vertical FH12,
schematic and layout, passing `check` and `validate` — and the buffers carry no
disable control. **No board change yet, and no cable purchased**, so the
end-to-end permutation is still assumed rather than measured. The v1.0
adopt/fallback decision below is therefore now a scheduling call, not a
blocked-on-implementation one.
**Contract:** [Digital InstrumentPort draft](../../board-interfaces/docs/instrument-port-digital.md).

## Direction and v1.0 release decision

Prefer the new 50-pin, 32-channel, read-only digital port for the upcoming
design if the bounded implementation work fits the v1.0 order schedule. It
replaces the mixed analog/digital allocation with more digital visibility and
places the connector and buffers together as a reusable laid-out KiCad block.
Analog and SWD/JTAG/debug remain separate optional interfaces, not prerequisites
for this change. Start with the existing horizontal 50-pin connector candidate;
vertical and 25-pin versions do not gate v1.0.

This reopens the 2026-09-11 plan to keep InstrumentPort-40 for v1.0. It does
not claim the 50-pin design is ready to order or that an unlimited delay is
acceptable. Before releasing fabrication files, record one explicit outcome:

- **Adopt digital-50:** reviewed pinout, block, new adapter design, board
  allocation, and pre-fabrication checks complete; subsequent bench qualification
  remains required before laboratory deployment.
- **Legacy-40 fallback:** if that work would delay the order unacceptably,
  explicitly retain the unchanged v0.3 interface for this release and defer
  the new port. Freeze its reduced overlay and record the lost observations.

The old 30-signal / 10-ground digital-40 proposal is superseded by the new
32-signal / 18-ground digital-50 direction. Existing 40-pin boards, captures,
and their LA5032 adapters remain legacy evidence; do not relabel them.

## Board integration

Use the [planned integrated block](../../kicad-libs/docs/digital-instrument-port-design-blocks.md)
with four SN74LV541ARKSR octal buffers. Its local symbol/footprint already exist;
the exact STEP model and the actual integrated block remain outstanding.

Power the buffers from **`+3.3V_MCU`**, independent of firmware and `HV_EN`.
The new default is **enabled with valid supply**, so failed boot/programming
does not prevent observation of signals that still exist on the board.
**There is no disable, as of 2026-09-15.** Both active-low OE inputs on all
four packages are held low with no jumper, no firmware link and no port, so the
port observes whenever `+3.3V_MCU` is valid and cannot be muted without
desoldering. The owning contract was relaxed the same day from requiring manual
disabling to permitting none; the rationale is in the
[block plan](../../kicad-libs/docs/digital-instrument-port-design-blocks.md#no-disable-control-and-why).

**This frees `GP24`.** The legacy `~{INSTR_BUF_OE}` existed because the
`SN74LVC125A` port was default-*off* and firmware had to switch it on. Nothing
replaces it, so `GP24` returns to the spare pool and its pull-up circuit and
init sequence are deleted rather than ported. Record that in
`docs/interface-map.md` with the other v1.0 GPIO changes — the allocation is
close to full, so this is a pin worth reclaiming deliberately rather than
leaving allocated to a signal that no longer exists.

Do not confuse observation enable with `~{BUS_SW_EN}` or any motor safety gate;
their safe-off/isolated defaults are unchanged and are not affected by this.

Preserve and recheck board-owned input terminations and tap locations when
replacing blocks. In particular, pulls requiring HIGH on a switched-domain net
reference `+3.3V_SW`, never the always-on rail. The `SW_RAIL_SENSE` divider's
off-state discharge function remains load-bearing. New CMOS thresholds and
rise/fall limits need review; a clean legacy LVC125 capture does not establish
LV541 compatibility. OE does not remove input loading or fix floating inputs.

Build a new board overlay from the actual v1.0 circuits: pyControl UART,
TMC SPI/status, the revised I2C DAC bus, torque ADC SPI/status, brake/fault and
event/sync signals, firmware markers, and any retained encoder/limit witnesses.
Do not silently carry the old SPI DAC assignments into the I2C design.

The 32-channel budget includes two firmware marker/beacon channels in the first
bank. Their indices are not frozen: DIG14/15 was the earlier proposal;
the 2026-09-13 recommendation is to consider DIG0/1 so smaller prefixes retain
identity. Resolve the [canonical marker decision](../../board-interfaces/docs/instrument-port-digital.md#markers-identity-and-capture-records)
before wiring `FW_TRIG0` / `FW_TRIG1`. Keep the existing beacon payload unchanged
and use the selected adapter's channel map. The old 18-channel budget no longer
forces eviction of
`ENC_A` / `ENC_B` if digital-50 is adopted; the final allocation still needs
an explicit board review. Preserve useful test pads regardless of port size.

Future opportunity, not v1.0 scope: a separately reviewed adapter could combine
two reduced 16-channel joystick boards into one 32-channel analyzer capture,
using one sampling timebase. This does not eliminate buffer/cable skew and
would join the board grounds. See the
[subdivision/aggregation observations](../../board-interfaces/docs/instrument-port-digital.md#subdivision-and-symmetry-observations).
Do not redesign the current two-analyzer setup solely to exercise this option.

The analog timing witness is a separate decision. Do not put `AMP_VOUT`,
`ANGLE_OUT`, or another slow analog signal directly into a CMOS port buffer.
Use a specified comparator front end if the digital capture needs that witness,
or keep amplitude/timing measurements on the existing analog connection/test
point. State comparator threshold, hysteresis, and delay when comparing old
analyzer-threshold captures with new ones. No divided high-voltage node belongs
on the digital connector, and the new connector has no `AIN*`/`AOUT*` tail.

## Migration and acceptance checklist

- [ ] Record the v1.0 adoption/fallback decision before fabrication release.
- [ ] Review/freeze the shared draft and marker indices; finish the horizontal
      buffer/connector block and a compatible new LA5032 adapter design.
- [ ] Allocate channels, identify exact tap nodes, review input logic levels,
      transitions, terminations, and switched/unpowered states.
- [ ] Place/route the integrated block; preserve unrelated board corrections.
      Re-export the netlist and verify every channel and OE connection.
- [ ] Review 50-pin placement, cable bend/latch access, pin-1 markings,
      retention, ground path, and source-damping/protection choices.
- [ ] Run new ERC/DRC and review fabrication outputs; existing clean reports
      do not cover this migration.
- [ ] Before laboratory use, continuity-check the actual cable and adapter;
      test capture with MCU held in reset, switched domains off, and power
      sequencing. There is no mute to test; instead confirm the OE pull-downs
      hold both inputs low across the rail's rise and fall. Use target-power-off
      cable changes unless separately qualified for hot plugging.
- [ ] Compare monitored operation with the cable attached and detached,
      including analog noise and simultaneous switching. Detaching is the only
      mute available, and it bounds the cable's contribution rather than the
      buffers' — they keep switching into their board-side traces and damping
      resistors — so treat a null result as inconclusive for the buffers and
      lift the 100 ohm resistors on suspect channels if it matters.
      Record qualified signal rate, cable length, delay/skew, and pulse limits.
- [ ] Verify beacon/capture maps and retain profile, overlay, board, adapter,
      cable, and instrument settings with the evidence.

Legacy allocation/bring-up documents remain useful for existing boards; their
default-high-Z buffer tests are not acceptance criteria for the new port.
Default-enabled observation does not establish animal-facing safety: shared
ground, cable faults, and supply disturbances still require system validation.
