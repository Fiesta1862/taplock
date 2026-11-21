# Threat model

This document exists so users can judge the app honestly. A focus tool that
overstates its guarantees is worse than useless.

## What we are protecting against

The adversary is **you, in a moment of weakness**: the impulse to open a
distracting app without thinking. The goal is not to defeat a determined
attacker with root access; it is to add deliberate friction to autopilot
behaviour.

## Tiers and known bypasses

### Friction tier (accessibility overlay / notification)

**Provides:** a visible interruption when a blocked app opens.

**Bypassable by:** disabling the accessibility service, force-stopping Taplock,
dismissing the notification, using another device.

**Honest claim:** "This reminds you." Never "this blocks you."

### Practical tier — Shizuku (Android)

**Provides:** packages are suspended through the shell `pm` tool. They do not
appear in the launcher and cannot be opened normally.

**Bypassable by:** revoking Shizuku access, uninstalling Taplock after
unsuspending, rebooting if suspension is not persisted, using web versions of
the same services, using a second device.

**Requirements:** Shizuku installed and granted once. No root required.

**Notes:** the app must persist suspended package names and restore them after
boot. Without that, a reboot is a trivial bypass.

### Strong tier — Device owner (Android)

**Provides:** `DevicePolicyManager.setPackagesSuspended()` with an active device
owner. Apps cannot be unsuspended by the user through normal UI.

**Bypassable by:** factory reset, safe mode (device-owner policies may be
suspended there), sideloaded alternatives, another device.

**Requirements:** the device must be provisioned as device owner, which usually
means wiping it or using a QR/ADB provisioning flow. Not suitable for a personal
phone you want to keep.

### Strong tier — Family Controls (iOS)

**Provides:** ManagedSettings shields on selected apps/categories; schedules via
DeviceActivity. The user cannot remove shields without going through the OS
Screen Time passcode flow.

**Bypassable by:** another device, web versions, changing the Screen Time
passcode if known, deleting and reinstalling the app if Apple's rules allow a
shield to lapse.

**Requirements:** Apple entitlement approval. Until approved, the iOS app must
fall back to the friction tier and say so.

## Tag-level threats

| Threat | Mitigation |
|---|---|
| Cloned tag | Accepted by design. Possession of the tag *is* the intent signal. |
| Random NFC tag scanned | Strict URL validation and host check; unknown token IDs rejected. |
| Malicious URL in tag | `https`-only, host allowlist, no URL fetching by the app. |
| Lost tag | Delete binding in app; tag becomes inert. |

## Data and privacy

- No account, no cloud sync, no third-party SDKs, no analytics.
- App lists, schedules and session history stay on the device.
- Export is explicit and local (JSON copied to clipboard / shared by user).
- NFC tags contain only a URL with an opaque token ID.
- The app requests NFC, and optionally notification/overlay permissions. It
  does not request contacts, location, camera or microphone.

## What we explicitly do not claim

- We cannot make a stock Android or iOS device tamper-proof against its owner.
- We cannot block the web version of a service with an app block.
- We cannot prevent use of a second phone or computer.
- A "dry run" / noop strategy never enforces anything.

Contributors adding a strategy must update this file with its real bypasses.
