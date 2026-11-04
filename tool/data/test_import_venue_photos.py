import unittest
from import_venue_photos import photo_record


class PhotoImportTest(unittest.TestCase):
    def setUp(self):
        self.review = {'file': 'File:Reviewed cafe.jpg', 'caption': 'Cafe at verified address',
                       'matchEvidence': 'Name, street and coordinates agree'}
        self.page = {'title': self.review['file'], 'imageinfo': [{
            'descriptionurl': 'https://commons.wikimedia.org/wiki/File:Reviewed_cafe.jpg',
            'url': 'https://upload.wikimedia.org/wikipedia/commons/a/ab/Reviewed_cafe.jpg',
            'extmetadata': {'LicenseShortName': {'value': 'CC BY-SA 4.0'},
                            'LicenseUrl': {'value': 'https://creativecommons.org/licenses/by-sa/4.0/'},
                            'Artist': {'value': '<a href="https://example.org">Photographer</a>'},
                            'DateTimeOriginal': {'value': '2024-01-02'}},
        }]}

    def test_author_is_plain_text_and_credit_is_retained(self):
        result = photo_record('osm-node-123', self.review, self.page, '2026-11-04')
        self.assertEqual(result['author'], 'Photographer')
        self.assertEqual(result['capturedAt'], '2024-01-02')
        self.assertEqual(result['license'], 'CC BY-SA 4.0')

    def test_rejects_missing_branch_evidence(self):
        with self.assertRaises(ValueError):
            photo_record('osm-node-123', self.review | {'matchEvidence': ''}, self.page, '2026-11-04')

    def test_rejects_unapproved_license_and_renamed_file(self):
        self.page['imageinfo'][0]['extmetadata']['LicenseShortName']['value'] = 'All rights reserved'
        with self.assertRaises(ValueError):
            photo_record('osm-node-123', self.review, self.page, '2026-11-04')
        with self.assertRaises(ValueError):
            photo_record('osm-node-123', self.review | {'file': 'File:Other branch.jpg'}, self.page, '2026-11-04')


if __name__ == '__main__':
    unittest.main()
