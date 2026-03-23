import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Strings.js" as Tr

Rectangle {
    id: headerRoot
    implicitHeight: 70
    color: "white"

    // bottom border for a clean separation
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: "#eeeeee"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 15

        // logo 
        Rectangle {
            width: 45; height: 45; radius: 10
            border.color: '#5695e7'
            border.width: 1
            Image {
                source: "../../assets/logo_v2.png"
                anchors.centerIn: parent
                
                width: parent.width * 0.8
                height: parent.height
                fillMode: Image.PreserveAspectFit
                
                // makes the edges look smooth on high-res screens
                mipmap: true 
            }
        }

        // app title and subtitle
        Column {
            spacing: -2
            Text {
                text: Tr.get("appTitle", window.currentLang)
                font.pixelSize: 22; font.bold: true; color: "#0070c0"
            }
            Text {
                // change text to smth more descriptive
                text: Tr.get("appSubtitle", window.currentLang)
                font.pixelSize: 12; color: "#7f8c8d"
            }
        }

        Item { Layout.fillWidth: true }

        // language toggle
        Rectangle {
            width: 160; height: 36; radius: 18
            color: "#f8f9fa"
            border.color: "#e0e0e0"

            Row {
                anchors.fill: parent
                anchors.margins: 2

                LangButton { 
                    langCode: "EN"
                    displayName: "English"
                }
                LangButton { 
                    langCode: "SW"
                    displayName: "Swahili"
                }
            }
        }
    }
}