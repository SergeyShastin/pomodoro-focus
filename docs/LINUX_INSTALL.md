# Install the Linux binary (no Flutter required)

The first binary release targets **Linux x86_64, built on Ubuntu 26.04**.
KDE Plasma 6 is the primary desktop. Other distributions and older Ubuntu releases are not verified; this is not a universal Linux package.

## 1. Install runtime libraries

On Ubuntu/Kubuntu 26.04:

```bash
sudo apt install libgtk-3-0t64 libayatana-appindicator3-1 libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 gstreamer1.0-plugins-good libsqlite3-0 libstdc++6 python3
```

For KDE screen power control and floating-window support in a Wayland session:

```bash
sudo apt install libkscreen-bin xwayland
```

Flutter, Dart, compilers and development headers are **not needed** to run this release. Runtime package names may differ on other distributions. GTK, GStreamer and the desktop notification server must be available.

## 2. Download and verify

Download `pomodoro-focus-1.0.0-linux-x86_64.tar.gz` and `SHA256SUMS` from the [v1.0.0 release](https://github.com/SergeyShastin/pomodoro-focus/releases/tag/v1.0.0) into the same directory.

```bash
sha256sum --check SHA256SUMS
tar -xzf pomodoro-focus-1.0.0-linux-x86_64.tar.gz
cd pomodoro-focus-1.0.0-linux-x86_64
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

The v1.0.0 archive was repackaged to include the MIT license and this updated guide. Application binaries are unchanged. Download the current archive and its matching `SHA256SUMS` together; the checksum of an earlier download will differ.
