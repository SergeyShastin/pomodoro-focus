#!/usr/bin/env python3
"""Register an existing Linux bundle in the current user's KDE/app menu."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bundle', type=Path, required=True)
    args = parser.parse_args()
    bundle = args.bundle.resolve()
    app_id = 'com.focus.pomodoro_focus'
    desktop = bundle / 'share/applications' / f'{app_id}.desktop'
    icon = bundle / 'share/icons/hicolor/256x256/apps' / f'{app_id}.png'
    for source in (bundle / 'pomodoro_focus', desktop, icon):
        if not source.is_file():
            parser.error(f'Build the Linux bundle first: missing {source}')
    # Use this bundle's actual location, even if it was moved after building.
    entry = desktop.read_text()
    executable = str(bundle / 'pomodoro_focus')
    executable = executable.replace('\\', '\\\\').replace('"', '\\"')
    executable = executable.replace('`', '\\`').replace('$', '\\$').replace('%', '%%')
    entry = '\n'.join(f'Exec="{executable}"' if line.startswith('Exec=') else line
                      for line in entry.splitlines()) + '\n'
    data = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local/share'))
    target_desktop = data / 'applications' / desktop.name
    target_icon = data / 'icons/hicolor/256x256/apps' / icon.name
    target_desktop.parent.mkdir(parents=True, exist_ok=True)
    target_icon.parent.mkdir(parents=True, exist_ok=True)
    target_desktop.write_text(entry)
    shutil.copy2(icon, target_icon)
    for command in (['update-desktop-database', str(target_desktop.parent)],
                    ['kbuildsycoca6', '--noincremental']):
        if shutil.which(command[0]):
            subprocess.run(command, check=True)
    print(f'Installed {target_desktop}')


if __name__ == '__main__':
    main()
