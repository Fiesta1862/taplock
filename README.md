# Taplock

> **An open-source, offline-first physical focus blocker.** Choose the apps that
> distract you, tap your phone to a passive NFC tag, and they stay blocked until
> you tap again. No account, no cloud, no subscription, no telemetry.

Inspired by [Brick](https://getbrick.com/products/grey-brick), rebuilt as an
open protocol and open hardware project so anyone can use it, audit it, or make
their own tag for a couple of dollars.

---

## Status

This is an **early scaffold**. What works today:

- ✅ NFC tag URL codec with strict validation and tests
- ✅ Mode / token / session models with JSON export
- ✅ `BlockStrategy` interface and a strategy registry
- ✅ Controller that turns a tag tap into a focus session
- ✅ Demo Flutter UI with a "simulate tap" button
- ✅ Method-channel bridges for CoreNFC / Android NDEF intents

What is intentionally **not** implemented yet:

- 🚧 Real OS enforcement (Shizuku, DevicePolicyManager, Family Controls) — the
  native files are clearly marked stubs that report themselves unavailable
- 🚧 Persistent local storage (the demo uses an in-memory repository)
- 🚧 Schedules, statistics screens, widgets, localisation

The app will never claim a block happened when it did not. That is enforced by
the `BlockStrategy.capabilities` contract and by the stubs returning
`applied = false`.

---

## Download

A prebuilt **Android APK** is attached to the
[v0.1.0 release](https://github.com/Fiesta1862/taplock/releases/tag/v0.1.0):

[`taplock-0.1.0.apk`](https://github.com/Fiesta1862/taplock/releases/download/v0.1.0/taplock-0.1.0.apk)
(46 MB, supports arm64 / armv7 / x86_64)

This is a demo build of the scaffold: the UI, NFC protocol and session logic
work, but OS-level app blocking is not implemented yet. See the
[release notes](https://github.com/Fiesta1862/taplock/releases/tag/v0.1.0)
for the full status and SHA-256 checksum.

A vector [UI preview](docs/app-preview.svg) shows the current screen layout.

---

## Repository layout

```
taplock/
├── app/                  Flutter app (shared Dart core + platform channels)
│   ├── lib/core/         Pure Dart: protocol, models, repository contract
│   ├── lib/blocks/       BlockStrategy interface, registry, implementations
│   ├── lib/services/     NFC bridge + tap-to-session controller
│   ├── lib/ui/           Demo interface
│   └── test/             Unit tests (no device required)
├── platform_overlays/    Native files to copy into a generated Flutter project
│   ├── android/          Manifest, NDEF intents, Kotlin channel stubs
│   └── ios/              AppDelegate, entitlements, Info.plist keys
├── hardware/             Tag spec, printable case, BOM
├── docs/                 Protocol, threat model, platform setup, roadmap
└── .github/              CI and contribution templates
```

**Design rule:** all decision logic lives in pure Dart under `lib/core` and
`lib/services`. Platform code only provides capabilities and reports results.
This keeps 90% of the code testable on a plain VM.

---

## Quick start

You need the Flutter SDK (3.19+ / Dart 3.3+). This repository does not commit
generated `android/` and `ios/` projects; generate them once, then overlay our
native files:

```bash
# 1. Generate pristine platform folders outside the repo
flutter create --org app.taplock --project-name taplock \
  --platforms=android,ios /tmp/taplock_platforms

# 2. Copy them into the app
cp -R /tmp/taplock_platforms/android app/
cp -R /tmp/taplock_platforms/ios app/

# 3. Overlay Taplock's native code
cp -R platform_overlays/android/. app/android/
cp -R platform_overlays/ios/. app/ios/

# 4. Merge ios/Info.plist.snippet into app/ios/Runner/Info.plist,
#    then set the CODE_SIGN_ENTITLEMENTS build setting to Runner.entitlements

# 5. Run the tests and the app
cd app
flutter pub get
flutter test
flutter run
```

On desktop, the demo UI still works: use **Simulate tag tap** instead of a real
tag. `NoopBlockStrategy` makes it explicit that nothing is being enforced.

### Before shipping

Replace every `taplock.example` placeholder with a domain you control:

- `app/lib/core/nfc_payload.dart` → `defaultTagHost`
- `platform_overlays/android/.../AndroidManifest.xml` → NDEF intent host
- `platform_overlays/ios/.../AppDelegate.swift` → universal-link host check
- `platform_overlays/ios/.../Runner.entitlements` → `applinks:` domain
- `docs/` and `hardware/` tag-writing instructions

---

## Blocking tiers — what is actually enforceable

| Tier | Android | iOS | User setup |
|---|---|---|---|
| **Strong** | Device owner (`setPackagesSuspended`) | Family Controls / ManagedSettings | ADB/QR provisioning or Apple entitlement approval |
| **Practical** | Shizuku (`pm suspend`, no root) | Focus-mode Shortcut fallback | One-time permission grant |
| **Friction** | Accessibility overlay warning | Notification reminder | None; bypassable by design |

See [docs/THREAT_MODEL.md](docs/THREAT_MODEL.md) for the honest list of bypasses,
and [docs/PLATFORM_SETUP.md](docs/PLATFORM_SETUP.md) for implementation notes.

Apple's `com.apple.developer.family-controls` entitlement is application-only
and not guaranteed. Design for graceful degradation; that is why the strategy
interface exists.

---

## The physical token

Any passive **NTAG213 / NTAG215 / NTAG216** tag works. The tag stores a single
NDEF URI record:

```
https://taplock.example/t?v=1&i=desk_tag_01&a=toggle
```

A URI record is required because iOS only scans tags in the background when
the payload is an associated-domain universal link. Full spec:
[docs/NFC_PROTOCOL.md](docs/NFC_PROTOCOL.md).

The token ID is a bearer identifier, not a secret. Anyone who can read the tag
can clone it — which is fine, because the app is the thing being protected and
the physical friction is the point. Do not put secrets in tags.

Cases and BOM: [hardware/README.md](hardware/README.md).

---

## Contributing

This project is meant to be contributed to, not just installed. Good first
contributions:

- Implement one of the stubbed blocking strategies
- Add a persistent `ModesRepository` (Drift/Isar) and tests
- Add schedules and local statistics
- Improve accessibility (screen-reader labels, dynamic type, high contrast)
- Translate the UI
- Add a printable case for another tag form factor

Read [CONTRIBUTING.md](CONTRIBUTING.md) and the issue templates first.

---

## Licences

| Part | Licence |
|---|---|
| App code (`app/`, `platform_overlays/`) | GPL-3.0-or-later — see [LICENSE](LICENSE) |
| Hardware (`hardware/`) | CERN-OHL-S-2.0 — see [LICENSES/HARDWARE.txt](LICENSES/HARDWARE.txt) |
| Docs (`docs/`, root Markdown) | CC-BY-SA-4.0 — see [LICENSES/DOCS.txt](LICENSES/DOCS.txt) |

Taplock is an independent project and is not affiliated with Brick LLC.
