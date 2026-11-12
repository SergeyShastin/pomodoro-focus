# Install the Linux binary (no Flutter required)

The first binary release targets **Linux x86_64, built on Ubuntu 26.04**.
KDE Plasma 6 is the primary desktop. Other distributions and older Ubuntu releases are not verified; this is not a universal Linux package.

## Recommended: graphical installation with .deb

Download `pomodoro-focus_1.2.0-1_amd64.deb` from the [v1.2.0 release](https://github.com/SergeyShastin/pomodoro-focus/releases/tag/v1.2.0). Open the downloaded file with your graphical package installer (Discover or another installer that supports local Debian packages) and choose Install. Your system may request administrator authentication. The package manager installs runtime dependencies and adds **Focus & World Clock** to the application menu. Flutter is not required.

This package targets **Ubuntu/Kubuntu 26.04 amd64**. It intentionally requires the 26.04 libc baseline; it is not intended for older Ubuntu releases. If your desktop does not associate `.deb` files with an installer, an alternative is:

```bash
sudo apt install ./pomodoro-focus_1.2.0-1_amd64.deb
```

The app is installed in `/opt/pomodoro-focus`, with its launcher at `/usr/bin/pomodoro-focus`. No desktop shortcut or autostart is enabled automatically. Enable autostart through KDE System Settings → Autostart → Add Application if desired. Remove the package through your package manager; settings and history are retained.

**Moving from the earlier user-local installer:** quit the running app before switching. A user-local menu entry or autostart entry takes precedence over the system entry and can keep launching the older copy. Remove `~/.local/share/applications/com.focus.pomodoro_focus.desktop` and, if present, `~/.config/autostart/com.focus.pomodoro_focus.desktop` using your file manager, then recreate autostart for the system-installed app if wanted. The old bundle in `~/.local/opt/pomodoro-focus` can be removed afterwards. Do not delete application data: saved settings and history are shared by the two installation methods.

For optional verification, download the adjacent `.deb.sha256` file alongside the `.deb` and run:

```bash
sha256sum --check pomodoro-focus_1.2.0-1_amd64.deb.sha256
```

**Updates (1.2.0 and later):** Settings → Application updates shows the running version even when automatic checks are off. The window title also includes the version. Check now finds a newer stable release; Update downloads and verifies its SHA-256 and submits the local package directly to PackageKit. Only the system authorization dialog is needed, without opening Discover. The app never receives your password. Rejecting authorization or a failed transaction leaves the running app open and does not trigger a restart.

After PackageKit reports success, the app verifies the installed Debian package and on-disk app version. It then restarts automatically when no unfinished focus session or pending history write remains. Active or paused focus is allowed to finish or be reset first. A running/paused break, its deadline, task and cycle counters are handed to the new process using a validated single-use snapshot. Normal Quit behavior is unchanged: unfinished focus is not generally persisted. A database write failure blocks automatic restart.

**Bootstrap:** versions 1.1.0/1.1.1 use Discover and require a manual Quit/relaunch once when installing 1.2.0. They cannot acquire the new restart behavior until the new app is running. Version 1.0.0 has no updater and must be upgraded manually. Both project variants use the public English release channel. Existing settings and completed history are preserved.

Automatic checks remain optional (enabled by default), at startup and at most every 12 hours. No tasks, history, settings or credentials are sent. The package manager may fetch required dependencies. An APT repository is not configured. Portable/user-local users should follow the launcher migration instructions above when switching to the system installation.

Only stable releases with a higher app version and a matching `pomodoro-focus_<version>-<revision>_amd64.deb` asset with a GitHub SHA-256 digest are offered. Automatic `.deb` updates currently target Ubuntu/Kubuntu 26.04+ x86_64. Newer distribution versions still need independent runtime testing. There is no APT repository. A Git push alone is not an update: publish a new release and its compatible package.

## Alternative: portable archive

## 1. Install runtime libraries

On Ubuntu/Kubuntu 26.04:

```bash
sudo apt install libgtk-3-0t64 libayatana-appindicator3-1 libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 gstreamer1.0-plugins-good libsqlite3-0 libstdc++6 python3 xdg-utils packagekit
```

For KDE screen power control and floating-window support in a Wayland session:

```bash
sudo apt install libkscreen-bin xwayland
```

Flutter, Dart, compilers and development headers are **not needed** to run this release. Runtime package names may differ on other distributions. GTK, GStreamer and the desktop notification server must be available.

## 2. Download and verify

Download `pomodoro-focus-1.2.0-linux-x86_64.tar.gz` and `SHA256SUMS` from the [v1.2.0 release](https://github.com/SergeyShastin/pomodoro-focus/releases/tag/v1.2.0) into the same directory.

```bash
sha256sum --check SHA256SUMS
tar -xzf pomodoro-focus-1.2.0-linux-x86_64.tar.gz
cd pomodoro-focus-1.2.0-linux-x86_64
```

## 3. Try or install

Try the app directly from the extracted directory:

```bash
./bundle/pomodoro_focus
```

Keep the entire `bundle` directory together; the executable needs the libraries and data beside it.

Install in your own account and add the menu entry:

```bash
./install.sh
```

Or install with automatic startup at desktop login:

```bash
./install.sh --autostart
```

Do not run the installer with sudo. It installs to `~/.local/opt/pomodoro-focus`, with a launcher and icon under `~/.local/share`. The optional autostart entry goes under `~/.config/autostart`. XDG data/config overrides are respected. You can then remove the extracted archive directory. Close an already running copy before updating; repeating installation keeps the previous bundle as `pomodoro-focus.backup-*`.

## Behavior and known limits

- Closing the window can keep the timer running in the tray. Use **Quit** to exit completely.
- An unfinished timer is not restored after a full exit. Saved settings and completed history are retained.
- KDE DND suppression depends on Plasma's notification server; critical notifications may follow system policy.
- Screen off/on at breaks is optional, disabled by default and requires KDE Wayland plus `kscreen-doctor`. It does not lock the screen or suspend the computer. Enable automatic break starts for a fully automatic cycle.
- Window positioning and always-on-top in a Wayland session use XWayland. Other desktops may support the core timer but not these KDE-specific integrations.
- A `GLIBC_* not found` or `GLIBCXX_* not found` error means the distribution is too old for this binary. Build from source on that distribution instead; do not replace system libraries manually.

## Remove the installation

Quit the app first. For the default installation paths:

```bash
rm -rf "$HOME/.local/opt/pomodoro-focus"
rm -f "$HOME/.local/share/applications/com.focus.pomodoro_focus.desktop"
rm -f "$HOME/.local/share/icons/hicolor/256x256/apps/com.focus.pomodoro_focus.png"
rm -f "$HOME/.config/autostart/com.focus.pomodoro_focus.desktop"
```

Adjust paths if you use XDG overrides or a custom installation prefix. This leaves your saved history and settings in place. You may also delete old `pomodoro-focus.backup-*` directories after checking they are no longer needed.

## Licenses

The application is licensed under [MIT](../LICENSE), including v1.0.0. The release archive includes `LICENSE` next to this installation guide, along with dependency notices in `THIRD_PARTY_NOTICES.txt` and the Flutter license in `FLUTTER_LICENSE`. Dependencies retain their respective license terms.

Download the archive and its matching `SHA256SUMS` from the same release. The Debian package has its own adjacent `.deb.sha256` file.

## Build a Debian package from source

For a distributable bundle and Debian package without personal build paths:

```bash
python3 tool/build_linux_release.py --output dist/linux-1.2.0
```

This requires Flutter and `dpkg-deb` and does not use sudo or install the package. It builds in a neutral temporary directory because generated Dart plugin metadata can include its build path. The lower-level `tool/build_linux_deb.py` can package an existing neutral-path bundle; it rejects native libraries with home-directory paths. The packager includes MIT, Flutter and dependency notices, creates a root-owned package with declared runtime dependencies, and writes a separate `.deb.sha256` checksum. Use `--flutter-license-file` if the Flutter license cannot be found beside the bundle or through the Flutter SDK on PATH. Use a higher Debian version when packaging an update; `SOURCE_DATE_EPOCH` can be set for reproducible timestamps. The prebuilt archive remains available independently.

## Publish a future update

1. Increase `version` in `pubspec.yaml` (for example `1.3.0+5`).
2. Run analysis/tests and build the distributable Linux release with `tool/build_linux_release.py`. The package builder reads the app version from the built bundle and refuses a mismatched Debian version.
3. Commit and push the public project, then publish a stable GitHub Release tagged `v1.3.0`, attaching `pomodoro-focus_1.3.0-1_amd64.deb` and its checksum. Keep the portable archive as an alternative.
4. GitHub provides the asset SHA-256 digest used by the app. Drafts, prereleases, missing packages and versions no newer than the installed app are not offered as installable updates. The app checks at most every 12 hours automatically; Check now bypasses that interval.
