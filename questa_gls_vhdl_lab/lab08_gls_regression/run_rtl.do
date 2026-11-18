#=====================================================================
# run_rtl.do  --  LAB 08 : the RTL level run of one design
#---------------------------------------------------------------------
#  The design is taken from the command line :
#
#      vsim -c -onfinish stop +TOP=alu4 -do "do run_rtl.do"
#
#  The testbench is called tb_<TOP> and it is NOT changed between the
#  two levels -- only the file that is compiled into "work" changes.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

set top "cnt4"
foreach a [split $::argv " "] {
    if {[regexp {^\+TOP=(.*)$} $a -> v]} { set top $v }
}
set tb "tb_$top"

if {![file exists "../rtl/${top}.vhd"]} {
    puts "!! wrong folder or no RTL for $top : [pwd]"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 08 : the RTL level run of $top"
puts "===================================================================="

file mkdir results

puts "---- compile the VHDL RTL and the testbench ----"
gls_prepare_lib work
gls_compile_rtl work $top
gls_compile_tb work $tb

vsim -t 10ps -voptargs=+acc "work.$tb" \
     "-gTRACEFILE=results/${top}_rtl.txt" \
     "-gRESULTFILE=results/${top}_res_rtl.txt" \
     -gGATE=false
if {[catch {run -all} err]} {
    puts "---- the simulation stopped : $err ----"
}

puts "   the RTL verdict : [gls_verdict_from results/${top}_res_rtl.txt]"
quit -code 0
