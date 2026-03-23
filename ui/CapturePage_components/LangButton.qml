import QtQuick

Rectangle {
    property string langCode: ""  // "EN" or "SW"
    property string displayName: ""
    
    width: parent.width / 2
    height: parent.height
    radius: 16
    color: currentLang === langCode ? "#1a73e8" : "transparent"

    Text {
        text: displayName
        anchors.centerIn: parent
        color: currentLang === langCode ? "white" : "#5f6368"
        font.bold: currentLang === langCode
    }

    MouseArea {
        anchors.fill: parent
        onClicked: currentLang = langCode, window.currentLang = langCode
    }
}