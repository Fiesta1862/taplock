# Contributing to Taplock

Thanks for helping make a genuinely useful focus tool. A few rules keep the
project trustworthy.

## Ground rules

- **Never claim enforcement that did not happen.** A strategy that only warns
  must declare `StrategyCapability.notify`. Update
  [`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md) when you add a strategy.
- **No analytics, no account, no cloud by default.** Any PR adding network
  access needs an explicit discussion first.
- **Decision logic goes in pure Dart.** Platform code reports capabilities and
  results; it does not make product decisions.
- **Every behaviour change needs a test.** `flutter test` must pass.

## Setup

See the Quick start section in [`README.md`](README.md). In short: generate the
platform folders with `flutter create`, copy the overlays, then:

```bash
cd app
flutter pub get
flutter analyze
flutter test
```

Use `flutter format .` before committing.

## Adding a blocking strategy

1. Create `app/lib/blocks/strategies/<name>_block_strategy.dart`.
2. Either extend `PlatformChannelStrategy` (for a native implementation) or
   implement `BlockStrategy` directly (for a pure-Dart/demo strategy).
3. Declare honest `capabilities` and a clear `description`.
4. Register it in `app/lib/app.dart`.
5. Add the native side under `platform_overlays/` following the existing
   MethodChannel contract (`isAvailable`, `currentState`, `apply`, `release`).
6. Document setup requirements and bypasses in `docs/PLATFORM_SETUP.md` and
   `docs/THREAT_MODEL.md`.
7. Add unit tests with a fake platform channel or a fake strategy.

The `NoopBlockStrategy` is the reference implementation to read first.

## Adding a mode, schedule or statistics feature

Extend the models in `app/lib/core/models.dart`, update the repository contract,
add JSON round-trip tests, and keep the UI in `app/lib/ui/` thin. Prefer adding
a field to the existing snapshot schema with a default over breaking exports.

## Commits and pull requests

- Use short imperative commit messages: `Add Shizuku availability check`.
- One logical change per PR.
- Link the issue you are addressing.
- Include screenshots for UI changes and test output for logic changes.
- Update the README/docs when behaviour or setup changes.

## Licensing

By contributing you agree that your code is licensed under GPL-3.0-or-later,
hardware files under CERN-OHL-S-2.0, and documentation under CC-BY-SA-4.0.
Do not paste third-party code without a compatible licence and attribution.

## Good first issues

Look for the `good first issue` label. Good candidates right now:

- Persistent repository implementation
- Schedule model and tests
- Accessibility labels in the demo UI
- A printable case for a 25 mm round sticker
- Translations
