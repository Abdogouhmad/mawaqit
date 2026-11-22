import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The generated delegates throw at runtime when a locale is missing a message
/// that exists in the template, and OTA copy is especially easy to forget in
/// FR/AR. Comparing the source ARBs here turns that into a fast CI failure.
void main() {
  const arbDir = 'lib/l10n';
  const template = 'app_en.arb';
  const locales = ['app_ar.arb', 'app_fr.arb'];

  Map<String, dynamic> readArb(String name) =>
      jsonDecode(File('$arbDir/$name').readAsStringSync())
          as Map<String, dynamic>;

  Set<String> messages(Map<String, dynamic> arb) =>
      arb.keys.where((key) => !key.startsWith('@')).toSet();

  test('all locales declare exactly the template messages', () {
    final english = messages(readArb(template));
    expect(english, isNotEmpty);

    for (final name in locales) {
      final localized = messages(readArb(name));
      expect(
        localized.difference(english),
        isEmpty,
        reason: '$name has messages missing from $template',
      );
      expect(
        english.difference(localized),
        isEmpty,
        reason: '$name is missing messages from $template',
      );
    }
  });

  test('every parameterized template message documents its placeholders', () {
    final english = readArb(template);
    for (final entry in english.entries) {
      if (entry.key.startsWith('@')) continue;
      final placeholders = RegExp(r'\{(\w+)\}')
          .allMatches(entry.value as String)
          .map((match) => match.group(1)!)
          .toSet();
      if (placeholders.isEmpty) continue;

      final meta = english['@${entry.key}'] as Map<String, dynamic>?;
      final documented = (meta?['placeholders'] as Map<String, dynamic>? ?? {})
          .keys
          .toSet();
      expect(
        documented,
        placeholders,
        reason: '@${entry.key} must document ${placeholders.join(', ')}',
      );
    }
  });
}
