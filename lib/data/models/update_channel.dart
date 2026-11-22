/// Release channel used for OTA update checks.
///
/// The value is persisted as a lowercase string in `UpdateStore`. Anything we
/// do not recognise (a missing key, a future value, corrupted preferences)
/// falls back to [stable], so an unknown value can never silently opt a user
/// into pre-release builds.
enum UpdateChannel {
  stable('stable'),
  beta('beta');

  const UpdateChannel(this.storageKey);

  /// Value written to / read from SharedPreferences.
  final String storageKey;

  /// Fail-closed parser: only an explicit `beta` opts into pre-releases.
  static UpdateChannel fromStorage(String? value) =>
      value == beta.storageKey ? beta : stable;

  /// Parser that also rejects unknown values, for untrusted manifest data.
  static UpdateChannel? tryFromStorage(String? value) {
    if (value == null || value.isEmpty || value == stable.storageKey) {
      return stable;
    }
    if (value == beta.storageKey) return beta;
    return null;
  }
}
