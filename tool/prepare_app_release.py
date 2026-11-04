"""Validate an unsigned iOS artifact and prepare (but never publish) update metadata."""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BUNDLE = 'vn.homnayangi.homNayAnGi'
REPO = 'AnhhPhuong06/HomNayAnGi'


def prepare(ipa: Path, notes: str, root: Path = ROOT) -> dict:
    match = re.search(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$',
                      (root / 'pubspec.yaml').read_text(encoding='utf-8'), re.M)
    if not match or not notes.strip() or len(notes) > 2000:
        raise ValueError('Invalid source version or release notes')
    version, build = match.groups()
    with zipfile.ZipFile(ipa) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)) or archive.testzip() is not None:
            raise ValueError('Duplicate entries or corrupted IPA')
        if any(n.startswith('/') or '..' in n.split('/') for n in names):
            raise ValueError('Unsafe archive path')
        base = 'Payload/Runner.app/'
        info = plistlib.loads(archive.read(base + 'Info.plist'))
        if (info.get('CFBundleIdentifier') != BUNDLE
                or info.get('CFBundleShortVersionString') != version
                or info.get('CFBundleVersion') != build
                or info.get('CFBundleSupportedPlatforms') != ['iPhoneOS']):
            raise ValueError('IPA does not match this source version, bundle or device platform')
        if base + 'Runner' not in names:
            raise ValueError('Missing app executable')
        if any(n.startswith(base + '_CodeSignature/') or n == base + 'embedded.mobileprovision' for n in names):
            raise ValueError('This publisher accepts unsigned manual builds only')
    tag = f'v{version}+{build}'
    manifest = json.loads((root / 'config/app_updates.json').read_text(encoding='utf-8'))
    if manifest.get('schemaVersion') != 1 or not isinstance(manifest.get('releases'), list):
        raise ValueError('Invalid current update metadata')
    entry = {'bundleId': BUNDLE, 'version': version, 'build': int(build),
             'channel': 'iosManual',
             'url': f'https://github.com/{REPO}/releases/tag/{tag}', 'notes': notes.strip()}
    previous = [r for r in manifest['releases'] if r.get('channel') == 'iosManual' and r.get('bundleId') == BUNDLE]
    for r in previous:
        old = tuple(int(p) for p in r['version'].split('.')) + (int(r['build']),)
        if old > tuple(int(p) for p in version.split('.')) + (int(build),):
            raise ValueError('Refusing update metadata rollback')
    manifest['releases'] = [r for r in manifest['releases']
                            if not (r.get('channel') == 'iosManual' and r.get('bundleId') == BUNDLE)] + [entry]
    return {'tag': tag, 'manifest': manifest,
            'sha256': hashlib.sha256(ipa.read_bytes()).hexdigest()}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ipa', type=Path, required=True)
    parser.add_argument('--notes', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    version = re.search(r'^version:\s*(\d+\.\d+\.\d+)\+', (ROOT / 'pubspec.yaml').read_text(encoding='utf-8'), re.M)
    if not version:
        raise ValueError('Invalid source version')
    notes = (args.notes or ROOT / 'docs/releases' / f'{version.group(1)}.md').read_text(encoding='utf-8')
    result = prepare(args.ipa, notes)
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / 'app_updates.json').write_text(json.dumps(result['manifest'], ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (args.output / 'SHA256SUMS.txt').write_text(f"{result['sha256']}  {args.ipa.name}\n", encoding='utf-8')
    (args.output / 'release-tag.txt').write_text(result['tag'], encoding='utf-8')
    (args.output / 'release-notes.md').write_text(notes, encoding='utf-8')
    print(f"Validated {result['tag']}; prepared metadata only. Publish the IPA before updating the public feed.")


if __name__ == '__main__':
    main()
