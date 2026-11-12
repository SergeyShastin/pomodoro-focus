#!/usr/bin/env python3
"""Build a distributable Linux bundle and .deb in a neutral temporary directory."""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path,
                        help='New directory for the bundle, .deb and checksum')
    parser.add_argument('--sqlite-source', type=Path,
                        help='Optional existing upstream SQLite source cache')
    args = parser.parse_args()
    source = Path(__file__).resolve().parents[1]
    output = args.output.resolve()
    if output.exists():
        parser.error('Output directory already exists; choose a new directory')
    flutter = shutil.which('flutter')
    if not flutter:
        parser.error('Flutter must be on PATH')
    sdk_license = Path(flutter).resolve().parents[1] / 'LICENSE'
    if not sdk_license.is_file():
        parser.error('Cannot locate the Flutter SDK license')
    if args.sqlite_source and not (args.sqlite_source / 'sqlite3.c').is_file():
        parser.error('SQLite source directory must contain sqlite3.c')
    # The generated Dart plugin registrant embeds its source URI in AOT output.
    # A neutral /tmp path prevents a developer account name entering the binary.
    with tempfile.TemporaryDirectory(prefix='pomodoro-release-', dir='/tmp') as temporary:
        project = Path(temporary) / 'source'
        project.mkdir()
        for name in ['lib', 'assets', 'linux']:
            shutil.copytree(source / name, project / name,
                            ignore=shutil.ignore_patterns('ephemeral', '.symlinks', '__pycache__'))
        for name in ['pubspec.yaml', 'pubspec.lock', 'l10n.yaml', 'analysis_options.yaml', '.metadata']:
            if (source / name).is_file():
                shutil.copy2(source / name, project / name)
        if args.sqlite_source:
            cache = project / 'build/linux/x64/release'
            cache.mkdir(parents=True)
            sqlite = args.sqlite_source.resolve()
            (cache / 'CMakeCache.txt').write_text(f'FETCHCONTENT_SOURCE_DIR_SQLITE3:PATH={sqlite}\n')
        for command in [[flutter, 'pub', 'get'], [flutter, 'gen-l10n'],
                        [flutter, 'build', 'linux', '--release', '--no-pub']]:
            subprocess.run(command, cwd=project, check=True)
        bundle = project / 'build/linux/x64/release/bundle'
        # Do not publish a partially packaged output on a failed build.
        output.parent.mkdir(parents=True, exist_ok=True)
        stage = Path(tempfile.mkdtemp(prefix='.pomodoro-stage-', dir=output.parent))
        try:
            shutil.copytree(bundle, stage / 'bundle')
            shutil.copy2(sdk_license, stage / 'FLUTTER_LICENSE')
            shutil.copy2(source / 'LICENSE', stage / 'LICENSE')
            subprocess.run([sys.executable, str(source / 'tool/build_linux_deb.py'),
                            '--bundle', str(stage / 'bundle'), '--output', str(stage),
                            '--flutter-license-file', str(stage / 'FLUTTER_LICENSE')], check=True)
            # Bundle desktop file must not refer back to the disposable build.
            desktop = stage / 'bundle/share/applications/com.focus.pomodoro_focus.desktop'
            desktop.write_text('\n'.join('Exec=pomodoro_focus' if line.startswith('Exec=') else line
                                         for line in desktop.read_text().splitlines()) + '\n')
            stage.rename(output)
        finally:
            if stage.exists():
                shutil.rmtree(stage)
    print(f'Distributable bundle and Debian package: {output}')


if __name__ == '__main__':
    main()
