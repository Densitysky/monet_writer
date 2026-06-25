import java.util.Properties
import java.io.FileInputStream

// 【新增】读取 local.properties 中的 Flutter 版本号配置
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { stream ->
        localProperties.load(stream)
    }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")?.toInt() ?: 1
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.monet_writer"

    // 【关键修改 1】必须升级到 36，以满足 image_picker 等插件的要求
    compileSdk = 36
    // 【核心修复】：将 NDK 版本升级到插件要求的 27.0.12077973
    ndkVersion = "27.0.12077973"

    compileOptions {
        // 保持 Java 17，适配 Android 36 编译环境
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.example.monet_writer"
        minSdk = flutter.minSdkVersion

        // 【关键修改 2】目标版本也同步为 36
        targetSdk = 36

        // 使用 Flutter 注入的版本号，来源于 pubspec.yaml 的 `version` 字段 (格式：x.y.z+build)
        versionCode = flutterVersionCode
        versionName = flutterVersionName
    }

    // 加载 key.properties 文件
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    // 定义签名配置
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = if (keystoreProperties.containsKey("storeFile")) file(keystoreProperties["storeFile"] as String) else null
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            // 【关键】使用 release 签名
            signingConfig = signingConfigs.getByName("release")
            // 启用混淆优化包体积
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// 强制统一依赖版本 (保护 Isar 和其他老库不崩)
configurations.all {
    resolutionStrategy {
        force("androidx.core:core-ktx:1.13.1")
        force("androidx.core:core:1.13.1")
        force("androidx.activity:activity-ktx:1.9.0")
        force("androidx.activity:activity:1.9.0")
    }
}

flutter {
    source = "../.."
}

dependencies {
}