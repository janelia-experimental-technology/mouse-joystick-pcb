#!/usr/bin/env python3
"""Clearance regression check for a board whose DRC ignores clearance.

`mouse-joystick-pcb` sets `rule_severities.clearance` to `ignore`, because the
design blocks it is composed from were authored to an older 0.10 mm floor and
reporting ~500 advisories buries every other DRC finding. See
`docs/interface-map.md` and the comment block in `mouse-joystick-pcb.kicad_dru`.

That is fine for hand-routing and wrong for autorouting: Freerouting's
characteristic failure is clearance violations, and this board cannot report
one. This script restores the check without disturbing the project.

It works on a **copy**. The real `.kicad_pro` is never modified.

    # once, before routing
    python3 scripts/clearance_check.py --save-baseline

    # after routing, or any time
    python3 scripts/clearance_check.py

Exit status is non-zero when clearance findings are new or have worsened, so it
can gate a fabrication step.

**KiCad's DRC is not fully deterministic, and this check is built around that.**
Measured on this board, 2026-09-18: three consecutive runs on identical copper
gave 499 clearance findings every time, but attributed them across 149, 151 and
148 net pairs, and 10 of ~270 reported positions moved. Where several nets crowd
together the engine picks a different counterpart item each run. A naive diff
therefore invents regressions.

What is stable, verified over three runs:

* the **total** clearance count,
* the **voltage-bearing** subset -- every pair, count and tightest gap identical,
* the unconnected count and the non-clearance violation tallies.

So those are what gate the check. **Caveat on the total, measured 2026-09-18:**
it is reproducible run-to-run but it is a coarse signal. Adding a DRU rule that
demonstrably suppressed five findings left the total at 499, because jitter
surfaced five elsewhere in the same run. Treat a rise as real; do not read a
flat total as proof that nothing moved. The voltage-bearing subset is the gate
that actually responded correctly to that change (12 findings -> 6). There is no
violation cap -- suppressing all clearance rules yields 0, so the engine is
reporting everything it finds. The full per-pair breakdown is printed for
orientation but never fails the build, because its jitter is an artefact of the
tool rather than a change in the board.
"""

from __future__ import annotations

import argparse
import collections
import fnmatch
import json
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

# The netclasses whose spacing carries real voltage. Kept identical to the
# "Voltage-bearing clearance is an error" rule in the kicad-libs mining project
# so both places mean the same thing. A finding on one of these is always
# listed in full, however small the delta.
VOLTAGE_BEARING = {
    "PWR_HV_ENTRY", "PWR_HV_BUS", "PWR_HV_RETURN", "PWR_HV_LOCAL",
    "MOTOR_2A", "BRIDGE_MID", "BOOTSTRAP", "GATE_DRIVE",
    "PWR_12V", "PWR_12V_LOCAL",
}

NET_RE = re.compile(r"\[([^\]]+)\]")
GAP_RE = re.compile(r"clearance ([\d.]+) mm; actual ([\d.]+) mm")


def resolve_netclass(net: str, patterns: list[dict]) -> str:
    """Resolve a net to its class the way KiCad does: last matching pattern wins."""
    found = "Default"
    for entry in patterns:
        if fnmatch.fnmatchcase(net, entry["pattern"]):
            found = entry["netclass"]
    return found


def run_drc(pcb: pathlib.Path, kicad_cli: str, workdir: pathlib.Path) -> dict:
    """Copy the project, force clearance to `error`, and run DRC on the copy."""
    stem = pcb.stem
    for suffix in (".kicad_pcb", ".kicad_pro", ".kicad_dru", ".kicad_prl"):
        src = pcb.with_suffix(suffix)
        if src.is_file():
            shutil.copy2(src, workdir / src.name)

    pro = workdir / f"{stem}.kicad_pro"
    data = json.loads(pro.read_text())
    severities = data["board"]["design_settings"].setdefault("rule_severities", {})
    was = severities.get("clearance")
    severities["clearance"] = "error"
    pro.write_text(json.dumps(data, indent=2))

    report = workdir / "drc.json"
    subprocess.run(
        # --refill-zones matters as soon as the board has copper pours: a stale
        # fill would hide or invent clearance findings. Safe without
        # --save-board, and this is a copy regardless.
        # --all-track-errors is load-bearing, not cosmetic. Without it KiCad
        # reports only the first violation per track and which one it picks
        # varies between runs on an unchanged board, so a diff against a
        # baseline produced three phantom regressions. Measured 2026-09-18.
        [kicad_cli, "pcb", "drc", "--format", "json", "--units", "mm",
         "--severity-all", "--all-track-errors", "--refill-zones",
         "--output", str(report), str(workdir / pcb.name)],
        check=True, capture_output=True, text=True,
    )
    result = json.loads(report.read_text())
    result["_clearance_was"] = was
    return result


def summarise(drc: dict, patterns: list[dict]) -> dict:
    """Reduce a DRC report to a position-independent clearance fingerprint."""
    pairs: dict[str, dict] = {}
    other = collections.Counter()

    for violation in drc.get("violations", []):
        if violation.get("type") != "clearance":
            other[f"{violation.get('severity')} {violation.get('type')}"] += 1
            continue

        nets = []
        for item in violation.get("items", []):
            nets += NET_RE.findall(item.get("description", ""))
        # keep the full path for netclass resolution, show the leaf
        classes = {resolve_netclass(n if n.startswith("/") else "/" + n, patterns)
                   for n in nets}
        leaves = sorted({n.split("/")[-1] for n in nets})
        key = " <-> ".join(leaves) if leaves else "(unknown)"

        gap = GAP_RE.search(violation.get("description", ""))
        actual = float(gap.group(2)) if gap else 0.0
        required = float(gap.group(1)) if gap else 0.0

        entry = pairs.setdefault(key, {
            "count": 0, "min_actual": actual, "required": required,
            "voltage_bearing": bool(classes & VOLTAGE_BEARING),
        })
        entry["count"] += 1
        entry["min_actual"] = min(entry["min_actual"], actual)
        entry["required"] = max(entry["required"], required)
        entry["voltage_bearing"] |= bool(classes & VOLTAGE_BEARING)

    # kicad-cli's schema (drc.v1.json) carries `unconnected_items` as a list and
    # has no `unconnected_count`; the MCP server adds that key. Accept either, and
    # never fall back to 0 silently — a wrong zero here would mask an unfinished
    # route, which is the main thing this check exists to catch.
    if "unconnected_items" in drc:
        unconnected = len(drc["unconnected_items"])
    elif "unconnected_count" in drc:
        unconnected = drc["unconnected_count"]
    else:
        raise KeyError("DRC report has neither unconnected_items nor unconnected_count")

    return {
        "clearance_total": sum(p["count"] for p in pairs.values()),
        "hv_pairs": {k: v for k, v in pairs.items() if v["voltage_bearing"]},
        "pairs": pairs,
        "other_violations": dict(other),
        "unconnected": unconnected,
        # each entry is {"key": ..., "description": ...}
        "ignored_checks": sorted(c.get("key", str(c)) for c in drc.get("ignored_checks", [])),
    }


def compare(base: dict, now: dict) -> tuple[list[str], list[str]]:
    """Return (regressions, notes).

    Only the dimensions shown to be reproducible gate the result; see the module
    docstring. Non-voltage-bearing per-pair movement is reported as a note.
    """
    regressions, notes = [], []

    if now["clearance_total"] > base["clearance_total"]:
        regressions.append(
            f"clearance findings rose {base['clearance_total']} -> "
            f"{now['clearance_total']}")
    elif now["clearance_total"] < base["clearance_total"]:
        notes.append(f"clearance findings fell {base['clearance_total']} -> "
                     f"{now['clearance_total']}")

    bhv, nhv = base.get("hv_pairs", {}), now["hv_pairs"]
    for key, cur in sorted(nhv.items()):
        old = bhv.get(key)
        if old is None:
            regressions.append(
                f"NEW voltage-bearing  {key}: {cur['count']} finding(s), tightest "
                f"{cur['min_actual']:.4f} mm against {cur['required']:.4f} mm")
        elif cur["count"] > old["count"]:
            regressions.append(
                f"MORE voltage-bearing {key}: {old['count']} -> {cur['count']}")
        elif cur["min_actual"] < old["min_actual"] - 1e-9:
            regressions.append(
                f"TIGHTER voltage-bearing {key}: {old['min_actual']:.4f} -> "
                f"{cur['min_actual']:.4f} mm")
    for key, old in sorted(bhv.items()):
        if key not in nhv:
            notes.append(f"voltage-bearing pair cleared: {key}")

    if now["unconnected"] > base["unconnected"]:
        regressions.append(
            f"unconnected rose {base['unconnected']} -> {now['unconnected']}")
    elif now["unconnected"] < base["unconnected"]:
        notes.append(f"unconnected fell {base['unconnected']} -> {now['unconnected']}")

    for kind, count in sorted(now["other_violations"].items()):
        was = base["other_violations"].get(kind, 0)
        if count > was:
            regressions.append(f"MORE {kind}: {was} -> {count}")

    # informational only: attribution here jitters between runs
    bp, np_ = base.get("pairs", {}), now["pairs"]
    appeared = sorted(set(np_) - set(bp) - set(nhv))
    if appeared:
        notes.append(f"{len(appeared)} low-voltage pair(s) newly attributed "
                     f"(tool jitter unless the total also rose): "
                     + ", ".join(appeared[:5]) + (" ..." if len(appeared) > 5 else ""))
    return regressions, notes


def main() -> int:
    here = pathlib.Path(__file__).resolve().parent.parent
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--pcb", type=pathlib.Path,
                    default=here / "kicad" / "mouse-joystick-pcb.kicad_pcb")
    ap.add_argument("--baseline", type=pathlib.Path,
                    default=here / "kicad" / "clearance-baseline.json")
    ap.add_argument("--save-baseline", action="store_true",
                    help="write the current state as the baseline and exit 0")
    ap.add_argument("--kicad-cli", default="kicad-cli")
    args = ap.parse_args()

    if not args.pcb.is_file():
        print(f"no such board: {args.pcb}", file=sys.stderr)
        return 2

    project = json.loads(args.pcb.with_suffix(".kicad_pro").read_text())
    patterns = project.get("net_settings", {}).get("netclass_patterns", [])

    with tempfile.TemporaryDirectory(prefix="clearance-check-") as tmp:
        drc = run_drc(args.pcb, args.kicad_cli, pathlib.Path(tmp))
    now = summarise(drc, patterns)

    live = drc.get("_clearance_was")
    print(f"clearance severity in the real project: {live}"
          + ("   (checked here at 'error' on a copy)" if live != "error" else ""))
    print(f"clearance findings: {now['clearance_total']} "
          f"across {len(now['pairs'])} net pairs")
    print(f"unconnected items:  {now['unconnected']}"
          + ("" if now["unconnected"] else "   (routing complete)"))
    if now["ignored_checks"]:
        print(f"still ignored by this project: {', '.join(now['ignored_checks'])}")

    hv = {k: v for k, v in now["pairs"].items() if v["voltage_bearing"]}
    print(f"\nvoltage-bearing net pairs: {len(hv)} "
          f"({sum(v['count'] for v in hv.values())} findings)")
    for key, val in sorted(hv.items(), key=lambda kv: kv[1]["min_actual"]):
        print(f"  {val['min_actual']:7.4f} mm vs {val['required']:.4f} mm "
              f"required, x{val['count']:<3d} {key}")

    if args.save_baseline:
        args.baseline.write_text(json.dumps(now, indent=2, sort_keys=True) + "\n")
        print(f"\nbaseline written: {args.baseline}")
        return 0

    if not args.baseline.is_file():
        print(f"\nno baseline at {args.baseline} — run with --save-baseline first",
              file=sys.stderr)
        return 2

    base = json.loads(args.baseline.read_text())
    regressions, notes = compare(base, now)

    print(f"\nbaseline: {base['clearance_total']} findings / "
          f"{len(base['pairs'])} pairs, {base['unconnected']} unconnected")
    for note in notes:
        print(f"  {note}")
    if regressions:
        print(f"\nREGRESSIONS ({len(regressions)}):")
        for reg in regressions:
            print(f"  {reg}")
        return 1
    print("\nno new or worsened clearance findings")
    return 0


if __name__ == "__main__":
    sys.exit(main())
