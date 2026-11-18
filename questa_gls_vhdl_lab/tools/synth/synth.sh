#!/bin/bash
#=====================================================================
# tools/synth/synth.sh -- VHDL RTL -> SG13G2 gate netlist with Yosys
#---------------------------------------------------------------------
# Runs inside WSL (Ubuntu).  It is the ONLY part of the guide that
# needs Linux -- every gate level simulation lab runs in QuestaSim on
# Windows with the pre-generated netlists in netlist/.
#
# Usage (from the questa_gls_vhdl_lab folder, inside WSL) :
#     bash tools/synth/synth.sh              # all designs
#     bash tools/synth/synth.sh cnt4 alu4    # only these
#
# THE CHAIN
#     VHDL RTL  --(ghdl synth)-->  Verilog  --(yosys + Liberty)-->  gate netlist
#
# GHDL turns the VHDL into Verilog first.  That Verilog is what Yosys
# reads, so Yosys never has to understand VHDL at all.  The intermediate
# file is kept in netlist/vhdl2verilog/ so the student can look at it.
#=====================================================================
set -e

export PATH="/root/.nix-profile/bin:$PATH"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
cd "$ROOT"

PDK_LIB="/mnt/e/lab/pdks/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_typ_1p20V_25C.lib"
OUTDIR="$ROOT/netlist"
V2V="$ROOT/netlist/vhdl2verilog"
mkdir -p "$OUTDIR" "$V2V"

if [ ! -f "$PDK_LIB" ]; then
  echo "!! Liberty file not found : $PDK_LIB"
  exit 2
fi

DESIGNS="${*:-cnt4 alu4 fsm_light sr16}"

for TOP in $DESIGNS; do
  echo "====================================================================="
  echo " synth : $TOP"
  echo "====================================================================="

  #--- step 1 : VHDL -> Verilog (GHDL) ----------------------------------
  rm -f work-obj08.cf
  ghdl --remove --std=08 2>/dev/null || true
  ghdl -a --std=08 "rtl/${TOP}.vhd"
  ghdl synth --std=08 --out=verilog "${TOP}" > "${V2V}/${TOP}_rtl.v"
  echo "--- the Verilog that Yosys will read (netlist/vhdl2verilog/${TOP}_rtl.v) ---"
  head -20 "${V2V}/${TOP}_rtl.v"

  #--- step 2 : Verilog -> gate netlist (Yosys + Liberty) ---------------
  LOG="$OUTDIR/${TOP}_synth.log"
  yosys -l "$LOG" -p "
    read_verilog ${V2V}/${TOP}_rtl.v
    hierarchy -check -top ${TOP}
    proc
    opt
    fsm
    opt
    memory
    opt
    techmap
    opt
    dfflibmap -liberty $PDK_LIB
    abc -liberty $PDK_LIB
    setundef -zero
    splitnets
    opt_clean
    write_verilog -noattr ${OUTDIR}/${TOP}_net.v
    tee -o ${OUTDIR}/${TOP}_stat.txt stat
  " 2>&1 | tail -20

  echo "--- cells used ---"
  grep -E '^\s+sg13g2' "${OUTDIR}/${TOP}_stat.txt" || true
  echo
done

echo "netlists written to $OUTDIR"
