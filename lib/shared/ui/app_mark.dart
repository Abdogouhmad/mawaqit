import 'package:flutter/material.dart';

import 'package:mawaqit/core/const/asset_paths.dart';

/// The app's own launcher art — the emerald mihrab mark — drawn in-app.
///
/// Both the About dialog and the Settings footer want the brand mark, and a
/// Material [Icon] glyph is not the logo. Rendering the real asset keeps the two
/// in step with each other and with the icon on the launcher.
///
/// The source PNG is a full-bleed rounded square — an emerald field with a light
/// mihrab and transparent corners — so it supplies its own shape and colour:
/// nothing clips, masks or tints it here.
class AppMark extends StatelessWidget {
  /// Lead size for the About dialog.
  static const double aboutSize = 72;

  /// Sign-off size for the Settings footer.
  static const double footerSize = 44;

  const AppMark({super.key, this.size = aboutSize});

  /// Square edge length in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    // The asset is 512px but is only ever drawn small, so decode it at the
    // resolution it is painted at rather than at full size — one fewer
    // full-resolution bitmap in the image cache for every appearance.
    final cacheWidth = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return Image.asset(
      AssetPaths.appIcon,
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      // Decorative: the app name is always rendered beside it.
      excludeFromSemantics: true,
    );
  }
}
