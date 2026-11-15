#!/usr/bin/env python3
"""Membuat ringkasan cakupan dari berkas lcov.info.

Dipakai setelah `flutter test --coverage`:

    python docs/tools/coverage_summary.py \
        --lcov coverage/lcov.info \
        --out docs/coverage-summary.md

Skrip sengaja tidak memakai paket pihak ketiga supaya bisa dijalankan di
lingkungan praktikum mana pun (Python 3.8+, tanpa `pip install`).
"""

from __future__ import annotations

import argparse
import collections
import pathlib
import sys

# Tidak ada lagi berkas yang dikecualikan. Sisa fitur lama (SyncService,
# repository versi lama, model Note/Post lokal, dan PostsPage) sudah dihapus
# dari repositori, sehingga seluruh isi `lib/` memang dipakai aplikasi.
EXCLUDED: dict[str, str] = {}

MODULES = [
    ("Fitur catatan", "lib/features/notes/"),
    ("Fitur asisten AI", "lib/features/assistant/"),
    ("Inti & validasi", "lib/core/"),
    ("Akses SQLite", "lib/data/local/"),
    ("Preferensi perangkat", "lib/data/prefs.dart"),
    ("Shell aplikasi", "lib/main.dart"),
    ("Shell aplikasi", "lib/router.dart"),
    ("Halaman pengaturan", "lib/pages/settings_page.dart"),
]


def read_lcov(path: pathlib.Path) -> "collections.OrderedDict[str, list[int]]":
    """Mengembalikan {berkas: [total_baris, baris_tercakup]}."""
    files: "collections.OrderedDict[str, list[int]]" = collections.OrderedDict()
    current: str | None = None
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if line.startswith("SF:"):
            current = line[3:].replace("\\", "/")
            files[current] = [0, 0]
        elif line.startswith("LF:") and current:
            files[current][0] = int(line[3:])
        elif line.startswith("LH:") and current:
            files[current][1] = int(line[3:])
    if not files:
        raise SystemExit(f"Tidak ada data cakupan di {path}")
    return files


def module_of(relative: str) -> str:
    for name, prefix in MODULES:
        if relative == prefix or relative.startswith(prefix):
            return name
    return "Lainnya"


def summarize(files: dict[str, list[int]]) -> tuple[int, int]:
    return sum(v[1] for v in files.values()), sum(v[0] for v in files.values())


def percent(covered: int, total: int) -> str:
    return f"{100.0 * covered / total:.1f}%" if total else "n/a"


def build_report(
    files: dict[str, list[int]], lcov_path: str, generated_note: str
) -> str:
    rel: dict[str, list[int]] = {}
    for absolute, counts in files.items():
        key = absolute.replace("\\", "/")
        if "/lib/" in key:
            key = "lib/" + key.split("/lib/", 1)[1]
        rel[key] = counts

    covered, total = summarize(rel)
    excluded = {k: v for k, v in rel.items() if k in EXCLUDED}
    ex_covered, ex_total = summarize(excluded)
    counted = {k: v for k, v in rel.items() if k not in EXCLUDED}
    live_covered, live_total = summarize(counted)

    out: list[str] = []
    out.append("# Ringkasan Cakupan Pengujian\n")
    out.append(
        "Dokumen ini dihasilkan otomatis agar angkanya bisa diverifikasi ulang, "
        "bukan diketik manual.\n"
    )
    out.append("```bash\n" + "python docs/tools/coverage_summary.py \\\n"
               f"    --lcov {lcov_path} \\\n"
               "    --out docs/coverage-summary.md\n```\n")
    out.append(generated_note + "\n")

    out.append("## 1. Angka utama\n")
    out.append("| Cakupan | Baris | Persentase |")
    out.append("| :--- | ---: | ---: |")
    out.append(f"| Seluruh `lib/` | {covered}/{total} | **{percent(covered, total)}** |")
    if excluded:
        out.append(
            f"| Kode yang dijangkau aplikasi | {live_covered}/{live_total} | "
            f"**{percent(live_covered, live_total)}** |"
        )
        out.append(
            f"| Kode mati / tidak dirutekan (dikecualikan) | {ex_covered}/{ex_total} | "
            f"{percent(ex_covered, ex_total)} |\n"
        )
        out.append(
            "Angka kedua adalah dasar evaluasi: berkas pada bagian 4 memang tidak "
            "bisa dijalankan dari `lib/main.dart`, sehingga mengujinya hanya "
            "menaikkan persentase tanpa memeriksa perilaku yang dipakai pengguna. "
            "Cara memutuskan hal ini dijelaskan di `README.md` bagian temuan.\n"
        )
    else:
        out.append("")
        out.append(
            "Seluruh berkas di `lib/` dapat dijangkau dari `lib/main.dart`; tidak "
            "ada kode mati yang dikecualikan dari angka ini.\n"
        )

    out.append("## 2. Per modul\n")
    out.append("| Modul | Baris | Persentase |")
    out.append("| :--- | ---: | ---: |")
    grouped: dict[str, list[int]] = {}
    for key, counts in counted.items():
        name = module_of(key)
        acc = grouped.setdefault(name, [0, 0])
        acc[0] += counts[1]
        acc[1] += counts[0]
    for name, _ in MODULES:
        if name in grouped:
            c, t = grouped.pop(name)
            out.append(f"| {name} | {c}/{t} | **{percent(c, t)}** |")
    for name in sorted(grouped):
        c, t = grouped[name]
        out.append(f"| {name} | {c}/{t} | {percent(c, t)} |")
    out.append("")

    out.append("## 3. Berkas dengan baris belum tercakup terbanyak\n")
    out.append("| Berkas | Cakupan | Baris belum tercakup | Status |")
    out.append("| :--- | ---: | ---: | :--- |")
    rows = sorted(
        ((counts[0] - counts[1], counts[1], counts[0], key) for key, counts in rel.items()),
        reverse=True,
    )
    for missed, c, t, key in rows[:20]:
        if missed == 0:
            continue
        status = "dikecualikan" if key in EXCLUDED else "diuji / perlu diuji"
        out.append(
            f"| `{key}` | {percent(c, t)} | {missed} | {status} |"
        )
    out.append("")

    if excluded:
        out.append("## 4. Berkas yang dikecualikan\n")
        out.append("| Berkas | Alasan |")
        out.append("| :--- | :--- |")
        for key in sorted(excluded):
            out.append(f"| `{key}` | {EXCLUDED[key]} |")
        out.append("")
        out.append(
            "Berkas-berkas ini tetap dianalisis `flutter analyze` dan diformat, "
            "hanya tidak dihitung dalam evaluasi cakupan.\n"
        )

    out.append("## 5. Catatan interpretasi\n")
    out.append(
        "- `lib/data/local/db.dart` hanya 30% karena `openNotesDb()` memanggil "
        "`getDatabasesPath()` lewat platform channel yang tidak tersedia di "
        "`flutter test`. Skemanya tetap diuji lewat `createNotesSchema()` pada "
        "database SQLite in-memory."
    )
    out.append(
        "- Fitur asisten AI diuji dengan `FakeAiAssistant`; panggilan jaringan "
        "sungguhan ke Gemini sengaja tidak dijalankan di test otomatis karena "
        "butuh API key dan tidak deterministik."
    )
    out.append(
        "- `lib/main.dart`, `lib/router.dart`, `lib/data/prefs.dart`, dan "
        "`lib/pages/settings_page.dart` tidak muncul di `lcov.info` karena "
        "tidak diimpor oleh unit/widget test; alur utamanya dijalankan oleh "
        "integration test di perangkat. Cakupan integration test belum "
        "digabung ke `lcov.info` karena Flutter belum menyatukannya otomatis."
    )
    out.append(
        "- Angka cakupan bukan target yang dikejar. Bagian yang tidak diuji "
        "dipilih berdasarkan risiko, bukan berdasarkan kemudahan menaikkan "
        "persentase."
    )
    out.append("")

    return "\n".join(out).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lcov", default="coverage/lcov.info")
    parser.add_argument("--out", default="docs/coverage-summary.md")
    parser.add_argument(
        "--note",
        default="Sumber: `coverage/lcov.info` dari `flutter test --coverage`.",
    )
    args = parser.parse_args()

    lcov_path = pathlib.Path(args.lcov)
    if not lcov_path.exists():
        print(f"Berkas tidak ditemukan: {lcov_path}", file=sys.stderr)
        print("Jalankan `flutter test --coverage` lebih dulu.", file=sys.stderr)
        return 1

    files = read_lcov(lcov_path)
    report = build_report(files, args.lcov, args.note)

    out_path = pathlib.Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(report, encoding="utf-8", newline="\n")
    print(report)
    print(f"Ditulis ke {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
