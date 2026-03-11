import QtQuick 
import QtQuick.Controls 
import QtQuick.Layouts 

Button {
    id: sideBarToggle
    Layout.alignment: Qt.AlignTop | Qt.AlignRight
    Layout.preferredWidth: 72
    Layout.preferredHeight: 33
    Layout.rightMargin: 10
    Layout.topMargin: 10
    
    onClicked: captureRoot.sideBarOpen = !captureRoot.sideBarOpen

    contentItem: Text {
        text: captureRoot.sideBarOpen ? "Hide ➡️" : "Show ⬅"
        color: "white"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.bold: true
    }

    background: Rectangle {
        color: "#2c3e50"
        opacity: 0.6 
        radius: 4
    }
}