pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // 【关键升级】满足 Flutter 要求，升级到 8.2.1
    id("com.android.application") version "8.9.1" apply false

    // 【配套升级】Kotlin 升级到 1.9.0 以匹配新版 AGP
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")