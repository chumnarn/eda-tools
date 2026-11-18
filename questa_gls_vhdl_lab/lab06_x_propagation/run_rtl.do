#=====================================================================
# run_rtl.do  --  LAB 06 : the RTL level run with an 'X' on the enable
#---------------------------------------------------------------------
#  The FIRST of two simulator processes.
#
#  THE POINT OF THIS LAB
#  The testbench drives 'X' into the enable of the counter and only
#  records what it sees.  The RTL run and the gate level run give
#  DIFFERENT answers :
#
#      RTL :  "if en = '1'" with en = 'X'  ->  the comparison is FALSE
#              -> the else branch is taken -> the register HOLDS (q = 3)
#
#      GLS :  'en' goes through real gates -> 'X' propagates
#              -> the D input of the flip-flop becomes 'X'
#              -> the register captures 'X'    (q = x)
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists ../rtl/cnt4.vhd]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab06_x_propagation"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 06 : step 1 -- the RTL level run with an 'X' on the enable"
puts "===================================================================="

file mkdir results

puts "---- compile the VHDL RTL and the testbench ----"
gls_prepare_lib work
gls_compile_rtl work cnt4
gls_compile_tb work tb_cnt4_x

vsim -t 10ps -voptargs=+acc work.tb_cnt4_x \
     -gTRACEFILE=results/obs_rtl.txt \
     -gRESULTFILE=results/result_rtl.txt \
     -gGATE=false
if {[catch {run -all} err]} {
    puts "---- the simulation stopped : $err ----"
}

puts "   the RTL observation : [string trim [gls_read_file results/obs_rtl.txt]]"
quit -code 0
