import ocmbin
import json
import unittest


class OCMbinTest(unittest.TestCase):
    """
        Test whether JSON header is read correctly from the binary file
    """
    A = ocmbin.ocmbin('test.bin')

    with open('test_header.json', 'r') as f:
        header = json.JSONDecoder().decode(f.read())

    def test_json_read(self):
        self.assertEqual(
            self.header,
            self.A.metadata
        )
