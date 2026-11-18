#=====================================================================
#  pitfall_summary.do  --  LAB 10 : collect every pitfall in one file
#---------------------------------------------------------------------
#  Writes  results/pitfall_report.txt
#=====================================================================

onerror {puts "!! ERROR : a step failed"; quit -code 90}

if {![file exists src/alu_fsm.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

if {![file exists results]} { file mkdir results }

proc read_file {name} {
    if {![file exists $name]} { return "" }
    set f [open $name r]
    set t [read $f]
    close $f
    return $t
}

set out [open results/pitfall_report.txt w]

puts $out "===================================================================="
puts $out " LAB 10 : the four code coverage pitfalls, measured"
puts $out "===================================================================="
puts $out ""

#---------------------------------------------------------------------
# PITFALL 1
#---------------------------------------------------------------------
puts $out "--------------------------------------------------------------------"
puts $out " PITFALL 1 : '+cover' without a spec uses the default of the tool"
puts $out "--------------------------------------------------------------------"
puts $out [read_file results/pitfall_cover_spec_comparison.txt]
puts $out ""

#---------------------------------------------------------------------
# PITFALL 2
#---------------------------------------------------------------------
puts $out "--------------------------------------------------------------------"
puts $out " PITFALL 2 : std.env.finish kills the whole 'vsim -c' session"
puts $out "--------------------------------------------------------------------"
set nostop [file exists results/pitfall_finish_nostop.ucdb]
set stop   [file exists results/pitfall_finish_stop.ucdb]
puts $out "command : vsim -c -coverage work.tb_alu_fsm_finish -do \"run -all; coverage save ...\""
puts $out "without -onfinish stop : the UCDB was created = $nostop   (expected: no)"
puts $out "   -> std.env.finish ended the session, 'coverage save' never ran"
puts $out "with    -onfinish stop : the UCDB was created = $stop   (expected: yes)"
puts $out "   -> the simulation only stops, the session stays alive"
puts $out ""

#---------------------------------------------------------------------
# PITFALL 3
#---------------------------------------------------------------------
puts $out "--------------------------------------------------------------------"
puts $out " PITFALL 3 : 'coverage goal' only works in the Coverage View"
puts $out "--------------------------------------------------------------------"
set t [read_file results/pitfall_goal_normal.txt]
foreach l [split $t "\n"] {
    if {[string match "*viewcov mode only*" $l]} {
        puts $out "normal simulation : $l"
    }
}
set t [read_file results/pitfall_goal_viewcov.txt]
set n 0
foreach l [split $t "\n"] {
    if {[string match "*Goal:*" $l]} {
        incr n
        if {$n <= 5} { puts $out "coverage view     : $l" }
    }
}
if {$n > 5} {
    puts $out "coverage view     : ... ($n goal lines in total)"
}
puts $out ""

#---------------------------------------------------------------------
# PITFALL 4
#---------------------------------------------------------------------
puts $out "--------------------------------------------------------------------"
puts $out " PITFALL 4 : merging two different instance paths"
puts $out "--------------------------------------------------------------------"
proc metric_lines {txt} {
    set res {}
    foreach l [split $txt "\n"] {
        if {[regexp {Number of Instances|Branches|Conditions|FSM States|FSM Transitions|Statements|Toggles|Total coverage} $l]} {
            lappend res [string trim $l]
        }
    }
    return $res
}
puts $out "---- RIGHT : ONE testbench (tb_alu_fsm), three generics ----"
foreach l [metric_lines [read_file results/merged_report.txt]] { puts $out $l }
puts $out ""
puts $out "---- WRONG : TWO testbenches (tb_alu_fsm + tb_alu_fsm_alt) ----"
foreach l [metric_lines [read_file results/pitfall_two_instances.txt]] { puts $out $l }
puts $out ""

close $out

puts "---- results/pitfall_report.txt written ----"
puts "== LAB 10 : pitfall summary done =="
