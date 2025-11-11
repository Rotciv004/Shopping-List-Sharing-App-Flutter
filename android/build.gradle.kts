allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// NOTE: Removed custom buildDir relocation to avoid Gradle snapshot root mismatch
// that caused: "this and base files have different roots" for plugin tasks.
// Keeping default build directories under the android/ tree ensures all plugin
// source (in pub cache) and generated intermediates stay on consistent roots.

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
