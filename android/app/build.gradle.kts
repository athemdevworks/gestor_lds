plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nuevotrujillo.gestorlds.gestor_lds"

    // 👇 SUBIMOS AL 36 PARA CALMAR A LOS PLUGINS NUEVOS
    compileSdk = 36

    defaultConfig {
        applicationId = "com.nuevotrujillo.gestorlds.gestor_lds"
        minSdk = 23

        // 👇 LO EMPAREJAMOS CON EL 36
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
