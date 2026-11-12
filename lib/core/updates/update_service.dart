import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:pub_semver/pub_semver.dart';

const updateRepository = 'SergeyShastin/pomodoro-focus';

enum UpdateFailure {
  network,
  unsupported,
  packageMissing,
  integrity,
  installation,
  restart,
}

class UpdateException implements Exception {
  final UpdateFailure failure;
  const UpdateException(this.failure);
}

class ReleaseUpdate {
  final String version;
  final String filename;
  final Uri url;
  final int size;
  final String digest;
  const ReleaseUpdate(
    this.version,
    this.filename,
    this.url,
    this.size,
    this.digest,
  );

  static ReleaseUpdate? parse(Map<String, dynamic> json, String current) {
    if (json['draft'] != false || json['prerelease'] != false) return null;
    final tag = json['tag_name'] as String? ?? '';
    if (!RegExp(r'^v?\d+\.\d+\.\d+$').hasMatch(tag)) return null;
    final version = tag.replaceFirst(RegExp(r'^v'), '');
    if (Version.parse(version) <= Version.parse(current.split('+').first)) {
      return null;
    }
    final assets = json['assets'];
    if (assets is! List) {
      throw const UpdateException(UpdateFailure.packageMissing);
    }
    for (final asset in assets.whereType<Map>()) {
      final filename = asset['name'];
      if (filename is! String ||
          !RegExp(
            '^pomodoro-focus_${RegExp.escape(version)}(?:-[0-9]+)?_amd64\\.deb\$',
          ).hasMatch(filename)) {
        continue;
      }
      final url = Uri.tryParse(asset['browser_download_url'] as String? ?? '');
      final digest = asset['digest'];
      final size = asset['size'];
      if (url == null ||
          url.scheme != 'https' ||
          url.host != 'github.com' ||
          url.userInfo.isNotEmpty ||
          url.port != 443 ||
          url.hasQuery ||
          url.hasFragment ||
          url.path != '/$updateRepository/releases/download/$tag/$filename' ||
          digest is! String ||
          !RegExp(r'^sha256:[a-f0-9]{64}$').hasMatch(digest) ||
          size is! int ||
          size <= 0 ||
          size > 512 * 1024 * 1024) {
        throw const UpdateException(UpdateFailure.integrity);
      }
      return ReleaseUpdate(version, filename, url, size, digest.substring(7));
    }
    throw const UpdateException(UpdateFailure.packageMissing);
  }
}

abstract class UpdateBackend {
  Future<String> currentVersion();
  Future<ReleaseUpdate?> check(String currentVersion);
  Future<File> download(ReleaseUpdate update, void Function(double) progress);
  Future<void> installPackage(File file);
  Future<bool> isInstalled(String version);
}

/// Requests only public release metadata and an explicitly selected package.
/// No authentication, analytics, user settings or session data are sent.
class GithubUpdateService implements UpdateBackend {
  final Future<String> Function() version;
  final Future<bool> Function() supported;
  final Future<void> Function(File) install;
  final HttpClient Function() clientFactory;
  GithubUpdateService({
    required this.version,
    required this.supported,
    required this.install,
    HttpClient Function()? clientFactory,
  }) : clientFactory = clientFactory ?? HttpClient.new;

  @override
  Future<String> currentVersion() => version();

  static Future<bool> supportsDebUpdates() async {
    if (!Platform.isLinux) return false;
    // ELF machine ID, rather than uname (which can differ under emulation).
    final executable = await File('/proc/self/exe').open();
    final header = await executable.read(20);
    await executable.close();
    if (header.length < 20 ||
        header[4] != 2 ||
        header[5] != 1 ||
        header[18] != 62 ||
        header[19] != 0) {
      return false;
    }
    final release = await File('/etc/os-release').readAsString();
    final values = <String, String>{};
    for (final line in const LineSplitter().convert(release)) {
      final equal = line.indexOf('=');
      if (equal > 0) {
        values[line.substring(0, equal)] = line
            .substring(equal + 1)
            .replaceAll('"', '');
      }
    }
    if (values['ID'] != 'ubuntu') return false;
    final number = double.tryParse(values['VERSION_ID'] ?? '') ?? 0;
    return number >= 26.04;
  }

  Future<HttpClientResponse> _get(HttpClient client, Uri uri) async {
    for (var redirects = 0; redirects < 6; redirects++) {
      if (uri.scheme != 'https' ||
          uri.port != 443 ||
          uri.userInfo.isNotEmpty ||
          !{
            'api.github.com',
            'github.com',
            'release-assets.githubusercontent.com',
            'objects.githubusercontent.com',
          }.contains(uri.host)) {
        throw const UpdateException(UpdateFailure.integrity);
      }
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 20));
      request.followRedirects = false;
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'PomodoroFocus-UpdateCheck',
      );
      request.headers.set(
        HttpHeaders.acceptHeader,
        uri.host == 'api.github.com'
            ? 'application/vnd.github+json'
            : 'application/octet-stream',
      );
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      if ({301, 302, 303, 307, 308}.contains(response.statusCode)) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location == null) {
          throw const UpdateException(UpdateFailure.network);
        }
        uri = uri.resolve(location);
        continue;
      }
      return response;
    }
    throw const UpdateException(UpdateFailure.network);
  }

  @override
  Future<ReleaseUpdate?> check(String currentVersion) async {
    if (!await supported()) {
      throw const UpdateException(UpdateFailure.unsupported);
    }
    final client = clientFactory()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final response = await _get(
        client,
        Uri.https('api.github.com', '/repos/$updateRepository/releases/latest'),
      );
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw const UpdateException(UpdateFailure.network);
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 20))) {
        bytes.addAll(chunk);
        if (bytes.length > 2 * 1024 * 1024) {
          throw const UpdateException(UpdateFailure.integrity);
        }
      }
      return ReleaseUpdate.parse(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
        currentVersion,
      );
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<File> download(
    ReleaseUpdate update,
    void Function(double) progress,
  ) async {
    final client = clientFactory()
      ..connectionTimeout = const Duration(seconds: 20);
    final directory = await Directory.systemTemp.createTemp(
      'pomodoro-focus-update-',
    );
    // createTemp uses unpredictable names; keep the installer private to this user.
    await Process.run('chmod', ['700', directory.path]);
    final partial = File('${directory.path}/package.part');
    IOSink? sink;
    try {
      final response = await _get(client, update.url);
      if (response.statusCode != 200) {
        throw const UpdateException(UpdateFailure.network);
      }
      sink = partial.openWrite();
      var received = 0;
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        received += chunk.length;
        if (received > update.size) {
          throw const UpdateException(UpdateFailure.integrity);
        }
        sink.add(chunk);
        progress(received / update.size);
      }
      await sink.close();
      sink = null;
      if (received != update.size ||
          (await sha256.bind(partial.openRead()).first).toString() !=
              update.digest) {
        throw const UpdateException(UpdateFailure.integrity);
      }
      final header = await partial.open();
      final magic = await header.read(8);
      await header.close();
      if (ascii.decode(magic, allowInvalid: true) != '!<arch>\n') {
        throw const UpdateException(UpdateFailure.integrity);
      }
      return await partial.rename('${directory.path}/${update.filename}');
    } catch (_) {
      await sink?.close();
      await directory.delete(recursive: true);
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> installPackage(File file) => install(file);

  @override
  Future<bool> isInstalled(String version) async {
    try {
      final result = await Process.run('dpkg-query', [
        '-W',
        '-f',
        r'${Status}\n${Version}',
        'pomodoro-focus',
      ]).timeout(const Duration(seconds: 10));
      final lines = result.stdout.toString().trim().split('\n');
      if (result.exitCode != 0 ||
          lines.length != 2 ||
          lines.first != 'install ok installed') {
        return false;
      }
      final metadata =
          jsonDecode(
                await File(
                  '/opt/pomodoro-focus/data/flutter_assets/version.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      final actual = metadata['version'] as String;
      return RegExp('^${RegExp.escape(actual)}-[0-9]+\$').hasMatch(lines[1]) &&
          Version.parse(actual) >= Version.parse(version);
    } catch (_) {
      return false;
    }
  }
}
