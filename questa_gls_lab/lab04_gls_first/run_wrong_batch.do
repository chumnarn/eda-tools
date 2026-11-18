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
#
#  This script is EXPECTED to fail.  It exists so that the error can
#  be seen with the own eyes before the right way is used.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists ../netlist/cnt4_net.v]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 04 : the WRONG way -- the cells are in another library"
puts "===================================================================="

gls_prepare_lib cells_lib
vlog -work cells_lib ../cells/sg13g2_stdcell.v

gls_prepare_lib work
vlog -work work ../netlist/cnt4_net.v
vlog -work work ../tb/tb_cnt4.v

#--- this fails : the cells cannot be found ------------------------------
vsim work.tb_cnt4

puts "---- the design loaded although the cells are missing ----"
quit -code 0
