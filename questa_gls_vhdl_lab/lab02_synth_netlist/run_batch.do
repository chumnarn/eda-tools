#=====================================================================
# run_batch.do  --  LAB 02 : from VHDL RTL to a gate netlist
#---------------------------------------------------------------------
#  Called by :  run.cmd
#
#  The netlist was produced by
#
#      VHDL  --(ghdl synth)-->  Verilog  --(yosys + Liberty)-->  gate netlist
#
#  and the intermediate Verilog is kept in netlist/vhdl2verilog/.
#  This lab looks at what Yosys produced and checks that every cell
#  really exists in the SG13G2 library.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists ../netlist/cnt4_net.v]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab02_synth_netlist"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 02 : the gate netlist of cnt4"
puts "===================================================================="

file mkdir results

set netfile "../netlist/cnt4_net.v"
set statfile "../netlist/cnt4_stat.txt"
set v2vfile "../netlist/vhdl2verilog/cnt4_rtl.v"
set cellfile "../cells/sg13g2_stdcell.v"

#--- 1. the statistics file ----------------------------------------------
puts "---- 1. the statistics file ----"
if {[file exists $statfile]} {
    set stxt [gls_read_file $statfile]
    foreach line [split $stxt "\n"] {
        if {[regexp {^\s+(Number of cells|Number of ports|Number of wires)} $line]} {
            puts "[string trim $line]"
        }
    }
    foreach line [split $stxt "\n"] {
        if {[regexp {^\s+(sg13g2_[A-Za-z0-9_]+)\s+([0-9]+)\s*$} $line -> cname ccount]} {
            puts "[format "   %-24s %s" $cname $ccount]"
        }
    }
} else {
    puts "   !! the statistics file is missing"
}

#--- 2. the cells that the netlist uses ----------------------------------
puts "---- 2. the cells used by the netlist ----"
set used [gls_netlist_cells $netfile]
set uniq {}
foreach c $used {
    if {[lsearch -exact $uniq $c] < 0} { lappend uniq $c }
}
foreach c $uniq { puts "   $c" }
puts "---- [llength $used] instances, [llength $uniq] different cell types ----"

#--- 3. check every cell against the library -----------------------------
#  CAREFUL : the pattern must be built with BRACES.
#  In a Tcl double quoted string the backslash of "\s" is dropped
#  ("\s" becomes "s") and the pattern no longer matches.
puts "---- 3. check every cell against the library ----"
set libtxt [gls_read_file $cellfile]
set missing {}
foreach c $uniq {
    set found [regexp [format {module\s+%s\s*\(} $c] $libtxt]
    if {!$found} { lappend missing $c }
}
if {[llength $missing] == 0} {
    puts "   OK : every cell of the netlist exists in ../cells/sg13g2_stdcell.v"
} else {
    puts "   !! these cells are NOT in the library :"
    foreach c $missing { puts "      $c" }
}

#--- 4. the intermediate Verilog that Yosys read -------------------------
puts "---- 4. the Verilog that Yosys actually read ----"
if {[file exists $v2vfile]} {
    set v2v [gls_read_file $v2vfile]
    foreach line [split $v2v "\n"] {
        if {[regexp {^\s*(module|input|output|reg|wire|always|endmodule)} $line]} {
            puts "[string trim $line]"
        }
    }
} else {
    puts "   !! the VHDL to Verilog file is missing"
}

#--- 5. the number of flip-flops -----------------------------------------
puts "---- 5. the design needs 4 flip-flops (a 4 bit counter needs 4) ----"
set ff 0
foreach c $used {
    if {[string match "sg13g2_dfrbp*" $c]} { incr ff }
}
puts "   the netlist has $ff flip-flop(s)"

#--- 6. the verdict ------------------------------------------------------
set ok 1
if {[llength $used] < 1}        { set ok 0 }
if {[llength $missing] > 0}     { set ok 0 }
if {$ff != 4}                   { set ok 0 }
if {![file exists $v2vfile]}    { set ok 0 }

if {$ok} {
    gls_write_verdict result.txt "PASS"
    puts "RESULT: PASS"
    quit -code 0
}
gls_write_verdict result.txt "FAIL"
puts "RESULT: FAIL"
quit -code 1
