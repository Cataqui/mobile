import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val aabSigningPropertiesFile = rootProject.file("aab-signing.properties")

val aabSigningProperties =
    Properties().apply {
        if (aabSigningPropertiesFile.exists()) {
            aabSigningPropertiesFile.inputStream().use(::load)
        }
    }

fun requiredAabSigningProperty(name: String): String =
    aabSigningProperties.getProperty(name)?.takeIf(String::isNotBlank)
        ?: throw GradleException(
            "Missing Android App Bundle signing property '$name' in ${aabSigningPropertiesFile.path}. " +
                "Run 'fvm dart run release:build_aab' from the repository root " +
                "so release tooling can create the signing adapter.",
        )

val buildsReleaseArtifact =
    gradle.startParameter.taskNames.any { taskName ->
        taskName.endsWith("assembleRelease") ||
            taskName.endsWith("bundleRelease") ||
            taskName.endsWith("packageRelease")
    }

if (buildsReleaseArtifact && !aabSigningPropertiesFile.exists()) {
    throw GradleException(
        "Android release artifacts require ${aabSigningPropertiesFile.path}. " +
            "Run 'fvm dart run release:build_aab' from the repository root " +
            "so release tooling can create it from the protected environment. " +
            "Release builds never fall back to the Android debug certificate.",
    )
}

android {
    namespace = "com.cataqui.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.cataqui.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("aab") {
            if (aabSigningPropertiesFile.exists()) {
                keyAlias = requiredAabSigningProperty("keyAlias")
                keyPassword = requiredAabSigningProperty("keyPassword")
                storeFile = rootProject.file(requiredAabSigningProperty("storeFile"))
                storePassword = requiredAabSigningProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("aab")
        }
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
