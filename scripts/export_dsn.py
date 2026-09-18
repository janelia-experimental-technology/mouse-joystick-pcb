#!/usr/bin/env python3
"""Export the board to a Specctra DSN file for Freerouting.

`kicad-cli pcb export` has no Specctra subcommand -- the format is only reachable
through the GUI or through KiCad's `pcbnew` Python bindings. This uses the
bindings, which is also what the MCP server's autoroute tool does internally.

Written because the GUI export crashed. It does not: the same KiCad version
exports this board cleanly headless, so that crash is in the dialog, not the
board data.

    python3 scripts/export_dsn.py            # -> fab/autoroute/<board>.dsn

The DSN carries netclass track widths, clearances and per-class via padstacks,
plus any existing traces as pre-routed `wiring`. It does **not** carry
`.kicad_dru` custom rules -- Specctra has no way to express them -- so the
JLCPCB pad-to-pad, via, annular-ring, hole-to-hole and copper-to-edge floors are
invisible to the router. Re-check them with `make clearance-check` afterwards.
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys

REQUIRED_SECTIONS = ("parser", "resolution", "unit", "structure",
                     "placement", "library", "network", "wiring")


def validate(path: pathlib.Path) -> list[str]:
    """Structural checks on the exported file. Returns a list of problems."""
    problems: list[str] = []
    text = path.read_text()

    missing = [s for s in REQUIRED_SECTIONS
               if not re.search(rf"^  \({s}\b", text, re.M)]
    if missing:
        problems.append(f"missing section(s): {', '.join(missing)}")

    # Balance check. The `(string_quote ")` declaration has a bare quote as its
    # value, which derails naive quote tracking, so drop that line first.
    body = "\n".join(l for l in text.split("\n") if "(string_quote" not in l)
    depth, in_string = 0, False
    for char in body:
        if char == '"':
            in_string = not in_string
        elif not in_string:
            if char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
                if depth < 0:
                    problems.append("unbalanced parentheses (extra close)")
                    break
    if depth > 0:
        problems.append(f"unbalanced parentheses ({depth} unclosed) — truncated?")
    if in_string:
        problems.append("unterminated string")
    return problems


def main() -> int:
    root = pathlib.Path(__file__).resolve().parent.parent
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--pcb", type=pathlib.Path,
                    default=root / "kicad" / "mouse-joystick-pcb.kicad_pcb")
    ap.add_argument("--output", type=pathlib.Path, default=None,
                    help="default: fab/autoroute/<board>.dsn")
    args = ap.parse_args()

    if not args.pcb.is_file():
        print(f"no such board: {args.pcb}", file=sys.stderr)
        return 2

    out = args.output or root / "fab" / "autoroute" / f"{args.pcb.stem}.dsn"
    out.parent.mkdir(parents=True, exist_ok=True)

    try:
        import pcbnew
    except ImportError:
        print("pcbnew bindings not importable — run this inside the KiCad "
              "environment, e.g. `make export-dsn`", file=sys.stderr)
        return 2

    board = pcbnew.LoadBoard(str(args.pcb))
    zones = board.Zones()
    counts = {
        "footprints": len(board.GetFootprints()),
        "tracks": len(board.GetTracks()),
        "nets": board.GetNetCount(),
        "zones": len(zones),
    }
    print(f"KiCad {pcbnew.GetBuildVersion()}  board {args.pcb.name}")
    print("  " + "  ".join(f"{k}={v}" for k, v in counts.items()))

    if not pcbnew.ExportSpecctraDSN(board, str(out)):
        print("ExportSpecctraDSN reported failure", file=sys.stderr)
        return 1
    if not out.is_file() or out.stat().st_size == 0:
        print(f"no output produced at {out}", file=sys.stderr)
        return 1

    problems = validate(out)
    text = out.read_text()
    wires = len(re.findall(r"\n    \(wire\b", text))
    vias = len(re.findall(r"\n    \(via ", text))
    classes = len(re.findall(r"\n    \(class ", text))
    print(f"\nwrote {out}  ({out.stat().st_size:,} bytes)")
    print(f"  netclasses exported: {classes}")
    print(f"  pre-routed wiring:   {wires} wires, {vias} vias")

    if problems:
        print("\nVALIDATION FAILED:", file=sys.stderr)
        for problem in problems:
            print(f"  {problem}", file=sys.stderr)
        return 1
    print("  structure:           all sections present, parentheses balanced")

    if counts["zones"] == 0:
        print("\nNOTE: this board has no copper zones. Every GND connection will "
              "be routed\n      as a trace. Pour and refill before autorouting "
              "unless that is intended.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
