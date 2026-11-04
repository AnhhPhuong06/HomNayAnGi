"""Import reviewed, branch-specific Commons photos with per-file attribution."""
from datetime import datetime, timezone
from html.parser import HTMLParser
import hashlib
import json
from pathlib import Path
import re
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
UA = 'HomNayAnGiPhotoImporter/1.0 (https://github.com/AnhhPhuong06/HomNayAnGi)'
LICENSES = {'CC0', 'Public domain', 'CC BY 2.0', 'CC BY 3.0', 'CC BY 4.0',
            'CC BY-SA 2.0', 'CC BY-SA 2.5', 'CC BY-SA 3.0', 'CC BY-SA 4.0'}
HOSTS = {'commons.wikimedia.org', 'upload.wikimedia.org', 'thumb.wikimedia.org'}


class PlainText(HTMLParser):
    def __init__(self):
        super().__init__(); self.parts = []
    def handle_data(self, data):
        self.parts.append(data)


def plain(value):
    parser = PlainText(); parser.feed(value)
    return ' '.join(' '.join(parser.parts).split())


def request(url, limit=8_000_000):
    if urllib.parse.urlparse(url).scheme != 'https' or urllib.parse.urlparse(url).hostname not in HOSTS:
        raise ValueError('Unexpected image host')
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    with urllib.request.urlopen(req, timeout=45) as response:
        if urllib.parse.urlparse(response.url).scheme != 'https' or urllib.parse.urlparse(response.url).hostname not in HOSTS:
            raise ValueError('Unexpected redirect host')
        content = response.read(limit + 1)
    if len(content) > limit:
        raise ValueError('Image/metadata too large')
    return content


def photo_record(venue_id, reviewed, page, checked_at):
    if not re.fullmatch(r'osm-(node|way|relation)-[0-9]+', venue_id):
        raise ValueError('Invalid venue ID')
    if not reviewed.get('matchEvidence') or not reviewed.get('caption'):
        raise ValueError('A branch-specific match and caption are required')
    if page.get('title') != reviewed['file']:
        raise ValueError('Commons title changed; review the match again')
    info = page['imageinfo'][0]; meta = info['extmetadata']
    license_name = meta.get('LicenseShortName', {}).get('value', '')
    if license_name not in LICENSES:
        raise ValueError('Photo license needs review')
    license_url = meta.get('LicenseUrl', {}).get('value', '').replace('http://', 'https://', 1)
    if license_name == 'Public domain' and not license_url:
        license_url = 'https://creativecommons.org/publicdomain/mark/1.0/'
    uri = urllib.parse.urlparse(license_url)
    if uri.scheme != 'https' or uri.hostname != 'creativecommons.org':
        raise ValueError('Missing recognized license URL')
    author = plain(meta.get('Artist', {}).get('value', ''))
    if not author:
        raise ValueError('Missing author attribution')
    return {
        'asset': f'assets/venue_photos/{venue_id}.jpg',
        'sourceUrl': info['descriptionurl'], 'originalUrl': info['url'],
        'downloadUrl': info.get('thumburl', info['url']),
        'author': author, 'license': license_name, 'licenseUrl': license_url,
        'caption': reviewed['caption'], 'matchEvidence': reviewed['matchEvidence'],
        'checkedAt': checked_at,
        'capturedAt': plain(meta.get('DateTimeOriginal', {}).get('value', 'Không rõ ngày chụp')),
    }


def main():
    source_path = ROOT / 'tool/data/venue_photo_sources.json'
    reviewed = json.loads(source_path.read_text(encoding='utf-8'))
    catalog = json.loads((ROOT / 'assets/data/real_restaurants.json').read_text(encoding='utf-8'))
    known_ids = {row['id'] for row in catalog}
    if any(key not in known_ids for key in reviewed['restaurants']):
        raise ValueError('Reviewed photo references an unknown venue')
    for venue_id, match in reviewed['restaurants'].items():
        venue = next(row for row in catalog if row['id'] == venue_id)
        if match.get('venueName') != venue['name'] or match.get('address') != venue['address']:
            raise ValueError(f'Venue identity changed; review photo again: {venue_id}')
    params = {'action': 'query', 'format': 'json', 'prop': 'imageinfo',
              'titles': '|'.join(p['file'] for p in reviewed['restaurants'].values()),
              'iiprop': 'url|extmetadata', 'iiurlwidth': 960}
    response = json.loads(request('https://commons.wikimedia.org/w/api.php?' + urllib.parse.urlencode(params)))
    pages = {page['title']: page for page in response['query']['pages'].values()}
    records = {}; downloads = {}
    for venue_id, match in reviewed['restaurants'].items():
        photo = photo_record(venue_id, match, pages[match['file']], reviewed['checkedAt'])
        data = request(photo['downloadUrl'], limit=4_000_000)
        if not data.startswith(b'\xff\xd8\xff'):
            raise ValueError('Expected a JPEG thumbnail')
        photo['sha256'] = hashlib.sha256(data).hexdigest()
        photo['venueName'] = next(row['name'] for row in catalog if row['id'] == venue_id)
        records[venue_id] = photo; downloads[photo['asset']] = data
    # Validate and download everything before replacing the published manifest.
    for relative, data in downloads.items():
        target = ROOT / relative; target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    manifest = {'schemaVersion': 1, 'importedAt': datetime.now(timezone.utc).isoformat(),
                'reviewedPhotoCount': len(records), 'catalogVenueCount': len(catalog),
                'source': 'Wikimedia Commons; branch matches reviewed in tool/data/venue_photo_sources.json',
                'displayChanges': 'Thumbnails displayed with cover cropping; originals and licenses linked in app.',
                'restaurants': records}
    output = ROOT / 'assets/data/restaurant_photos.json'
    temp = output.with_suffix('.tmp'); temp.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    temp.replace(output)
    credits = ['# Real venue photographs', '',
               'Each photo retains its own license. Commons thumbnails are displayed with cover cropping.',
               'Capture dates refer to the source, not the current appearance of the venue.', '']
    for venue_id, photo in records.items():
        credits += [f'## {photo["venueName"]} ({venue_id})', '',
                    f'- Author: {photo["author"]}', f'- License: {photo["license"]} — {photo["licenseUrl"]}',
                    f'- Source: {photo["sourceUrl"]}', f'- Captured: {photo["capturedAt"]}',
                    f'- Branch match reviewed: {photo["checkedAt"]}', '']
    (ROOT / 'assets/venue_photos/CREDITS.md').write_text('\n'.join(credits), encoding='utf-8')
    print(f'Imported {len(records)} real venue photos for {len(catalog)} catalog venues.')


if __name__ == '__main__':
    main()
