#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_manual.py — รวมไฟล์ Markdown ทั้งคู่มือเป็นเอกสารเดียว

ผลลัพธ์ 2 ไฟล์
  1. Precision-Synthesis-QuickStart-TH.html — HTML ไฟล์เดียว เปิดด้วยเบราว์เซอร์
     มีสารบัญด้านข้าง พิมพ์เป็น PDF ได้จากเบราว์เซอร์
  2. Precision-Synthesis-QuickStart-TH.md — Markdown ฉบับรวม (สำหรับแจกจ่ายหรือแปลงต่อ)

วิธีใช้
  python build_manual.py
"""

import html
import re
import sys
import unicodedata
from datetime import date
from pathlib import Path


# Windows console มักตั้งเป็น cp1252 ทำให้พิมพ์ภาษาไทยไม่ได้
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

ROOT = Path(__file__).resolve().parent.parent
OUT_HTML = ROOT / "Precision-Synthesis-QuickStart-TH.html"
OUT_MD = ROOT / "Precision-Synthesis-QuickStart-TH.md"

# ลำดับไฟล์ตามลำดับการอ่าน
FILES = [
    "README.md",
    "00-orientation-and-toolchain.md",
    "01-vhdl-rtl-and-verification.md",
    "02-precision-project-setup.md",
    "03-qor-analysis-and-critical-path.md",
    "04-vivado-handoff.md",
    "05-qor-comparison-10ns-vs-8ns.md",
    "06-troubleshooting-and-checklists.md",
    "appendix-a-tcl-command-reference.md",
    "appendix-b-glossary-th-en.md",
]

# ชื่อไฟล์ -> เลขบทสำหรับลิงก์ภายใน
SLUGS = {
    "README.md": "readme",
    "00-orientation-and-toolchain.md": "ch00",
    "01-vhdl-rtl-and-verification.md": "ch01",
    "02-precision-project-setup.md": "ch02",
    "03-qor-analysis-and-critical-path.md": "ch03",
    "04-vivado-handoff.md": "ch04",
    "05-qor-comparison-10ns-vs-8ns.md": "ch05",
    "06-troubleshooting-and-checklists.md": "ch06",
    "appendix-a-tcl-command-reference.md": "appa",
    "appendix-b-glossary-th-en.md": "appb",
}


# ---------------------------------------------------------------- ยูทิลิตี้

def slugify(text: str) -> str:
    """สร้าง id จากหัวข้อ ใช้เป็น anchor"""
    text = unicodedata.normalize("NFKD", text)
    text = re.sub(r"[^\w\s\-]", "", text, flags=re.UNICODE)
    text = re.sub(r"\s+", "-", text.strip().lower())
    return text[:80] or "sec"


def count_words(text: str) -> int:
    """ประมาณขนาดเนื้อหา: ภาษาไทยไม่มีช่องว่างระหว่างคำ จึงนับเป็นอักขระไทย + คำอังกฤษ
    ค่าที่ได้จึงเป็น "หน่วยข้อความ" ไม่ใช่จำนวนคำแบบเคร่งคัด"""
    thai = len(re.findall(r"[\u0E00-\u0E7F]", text))
    latin = len(re.findall(r"[A-Za-z0-9_\-\.]+", text))
    return thai + latin


def inline(text: str) -> str:
    """แปลง markdown แบบ inline เป็น HTML"""
    out = html.escape(text, quote=False)

    # โค้ดแบบ inline
    out = re.sub(r"`([^`]+)`", r"<code>\1</code>", out)

    # ข้อความหนา
    out = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", out)
    # ข้อความเอียง (ระวังไม่ไปแตะ * ที่อยู่ในโค้ด ซึ่งถูก escape เป็น &#42; แล้วไม่เป็นจริง)
    out = re.sub(r"(?<![\w*])\*([^*\n]+)\*(?!\w)", r"<em>\1</em>", out)
    # ขีดฆ่า
    out = re.sub(r"~~([^\n]+)~~", r"<del>\1</del>", out)
    # ลิงก์
    out = re.sub(
        r"\[([^\]]+)\]\(([^)\s]+)\)",
        r'<a href="\2" target="_blank" rel="noopener">\1</a>',
        out,
    )
    return out


def split_table_row(line: str):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def is_separator(line: str) -> bool:
    return bool(re.match(r"^\s*\|?[\s:\-|]+\|[\s:\-|]*$", line)) and "-" in line


def convert(md: str, base_slug: str) -> tuple[str, list[tuple[int, str, str]]]:
    """แปลง markdown ทั้งเล่มเป็น HTML
    คืนค่า (html, รายการหัวข้อ [(ระดับ, ข้อความ, anchor)])
    """
    lines = md.split("\n")
    out = []
    toc = []
    used_anchors: set[str] = set()
    i = 0
    n = len(lines)
    in_code = False
    code_lang = ""
    code_buf: list[str] = []

    while i < n:
        line = lines[i]

        # โค้ดแบบเส้นเดียวแบบ fence
        m = re.match(r"^```(\w*)\s*$", line)
        if m:
            if not in_code:
                in_code = True
                code_lang = m.group(1)
                code_buf = []
            else:
                out.append(
                    '<pre class="code"><code class="lang-{}">{}</code></pre>'.format(
                        html.escape(code_lang or "text"),
                        html.escape("\n".join(code_buf)),
                    )
                )
                in_code = False
            i += 1
            continue

        if in_code:
            code_buf.append(line)
            i += 1
            continue

        # เส้นคั่น
        if re.match(r"^\s*(---|\*\*\*|___)\s*$", line):
            out.append("<hr>")
            i += 1
            continue

        # หัวข้อ
        m = re.match(r"^(#{1,6})\s+(.*)$", line)
        if m:
            level = len(m.group(1))
            text = m.group(2).strip()
            anchor = base_slug + "-" + slugify(text)
            # กัน anchor ซ้ำ (เช่นหัวข้อสองชื่อเดียวกันในไฟล์เดียวกัน)
            # เพราะ id ซ้ำจะทำให้ลิงก์จากสารบัญกระโดดไปยังหัวข้อผิด
            if anchor in used_anchors:
                suffix = 2
                while "{}-{}".format(anchor, suffix) in used_anchors:
                    suffix += 1
                anchor = "{}-{}".format(anchor, suffix)
            used_anchors.add(anchor)
            toc.append((level, text, anchor))
            css = "h2" if level == 1 else ("h3" if level == 2 else "h4")
            out.append(
                '<{t} id="{a}">{txt}</{t}>'.format(
                    t=css, a=anchor, txt=inline(text)
                )
            )
            i += 1
            continue

        # ตาราง
        if (
            line.strip().startswith("|")
            and i + 1 < n
            and is_separator(lines[i + 1])
        ):
            header = split_table_row(line)
            i += 2
            rows = []
            while i < n and lines[i].strip().startswith("|"):
                rows.append(split_table_row(lines[i]))
                i += 1
            t = ['<div class="table-wrap"><table><thead><tr>']
            t += ["<th>{}</th>".format(inline(h)) for h in header]
            t.append("</tr></thead><tbody>")
            for r in rows:
                t.append("<tr>")
                # จัดความกว้างคอลัมน์ให้เท่ากับหัวตาราง
                for cidx in range(len(header)):
                    cell = r[cidx] if cidx < len(r) else ""
                    t.append("<td>{}</td>".format(inline(cell)))
                t.append("</tr>")
            t.append("</tbody></table></div>")
            out.append("".join(t))
            continue

        # รายการแบบเลข
        m = re.match(r"^(\s*)(\d+)\.\s+(.*)$", line)
        if m:
            out.append("<ol>")
            while i < n:
                mm = re.match(r"^(\s*)(\d+)\.\s+(.*)$", lines[i])
                if not mm:
                    break
                out.append("<li>{}</li>".format(inline(mm.group(3))))
                i += 1
            out.append("</ol>")
            continue

        # รายการแบบ bullet
        m = re.match(r"^(\s*)[-*+]\s+(.*)$", line)
        if m:
            out.append("<ul>")
            while i < n:
                mm = re.match(r"^(\s*)[-*+]\s+(.*)$", lines[i])
                if not mm:
                    break
                out.append("<li>{}</li>".format(inline(mm.group(2))))
                i += 1
            out.append("</ul>")
            continue

        # blockquote
        if line.strip().startswith(">"):
            buf = []
            while i < n and lines[i].strip().startswith(">"):
                buf.append(lines[i].strip().lstrip(">").strip())
                i += 1
            out.append(
                "<blockquote>{}</blockquote>".format(inline(" ".join(buf)))
            )
            continue

        # ย่อหน้า
        if line.strip() == "":
            i += 1
            continue

        buf = []
        while i < n and lines[i].strip() != "" and not re.match(
            r"^(#{1,6}\s|```|\s*[-*+]\s|\s*\d+\.\s|\s*\|)", lines[i]
        ):
            buf.append(lines[i].strip())
            i += 1
        if buf:
            out.append("<p>{}</p>".format(inline(" ".join(buf))))

    if in_code and code_buf:
        out.append(
            '<pre class="code"><code class="lang-{}">{}</code></pre>'.format(
                html.escape(code_lang or "text"),
                html.escape("\n".join(code_buf)),
            )
        )

    return "\n".join(out), toc


CSS = """
:root{
  --fg:#1a1d21; --muted:#5b6470; --bg:#ffffff; --panel:#f6f8fa;
  --line:#e3e7ec; --accent:#0b5cad; --accent-soft:#e8f1fb; --code-bg:#f4f6f8;
}
*{box-sizing:border-box}
html{scroll-behavior:smooth}
body{
  margin:0; background:var(--bg); color:var(--fg);
  font-family:"Leelawadee UI","Sarabun","Noto Sans Thai","IBM Plex Sans Thai",
              "Helvetica Neue",Arial,sans-serif;
  font-size:16px; line-height:1.85;
}
.layout{display:flex; max-width:1400px; margin:0 auto;}
/* ---------- สารบัญ ---------- */
#toc{
  width:300px; flex:0 0 300px; border-right:1px solid var(--line);
  padding:28px 18px 60px; height:100vh; overflow-y:auto;
  position:sticky; top:0; background:var(--panel);
}
#toc h2{font-size:15px; margin:0 0 12px; letter-spacing:.02em; color:var(--muted);
  text-transform:uppercase; font-weight:700}
#toc ol{list-style:none; margin:0; padding:0; counter-reset:c}
#toc ol li{margin:0 0 2px}
#toc a{
  display:block; padding:5px 8px; border-radius:6px; color:var(--fg);
  text-decoration:none; font-size:14px; line-height:1.5;
  border-left:3px solid transparent;
}
#toc a:hover{background:var(--accent-soft); color:var(--accent)}
#toc a.lv1{font-weight:700; margin-top:10px; border-left-color:var(--accent)}
#toc a.lv2{padding-left:20px; color:var(--muted); font-size:13.5px}
#toc a.lv3{padding-left:32px; color:var(--muted); font-size:13px}
/* ---------- เนื้อหา ---------- */
main{flex:1 1 auto; min-width:0; padding:40px 52px 120px;}
main h2{font-size:30px; line-height:1.4; margin:64px 0 18px; padding-bottom:12px;
  border-bottom:2px solid var(--accent);}
main h2:first-child{margin-top:0}
main h3{font-size:23px; margin:38px 0 12px; color:#12395e}
main h4{font-size:19px; margin:28px 0 10px; color:#24506f}
.cover{
  background:linear-gradient(180deg,var(--panel) 0%,#ffffff 100%);
  border:1px solid var(--line); border-left:5px solid var(--accent);
  border-radius:10px; padding:34px 38px; margin:0 0 46px;
}
.cover h1{
  font-size:34px; line-height:1.35; margin:0 0 16px; color:var(--accent);
  font-weight:700; letter-spacing:-.01em;
}
.cover p{margin:0 0 10px; color:var(--muted); font-size:15.5px; max-width:70ch}
.cover p:last-child{margin-bottom:0}
main p{margin:0 0 16px}
main ul,main ol{margin:0 0 18px; padding-left:26px}
main li{margin:0 0 8px}
main li>ul,main li>ol{margin-top:8px}
main strong{font-weight:700}
code{
  font-family:"Cascadia Mono","JetBrains Mono",Consolas,"Courier New",monospace;
  background:var(--code-bg); border:1px solid var(--line); border-radius:4px;
  padding:1px 5px; font-size:.88em; color:#0a3d62;
}
pre.code{
  background:#1b1f24; color:#e6edf3; border-radius:8px; padding:16px 18px;
  overflow-x:auto; font-size:13.5px; line-height:1.65; margin:0 0 20px;
}
pre.code code{background:none; border:none; color:inherit; padding:0; font-size:inherit}
.table-wrap{overflow-x:auto; margin:0 0 22px}
table{border-collapse:collapse; width:100%; font-size:14.5px}
th,td{border:1px solid var(--line); padding:9px 12px; text-align:left; vertical-align:top}
th{background:var(--accent-soft); font-weight:700}
tbody tr:nth-child(even){background:#fafbfc}
blockquote{
  margin:0 0 18px; padding:12px 18px; background:var(--panel);
  border-left:4px solid var(--accent); color:var(--muted); border-radius:0 6px 6px 0;
}
hr{border:none; border-top:1px solid var(--line); margin:34px 0}
a{color:var(--accent)}
.srcfile{font-size:12px; color:var(--muted); border-top:1px dashed var(--line);
  padding-top:6px; margin-top:28px}
/* ---------- พิมพ์เป็น PDF ---------- */
@media print{
  #toc{display:none}
  body{font-size:11pt; line-height:1.6}
  main{padding:0}
  main h2{page-break-before:always; font-size:20pt}
  main h2:first-child{page-break-before:auto}
  main h3,main h4{page-break-after:avoid}
  .cover{border:1px solid #ccc; border-left:5px solid #333; background:none;
         page-break-after:always}
  .cover h1{font-size:22pt}
  .cover p{color:#333}
  pre.code{background:#f2f2f2; color:#111; border:1px solid #ccc; font-size:9pt;
           white-space:pre-wrap; word-wrap:break-word}
  pre.code code{color:#111}
  table{page-break-inside:avoid; font-size:9.5pt}
  a{color:#111; text-decoration:none}
}
"""

PAGE_HEAD = """<!DOCTYPE html>
<html lang="th">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>คู่มือ Siemens Precision Synthesis Quick Start (ฉบับเต็ม)</title>
<style>{css}</style>
</head>
<body>
<div class="layout">
<nav id="toc">
<h2>สารบัญ</h2>
<ol>{toc}</ol>
</nav>
<main>
"""

PAGE_TAIL = """
</main>
</div>
</body>
</html>
"""


def main() -> None:
    missing = [f for f in FILES if not (ROOT / f).exists()]
    parts = []
    all_toc: list[tuple[int, str, str]] = []
    total_words = 0

    for fname in FILES:
        path = ROOT / fname
        if not path.exists():
            print("ข้ามไป (ยังไม่มีไฟล์): {}".format(fname))
            continue
        md = path.read_text(encoding="utf-8")
        total_words += count_words(md)
        slug = SLUGS.get(fname, slugify(fname))
        body, toc = convert(md, slug)
        parts.append(body)
        for level, text, anchor in toc:
            # สารบัญแถบข้าง: ระดับ 1 = ชื่อบท, ระดับ 2 = หัวข้อย่อยของบทนั้น
            if level in (1, 2):
                all_toc.append((level, text, anchor))
        parts.append('<p class="srcfile">แหล่งไฟล์: {}</p>'.format(fname))
        print("รวมแล้ว: {:<46} {:>7} หน่วย".format(fname, count_words(md)))

    toc_html = []
    for level, text, anchor in all_toc:
        toc_html.append(
            '<li><a class="lv{}" href="#{}">{}</a></li>'.format(
                level, anchor, html.escape(text)
            )
        )

    cover = (
        '<div class="cover">'
        "<h1>คู่มือ Siemens Precision Synthesis Quick Start (ฉบับเต็ม)</h1>"
        "<p>เอกสารประกอบการอบรม ภาษาไทย · ยึดลำดับงานจาก Precision Synthesis Quick Start Guide "
        "รุ่น PS2018.1 และขยายเป็นแบบฝึกหัดบนบอร์ด Digilent Nexys A7-100T "
        "ตั้งแต่สร้าง RTL จนถึงสร้าง bitstream</p>"
        "<p>สร้างเมื่อ {} · รวม {} หน่วยข้อความ · {} บท + ภาคผนวก</p>"
        "<p>เอกสารฉบับรวมอยู่ในโฟลเดอร์ "
        "<code>Precision-Synthesis-QuickStart-TH/</code> (รูปแบบ Markdown แก้ได้)</p>"
        "</div>"
    ).format(date.today().isoformat(), "{:,}".format(total_words), len(FILES))

    html_doc = (
        PAGE_HEAD.format(css=CSS, toc="".join(toc_html))
        + cover
        + "\n".join(parts)
        + PAGE_TAIL
    )
    OUT_HTML.write_text(html_doc, encoding="utf-8")

    md_doc = []
    for fname in FILES:
        path = ROOT / fname
        if not path.exists():
            continue
        md_doc.append(path.read_text(encoding="utf-8").rstrip())
        md_doc.append("\n\n---\n\n")
    OUT_MD.write_text("\n".join(md_doc), encoding="utf-8")

    print("-" * 62)
    print("ไฟล์ที่รวมได้      : {} / {}".format(len(FILES), len(FILES)))
    print("รายการในสารบัญ   : {} (บท {} + หัวข้อย่อย {})".format(
        len(all_toc),
        sum(1 for lv, _, _ in all_toc if lv == 1),
        sum(1 for lv, _, _ in all_toc if lv == 2),
    ))
    print("หน่วยข้อความรวม : {:,}".format(total_words))
    print("ไฟล์ HTML        : {} ({:.1f} KB)".format(OUT_HTML.name, OUT_HTML.stat().st_size / 1024))
    print("ไฟล์ Markdown    : {} ({:.1f} KB)".format(OUT_MD.name, OUT_MD.stat().st_size / 1024))


if __name__ == "__main__":
    main()
