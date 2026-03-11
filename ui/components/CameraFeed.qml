import QtMultimedia
import QtQuick
import QtQuick.Controls

Rectangle {
    anchors.fill: parent

    VideoOutput {
        id: cameraFeed
        objectName: "cameraFeed"
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop // if we want to maintain the circular eye shape?
    }
}