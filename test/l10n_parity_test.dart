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

  test('every parameterized message documents its placeholders', () {
    // Only the template needs placeholder metadata: `gen-l10n` reads types and
    // examples from the canonical EN ARB, and localized ARBs merely translate
    // the strings. Cross-locale placeholder *usage* is checked separately.
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

  test('messages use the same placeholders across all locales', () {
    final english = readArb(template);
    for (final name in locales) {
      final localized = readArb(name);
      for (final entry in english.entries) {
        if (entry.key.startsWith('@')) continue;
        final expected = RegExp(r'\{(\w+)\}')
            .allMatches(entry.value as String)
            .map((match) => match.group(1)!)
            .toSet();
        final actual = RegExp(r'\{(\w+)\}')
            .allMatches(localized[entry.key] as String)
            .map((match) => match.group(1)!)
            .toSet();
        expect(
          actual,
          expected,
          reason: '$name: ${entry.key} must use the same placeholders as en',
        );
      }
    }
  });

  test('every template message with metadata has a description', () {
    final english = readArb(template);
    for (final entry in english.entries) {
      if (!entry.key.startsWith('@') || entry.key == '@@locale') continue;
      final meta = entry.value as Map<String, dynamic>;
      expect(
        meta['description'],
        isA<String>(),
        reason: '${entry.key} needs a description for translators',
      );
    }
  });

  test('no metadata refers to a message that no longer exists', () {
    for (final name in [template, ...locales]) {
      final arb = readArb(name);
      final declared = messages(arb);
      for (final key in arb.keys) {
        if (!key.startsWith('@') || key == '@@locale') continue;
        expect(
          declared.contains(key.substring(1)),
          isTrue,
          reason: '$name: stale ARB metadata $key',
        );
      }
    }
  });
}
