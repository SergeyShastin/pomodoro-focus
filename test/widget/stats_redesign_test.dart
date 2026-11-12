import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/core/database/app_database.dart';
import 'package:pomodoro_focus/core/desktop/linux_screen_power_service.dart';
import 'package:pomodoro_focus/features/settings/presentation/settings_screen.dart';
import 'package:pomodoro_focus/core/theme/app_theme.dart';
import 'package:pomodoro_focus/features/settings/presentation/goal_setting_tile.dart';
import 'package:pomodoro_focus/features/settings/presentation/settings_provider.dart';
import 'package:pomodoro_focus/features/stats/domain/focus_stats.dart';
import 'package:pomodoro_focus/features/stats/presentation/stats_provider.dart';
import 'package:pomodoro_focus/features/stats/presentation/stats_screen.dart';
import 'package:pomodoro_focus/features/stats/presentation/widgets/daily_focus_chart.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

FocusStatsSummary sampleSummary() => FocusStatsSummary(
      todayPomodoros: 5,
      todayMinutes: 125,
      weekPomodoros: 23,
      weekMinutes: 575,
      last7Days: List.generate(
          7,
          (i) => DailyFocusItem(
              date: DateTime(2026, 11, 6 + i),
              minutes: [50, 100, 0, 150, 75, 225, 125][i],
              pomodorosCount: [2, 4, 0, 6, 3, 9, 5][i])),
    );

void main() {
  setUpAll(() async {
    // Use real font glyphs for local visual QA; CI can use the test font.
    final font = File('/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf');
    if (await font.exists()) {
      final loader = FontLoader('VisualQANoto');
      loader.addFont(font.readAsBytes().then(ByteData.sublistView));
      await loader.load();
    }
    final configFile = File('.dart_tool/package_config.json').absolute;
    final config =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    final flutter = (config['packages'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((package) => package['name'] == 'flutter');
    final sdk =
        Directory.fromUri(configFile.uri.resolve(flutter['rootUri'] as String))
            .parent
            .parent;
    final icons = File(
        '${sdk.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (await icons.exists()) {
      final loader = FontLoader('MaterialIcons');
      loader.addFont(icons.readAsBytes().then(ByteData.sublistView));
      await loader.load();
    }
  });
  for (final scenario in [
    (
      name: 'desktop-light',
      width: 1440.0,
      height: 1400.0,
      scale: 1.2,
      dark: false
    ),
    (
      name: 'desktop-oled',
      width: 1440.0,
      height: 1400.0,
      scale: 1.2,
      dark: true
    ),
    (
      name: 'narrow-large-text',
      width: 380.0,
      height: 900.0,
      scale: 1.5,
      dark: false
    ),
  ]) {
    testWidgets('stats ${scenario.name}: readable counts, targets and chart',
        (tester) async {
      final oldShadows = debugDisableShadows;
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = oldShadows);
      tester.view.physicalSize = Size(scenario.width, scenario.height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues(
          {'automatic_updates': false, 'font_scale': scenario.scale});
      final prefs = await SharedPreferences.getInstance();
      final repaint = GlobalKey();
      final summary = sampleSummary();
      final sessions = List.generate(
          5,
          (i) => FocusSession(
              id: i,
              taskName: [
                'App development',
                'Reading and notes',
                '',
                'Planning',
                'Project work'
              ][i],
              phase: 'work',
              startTime: DateTime(2026, 11, 12, 14 - i, 0),
              endTime: DateTime(2026, 11, 12, 14 - i, 25),
              durationMinutes: 25,
              completed: true));
      await tester.pumpWidget(ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            statsSummaryProvider.overrideWith((ref) async => summary),
            recentSessionsStreamProvider
                .overrideWith((ref) => Stream.value(sessions)),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: scenario.dark
                ? AppTheme.oled(null, const Color(0xFF236981),
                    fontScale: scenario.scale)
                : AppTheme.light(null, const Color(0xFF236981),
                    fontScale: scenario.scale),
            home: Builder(
                builder: (context) => Theme(
                    data: Theme.of(context).copyWith(
                        textTheme: Theme.of(context)
                            .textTheme
                            .apply(fontFamily: 'VisualQANoto')),
                    child: RepaintBoundary(
                        key: repaint, child: const StatsScreen()))),
          )));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await precacheImage(const AssetImage('assets/icons/app_icon.png'),
            tester.element(find.byType(StatsScreen)));
      });
      await tester.pumpAndSettle();
      expect(find.text('Earned today'), findsOneWidget);
      expect(find.text('5 of 8 pomodoros'), findsOneWidget);
      expect(find.text('23 of 40 pomodoros'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (scenario.width > 1000) {
        await tester.runAsync(() async {
          final boundary = repaint.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/visual-qa/stats-${scenario.name}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.scrollUntilVisible(find.byType(DailyFocusChart), 250,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.text('Minutes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Minutes'));
      await tester.pumpAndSettle();
      final segment = tester.widget<SegmentedButton<FocusChartMetric>>(
          find.byType(SegmentedButton<FocusChartMetric>));
      expect(segment.selected, {FocusChartMetric.minutes});
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'goal editor validates input, accepts zero, saves and closes cleanly',
      (tester) async {
    int? saved;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: GoalSettingTile(
              title: 'Daily goal',
              value: 8,
              maximum: 1440,
              onChanged: (value) => saved = value)),
    ));
    await tester.tap(find.text('Daily goal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '-1');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(find.text('Enter a whole number from 0 to 1440.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved, 0);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'settings at 150 percent edit and persist a daily goal on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(380, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(
        {'automatic_updates': false, 'font_scale': 1.5});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          screenPowerAvailableProvider.overrideWith((ref) async => false),
        ],
        child: MaterialApp(
          theme:
              AppTheme.light(null, AppTheme.defaultSeedColor, fontScale: 1.5),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        )));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Daily goal'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Daily goal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily goal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '12');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(prefs.getInt('daily_goal_pomodoros'), 12);
    await tester.scrollUntilVisible(
        find.text('Minimize to tray when closing the window'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
