# Tag specification

## Required NDEF content

Exactly one NDEF record:

```
TNF   = 0x01 (well-known)
TYPE  = "U"  (URI)
PAYLOAD = <URI prefix byte><UTF-8 URL>
```

The URL format is defined in [`../docs/NFC_PROTOCOL.md`](../docs/NFC_PROTOCOL.md).
Generate it with `buildTagUrl()` rather than typing it by hand.

Example payload URL:

```
https://taplock.example/t?v=1&i=desk_tag_01&a=toggle
```

## Writing with a phone

1. Install an NDEF writer app (NFC Tools, NFC TagWriter by NXP, etc.).
2. Choose **Write → Add record → URL**.
3. Paste the URL including `https://`.
4. Write to the tag and verify by reading it back.
5. In Taplock, bind the `i` value to a mode.

## Writing with a desktop USB writer

Tools such as `nfc-tools` / `libnfc` can write a URI record directly:

```bash
nfc-tagwriter --uri 'https://taplock.example/t?v=1&i=desk_tag_01&a=toggle'
```

Exact flags vary by tool version — verify the written record regardless.

## Layout recommendations

- Put the token ID on a label on the case, so a lost tag can be re-bound easily.
- Use different case colours per mode.
- Keep metal away from the antenna area; a metal desk surface can detune a
  sticker tag. A 2–3 mm printed spacer is usually enough.

## Durability test

Before releasing a case design:

1. Write the tag.
2. Tap 50 times from different phone orientations.
3. Drop the assembled token from 1 m onto a hard floor, 10 times.
4. Tap 20 more times.

If reads become unreliable, increase `clearance` and move the tag away from
the case wall.
