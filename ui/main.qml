import QtQuick
import QtQuick.Controls
import "Strings.js" as Tr
import "./CapturePage_components" as Components

ApplicationWindow {
    id: window
    visible: true
    width: 1024; height: 600
    title: "ROP Screening"

    header: Column {
        Components.CaptureHeader { 
            id: appHeader 
            width: parent.width
        }
        Components.Toolbar {
            id: navBar
            width: parent.width
        }
    }
    property string currentLang: "EN"
    property var activePatient: null 

    function selectPatient(patientData) {
        activePatient = patientData;
        stackView.push("CapturePage.qml");
    }

    // 1. DATA MODEL: now backed by SQLite via patientDb
    ListModel { id: patientModel }

    function refreshPatients() {
        patientModel.clear()
        var patients = patientDb.getPatients()
        for (var i = 0; i < patients.length; i++) {
            patientModel.append(patients[i])
        }
    }

    Connections {
        target: patientDb
        function onPatientsChanged() { refreshPatients() }
    }

    Component.onCompleted: refreshPatients()

    // 3. THE STACK: manages which page is visible
    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: "PatientListPage.qml"
    }
}