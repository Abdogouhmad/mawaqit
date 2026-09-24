# Mawaqit release shrinking rules (used with isMinifyEnabled + isShrinkResources).
# Libraries (WorkManager, Glance, home_widget, notification plugins) ship their
# own rules via consumer-rules; only app entry points need pinning here.

# Flutter engine / plugins (referenced reflectively).
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# App native entry points: manifest receivers/services/activities and the
# MethodChannel bridge are looked up by name, so R8 must not rename them.
-keep class com.mawaqit.mawaqit.** { *; }

# The Flutter engine references Play Core split-install APIs for deferred
# components, which this app neither uses nor bundles (GitHub APK
# distribution, not Play). Suppress the missing-class warnings so R8 doesn't
# fail on them — exactly what the build's missing_rules.txt asks for.
-dontwarn com.google.android.play.core.**
