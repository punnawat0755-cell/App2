import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppEnv {
  AppEnv._();

  static final Map<String, String> _values = <String, String>{};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;

    try {
      final rawEnv = await rootBundle.loadString('.env');
      _values
        ..clear()
        ..addAll(_parse(rawEnv));
    } catch (error) {
      debugPrint('AppEnv: unable to load .env asset: $error');
    } finally {
      _loaded = true;
    }
  }

  static String string(
    String key, {
    String defaultValue = '',
    String? compileTimeValue,
  }) {
    final normalizedCompileTimeValue = compileTimeValue?.trim();
    if (normalizedCompileTimeValue != null &&
        normalizedCompileTimeValue.isNotEmpty) {
      return normalizedCompileTimeValue;
    }

    final bundledValue = _values[key]?.trim();
    if (bundledValue != null && bundledValue.isNotEmpty) {
      return bundledValue;
    }

    return defaultValue;
  }

  static bool boolean(
    String key, {
    required bool defaultValue,
    bool? compileTimeValue,
  }) {
    if (compileTimeValue != null) {
      return compileTimeValue;
    }

    final bundledValue = _values[key]?.trim().toLowerCase();
    switch (bundledValue) {
      case '1':
      case 'true':
      case 'yes':
      case 'on':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'off':
        return false;
      default:
        return defaultValue;
    }
  }

  static Map<String, String> _parse(String rawEnv) {
    final parsed = <String, String>{};

    for (final rawLine in rawEnv.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      final separatorIndex = line.indexOf('=');
      if (separatorIndex <= 0) {
        continue;
      }

      final key = line.substring(0, separatorIndex).trim();
      var value = line.substring(separatorIndex + 1).trim();

      if (value.length >= 2) {
        final startsWithSingleQuote = value.startsWith("'");
        final endsWithSingleQuote = value.endsWith("'");
        final startsWithDoubleQuote = value.startsWith('"');
        final endsWithDoubleQuote = value.endsWith('"');
        final isWrappedInQuotes =
            (startsWithSingleQuote && endsWithSingleQuote) ||
                (startsWithDoubleQuote && endsWithDoubleQuote);

        if (isWrappedInQuotes) {
          value = value.substring(1, value.length - 1);
        }
      }

      if (key.isNotEmpty) {
        parsed[key] = value;
      }
    }

    return parsed;
  }
}
