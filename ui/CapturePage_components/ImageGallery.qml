import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Strings.js" as Tr

ColumnLayout {
    Layout.fillHeight: true 
    spacing: 8

    Connections {
        target: cameraManager
        function onImageSaved(path) {
            console.log("adding to gallery:", path)
            galleryModel.insert(0, { "filesource": path })
        }
    }

    Text {
        text: Tr.get("recentCaptures", window.currentLang)
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        font.bold: true
        font.pixelSize: 16
        color: "#2c3e50"
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "#f8f9fa"
        radius: 12
        border.color: "#eeeeee"
        border.width: 1
        clip: true

        GridView {
            id: galleryGrid
            anchors.fill: parent
            anchors.margins: 10
            cellWidth: parent.width / 2
            cellHeight: 110

            model: ListModel { id: galleryModel }

            delegate: Item {
                width: galleryGrid.cellWidth
                height: galleryGrid.cellHeight

                Rectangle {
                    anchors.fill: parent 
                    anchors.margins: 4
                    radius: 8
                    color: "white"
                    border.color: "#dddddd"
                    clip: true

                    Image {
                        anchors.fill: parent 
                        source: model.filesource
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            fullImagePopup.imageSource = model.filesource
                            fullImagePopup.open()
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: Tr.get("noCaptures", window.currentLang)
                color: "#bdc3c7"
                font.italic: true
                visible: galleryGrid.count === 0
            }
        }
    }

    Popup {
        id: fullImagePopup
        property alias imageSource: fullImage.source

        anchors.centerIn: Overlay.overlay
        width: Overlay.overlay ? Overlay.overlay.width * 0.8 : 600
        height: Overlay.overlay ? Overlay.overlay.height * 0.8 : 600
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#000000"
            radius: 8
        }

        Image {
            id: fullImage
            anchors.fill: parent
            anchors.margins: 10
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: fullImagePopup.close()
        }
    }
}