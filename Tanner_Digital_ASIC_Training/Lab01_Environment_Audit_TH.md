# Lab 1 — Environment audit: เปิด L-Edit/TDI ตรวจ license รัน reference design และตรวจ library views

หลักสูตร Tanner Digital ASIC Design Implementation — ระดับเริ่มต้นถึงระดับกลาง

## 1. เป้าหมายและขอบเขต

บทปฏิบัติการนี้ใช้ยืนยันว่าเครื่องมือ สภาพแวดล้อมการทำงาน และข้อมูลเทคโนโลยีพร้อมสำหรับการสร้าง digital block ที่จะนำไปประกอบใน analog-on-top design ผู้เรียนต้องแยกให้ออกระหว่าง “ติดตั้งโปรแกรมแล้ว” “เปิด GUI ได้” “รัน engine ได้” และ “ได้ผล implementation ที่ตรวจสอบได้” เพราะแต่ละสถานะมีหลักฐานและข้อกำหนดต่างกัน

เมื่อจบบท ผู้เรียนต้องสามารถ:

1. ระบุ version/build และ execution host ของ L-Edit, synthesis engine และ place-and-route engine
2. ตรวจการใช้ license ด้วยงานจริง และแยก network connectivity ออกจาก feature checkout
3. เปิด reference project โดยไม่เปลี่ยนต้นฉบับ ระบุ top และ input ที่ถูกใช้จริง
4. รัน baseline ตามขอบเขตที่ผู้สอนกำหนด เก็บ log/report และเปิดผลกลับมาตรวจใน L-Edit
5. ตรวจความสอดคล้องของ Liberty, LEF, layout, simulation models และ LVS reference views ตามที่ flow ต้องใช้
6. สรุป PASS, FAIL, BLOCKED และ NOT TESTED พร้อมหลักฐาน โดยไม่ใช้การคาดเดาแทนผลทดสอบ

เวลาที่แนะนำ 3–4 ชั่วโมง: เตรียม environment 30 นาที, เปิด GUI/ตรวจ license 40 นาที, reference run 60–90 นาที, library audit 45 นาที และจัดทำรายงาน 20 นาที ทั้งนี้ runtime ขึ้นกับ reference design และทรัพยากรเครื่อง

**สถานะเอกสาร:** เป็นขั้นตอนปฏิบัติและแบบฟอร์มสำหรับนำไปใช้ในห้องอบรม ยังไม่ได้รันกับ installation, license หรือ PDK ของผู้เรียน จึงไม่มีผล PASS ที่ยืนยันแทนเครื่องจริง

## 2. เข้าใจองค์ประกอบของระบบก่อนเริ่ม

Siemens อธิบาย Digital Implementer ว่าใช้ Oasys สำหรับ synthesis และ Nitro สำหรับ place-and-route โดยเริ่มงานผ่าน wizard ใน L-Edit และเปิดให้ปรับแต่งด้วย Tcl ได้ [1] บทนี้จึงแยกการตรวจแต่ละส่วน แทนการถือว่าเปิด layout editor ได้แล้วหมายถึง RTL-to-GDSII พร้อมทั้งหมด

| ส่วนประกอบ | สิ่งที่ต้องตรวจ | หลักฐานขั้นต่ำ |
|---|---|---|
| L-Edit | เปิดโปรแกรม เปิดฐานข้อมูล และดู layout ได้ | version/build, startup messages, cell/view ที่เปิด |
| TDI integration | พบจุดตั้งค่าและ launch flow ของ installation นี้ | project setup และ flow/template revision |
| Synthesis engine | เริ่ม process, checkout feature, elaborate/map ได้ | startup และ synthesis log/report |
| P&R engine | อ่าน technology/library, สร้างและ export implementation ได้ | import/placement/CTS/route/export log ตาม scope |
| Execution environment | OS, dependencies, path, permission, remote access ถ้ามี | system inventory และ job log |
| Technology/library | views อยู่ใน release และ configuration ที่เข้ากัน | manifest, loaded-library log, view audit |

ชื่อเมนู toolbar, executable, feature license และ script ขึ้นกับ release และ package ที่องค์กรได้รับ ให้ใช้ Help/คู่มือที่ติดตั้งมาด้วยเป็นหลัก ชื่อ เช่น Digital Implementer, TDI หรือ Nitro ในบทนี้เป็นคำสำหรับค้นหาฟังก์ชัน ไม่ใช่คำรับรองว่าทุก release มีเมนูชื่อเดียวกัน

หากใช้ GUI และ engine คนละเครื่อง ต้องตรวจ OS ที่ engine release รองรับจาก installation guide โดยตรง การเปิด L-Edit บน Windows ไม่ยืนยันว่า engine ใช้งานบน Windows เครื่องเดียวกันได้ และไม่ควรถือว่า WSL หรือ Linux distribution ที่ใช้อยู่ได้รับการรับรองโดยอัตโนมัติ

## 3. สิ่งที่ผู้สอนต้องเตรียม

ก่อนอบรม ผู้สอนหรือ CAD administrator ต้องจัดเตรียม reference package ที่ทดลองผ่านแล้วใน configuration เป้าหมาย โดยมี:

- ชื่อ release/build ของ tools และ supported OS ที่ใช้เป็น baseline
- วิธีเปิด L-Edit และวิธีเริ่ม engine ที่องค์กรทดสอบแล้ว
- license configuration สำหรับผู้เรียน และผู้รับผิดชอบเมื่อ feature ไม่พอ
- reference project พร้อม README, RTL source list, top, constraints และ flow settings
- PDK/standard-cell release ที่ได้รับอนุญาตให้ใช้ พร้อม technology setup สำหรับ flow นี้
- baseline log/report หรือช่วงค่าที่คาดหวัง รวมทั้ง known warnings
- ขอบเขตการรัน: import-only, synthesis หรือ full implementation พร้อมระบุอย่างชัดเจน
- reference outputs ที่จำเป็นสำหรับการเปิดกลับใน L-Edit เช่น OA database หรือ stream layout ตาม flow

**อย่าเริ่มด้วยการสร้าง library integration ใหม่พร้อมกับทดสอบ installation** เพราะเมื่อผิดพลาดจะไม่ทราบว่าเกิดจาก environment หรือข้อมูลใหม่ หากไม่มี reference package ที่ผ่านแล้ว ให้บันทึกว่า reference validation ถูก BLOCKED และทำเฉพาะ inventory/GUI/library inspection ที่ทำได้

### 3.1 แบบฟอร์มก่อนเริ่ม

| รายการ | ค่าในห้องอบรม |
|---|---|
| ผู้ปฏิบัติ / วันที่ / run ID | … |
| L-Edit version/build และ install path | … |
| Synthesis version/build และ execution host | … |
| P&R version/build และ execution host | … |
| Client OS / engine OS | … |
| License configuration ที่ administrator รับรอง | … |
| Reference package revision/hash | … |
| Reference top / source language | … |
| PDK / metal stack / stdcell release | … |
| Timing library corners / RC configuration | … |
| Expected scope / output / warning baseline | … |

ไม่ใส่ license file ทั้งฉบับ รหัสผ่าน หรือ private key ลงในรายงานที่แชร์ ชื่อ host ภายในอาจเก็บในหลักฐานจำกัดสิทธิ์และใช้ชื่อย่อในเอกสารการสอน

## 4. ขั้นที่ 1 — สร้างพื้นที่ทำงานและตรึง input

### 4.1 เตรียมโฟลเดอร์

1. เลือก working directory ที่ผู้ใช้และ engine account อ่าน/เขียนได้
2. สร้างโฟลเดอร์ `reference_copy`, `runs`, `audit` และ `evidence`
3. คัดลอก reference package มาไว้ใน `reference_copy` โดยไม่แก้ต้นฉบับ
4. แยก run directory ต่อครั้ง เช่น `runs/baseline_001`
5. จัดทำ manifest ของ inputs และ revision ของ flow ก่อน launch

ตัวอย่าง PowerShell สำหรับสร้างพื้นที่ฝึก ตัวอย่างนี้เป็นคำสั่ง OS ไม่ใช่คำสั่ง TDI:

```powershell
$labRoot = 'C:\asic_training\lab01'
New-Item -ItemType Directory -Force -Path $labRoot | Out-Null
foreach ($part in @('reference_copy','runs','audit','evidence')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $labRoot $part) | Out-Null
}
Set-Location -LiteralPath $labRoot
```

ให้เปลี่ยน path ให้ตรงกับสิทธิ์ของผู้เรียน เก็บ PDK ไว้ในตำแหน่งที่ flow รองรับและอ้างอิงด้วย configuration ที่ตรวจสอบได้ ไม่ต้องคัดลอก PDK ทุกไฟล์เข้าพื้นที่ฝึก

### 4.2 ตรวจ write permission ของทั้ง GUI และ engine

ทดลองสร้างและลบไฟล์ทดสอบขนาดเล็กใน working directory ด้วย account ที่ใช้รันจริง หากเป็น remote engine ต้องทดสอบจากฝั่ง remote ด้วย path ที่ engine มองเห็นจริง

ตัวอย่างสำหรับ Linux engine host:

```bash
pwd
id
uname -a
df -h .
df -i .
free -h
touch .lab01_write_probe
rm -- .lab01_write_probe
```

ตรวจ quota เพิ่มตามระบบขององค์กร `df` ไม่ได้ยืนยัน user quota และอย่าใช้คำสั่งลบแบบ recursive เพื่อแก้ permission ปัญหา

**เกณฑ์ผ่าน:** working directory ถูกต้อง เขียนได้ มีพื้นที่ตามข้อกำหนด reference และบันทึก input revision แล้ว การเปิดไฟล์ผ่าน GUI สำเร็จไม่แทนการตรวจ path ฝั่ง engine

## 5. ขั้นที่ 2 — ตรวจ installation และ execution environment

### 5.1 บันทึกข้อมูลเครื่อง

Windows:

```powershell
Get-CimInstance Win32_OperatingSystem |
    Select-Object Caption, Version, OSArchitecture
Get-CimInstance Win32_ComputerSystem |
    Select-Object TotalPhysicalMemory
Get-PSDrive -PSProvider FileSystem
```

Linux:

```bash
cat /etc/os-release
uname -m
ulimit -a
```

เทียบข้อมูลกับ installation/release notes ของ **แต่ละ engine** รวมถึง library ของ OS, shell และวิธี remote execution ถ้ามี ไม่กำหนด RAM ขั้นต่ำแบบตายตัวโดยไม่มีข้อมูลของ design ให้ใช้ requirement ของ release และ measured peak memory ของ reference เป็นฐาน

### 5.2 ตรวจว่ากำลังเรียก installation ที่ต้องการ

1. เปิด Properties ของ shortcut หรือ launcher ที่ผู้สอนให้
2. จด target และ wrapper script ที่เกี่ยวข้อง
3. เปิด L-Edit แล้วดูหน้าข้อมูลผลิตภัณฑ์/Help/About ตาม release
4. เก็บ version/build ที่แสดงจริง
5. เมื่อรัน synthesis/P&R ให้เก็บ version จาก startup log ของ process นั้นเพิ่ม

อย่าอนุมาน version ของ engine จาก version ของ L-Edit เนื่องจาก launcher หรือ remote configuration อาจชี้ไปยัง engine คนละ installation

### 5.3 ตรวจ remote execution ถ้าใช้

ตรวจลำดับต่อไปนี้:

1. GUI host ติดต่อ execution host ผ่านช่องทางที่องค์กรกำหนดได้
2. Authentication สำเร็จด้วย account ที่ได้รับอนุญาต
3. Remote working directory มีอยู่และเขียนได้
4. Engine host อ่าน RTL, SDC, Liberty, LEF และ technology setup ได้
5. Environment ที่ job ได้รับตรงกับ session ที่ใช้ตรวจ ไม่อาศัยเพียง interactive shell
6. Output กลับมาถึงตำแหน่งที่ L-Edit เปิดได้

ตัวอย่าง `C:\asic_training\lab01` และ `/projects/training/lab01` เป็นคนละ path ต้องมี mapping หรือ transfer ที่ชัดเจน ไม่ใช่เปลี่ยน backslash เป็น slash แล้วถือว่าเป็นไฟล์เดียวกัน

**เกณฑ์ผ่าน:** ยืนยันเครื่องและ installation ที่รันจริงได้ พร้อม supported configuration หรือบันทึกข้อเบี่ยงเบนที่ผู้สอนยอมรับ หากรองรับไม่ชัดเจน ให้ระบุ “ยังไม่ยืนยัน compatibility”

## 6. ขั้นที่ 3 — เปิด L-Edit และตรวจ GUI เบื้องต้น

1. เปิดด้วย launcher ที่องค์กรเตรียมไว้ เพื่อรับ environment ที่ถูกต้อง
2. บันทึกเวลาเปิดและข้อความ startup/license
3. ตรวจ version/build
4. เปิดสำเนา reference project หรือฐานข้อมูลตัวอย่างตาม README
5. ตรวจ library/cell/view ที่กำลังเปิดว่าตรงกับ reference
6. ทดลอง zoom, pan, fit view และเลือก instance หนึ่งตัว
7. เปิด properties ของ cell/instance เพื่อตรวจชื่อและ hierarchy
8. ตรวจ layer palette ว่ามี technology layers ตาม reference
9. ในสำเนาที่เขียนได้ ให้ทดสอบ save ตามวิธีของ project จากนั้นปิดและเปิดกลับ

อย่าปรับแก้ standard-cell master เพื่อทดสอบ save ให้สร้างหรือใช้ scratch cell ที่ผู้สอนกำหนด และอย่า import GDS ทับ technology/reference library

### 6.1 ตรวจจุดเข้า TDI

1. ค้นหาคำสั่ง Digital Implementer/TDI/Nitro จาก UI หรือ Help ของ release
2. ถ้ามี toolbar ที่เกี่ยวข้อง ตรวจว่าเปิดใช้งานได้
3. เปิดหน้าตั้งค่า project เพื่อดู input และ engine configuration
4. หากไม่พบ ให้ตรวจ installation components, edition, integration setup และ feature entitlement ก่อนสรุปว่าเป็นปัญหา license
5. บันทึกชื่อเมนูที่ใช้จริงลงในคู่มือประจำห้องอบรม

**เกณฑ์ผ่าน GUI:** เปิดและแสดง reference layout ได้ พร้อมยืนยัน technology และ version

**เกณฑ์ผ่าน TDI integration:** เปิด setup ของ flow ที่ได้รับได้ ยังไม่ถือว่า engine license ผ่านจนกว่าจะเริ่มงานจริง

## 7. ขั้นที่ 4 — ตรวจ license อย่างเป็นลำดับ

### 7.1 แยกหลักฐานเป็นสามระดับ

| ระดับ | ตรวจอะไร | ยืนยันอะไรได้ |
|---|---|---|
| Configuration | client/job เห็นค่าชี้ license ตามคู่มือ | มี configuration ให้ใช้งาน |
| Connectivity/status | DNS/port/license service ติดต่อได้ | เส้นทางและบริการบางส่วนตอบสนอง |
| Feature checkout | engine ขอ feature และเริ่มงานได้ | process นี้ใช้ entitlement ที่ต้องการได้ ณ เวลาทดสอบ |

TCP connection ที่สำเร็จไม่รับรองว่า vendor daemon/feature พร้อม และการเปิด L-Edit ไม่ยืนยัน entitlement ของ synthesis/P&R

### 7.2 ตรวจค่าที่ process ได้รับ

ให้ CAD administrator ระบุ licensing generation และชื่อตัวแปรที่ release ใช้ก่อน ตัวอย่างคำสั่งต่อไปนี้ใช้สำรวจตัวแปรที่พบบ่อย ไม่ใช่คำแนะนำให้ตั้งทุกตัวพร้อมกัน:

```powershell
$licenseVars = @('SALT_LICENSE_SERVER','MGLS_LICENSE_FILE','LM_LICENSE_FILE')
foreach ($varName in $licenseVars) {
    [pscustomobject]@{
        Name = $varName
        Value = [Environment]::GetEnvironmentVariable($varName, 'Process')
    }
}
```

```bash
printenv SALT_LICENSE_SERVER
printenv MGLS_LICENSE_FILE
printenv LM_LICENSE_FILE
```

ค่าที่ว่างไม่ได้แปลว่าไม่มี license เสมอไป เพราะ installation อาจใช้ configuration อื่นตามคู่มือ ห้ามคัดลอกค่าจากคู่มือเก่าไปทับ environment โดยไม่ทราบลำดับการค้นหา license ของ release นั้น

หาก administrator ให้ค่า `port@server` ให้ใช้ค่าจริงที่ได้รับ ไม่เดา port จากตัวอย่างอินเทอร์เน็ต หลังแก้ environment ต้องเปิด process ใหม่ที่รับค่าดังกล่าว รวมทั้ง remote job launcher ถ้าเกี่ยวข้อง

### 7.3 ทดสอบ connectivity แบบจำกัดขอบเขต

ตัวอย่าง PowerShell ใช้ค่า host/port ที่ administrator ยืนยัน:

```powershell
$licenseHost = Read-Host 'License server hostname supplied by administrator'
$licensePort = [int](Read-Host 'License server TCP port supplied by administrator')
Resolve-DnsName -Name $licenseHost
Test-NetConnection -ComputerName $licenseHost -Port $licensePort
```

หากระบบใช้ vendor daemon port แยก ต้องตรวจตาม configuration ที่ administrator ระบุด้วย อย่าสแกนช่วง port ทั้งเครือข่าย และหากมี license-status utility ให้ใช้ executable/options ที่คู่มือ installation ขององค์กรระบุ ไม่สมมติว่าทุกระบบมี `lmutil` หรือ utility ชื่อเดียวกัน

### 7.4 ยืนยัน checkout ผ่าน reference run

1. เปิด L-Edit และเก็บ startup evidence
2. เริ่ม synthesis reference แล้วตรวจ feature checkout/startup ใน log
3. เริ่ม P&R reference แล้วตรวจแบบเดียวกัน
4. จดชื่อ feature ที่รายงานจริง เวลา และ execution host
5. ตรวจงานไม่ค้างใน license queue และ process ไม่จบจาก license error
6. เมื่อจบ ปิด process ตามปกติ และตรวจการคืน license ด้วยวิธีที่ administrator อนุญาต หากจำเป็น

หาก log ไม่แสดง feature name ให้เก็บหลักฐานว่า engine เริ่มและทำขั้นตอนจริงสำเร็จ พร้อมขอ license-status evidence จากผู้ดูแล ไม่สร้างชื่อ feature ขึ้นเอง

### 7.5 วิเคราะห์อาการ

| อาการ | จุดที่ต้องตรวจต่อ | หลักฐานที่ควรเก็บ |
|---|---|---|
| หา hostname ไม่พบ | DNS, VPN, hostname ที่ได้รับ | resolver error และเวลาที่เกิด |
| Port ติดต่อไม่ได้ | route, firewall, service, port จริง | connectivity result จาก execution host |
| ติดต่อ server ได้แต่ checkout ไม่ได้ | daemon, feature, entitlement, compatibility | ข้อความปฏิเสธเต็มจาก tool |
| No license available/queue | จำนวน seat และผู้ใช้งานตามสิทธิ์ | queue/status และเวลา |
| L-Edit เปิดได้ แต่ synthesis ล้มเหลว | engine path, platform, license, input | engine startup log |
| GUI ได้ แต่ remote engine ไม่ได้ | environment/network ของ remote job | job environment และ remote log |
| Feature/version mismatch หรือ expired | entitlement และช่วง version/วันหมดอายุ | error code และ release/build |

ไม่ restart license server, force-release seat ของผู้อื่น หรือแก้ license file เพื่อแก้ปัญหาในห้องฝึก ให้ส่งข้อมูลที่จำเป็นแก่ผู้ดูแล

## 8. ขั้นที่ 5 — ตรวจ library views ก่อนรัน

### 8.1 จัดทำ view matrix

ข้อมูลแต่ละชนิดมีหน้าที่ต่างกัน และไม่จำเป็นต้องมีทุกชนิดสำหรับทุกขั้นตอน:

| View/data | หน้าที่ | ตรวจใน Lab 1 |
|---|---|---|
| Liberty `.lib` หรือรูปแบบที่ engine รองรับ | function, timing, power, operating conditions | library/cell/pin, units, corner, read log |
| Technology LEF หรือ technology data ของ flow | routing layers, via, site และหน่วย | layer/stack/site/DBU ที่ถูกใช้จริง |
| Cell/macro LEF | abstract boundary, pins, obstructions | macro names, size, site, pin geometry |
| OA layout / GDS / OASIS ตาม flow | geometry จริงและ hierarchy | master resolution, layer map, units, boundary |
| Verilog simulation models | behavior ของ mapped cells สำหรับ GLS | module/pin/PG convention, compile compatibility |
| SPICE/CDL หรือ LVS reference ที่ deck ใช้ | device/connectivity reference | subcircuit names, pin order, globals |
| RC technology/configuration | parasitic estimation/extraction | layer mapping และ RC corner ที่เลือก |
| DRC/LVS decks ถ้ารวมในหลักสูตร | physical/electrical verification | deck revision, tool compatibility, license scope |

การมี analog PDK ที่เปิด layout ได้ไม่ยืนยันว่ามี standard-cell timing library, abstract views และ flow setup ที่พร้อมสำหรับ TDI และการรองรับ format ไม่เท่ากับการที่ PDK นั้นผ่าน qualification กับ release ที่ใช้อยู่

### 8.2 ตรวจ library identity

1. ระบุชื่อ foundry/process, PDK release, standard-cell family และ release
2. ระบุ metal stack ที่เลือก รวมตัวเลือกที่เกี่ยวกับ routing/via
3. บันทึก path ของไฟล์ที่ project อ้างอิงจริง
4. ตรวจ symbolic links, search path และไฟล์ชื่อซ้ำจากหลาย release
5. อ่าน loaded-library log เพื่อยืนยันว่า tool ใช้ไฟล์เดียวกับที่ตรวจ
6. เก็บ hash ของไฟล์สำคัญหรือ manifest ของ release

ตัวอย่าง PowerShell หลังตั้ง `$labRoot` ตามขั้นที่ 1:

```powershell
Get-ChildItem -LiteralPath (Join-Path $labRoot 'reference_copy') -File -Recurse |
    Get-FileHash -Algorithm SHA256 |
    Export-Csv -NoTypeInformation -Encoding utf8 -LiteralPath (
        Join-Path $labRoot 'audit\reference_input_sha256.csv'
    )
```

อย่าใช้ทั้งโฟลเดอร์ run เป็น input hash เพราะ output เปลี่ยนทุกครั้ง และอย่าเปิดเผยหรือแจกจ่าย library นอกสิทธิ์การใช้งาน

### 8.3 ตรวจ cell identity ข้าม views

เลือกอย่างน้อย inverter, buffer, NAND/NOR, D flip-flop และ physical-only cell ที่ flow ใช้ เช่น filler/tap/endcap พร้อม tie cell ถ้ามี

| Cell ที่เลือก | Liberty | LEF | Layout | Sim model | LVS reference | ผล |
|---|---|---|---|---|---|---|
| Inverter จริงของ library | … | … | … | … | … | … |
| Buffer จริงของ library | … | … | … | … | … | … |
| DFF จริงของ library | … | … | … | … | … | … |
| Tie cell ถ้า flow ใช้ | … | … | … | … | … | … |
| Physical-only cell ที่ flow ใช้ | ตามความจำเป็น | … | … | ตาม flow | ตาม LVS flow | … |

สำหรับทุก signal-bearing instance ใน mapped netlist ต้องมี logical/timing และ physical views ที่ flow ต้องการตามขั้นตอนจริง ส่วน physical-only cells อาจไม่มี Liberty function หรือ simulation model แบบ logic ปกติได้ ให้ตรวจตามวิธี export/verification ของ PDK ไม่บังคับว่าจำนวน cell ในทุก view ต้องเท่ากัน

### 8.4 ตรวจ pins, buses และ supplies

ตรวจรายละเอียดต่อไปนี้จากข้อมูลจริง:

- ชื่อ cell/module/macro/subcircuit ตรงกัน รวมตัวพิมพ์เล็ก–ใหญ่
- Signal pins มีชื่อและ direction ที่สอดคล้องกัน และมี documented mapping ถ้ารูปแบบต่างกัน
- Bus ใช้ `data[7]`, `data<7>` หรือรูปแบบอื่นอย่างไร และ importer จัดการได้ถูกต้องหรือไม่
- Pin order ของ SPICE/CDL ตรงกับ reference ที่ LVS ใช้
- PG pins ใน Liberty, LEF/layout และ netlist มีความสัมพันธ์ถูกต้อง
- Global nets เช่น `VDD!` หรือ `VSS!` มี mapping ตาม flow และไม่ถูกสันนิษฐานว่าเท่ากับ `VDD`/`VSS` อัตโนมัติ
- Verilog model ใช้ explicit supply ports, conditional power-pin defines หรือ internal supplies แบบใด
- ถ้ามีหลาย voltage domain ต้องมี mapping และข้อกำหนดพิเศษครบ ไม่ใช้ global connect แบบเหมารวมข้าม domain

ตัวอย่าง supply contract สำหรับกรอกข้อมูล ไม่ใช่ชื่อที่ต้องใช้กับทุก PDK:

| ความหมาย | Top-level net | Stdcell PG pin | Global/alias rule | ผู้กำหนด |
|---|---|---|---|---|
| Digital supply | … | … | … | PDK/flow configuration |
| Digital ground | … | … | … | PDK/flow configuration |
| Well/bulk ถ้ามี | … | … | … | PDK verification guide |

ข้อความใน layout ที่เขียนว่า VDD ไม่รับรอง connectivity ต้องมี pin/net/database หรือ extraction evidence ตามขั้นตอนตรวจที่เกี่ยวข้อง

### 8.5 ตรวจหน่วยและ geometry

1. อ่าน time/capacitance units จาก timing library และ report ของ tool
2. ตรวจหน่วยของ SDC จาก command context และ timing report ไม่เดาว่าทุก flow ใช้ ns
3. ตรวจ LEF units, layout database units และ stream-import units
4. เปิด master cell ใน L-Edit วัดขนาดแล้วเทียบกับ abstract boundary
5. ตรวจ site, row height, legal orientations และ routing layer names
6. ตรวจ pin shapes อยู่บนชั้นที่ flow รู้จัก และไม่หายจาก layer mapping
7. ตรวจ power rails และ physical-only cell boundary ตาม library integration guide

ขนาด boundary อาจมีความต่างตาม abstract convention ให้เทียบกับ tolerance/ข้อกำหนดของ library ห้ามตัดสินว่าผิดจากภาพเพียงอย่างเดียว ความต่าง 1,000 เท่าเป็นสัญญาณที่ควรตรวจ units/scale ทันที

### 8.6 ตรวจ corner อย่างมีความหมาย

แยก **PVT timing corner** ออกจาก **RC corner** โดยบันทึก process, operating voltage, temperature, timing library set และ extraction setting ที่เลือกจริง อย่าเรียกทุกชุดรวมกันว่า “slow corner” แล้วละรายละเอียด

ใน Lab 1 อาจรันเพียงหนึ่ง scenario ตาม reference เพื่อยืนยัน environment ได้ แต่ต้องระบุว่าไม่ได้ครอบคลุม MMMC sign-off และไม่อนุมานว่า slow=max RC หรือ fast=min RC ใช้ได้กับทุก path โดยอัตโนมัติ

**เกณฑ์ผ่าน:** required views โหลดได้ resolve masters ได้ pins/PG/units/technology สัมพันธ์กันตาม scope และไม่มี mismatch ที่ยังไม่อธิบาย

## 9. ขั้นที่ 6 — เปิดและตรวจ reference project

1. อ่าน README และ baseline report ก่อนเปลี่ยนค่าใด ๆ
2. เปิดสำเนา project ผ่านวิธีที่ release รองรับ
3. ระบุ top cell/module/entity และ language mode
4. ตรวจ source file order, include paths, defines, parameters/generics และ constraints
5. ตรวจ timing/physical libraries และ technology settings ที่ผูกไว้
6. ตรวจ working directory และ output prefix ให้เป็น run ใหม่
7. ตรวจ clock, voltage และ corner ตรงกับ baseline
8. ตรวจ synthesis/P&R settings, CTS cells และ physical-only cell configuration ถ้าเกี่ยวข้อง
9. บันทึก setup หรือ export scripts ด้วยวิธีที่ tool รองรับ
10. ยืนยันว่าไม่มี stale outputs ถูกนำมาแสดงแทน run ใหม่

สำหรับ VHDL ต้องตรวจ VHDL standard, package analysis order และ top entity/architecture สำหรับ Verilog/SystemVerilog ต้องตรวจ language mode, include และ defines อย่างชัดเจน การมี simulation ที่รับ VHDL ไม่ใช่หลักฐานว่า synthesis installation นี้รับ VHDL path ที่ต้องการด้วย

เริ่มจาก reference ที่ผู้สอนทดสอบแล้วก่อน หากเตรียม reference คู่ภาษา ให้รันแยกในคนละ directory และอย่า compile ทั้งคู่เป็น top เดียวกัน

## 10. ขั้นที่ 7 — รัน baseline และตรวจทีละ checkpoint

ใช้ปุ่ม Run/Launch หรือตัวเรียก flow ที่มากับ reference และ release นั้น ไม่ใช้ Tcl จากเครื่องมือยี่ห้ออื่นแทน command ของ Oasys/Nitro

เอกสาร Siemens อธิบาย reference flow ในลำดับ import, placement, clock, route และ export [2] แต่ชื่อไฟล์และขั้นย่อยใน installation จริงอาจต่างกัน ให้เก็บลำดับที่ใช้จริงในรายงาน

### 10.1 Checkpoint A — Startup และ input import

ตรวจ:

1. Run timestamp และ output directory เป็นรอบใหม่
2. Engine version/build และ execution host ถูกต้อง
3. License ผ่านหรือ engine เริ่มทำงานจริงได้
4. Loaded source/library/technology paths ตรงกับ manifest
5. Top และ port list ถูกต้อง
6. ไม่มี file-not-found, unsupported format, unresolved reference หรือ fatal error

หยุดหากเป็น input สำคัญหาย ไม่ควรปล่อยให้ flow สร้างผลต่อด้วย black box โดยไม่ตั้งใจ

### 10.2 Checkpoint B — Elaboration และ synthesis

ตรวจ top, port widths, register count, mapped cell count, sequential/combinational cells, unresolved cells, unintended latches และ synthesis check messages

ตรวจว่า clock constraint ถูกอ่านและผูกกับ object ที่คาดหวัง รวม unconstrained endpoints ตาม scope ของ design อย่าใช้ WNS/TNS ที่ดูดีเป็นหลักฐานว่า constraints ครบ

เทียบ cell area กับ cell area ใน baseline ไม่เทียบกับ core area และหาก register ถูก optimize ทิ้งมากผิดปกติ ให้ตรวจ top, parameter, tie-off, output visibility และ source list ก่อนสรุปว่าเป็นผล optimization ที่ดีขึ้น

### 10.3 Checkpoint C — Floorplan และ power setup

ตรวจ block boundary/core area, placement rows, units, PG mapping, rails/straps และ required special cells ตาม reference

เปิด floorplan ได้ไม่ยืนยันว่า PDN ต่อครบ หาก flow มี connectivity check ให้ตรวจผลตาม scope และเก็บ error location เมื่อพบปัญหา

### 10.4 Checkpoint D — Placement และ CTS

ตรวจ placement legality, overlap/out-of-bound instances, congestion, CTS execution และ clock reports ตาม baseline

หาก reference ตั้งใจหยุดก่อน CTS ให้บันทึก CTS เป็น NOT TESTED การมี clock buffers อยู่ใน layout ไม่ยืนยัน clock connectivity หรือ timing closure

### 10.5 Checkpoint E — Routing และ export

ตรวจ route completion, unresolved/unrouted nets, exported netlist/layout/database, top name และจำนวน/ชนิด cells ที่คาดหวัง

รอจน engine จบและตรวจ final log ไม่ถือว่ามี output file แล้วแปลว่ารันสำเร็จ เพราะไฟล์อาจถูกเขียนก่อน fatal error หรือเป็นไฟล์เก่า

### 10.6 ตารางบันทึก run

| Checkpoint | Expected | Observed | Evidence | Status |
|---|---|---|---|---|
| Startup/license | Engine เริ่มตาม reference | … | log และเวลา | … |
| Input import | Top/views resolve | … | import log | … |
| Synthesis | Mapping/check ตาม baseline | … | synthesis report | … |
| Constraints | Clock/coverage ตาม reference | … | constraint report | … |
| Floorplan/PG | Geometry/net mapping ถูกต้อง | … | database/check report | … |
| Placement/CTS | ผ่านตามขอบเขตรัน | … | report | … |
| Routing/export | งานจบและ outputs ครบ | … | final log/output list | … |
| Reopen | เปิดผลใหม่ใน L-Edit ได้ | … | view identity/inspection | … |

หากเครื่องมือไม่มี report บางชนิด ให้บันทึกวิธีตรวจอื่นที่ใช้ได้จริง พร้อมข้อจำกัด ไม่สร้าง report name หรือ PASS ขึ้นมา

## 11. ขั้นที่ 8 — เปิดผลกลับใน L-Edit

1. เปิด output ที่ flow ระบุว่าเป็น final layout/database ใน run ล่าสุด
2. ตรวจชื่อ top, เวลา export และ output path
3. ตรวจ hierarchy และ unresolved masters
4. Fit view แล้วตรวจขนาด boundary เทียบกับ floorplan report
5. Zoom ที่ standard-cell rows และเปิด master อย่างน้อยหนึ่งตัว
6. ตรวจ signal routing, PG routing และ clock network ตาม scope ที่รัน
7. ตรวจ layers หลัง import ว่าตรงกับ technology และ layer map
8. ตรวจ signal/supply pins ตาม pin list และ export convention
9. บันทึกผลเปิดกลับและสิ่งที่ยังไม่ได้ตรวจ

ถ้าเห็นเพียงกรอบหรือ instance boxes ให้ตรวจว่าเปิด abstract view, ปิด visibility, master library ไม่ถูกผูก หรือ stream export ไม่ได้รวม cell geometry ตาม convention อย่าแก้ด้วยการวาด geometry ชดเชยด้วยมือ

**เกณฑ์ผ่าน:** เปิดผล run ใหม่ได้พร้อม technology/hierarchy ที่ resolve และไม่มีความผิดปกติที่อธิบายไม่ได้ การเปิดผลได้ยังไม่รับรอง foundry DRC/LVS, complete STA หรือ tapeout readiness

## 12. ตัวอย่าง RTL คู่ภาษาเพื่อใช้ตรวจ frontend เพิ่มเติม

ตัวอย่างนี้เป็น counter 8 บิตที่มี synchronous active-high reset และ enable ใช้หลัง reference baseline ผ่านแล้ว หรือให้ผู้สอนนำไปสร้าง reference ที่ผ่านการทดสอบก่อนอบรม ไม่ใช้แทน vendor reference โดยอัตโนมัติ

พฤติกรรม: ที่ rising edge ของ `clk` ถ้า `rst=1` ให้ `q=0`; ถ้าไม่ reset และ `en=1` ให้เพิ่มหนึ่งแบบ modulo 256; นอกนั้นคงค่าเดิม ไม่มี asynchronous reset และไม่สร้าง gated clock

### 12.1 VHDL

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audit_counter is
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    en  : in  std_logic;
    q   : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of audit_counter is
  signal count : unsigned(7 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        count <= (others => '0');
      elsif en = '1' then
        count <= count + 1;
      end if;
    end if;
  end process;
  q <= std_logic_vector(count);
end architecture;
```

### 12.2 Verilog-2001

```verilog
module audit_counter (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,
    output reg  [7:0] q
);
    always @(posedge clk) begin
        if (rst)
            q <= 8'h00;
        else if (en)
            q <= q + 8'd1;
    end
endmodule
```

### 12.3 SystemVerilog

```systemverilog
module audit_counter (
    input  logic       clk,
    input  logic       rst,
    input  logic       en,
    output logic [7:0] q
);
    always_ff @(posedge clk) begin
        if (rst)
            q <= 8'h00;
        else if (en)
            q <= q + 8'd1;
    end
endmodule
```

เลือก source เพียงภาษาหนึ่งต่อ run ทั้งสามเวอร์ชันไม่มีการกำหนด power-up value ต้องมี rising edge ที่ reset เป็นหนึ่งก่อนใช้ค่าผลลัพธ์ที่คาดหวัง

### 12.4 Timing contract ตัวอย่าง

สมมติ time unit ที่ยืนยันใน tool แล้วเป็น ns: clock period 20 ns, input delay 2 ns, output delay 3 ns, input transition 0.2 ns และ clock uncertainty 0.2 ns เป็นเพียงค่าฝึก ไม่ใช่ข้อกำหนดของ PDK หรือชิปจริง

```tcl
# ตัวอย่าง SDC: ตรวจ syntax/units กับ engine release ก่อนใช้
create_clock -name CLK -period 20.0 [get_ports clk]
set_clock_uncertainty 0.2 [get_clocks CLK]
set_input_delay -max 2.0 -clock CLK [get_ports {rst en}]
set_input_delay -min 0.0 -clock CLK [get_ports {rst en}]
set_output_delay -max 3.0 -clock CLK [get_ports {q*}]
set_output_delay -min 0.0 -clock CLK [get_ports {q*}]
set_input_transition 0.2 [get_ports {rst en}]
```

ก่อนใช้ต้องตรวจว่า collections จับ `clk`, `rst`, `en` และ q ทั้ง 8 บิตจริง ไม่ใช้ wildcard แล้วถือว่าถูกต้องเสมอ กำหนด output load ตาม cap units และ reference environment ของ library เพิ่มให้ครบ หากยังไม่ได้กำหนด ให้บันทึกข้อจำกัด ห้ามเรียกว่า timing contract สมบูรณ์

`rst` เป็น synchronous input จึงไม่ใส่ false path เพียงเพราะชื่อ reset และค่า min delay ศูนย์เป็นสมมติฐานสำหรับตัวอย่างฝึก ต้องเปลี่ยนตาม external timing ในงานจริง

### 12.5 ผลที่คาดหวัง

- Elaboration มี state 8 บิตและ feedback สำหรับ enable
- ไม่มี unintended latch, unresolved module หรือ combinationally gated clock
- Reset ใช้กลไก synchronous ตาม RTL โดย implementation จริงอาจเป็น DFF ที่มี synchronous reset หรือ logic บน D input
- จำนวน cells/area ของคู่ภาษาอาจต่างได้จาก optimization; ไม่ใช้ความเท่ากันแบบตัวเลขเป็นหลักฐาน equivalence
- หากต้องยืนยัน function ข้ามภาษา ให้ใช้ self-checking testbench/reference behavior หรือ equivalence flow ที่รองรับ ซึ่งเป็นงานต่อเนื่องของ functional verification

## 13. ขั้นที่ 9 — Controlled negative test

หลัง baseline ผ่าน ให้ทำในสำเนา project และเลือกหนึ่งกรณีที่ย้อนกลับได้:

1. เปลี่ยน path ของ **สำเนา configuration** ให้ชี้ Liberty ที่ไม่มีอยู่ แล้วตรวจว่าระบบรายงาน missing input ชัดเจน
2. หรือเปลี่ยนชื่อ top ให้ไม่มีอยู่ แล้วตรวจ elaboration error
3. เก็บข้อความผิดพลาดและ checkpoint ที่หยุด
4. คืนค่า configuration ให้ตรง baseline
5. รันซ้ำถึง checkpoint ที่เคยล้มเหลวเพื่อยืนยันการคืนค่า

ห้ามแก้ shared PDK, shared license หรือไฟล์ต้นฉบับเพื่อทำ negative test เป้าหมายคือยืนยันว่า audit อ่าน failure ได้จริง ไม่ใช่ทดสอบว่าระบบจะยอมข้าม input ที่หายหรือไม่

## 14. Troubleshooting แบบแยกสาเหตุ

| ปัญหา | สาเหตุที่ต้องพิสูจน์ | ขั้นตอนตรวจต่อ |
|---|---|---|
| GUI เปิดได้ แต่ไม่มีคำสั่ง TDI | component/edition/integration ไม่ตรง | ตรวจ installed components และ Help ของ release |
| เริ่ม engine ไม่ได้ | executable, dependency, execution host, permission | ตรวจ launcher command และ startup stderr |
| หา RTL ไม่พบ | relative path/working directory/remote mapping | ตรวจ resolved path ใน engine log |
| Unknown cell หลัง synthesis | source/library search path หรือ unresolved module | ตรวจ source list และ loaded libraries |
| Missing master ใน P&R | mapped cell ไม่มี physical abstract | เทียบ netlist cells กับ LEF/OA master list |
| Master ซ้ำ | library aliases หรือหลาย release ปะปน | ตรวจ search order และ canonical paths |
| ไม่มี routing layers/site | technology data ไม่ครบหรือไม่ตรง | ตรวจ technology import และ site mapping |
| Layout เล็ก/ใหญ่ผิดปกติ | units หรือ layer/stream setup | เทียบ boundary dimensions และ DBU |
| PG pins ไม่ต่อ | naming/mapping/global rules ไม่ตรง | ตรวจ PG contract และ connectivity report |
| Simulation หา model ไม่พบ | model list/defines/power ports ไม่ครบ | ตรวจ simulation compile ซึ่งแยกจาก synthesis |
| Timing ดูผ่านแต่ไม่มี clocks | constraints ไม่ถูกอ่านหรือ collection ว่าง | ตรวจ clock report และ unconstrained endpoints |
| Report ต่าง baseline มาก | version/corner/config/input เปลี่ยน | เทียบ manifest และ startup/loaded paths |
| งานถูก kill โดยไม่มี tool fatal | OOM, scheduler, quota, walltime | ตรวจ job/system logs ที่ได้รับสิทธิ์ |
| เปิดผลแล้วเหมือนเดิม | stale output หรือผิด top/view | ตรวจ run ID, export timestamp และ path |

แก้ทีละปัจจัยและรัน checkpoint ที่เกี่ยวข้องใหม่ หลีกเลี่ยงการเปลี่ยน clock, utilization, library และ engine version พร้อมกัน เพราะจะสูญเสียความสามารถในการระบุสาเหตุ

## 15. เกณฑ์การยอมรับและสถานะ

### 15.1 นิยามสถานะ

- **PASS:** มีหลักฐานว่าข้อกำหนดที่ระบุผ่านจริง
- **FAIL:** ทำการทดสอบแล้วพบพฤติกรรมผิดจากข้อกำหนด
- **BLOCKED:** ทดสอบต่อไม่ได้เพราะ dependency/สิทธิ์/ทรัพยากรหรือข้อมูลยังไม่พร้อม
- **NOT TESTED:** อยู่นอก scope หรือยังไม่ได้ทดสอบ ห้ามแปลงเป็น PASS

### 15.2 Acceptance checklist

| ID | ข้อกำหนด | หลักฐาน |
|---|---|---|
| EA-01 | ระบุ tools/build/OS/execution hosts ครบ | environment inventory |
| EA-02 | GUI เปิด reference และ technology ถูกต้อง | project/cell/view evidence |
| EA-03 | Synthesis และ P&R เริ่มงานจริงได้ตาม scope | startup/license evidence ของแต่ละ engine |
| EA-04 | Input และ required views resolve ครบ | manifest และ loaded-library logs |
| EA-05 | Constraints ถูกอ่านและ coverage ตรง baseline | clock/constraint checks |
| EA-06 | Reference จบถึง checkpoint เป้าหมาย | final status/report ไม่มี unexplained fatal |
| EA-07 | เปิดผลใหม่กลับใน L-Edit ได้ | output identity และ layout inspection |
| EA-08 | ตรวจ pin/PG/unit/corner mapping แล้ว | view matrix และ contract |
| EA-09 | Negative test ตรวจพบและคืนค่าได้ | failure evidence และ rerun |
| EA-10 | บันทึก warnings/limitations/owner ครบ | audit summary |

หาก scope คือ full reference implementation ต้องผ่าน synthesis/P&R/export/reopen ที่กำหนดครบ หากทำเพียง GUI/import audit ให้รายงานสถานะตามนั้นและระบุ downstream stages เป็น NOT TESTED ไม่ใช้ชื่อ “RTL-to-GDSII ready” แบบครอบคลุม

ผล audit ไม่ใช่การอนุมัติ tapeout การรับรอง DRC/LVS/STA/sign-off ต้องทำด้วย decks, scenarios และเกณฑ์ที่ผู้รับงานยอมรับในบทต่อไป

## 16. สิ่งส่งมอบของผู้เรียน

ส่งโฟลเดอร์รายงานที่มีข้อมูลดังนี้ โดยอ้างอิง PDK ตามสิทธิ์ ไม่แจกไฟล์ proprietary ทั้งชุด:

1. `environment_audit.md` — สรุปเครื่อง/tool/build/host/scope/status
2. `input_manifest.csv` — input paths/revisions/hashes ที่อนุญาตให้แชร์
3. `library_view_matrix.csv` — selected cells, required views, pins/PG/units/corners
4. `baseline_comparison.csv` — expected/observed metrics พร้อมชื่อ report
5. Logs และ reports ของ reference run ตามข้อกำหนดการอบรม
6. หลักฐานการเปิด final layout กลับ และ controlled negative test
7. Known issues พร้อม severity, owner และ next action

### 16.1 แบบสรุปที่พร้อมกรอก

```text
Lab: 01 Environment audit
Run ID:
Operator / date:
Scope tested:
Reference revision:
L-Edit version/build:
Synthesis version/build/host:
P&R version/build/host:
PDK / stdcell / metal stack:
PVT / RC configuration:
License checkout evidence:
Source/top/constraints evidence:
Required views loaded:
Final completed checkpoint:
Reopened output path/top/view:
Comparison against baseline:
Negative test and restoration:
Unexplained errors/warnings:
Not tested:
Overall status and justification:
Issue owner / next action:
```

### 16.2 คำถามทบทวน

1. ทำไมเปิด L-Edit ได้จึงยังไม่ยืนยันว่า synthesis/P&R ใช้ได้?
2. TCP port ติดต่อได้แต่ checkout ไม่ได้ เกิดจากอะไรได้บ้าง และต้องเก็บหลักฐานใด?
3. ทำไม Liberty และ LEF จึงใช้แทนกันไม่ได้?
4. ทำไม filler ไม่จำเป็นต้องมี logic model เหมือน inverter?
5. จะพิสูจน์อย่างไรว่า engine โหลด library release ที่ต้องการจริง?
6. ถ้า output file มีอยู่ แต่ final log ระบุ fatal error ควรรายงานสถานะอย่างไร?
7. ทำไม RTL reset แบบ synchronous จึงไม่ควรถูกตั้ง false path โดยอัตโนมัติ?
8. PVT corner ต่างจาก RC corner อย่างไร และหนึ่ง reference run ยืนยันอะไรได้บ้าง?
9. ถ้า reference ไม่มี baseline ที่ผ่านแล้ว สิ่งใดควรเป็น BLOCKED?
10. หลักฐานใดต้องเพิ่มก่อนเปลี่ยนคำว่า environment audit ผ่าน เป็น design sign-off ผ่าน?

## 17. เอกสารอ้างอิงและข้อกำหนดเฉพาะ release

แหล่งผลิตภัณฑ์สาธารณะใช้ยืนยันโครงสร้างระบบ ส่วนคำสั่ง เมนู platform และ license configuration ที่ใช้จริงต้องอิงคู่มือของ release ที่ติดตั้ง

1. Siemens, **Digital Implementation** — ภาพรวม L-Edit wizard, Oasys synthesis และ Nitro P&R: https://eda.sw.siemens.com/en-US/ic/ic-custom/ams/digital-implementer/
2. Siemens, **A full-flow solution for analog/mixed-signal IC design** — ส่วน digital implementation และ reference flow: https://static.sw.cdn.siemens.com/siemens-disw-assets/public/1xqViRATpGkS6iFOXguaxE/en-US/Siemens-SW-Full-flow-solution-for-analog-mixed-signal-IC-design-WP-84095-D9.pdf
3. Siemens Customer Center/Support — ใช้เข้าถึง Installation Guide, release notes, Licensing Manual, Oasys/Nitro command reference และ compatibility information ตาม entitlement: https://customer.sw.siemens.com/
4. PDK/library integration guide ของ release เป้าหมาย — ผู้สอนต้องเติมชื่อเอกสาร revision และตำแหน่งเข้าถึงภายในก่อนใช้งาน

ตรวจแหล่งสาธารณะสำหรับการจัดทำบทวันที่ 16 ตุลาคม 2026; เอกสารสาธารณะไม่ใช้แทน release-specific qualification ของ installation ในห้องอบรม
