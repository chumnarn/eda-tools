#!/bin/bash
#=====================================================================
# tools/check_vhdl.sh
#   ตรวจสอบโค้ด VHDL ทั้งหมดด้วย GHDL (ตัวจำลองโอเพนซอร์ส)
#   ใช้ใน WSL :  bash tools/check_vhdl.sh
#---------------------------------------------------------------------
#  ขั้นตอน
#    1. คอมไพล์ rtl/*.vhd และ tb/*.vhd ด้วย GHDL --std=08
#       ลงในไดเรกทอรีชั่วคราว (ไฟล์ work-obj08.cf ของโปรเจกต์ไม่ถูกแตะ)
#    2. elaborate และ "รัน" testbench ทั้ง 4 ตัวจริง
#       -> พิสูจน์พฤติกรรมและรูปแบบไฟล์ trace
#    3. รัน "ghdl synth" บน RTL ทั้ง 3 ดีไซน์
#       -> พิสูจน์ว่าสังเคราะห์เป็น Verilog ที่ Yosys อ่านต่อได้
#       (เหมือนขั้นตอนแรกของ tools/synth/synth.sh)
#
#  ผลลัพธ์ : exit 0 = ผ่านทุกไฟล์, exit 1 = มีข้อผิดพลาด
#=====================================================================

set -u

# ROOT = โฟลเดอร์โปรเจกต์ (สองระดับขึ้นไปจาก tools/)
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

WORK="${TMPDIR:-/tmp}/ghdl_check_work"
RUN="${TMPDIR:-/tmp}/ghdl_run"
rm -rf "$WORK" "$RUN"
mkdir -p "$WORK" "$RUN"

if ! command -v ghdl >/dev/null 2>&1; then
    echo "!! ghdl was not found in the PATH"
    exit 1
fi
echo "---- ghdl version ----"
ghdl --version | head -n 2
echo

ERRS=0

#---------------------------------------------------------------------
#  1. compile every VHDL file
#---------------------------------------------------------------------
for f in rtl/*.vhd tb/*.vhd; do
    echo "== $f"
    if ! ghdl -a --std=08 --workdir="$WORK" "$f"; then
        ERRS=$((ERRS+1))
    fi
done

echo "---- ghdl --dir --std=08 ----"
ghdl --dir --std=08 --workdir="$WORK"
echo "---- compile errors : $ERRS ----"
[ "$ERRS" -eq 0 ] || exit 1

#---------------------------------------------------------------------
#  2. elaborate and run the testbenches
#---------------------------------------------------------------------
cd "$RUN"
for TB in tb_cnt4 tb_cnt4_x tb_alu4 tb_fsm_light tb_sr16; do
    echo "====================================================================="
    echo " RUN : $TB"
    echo "====================================================================="
    ghdl -e --std=08 --workdir="$WORK" "$TB" || exit 1
    ghdl -r --std=08 --workdir="$WORK" "$TB" \
          -gTRACEFILE="$RUN/$TB.trace" -gRESULTFILE="$RUN/$TB.result" || exit 1
    echo "---- $TB.trace ----"
    cat "$RUN/$TB.trace"
    echo "---- $TB.result ----"
    cat "$RUN/$TB.result"
done

#---------------------------------------------------------------------
#  3. ghdl synth -> Verilog
#---------------------------------------------------------------------
cd "$ROOT"
for TOP in cnt4 alu4 fsm_light sr16; do
    echo "---- ghdl synth : $TOP ----"
    if ghdl synth --std=08 --workdir="$WORK" --out=verilog "$TOP" > "$RUN/${TOP}_rtl.v"; then
        echo "SYNTH_OK $TOP  ($(wc -l < "$RUN/${TOP}_rtl.v") lines of Verilog)"
    else
        echo "SYNTH_FAILED $TOP"
        ERRS=$((ERRS+1))
    fi
done

echo "---- total errors : $ERRS ----"
exit $ERRS
