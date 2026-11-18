#!/bin/bash
#=====================================================================
# tools/synth/synth.sh -- RTL -> SG13G2 gate netlist with Yosys
#---------------------------------------------------------------------
# Runs inside WSL (Ubuntu).  It is the ONLY part of the guide that
# needs Linux -- every gate level simulation lab runs in QuestaSim on
# Windows with the pre-generated netlists in netlist/.
#
# Usage (from the questa_gls_lab folder, inside WSL) :
#     bash tools/synth/synth.sh              # all designs
#     bash tools/synth/synth.sh cnt4 alu4    # only these
#
# The IHP SG13G2 Liberty file is read from the PDK on the E: drive.
#=====================================================================
set -e

export PATH="/root/.nix-profile/bin:$PATH"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
cd "$ROOT"

PDK_LIB="/mnt/e/lab/pdks/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_typ_1p20V_25C.lib"
OUTDIR="$ROOT/netlist"
mkdir -p "$OUTDIR"

if [ ! -f "$PDK_LIB" ]; then
  echo "!! Liberty file not found : $PDK_LIB"
  exit 2
fi

DESIGNS="${*:-cnt4 alu4 fsm_light sr16}"

for TOP in $DESIGNS; do
  echo "====================================================================="
  echo " synth : $TOP"
  echo "====================================================================="
  LOG="$OUTDIR/${TOP}_synth.log"

  yosys -l "$LOG" -p "
    read_verilog rtl/${TOP}.v
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
  " 2>&1 | tail -25

  echo "--- cells used ---"
  grep -E '^\s+sg13g2' "${OUTDIR}/${TOP}_stat.txt" || true
  echo
done

echo "netlists written to $OUTDIR"
