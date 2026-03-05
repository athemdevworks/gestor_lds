android {
    namespace = "com.nuevotrujillo.gestorlds.gestor_lds"

    // 👇 CAMBIO 1: Forzamos el SDK 35 para que el PDF no falle (lStar)
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.nuevotrujillo.gestorlds.gestor_lds"

        // 👇 CAMBIO 2: Forzamos minSdk a 23 (Android 6.0+) para evitar quejas de plugins
        minSdk = 23

        // 👇 CAMBIO 3: Sincronizamos con el 35
        targetSdk = 35

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ... resto del archivo igual
}