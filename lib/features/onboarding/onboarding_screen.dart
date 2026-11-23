import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mawaqit/core/navigation/app_shell.dart';
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/data/models/alarm_access.dart';
import 'package:mawaqit/features/onboarding/onboarding_gate.dart';
import 'package:mawaqit/l10n/enum_localization.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/shared/ui/app_button.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/app_icon_button.dart';
import 'package:mawaqit/shared/ui/app_list_row.dart';
import 'package:mawaqit/shared/ui/app_mark.dart';
import 'package:mawaqit/shared/ui/app_pill.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// The first-run walkthrough.
///
/// Four short pages replace the old "grant everything now" gate: what the app
/// is, why it needs alerts, why it needs the screen/battery exceptions, and
/// where to choose a city. Every permission row shows its live state and opens
/// the matching system screen; none of them block Skip or Finish. The current
/// page is persisted, so leaving halfway through resumes on the same page.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const int pageCount = 4;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  late final PageController _pages;
  late final int _initialPage;

  /// Mirrors the controller's current page. Reading `PageController.page`
  /// during the first build throws before the attached `PageView` has positions,
  /// so the header and footer read this instead.
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialPage = OnboardingGate.instance.step.clamp(
      0,
      OnboardingScreen.pageCount - 1,
    );
    _currentPage = _initialPage;
    _pages = PageController(initialPage: _initialPage);
    unawaited(_refreshAccess());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pages.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refreshAccess());
  }

  Future<void> _refreshAccess() async {
    await ref.read(notificationServiceProvider).refreshAlarmAccess();
    if (mounted) setState(() {});
  }

  AlarmAccess get _access => ref.read(notificationServiceProvider).alarmAccess;

  Future<void> _request(AlarmPermission permission) async {
    await ref.read(notificationServiceProvider).requestAlarmAccess(permission);
    await _refreshAccess();
  }

  Future<void> _goTo(int page) async {
    await OnboardingGate.instance.rememberStep(page);
    if (!mounted) return;
    setState(() => _currentPage = page);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    await _pages.animateToPage(
      page,
      duration: reduceMotion ? Duration.zero : AppMotion.route,
      curve: reduceMotion ? Curves.linear : AppMotion.standard,
    );
  }

  Future<void> _finish({required bool keepStep}) async {
    final gate = OnboardingGate.instance;
    await gate.complete(keepStep: keepStep);
    if (!mounted) return;
    final target = gate.pendingTarget ?? AppRoutes.home;
    gate.pendingTarget = null;
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final page = _currentPage;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.huge,
                AppSpacing.md,
                AppSpacing.huge,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  const AppMark(size: AppSize.markFooter),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: UiText(
                      l10n.onboardingStep(page + 1, OnboardingScreen.pageCount),
                      type: UiTextType.labelMedium,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  // A text button would not fit beside the progress label at
                  // 2x text on a 360dp phone. The icon keeps Skip reachable and
                  // the tooltip supplies the same localized announcement.
                  AppIconButton(
                    icon: Icons.close_rounded,
                    tooltip: l10n.onboardingSkip,
                    onPressed: () => _finish(keepStep: true),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (index) {
                  unawaited(OnboardingGate.instance.rememberStep(index));
                  setState(() => _currentPage = index);
                },
                children: [
                  _WelcomePage(l10n: l10n),
                  _PermissionPage(
                    icon: Icons.notifications_active_outlined,
                    title: l10n.onboardingAlertsTitle,
                    body: l10n.onboardingAlertsBody,
                    permissions: const [
                      AlarmPermission.notifications,
                      AlarmPermission.exactAlarms,
                    ],
                    access: _access,
                    onRequest: _request,
                  ),
                  _PermissionPage(
                    icon: Icons.lock_outline,
                    title: l10n.onboardingTakeoverTitle,
                    body: l10n.onboardingTakeoverBody,
                    permissions: const [
                      AlarmPermission.fullScreenIntent,
                      AlarmPermission.overlay,
                      AlarmPermission.policyAccess,
                      AlarmPermission.battery,
                    ],
                    access: _access,
                    onRequest: _request,
                  ),
                  _LocationPage(
                    l10n: l10n,
                    onOpenSettings: () => _finish(keepStep: true),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.huge,
                AppSpacing.xs,
                AppSpacing.huge,
                AppSpacing.pageBottom,
              ),
              child: AppButton(
                label: page == OnboardingScreen.pageCount - 1
                    ? l10n.onboardingFinish
                    : l10n.onboardingNext,
                icon: page == OnboardingScreen.pageCount - 1
                    ? Icons.arrow_forward_rounded
                    : null,
                onPressed: () => page == OnboardingScreen.pageCount - 1
                    ? _finish(keepStep: false)
                    : _goTo(page + 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _PageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppMark(),
          const SizedBox(height: AppSpacing.tera),
          UiText(
            l10n.onboardingWelcomeTitle,
            type: UiTextType.displaySmall,
            fontWeight: AppWeight.bold,
            letterSpacing: AppTypeDetail.appTitleTracking,
          ),
          const SizedBox(height: AppSpacing.md),
          UiText(
            l10n.onboardingWelcomeBody,
            type: UiTextType.bodyLarge,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _LocationPage extends StatelessWidget {
  const _LocationPage({required this.l10n, required this.onOpenSettings});

  final AppLocalizations l10n;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _PageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.near_me_outlined,
            size: AppIconSize.xxl,
            color: scheme.primary,
          ),
          const SizedBox(height: AppSpacing.tera),
          UiText(
            l10n.onboardingLocationTitle,
            type: UiTextType.displaySmall,
            fontWeight: AppWeight.bold,
            letterSpacing: AppTypeDetail.appTitleTracking,
          ),
          const SizedBox(height: AppSpacing.md),
          UiText(
            l10n.onboardingLocationBody,
            type: UiTextType.bodyLarge,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.giga),
          AppButton(
            label: l10n.onboardingOpenSettings,
            icon: Icons.tune_outlined,
            variant: AppButtonVariant.outlined,
            expanded: false,
            onPressed: onOpenSettings,
          ),
        ],
      ),
    );
  }
}

class _PermissionPage extends StatelessWidget {
  const _PermissionPage({
    required this.icon,
    required this.title,
    required this.body,
    required this.permissions,
    required this.access,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<AlarmPermission> permissions;
  final AlarmAccess access;
  final Future<void> Function(AlarmPermission) onRequest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return _PageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIconSize.xxl, color: scheme.primary),
          const SizedBox(height: AppSpacing.tera),
          UiText(
            title,
            type: UiTextType.displaySmall,
            fontWeight: AppWeight.bold,
            letterSpacing: AppTypeDetail.appTitleTracking,
          ),
          const SizedBox(height: AppSpacing.md),
          UiText(
            body,
            type: UiTextType.bodyLarge,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.lg),
          UiText(
            l10n.onboardingPermissionHint,
            type: UiTextType.bodySmall,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (defaultTargetPlatform == TargetPlatform.android)
            AppCard(
              ambient: false,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                children: [
                  for (final permission in permissions)
                    AppListRow(
                      title: permission.localized(l10n),
                      subtitle: permission.localizedBlurb(l10n),
                      leading: Icon(permission.icon, color: scheme.primary),
                      trailing: AppPill(
                        label: access.granted(permission)
                            ? l10n.accessAllowed
                            : l10n.accessFix,
                        icon: access.granted(permission)
                            ? Icons.check_circle_outline
                            : Icons.open_in_new,
                        dense: true,
                        color: access.granted(permission)
                            ? scheme.primary
                            : scheme.error,
                      ),
                      onTap: () => onRequest(permission),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.huge,
        vertical: AppSpacing.lg,
      ),
      child: child,
    );
  }
}
