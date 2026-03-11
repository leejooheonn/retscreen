import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Button {
    id: captureButton

    Text {
        text: "📷  Capture Image"
        color: "white"  
        font.pixelSize: 20         
        anchors.centerIn: parent    
    }

    background: Rectangle {
        implicitWidth: 100
        implicitHeight: 60
        radius: 8
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#007bff" }
            GradientStop { position: 1.0; color: "#00a8cc" }
        }
    }
    opacity: captureButton.pressed ? 0.8 : 1.0
}