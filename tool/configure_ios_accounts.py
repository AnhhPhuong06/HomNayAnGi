"""Prepare client configuration without printing values or uploading credentials."""
import argparse
import json
import os
from pathlib import Path
import plistlib
import re
import sys

BUNDLE_ID = 'vn.homnayangi.homNayAnGi'
ENV_NAME = 'FIREBASE_IOS_CONFIG_JSON'


def validate(data):
    if not isinstance(data, dict):
        raise ValueError('Configuration must be a JSON object.')
    if any(key in data for key in ('private_key', 'client_secret', 'FACEBOOK_APP_SECRET')):
        raise ValueError('Use mobile client configuration, never server credentials.')

    def value(key, pattern, optional=False):
        raw = data.get(key, '')
        if optional and raw == '':
            return ''
        if (not isinstance(raw, str) or not re.fullmatch(pattern, raw)
                or any(marker in raw.upper() for marker in ('REPLACE', 'NOT-CONFIGURED', 'YOUR_'))):
            raise ValueError(f'Missing or invalid {key}. Obtain it from the provider console.')
        return raw

    config = {
        'FIREBASE_API_KEY': value('FIREBASE_API_KEY', r'AIza[\w-]{35}'),
        'FIREBASE_PROJECT_ID': value('FIREBASE_PROJECT_ID', r'[a-z][a-z0-9-]{4,28}[a-z0-9]'),
        'FIREBASE_MESSAGING_SENDER_ID': value('FIREBASE_MESSAGING_SENDER_ID', r'[0-9]+'),
        'FIREBASE_IOS_APP_ID': value('FIREBASE_IOS_APP_ID', r'1:[0-9]+:ios:[a-fA-F0-9]+'),
        'GOOGLE_IOS_CLIENT_ID': value('GOOGLE_IOS_CLIENT_ID', r'[0-9]+(?:-[\w-]+)?\.apps\.googleusercontent\.com'),
        'GOOGLE_WEB_CLIENT_ID': value('GOOGLE_WEB_CLIENT_ID', r'[0-9]+(?:-[\w-]+)?\.apps\.googleusercontent\.com', True),
    }
    if config['FIREBASE_IOS_APP_ID'].split(':')[1] != config['FIREBASE_MESSAGING_SENDER_ID']:
        raise ValueError('Firebase app ID and sender ID belong to different projects.')
    facebook_id = value('FACEBOOK_APP_ID', r'[1-9][0-9]+', True)
    facebook_token = value('FACEBOOK_CLIENT_TOKEN', r'[A-Za-z0-9_-]+', True)
    if bool(facebook_id) != bool(facebook_token):
        raise ValueError('Provide both FACEBOOK_APP_ID and FACEBOOK_CLIENT_TOKEN, or neither.')
    apple = data.get('APPLE_LOGIN_ENABLED', False)
    if not isinstance(apple, bool):
        raise ValueError('APPLE_LOGIN_ENABLED must be true or false.')
    config['FACEBOOK_LOGIN_ENABLED'] = bool(facebook_id)
    config['APPLE_LOGIN_ENABLED'] = apple
    # Derive the callback from the same ID passed to GoogleSignIn.initialize.
    reverse_id = '.'.join(reversed(config['GOOGLE_IOS_CLIENT_ID'].split('.')))
    social = f'GOOGLE_REVERSED_CLIENT_ID = {reverse_id}\n'
    if facebook_id:
        social += f'FACEBOOK_APP_ID = {facebook_id}\nFACEBOOK_CLIENT_TOKEN = {facebook_token}\n'
    return config, social


def from_plist(path):
    with path.open('rb') as handle:
        data = plistlib.load(handle)
    if not isinstance(data, dict):
        raise ValueError('Expected a Firebase iOS configuration plist.')
    if data.get('BUNDLE_ID') != BUNDLE_ID:
        raise ValueError(f'Register the iOS app with bundle ID {BUNDLE_ID}.')
    return {
        'FIREBASE_API_KEY': data.get('API_KEY', ''),
        'FIREBASE_PROJECT_ID': data.get('PROJECT_ID', ''),
        'FIREBASE_MESSAGING_SENDER_ID': data.get('GCM_SENDER_ID', ''),
        'FIREBASE_IOS_APP_ID': data.get('GOOGLE_APP_ID', ''),
        'GOOGLE_IOS_CLIENT_ID': data.get('CLIENT_ID', ''),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument('--plist', type=Path, help='Firebase iOS plist downloaded AFTER enabling Google sign-in.')
    source.add_argument('--from-env', action='store_true', help=f'Read {ENV_NAME}; never log its contents.')
    parser.add_argument('--project-dir', type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args()
    try:
        if args.plist:
            data = from_plist(args.plist)
        else:
            raw = os.environ.get(ENV_NAME, '')
            if not raw:
                raise ValueError(f'Add repository secret {ENV_NAME}; see docs/firebase-free-setup.md.')
            data = json.loads(raw)
        config, social = validate(data)
        output = args.project_dir / 'config/firebase.ios.json'
        native = args.project_dir / 'ios/Flutter/Social.xcconfig'
        # Preserve existing Facebook settings during local Google setup.
        if args.plist and native.exists():
            existing = [line for line in native.read_text(encoding='utf-8').splitlines()
                        if not re.match(r'^\s*GOOGLE_REVERSED_CLIENT_ID\s*=', line)]
            social = '\n'.join(existing) + '\n' + social
        output.parent.mkdir(parents=True, exist_ok=True)
        native.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(config, indent=2) + '\n', encoding='utf-8')
        native.write_text(social, encoding='utf-8')
        print('Prepared config/firebase.ios.json and ios/Flutter/Social.xcconfig (values hidden).')
        return 0
    except (json.JSONDecodeError, plistlib.InvalidFileException, UnicodeError):
        print('Invalid configuration format; values hidden.', file=sys.stderr)
        return 1
    except ValueError as error:
        print(str(error), file=sys.stderr)
        return 1
    except OSError:
        print('Could not read or write account configuration files.', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
