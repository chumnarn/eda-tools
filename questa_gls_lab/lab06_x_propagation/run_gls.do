#=====================================================================
# run_gls.do  --  LAB 06 : the gate level run and the comparison
#---------------------------------------------------------------------
#  The SECOND of two simulator processes.
#
#  THE POINT OF THIS LAB
#  The testbench drives 'x' into the enable of the counter and only
#  records what it sees.  The RTL run and the gate level run give
#  DIFFERENT answers :
#
#      RTL :  "if (en)" with en = 'x'  ->  the condition is not true
#              -> the else branch is taken -> the register HOLDS (q = 3)
#
#      GLS :  'en' goes through real gates -> 'x' propagates
#              -> the D input of the flip-flop becomes 'x'
#              -> the register captures 'x'    (q = x)
#
#  The script checks that the difference really appears.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists ../netlist/cnt4_net.v]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab06_x_propagation"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 06 : step 2 -- the gate level run with an 'x' on the enable"
puts "===================================================================="

file mkdir results

gls_prepare_lib work
vlog -work work ../cells/sg13g2_stdcell.v
vlog -work work ../netlist/cnt4_net.v
vlog -work work ../tb/tb_cnt4_x.v

vsim -voptargs=+acc work.tb_cnt4_x +GATE +obsfile=results/obs_gls.txt +resultfile=results/result_gls.txt
if {[catch {run -all} err]} {
    puts "---- the simulation stopped : $err ----"
}

set obs_rtl [string trim [gls_read_file results/obs_rtl.txt]]
set obs_gls [string trim [gls_read_file results/obs_gls.txt]]
puts "   the RTL saw : $obs_rtl"
puts "   the GLS saw : $obs_gls"

puts "---- the difference ----"
set rtl_has_x [string match "*x*" [string tolower $obs_rtl]]
set gls_has_x [string match "*x*" [string tolower $obs_gls]]
puts "   the RTL run produced an 'x' : $rtl_has_x   (expected : 0)"
puts "   the GLS run produced an 'x' : $gls_has_x   (expected : 1)"

if {$rtl_has_x == 0 && $gls_has_x == 1} {
    puts "   OK : the gate level simulation sees what the RTL hides"
    gls_write_verdict result.txt "PASS"
    puts "RESULT: PASS"
    quit -code 0
}
puts "   !! the expected difference was NOT observed"
gls_write_verdict result.txt "FAIL"
puts "RESULT: FAIL"
quit -code 1
