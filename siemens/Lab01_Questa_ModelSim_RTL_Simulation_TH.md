# Lab 1 — RTL simulation ด้วย Questa หรือ ModelSim

บทปฏิบัติการสำหรับคู่มือ Siemens EDA Tool Flow for Front-End Digital IC Design • VHDL-2008 • เวลาแนะนำ 75–90 นาที

## 1. จุดประสงค์และสิ่งที่ต้องส่ง

เมื่อจบ Lab ผู้เรียนต้องสามารถ compile RTL และ testbench ตามลำดับ, elaborate testbench top, ตรวจผลด้วย assertions, อ่าน waveform ตาม clock edge และพิสูจน์ว่า batch regression คืนสถานะล้มเหลวเมื่อ DUT ผิดพฤติกรรม ส่ง RTL/TB, script, log ของ baseline และ negative test, waveform พร้อม cursor ที่จุดตรวจ wrap และ reset priority และตารางสรุป ACC-01 ถึง ACC-04

## 2. ขั้นที่ 1 — กำหนดพฤติกรรมก่อนเขียนโค้ด

วงจรรับข้อมูล unsigned 8 บิต ที่ rising edge ของ clock คาบ 20 ns เมื่อ enable เป็น 1 และ reset เป็น 1 ให้บวกข้อมูลเข้าค่าสะสมแล้วเก็บผล modulo 256 Reset เป็น synchronous active-low จึงมีผลที่ rising edge และมี priority เหนือ enable

| เงื่อนไขที่ rising edge | ผลหลังอัปเดต | Requirement |
|---|---|---|
| rst_ni = 0 | 0 | ACC-01 |
| rst_ni = 1, en_i = 0 | คงค่าเดิม | ACC-02 |
| rst_ni = 1, en_i = 1 | ผลรวม 8 บิต | ACC-03 |
| ผลรวมทางคณิตศาสตร์ ≥ 256 ขณะบวก | เก็บเศษจากการหารด้วย 256 | ACC-04 |

คำนวณด้วยมือก่อนจำลอง 250 + 10 = 260 = 0x104 ดังนั้น output 8 บิตเป็น 0x04 ถ้าข้อกำหนดต้องเก็บ carry จะต้องขยาย operands ก่อนบวกและปรับ interface กับ test plan ตามไปด้วย

## 3. ขั้นที่ 2 — เตรียมเครื่องมือและไฟล์

เปิด Bash ในสภาพแวดล้อมที่มี Questa หรือ ModelSim พร้อม VHDL license แล้วตรวจเครื่องมือและรุ่นที่กำลังใช้งาน

```bash
command -v vlib vmap vcom vsim
vsim -version
vcom -help
mkdir -p lab01_acc8
cd lab01_acc8
```

ตรวจว่ารุ่นที่ใช้รองรับ `vcom -2008` หากโปรแกรมอยู่ใน PATH หลายชุด ให้ตรวจว่า compiler และ simulator มาจาก installation เดียวกัน ตัวอย่าง script ใช้ Bash และ mktemp สำหรับ Windows ให้ใช้ Bash ในสภาพแวดล้อมที่เรียก executable ของ simulator ได้ หรือป้อนคำสั่งจำลองทีละบรรทัดใน Questa/ModelSim Transcript ตามขั้นที่ 5

## 4. ขั้นที่ 3 — สร้าง DUT และ self-checking testbench

บันทึก DUT เป็น `acc8.vhd` ตัวแปรสถานะจริงคือ `sum_q` ซึ่งถูกเขียนที่ rising edge เท่านั้น สาขา enable เป็น 0 คงค่าของ register และ assignment ไป `sum_o` ทำให้ TB ตรวจผลจากขอบเขต interface ได้โดยตรง

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity acc8 is
  port (
    clk_i, rst_ni, en_i : in std_logic;
    data_i              : in std_logic_vector(7 downto 0);
    sum_o               : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of acc8 is
  signal sum_q : unsigned(7 downto 0);
begin
  process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_ni = '0' then
        sum_q <= (others => '0');
      elsif en_i = '1' then
        sum_q <= sum_q + unsigned(data_i);
      end if;
    end if;
  end process;
  sum_o <= std_logic_vector(sum_q);
end architecture;
```

บันทึก testbench เป็น `tb_acc8.vhd` โดยใช้ `work.tb_acc8` เป็น simulation top และ bind DUT ด้วย direct entity instantiation

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_acc8 is
end entity;

architecture test of tb_acc8 is
  signal clk : std_logic := '0';
  signal rst_n, en : std_logic := '0';
  signal din : std_logic_vector(7 downto 0) := (others => '0');
  signal dout : std_logic_vector(7 downto 0);
begin
  clk <= not clk after 10 ns;
  dut : entity work.acc8
    port map (clk_i => clk, rst_ni => rst_n, en_i => en,
              data_i => din, sum_o => dout);

  stimulus : process
    procedure step(rst, enable : std_logic;
                   value, expected : natural; label_text : string) is
    begin
      wait until falling_edge(clk);
      rst_n <= rst;
      en <= enable;
      din <= std_logic_vector(to_unsigned(value, din'length));
      wait until rising_edge(clk);
      wait for 1 ns;
      assert dout = std_logic_vector(to_unsigned(expected, dout'length))
        report label_text & " failed" severity failure;
    end procedure;
  begin
    step('0', '1',  17,   0, "ACC-01 initial reset");
    step('1', '1', 250, 250, "ACC-03 first addition");
    step('1', '1',  10,   4, "ACC-04 wrap");
    step('1', '0',  99,   4, "ACC-02 hold");
    step('1', '1',   2,   6, "ACC-03 resume");
    step('0', '1',   7,   0, "ACC-01 reset priority");
    report "TB_ACC8_PASS" severity note;
    wait;
  end process;
end architecture;
```

Procedure `step` drive ที่ falling edge ทำให้มีเวลา 10 ns ก่อน DUT sample ที่ rising edge การตรวจทันทีหลัง `wait until rising_edge(clk)` อาจอ่าน output ค่าเก่า เพราะ VHDL signal assignment กำหนดการอัปเดตผ่าน delta cycles ทั้งใน process ของ register และ concurrent assignment ที่ output ใน Lab นี้จึง sample หลัง edge 1 ns เพื่อให้ settle ใน RTL simulation ค่า 1 ns เป็นนโยบายของ testbench สำหรับกรณีศึกษานี้

## 5. ขั้นที่ 4 — สร้าง library, compile และรันแบบ batch

บันทึกเป็น `run.sh` ใช้ไดเรกทอรีใหม่ในทุก run เพื่อแยก compiled library, configuration และหลักฐานของแต่ละการทดลอง

```bash
#!/usr/bin/env bash
set -euo pipefail

lab_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$lab_dir/runs"
run_dir="$(mktemp -d "$lab_dir/runs/rtl.XXXXXX")"
printf 'Run directory: %s\n' "$run_dir"
cd "$run_dir"

vmap -c
vlib work
vmap work work
vcom -2008 -work work "$lab_dir/acc8.vhd" "$lab_dir/tb_acc8.vhd" \
  2>&1 | tee compile.log

if ! vsim -c -t 1ps work.tb_acc8 \
    -do 'run 150 ns; quit -f' 2>&1 | tee rtl.log; then
  printf 'FAIL: simulator command failed\n' >&2
  exit 1
fi

if grep -Eq '\*\* (Failure|Fatal|Error)([[:space:]]|:)' rtl.log; then
  printf 'FAIL: simulator reported an error or assertion failure\n' >&2
  exit 1
fi

if ! grep -Fq 'TB_ACC8_PASS' rtl.log; then
  printf 'FAIL: testbench did not reach the end\n' >&2
  exit 1
fi

printf 'PASS: all ACC-01 through ACC-04 checks completed\n'
```

```bash
bash run.sh
echo "$?"
```

| คำสั่ง | สิ่งที่เกิดขึ้น | วิธีตรวจ |
|---|---|---|
| `vmap -c` | คัดลอก simulator initialization มาที่ run directory | ตรวจ modelsim.ini ใน run |
| `vlib work` | สร้าง compiled library | มี work directory |
| `vmap work work` | ผูก logical name เข้ากับ directory | ตรวจ mapping และตำแหน่ง ini ใน transcript |
| `vcom -2008` | วิเคราะห์ VHDL และเก็บ design units | compile DUT ก่อน TB เพราะ TB อ้าง entity โดยตรง |
| `vsim ... work.tb_acc8` | Elaborate hierarchy, bind DUT แล้วเริ่ม simulation | ตรวจว่าโหลดทั้ง TB และ DUT |
| `run 150 ns` | รันครบทุก assertion | PASS marker ที่ 131 ns และ exit status 0 |

Clock generator ทำงานต่อหลัง testbench เข้าสู่ `wait;` จึงใช้เวลารันแบบจำกัด หาก installation มีการ override initialization ผ่าน environment ให้ตรวจจากข้อความของ `vmap` และใช้ configuration ที่ห้องปฏิบัติการกำหนดให้ตรงกันทั้ง compile และ simulation

## 6. ขั้นที่ 5 — เปิด GUI และตรวจ waveform ทีละ edge

เปิด GUI จากไดเรกทอรี run ที่ compile สำเร็จด้วย `vsim` แล้วพิมพ์ใน Transcript

```tcl
vsim -t 1ps work.tb_acc8
add wave sim:/tb_acc8/clk
add wave sim:/tb_acc8/rst_n
add wave sim:/tb_acc8/en
add wave -radix hexadecimal sim:/tb_acc8/din
add wave -radix hexadecimal sim:/tb_acc8/dout
run 150 ns
wave zoom full
```

หากเริ่มจาก GUI โดยยังไม่ได้ compile ให้ใช้ Transcript รัน `vmap -c`, `vlib work`, `vmap work work`, `vcom -2008 -work work acc8.vhd tb_acc8.vhd` จากไดเรกทอรีที่มีไฟล์ทั้งสองและยังไม่มี compiled library แล้วจึงโหลด TB ถ้าจะทบทวน stimulus เดิมให้ใช้ `restart -f` และรันอีกครั้ง

| Drive ที่ falling edge (ns) | Sample DUT ที่ rising edge (ns) | TB ตรวจ (ns) | rst_n | en | din hex | dout hex |
|---:|---:|---:|---:|---:|---:|---|---|
| 20 | 30 | 31 | 0 | 1 | 11 | 00 |
| 40 | 50 | 51 | 1 | 1 | FA | FA |
| 60 | 70 | 71 | 1 | 1 | 0A | 04 |
| 80 | 90 | 91 | 1 | 0 | 63 | 04 |
| 100 | 110 | 111 | 1 | 1 | 02 | 06 |
| 120 | 130 | 131 | 0 | 1 | 07 | 00 |

ก่อน transaction แรก rising edge ที่ 10 ns ล้าง register เพราะ TB เริ่มต้นด้วย reset active ตรวจช่วง 120–130 ns เป็นพิเศษ เมื่อ reset ถูก assert ที่ 120 ns ค่า output ยังเป็น 0x06 จนถึง rising edge ที่ 130 ns ซึ่งแสดงพฤติกรรม synchronous reset หาก waveform แสดง `U` ก่อน rising edge แรก ให้เทียบกับการที่ `sum_q` ยังไม่มีค่าเริ่มต้นและยังไม่ถูก reset

## 7. ขั้นที่ 6 — พิสูจน์เส้นทาง FAIL

1. เก็บ run directory ของ baseline ไว้ จากนั้นเปลี่ยน expected ของ `ACC-04 wrap` ใน TB จาก 4 เป็น 5 โดยคง DUT เดิม รัน `bash run.sh` แล้วตรวจ `echo "$?"` ทันที ผลที่คาดคือสถานะ nonzero และข้อความ `ACC-04 wrap failed` ที่ 71 ns การทดลองนี้ตรวจว่า comparator, transcript และ shell gate ทำงานร่วมกัน
2. คืนค่า expected เป็น 4 แล้วแก้ DUT ชั่วคราวให้สาขา enable มาก่อน reset รันใหม่ คาดว่า `ACC-01 initial reset failed` ที่ 31 ns เพราะ output กลายเป็น 17 ทั้งที่ reset active การทดลองนี้ตรวจว่า testbench จับ defect ใน RTL จริง
3. คืน DUT ให้ reset มี priority สูงกว่า enable แล้วรัน baseline อีกครั้ง เก็บ logs ของทั้งสามกรณีโดยระบุว่า run ใดเป็น intentional failure

## 8. Troubleshooting

| อาการ | ตรวจตามลำดับ |
|---|---|
| `command not found` | PATH และ executable ของ installation ที่ห้อง Lab ใช้ |
| License checkout ล้มเหลว | Edition, license availability และวิธีตั้งค่าตามห้อง Lab |
| vcom หา entity acc8 ไม่พบ | Compile order, logical library mapping และชื่อ entity |
| โหลดได้แต่ไม่มี stimulus | ตรวจว่า top คือ `work.tb_acc8` และสั่ง `run` แล้ว |
| Expected ถูกแต่ assertion อ่านค่าเก่า | วาง cursor ที่ rising edge กับจุด sample แยกกัน ตรวจลำดับ drive และ delta cycles |
| `run` จบแต่ไม่มี PASS | ตรวจเวลารัน, testbench top, early stop และ assertion failure ใน transcript |
| ดู signal ภายใน DUT ไม่ได้ | ใช้ top-level TB signals ก่อน หากต้องดู state ภายในให้เปิด signal visibility ตาม release ที่ใช้ |

## 9. เกณฑ์ตรวจรับและคำถามท้าย Lab

- Baseline มี PASS marker ที่ 131 ns, shell status 0 และค่า output ตรงตารางทุกแถว
- Negative test อย่างน้อยหนึ่งกรณีให้ shell status nonzero และระบุ requirement ที่เสียได้จาก log
- อธิบายจาก waveform ว่า hold ตรวจอย่างไรเมื่อ input เปลี่ยน และเหตุใด synchronous reset จึงรอ edge
- อธิบายผลเมื่อรันเพียง 100 ns โดยเทียบสิ่งที่เกิดขึ้นกับเงื่อนไข PASS ของ script
- เสนอ test เพิ่มสำหรับยืนยันว่า enable ต่ำค้างหลายรอบยังคงค่าเดิม และระบุว่าควรเพิ่มแถวใดใน requirement matrix

คำสั่ง Lab นี้ใช้ RTL และ testbench เพียงสองไฟล์ จึงทำได้ก่อนติดตั้ง ASIC PDK ส่วนผลที่ให้ในตารางเป็น expected results จากการไล่ clock edges และคำนวณ reference values สภาพแวดล้อมที่จัดทำคู่มือไม่มี Questa/ModelSim สำหรับยืนยันผลบน simulator จริง

## เอกสารอ้างอิง

- [Siemens Questa One Sim](https://resources.sw.siemens.com/ro-RO/fact-sheet-questa-one-sim/)
- [ตัวอย่างการใช้ Questa Sim script และคำสั่ง compile/visualization จาก Macnica](https://www.macnica.co.jp/en/business/semiconductor/articles/altera/133965/)

