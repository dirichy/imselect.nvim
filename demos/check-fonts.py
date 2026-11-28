#!/usr/bin/env python3
"""Check demo text against explicit font files or the recording environment."""

import json
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
output = root / "demos/output/font-verification.json"
output.parent.mkdir(parents=True, exist_ok=True)
report = {"verified": False, "fonts": [], "missing": []}
output.write_text(json.dumps(report))
try:
    fonts = sys.argv[1:] or sorted(
        {
            subprocess.check_output(
                ["fc-match", "-f", "%{file}", family], text=True
            ).strip()
            for family in ("monospace", "Noto Sans", "Noto Sans CJK SC", "Sans Bold")
        }
    )
    supported = set()
    for font in fonts:
        charset = subprocess.check_output(
            ["fc-query", "-f", "%{charset}\n", font], text=True
        )
        for span in charset.split():
            ends = span.split("-")
            supported.update(range(int(ends[0], 16), int(ends[-1], 16) + 1))
        report["fonts"].append(
            {
                "file": font,
                "version": subprocess.check_output(
                    ["fc-query", "-f", "%{family}: %{fontversion}\n", font], text=True
                ).strip(),
            }
        )
    # Candidate alternatives seen in the recordings, plus Screenkey/UI symbols.
    text = "能量能力能史沧你好妳逆号拟…⏎␣\u2009◀▶"
    for name in ("init.lua", "record.py"):
        text += (root / "demos" / name).read_text()
    required = {ord(char) for char in text if not char.isspace()}
    report["missing"] = [
        f"U+{point:04X} {chr(point)}" for point in sorted(required - supported)
    ]
    report["characters_checked"] = len(required)
    assert not report["missing"], "Missing glyphs: " + ", ".join(report["missing"])
    report["verified"] = True
finally:
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2))
print(f"Font coverage verified: {len(required)} characters, {len(fonts)} font files")
