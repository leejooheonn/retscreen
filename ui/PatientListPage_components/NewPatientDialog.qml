import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: addPatientDialog
    modal: true
    standardButtons: Dialog.NoButton
    anchors.centerIn: Overlay.overlay
    
    background: Rectangle {
        implicitWidth: 460
        radius: 16
        color: "#ffffff"
        border.color: "#e2e8f0"
        border.width: 1
    }

    contentItem: ColumnLayout {
        spacing: 24
        
        Text {
            text: "Add New Patient Details"
            font.pixelSize: 22
            font.weight: Font.Bold
            color: "#0f172a"
            Layout.topMargin: 10
        }

        component CustomInput : ColumnLayout {
            property alias label: lbl.text
            property alias placeholder: field.placeholderText
            property alias text: field.text
            spacing: 8
            Layout.fillWidth: true
            
            Text { 
                id: lbl
                font.pixelSize: 13
                font.weight: Font.Medium
                color: "#64748b"
            }
            
            TextField {
                id: field
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                leftPadding: 12
                color: "#1e293b"
                font.pixelSize: 15
                placeholderTextColor: "#94a3b8"
                
                background: Rectangle {
                    radius: 8
                    color: field.activeFocus ? "#ffffff" : "#f8fafc"
                    border.color: field.activeFocus ? "#0070c0" : "#e2e8f0"
                    border.width: field.activeFocus ? 2 : 1
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }
            }
        }

        CustomInput { id: idIn; label: "Patient ID"; placeholder: "e.g. ROP-001" }
        CustomInput { id: nameIn; label: "Full Name"; placeholder: "Enter patient's name" }
        
        RowLayout {
            spacing: 20
            CustomInput { id: gestIn; label: "Gestation (weeks)"; placeholder: "28" }
            CustomInput { id: weightIn; label: "Birth Weight (g)"; placeholder: "1200" }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            Layout.topMargin: 10
            spacing: 12

            Button {
                id: cancelBtn
                text: "Cancel"
                flat: true
                contentItem: Text {
                    text: cancelBtn.text
                    color: "#64748b"
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: addPatientDialog.close()
            }

            Button {
                id: saveBtn
                text: "Save Patient"
                Layout.preferredWidth: 140
                Layout.preferredHeight: 45
                
                contentItem: Text {
                    text: saveBtn.text
                    color: "white"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 8
                    color: saveBtn.pressed ? "#005a9e" : (saveBtn.hovered ? "#0078d4" : "#0070c0")
                }
                
                onClicked: {
                    let currentDate = new Date();
                    let dateString = currentDate.toLocaleDateString("en-US", {
                        year: 'numeric', month: '2-digit', day: '2-digit'
                    });
                    
                    patientDb.addPatient(
                        idIn.text,
                        nameIn.text,
                        gestIn.text + " weeks",
                        weightIn.text + "g",
                        dateString
                    )
                    addPatientDialog.close()
                }
            }
        }
    }
}