# Module 6 — Floorplan และ Power Planning

## 6.1 เป้าหมายและขอบเขต

Floorplanning คือการแปลงข้อกำหนดเชิงตรรกะและข้อจำกัดของระบบให้เป็นกรอบทางกายภาพสำหรับ placement, clock tree synthesis (CTS) และ routing ส่วน power planning คือการจัดโครงข่ายไฟเลี้ยงและกราวด์ให้ส่งกระแสถึงอุปกรณ์ได้อย่างถูกต้อง ภายใต้ข้อจำกัดด้านแรงดันตก ความหนาแน่นกระแส และพื้นที่โลหะ ทั้งสองงานต้องพิจารณาร่วมกัน เพราะ power straps ใช้ routing resources และตำแหน่ง macro มีผลต่อทั้งเส้นทางสัญญาณและเส้นทางกระแส

เมื่อจบบท ผู้เรียนต้องสามารถคำนวณขนาด core เบื้องต้น อธิบายนิยาม utilization ของ flow ที่ใช้ วาง pin และ macro สร้าง placement rows และ blockages วางแผน rails/straps และอธิบายหลักฐานที่ใช้ตรวจรับ floorplan กับ PDN ได้

เนื้อหาเป็นหลักการที่ใช้กับ Tanner Digital ASIC Design Implementation และ physical implementation flow อื่นได้ ขั้นตอนเชิงแนวคิดไม่ผูกกับชื่อเมนูของซอฟต์แวร์ ตัวอย่างคำสั่งที่ระบุว่า OpenROAD ใช้สำหรับทดลองในเครื่องมือนั้นเท่านั้น ต้องอ้างอิงคู่มือและ PDK setup ของ Tanner รุ่นที่ติดตั้งเมื่อดำเนินงานจริง

## 6.2 ข้อมูลนำเข้าที่ต้องพร้อม

| ข้อมูล | สิ่งที่ต้องตรวจ | ผลต่อการวางแผน |
|---|---|---|
| Mapped netlist | top, hierarchy, unresolved references, macro instances | จำนวนและประเภทวัตถุที่จะวาง |
| Timing constraints | clocks, I/O delays, exceptions, modes | ลำดับความสำคัญของระยะทางและ pin placement |
| Technology LEF | DBU, manufacturing grid, routing layers, vias | geometry และ routing resources |
| Cell/macro LEF | dimensions, site, symmetry, pins, obstructions | rows, orientation และ pin access |
| Liberty | cell area, power, PVT และหน่วย | ประมาณพื้นที่และกิจกรรมการใช้พลังงาน |
| Power intent | supplies, domains, voltage, power states | net mapping และ special cells |
| Package/interface plan | pad/bump positions, supplies, ESD | ขอบเขต die และแหล่งจ่ายของ PDN |
| PDK physical rules | tap distance, endcaps, via/metal rules | กฎการสร้างโครงสร้างทางกายภาพ |

ก่อนเริ่มต้องยืนยันว่า macro ใน netlist มี physical abstract ที่ตรงกัน และ power pins สอดคล้องกับ logical/physical views ชื่อ VDD ใน netlist ไม่ได้พิสูจน์ว่า layout เชื่อมถึง VDD จริง และ macro ที่ใช้ black box ต้องมีข้อมูลพื้นที่ pin และ obstruction เพียงพอสำหรับงานทางกายภาพ

## 6.3 แยก die, core และพื้นที่ที่วางเซลล์ได้

**Die area** คือขอบเขตชิปตามนิยามของฐานข้อมูลหรือ flow ส่วน **core area** คือบริเวณที่จัดสรรให้วงจรหลัก ภายใน core อาจมี macro, halo, blockage และพื้นที่ที่ไม่มี rows ทำให้พื้นที่วาง standard cells จริงน้อยกว่าพื้นที่ core

ขอบเขต seal ring, scribe lane และ die boundary ต้องยึดข้อกำหนดส่งมอบของ foundry อย่ารวมพื้นที่นอกขอบเขต die หรือใช้ core-to-die margin เป็นตัวแทน pad ring โดยอัตโนมัติ สำหรับ full chip ต้องคิดพื้นที่ IO cells, corners, IO fillers, power pads, ESD structures และข้อกำหนดประกอบชิปแยกต่างหาก

กำหนดสัญลักษณ์ดังนี้

- A_core: พื้นที่ core ทางเรขาคณิต
- A_std: ผลรวมพื้นที่ standard cells ตามนิยามที่เลือก
- A_macro: พื้นที่ macro
- A_excluded: พื้นที่ที่ไม่อนุญาตให้วาง standard cells เช่น union ของ macro, hard blockage และ halo ที่ตัด rows
- A_rows: พื้นที่ legal placement sites ที่เหลือจริง

โดยประมาณ A_rows ≈ A_core − A_excluded แต่ต้องหักพื้นที่ที่ซ้อนทับกันเพียงครั้งเดียว และคำนึงถึงการ snap, row cutting และ fragment ของ rows ด้วย

## 6.4 Utilization: ต้องบอก numerator และ denominator

สูตรเริ่มต้นที่ใช้บ่อยคือ

\[
A_{core} \approx \frac{A_{placeable\_cells}}{U}
\]

โดย U เป็นสัดส่วน เช่น 0.60 ไม่ใช่ 60 ในสมการนี้ สูตรใช้ได้เมื่อพื้นที่เซลล์และ utilization ถูกนิยามตรงกัน และพื้นที่ core ใกล้เคียงกับพื้นที่ที่ใช้เป็นตัวหารของ U

ตัวอย่างนิยามที่ต้องแยกกัน:

\[
U_{core}=\frac{A_{std}}{A_{core}},\qquad
U_{rows}=\frac{A_{std}}{A_{rows}}
\]

เครื่องมือบางรายงานรวม macro หรือ physical-only cells บางประเภท บางรายงานไม่รวม จึงต้องบันทึกนิยามจากคู่มือหรือรายงานจริง ห้ามเปรียบเทียบตัวเลขที่ใช้คนละฐานโดยไม่ปรับนิยาม

**Floorplan utilization** ใช้กำหนดขนาดพื้นที่ ส่วน **placement target density** เป็นเป้าหมายการกระจายเซลล์ของ placement algorithm อาจอ้างอิง bin, whitespace, macro หรือ padding ต่างกัน การตั้งสองค่าให้เท่ากันไม่ได้รับประกันว่าจะได้ผลตามต้องการ

สำหรับกรณีมี macro หาก U_rows = A_std/A_rows อาจประมาณว่า

\[
A_{core}\approx A_{excluded}+\frac{A_{std,planned}}{U_{rows}}
\]

นี่เป็นเพียงสมการวางงบพื้นที่ ไม่ได้พิสูจน์ว่ามีช่องทาง routing หรือ placement ต่อเนื่องเพียงพอ การจัดวาง macro อาจทำให้เกิดคอขวดแม้พื้นที่รวมยังเหลือมาก

### 6.4.1 เผื่อพื้นที่เพิ่มตาม flow

พื้นที่เซลล์หลัง synthesis ไม่ใช่พื้นที่เซลล์สุดท้าย ต้องประเมินการเพิ่มจาก CTS, setup/hold repair, high-fanout buffering, tie cells, taps, endcaps และ decaps ตาม flow พร้อมระบุว่ารายงานพื้นที่นับรายการใดแล้ว

Filler cells ใช้เติมช่องว่างที่เหลือเพื่อความต่อเนื่องทางกายภาพตาม library ไม่ควรบวกพื้นที่ filler เต็ม whitespace ลงใน A_std แล้วหารด้วย utilization ซ้ำ เพราะจะนับพื้นที่ซ้ำ การกันพื้นที่สำหรับ CTS/buffers ต่างจากการเติม filler ในช่วงที่ flow กำหนด

Routing resources ไม่ใช่เพียงพื้นที่ว่างบนระนาบ placement โลหะแต่ละชั้นมีความจุจำกัดจาก preferred direction, PDN, obstructions, vias และ pin access จึงต้องยืนยันด้วย trial placement/global routing และ congestion report

### 6.4.2 ตัวอย่าง standard-cell-only

สมมติ A_std หลัง synthesis = 120,000 µm² เผื่อ netlist growth 15% สำหรับตัวอย่างการสอน และเลือก U_rows = 0.60 โดยยังไม่มี macro หรือ blockage ขนาดใหญ่

\[
A_{std,planned}=120000(1.15)=138000\;\mu m^2
\]
\[
A_{core}\approx138000/0.60=230000\;\mu m^2
\]

ถ้ากำหนด r = H/W = 0.80 จะได้

\[
W=\sqrt{A_{core}/r}\approx536.19\;\mu m,
\quad H=rW\approx428.95\;\mu m
\]

ต้องปรับ W, H และ origin ให้ถูกต้องตาม site/row/manufacturing grid แล้วคำนวณพื้นที่ใหม่ หากสมมติ margin รอบ core ด้านละ 30 µm ขนาด die เบื้องต้นจะประมาณ 596.19 × 488.95 µm ก่อน snap ตัวเลข margin นี้ใช้สาธิตเท่านั้น ไม่ใช่ข้อกำหนด pad ring หรือ PDK

ค่าเผื่อ 15% และ utilization 60% ไม่ใช่ค่ามาตรฐานสำหรับทุก design ควรใช้ข้อมูลจากงานลักษณะเดียวกันและผล trial run มาปรับ

### 6.4.3 ตัวอย่างมี macro

หาก A_std,planned = 138,000 µm² และพื้นที่ union ที่กันให้ macro/halo/blockage = 80,000 µm² ที่ U_rows = 0.60 จะได้ A_core ≈ 310,000 µm² การนำ 138,000 หาร 310,000 จะได้ U_core ≈ 44.5% แต่ U_rows ยังเท่ากับ 60% ตามสมมติฐาน ทั้งสองตัวเลขถูกต้องได้พร้อมกัน

## 6.5 Aspect ratio และการเลือกรูปร่าง block

ต้องประกาศนิยาม aspect ratio เสมอ ในบทนี้ r = H/W แต่เครื่องมืออื่นอาจใช้ W/H รูปร่างใกล้สี่เหลี่ยมจัตุรัสมักเป็นจุดเริ่มต้นที่สะดวก แต่รูปร่างที่เหมาะสมขึ้นกับตำแหน่ง IO, dataflow, macro dimensions และตำแหน่ง block ข้างเคียง

Block ที่ยาวมากอาจเพิ่ม wire delay และ clock distribution distance ส่วน block ที่แคบอาจเหลือช่อง route ไม่พอหลังวาง macro และ PDN การลดพื้นที่จน placement ผ่านแต่ routing ไม่ผ่านไม่ถือเป็นการปรับปรุงที่สำเร็จ

สำหรับ full chip ให้ตรวจข้อจำกัดแบบ pad-limited ด้วย หากผลรวมความกว้าง IO cells และ corners ของด้านใดเกินช่วงที่ใช้ได้ ต้องขยาย die หรือปรับ pad assignment ต่อให้ core logic ยังเล็กก็ตาม

## 6.6 Placement rows และความถูกต้องของ grid

Rows สร้างจาก placement site ใน LEF จึงไม่ควรกำหนดความสูงแถวจากตัวเลขที่เดาเอง ต้องตรวจ site width, row height, orientation, library symmetry และตำแหน่ง power rails การสลับแถวเพื่อให้ rails ตรงกันเป็นวิธีที่พบได้บ่อย แต่ต้องทำตาม library และ PDK

ขั้นตอนตรวจประกอบด้วย:

1. ยืนยัน DBU ต่อ µm และหน่วยทุก view
2. สร้าง core origin ที่วาง rows ได้ถูกต้อง
3. Snap ความกว้างตาม site และความสูงตาม row pattern
4. ตัด rows รอบ macro และบริเวณห้ามวาง
5. ตรวจเศษแถวสั้นที่ไม่รองรับ endcaps/taps หรือ legal cells
6. ตรวจ multi-height cells และ row pattern หาก library ใช้หลายความสูง

Manufacturing grid, placement site และ routing track เป็นคนละข้อจำกัด วัตถุที่ถูก placement grid อาจยัง off-track สำหรับ pin access หรือผิด manufacturing grid ใน geometry อื่นได้

## 6.7 Pin locations และ macro placement

### 6.7.1 Block pins กับ chip pads

Block pin เป็นรูปทรงโลหะบนขอบหรือภายใน block ตาม abstract ส่วน chip pad คือ physical cell ที่เชื่อมโลกภายนอกและอาจมีวงจร ESD ห้ามถือว่าสร้าง block pin แล้วเท่ากับมี IO pad ครบ

วาง pin ตาม dataflow และความสัมพันธ์กับ block ข้างเคียง กลุ่ม bus ควรมีลำดับที่ช่วยลดการไขว้ แต่ต้องใช้ข้อมูล connectivity จริง มิใช่เรียงชื่ออย่างเดียว แยกบริเวณที่ต้องการ clock access และ reset access พร้อมจัด pin layer/spacing ที่เอื้อต่อ routing ตรวจว่าตำแหน่ง pin ไม่ถูก PDN หรือ macro obstruction ปิดทางเข้าถึง

Pin placement ไม่แทน I/O timing constraints แม้ pin อยู่ใกล้ register ก็ยังต้องมี input/output delay ตาม external environment

### 6.7.2 Macro placement

วาง SRAM หรือ hard macro โดยพิจารณาร่วมกันทั้ง timing-critical connections, pin side, power pin access, routing channels และ legal orientations การหมุน macro ต้องอยู่ใน symmetry ที่อนุญาตและต้องไม่ทำให้ pin หรือ power connection ใช้งานไม่ได้

Halo คือบริเวณกันชนรอบ macro เพื่อช่วย pin access หรือเว้นพื้นที่สำหรับโครงสร้างทางกายภาพ ต้องตรวจว่า flow แปลง halo เป็น placement blockage, routing blockage หรือเพียงข้อกำหนดระหว่าง macro เพราะความหมายต่างกัน

ช่องว่างระหว่าง macro ต้องรองรับสายที่ผ่าน, vias, PDN, buffering และกฎ physical cells ถ้าเพิ่ม halo จนช่องว่างเหลือแคบลง อาจทำให้ congestion แย่ลงแม้ pin access รอบ macro ดูดีขึ้น

## 6.8 Blockages และข้อจำกัดการใช้พื้นที่

| ประเภท | วัตถุประสงค์ | ข้อควรตรวจ |
|---|---|---|
| Hard placement blockage | ห้ามวางเซลล์ตามขอบเขตที่กำหนด | ลด legal row area เท่าใด |
| Soft placement blockage | จำกัดการวางในบางช่วงของ flow | เครื่องมืออนุญาต optimization cells เมื่อใด |
| Partial blockage | จำกัด local cell density | ค่า density และ semantics ของเครื่องมือ |
| Routing blockage | กันโลหะ/ทางเดินบางชั้น | signal, PG, via และ layer scope |
| Macro obstruction จาก LEF | ป้องกัน geometry ภายใน macro | ใช้ abstract ที่ถูกต้องและครบ |

อย่ากันทุกชั้นโลหะเหนือ macro โดยไม่มีเหตุผล เพราะอาจสูญเสียทางเดินสัญญาณและ PDN ที่ใช้ได้จริง ในทางกลับกันอย่าอนุญาต route ผ่านบริเวณที่ LEF/PDK ไม่อนุญาต

## 6.9 โครงสร้าง Power Distribution Network

PDN ต้องมีเส้นทางครบจากแหล่งจ่ายที่กำหนด เช่น power pad หรือ bump ไปยัง ring/mesh/straps แล้วลงสู่ local rails และ power pins ของ standard cells กับ macros เส้นทางกราวด์ต้องตรวจอย่างจริงจังเท่ากับเส้นทาง VDD

| โครงสร้าง | หน้าที่ | ความเสี่ยงหลัก |
|---|---|---|
| Power ring | กระจายไฟรอบ core หรือ macro เมื่อ flow ใช้ | ring ไม่เชื่อม source หรือกินพื้นที่ขอบ |
| Straps/mesh | กระจายกระแสข้าม block | pitch ห่างเกินไปหรือบัง signal routes |
| Local rails | จ่ายไฟตาม rows | rail ขาดที่ row cuts หรือ cell pin ไม่สัมผัส |
| Via arrays/stacks | เชื่อมโลหะต่างชั้น | enclosure, cut spacing, จำนวน via ไม่พอ |
| Macro PG connection | ส่งไฟถึง macro supply pins | pin layer หรือ geometry ไม่ตรงกับ grid |

Ring ไม่ใช่ข้อบังคับสากล บางระบบจ่ายผ่าน mesh และ bumps โดยตรง ต้องออกแบบจาก topology ของ package และข้อกำหนด power intent

### 6.9.1 แยก logical connection กับ physical connection

Global net connection กำหนดว่าขา supply ของ instance อยู่บน net ใด ส่วน PDN routing สร้าง geometry เพื่อเชื่อมจริง การผ่านอย่างใดอย่างหนึ่งไม่พิสูจน์อีกอย่างหนึ่ง ต้องตรวจ resolved instance/pin lists และ physical connectivity

หากใช้ regular expression เชื่อม macro ให้ตรวจจำนวนที่ match และชื่อจริงหลัง elaboration เช่น generated array indices อาจมีอักขระพิเศษ ต้องไม่ยอมรับรายงาน no match หรือ match ผิด domain

## 6.10 วางงบกระแส แรงดันตก และ electromigration

ประมาณกำลังไฟเบื้องต้นด้วย

\[
P_{dynamic}\approx\alpha C_{sw}V^2f,
\qquad I_{avg}\approx P_{avg}/V
\]

นิยาม activity factor ต้องตรงกับวิธีนับ switching capacitance ในการประมาณนี้ และต้องรวม internal power/leakage ตามข้อมูลจริงเมื่อวิเคราะห์ละเอียด I_avg ใช้ตั้งงบเริ่มต้นได้ แต่ไม่ใช่ตัวแทน peak current ในทุกช่วงเวลา

แรงดันตกเชิง DC ประมาณได้จาก ΔV = IR และความต้านทานแถบโลหะอย่างง่ายคือ R ≈ R_sheet L/W ภายใต้สมมติฐานชั้นโลหะสม่ำเสมอ Via, branching, temperature และ parallel paths ต้องนำเข้าการวิเคราะห์จริง

**ตัวอย่าง:** แหล่งจ่ายสมมติ 1.2 V ใช้กำลังเฉลี่ย 24 mW จะได้ I_avg = 20 mA ถ้าตั้งงบแรงดันตก 3% จะมีงบ 36 mV และได้ R_equivalent ≤ 1.8 Ω สำหรับเส้นทางสมมติที่รับกระแสทั้งหมดนี้ ตัวเลขดังกล่าวเป็นแบบจำลองรวมเพื่อสอนหลักการ ไม่ใช่ width rule ของ strap และไม่ใช้แทนการวิเคราะห์โครงข่ายกระจาย

EM ต้องใช้ current density และ via current limits ตาม foundry รวมถึงเงื่อนไขอุณหภูมิ อายุการใช้งาน และลักษณะกระแสที่กฎกำหนด การดูเฉพาะความกว้างโลหะโดยไม่ตรวจ vias อาจพลาดคอขวดสำคัญ

สำหรับ transient power integrity ต้องพิจารณา switching bursts, package impedance, L·di/dt และ decoupling การวิเคราะห์ static IR ที่ผ่านไม่ได้รับประกัน dynamic droop ว่าผ่านด้วย

### 6.10.1 เลือก width, pitch, layer และ via

เริ่มจากชั้นโลหะที่ PDK/flow อนุญาต กำหนดทิศทางให้เหมาะกับ routing architecture แล้วเลือก width/pitch/offset ที่สร้าง via connections ได้จริง ประเมิน IR/EM และ congestion จากนั้นปรับซ้ำ

สัดส่วน W/P ใช้ประมาณการครองพื้นที่ของเส้นขนานบนชั้นเดียวได้ หาก P เป็น pitch ของเส้นที่กำลังนับ ต้องระบุว่ารวม VDD และ VSS อย่างไร สัดส่วนนี้ไม่รวม via keepouts หรือข้อจำกัด pin access จึงไม่ใช่ routing capacity ที่เหลือจริง

เพิ่ม strap ทุกตำแหน่งอาจลด IR แต่ทำให้ signal detours และ timing แย่ลง ส่วนเพิ่ม via ต้องตรวจ enclosure/spacing และกฎ cut arrays ไม่ใช่เพิ่มจำนวน cut โดยไม่มีข้อจำกัด

## 6.11 Special cells และลำดับการใช้งาน

| Cell | หน้าที่ | แนวทางใช้งาน |
|---|---|---|
| Well tap / substrate tap | เชื่อม well/substrate ไปยัง supply ที่ถูกต้อง | ระยะห่างและ domain ตาม PDK |
| Endcap / boundary cell | ทำ termination ที่ขอบ row/well ตาม library | ใส่หลัง row cutting ตาม flow |
| Tie-high / tie-low | สร้างค่าคงที่ด้วย cell ที่รองรับ | ตรวจ fanout, domain และข้อจำกัดระยะ |
| Filler | เติมช่องเพื่อความต่อเนื่องของโครงสร้างตาม library | ใช้ชุดขนาดและลำดับที่ flow กำหนด |
| Decap | เพิ่ม local capacitance ระหว่าง supplies | ต้องประเมิน droop, leakage และพื้นที่ |
| Antenna diode | ลดความเสี่ยงระหว่าง fabrication ตาม rule | มักสัมพันธ์กับ routing/antenna repair |
| Level shifter / isolation | จัดการ voltage crossing และ power-off domains | ต้องตรงกับ power intent และ placement rules |
| Power switch | เปิด/ปิด supply domain | ต้องวางเครือข่าย switched supply และ control |

Filler ไม่ทำหน้าที่แทน tap และ decap ไม่แก้ disconnected supply การต่อ logic input เข้ารางไฟโดยตรงแทน tie cellต้องยึด library/PDK policy ไม่ควรทำเป็นค่าเริ่มต้น

ลำดับโดยทั่วไปเริ่มจาก macro/row geometry ตามด้วย taps/endcaps, PDN และ placement ส่วน tie insertion, decap และ filler อาจเกิดต่างช่วงกันตาม flow หลัง optimization ที่เคลื่อนหรือเพิ่มเซลล์อาจต้อง remove/reinsert fillers และตรวจ legality ใหม่ ห้ามถือว่าลำดับเดียวใช้ได้กับทุกเครื่องมือ

## 6.12 ขั้นตอนปฏิบัติสำหรับห้องทดลอง

### ขั้นที่ 1 — สร้าง baseline

บันทึก netlist/SDC/PDK revisions และ cell area ก่อนวาง ตรวจ clock coverage และ unconstrained paths จาก Module 5 เพื่อไม่ให้ผลทดลองด้าน timing ถูกบิดเบือนด้วย constraints ที่ขาด

### ขั้นที่ 2 — ทำตารางงบพื้นที่

แยก synthesis cells, projected growth, macros, excluded regions และค่าที่ใช้สำหรับ U ระบุว่าจะนับ taps/endcaps/decaps ในพื้นที่เซลล์หรือกันพื้นที่ให้แยกต่างหาก หลีกเลี่ยง double counting

### ขั้นที่ 3 — สร้าง floorplan candidate

เลือก core dimensions/aspect ratio, snap rows และกำหนด core-to-die margins จากข้อจำกัดจริง ตรวจ bounding boxes หลังเครื่องมือปรับ grid ไม่ใช้เพียงค่าที่ป้อนใน configuration

### ขั้นที่ 4 — วาง macro, pins และ blockages

ตรวจ orientation และ pin access กำหนดช่อง routing จาก connectivity แล้ว lock ตำแหน่งที่พร้อมทดสอบ เก็บภาพ floorplan ที่มีชื่อ macro, pins และ scale เพื่อใช้ทบทวน

### ขั้นที่ 5 — สร้าง physical cells และ PDN

ใส่ taps/endcaps ตาม PDK สร้าง supply nets และ domain mapping จากนั้นสร้าง rails/straps/vias ตรวจ macros ทั้งหมดและทั้ง VDD/VSS รวม IO supplies หากเป็น full chip

### ขั้นที่ 6 — ตรวจสามชั้น

1. Logical: instance/pin-to-net mapping ถูกต้อง ไม่มีผิด domain
2. Geometric: rails, straps, pins และ vias ต่อจริง และผ่านกฎ geometry ที่เกี่ยวข้อง
3. Electrical: วิเคราะห์ IR/EM ด้วย source locations และ current model ที่สมเหตุผล

### ขั้นที่ 7 — Trial implementation

รัน placement และ global routing เพื่อดู local congestion, pin access, wirelength, timing และพื้นที่เซลล์เพิ่ม ถ้าเกิด hotspot ให้แก้ตำแหน่ง pin/macro/channel หรือ PDN ก่อนพิจารณาขยายพื้นที่ทั้ง block

### ขั้นที่ 8 — เลือก candidate ด้วยหลักฐาน

เปรียบเทียบพื้นที่, local congestion, timing, power integrity และ routability พร้อมกัน เก็บ candidate ที่เหมาะสมและเหตุผล ไม่เลือกจาก utilization ที่สูงที่สุดเพียงตัวเดียว

## 6.13 ตัวอย่างคำนวณและคำสั่ง

### Python: คำนวณขนาด core เบื้องต้น

```python
from math import sqrt, ceil

area_synth = 120_000.0  # um^2; selected standard-cell set
growth = 0.15
util = 0.60            # fraction; A_std_planned / A_usable_rows
aspect = 0.80          # H / W
area_excluded = 0.0    # union area; illustrative standard-cell-only case
assert 0 < util <= 1 and aspect > 0
area_std = area_synth * (1 + growth)
area_core = area_excluded + area_std / util
w = sqrt(area_core / aspect)
h = aspect * w
print(f"raw core: {w:.3f} x {h:.3f} um; area={area_core:.1f} um^2")

# Supply these from the actual LEF/site and row pattern.
def snap_up(value, quantum):
    assert quantum > 0
    return ceil(value / quantum) * quantum
# W = snap_up(w, site_width)
# H = snap_up(h, legal_row_pattern_height)
# Recompute usable row area from the implementation database afterwards.
```

การ snap ขนาดอย่างเดียวไม่ตรวจ origin, parity, macro cuts หรือ legal orientations ต้องตรวจฐานข้อมูลจริงเสมอ

### OpenROAD: สร้าง floorplan แบบกำหนดขอบเขต

หลังโหลด technology/cell LEFs และ link netlist แล้ว ตัวอย่างเชิงโครงสร้างคือ

```tcl
# Replace with a real SITE name from the loaded library.
set site_name YOUR_LIBRARY_SITE
initialize_floorplan \
    -die_area  {0 0 600 500} \
    -core_area {30 30 570 470} \
    -site $site_name
```

ในตัวอย่าง core มีขนาด 540 × 440 µm ก่อนพิจารณา snapping/rows อีกวิธีหนึ่งคือใช้ utilization/aspect ratio ให้เครื่องมือคำนวณ แต่ไม่ควรปนสองวิธีในคำสั่งเดียวกัน ตัวเลือก utilization ของ OpenROAD ใช้หน่วยเปอร์เซ็นต์ และ aspect ratio ใช้ H/W ตามเอกสารของเครื่องมือนี้

คำสั่งนี้ยังไม่ได้สร้าง PDN หรือ full-chip padframe และไม่ใช่ Tanner Tcl syntax การสร้าง PDN ต้องใช้ layer names, via definitions และ cell masters ที่มีจริงใน PDK จึงไม่ควรแจก template ที่ใส่ชื่อสมมติแล้วเรียกว่า ready-to-run

## 6.14 การตรวจ PDN ที่มักถูกมองข้าม

**Connectivity ผ่านแต่ DRC ไม่ผ่าน:** สายและ via อาจสัมผัสกันทาง topology แต่ enclosure, width, cut spacing หรือกฎเฉพาะ foundry ยังผิด ต้องตรวจด้วย rule deck และ geometry ที่เกี่ยวข้อง

**Metal ข้ามกันแต่ไม่เชื่อม:** รูปทรงบนคนละชั้นที่ทับกันในภาพไม่เชื่อมไฟหากไม่มี via stack ถูกต้อง ต้องตรวจ via objects และ layer connectivity

**Macro มีไฟเพียงบางขา:** อย่าใช้จำนวน macro instances เป็นตัวแทนจำนวน PG pins ที่เชื่อม ตรวจ supply pins ทุกชนิดตาม macro model และข้อกำหนด LVS รวมกรณีมีหลาย power pin บนหลาย layer

**Supply sources กำหนดไม่จริง:** IR analysis ที่ตั้ง source กระจายทั่ว grid โดยไม่ตรง pad/bump อาจให้ผลดีเกินจริง ต้องบันทึก source model และ package assumptions

**Tap ถูกระยะจากจุดศูนย์กลางแต่ผิดกฎจริง:** บางกฎวัดระยะจาก diffusion/well geometry ไม่ใช่ระยะระหว่าง tap origins เท่านั้น ใช้กฎ foundry เป็นเกณฑ์

## 6.15 ปัญหาที่พบบ่อยและแนวทางแก้

| อาการ | สาเหตุที่ควรตรวจ | แนวทางแก้ |
|---|---|---|
| Placement ล้มเหลวแม้ U_core ต่ำ | macro/halo กิน legal rows หรือเกิดช่องแคบ | ตรวจ U_rows และ row fragments |
| Congestion สูงรอบ SRAM | pins อัดด้านเดียว, channel แคบ, PDN บัง | ปรับ macro orientation/channel/pin routing |
| PDN floating stripe | ขาด vias หรือไม่ถึง source | ตรวจ net, geometry และ source path |
| Macro PG mapping ไม่ match | hierarchy เปลี่ยนหรือ regex ผิด | ตรวจ resolved instance/pin lists |
| IR hotspot เฉพาะจุด | activity สูง, grid ห่าง, via bottleneck | ปรับ local grid/vias และวิเคราะห์ซ้ำ |
| CTS/hold repair ไม่มีที่วาง | netlist growth เกินงบหรือ local density สูง | เพิ่ม local whitespace/ปรับ floorplan |
| Pad ring ไม่พอดี | IO width/corners เกิน available side | ปรับ die/pad assignment ตามข้อกำหนด |
| Timing แย่เมื่อเพิ่ม straps | signal routing resources ลด | ทบทวน layer/pitch/offset พร้อม IR |

## 6.16 เกณฑ์ตรวจรับก่อนส่งต่อ placement

- มี area budget ที่ระบุนิยาม utilization, cell set และ growth assumptions
- Core/die dimensions, origins, rows และ orientations ถูก grid และ library
- Macro ไม่มี overlap และมี pin/PG access ที่ตรวจแล้ว
- Pin assignment ตรง interface และมี constraints ด้าน timing ครบตาม scope
- Blockages/halos มีเหตุผลและคำนวณพื้นที่ซ้อนทับอย่างถูกต้อง
- Taps/endcaps และ physical cells ที่ต้องมีในระยะนี้ตรง PDK
- PG mapping ครบทุก instance/pin ที่จำเป็น ไม่มี shorts ข้าม domain
- ไม่มี floating rails/straps/macros ที่ยังไม่ได้อธิบายและแก้ไข
- มี geometry checks และ early IR/EM assessment ตามความพร้อมของ model
- Trial placement/global routing แสดงว่า floorplan มีทางไปต่อ พร้อมรายการ hotspot ที่ต้องติดตาม

การผ่านเกณฑ์ระยะ floorplan เป็นการอนุมัติให้เดิน flow ต่อ ไม่ใช่ sign-off ของชิป ยังต้องตรวจหลัง CTS/route/extraction และ physical verification ด้วยข้อมูลสุดท้าย

## 6.17 แบบฝึกหัดและชิ้นงานส่ง

1. คำนวณตัวอย่างในข้อ 6.4 ด้วย U = 0.45, 0.55, 0.65 โดยคง netlist growth เดิม อธิบายว่าพื้นที่ลดลงเท่าใดและสิ่งใดต้องทดสอบเพิ่ม
2. เพิ่ม macro/halo แล้วรายงานทั้ง U_core กับ U_rows จากฐานข้อมูล พร้อมอธิบายส่วนต่าง
3. เปรียบเทียบ aspect ratios สองค่าที่เครื่องมือรองรับโดยคงเป้าพื้นที่ใกล้กัน ตรวจผล wirelength/congestion/timing หลัง trial run
4. สร้างข้อผิดพลาด PDN ในสำเนาทดลอง เช่นขาด via connection หนึ่งจุด แล้วพิสูจน์ว่า checker ตรวจพบ เก็บ baseline ไว้เปรียบเทียบ
5. ทดลอง PDN สองชุด width/pitch แล้วเปรียบเทียบ IR และ routing congestion ด้วย current/source assumptions เดียวกัน

ชิ้นงานประกอบด้วย floorplan database/DEF ตาม flow, configuration/scripts, area budget, pin/macro map, PDN specification, connectivity/geometry reports และตารางเปรียบเทียบ candidate ระบุรุ่นเครื่องมือ/PDK และข้อจำกัดของ early analysis ให้ผู้อื่นทำซ้ำได้

คำถามทบทวน: ทำไม core utilization ต่ำจึงยัง route ไม่ผ่าน? ทำไม filler ไม่เท่ากับ tap? ทำไม PDN connectivity ผ่านจึงยังไม่พอ? และทำไมพื้นที่หลัง synthesis จึงใช้เป็นขนาด core โดยตรงไม่ได้?

## 6.18 เอกสารอ้างอิงและขอบเขตของตัวอย่าง

แหล่งต่อไปนี้ใช้ยืนยัน semantics ของตัวอย่าง OpenROAD และเป็นเอกสารอ่านเพิ่มเติม ไม่ใช้แทน Tanner release manual หรือ foundry design rules

1. OpenROAD — Initialize Floorplan: https://openroad.readthedocs.io/en/latest/main/src/ifp/README.html
2. OpenROAD — Power Distribution Network Generator: https://openroad.readthedocs.io/en/latest/main/src/pdn/README.html
3. OpenROAD — Tapcell: https://openroad.readthedocs.io/en/latest/main/src/tap/README.html
4. OpenROAD Flow Scripts — Flow Tutorial: https://openroad-flow-scripts.readthedocs.io/en/latest/tutorials/FlowTutorial.html

ตรวจเอกสารออนไลน์วันที่ 16 ตุลาคม 2026 สำหรับงานจริงต้องบันทึก release/commit ของเครื่องมือที่ใช้ เนื่องจากหน้า latest อาจเปลี่ยนแปลงได้ ค่า utilization, margin, growth และ power budget ในบทเป็นโจทย์สาธิต ต้องแทนด้วยข้อมูล design, PDK และ package ของงานจริง
