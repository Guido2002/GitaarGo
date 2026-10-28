import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';

const releaseRepository = 'Guido2002/GitaarGo';
const releaseApi =
    'https://api.github.com/repos/$releaseRepository/releases/latest';
const releasesPage = 'https://github.com/$releaseRepository/releases';

class ReleaseAsset {
  final String name;
  final Uri url;
  final int size;
  final String? sha256;
  const ReleaseAsset(this.name, this.url, this.size, this.sha256);
  factory ReleaseAsset.fromJson(Map<String, dynamic> j) {
    final name = j['name'] as String;
    final url = Uri.parse(j['browser_download_url'] as String);
    if (url.scheme != 'https' ||
        url.host != 'github.com' ||
        !url.path.startsWith('/$releaseRepository/releases/download/')) {
      throw const FormatException('Onverwachte downloadlocatie.');
    }
    final size = j['size'] as int;
    if (size <= 0 || size > 250 * 1024 * 1024) {
      throw const FormatException('Ongeldige bestandsgrootte.');
    }
    final digest = j['digest'];
    final hash =
        digest is String && RegExp(r'^sha256:[a-fA-F0-9]{64}$').hasMatch(digest)
        ? digest.substring(7).toLowerCase()
        : null;
    return ReleaseAsset(name, url, size, hash);
  }
}

class AppRelease {
  final Version version;
  final String notes;
  final ReleaseAsset apk;
  final ReleaseAsset? checksums;
  const AppRelease(this.version, this.notes, this.apk, this.checksums);
  static AppRelease? parse(Map<String, dynamic> j) {
    if (j['draft'] == true || j['prerelease'] == true) return null;
    final version = Version.parse(
      (j['tag_name'] as String).replaceFirst(RegExp(r'^v'), ''),
    );
    if (version.isPreRelease) return null;
    final assets = (j['assets'] as List).cast<Map<String, dynamic>>();
    final apkName = 'GitaarGo-$version.apk';
    final candidates = assets.where((a) => a['name'] == apkName);
    if (candidates.length != 1) {
      throw const FormatException(
        'De release bevat geen universele GitaarGo-APK.',
      );
    }
    final hashes = assets.where((a) => a['name'] == 'SHA256SUMS.txt');
    return AppRelease(
      version,
      j['body'] as String? ?? '',
      ReleaseAsset.fromJson(candidates.single),
      hashes.isEmpty ? null : ReleaseAsset.fromJson(hashes.single),
    );
  }
}

/// Optional network functionality; no microphone audio or practice data leaves
/// the device. Cancellation closes the HTTP client and removes partial files.
class UpdateService {
  final http.Client client;
  final Duration timeout;
  bool _cancelled = false;
  UpdateService({
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : client = client ?? http.Client();
  static const _headers = {
    'User-Agent': 'GitaarGo-updater',
    'Accept': 'application/vnd.github+json',
  };
  Future<AppRelease?> check(String installed) async {
    final response = await client
        .get(Uri.parse(releaseApi), headers: _headers)
        .timeout(timeout);
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw HttpException(
        'Updates ophalen mislukt (HTTP ${response.statusCode}). Probeer later opnieuw.',
      );
    }
    final release = AppRelease.parse(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    return release != null && release.version > Version.parse(installed)
        ? release
        : null;
  }

  Future<String> _expectedHash(AppRelease release) async {
    if (release.apk.sha256 != null) return release.apk.sha256!;
    final asset = release.checksums;
    if (asset == null) {
      throw const FormatException(
        'Deze release mist een controlegetal. Download wordt niet geïnstalleerd.',
      );
    }
    final response = await client
        .get(asset.url, headers: _headers)
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw const HttpException('Controlebestand kon niet worden opgehaald.');
    }
    for (final line in const LineSplitter().convert(response.body)) {
      final match = RegExp(r'^([a-fA-F0-9]{64})\s+\*?(.+)$').firstMatch(line);
      if (match != null && match.group(2) == release.apk.name) {
        return match.group(1)!.toLowerCase();
      }
    }
    throw const FormatException('Geen passend controlegetal voor deze APK.');
  }

  Future<File> download(
    AppRelease release,
    Directory directory, {
    void Function(double)? onProgress,
  }) async {
    await directory.create(recursive: true);
    // Fixed basename avoids trusting a remotely supplied filesystem path.
    final part = File('${directory.path}/gitaargo-update.apk.part');
    final complete = File('${directory.path}/gitaargo-update.apk');
    try {
      final expected = await _expectedHash(release);
      if (_cancelled) throw const HttpException('Download geannuleerd.');
      final request = http.Request('GET', release.apk.url)
        ..headers.addAll(_headers);
      final response = await client.send(request).timeout(timeout);
      if (response.statusCode != 200) {
        throw HttpException('Download mislukt (HTTP ${response.statusCode}).');
      }
      if (response.contentLength != null &&
          response.contentLength != release.apk.size) {
        throw const FormatException(
          'De downloadgrootte wijkt af van de release.',
        );
      }
      final hashOutput = _DigestReceiver();
      final hasher = sha256.startChunkedConversion(hashOutput);
      final sink = part.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.stream.timeout(timeout)) {
          if (_cancelled) throw const HttpException('Download geannuleerd.');
          received += chunk.length;
          if (received > release.apk.size) {
            throw const FormatException('Download is groter dan verwacht.');
          }
          hasher.add(chunk);
          sink.add(chunk);
          onProgress?.call(received / release.apk.size);
        }
        await sink.flush();
      } finally {
        hasher.close();
        await sink.close();
      }
      if (received != release.apk.size) {
        throw const FormatException(
          'De APK-download is onvolledig. Probeer opnieuw.',
        );
      }
      if (hashOutput.digest.toString() != expected) {
        throw const FormatException(
          'APK-controle mislukt. Het bestand wordt niet geïnstalleerd.',
        );
      }
      if (_cancelled) throw const HttpException('Download geannuleerd.');
      if (await complete.exists()) await complete.delete();
      return await part.rename(complete.path);
    } catch (_) {
      if (await part.exists()) await part.delete();
      rethrow;
    }
  }

  void close() {
    _cancelled = true;
    client.close();
  }
}

class _DigestReceiver implements Sink<Digest> {
  Digest? digest;
  @override
  void add(Digest data) {
    digest = data;
  }

  @override
  void close() {}
}
