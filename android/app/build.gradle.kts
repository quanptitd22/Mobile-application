plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.medireminder_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.medireminder_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Kotlin DSL: bật coreLibraryDesugaring
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(kotlin("stdlib-jdk7"))

    // Kotlin DSL: core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
dependencies {
    // Import the Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))

    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")

    // Nếu muốn dùng thêm Firebase khác thì bỏ comment:
    // implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore")
    // implementation("com.google.firebase:firebase-database")
    // implementation("com.google.firebase:firebase-messaging")
}
