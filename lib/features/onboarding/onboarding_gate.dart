import 'package:flutter/foundation.dart';

import 'package:mawaqit/core/const/pref_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Decides whether the first-run walkthrough is shown before the tab shell.
///
/// This is deliberately a tiny synchronous gate, not a Riverpod provider. The
/// router is created once at startup and its `redirect` has to answer *during*
/// the first frame; an async provider there would either flash Home before the
/// preference arrived or need a second router. `main()` loads the flag before
/// `runApp`, so by the time `isComplete` is read it is already the stored value.
///
/// The step is persisted separately so a user who leaves mid-flow resumes on
/// the same page instead of starting over. Skipping and finishing both mark the
/// flow complete; only finishing clears the saved step.
class OnboardingGate {
  OnboardingGate._();

  static final OnboardingGate instance = OnboardingGate._();

  // Tests and any host that skips `main()` see the ordinary app; only the real
  // bootstrap's `load()` can turn this false for a first-run install.
  bool _complete = true;
  int _step = 0;

  /// Where the user was headed when onboarding interrupted the launch.
  ///
  /// A widget tap or a deep link must still land on its original tab once the
  /// flow is dismissed; without this, onboarding would silently swallow it.
  String? pendingTarget;

  bool get isComplete => _complete;

  /// Clamped to the number of pages in [OnboardingScreen].
  int get step => _step;

  /// Reads the stored completion flag and step. Never throws: a preference
  /// failure must degrade to showing onboarding, not to a blank app.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _complete = prefs.getBool(PrefKeys.onboardingComplete) ?? false;
      _step = prefs.getInt(PrefKeys.onboardingStep) ?? 0;
    } catch (error) {
      debugPrint('Onboarding gate could not read preferences: $error');
      _complete = false;
      _step = 0;
    }
  }

  Future<void> rememberStep(int step) async {
    if (_step == step) return;
    _step = step;
    await _write((prefs) => prefs.setInt(PrefKeys.onboardingStep, step));
  }

  /// Marks the walkthrough seen. [keepStep] preserves the page for a skip so a
  /// later "Replay setup" entry can resume there; finishing clears it.
  Future<void> complete({bool keepStep = false}) async {
    _complete = true;
    if (!keepStep) _step = 0;
    await _write((prefs) async {
      await prefs.setBool(PrefKeys.onboardingComplete, true);
      if (keepStep) {
        await prefs.setInt(PrefKeys.onboardingStep, _step);
      } else {
        await prefs.remove(PrefKeys.onboardingStep);
      }
    });
  }

  Future<void> _write(
    Future<void> Function(SharedPreferences prefs) write,
  ) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (error) {
      debugPrint('Onboarding gate could not write preferences: $error');
    }
  }

  /// Test-only reset so each widget test starts from a known first-run state.
  @visibleForTesting
  void resetForTests({bool complete = true, int step = 0, String? target}) {
    _complete = complete;
    _step = step;
    pendingTarget = target;
  }
}
