import java.util.Properties

plugins {
    id("org.jetbrains.kotlin.plugin.compose") version "2.4.0"
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The versionCode is derived deterministically from the SemVer `versionName`
// (e.g. "0.4.0" → 400, "1.2.43" → 10243) with the formula
// `major*10000 + minor*100 + patch`, so `pubspec.yaml` stays the single source
// of truth and every build of a given tag gets the identical versionCode that
// update_manifest.json and the release automation expect.
val pubspecVersionName = flutter.versionName ?: "0.0.0"
val versionParts = pubspecVersionName.split('.').map { it.toIntOrNull() ?: 0 }
val derivedVersionCode =
    versionParts.getOrElse(0) { 0 } * 10000 +
    versionParts.getOrElse(1) { 0 } * 100 +
    versionParts.getOrElse(2) { 0 }

android {
    namespace = "com.mawaqit.mawaqit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mawaqit.mawaqit"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Derived from SemVer (major*10000 + minor*100 + patch) so the code
        // matches the OTA manifest exactly. When building split APKs, 1000 *
        // ABI_VERSION is added automatically by Flutter; you can force the
        // single derived value with `-P force-version-code-ignoring-abi=true`.
        versionCode = derivedVersionCode
        versionName = pubspecVersionName
    }

    signingConfigs {
        create("release") {
            val props = Properties()
            val propsFile = rootProject.file("key.properties")
            if (propsFile.exists()) {
                propsFile.inputStream().use { props.load(it) }
            }
            if (props["storeFile"] != null) {
                storeFile = file(props["storeFile"] as String)
                storePassword = props["storePassword"] as String
                keyAlias = props["keyAlias"] as String
                keyPassword = props["keyPassword"] as String
            } else {
                // Local dev fallback: reuse the debug signature.
                storeFile = file("${System.getProperty("user.home")}/.android/debug.keystore")
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
    }

    buildTypes {
        release {
            // Signed with the stable release keystore provisioned by ./build.sh
            // (android/key.properties, written from the MAWAQIT_* secrets or
            // reused locally). Falls back to the debug key when no keystore is
            // present so `flutter run --release` still works on a fresh clone.
            signingConfig = signingConfigs.getByName("release")
            // R8 + resource shrinking keep the APK lean: unused Dart/Java code
            // and unreferenced resources are stripped. Entry points are pinned
            // in proguard-rules.pro.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
    buildFeatures {
        compose = true
    }

}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.glance:glance-appwidget:1.2.0")
    // The workmanager plugin keeps work-runtime to itself, so BootReceiver
    // cannot enqueue the post-reboot re-arm without declaring it here. Pinned to
    // the version the plugin resolves, so Gradle picks a single artifact.
    implementation("androidx.work:work-runtime:2.10.2")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
