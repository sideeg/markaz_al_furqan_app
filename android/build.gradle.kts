allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// تعديل مسار البناء (Build Directory)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // تعيين مسار بناء فرعي لكل مشروع
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // هذا السطر مهم جداً لضمان ترتيب التقييم
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
plugins {
    // ...
    id("com.google.gms.google-services") version "4.4.4" apply false
}