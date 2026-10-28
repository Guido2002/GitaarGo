// Device test of the native FileProvider handoff without requiring a public
// release. Copy a verified APK into the test app's update cache while it waits.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('verified local APK opens Android package installer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Installatiecontrole'))),
    );
    await tester.runAsync(() async {
      final file = File(
        '${(await getTemporaryDirectory()).path}/gitaargo-updates/installer-test.apk',
      );
      // The host writes atomically to .ready after transferring all APK bytes.
      final ready = File('${file.path}.ready');
      for (var i = 0; i < 300 && !await ready.exists(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      expect(
        await ready.exists(),
        true,
        reason: 'Geen geverifieerde APK van de testhost ontvangen.',
      );
      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );
      expect(result.type, ResultType.done, reason: result.message);
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
