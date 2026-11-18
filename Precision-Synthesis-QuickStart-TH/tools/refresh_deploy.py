#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
refresh_deploy.py — คัดลอกเอกสารและ labs ลงโฟลเดอร์ deploy/ สำหรับเผยแพร่

วิธีใช้
  python refresh_deploy.py
"""

import shutil
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

ROOT = Path(__file__).resolve().parent.parent
DEPLOY = ROOT / "deploy"

DOCS = [
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
    "Precision-Synthesis-QuickStart-TH.html",
    "Precision-Synthesis-QuickStart-TH.md",
]

LABS_SUBDIRS = ["rtl", "tb", "sdc", "precision", "vivado", "results"]


def main() -> None:
    DEPLOY.mkdir(exist_ok=True)
    count = 0

    for name in DOCS:
        src = ROOT / name
        if not src.exists():
            print("ข้ามไป (ไม่มีไฟล์): {}".format(name))
            continue
        shutil.copy2(src, DEPLOY / name)
        count += 1
        print("คัดลอก: {}".format(name))

    for sub in LABS_SUBDIRS:
        src_dir = ROOT / "labs" / sub
        if not src_dir.exists():
            continue
        dst_dir = DEPLOY / "labs" / sub
        dst_dir.mkdir(parents=True, exist_ok=True)
        for src in src_dir.glob("*"):
            if src.is_file():
                shutil.copy2(src, dst_dir / src.name)
                count += 1
                print("คัดลอก: labs/{}/{}".format(sub, src.name))

    print("-" * 50)
    print("คัดลอกทั้งหมด {} ไฟล์ลง {}".format(count, DEPLOY))


if __name__ == "__main__":
    main()
