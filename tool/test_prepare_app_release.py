import json
from pathlib import Path
import plistlib
import tempfile
import unittest
import zipfile
from prepare_app_release import BUNDLE, prepare, release_only_changes


class ReleaseTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'config').mkdir()
        (self.root / 'pubspec.yaml').write_text('version: 1.1.0+2\n')
        (self.root / 'config/app_updates.json').write_text(json.dumps({'schemaVersion': 1, 'releases': []}))
        self.ipa = self.root / 'test.ipa'

    def write_ipa(self, changes=None, extra=None):
        info = {'CFBundleIdentifier': BUNDLE, 'CFBundleShortVersionString': '1.1.0',
                'CFBundleVersion': '2', 'CFBundleSupportedPlatforms': ['iPhoneOS'],
                'CFBundleURLTypes': [{'CFBundleURLSchemes': ['com.googleusercontent.apps.123456789-ios']}]}
        info.update(changes or {})
        with zipfile.ZipFile(self.ipa, 'w') as z:
            z.writestr('Payload/Runner.app/Info.plist', plistlib.dumps(info))
            z.writestr('Payload/Runner.app/Runner', b'fixture-executable')
            z.writestr('Payload/Runner.app/Frameworks/App.framework/App', b'fixture homnayangi-cba95 123456789-ios.apps.googleusercontent.com')
            if extra:
                z.writestr(extra, b'fixture')

    def test_prepares_matching_manual_metadata_without_modifying_public_feed(self):
        self.write_ipa()
        result = prepare(self.ipa, 'Release notes', self.root)
        self.assertEqual(result['tag'], 'v1.1.0+2')
        self.assertEqual(result['manifest']['releases'][0]['channel'], 'iosManual')
        self.assertEqual(json.loads((self.root / 'config/app_updates.json').read_text())['releases'], [])

    def test_rejects_wrong_build_bundle_and_simulator(self):
        for change in [{'CFBundleVersion': '1'}, {'CFBundleIdentifier': 'other.app'},
                       {'CFBundleSupportedPlatforms': ['iPhoneSimulator']}]:
            with self.subTest(change=change):
                self.write_ipa(change)
                with self.assertRaises(ValueError):
                    prepare(self.ipa, 'Notes', self.root)

    def test_rejects_signed_or_unsafe_archive(self):
        for path in ['Payload/Runner.app/_CodeSignature/CodeResources',
                     'Payload/Runner.app/embedded.mobileprovision', '../outside']:
            with self.subTest(path=path):
                self.write_ipa(extra=path)
                with self.assertRaises(ValueError):
                    prepare(self.ipa, 'Notes', self.root)

    def test_rejects_compile_only_and_only_allows_non_runtime_changes(self):
        self.write_ipa({'CFBundleURLTypes': []})
        with self.assertRaisesRegex(ValueError, 'Compile-only'):
            prepare(self.ipa, 'Notes', self.root)
        self.assertTrue(release_only_changes(['docs/app-updates.md', 'EXPORT_MANIFEST.json', '.github/workflows/publish-ios-update.yml']))
        for path in ['lib/main.dart', 'assets/data/restaurants.json', 'ios/Runner/Info.plist', 'pubspec.yaml', 'pubspec.lock', '.github/workflows/ios-unsigned.yml', 'firestore.rules', 'config/firebase.example.json']:
            self.assertFalse(release_only_changes(['README.md', path]), path)

    def test_rejects_rollback_and_preserves_other_channels(self):
        self.write_ipa()
        feed = {'schemaVersion': 1, 'releases': [{'channel': 'iosManual', 'bundleId': BUNDLE, 'version': '1.2.0', 'build': 3}]}
        path = self.root / 'config/app_updates.json'
        path.write_text(json.dumps(feed))
        with self.assertRaises(ValueError):
            prepare(self.ipa, 'Notes', self.root)
        feed['releases'][0]['channel'] = 'iosAppStore'
        path.write_text(json.dumps(feed))
        self.assertEqual(len(prepare(self.ipa, 'Notes', self.root)['manifest']['releases']), 2)


if __name__ == '__main__':
    unittest.main()
