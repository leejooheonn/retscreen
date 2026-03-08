import QtQuick
import QtQuick.Controls
import QtMultimedia
import QtQuick.Layouts

Item {
    id: captureRoot

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // header
        Rectangle {
            Layout.fillWidth: true
            color: "#f8f9fa"
            Layout.preferredHeight: 50

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20

                Text {
                    text: "ROP Screening"
                    font.pixelSize: 20
                    color: "#2c3e50"
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Row {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter
                    Rectangle {
                        width: 12; height: 12; radius: 6
                        color: "#27ae60"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text { text: "Live"; font.bold: true; color: "#27ae60"}
                }
            }
        }

        // live camera feed
        Rectangle {
            color: "#222"
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // capture button
        Rectangle {
            Layout.fillWidth: true
            color: "#eeeeee"
            Layout.preferredHeight: 80
        }
        /* VideoOutput {
            id: cameraFeed
            objectName: "cameraFeed"
            anchors.fill: parent
            // fillMode: VideoOutput.PreserveAspectCrop if we want to maintain the circular eye shape
        }

        Button {
            text: "Capture Image"
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: 40

            onClicked: console.log("Image captured!")   
        } */
    }
}
