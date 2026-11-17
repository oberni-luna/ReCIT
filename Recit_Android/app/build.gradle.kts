plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.ksp)
    alias(libs.plugins.room)
}

android {
    namespace = "studio.lunabee.nouveaurecit"
    compileSdk = 37

    defaultConfig {
        // The end-to-end scenario's seams (`e2e/E2EHooks`): off unless a build type the scenario plays turns them on.
        buildConfigField("boolean", "E2E_SEAMS", "false")
        applicationId = "studio.lunabee.exlibris.android"
        minSdk = 28
        targetSdk = 37
        versionCode = 7
        versionName = "1.4.1"
    }

    // The upload key lives outside the repository: its path and passwords are read from
    // ~/.gradle/gradle.properties. Without them the release bundle comes out unsigned.
    val uploadStoreFile: String? = providers.gradleProperty("EXLIBRIS_UPLOAD_STORE_FILE").orNull
    signingConfigs {
        if (uploadStoreFile != null) {
            create("upload") {
                storeFile = file(uploadStoreFile)
                storePassword = providers.gradleProperty("EXLIBRIS_UPLOAD_STORE_PASSWORD").get()
                keyAlias = providers.gradleProperty("EXLIBRIS_UPLOAD_KEY_ALIAS").get()
                keyPassword = providers.gradleProperty("EXLIBRIS_UPLOAD_KEY_PASSWORD").get()
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".dev"
            buildConfigField("String", "SESSION_STORE_NAME", "\"asso.recits.auth.cookies.dev\"")
            buildConfigField("boolean", "E2E_SEAMS", "true")
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = signingConfigs.findByName("upload")
            buildConfigField("String", "SESSION_STORE_NAME", "\"asso.recits.auth.cookies\"")
        }
        // The end-to-end scenario's build (feature 0065, `E2E_BUILD=release scripts/e2e-android.sh`): shrunk and
        // optimised by R8 like `release` — its R8 lines are kept the same as release's — so the scenario plays what
        // the Play Store ships rather than a debug build that never meets R8. It differs where the runner needs it:
        // the `.dev` package the runner targets, the debug key (no upload key on the machine that runs it), and the
        // scenario's seams.
        create("e2eRelease") {
            applicationIdSuffix = ".dev"
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("debug")
            matchingFallbacks += listOf("release")
            // The debug build's store: both builds are the same `.dev` package, so a session signed in on one survives
            // the other installed over it — what `e2eKeepSession` relies on when switching between them.
            buildConfigField("String", "SESSION_STORE_NAME", "\"asso.recits.auth.cookies.dev\"")
            buildConfigField("boolean", "E2E_SEAMS", "true")
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
    }
}

kotlin {
    jvmToolchain(17)
    compilerOptions {
        optIn.addAll(
            "androidx.compose.material3.ExperimentalMaterial3Api",
            "kotlinx.coroutines.ExperimentalCoroutinesApi",
        )
    }
}

room {
    schemaDirectory("$projectDir/schemas")
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.lifecycle.viewmodel.navigation3)
    implementation(libs.androidx.navigation3.runtime)
    implementation(libs.androidx.navigation3.ui)
    implementation(libs.androidx.room.runtime)
    implementation(libs.androidx.room.ktx)
    ksp(libs.androidx.room.compiler)
    implementation(libs.androidx.datastore.preferences)

    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.foundation)
    implementation(libs.compose.material3)
    implementation(libs.compose.material.icons.extended)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)

    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.okhttp)
    implementation(libs.coil.compose)
    implementation(libs.coil.network.okhttp)
    implementation(libs.camerax.camera2)
    implementation(libs.camerax.lifecycle)
    implementation(libs.camerax.view)
    implementation(libs.mlkit.barcode.scanning)
    implementation(libs.osmdroid.android)

    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.okhttp.mockwebserver)
}
