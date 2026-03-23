import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../Strings.js" as Tr

// This creates a reusable row for the patient data grid
RowLayout {
    property string label: ""
    property string value: ""
    property color valueColor: "#2c3e50"

    Text {
        text: Tr.get(label, window.currentLang) + ":"
        color: "#7f8c8d"
        font.pixelSize: 13
        
        Layout.preferredWidth: 115
        elide: Text.ElideRight
    }

    Text {
        text: value
        color: valueColor
        font.bold: true
        font.pixelSize: 14
        
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        verticalAlignment: Text.AlignVCenter
    }
}