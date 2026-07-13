import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects
import "CapturePage_components"
import "Strings.js" as Tr

// deviceManager and cameraManager are set as context properties in main.py

Item {
    id: captureRoot
    property bool sideBarOpen: true

    ColumnLayout {
        anchors.fill: parent

        // title header
        CaptureHeader { 
            Layout.fillWidth: true
            Layout.preferredHeight: 60
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
                    Layout.leftMargin: 20
                    Layout.bottomMargin: 10
                    radius: 9
                    color: '#f3fcff'

                    border.color: '#baddfa' 
                    border.width: 1
                    
                    // glow effect
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: '#42007bff' 
                        shadowBlur: 1.0
                        shadowHorizontalOffset: -2 // Pushes the shadow to the left
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10

                        Rectangle {
                            id: cameraContainer
                            Layout.fillWidth: true
                            Layout.fillHeight: true
 
                            CameraFeed {
                                anchors.fill: parent
                                // toggle sidebar button
                                ToggleButton {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 10
                                }

                                // resolution mode toggle — top-left of camera feed
                                Rectangle {
                                    id: modeToggle
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.margins: 10
                                    width: 108; height: 33
                                    radius: 6
                                    color: "#2c3e50"
                                    opacity: 0.75

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 2

                                        Rectangle {
                                            width: (parent.width - 2) / 2
                                            height: parent.height
                                            radius: 4
                                            color: deviceManager.captureMode === "16mp" ? "white" : "transparent"
                                            Text {
                                                anchors.centerIn: parent
                                                text: "16 MP"
                                                font.pixelSize: 11; font.bold: true
                                                color: deviceManager.captureMode === "16mp" ? "#2c3e50" : "white"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: deviceManager.setMode("16mp")
                                            }
                                        }

                                        Rectangle {
                                            width: (parent.width - 2) / 2
                                            height: parent.height
                                            radius: 4
                                            color: deviceManager.captureMode === "48mp" ? "white" : "transparent"
                                            Text {
                                                anchors.centerIn: parent
                                                text: "64 MP"
                                                font.pixelSize: 11; font.bold: true
                                                color: deviceManager.captureMode === "48mp" ? "#2c3e50" : "white"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: deviceManager.setMode("48mp")
                                            }
                                        }
                                    }
                                }

                                // camera state overlay — top-left below mode toggle
                                Rectangle {
                                    id: cameraStateOverlay
                                    anchors.left: parent.left
                                    anchors.top: modeToggle.bottom
                                    anchors.leftMargin: 10
                                    anchors.topMargin: 6
                                    height: 33
                                    width: stateRow.width + 20
                                    radius: 6
                                    color: "#2c3e50"
                                    opacity: 0.75

                                    property int brightness: 50
                                    property string focusText: "AUTO"

                                    Connections {
                                        target: deviceManager
                                        function onBrightnessChanged(v) { cameraStateOverlay.brightness = v }
                                        function onFocusChanged(v) { cameraStateOverlay.focusText = v.toFixed(1) }
                                    }

                                    Row {
                                        id: stateRow
                                        anchors.centerIn: parent
                                        spacing: 14

                                        Row {
                                            spacing: 5
                                            Text {
                                                text: "BRT"
                                                font.pixelSize: 11; font.bold: true
                                                color: "#aaaaaa"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            TextInput {
                                                id: brtInput
                                                color: "white"
                                                font.pixelSize: 11; font.bold: true
                                                width: 28
                                                selectByMouse: true
                                                validator: IntValidator { bottom: 0; top: 100 }
                                                Binding on text {
                                                    when: !brtInput.activeFocus
                                                    value: cameraStateOverlay.brightness.toString()
                                                }
                                                onAccepted: {
                                                    var v = parseInt(text)
                                                    if (!isNaN(v)) deviceManager.setBrightness(v)
                                                    focus = false
                                                }
                                            }
                                        }

                                        Row {
                                            spacing: 5
                                            Text {
                                                text: "FOC"
                                                font.pixelSize: 11; font.bold: true
                                                color: "#aaaaaa"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            TextInput {
                                                id: focInput
                                                color: "white"
                                                font.pixelSize: 11; font.bold: true
                                                width: 38
                                                selectByMouse: true
                                                Binding on text {
                                                    when: !focInput.activeFocus
                                                    value: cameraStateOverlay.focusText
                                                }
                                                onAccepted: {
                                                    var v = parseFloat(text)
                                                    if (!isNaN(v)) deviceManager.setFocus(v)
                                                    focus = false
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // capture button
                            CaptureButton {
                                id: captureBtn
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                width: parent.width * 0.95
                                height: 38
                                anchors.margins: 10
                            }
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
