# Lint, CDC/RDC และ Formal Verification

บทประกอบหัวข้อ 4 ของคู่มือ Siemens EDA Tool Flow for Front-End Digital IC Design

## 4.1 เลือกวิธีตรวจให้ตรงกับข้อผิดพลาด

| วิธี | คำถามที่ตอบ | หลักฐาน |
|---|---|---|
| Lint | RTL ที่ elaborate แล้วมีโครงสร้างหรือการใช้ภาษาที่เสี่ยงผิดเจตนาหรือไม่ | Rule ID, hierarchy, source location และ rule profile |
| CDC | สัญญาณจาก clock หนึ่งถูกส่งไปยังอีก clock อย่างปลอดภัยและข้อมูลยังสัมพันธ์กันหรือไม่ | Clock inventory, crossing paths, synchronizer/protocol results |
| RDC | การ assert หรือ release reset ของ domain หนึ่งกระทบ receiver ที่ยังทำงานอยู่หรือไม่ | Reset tree, reset sequence, isolation หรือ protocol proof |
| Formal property checking | ทุกพฤติกรรมที่เกิดได้ภายใต้โมเดลและ assumptions ตรงตาม requirement หรือไม่ | Proof status, cover witnesses และ counterexamples |
| Formal equivalence | RTL และ netlist ที่กำหนดเป็น golden/revised ให้ผลเทียบเท่ากันภายใต้ configuration ที่กำหนดหรือไม่ | Compare points และ equivalence results |

Questa Lint, Questa CDC, Questa RDC และ Questa Verify Property เป็นเครื่องมือคนละส่วนของ flow ตรวจสิทธิ์และความสามารถด้าน VHDL, PSL, SVA หรือ mixed-language ตามรุ่นที่ติดตั้ง การที่ Lab 1 รันบน ModelSim ได้ยืนยันความพร้อมของ simulator สำหรับ Lab นั้น ส่วน static/formal apps ต้องตรวจแยกตาม installation บทนี้ระบุ workflow และตัวอย่าง properties สำหรับนำไปตั้งค่ากับ project template ของรุ่นที่ใช้

## 4.2 ขั้นที่ 1 — Freeze configuration แล้วตรวจโมเดล

1. บันทึก commit, top, file order, libraries, generics/defines, black boxes, tool versions และ rule profile ใช้ design sources ของ Lab 1 และตัด simulation-only testbench ออกจาก design manifest ของ static analysis
2. Elaborate แล้วเทียบ hierarchy, port widths และจำนวน instance กับที่คาด ตรวจ unresolved references และ macro model ก่อนแปลผลรายงาน
3. ทำ inventory ของ clocks, resets, top-level I/O domains และ operating modes ระบุ generated clocks จาก divider/PLL, clock mux, test clock และ reset polarity รวมถึง power state หากมี UPF
4. ตรวจการ bind ของ constraints กับ object จริง สัญญาณ I/O ที่ไม่ทราบ domain และ clocks ที่ tool ไม่รู้จักต้องมีเจ้าของตรวจสอบ รันแต่ละ mode เมื่อ clock/reset relation หรือ reachability ต่างกัน
5. ทำ positive และ negative controls สำหรับแต่ละวิธี การทดลอง defect ที่รู้ตำแหน่งช่วยตรวจว่า rule หรือ property ถูก enable และ bind เข้ากับ DUT จริง

## 4.3 ขั้นที่ 2 — Lint และ triage

เริ่มจากกฎที่กระทบ function และ synthesis ก่อน เช่น undriven/multiple-driven nets, unintended latch, combinational loop, out-of-range index, signedness และ width loss จากนั้นจึงตรวจ maintainability และ coding convention แยก severity ที่ tool ให้จากผลกระทบต่อการออกแบบ เพราะ warning เรื่อง truncation อาจทำให้ address alias ใน SoC

### ตัวอย่าง 1 — ขนาดผลบวก

ใน acc8 ของ Lab 1 การบวก unsigned 8 บิตแล้วเก็บผล 8 บิตตรงกับ ACC-04 ซึ่งกำหนด modulo 256 ถ้าต้องการระบุเจตนาของการเลือก low bits ให้ชัด หรือจำเป็นต้องใช้ carry ภายหลัง สามารถขยาย operands ก่อนบวกดังนี้

```vhdl
-- ตัวแปรภายใน clocked process
variable sum_ext : unsigned(8 downto 0);

-- ในสาขาที่ enable ทำงาน
sum_ext := resize(sum_q, 9) + resize(unsigned(data_i), 9);
sum_q   <= sum_ext(7 downto 0);
```

เมื่อ 250 + 10 จะได้ sum_ext = 0x104 และ sum_q = 0x04 การ resize ผลหลังบวกในความกว้างเดิมให้ค่า 0x004 เพราะ carry หลุดไปแล้ว หากแก้จากโค้ด Lab 1 ให้รัน regression และ formal ACC-03/04 ซ้ำ

### ตัวอย่าง 2 — Unintended latch

ใน process(all) ถ้า assign output เฉพาะเมื่อ sel = '1' output ต้องคงค่าเมื่อเงื่อนไขเป็นเท็จ จึงอาจ infer latch แก้ด้วย default assignment หรือกำหนดทุก branch ตาม spec การไม่มี else ใน clocked enable ของ acc8 เป็นกรณี register hold ที่ตั้งใจไว้ ให้พิจารณา process semantics ก่อนแก้ warning

### วิธีอ่านผล

เลือก violation ที่ต้นเหตุร่วมก่อน เช่น generic ผิดตัวเดียวอาจทำให้ width warnings หลายจุด เปิด source, elaborated cone และดูค่าพารามิเตอร์จริง แยกผลเป็น fix, intentional พร้อมเหตุผล, configuration issue หรือ pending review ทำ negative control ด้วย combinational branch ที่ขาด assignment และตรวจว่ารายงานชี้ไปยัง output ที่คงค่า กฎและชื่อ rule ID ขึ้นกับ profile ของเครื่องมือ

## 4.4 ขั้นที่ 3 — CDC จาก inventory ถึง protocol

### Metastability และ data coherence

เมื่อ data เปลี่ยนใกล้ sampling edge ของ clock ปลายทาง flop แรกอาจเข้าสู่ metastability การเพิ่ม resolution time ผ่าน synchronizer ช่วยลดโอกาสที่ metastability จะแพร่ไปถึง downstream logic แนวโน้ม MTBF มักอธิบายได้ด้วยความสัมพันธ์เชิงประมาณ exp(T_res/τ)/(K·f_dst·f_toggle) โดยค่าคงที่ขึ้นกับเทคโนโลยีและ characterization ใช้ข้อมูล cell, placement และ timing จริงในการประเมิน หลีกเลี่ยงการใช้ flop ขั้นแรกขับ logic อื่นหรือแยก fanout ออกก่อนถึงขั้นสุดท้าย

Data coherence เป็นอีกปัญหาหนึ่ง แม้แต่ละบิตใช้ 2 FF แต่ receiver อาจเห็นค่าจากคนละ transaction เช่น bus เปลี่ยน 0x7F → 0x80 แล้วรับ 0x00 หรือ 0xFF ชั่วคราวจากการสังเกตบิตคนละรอบ

| รูปแบบ | โครงสร้าง | เงื่อนไขที่ต้องตรวจ |
|---|---|---|
| Level 1 บิต | Synchronizer 2 FF ขึ้นไปตาม MTBF | Level ค้างพอให้รับได้, ไม่มี combinational glitch, stage แรกมี fanout ที่เหมาะสม |
| Pulse/event | Toggle หรือ request/acknowledge | Toggle ต้องเว้น event ให้ receiver เห็นการเปลี่ยนแต่ละครั้ง และเริ่มต้น state ตรงกัน |
| Multi-bit snapshot | Bundled data พร้อม handshake | Source ถือ payload จน ACK, มี timing budget ให้ bus settle ก่อน capture |
| Stream ต่อเนื่อง | Asynchronous FIFO | Gray pointer, pointer synchronization, full/empty, reset policy และ physical skew constraints |
| Control หลายเส้นมาเจอกัน | รวมความหมายก่อน crossing หรือใช้ protocol เดียว | ตรวจ reconvergence เมื่อ synchronizer แต่ละเส้นหน่วงได้ต่างกัน |

### กรณีศึกษา — ส่ง operand จาก cfg_clk ไป core_clk

ให้ cfg_clk ส่งข้อมูล 8 บิตเข้าสู่ acc8 ใน core_clk คาบ 20 ns หากส่ง cfg_valid เป็น pulse 8 ns พัลส์อาจตกอยู่ระหว่าง rising edges ทั้งหมด เช่น active ตั้งแต่ 2 ถึง 10 ns เมื่อ core edges อยู่ที่ 0 และ 20 ns จึงเลือก mailbox แบบ toggle request/acknowledge สำหรับกรณีรับได้ครั้งละหนึ่งรายการ

1. Source รับ transaction เมื่อ req เท่ากับ ack ที่ sync กลับมา แล้ว latch payload และ toggle req
2. Destination sync req แล้วตรวจความต่างจาก req ที่ประมวลผลครั้งล่าสุด
3. Destination capture payload เมื่อครบเงื่อนไข bundled-data timing และส่ง enable หนึ่งรอบให้ accumulator โดยกำหนดชัดว่า ACK หมายถึง capture หรือ commit
4. Destination toggle/อัปเดต ACK ให้ตรงกับ req ที่รับแล้ว Source รอ ACK ผ่าน synchronizer ก่อนเขียน payload ใหม่
5. กำหนด reset contract ให้ชัด ตัวอย่างนี้เริ่ม req และ ack ที่ 0 และ block traffic จนทั้งสอง domain พร้อม ถ้าอนุญาตให้ reset ข้างเดียวกลางรายการ ต้องกำหนดวิธี flush หรือ recovery เพื่อป้องกัน phantom/duplicate event

| Crossing | จาก → ไป | สิ่งที่ต้องตรวจ |
|---|---|---|
| req | cfg → core | Registered launch, synchronizer, detect ครั้งเดียวต่อ toggle |
| ack | core → cfg | Synchronizer และ ACK หลังเหตุการณ์ที่ contract กำหนด |
| payload[7:0] | cfg → core | คงค่าจน ACK และ settle ก่อน capture ภายใต้ physical timing budget |
| ready/reset status | ตาม topology | Synchronization, release ordering และไม่มี traffic ก่อนพร้อม |

### การอ่าน Questa CDC

ตรวจ clock/domain summary ก่อนดู violation count แล้วเปิด path ตั้งแต่ source register ผ่าน logic และ synchronizer ไปถึง receiver ตรวจ classification ของ unsynchronized paths, pulse loss, combinational logic ก่อน synchronizer และ reconvergence ตรวจด้วยว่า protocol properties ผูกกับ path ที่ต้องการ ข้อความว่า recognized synchronizer ยืนยันโครงสร้างที่ tool รู้จัก ส่วนความถี่ event และ stability ของ bundled data ต้องมีหลักฐาน protocol เพิ่ม STA exceptions เช่น asynchronous clock groups เปลี่ยนวิธีรายงาน timing จึงต้องจัดการ physical constraints ของ synchronizer หรือ bundled-data bus แยกตาม methodology ตรวจซ้ำหลัง synthesis/implementation เมื่อมี optimization ที่เปลี่ยนโครงสร้าง

## 4.5 ขั้นที่ 4 — RDC แม้ใช้ clock เดียวกัน

สมมติ src_q และ dst_q ใช้ core_clk เดียวกัน แต่ src_q มี asynchronous warm reset และ dst_q ใช้ power-on reset คนละเส้น ถ้า warm reset ทำให้ src_q เปลี่ยนค่าใกล้ rising edge ขณะที่ dst_q ยัง sample อยู่ จะเกิดเส้นทาง asynchronous จาก reset ผ่าน Q ไปยัง D ของ receiver การ synchronize deassertion ช่วยควบคุมการ release แต่ assertion ของ source ยังเปลี่ยน Q ได้ระหว่าง edges

| Reset scenario | สิ่งที่ receiver ต้องรับประกัน |
|---|---|
| Cold boot ทั้งระบบ | Traffic ถูก block จน reset release และ interface พร้อม |
| Warm reset เฉพาะ source | Drain/flush รายการค้างตาม spec และ isolate/หยุด sample ก่อน source reset |
| Destination reset เฉพาะส่วน | Source เห็น readiness หรือ epoch ใหม่ก่อนส่งหรือ retry |
| Clock หยุดระหว่าง reset | การ release ที่ต้องอาศัย edge รอจน clock กลับมา และระบบยัง block traffic |

เริ่มจาก trace reset tree และ local reset logic ตรวจ source/destination reset relation ในแต่ละ mode เปิด path ที่มี asynchronous source assertion แล้วถามว่า receiver ยัง sample ได้หรือไม่ ถ้าใช้ isolation ให้ระบุสัญญาณควบคุมที่มาจาก domain ที่ยังทำงานและพิสูจน์ว่า isolation active ก่อน reset รวมถึงค้างจน payload valid หลัง release การสั่ง isolate ผ่าน synchronizer หลัง assert reset แล้วอาจสายเกินไป หาก reset มาโดยคาดการณ์ไม่ได้ ให้เลือก architecture ที่รองรับลักษณะนั้น เช่น reset ร่วมที่ผ่านการทบทวนหรือ interface recovery ที่ออกแบบไว้เฉพาะ อย่าอนุมานลำดับ reset จากชื่อสัญญาณ

ตรวจ negative control โดยยอมให้ warm reset เกิดระหว่าง transaction ขณะที่ receiver ยังรับข้อมูล แล้วหาทั้งเส้นทาง RDC และ counterexample ของ protocol หาก flow นำเข้า CDC path/waiver data ให้ตรวจว่าใช้ snapshot เดียวกันและเหตุผลของ waiver ใช้ได้กับ reset mode ด้วย

## 4.6 ขั้นที่ 5 — Formal property checking ของ acc8

ให้ Q[n] เป็น output ที่ sample ก่อน rising edge n และ R[n], E[n], D[n] เป็น reset_n, enable, data ที่ edge เดียวกัน ดังนั้น Q[n+1] สะท้อน state update จาก edge n ต่างจาก TB ของ Lab 1 ซึ่งอ่านหลัง edge n ไป 1 ns

| Requirement | Transition ที่พิสูจน์ | Cover ที่ต้องการ |
|---|---|---|
| ACC-01 | R[n] = 0 ⇒ Q[n+1] = 0 | Reset ขณะ Q ≠ 0 และ E = 1 |
| ACC-02 | R[n] = 1, E[n] = 0 ⇒ Q[n+1] = Q[n] | Hold ขณะ Q ≠ 0 |
| ACC-03 | R[n] = 1, E[n] = 1 ⇒ Q[n+1] = low8(Q[n]+D[n]) | รับข้อมูลต่อเนื่อง |
| ACC-04 | เมื่อเปิดรับและผลรวม 9 บิตมี carry ให้ output เท่ากับ low 8 บิต | Q = 250, D = 10, ถัดไป Q = 4 |

ตัวอย่าง SVA สำหรับ checker ที่ต่อพอร์ตเดียวกับ DUT VHDL ผ่าน mixed-language harness ที่รองรับ หรือใช้เป็นต้นแบบในการเขียน PSL ตาม compiler ของห้อง Lab

```systemverilog
module acc8_properties (
  input logic       clk_i, rst_ni, en_i,
  input logic [7:0] data_i, sum_o
);
  function automatic logic [7:0] add_mod256(
    input logic [7:0] a, b
  );
    logic [8:0] wide_sum;
    wide_sum = {1'b0, a} + {1'b0, b};
    return wide_sum[7:0];
  endfunction

  a_reset: assert property (@(posedge clk_i)
    !rst_ni |=> sum_o == 8'd0);

  a_hold: assert property (@(posedge clk_i)
    rst_ni && !en_i |=> sum_o == $past(sum_o));

  a_add: assert property (@(posedge clk_i)
    rst_ni && en_i |=>
      sum_o == add_mod256($past(sum_o), $past(data_i)));

  c_reset_priority: cover property (@(posedge clk_i)
    (!rst_ni && en_i && sum_o != 8'd0) ##1 (sum_o == 8'd0));

  c_wrap: cover property (@(posedge clk_i)
    (rst_ni && en_i && sum_o == 8'd250 && data_i == 8'd10)
    ##1 (sum_o == 8'd4));
endmodule
```

a_add ครอบคลุมทั้งผลรวมปกติและ wrap เพราะ reference คำนวณ 9 บิตแล้วเลือก low bits c_wrap ใช้เป็น witness ของสถานการณ์ที่ต้องเกิดได้ตาม spec ใช้ |=> เพื่อประเมิน consequent ที่ sample ถัดไป และใช้ $past เพื่ออ้าง operands ของ edge ที่กระตุ้น property a_reset ต้อง active ขณะ reset เป็น 0 จึงไม่ครอบด้วย disable iff ที่ปิด property นี้ระหว่าง reset

### ขั้นตอนตั้งและรัน proof

1. Bind checker และตรวจจำนวน assertions/covers ที่ถูกโหลด ระบุ clock, reset และ initial-state semantics จาก report
2. หากต้องการ cover trace ที่เริ่มจาก boot จริง ให้ตั้ง initial reset sequence ตาม spec หรือเพิ่ม history guard ที่เริ่มหลัง reset ถูก sample ตรวจว่าค่า 250 ใน witness มาจากการบวกจริงหลัง boot หาก unconstrained initial state สามารถเริ่มที่ 250 ได้ทันที
3. กำหนด assumptions เฉพาะสัญญาของ environment เช่น data stable จน ACK สำหรับ mailbox ฝั่ง producer หลีกเลี่ยง assume ผลลัพธ์ของ DUT หรือสมมติให้ en_i เป็น 0 ตลอด หากต้องพิสูจน์ข้อกำหนดการบวก
4. รัน covers ควบคู่กับ assertions ตรวจ antecedent reachability และทดลองผ่อน assumption ทีละตัวเมื่อ cover ไม่พบ trace ตัวอย่าง assume enable เป็น 0 ทำให้ a_add ผ่านแบบ vacuous ได้
5. อ่าน counterexample ตาม edge ที่ antecedent เริ่ม ตรวจ reset history, operands, state และ edge ที่ consequent ผิด หากสลับ priority ของ acc8 ให้ enable มาก่อน reset ให้หา trace ที่ reset active และ data ≠ 0 แล้ว output ถัดไปไม่เป็นศูนย์
6. สำหรับ mailbox ตรวจ safety เช่น no duplicate capture, no ACK before capture และ payload stable while busy ส่วน eventual delivery ต้องระบุว่าทั้งสอง clocks เดินต่อและ receiver พร้อมภายใต้เงื่อนไขใด หากต้องพิสูจน์ bounded response ให้กำหนด bound และหน่วย cycle ให้ชัด การ prove ด้วยโมเดล digital ต้องระบุ CDC latency/nondeterminism ที่ใช้ และประเมิน metastability ทางกายภาพแยกต่างหาก

| สถานะ | วิธีรายงาน |
|---|---|
| Proven | ระบุ property, configuration และ assumptions ที่ใช้พิสูจน์ |
| Counterexample | เก็บ trace และจำแนก RTL bug, property bug หรือ environment gap |
| Bounded | ระบุ depth และ clock/model ที่ใช้ รายงานผลเฉพาะขอบเขตที่ตรวจ |
| Inconclusive/timeout | ระบุสิ่งที่ค้างและวางแผนลด cone หรือแบ่ง proof |
| Cover reached | เก็บ witness และตรวจว่า reset/traffic เกิดตามเจตนา |
| Cover ยังไม่ถึง | แยก search depth ไม่พอออกจากกรณีที่พิสูจน์ว่า unreachable |

## 4.7 Regression gates และเกณฑ์ส่งมอบ

- Lint ต้องไม่มี violation ระดับที่โครงการกำหนดซึ่งยังไม่มี disposition และ negative control ต้อง trigger กฎที่คาด
- CDC/RDC ต้องตรวจ inventory ครบทุก mode ที่อยู่ในขอบเขต มี disposition ให้ unresolved/unknown domains และ crossing ที่เสี่ยง พร้อมหลักฐาน timing หรือ protocol ตามประเภท
- Formal ต้องจัดทำ matrix ต่อ requirement พร้อม proof status, assumptions, covers และ counterexamples ที่เกี่ยวข้อง
- Waiver ควรมี rule ID, mode, source/destination path, เหตุผล, หลักฐาน, owner/reviewer และ trigger ให้ตรวจใหม่เมื่อ hierarchy, IP, clock/reset หรือ constraints เปลี่ยน
- เก็บ manifest, clock/reset inventory, scripts, rule profiles, proof configurations และรายงานจาก revision เดียวกัน แล้วใช้ผลใน handoff review ก่อน synthesis หรือ integration

### แบบฝึกท้ายบท

1. เปลี่ยน reset priority ของ acc8 แล้วอธิบายว่าทำไม simulation และ formal อาจจับ defect ได้ แม้ lint จะรายงานว่าโค้ดใช้ภาษาได้ถูกต้อง
2. เพิ่ม req และ ack สำหรับ mailbox แล้วเขียน acceptance condition, hold invariant และ event ที่นับเป็น ACK ให้ตรวจได้ทีละ clock
3. ระบุ hazard เมื่อ warm reset ทำให้ req กลับเป็น 0 ขณะที่ปลายทางจำค่าเดิมเป็น 1 แล้วเสนอ reset/recovery contract
4. เพิ่ม assumption ที่ปิด enable แล้วเทียบ proof status ของ a_add กับผล c_wrap ก่อนและหลัง assumption

ตัวอย่าง HDL และ SVA ใช้อธิบายแนวทางและ expected behavior ยังไม่ได้ compile หรือรัน proof ด้วย Siemens tools ในสภาพแวดล้อมนี้

## อ้างอิง

- [Siemens Questa Design Solutions](https://www.siemens.com/en-gb/products/ic/questa-one/design-solutions/)
- [Siemens Questa CDC](https://www.siemens.com/lt-lt/products/ic/questa-one/design-solutions/clock-domain-crossing/)
- [Siemens Questa RDC](https://www.siemens.com/en-us/products/ic/questa-one/design-solutions/reset-domain-crossing/)
- [Siemens Questa Verify Property](https://www.siemens.com/en-us/products/ic/questa-one/formal-verification/verify-property/)
- [Siemens Questa Signoff CDC](https://www.siemens.com/en-gb/products/ic/questa-one/design-solutions/signoff-gatelevel-cdc/)
