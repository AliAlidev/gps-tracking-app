# Building APK for Android

This guide explains how to build an APK file for the GPS Tracking App.

## Prerequisites

1. **Flutter SDK** installed and configured
2. **Android Studio** or Android SDK installed
3. **Java JDK** (version 8 or higher)

## Quick Build Commands

### Debug APK (for testing)

```bash
cd mobile
flutter build apk --debug
```

The APK will be generated at:
`mobile/build/app/outputs/flutter-apk/app-debug.apk`

### Release APK (for distribution)

```bash
cd mobile
flutter build apk --release
```

The APK will be generated at:
`mobile/build/app/outputs/flutter-apk/app-release.apk`

### Split APKs by ABI (smaller file size)

```bash
cd mobile
flutter build apk --split-per-abi
```

This creates separate APKs for:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (x86_64)

## Step-by-Step Instructions

### 1. Navigate to Mobile Directory

```bash
cd mobile
```

### 2. Get Dependencies

```bash
flutter pub get
```

### 3. Check Flutter Setup

```bash
flutter doctor
```

Make sure Android toolchain is properly configured.

### 4. Build Release APK

```bash
flutter build apk --release
```

### 5. Find Your APK

After building, the APK will be located at:
```
mobile/build/app/outputs/flutter-apk/app-release.apk
```

## Signing the APK (For Production)

For production releases, you should sign your APK with a keystore.

### 1. Create a Keystore

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2. Create key.properties file

Create `mobile/android/key.properties`:

```properties
storePassword=<password from previous step>
keyPassword=<password from previous step>
keyAlias=upload
storeFile=<location of the key store file>
```

### 3. Update build.gradle

Update `mobile/android/app/build.gradle` to include signing config:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 4. Build Signed APK

```bash
flutter build apk --release
```

## App Bundle (For Google Play Store)

If you're publishing to Google Play Store, use App Bundle instead:

```bash
flutter build appbundle --release
```

This creates:
`mobile/build/app/outputs/bundle/release/app-release.aab`

## Troubleshooting

### Error: "Gradle build failed"

1. Check if Android SDK is properly installed
2. Run `flutter clean` and try again
3. Check `mobile/android/local.properties` has correct SDK path

### Error: "SDK location not found"

Create `mobile/android/local.properties`:

```properties
sdk.dir=/path/to/your/android/sdk
```

### Error: "Minimum supported Gradle version"

Update Gradle version in `mobile/android/gradle/wrapper/gradle-wrapper.properties`

### Build Size Too Large

Use split APKs:
```bash
flutter build apk --split-per-abi --release
```

Or enable ProGuard/R8:
- Already enabled by default in release builds
- Check `mobile/android/app/build.gradle` for minifyEnabled

## Installing the APK

### Via ADB (Android Debug Bridge)

```bash
adb install mobile/build/app/outputs/flutter-apk/app-release.apk
```

### Via File Transfer

1. Copy APK to your Android device
2. Enable "Install from Unknown Sources" in device settings
3. Open the APK file on your device
4. Follow installation prompts

## Build Variants

### Debug Build
- Includes debugging symbols
- Larger file size
- Not optimized
- Command: `flutter build apk --debug`

### Profile Build
- Optimized for performance profiling
- Command: `flutter build apk --profile`

### Release Build
- Optimized and minified
- Smaller file size
- Production-ready
- Command: `flutter build apk --release`

## Additional Options

### Build with specific flavor

```bash
flutter build apk --release --flavor production
```

### Build with specific target file

```bash
flutter build apk --release --target lib/main.dart
```

### Build with obfuscation (extra security)

```bash
flutter build apk --release --obfuscate --split-debug-info=./debug-info
```

## File Sizes

Typical APK sizes:
- Debug: ~50-80 MB
- Release: ~20-40 MB
- Split per ABI: ~10-20 MB each

## Notes

- First build takes longer (downloads dependencies)
- Subsequent builds are faster
- Release builds are optimized and smaller
- Always test release builds before distribution
- Keep your keystore file secure and backed up

