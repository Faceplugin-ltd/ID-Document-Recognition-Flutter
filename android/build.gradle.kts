group = "com.faceplugin.document_reader_sdk"
version = "1.0-SNAPSHOT"

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // AGP only — do not apply Kotlin Gradle Plugin (Built-in Kotlin / AGP 9+).
        classpath("com.android.tools.build:gradle:8.9.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "com.faceplugin.document_reader_sdk"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
    }
}

// Built-in Kotlin (AGP 9+ / Flutter consumer) — no org.jetbrains.kotlin.android apply.
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation("androidx.exifinterface:exifinterface:1.3.7")
    val bundledAar = file("libs/documentreadersdk.aar")
    when {
        bundledAar.exists() -> implementation(files(bundledAar))
        findProject(":libdocsdk") != null ->
            // Example app: example/android/libdocsdk via settings.gradle.kts
            implementation(project(":libdocsdk"))
        else ->
            throw GradleException(
                "Missing documentreadersdk.aar.\n" +
                    "Place it at android/libs/documentreadersdk.aar " +
                    "(or example/android/libdocsdk/ for the demo)."
            )
    }
}
