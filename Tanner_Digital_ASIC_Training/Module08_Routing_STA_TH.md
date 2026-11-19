# Module 8 — Routing และ Static Timing Analysis (STA)

เอกสารประกอบหลักสูตร Tanner Digital ASIC Design Implementation ระดับเริ่มต้นถึงระดับกลาง

## 8.1 เป้าหมายการเรียนรู้

เมื่อจบโมดูล ผู้เรียนต้องอธิบายความแตกต่างระหว่าง global routing และ detailed routing อ่านปัญหา congestion และ pin access เชื่อมโยง geometry กับ parasitic RC คำนวณ setup/hold slack ด้วยนิยาม skew ที่ชัดเจน และเสนอ timing repair โดยพิจารณาผลข้างเคียงต่อ area, power, routability และ timing corner อื่นได้

ผลลัพธ์ที่ต้องส่งประกอบด้วย routed design, รายงาน routing/antenna, parasitic extraction, STA setup/hold, หลักฐาน clock และ constraint coverage และตารางเปรียบเทียบก่อน–หลังแก้ไข การจบคำสั่ง route หรือการเห็น slack เป็นบวกเพียงหนึ่ง path ยังไม่เพียงพอต่อการยอมรับงาน

ในหลักสูตรนี้ใช้หลักการเดียวกันกับ RTL ทั้ง VHDL และ Verilog/SystemVerilog หลัง synthesis ทั้งสองภาษาต้องถูกแปลงเป็น technology-mapped netlist ซึ่งอ้างอิง standard-cell library ที่ตรงกับ physical views

## 8.2 จาก placement และ CTS สู่ routed implementation

หลัง placement เครื่องมือทราบตำแหน่ง cell และ pin แต่เส้นเชื่อมที่เห็นอาจเป็นเพียง connectivity หรือ estimated routing หลัง CTS มี clock buffers/inverters และ clock topology แล้ว แต่ geometry และ RC อาจยังไม่ใช่ผลสุดท้าย การ routing ทำให้ net เหล่านี้มีเส้นโลหะและ via ที่สร้างได้ตามกฎของเทคโนโลยี

ข้อมูลตั้งต้นที่ต้องสัมพันธ์กัน ได้แก่ mapped netlist, placement/CTS database, technology/cell LEF, routing rules, macro obstructions, power-grid geometry, Liberty, SDC และ extraction technology data ชื่อ cell/pin/net และหน่วยต้องสอดคล้องกัน การอ่าน LEF ได้สำเร็จไม่ได้ยืนยันว่า Liberty หรือ extraction model ถูก corner

| ระยะ | ข้อมูล interconnect | ใช้ประเมินอะไร | ข้อจำกัดหลัก |
|---|---|---|---|
| หลัง synthesis | wire-load หรือประมาณจากโครงสร้าง | แนวโน้ม logic depth และ cell delay | ไม่เห็น geometry จริง |
| หลัง placement | ประมาณจากตำแหน่ง cell | ความเสี่ยง wirelength/congestion | ยังไม่เห็น detour/via จริง |
| หลัง global route | routing topology และ layer โดยประมาณ | timing/routability ที่ใกล้ขึ้น | ยังไม่ครบรายละเอียด DRC |
| หลัง detailed route | โลหะและ via ที่ route แล้ว | post-route timing เมื่อ extract แล้ว | ต้องตรวจ extraction/annotation |
| หลัง finishing | geometry รวม ECO/fill ตาม flow | ผลสุดท้ายตามวิธี sign-off | ต้องใช้ deck/model ที่กระบวนการรับรอง |

หากมีการเพิ่ม metal fill หรือแก้ geometry หลัง extraction ต้องประเมินผลต่อ capacitance และทำ extraction/STA ซ้ำตาม flow ที่กำหนด อย่าใช้ SPEF เก่ากับ netlist หรือ layout ที่เปลี่ยนแล้ว

## 8.3 Global routing: วางแนวทางและจัดสรรทรัพยากร

Global router แบ่งพื้นที่เป็นบริเวณหรือ global-routing cells แล้วจัดเส้นทางโดยคำนึงถึง connectivity, routing capacity, blockages, layer constraints, wirelength, congestion และ timing ผลที่ใช้ส่งต่อมักเป็น routing guides หรือข้อมูล topology มากกว่าจะเป็น geometry สุดท้ายทุก segment [1]

### 8.3.1 Capacity, demand และ overflow

Capacity คือทรัพยากร routing ที่ใช้งานได้ตามแบบจำลองของเครื่องมือ ส่วน demand คือทรัพยากรที่เส้นทางต้องการบนขอบหรือบริเวณนั้น แนวคิดอย่างง่ายคือ

\[
\mathrm{overflow}=\max(0,\mathrm{demand}-\mathrm{capacity})
\]

ต้องอ่านหน่วยและวิธีรวม overflow ของเครื่องมือ เพราะบางรายงานสรุปตาม edge, layer หรือจำนวน track และอาจมีการลด capacity เพื่อเผื่อรายละเอียดที่ global router ยังไม่จำลอง

แม้ global overflow เป็นศูนย์ detailed routing ก็อาจยังติด เพราะ pin access, via enclosure, local spacing หรือรูปแบบโลหะที่ละเอียดกว่า ในทางกลับกัน การยอมให้ global routing จบทั้งที่ overflow สูงมักผลักปัญหาไปยัง detailed routing และเพิ่ม detour

### 8.3.2 อ่าน congestion map ให้เป็น

ตรวจว่าจุดร้อนอยู่รอบ macro, ช่องระหว่าง macro, บริเวณ I/O, ขอบ power strap หรือกลุ่ม cell ที่มี pin หนาแน่น แยก horizontal/vertical congestion และแยกตาม layer ค่าเฉลี่ยทั้งชิปต่ำอาจซ่อน bottleneck เฉพาะบริเวณได้

ตัวอย่าง: macro สองตัวมีช่องกว้างพอให้วาง cell แต่ช่องนั้นถูก PDN และ pin breakout ใช้ไปมาก การเพิ่ม buffer ในช่องเพื่อแก้ timing อาจทำให้ routability แย่ลง ทางแก้อาจเป็นการขยับ macro ขยาย channel ย้าย pin หรือลด local density แทนการเพิ่มจำนวน routing iterations

### 8.3.3 Routing layer และ PDN

แต่ละ layer มี pitch, preferred direction, resistance, capacitance และข้อจำกัดต่างกัน การใช้โลหะชั้นบนอาจลด resistance ของเส้นยาว แต่ต้องแลกกับ via stack และทรัพยากรที่อาจสงวนให้ clock/PDN ผลด้าน delay ต้องวัดจาก RC และ load จริง

Power straps และ macro obstructions ลดพื้นที่เดินสัญญาณ จึงไม่ควรวางแผน signal routing โดยคิดว่าโลหะทุกชั้นมี capacity เต็ม การเปิด layer เพิ่มต้องสอดคล้องกับ PDK, stack ที่เลือก และการแบ่งใช้ทรัพยากรของทั้งชิป

## 8.4 Detailed routing: สร้าง geometry ที่ต่อถึงและผ่านกฎ

Detailed router เลือก track, wire segment และ via เพื่อเชื่อม pin ให้ครบ พร้อมหลีกเลี่ยง short และละเมิดกฎ geometry สำหรับ OpenROAD องค์ประกอบที่ระบุในเอกสารรวม pin-access analysis, track assignment, initial routing และ search-and-repair ร่วมกับ DRC engine [2]

ตัวชี้วัดที่ต้องอ่าน ได้แก่ unrouted connections, DRC markers แยกชนิด, wirelength, via count และแนวโน้มการแก้ violation ระหว่าง iterations จำนวน markers คงที่นานอาจชี้ข้อจำกัดทาง geometry ที่ต้องย้อนแก้ placement หรือ pin location

### 8.4.1 Pin access

Pin access คือความสามารถในการเข้าถึงรูป pin ด้วย wire/via ที่ถูกกฎ Pin อาจมีอยู่ใน LEF แต่เข้าถึงได้ยากเมื่อถูกบังด้วยโลหะใกล้เคียง cell neighbor, macro blockage หรือข้อจำกัด via

สิ่งที่ต้องตรวจใน layout ได้แก่ pin shape/layer, routing grid, ตำแหน่ง cell และ orientation, spacing รอบ pin, enclosure ของ via และโลหะของ PDN ที่ผ่านใกล้กัน ปัญหา pin access บางอย่างแก้ได้ด้วย cell spreading, เปลี่ยน cell equivalent หรือปรับตำแหน่ง macro/pin แต่ทุกวิธีต้องรักษา placement legality และ connectivity

อย่าแก้ด้วยการลด spacing หรือปิดกฎ DRC เพียงเพื่อให้ route จบ กฎจากเทคโนโลยีต้องเป็นเงื่อนไขของการแก้ปัญหา

### 8.4.2 Via

Via เชื่อมโลหะต่างชั้นและมี resistance รวมถึงข้อกำหนด cut spacing/enclosure การเปลี่ยน layer บ่อยเพิ่ม via count และอาจเพิ่ม delay หรือความซับซ้อนในการ route แม้ wirelength รวมจะสั้นลง

Via array หรือ redundant via อาจเพิ่มความทนทานและลด resistance เมื่อ flow/PDK รองรับ แต่ต้องมีพื้นที่และผ่านกฎ การลด via ทุกตัวก็ไม่ใช่เป้าหมาย เพราะบาง via จำเป็นต่อการหลบสิ่งกีดขวางหรือเลือก layer ที่เหมาะสม

### 8.4.3 Router DRC กับ sign-off DRC

Router ใช้แบบจำลองกฎที่รองรับเพื่อสร้างและซ่อมเส้นทาง แต่ผล router DRC เป็นศูนย์ไม่ทดแทน final DRC ด้วย deck ที่กำหนด รวมทั้งต้องตรวจ LVS และ power connectivity ตามโมดูล physical verification

งานที่ route จบแต่มี unconnected pin, supply net ต่อผิด หรือ LVS ไม่ตรง ยังไม่ใช่งานที่พร้อมส่งผลิต

## 8.5 RC extraction: เชื่อม layout เข้ากับ timing

### 8.5.1 องค์ประกอบ parasitic

เส้นโลหะมี distributed resistance และ capacitance ไม่ใช่ wire ที่ delay เป็นศูนย์ แบบจำลองพื้นฐานสำหรับเส้นสม่ำเสมอคือ

\[
R\approx\rho\frac{L}{wt}
\]

โดย \(L\) คือความยาว \(w\) คือความกว้าง \(t\) คือความหนา และ \(\rho\) คือ resistivity สูตรนี้ใช้สร้าง intuition ส่วน extraction จริงต้องใช้ model ของเทคโนโลยี รวมผล geometry และ process ที่เกี่ยวข้อง

Capacitance ประกอบด้วย coupling ไปยังตัวนำรอบข้างและ capacitance ต่อ reference conductor ดังนั้น wire ที่ยาวเท่ากันอาจมี RC ไม่เท่ากัน หากอยู่คนละ layer หรือมีเพื่อนบ้านต่างกัน

สำหรับโซ่ RC แบบต้นไม้ แนวคิด Elmore delay เขียนได้เป็นผลรวม \(R_i C_{\mathrm{downstream},i}\) ช่วยอธิบายว่าความต้านทานใกล้ driver ซึ่งต้องชาร์จ capacitance ปลายทางจำนวนมากมีผลสำคัญ แต่ STA จริงอาจใช้วิธีคำนวณที่ละเอียดกว่านี้

### 8.5.2 Cell delay และ net delay มีความสัมพันธ์กัน

Cell delay ขึ้นกับ input slew และ output load จาก Liberty เมื่อ wire capacitance เพิ่ม ไม่เพียง net delay เพิ่ม แต่ driver อาจช้าลงและส่ง slew ที่แย่ไปยัง cell ถัดไป ดังนั้นการแยก cell/net delay มีประโยชน์ในการวินิจฉัย แต่ทั้งสองส่วนไม่ได้เป็นอิสระจากกัน

การใส่ buffer อาจลด delay ของเส้นยาวโดยแบ่ง RC/load แต่เพิ่ม cell delay, input capacitance, area และ power ต้องประเมินผลทั้งเส้นทางและ fanout branches ที่ใช้ร่วมกัน

### 8.5.3 SPEF และ annotation

SPEF เป็นรูปแบบแลกเปลี่ยน parasitic network ไม่ใช่รายงาน slack และไม่ใช่ SDF ซึ่งใช้แลกเปลี่ยน delay/timing-check information สำหรับงานที่รองรับ ทั้งสองไฟล์มีหน้าที่ต่างกัน

ก่อนเชื่อผล post-route STA ต้องตรวจ:

1. SPEF มาจาก geometry และ revision เดียวกับ netlist ปัจจุบัน
2. Hierarchy delimiter, bus naming และ name mapping ตรงกัน
3. Resistance/capacitance units ถูกต้องและเครื่องมืออ่านตามคาด
4. Clock/data nets ที่คาดว่าจะมี parasitic ได้รับ annotation
5. ไม่มี warning ที่ทำให้ nets สำคัญถูกละเว้นหรือใช้ค่าประมาณโดยไม่ตั้งใจ
6. Extraction corner และ coupling treatment ถูกระบุในบันทึกผล

ไม่ควรกำหนดว่า coverage ต้องเป็น 100% โดยไม่อ่านนิยาม denominator เช่น supply, ideal nets หรือ nets ที่ไม่มี routed segment อาจถูกนับต่างกัน ต้องแจกแจงส่วนที่ไม่ annotate และยืนยันว่าไม่ทำให้เส้นทางสำคัญขาด RC

OpenRCX เป็นตัวอย่าง extractor ที่ทำงานกับ routed database และ extraction model ของเทคโนโลยี [3] การมีไฟล์ SPEF ไม่ได้ยืนยันโดยตัวมันเองว่าเป็น sign-off extraction ที่กระบวนการผลิตยอมรับ

### 8.5.4 PVT corner กับ RC corner

PVT corner กำหนดพฤติกรรม cell ขณะที่ RC corner กำหนด parasitic interconnect ต้องตรวจเป็น analysis scenario ที่ flow กำหนด อย่าสรุปว่า setup แย่สุดต้องเป็น slow/hot เสมอ หรือ hold แย่สุดต้องเป็น fast/cold เสมอ เพราะผลขึ้นกับ library, temperature dependence, clock/data topology และ corner combinations ที่รับรอง

Coupling capacitance อาจมีผลต่อ delay และ noise ตามการสวิตช์ของ aggressor การอ่าน coupling ใน SPEF ไม่ได้ยืนยันว่า STA เปิด signal-integrity analysis แล้ว ต้องระบุความสามารถและ mode ของเครื่องมือที่ใช้

## 8.6 Antenna effect และการซ่อม

Antenna effect เกี่ยวข้องกับประจุสะสมระหว่างกระบวนการ fabrication ซึ่งอาจทำให้ gate dielectric เสียหาย กฎจึงสัมพันธ์กับโลหะที่เชื่อมกับ gate ในขั้นตอนการผลิต ไม่ใช่เพียงความยาว wire หรือการทำงานปกติหลังผลิตเสร็จ

กฎอาจพิจารณา area, sidewall area, gate area, diffusion/diode และ cumulative exposure ตาม layer คำว่า partial/cumulative ratio ต้องอ่านตาม rule deck จริง จึงไม่ควรใช้สูตร antenna ratio แบบเดียวแทนทุกเทคโนโลยี

แนวทางซ่อมที่ใช้ได้เมื่อ PDK/flow รองรับ ได้แก่ layer jumping เพื่อเปลี่ยน connectivity ระหว่างขั้นตอนผลิต เพิ่ม antenna diode ที่ได้รับอนุญาต หรือ reroute ให้สอดคล้องกับข้อกำหนด การเพิ่ม diode เพิ่ม capacitance และอาจกระทบ timing/placement ส่วน jumper เพิ่ม via และเปลี่ยน RC

หลัง antenna repair ต้อง legalize และ route ส่วนที่เปลี่ยน ตรวจ antenna/DRC ซ้ำ extract RC ใหม่ และรัน STA อีกครั้ง อย่าใช้ timing report ก่อนเพิ่ม diode เป็นผลหลังซ่อม

## 8.7 ขอบเขตและสัญลักษณ์ของสมการ STA

ส่วนนี้พิจารณา edge-triggered register-to-register path ภายใต้คล็อกเดียว ใช้ active edge ชนิดเดียวกัน setup ตรวจกับ capture edge ถัดไป และ hold ตรวจกับ edge ปัจจุบัน ไม่รวม timing exceptions, latch borrowing หรือ generated/multiphase clock relationships

| สัญลักษณ์ | ความหมาย |
|---|---|
| \(T_{period}\) | คาบระหว่าง launch edge กับ capture edge ถัดไป |
| \(L\) | clock arrival ที่ launch register |
| \(C\) | clock arrival ที่ capture register สำหรับ edge อ้างอิงเดียวกัน |
| \(skew=C-L\) | capture clock arrival ลบ launch clock arrival |
| \(T_{cq,max/min}\) | clock-to-Q delay สูงสุด/ต่ำสุดของ launch register |
| \(T_{data,max/min}\) | delay จาก Q ถึง D ผ่าน combinational cells และ interconnect ไม่รวม Tcq |
| \(T_{setup},T_{hold}\) | timing checks ของ capture register สำหรับ transition/condition ที่วิเคราะห์ |
| \(U_{setup},U_{hold}\) | uncertainty budget ของแต่ละ check ในแบบจำลองนี้ |

Max/min เป็นการเลือกเส้นทางและเงื่อนไขการวิเคราะห์ที่เหมาะกับ check ไม่ใช่นำ max delay เดียวกันไปใช้ทั้ง setup และ hold และค่า setup/hold ใน Liberty อาจขึ้นกับ slew และมีเครื่องหมายต่างจากตัวอย่างได้

## 8.8 Setup analysis และการพิสูจน์สมการ

กำหนด launch reference edge ที่เวลา 0 เวลาที่ data มาถึงช้าที่สุดคือ

\[
A_{setup}=L+T_{cq,max}+T_{data,max}
\]

เวลาที่ data ต้องมาถึงไม่เกินคือ

\[
R_{setup}=T_{period}+C-T_{setup}-U_{setup}
\]

Setup ผ่านเมื่อ \(A_{setup}\le R_{setup}\) ย้ายข้างและใช้ \(skew=C-L\) ได้

\[
\boxed{T_{cq,max}+T_{data,max}+T_{setup}+U_{setup}\le T_{period}+skew}
\]

\[
\boxed{S_{setup}=T_{period}+skew-T_{cq,max}-T_{data,max}-T_{setup}-U_{setup}}
\]

Setup slack คือ required time ลบ arrival time ค่าไม่ติดลบหมายถึงผ่าน check ภายใต้ scenario นี้ Positive skew ทำให้ capture edge มาช้าขึ้น จึงเพิ่มเวลาที่ data มีสำหรับ setup

### 8.8.1 ตัวอย่าง setup

กำหนด period 10.00 ns, skew +0.10 ns, Tcq,max 0.20 ns, data,max 8.90 ns, setup 0.30 ns และ uncertainty 0.20 ns

\[
S_{setup}=10.00+0.10-0.20-8.90-0.30-0.20=\boxed{+0.50\ ns}
\]

เมื่อเลือก \(L=0\) และ \(C=0.10\) เพื่อคำนวณโดยใช้ reference ที่สะดวก จะได้ arrival = 9.10 ns และ required = 9.60 ns ความต่างคือ 0.50 ns การเลือก \(L=0\) นี้เป็นการเลื่อนจุดอ้างอิงเวลา ไม่ได้หมายความว่า clock tree ไม่มี insertion delay จริง

Data budget สูงสุดเท่ากับ 9.40 ns ดังนั้น data path 8.90 ns เหลือ margin 0.50 ns ตัวเลขนี้เป็นผลของตัวอย่าง ไม่ใช่ margin sign-off ที่ใช้ได้กับทุก flow

## 8.9 Hold analysis และการพิสูจน์สมการ

Hold ตรวจว่าข้อมูลใหม่จาก launch edge เดียวกันไม่มาถึงเร็วเกินไปจนรบกวนข้อมูลเดิมที่ capture register ต้องรักษาไว้

\[
A_{hold}=L+T_{cq,min}+T_{data,min}
\]

\[
R_{hold}=C+T_{hold}+U_{hold}
\]

Hold ผ่านเมื่อ \(A_{hold}\ge R_{hold}\) จึงได้

\[
\boxed{T_{cq,min}+T_{data,min}\ge T_{hold}+U_{hold}+skew}
\]

\[
\boxed{S_{hold}=T_{cq,min}+T_{data,min}-T_{hold}-U_{hold}-skew}
\]

สำหรับนิยามนี้ hold slack คือ arrival time ลบ required time Positive skew ทำให้ capture edge มาช้าขึ้น จึงต้องรักษาข้อมูลเดิมนานขึ้น และ hold ยากขึ้น

### 8.9.1 ตัวอย่าง hold

กำหนด Tcq,min 0.08 ns, data,min 0.05 ns, hold 0.10 ns, uncertainty 0.02 ns และ skew +0.10 ns

\[
S_{hold}=0.08+0.05-0.10-0.02-0.10=\boxed{-0.09\ ns}
\]

เมื่อเลือก \(L=0\) และ \(C=0.10\) จะได้ earliest arrival = 0.13 ns แต่ต้องไม่มาก่อน 0.22 ns ข้อมูลใหม่จึงมาเร็วไป 0.09 ns

หากทุกค่าอื่นคงเดิม ต้องเพิ่ม minimum data delay อย่างน้อย 0.09 ns เพื่อแตะศูนย์ทางคณิตศาสตร์ แต่ implementation ต้องใช้ delay ที่วัดหลัง route และตรวจทุก scenario พร้อม margin ตามโครงการ การเพิ่ม delay 0.09 ns ที่ nominal corner ไม่รับประกันว่าจะเพิ่มได้เท่ากันที่ fast corner

การเพิ่ม period จาก 10 เป็น 12 ns ช่วย setup 2 ns ในแบบจำลองนี้ แต่ไม่แก้ hold เนื่องจากไม่มี period อยู่ในสมการ hold สำหรับความสัมพันธ์ของ edge ที่กำหนด

## 8.10 ความสัมพันธ์ของ skew กับ setup/hold

| การเปลี่ยนโดยตรึงปัจจัยอื่น | Setup slack | Hold slack |
|---|---:|---:|
| skew เพิ่ม +0.10 ns | เพิ่ม 0.10 ns | ลด 0.10 ns |
| data delay เพิ่ม 0.10 ns ใน check นั้น | ลด 0.10 ns | เพิ่ม 0.10 ns |
| uncertainty ของ check เพิ่ม 0.10 ns | ลด 0.10 ns | ลด 0.10 ns |
| period เพิ่ม 1 ns | เพิ่ม 1 ns | ไม่เปลี่ยน |

ตารางเป็น sensitivity ของสมการอย่างง่าย การเปลี่ยน cell หรือ route จริงอาจเปลี่ยน max และ min delay ไม่เท่ากัน รวมทั้งเปลี่ยน slew/load ของ path อื่นด้วย

Skew ของคู่ register ไม่ใช่ clock latency ของ register ตัวใดตัวหนึ่ง และไม่เท่ากับ global maximum skew เสมอ ตัวเลข capture–launch ที่ใช้ในแต่ละ check ต้องอ้างอิง edge และ early/late assumptions ที่เครื่องมือเลือก

## 8.11 Derates และ common-path pessimism removal

สมการข้างต้นเป็นฐานสำหรับเรียนรู้ ในรายงานจริงเครื่องมืออาจใช้ early/late derates, OCV/AOCV/POCV ตามความสามารถและวิธีวิเคราะห์ รวมถึง common-path pessimism removal ซึ่งอาจเรียก CPPR หรือ CRPR

โดยแนวคิด setup ที่ pessimistic มักพิจารณา launch clock/data ทางช้าและ capture clock ทางเร็ว ส่วน hold มักใช้ launch/data ทางเร็วและ capture clock ทางช้า แต่ต้องอ่าน actual path report และ scenario ไม่ควรแทนด้วยค่าคล็อก nominal เพียงคู่เดียว

Launch และ capture clock อาจมี segment ร่วมกัน การใช้ early/late ที่ต่างกันบน segment เดียวกันอาจสร้าง pessimism จึงมี correction เพื่อเอาส่วนที่เกินจำเป็นออกตามวิธีของเครื่องมือ Correction นี้เป็นการคำนวณวิเคราะห์ ไม่ใช่การเพิ่ม buffer หรือเปลี่ยน geometry

วิธีอ่านรายงานคือเริ่มจาก clock edge, ไล่ source/network latency และ derated increments แยก launch/capture แล้วดู uncertainty, library timing check และ pessimism correction ในตำแหน่งที่รายงานแสดง อย่านำ correction มาบวกซ้ำกับ slack ที่เครื่องมือคำนวณแล้ว

หลัง CTS ต้องใช้ propagated clock สำหรับ post-CTS/post-route analysis ตาม flow และตรวจว่าไม่ได้คง ideal-network assumptions โดยไม่ตั้งใจ Uncertainty หลัง CTS ยังอาจจำเป็นสำหรับ jitter และ budget ที่เหลือ แต่ต้องไม่บวก estimated skew budget เดิมซ้ำกับ clock skew ที่ propagate จริง

## 8.12 วิธีอ่าน timing report อย่างเป็นระบบ

1. ระบุ mode, PVT/RC corner, min/max analysis, derate และ parasitic source
2. ระบุ startpoint/endpoint ว่าเป็น register และอยู่ใน clock relationship ที่คาดไว้
3. ตรวจ launch/capture edge รวม period และ phase ก่อนอ่าน delay
4. ตรวจว่า clock propagated และ clock paths มี cell/net delay ตามคาด
5. แยก Tcq, combinational cell delay และ net delay โดยไม่บวก Tcq ซ้ำ
6. อ่าน input slew, output load และ transition ที่ละเมิดเพื่อหาสาเหตุ
7. ตรวจ required time รวม setup/hold, uncertainty และ correction
8. คำนวณ slack ตาม check และเทียบกับค่าที่รายงาน
9. ตรวจ path อื่นในกลุ่มเดียวกันและทุก scenario หลังแก้ไข

หาก report รวม arrival ของ launch clock อยู่แล้ว อย่าเพิ่ม skew ซ้ำเข้าไปใน arrival สมการย่อใช้หลังหัก \(L\) ออกทั้งสองข้างแล้ว

### 8.12.1 WNS, TNS และ coverage

Worst slack ชี้กรณีที่แย่ที่สุด ส่วน WNS บางเครื่องมือใช้ความหมายเฉพาะค่าติดลบและคืนศูนย์เมื่อทุก path ผ่าน TNS สะท้อนผลรวม negative slack ตามวิธีนับ endpoint/path ของเครื่องมือ จึงต้องระบุ report definition เมื่อต้องเปรียบเทียบข้ามเครื่องมือ

รายงาน setup และ hold แยกกันพร้อมจำนวน violating endpoints/path groups ไม่ใช้จำนวนเส้นทางที่พิมพ์ออกมาเป็นจำนวน violation ทั้งหมด เพราะตัวเลือก report อาจจำกัดจำนวน path

WNS/TNS ดูดีแต่มี unconstrained endpoints หรือ missing clocks ยังสรุปว่า timing ผ่านไม่ได้ และ STA ไม่ทดแทน CDC/metastability analysis, functional verification หรือ power-integrity verification

## 8.13 ตัวอย่าง RTL คู่ภาษาเพื่อใช้ศึกษารูปแบบ path

ตัวอย่างนี้มี register สองชั้น ค่าผลรวมจาก a_q ถูกจับที่ q_o ใน edge ถัดไป ใช้ synchronous reset เพื่อลดความซับซ้อนของการสาธิต register-to-register timing

### SystemVerilog

```systemverilog
module route_sta_demo (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] d_i,
    output logic [7:0] q_o
);
    logic [7:0] a_q;
    always_ff @(posedge clk) begin
        if (rst) begin
            a_q <= 8'h00;
            q_o <= 8'h00;
        end else begin
            a_q <= d_i;
            q_o <= a_q + 8'h01;
        end
    end
endmodule
```

### VHDL-2008

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity route_sta_demo is
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        d_i : in  std_logic_vector(7 downto 0);
        q_o : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of route_sta_demo is
    signal a_q : unsigned(7 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                a_q <= (others => '0');
                q_o <= (others => '0');
            else
                a_q <= unsigned(d_i);
                q_o <= std_logic_vector(a_q + to_unsigned(1, 8));
            end if;
        end if;
    end process;
end architecture;
```

ทั้งสองตัวอย่างเป็น alternative implementations ให้เลือกใช้หนึ่งภาษาในแต่ละ run ไม่ compile เป็น top ชื่อเดียวกันพร้อมกัน ผลบวกมีความกว้าง 8 บิตและ wrap เมื่อเกิน 255 เหมือนกัน ไม่มีการกำหนด delay ด้วย RTL

Synthesis อาจ optimize, เปลี่ยนชื่อ หรือเลือกโครงสร้าง cell ต่างกัน จึงต้องเลือก startpoint/endpoint จาก mapped netlist จริง ไม่ hard-code ชื่อ RTL register โดยไม่ตรวจสอบ ตัวอย่างตัวเลข slack ก่อนหน้านี้เป็นโจทย์คำนวณอิสระ ไม่ใช่ผลวัดของวงจรนี้

## 8.14 ตัวอย่าง SDC และ post-route STA ด้วย OpenSTA

คำสั่งต่อไปนี้เป็นตัวอย่างอ้างอิง OpenSTA [4] ไม่ใช่ Tcl ของ Tanner/Siemens และไม่ใช่สคริปต์พร้อมรันโดยไม่มี library/netlist/SPEF ต้องแทน path และตรวจ syntax กับเวอร์ชันที่ติดตั้ง การตั้งค่า Tanner ให้ใช้ขั้นตอนและคำสั่งที่เอกสารของรุ่นนั้นรองรับ โดยยึดหลักการตรวจเดียวกัน

### 8.14.1 SDC สำหรับวงจรสาธิต

```tcl
# Example values: confirm time units are ns in the loaded library.
create_clock -name core_clk -period 10.000 [get_ports clk]
set_clock_uncertainty -setup 0.200 [get_clocks core_clk]
set_clock_uncertainty -hold  0.020 [get_clocks core_clk]

# Example external synchronous environment, including synchronous reset.
set_input_delay -clock core_clk -max 2.000 [get_ports {d_i* rst}]
set_input_delay -clock core_clk -min 0.200 [get_ports {d_i* rst}]
set_output_delay -clock core_clk -max 2.000 [get_ports {q_o*}]
set_output_delay -clock core_clk -min -0.100 [get_ports {q_o*}]
```

ค่า I/O เป็นสมมติฐานของแลบ ไม่ใช่ข้อกำหนดสำหรับทุกชิป Output delay -min ที่เป็นลบในตัวอย่างแทน external hold requirement ภายใต้ clock reference ที่กำหนด ต้องสร้าง budget จากอุปกรณ์ปลายทางและ board timing จริง

ต้องกำหนด input drive/transition และ output load ให้ตรง environment เพิ่มด้วย ค่าตัวเลข capacitance ต้องอ่านจากหน่วย library การใช้ wildcard ต้องตรวจว่า match ครบและไม่มี empty collection อย่าใส่ false path ให้ synchronous reset โดยอัตโนมัติ

### 8.14.2 โครงสร้างสคริปต์ STA หนึ่ง scenario

```tcl
read_liberty ./lib/selected_corner.lib
read_verilog ./results/route_sta_demo_postroute.v
link_design route_sta_demo
read_sdc ./constraints/route_sta_demo.sdc
read_spef ./results/route_sta_demo_selected_rc.spef
set_propagated_clock [all_clocks]

report_units
check_setup -verbose
report_parasitic_annotation
report_checks -path_delay max -format full_clock_expanded \
    -group_path_count 10
report_checks -path_delay min -format full_clock_expanded \
    -group_path_count 10
```

ตัวอย่างอ่าน Liberty หนึ่งไฟล์เพื่อแสดงลำดับ สำหรับงานจริงต้องอ่าน libraries ครบทุก cell ที่ instantiate รวม clock, I/O และ macro timing models ที่เกี่ยวข้อง สคริปต์หนึ่ง scenario ต้องรันซ้ำตาม analysis matrix ที่กำหนด หรือใช้ multi-corner setup ที่รองรับ

รายงานตัวอย่างอาจรวม I/O paths ให้เลือก register-to-register path จากรายงานจริงเพื่อฝึกสมการ การเปลี่ยน propagated flag ไม่ได้สร้าง CTS หรือ clock parasitics ต้องมี clock-tree netlist และข้อมูล delay ที่ถูกต้องอยู่แล้ว

### 8.14.3 หลักการใช้ timing repair ใน implementation tool

OpenSTA ทำหน้าที่วิเคราะห์ ส่วน implementation tool ต้องแก้ cell/placement/routing ด้วย workflow ของตน OpenROAD มี gate-resizer/timing-repair facilities เป็นตัวอย่าง [5] แต่ไม่ควรนำคำสั่ง repair ไปใส่ใน standalone STA session แล้วคาดว่าจะได้ layout ที่แก้ครบ

ลำดับเชิงแนวคิดคือ analyze → เลือก ECO → เปลี่ยน cell/netlist → legalize → route ส่วนที่เปลี่ยน → extract → analyze ทุก scenario → physical verification การแก้ก่อน route บางช่วงอาจใช้ estimated parasitics เพื่อให้เร็วขึ้น แต่การยอมรับผลต้องใช้ parasitics ที่เหมาะกับ milestone

## 8.15 Timing repair: เลือกวิธีตามสาเหตุ

### 8.15.1 Setup violation

| สาเหตุจากรายงาน/geometry | แนวทางแก้ | ผลข้างเคียงที่ต้องตรวจ |
|---|---|---|
| logic depth สูง | ลด logic levels, restructure หรือ pipeline เมื่อ specification ยอมรับ | latency และ functional behavior |
| driver อ่อน/โหลดมาก | resize หรือ buffer fanout branches | upstream load, area, power |
| wire delay เด่น | ย้าย cell, ลด detour, ปรับ route/layer ตามกฎ | congestion, via, hold |
| pin access บังคับ detour | spreading, equivalent cell, ปรับตำแหน่ง pin/macro | legality, DRC |
| clock relationship/constraints ผิด | แก้ให้ตรง specification และ environment | coverage และผลทุก path |

อย่าคาดว่า upsizing ทุก cell จะทำให้ timing ดีเสมอ Cell ใหญ่ขึ้นเพิ่ม input capacitance ซึ่งอาจทำให้ stage ก่อนหน้าช้าลง และใช้พื้นที่ routing มากขึ้น การเพิ่ม buffer ในบริเวณแออัดอาจทำให้ route อ้อมจนเสียประโยชน์เดิม

การเพิ่ม pipeline register เปลี่ยน architecture และ latency จึงต้องแก้ RTL ทั้งสองภาษาที่ใช้ในหลักสูตรและตรวจ functional behavior ใหม่ ไม่ถือเป็น physical ECO ที่โปร่งใสต่อระบบ

### 8.15.2 Hold violation

แนวทางหลักคือเพิ่ม delay ใน data branch ที่เกี่ยวข้อง เช่นใช้ delay/buffer cells ที่ flow อนุญาต หรือเลือก cell implementation ที่ช้าลงอย่างเหมาะสม ตำแหน่งการแทรกใกล้ capture branch ช่วยจำกัดผลต่อ fanout อื่น แต่ต้องตัดสินจาก topology และพื้นที่จริง

ต้องตรวจ setup ของ path เดียวกันและ path ที่ใช้ร่วมกันทุกครั้ง Route detour อาจเพิ่ม delay ได้แต่ไวต่อ geometry/corner และต้องเป็นวิธีที่ implementation flow ควบคุม การต่อ delay ด้วย `#delay` ใน Verilog หรือ `after` ใน VHDL ไม่ใช่วิธีสร้าง hold fix สำหรับ ASIC

หากใช้ delay buffers ให้เครื่องมือรักษาไว้ตามวิธีของ flow อย่าใส่ inverter ตัวเดียวจนกลับ polarity และอย่าสมมติว่าการเพิ่ม RTL buffer จะรอด synthesis optimization เสมอ

### 8.15.3 ตัวอย่างผลแลกเปลี่ยน

ถ้า setup +0.50 ns และ hold −0.09 ns เป็น check ของ path ที่ต้องแก้ร่วมกัน และ ECO เพิ่ม max data delay 0.15 ns กับ min data delay 0.12 ns โดยค่าอื่นคงเดิม จะได้ setup +0.35 ns และ hold +0.03 ns

ผลนี้เป็นการคำนวณเพื่ออธิบาย tradeoff เท่านั้น ต้องยืนยันค่าที่เพิ่มจริงหลัง route/extraction และตรวจว่า endpoint/corner อื่นไม่ล้มเหลว Margin +0.03 ns ไม่ได้หมายถึงพร้อม sign-off โดยอัตโนมัติ

### 8.15.4 Clock ECO และ useful skew

การปรับ clock arrival อาจช่วย path หนึ่งแต่ทำให้ path ที่เชื่อมเข้า/ออกจาก register เดียวกันแย่ลง ทั้ง setup และ hold รวมถึงเปลี่ยน clock slew/load จึงต้องวิเคราะห์ทั้ง timing graph และทุก scenario อย่าแก้ clock tree จากสมการของ path เดียว

## 8.16 ขั้นตอนปฏิบัติสำหรับแลบ

### ขั้นที่ 1 — ยืนยัน baseline หลัง CTS

บันทึก tool version, PDK/library revision, netlist/SDC/database และ scenario ตรวจ placement legality, clock sinks และ propagated/ideal settings ให้ชัดเจน เก็บ setup/hold reports ก่อน route โดยระบุว่าใช้ estimated RC แบบใด

### ขั้นที่ 2 — Global route และวิเคราะห์ bottleneck

รันตาม flow ที่เตรียมไว้ เก็บ guides/congestion reports เปิดดูจุดร้อนอย่างน้อยหนึ่งแห่ง ระบุ layer, macro/PDN ที่เกี่ยวข้อง และผลกระทบต่อ critical path ถ้า overflow หรือ pin density สูงให้แก้ placement/floorplan อย่างมีเหตุผล

### ขั้นที่ 3 — Detailed route

ตรวจ unrouted connections และ DRC แยกชนิด เลือก marker หนึ่งจุดมาอธิบายด้วย geometry จริง หากต้องเปลี่ยน placement ให้บันทึก revision และ route ใหม่ตาม flow อย่าใช้การมองภาพรวมทั้งชิปแทนการตรวจ pin/via ระดับขยาย

### ขั้นที่ 4 — Antenna และ finishing

ตรวจด้วยวิธีที่ flow กำหนด ซ่อมด้วย cell/layer strategy ที่รองรับ แล้วตรวจซ้ำ บันทึก diode count และ geometry changes หาก finishing ทำให้ RC เปลี่ยนให้วาง extraction หลังขั้นตอนนั้นตามข้อกำหนดโครงการ

### ขั้นที่ 5 — Extract และตรวจ annotation

ใช้ extraction technology data ที่ตรง stack/corner เก็บ SPEF และ log ตรวจ missing names/unannotated nets ก่อนรัน STA เมื่อมี warning ห้ามข้ามไปตีความ slack โดยยังไม่ทราบผลกระทบ

### ขั้นที่ 6 — วิเคราะห์ setup/hold

รัน scenario matrix รายงาน max/min แยกกัน เลือก worst setup และ worst hold อย่างน้อยอย่างละหนึ่ง path คำนวณ arrival/required/slack ด้วยตนเอง พร้อมระบุส่วนที่เป็น derate หรือ correction จากเครื่องมือ

### ขั้นที่ 7 — ทำ ECO หนึ่งรอบ

เลือกปัญหาจริงหนึ่งรายการ ระบุสาเหตุก่อนแก้ ทำ legalize/reroute/re-extract และ STA ซ้ำ เปรียบเทียบ cell area, wirelength, via count, buffer/diode count, setup/hold และ DRC ใช้ design/corner/report definition เดิมเพื่อให้เทียบกันได้

### ขั้นที่ 8 — จัดชุดหลักฐาน

ส่ง final database/netlist, constraints, SPEF ตาม corners ที่วิเคราะห์, routing/antenna/STA reports และ manifest ระบุ revision ของ inputs/outputs ให้สามารถรันซ้ำได้ อย่าแยกส่ง netlist จากคนละ ECO กับ SPEF

## 8.17 ตารางสรุปผลที่ผู้เรียนต้องกรอก

| รายการ | ก่อน ECO | หลัง ECO | Corner/ข้อสังเกต |
|---|---|---|---|
| Worst setup slack / setup TNS | | | |
| Worst hold slack / hold TNS | | | |
| Violating endpoints แยก setup/hold | | | |
| Unconstrained endpoints / missing clocks | | | |
| Parasitic annotation และข้อยกเว้น | | | |
| Transition/capacitance violations | | | |
| Unrouted connections / routing DRC | | | |
| Antenna violations | | | |
| Cell area / wirelength / via count | | | |
| Buffer/delay-cell/antenna-diode count | | | |

หากไม่มีข้อมูลให้ระบุ “ยังไม่ได้ตรวจ” พร้อมเหตุผล ไม่ใช้ศูนย์แทนข้อมูลที่ไม่ได้วัด

## 8.18 ปัญหาที่พบบ่อยและการวินิจฉัย

| อาการ | สิ่งที่ควรตรวจเป็นอันดับแรก |
|---|---|
| Post-route setup แย่กว่า post-CTS มาก | RC source, detour, congestion, slew/load และ clock mode |
| Hold แย่หลัง CTS/route | pairwise skew และ minimum data path พร้อม fast scenarios |
| Global overflow เป็นศูนย์แต่ detailed route ติด | pin access, local spacing, via enclosure และ macro obstruction |
| SPEF อ่านผ่านแต่ net delay ต่ำผิดปกติ | annotation coverage, net naming, units และ revision |
| เพิ่ม buffer แล้ว setup แย่ลง | upstream capacitance, extra stages และ route congestion |
| เพิ่ม period แล้ว hold ยังติด | เป็นพฤติกรรมที่คาดได้ของ same-edge hold ในขอบเขตนี้ |
| Router DRC ผ่านแต่ final DRC ไม่ผ่าน | ความต่างของกฎที่รองรับและ geometry หลัง finishing |
| ไม่มี negative slack แต่ clocks/endpoints หาย | constraint/linking coverage ก่อนพิจารณา timing closure |

## 8.19 แบบฝึกหัดและแนวคำตอบ

1. จากตัวอย่าง setup ถ้า skew เปลี่ยนจาก +0.10 เป็น −0.10 ns โดยค่าอื่นคงเดิม slack เท่าไร? **+0.30 ns**
2. จากตัวอย่าง hold ถ้า skew เป็นศูนย์ slack เท่าไร? **+0.01 ns**
3. ต้องเพิ่ม minimum data delay เท่าไรเพื่อให้ hold ตัวอย่างมี margin +0.05 ns? **0.14 ns ภายใต้สมมติฐานว่าค่าอื่นไม่เปลี่ยน**
4. ถ้า setup ตัวอย่างมี data,max เพิ่ม 0.70 ns จาก detour slack เป็นเท่าไร? **−0.20 ns**
5. เหตุใดการลด clock frequency จึงไม่ใช่ hold fix สำหรับ path นี้? **เพราะ check ใช้ edge เดียวกันและสมการไม่มี period**
6. Antenna diode ช่วยปัญหา fabrication แล้วเหตุใดต้องตรวจ timing ซ้ำ? **เพราะเพิ่ม load และอาจเปลี่ยน placement/route/RC**
7. มี SPEF แล้วถือว่า SI sign-off ผ่านหรือไม่? **ยังสรุปไม่ได้ ต้องตรวจ coupling treatment และความสามารถ/mode ของ analyzer**
8. ต้องหัก CPPR ออกจาก slack ที่รายงานอีกครั้งหรือไม่? **ไม่ทำซ้ำ ต้องดูว่าเครื่องมือรวม correction แล้วอย่างไร**

## 8.20 เกณฑ์ยอมรับงาน

ผู้เรียนต้องแสดง connectivity และ routing checks ที่ไม่มีปัญหาค้างตาม milestone พร้อมผล antenna และ physical verification ที่ flow กำหนด ต้องตรวจ constraints/clocks/parasitic coverage อธิบายรายการที่ไม่ครอบคลุม และส่ง setup/hold ที่ผ่านทุก scenario ที่กำหนดพร้อม margin ของโครงการ

ต้องอ่านได้ว่าค่า slack มาจาก edge, data path, clock paths และ timing check ใด รวมทั้งพิสูจน์ว่า ECO ไม่ทำให้ check อื่นล้มเหลว หากยังมี blocker ให้รายงานตรงตามหลักฐานและระบุขั้นตอนแก้ ไม่สรุป “timing clean” จากรายงานเพียงหนึ่ง corner

## เอกสารอ้างอิงและขอบเขตการใช้คำสั่ง

แหล่งต่อไปนี้เป็นเอกสารทางการสำหรับอ้างอิง workflow/คำสั่งตัวอย่าง ตรวจสอบเมื่อ 16 ตุลาคม 2026 เนื้อหาหลักด้านสมการและโจทย์คำนวณในบทนี้เป็นคำอธิบายเพื่อการสอน ส่วน syntax ต้องตรวจให้ตรงเวอร์ชันที่ติดตั้ง

1. OpenROAD — Global Routing: https://openroad.readthedocs.io/en/latest/main/src/grt/README.html
2. OpenROAD — Detailed Routing: https://openroad.readthedocs.io/en/latest/main/src/drt/README.html
3. OpenROAD — Parasitics Extraction: https://openroad.readthedocs.io/en/latest/main/src/rcx/README.html
4. OpenSTA — Commands: https://opensta.readthedocs.io/en/latest/Commands/
5. OpenROAD — Gate Resizer: https://openroad.readthedocs.io/en/latest/main/src/rsz/README.html

สำหรับ Tanner/Siemens ต้องใช้คู่มือที่มากับ product/version และ license ของห้องปฏิบัติการเป็นหลัก ชื่อเมนูหรือคำสั่งจาก OpenROAD/OpenSTA ในบทนี้ไม่ได้ยืนยันความเข้ากันได้กับ Tanner Tcl
