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

  /// Platforms with no download: the page shows [statusKey]'s message instead.
  bool get showsStatus => isMobile || this == macos;

  String get statusKey => 'download.status_$slug';

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

/// `releases/latest/download/<file>` always points at the newest release.
const String kReleaseDownloadBase = 'https://github.com/sanborn90911/dropX_website/releases/latest/download';

class InstallerFile {
  final String fileName;
  final String descriptionKey;

  /// Whether the file is attached to a release yet. Unpublished
  /// files show "not available yet" instead of downloading.
  final bool published;

  const InstallerFile(this.fileName, this.descriptionKey, {this.published = false});

  /// The file attached to the newest GitHub release. Keep the file names
  /// identical from one release to the next so this link never changes.
  Uri get uri => Uri.parse('$kReleaseDownloadBase/$fileName');
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
