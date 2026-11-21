# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
Semantic Versioning.

## [0.1.0] - 2026-11-21

### Added

- NFC tag protocol v1: strict, tested URL codec for NDEF URI records
- Data models for modes, token bindings and focus sessions, with JSON export
- `BlockStrategy` interface, registry and honest capability model
- `FocusController` implementing tap → session → tap → saved session
- Flutter demo UI with token binding, strategy selection and tap simulation
- Native platform overlays for Android NDEF intents and iOS CoreNFC /
  universal links
- Open-hardware tag specification and parametric printable case
- Threat model, platform setup guide, roadmap and contribution templates
- GPL-3.0 / CERN-OHL-S-2.0 / CC-BY-SA-4.0 licences and CI workflow

### Notes

- OS enforcement strategies (Shizuku, Device Owner, Family Controls) are
  scaffolded stubs that report themselves unavailable. No release claims
  enforcement that is not implemented.
- `taplock.example` is a placeholder domain and must be replaced before
  shipping.

[0.1.0]: https://github.com/Fiesta1862/taplock/releases/tag/v0.1.0
