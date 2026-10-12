import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/features/settings/widgets/alarm_access_section.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Settings → Permissions.
///
/// The one place to check that the system accesses the adhan depends on are
/// granted. Each row opens the exact Android screen that grants it, and a live
/// *Allowed* / *Fix* pill reports the current state.
///
/// Pushed from the main settings list, so it renders its own [Scaffold] and
/// [AppBar] with a back button. The bodies of the rows are Android-only; other
/// platforms get a short explanation instead of an empty screen.
class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: UiText(
          l10n.settingsSectionPermissions,
          type: UiTextType.titleLarge,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.huge,
            AppSpacing.sm,
            AppSpacing.huge,
            AppSpacing.pageBottom,
          ),
          child: defaultTargetPlatform == TargetPlatform.android
              ? const AlarmAccessSection()
              : AppCard(child: UiText(l10n.settingsPermissionsUnavailable)),
        ),
      ),
    );
  }
}
