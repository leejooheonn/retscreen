import QtQuick
import QtQuick.Controls
import "Strings.js" as Tr

ApplicationWindow {
    id: window
    visible: true
    width: 800; height: 480
    title: "ROP screening"

    property string currentLang: "EN" // default language
    property var globalCamera: cameraManager

    CapturePage {
        anchors.fill: parent
    }
}
