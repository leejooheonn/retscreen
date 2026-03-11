import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    Layout.fillHeight: true
    Layout.preferredWidth: sideBarOpen ? parent.width * 0.3 : 0
    color: '#f8f9fa'
    opacity: sideBarOpen ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300 } } // check what this does

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // patient data card
        Rectangle {
            id: dataCard
            Layout.fillWidth: true
            Layout.preferredHeight: 250

            color: "#edfbff"
            border.color: '#4a98cd'
            border.width: 2
            radius: 12

            GridLayout {
                columns: 2
                anchors.fill: parent
                anchors.margins: 20
                rowSpacing: 20
                columnSpacing: 10

                Column {
                    Text { text: "Patient ID"; color: "#7f8c8d"; font.pixelSize: 12 }
                    Text { text: "ROP-DEMO-001"; color: "#0056b3"; font.bold: true; font.pixelSize: 16 }
                }
                Column {
                    Text { text: "Name"; color: "#7f8c8d"; font.pixelSize: 12 }
                    Text { text: "John Doe"; color: "#2c3e50"; font.bold: true; font.pixelSize: 16 }
                }

                Column {
                    Text { text: "Gestational Age"; color: "#7f8c8d"; font.pixelSize: 12 }
                    Text { text: "28 weeks"; color: "#2c3e50"; font.bold: true; font.pixelSize: 16 }
                }
                Column {
                    Text { text: "Birth Weight"; color: "#7f8c8d"; font.pixelSize: 12 }
                    Text { text: "1500 g"; color: "#2c3e50"; font.bold: true; font.pixelSize: 16 }
                }
                
                Column {
                    Text { text: "Screening Date"; color: "#7f8c8d"; font.pixelSize: 12 }
                    Text { text: "3/9/2026"; color: "#2c3e50"; font.bold: true; font.pixelSize: 16 }
                }
                Column {
                    Text { text: "Images Captured"; color: "#7f8c8d"; font.pixelSize: 12 }
                    Text { text: "0"; color: "#0056b3"; font.bold: true; font.pixelSize: 16 }
                }
            } 
        }
        // image gallery
        Rectangle {
            id: galleryCard
            Layout.fillWidth: true
            Layout.preferredHeight: 200

            color: "#edfbff"
            border.color: '#4a98cd'
            border.width: 2
            radius: 12

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                Text { text: "Image Gallery"; color: "#7f8c8d"; font.pixelSize: 12 }
                
                // placeholder for image thumbnails
                RowLayout {
                    spacing: 10

                    Rectangle {
                        width: 60; height: 60
                        color: "#bdc3c7"
                        radius: 4
                        Text { text: "No Images"; anchors.centerIn: parent; color: "#7f8c8d"; font.pixelSize: 10 }
                    }
                }
            }
        }
    }
}   