#!/bin/bash
export PATH="/root/.nix-profile/bin:$PATH"
echo "--- ghdl ---"
ghdl --version 2>&1 | head -3
echo "--- yosys ---"
yosys -V 2>&1 | head -2
echo "--- ghdl plugin ---"
ls /nix/store/*yosys-ghdl*/share/yosys/plugins/ 2>/dev/null | head
echo "--- liberty ---"
ls -la "/mnt/e/lab/pdks/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_typ_1p20V_25C.lib" 2>&1 | head -2
echo "--- iverilog / verilator ---"
iverilog -V 2>&1 | head -1
