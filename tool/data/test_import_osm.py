import json
from pathlib import Path
import tempfile
import unittest

from import_osm import export_catalog, is_venue, categories, representative_way, relation_polygon


class ImportTests(unittest.TestCase):
    def test_lifecycle_private_unnamed_and_category_mapping(self):
        self.assertFalse(is_venue({'amenity': 'restaurant'}))
        self.assertFalse(is_venue({'amenity': 'restaurant', 'name': 'Closed', 'disused': 'yes'}))
        self.assertFalse(is_venue({'amenity': 'cafe', 'name': 'Private', 'access': 'private'}))
        self.assertEqual(categories({'amenity': 'restaurant', 'name': 'Phở Bò'}), ['noodles'])
        self.assertEqual(categories({'amenity': 'restaurant', 'name': 'Nhà hàng An'}), ['other'])
        self.assertEqual(categories({'amenity': 'cafe', 'name': 'An'}), ['cafe'])

    def test_geometry_handles_missing_nodes_and_holes(self):
        self.assertIsNone(representative_way([1, 2, 3, 1], {}))
        coordinates = {1: (0, 0), 2: (10, 0), 3: (10, 10), 4: (0, 10),
                       5: (4, 4), 6: (6, 4), 7: (6, 6), 8: (4, 6)}
        geometry = relation_polygon([(1, 'outer'), (2, 'inner')],
                                    {1: [1, 2, 3, 4, 1], 2: [5, 6, 7, 8, 5]}, coordinates)
        self.assertEqual(geometry.area, 96)
        self.assertTrue(geometry.covers(geometry.representative_point()))

    def test_streaming_import_provenance_country_filter_and_unknown_fields(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / 'fixture.osm'
            nodes = [(1, 10, 100), (2, 10, 110), (3, 20, 110), (4, 20, 100),
                     (10, 15, 105), (11, 15, 105.1), (12, 15.1, 105.1), (13, 15.1, 105)]
            xml = ['<osm version="0.6" generator="test">']
            for oid, lat, lon in nodes:
                xml.append(f'<node id="{oid}" lat="{lat}" lon="{lon}" version="1"/>')
            xml += ['<node id="20" lat="16" lon="106" version="1"><tag k="amenity" v="restaurant"/><tag k="name" v="Phở Test"/></node>',
                    '<node id="21" lat="5" lon="5" version="1"><tag k="amenity" v="cafe"/><tag k="name" v="Outside"/></node>',
                    '<node id="22" lat="16" lon="106" version="1"><tag k="amenity" v="restaurant"/><tag k="name" v="Phở Test"/></node>',
                    '<way id="100" version="1"><nd ref="1"/><nd ref="2"/><nd ref="3"/><nd ref="4"/><nd ref="1"/></way>',
                    '<way id="101" version="1"><nd ref="10"/><nd ref="11"/><nd ref="12"/><nd ref="13"/><nd ref="10"/><tag k="name" v="Cafe Test"/><tag k="amenity" v="cafe"/></way>']
            for rid, level, name in [(1, 2, 'Vietnam'), (2, 4, 'Province'), (3, 8, 'Ward')]:
                xml.append(f'<relation id="{rid}" version="1"><member type="way" ref="100" role="outer"/>'
                           f'<tag k="type" v="multipolygon"/><tag k="boundary" v="administrative"/>'
                           f'<tag k="admin_level" v="{level}"/><tag k="ISO3166-1" v="VN"/><tag k="name" v="{name}"/></relation>')
            xml.append('</osm>')
            source.write_text('\n'.join(xml), encoding='utf-8')
            output = root / 'real_restaurants.json'
            manifest = export_catalog(source, output)
            venues = json.loads(output.read_text(encoding='utf-8'))
            self.assertEqual(len(venues), 2)
            self.assertEqual(manifest['importDiagnostics']['outside_vietnam_boundary'], 1)
            self.assertEqual(manifest['importDiagnostics']['duplicate_name_position'], 1)
            for venue in venues:
                self.assertEqual(venue['province'], 'Province')
                self.assertEqual(venue['area'], 'Ward')
                self.assertIsNone(venue['rating'])
                self.assertIsNone(venue['priceMin'])
                self.assertEqual(venue['imageUrl'], '')
                self.assertTrue(venue['sourceUrl'].startswith('https://www.openstreetmap.org/'))


if __name__ == '__main__':
    unittest.main()
