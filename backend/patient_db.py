import sqlite3
from pathlib import Path
from PySide6.QtCore import QObject, Slot, Signal

DB_PATH = Path(__file__).parent.parent / "rop_screening.db"


class PatientDatabase(QObject):
    patientsChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._conn = sqlite3.connect(str(DB_PATH))
        self._conn.execute("PRAGMA foreign_keys = ON")
        self._init_tables()

    def _init_tables(self):
        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS patients (
                patient_id TEXT PRIMARY KEY,
                name TEXT,
                gestation TEXT,
                weight TEXT,
                date TEXT
            )
        """)
        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS captures (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                patient_id TEXT,
                image_path TEXT,
                captured_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
            )
        """)
        self._conn.commit()

        cur = self._conn.execute("SELECT COUNT(*) FROM patients")
        if cur.fetchone()[0] == 0:
            self._conn.execute(
                "INSERT INTO patients VALUES (?,?,?,?,?)",
                ("ROP-DEMO-001", "Demo Patient", "28 weeks", "1200g", "4/23/2026")
            )
            self._conn.commit()

    @Slot(result="QVariantList")
    def getPatients(self):
        cur = self._conn.execute(
            "SELECT patient_id, name, gestation, weight, date FROM patients"
        )
        result = []
        for pid, name, gestation, weight, date in cur.fetchall():
            count = self._conn.execute(
                "SELECT COUNT(*) FROM captures WHERE patient_id = ?", (pid,)
            ).fetchone()[0]
            result.append({
                "patientId": pid, "name": name, "gestation": gestation,
                "weight": weight, "date": date, "imageCount": count
            })
        return result

    @Slot(str, str, str, str, str)
    def addPatient(self, patient_id, name, gestation, weight, date):
        self._conn.execute(
            "INSERT OR REPLACE INTO patients (patient_id, name, gestation, weight, date) "
            "VALUES (?,?,?,?,?)",
            (patient_id, name, gestation, weight, date)
        )
        self._conn.commit()
        self.patientsChanged.emit()

    @Slot(str, str)
    def addCapture(self, patient_id, image_path):
        self._conn.execute(
            "INSERT INTO captures (patient_id, image_path) VALUES (?, ?)",
            (patient_id, image_path)
        )
        self._conn.commit()
        self.patientsChanged.emit()

    @Slot(str, result="QVariantList")
    def getCaptures(self, patient_id):
        cur = self._conn.execute(
            "SELECT image_path FROM captures WHERE patient_id = ? ORDER BY id DESC",
            (patient_id,)
        )
        return [row[0] for row in cur.fetchall()]