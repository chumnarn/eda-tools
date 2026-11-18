**การใช้งาน ModelSim (และ QuestaSim) สำหรับ VHDL ใน ASIC Design อย่างละเอียด**

ModelSim (ปัจจุบันเป็นส่วนหนึ่งของ Siemens EDA / Questa) เป็นตัวจำลอง (simulator) มาตรฐานอุตสาหกรรมที่รองรับ VHDL, Verilog และ SystemVerilog ได้ดีมาก เหมาะสำหรับใช้ในขั้น **Functional Simulation (RTL)** และ **Gate-level / Timing Simulation** ใน ASIC design flow

ในบริบทของ ASIC Design Workshop ที่ใช้ Open Source EDA (เช่น LibreLane + IHP PDK) ร่วมกับ ModelSim/QuestaSim สำหรับการจำลอง VHDL เครื่องมือนี้ยังคงมีบทบาทสำคัญในขั้นตอน verification ก่อนเข้าสู่ synthesis และ place & route

### 1. บทบาทของ ModelSim ใน ASIC Design Flow

| ขั้นตอน | ประเภทการจำลอง | วัตถุประสงค์หลัก | ไฟล์ที่เกี่ยวข้อง |
|---------|------------------|------------------|-------------------|
| **RTL / Behavioral** | Functional Simulation | ตรวจสอบฟังก์ชันการทำงาน | VHDL source + Testbench |
| **Post-Synthesis** | Gate-level Functional | ตรวจสอบว่า synthesis ไม่เปลี่ยนพฤติกรรม | Netlist (VHDL/Verilog) + Testbench |
| **Post-P&R / Timing** | Timing Simulation (SDF back-annotation) | ตรวจสอบ timing จริงด้วย delay | Netlist + SDF + VITAL models |
| **Regression / Debug** | Batch mode + Coverage | รัน test หลายตัวและวัด coverage | .do scripts, Makefile |

ModelSim เด่นเรื่อง **debugging** (waveform, breakpoint, force, examine) และรองรับ **VITAL** สำหรับ timing simulation ของ ASIC/FPGA netlist ได้ดี

### 2. คำสั่งพื้นฐานที่ต้องรู้ (Command-line / Transcript)

ModelSim ใช้ Tcl เป็นพื้นฐาน คำสั่งหลักสำหรับ VHDL:

```bash
# สร้าง library
vlib work

# Map library (ถ้าต้องการ)
vmap work work

# Compile VHDL
vcom -2008 design.vhd          # รองรับ VHDL-2008
vcom -93 tb_design.vhd         # หรือระบุ version

# เริ่ม simulation
vsim work.tb_design            # โหลด entity/architecture

# ใน simulator (vsim prompt)
add wave -r /*                 # เพิ่มสัญญาณทั้งหมด
run 1 us                       # รัน 1 ไมโครวินาที
run -all                       # รันจนจบ (หรือจน assert/finish)
quit -sim                      # ออกจาก simulation
```

**ตัวเลือกสำคัญของ `vcom`:**
- `-2008`, `-93`, `-87` : เลือกมาตรฐาน VHDL
- `-work <lib>` : compile ไป library อื่น
- `-cover bces` : เปิด code coverage (ต้องมี license ที่รองรับ)
- `-quiet` : ลดข้อความ output

**ตัวเลือกสำคัญของ `vsim`:**
- `-c` : batch mode (ไม่มี GUI)
- `-t ps` หรือ `-t 1ps` : ตั้งค่า simulator resolution
- `-sdfmax /uut=delay.sdf` : back-annotate SDF (max delay)
- `-coverage` : เปิด coverage
- `-voptargs="+acc"` : ปิดการ optimize บางส่วนเพื่อให้ debug ได้ดีขึ้น

### 3. Workflow แนะนำสำหรับ ASIC (ใช้ .do file)

การเขียน **.do file** (Tcl script) เป็นวิธีที่ดีที่สุดสำหรับ reproducibility และ regression

ตัวอย่าง `run_sim.do`:

```tcl
# ล้าง simulation เก่า
quit -sim
catch {vdel -all -lib work}

# สร้าง library ใหม่
vlib work
vmap work work

# Compile (เรียงลำดับให้ถูกต้องสำหรับ VHDL)
vcom -2008 ../rtl/counter.vhd
vcom -2008 ../tb/tb_counter.vhd

# Optimize (แนะนำสำหรับ design ใหญ่)
vopt tb_counter -o tb_counter_opt +acc

# เริ่ม simulation
vsim -t ns tb_counter_opt

# เพิ่ม waveform
add wave -divider "Clock & Reset"
add wave /tb_counter/clk
add wave /tb_counter/reset

add wave -divider "DUT Signals"
add wave -r /tb_counter/uut/*

# รัน
run 2 us

# บันทึก waveform (ถ้าต้องการ)
# write format wave -window .main_pane.wave.interior.cs.body.pw.wf wave.do

echo "Simulation finished"
```

รันด้วย:
```bash
vsim -do run_sim.do
# หรือ batch:
vsim -c -do "do run_sim.do; quit -f"
```

### 4. การเขียน Testbench VHDL ที่ดีสำหรับ ASIC

หลักการสำคัญ:
- ใช้ `std_logic` / `std_logic_vector` + `ieee.numeric_std`
- มี clock process แยก
- มี reset sequence ที่ชัดเจน
- Self-checking (ใช้ `assert` หรือ procedure)
- รองรับ VHDL-2008 `finish` เพื่อหยุด simulation สะอาด

ตัวอย่างสั้น ๆ:

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_counter is
end entity;

architecture sim of tb_counter is
  signal clk   : std_logic := '0';
  signal reset : std_logic := '1';
  signal count : std_logic_vector(7 downto 0);
  
  constant CLK_PERIOD : time := 10 ns;
begin
  -- Clock
  clk <= not clk after CLK_PERIOD/2;

  -- DUT
  uut: entity work.counter
    port map (clk => clk, reset => reset, count => count);

  -- Stimulus & Check
  stim: process
  begin
    reset <= '1';
    wait for 50 ns;
    reset <= '0';
    
    wait for 200 ns;
    assert unsigned(count) = 20 
      report "Count mismatch" severity error;
    
    -- หยุด simulation (VHDL-2008)
    std.env.finish;
    wait;
  end process;
end architecture;
```

### 5. Timing Simulation (SDF + VITAL) ใน ASIC

หลัง synthesis และ place & route จะได้:
- Gate-level netlist (VHDL)
- ไฟล์ `.sdf` (Standard Delay Format)

วิธีรัน:

```bash
vcom netlist.vhd
vcom tb.vhd
vsim -sdfmax /tb/uut=design.sdf tb
```

หรือใช้กับ `vopt` เพื่อความเร็ว:

```bash
vopt -sdfmax /tb/uut=design.sdf tb -o tb_opt
vsim tb_opt
```

**หมายเหตุสำคัญ:**
- ต้องมี VITAL-compliant cell models จาก foundry/PDK
- ใช้ `+notimingchecks` ถ้าต้องการปิด timing check เพื่อความเร็ว (แต่ระวังผลลัพธ์)
- Resolution ควรเป็น `ps` หรือละเอียดกว่าเมื่อมี delay เล็กมาก

### 6. เทคนิค Debugging ที่ใช้บ่อย

| เทคนิค | คำสั่ง / วิธี | ใช้เมื่อ |
|--------|----------------|----------|
| **Waveform** | `add wave`, `log -r /*` | ดูพฤติกรรมโดยรวม |
| **Force** | `force /tb/clk 1 0 ns, 0 5 ns -repeat 10 ns` | บังคับค่าสัญญาณ |
| **Examine** | `examine /tb/uut/count` | ดูค่าปัจจุบัน |
| **Breakpoint** | GUI หรือ `bp` | หยุดที่บรรทัดที่สนใจ |
| **When** | `when {/tb/count = x"FF"} {stop}` | หยุดเมื่อเงื่อนไข |
| **Coverage** | `vsim -coverage` + `coverage report` | วัดความครอบคลุมของ test |

### 7. Best Practices สำหรับ ASIC Design

1. **แยก Library** — ใช้หลาย library (เช่น `rtl`, `tb`, `gate`) แทนการใส่ทุกอย่างใน `work`
2. **ใช้ VHDL-2008** กับ testbench (รองรับ `std.env.finish`, external names, etc.)
3. **Script ทุกอย่าง** — ใช้ `.do` หรือ Makefile เพื่อให้ regression ทำซ้ำได้
4. **Self-checking testbench** — อย่าพึ่ง waveform อย่างเดียว
5. **ปิด optimization เมื่อ debug** — ใช้ `+acc` หรือปิด `voptflow` ชั่วคราว
6. **จัดการ hierarchy** — ใช้ hierarchical reference หรือ external name ใน VHDL-2008
7. **Regression** — รัน batch mode + เก็บ log และ exit code

### 8. ข้อจำกัดและการเชื่อมโยงกับ Open Source EDA

- ModelSim/Questa เป็นเครื่องมือ commercial (มี Intel FPGA Starter Edition ที่ใช้ฟรีได้จำกัด)
- ใน flow ที่ใช้ LibreLane + IHP SG13G2 คุณสามารถใช้ ModelSim สำหรับ VHDL simulation ก่อนส่ง netlist เข้า LibreLane
- สำหรับ pure open-source ทางเลือกคือ GHDL + GTKWave (รองรับ VHDL-2008 ได้ดี แต่ debugging ไม่สะดวกเท่า ModelSim)

---

**สรุป Workflow แนะนำ:**

1. เขียน RTL VHDL + Testbench
2. สร้าง `.do` file สำหรับ compile + simulate
3. รัน functional simulation จน self-checking ผ่าน
4. ส่งไป synthesis (LibreLane / Yosys / etc.)
5. นำ gate-level netlist กลับมาจำลองอีกครั้ง (ถ้าต้องการ)
6. หลัง P&R ทำ timing simulation ด้วย SDF (ถ้ามี cell models)

หากต้องการตัวอย่างเต็มสำหรับ module เฉพาะ (เช่น counter, FIFO, RISC-V core interface, หรือการเชื่อมกับ LibreLane) หรือต้องการ template `.do` + testbench เพิ่มเติม แจ้งได้เลย จะช่วยปรับให้เหมาะกับ workshop ได้ครับ.