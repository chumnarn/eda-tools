# Lab 6 — Placement: เปรียบเทียบ utilization 40% และ 60%

หลักสูตร Tanner Digital ASIC Design Implementation — ระดับเริ่มต้นถึงกลาง

## 6.1 วัตถุประสงค์และขอบเขต

เมื่อจบ Lab ผู้เรียนต้องรัน placement จาก floorplan/PDN ที่ตรวจแล้วได้ ตรวจ legal placement ด้วยรายงานของเครื่องมือ และอธิบาย trade-off ระหว่างพื้นที่ timing และ congestion โดยอ้างอิงข้อมูลจริงจากสองรัน

ใช้ digital block สำหรับ analog-on-top จาก Lab 2–5 เช่น counter ที่มี reset และ enable ทั้ง VHDL และ Verilog/SystemVerilog ใช้กระบวนการทดลองเดียวกันหลัง synthesis แต่ต้องเลือก mapped netlist เพียงชุดเดียวเป็น baseline ของการเปรียบเทียบ 40%/60% หากต้องการเปรียบเทียบสองภาษาให้ทำเป็นอีกการทดลองหนึ่ง เพราะ synthesis อาจให้โครงสร้างต่างกัน

Lab นี้สิ้นสุดที่ placement และ pre-CTS optimization ไม่ใช่ผล sign-off หลัง route ไม่รวมการสร้าง full-chip pad ring/ESD/package

**เวลาที่แนะนำ:** 3–4 ชั่วโมง แบ่งเป็นเตรียม baseline 30 นาที รันสองกรณี 60–90 นาที วิเคราะห์ 60 นาที และจัดทำรายงาน 30 นาที เวลารันขึ้นกับขนาดวงจรและเครื่อง

## 6.2 การใช้งาน TDI และข้อกำหนดเรื่องเวอร์ชัน

Siemens อธิบาย Digital Implementer ว่าเริ่ม flow ผ่าน L-Edit มี setup wizard และปรับแต่งด้วย Tcl โดยใช้ Oasys และ Nitro เป็น synthesis/P&R engines [1] เอกสาร white paper แสดงการแยกขั้น import, placement, clock, route และ export ใน reference flow [2]

ชื่อเมนู ชื่อไฟล์ Tcl ตัวเลือก density และคำสั่ง report อาจต่างกันตาม release/PDK/reference flow คู่มือนี้จึงระบุการทำงานที่ต้องทำและหลักฐานที่ต้องได้ ไม่อ้างว่าชื่อเมนูหรือคำสั่ง P&R ใดใช้ได้ทุกเวอร์ชัน ให้ใช้ Help และ generated scripts ของ installation จริงเป็นหลัก ห้ามนำคำสั่งจาก OpenROAD/Innovus/ICC2 มาวางใน Nitro โดยสมมติว่า syntax เหมือนกัน

ก่อนเริ่ม ผู้สอนต้องยืนยันวิธีเลือก stage, save/restore checkpoint, รายงาน legality, timing, area และ congestion ใน reference project ที่ใช้สอน พร้อมแนบชื่อเมนู/คำสั่งจริงใน runbook ของห้องปฏิบัติการ

## 6.3 แนวคิดที่ต้องเข้าใจก่อนทดลอง

### 6.3.1 Placement ทำอะไร

Global placement หาตำแหน่งโดยประมาณตาม connectivity, timing และข้อจำกัดพื้นที่ ระหว่างกระบวนการนี้ cell อาจยังไม่ลง site หรืออาจ overlap ได้ Legalization ย้าย cell ให้สอดคล้องกับ rows, sites, orientation และข้อจำกัดที่เกี่ยวข้อง ส่วน detailed placement ปรับตำแหน่งในระดับละเอียดเพื่อลดต้นทุน เช่น wirelength โดยต้องรักษาความถูกต้อง

Flow อาจรวมหลายขั้นในคำสั่งเดียว หรือสลับ optimization กับ legalization หลายครั้ง ให้ตรวจ checkpoint สุดท้ายหลังขั้นที่อาจเปลี่ยนขนาดหรือแทรก cell อีกครั้ง การรันจบโดยไม่มี fatal error ไม่เท่ากับ legality ผ่าน

### 6.3.2 Utilization มีตัวเศษและตัวส่วน

สำหรับการคำนวณเบื้องต้นของ Lab กำหนด

\[
U_{plan}=A_{cells,baseline}/A_{available,plan}
\]

โดย A_cells,baseline เป็นพื้นที่ mapped cells ที่เลือกนับ และ A_available,plan เป็นพื้นที่วาง cell ตามนิยามที่เลือก หากไม่มี macro/blockage และนิยามใช้ core ทั้งหมด อาจประมาณ A_available,plan ด้วย A_core ได้ แต่เมื่อมีสิ่งกีดขวางหรือพื้นที่สงวนต้องใช้พื้นที่ที่วางได้จริง

เครื่องมืออาจนับ fixed cells, physical-only cells, padding, partial blockage หรือพื้นที่ macro ต่างจากสูตรนี้ ต้องคัดลอกนิยามจากรายงานและระบุ numerator/denominator ทุกครั้ง อย่าเรียก core utilization, row utilization และ local density ว่าเป็นตัวเลขเดียวกัน

**Target utilization** เป็นค่าที่ป้อนเพื่อสร้างหรือกำหนด floorplan ส่วน **actual utilization** เป็นผลที่คำนวณจาก database ณ stage นั้น หลัง buffer insertion/resizing ตัวเศษอาจเปลี่ยน ทำให้ actual ไม่ตรงกับ target

### 6.3.3 การทดลองหลัก: เปลี่ยนขนาด core

ให้ใช้ mapped netlist เดิมและเปลี่ยนพื้นที่ core เพื่อให้เป้าหมาย U เป็น 0.40 และ 0.60 โดยรักษา aspect ratio และนโยบาย floorplan/PDN/pins ให้เหมือนกัน หาก core มี aspect ratio r = W/H:

\[
A_{core}\approx A_{cells}/U,\quad W=\sqrt{A_{core}r},\quad H=\sqrt{A_{core}/r}
\]

ตัวอย่างเพื่อสอนการคำนวณเท่านั้น: A_cells = 10,000 µm², r = 1 และยังไม่มีพื้นที่หักออก

| รายการ | U40 | U60 |
|---|---:|---:|
| Target utilization | 0.40 | 0.60 |
| Core area โดยประมาณ (µm²) | 25,000 | 16,666.67 |
| W = H โดยประมาณ (µm) | 158.11 | 129.10 |

พื้นที่ U60 ลดประมาณ 33.33% จาก U40 และมิติแต่ละด้านลดประมาณ 18.35% ก่อน snapping เป็น row/site ที่อนุญาต ตัวเลขนี้ไม่ใช่ผลรันจริงและไม่ใช่การลด cell area 33.33%

หลัง snapping ให้ใช้ boundary จริงจาก database คำนวณซ้ำ สำหรับวงจรเล็กมาก pin pitch, ring width, margins และจำนวน row ขั้นต่ำอาจเป็นข้อจำกัดหลักจนทำ target ไม่ได้ อย่าฝืนลด core จนผิดกฎ

**การทดลองเสริมคนละแบบ:** คง core เดิมแล้วเปลี่ยน density target ของ placer วิธีนี้เปลี่ยนการกระจาย cell แต่ไม่ได้ทำให้ core area เปลี่ยนเป็น A_cells/U อย่านำผลสองแบบมารวมเป็นตารางเดียวโดยไม่อธิบาย

### 6.3.4 ทำไม 40% ไม่ได้ชนะเสมอ

พื้นที่มากช่วยเผื่อ routing, buffering และ CTS แต่ cell อาจห่างกัน ทำให้สายยาวขึ้น ส่วนพื้นที่น้อยอาจลดระยะบางเส้นทาง แต่เพิ่ม local density, pin-access pressure และ detour ความสัมพันธ์ระหว่าง utilization กับ timing/congestion จึงไม่จำเป็นต้องเป็นเส้นตรง และขึ้นกับ connectivity, pin placement, PG resources และการ optimize

## 6.4 Input และเงื่อนไขก่อนเริ่ม

| Input | สิ่งที่ต้องยืนยัน |
|---|---|
| Mapped netlist จาก Lab 4 | Top ถูกต้อง ไม่มี unresolved functional cell/latch ที่ไม่ตั้งใจ |
| SDC | Clock, input/output delay, drive/load และ timing coverage ตรวจแล้ว |
| Timing libraries | PVT, units และ corner ชัดเจน |
| Physical libraries | LEF/site/row และ cell dimensions ตรงกับ mapped cells |
| Floorplan/PDN จาก Lab 5 | Boundary, pins, supplies และ PG checks มีหลักฐาน |
| Technology/RC settings | Layer directions, routing layers และ RC model ถูกต้อง |
| Reference flow | เปิดได้ รู้ตำแหน่ง stage placement และ output checkpoints |

ห้ามเปรียบเทียบรันที่ใช้ SDC คนละชุดหรือรันหนึ่งไม่มี timing library ครบกับอีกรันหนึ่งที่โหลดครบ ก่อน placement ต้องมี timing baseline ที่ไม่มี unconstrained endpoint โดยไม่ทราบเหตุผล หากมี exception/coverage exclusion ที่อนุมัติให้บันทึกจำนวนและเหตุผล

## 6.5 ขั้นที่ 1 — ตรึง baseline และวางแผนรัน

1. เปิด project ของ Lab 5 ใน L-Edit/TDI และตรวจชื่อ top/library/cell view
2. เก็บ mapped netlist และ SDC เป็น read-only baseline ในพื้นที่งานของหลักสูตร
3. บันทึก tool build, PDK/library release, corner, RC settings และ units
4. เก็บค่า cell count, baseline cell area, sequential count และจำนวน nets
5. กำหนด run IDs เช่น `lab06_u40_s1` และ `lab06_u60_s1`
6. กำหนด aspect ratio, margins, pin policy, PG policy และ optimization effort ก่อนรัน
7. ถ้ามี seed ให้ใช้ค่าเดียวกันในคู่หลัก หากไม่มีให้ระบุว่าไม่ได้ควบคุม seed

โครงสร้างผลลัพธ์ที่แนะนำ:

```text
lab06/
  baseline/        mapped netlist, SDC, library manifest
  u40/            floorplan, settings, logs, checkpoints, reports
  u60/            floorplan, settings, logs, checkpoints, reports
  comparison/     metrics.csv, analysis.md
```

อย่าเริ่ม U60 จาก database หลัง optimization ของ U40 เพราะ cell resizing และ buffer insertion จะกลายเป็นตัวแปรแฝง ให้สร้างแต่ละ floorplan จาก baseline เดียวกันแล้วรันแยก

## 6.6 ขั้นที่ 2 — สร้าง floorplan U40

1. สำเนา configuration ของ Lab 5 ไปยัง run U40 โดยให้ output directory และ checkpoint แยกกัน
2. ตรวจว่าระบบใช้ auto-sizing ตาม utilization หรือ explicit core dimensions หากกำหนดทั้งคู่ ให้ตรวจ precedence ใน Help และ log
3. ถ้าใช้ช่อง utilization ให้ตรวจหน่วยว่าใช้ `40` หรือ `0.40` จาก Help ของ release จริง ห้ามเดา
4. หากใช้ explicit dimensions ให้คำนวณจาก baseline area แล้ว snap ตาม site width และ row height
5. สร้าง rows และตรวจ row count, available sites, orientation และ core margins
6. วาง signal pins ตามนโยบายเดียวกับอีกกรณี เช่น อยู่ด้านเดิม ลำดับเดิม และตำแหน่งสัมพัทธ์ตามด้าน โดยต้องลง routing grid และมี spacing ถูกต้อง
7. สร้าง PG ใหม่สำหรับ boundary ใหม่นี้ ตรวจ ring/strap/rails/vias และ connectivity อีกครั้ง
8. ตรวจ fixed cells, blockages และ reserved regions ไม่ล้ำ core หรือทำให้พื้นที่ใช้งานจริงผิดจากที่ตั้งใจ
9. บันทึก actual core width/height, usable row area และ initial utilization ก่อน placement
10. Save checkpoint หลัง floorplan/PDN ด้วยชื่อที่ระบุ U40 ชัดเจน

การคง PG policy หมายถึงใช้ layer, width, pitch และข้อกำหนดเดียวกันเท่าที่ geometry อนุญาต จำนวน straps อาจต่างกันเมื่อขนาด core ต่าง ต้องบันทึกจำนวนและ routing obstruction ที่เกิดจริง ไม่จำเป็นต้องบังคับจำนวน straps เท่ากันจน topology ไม่เหมาะสม

**จุดตรวจ A:** ไม่มี floorplan/PG failure ที่ยังไม่วิเคราะห์ pins/rows อยู่ในขอบเขต และสามารถย้อนกลับมารัน placement จาก checkpoint นี้ได้

## 6.7 ขั้นที่ 3 — รัน placement U40

1. ตรวจ input checkpoint ที่จะโหลดว่าเป็น U40 หลัง floorplan/PDN ไม่ใช่ checkpoint เก่าหลัง CTS
2. เลือก placement stage ผ่าน GUI หรือ reference script ของ installation
3. ตรวจว่าเปิด timing-driven และ congestion-aware options ตามที่ reference flow รองรับ และใช้ effort ที่ตกลงไว้
4. เริ่มรันและเก็บ full log อย่าเก็บเฉพาะข้อความท้ายหน้าต่าง
5. ตรวจ log ว่าอ่าน netlist/libraries/SDC สำเร็จ จำนวน instances สมเหตุผล และมี clock ที่ต้องการจริง
6. ให้ flow ทำ global placement, legalization, detailed placement และ pre-CTS optimization ตามลำดับของ reference flow
7. ถ้า optimization เพิ่มหรือ resize cells ให้ตรวจ legality ที่ checkpoint สุดท้ายอีกครั้ง
8. Save checkpoint หลัง placement และส่งออก reports ตามหัวข้อถัดไป

หาก GUI เรียกทั้ง flow โดยอัตโนมัติ ให้ใช้วิธีเลือก stage/checkpoint ที่มีเอกสารรองรับ หรือ generated scripts ที่ผู้สอนตรวจแล้ว ไม่ตัดไฟล์ Tcl แบบสุ่ม เพราะอาจข้ามขั้น update database หรือ save ที่จำเป็น

**คำอธิบายลำดับงานต่อไปนี้เป็น pseudocode ไม่ใช่ Nitro command:**

```text
RESTORE floorplan_checkpoint
VERIFY netlist / libraries / constraints / rows / supplies
RUN global_placement
RUN legalization_and_detailed_placement
RUN pre_CTS_optimization_if_enabled
CHECK final_placement_legality
REPORT area / timing / constraints / congestion / wirelength
SAVE placed_checkpoint
```

## 6.8 ขั้นที่ 4 — ตรวจ placement legality

เปิด report/check function ด้าน placement legality ของ release ที่ใช้งาน บันทึกคำสั่งหรือเมนูจริงไว้ในรายงาน เก็บทั้ง summary และรายละเอียด instance ที่ผิด

| หัวข้อ | สิ่งที่ต้องตรวจ | เกณฑ์ของ Lab |
|---|---|---|
| Unplaced instances | Functional cells ที่ควรวางยังไม่มีตำแหน่ง | 0 |
| Cell overlap | Overlap ที่ผิดกฎ รวมกับ fixed cells | 0 |
| Row/site alignment | Cell anchor อยู่บนตำแหน่งที่อนุญาต | 0 violations |
| Orientation | สอดคล้องกับ row/site และ cell symmetry | 0 violations |
| Boundary | Cell ไม่ล้ำ placement region | 0 violations |
| Blockage/region | เคารพ hard blockage และ region constraints | 0 violations |
| Cell spacing/padding | ข้อกำหนดที่ checker รองรับ | 0 unresolved violations |
| Multi-height cells ถ้ามี | วางครอบ rows ตามข้อกำหนด library | 0 violations |

Soft/partial blockages ต้องอ่าน semantics ของ flow อย่าตีความว่าเป็นข้อห้ามเด็ดขาดแบบ hard blockage หาก checker ไม่ครอบคลุมบางหัวข้อให้ระบุว่าไม่ได้ตรวจด้วยวิธีนั้น และใช้ check ที่เหมาะสมเพิ่ม

เปิด layout ดูบริเวณที่หนาแน่น ขอบ core รอบ PG straps และ pins เพื่อช่วยวิเคราะห์ แต่ภาพที่ดูเป็นระเบียบไม่ทดแทนรายงาน legality ทั้งนี้ legal placement ไม่ได้ยืนยัน routing DRC/LVS หรือ PG connectivity โดยอัตโนมัติ

**จุดตรวจ B:** รายงาน legality ผ่าน ณ checkpoint ที่จะใช้วิเคราะห์ และมี log ระบุ stage/time ตรงกัน

## 6.9 ขั้นที่ 5 — เก็บ area และการเปลี่ยนแปลง cell

เก็บ core area, usable row area, standard-cell area และ cell counts แยกกัน ถ้า report รวม tap/endcap/filler/tie/decap ให้ระบุชัดว่า cell area แถวใดรวม physical-only cells

เปรียบเทียบ baseline กับหลัง placement เพื่อหาจำนวน buffer ที่เพิ่ม ขนาด cell ที่เปลี่ยน และสัดส่วนพื้นที่ที่เพิ่มจาก optimization:

\[
\Delta A_{cell}(\%)=100(A_{cell,placed}-A_{cell,baseline})/A_{cell,baseline}
\]

Core area ที่ลดลงไม่ได้แปลว่า cell area ลดลง และ spare placement capacity ไม่ใช่ routing capacity โดยตรง การนับ physical-only cells ต้องสอดคล้องกันทั้งสองรัน

## 6.10 ขั้นที่ 6 — วิเคราะห์ pre-CTS timing

1. ยืนยัน clock เป็น ideal หรือสถานะตาม reference flow จด source/network latency assumptions และ uncertainty
2. ระบุ RC model ว่าเป็น placement-based estimate, trial-route estimate หรือแบบอื่น ห้ามเรียกว่า extracted post-route RC
3. รัน timing update/report หลัง checkpoint สุดท้าย
4. เก็บ setup WNS/TNS, violating endpoints และอย่างน้อย 5–10 worst paths ถ้าวงจรมีพอ
5. แยก path groups เช่น input-to-register, register-to-register และ register-to-output
6. ตรวจ max transition, max capacitance และ max fanout ตามข้อกำหนด library/flow
7. เก็บ clock coverage/unconstrained endpoints อีกครั้ง เพื่อยืนยันว่า WNS ดีไม่ได้เกิดจาก path หาย
8. ถ้ามี min-delay report ให้เก็บเป็นข้อมูลคัดกรองก่อน CTS พร้อมอธิบายว่า clock tree จริงยังไม่ถูกสร้าง

สำหรับแต่ละ worst path ให้บันทึก startpoint, endpoint, group, corner, arrival, required, slack, logic depth, cell/net delay, fanout และ estimated wirelength ถ้ามี เมื่อ path เปลี่ยนอันดับให้เทียบทั้ง worst path ของแต่ละรันและคู่ startpoint/endpoint เดียวกันเท่าที่ทำได้

หาก U60 timing ดีขึ้น ให้ตรวจว่าเกิดจากสายสั้นลงหรือจากเพิ่มขนาด cell/เพิ่ม buffers หาก timing แย่ลงให้ตรวจ congestion, detour estimate, fanout และ local density ก่อนสรุปว่า utilization เป็นสาเหตุเพียงตัวเดียว

**ข้อจำกัด:** pre-CTS setup ผ่านไม่รับประกัน setup/hold หลัง CTS และ route ส่วน hold failure ก่อน CTS ต้องพิจารณาความถูกต้องของ min libraries, IO delays และ ideal-clock assumptions ไม่แก้ด้วยการแทรก delay แบบสุ่ม

## 6.11 ขั้นที่ 7 — วิเคราะห์ congestion และ wirelength

1. เปิด congestion analysis ที่ reference flow รองรับ หากต้องรัน trial/global route ให้ทำบนสำเนา checkpoint และใช้ settings เดียวกันทั้งสองกรณี
2. บันทึก stage, routing layers, grid/bin dimensions, PG obstruction และวิธีประมาณ capacity
3. เก็บ peak demand/capacity ratio, overflow, จำนวน congested bins และแยกแนว horizontal/vertical หรือราย layer เท่าที่มี
4. ส่งออก heatmap พร้อม legend, units และ scale เดียวกันสำหรับภาพเปรียบเทียบ ถ้าต้องใช้ scale ต่างกันให้ระบุชัด
5. ตรวจอย่างน้อยสามบริเวณ: ขอบที่มี pins หนาแน่น กลุ่ม sequential/combinational cells หนาแน่น และบริเวณที่ PG/blocked layers ลด routing resources
6. เก็บ wirelength โดยบอกชนิด เช่น HPWL, estimated routed length หรือ trial-route length อย่าเปรียบเทียบตัวเลขคนละชนิด

นิยามเพื่ออธิบายแนวคิดเท่านั้น สำหรับ bin b และทิศ/ชั้นที่ระบุ:

\[
R_b=D_b/C_b,\quad O_b=\max(0,D_b-C_b)
\]

R_b > 1 หมายถึง demand เกิน capacity ในโมเดลนั้น หาก C_b = 0 ต้องใช้กติกาของเครื่องมือ ไม่หารตรง ๆ การรวม overflow และหน่วยขึ้นกับเครื่องมือ ห้ามรวมคนละชั้นหรือทิศเองโดยไม่มีนิยาม

Overflow เป็นศูนย์ใน estimated global routing ไม่ยืนยัน detailed routing/pin access ผ่าน และ local density สูงไม่เท่ากับ congestion เสมอไป สำหรับ counter ขนาดเล็กทั้งสองรันอาจไม่มี congestion ซึ่งเป็นผลที่รายงานได้ หากต้องการ stress test ให้ใช้ design ที่ใหญ่ขึ้นเป็นการทดลองเสริมและตรึง design นั้นก่อนเริ่มคู่เปรียบเทียบใหม่

หากไม่มี congestion engine/report ในชุดเครื่องมือที่ใช้ ให้รายงาน `N/A — ไม่ได้ตรวจ` พร้อมเหตุผล ใช้ wirelength และภาพช่วยวิเคราะห์ได้ แต่ห้ามสรุปว่า congestion ผ่านจากภาพหรือ utilization เพียงอย่างเดียว

## 6.12 ขั้นที่ 8 — สร้างและรัน U60

1. กลับไปใช้ baseline mapped netlist/SDC เดิม
2. ทำขั้นสร้าง floorplan ใหม่โดยเปลี่ยน target เป็น 60% หรือปรับ core dimensions ตามสูตร
3. รักษา aspect ratio, pin-side/order policy, PG policy, corners, RC settings และ placement effort เดิม
4. Regenerate rows/pins/PG และตรวจ Lab 5 checks ใหม่ เพราะ geometry เปลี่ยน
5. รัน placement และเก็บ legality/area/timing/congestion ด้วยวิธีเดียวกับ U40
6. ตรวจ input fingerprints และ run manifest ว่าไม่มีการเปลี่ยน netlist/constraints โดยไม่ตั้งใจ
7. หาก U60 ล้มเหลว ให้เก็บ log และ checkpoint ที่ล้มเหลว วิเคราะห์แล้วแก้เป็น run ID ใหม่ เช่น `u60_fix01` ไม่เขียนทับหลักฐานเดิม

ถ้าต้องประเมินความผันผวน ใช้หลาย seed เช่น 3 seeds ต่อ utilization โดยจับคู่ seed ให้ตรงกันและรายงานช่วงผล การทดลองขั้นต่ำหนึ่งคู่ยังใช้เรียนรู้ได้ แต่ไม่ควรอ้างว่าความต่างเล็กน้อยมีนัยสำคัญแน่นอน

## 6.13 ขั้นที่ 9 — ตารางบันทึกผลจริง

กรอกค่าจาก reports เท่านั้น ใช้ `N/A` เมื่อไม่มีข้อมูล ระบุ units และชื่อ report/checkpoint ที่มา

| Metric | U40 | U60 | ข้อสังเกต/หลักฐาน |
|---|---|---|---|
| Tool build / PDK / corner | | | ต้องตรงกัน |
| Netlist / SDC fingerprint | | | ต้องตรงกัน |
| Actual core W × H (µm) | | | หลัง snapping |
| Core area (µm²) | | | Boundary จริง |
| Available row area (µm²) | | | นิยามที่ใช้ |
| Baseline cell area (µm²) | | | ต้องตรงกัน |
| Post-place cell area (µm²) | | | ระบุการรวม physical-only |
| Target / actual utilization (%) | | | ระบุ numerator/denominator |
| Functional cells / inserted buffers | | | ระบุ stage |
| Unplaced / overlaps / other legality | | | แยกจำนวนแต่ละประเภท |
| Setup WNS (ns) | | | Group/corner |
| Setup TNS (ns) / violating endpoints | | | นิยาม/coverage ตรงกัน |
| Unconstrained endpoints | | | แนบเหตุผลที่ยอมรับ |
| Slew / cap / fanout violations | | | แยกประเภท |
| Wirelength (µm) | | | ระบุ HPWL หรือ route estimate |
| Congestion method / grid | | | ต้องเทียบกันได้ |
| Peak ratio / overflow / congested bins | | | หน่วยตาม report |
| Runtime / peak memory | | | เครื่องและ threads เดียวกัน |

คำนวณการลดพื้นที่จากฐาน U40:

\[
Saving_{core}(\%)=100(A_{40}-A_{60})/A_{40}
\]

สำหรับ slack ใช้ความต่างแบบ ns: ΔWNS = WNS60 − WNS40 ค่าบวกหมายถึง setup WNS ดีขึ้นในเงื่อนไขที่เทียบได้ หลีกเลี่ยงเปอร์เซ็นต์การเปลี่ยน WNS เมื่อค่าใกล้ศูนย์หรือข้ามเครื่องหมาย

## 6.14 ขั้นที่ 10 — สรุปผลและเลือก checkpoint สำหรับ CTS

เขียนข้อสรุป 1–2 หน้า โดยตอบตามลำดับ:

1. สองรันเทียบกันได้หรือไม่ มีตัวแปรใดเปลี่ยนนอกเหนือจาก floorplan size และผลตามธรรมชาติของการเปลี่ยน geometry
2. Legal placement ผ่านหรือไม่ อ้างชื่อรายงานและจำนวน violation
3. ได้พื้นที่ลดลงเท่าใด โดยแยก core area กับ cell area
4. Timing เปลี่ยนเท่าใด path ประเภทใดเป็นตัวกำหนด และ RC/clock assumptions คืออะไร
5. Congestion เปลี่ยนตรงไหน มี overflow/pin-access concern หรือไม่ และตรวจด้วยวิธีใด
6. เหลือพื้นที่และ routing resources สำหรับ CTS/hold repair เพียงใด มีข้อบ่งชี้อะไรสนับสนุน
7. เลือกรันใดไป CTS และต้องยืนยันอะไรหลัง CTS/route

อย่าเลือก 60% เพียงเพราะเล็กกว่า หรือเลือก 40% เพียงเพราะ density ต่ำกว่า ให้ใช้ legality เป็นเงื่อนไขพื้นฐาน แล้วพิจารณา timing/routability margin และข้อกำหนด boundary ของ analog top ร่วมกัน ถ้าทั้งสองกรณีไม่เหมาะสมให้เสนอ utilization กลาง เช่น 50% เป็นรันใหม่พร้อมเหตุผล

## 6.15 ตารางแก้ปัญหา

| อาการ | ตรวจอะไรเป็นอันดับแรก | แนวทางแก้และหลักฐานหลังแก้ |
|---|---|---|
| Unplaced cells | Available sites, fixed objects, regions, cell height | แก้ rows/region หรือเพิ่มพื้นที่ แล้วรัน legality |
| Overlap หลัง optimization | มี legalization หลัง resize/insert หรือไม่ | ใช้ขั้น legalize ที่ flow รองรับแล้วตรวจซ้ำ |
| Orientation ผิด/rail alignment มีปัญหา | Site symmetry, row orientation, library consistency | แก้ tech/row setup และตรวจ PG ตาม Lab 5 |
| Target 60% แต่ actual ต่างมาก | หน่วย input, floorplan precedence, snapping, area definition | ใช้ dimensions และรายงาน denominator จริง |
| WNS ดีมากผิดปกติ | Clocks/IO constraints, unresolved cells, path coverage | แก้ coverage แล้วออกรายงานใหม่ |
| U60 timing แย่ | Fanout, density hotspots, resize/buffers, net delay | วิเคราะห์ path แล้วทำ controlled rerun |
| Congestion ที่ขอบ | Pin concentration, access layers, PG obstruction | กระจาย pins/เพิ่มพื้นที่ โดยแยกรันปรับปรุงจากคู่หลัก |
| Congestion กลาง core | Connectivity cluster, blockages, straps, layer capacity | ปรับ density/placement constraints โดยมี report รองรับ |
| U40 สายยาวมาก | Pin policy, connectivity, cell spreading | พิจารณา core เล็กลงหรือ grouping ที่ flow รองรับ |
| รันจบแต่ไม่มี congestion report | Analysis stage ไม่ทำงานหรือไม่รองรับ | ระบุ N/A หรือใช้ trial route ที่ยืนยันแล้ว |
| Tiny design ได้ผลเหมือนกัน | จำนวน cells และ minimum floorplan limits | รายงานตามจริง เพิ่ม design เสริมโดยไม่ปะปนผล |

ทุกครั้งที่แก้ boundary/pins/rows/PG ต้องตรวจ floorplan/PG ที่เกี่ยวข้องใหม่ ทุกครั้งที่แก้ netlist/SDC/library ต้องสร้าง baseline ใหม่และรันทั้งสองกรณีใหม่ก่อนอ้างการเปรียบเทียบ

## 6.16 แบบฝึกหัดเพิ่มเติม

1. คำนวณ core dimensions สำหรับ 50% จาก baseline จริง เทียบกับขนาดหลัง snapping และอธิบายผลต่าง
2. เลือก critical path เดียวกันจาก U40/U60 แยกผล cell delay กับ net delay
3. ทำ pin-placement variant เพียงหนึ่งรันและวิเคราะห์ว่า hotspot เคลื่อนอย่างไร โดยคงคู่หลักเดิมไว้
4. ถ้าเครื่องมือรองรับ ให้เทียบ congestion estimate หลัง placement กับ global route บนสำเนา checkpoint อธิบายข้อจำกัดของแต่ละโมเดล
5. ระบุเหตุผลสามข้อที่ legal placement แล้วยังอาจ route ไม่ผ่าน
6. อธิบายเหตุใด buffer count และ cell area อาจเพิ่มขึ้นเมื่อพยายามแก้ timing

## 6.17 สิ่งที่ส่งและเกณฑ์ผ่าน

ส่ง baseline manifest, settings ของ U40/U60, floorplan/placed checkpoints, full logs, legality/area/timing/congestion reports, ภาพเปรียบเทียบที่มี scale และตารางผลพร้อมข้อสรุป

**เกณฑ์ผ่านหลัก:**

- ทั้งสองกรณีใช้ baseline และ analysis conditions ที่เทียบกันได้
- ทั้งสอง final placement checkpoints legal ตาม checks ที่รองรับ ไม่มี unresolved placement violations
- ตรวจ timing coverage และอธิบาย exceptions/exclusions ครบ ไม่ใช้ WNS จาก analysis ที่ไม่สมบูรณ์
- วิเคราะห์ cell/core area, timing และ congestion โดยอ้าง report จริง หากไม่มี congestion check ต้องระบุข้อจำกัดและยังไม่อ้างว่าผ่านด้าน routability
- ระบุรันที่เลือกไป CTS พร้อมความเสี่ยงและรายการตรวจต่อ

Lab นี้เน้น **legal placement และคุณภาพการวิเคราะห์** จึงไม่จำเป็นต้องบังคับให้ทุก utilization มี setup WNS ≥ 0 หาก timing ยังไม่ผ่าน ผู้เรียนต้องแสดง path analysis และแผนแก้ก่อนส่งต่อ กรณีหนึ่งรันทำ legal placement ไม่ได้ ให้ถือว่าเป็นผลทดลองที่มีประโยชน์แต่ยังไม่ผ่านเป้าหมายทั้งสองกรณี ต้องแก้แล้วส่งรันใหม่ หรือได้รับการปรับขอบเขต Lab จากผู้สอน

**Rubric แนะนำ:** reproducibility 20%, legality 25%, area/utilization 15%, timing 20%, congestion และการเลือกแนวทาง 20%

## 6.18 Checklist ก่อนเริ่ม Lab 7 — CTS

- [ ] เปิด placed checkpoint ที่เลือกได้และระบุ run ID ชัดเจน
- [ ] Final legality report ผ่านและตรงกับ checkpoint
- [ ] Clock/reset/pins/PG และ timing constraints ถูกต้อง
- [ ] รู้ว่า clock ปัจจุบันเป็น ideal/propagated ตามสถานะใด
- [ ] มี pre-CTS timing baseline และข้อจำกัด RC model
- [ ] บันทึก congestion hotspots และ capacity สำหรับ optimization ต่อ
- [ ] มี known issues และแผนยืนยัน setup/hold หลังสร้าง clock tree

## เอกสารอ้างอิงและขอบเขตการตรวจสอบ

[1] Siemens, **Digital Implementation** — ภาพรวม L-Edit wizard, Tcl customization และ Oasys/Nitro engines: https://www.siemens.com/en-us/products/ic/ic-custom/ams/digital-implementer/

[2] Siemens, **A full-flow solution for analog/mixed-signal IC design** — ภาพรวม digital implementation และ reference-flow stages: https://static.sw.cdn.siemens.com/siemens-disw-assets/public/1xqViRATpGkS6iFOXguaxE/en-US/Siemens-SW-Full-flow-solution-for-analog-mixed-signal-IC-design-WP-84095-D9.pdf

[3] เอกสารที่ต้องตรวจใน installation จริง: Nitro command reference, user manual, TDI generated scripts และ PDK/reference-flow documentation ของ release ที่ห้องปฏิบัติการใช้

ตรวจแหล่งข้อมูลสาธารณะวันที่ 16 ตุลาคม 2026 คู่มือนี้เป็นขั้นตอนการทดลองและแม่แบบวิเคราะห์ ยังไม่ได้รันบน TDI/PDK ของห้องปฏิบัติการ ไม่มีผล benchmark จริงหรือการรับรองว่าเมนู/คำสั่งตรงกับทุก release
