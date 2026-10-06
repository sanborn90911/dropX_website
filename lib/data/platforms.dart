import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Declaration order is the display order everywhere (header menu and the
/// download page's platform list).
enum DeviceOs {
  android('android', 'Android', Icons.android),
  ios('ios', 'iOS', Icons.phone_iphone),
  macos('macos', 'macOS', Icons.laptop_mac),
  windows('windows', 'Windows', Icons.desktop_windows_outlined),
  linux('linux', 'Linux', Icons.terminal);

  final String slug;
  final String label;
  final IconData icon;

  const DeviceOs(this.slug, this.label, this.icon);

  bool get isMobile => this == android || this == ios;

  /// Platforms with no download yet: the page shows "Under testing - Coming soon".
  bool get showsComingSoon => isMobile || this == macos;

  static DeviceOs? fromSlug(String? slug) {
    for (final os in values) {
      if (os.slug == slug) return os;
    }
    return null;
  }

  /// On web, [defaultTargetPlatform] is derived from the browser's user
  /// agent, so this reflects the visitor's OS. Falls back to Windows.
  static DeviceOs detect() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.linux:
        return linux;
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.fuchsia:
        return windows;
    }
  }
}

class InstallerFile {
  final String fileName;
  final String descriptionKey;

  /// Whether the file is on the site (in `web/downloads/`) yet. Unpublished
  /// files show "not available yet" instead of downloading.
  final bool published;

  const InstallerFile(this.fileName, this.descriptionKey, {this.published = false});

  /// Where the file is served from, whatever page the visitor is on.
  Uri get uri => Uri.base.resolve('/downloads/$fileName');
}

const Map<DeviceOs, List<InstallerFile>> kInstallers = {
  DeviceOs.windows: [
    InstallerFile('dropX-Setup-x64.exe', 'download.win_exe', published: true),
    InstallerFile('dropX-Portable-x64.exe', 'download.win_portable', published: true),
  ],
  DeviceOs.linux: [
    InstallerFile('dropX-linux-x64.tar.gz', 'download.linux_targz', published: true),
    InstallerFile('dropx_amd64.deb', 'download.linux_deb', published: true),
    InstallerFile('dropX-x86_64.AppImage', 'download.linux_appimage', published: true),
  ],
};
