"""Export portable Flutter sources and the Xcode workspace, without local caches."""

from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import stat
import zipfile


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "artifacts" / "hom_nay_an_gi-xcode.zip"
PREFIX = "hom_nay_an_gi_xcode/"
SOURCE_DIRS = ("lib", "assets", "ios", "test", "integration_test", "test_driver", "docs", "tool", "config")
ROOT_FILES = (
    "pubspec.yaml", "pubspec.lock", "analysis_options.yaml", "README.md",
    ".metadata", ".gitignore", ".gitattributes", ".env.example", "firebase.json", "firestore.rules",
)
SKIP_DIRS = {
    "__pycache__", ".git", ".dart_tool", "build", "Pods", ".symlinks",
    "ephemeral", "DerivedData", "xcuserdata", ".generated", "node_modules",
}
SKIP_FILES = {
    "Generated.xcconfig", "flutter_export_environment.sh",
    "GeneratedPluginRegistrant.h", "GeneratedPluginRegistrant.m",
    ".DS_Store", "local.properties", "Social.xcconfig",
}
PRIVATE_SUFFIXES = {".p12", ".p8", ".pem", ".key", ".mobileprovision", ".jks", ".keystore"}
PREVIEW_FILES = (
    "artifacts/modern_login_light.png", "artifacts/modern_login_dark.png",
    "artifacts/modern_home_fixture.png", "artifacts/modern_blog_empty_fixture.png",
    "artifacts/modern_discover_fixture.png", "artifacts/facebook_logo_login_native.png",
    "artifacts/facebook_logo_launcher_native.png",
    "artifacts/facebook_logo_splash_native.png",
    "artifacts/upgrade_settings_fixture.png", "artifacts/upgrade_taste_fixture.png",
    "artifacts/upgrade_map_offline_fixture.png", "artifacts/upgrade_map_native_fixture.png",
    "artifacts/upgrade_taste_native_fixture.png", "artifacts/upgrade_settings_native_fixture.png",
    "artifacts/upgrade_login_native.png",
    "artifacts/adaptive_tablet_discover_fixture.png",
    "artifacts/adaptive_desktop_home_fixture.png",
    "artifacts/adaptive_personalization_fixture.png",
    "artifacts/adaptive_community_places_fixture.png",
    "artifacts/adaptive_place_form_fixture.png",
    "artifacts/adaptive_personalization_native_fixture.png",
    "artifacts/adaptive_place_form_native_fixture.png",
    "artifacts/adaptive_places_native_fixture.png",
    "artifacts/adaptive_login_native.png",
)


def portable_bytes(path: Path) -> bytes:
    data = path.read_bytes()
    if path.suffix in {
        ".dart", ".yaml", ".lock", ".md", ".sh", ".py", ".txt", ".json",
        ".plist", ".pbxproj", ".xcconfig", ".xcscheme", ".xcsettings",
        ".xcworkspacedata", ".storyboard", ".swift", ".h", ".m", ".entitlements", ".rules", ".mjs",
    } or path.name.startswith("."):
        data = data.replace(b"\r\n", b"\n")
    return data


def main() -> None:
    paths = [ROOT / name for name in ROOT_FILES]
    paths.extend(ROOT / name for name in PREVIEW_FILES if (ROOT / name).is_file())
    for name in SOURCE_DIRS:
        for directory, dirs, files in os.walk(ROOT / name):
            dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS)
            paths.extend(Path(directory) / f for f in files)
    selected = []
    for path in sorted(set(paths)):
        relative = path.relative_to(ROOT)
        if path.is_symlink() or not path.resolve().is_relative_to(ROOT):
            raise ValueError(f"Export refuses linked/outside source: {relative}")
        if (set(relative.parts) & SKIP_DIRS or path.name in SKIP_FILES
                or path.suffix.lower() in PRIVATE_SUFFIXES):
            continue
        if path.name.startswith(".env") and path.name != ".env.example":
            continue
        if (relative.parts[0] == "config" and path.name != "firebase.example.json") or path.name.endswith("-debug.log"):
            continue
        selected.append((relative.as_posix(), portable_bytes(path)))

    manifest = {
        "exportedAt": datetime.now(timezone.utc).isoformat(),
        "flutterVersion": "3.47.9",
        "entryPoint": "lib/main.dart",
        "workspace": "ios/Runner.xcworkspace",
        "prepareAndOpen": "bash ios/open_xcode.sh",
        "scope": "Flutter application sources for iOS; SDK and build caches excluded",
        "iosBuildVerified": False,
        "files": {name: hashlib.sha256(data).hexdigest() for name, data in selected},
    }
    selected.append(("EXPORT_MANIFEST.json", (
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"
    ).encode("utf-8")))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(OUTPUT, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for name, data in selected:
            info = zipfile.ZipInfo(PREFIX + name)
            info.create_system = 3
            mode = 0o755 if name.endswith(".sh") else 0o644
            info.external_attr = (stat.S_IFREG | mode) << 16
            archive.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED)
    print(f"Exported {len(selected)} files: {OUTPUT} ({OUTPUT.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
