import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pomodoro_focus/core/updates/update_service.dart';

Map<String, dynamic> release({String version = '1.10.0', List<int>? bytes}) {
  final data = bytes ?? ascii.encode('!<arch>\nfixture');
  final name = 'pomodoro-focus_$version-1_amd64.deb';
  return {
    'draft': false,
    'prerelease': false,
    'tag_name': 'v$version',
    'assets': [
      <String, dynamic>{
        'name': name,
        'browser_download_url':
            'https://github.com/$updateRepository/releases/download/v$version/$name',
        'size': data.length,
        'digest': 'sha256:${sha256.convert(data)}',
      },
    ],
  };
}

class InstallerProcess extends Mock implements Process {}

class Client extends Mock implements HttpClient {}

class Request extends Mock implements HttpClientRequest {}

class Headers extends Fake implements HttpHeaders {
  final values = <String, String>{};
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    values[name] = value.toString();
  }

  @override
  String? value(String name) => values[name];
}

class Response extends Stream<List<int>> implements HttpClientResponse {
  @override
  final int statusCode;
  final List<int> data;
  @override
  final Headers headers;
  Response(this.statusCode, this.data, [Headers? headers])
    : headers = headers ?? Headers();
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(data).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => registerFallbackValue(Uri.https('github.com')));
  test(
    'opens KDE installer with one local path argument, falls back without a shell',
    () async {
      final calls = <List<String>>[];
      final process = InstallerProcess();
      when(() => process.stdout).thenAnswer((_) => const Stream.empty());
      when(() => process.stderr).thenAnswer((_) => const Stream.empty());
      when(() => process.exitCode).thenAnswer((_) async => 0);
      final file = File('/tmp/folder with spaces/update.deb');
      await GithubUpdateService.launchInstaller(
        file,
        desktop: 'KDE',
        start: (command, args) async {
          calls.add([command, ...args]);
          return process;
        },
      );
      expect(calls.single, ['plasma-discover', '--local-filename', file.path]);
      calls.clear();
      await GithubUpdateService.launchInstaller(
        file,
        desktop: 'KDE',
        start: (command, args) async {
          calls.add([command, ...args]);
          if (command == 'plasma-discover') {
            throw const ProcessException('plasma-discover', [], 'missing');
          }
          return process;
        },
      );
      expect(calls.last, ['xdg-open', file.uri.toString()]);
      await expectLater(
        GithubUpdateService.launchInstaller(
          file,
          desktop: 'KDE',
          start: (_, _) async {
            throw const ProcessException('missing', []);
          },
        ),
        throwsA(isA<UpdateException>()),
      );
    },
  );
  test('numeric versions, current versions and prereleases', () {
    expect(ReleaseUpdate.parse(release(), '1.9.9')!.version, '1.10.0');
    expect(ReleaseUpdate.parse(release(), '1.10.0+2'), isNull);
    expect(
      ReleaseUpdate.parse({...release(), 'prerelease': true}, '1.0.0'),
      isNull,
    );
    expect(ReleaseUpdate.parse({...release(), 'draft': true}, '1.0.0'), isNull);
    expect(
      ReleaseUpdate.parse({...release(), 'tag_name': 'v2.0.0-beta'}, '1.0.0'),
      isNull,
    );
  });
  test('requires a compatible package, trusted URL and SHA-256', () {
    for (final replacement in [
      {'browser_download_url': 'http://github.com/file.deb'},
      {'browser_download_url': 'https://example.org/file.deb'},
      {'digest': null},
      {'size': 1024 * 1024 * 1024},
    ]) {
      final json = release();
      (json['assets'] as List)[0].addAll(replacement);
      expect(
        () => ReleaseUpdate.parse(json, '1.0.0'),
        throwsA(isA<UpdateException>()),
      );
    }
    expect(
      () => ReleaseUpdate.parse({...release(), 'assets': []}, '1.0.0'),
      throwsA(isA<UpdateException>()),
    );
  });

  late Client client;
  late Headers requestHeaders;
  late GithubUpdateService service;
  setUp(() {
    client = Client();
    requestHeaders = Headers();
    service = GithubUpdateService(
      version: () async => '1.0.0',
      supported: () async => true,
      launch: (_) async {},
      clientFactory: () => client,
    );
  });
  void respond(Response response) {
    final request = Request();
    when(() => request.headers).thenReturn(requestHeaders);
    when(request.close).thenAnswer((_) async => response);
    when(() => client.getUrl(any())).thenAnswer((_) async => request);
  }

  test('metadata request contains no credentials or personal data', () async {
    respond(Response(200, utf8.encode(jsonEncode(release()))));
    expect((await service.check('1.0.0'))!.version, '1.10.0');
    verify(
      () => client.getUrl(
        Uri.https('api.github.com', '/repos/$updateRepository/releases/latest'),
      ),
    ).called(1);
    expect(requestHeaders.values.keys.toSet(), {
      HttpHeaders.userAgentHeader,
      HttpHeaders.acceptHeader,
    });
  });
  test('HTTP failures and untrusted redirects fail safely', () async {
    respond(Response(403, []));
    await expectLater(service.check('1.0.0'), throwsA(isA<UpdateException>()));
    respond(
      Response(
        302,
        [],
        Headers()
          ..values[HttpHeaders.locationHeader] = 'https://example.org/file',
      ),
    );
    await expectLater(service.check('1.0.0'), throwsA(isA<UpdateException>()));
  });
  test('download verifies length, SHA-256 and Debian archive header', () async {
    final data = ascii.encode('!<arch>\nfixture');
    final update = ReleaseUpdate.parse(release(bytes: data), '1.0.0')!;
    respond(Response(200, data));
    final progress = <double>[];
    final file = await service.download(update, progress.add);
    addTearDown(() => file.parent.delete(recursive: true));
    expect(await file.readAsBytes(), data);
    expect(file.path.endsWith('.deb'), isTrue);
    expect(progress.last, 1);
    for (final invalid in [
      data.sublist(1),
      List<int>.filled(data.length, 1),
      [...data, 1],
    ]) {
      respond(Response(200, invalid));
      await expectLater(
        service.download(update, (_) {}),
        throwsA(isA<UpdateException>()),
      );
    }
    final invalidHeader = ascii.encode('not-a-deb');
    respond(Response(200, invalidHeader));
    await expectLater(
      service.download(
        ReleaseUpdate.parse(release(bytes: invalidHeader), '1.0.0')!,
        (_) {},
      ),
      throwsA(isA<UpdateException>()),
    );
  });
}
