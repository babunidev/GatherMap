"""Static safety tests for GatherMap's Forever-only development manifest.

These do not replace Lua syntax, API behavior, or in-game verification.
Run from repo root: python3 -m unittest discover -s tests -p 'test_forever_*.py'
"""
from pathlib import Path
import re
import shutil
import subprocess
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "GatherMap_Camelot.toc"
RUNTIME = ROOT / "GatherMapForever.lua"
DATA = ROOT / "GatherMapData.lua"
XML = ROOT / "GatherMapWorldPins.xml"


class ForeverCompatibilityTests(unittest.TestCase):
    def test_manifest_and_load_order(self):
        text = MANIFEST.read_text()
        self.assertIn("## Interface: 16001", text)
        self.assertIn("## SavedVariables: GatherMapDB", text)
        self.assertNotIn("OptionalDeps: Interact", text)
        files = [line.strip() for line in text.splitlines()
                 if line.strip() and not line.lstrip().startswith("##")]
        self.assertEqual(files, [DATA.name, XML.name, RUNTIME.name])
        for name in files:
            self.assertTrue((ROOT / name).is_file(), name)
        self.assertNotIn("GatherMap.lua", files)

    def test_legacy_manifest_not_converted(self):
        old = (ROOT / "GatherMap.toc").read_text()
        self.assertIn("## Interface: 11200", old)
        self.assertIn("## Version: 0.4.3", old)
        self.assertIn("GatherMap.lua", old)

    def test_provider_template(self):
        root = ET.parse(XML).getroot()
        template = next((element for element in root.iter()
                         if element.attrib.get("name") ==
                         "GatherMapForeverWorldPinTemplate"), None)
        self.assertIsNotNone(template)
        self.assertEqual(template.attrib["mixin"],
                         "GatherMapForeverWorldPinMixin")

    def test_uses_modern_apis_and_preserves_legacy_data(self):
        source = RUNTIME.read_text()
        for symbol in (
            "C_SkillInfo.GetSkillLineInfoByID",
            "C_Map.GetBestMapForUnit",
            "C_Map.GetPlayerMapPosition",
            "C_Map.GetWorldPosFromMapPos",
            "C_Minimap.GetViewRadius",
            "MapCanvasPinMixin",
            "MapCanvasDataProviderMixin",
            'db.nodes["map:"..mapID]',
        ):
            self.assertIn(symbol, source)
        for forbidden in (
            "InstallInteractHook", "WORLD_MAP_UPDATE",
            "SPELLCAST_STOP", "GetCurrentMapContinent",
            "SetMapZoom(", 'GetPlayerMapPosition("player")',
        ):
            self.assertNotIn(forbidden, source)
        self.assertIn("function(self,event,loaded)", source)
        self.assertIn("legacy migration are pending", source)
        self.assertIn("resourceSkills", DATA.read_text())

    def test_resource_assets_still_present(self):
        icons = list((ROOT / "Icons").glob("Herb*.tga"))
        self.assertEqual(len(icons), 29)

    def test_lua_syntax_when_compiler_installed(self):
        compiler = next((shutil.which(command)
                         for command in ("luac", "luac5.4", "luac5.1")
                         if shutil.which(command)), None)
        if not compiler:
            self.skipTest("No luac executable available; syntax not checked")
        for path in (RUNTIME, DATA):
            result = subprocess.run(
                [compiler, "-p", str(path)],
                capture_output=True, text=True, check=False)
            self.assertEqual(result.returncode, 0,
                             f"{path.name}: {result.stderr}")


if __name__ == "__main__":
    unittest.main()
