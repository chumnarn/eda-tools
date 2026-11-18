#=====================================================================
# run_wrong_batch.do  --  LAB 04 : the WRONG way, on purpose
#---------------------------------------------------------------------
#  Called by :  run_wrong.cmd
#
#  The cell models go into their own library and the netlist into
#  "work".  The simulator then refuses the design :
#
#      ** Error: (vsim-3033) Instantiation of 'sg13g2_xor2_1' failed.
#                 The design unit was not found.
#     Error loading design
#
#  THIS SCRIPT IS EXPECTED TO DIE AT STEP 3.
#  A failed design load is a FATAL error in ModelSim : the whole
#  session ends, so no Tcl command after the "vsim" call is reached.
#  That is why the verdict is NOT written here -- run_wrong.cmd reads
#  the transcript file after the simulator has exited and looks for
#  the text "vsim-3033" in it.
#=====================================================================

onerror {puts "!! the script stopped here (this is what a failed design load does)"}

if {![file exists ../netlist/cnt4_net.v]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab04_gls_first"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 04 : the WRONG way -- the cells are in another library"
puts "===================================================================="

file mkdir results

puts "---- 1. compile the cells into the library 'cells_lib' ----"
gls_prepare_lib cells_lib
vlog -work cells_lib ../cells/sg13g2_stdcell.v

puts "---- 2. compile the netlist and the testbench into 'work' ----"
gls_prepare_lib work
vlog -work work ../netlist/cnt4_net.v
vcom -2008 -work work ../tb/tb_cnt4.vhd

puts "---- 3. try to load the design ----"
puts "   the cells are NOT in 'work' -> the simulator cannot find them"
puts "   THIS STEP IS EXPECTED TO FAIL AND TO END THE SESSION."
vsim -t 10ps -voptargs=+acc work.tb_cnt4 \
     -gTRACEFILE=results/trace_wrong.txt \
     -gRESULTFILE=results/result_wrong.txt \
     -gGATE=true

puts "   !! the design loaded -- the expected mistake did NOT happen"
quit -code 1
