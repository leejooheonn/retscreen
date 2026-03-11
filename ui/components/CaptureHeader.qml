import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: headerRoot
    implicitHeight: 70
    color: "white"
    
    // Bottom border for a clean separation
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

        // --- LEFT SECTION: Branding ---
        Rectangle {
            width: 45; height: 45; radius: 10
            border.color: '#5695e7'
            border.width: 1
            Image {
                id: logoImage
                source: "../../assets/logo_v2.png"
                anchors.centerIn: parent
                
                width: parent.width * 0.8
                height: parent.height
                fillMode: Image.PreserveAspectFit
                
                // makes the edges look smooth on high-res screens
                mipmap: true 
            }
        }

        Column {
            spacing: -2
            Text {
                text: "ROP Screening"
                font.pixelSize: 22; font.bold: true; color: "#0070c0"
            }
            Text {
                text: "Retinopathy of Prematurity Detection"
                font.pixelSize: 12; color: "#7f8c8d"
            }
        }

        Item { Layout.fillWidth: true }

        // --- RIGHT SECTION: Language Toggle ---
        Rectangle {
            width: 160; height: 36; radius: 18
            color: "#f8f9fa"
            border.color: "#e0e0e0"

            Row {
                anchors.fill: parent
                anchors.margins: 2

                // English Button
                Rectangle {
                    width: parent.width / 2; height: parent.height
                    radius: 16
                    color: currentLang === "EN" ? "#1a73e8" : "transparent"
                    Text {
                        text: "English"
                        anchors.centerIn: parent
                        color: currentLang === "EN" ? "white" : "#5f6368"
                        font.bold: currentLang === "EN"
                    }
                    MouseArea { anchors.fill: parent; onClicked: currentLang = "EN" }
                }

                // Kiswahili Button
                Rectangle {
                    width: parent.width / 2; height: parent.height
                    radius: 16
                    color: currentLang === "SW" ? "#1a73e8" : "transparent"
                    Text {
                        text: "Kiswahili"
                        anchors.centerIn: parent
                        color: currentLang === "SW" ? "white" : "#5f6368"
                        font.bold: currentLang === "SW"
                    }
                    MouseArea { anchors.fill: parent; onClicked: currentLang = "SW" }
                }
            }
        }
    }
    
    // Add this property to your CapturePage or Header
    property string currentLang: "EN"
}