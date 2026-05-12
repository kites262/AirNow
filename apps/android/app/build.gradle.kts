plugins {
  id("com.android.application")
  id("org.jetbrains.kotlin.android")
}

val localProperties = java.util.Properties().apply {
  val file = rootProject.file("local.properties")
  if (file.exists()) load(file.inputStream())
}
val appPackage: String = localProperties.getProperty("APP_PACKAGE", "com.example.airnow")
val appDomain: String = localProperties.getProperty("APP_DOMAIN", "https://example.com")

android {
  namespace = appPackage
  compileSdk = 34

  defaultConfig {
    applicationId = appPackage
    minSdk = 24
    targetSdk = 34
    versionCode = 1
    versionName = "1.0.0"
    buildConfigField("String", "WEB_URL", "\"$appDomain\"")
    buildConfigField("String", "APP_PACKAGE", "\"$appPackage\"")
  }

  buildFeatures {
    buildConfig = true
  }

  buildTypes {
    release {
      isMinifyEnabled = true
      isShrinkResources = true
      proguardFiles(
        getDefaultProguardFile("proguard-android-optimize.txt"),
        "proguard-rules.pro",
      )
    }
    debug {
      isMinifyEnabled = false
    }
  }

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }

  kotlinOptions {
    jvmTarget = "17"
  }
}

dependencies {
  implementation("androidx.core:core-ktx:1.12.0")
  implementation("androidx.appcompat:appcompat:1.6.1")
  implementation("androidx.webkit:webkit:1.10.0")
}
