
## ภาคผนวก

### 6.1 สัญญาตัวแปรฉบับเต็ม

ตารางนี้ได้จากการรัน lab 06 บนเครื่องนี้
คอลัมน์ "อ่านที่" คือ **ไฟล์และบรรทัดจริง** ที่อ่านตัวแปรนั้น

| ตัวแปร | หน้า Setup TDI | อ่านที่ | ความหมาย |
|---|---|---|---|
| `ams_run_control` | Run File | `0_data_prep.tcl:109` | `synpnr` / `syn` / `pnr` |
| `lef_file_list` | Tech and Lib | `tanner_oasys.tcl:23` | รายการ LEF ของขั้นสังเคราะห์ |
| `lib_file_list` | Tech and Lib | `tanner_oasys.tcl:13` | รายการ Liberty |
| `ptf_file_list` | Tech and Lib | `tanner_oasys.tcl:41` | รายการ PTF |
| `tanner_ptf_file_corner_list` | Tech and Lib | `tanner_oasys.tcl:33` | ชื่อมุมของแต่ละ PTF |
| `tech_file_list` | Tech and Lib | `0_data_prep.tcl:18` | เทคโนโลยี LEF ของขั้นวางเดินสาย |
| `cell_lef_file_list` | Tech and Lib | `0_data_prep.tcl:100` | standard cell LEF ของขั้นวางเดินสาย |
| `corner_list` | Tech and Lib | `0_data_prep.tcl:37` | รายการมุมของกระบวนการ |
| `rlc_file_list` | Tech and Lib | `0_data_prep.tcl:35` | ไฟล์โมเดล RLC |
| `top_cell` | Netlist/RTL | `0_data_prep.tcl:160` | โมดูลเป้าหมายของขั้นวางเดินสาย |
| `tanner_cell` | Netlist/RTL | `tanner_oasys.tcl:93` | โมดูลเป้าหมายของขั้นสังเคราะห์ |
| `verilog_file_list` | Netlist/RTL | `tanner_oasys.tcl:65` | รายการไฟล์ RTL |
| `is_list_file` | Netlist/RTL | `tanner_oasys.tcl:57` | อ่านรายการไฟล์จาก list file |
| `is_Verilog` | Netlist/RTL | `tanner_oasys.tcl:59` | list file เป็น Verilog หรือ VHDL |
| `list_file` | Netlist/RTL | `tanner_oasys.tcl:60` | พาธของ list file |
| `use_list_file` | Netlist/RTL | `0_data_prep.tcl:113` | สลับโหมด list file ของขั้น data prep |
| `enable_scan` | Netlist/RTL | `1_rtl_synthesis.tcl:50` | เปิดการทำ scan |
| `syn_netlist` | Netlist/RTL | `0_data_prep.tcl:159` | ที่เก็บ netlist ระดับ gate |
| `tanner_timing_mode` | Timing | `tanner_oasys.tcl:104` | `clocks` หรือ `sdc` |
| `tanner_clock_spec` | Timing | `tanner_oasys.tcl:105` | รายการคล็อก — **ใช้เฉพาะโหมด `clocks`** |
| `MGC_modes` | Timing | `tanner_oasys.tcl:118` | รายการ mode — **ใช้เฉพาะโหมด `sdc`** |
| `oasys_importConstraintsFile` | Timing | `tanner_oasys.tcl:120` | ไฟล์ SDC ของแต่ละ mode — **โหมด `sdc`** |
| `floorplan_mode` | Floorplan | `2_floorplan.tcl:42` | `block` / `layout` / `def` |
| `def_floorplan_file` | Floorplan | `2_floorplan.tcl:82` | ไฟล์ DEF ในโหมด `def` |
| `chip_width` | Floorplan | `2_floorplan.tcl:48` | ความกว้างของ die (DBU) |
| `chip_height` | Floorplan | `2_floorplan.tcl:48` | ความสูงของ die (DBU) |
| `chip_origin_x` | Floorplan | `2_floorplan.tcl:55` | จุดเริ่ม X ของ die |
| `chip_origin_y` | Floorplan | `2_floorplan.tcl:55` | จุดเริ่ม Y ของ die |
| `core_site` | Floorplan | `2_floorplan.tcl:178` | ชื่อ site ของแถวเซลล์ |
| `core_yb_spacing` | Floorplan | `compute_floorplan_details.tcl:87` | ระยะใต้แถวเซลล์จาก ring |
| `core_xl_spacing` | Floorplan | `compute_floorplan_details.tcl:88` | ระยะซ้ายแถวเซลล์จาก ring |
| `core_yt_spacing` | Floorplan | `compute_floorplan_details.tcl:89` | ระยะบนแถวเซลล์จาก ring |
| `core_xr_spacing` | Floorplan | `compute_floorplan_details.tcl:90` | ระยะขวาแถวเซลล์จาก ring |
| `highest_routing_layer` | Floorplan | `2_floorplan.tcl:37` | ชั้นโลหะสูงสุดที่เดินสายได้ |
| `fp_utilization` | Floorplan | `2_floorplan.tcl:63` | เป้าหมายความหนาแน่น |
| `fp_aspect_ratio` | Floorplan | `2_floorplan.tcl:64` | อัตราส่วนกว้าง:ยาว |
| `power_nets` | Power Plan | `2_floorplan.tcl:29` | ชื่อแหล่งจ่าย |
| `ground_nets` | Power Plan | `2_floorplan.tcl:29` | ชื่อกราวด์ |
| `enable_pg_ring` | Power Plan | `2_floorplan.tcl:104` | เปิด/ปิดแหวนจ่ายไฟ |
| `enable_pg_stripe` | Power Plan | `3_powerplan.tcl:149` | เปิด/ปิดแถบจ่ายไฟ |
| `pg_ring_vlayer` | Power Plan | `2_floorplan.tcl:105` | ชั้นของเส้นแนวตั้งของ ring |
| `pg_ring_hlayer` | Power Plan | `2_floorplan.tcl:106` | ชั้นของเส้นแนวนอนของ ring |
| `pg_ring_net_order` | Power Plan | `3_powerplan.tcl:71` | ลำดับวงจากนอกเข้าใน |
| `pg_ring_widths` | Power Plan | `3_powerplan.tcl:73` | ความกว้างของแต่ละวง |
| `pg_ring_spacing` | Power Plan | `3_powerplan.tcl:61` | ระยะห่างระหว่างวง |
| `pg_ring_offset_top` | Power Plan | `3_powerplan.tcl:101` | ระยะเพิ่มด้านบน |
| `pg_ring_offset_right` | Power Plan | `3_powerplan.tcl:100` | ระยะเพิ่มด้านขวา |
| `pg_ring_offset_bottom` | Power Plan | `3_powerplan.tcl:99` | ระยะเพิ่มด้านล่าง |
| `pg_ring_offset_left` | Power Plan | `3_powerplan.tcl:98` | ระยะเพิ่มด้านซ้าย |
| `pg_stripe_list` | Power Plan | `3_powerplan.tcl:153` | รายการแถบจ่ายไฟ |
| `num_of_stripes` | Power Plan | `3_powerplan.tcl:195` | จำนวนแถบ |

### 6.2 ตัวแปรของ flow ที่ตั้งค่าได้จากหน้า Additional Commands

จาก `ap_ref_flows/flow_variables.tcl`

| ตัวแปร | ค่าเริ่มต้น | ผลของการเปลี่ยน |
|---|---|---|
| `exit_on_flow_error` | 0 | หยุดทันทีเมื่อเจอ error |
| `enable_no_clock_flow` | 0 | อนุญาตให้ flow ทำงานโดยไม่มีคล็อก |
| `save_all_verilog` | 0 | บันทึก Verilog ทุกเวอร์ชัน |
| `export_RDB` | 1 | export ฐานข้อมูลรายงาน |
| `allow_incomplete_liberty_data` | 0 | ยอมรับ Liberty ที่ไม่ครบ |
| `dont_use_libcells` | *(ว่าง)* | เซลล์ที่ห้ามใช้ |
| `HDL_format` | *(ว่าง)* | `verilog` / `systemverilog` / `vhdl87` / `vhdl93` / `vhdl2008` |
| `rtl_max_util` | 85 | ความหนาแน่นสูงสุดของ netlist ที่สังเคราะห์ |
| `enable_clock_gating` | 0 | ใส่ clock gating อัตโนมัติ |
| `DFT_flow` | `native` | วิธีทำ scan: `native` / `tessent` |
| `force_io_placement` | 1 | บังคับวางพอร์ตตามตำแหน่งที่กำหนด |
| `delete_unconnected_phys_pins` | 0 | ลบรูปพอร์ตที่ไม่ต่อ |
| `well_tap_cell` | *(ว่าง)* | เซลล์ well tap |
| `well_tap_h_spread` | *(ว่าง)* | ระยะแนวนอนระหว่างคอลัมน์ well tap |
| `well_tap_h_offset` | 0 | ตำแหน่งเริ่มของ well tap แรก |
| `well_tap_pattern` | `none` | `none` / `stagger` / `even_rows` / `odd_rows` |
| `pg_rail_method` | `auto` | `auto` / `lef` / `filler` |
| `physical_effort` | `low` | ความพยายามของ physical synthesis |
| `cts_repeaters` | *(ว่าง)* | เซลล์ repeater ของ clock tree |
| `delay_cells` | *(ว่าง)* | เซลล์ delay |
| `tie_high_libcell` | *(ว่าง)* | เซลล์ tie logic ขั้นสูง |
| `tie_low_libcell` | *(ว่าง)* | เซลล์ tie logic ขั้นต่ำ |
| `route_optimize_effort` | `low` | ความพยายามของ router |
| `route_opt_via_effort` | `low` | ความพยายามของการเพิ่ม via |
| `antenna_diodes` | *(ว่าง)* | เซลล์ antenna diode |
| `auto_select_diodes` | 1 | เลือกเซลล์ diode ให้อัตโนมัติ |
| `decap_libcells` | *(ว่าง)* | เซลล์ decap |
| `filler_libcells` | *(ว่าง)* | เซลล์ filler |
| `check_user_defined_filler_libcells` | 0 | ตรวจเซลล์ filler ที่ผู้ใช้กำหนด |
| `filler_avoid_viol` | 0 | ให้ filler หลีกเลี่ยง violation |
| `repair_after_filler` | 1 | ซ่อม DRC หลังใส่ filler |

### 6.3 ตัวแปรของ engine ที่ตั้งได้ด้วย `set_param`

จาก `flow_variables.tcl` ส่วนท้าย

| พารามิเตอร์ | ค่าเริ่มต้น | ความหมาย |
|---|---|---|
| `basic verbose_level` | 0 | ระดับความละเอียดของข้อความ |
| `basic timestamp` | 0 | ใส่ timestamp ในข้อความ |
| `db no_brace_in_oblist` | true | ไม่ใช้วงเล็บปีกกาในรายการ object |
| `db save_all_params` | true | บันทึกพารามิเตอร์ทั้งหมด |
| `db trim_macro_blockage` | 1 | ตัดรูป blockage ของ macro ให้พอดี |
| `ta setup_slack_margin` | 0.0 | ขอบเขต slack ของ setup |
| `ta hold_slack_margin` | 0.0 | ขอบเขต slack ของ hold |
| `ta enable_preset_and_clear_arcs` | true | เปิดการตรวจ arc ของ preset/clear |
| `ta dont_check_clock_gating` | false | ไม่ตรวจ clock gating |
| `ta dont_check_recovery_removal` | false | ไม่ตรวจ recovery/removal |
| `ta default_clock_at_input_port` | false | เดา clock ที่พอร์ต input หรือไม่ |
| `place no_filler1` | false | ไม่ใช้ filler ความกว้าง 1 |
| `place use_min_spacing_rules` | true | ใช้กฎระยะห่างขั้นต่ำ |
| `cts move_commit_table_verbosity` | 0 | ความละเอียดของตาราง commit ของ CTS |
| `opt verbose_level` | 0 | ระดับความละเอียดของ optimizer |
| `opt dont_create_assign` | true | ไม่สร้าง assign ใหม่ |
| `route dont_use_m1_wire` | 0 | ไม่ใช้สาย Metal1 |
| `route max_filler_cell_mask` | 1 | ระดับโลหะสูงสุดในเซลล์ filler |
| `route allow_cell_off_grid` | false | อนุญาตให้เซลล์ไม่ตรง grid |

### 6.4 ข้อมูลตัวอย่าง ADC8 ที่วัดได้จริง

| รายการ | ค่า |
|---|---|
| โมดูล | `ADCCtrl` |
| พอร์ตทั้งหมด | 15 (input 4 / output 11) |
| บัสเอาต์พุต | `B[7:0]` |
| คล็อก | `clk`, คาบเวลา 10000 ns, duty 50% |
| `timescale` ของ RTL | `100ns/1ps` (1 time unit = 100 ns) |
| เลย์เอาต์ | `prBoundray:drawing` (Icon Layer) |
| ขนาดบล็อก | 177.800 × 53.000 µm |
| หน่วย DEF | 1000 DBU = 1 µm |
| พอร์ตอยู่บน | Metal4 — ขอบล่าง 6 / ขอบบน 9 |
| ระยะพอร์ตต่ำสุด | 15.200 µm |
| เทคโนโลยี | Generic 250 nm, Metal1..Metal4, Via1..Via3 |
| site | `CORE`, 1.15 × 8.10 µm |
| เซลล์มาตรฐาน | 22 เซลล์ (LEF และ Liberty เท่ากันแต่ไม่ใช่ชุดเดียวกัน) |
| มุมของกระบวนการ | fast = FF 2.75 V −40 °C, nominal = TT 2.50 V 25 °C, slow = SS 2.25 V 125 °C |
| PTF | `Generic250_MET4_typ`, หน่วยความจุ ff, ความต้านทาน ohm |
| min spacing | Metal3 / Metal4 = 0.5 µm |

### 6.5 สูตรที่ flow ใช้คำนวณแผน power

จาก `ap_ref_flows/tcl_procs/compute_floorplan_details.tcl`

```tcl
set total_widths   [expr ผลรวมของ pg_ring_widths]        # หรือ width เดียว x จำนวนแหล่งจ่าย
set total_spacing  [expr ผลรวมของ pg_ring_spacing]       # หรือ spacing เดียว x (จำนวนแหล่งจ่าย - 1)
set pg_ring_width  [expr $total_widths + $total_spacing]

set width_contrib    = width ของ Vdd + width ของ Gnd
set spacing_contrib  = 2 x spacing แรก
set macro_ring_spacing = 2 x ความสูงของ site          # ถ้าไม่ได้ตั้งไว้เอง
set oversize_m2m     = 2 x (width_contrib + spacing_contrib + macro_ring_spacing)

set ring_offset_<side> = pg_ring_offset_<side> + pg_ring_width
set core_to_<side>    = ring_offset_<side> + core_<side>_spacing
set oversize_b2m      = max(ring_offset ทั้งสี่ด้าน) + oversize_m2m
```

ตัวอย่างที่คำนวณได้จากค่าในคู่มือนี้

| ปริมาณ | ค่า |
|---|---|
| `total_widths` | 3.5 µm |
| `total_spacing` | 0.6 µm |
| `pg_ring_width` | 4.1 µm |
| `width_contrib` | 3.5 µm |
| `spacing_contrib` | 1.2 µm |
| `macro_ring_spacing` | 16.2 µm |
| `oversize_m2m` | 41.8 µm |
| `ring_offset_*` | 4.1 µm ทุกด้าน |
| `oversize_b2m` | 45.9 µm |

### 6.6 ไฟล์ทั้งหมดที่คัดลอกมาในโปรเจกต์นี้

ทั้งหมดมาจากการติดตั้ง Custom IC 2025.4 และชุดตัวอย่าง ADC8

| ไฟล์ต้นทาง | ไฟล์ในโปรเจกต์ | ขนาด |
|---|---|---|
| `...\ADC8\ADC8\ADCCtrl\PNR_Data\from_ledit.def` | `design/from_ledit.def` | 3,287 B |
| `...\ADC8\ADC8\ADCCtrl\PNR_Data\scanchain.tcl` | `design/scanchain.tcl` | 779 B |
| `...\ADC8\ADC8\ADCCtrl\AP_Data\ADCCtrl_rtl.v` | `design/files/ADCCtrl_rtl.v` | 945 B |
| `...\ADCCtrl\STA_Data\files\Generic250nm_tech.lef` | `design/files/…` | 6,900 B |
| `...\ADCCtrl\STA_Data\files\Generic250nm_StdCells.lef` | `design/files/…` | 62,591 B |
| `...\ADCCtrl\STA_Data\files\Generic250nm_TT_2P50V_25C.lib` | `design/files/…` | 377,228 B |
| `...\ADCCtrl\STA_Data\files\Generic250nm_typ.ptf` | `design/files/…` | 159,458 B |
| `...\ADCCtrl\STA_Data\files\timing_constraints.sdc` | `design/files/…` | 73 B |
| `...\Generic_250nm\...\Liberty\Generic250nm_FF_2P75V_M40C.lib` | `design/files/…` | 330,089 B |
| `...\Generic_250nm\...\Liberty\Generic250nm_SS_2P25V_125C.lib` | `design/files/…` | 330,351 B |

ไฟล์ที่คู่มือนี้เขียนขึ้นเอง

| ไฟล์ | รายละเอียด |
|---|---|
| `design/nitro_settings_ADCCtrl.tcl` | ตัวอย่างไฟล์ตั้งค่าตามสัญญาในหัวข้อ 6.1 |
| `design/files/timing_constraints_full.sdc` | SDC ฉบับครบที่เพิ่ม input/output delay |
| `tools/checks/*.js` | ตัวตรวจสอบของ lab 01..06 เขียนขึ้นใหม่ทั้งหมด |
| `tools/run_template.cmd`, `tools/make-runners.ps1` | ตัวสร้าง runner ของแต่ละ lab |
| `docs/parts/*.md` | ต้นฉบับคู่มือ |

### 6.7 ที่มาและลิขสิทธิ์

- คู่มือ **Tanner Digital Implementer (TDI) Self-Paced Tutorial** ของ Siemens EDA
  (รุ่น 2024.3) เป็นเอกสารประกอบการใช้งานของหน้าต่าง Setup TDI
  เอกสารนี้เป็นเอกสารภายในของ Siemens ที่มีข้อกำหนดเรื่องการเผยแพร่
  **คู่มือฉบับนี้จัดทำขึ้นเป็นเอกสารภายในขององค์กร ไม่ควรแจกจ่ายต่อ**
- ไฟล์ตัวอย่าง ADC8, LEF, Liberty, PTF และ SDC เป็นส่วนหนึ่งของ
  **Siemens Custom IC Platform 2025.4** ซึ่งใช้ภายใต้สัญญาอนุญาตของผู้ใช้
- โค้ดตัวตรวจสอบ, ไฟล์ตั้งค่าตัวอย่าง และเอกสารทั้งหมดในโปรเจกต์นี้
  **เขียนขึ้นใหม่** สำหรับคู่มือนี้
- `Tanner`, `L-Edit`, `Nitro`, `Oasys` และ `Siemens EDA` เป็นเครื่องหมายการค้า
  ของ Siemens EDA

### 6.8 สร้างเอกสารใหม่

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-docs.ps1
```

ต้องมี **pandoc** และ **Google Chrome**
สคริปต์จะรวม `docs/parts/*.md` เป็น `docs/Lab_Guide_TDI.md`
แล้วสร้าง HTML และ PDF ต่อ

สร้างไฟล์ ZIP ส่งมอบ

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File tools\make-zip.ps1
```

---
