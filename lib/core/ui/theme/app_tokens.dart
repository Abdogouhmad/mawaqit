/// Single import for the app's design tokens.
///
/// Component code imports this file instead of reaching into four token files.
/// It is a façade only — the values stay in the file that owns their category,
/// so there is still one place to change a spacing step, a duration or an alpha.
///
/// See `docs/design_system.md` for the vocabulary and the rules for using it.
library;

export 'app_colors.dart';
export 'effects.dart';
export 'motion.dart';
export 'shapes.dart';
