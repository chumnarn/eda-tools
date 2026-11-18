#=====================================================================
#  run_batch.do  --  LAB 10 : the verdict of the whole coverage flow
#---------------------------------------------------------------------
#  This is the last step of run.cmd.  It does not run a simulation, it
#  checks that every artifact of the flow is really there and that the
#  three tests really passed.
#
#  PASS is decided by the SAME rule as in the other labs : the testbench
#  has to print TEST_PASSED.  Because the three tests run in three
#  different simulator sessions, the transcripts of the three sessions
#  are checked (results/test_*_transcript.txt).
#=====================================================================

onerror {puts "!! ERROR : a step failed"; quit -code 90}

if {![file exists src/alu_fsm.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

puts "===================================================================="
puts " LAB 10 : verdict"
puts " cwd    : [pwd]"
puts "===================================================================="

proc read_file {name} {
    if {![file exists $name]} { return "" }
    set f [open $name r]
    set t [read $f]
    close $f
    return $t
}

# ---- every artifact has to exist -------------------------------------
set missing {}
foreach f {results/basic.ucdb results/extra.ucdb results/edge.ucdb \
            results/merged.ucdb results/basic_report.txt \
            results/extra_report.txt results/edge_report.txt \
            results/merged_report.txt results/merged_detail.txt \
            results/test_basic_transcript.txt \
            results/test_extra_transcript.txt \
            results/test_edge_transcript.txt \
            results/pitfall_report.txt} {
    if {![file exists $f]} { lappend missing $f }
}

# ---- every test has to print TEST_PASSED -----------------------------
set failed {}
foreach t {basic extra edge} {
    if {![regexp {TEST_PASSED} [read_file "results/test_${t}_transcript.txt"]]} {
        lappend failed $t
    }
}

# ---- the merged report has to contain the numbers --------------------
set have_numbers [regexp {Total coverage} [read_file results/merged_report.txt]]

# ---- print the measured numbers --------------------------------------
proc total_of {name} {
    if {![file exists $name]} { return "n/a" }
    set f [open $name r]
    set t [read $f]
    close $f
    foreach l [split $t "\n"] {
        if {[string match "*Total coverage*" $l]} { return [string trim $l] }
    }
    return "n/a"
}

puts ""
puts "---- the measured coverage ----"
puts [format "  test 'basic' : %s" [total_of results/basic_report.txt]]
puts [format "  test 'extra' : %s" [total_of results/extra_report.txt]]
puts [format "  test 'edge'  : %s" [total_of results/edge_report.txt]]
puts [format "  MERGED       : %s" [total_of results/merged_report.txt]]
puts ""

# ---- verdict ----------------------------------------------------------
set rf [open result.txt w]
if {[llength $missing] == 0 && [llength $failed] == 0 && $have_numbers} {
    puts $rf "PASS"
    close $rf
    puts "RESULT: PASS"
    quit -code 0
} else {
    puts $rf "FAIL"
    close $rf
    if {[llength $missing] > 0} {
        puts "!! missing artifacts : [join $missing {, }]"
    }
    if {[llength $failed] > 0} {
        puts "!! these tests did not print TEST_PASSED : [join $failed {, }]"
    }
    if {!$have_numbers} {
        puts "!! the merged report does not contain any coverage number"
    }
    puts "RESULT: FAIL"
    quit -code 1
}
