#=====================================================================
# tools/gls_common.do -- helpers that every GLS lab uses
#---------------------------------------------------------------------
#  This file is "source"d by the run_batch.do of each lab:
#
#      source ../tools/gls_common.do
#
#  It must be sourced with a RELATIVE path and the simulator must be
#  started from the folder of the lab.  Do NOT use [info script] to
#  find the path of a script : in ModelSim 2026.1 it returns the path
#  of vsim itself and crashes the simulator (see appendix C.1).
#=====================================================================

#--- the project root (one level above the lab folder) -----------------
proc gls_root {} {
    return [file normalize [file join [pwd] ..]]
}

#--- a fresh library ----------------------------------------------------
proc gls_prepare_lib {libname} {
    if {[file exists $libname]} { file delete -force $libname }
    vlib $libname
    vmap $libname $libname
}

#--- read a text file into a string -------------------------------------
proc gls_read_file {name} {
    if {![file exists $name]} { return "" }
    set fh [open $name r]
    set t [read $fh]
    close $fh
    return $t
}

#--- the verdict the testbench wrote ------------------------------------
proc gls_verdict_from {resultfile} {
    set v [string toupper [string trim [gls_read_file $resultfile]]]
    if {$v eq "PASS"} { return "PASS" }
    return "FAIL"
}

#--- write the verdict --------------------------------------------------
proc gls_write_verdict {resultfile verdict} {
    set fh [open $resultfile w]
    puts $fh $verdict
    close $fh
}

#--- compare two trace files line by line -------------------------------
#    returns the list of the lines that differ (empty = identical)
proc gls_diff_lines {file_a file_b} {
    set a [split [gls_read_file $file_a] "\n"]
    set b [split [gls_read_file $file_b] "\n"]
    set diff {}
    set n [expr {[llength $a] > [llength $b] ? [llength $a] : [llength $b]}]
    for {set i 0} {$i < $n} {incr i} {
        set la [lindex $a $i]
        set lb [lindex $b $i]
        if {$la ne $lb} { lappend diff [list $i $la $lb] }
    }
    return $diff
}

#--- the cell library ----------------------------------------------------
proc gls_compile_cells {libname} {
    set root [gls_root]
    vlog -work $libname [file join $root cells sg13g2_stdcell.v]
}

#--- print the cells that a netlist uses --------------------------------
proc gls_netlist_cells {netfile} {
    set txt [gls_read_file $netfile]
    set cells {}
    foreach line [split $txt "\n"] {
        if {[regexp {^\s*(sg13g2_[A-Za-z0-9_]+)\s+\S+\s*\(} $line -> name]} {
            lappend cells $name
        }
    }
    return $cells
}
