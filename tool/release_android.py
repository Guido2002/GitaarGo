#!/usr/bin/env python3
"""Build and publish an immutable GitHub release using this Mac's signing key.

Bump pubspec.yaml, commit changes, then run:
  python3 tool/release_android.py --publish
Credentials are obtained from git's credential helper, never written to files.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parent.parent
REPO = 'Guido2002/GitaarGo'
API = f'https://api.github.com/repos/{REPO}'


def run(*args, capture=False):
    result = subprocess.run(args, cwd=ROOT, check=True, text=True,
                            stdout=subprocess.PIPE if capture else None)
    return result.stdout.strip() if capture else None


def credentials():
    token = os.environ.get('GH_TOKEN') or os.environ.get('GITHUB_TOKEN')
    if not token:
        result = subprocess.run(['git', 'credential', 'fill'],
            input='protocol=https\nhost=github.com\n\n', text=True,
            capture_output=True, env={**os.environ, 'GIT_TERMINAL_PROMPT':'0'})
        fields = dict(line.split('=', 1) for line in result.stdout.splitlines() if '=' in line)
        token = fields.get('password')
    if not token:
        raise RuntimeError('Geen GitHub-credential beschikbaar via git credential helper of GH_TOKEN.')
    return token


def request(token, url, *, method='GET', data=None, content_type='application/json'):
    if isinstance(data, dict):
        data = json.dumps(data).encode()
    req = urllib.request.Request(url, data=data, method=method, headers={
        'Authorization':f'Bearer {token}', 'Accept':'application/vnd.github+json',
        'User-Agent':'GitaarGo-release', 'Content-Type':content_type,
        'X-GitHub-Api-Version':'2022-11-28'})
    try:
        with urllib.request.urlopen(req, timeout=180) as response:
            body=response.read()
            return json.loads(body) if body else None
    except urllib.error.HTTPError as error:
        if error.code == 404 and method == 'GET':
            return None
        raise RuntimeError(f'GitHub {method} mislukt (HTTP {error.code}): {error.read(600).decode(errors="replace")}') from None


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--publish', action='store_true', help='Push commit/tag en publiceer APK op GitHub.')
    parser.add_argument('--skip-build', action='store_true', help='Gebruik de reeds gecontroleerde release-APK.')
    args=parser.parse_args()
    os.chdir(ROOT)
    match=re.search(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$', (ROOT/'pubspec.yaml').read_text(), re.M)
    if not match:
        raise RuntimeError('pubspec.yaml moet een stabiele versie major.minor.patch+build bevatten.')
    version, build=match.groups()
    tag=f'v{version}'
    notes=ROOT/f'docs/releases/{version}.md'
    if not notes.is_file():
        raise RuntimeError(f'Release-notities ontbreken: {notes.relative_to(ROOT)}')
    token=credentials() if args.publish else None
    if args.publish:
        repository=request(token,API)
        if not repository or repository.get('private',True):
            raise RuntimeError('De downloadrepository is privé. De updater heeft een publieke release-host nodig; publiceer geen onbereikbare update.')
    existing=request(token, f'{API}/releases/tags/{tag}') if args.publish else None
    if existing and not existing['draft']:
        raise RuntimeError('Deze versie is al gepubliceerd. Verhoog versie én buildnummer; vervang geen gepubliceerde APK.')
    if args.publish and run('git','status','--porcelain',capture=True):
        raise RuntimeError('Commit eerst alle bronwijzigingen. Een release moet bij een exacte schone commit horen.')
    head=run('git','rev-parse','HEAD',capture=True)
    if not args.skip_build:
        run('flutter','pub','get')
        run('flutter','analyze')
        run('flutter','test')
        run('flutter','build','apk','--release')
    source=ROOT/'build/app/outputs/flutter-apk/app-release.apk'
    if not source.is_file():
        raise RuntimeError('Geen release-APK gevonden.')
    # Match package/version/build before attaching any binary to the release.
    sdk_line=next(line for line in (ROOT/'android/local.properties').read_text().splitlines() if line.startswith('sdk.dir='))
    sdk=Path(sdk_line.split('=',1)[1])
    tools=sorted((sdk/'build-tools').iterdir(), key=lambda p:tuple(int(n) for n in re.findall(r'\d+',p.name)))
    badging=run(str(tools[-1]/'aapt'),'dump','badging',str(source),capture=True)
    if not all(value in badging for value in ["name='nl.gitaargo.gitaargo'", f"versionName='{version}'", f"versionCode='{build}'"]):
        raise RuntimeError('APK package/versie/build komen niet overeen met pubspec.yaml.')
    abi_line=next((line for line in badging.splitlines() if line.startswith('native-code:')), '')
    if set(re.findall(r"'([^']+)'",abi_line)) != {'armeabi-v7a','arm64-v8a','x86_64'}:
        raise RuntimeError('Publiceer een universele APK met alle drie Flutter-architecturen.')
    # Use Flutter's configured Java installation for apksigner on macOS too.
    flutter_config=json.loads(run('flutter','config','--machine',capture=True))
    java=flutter_config.get('jdk-dir')
    env={**os.environ}
    if java:
        env['JAVA_HOME']=java
    subprocess.run([str(tools[-1]/'apksigner'),'verify','--verbose',str(source)],check=True,env=env)
    run(str(tools[-1]/'zipalign'),'-c','-P','16','4',str(source))
    destination=ROOT/'build/releases'
    destination.mkdir(parents=True,exist_ok=True)
    apk=destination/f'GitaarGo-{version}.apk'
    apk.write_bytes(source.read_bytes())
    digest=hashlib.sha256(apk.read_bytes()).hexdigest()
    checksums=destination/'SHA256SUMS.txt'
    checksums.write_text(f'{digest}  {apk.name}\n')
    run('python3','tool/verify_apk.py',str(apk))
    if not args.publish:
        print(f'Releasebestanden gebouwd: {apk.relative_to(ROOT)}',flush=True)
        return
    # Never overwrite an existing tag that refers to another source snapshot.
    tag_result=subprocess.run(['git','rev-parse',f'{tag}^{{commit}}'],cwd=ROOT,capture_output=True,text=True)
    if tag_result.returncode==0 and tag_result.stdout.strip()!=head:
        raise RuntimeError('Bestaande tag wijst naar een andere commit.')
    if tag_result.returncode!=0:
        run('git','tag','-a',tag,'-m',f'GitaarGo {version}')
    run('git','push','--atomic','origin','HEAD',f'refs/tags/{tag}')
    release=existing or request(token,f'{API}/releases',method='POST',data={
        'tag_name':tag,'target_commitish':head,'name':f'GitaarGo {version}',
        'body':notes.read_text(),'draft':True,'prerelease':False})
    upload_base=release['upload_url'].split('{',1)[0]
    for asset in [apk,checksums]:
        expected='sha256:'+hashlib.sha256(asset.read_bytes()).hexdigest()
        found=next((a for a in release.get('assets',[]) if a['name']==asset.name),None)
        if found:
            if found.get('digest')!=expected:
                raise RuntimeError(f'Draft bevat al een afwijkend bestand: {asset.name}')
            continue
        print(f'Uploaden: {asset.name}',flush=True)
        uploaded=request(token,upload_base+'?'+urllib.parse.urlencode({'name':asset.name}),
            method='POST',data=asset.read_bytes(),content_type='application/vnd.android.package-archive' if asset.suffix=='.apk' else 'text/plain')
        if uploaded.get('digest')!=expected:
            raise RuntimeError('GitHub-uploadchecksum wijkt af; release blijft concept.')
    # Publish only after both assets were uploaded and verified.
    result=request(token,f"{API}/releases/{release['id']}",method='PATCH',data={'draft':False,'make_latest':'true'})
    print(f"Release gepubliceerd: {result['html_url']}",flush=True)


if __name__=='__main__':
    try:
        main()
    except (RuntimeError, subprocess.CalledProcessError, OSError) as error:
        print(f'Release gestopt: {error}',file=sys.stderr)
        sys.exit(1)
