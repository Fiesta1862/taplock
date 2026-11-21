# Hardware

The physical part of Taplock is deliberately boring: a passive NFC tag in a
case. No battery, no PCB, no firmware, no pairing.

## Bill of materials (per token)

| Item | Example | Approx. cost |
|---|---|---|
| NFC tag | NTAG213 sticker (25 mm disc or 85 × 54 mm card) | $0.10–$0.50 |
| Case | 3D-printed PLA, ~15 g | $0.30–$1.00 |
| Optional | adhesive backing, keyring loop | $0.10 |

Total: roughly **$1 per token**, versus a manufactured plastic device. You can
also skip the case entirely and use a sticker on your desk.

## Why NTAG213/215/216

- Passive and battery-free — always ready
- 144 / 540 / 888 bytes, far more than our ~70-byte URL
- Supported by every modern phone with NFC
- Cheap, widely available, readable by any NFC writing app

## Files

- [`tag_spec.md`](tag_spec.md) — NDEF contents and writing instructions
- [`case.scad`](case.scad) — parametric OpenSCAD case for a card-sized tag
- [`kicad/`](kicad/README.md) — optional custom PCB path (later)

## Printing the case

1. Open `case.scad` in OpenSCAD (or use the popular online renderer).
2. Adjust `tag_width`, `tag_height` and `clearance` for your tag.
3. Export as STL and print in PLA at 0.2 mm layers, 20% infill, no supports.
4. Slide the tag in; the lip holds it flush. A dab of glue is optional.
5. Write the URL **before** assembling the case.

The case is licensed under CERN-OHL-S-2.0. If you publish a remix, keep the
source files and the same licence.

## Design goals

- A tag should survive being tossed in a bag
- Anyone with a $5 3D print or a sticker can participate
- No proprietary cartridge, no cloud activation, no battery to charge
- Different tags can be visually distinguished (colour, shape, label)
