# NFC token protocol (v1)

## Design goals

1. Readable in the background on **both** iOS and Android
2. No app required to write a tag — any NFC writing app works
3. No personal data or secrets on the tag
4. Strict validation so a random NFC tag cannot trigger a block

## Wire format

The tag contains **one NDEF record**:

- TNF: `0x01` (well-known)
- Type: `U` (URI record, `RTD_URI`)
- Payload: prefix identifier byte + UTF-8 URL body

The URL is:

```
https://<host>/t?v=1&i=<tokenId>&a=<action>[&m=<modeId>][&d=<minutes>]
```

### Parameters

| Key | Required | Rules |
|---|---|---|
| `v` | yes | Protocol version. Currently `1`. |
| `i` | yes | Token ID: 6–64 chars, `[A-Za-z0-9_-]`. |
| `a` | yes | `lock`, `unlock` or `toggle`. |
| `m` | no | Mode ID. If present, overrides the mode bound to the token. |
| `d` | no | Lock duration in minutes, 1–1440. |

### Example

```
https://taplock.example/t?v=1&i=desk_tag_01&a=toggle
```

A timed lock for a 25-minute study session:

```
https://taplock.example/t?v=1&i=study_tag_1&a=lock&m=study&d=25
```

## Why a URI record instead of custom data

iOS only delivers NFC tag reads in the background when the NDEF payload is a
URI record matching an app-associated domain. A custom MIME record would
require the app to be open, which defeats the physical-tap interaction.

The trade-off: you must own a domain and publish an Apple App Site Association
file. See [PLATFORM_SETUP.md](PLATFORM_SETUP.md).

## Platform delivery paths

| Platform | Background path |
|---|---|
| iOS | Tag read → universal link → `NSUserActivityTypeBrowsingWeb` in `AppDelegate` |
| Android | Tag read → `NDEF_DISCOVERED` intent filtered on scheme + host |
| Both (foreground) | Explicit scan button → `scanOnce` method channel |

All three paths converge on `NfcService.tagUrls`, then `parseTagUrl`, then
`FocusController.handleTagUrl`. No platform code parses protocol fields.

## Validation rules enforced by the Dart codec

- scheme must be `https`
- host must match `expectedHost` when configured
- path must be `/t`
- `v` must be `1`
- `i` must match the token ID pattern
- `a` must be a known action
- `d`, if provided, must parse as an integer in 1–1440

Unparseable tags are ignored with a user-visible message; they never change
state.

## Writing a tag

Use NFC Tools, NFC TagWriter, or any NDEF writer:

1. Add a record of type **URL / URI**
2. Enter the full URL from above (including `https://`)
3. Write to an NTAG213/215/216 tag
4. Bind the same `i` value in the app (Tokens → Bind a new token)

`buildTagUrl()` in `app/lib/core/nfc_payload.dart` generates the URL so you do
not have to assemble it by hand.

## Security notes

- Token IDs are **bearer identifiers**, not credentials. Treat the tag like a
  key to a physical lock: cloning it is possible, and that is acceptable.
- Never put passwords, API tokens or personal identifiers in a tag.
- `expectedHost` should always be set in a production build so a tag pointing
  at another domain cannot be trusted.
- If a token is lost, delete its binding in the app; the tag becomes inert.
