"""Membuat database SQLite 1.500 catatan untuk screenshot di perangkat.

Skema mengikuti lib/data/local/db.dart. Jalankan:

    python docs/tools/seed_device_db.py offline_notes.db

Lalu dorong ke perangkat (lihat README bagian Screenshots).
"""

import datetime
import sqlite3
import sys

TITLES = [
    "Rencana rapat mingguan",
    "Belanja bulanan keluarga",
    "Ide aplikasi catatan offline",
    "Review pull request Minggu 8",
    "Belajar Clean Architecture",
    "Daftar buku yang ingin dibaca",
    "Rencana liburan akhir tahun",
    "Catatan rapat koordinasi tim",
    "Anggaran transportasi bulan ini",
    "Checklist presentasi proyek",
    "Resep masakan rumahan sederhana",
    "Target belajar Flutter minggu ini",
    "Daftar kontak penting kampus",
    "Evaluasi performa aplikasi",
    "Rencana perbaikan UI beranda",
]

BODY = (
    "Catatan contoh nomor {i} untuk mengukur performa daftar panjang. "
    "Isi ini sengaja dibuat beberapa baris agar tinggi kartu bervariasi, "
    "sehingga layout dan paint benar-benar diuji."
)


def main(path: str, count: int = 1500) -> None:
    con = sqlite3.connect(path)
    cur = con.cursor()
    cur.executescript(
        """
        DROP TABLE IF EXISTS notes;
        DROP TABLE IF EXISTS cached_posts;
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE cached_posts(
          id INTEGER PRIMARY KEY,
          payload TEXT NOT NULL,
          cached_at TEXT NOT NULL
        );
        """
    )

    now = datetime.datetime(2026, 11, 15, 2, 38, 0)
    rows = []
    for i in range(count):
        title = f"{TITLES[i % len(TITLES)]} {i + 1}"
        body = "" if i % 3 == 0 else BODY.format(i=i + 1)
        updated = (now - datetime.timedelta(minutes=i)).isoformat(timespec="milliseconds")
        rows.append((title, body, updated, 1 if i % 7 == 0 else 0))

    cur.executemany(
        "INSERT INTO notes(title, body, updated_at, dirty) VALUES (?, ?, ?, ?)",
        rows,
    )
    # sqflite menyimpan versi skema di PRAGMA user_version.
    cur.execute("PRAGMA user_version = 1")
    con.commit()
    con.close()
    print(f"{count} catatan ditulis ke {path}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "offline_notes.db")
