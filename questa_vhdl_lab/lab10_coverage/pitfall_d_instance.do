#=====================================================================
#  pitfall_d_instance.do  --  LAB 10 : PITFALL 4
#---------------------------------------------------------------------
#  The coverage database is stored per INSTANCE PATH.
#
#  This script runs the DUT from a SECOND testbench whose entity name is
#  different (tb_alu_fsm_alt), so the instance path of the DUT is
#
#      /tb_alu_fsm_alt/dut
#
#  and not
#
#      /tb_alu_fsm/dut
#
#  When the UCDB of that run is merged with the UCDB of the normal test,
#  the merged database holds TWO COPIES of every bin of the DUT : the
#  bin count is inflated and the percentage no longer describes the
#  design.
#
#  The fix : keep ONE testbench and select the test with a generic.
#=====================================================================

onerror {puts "!! ERROR : a step failed"; quit -code 90}

if {![file exists src/alu_fsm.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

if {![file exists results]} { file mkdir results }

puts "===================================================================="
puts " LAB 10 : PITFALL 4 -- merging two different instance paths"
puts "===================================================================="

# ---- run the SAME design from a testbench with another name ----------
vsim -coverage work.tb_alu_fsm_alt
run -all
coverage save results/pitfall_alt.ucdb -codeAll -testname alt

# ---- the WRONG merge : two different instance paths ------------------
if {[file exists results/pitfall_two_instances.ucdb]} {
    file delete -force results/pitfall_two_instances.ucdb
}
exec vcover merge results/pitfall_two_instances.ucdb \
     results/basic.ucdb results/pitfall_alt.ucdb
exec vcover report -summary -codeAll \
     -output results/pitfall_two_instances.txt results/pitfall_two_instances.ucdb

puts ""
puts "---- WRONG : merged from two different testbench names ----"
puts [exec vcover report -summary -codeAll results/pitfall_two_instances.ucdb]

puts ""
puts "---- RIGHT : merged from ONE testbench, three generics ----"
puts [exec vcover report -summary -codeAll results/merged.ucdb]

puts "== LAB 10 : pitfall 4 done =="
