// Run after publishing the first release. Uses the actual public, signed APK.
// On the test emulator allow GitaarGo's install permission before running:
// adb shell appops set nl.gitaargo.gitaargo REQUEST_INSTALL_PACKAGES allow
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gitaargo/features/update/update_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'public signed APK downloads, verifies and opens Android installer',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('GitaarGo installercontrole')),
        ),
      );
      await tester.runAsync(() async {
        final info = await PackageInfo.fromPlatform();
        expect(info.packageName, 'nl.gitaargo.gitaargo');
        final service = UpdateService();
        try {
          final release = await service.check('0.0.0');
          expect(
            release,
            isNotNull,
            reason: 'Publiceer eerst een stabiele release met APK.',
          );
          final file = await service.download(
            release!,
            Directory(
              '${(await getTemporaryDirectory()).path}/gitaargo-updates',
            ),
          );
          expect(await file.length(), release.apk.size);
          final launch = await OpenFilex.open(
            file.path,
            type: 'application/vnd.android.package-archive',
          );
          expect(launch.type, ResultType.done, reason: launch.message);
          // The OS confirmation screen is deliberately left to the user. A
          // successful handoff is not reported as a completed app installation.
        } finally {
          service.close();
        }
      });
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
