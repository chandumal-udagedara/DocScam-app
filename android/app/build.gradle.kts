import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Add the Google services and Crashlytics plugins
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.scamslayers.docscam"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "30.0.14904198"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.scamslayers.docscam"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Signing secrets live in android/keystore.properties, which is git-ignored.
    // Without it, release builds fall back to debug signing so the project still builds.
    val releaseKeystoreFile = rootProject.file("keystore.properties")
    val releaseKeystore = Properties()
    val hasReleaseKeystore = releaseKeystoreFile.exists()
    if (hasReleaseKeystore) {
        releaseKeystore.load(FileInputStream(releaseKeystoreFile))
    }

    signingConfigs {
        if (hasReleaseKeystore) create("release") {
            keyAlias = releaseKeystore["keyAlias"] as String
            keyPassword = releaseKeystore["keyPassword"] as String
            storeFile = releaseKeystore["storeFile"]?.let { file(it) }
            storePassword = releaseKeystore["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) signingConfigs.getByName("release")
                            else signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
