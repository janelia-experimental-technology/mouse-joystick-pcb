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

Post-processing
---------------
`pcbnew.ExportSpecctraDSN()` is faithful about most things and wrong about a few.
See `docs/routing-rescue-2026-09-21.md` for the corrected export geometry and
`docs/autoroute-log.md` for historical router measurements. The early
postprocessor had malformed plane nesting; its scores do not benchmark this
corrected version.

  --plane-fill        (default on)  Replace each `(plane ...)` outline with the
                      zone's real filled polygons plus `(window ...)` cutouts.
                      KiCad exports the zone OUTLINE, so a pour on a layer that
                      already carries traces tells the router "this whole
                      rectangle is solid GND" on top of live signal copper.
                      Unfracture polygons and nest windows inside planes,
                      with planes inside structure.

  --bridge-split-pads (default on)  A pad number used more than once in one
                      footprint -- an exposed pad plus its thermal via array --
                      exports as N separate terminals. Freerouting's
                      connectivity is graph-based, not geometric, so it tries to
                      route traces between vias that sit inside a single pad.
                      Emits protected wires only where a shared convex copper
                      pad contains the joining segment. Separate contacts with
                      the same number (e.g. BNC shell pins) are not bridged.

  --fit-pitch         (default off)  Reduce netclass clearance/width where the
                      class cannot physically escape the finest-pitch pad it has
                      to reach. Policy, not fidelity, so it is opt-in -- but it
                      is the single change that helped most. Measured: routed
                      five connections that had failed in every prior run.

  --protect-prerouted (default off)  Rewrite pre-routed `route` AND `fix` as
                      `(type protect)`. Do not use `fix`: KiCad's
                      "locked" flag exports as `fix` and cost 157 already-
                      connected pins in a measured run.
"""

from __future__ import annotations

import argparse
import collections
import math
import pathlib
import re
import sys

REQUIRED_SECTIONS = ("parser", "resolution", "unit", "structure",
                     "placement", "library", "network", "wiring")


def scope_spans(text: str):
    """Yield (scope path, start, end) while respecting quoted identifiers.

    Specctra's bare quote declaration is not a quoted string. Blank that line
    without shifting offsets so it cannot consume the rest of the document.
    """
    source = re.sub(r'(?m)^.*\(string_quote[^\n]*',
                    lambda m: ' ' * len(m.group()), text)
    stack = []
    quoted = escaped = False
    for i, char in enumerate(source):
        if quoted:
            if escaped:
                escaped = False
            elif char == '\\':
                escaped = True
            elif char == '"':
                quoted = False
        elif char == '"':
            quoted = True
        elif char == '(':
            match = re.match(r'\s*([^\s()]+)', source[i + 1:])
            if not match:
                raise ValueError('scope without a name')
            stack.append((match.group(1), i))
        elif char == ')':
            if not stack:
                raise ValueError('unbalanced parentheses (extra close)')
            path = tuple(name for name, _ in stack)
            _, start = stack.pop()
            yield path, start, i + 1
    if quoted or stack:
        raise ValueError('unterminated string or unclosed scope')


def replace_planes(text: str, fills: str) -> str:
    """Replace only structure's plane children and keep other scopes intact."""
    spans = list(scope_spans(text))
    for path, start, end in sorted(spans, key=lambda item: item[1], reverse=True):
        if path[-2:] == ('structure', 'plane'):
            text = text[:start] + text[end:]
    structure = next((s for s in scope_spans(text)
                      if s[0] == ('pcb', 'structure')), None)
    if structure is None:
        raise ValueError('missing pcb/structure scope')
    end = structure[2] - 1
    return text[:end] + '\n' + fills + '\n  ' + text[end:]

# DSN is written with `(resolution um 10)`: coordinates are micrometres with one
# decimal, and y is negated relative to KiCad.
def _x(nm: int) -> str:
    return f"{nm / 1000:.1f}".rstrip("0").rstrip(".")


def _y(nm: int) -> str:
    return f"{-nm / 1000:.1f}".rstrip("0").rstrip(".")


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
    try:
        for path, _, _ in scope_spans(text):
            if path[-1] == 'plane' and path != ('pcb', 'structure', 'plane'):
                problems.append('plane outside pcb/structure')
            if path[-1] == 'window' and path[-2] not in (
                    'plane', 'keepout', 'wire_keepout', 'via_keepout', 'wire'):
                problems.append('window outside an area scope')
    except ValueError as exc:
        problems.append(str(exc))
    return problems


def real_plane_fills(board, pcbnew) -> tuple[str, int]:
    """Specctra `(plane ...)` blocks built from the zones' actual fill polygons.

    KiCad emits the zone outline. That is a lie on any layer that also carries
    traces, and Freerouting throws NullPointerExceptions when it tries to
    reconcile solid plane copper with signal copper in the same place.
    """
    out, n = [], 0
    for zone in board.Zones():
        if zone.GetIsRuleArea() or not zone.IsOnCopperLayer():
            continue
        net = zone.GetNetname()
        if not net:
            continue
        for layer in zone.GetLayerSet().CuStack():
            try:
                polys = zone.GetFilledPolysList(layer)
            except Exception:
                continue
            if polys is None or polys.OutlineCount() == 0:
                continue
            # KiCad stores filled areas fractured: holes are joined to the
            # outline with zero-width slits. Specctra wants separate windows.
            # Work on a clone so exporting does not change the board's fill.
            polys = polys.CloneDropTriangulation()
            polys.Unfracture()
            name = board.GetLayerName(layer)
            for i in range(polys.OutlineCount()):
                chain = polys.Outline(i)
                pts = " ".join(
                    f"{_x(chain.CPoint(j).x)} {_y(chain.CPoint(j).y)}"
                    for j in range(chain.PointCount()))
                block = [f'    (plane "{net}" (polygon {name} 0  {pts})']
                for h in range(polys.HoleCount(i)):
                    hole = polys.Hole(i, h)
                    hpts = " ".join(
                        f"{_x(hole.CPoint(j).x)} {_y(hole.CPoint(j).y)}"
                        for j in range(hole.PointCount()))
                    block.append(f'      (window (polygon {name} 0  {hpts}))')
                block.append('    )')
                out.append("\n".join(block))
                n += 1
    return "\n".join(out), n


def bridge_split_pads(board, pcbnew) -> tuple[list[str], int]:
    """Protected wires inside overlapping same-number, same-net convex pads.

    An exposed pad and its thermal via array are one piece of copper, but each
    instance exports as its own terminal and Freerouting will not infer the
    connection from geometric overlap.
    """
    wires, bridged = [], 0
    for fp in board.GetFootprints():
        groups = collections.defaultdict(list)
        for pad in fp.Pads():
            num = pad.GetNumber()
            if num:
                groups[num].append(pad)
        for num, pads in groups.items():
            if len(pads) < 2:
                continue
            net = pads[0].GetNetname()
            if not net:
                continue
            # Repeated pad numbers do NOT imply overlapping copper. BNC shell
            # pads, for example, surround a signal pin: star-connecting their
            # centres draws a ground short straight through that signal pad.
            # Only join centres wholly contained in a convex copper pad.
            # This permits thermal-via/EP bridges while leaving separated
            # connector contacts for the real router.
            pads.sort(key=lambda p: -(p.GetSize().x * p.GetSize().y))
            connected = set()
            for pad in pads:
                if pad.GetNetname() != net:
                    continue
                p = pad.GetPosition()
                pair = None
                for anchor in pads:
                    if anchor is pad or anchor.GetNetname() != net:
                        continue
                    for layer in (pcbnew.F_Cu, pcbnew.B_Cu):
                        if not (anchor.IsOnLayer(layer) and pad.IsOnLayer(layer)):
                            continue
                        if anchor.GetShape(layer) not in (
                                pcbnew.PAD_SHAPE_RECT, pcbnew.PAD_SHAPE_ROUNDRECT,
                                pcbnew.PAD_SHAPE_CIRCLE, pcbnew.PAD_SHAPE_OVAL):
                            continue
                        if (anchor.HitTest(anchor.GetPosition(), -50000, layer)
                                and anchor.HitTest(p, -50000, layer)):
                            pair = anchor, layer
                            break
                    if pair:
                        break
                if pair is None:
                    continue
                anchor, layer = pair
                apos = anchor.GetPosition()
                key = tuple(sorted(((apos.x, apos.y), (p.x, p.y)))) + (layer,)
                if key in connected or (p.x == apos.x and p.y == apos.y):
                    continue
                connected.add(key)
                wires.append(
                    f'    (wire (path {board.GetLayerName(layer)} 100  '
                    f'{_x(apos.x)} {_y(apos.y)}  {_x(p.x)} {_y(p.y)})'
                    f'(net "{net}")(type protect))')
                bridged += 1
    return wires, bridged


def fit_pitch(text: str) -> tuple[str, list[str]]:
    """Shrink netclass clearance/width that cannot escape its finest-pitch pad.

    Reports what it changed; the caller prints it. Only ever reduces.
    """
    notes: list[str] = []
    nw = text[text.index("(network"):text.index("(wiring")]
    for m in re.finditer(r"\(class\s+(\S+)", nw):
        name = m.group(1)
        blk = _sexp(nw, m.start())
        w = re.search(r"\(width\s+([\d.]+)\)", blk)
        c = re.search(r"\(clearance\s+([\d.]+)\)", blk)
        if not (w and c):
            continue
        width, clear = float(w.group(1)), float(c.group(1))
        need = _min_pitch_for_class(text, name)
        if need is None:
            continue
        # A trace leaving a pad must clear the neighbour: pitch - nbr/2 - w/2 >= c
        avail = need
        if avail - width / 2 - clear >= 0:
            continue
        new_w = min(width, 300.0)
        new_c = max(100.0, min(clear, avail - new_w / 2))
        if new_c >= clear and new_w >= width:
            continue
        new_blk = re.sub(r"\(width\s+[\d.]+\)", f"(width {new_w:.0f})", blk)
        new_blk = re.sub(r"\(clearance\s+[\d.]+\)",
                         f"(clearance {new_c:.0f})", new_blk)
        text = text.replace(blk, new_blk, 1)
        notes.append(f"{name}: width {width:.0f}->{new_w:.0f} um, "
                     f"clearance {clear:.0f}->{new_c:.0f} um")
    return text, notes


def _sexp(text: str, start: int) -> str:
    depth = 0
    for i in range(start, len(text)):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
    return text[start:]


def _padstack_extents(lib: str) -> dict[str, tuple[float, float]]:
    """Bounding box (w, h) in um for every padstack in the library section."""
    dims: dict[str, tuple[float, float]] = {}
    for m in re.finditer(r"\(padstack\s+(\S+)", lib):
        b = _sexp(lib, m.start())
        poly = re.search(r"\(polygon\s+\S+\s+[\d.]+\s+([-\d.\s]+)\)", b)
        rect = re.search(r"\(rect\s+\S+\s+(-?[\d.]+)\s+(-?[\d.]+)"
                         r"\s+(-?[\d.]+)\s+(-?[\d.]+)\)", b)
        circ = re.search(r"\(circle\s+\S+\s+([\d.]+)", b)
        if poly:
            v = [float(x) for x in poly.group(1).split()]
            dims[m.group(1).strip('"')] = (max(v[0::2]) - min(v[0::2]),
                                           max(v[1::2]) - min(v[1::2]))
        elif rect:
            dims[m.group(1).strip('"')] = (
                abs(float(rect.group(3)) - float(rect.group(1))),
                abs(float(rect.group(4)) - float(rect.group(2))))
        elif circ:
            d = float(circ.group(1))
            dims[m.group(1).strip('"')] = (d, d)
    return dims


def _min_pitch_for_class(text: str, cls: str) -> float | None:
    """Usable escape corridor, in um, at the tightest pad this class reaches.

    Returns `distance - neighbour_extent_toward_us` for the worst pad, which is
    the room a trace centred on the pad has before it must satisfy clearance.
    The caller still subtracts half the track width. None when nothing matches.
    """
    lib = text[text.index("(library"):text.index("(network")]
    nw = text[text.index("(network"):text.index("(wiring")]
    blk = _sexp(nw, nw.index(f"(class {cls} "))
    nets = set(blk.split("(circuit")[0].replace(f"(class {cls}", "").split())
    if not nets:
        return None
    refs = set()
    for m in re.finditer(r"\(net\s+(\S+)\s*\(pins([^)]*)\)", nw):
        if m.group(1) in nets or m.group(1).strip('"') in {n.strip('"') for n in nets}:
            refs.update(p.rsplit("-", 1)[0] for p in m.group(2).split())
    if not refs:
        return None
    pl = text[text.index("(placement"):text.index("(library")]
    imgs = set()
    for m in re.finditer(r"\(component\s+(\S+)", pl):
        b = _sexp(pl, m.start())
        if any(re.search(rf"\(place {re.escape(r)}\s", b) for r in refs):
            imgs.add(m.group(1).strip('"'))
    dims = _padstack_extents(lib)
    best = None
    for img in imgs:
        try:
            b = _sexp(lib, lib.index(f'(image "{img}"'))
        except ValueError:
            try:
                b = _sexp(lib, lib.index(f"(image {img}"))
            except ValueError:
                continue
        pins = [(pm.group(1).strip('"'), pm.group(2),
                 float(pm.group(3)), float(pm.group(4)))
                for pm in re.finditer(
                    r"\(pin\s+(\S+)\s+(?:\(rotate[^)]*\)\s*)?([^\s)]+)"
                    r"\s+(-?[\d.]+)\s+(-?[\d.]+)\)", b)]
        for _, num, x, y in pins:
            near = [(math.hypot(ox - x, oy - y), ops, ox - x, oy - y)
                    for ops, onum, ox, oy in pins
                    if onum.split("@")[0] != num.split("@")[0]
                    and math.hypot(ox - x, oy - y) > 0]
            if not near:
                continue
            near.sort()
            # Only the in-row neighbours constrain a radial escape; anything
            # much further away is behind the pad, not beside it.
            for d, ops, dx, dy in near:
                if d > near[0][0] * 1.3:
                    break
                w, h = dims.get(ops, (0.0, 0.0))
                extent = abs(dx / d) * w / 2 + abs(dy / d) * h / 2
                room = d - extent
                if best is None or room < best:
                    best = room
    return best


def main() -> int:
    root = pathlib.Path(__file__).resolve().parent.parent
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--pcb", type=pathlib.Path,
                    default=root / "kicad" / "mouse-joystick-pcb.kicad_pcb")
    ap.add_argument("--output", type=pathlib.Path, default=None,
                    help="default: fab/autoroute/<board>.dsn")
    ap.add_argument("--no-plane-fill", action="store_true",
                    help="keep KiCad's zone-outline planes (see module docstring)")
    ap.add_argument("--refill", action="store_true",
                    help="refill zones in memory before export (source board unchanged)")
    ap.add_argument("--no-bridge-split-pads", action="store_true",
                    help="do not join pads sharing a pad number")
    ap.add_argument("--fit-pitch", action="store_true",
                    help="shrink netclass geometry that cannot escape its pads")
    ap.add_argument("--protect-prerouted", action="store_true",
                    help="mark pre-routed wiring (including locked tracks) protect")
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
    if args.refill:
        pcbnew.ZONE_FILLER(board).Fill(board.Zones())
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

    # --- post-processing -------------------------------------------------
    text = out.read_text()
    applied: list[str] = []

    if not args.no_plane_fill and re.search(r"\n\s*\(plane\b", text):
        fills, n = real_plane_fills(board, pcbnew)
        if n:
            text = replace_planes(text, fills)
            applied.append(f"plane-fill: {n} real filled polygon(s) "
                           f"replacing zone outlines")

    if not args.no_bridge_split_pads:
        bridges, n = bridge_split_pads(board, pcbnew)
        if n:
            idx = text.rindex("\n  )")           # close of (wiring ...)
            text = text[:idx] + "\n" + "\n".join(bridges) + text[idx:]
            applied.append(f"bridge-split-pads: {n} wire(s) joining pads that "
                           f"share a pad number")

    if args.fit_pitch:
        text, notes = fit_pitch(text)
        for note in notes:
            applied.append(f"fit-pitch: {note}")

    if args.protect_prerouted:
        text, n = re.subn(r"\(type (?:route|fix)\)", "(type protect)", text)
        applied.append(f"protect-prerouted: {n} item(s) marked protect")

    out.write_text(text)

    problems = validate(out)
    wires = len(re.findall(r"\n    \(wire\b", text))
    vias = len(re.findall(r"\n    \(via ", text))
    classes = len(re.findall(r"\n    \(class ", text))
    print(f"\nwrote {out}  ({out.stat().st_size:,} bytes)")
    print(f"  netclasses exported: {classes}")
    print(f"  pre-routed wiring:   {wires} wires, {vias} vias")
    for note in applied:
        print(f"  {note}")

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
