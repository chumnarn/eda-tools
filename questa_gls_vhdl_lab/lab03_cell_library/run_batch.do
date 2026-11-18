#=====================================================================
# run_batch.do  --  LAB 03 : the cell library of the design
#---------------------------------------------------------------------
#  Called by :  run.cmd
#
#  Before a netlist can be simulated, the simulator has to know what a
#  cell like "sg13g2_dfrbpq_1" really is.  This lab compiles the
#  Verilog simulation models of the IHP SG13G2 standard cell library
#  and shows what is inside :
#
#     * how many cells the library has
#     * which of them are sequential (flip-flops and LATCHES)
#     * what the Liberty file says about the corners
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists ../cells/sg13g2_stdcell.v]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab03_cell_library"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 03 : the SG13G2 cell library"
puts "===================================================================="

file mkdir results

set cellfile "../cells/sg13g2_stdcell.v"
set libfile  "../cells/sg13g2_stdcell_typ_1p20V_25C.lib"

#--- 1. compile the simulation models -----------------------------------
puts "---- 1. compile the cell models into the library 'sg13g2' ----"
gls_prepare_lib sg13g2
vlog -work sg13g2 $cellfile

#--- 2. what is inside ? -------------------------------------------------
puts "---- 2. the cells of the library ----"
set txt [gls_read_file $cellfile]

# The model file documents every cell with a "// type: XXX" comment placed
# just above the module.  We sort the library by THAT comment and not by the
# cell name, because the name only hints at the function :
#   sg13g2_dfrbp_1      -> a flip-flop      (dfrbp)
#   sg13g2_decap_4      -> a decapacitor   (physical only, not a gate)
#   sg13g2_dlygate4sd1_1-> a delay cell    (not a logic gate)
#   sg13g2_dlhr_1       -> a latch
set mods {}
set types {}
set curtype ""
foreach line [split $txt "\n"] {
    if {[regexp {^\s*//\s*type:\s*(\S+)\s*$} $line -> t]} {
        set curtype $t
        continue
    }
    if {[regexp {^\s*module\s+([A-Za-z0-9_]+)\s*\(} $line -> name]} {
        lappend mods $name
        lappend types $curtype
        set curtype ""
    }
}
puts "   [llength $mods] modules"

set ff_types    {dffrr dfrbpq sdfrrs sdfrbp sdfrbpq}
set latch_types {DLHQ DLHR DLHRQ DLLR DLLRQ gclk sgclk}
set dly_types   {DLY1 DLY2 DLY4}
set util_types  {NP_ant DECAP fill keepstate tie1 tie0}

set ff {}
set latch {}
set dly {}
set util {}
set comb {}
for {set i 0} {$i < [llength $mods]} {incr i} {
    set m [lindex $mods $i]
    set t [lindex $types $i]
    if {[lsearch -exact $ff_types    $t] >= 0} { lappend ff    $m ; continue }
    if {[lsearch -exact $latch_types $t] >= 0} { lappend latch $m ; continue }
    if {[lsearch -exact $dly_types   $t] >= 0} { lappend dly   $m ; continue }
    if {[lsearch -exact $util_types  $t] >= 0} { lappend util  $m ; continue }
    lappend comb $m
}
set ff_count    [llength $ff]
set latch_count [llength $latch]
set dly_count   [llength $dly]
set util_count  [llength $util]
set comb_count  [llength $comb]

puts "   flip-flops (sequential)  : $ff_count"
foreach m $ff    { puts "      $m" }
puts "   latches + latch clocks   : $latch_count"
foreach m $latch { puts "      $m" }
puts "   delay cells              : $dly_count"
foreach m $dly   { puts "      $m" }
puts "   utility / physical only  : $util_count"
foreach m $util  { puts "      $m" }
puts "   combinational gates      : $comb_count"

set grouped [expr {$ff_count + $latch_count + $dly_count + $util_count + $comb_count}]
puts "   sum of the 5 groups      : $grouped  (total [llength $mods])"

#--- 3. the Liberty file -------------------------------------------------
puts "---- 3. the Liberty file ----"
if {[file exists $libfile]} {
    set ltxt [gls_read_file $libfile]
    set printed_lib 0
    foreach line [split $ltxt "\n"] {
        if {[regexp {^\s*(time_unit|capacitive_load_unit|voltage_unit|current_unit)\s*[:(]} $line]} {
            puts "   [string trim $line]"
        } elseif {$printed_lib == 0 &&
                  [regexp {^\s*library\s*\(\s*([A-Za-z0-9_]+)\s*\)\s*\{} $line]} {
            puts "   [string trim $line]"
            set printed_lib 1
        }
    }
    puts "   size of the Liberty file : [file size $libfile] bytes"
} else {
    puts "   !! the Liberty file is missing"
}

#--- 4. the verdict ------------------------------------------------------
set ok 1
if {[llength $mods] < 50}  { set ok 0 }
if {$ff_count < 1}          { set ok 0 }
if {$latch_count < 1}       { set ok 0 }
if {$comb_count < 1}        { set ok 0 }
if {$grouped != [llength $mods]} { set ok 0 }
if {![file exists $libfile]} { set ok 0 }

if {$ok} {
    gls_write_verdict result.txt "PASS"
    puts "RESULT: PASS"
    quit -code 0
}
gls_write_verdict result.txt "FAIL"
puts "RESULT: FAIL"
quit -code 1
