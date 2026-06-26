# QuickPlate Release & Over-the-Air (OTA) Patch Guide

This guide documents the procedures for signing, building, releasing, and patching the **QuickPlate** Android application using **Shorebird** and **GitHub Actions**.

---

## 1. Local Android Release Signing (Local Builds)

By default, the Gradle configuration signs release builds using debug credentials unless a `key.properties` file is found. To sign builds for production locally:

1. **Generate a Keystore file**:
   ```bash
   keytool -genkeypair -v -keystore android/app/upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
   ```
2. **Create `android/key.properties`**:
   Create a file at `android/key.properties` (which is already git-ignored) and add:
   ```properties
   storePassword=<keystore-password-you-set>
   keyPassword=<alias-password-you-set>
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```
3. **Build the Release locally**:
   ```bash
   flutter build apk --release
   # or with fvm:
   fvm flutter build apk --release
   ```

---

## 2. GitHub Actions Secrets Configuration

To run automated builds and Shorebird OTA updates via GitHub CI/CD, configure the following secrets under **Settings > Secrets and variables > Actions** in your GitHub repository:

| Secret Name | Description | Value Example / How to obtain |
| :--- | :--- | :--- |
| `ANDROID_KEYSTORE_BASE64` | Base64 encoded `.jks` file | Run `cat android/app/upload-keystore.jks | base64 -w 0` |
| `KEYSTORE_PASSWORD` | Keystore password | The password chosen during `keytool` generation |
| `KEY_PASSWORD` | Key/Alias password | The password chosen during `keytool` generation |
| `KEY_ALIAS` | Key alias name | `upload` |
| `SHOREBIRD_TOKEN` | CI login token for Shorebird | Run `shorebird login:ci` locally to generate |

---

## 3. Deployment & Update Workflows

### Scenario A: New Release (GitHub Release & Google Play Store)
When introducing native code changes (e.g., modifying Gradle configuration, adding new plugins, changing Android/iOS configurations):

1. **Tag the commit** you want to release with a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. **GitHub Action: Release Build** will trigger automatically, build a signed APK and AAB (App Bundle), and attach them to a new GitHub Release.
3. Download the AAB from the GitHub Release and upload it to the **Google Play Console**.

---

### Scenario B: Publish Shorebird Base Release (First OTA Anchor)
For Shorebird to distribute updates, you must first build and publish a "base release" containing the native bundle that matches what is installed on users' devices:

1. Go to the **Actions** tab on your GitHub repository.
2. Select **Shorebird Release** from the list of workflows.
3. Click **Run workflow** (select the branch you want to build).
4. This will build a signed release and register it with the Shorebird console.

---

### Scenario C: Distribute a Dart-only Hotfix (OTA Patch)
If you only changed Dart/Flutter code (no native Java/Kotlin/Swift/Gradle changes):

1. Go to the **Actions** tab on your GitHub repository.
2. Select **Shorebird Patch** from the list of workflows.
3. Click **Run workflow**.
4. The workflow builds the package, computes the Dart diff, and pushes the OTA patch to all active user devices in minutes.

---

## 4. Useful Commands

* **Run Shorebird Doctor**:
  Checks your local environment tools, Flutter version, and setup.
  ```bash
  shorebird doctor
  ```
* **Verify Shorebird Preview**:
  Preview a specific release on a connected device/emulator.
  ```bash
  shorebird preview
  ```
