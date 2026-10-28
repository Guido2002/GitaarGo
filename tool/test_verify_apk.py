import hashlib
from pathlib import Path
import tempfile
import unittest
import zipfile
from verify_apk import verify


class ApkTransferTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.apk = Path(self.temp.name) / 'GitaarGo.apk'
        with zipfile.ZipFile(self.apk, 'w') as archive:
            archive.writestr('AndroidManifest.xml', b'manifest')
            archive.writestr('classes.dex', b'classes')

    def test_complete_transfer_matches_published_digest(self):
        digest = hashlib.sha256(self.apk.read_bytes()).hexdigest()
        (self.apk.parent / 'SHA256SUMS.txt').write_text(f'{digest}  {self.apk.name}\n')
        self.assertEqual(verify(self.apk), digest)

    def test_truncated_transfer_is_rejected(self):
        self.apk.write_bytes(self.apk.read_bytes()[:-40])
        with self.assertRaisesRegex(ValueError, 'beschadigd of onvolledig'):
            verify(self.apk)

    def test_changed_transfer_is_rejected_even_if_zip_is_readable(self):
        (self.apk.parent / 'SHA256SUMS.txt').write_text(f'{"0" * 64}  {self.apk.name}\n')
        with self.assertRaisesRegex(ValueError, 'SHA256SUMS'):
            verify(self.apk)

    def test_other_zip_is_not_an_apk(self):
        with zipfile.ZipFile(self.apk, 'w') as archive:
            archive.writestr('readme.txt', b'not an apk')
        with self.assertRaisesRegex(ValueError, 'AndroidManifest.xml'):
            verify(self.apk)


if __name__ == '__main__':
    unittest.main()
