import QtQuick 2.15
import QtQuick.Layouts 1.15

// This creates a reusable row for the patient data grid
RowLayout {
    property string label: ""
    property string value: ""
    property color valueColor: "#2c3e50"
    
    Layout.fillWidth: true
    spacing: 10

    Text {
        text: label + ":"
        color: "#7f8c8d"
        font.pixelSize: 13
        Layout.preferredWidth: 100 // Keeps the labels aligned
    }

    Text {
        text: value
        color: valueColor
        font.bold: true
        font.pixelSize: 15
        Layout.fillWidth: true
        elide: Text.ElideRight // Prevents long names from breaking the layout
    }
}