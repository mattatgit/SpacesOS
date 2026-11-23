import QtQuick

Image {
    // Figma exports the vertical line as a horizontal 40.5 × 0.5 SVG.
    width: 40.5
    height: 0.5
    sourceSize: Qt.size(81, 1)
    fillMode: Image.Stretch
    rotation: 90
    antialiasing: true
}
