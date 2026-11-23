.pragma library

// Icon boxes and separator centre lines measured in the three Figma profiles.
var profiles = {
    56: {
        width: 384,
        icons: [[11, 8, 40], [76, 8, 40], [128, 10, 36], [176, 10, 36],
                [225, 10, 36], [272, 10, 36], [336, 8, 36]],
        dividers: [64, 320],
        tint: "#4d7599db",
        outline: "transparent",
        shadow: "#26000000",
        divider: "divider-compact.svg"
    },
    64: {
        width: 424,
        icons: [[18, 12, 40], [90, 12, 40], [146, 14, 36], [198, 14, 36],
                [250, 14, 36], [302, 14, 36], [370, 14, 36]],
        dividers: [74, 354],
        tint: "#806e7656",
        outline: "#939393",
        shadow: "#40000000",
        divider: "divider.svg"
    },
    80: {
        width: 500,
        icons: [[18, 16, 48], [98, 16, 48], [162, 16, 48], [226, 16, 48],
                [290, 16, 48], [354, 16, 48], [434, 16, 48]],
        dividers: [82, 418],
        tint: "#806e7656",
        outline: "#939393",
        shadow: "#40000000",
        divider: "divider.svg"
    }
};

var dragMinimum = 64;
var dragMaximum = 80;

function supportsHeight(height) {
    return height === 56 || (height >= dragMinimum && height <= dragMaximum);
}

function atHeight(height) {
    if (profiles[height])
        return profiles[height];

    const standard = profiles[dragMinimum];
    const large = profiles[dragMaximum];
    const progress = (height - dragMinimum) / (dragMaximum - dragMinimum);
    const interpolate = (start, end) => start + (end - start) * progress;
    return Object.assign({}, standard, {
        width: interpolate(standard.width, large.width),
        icons: standard.icons.map((box, index) =>
            box.map((value, coordinate) => interpolate(value, large.icons[index][coordinate]))),
        dividers: standard.dividers.map((value, index) => interpolate(value, large.dividers[index]))
    });
}
