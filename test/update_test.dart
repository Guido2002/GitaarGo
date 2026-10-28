import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gitaargo/features/update/update_service.dart';

Map<String, dynamic> releaseJson({
  String version = '0.3.0',
  String? digest,
  int size = 4,
}) => {
  'tag_name': 'v$version',
  'draft': false,
  'prerelease': false,
  'body': 'Nieuwe functies',
  'assets': [
    {
      'name': 'GitaarGo-$version.apk',
      'browser_download_url':
          'https://github.com/Guido2002/GitaarGo/releases/download/v$version/GitaarGo-$version.apk',
      'size': size,
      'digest': digest,
    },
    {
      'name': 'SHA256SUMS.txt',
      'browser_download_url':
          'https://github.com/Guido2002/GitaarGo/releases/download/v$version/SHA256SUMS.txt',
      'size': 90,
    },
  ],
};
void main() {
  test(
    'semver, oudere versie, draft en prerelease krijgen geen update',
    () async {
      for (final version in ['0.1.9', '0.2.0', '0.3.0', '0.10.0']) {
        final service = UpdateService(
          client: MockClient(
            (r) async =>
                http.Response(jsonEncode(releaseJson(version: version)), 200),
          ),
        );
        expect(
          await service.check('0.2.0'),
          version == '0.3.0' || version == '0.10.0' ? isNotNull : isNull,
        );
        service.close();
      }
      expect(AppRelease.parse(releaseJson()..['draft'] = true), isNull);
      expect(AppRelease.parse(releaseJson()..['prerelease'] = true), isNull);
    },
  );
  test('ontbrekende release is geen fout, API-fout wordt getoond', () async {
    final empty = UpdateService(
      client: MockClient((r) async => http.Response('', 404)),
    );
    expect(await empty.check('0.2.0'), isNull);
    empty.close();
    final failed = UpdateService(
      client: MockClient((r) async => http.Response('', 403)),
    );
    await expectLater(failed.check('0.2.0'), throwsA(isA<HttpException>()));
    failed.close();
  });
  test('selecteert de universele APK en weigert onverwachte downloadhost', () {
    final json = releaseJson();
    (json['assets'] as List).insert(0, {'name': 'GitaarGo-arm64.apk'});
    expect(AppRelease.parse(json)!.apk.name, 'GitaarGo-0.3.0.apk');
    json['assets'][1]['browser_download_url'] = 'https://example.com/fake.apk';
    expect(() => AppRelease.parse(json), throwsFormatException);
  });
  for (final scenario in [
    'valid',
    'truncated',
    'tampered',
    'cancel',
    'checksum-file',
  ]) {
    test('APK transfer: $scenario', () async {
      final dir = await Directory.systemTemp.createTemp('gitaargo-update');
      addTearDown(() => dir.delete(recursive: true));
      final bytes = [1, 2, 3, 4];
      final hash = sha256.convert(bytes).toString();
      final json = releaseJson(
        digest: scenario == 'checksum-file' ? null : 'sha256:$hash',
      );
      final release = AppRelease.parse(json)!;
      late UpdateService service;
      service = UpdateService(
        client: MockClient.streaming((request, body) async {
          if (request.url.path.endsWith('.txt')) {
            return http.StreamedResponse(
              Stream.value(utf8.encode('$hash  ${release.apk.name}\n')),
              200,
            );
          }
          final data = scenario == 'truncated'
              ? [1, 2]
              : scenario == 'tampered'
              ? [1, 2, 3, 5]
              : bytes;
          return http.StreamedResponse(Stream.value(data), 200);
        }),
      );
      addTearDown(service.close);
      Future<File> run() => service.download(
        release,
        dir,
        onProgress: scenario == 'cancel' ? (_) => service.close() : null,
      );
      if (scenario == 'valid' || scenario == 'checksum-file') {
        final file = await run();
        expect(await file.readAsBytes(), bytes);
        expect(
          await File('${dir.path}/gitaargo-update.apk.part').exists(),
          false,
        );
      } else {
        await expectLater(
          run(),
          throwsA(anyOf(isA<FormatException>(), isA<HttpException>())),
        );
        expect(await File('${dir.path}/gitaargo-update.apk').exists(), false);
        expect(
          await File('${dir.path}/gitaargo-update.apk.part').exists(),
          false,
        );
      }
    });
  }
  test('ontbrekende hash weigert installatiebestand', () async {
    final json = releaseJson();
    (json['assets'] as List).removeLast();
    final release = AppRelease.parse(json)!;
    final dir = await Directory.systemTemp.createTemp('gitaargo-update');
    addTearDown(() => dir.delete(recursive: true));
    final s = UpdateService(
      client: MockClient((r) async => http.Response('data', 200)),
    );
    addTearDown(s.close);
    await expectLater(s.download(release, dir), throwsFormatException);
  });
}
