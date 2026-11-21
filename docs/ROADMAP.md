# Roadmap

## v0.1 — protocol and skeleton

- [x] NFC URL codec with validation and tests
- [x] Modes, bindings, sessions, JSON export
- [x] BlockStrategy interface and registry
- [x] Controller: tap → session → tap → save
- [x] Demo UI with simulated taps
- [x] Native channel/intent scaffolding
- [x] Threat model and platform docs
- [ ] Generate platform folders and run `flutter test` with a real SDK
- [ ] Replace `taplock.example` with a real domain

## v0.2 — real enforcement

- [ ] Shizuku strategy on Android
- [ ] Device owner strategy on Android
- [ ] Accessibility friction strategy (F-Droid build)
- [ ] Apple Family Controls entitlement request + Swift implementation
- [ ] Strategy capability badges in the UI
- [ ] Persist sessions and suspended packages across reboot

## v0.3 — daily driver

- [ ] Persistent local repository (Drift or Isar) + migration tests
- [ ] Schedules (Work / Study / Sleep auto-modes)
- [ ] Timed locks from the tag (`d` parameter)
- [ ] Local statistics with CSV/JSON export
- [ ] Home-screen widgets and quick settings tile (Android)
- [ ] Accessibility pass: dynamic type, TalkBack/VoiceOver, high contrast
- [ ] Localisation (start with 5 languages)

## v1.0 — public release

- [ ] Open hardware files verified by a print/assembly test
- [ ] F-Droid submission
- [ ] App Store / Play submission where policy allows
- [ ] Security review of the threat model
- [ ] Contributor documentation translated
