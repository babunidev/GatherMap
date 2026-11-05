#!/usr/bin/env python3
"""Audit or create a development-only Forever addon ZIP.

No tags, releases, uploads, CurseForge operations or network calls.
Usage:
  python3 tools/check_forever_package.py
  python3 tools/check_forever_package.py --output /tmp/GatherMap-forever-dev.zip
"""
from __future__ import annotations
import argparse
import re
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "GatherMap_Camelot.toc"
ADDON_NAME = "GatherMap"
INTERFACE = "16001"
MARKER_COLORS = ("red", "orange", "yellow", "green", "gray", "purple")
MARKER_FILES = [f"Textures/Markers/marker_{color}.tga" for color in MARKER_COLORS]
RUNTIME_FILES = [
    "GatherMapData.lua",
    "GatherMapMarkers.lua",
    "GatherMapSpatial.lua",
    "GatherMapDifficulty.lua",
    "GatherMapMigration.lua",
    "GatherMapForever.lua",
    "GatherMapWorldPins.xml",
    "GatherMapCapture.lua",
]


def verify():
    toc = MANIFEST.read_text(encoding="utf-8")
    assert re.search(r"^## Interface:\s*16001\s*$", toc, re.M), "Forever interface mismatch"
    assert re.search(r"^## SavedVariables:\s*GatherMapDB\s*$", toc, re.M)
    assert re.search(r"^## Version:\s*0\.5\.0-alpha\s*$", toc, re.M)
    files = [x.strip() for x in toc.splitlines() if x.strip() and not x.startswith("##")]
    assert files == RUNTIME_FILES, "manifest load order differs from tested Forever runtime"
    assert files.index("GatherMapForever.lua") < files.index("GatherMapWorldPins.xml"), (
        "the global world-pin mixin must exist before XML references it"
    )
    for path in files:
        assert (ROOT / path).is_file(), f"missing addon file: {path}"
    source = (ROOT / "GatherMapData.lua").read_text(encoding="utf-8")
    referenced = set(re.findall(r'iconRoot\s*\.\.\s*"(Herb[A-Za-z]+)"', source))
    icons = sorted((ROOT / "Icons").glob("Herb*.tga"))
    names = {icon.stem for icon in icons}
    assert len(icons) == 29, "original resource art inventory changed"
    assert referenced <= names, "missing resource textures: " + ", ".join(sorted(referenced-names))
    assert all(icon.stat().st_size > 18 for icon in icons), "empty or malformed TGA assets"
    marker_runtime = (ROOT / "GatherMapForever.lua").read_text(encoding="utf-8")
    assert 'DOT_SIZE, MIN_INDEX_NODES = 300, 6, 128' in marker_runtime, (
        "textured four-corner marker dimensions changed"
    )
    assert 'markerRoot = "Interface\\\\AddOns\\\\GatherMap\\\\Textures\\\\Markers\\\\marker_"' in marker_runtime
    assert 'markerRoot.."purple.tga"' in marker_runtime, "unknown color fallback missing"
    for color in MARKER_COLORS:
        assert f'markerRoot.."{color}.tga"' in marker_runtime, (
            f"marker texture {color} is not referenced by the UI"
        )
    marker_paths = [ROOT / name for name in MARKER_FILES]
    for path in marker_paths:
        assert path.is_file(), f"missing marker art: {path.relative_to(ROOT)}"
        raw = path.read_bytes()
        assert len(raw) >= 18 + 16 * 16 * 4, (
            f"truncated RGBA marker: {path.relative_to(ROOT)}"
        )
        # Uncompressed 16x16, 32-bit TGA with 8-bit alpha (no Pillow dependency).
        assert raw[2] == 2 and raw[16] == 32 and raw[17] & 15 == 8
        assert int.from_bytes(raw[12:14], "little") == 16
        assert int.from_bytes(raw[14:16], "little") == 16
    paths = [MANIFEST] + [ROOT / f for f in files] + icons + marker_paths
    assert len(paths) == len({p.relative_to(ROOT).as_posix() for p in paths})
    assert all(p.is_file() and p.stat().st_size > 0 for p in paths)
    assert all(p.suffix.lower() in (".toc", ".lua", ".xml", ".tga") for p in paths)
    return paths


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="Optional local development ZIP path")
    args = parser.parse_args()
    paths = verify()
    print(f"PASS: Forever {INTERFACE} manifest, {len(paths)} installable files, "
          "29 existing herb icons and 6 new RGBA marker textures; "
          "no legacy runtime or TOC included")
    print("NOTE: Source/API compliance, artwork licensing and gameplay remain unverified.")
    if args.output:
        target = args.output.expanduser().resolve()
        assert target.suffix.lower() == ".zip", "output must be a .zip"
        assert target != ROOT, "invalid output location"
        target.parent.mkdir(parents=True, exist_ok=True)
        with ZipFile(target, "w", ZIP_DEFLATED) as archive:
            for path in paths:
                archive.write(path, f"{ADDON_NAME}/{path.relative_to(ROOT).as_posix()}")
        with ZipFile(target) as archive:
            assert archive.testzip() is None, "ZIP integrity test failed"
            members = archive.namelist()
            assert len(members) == len(paths)
            assert all(name.startswith(f"{ADDON_NAME}/") for name in members)
            assert not any(name.endswith("/GatherMap.lua") or
                           name.endswith("/GatherMap.toc") for name in members)
        print(f"Development-only ZIP created: {target}")
        print("NOT APPROVED FOR PUBLICATION; packaging is not a release.")


if __name__ == "__main__":
    main()
