import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase applies itself as soon as the config file is present. The Google
// Services plugin fails the build outright when google-services.json is
// missing, so it must not be applied unconditionally — and this way enabling
// Crashlytics is a file drop, with no code change and no new release.
// The Crashlytics plugin uploads the R8 mapping file for every release build,
// which is what makes an obfuscated stack trace readable in the console.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

// Load android/key.properties (gitignored). When absent — e.g. in CI without
// secrets, or a fresh clone — the release build still succeeds but is left
// UNSIGNED. It is never debug-signed; see the release block below.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val hasReleaseKey = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.americangroupllc.calcmaster"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.americangroupllc.calcmaster"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
    buildFeatures {
        // AGP 9 disables resValue by default; the flavors below use it to set
        // android:label per environment.
        resValues = true
    }

    // dev / staging / prod install side by side via an applicationId suffix, so
    // a tester can hold all three and staging can never overwrite production.
    flavorDimensions += "env"

    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "CalcMaster Dev")
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "CalcMaster Staging")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "CalcMaster")
        }
    }


    buildTypes {
        release {
            // Deliberately does NOT fall back to signingConfigs.debug. Play
            // rejects debug-signed uploads, and a silent fallback produces an
            // artifact that looks releasable but is not. With no
            // android/key.properties the build still succeeds and the artifact
            // is left unsigned, so the missing key is obvious rather than
            // hidden. Mirrors Kinnav/android/app/build.gradle.kts:83-92.
            if (hasReleaseKey) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
