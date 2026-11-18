#=====================================================================
# run_batch.do  --  LAB 02 : from RTL to a gate netlist
#---------------------------------------------------------------------
#  Called by :  run.cmd
#
#  This lab does NOT simulate anything.  It looks at what Yosys
#  produced and checks that the netlist is consistent with the cell
#  library :
#
#     1. the netlist file exists
#     2. every cell it instantiates really exists in the cell library
#     3. the statistics file agrees with the netlist
#
#  The synthesis itself is done by tools/synth/synth.sh inside WSL and
#  is NOT repeated here : the netlists in ../netlist are shipped with
#  the guide, so a student without Linux can still do every GLS lab.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists ../netlist/cnt4_net.v]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab02_synth_netlist"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 02 : the netlist that Yosys produced"
puts "===================================================================="

file mkdir results

set netfile  "../netlist/cnt4_net.v"
set statfile "../netlist/cnt4_stat.txt"
set cellfile "../cells/sg13g2_stdcell.v"

#--- 1. the statistics of the synthesis ---------------------------------
puts "---- 1. the statistics file ----"
puts [gls_read_file $statfile]

#--- 2. the cells the netlist instantiates ------------------------------
puts "---- 2. the cells used by the netlist ----"
set cells [gls_netlist_cells $netfile]
set counts {}
foreach c $cells {
    if {[lsearch -exact $counts $c] < 0} {
        lappend counts $c
        puts "   $c"
    }
}
puts "---- $cells instances, [llength $counts] different cell types ----"

#--- 3. do all of them exist in the cell library ? ----------------------
puts "---- 3. check every cell against the library ----"
set libtxt [gls_read_file $cellfile]
set missing {}
foreach c $counts {
    # CAREFUL : a "[" inside a double quoted string starts a command
    # substitution in Tcl, so the pattern is built without regexp here.
    if {[string first "module $c (" $libtxt] < 0} {
        lappend missing $c
    }
}
if {[llength $missing] > 0} {
    puts "   !! these cells are NOT in the library : [join $missing {, }]"
} else {
    puts "   OK : every cell of the netlist exists in $cellfile"
}

#--- 4. how many flip-flops does the design have ? ----------------------
set ff 0
foreach c $cells { if {[string match "sg13g2_dfrbpq*" $c]} { incr ff } }
puts "---- 4. the design needs $ff flip-flops (a 4 bit counter needs 4) ----"

#--- 5. the verdict ------------------------------------------------------
set ok 1
if {[llength $missing] > 0} { set ok 0 }
if {$ff != 4} { set ok 0 }
if {![file exists $statfile]} { set ok 0 }

if {$ok} {
    gls_write_verdict result.txt "PASS"
    puts "RESULT: PASS"
    quit -code 0
}
gls_write_verdict result.txt "FAIL"
puts "RESULT: FAIL"
quit -code 1
