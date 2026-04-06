import QtQuick
import QtQuick.Controls

Rectangle {
    anchors.fill: parent
    color: "black"

    Image {
        id: cameraFeed
        objectName: "cameraFeed"
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        // frameCount change triggers a reload; provider returns the latest frame synchronously
        source: "image://stream/frame?" + mjpegStream.frameCount
        cache: false
        asynchronous: false  // synchronous pull from provider — no blank flash between frames
    }

    // AF window overlay — matches _AF_WINDOW on Pi (center 25%×25% of sensor).
    // Sensor is 4:3; preview crops to 16:9, so height maps to ~33.3% of preview height.
    Rectangle {
        anchors.centerIn: parent
        width:  parent.width  * 0.25
        height: parent.height * 0.333
        color: "transparent"
        border.color: "#FFFF00"
        border.width: 1
    }
}
