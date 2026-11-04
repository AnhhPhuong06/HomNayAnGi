import contextlib
import io
import json
import os
from pathlib import Path
import plistlib
import tempfile
import unittest
from unittest.mock import patch

import configure_ios_accounts as setup


class AccountConfigurationTest(unittest.TestCase):
    def setUp(self):
        self.data = {
            'FIREBASE_API_KEY': 'AIza' + 'a' * 35,
            'FIREBASE_PROJECT_ID': 'meal-test-project',
            'FIREBASE_MESSAGING_SENDER_ID': '123456789',
            'FIREBASE_IOS_APP_ID': '1:123456789:ios:abcdef123',
            'GOOGLE_IOS_CLIENT_ID': '123456789-ios.apps.googleusercontent.com',
        }

    def test_configures_google_without_facebook_or_web_client(self):
        config, native = setup.validate(self.data)
        self.assertEqual(config['GOOGLE_WEB_CLIENT_ID'], '')
        self.assertIn('com.googleusercontent.apps.123456789-ios', native)
        self.assertNotIn('FACEBOOK_', native)
        self.assertFalse(config['FACEBOOK_LOGIN_ENABLED'])
        self.assertFalse(config['APPLE_LOGIN_ENABLED'])

    def test_provider_flags_need_explicit_configuration(self):
        config, _ = setup.validate(self.data | {'FACEBOOK_APP_ID': '1234', 'FACEBOOK_CLIENT_TOKEN': 'test-client-token', 'APPLE_LOGIN_ENABLED': True})
        self.assertTrue(config['FACEBOOK_LOGIN_ENABLED'])
        self.assertTrue(config['APPLE_LOGIN_ENABLED'])
        with self.assertRaises(ValueError):
            setup.validate(self.data | {'APPLE_LOGIN_ENABLED': 'true'})

    def test_rejects_missing_placeholder_and_cross_project_values(self):
        for change in [
            {'FIREBASE_API_KEY': ''},
            {'GOOGLE_IOS_CLIENT_ID': '123-REPLACE_ME.apps.googleusercontent.com'},
            {'FIREBASE_MESSAGING_SENDER_ID': '98765'},
            {'FACEBOOK_APP_ID': '1234'},
            {'private_key': 'private-material'},
        ]:
            with self.subTest(change=list(change)), self.assertRaises(ValueError):
                setup.validate(self.data | change)

    def test_rejects_xcconfig_injection(self):
        with self.assertRaises(ValueError):
            setup.validate(self.data | {'FACEBOOK_APP_ID': '1234',
                                        'FACEBOOK_CLIENT_TOKEN': 'token\n#include "/tmp/evil"'})

    def test_plist_requires_registered_bundle(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'GoogleService-Info.plist'
            path.write_bytes(plistlib.dumps({'BUNDLE_ID': 'wrong.bundle'}))
            with self.assertRaisesRegex(ValueError, setup.BUNDLE_ID):
                setup.from_plist(path)

    def test_cli_writes_configuration_without_logging_values(self):
        with tempfile.TemporaryDirectory() as directory:
            stdout = io.StringIO()
            with patch.dict(os.environ, {setup.ENV_NAME: json.dumps(self.data)}), \
                    patch('sys.argv', ['configure', '--from-env', '--project-dir', directory]), \
                    contextlib.redirect_stdout(stdout):
                self.assertEqual(setup.main(), 0)
            output = json.loads((Path(directory) / 'config/firebase.ios.json').read_text())
            self.assertEqual(output['FIREBASE_IOS_APP_ID'], self.data['FIREBASE_IOS_APP_ID'])
            self.assertNotIn(self.data['FIREBASE_API_KEY'], stdout.getvalue())
            self.assertTrue((Path(directory) / 'ios/Flutter/Social.xcconfig').is_file())

    def test_missing_secret_fails_before_creating_files(self):
        with tempfile.TemporaryDirectory() as directory:
            stderr = io.StringIO()
            with patch.dict(os.environ, {setup.ENV_NAME: ''}), \
                    patch('sys.argv', ['configure', '--from-env', '--project-dir', directory]), \
                    contextlib.redirect_stderr(stderr):
                self.assertEqual(setup.main(), 1)
            self.assertIn(setup.ENV_NAME, stderr.getvalue())
            self.assertEqual(list(Path(directory).iterdir()), [])


if __name__ == '__main__':
    unittest.main()
