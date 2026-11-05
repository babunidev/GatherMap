"""Static safety tests for GatherMap's Forever-only development manifest.

These do not replace Lua syntax, API behavior, or in-game verification.
Run from repo root: python3 -m unittest discover -s tests -p 'test_forever_*.py'
"""
from pathlib import Path
import re
import sys
import shutil
import subprocess
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "GatherMap_Camelot.toc"
RUNTIME = ROOT / "GatherMapForever.lua"
CAPTURE = ROOT / "GatherMapCapture.lua"
DATA = ROOT / "GatherMapData.lua"
DIFFICULTY = ROOT / "GatherMapDifficulty.lua"
MARKERS = ROOT / "GatherMapMarkers.lua"
SPATIAL = ROOT / "GatherMapSpatial.lua"
MIGRATION = ROOT / "GatherMapMigration.lua"
XML = ROOT / "GatherMapWorldPins.xml"


class ForeverCompatibilityTests(unittest.TestCase):
    def test_manifest_and_load_order(self):
        text = MANIFEST.read_text()
        self.assertIn("## Interface: 16001", text)
        self.assertIn("## SavedVariables: GatherMapDB", text)
        self.assertNotIn("OptionalDeps: Interact", text)
        files = [line.strip() for line in text.splitlines()
                 if line.strip() and not line.lstrip().startswith("##")]
        self.assertEqual(files, [DATA.name, MARKERS.name, SPATIAL.name, DIFFICULTY.name, MIGRATION.name, RUNTIME.name, XML.name, CAPTURE.name])
        for name in files:
            self.assertTrue((ROOT / name).is_file(), name)
        self.assertNotIn("GatherMap.lua", files)
        self.assertLess(files.index(RUNTIME.name), files.index(XML.name), "world pin mixin must exist before XML is loaded")

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
        source = RUNTIME.read_text() + "\n" + DIFFICULTY.read_text()
        for symbol in (
            "skillApi.GetSkillLineInfoByID",
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
        self.assertIn("Historical zones ", source)
        self.assertIn("resourceSkills", DATA.read_text())

    def test_skill_event_driven_refresh(self):
        runtime = RUNTIME.read_text()
        self.assertIn("difficulty.Refresh()", runtime)
        self.assertIn("difficulty.Color(", runtime)
        self.assertIn("difficulty.IsVisible(", runtime)
        for event in (
            "SKILL_LINES_CHANGED",
            "CHAT_MSG_SKILL",
            "PLAYER_EQUIPMENT_CHANGED",
            "PROFESSION_EQUIPMENT_CHANGED",
            "UNIT_AURA",
            "PLAYER_LEVEL_UP",
        ):
            self.assertIn(f'f:RegisterEvent("{event}")', runtime)
        self.assertNotIn("skillTick", runtime)
        self.assertIn("GatherMapDifficulty.lua", MANIFEST.read_text())

    def test_marker_geometry_and_map_canvas_invariants(self):
        runtime = RUNTIME.read_text()
        grouping = MARKERS.read_text()
        for symbol in (
            "markers.Group(",
            "markers.MiniPoint(",
            "markers.WorldPoint(",
            "OnCanvasScaleChanged",
            "OnCanvasSizeChanged",
            "map:GetCanvas()",
            "map:GetCanvasScale()",
            'CreateFrame("Frame", nil, UIParent)',
            "local function Union(",
        ):
            self.assertIn(symbol, runtime + grouping)
        self.assertNotIn("GameTooltip:SetOwner", runtime)
        self.assertNotIn("GameTooltip:Hide", runtime)
        self.assertIn('db.enabled=true;MarkDirty()', runtime)
        self.assertIn('db.worldMapEnabled=not db.worldMapEnabled', runtime)
        self.assertIn('GatherMapForeverMenuButton', runtime)
        self.assertIn('GatherMapForeverSettingsPanel', runtime)
        self.assertIn('ns.GatherMapSetCapture(not db.recordingEnabled)', runtime)
        self.assertNotIn('GatherMapForeverMapToggle', runtime)
        self.assertIn("MAX_PINS", runtime)
        self.assertIn("GatherMapMarkers.lua", MANIFEST.read_text())
        self.assertIn("GatherMapForeverWorldPinMixin:CheckMouseButtonPassthrough()", runtime)
        self.assertNotIn("self:SetPassThroughButtons(", runtime)
        self.assertNotIn('self:EnableMouse(false)', runtime.split(
            "function GatherMapForeverWorldPinMixin:OnLoad()", 1)[1].split("end", 1)[0])
        self.assertIn("IsRotateMinimapIgnored", runtime)
        self.assertIn('command=="pinpos"', runtime)
        self.assertIn("sx * cs + sy * sn", grouping)

    def test_performance_and_coexistence_guards(self):
        source = RUNTIME.read_text()
        grouping = MARKERS.read_text()
        index = SPATIAL.read_text()
        self.assertIn("spatial.Nearby(", source)
        self.assertIn("spatial.Build(", source)
        self.assertIn("MarkStyleDirty()", source)
        self.assertIn("visibleMiniPins", source)
        self.assertIn("worldLayout", source)
        self.assertIn("worldDirty", source)
        self.assertIn("Union(parent, sizes, i, nearby[1])", grouping)
        self.assertIn("break", grouping)
        self.assertIn("MAX_QUERY_CELLS", index)
        self.assertIn("MAX_PINS", source)
        self.assertNotIn("GameTooltip:SetOwner", source)
        self.assertNotIn("hooksecurefunc(", source)
        self.assertNotIn("SetMapZoom(", source)

    def test_forever_package_audit(self):
        result = subprocess.run(
            [sys.executable, str(ROOT / "tools" / "check_forever_package.py")],
            capture_output=True, text=True, check=False
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("PASS: Forever", result.stdout)
        for name in ("docs/TEST_PLAN.md", "docs/FOREVER_API_AUDIT.md",
                     "docs/THIRD_PARTY_ASSETS.md", "docs/LEGACY_0_4_3.md"):
            self.assertTrue((ROOT / name).is_file(), name)

    def test_legacy_migration_integrity(self):
        runtime = RUNTIME.read_text()
        source = MIGRATION.read_text()
        self.assertIn("migration.Init(db, MarkDirty)", runtime)
        self.assertIn("MigrationCommand(command)", runtime)
        self.assertIn("migration.Apply(key,confirm)", runtime)
        self.assertIn("migration.VerifyAnchor(key,confirm)", runtime)
        self.assertIn("local function Verified(key)", source)
        self.assertIn("local build=ClientBuild()", source)
        self.assertIn("db.migrationBackups", source)
        self.assertIn("db.migrationLedger", source)
        self.assertIn('db.nodes[result.targetKey]=result.after', source)
        self.assertNotIn('db.nodes[key]=nil', source)
        self.assertIn("local function SourceVersion()", source)
        self.assertIn('if version<3 and kind=="skin"', source)
        self.assertIn("if isNew then db.version=3 end", runtime)
        helper = (ROOT / "Upgrade-SavedData.ps1").read_text()
        self.assertIn("_Camelot.toc", helper)
        self.assertTrue((ROOT / "Backup-GatherMap.ps1").is_file())

    def test_resource_assets_still_present(self):
        icons = list((ROOT / "Icons").glob("Herb*.tga"))
        self.assertEqual(len(icons), 29)

    def test_lua_syntax_when_compiler_installed(self):
        compiler = next((shutil.which(command)
                         for command in ("luac", "luac5.4", "luac5.1")
                         if shutil.which(command)), None)
        if not compiler:
            self.skipTest("No luac executable available; syntax not checked")
        for path in (RUNTIME, DATA, MARKERS, SPATIAL, DIFFICULTY, MIGRATION, CAPTURE):
            result = subprocess.run(
                [compiler, "-p", str(path)],
                capture_output=True, text=True, check=False)
            self.assertEqual(result.returncode, 0,
                             f"{path.name}: {result.stderr}")


if __name__ == "__main__":
    unittest.main()
