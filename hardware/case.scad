// Taplock card-tag case - parametric, printable, CERN-OHL-S-2.0
// Adjust the dimensions below to fit your tag, then export as STL.

tag_width  = 54;    // credit-card width
tag_height = 86;    // credit-card height
clearance  = 0.6;   // side clearance in mm
wall       = 1.6;   // wall thickness
floor      = 1.2;   // bottom thickness
lip        = 3.0;   // how far the wall overlaps the tag
corner_r   = 5.0;   // outer corner radius
keyring    = true;  // add a keyring hole

outer_w = tag_width  + 2 * (clearance + wall);
outer_h = tag_height + 2 * (clearance + wall) + (keyring ? 10 : 0);
inner_w = tag_width  + 2 * clearance;
inner_h = tag_height + 2 * clearance;

$fn = 48;

module rounded_box(w, h, height, r) {
    hull() {
        for (x = [-w/2 + r, w/2 - r], y = [-h/2 + r, h/2 - r]) {
            translate([x, y, 0]) cylinder(r = r, h = height);
        }
    }
}

module shell() {
    difference() {
        rounded_box(outer_w, outer_h, floor + lip, corner_r);

        // Cavity open at the top; the remaining rim forms a retaining lip.
        translate([0, -((keyring ? 10 : 0) / 2), floor])
            rounded_box(inner_w, inner_h, lip + 2, max(corner_r - wall, 1));

        if (keyring) {
            translate([0, outer_h/2 - 7, -1])
                cylinder(r = 2.5, h = floor + lip + 2);
        }
    }
}

shell();
