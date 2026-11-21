# Platform setup

This file documents the OS gates. The native code in `platform_overlays/` is
scaffolded; these are the steps to make each strategy real.

## iOS — NFC

1. In Xcode, add the **Near Field Communication Tag Reading** capability.
2. Add `NFCReaderUsageDescription` to `Info.plist` (see the overlay snippet).
3. Add `com.apple.developer.nfc.readersession.formats = [NDEF]` to
   `Runner.entitlements`.
4. Add `applinks:<your-domain>` to associated domains.
5. Publish an Apple App Site Association file at
   `https://<your-domain>/.well-known/apple-app-site-association`:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "<TEAMID>.app.taplock.taplock",
        "paths": ["/t*"]
      }
    ]
  }
}
```

6. Update the host checks in `buildTagUrl`, `AppDelegate` and the manifest.

Background tag reads arrive as a universal link (`NSUserActivityTypeBrowsingWeb`),
not as a CoreNFC delegate callback. The foreground `scanOnce` path uses
`NFCNDEFReaderSession` directly. Both are implemented in the overlay.

## iOS — Family Controls (strong tier)

1. Request `com.apple.developer.family-controls` from Apple through the
   Developer portal entitlement request form. Explain the use case clearly and
   link this repository.
2. Approval is discretionary. Until it arrives, keep
   `FamilyControls.entitlements.example` as an example and do **not** add the
   key to `Runner.entitlements` — builds will fail or APIs will crash.
3. Once approved:
   - `AuthorizationCenter.shared.requestAuthorization(for: .individual)`
   - select apps with `FamilyControlsPicker` / `MBApplicationToken`
   - shield them with `ManagedSettingsStore().shield.applications`
   - auto-schedule with a `DeviceActivityMonitor` extension
4. Add a `DeviceActivityMonitor` extension target and register it in
   `Info.plist` / the extension's `Info.plist`.

The Dart side already has `FamilyControlsBlockStrategy` on the method channel
`app.taplock/blocks/familyControls`; only the Swift implementation is pending.

## Android — NFC

The manifest overlay filters `NDEF_DISCOVERED` on `https://<host>`. No runtime
permission is needed on modern Android (NFC permission is normal, not
dangerous). `MainActivity` parses the NDEF URI record and emits the raw URL on
the `app.taplock/nfc/tags` event channel.

Test with a physical tag or an NFC emulator; the Android emulator's NFC support
is limited.

## Android — Shizuku (practical tier)

1. Add to `android/app/build.gradle`:

```gradle
dependencies {
    implementation "dev.rikka.shizuku:api:13.1.5"
    implementation "dev.rikka.shizuku:provider:13.1.5"
}
```

2. Add the Shizuku provider to the manifest and implement the checks in
   `ShizukuBlockStrategy.kt`:

```kotlin
if (Shizuku.checkSelfPermission() != PackageManager.PERMISSION_GRANTED) {
    Shizuku.requestPermission(1001)
}
val session = Shizuku.newProcess(
    arrayOf("pm", "suspend", *bundleIds.toTypedArray()), null, null
)
val exit = session.waitFor()
```

3. Use `pm list packages -d` to verify what is actually suspended.
4. Persist the suspended list locally and restore it on `BOOT_COMPLETED`,
   otherwise a reboot becomes a trivial bypass.
5. Release with `pm unsuspend <pkg>`.

Shizuku uses ADB or root under the hood but does not require the app to be
rooted. The user grants access once through wireless debugging.

## Android — Device owner (strong tier)

Provision a *dedicated* device (this wipes it):

```bash
adb shell dpm set-device-owner app.taplock.taplock/.OwnerReceiver
```

Then implement `DeviceOwnerBlockStrategy.kt`:

```kotlin
val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE)
        as DevicePolicyManager
val admin = ComponentName(context, OwnerReceiver::class.java)

dpm.isDeviceOwnerApp(context.packageName)          // availability check
dpm.setPackagesSuspended(admin, bundleIds, true)   // block
dpm.setPackagesSuspended(admin, bundleIds, false)  // release
```

Add an `OwnerReceiver : DeviceAdminReceiver` and its manifest registration.

## Android — accessibility tier (friction only)

An `AccessibilityService` can watch `TYPE_WINDOW_STATE_CHANGED` and launch a
blocking activity when a blocked package comes forward. It cannot reliably
prevent the app from opening, and Google's Play policy restricts using the
accessibility API for non-accessibility purposes.

Consequences:

- Fine for F-Droid / self-built APKs, with clear disclosure
- Likely rejection on Google Play if presented as a blocking feature
- Always declare `StrategyCapability.notify`, never `enforce`

## Distribution notes

- **F-Droid** is a natural fit: no proprietary SDKs, reproducible builds,
  GPL-3.0 code. Include metadata in a separate `fdroiddata` submission.
- **Google Play** may object to app-suspension behaviour; be explicit in the
  store listing about device owner / Shizuku requirements.
- **iOS** requires the entitlement for anything beyond reminders. A
  TestFlight-only build is a reasonable way to validate the UX while approval
  is pending.
