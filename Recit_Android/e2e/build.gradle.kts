plugins {
    alias(libs.plugins.android.test)
}

/**
 * The end-to-end scenario (feature 0065): UI Automator driving the debug — or R8-minified `e2eRelease` — app on an emulator, against
 * the real inventaire.io. A separate, self-instrumenting module rather than `app/src/androidTest`,
 * because a test running inside the app's process dies with it — and the scenario has to kill the
 * app and start it again to check the session survives.
 *
 * Run it through `scripts/e2e-android.sh`, which hands over the credentials and renders the report.
 */
android {
    namespace = "studio.lunabee.nouveaurecit.e2e"
    compileSdk = 37

    defaultConfig {
        minSdk = 28
        targetSdk = 37
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    // `e2eRelease` plays the scenario on the app's R8-minified `e2eRelease` variant, matched by build type name;
    // the runner itself stays a plain, debug-signed test APK.
    buildTypes {
        create("e2eRelease") {
            initWith(getByName("debug"))
            matchingFallbacks += listOf("debug")
        }
    }

    targetProjectPath = ":app"
    experimentalProperties["android.experimental.self-instrumenting"] = true

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    implementation(libs.androidx.test.runner)
    implementation(libs.androidx.test.ext.junit)
    implementation(libs.androidx.test.uiautomator)
    implementation(libs.junit)
}
