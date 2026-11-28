#!/usr/bin/env python3
"""Generate an AltStore Classic source from the actual IPA and release metadata."""

import argparse
import json
import plistlib
import re
import zipfile
from pathlib import Path
from urllib.parse import quote


def generate(ipa, release, previous=None):
    if release["draft"] or release["prerelease"]:
        raise ValueError("Only published stable releases belong in this source")
    tag = release["tag_name"]
    if not re.fullmatch(r"v?\d+\.\d+\.\d+", tag):
        raise ValueError(f"Unsupported release tag: {tag}")

    with zipfile.ZipFile(ipa) as archive:
        plists = [
            name for name in archive.namelist()
            if re.fullmatch(r"Payload/[^/]+\.app/Info.plist", name)
        ]
        if len(plists) != 1:
            raise ValueError("Expected exactly one app in the IPA")
        info = plistlib.loads(archive.read(plists[0]))
        if info["CFBundleIdentifier"] != "ru.djachenko.ios.Photochem":
            raise ValueError("Unexpected app bundle identifier")
        if info["CFBundleShortVersionString"] != tag.removeprefix("v"):
            raise ValueError("Release tag does not match the IPA version")
        if info["CFBundleSupportedPlatforms"] != ["iPhoneOS"]:
            raise ValueError("Expected an iPhone device build")
        extensions = [
            name for name in archive.namelist()
            if re.fullmatch(r"Payload/[^/]+\.app/PlugIns/[^/]+\.appex/Info.plist", name)
        ]
        if not extensions:
            raise ValueError("Missing Live Activity extension")
        privacy = {}
        for name in [*plists, *extensions]:
            bundle_info = plistlib.loads(archive.read(name))
            for key, value in bundle_info.items():
                if key.startswith("NS") and "UsageDescription" in key:
                    privacy[key] = value

    version = {
        "version": info["CFBundleShortVersionString"],
        "buildVersion": str(info["CFBundleVersion"]),
        "date": release["published_at"],
        "localizedDescription": release.get("body") or "",
        "downloadURL": f'{release["html_url"].rsplit("/tag/", 1)[0]}/download/{quote(tag, safe="")}/Photochem.ipa',
        "size": Path(ipa).stat().st_size,
        "minOSVersion": info["MinimumOSVersion"],
    }
    versions = []
    if previous:
        versions = previous["apps"][0]["versions"]
    # Re-running a release replaces its entry; rebuilding an older release must
    # not advertise it as an upgrade to users already running a newer version.
    versions = [item for item in versions if item["version"] != version["version"]]
    versions.append(version)
    versions.sort(key=lambda item: tuple(map(int, item["version"].split("."))), reverse=True)
    app = {
        "name": "Photochem",
        "bundleIdentifier": info["CFBundleIdentifier"],
        "developerName": "Igor Djachenko",
        "subtitle": "Таймер для проявки фотоплёнки",
        "localizedDescription": "Расчёт времени этапов по пробегу химии, таймер проявки, Live Activity и журнал сеансов.",
        # The app currently has no custom icon; use the developer's avatar.
        "iconURL": "https://github.com/djachenko.png",
        "versions": versions,
        "appPermissions": {"entitlements": [], "privacy": privacy},
    }
    return {
        "name": "Photochem",
        "identifier": "ru.djachenko.photochem.source",
        "apps": [app],
        "news": [],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ipa", type=Path, required=True)
    parser.add_argument("--release", type=Path, required=True)
    parser.add_argument("--previous", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    previous = None
    if args.previous and args.previous.exists():
        previous = json.loads(args.previous.read_text())
    result = generate(args.ipa, json.loads(args.release.read_text()), previous)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")


if __name__ == "__main__":
    main()
