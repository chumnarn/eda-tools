#=====================================================================
# lab3_merge.do  --  Lab 3 : merge the coverage of the two tests
#---------------------------------------------------------------------
#   vcover merge results/merged.ucdb results/basic.ucdb results/extra.ucdb
#
# The merge is done with the standalone vcover utility because the
# simulator session is already closed at this point.  Inside the GUI the
# same thing is done with
#     View > Verification Management > Browser
#     -> add both UCDB files -> right click > Merge
#=====================================================================

if {[file exists ./modelsim.ini] == 0} {
    cd [file normalize [file join [file dirname [info script]] ..]]
}

puts "== Lab 3 : merge =="

if {[file exists results/merged.ucdb]} { file delete -force results/merged.ucdb }

exec vcover merge results/merged.ucdb results/basic.ucdb results/extra.ucdb

puts ""
puts "---- coverage after merging the two tests ----"
exec vcover report -summary -codeAll -instance=/tb_cmd_fsm/dut results/merged.ucdb

puts "== Lab 3 : done =="
