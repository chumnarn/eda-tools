# Module 7 — Placement และ Clock Tree Synthesis (CTS)

## 7.1 เป้าหมายและขอบเขต

Placement เปลี่ยน netlist ที่ผ่าน technology mapping ให้เป็นตำแหน่งของ standard cells บน placement rows ส่วน CTS สร้างวงจรกระจาย clock จากจุดอ้างอิงไปยัง clock sinks โดยใช้ clock buffers/inverters และสายเชื่อมต่อ ทั้งสองขั้นตอนทำให้โครงสร้างทางตรรกะกลายเป็นวงจรที่มีข้อจำกัดทางกายภาพชัดเจนขึ้น แต่ยังต้องผ่าน routing, extraction และ timing verification ต่อไป

เมื่อจบโมดูล ผู้เรียนต้องสามารถ:

1. แยก placement legality ออกจาก placement quality และ routability
2. อธิบาย density, utilization, HPWL, congestion และผลต่อ timing
3. วิเคราะห์ high-fanout nets โดยพิจารณา load และระยะทางร่วมกับจำนวน sinks
4. แยก ideal clock, source latency, network latency และ propagated clock
5. อ่าน insertion delay, skew, transition และ capacitance ของ clock network
6. คำนวณผลของ skew ต่อ setup/hold และวางแผนแก้ไขหลัง CTS
7. ส่งต่อฐานข้อมูลและรายงานที่ตรวจสอบย้อนกลับได้

**บริบท Tanner Digital ASIC Design Implementation:** ใช้แนวคิดและรายการตรวจในบทนี้กับเครื่องมือ placement/CTS ที่ติดตั้งจริงในหลักสูตร ชื่อเมนู คำสั่ง และความสามารถขึ้นกับผลิตภัณฑ์ รุ่น และ license จึงไม่ถือว่าคำสั่ง OpenROAD ในบทนี้เป็นคำสั่งของ Tanner Digital Implementer หรือ Aprisa ตัวอย่าง Tcl มีไว้แสดงลำดับงานผ่านเครื่องมืออ้างอิงที่มีเอกสารสาธารณะ

## 7.2 ข้อมูลนำเข้าและเงื่อนไขก่อนเริ่ม

| ข้อมูล | สิ่งที่ต้องตรวจ | ผลเมื่อไม่ถูกต้อง |
|---|---|---|
| Mapped netlist | ไม่มี unresolved references, undriven nets หรือ latch ที่ไม่ตั้งใจ | วางได้ไม่ครบหรือ timing ไม่สะท้อนวงจรจริง |
| Technology/cell LEF | site, row height, pin shapes, obstruction และชื่อ cell | off-grid, pin access ยาก หรือ cell ไม่เข้ากับ rows |
| Liberty | PVT, timing arcs, pin capacitance และหน่วย | delay/load ผิด หรือ clock sink ถูกตีความผิด |
| Floorplan | core, rows, macro halo, blockages, pin locations | density สูงเฉพาะจุดหรือช่อง routing ไม่พอ |
| SDC | clocks, generated clocks, I/O delay, uncertainty และ exceptions | WNS/TNS ดูดีโดยมี paths ไม่ได้รับการตรวจ |
| RC model | ค่าที่ใช้ประมาณ signal/clock wires และ corner | timing ก่อน route คลาดเคลื่อนมาก |
| Cell policy | allowed buffers, dont_use, dont_touch, voltage domains | repair/CTS สร้าง cell ไม่ได้หรือข้าม domain ผิด |

ก่อนเริ่มให้บันทึกจำนวน sequential cells, clock sinks, cell area และจำนวน endpoints ที่ unconstrained เป็น baseline ระบุว่า cell area รวม physical-only cells หรือไม่ และพื้นที่ในตัวหาร utilization หัก macros/blockages อย่างไร

หากมีหลาย power domains ต้องตรวจความพร้อมของ level shifters, isolation และ supply ของ clock buffers ตาม power intent ด้วย การต่อ clock ครบในเชิง netlist ไม่ยืนยันว่า clock tree ได้รับไฟเลี้ยงถูก domain

## 7.3 ลำดับการทำ Placement

### 7.3.1 Global placement

Global placement หาตำแหน่งโดยรวมของ cells ภายใต้ข้อจำกัดพื้นที่และวัตถุประสงค์ เช่น ลด wirelength ลดความหนาแน่น และให้ความสำคัญกับ critical nets ตำแหน่งระหว่าง optimization อาจมี overlap หรือยังไม่ตรง legal sites จึงยังไม่ใช่ผลพร้อมส่ง routing

แบบจำลองเชิงแนวคิด:

\[
J = w_W W + w_D D + w_T T + w_C C
\]

โดย W คือ wirelength cost, D คือ density penalty, T คือ timing penalty และ C คือ congestion penalty สมการนี้ใช้สอน tradeoff ไม่ใช่สมการภายในที่รับรองสำหรับทุกเครื่องมือ น้ำหนักและรูปแบบ cost แตกต่างกันตาม algorithm

Timing-driven placement มักให้น้ำหนักกับ critical nets มากขึ้น แต่หาก clocks หรือ I/O constraints ไม่ครบ เครื่องมือจะเร่ง paths ตามโจทย์ที่ไม่ครบถ้วน Routability-driven placement อาจยอมเพิ่ม wirelength เพื่อกระจาย cells ออกจากบริเวณที่ routing demand สูง

### 7.3.2 Legalization และ detailed placement

Legalization ย้าย cells ไปยัง sites ที่ถูกต้องและแก้ overlap จากนั้น detailed placement ปรับตำแหน่งเฉพาะที่เพื่อปรับปรุงคุณภาพ ทั้งสองหน้าที่อาจรวมอยู่ในคำสั่งเดียวของบางเครื่องมือ

รายการตรวจ placement legality ได้แก่:

- Cell อยู่ภายในขอบเขตและ region ที่อนุญาต
- ตำแหน่งตรง site grid และสัมพันธ์กับ row geometry
- ไม่มี overlap ที่ผิดกฎระหว่าง standard cells, macros และ fixed objects
- Orientation สอดคล้องกับ LEF symmetry และ row orientation
- Cell height/site เข้ากับ rows โดยเฉพาะ mixed-height libraries
- เคารพ placement blockages, fences และข้อจำกัดของ power domain
- ไม่มี instance ที่ต้องวางแต่ยังเป็น unplaced

การตรวจ placement legality **ไม่ครอบคลุม** routed-metal DRC, power connectivity, LVS หรือ timing closure ต้องมีการตรวจแยกตามหน้าที่

ทุกครั้งที่ sizing, buffer insertion หรือ ECO ทำให้ geometry เปลี่ยน ควรทำ legalization และตรวจซ้ำตาม flow เพราะวงจรที่เคย legal อาจเกิด overlap หลังเปลี่ยน cell width

## 7.4 Density, utilization และพื้นที่สำรอง

นิยามตัวอย่าง:

\[
U_{place}=\frac{\sum A_{movable\ cells}}{A_{eligible\ placement\ rows}}
\]

นี่เป็นนิยามเพื่อการสื่อสารในบทเรียน ไม่ควรนำค่าในรายงานคนละเครื่องมือมาเปรียบเทียบจนกว่าจะตรวจตัวเศษและตัวหาร Global-placement target density, reported core utilization และ local bin density อาจเป็นคนละค่า

ตัวอย่าง rows ที่ใช้วางได้ 100,000 µm² และ movable cells รวม 60,000 µm² ให้ utilization 60% ถ้า CTS และ timing repair เพิ่ม cells 8,000 µm² จะเพิ่มเป็น 68% เมื่อใช้ตัวหารเดิม ตัวอย่างนี้ยังไม่รวมการเปลี่ยนแปลงจาก blockages หรือ padding ที่ flow อาจนำมาคิดต่างกัน

**Local density สำคัญกว่าค่าเฉลี่ยเพียงตัวเดียว:** ทั้ง block อาจมี utilization 55% แต่บริเวณหน้า SRAM มี local density สูงและ pin จำนวนมาก ทำให้ routing ผ่านไม่ได้ ขณะที่อีกด้านยังมีพื้นที่ว่าง

พื้นที่สำรองควรรองรับ clock buffers, signal buffers, hold delay cells, gate sizing, tie cells และ physical cells ตามลำดับของ flow อย่านับ whitespace ทั้งหมดว่าเป็นพื้นที่ routing เพราะสาย routing ใช้หลายชั้นเหนือ cells และถูกจำกัดด้วย pin access, power straps, vias และ layer rules

Placement padding ช่วยกันพื้นที่รอบ cells เพื่อปรับ pin access แต่ทำให้ capacity สำหรับการวางลดลง หากเพิ่ม padding กว้างทั้ง block อาจทำให้ legalization ล้มเหลว ควรเริ่มจากบริเวณหรือ cell กลุ่มที่มีหลักฐานว่าเป็นปัญหา

## 7.5 Wirelength และ congestion

### 7.5.1 HPWL

Half-perimeter wirelength ของ net n ประมาณจาก bounding box ของ pins:

\[
HPWL_n=(x_{max}-x_{min})+(y_{max}-y_{min})
\]

ถ้า pins อยู่ที่ (10,10), (50,20), (30,70) µm จะได้ HPWL = 40 + 60 = 100 µm ค่านี้เป็นตัวประมาณ ไม่ใช่ความยาว routed wire จริงของ net หลายขา และไม่รวมรายละเอียด detours, vias หรือชั้นโลหะ

HPWL ลดลงอาจช่วยลด RC แต่ไม่ได้รับรอง timing เพราะ drive strength, input slew, pin capacitance, routing layer และ coupling ยังมีผล การอัด cells ให้ใกล้กันเกินไปอาจลด HPWL แต่เพิ่ม congestion จนสายจริงต้องอ้อม

### 7.5.2 Congestion

แบ่งพื้นที่เป็น routing bins/edges แล้วเปรียบเทียบ demand กับ capacity:

\[
R=\frac{Demand}{Capacity},\qquad Overflow=\max(0,Demand-Capacity)
\]

ต้องระบุว่ารายงานเป็นทิศทางใด ชั้นใด และรวมอย่างไร ค่า density overflow ของ global placer ไม่ใช่ routing overflow จึงใช้แทนกันไม่ได้

สาเหตุที่พบบ่อย ได้แก่ macro channels แคบ, bus จำนวนมากตัดผ่านบริเวณเดียว, pins รวมอยู่ด้านเดียว, high-fanout nets กระจายทั่ว block และ PDN กิน routing resources มากในตำแหน่งสำคัญ

แนวทางแก้ตามต้นเหตุ:

| หลักฐาน | แนวทางทดลอง | สิ่งที่ต้องตรวจหลังแก้ |
|---|---|---|
| Hotspot รอบ macro pins | ปรับ macro orientation/ช่องว่างหรือ pin assignment ที่อนุญาต | bus distance และ timing |
| Local cell density สูง | ลด target density หรือเพิ่ม partial blockage | legalization และ critical-path length |
| สายต้องผ่านคอขวด | ปรับ floorplan/ช่อง routing | พื้นที่และ PDN |
| Cell pin access ยาก | selective padding หรือเปลี่ยน cell ที่เหมาะสม | area และ detailed-route DRC |
| Buffers เพิ่มมากหลัง repair | ตรวจ constraint, fanout และตำแหน่ง sinks | transition/load และ clock/data timing |

การเพิ่ม routing layers หรือเปลี่ยน PDN ต้องอยู่ในข้อจำกัด PDK และ power integrity การแก้ congestion โดยลด power straps โดยไม่วิเคราะห์ IR/EM อาจสร้างปัญหาที่รุนแรงกว่าเดิม

## 7.6 High fanout และ buffering

Fanout คือจำนวน loads ตามนิยามของรายงาน ขณะที่ electrical load เกี่ยวข้องกับ capacitance ของ pins และสาย:

\[
C_{load}\approx\sum_i C_{pin,i}+C_{wire}
\]

Net ที่มี 100 sinks ใกล้กันอาจขับง่ายกว่า net 30 sinks ที่กระจายไกล และ fanout limit ใน Liberty อาจใช้ fanout_load ซึ่งไม่เท่ากับจำนวน pins แบบตรงไปตรงมา ต้องตรวจวิธีรายงานของเครื่องมือ

Buffer tree แบ่งภาระและระยะทางออกเป็นช่วง ลด RC delay ของสายยาวและช่วย transition แต่เพิ่ม stage delay, power, area และ routing demand จึงไม่ใช่ว่ายิ่งใส่ buffers มากยิ่งดี

| Net | แนวทาง | ประเด็นสำคัญ |
|---|---|---|
| Clock | ให้ CTS/clock optimization จัดการ | skew, slew, pulse width และ clock gates |
| Synchronous enable | signal buffering หรือ replication ที่ flow รองรับ | setup/hold ของทุก destination |
| Asynchronous reset | reset-tree strategy ตามข้อกำหนด | recovery/removal และ reset-release architecture |
| Scan enable/test control | วิเคราะห์ตาม operating/test modes | mode constraints และ fanout |
| Tie-high/tie-low | ใช้ tie-cell strategy ของ PDK | fanout/ระยะทางและข้อกำหนด reliability |

การ buffer asynchronous reset ไม่ทดแทน asynchronous-assert/synchronous-deassert architecture และการแก้ high fanout ไม่ทดแทน CDC/RDC treatment ห้ามแก้ปัญหาโดย false-path กว้าง ๆ จนซ่อน paths ที่ควรตรวจ

หลัง buffering ให้ตรวจ max transition, max capacitance และ fanout ตามข้อกำหนดจริง พร้อม re-legalize และตรวจ timing อีกครั้ง

## 7.7 Ideal clock และ propagated clock

### Ideal clock

ในช่วงก่อน CTS clock network ยังไม่ถูกสร้างครบ จึงมักวิเคราะห์แบบ ideal clock โดย STA ไม่คำนวณ delay/slew ของ clock distribution network แบบ propagated ตาม cells และ wires จริง ทั้งนี้ ideal clock **ไม่ได้หมายถึง latency หรือ uncertainty เป็นศูนย์เสมอไป** ผู้ใช้สามารถกำหนด estimated latency, clock transition และ uncertainty ไว้ได้

### Propagated clock

หลังสร้าง clock tree ให้ STA คำนวณ clock arrival ผ่าน arcs ของ clock cells และ RC ของสายตามข้อมูลที่มี Post-CTS ก่อน route ยังอาจใช้ estimated parasitics จึงยังไม่เท่ากับ post-route extracted timing

แยก latency เป็น:

- **Source latency:** เวลาในส่วนก่อนจุดนิยาม clock เช่น external source/ส่วนที่ model ไว้นอก block
- **Network latency:** เวลาใน distribution network จากจุดนิยามไปยัง sink

เมื่อเปลี่ยนเป็น propagated clock ต้องตรวจการจัดการ estimated network latency เดิมตาม semantics ของเครื่องมือ ไม่บวก network estimate ซ้ำกับ network delay ที่คำนวณจริง ส่วน source latency อาจยังต้องอยู่ตาม clock boundary เดิม

Clock uncertainty ก่อน CTS อาจรวม budget ของ skew และ jitter หลัง CTS สามารถปรับส่วน estimated skew เมื่อมีการวิเคราะห์ skew จริงแล้วตาม methodology แต่ไม่ควรลบ uncertainty ทั้งหมด เพราะ jitter และ residual modeling margin ยังมีอยู่ ต้องระวังการนับ margin ซ้ำกับ OCV/derating เช่นกัน

Generated clocks ต้องกำหนด source, divide/multiply และ edge relationship ให้ถูกต้อง การสร้าง tree ให้สายที่ออกจาก divider ไม่ได้ทำให้ STA รู้ความสัมพันธ์กับ master clock โดยอัตโนมัติในทุก flow

## 7.8 CTS สร้างอะไร และ optimize อะไร

CTS เริ่มจาก clock root, sinks และ constraints จากนั้นแบ่งกลุ่ม sinks เลือก clock cells สร้าง topology และวาง buffers เพื่อควบคุม delay, skew, slew และโหลดภายใต้พื้นที่ที่ใช้ได้

ข้อมูลที่ต้องเตรียม ได้แก่ clock roots และ sink counts, allowed clock buffers/inverters, clock-gating structure, macro clock pins, routing layers/RC, dont_touch policy และข้อจำกัดของ power domains

เป้าหมายอาจประกอบด้วย:

1. ให้ sinks ที่ตั้งใจทุกจุดเชื่อมต่อและมี clock polarity ถูกต้อง
2. ควบคุม clock transition และ capacitance ตลอด tree
3. ควบคุม skew ของ sinks/path groups ที่สัมพันธ์กัน
4. จำกัด insertion delay, area และ clock power
5. หลีกเลี่ยง placement/routing ที่ทำให้ tree สร้างจริงไม่ได้

Clock gating ควรใช้ cells/architecture ที่รองรับการป้องกัน glitches และมี clock-gating timing checks การแทรก AND gate ใน RTL เพื่อ gate clock โดยตรงไม่ใช่สิ่งที่ CTS จะทำให้ปลอดภัยเอง Multi-clock, gated-clock และ macro branches อาจมี stop/exclude/balance behavior ต่างกัน ต้องตรวจ sink classification จากรายงานจริง

## 7.9 ตัวชี้วัดของ clock network

### Insertion delay

ในบทนี้นิยาม insertion delay เป็น network delay จาก clock root ที่กำหนดไปยัง sink ต้องเขียนจุดเริ่มและจุดสิ้นสุดเสมอ เพราะบางรายงานใช้ขอบเขตต่างกัน ควรดู min/max และ distribution ไม่ใช่เพียง average

### Skew

สำหรับคู่ launch/capture ให้กำหนด:

\[
S=L_C-L_L
\]

เมื่อ S เป็นบวก capture clock มาช้ากว่า launch clock ส่วน global skew ภายใต้ scenario/edge เดียวกันมักหมายถึง max sink arrival − min sink arrival ซึ่งไม่ใช่ skew ของทุก timing path โดยตรง และไม่ควรรวม sinks ของ unrelated clocks เป็นตัวเลขเดียว

### Transition และ clock load

Clock transition คือ rise/fall slew ที่ pins ซึ่งต้องผ่านข้อจำกัดและอยู่ในช่วงที่ library model รองรับ Clock load คือ capacitance ที่ stage นั้นขับ ไม่ใช่แค่ clock pin capacitance ของ flip-flops ทั้ง block ต้องตรวจ intermediate buffers, long branches และ macro sinks ด้วย

Slew ช้ามากทำให้ clock-cell delay และ sequential-cell timing เปลี่ยน เพิ่ม short-circuit power และอาจผิด max-transition constraint Slew เร็วที่สุดก็ไม่ใช่เป้าหมายสากล เพราะใช้ drive strength และพลังงานมากขึ้น

ตรวจ minimum pulse width, duty cycle และ clock-gating checks เพิ่มเติมเมื่อเกี่ยวข้อง Low skew เพียงค่าเดียวไม่รับรองคุณภาพ clock network

## 7.10 ผลของ skew ต่อ setup และ hold

ใช้ตัวอย่าง rising-edge registers, cycle ถัดไปสำหรับ setup และขอบเดียวกันสำหรับ hold ไม่รวม OCV/CPPR เพื่อให้เห็นเครื่องหมายชัดเจน ให้ T เป็น period, L_L/L_C เป็น clock network latency, t_cq เป็น clock-to-Q, d เป็น data-path delay และ U เป็น margin ที่หักออกจาก slack:

\[
Slack_{setup}=T+(L_C-L_L)-t_{cq,max}-d_{max}-t_{setup}-U_{setup}
\]

\[
Slack_{hold}=t_{cq,min}+d_{min}-(L_C-L_L)-t_{hold}-U_{hold}
\]

ดังนั้น positive skew ช่วย setup ของคู่นี้ แต่ทำให้ hold แย่ลง Negative skew ให้ผลกลับกัน Useful skew จึงต้องประเมิน paths ขาเข้าและขาออกของ registers รวมทุก scenario ไม่ใช่ปรับเพื่อช่วย path เดียว

### ตัวอย่างที่ 1: setup ผ่านก่อน CTS แต่ไม่ผ่านหลัง CTS

กำหนด T=2.00 ns, t_cq,max=0.10 ns, d_max=1.65 ns, t_setup=0.10 ns และ U_setup=0.10 ns

ก่อน CTS สมมติ skew เป็นศูนย์:

\[
Slack=2.00-0.10-1.65-0.10-0.10=+0.05\ ns
\]

หลัง CTS L_L=0.45 ns และ L_C=0.25 ns จึง S=−0.20 ns:

\[
Slack=2.00-0.20-0.10-1.65-0.10-0.10=-0.15\ ns
\]

แม้ data delay สมมติคงเดิม setup ก็ล้มเหลวจาก skew ได้ ในงานจริง data delay มักเปลี่ยนด้วยจาก cell movement และ RC estimate

### ตัวอย่างที่ 2: positive skew ทำให้ hold ล้มเหลว

กำหนด t_cq,min=0.06 ns, d_min=0.04 ns, t_hold=0.05 ns และ U_hold=0.02 ns ก่อน CTS ที่ S=0 ได้ hold slack=+0.03 ns

หลัง CTS L_L=0.25 ns และ L_C=0.37 ns จึง S=+0.12 ns:

\[
Slack=0.06+0.04-0.12-0.05-0.02=-0.09\ ns
\]

หากเพิ่ม minimum data delay 0.11 ns จะได้ hold slack ประมาณ +0.02 ns ในแบบจำลองนี้ แต่ต้องตรวจ setup ของ path เดียวกันและ paths อื่นที่ใช้ logic ร่วมกัน ตลอดจนทุก corner ห้ามถือว่าจำนวน delay cells คำนวณได้จากค่า delay คงที่โดยไม่ดู slew/load

สำหรับ OCV การตรวจ setup มักใช้ launch clock/data แบบ late และ capture clock แบบ early ส่วน hold ใช้ launch/data แบบ early และ capture แบบ late ตาม analysis configuration รายงานอาจมี CPPR/CRPR เพื่อแก้ pessimism ของ common clock path จึงต้องอ่าน clock paths แบบขยายก่อนสรุปจากสมการอย่างง่าย

Hold แบบ same-edge ไม่ดีขึ้นโดยการเพิ่ม clock period ตามปกติ หากลด frequency แล้ว hold ยังไม่ผ่าน ให้กลับไปตรวจ min data delay, skew และ edge relationships

## 7.11 Workflow ปฏิบัติ

### ขั้นที่ 1 — ตรวจ baseline

ตรวจ netlist/library/SDC consistency, clock coverage, unconstrained endpoints, modes และ corners บันทึก tool version และ configuration ที่ใช้

### ขั้นที่ 2 — Global placement

รันด้วย density ที่อธิบายได้ ตรวจ density map, timing และตำแหน่ง critical nets หาก congestion รุนแรงให้ย้อนแก้ floorplan/pins/macros ก่อนเพิ่ม optimization effort

### ขั้นที่ 3 — Legalize และตรวจ early routability

ตรวจ overlap, site alignment, orientation และ unplaced cells ใช้ congestion estimation หรือ trial/global route ตาม flow เพื่อดูบริเวณที่ HPWL ไม่บอกปัญหา

### ขั้นที่ 4 — Pre-CTS optimization

แก้ high fanout, max transition/capacitance และ setup ที่จำเป็น ตรวจการใช้ dont_touch อย่ารีบแก้ hold ทุกจุดจาก ideal-clock model โดยไม่พิจารณา strategy หลัง CTS

### ขั้นที่ 5 — สร้าง CTS

ตรวจ clock root/sinks และ allowed cells สร้าง tree แล้วเทียบ sink count กับจำนวนที่คาดหมาย แยก clock/gated domains ตาม architecture ตรวจ ignored/unbalanced sinks และ warnings

### ขั้นที่ 6 — Propagate clocks และ post-CTS STA

เปิด propagated-clock analysis ตาม flow อัปเดต parasitics และตรวจ latency/skew/slew/load พร้อมทั้ง setup และ hold ต้องรายงาน clock model และ parasitic model ที่ใช้คู่กับผลเสมอ

### ขั้นที่ 7 — Timing repair และ legalization

แก้ setup และ hold ตามลำดับของ optimizer; บาง flow ทำ setup ก่อน hold เพื่อลดผลกระทบของ hold insertion ต่อ setup ตรวจทั้งสองซ้ำหลังแก้ และดู area/congestion เพิ่มด้วย

### ขั้นที่ 8 — Global route และประเมินใหม่

เมื่อมี routing topology ที่สมจริงขึ้น ให้ปรับ parasitics และประเมิน timing/clock metrics อีกครั้ง ผล post-CTS ก่อน route เป็น milestone ระหว่างทาง ไม่ใช่ sign-off

## 7.12 ตัวอย่าง Tcl อ้างอิง OpenROAD

ตัวอย่างนี้เป็น skeleton ไม่ใช่ full-flow script ต้องโหลด Liberty, technology/cell LEF, design database, SDC และตั้ง wire RC ของ PDK ก่อน ชื่อ cells ต้องมาจาก library จริง ตรวจ `help` ใน build ที่ติดตั้งและใช้ stage scripts ของ flow เป็นหลัก

```tcl
# A. บนฐานข้อมูลก่อน placement ที่โหลด constraints และ RC แล้ว
global_placement -density 0.60
detailed_placement
check_placement -verbose
estimate_parasitics -placement

report_checks -path_delay max -format full_clock_expanded
report_checks -path_delay min -format full_clock_expanded
report_wns
report_tns

# B. ใช้ชื่อ clock cells ที่มีจริง และได้รับอนุญาตสำหรับ PDK
# ตั้งค่า $cts_buffers และ $cts_root_buffer ใน technology setup ก่อน
clock_tree_synthesis -buf_list $cts_buffers -root_buf $cts_root_buffer
detailed_placement
check_placement -verbose

# C. แบบ single-domain ตัวอย่าง; งานหลาย clocks ต้องตรวจ scope ให้ครบ
set_propagated_clock [all_clocks]
estimate_parasitics -placement
report_cts
report_checks -path_delay max -format full_clock_expanded
report_checks -path_delay min -format full_clock_expanded

# D. repair เปลี่ยน netlist/placement จึงต้องตรวจอีกครั้ง
repair_timing
detailed_placement
check_placement -verbose
estimate_parasitics -placement
report_checks -path_delay max -format full_clock_expanded
report_checks -path_delay min -format full_clock_expanded
```

ค่า density 0.60 เป็นค่าประกอบบทเรียน ไม่ใช่ค่าที่รับรองสำหรับทุก PDK คำสั่ง `estimate_parasitics -placement` ให้ข้อมูลประมาณจาก placement ไม่ใช่ extracted SPEF สำหรับ flow ที่มี global-route estimation หรือ parasitic data อยู่แล้ว ให้ใช้วิธีที่ flow กำหนดและอย่าเขียนทับ extracted data โดยไม่ตั้งใจ

OpenROAD detailed placement ใช้ legalize และ re-legalize หลังการแก้ไขได้ ส่วนเอกสาร resizer ระบุให้ `repair_timing` ทำงานหลัง CTS ด้วย propagated clocks [R1, R4] นี่เป็นเหตุผลของลำดับตัวอย่าง ไม่ใช่การรับรองว่าจะปิด timing ได้ทุกดีไซน์

## 7.13 การอ่านรายงานอย่างเป็นระบบ

สำหรับแต่ละ path ให้ตอบตามลำดับ:

1. Startpoint/endpoint คืออะไร และอยู่ clock domain ใด
2. เป็น setup, hold, recovery/removal หรือ gating check
3. ใช้ mode, PVT, RC และ early/late analysis แบบใด
4. Launch/capture edge สัมพันธ์กันอย่างไร มี generated clock หรือ multicycle หรือไม่
5. Clock paths ถูก propagate จริงหรือยัง และมี source latency เท่าใด
6. Data delay ส่วนใดมาจาก cells และส่วนใดจาก nets
7. Clock skew, uncertainty และ CPPR มีส่วนต่อ slack อย่างไร
8. การแก้ที่เสนอจะกระทบ paths อื่นและ electrical constraints อย่างไร

WNS บอกความรุนแรงของ path ที่แย่ที่สุด ส่วน TNS สะท้อนภาพรวม violation ตามวิธีรวม endpoints ของเครื่องมือ ต้องรายงาน violating endpoint count ประกอบ ค่า setup WNS ที่ดีขึ้นไม่ยืนยันว่า hold ดีขึ้น และค่า WNS/TNS ที่ไม่มี violation ไม่ยืนยัน coverage หากยังมี unconstrained endpoints

## 7.14 Troubleshooting

| อาการ | สิ่งที่ตรวจเป็นอันดับแรก | แนวทางแก้ |
|---|---|---|
| Legalization ล้มเหลว | effective capacity, padding, cell height และ fences | ลด local density/ปรับ rows หรือข้อจำกัดที่ผิด |
| Placement legal แต่ route ไม่ผ่าน | hotspot, macro channels, pins และ layer capacity | แก้ floorplan/pin access และทดลอง global route |
| Buffer count เพิ่มผิดปกติ | transition/load limits, input slew, dont_use และ units | แก้ constraint/model ที่ผิดก่อนปรับ topology |
| CTS ไม่พบ sinks | clock definition, sequential arcs, gating และ connectivity | แก้ clock tracing และ library/netlist mapping |
| Clock slew fail | branch load, wire RC, allowed cells และ placement | ปรับ buffer stages/drive หรือ sink clustering |
| Skew สูง | unequal branches, macros, obstacles และ root location | ปรับ topology/placement และ balance policy |
| Hold fail จำนวนมากหลัง CTS | propagated clocks, positive pairwise skew และ short paths | แก้ model ก่อนทำ hold repair ที่เหมาะสม |
| Setup แย่หลัง hold repair | delay cells อยู่บน shared/critical paths | ปรับจุด repair และวน setup/hold optimization |
| Timing ดีมากผิดคาดหลัง CTS | clock ยัง ideal หรือ constraints หลุด | ตรวจ full clock paths และ coverage |
| Insertion delay สูงแต่ skew ต่ำ | clock power, I/O timing และ absolute latency budget | ประเมิน root/levels/RC ไม่ตัดสินจาก skew อย่างเดียว |

## 7.15 Lab — เปรียบเทียบ Placement และ CTS

ใช้ synchronous counter 32 บิตพร้อม clock enable และ self-checking testbench จากบทก่อนหน้าได้ทั้ง VHDL หรือ Verilog/SystemVerilog หลัง synthesis ทั้งสองภาษาจะเข้าสู่ mapped-netlist flow เดียวกัน หากจะเปรียบเทียบ PPA ข้ามภาษา ต้องตรวจว่าฟังก์ชัน reset/enable, width และ constraints ตรงกัน

### การทดลอง A: density sweep

ใช้ input checkpoint เดียวกัน ทดลอง target density เช่น 0.45, 0.55 และ 0.65 โดยตรึง floorplan, SDC, libraries, seed และ tool settings อื่น บางดีไซน์อาจไม่มี legal capacity สำหรับทุกค่าที่ทดลอง ให้บันทึก failure แทนการเปลี่ยน floorplan กลางชุดทดลอง

บันทึก legalization result, HPWL, congestion/overflow ตามนิยามของรายงาน, setup WNS/TNS, cell area และจำนวน buffers เปรียบเทียบผลหลัง global-route estimation ที่จุดเดียวกันด้วย

### การทดลอง B: ideal เทียบ propagated clocks

เก็บ pre-CTS และ post-CTS checkpoints ตรวจว่า pre-CTS clock เป็น ideal ตามที่ตั้งใจ และ post-CTS มี clock-cell arcs ปรากฏใน full timing path เลือก setup และ hold path อย่างละหนึ่งเส้นมาแยก launch latency, capture latency, data delay และ uncertainty

### การทดลอง C: post-CTS repair

เก็บฐานข้อมูลก่อน repair รัน timing repair แล้ว re-legalize และวิเคราะห์ซ้ำ เปรียบเทียบจำนวน inserted cells, area, setup/hold และ congestion หากไม่มี violation เดิม ไม่จำเป็นต้องสร้าง ECO ปลอมเพื่อให้เห็นการเปลี่ยนแปลง สามารถใช้กรณีตัวเลขในหัวข้อ 7.10 เป็นโจทย์วิเคราะห์เสริม

| Run | Clock model | Parasitics | Legal | Area | Buffers | Setup WNS | Hold worst slack | Congestion |
|---|---|---|---|---|---|---|---|---|
| Pre-CTS | Ideal | Placement estimate | … | … | … | … | … | … |
| Post-CTS | Propagated | Placement estimate | … | … | … | … | … | … |
| Post-repair | Propagated | Placement estimate | … | … | … | … | … | … |
| Post-global-route | Propagated | Route estimate | … | … | … | … | … | … |

ต้องระบุหน่วยและ corner แยกสำหรับแต่ละแถว หาก setup และ hold ใช้คนละ corner ให้บันทึกชื่อทั้งคู่ ห้ามใส่ตัวเลขสมมติลงตารางในฐานะผลการรันจริง

## 7.16 เกณฑ์ผ่านและสิ่งส่งมอบ

เกณฑ์ผ่านระดับ placement/CTS milestone:

- Placement legal และไม่มี required movable instances ค้างเป็น unplaced
- Clock definitions/sink classification ถูกต้อง และจำนวน sinks สอดคล้องกับ design intent
- ใช้ propagated clocks ใน post-CTS analysis และมี RC model ที่ระบุชัด
- รายงาน clock transition/capacitance, latency/skew และ checks ที่เกี่ยวข้องครบ
- ตรวจ setup/hold ตาม modes/corners ที่กำหนด พร้อม unconstrained-path audit
- ถ้ายังมี violations ต้องมี path-level root cause และแผนแก้ที่ตรวจสอบได้ โดยยังไม่ระบุว่า timing closed
- มี congestion assessment และพื้นที่รองรับการเปลี่ยนแปลงก่อนส่ง routing

สิ่งส่งมอบประกอบด้วย input versions, SDC/technology setup, placement/CTS configuration, checkpoints, post-CTS netlist, timing reports แบบขยาย clock paths, clock metrics และตารางเปรียบเทียบก่อน/หลัง repair

การผ่าน milestone นี้ไม่แทนที่ post-route extraction, MMMC sign-off, SI, power integrity และ physical verification ที่โครงการกำหนด

## 7.17 คำถามทบทวนพร้อมแนวคำตอบ

1. **Placement legal แล้วเหตุใด detailed routing ยังล้มเหลว?** — Legality ตรวจตำแหน่ง cells ขณะที่ routing ต้องมี tracks, pin access และ via resources เพียงพอ
2. **ลด density แล้ว timing ต้องดีขึ้นหรือไม่?** — ไม่เสมอไป Congestion อาจลด แต่ระยะสายและ RC อาจเพิ่ม
3. **Ideal clock หมายถึง clock latency เป็นศูนย์หรือไม่?** — ไม่จำเป็น อาจมี latency และ slew ที่กำหนดเป็น model ไว้
4. **Clock tree มี skew ต่ำแปลว่า setup/hold ผ่านหรือไม่?** — ไม่ เพราะ data delay, pairwise skew, uncertainty, corner และ edge relationships ยังมีผล
5. **Positive skew มีผลอย่างไร?** — ภายใต้นิยาม capture minus launch ในบทนี้ ช่วย setup และทำร้าย hold ของคู่ที่กำลังพิจารณา
6. **เพิ่ม period แก้ hold same-edge ได้หรือไม่?** — โดยทั่วไปไม่ได้ ต้องแก้ minimum path/skew หรือความผิดพลาดของ constraints
7. **ทำไม post-CTS timing ยังเปลี่ยนหลัง route?** — Topology, wire RC, coupling และ ECO ที่ใช้จริงต่างจากประมาณการก่อน route
8. **เหตุใดต้อง re-legalize หลัง buffering?** — การเพิ่ม/ขยาย cells เปลี่ยน geometry และอาจสร้าง overlap หรือทำให้พื้นที่ไม่พอ

## 7.18 เอกสารอ้างอิง

แหล่งด้านล่างใช้อ้างอิง workflow และตัวอย่างคำสั่ง OpenROAD ไม่ใช่เอกสารคำสั่ง Siemens/Tanner ตรวจเอกสารของรุ่นที่ติดตั้งจริงก่อนนำไปรัน ตรวจสอบแหล่งออนไลน์วันที่ 16 ตุลาคม 2026

- [R1] OpenROAD — Detailed Placement: https://openroad.readthedocs.io/en/latest/main/src/dpl/README.html
- [R2] OpenROAD — Global Placement: https://openroad.readthedocs.io/en/latest/main/src/gpl/README.html
- [R3] OpenROAD — Clock Tree Synthesis: https://openroad.readthedocs.io/en/latest/main/src/cts/README.html
- [R4] OpenROAD — Gate Resizer: https://openroad.readthedocs.io/en/latest/main/src/rsz/README.html

**ใจความสำคัญสำหรับผู้เรียน:** Placement ต้อง legal และรองรับ routing; CTS ต้องสร้าง clock network ที่วิเคราะห์ได้ด้วย propagated clocks; การยืนยัน setup/hold ต้องมาจากรายงาน timing ที่ constraints, corners และ parasitics ครบถ้วน
