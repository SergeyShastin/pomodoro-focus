import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/core/updates/update_controller.dart';
import 'package:pomodoro_focus/core/updates/update_service.dart';
import 'package:pomodoro_focus/core/updates/update_widgets.dart';
import 'package:pomodoro_focus/features/settings/presentation/settings_provider.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Backend implements UpdateBackend {
  int downloads = 0, opens = 0;
  @override
  Future<String> currentVersion() async => '1.1.0';
  @override
  Future<ReleaseUpdate?> check(String currentVersion) async =>
      ReleaseUpdate('2.0.0', 'test.deb', Uri.https('github.com'), 100, 'hash');
  @override
  Future<File> download(
    ReleaseUpdate update,
    void Function(double) progress,
  ) async {
    downloads++;
    progress(1);
    return File('/tmp/update-widget.deb');
  }

  @override
  Future<void> openInstaller(File file) async {
    opens++;
  }
}

void main() {
  testWidgets(
    'update banner fits a narrow screen and preserves the current page',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'automatic_updates': false,
        'enable_notifications': false,
      });
      final prefs = await SharedPreferences.getInstance();
      final backend = Backend();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          updateBackendProvider.overrideWithValue(backend),
        ],
      );
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(380, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var count = 0;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => UpdateHost(child: child!),
            home: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => setState(() => count++),
                    child: Text('Page $count'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Page 0'));
      await tester.pumpAndSettle();
      await container.read(updateControllerProvider.notifier).check();
      await tester.pumpAndSettle();
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Version 2.0.0 is available'), findsOneWidget);
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Installer opened.'), findsOneWidget);
      expect(find.text('Page 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'manual update flow, installer status and persisted opt out at narrow width',
    (tester) async {
      SharedPreferences.setMockInitialValues({'automatic_updates': false});
      final prefs = await SharedPreferences.getInstance();
      final backend = Backend();
      tester.view.physicalSize = const Size(380, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            updateBackendProvider.overrideWithValue(backend),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(
              body: SingleChildScrollView(child: UpdatesSettingsCard()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check now'));
      await tester.pumpAndSettle();
      expect(find.text('Version 2.0.0 is available'), findsOneWidget);
      expect(backend.downloads, 0);
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect([backend.downloads, backend.opens], [1, 1]);
      expect(find.textContaining('Installer opened.'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(prefs.getBool('automatic_updates'), isTrue);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(prefs.getBool('automatic_updates'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
