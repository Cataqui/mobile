import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val secrets = Properties()
val secretsFile = rootProject.file("secrets.properties")

require(secretsFile.isFile) {
    "Missing app/android/secrets.properties. Copy secrets.properties.example and configure it."
}
secretsFile.inputStream().use { secrets.load(it) }

val googleMapsApiKey =
    requireNotNull(secrets.getProperty("GOOGLE_MAPS_API_KEY")?.trim()) {
        "Missing GOOGLE_MAPS_API_KEY in app/android/secrets.properties."
    }

require(googleMapsApiKey.isNotEmpty() && googleMapsApiKey != "PASTE_ANDROID_API_KEY_HERE") {
    "GOOGLE_MAPS_API_KEY must be configured in app/android/secrets.properties."
}

android {
    namespace = "com.cataqui.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    flavorDimensions += "environment"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.cataqui.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
    }

    productFlavors {
        create("development") {
            dimension = "environment"
            applicationIdSuffix = ".development"
            resValue("string", "app_name", "Cataquí Dev")
            signingConfig = signingConfigs.getByName("debug")
        }

        create("production") {
            dimension = "environment"
            resValue("string", "app_name", "Cataquí")
        }
    }

    buildFeatures {
        resValues = true
    }

    lint {
        abortOnError = true
        lintConfig = file("lint.xml")
        warningsAsErrors = true
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
