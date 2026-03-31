import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../Strings.js" as Tr

RowLayout {
    id: brightnessRoot
    spacing: 8

    property int value: 50   // 0-100, synced with deviceManager

    // Sync from Pi (e.g. if Pi changes brightness independently)
    Connections {
        target: deviceManager
        function onBrightnessChanged(v) { brightnessRoot.value = v }
    }

    Image {
        source: "../../assets/camera_icon.png"
        Layout.preferredWidth: 18
        Layout.preferredHeight: 18
        fillMode: Image.PreserveAspectFit
        opacity: 0.6
    }

    Slider {
        id: brightnessSlider
        Layout.fillWidth: true
        from: 0; to: 100
        value: brightnessRoot.value
        stepSize: 1

        onMoved: {
            brightnessRoot.value = Math.round(value)
            deviceManager.setBrightness(Math.round(value))
        }

        background: Rectangle {
            x: brightnessSlider.leftPadding
            y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
            width:  brightnessSlider.availableWidth
            height: 4
            radius: 2
            color: "#dbefff"

            Rectangle {
                width:  brightnessSlider.visualPosition * parent.width
                height: parent.height
                radius: 2
                color:  "#0078e0"
            }
        }

        handle: Rectangle {
            x: brightnessSlider.leftPadding + brightnessSlider.visualPosition *
               (brightnessSlider.availableWidth - width)
            y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
            width: 16; height: 16; radius: 8
            color: brightnessSlider.pressed ? "#0078e0" : "#ffffff"
            border.color: "#0078e0"
            border.width: 2
        }
    }

    Text {
        text: brightnessRoot.value
        font.pixelSize: 12
        color: "#2c3e50"
        Layout.preferredWidth: 24
        horizontalAlignment: Text.AlignRight
    }
}
