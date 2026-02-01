 // ↑ add this whole block at the very top of android/build.gradle.kts
 buildscript {
       repositories {
            google()
             mavenCentral()
           }
       dependencies {
             // ① Kotlin Gradle plugin 1.9.10 (so metadata v2.1.0 is understood)
             classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.10")
             // ② Android Gradle plugin (match your AGP version)
             classpath("com.android.tools.build:gradle:7.4.2")
             // ③ (if you’re using Firebase / Google Services)
             classpath("com.google.gms:google-services:4.3.15")
           }
     }





allprojects {
    repositories {
        google()
        mavenCentral()
    }

}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
