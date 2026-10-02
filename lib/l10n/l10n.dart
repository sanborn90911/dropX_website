import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'languages.dart';

/// Loads `assets/i18n/<code>.json` and resolves string keys. Any key that is
/// missing or left empty in the selected language falls back to English, so
/// a partially-translated file is always safe to ship.
class LocaleController extends ChangeNotifier {
  String _code = kDefaultLanguage;
  Map<String, String> _english = const {};
  Map<String, String> _current = const {};

  String get code => _code;
  SiteLanguage get language => kLanguages[_code]!;
  bool get isRtl => language.isRtl;

  Future<void> init() async {
    _english = await _load(kDefaultLanguage);
    _current = _english;
  }

  Future<void> setLanguage(String code) async {
    if (code == _code || !kLanguages.containsKey(code)) return;
    _current = code == kDefaultLanguage ? _english : await _load(code);
    _code = code;
    notifyListeners();
  }

  /// Translated string for [key]. `{name}` placeholders are filled from [args].
  String t(String key, [Map<String, String> args = const {}]) {
    final current = _current[key];
    var value = (current != null && current.isNotEmpty) ? current : (_english[key] ?? key);
    args.forEach((k, v) => value = value.replaceAll('{$k}', v));
    return value;
  }

  static Future<Map<String, String>> _load(String code) async {
    try {
      final raw = await rootBundle.loadString('assets/i18n/$code.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return {
        for (final e in decoded.entries)
          if (!e.key.startsWith('_') && e.value is String) e.key: e.value as String,
      };
    } catch (_) {
      return const {};
    }
  }
}

/// Provides the [LocaleController] to the widget tree; widgets that call
/// [L10n.of] rebuild when the language changes.
class L10n extends InheritedNotifier<LocaleController> {
  const L10n({super.key, required LocaleController controller, required super.child}) : super(notifier: controller);

  static LocaleController of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<L10n>()!.notifier!;
}
