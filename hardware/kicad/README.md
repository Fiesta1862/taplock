# Custom PCB (optional, later)

You do **not** need a PCB. Off-the-shelf NTAG inlays are cheaper and more
reliable than a first attempt at tuned antenna design.

Only consider a custom board if you want a specific shape, integrated mounting
holes, or a printed graphic. Then:

1. Pick a tag IC with an established reference design (NTAG213/216).
2. Copy the manufacturer's antenna matching network exactly.
3. Keep metal and ground planes out of the antenna area.
4. Order with a 0.8–1.6 mm FR4 board and no heavy copper in the loop region.
5. Verify read distance against a phone before committing to a case design.

Licence for any PCB sources added here: CERN-OHL-S-2.0 (see
`../../LICENSES/HARDWARE.txt`). Include the schematic, board file, BOM and
gerbers — a gerber-only release is not open hardware.

Status: no board files yet. Contributions welcome once the v0.2 app is stable.
