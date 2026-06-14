plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.vivatpass"
    compileSdk = 36
    // NDK 26.1.10909125 wajib untuk tflite_flutter 0.12.x (GPU delegate)
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.vivatpass"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ── KRITIS: jangan compress .tflite — TFLite tidak bisa baca file terkompresi ──
    androidResources {
        noCompress += listOf("tflite", "lite")
    }

    buildTypes {
        release {
            // Signing dengan debug key — ganti ke release key saat production
            signingConfig = signingConfigs.getByName("debug")
            // Matikan minify/shrink — bisa menghapus class TFLite yang dipakai reflection
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            isDebuggable = true
        }
    }

    // Split APK per ABI — kurangi ukuran APK di Play Store
    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "armeabi-v7a", "x86_64")
            isUniversalApk = true   // tetap buat universal APK untuk sideload
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    // tflite_flutter 0.12.x sudah bundel litert-api (GPU delegate included)
    // Tidak perlu tambahkan tensorflow-lite-gpu secara eksplisit
}

flutter {
    source = "../.."
}
