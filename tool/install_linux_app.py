#!/usr/bin/env python3
"""Install a built Linux bundle for the current user, optionally with autostart."""
import argparse
from datetime import datetime
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

APP_ID = 'com.focus.pomodoro_focus'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bundle', type=Path, required=True)
    parser.add_argument('--prefix', type=Path,
                        default=Path.home() / '.local/opt/pomodoro-focus')
    parser.add_argument('--autostart', action='store_true')
    args = parser.parse_args()
    bundle = args.bundle.resolve()
    prefix = args.prefix.expanduser().absolute()
    marker = prefix / '.pomodoro-focus-install'
    if prefix.is_symlink():
        parser.error('Installation directory must not be a symlink')
    if prefix.exists() and not marker.is_file():
        parser.error(f'Refusing to replace an unmanaged directory: {prefix}')
    for source in (bundle / 'pomodoro_focus',
                   bundle / 'share/applications' / f'{APP_ID}.desktop',
                   bundle / 'share/icons/hicolor/256x256/apps' / f'{APP_ID}.png'):
        if not source.is_file():
            parser.error(f'Build Linux first: missing {source}')
    if bundle == prefix or bundle in prefix.parents or prefix in bundle.parents:
        parser.error('Build bundle and installation must be separate directories')
    prefix.parent.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix='.pomodoro-focus-', dir=prefix.parent))
    backup = None
    try:
        shutil.copytree(bundle, stage, dirs_exist_ok=True)
        (stage / marker.name).write_text(f'{APP_ID}\n')
        if prefix.exists():
            backup = prefix.with_name(prefix.name + '.backup-' +
                                      datetime.now().strftime('%Y%m%d-%H%M%S-%f'))
            prefix.rename(backup)
        stage.rename(prefix)
    except Exception:
        if backup is not None and not prefix.exists():
            backup.rename(prefix)
        raise
    finally:
        if stage.exists():
            shutil.rmtree(stage)
    # Register this stable location, rather than the disposable Flutter build.
    subprocess.run([sys.executable, str(Path(__file__).with_name(
        'install_linux_desktop_entry.py')), '--bundle', str(prefix)], check=True)
    if args.autostart:
        data = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local/share'))
        config = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config'))
        entry = (data / 'applications' / f'{APP_ID}.desktop').read_text()
        autostart = config / 'autostart' / f'{APP_ID}.desktop'
        autostart.parent.mkdir(parents=True, exist_ok=True)
        autostart.write_text(entry)
        print(f'Autostart enabled: {autostart}')
    print(f'Application installed: {prefix}')
    if backup is not None:
        print(f'Previous version preserved: {backup}')


if __name__ == '__main__':
    main()
