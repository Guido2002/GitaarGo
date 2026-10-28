"""Check a local APK before installation; no Android device is modified.

Like ChromecastRemote's updater, reject incomplete files before handing them
into Android. For local artifacts also compare the published SHA256SUMS entry.
ZIP integrity is not a substitute for Android's signing-certificate validation.
"""
import argparse
import hashlib
from pathlib import Path
import sys
import zipfile


def verify(apk: Path) -> str:
    if not apk.is_file():
        raise ValueError(f'APK niet gevonden: {apk}')
    hasher = hashlib.sha256()
    with apk.open('rb') as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b''):
            hasher.update(chunk)
    digest = hasher.hexdigest()
    checksums = apk.parent / 'SHA256SUMS.txt'
    if checksums.is_file():
        entries = []
        for line in checksums.read_text().splitlines():
            fields = line.split(maxsplit=1)
            if len(fields) == 2 and Path(fields[1].lstrip('*')).name == apk.name:
                entries.append(fields[0].lower())
        if entries and (len(set(entries)) != 1 or entries[0] != digest):
            raise ValueError('APK komt niet overeen met SHA256SUMS.txt. Kopieer/download het volledige oorspronkelijke bestand opnieuw.')
    try:
        with zipfile.ZipFile(apk) as archive:
            for required in ['AndroidManifest.xml', 'classes.dex']:
                if required not in archive.namelist() or archive.getinfo(required).file_size == 0:
                    raise ValueError(f'Ongeldige GitaarGo-APK: {required} ontbreekt of is leeg.')
            bad_file = archive.testzip()
            if bad_file:
                raise ValueError(f'Beschadigde APK-inhoud: {bad_file}. Download het bestand opnieuw.')
    except (zipfile.BadZipFile, EOFError, RuntimeError) as error:
        raise ValueError(f'APK is beschadigd of onvolledig: {error}') from error
    return digest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    args = parser.parse_args()
    try:
        digest = verify(args.apk)
    except (OSError, ValueError) as error:
        print(f'Installatie niet gestart: {error}', file=sys.stderr)
        return 1
    print(f'APK-bestandscontrole geslaagd. SHA-256: {digest}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
