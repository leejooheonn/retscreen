import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "components"

Item {
    id: captureRoot
    property bool sideBarOpen: true

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // title header
        CaptureHeader { 
            Layout.fillWidth: true
            Layout.preferredHeight: 50
        }

        // live camera feed and patient data sidebar
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                
                // camera feed and toggle button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: sideBarOpen ? parent.width * 0.7 : parent.width
                    radius: 8

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10

                        CameraFeed { 
                            // toggle sidebar button
                            ToggleButton { 
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 10
                            }
                        }

                        // capture button
                        CaptureButton {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            Layout.bottomMargin: 20
                        } 
                    }
                }
                // patient data sidebar
                PatientDataSidebar {
                    Layout.fillHeight: true
                }
            }
        }
    }
}
