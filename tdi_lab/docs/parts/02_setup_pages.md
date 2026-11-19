
## บทที่ 2 — หน้าต่าง Setup TDI ทั้ง 7 หน้า

หน้าต่าง Setup TDI มี 7 หน้า แต่ละหน้าคือการกรอกกลุ่มของตัวแปรที่ flow อ่าน
หัวข้อนี้อธิบายแต่ละหน้าว่า **ถามอะไร เก็บลงตัวแปรอะไร และ flow เอาไปทำอะไร**

หมายเหตุเรื่องชื่อ: ในตัวเครื่องมือชื่อเลเยอร์ที่ใช้ทำ P&R boundary
เขียนว่า `prBoundray:drawing` (พิมพ์ผิดจาก Boundary) — ให้จำไว้เพราะต้องกำหนด
เป็น Icon Layer ให้ตรงชื่อพอดี

### 2.1 หน้า Run File

| ช่อง | ความหมาย |
|---|---|
| Data Directory | โฟลเดอร์ที่เก็บผลลัพธ์ของแต่ละรอบ (มี timestamp) |
| Use Custom Run Script | ใช้สคริปต์ TCL ของตัวเองแทนสคริปต์ที่ TDI สร้างให้ |

**สิ่งที่ flow เอาไปทำ**

- โฟลเดอร์ข้อมูลจะถูกคัดลอกไปที่ `/tmp/<user>_nitro_data` บนเครื่อง Linux
  (ยกเว้นโฟลเดอร์ `results/` ที่เก็บผลลัพธ์ที่ดึงกลับมา)
- ถ้าไม่เลือก Custom Run Script TDI จะสร้างสคริปต์ขับ Nitro จากค่าที่กรอก
  คุณจึงไม่ต้องเขียน TCL เอง — แต่ถ้าอยากควบคุมลำดับขั้นตอนเอง
  ให้เขียนสคริปต์แล้วชี้ที่นี่

**ตัวแปรที่เกี่ยวข้อง**

| ตัวแปร | อ่านที่ | ความหมาย |
|---|---|---|
| `ams_run_control` | `aprisa_ams.tcl:42` | `synpnr` / `syn` / `pnr` |

### 2.2 หน้า Tech and Lib

หน้านี้รวบรวมไฟล์สี่ชนิดที่ต้องให้กับ flow

| ชนิดไฟล์ | สกุล | ให้ข้อมูลอะไร |
|---|---|---|
| **LEF** | `.lef` | รูปทรงและ layout ของเซลล์ + ชั้นโลหะของเทคโนโลยี |
| **Liberty** | `.lib` | เวลา กำลัง และพื้นที่ของเซลล์ |
| **PTF** | `.ptf` | ความต้านทานและความจุของชั้นโลหะ (Nitro ใช้เท่านั้น) |
| **Corner** | — | มุมของกระบวนการ ได้สูงสุด 3: `fast` / `nominal` / `slow` |

**สิ่งที่ flow เอาไปทำ — และนี่คือจุดที่ทำให้สับสน**

หน้าเดียวกันนี้ถูกอ่านโดย **สองชุดสคริปต์ที่ใช้ชื่อตัวแปรต่างกัน**

| ผู้อ่าน | ตัวแปรที่อ่าน | ใช้ทำอะไร |
|---|---|---|
| `tanner_oasys.tcl` (synthesis) | `lef_file_list` | `read_lef` ทีละไฟล์ |
| `tanner_oasys.tcl` (synthesis) | `lib_file_list` | `read_library` ทีละไฟล์ |
| `tanner_oasys.tcl` (synthesis) | `ptf_file_list` + `tanner_ptf_file_corner_list` | `read_ptf` |
| `0_data_prep.tcl` (P&R) | `tech_file_list` | นำเข้าเทคโนโลยี |
| `0_data_prep.tcl` (P&R) | `cell_lef_file_list` | `import_lef -lib_cell_only` |
| `0_data_prep.tcl` (P&R) | `corner_list` | ลูปผ่านมุมของกระบวนการ |
| `0_data_prep.tcl` (P&R) | `rlc_file_list` | โมเดล RLC (เว้นว่างได้ถ้าใช้ PTF) |

> **บันทึกไว้เลย**
>
> ไฟล์ LEF เดียวกันถูกส่งเข้า flow **สองชื่อที่ต่างกัน**
> `lef_file_list` สำหรับขั้นสังเคราะห์ และ
> `tech_file_list` + `cell_lef_file_list` สำหรับขั้นวางเดินสาย
> ถ้าตั้งแต่ในหน้าต่างแล้วสองชุดนี้จะถูกเขียนให้อัตโนมัติ
> แต่ถ้าคุณเขียนไฟล์ตั้งค่าเอง (ดู lab 06) ต้องใส่ให้ครบทั้งสองชุด

**กฎสามข้อที่ต้องไม่ผิด**

1. **tech LEF ต้องมาก่อน standard cell LEF เสมอ**
   เพราะ tech LEF เป็นตัวกำหนดชั้นโลหะและ via ที่เซลล์ LEF อ้างถึง
   ผิดลำดับแล้ว LEF ที่สองจะอ่านไม่ผ่าน
2. **PTF อ่านเข้าได้แค่ไฟล์เดียว**
   ดู `tanner_oasys.tcl:33-50` — flow จะเลือกไฟล์ PTF ไฟล์เดียว
   ตามลำดับความสำคัญ `slow` → `nominal` → `fast`
   แล้วอ่านเฉพาะไฟล์นั้น (ถ้าตั้ง PTF ไว้สามไฟล์ ก็ยังถูกอ่านแค่ไฟล์เดียว)
3. **LEF กับ Liberty ต้องตรงกัน**
   ไม่ตรงกันแล้วจะพังตอนสังเคราะห์ และข้อความแจ้งเตือนมักไม่ชี้ว่าเป็นเรื่องนี้
   (lab 03 มีตัวอย่างจริงที่เจอในชุด Generic 250 nm)

### 2.3 หน้า Netlist/RTL

| ช่อง | ความหมาย |
|---|---|
| Run control | สังเคราะห์+วางเดินสายพร้อมกัน หรือแยกทีละขั้น |
| Netlist/RTL files for synthesis | ไฟล์ RTL ที่จะสังเคราะห์ |
| Top Cell | ชื่อโมดูลบนสุด |
| Power Net / Ground Net | ชื่อเน็ตของแหล่งจ่ายและกราวด์ |

**สิ่งที่ flow เอาไปทำ**

- `tanner_oasys.tcl` อ่านไฟล์ตามนามสกุลอัตโนมัติ:
  `.vhd`/`.vhdl` → `read_vhdl`, `.sv` → `read_verilog -sv`, อื่น ๆ → `read_verilog`
- ถ้ามีไฟล์ scan configuration ก็จะสังเคราะห์แบบ `-map_to_scan`
- ผลลัพธ์คือ `results/<top>_syn.v`

**ตัวแปรที่เกี่ยวข้อง**

| ตัวแปร | อ่านที่ | ความหมาย |
|---|---|---|
| `tanner_cell` | `tanner_oasys.tcl:96` | โมดูลเป้าหมายของการสังเคราะห์ |
| `top_cell` | `2_floorplan.tcl` | โมดูลเป้าหมายของการวางเดินสาย |
| `verilog_file_list` | `tanner_oasys.tcl:65` | รายการไฟล์ RTL |
| `is_list_file` / `list_file` | `tanner_oasys.tcl:57` | โหมดอ่านไฟล์จาก list file |
| `is_Verilog` | `tanner_oasys.tcl:59` | list file นั้นเป็น Verilog หรือ VHDL |
| `use_list_file` | `0_data_prep.tcl:113` | สลับโหมด list file ของขั้น data prep |
| `enable_scan` | `1_rtl_synthesis.tcl:50` | เปิดการทำ scan หรือไม่ |
| `syn_netlist` | ขั้น export | ที่เก็บ netlist ระดับ gate |

> **Top Cell ต้องตรงกับชื่อใน DEF**
>
> ในตัวอย่าง ADC8 ทั้ง RTL (`module ADCCtrl`) และ DEF (`DESIGN ADCCtrl;`)
> ต้องเป็นชื่อเดียวกัน lab 01 ตรวจเรื่องนี้โดยตรง

### 2.4 หน้า Timing

หน้านี้มีสองทางเลือก และความต่างระหว่างมัน **สำคัญมาก**

| ทางเลือก | ข้อมูลที่มี | เหมาะกับ |
|---|---|---|
| **Define clocks** | มีแค่นามคล็อกและคาบเวลา ไม่มี delay, load, fanout | ลองเล่น สำรวจ flow |
| **SDC file** | ข้อจำกัดเวลา กำลัง และพื้นที่ครบ | งานที่จะส่งผลิต |

**สิ่งที่ flow เอาไปทำ — อ่านจากโค้ดจริง**

โหมด `clocks` (`tanner_oasys.tcl:104-116`):

```tcl
create_clock -name $clk -period $period -waveform $waveform [get_ports $clk]
set_input_delay  -clock $clk 1 [all_inputs]
set_output_delay -clock $clk 1 [all_outputs]
```

สังเกตว่า delay ที่ใส่ให้คือ **ค่า 1 หน่วยเวลา** ไม่ใช่งบประมาณจริง
คือการบอก flow ว่า "ตัวเลขนี้เอาไปคิด" ไม่ใช่ความต้องการจริงของดีไซน์

โหมด `sdc` (`tanner_oasys.tcl:117-125`):

```tcl
foreach mode $MGC_modes {
    set_timing_mode $mode
    foreach sdc_file $oasys_importConstraintsFile($mode) {
        read_sdc $sdc_file -mode $mode
    }
}
```

โหมดนี้อ่าน SDC ได้หลายไฟล์ต่อหนึ่ง mode จึงรองรับการตั้งหลายมุมได้

> **สำหรับงานจริง ให้ใช้หน้า SDC เสมอ**
>
> ตัวอย่างที่แนบมามี SDC แบบครบแล้วที่
> `design/files/timing_constraints_full.sdc`
> และ lab 04 จะเปรียบเทียบกับแบบที่มากับตัวอย่างให้

**ตัวแปรที่เกี่ยวข้อง**

| ตัวแปร | อ่านที่ | ความหมาย |
|---|---|---|
| `tanner_timing_mode` | `tanner_oasys.tcl:104` | `clocks` หรือ `sdc` |
| `tanner_clock_spec` | `tanner_oasys.tcl:105` | รายการคล็อก ในโหมด clocks |
| `MGC_modes` | `tanner_oasys.tcl:118` | รายการ mode วิเคราะห์ ในโหมด sdc |
| `oasys_importConstraintsFile` | `tanner_oasys.tcl:120` | ไฟล์ SDC ของแต่ละ mode |

### 2.5 หน้า Floorplan

TDI ให้เลือก floorplan ได้สามวิธี

| วิธี | ตัวแปร | ลักษณะ |
|---|---|---|
| Specify Block Details | `floorplan_mode` = `block` | กำหนด Die Area และ Row Margins ด้วยตัวเลข |
| Export from layout | `floorplan_mode` = `layout` | ดึง boundary และตำแหน่งพอร์ตจากเลย์เอาต์ใน L-Edit |
| Use Def floorplan file | `floorplan_mode` = `def` | อ่านจากไฟล์ DEF |

**สิ่งที่ flow เอาไปทำ**

- `2_floorplan.tcl` เลือกวิธีตาม `floorplan_mode` แล้วสร้างรายการ layer ที่จะวาง
- ถ้าเป็นโหมด `layout` หรือ `def` flow จะ **วางพอร์ตให้ตรงตำแหน่งที่กำหนดไว้**
  ซึ่งเป็นสิ่งที่ต้องการเมื่อนำบล็อกดิจิทัลไปต่อกับส่วนอนาล็อก

**ตัวแปรที่เกี่ยวข้อง**

| ตัวแปร | อ่านที่ | ความหมาย |
|---|---|---|
| `floorplan_mode` | `2_floorplan.tcl` | `block` / `layout` / `def` |
| `def_floorplan_file` | `2_floorplan.tcl` | ไฟล์ DEF ในโหมด `def` |
| `chip_width` / `chip_height` | `2_floorplan.tcl` | ขนาด die ในหน่วย DBU |
| `chip_origin_x` / `chip_origin_y` | `2_floorplan.tcl` | จุดเริ่มของ die |
| `core_site` | `2_floorplan.tcl` | ชื่อ site ของแถวเซลล์มาตรฐาน |
| `core_yb_spacing` / `core_xl_spacing` / `core_yt_spacing` / `core_xr_spacing` | `compute_floorplan_details.tcl:87` | **ระยะจาก power ring ถึงแถวเซลล์แรก** |
| `highest_routing_layer` | `2_floorplan.tcl` | ชั้นโลหะสูงสุดที่อนุญาตให้เดินสาย |
| `fp_utilization` | `2_floorplan.tcl` | เป้าหมายความหนาแน่น |
| `fp_aspect_ratio` | `2_floorplan.tcl` | อัตราส่วนกว้าง:ยาวของบล็อก |

> **Row Margins ไม่ใช่ระยะจากขอบ die**
>
> ค่าที่ TDI เรียกว่า Row Margins ถูกส่งไปเป็น `core_*_spacing`
> ซึ่งคือ **ระยะจากขอบของ power ring ถึงแถวเซลล์แรก**
> ส่วนระยะจากขอบ die จริง ๆ จะถูกคำนวณโดย flow เอง:
>
> ```tcl
> set core_to_bottom [expr $ring_offset_bottom + $core_yb_spacing]
> ```
>
> โดย `ring_offset_*` มาจากความกว้างของ ring ที่คำนวณจากแผน power
> (ดูหัวข้อ 2.6)

### 2.6 หน้า Power Plan

หน้านี้ตั้งค่าแหวนและแถบจ่ายไฟ

**สิ่งที่ flow เอาไปทำ — อ่านจาก `3_powerplan.tcl`**

| ตัวแปร | ความหมาย |
|---|---|
| `power_nets` | รายชื่อแหล่งจ่าย **อันแรกคือแหล่งจ่ายหลัก** |
| `ground_nets` | รายชื่อกราวด์ **อันแรกคือกราวด์หลัก** |
| `enable_pg_ring` | เปิด/ปิดแหวนจ่ายไฟ |
| `enable_pg_stripe` | เปิด/ปิดแถบจ่ายไฟ |
| `pg_ring_vlayer` / `pg_ring_hlayer` | ชั้นโลหะของเส้นแนวตั้ง / แนวนอน |
| `pg_ring_net_order` | **ลำดับวงแหวนจากนอกเข้าใน** |
| `pg_ring_widths` | ความกว้างของแต่ละวง |
| `pg_ring_spacing` | ระยะห่างระหว่างวง |
| `pg_ring_offset_top/right/bottom/left` | ระยะเพิ่มจาก ring ถึงขอบ die |
| `pg_stripe_list` / `num_of_stripes` | รายการแถบจ่ายไฟ |

**กฎสองข้อที่ flow บังคับ** (จาก `compute_floorplan_details.tcl:36-45`)

```tcl
# จำนวน spacing ต้องเป็น 1 หรือ (จำนวนแหล่งจ่าย - 1)
if {$size_of_ring_spacing != "1" && ($size_of_ring_spacing != [expr $nb_of_supplies -1])} {
    puts "FLOW-ERROR : Nb of ring spacing values does not match number of intervals between supplies"
}
# จำนวน width ต้องเป็น 1 หรือ จำนวนแหล่งจ่าย
if {$size_of_ring_width != "1" && ($size_of_ring_width != $nb_of_supplies)} {
    puts "FLOW-ERROR : Nb of ring width values does not match number of supplies"
}
```

> **ตัวอย่างที่พลาดง่าย**
>
> มีแหล่งจ่าย 2 ตัว (Vdd, Gnd) และใส่ spacing ไป 2 ค่า
> ค่าที่สองไม่จำเป็นต้องมี เพราะมีแค่ช่องว่างระหว่างวงเพียงช่องเดียว
> ถ้าใส่เกิน flow จะหยุดพร้อมข้อความ `FLOW-ERROR`
> lab 06 ตรวจกฎนี้ด้วย

**ข้อจำกัดที่ flow ตรวจเองอีกข้อ** (จาก `3_powerplan.tcl`)

spacing ของ ring ต้องไม่น้อยกว่า min spacing ของชั้นโลหะที่ใช้
ไม่อย่างนั้น flow จะพิมพ์

```text
FLOW-ERROR : PG ring spacing constraint is smaller than Metal4 or Metal3
min_spacing DRC constraint. Please revisit your constraint...
```

**ตัวอย่างจริงจากชุด Generic 250 nm**

| ค่า | ตัวเลข |
|---|---|
| แหล่งจ่าย | Vdd (นอกสุด), Gnd (ข้างใน) |
| เส้นแนวตั้ง / แนวนอน | Metal4 / Metal3 |
| ความกว้าง | 2.0 µm (Vdd), 1.5 µm (Gnd) |
| spacing | 0.6 µm (ค่าเดียว) |
| min spacing ของ Metal4 / Metal3 | 0.5 µm |

และเมื่อคำนวณด้วยสูตรของ flow จะได้

| ปริมาณ | ค่า | สูตร |
|---|---|---|
| ความกว้าง ring รวม | 4.1 µm | ผลรวม width (3.5) + spacing (0.6) |
| `width_contrib` | 3.5 µm | width ของ Vdd + width ของ Gnd |
| `spacing_contrib` | 1.2 µm | 2 × spacing |
| `macro_ring_spacing` | 16.2 µm | 2 × ความสูง site (8.10 µm) |
| `oversize_m2m` | 41.8 µm | 2 × (width_contrib + spacing_contrib + macro_ring_spacing) |
| `oversize_b2m` | 45.9 µm | max(offset ทั้งสี่ด้าน) + oversize_m2m |

### 2.7 หน้า Additional Commands

ช่องแก้ไขในหน้านี้คือ **ตัวแปรที่เขียนทับค่าเริ่มต้นของ flow**

ค่าที่ตั้งไว้ในนี้จะถูกเขียนลงไฟล์ `additional_commands.tcl`
แล้วถูก `source` เข้าไปใน flow ตามโค้ดใน `aprisa_ams.tcl`:

```tcl
# Source Customization
if {[file exists additional_commands.tcl]} {
    puts "\nFLOW-INFO: Loading Aprisa customization"
    source additional_commands.tcl
}
```

**ตัวแปรที่ควรรู้** (จาก `flow_variables.tcl`)

| ตัวแปร | ค่าเริ่มต้น | ผลของการเปลี่ยน |
|---|---|---|
| `rtl_max_util` | 85 | เปอร์เซ็นต์ความหนาแน่นสูงสุดของ netlist ที่สังเคราะห์ |
| `enable_clock_gating` | 0 | เปิดการใส่ clock gating ให้อัตโนมัติ |
| `DFT_flow` | `native` | วิธีทำ scan (`native` / `tessent`) |
| `force_io_placement` | 1 | บังคับให้วางพอร์ตตามตำแหน่งที่กำหนด |
| `delete_unconnected_phys_pins` | 0 | ลบรูปพอร์ตที่ไม่ได้ต่อ |
| `well_tap_cell` | *(ว่าง)* | เซลล์ well tap |
| `physical_effort` | `low` | ความพยายามของ physical synthesis |
| `tie_high_libcell` / `tie_low_libcell` | *(ว่าง)* | เซลล์สำหรับ tie logic |
| `delay_cells` | *(ว่าง)* | เซลล์ delay |
| `filler_libcells` | *(ว่าง)* | เซลล์ filler |
| `decap_libcells` | *(ว่าง)* | เซลล์ decap |
| `antenna_diodes` | *(ว่าง)* | เซลล์ antenna diode |
| `route_optimize_effort` | `low` | ความพยายามของ router |
| `repair_after_filler` | 1 | ซ่อม DRC หลังใส่ filler |
| `exit_on_flow_error` | 0 | หยุดทันทีเมื่อเจอ error |

> **ข้อควรระวัง**
>
> การตั้งค่า `tie_high_libcell` หรือ `tie_low_libcell` ต้องดูว่าเซลล์นั้น
> **มี LEF ด้วย** ไม่ใช่มีแค่ใน Liberty
> ในชุด Generic 250 nm ที่แนบมา `TIELOW` และ `TIEHIGH`
> มีอยู่ใน Liberty แต่ **ไม่มีใน LEF** (lab 03)
> ถ้าตั้งค่านี้แล้ว flow จะพังตอนใส่ tie cell

---
