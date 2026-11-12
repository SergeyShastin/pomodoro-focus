#!/usr/bin/env python3
"""Package an existing Linux x86_64 release bundle as a user-installable .deb."""
import argparse
from datetime import datetime, timezone
import gzip
import hashlib
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile

APP_ID = 'com.focus.pomodoro_focus'
PACKAGE = 'pomodoro-focus'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bundle', required=True, type=Path)
    parser.add_argument('--version', default='1.0.0-1')
    parser.add_argument('--output', type=Path, default=Path('dist'))
    parser.add_argument('--license-file', type=Path,
                        default=Path(__file__).resolve().parents[1] / 'LICENSE')
    parser.add_argument('--flutter-license-file', type=Path)
    args = parser.parse_args()
    if not re.fullmatch(r'[0-9][A-Za-z0-9.+~\-]*', args.version):
        parser.error('Invalid Debian version')
    if not shutil.which('dpkg-deb'):
        parser.error('dpkg-deb is required (package: dpkg)')
    bundle = args.bundle.resolve()
    license_file = args.license_file.resolve()
    flutter_license = args.flutter_license_file or bundle.parent / 'FLUTTER_LICENSE'
    if not flutter_license.is_file() and args.flutter_license_file is None:
        flutter = shutil.which('flutter')
        if flutter:
            flutter_license = Path(flutter).resolve().parents[1] / 'LICENSE'
    if not flutter_license.is_file():
        parser.error('Provide the Flutter license with --flutter-license-file')
    required = [bundle / 'pomodoro_focus',
                bundle / 'lib/libapp.so',
                bundle / 'lib/libflutter_linux_gtk.so',
                bundle / 'data/icudtl.dat',
                bundle / 'data/flutter_assets/NOTICES.Z',
                bundle / f'share/applications/{APP_ID}.desktop',
                bundle / f'share/icons/hicolor/256x256/apps/{APP_ID}.png',
                license_file]
    for source in required:
        if not source.is_file():
            parser.error(f'Missing required release file: {source}')
    # Refuse a debug or wrong-architecture bundle rather than mislabelling it.
    header = (bundle / 'pomodoro_focus').read_bytes()[:20]
    if (header[:6] != b'\x7fELF\x02\x01' or len(header) < 20
            or struct.unpack('<H', header[18:20])[0] != 62):
        parser.error('The bundle executable must be Linux x86_64 ELF')
    for source in bundle.rglob('*'):
        if source.is_symlink():
            target = source.resolve()
            if not target.is_relative_to(bundle):
                parser.error(f'External bundle symlink: {source}')
    output = args.output.resolve()
    if output.is_relative_to(bundle):
        parser.error('Output directory must be outside the bundle')
    output.mkdir(parents=True, exist_ok=True)
    destination = output / f'{PACKAGE}_{args.version}_amd64.deb'
    if destination.exists():
        parser.error(f'Refusing to overwrite an existing package: {destination}')
    with tempfile.TemporaryDirectory(prefix='pomodoro-deb-') as temporary:
        root = Path(temporary) / PACKAGE
        app = root / 'opt' / PACKAGE
        shutil.copytree(bundle, app, symlinks=True)
        desktop = app / f'share/applications/{APP_ID}.desktop'
        entry = '\n'.join('Exec=pomodoro-focus' if line.startswith('Exec=')
                          else line for line in desktop.read_text().splitlines()) + '\n'
        desktop.write_text(entry)
        menu = root / f'usr/share/applications/{APP_ID}.desktop'
        menu.parent.mkdir(parents=True)
        menu.write_text(entry)
        icon = root / f'usr/share/icons/hicolor/256x256/apps/{APP_ID}.png'
        icon.parent.mkdir(parents=True)
        shutil.copyfile(app / f'share/icons/hicolor/256x256/apps/{APP_ID}.png', icon)
        launcher = root / 'usr/bin' / PACKAGE
        launcher.parent.mkdir(parents=True)
        launcher.write_text('#!/bin/sh\nexec /opt/pomodoro-focus/pomodoro_focus "$@"\n')
        launcher.chmod(0o755)
        (app / 'pomodoro_focus').chmod(0o755)
        docs = root / f'usr/share/doc/{PACKAGE}'
        docs.mkdir(parents=True)
        shutil.copyfile(license_file, docs / 'copyright')
        shutil.copyfile(flutter_license, docs / 'FLUTTER_LICENSE')
        try:
            notices = gzip.decompress((app / 'data/flutter_assets/NOTICES.Z').read_bytes())
        except (OSError, EOFError) as error:
            parser.error(f'Cannot read dependency notices: {error}')
        (docs / 'THIRD_PARTY_NOTICES.txt.gz').write_bytes(gzip.compress(notices, mtime=0))
        install = Path(__file__).resolve().parents[1] / 'docs/LINUX_INSTALL.md'
        if install.is_file():
            guide = install.read_text().replace('[MIT](../LICENSE)', '[MIT](copyright)')
            (docs / 'INSTALL.md').write_text(guide)
        epoch = int(os.environ.get('SOURCE_DATE_EPOCH', '0'))
        date = datetime.fromtimestamp(epoch, timezone.utc).strftime('%a, %d %b %Y %H:%M:%S +0000')
        changelog = (f'{PACKAGE} ({args.version}) stable; urgency=medium\n\n'
                     '  * Package the Linux release for graphical installation.\n\n'
                     f' -- Pomodoro Focus Contributors <contributors@example.invalid>  {date}\n')
        (docs / 'changelog.Debian.gz').write_bytes(gzip.compress(changelog.encode(), mtime=0))
        installed_size = (sum(f.stat().st_size for f in root.rglob('*') if f.is_file()) + 1023) // 1024
        control = root / 'DEBIAN'
        control.mkdir()
        (control / 'control').write_text(f'''Package: {PACKAGE}
Version: {args.version}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Pomodoro Focus Contributors <contributors@example.invalid>
Installed-Size: {installed_size}
Depends: libc6 (>= 2.43), libstdc++6 (>= 11), libgtk-3-0t64, libayatana-appindicator3-1, libgstreamer1.0-0, libgstreamer-plugins-base1.0-0, gstreamer1.0-plugins-good, libsqlite3-0
Suggests: libkscreen-bin, xwayland
Homepage: https://github.com/SergeyShastin/pomodoro-focus
Description: Offline Pomodoro timer and world clock
 Configurable focus sessions, world clocks, local history and goals.
 Includes KDE tray, notification inhibition and optional display power control.
 Built for Ubuntu/Kubuntu 26.04 x86_64; Flutter is not required at runtime.
''')
        md5sums = []
        for f in sorted(root.rglob('*')):
            if f.is_file() and not f.is_symlink() and control not in f.parents:
                md5sums.append(f'{hashlib.md5(f.read_bytes()).hexdigest()}  {f.relative_to(root)}\n')
        (control / 'md5sums').write_text(''.join(md5sums))
        for directory in [root, *(f for f in root.rglob('*') if f.is_dir())]:
            directory.chmod(0o755)
        for f in root.rglob('*'):
            if f.is_file() and not f.is_symlink():
                f.chmod(0o755 if f in (launcher, app / 'pomodoro_focus') else 0o644)
        env = os.environ.copy()
        env.setdefault('SOURCE_DATE_EPOCH', '0')
        subprocess.run(['dpkg-deb', '--root-owner-group', '-Zxz', '--build',
                        str(root), str(destination)], env=env, check=True)
    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    destination.with_suffix('.deb.sha256').write_text(f'{digest}  {destination.name}\n')
    print(f'Package: {destination}')
    print(f'SHA256: {digest}')


if __name__ == '__main__':
    main()
