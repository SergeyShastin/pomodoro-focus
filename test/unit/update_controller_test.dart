import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/core/updates/update_controller.dart';
import 'package:pomodoro_focus/core/updates/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Backend implements UpdateBackend {
  int checks = 0, downloads = 0, opens = 0;
  bool corrupt = false, cannotOpen = false;
  Completer<ReleaseUpdate?>? pending;
  final release =
      ReleaseUpdate('2.0.0', 'test.deb', Uri.https('github.com'), 10, 'hash');
  @override
  Future<String> currentVersion() async => '1.1.0';
  @override
  Future<ReleaseUpdate?> check(String currentVersion) async {
    checks++;
    if (pending == null) return release;
    return await pending!.future;
  }

  @override
  Future<File> download(
      ReleaseUpdate update, void Function(double) progress) async {
    downloads++;
    progress(0.5);
    if (corrupt) throw const UpdateException(UpdateFailure.integrity);
    return File('/tmp/test-update.deb');
  }

  @override
  Future<void> openInstaller(File file) async {
    opens++;
    if (cannotOpen) throw const UpdateException(UpdateFailure.installer);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Backend backend;
  late SharedPreferences prefs;
  late UpdateController controller;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    backend = Backend();
    controller = UpdateController(backend, prefs);
  });
  tearDown(() => controller.dispose());
  test('manual check works with automatic checks disabled; does not download',
      () async {
    controller.configure(false);
    await controller.check();
    expect(controller.state.phase, UpdatePhase.available);
    expect([backend.checks, backend.downloads, backend.opens], [1, 0, 0]);
    await controller.install();
    expect(controller.state.phase, UpdatePhase.opened);
    expect([backend.downloads, backend.opens], [1, 1]);
  });
  test(
      'corrupt download never opens installer; opening failure can retry cached package',
      () async {
    await controller.check();
    backend.corrupt = true;
    await controller.install();
    expect(controller.state.failure, UpdateFailure.integrity);
    expect(backend.opens, 0);
    backend.corrupt = false;
    backend.cannotOpen = true;
    await controller.install();
    expect(controller.state.failure, UpdateFailure.installer);
    backend.cannotOpen = false;
    await controller.install();
    expect(backend.downloads, 2);
    expect(controller.state.phase, UpdatePhase.opened);
  });
  test('check is single-flight; disabling auto discards its pending result',
      () async {
    controller.configure(true);
    backend.pending = Completer();
    final first = controller.check(automatic: true);
    await Future<void>.delayed(Duration.zero);
    await controller.check();
    expect(backend.checks, 1);
    controller.configure(false);
    backend.pending!.complete(backend.release);
    await first;
    expect(controller.state.release, isNull);
    expect(prefs.getInt('update_last_attempt'), isNotNull);
  });
  testWidgets('automatic polling respects persisted interval and opt out',
      (tester) async {
    await prefs.setInt(
        'update_last_attempt', DateTime.now().millisecondsSinceEpoch);
    controller.configure(true);
    await tester.pump(const Duration(minutes: 1));
    expect(backend.checks, 0);
    controller.configure(false);
    await tester.pump(const Duration(hours: 13));
    expect(backend.checks, 0);
  });
}
