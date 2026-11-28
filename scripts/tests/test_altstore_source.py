import copy
import importlib.util
import plistlib
import tempfile
import unittest
import zipfile
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "altstore_source", Path(__file__).parents[1] / "altstore-source.py"
)
source = importlib.util.module_from_spec(spec)
spec.loader.exec_module(source)


class AltStoreSourceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.ipa = Path(self.temp.name) / "Photochem.ipa"
        self.info = {
            "CFBundleIdentifier": "ru.djachenko.ios.Photochem",
            "CFBundleShortVersionString": "0.2.0",
            "CFBundleVersion": "3",
            "CFBundleSupportedPlatforms": ["iPhoneOS"],
            "MinimumOSVersion": "18.0",
        }
        self.release = {
            "tag_name": "0.2.0",
            "draft": False,
            "prerelease": False,
            "published_at": "2026-11-28T08:00:00Z",
            "body": "Исправления и улучшения",
            "html_url": "https://github.com/djachenko/photochem/releases/tag/0.2.0",
        }

    def write_ipa(self, extension=True):
        with zipfile.ZipFile(self.ipa, "w") as archive:
            archive.writestr("Payload/PhotochemApp.app/Info.plist", plistlib.dumps(self.info))
            if extension:
                archive.writestr(
                    "Payload/PhotochemApp.app/PlugIns/PhotochemWidgets.appex/Info.plist",
                    plistlib.dumps({"NSCameraUsageDescription": "Test extension permission"}),
                )

    def test_uses_actual_ipa_metadata_and_extension_permissions(self):
        self.write_ipa()
        app = source.generate(self.ipa, self.release)["apps"][0]
        version = app["versions"][0]
        self.assertEqual(version["size"], self.ipa.stat().st_size)
        self.assertEqual(version["buildVersion"], "3")
        self.assertEqual(version["minOSVersion"], "18.0")
        self.assertEqual(version["localizedDescription"], self.release["body"])
        self.assertEqual(
            version["downloadURL"],
            "https://github.com/djachenko/photochem/releases/download/0.2.0/Photochem.ipa",
        )
        self.assertEqual(app["appPermissions"]["privacy"]["NSCameraUsageDescription"],
                         "Test extension permission")

    def test_rebuild_keeps_newer_release_first_and_replaces_existing_entry(self):
        self.write_ipa()
        previous = source.generate(self.ipa, self.release)
        newer = copy.deepcopy(previous["apps"][0]["versions"][0])
        newer["version"] = "0.10.0"
        previous["apps"][0]["versions"].insert(0, newer)
        self.info["CFBundleVersion"] = "4"
        self.write_ipa()
        versions = source.generate(self.ipa, self.release, previous)["apps"][0]["versions"]
        self.assertEqual([v["version"] for v in versions], ["0.10.0", "0.2.0"])
        self.assertEqual(versions[1]["buildVersion"], "4")

    def test_rejects_wrong_tag_bundle_platform_or_missing_extension(self):
        for key, value in [
            ("CFBundleShortVersionString", "0.1.0"),
            ("CFBundleIdentifier", "other.app"),
            ("CFBundleSupportedPlatforms", ["iPhoneSimulator"]),
        ]:
            with self.subTest(key=key):
                original = self.info[key]
                self.info[key] = value
                self.write_ipa()
                with self.assertRaises(ValueError):
                    source.generate(self.ipa, self.release)
                self.info[key] = original
        self.write_ipa(extension=False)
        with self.assertRaisesRegex(ValueError, "extension"):
            source.generate(self.ipa, self.release)

    def test_rejects_unpublished_or_prerelease(self):
        self.write_ipa()
        for key in ("draft", "prerelease"):
            with self.subTest(key=key):
                release = {**self.release, key: True}
                with self.assertRaises(ValueError):
                    source.generate(self.ipa, release)


if __name__ == "__main__":
    unittest.main()
