allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // --- KORRIGIERTER BLOCK FÜR NEUES KOTLIN ---
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            // Neue Syntax: .set(false) statt = false
            allWarningsAsErrors.set(false)
            
            // Neue Syntax: .add(...) statt = ... + ...
            freeCompilerArgs.add("-Xjvm-default=all")
        }
    }
    // -------------------------------------------
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