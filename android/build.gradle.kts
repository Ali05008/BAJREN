allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// flutter_webrtc (and potentially other plugins) ship their own Android
// module compiled against an older compileSdk (31), which fails AGP's AAR
// metadata check against newer transitive androidx dependencies that
// require compileSdk >= 34. Raising OUR app's compileSdk does not affect
// a plugin's OWN module compileSdk — so we force every subproject
// (including plugin modules) to compile against the same, newer SDK here.
// This is Gradle configuration only: no plugin source, WebRTC, signaling,
// or calling logic is touched.
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android")
        if (androidExt is com.android.build.gradle.BaseExtension) {
            androidExt.compileSdkVersion(36)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
