# AGENTS.md — tdi_lab

คู่มือ Tanner Digital Implementer (TDI) แบบ labs + ภาคผนวกอ้างอิง
ทุกตัวเลขในเอกสารมาจากการรันจริงบนเครื่องนี้

## คำสั่งที่ใช้บ่อย

```bat
REM รันทุก lab
cd tdi_lab\lab07_regression && run.cmd

REM รัน lab เดียว
cd tdi_lab\lab01_rtl_ports && run.cmd

REM สร้างเอกสารใหม่ (ต้องมี pandoc + Chrome)
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-docs.ps1

REM แพ็กส่งมอบ
powershell -NoProfile -ExecutionPolicy Bypass -File tools\make-zip.ps1

REM สร้าง run.cmd ของทุก lab ใหม่ (หลังแก้เทมเพลต)
powershell -NoProfile -ExecutionPolicy Bypass -File tools\make-runners.ps1
```

## กฎที่ห้ามละเมิดในโปรเจกต์นี้

1. **ไฟล์ `.cmd` ต้องเป็น ASCII ล้วน** — Thai หรือ UTF-8 ใน `.cmd` ทำให้
   `cmd.exe` อ่านโครงสร้างบรรทัดผิด (คอมเมนต์กินตัวอักษรแรกของบรรทัดถัดไป)
2. **ห้ามมี `(` หรือ `)` ที่ไม่ escape ในบรรทัด `echo` ที่อยู่ในบล็อก `if`**
   — `cmd.exe` จะรายงาน syntax error แล้วหยุดสคริปต์ทั้งบล็อก
   (เคยเจอกับ `echo ... lab(s) failed` → `failed was unexpected at this time.`)
3. **ห้ามใช้ `&` ในข้อความที่ echo ออกมา** — `cmd.exe` ตีความเป็นตัวคั่นคำสั่ง
   (เคยเจอกับชื่อ lab ที่มี "P&R")
4. **ห้ามใช้ `echo > file`** — จะเขียนข้อความ "ECHO is off." ลงไฟล์
   ใช้ `type nul > file` แทน
5. **ห้ามใช้ `[System.IO.File]::WriteAllText` ในไฟล์ `.ps1` ของโปรเจกต์นี้**
   — เครื่องมือเขียนไฟล์จะลบไฟล์นั้นทิ้งทันที (ใช้ `Set-Content` / `Out-File` แทน)
6. **คอมเมนต์ใน `.ps1` เขียนเป็น ASCII** — PowerShell 5.1 อ่าน `.ps1` ที่ไม่มี BOM
   เป็น ANSI ภาษาไทยจะเพี้ยน
7. **`Get-Content` ต้องใส่ `-Encoding UTF8`** เสมอเมื่ออ่านไฟล์ `.md`
   ที่เขียนด้วย UTF-8 ไม่มี BOM ไม่งั้นภาษาไทยจะเพี้ยน
8. **อย่าแก้ `.cmd` ด้วย PowerShell `-replace` แบบจับคู่แบบ array ที่พลาด**
   — `$string[0]` คืน **ตัวอักษรแรก** ไม่ใช่ string ทั้งก้อน
   (เคยทำให้ไฟล์ JS ทั้ง 3 ไฟล์เสียหายเพราะ `C` ถูกแทนที่ด้วย `.`)

## โครงสร้าง

- `docs/parts/*.md` → `tools/build-docs.ps1` → `docs/Lab_Guide_TDI.{md,html,pdf}`
- `tools/checks/checkNN_*.js` → lab NN เรียกใช้ → `labNN_*/run.cmd`
- `design/` → ไฟล์ตัวอย่าง ADC8 + `nitro_settings_ADCCtrl.tcl` (ตัวอย่างสัญญา 51 ตัวแปร)
- lab แต่ละตัวมี `run.cmd` (ASCII) + `results/output.txt` + `result.txt`

## ตรวจงาน

ก่อนส่งมอบต้องเห็น

```text
lab07_regression → passed : 6 / failed : 0 / exit 0
```

และตัวเลขในเอกสารต้องตรงกับผลรันจริง
(ตัวตรวจสอบใน `tools/checks/` พิสูจน์ตัวเลขทุกตัวในคู่มือ)
