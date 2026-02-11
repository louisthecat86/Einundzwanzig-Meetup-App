allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // --- NEU HINZUGEFÜGT: Fix für veraltete Plugins (wie nfc_manager 3.5.0) ---
    // Verhindert, dass Warnungen (z.B. 'toLowerCase is deprecated') den Build abbrechen.
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            allWarningsAsErrors = false
            // Hilft zusätzlich bei Kompatibilitätsproblemen mit älteren Kotlin-Versionen
            freeCompilerArgs = freeCompilerArgs + listOf("-Xjvm-default=all")
        }
    }
    // -------------------------------------------------------------------------
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}