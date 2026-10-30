"""Extract named dining venues from Vietnam OSM, without loading all nodes in RAM.

Three streaming passes collect venue/boundary references, the required ways,
then only their node coordinates. No private OSM contributor metadata is used.
"""
from __future__ import annotations

import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import unicodedata

import osmium
from shapely import make_valid, prepare
from shapely.geometry import LineString, Point, Polygon
from shapely.ops import polygonize, unary_union
from shapely.strtree import STRtree

AMENITIES = {'restaurant', 'fast_food', 'cafe', 'food_court', 'ice_cream'}
ROOT = Path(__file__).resolve().parents[2]
UNKNOWN_PROVINCE = 'Chưa rõ tỉnh/thành'
UNKNOWN_AREA = 'Chưa rõ khu vực'


def text(value: str) -> str:
    return unicodedata.normalize('NFC', ' '.join(value.split())).strip()


def is_venue(tags: dict[str, str]) -> bool:
    return (tags.get('amenity') in AMENITIES
            and bool(text(tags.get('name:vi') or tags.get('name', '')))
            and tags.get('disused') != 'yes' and tags.get('abandoned') != 'yes'
            and tags.get('access') not in {'private', 'no'}
            and tags.get('addr:country', 'VN').upper() in {'VN', 'VIETNAM'})


class CatalogScan(osmium.SimpleHandler):
    def __init__(self):
        super().__init__()
        self.points = []
        self.ways = {}
        self.relations = {}
        self.boundaries = {}
        self.counts = Counter()

    def node(self, node):
        if node.tags.get('amenity') not in AMENITIES:
            return
        tags = dict(node.tags)
        self.counts['dining_nodes_seen'] += 1
        if is_venue(tags) and node.location.valid():
            self.points.append(('node', node.id, tags,
                                (node.location.lon, node.location.lat), str(node.timestamp)))

    def way(self, way):
        if way.tags.get('amenity') in AMENITIES:
            self.counts['dining_ways_seen'] += 1
            tags = dict(way.tags)
            if is_venue(tags):
                self.ways[way.id] = (tags, [n.ref for n in way.nodes], str(way.timestamp))

    def relation(self, relation):
        tags = dict(relation.tags)
        members = [(m.ref, m.role) for m in relation.members if m.type == 'w']
        if is_venue(tags):
            self.relations[relation.id] = (tags, members, str(relation.timestamp))
        if (tags.get('boundary') == 'administrative'
                and tags.get('admin_level') in {'2', '4', '6', '8'}):
            self.boundaries[relation.id] = (tags, members)


class WayScan(osmium.SimpleHandler):
    def __init__(self, wanted):
        super().__init__()
        self.wanted = wanted
        self.ways = {}

    def way(self, way):
        if way.id in self.wanted:
            self.ways[way.id] = [n.ref for n in way.nodes]


class NodeScan(osmium.SimpleHandler):
    def __init__(self, wanted):
        super().__init__()
        self.wanted = wanted
        self.coordinates = {}

    def node(self, node):
        if node.id in self.wanted and node.location.valid():
            self.coordinates[node.id] = (node.location.lon, node.location.lat)


def relation_polygon(members, ways, coordinates):
    outers, inners = [], []
    for way_id, role in members:
        refs = ways.get(way_id, [])
        if len(refs) < 2 or any(ref not in coordinates for ref in refs):
            continue
        line = LineString([coordinates[ref] for ref in refs])
        (inners if role == 'inner' else outers).append(line)
    if not outers:
        return None
    polygons = list(polygonize(outers))
    if not polygons:
        return None
    shape = make_valid(unary_union(polygons))
    if inners:
        shape = make_valid(shape.difference(unary_union(list(polygonize(inners)))))
    return shape if not shape.is_empty else None


def representative_way(refs, coordinates):
    if len(refs) < 3 or refs[0] != refs[-1] or any(r not in coordinates for r in refs):
        return None
    shape = make_valid(Polygon([coordinates[r] for r in refs]))
    if shape.is_empty:
        return None
    point = shape.representative_point()
    return point.x, point.y


def normalized(value):
    value = value.lower().replace('đ', 'd')
    return ''.join(c for c in unicodedata.normalize('NFD', value)
                   if unicodedata.category(c) != 'Mn')


def categories(tags):
    """Infer only a cuisine/category, never infer a price, rating or exact dish."""
    if tags.get('amenity') == 'cafe':
        return ['cafe']
    if tags.get('amenity') == 'ice_cream':
        return ['dessert']
    cuisine = normalized(tags.get('cuisine', ''))
    name = normalized(tags.get('name:vi') or tags.get('name', ''))
    haystack = ' ' + name + ' ' + cuisine + ' '
    rules = {
        'noodles': ['pho ', 'bun ', 'noodle', 'ramen', 'mi quang', 'hu tieu'],
        'rice': ['com ', 'rice'],
        'hotpot': ['lau ', 'hotpot', 'hot_pot'],
        'grill': ['nuong', 'barbecue', 'bbq', 'grill'],
        'bread': ['banh mi', 'sandwich'],
        'healthy': ['vegan', 'vegetarian', 'salad', ' com chay', ' quan chay'],
        'dessert': ['ice_cream', 'dessert', 'bakery', ' che '],
    }
    result = {category for category, words in rules.items() if any(word in haystack for word in words)}
    return sorted(result) or ['other']


def address(tags):
    street = text(' '.join(filter(None, [tags.get('addr:housenumber'), tags.get('addr:street')
                                       or tags.get('addr:place')])))
    return text(tags.get('addr:full', '')) or street or 'Chưa có địa chỉ trong OpenStreetMap'


def export_catalog(path: Path, output: Path):
    reader = osmium.io.Reader(str(path))
    header = reader.header()
    snapshot = header.get('osmosis_replication_timestamp') or None
    reader.close()
    print('Pass 1/3: dining venues and administrative boundaries', flush=True)
    scan = CatalogScan()
    scan.apply_file(str(path))
    wanted_ways = {wid for _, members in scan.boundaries.values() for wid, _ in members}
    wanted_ways.update(wid for _, members, _ in scan.relations.values() for wid, _ in members)
    print(f'Pass 2/3: {len(wanted_ways)} boundary/relation ways', flush=True)
    way_scan = WayScan(wanted_ways)
    way_scan.apply_file(str(path))
    ways = way_scan.ways
    ways.update({wid: refs for wid, (_, refs, _) in scan.ways.items()})
    wanted_nodes = {node for refs in ways.values() for node in refs}
    print(f'Pass 3/3: {len(wanted_nodes)} required node positions', flush=True)
    node_scan = NodeScan(wanted_nodes)
    node_scan.apply_file(str(path))
    coordinates = node_scan.coordinates
    print(f'Building {len(scan.boundaries)} boundary geometries', flush=True)
    shapes, boundary_tags = [], []
    country = None
    for tags, members in scan.boundaries.values():
        shape = relation_polygon(members, ways, coordinates)
        if shape is None:
            scan.counts['boundary_geometry_unavailable'] += 1
            continue
        prepare(shape)
        if tags.get('admin_level') == '2':
            if tags.get('ISO3166-1') == 'VN' or tags.get('ISO3166-1:alpha2') == 'VN':
                country = shape
            continue
        shapes.append(shape)
        boundary_tags.append(tags)
    if country is None:
        raise ValueError('Vietnam country boundary unavailable; refusing unverified country coverage')
    tree = STRtree(shapes)

    def area_names(point, tags):
        matches = [boundary_tags[int(i)] for i in tree.query(point)
                   if shapes[int(i)].covers(point)]
        province = next((text(t.get('name:vi') or t.get('name', '')) for t in matches
                         if t.get('admin_level') == '4'), '')
        # Use neutral "area": historical district and current ward boundaries may coexist.
        local = sorted((t for t in matches if t.get('admin_level') in {'6', '8'}),
                       key=lambda t: int(t['admin_level']), reverse=True)
        area = text(local[0].get('name:vi') or local[0].get('name', '')) if local else ''
        return (province or text(tags.get('addr:province', '')) or UNKNOWN_PROVINCE,
                area or text(tags.get('addr:suburb') or tags.get('addr:district')
                             or tags.get('addr:city', '')) or UNKNOWN_AREA)

    candidates = list(scan.points)
    relation_members = set()
    for rid, (tags, members, updated) in scan.relations.items():
        shape = relation_polygon(members, ways, coordinates)
        if shape is None:
            scan.counts['venue_relation_geometry_unavailable'] += 1
            continue
        point = shape.representative_point()
        candidates.append(('relation', rid, tags, (point.x, point.y), updated))
        relation_members.update(wid for wid, _ in members)
    for wid, (tags, refs, updated) in scan.ways.items():
        if wid in relation_members:
            continue
        point = representative_way(refs, coordinates)
        if point is not None:
            candidates.append(('way', wid, tags, point, updated))
        else:
            scan.counts['venue_way_geometry_unavailable'] += 1

    fetched = datetime.now(timezone.utc).isoformat()
    venues, seen = [], set()
    print(f'Validating country membership for {len(candidates)} dining candidates', flush=True)
    for kind, oid, tags, (lon, lat), updated in candidates:
        if not (math.isfinite(lon) and math.isfinite(lat) and country.covers(Point(lon, lat))):
            scan.counts['outside_vietnam_boundary'] += 1
            continue
        name = text(tags.get('name:vi') or tags['name'])
        # Deduplicate the common node + building outline representation, ~1m precision.
        fingerprint = (normalized(name), round(lat, 5), round(lon, 5))
        if fingerprint in seen:
            scan.counts['duplicate_name_position'] += 1
            continue
        seen.add(fingerprint)
        province, area = area_names(Point(lon, lat), tags)
        source_url = f'https://www.openstreetmap.org/{kind}/{oid}'
        cuisine_tags = [text(c.replace('_', ' ')) for c in tags.get('cuisine', '').split(';') if c]
        links = []
        for key in ['contact:tiktok', 'tiktok']:
            value = tags.get(key, '')
            if value.startswith('https://www.tiktok.com/@') or value.startswith('https://tiktok.com/@'):
                links.append({'platform': 'tiktok', 'url': value, 'label': 'TikTok từ OpenStreetMap'})
        venues.append({
            'id': f'osm-{kind}-{oid}', 'name': name,
            'description': 'Địa điểm được ghi nhận trên OpenStreetMap; chưa xác minh hoạt động hiện tại.',
            'imageUrl': '', 'country': 'VN', 'latitude': round(lat, 7), 'longitude': round(lon, 7),
            'address': address(tags), 'province': province, 'area': area,
            'categories': categories(tags), 'tags': cuisine_tags,
            'priceMin': None, 'priceMax': None, 'rating': None, 'reviewCount': None,
            'openingHours': tags.get('opening_hours') or None,
            'phone': tags.get('contact:phone') or tags.get('phone') or None,
            'mapUrl': None, 'mealTimes': [], 'companions': [],
            'sourceName': 'OpenStreetMap', 'sourceUrl': source_url,
            'sourceUpdatedAt': updated, 'sourceSnapshotAt': snapshot, 'importedAt': fetched,
            'sourceLinks': links,
        })
    venues.sort(key=lambda r: (r['province'], r['area'], r['name'], r['id']))
    if not venues:
        raise ValueError('No real venues extracted; refusing to replace the catalog')
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix('.json.tmp')
    temporary.write_text(json.dumps(venues, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    temporary.replace(output)
    counts = Counter(v['province'] for v in venues)
    with path.open('rb') as source_stream:
        input_sha256 = hashlib.file_digest(source_stream, 'sha256').hexdigest()
    manifest = {
        'source': 'OpenStreetMap contributors / Geofabrik Vietnam extract',
        'downloadUrl': 'https://download.geofabrik.de/asia/vietnam-latest.osm.pbf',
        'sourceSnapshotAt': snapshot, 'importedAt': fetched,
        'inputSha256': input_sha256,
        'license': 'ODbL-1.0', 'licenseUrl': 'https://opendatacommons.org/licenses/odbl/1-0/',
        'attribution': '© OpenStreetMap contributors',
        'attributionUrl': 'https://www.openstreetmap.org/copyright',
        'namedDiningVenues': len(venues), 'provinceCounts': dict(sorted(counts.items())),
        'importDiagnostics': dict(scan.counts), 'namedVenuesOnly': True,
        'coverageNote': 'All qualifying named dining objects in this extract, not all operating restaurants in Vietnam.',
        'tiktokLinkCount': sum(len(v['sourceLinks']) for v in venues),
        'unknownPriceCount': len(venues), 'unknownRatingCount': len(venues),
    }
    output.with_name('catalog_manifest.json').write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'Imported {len(venues)} real OSM venues across {len(counts)} province labels.', flush=True)
    return manifest


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path)
    parser.add_argument('--output', type=Path, default=ROOT / 'assets/data/real_restaurants.json')
    args = parser.parse_args()
    export_catalog(args.input, args.output)
