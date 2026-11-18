#=====================================================================
#  merge.do  --  LAB 10 : merge the coverage of the three tests
#---------------------------------------------------------------------
#   vcover merge results/merged.ucdb results/basic.ucdb results/extra.ucdb results/edge.ucdb
#
# The merge is done with the standalone vcover utility because the
# simulator sessions are already closed at this point.  Inside the GUI the
# same thing is done with
#     View > Verification Management > Browser
#     -> add the three UCDB files -> right click > Merge
#
# IMPORTANT : the three UCDB files come from the SAME testbench
# (tb_alu_fsm) and only the generic -gTEST=... is different, so the
# instance path /tb_alu_fsm/dut is identical in all three databases.
# The merge therefore adds the HITS of one bin, it does not add a second
# copy of the bin.  See pitfall_d_instance.do for the wrong way.
#
# NOTE : vcover always returns the exit code 0, even when it reports an
#        error.  Never rely on its exit code, read the output instead.
#=====================================================================

onerror {puts "!! ERROR : a step failed"; quit -code 90}

if {![file exists src/alu_fsm.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

if {![file exists results]} { file mkdir results }

puts "===================================================================="
puts " LAB 10 : merge"
puts "===================================================================="

if {[file exists results/merged.ucdb]} { file delete -force results/merged.ucdb }

exec vcover merge results/merged.ucdb \
     results/basic.ucdb results/extra.ucdb results/edge.ucdb

puts ""
puts "---- coverage after merging the three tests ----"
puts [exec vcover report -summary -codeAll results/merged.ucdb]

puts "== LAB 10 : merge done =="
