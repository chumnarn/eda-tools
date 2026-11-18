## ภาคผนวก

### ภาคผนวก ก — กับดักที่วัดได้จริงบนเครื่องนี้

ทุกข้อในตารางนี้ **เกิดขึ้นจริง** ระหว่างทำคู่มือนี้ ไม่ใช่ข้อควรระวังทั่วไป
แต่ละข้อมีวิธีตรวจสอบและวิธีแก้ให้พร้อมกัน

#### C.1 `info script` ในไฟล์ `.do` คืนค่าผิด — ทำให้ QuestaSim crash

| | |
|---|---|
| **อาการ** | `vsim.exe : ** Fatal: Exiting VSIM license process.` แล้ว process ตายด้วยรหัส `3221225477` (0xC0000005, access violation) |
| **สาเหตุ** | เมื่อสั่ง `do file.do` ตัว `info script` ของ Tcl จะคืนค่า **path ของตัว vsim** ไม่ใช่ไฟล์ `.do` |
| **ตัวอย่าง** | `cd [file normalize [file dirname [info script]]]` → `cd` เข้า `C:/mtitcl/vsim` (โฟลเดอร์ของตัวโปรแกรม) แล้วพัง |
| **วิธีตรวจ** | พิมพ์ `puts [info script]` ในไฟล์ `.do` → จะได้ `C:/mtitcl/vsim/vsim` |
| **วิธีแก้** | ใช้ `source file.do` แทน `do file.do` — `source` ทำให้ `info script` คืน path ของไฟล์จริง |

```tcl
# do  -> info script = C:/mtitcl/vsim/vsim   (ผิด)
# source -> info script = C:/path/to/your/file.do   (ถูก)
```

> คู่มือนี้เลือกใช้แนวทางที่ปลอดภัยกว่า คือ **ไม่พึ่ง `info script` เลย**
> ทุกสคริปต์ `.do` ต้องรันจากโฟลเดอร์ของ lab (ทำโดย `run.cmd` ที่ `cd /d "%~dp0"`)
> และมี guard ตรวจว่าอยู่ในโฟลเดอร์ที่ถูกต้อง

#### C.2 ภาษาไทยในไฟล์ `.cmd` ทำให้ `cmd.exe` พังโครงสร้างบรรทัด

| | |
|---|---|
| **อาการ** | `'<ภาษาไทย>' is not recognized as an internal or external command` และบรรทัดถัดไปเสียไปด้วย (เช่น `echo` กลายเป็น `cho`) |
| **สาเหตุ** | `cmd.exe` อ่านไฟล์ `.cmd` ตาม code page ของ console (ไม่ใช่ UTF-8) ไบต์ภาษาไทยจึงกินตัวอักษรแรกของบรรทัดถัดไป |
| **วิธีแก้** | ให้ไฟล์ `.cmd` เป็น **ASCII ล้วน** เขียนคำอธิบายภาษาไทยไว้ใน `rem` ที่เป็น ASCII หรือย้ายไปไว้ในคู่มือ |

ตรวจสอบด้วย PowerShell ก่อน commit ไฟล์

```powershell
Get-ChildItem -Recurse -Include *.cmd | ForEach-Object {
  $n = 0
  foreach ($line in [System.IO.File]::ReadAllLines($_.FullName)) {
    $n++
    if ($line -match '[^\x00-\x7F]') { "$($_.FullName):$n : $line" }
  }
}
```

#### C.3 วงเล็บที่ไม่ escape ใน `echo` ที่อยู่ใน `if` block

| | |
|---|---|
| **อาการ** | สคริปต์หยุดทันที **โดยไม่มีข้อความแม้แต่บรรทัดเดียว** และ exit code = 1 |
| **สาเหตุ** | `cmd.exe` มอง `(` ในข้อความว่าเป็นการเปิด block ใหม่ ทำให้ syntax เพี้ยน |
| **ตัวอย่าง** | `echo [RESULT] FAIL  (no result file)` ภายใน `if (...)` → พัง |

วิธีแก้: เขียนข้อความให้ไม่มีวงเล็บ หรือ escape ด้วย `^(` และ `^)`

#### C.4 `vsim` คืน exit code 0 แม้แต่เปิดไฟล์ `.do` ไม่ได้

| | |
|---|---|
| **อาการ** | สคริปต์ batch รายงานว่า PASS ทั้งที่ไม่มีอะไรรันจริง |
| **สาเหตุ** | `vsim -c -do "do ไม่มีไฟล์.do"` พิมพ์ `Cannot open macro file: ...` แล้วจบด้วยรหัส 0 |
| **วิธีแก้** | ให้ testbench เขียนผลลงไฟล์ `result.txt` แล้วให้สคริปต์อ่านไฟล์นั้น (ไม่พึ่ง exit code อย่างเดียว) |

#### C.5 ใน `for %%V in (...)` เครื่องหมาย `=` ถูกตีความเป็นตัวคั่นคู่ `var=value`

| | |
|---|---|
| **อาการ** | รายการที่ตั้งใจจะเป็น 1 ชิ้น กลายเป็นหลายชิ้น |
| **สาเหตุ** | ภาษาของ `for` รองรับรายการรูปแบบ `ตัวแปร=ค่า` จึงตัดข้อความที่มี `=` ออกเป็นคนละชิ้น |
| **วิธีแก้** | อย่าใช้ `=` เป็นตัวคั่นข้อมูลในรายการของ `for` — แยกกรณีพิเศษออกไปเป็น `if` แทน |

#### C.6 ไฟล์ `.vhd` ที่มี BOM (UTF-8 with BOM) คอมไพล์ไม่ได้

| | |
|---|---|
| **อาการ** | `** Error: tb/tb_timer.vhd(1): near "?": syntax error` |
| **สาเหตุ** | BOM (3 ไบต์ `EF BB BF`) ที่หัวไฟล์ถูกตัวคอมไพล์อ่านเป็นอักขระผิด |
| **วิธีแก้** | บันทึกเป็น UTF-8 **ไม่มี BOM** |

```powershell
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($path, $text, $enc)
```

#### C.7 ภาษาไทยใน string literal ของ VHDL ใช้ไม่ได้

| | |
|---|---|
| **อาการ** | `** Error: (vcom-1576) String literal has a character with value 0x95 not in the enumeration type std.STANDARD.CHARACTER.` |
| **สาเหตุ** | string literal ของ VHDL ประกอบด้วยอักขระ `CHARACTER` (Latin-1) เท่านั้น |
| **วิธีแก้** | ใช้ภาษาไทยได้ใน **comment** เท่านั้น ใน `report`/`assert` ให้ใช้ภาษาอังกฤษ |

#### C.8 `const` เป็นคำสงวนใน VHDL-2008

```vhdl
procedure write_result(const fname : in string; ...)   -- ผิด
-- ** Error: near "fname": (vcom-1576) expecting ':'.
procedure write_result(constant fname : in string; ...) -- ถูก
```

#### C.9 `writeline` ต้องการ `line` ไม่ใช่ `string`

```vhdl
writeline(f, verdict);      -- ผิด : (vcom-1600) No feasible entries for subprogram "WRITELINE"
write(l, verdict);
writeline(f, l);            -- ถูก
```

#### C.10 `std_logic_vector` ไม่มีตัว `+`

```vhdl
tmp := ('0' & unsigned(a)) + ('0' & unsigned(b));   -- ผิด : ผสมสองชนิด
tmp := ('0' & unsigned(a)) + unsigned('0' & unsigned(b));  -- ถูก
```

#### C.11 `bus` เป็นคำสงวนของ VHDL

ตั้งชื่อ signal ว่า `bus` ไม่ได้ → ใช้ `data_bus` แทน

#### C.12 `string(0 to n)` ใช้ไม่ได้

`STRING` ถูกนิยามเป็น `array (POSITIVE range <>) of CHARACTER`
ดังนั้น index ต้องเป็นบวกเสมอ ใช้ `string(1 to n)`

#### C.13 array ของ unconstrained string ต้องมีความยาวเท่ากันทุกช่อง

```vhdl
type note_array is array (natural range <>) of string;
constant NOTES : note_array := ("ADD ok", "SUB exposes the bug");  -- ผิด
-- ** Error: (vcom-1622) Unconstrained subelements cannot be of different sizes.
```

ทางออกที่ดีกว่า: ใช้ enumerated type + ฟังก์ชันแปลงเป็น string

```vhdl
type note_id_t is (N_ADD, N_SUB, N_AND, N_OR);
function note_text(n : note_id_t) return string is ...
```

#### C.14 `use` clause เลือกได้เฉพาะ package

```vhdl
use ip_lib.ip_core.all;   -- ผิด : 'ip_core' is not a library or a package
```

และชื่อไลบรารีต้องประกาศก่อน

```vhdl
library ip_lib;            -- ต้องมีบรรทัดนี้
core : entity ip_lib.ip_core port map (...);
```

#### C.15 อย่าลบ `modelsim.ini` ระหว่าง session

ตัวจำลองโหลดไฟล์นี้ไว้ตั้งแต่ตอนเริ่ม ถ้าลบทิ้ง การคอมไพล์ที่อ้างไลบรารีอื่นจะ
ขึ้น `** Error: (vcom-1136) Unknown identifier "ip_lib".`

#### C.16 `vcd add` ต้องทำก่อน `run`

ถ้าทำหลัง ไฟล์ VCD จะมีแต่ header (1,310 bytes) ไม่มีค่าที่เปลี่ยนแปลง
ทำก่อนจะได้ 3,219 bytes

#### C.17 `wlf2vcd` เปิดไฟล์ WLF ไม่ได้ระหว่างจำลอง

```text
** Error: Unable to open WLF file "vsim.wlf".
```

ต้องรอให้ simulator ปิดตัวลงก่อน

#### C.18 `severity failure` ทำให้สคริปต์ `.do` ถูกรันซ้ำ

เมื่อ testbench หยุดด้วย `severity failure` ระหว่าง `run -all`
ModelSim จะ abort สคริปต์ปัจจุบัน แล้ว **เริ่มรายการคำสั่ง `-do` ใหม่ตั้งแต่ต้น**
(ตรวจได้จาก log ที่มีบรรทัด `# do run_batch.do` ซ้ำ)

ทางแก้ที่ใช้ในคู่มือนี้: ห่อ `run -all` ด้วย `catch` และให้ testbench เป็นคนเขียนผล

#### C.19 `examine` ในโหมด console ไม่พิมพ์ผลลัพธ์

ต้องเก็บค่าที่คืนมาแล้ว `puts` เอง

```tcl
set v [examine -radix hex -value /tb_alu/dut/y]
puts "  y = $v"
```

#### C.20 `[time]` ชนกับคำสั่ง `time` ของ Tcl

```tcl
puts "stopped at [time]"     -- ** Error: wrong # args: should be "time command ?count?"
puts "stopped at $::now"     -- ถูก
```

#### C.21 license ถูกเช็คตอน “โหลด design” เท่านั้น

`vsim -c -do "quit -f"` ไม่ดึง license ต้องคอมไพล์แล้วโหลด design จริงจึงจะเจอข้อความ
"License checkout has been disallowed" — ตัว `run.cmd` ใช้หลักการนี้ในการเลือกชุดติดตั้ง

#### C.22 `=` ไม่แพร่ค่า X

ตัวเปรียบเทียบของ IEEE 1164 คืน `FALSE` เมื่อ operand มี `X`/`U`
ต้องใช้ตัวบิต (`xor`/`and`/`or`) หรือ `is_x()` ถ้าต้องการให้ X แพร่

#### C.23 คำสั่ง `mem` ใน 2026.1 ไม่มี `mem export`

คำสั่งที่มีคือ `mem compare`, `mem display`, `mem list`, `mem load`, `mem save`, `mem search`
ใช้ `mem save` แทน `mem export`

#### C.24 QuestaSim GUI ที่เปิดค้างไว้ จะบล็อก QuestaSim แบบบรรทัดคำสั่ง

วัดได้จริงบนเครื่องนี้: ขณะที่ QuestaSim GUI (`vish.exe -gui`, ชื่อหน้าต่าง
“Questa Sim-64 2026.1”) ยังเปิดอยู่ การรัน `vsim` ของชุด QuestaSim แบบบรรทัดคำสั่ง
จะได้ข้อความ

```text
** Error: License checkout has been disallowed because
only one session is allowed to run on an uncounted nodelocked
license and an instance of QuestaSim is already running with a
nodelocked license on this machine.
```

แต่ **ModelSim DE-64 ยังรันได้ตามปกติ** เพราะเป็นอีก seat หนึ่ง
ทางแก้คืออย่า hardcode path ของชุดใดชุดหนึ่ง แต่ให้สแกน license จริงก่อน
(ดู `tools/pick_tool.cmd`) แล้วเลือกชุดที่ใช้ได้

#### C.25 `uniform` อาจคืนค่าที่แปลงเป็น `integer` แล้วเกินช่วงของ bus

วัดได้จริง: seed `(777,888)` คืนค่าแรก `9.976514e-01`
`integer(u * 16.0)` จึงได้ **16** ซึ่งเกิน address bus 4 บิต
ถ้าเอาไป `to_unsigned(16, 4)` จะได้

```text
** Warning: NUMERIC_STD.TO_UNSIGNED: vector truncated
```

และที่อยู่จะกลายเป็น 0 **แบบเงียบ ๆ** — testbench ที่อ่านกลับ address เดิม
ยังผ่านอยู่ จึงเป็นบั๊กที่ checker แบบธรรมดาจับไม่ได้
แก้ด้วย `mod 16` ทุกครั้งที่แปลงค่าจาก `uniform` ไปเป็นจำนวนเต็ม

#### C.26 `variable a, b : positive := 777;` ให้ค่า 777 **ทั้งสองตัว**

ตัวแปรที่ประกาศรวดในบรรทัดเดียวจะได้ค่าเริ่มต้นเท่ากันหมด
ต้องประกาศแยกทีละตัวถ้าต้องการ seed สองค่าที่ต่างกัน

#### C.27 `read(l, s)` อ่าน `string` จาก `line` ต้องยาวเท่ากับที่เหลือของบรรทัด

ถ้าไม่ใช่จะได้

```text
** Error: (vsim-3549) String is not the length of the remaining line.
```

แก้โดยอ่านทีละตัวอักษรแล้วข้ายช่องว่าง (`read(l, c)`) หรือใช้ `hread`
ซึ่งรับ flag `good` มาบอกว่าอ่านได้หรือไม่

#### C.28 `transcript` ถูกล็อกเมื่อโหลด design ซ้ำ

ถ้าสคริปต์ `.do` โหลด design ครั้งที่สีด้วย `vsim` อีกครั้ง
ไฟล์ `transcript` จะถูกถือไว้ในโหมดเขียน แล้วอ่านไม่ได้
ทางแก้คือให้ **testbench เขียนผลลง `result.txt` เอง** แล้วให้สคริปต์
อ่านไฟล์นั้น (ดู Lab 08)

#### C.29 `run.cmd` ที่ไม่มี `cd /d "%~dp0"` จะหาไฟล์ `.do` ไม่เจอ

อาการคือ

```text
# Cannot open macro file: run_batch.do
```

และ `vsim` จะ **คืน exit code 0** พร้อมกับไม่มีไฟล์ `result.txt`
ต้องมี `cd /d "%~dp0"` ใน `run.cmd` ทุกตัวเสมอ
และสคริปต์ที่ถูกเรียกด้วย `call` ต้อง `cd /d` กลับมาที่โฟลเดอร์ตัวเอง
(ดูข้อ 2 ของ Lab 11)

---

### ภาคผนวก ข — ตารางคำสั่ง Tcl ที่ใช้บ่อย (ตรวจด้วย `help <คำสั่ง>`)

| คำสั่ง | รูปแบบที่วัดได้จริง |
|---|---|
| `mem load` | `mem load {-infile <infile> \| -filldata <data_word> [-infile <infile>]} [-endaddress <end>] [-fillradix <radix_type>] [-filltype {dec \| inc \| rand \| value}] [-format [bin \| hex \| mti]] [<path>] [-skip <Nwords>] [-startaddress <st>] [-truncate]` |
| `mem save` | `mem save <file_name> [<object_name>]` |
| `examine` | `examine <name>... [-delta <delta>] [-event <time>] [-handle] {[-in] [-out] [-inout] \| [-ports]} [-internal] [-maxlen <integer>] [-expr <expression>] [-name] [-<radix_type>] [-radix <type>] [-showbase] [-time <time>] [-value]` |
| `add wave` | `add wave [-allowconstants] [-color <name>] [-depth <level>] [-divider <name>] [-expand <signal>] [-format <type>] [-group <group> [<sig>...]] [-height <px>] {[-in] [-out] [-inout] \| [-ports]} [-internal] [-label <name>] [-max <real>] [-min <real>] [-noupdate] [-position <loc>] [-radix <type>] [-recursive] [-time] [<object_name>...]` |
| `bp` | `bp {<filename> <line_number> \| in <task_or_fcn>} {-c {...}} [-cond "<expr>"] [-disable] [-id <id#>] [-label "<label>"] [-inst <region>] [<command>...] \| [-query <filename> [<line_number>]]` |
| `run` | `run {[<timesteps>[<time_units>]] \| -all \| -continue \| -final \| -finish \| -init \| -next \| -over [<n>]} \| {-step [<n>] [-current] [-out] [-over [<n>]]}` |
| `coverage save` | `coverage save [-instance <path>] [-code {b\|c\|e\|s\|t\|f}...] [-codeAll] [-du <du_name>] [-empty <ucdb>] [-testname <test_name>] [-norecursive] [-onexit] [-prune <inst_path>] [<file_name>] [-assert] [-directive]` |
| `force` | `force <object_name> {<value> [[@]<time_info>][, <value> ...]} [-freeze \| -drive \| -deposit] [-cancel [@]<time_info>] [-repeat [@]<time_info>]` |
| `when` | `when [[-fast] [-id <id#>] [-label <label>] [-repeat] {<condition>} {<command>}]` |
| `log` | `log -flush <object> \| {[-filter <f> \| -nofilter <f>] [-howmany] {[-in] [-inout] [-out] \| [-ports]} [-internal] [-recursive [-depth <level>]] <object_name> ...}` |
| `quit` | `quit [-f \| -force] [-sim] [-code <integer>]` |
| `vcd` | `vcd add \| checkpoint \| comment \| dumpports... \| file \| files \| flush \| limit \| off \| on` |

### ภาคผนวก ค — ตัวเลือกของคำสั่งที่ใช้บ่อย

| คำสั่ง | ตัวเลือก | ความหมาย |
|---|---|---|
| `vcom` | `-2008` | ใช้มาตรฐาน VHDL-2008 (จำเป็นสำหรับ `std.env.finish`, `is_x`) |
| `vcom` | `-work <lib>` | ระบุไลบรารีปลายทาง |
| `vcom` | `-nopsl` | ปิดการ parse PSL ที่ฝังในคอมเมนต์ |
| `vcom` | `-pslext` | เปิดตัวดำเนินการ LTL/Universal ของ PSL |
| `vcom` | `+cover=<spec>` | ใส่ instrumentation สำหรับ code coverage (ค่าเริ่มต้นของเครื่องมือคือ `sbceft`) |
| `vsim` | `-c` | โหมด console (ไม่มี GUI) |
| `vsim` | `-onfinish <mode>` | `ask` (ค่าเริ่มต้น) \| `stop` \| `exit` \| `final` — ควรใช้ `stop` ในงาน batch |
| `vsim` | `-voptargs=+acc` | เปิดการเข้าถึง signal ภายในทั้งหมด (จำเป็นสำหรับ memory) |
| `vsim` | `-coverage` | เปิดการเก็บข้อมูล coverage |
| `vsim` | `-L <lib>` | เพิ่มไลบรารีในเส้นทางค้นหา |
| `vsim` | `-lib <lib>` | โหลด top จากไลบรารีที่ระบุ |
| `vsim` | `-g<NAME>=<value>` | ส่งค่าให้ generic ของ entity |

### ภาคผนวก ง — เทียบกับ Questa SIM Tutorial 2026.1 (คู่มือทางการ)

| Lab ของคู่มือนี้ | บทที่เกี่ยวข้องในคู่มือทางการ |
|---|---|
| LAB 01 | Ch.3 Basic Simulation — Create the Working Design Library / Compile / Optimize / Load / Run / Breakpoints |
| LAB 02 | Ch.5 Working With Multiple Libraries — Creating the Resource Library / Linking to the Resource Library |
| LAB 03 | Ch.3 (Run the Simulation) + หลักการเขียน testbench ที่ตรวจตัวเอง |
| LAB 04 | Ch.7 Analyzing Waveforms + Ch.8 Creating Stimulus With Waveform Editor (ส่วน Export) |
| LAB 05 | Ch.3 Set Breakpoints and Step through the Source + Ch.10 Dataflow Window |
| LAB 06 | Ch.10 Debugging With The Dataflow Window — Tracing an X (Unknown) |
| LAB 07 | Ch.11 Viewing And Initializing Memories |
| LAB 08 | Ch.8 (Create Graphical Stimulus with a Wizard / Simulating with the Test Bench File) |
| LAB 09 | Ch.14 Debugging With PSL Assertions |
| LAB 10 | Ch.13 Simulating With Code Coverage |
| LAB 11 | Ch.4 Projects / Simulation Configurations + แนวทาง CI ของคู่มือทางการ |

> คู่มือทางการครอบคลุม SystemC, SystemVerilog assertions/functional coverage และ DPI ด้วย
> คู่มือนี้จำกัดขอบเขตที่ **VHDL** ตามที่โจทย์กำหนด และเจาะลึกกว่าในส่วน
> batch/CI กับกับดักที่เจอจริงบนเครื่อง

### ภาคผนวก จ — สรุป “ทำอะไรต่อ” หลังจบทุก lab

| คุณทำได้แล้ว | ขั้นต่อไปที่ควรทำ |
|---|---|
| จำลอง VHDL ได้ทั้ง GUI และ batch | ลองทำ Lab 11 เพื่อรันทุก lab เป็นชุด |
| เขียน testbench ที่ตรวจตัวเอง | เพิ่ม PSL assertion (Lab 09) เพื่อตรวจ property ที่ซับซ้อนขึ้น |
| ดู coverage แล้ว | ตั้ง coverage goal และทำให้ regression ไม่ผ่านเมื่อ coverage ต่ำกว่าเกณฑ์ |
| แก้บั๊กด้วย breakpoint | ลองใช้ `force`/`release` และ `when` เพื่อทำ debug แบบในเชิงพฤติกรรม |
| ส่งออก VCD ได้ | ต่อเข้ากับ flow อื่น เช่น สร้างรายงาน HTML coverage แล้วเก็บเป็น artifact ของ CI |

---

## ภาคผนวก ฉ — คำถามที่พบบ่อย (FAQ)

**ถาม: รัน `run.cmd` แล้วขึ้น `[RESULT] FAIL -- the simulator did not finish` ทำอย่างไร ?**

1. เปิดไฟล์ `transcript` ในโฟลเดอร์ lab ดูข้อความท้าย ๆ
2. ถ้าเจอ `License checkout has been disallowed` → มี QuestaSim GUI เปิดค้างอยู่
   ให้ปิด แล้วรันใหม่
3. ถ้าเจอ `Cannot open macro file` → สคริปต์ถูกเรียกจากโฟลเดอร์ผิด
   ให้รันจากในโฟลเดอร์ของ lab
4. ถ้าเจอ error ของ `vcom` → ดูบรรทัดและเลขบรรทัดที่ชี้

**ถาม: ทำไมผลลัพธ์ต่างกันเวลารันใน GUI กับแบบ batch ?**

ตรวจดูว่าเวลาจำลองสิ้นสุดเท่าไร — ใน GUI ค่าเริ่มต้นของการรันคือ 100 ns
ถ้าต้องการให้รันจนจบ ให้ใช้ `run -all` เสมอ

**ถาม: ใช้ `std.env.finish` แล้วสคริปต์ถัดไปไม่ทำงาน ?**

ใช้ `vsim -c -onfinish stop` — ค่าเริ่มต้นคือ `ask` ซึ่งจะถามในโหมด console
และ `-onfinish stop` จะทำให้จำลอง “หยุด” แทนที่จะ “จบ session” คำสั่งที่เหลือจึงทำงานต่อ

**ถาม: จะเขียนข้อความภาษาไทยลงใน report ของ testbench ได้ไหม ?**

ไม่ได้ใน string literal (ข้อ C.7) แต่ถ้าอยากให้ผู้อ่านไทยเข้าใจ ให้เขียนเป็น comment ในไฟล์ VHDL
แล้วให้ `report` พิมพ์ข้อความอังกฤษ

**ถาม: รันทุก lab พร้อมกันได้ไหม ?**

**ไม่ได้** ถ้า license เป็น single-session แบบของเครื่องนี้
ต้องรันทีละ lab หรือใช้เครื่อง/ชุดติดตั้งที่มี license แยกกัน
(สคริปต์ `regression.cmd` ของ Lab 11 รันทีละ lab อยู่แล้ว)

**ถาม: ย้ายโฟลเดอร์ lab ไปที่อื่นแล้วรันไม่ได้ ?**

ไฟล์ `.do` ทุกตัวอ้างอิงไฟล์แบบสัมพัทธ์ จึงต้อง `cd` เข้าโฟลเดอร์ lab ก่อนรัน
(`run.cmd` ทำให้อัตโนมัติ) ส่วน `run.cmd` จะหาเครื่องมือจาก path ที่ติดตั้งจริง
ถ้าย้ายไปเครื่องอื่นให้ตั้ง `QUESTASIM_HOME` หรือ `MODELSIM_HOME`
