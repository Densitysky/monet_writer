allprojects {
    repositories {
        google()
        mavenCentral()
        // ucrop 需要的仓库
        maven { url = uri("https://www.jitpack.io") }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 【关键修复】强制所有插件使用 SDK 36 编译，解决 lStar not found 问题
subprojects {
    afterEvaluate {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                // 强制修改 compileSdk 为 36
                val setCompileSdk = android.javaClass.getMethod("setCompileSdk", Integer.TYPE)
                setCompileSdk.invoke(android, 36)
            } catch (e: Exception) {
                try {
                    // 兼容旧版 AGP 属性名
                    val setCompileSdkVersion = android.javaClass.getMethod("setCompileSdkVersion", Integer.TYPE)
                    setCompileSdkVersion.invoke(android, 36)
                } catch (e2: Exception) {
                    println("Note: Could not force compileSdk for ${project.name}")
                }
            }
        }
    }
}

// Isar 的 namespace 修复逻辑 (保持)
subprojects {
    if (name == "isar_flutter_libs") {
        afterEvaluate {
            try {
                val android = extensions.findByName("android")
                if (android != null) {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(android, "dev.isar.isar_flutter_libs")
                    println("Isar namespace fixed successfully for $name")
                }
            } catch (e: Exception) {
                println("Isar fix skipped: $e")
            }
        }
    }
}

// 依赖关系
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}