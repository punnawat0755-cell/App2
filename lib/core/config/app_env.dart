class AppEnv {
  AppEnv._();

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

    return defaultValue;
  }
}
