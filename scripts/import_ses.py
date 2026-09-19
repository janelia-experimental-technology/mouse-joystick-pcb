#!/usr/bin/env python3
"""Apply a Freerouting Specctra session (.ses) to the board without the GUI.

Pcbnew's File > Import > Specctra Session dialog crashes on this board. The
crash is in the dialog, not the session data: the same KiCad version applies
the same .ses cleanly through the `pcbnew` bindings, which is what this does.
Companion to `export_dsn.py`, which exists for the mirror-image GUI bug.

    python3 scripts/import_ses.py --dry-run    # report only, write nothing
    python3 scripts/import_ses.py              # apply in place, keep a backup

Why the dialog crashes here: KiCad's DSN exporter needs unique Specctra
component ids, so N footprints sharing one reference are exported as `REF**`,
`REF**_1`, `REF**_2`, ... Freerouting echoes those invented ids back in the
session `placement` block, and nothing on the board answers to them. Annotating
the offending footprints makes the GUI path work again; `--check-refs` reports
them. This script does not need the fix -- it skips unresolved placement
entries, which carry no routing.

The import replaces *all* tracks and vias with the session's, which is correct:
the DSN carried the pre-existing routing to the router and the session returns
it as `protect` wires. Footprint positions are asserted unchanged afterwards.

One KiCad defect is worked around here. The session carries a via's pad
diameter but not its drill, and on import KiCad drops the explicit drill rather
than reading it back out of the `Via[0-3]_<pad>:<drill>_um` padstack name, so
every via falls through to its netclass drill. Where a via was sized by hand
against a netclass that drills larger, the pad stays and the hole grows: on this
board seven 0.60/0.30 mm vias came back 0.60/0.50 and 0.60/0.40, under the
JLCPCB 0.125 mm annular ring floor. Vias that survive the round trip at the same
position get their original geometry back; `--no-restore-vias` turns that off.
"""

from __future__ import annotations

import argparse
import collections
import datetime
import pathlib
import shutil
import sys

LAYERS = ("F.Cu", "In1.Cu", "In2.Cu", "B.Cu")


def survey(board, pcbnew):
    """Counts that must be compared across the import."""
    tracks = collections.Counter()
    length = collections.Counter()
    geometry = {}
    vias = 0
    for item in board.GetTracks():
        if item.Type() == pcbnew.PCB_VIA_T:
            vias += 1
            pos = item.GetPosition()
            geometry[(pos.x, pos.y)] = (item.GetFrontWidth(), item.GetDrillValue())
            continue
        name = board.GetLayerName(item.GetLayer())
        tracks[name] += 1
        length[name] += item.GetLength() / 1e6
    return {
        "tracks": tracks,
        "length": length,
        "vias": vias,
        "geometry": geometry,
        "total": len(board.GetTracks()),
        "zones": len(board.Zones()),
        "placement": {f.GetReference(): (f.GetPosition().x, f.GetPosition().y,
                                         f.GetOrientationDegrees(), f.IsFlipped())
                      for f in board.GetFootprints()},
    }


def restore_vias(board, before, pcbnew):
    """Undo KiCad's netclass drill override on vias that predate the session."""
    restored = []
    for item in board.GetTracks():
        if item.Type() != pcbnew.PCB_VIA_T:
            continue
        pos = item.GetPosition()
        was = before["geometry"].get((pos.x, pos.y))
        if was is None:
            continue
        now = (item.GetFrontWidth(), item.GetDrillValue())
        if now == was:
            continue
        restored.append((item.GetNetname(), pos.x / 1e6, pos.y / 1e6, now, was))
        item.SetFrontWidth(was[0])
        item.SetDrill(was[1])
    return restored


def report_layers(before, after):
    print(f"{'layer':<8} {'tracks':>16} {'length (mm)':>22}")
    for layer in LAYERS:
        bt, at = before["tracks"][layer], after["tracks"][layer]
        bl, al = before["length"][layer], after["length"][layer]
        print(f"  {layer:<6} {bt:>6} -> {at:<6} {bl:>10.1f} -> {al:<10.1f}")
    print(f"  {'vias':<6} {before['vias']:>6} -> {after['vias']:<6}")


def check_refs(board):
    """Footprint references that will confuse the GUI Specctra round trip."""
    seen = collections.Counter(f.GetReference() for f in board.GetFootprints())
    return {ref: n for ref, n in seen.items()
            if n > 1 or not ref or "?" in ref or "*" in ref}


def main() -> int:
    root = pathlib.Path(__file__).resolve().parent.parent
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--pcb", type=pathlib.Path,
                    default=root / "kicad" / "mouse-joystick-pcb.kicad_pcb")
    ap.add_argument("--ses", type=pathlib.Path, default=None,
                    help="default: fab/autoroute/<board>.ses")
    ap.add_argument("--output", type=pathlib.Path, default=None,
                    help="default: overwrite --pcb in place")
    ap.add_argument("--dry-run", action="store_true",
                    help="import into memory and report, but write nothing")
    ap.add_argument("--check-refs", action="store_true",
                    help="only report references that break the GUI import")
    ap.add_argument("--no-restore-vias", action="store_true",
                    help="keep KiCad's netclass drill override on pre-existing vias")
    ap.add_argument("--no-backup", action="store_true")
    args = ap.parse_args()

    ses = args.ses or root / "fab" / "autoroute" / f"{args.pcb.stem}.ses"
    for path, what in ((args.pcb, "board"), (ses, "session")):
        if not path.is_file():
            print(f"no such {what}: {path}", file=sys.stderr)
            return 2

    try:
        import pcbnew
    except ImportError:
        print("pcbnew bindings not importable -- run this inside the KiCad "
              "environment, e.g. `make kicad-shell`", file=sys.stderr)
        return 2

    board = pcbnew.LoadBoard(str(args.pcb))
    print(f"KiCad {pcbnew.GetBuildVersion()}  board {args.pcb.name}  session {ses.name}")

    bad = check_refs(board)
    if bad:
        print("\nreferences the GUI Specctra import cannot resolve:")
        for ref, n in sorted(bad.items()):
            print(f"  {ref!r} x{n} -> exported as "
                  + ", ".join([ref] + [f"{ref}_{i}" for i in range(1, n)]))
        print("  annotate these to make Pcbnew's import dialog usable; this "
              "script skips them.")
    if args.check_refs:
        return 1 if bad else 0

    before = survey(board, pcbnew)
    if not pcbnew.ImportSpecctraSES(board, str(ses)):
        print("ImportSpecctraSES reported failure", file=sys.stderr)
        return 1

    restored = []
    if not args.no_restore_vias:
        restored = restore_vias(board, before, pcbnew)
        if restored:
            print(f"\nrestored {len(restored)} via(s) KiCad re-drilled from the netclass:")
            for net, x, y, now, was in restored:
                print("  %-24s (%.3f, %.3f)  %.2f/%.2f -> %.2f/%.2f mm"
                      % (net, x, y, now[0] / 1e6, now[1] / 1e6,
                         was[0] / 1e6, was[1] / 1e6))

    after = survey(board, pcbnew)

    print(f"\ntracks {before['total']} -> {after['total']}")
    report_layers(before, after)

    problems = []
    moved = [r for r, v in before["placement"].items()
             if after["placement"].get(r) != v]
    if moved:
        problems.append(f"import moved {len(moved)} footprint(s): "
                        + ", ".join(sorted(moved)[:8]))
    if after["total"] <= before["total"]:
        problems.append(f"no routing gained ({before['total']} -> {after['total']})")
    if after["zones"] != before["zones"]:
        problems.append(f"zone count changed {before['zones']} -> {after['zones']}")
    if problems:
        print("\nVALIDATION FAILED:", file=sys.stderr)
        for problem in problems:
            print(f"  {problem}", file=sys.stderr)
        return 1
    print("  placement unchanged, zones unchanged, routing gained")

    if args.dry_run:
        print("\n--dry-run: nothing written")
        return 0

    out = args.output or args.pcb
    if out == args.pcb and not args.no_backup:
        stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        backup = args.pcb.with_suffix(f".kicad_pcb.pre-ses-{stamp}")
        shutil.copy2(args.pcb, backup)
        print(f"\nbacked up to {backup.name}")
    board.Save(str(out))
    print(f"wrote {out}")
    print("\nNext: reopen in Pcbnew, then re-run DRC and `make clearance-check` -- "
          "the router never saw the .kicad_dru floors.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
