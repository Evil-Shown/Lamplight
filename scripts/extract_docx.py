import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"


def cell_text(tc):
    parts = []
    for t in tc.iter(f"{W}t"):
        if t.text:
            parts.append(t.text)
        if t.tail:
            parts.append(t.tail)
    return " ".join(parts).strip()


def extract_docx(path: Path) -> str:
    with zipfile.ZipFile(path) as z:
        root = ET.fromstring(z.read("word/document.xml"))
    out = [f"# Source: {path.name}", ""]
    body = root.find(f"{W}body")
    if body is None:
        return ""
    for child in body:
        tag = child.tag.split("}")[-1]
        if tag == "p":
            parts = []
            for t in child.iter(f"{W}t"):
                if t.text:
                    parts.append(t.text)
                if t.tail:
                    parts.append(t.tail)
            line = "".join(parts).strip()
            if line:
                out.append(line)
                out.append("")
        elif tag == "tbl":
            rows = []
            for tr in child.iter(f"{W}tr"):
                row = [cell_text(tc) for tc in tr.iter(f"{W}tc")]
                if any(row):
                    rows.append(row)
            if rows:
                out.append("--- TABLE ---")
                for row in rows:
                    out.append(" | ".join(row))
                out.append("")
    return "\n".join(out)


def main():
    paths = [
        Path(r"C:\Users\TUF\Desktop\HCI_Assignment-2_WE_153_2.2.docx"),
        Path(r"C:\Users\TUF\Desktop\Assignment1_HCI.docx"),
    ]
    dest = Path(__file__).resolve().parents[1] / "docs" / "hci_assignments_extracted"
    dest.mkdir(parents=True, exist_ok=True)
    for p in paths:
        if not p.exists():
            print(f"MISSING: {p}")
            continue
        text = extract_docx(p)
        name = p.stem.replace(" ", "_") + ".md"
        out_path = dest / name
        out_path.write_text(text, encoding="utf-8")
        print(f"Wrote {out_path} ({len(text)} chars)")


if __name__ == "__main__":
    main()
