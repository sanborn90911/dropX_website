import 'dart:convert';
import 'dart:io';

import 'package:dropx_website/l10n/languages.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _load(String code) =>
    json.decode(File('assets/i18n/$code.json').readAsStringSync()) as Map<String, dynamic>;

void main() {
  final english = _load('en');

  for (final code in kLanguages.keys) {
    test('$code.json translates every English key', () {
      final pack = _load(code);
      final missing = [
        for (final key in english.keys)
          if ((pack[key] as String?)?.trim().isEmpty ?? true) key,
      ];
      expect(missing, isEmpty);
      expect(pack.keys.toSet().difference(english.keys.toSet()), isEmpty, reason: 'unknown keys');
      expect(pack['home.download_for'], contains('{os}'));
    });
  }
}
