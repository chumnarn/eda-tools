#=====================================================================
# run_batch.do  --  LAB 08 : advanced stimulus (batch, no windows)
#---------------------------------------------------------------------
#  Called by :  run.cmd
#
#  Two ways of parameterising the testbench are shown:
#
#    1) VHDL generics, overridden on the vsim command line :
#           vsim -gNUM_RANDOM=8 -gSEED1=12345 -gSEED2=67890 work.tb_stimulus
#
#    2) a "+plusarg" on the vsim command line :
#           vsim +NUM_RANDOM=4 +SEED1=777 +SEED2=888 -do "do run_batch.do"
#       VHDL itself CANNOT read a plusarg (std.env has no getenv in
#       VHDL-2008), so this script reads the plusarg in Tcl and turns
#       it into the same generic override.
#
#  WHY result.txt ?
#    The testbench itself writes result.txt (PASS / FAIL) at the end of
#    the simulation.  This script does NOT read the transcript file to
#    decide the verdict : as soon as the design is loaded a second time
#    (the plusarg run below) the simulator keeps the transcript open and
#    the file cannot be read any more.  result.txt is written by the
#    running testbench and is always readable.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists src/ram8.vhd]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab08_stimulus"
    quit -code 2
}

puts "===================================================================="
puts " LAB 08 : advanced stimulus (batch)"
puts "===================================================================="

#--- 0. remove a result file of an earlier run -------------------------
if {[file exists result.txt]} { file delete -force result.txt }

#--- 1. build the library ------------------------------------------------
if {[file exists work]} { file delete -force work }
vlib work
vmap work work

vcom -2008 src/ram8.vhd
vcom -2008 tb/tb_stimulus.vhd

#--- 2. mechanism 1 : VHDL generics -------------------------------------
vsim -gVECTOR_FILE=vectors.txt -gNUM_RANDOM=8 -gSEED1=12345 -gSEED2=67890 work.tb_stimulus
if {[catch {run -all} err]} {
    puts "!! the simulation stopped with an error : $err"
}

#--- 3. read the verdict of the first run -------------------------------
proc read_verdict {} {
    if {![file exists result.txt]} { return "NOFILE" }
    set fh [open result.txt r]
    set t [string trim [read $fh]]
    close $fh
    return $t
}

set v1 [read_verdict]
puts "--- run 1 (generics) : result.txt = $v1"
if {$v1 ne "PASS"} {
    set rf [open result.txt w]
    puts $rf "FAIL"
    close $rf
    puts "RESULT: FAIL"
    quit -code 1
}

#--- 4. mechanism 2 : "+plusarg" turned into a generic -------------------
set gargs {}
foreach a [split $::argv " "] {
    if {[regexp {^\+([A-Za-z_][A-Za-z0-9_]*)=(.*)$} $a -> nm val]} {
        lappend gargs -g$nm=$val
        puts "plusarg found : +$nm=$val   ->   passed to VHDL as -g$nm=$val"
    }
}
if {[llength $gargs] > 0} {
    puts "--- second run, parameterised by the plusargs ---"
    if {[file exists result.txt]} { file delete -force result.txt }
    vsim {*}$gargs work.tb_stimulus
    if {[catch {run -all} err]} {
        puts "!! the simulation stopped with an error : $err"
    }
    set v2 [read_verdict]
    puts "--- run 2 (plusargs) : result.txt = $v2"
    if {$v2 ne "PASS"} {
        set rf [open result.txt w]
        puts $rf "FAIL"
        close $rf
        puts "RESULT: FAIL"
        quit -code 1
    }
}

#--- 5. judge the result -------------------------------------------------
set rf [open result.txt w]
puts $rf "PASS"
close $rf
puts "RESULT: PASS"
quit -code 0
