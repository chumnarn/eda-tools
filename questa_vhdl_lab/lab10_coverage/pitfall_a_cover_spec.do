#=====================================================================
#  pitfall_a_cover_spec.do  --  LAB 10 : PITFALL 1
#---------------------------------------------------------------------
#  "+cover" WITHOUT a spec silently falls back to the default spec of
#  the tool.  "vcom -help all" states it:
#
#      +cover[=<spec>]  ... If no <spec> characters are given, sbceft is
#                        the default.
#
#  This script MEASURES it.  The very same test is run twice :
#      (a) the DUT is compiled with "+cover=bcesft"  (explicit)
#      (b) the DUT is compiled with a plain "+cover" (default)
#  and the two summary reports are compared.
#
#  NOTE : after every vcom the testbench has to be compiled again,
#  otherwise vsim stops with
#      ** Error: (vsim-13) Recompile work.tb_alu_fsm(sim) because
#                 work.alu_fsm has changed.
#=====================================================================

onerror {puts "!! ERROR : a step failed"; quit -code 90}

if {![file exists src/alu_fsm.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

if {![file exists results]} { file mkdir results }

puts "===================================================================="
puts " LAB 10 : PITFALL 1 -- the default spec of the +cover plusarg"
puts "===================================================================="

# ---- (a) explicit spec ----------------------------------------------
vcom -2008 src/alu_fsm.vhd +cover=bcesft
vcom -2008 tb/tb_alu_fsm.vhd
vsim -coverage work.tb_alu_fsm -gTEST=basic
run -all
coverage save results/pitfall_explicit_spec.ucdb -codeAll -testname explicit_spec
exec vcover report -summary -codeAll -output results/pitfall_explicit_spec.txt results/pitfall_explicit_spec.ucdb

# ---- (b) default spec -----------------------------------------------
vcom -2008 src/alu_fsm.vhd +cover
vcom -2008 tb/tb_alu_fsm.vhd
vsim -coverage work.tb_alu_fsm -gTEST=basic
run -all
coverage save results/pitfall_default_spec.ucdb -codeAll -testname default_spec
exec vcover report -summary -codeAll -output results/pitfall_default_spec.txt results/pitfall_default_spec.ucdb

# ---- restore the canonical build -------------------------------------
vcom -2008 src/alu_fsm.vhd +cover=bcesft
vcom -2008 tb/tb_alu_fsm.vhd

# ---- compare the two metric tables ----------------------------------
proc metric_lines {txt} {
    set res {}
    foreach l [split $txt "\n"] {
        if {[regexp {Branches|Conditions|FSM States|FSM Transitions|Statements|Toggles|Total coverage} $l]} {
            lappend res [string trim $l]
        }
    }
    return $res
}

set fa [open results/pitfall_explicit_spec.txt r]
set t_expl [read $fa]
close $fa
set fb [open results/pitfall_default_spec.txt r]
set t_def [read $fb]
close $fb

set l_expl [metric_lines $t_expl]
set l_def  [metric_lines $t_def]

set cf [open results/pitfall_cover_spec_comparison.txt w]
puts $cf "===================================================================="
puts $cf " PITFALL 1 : '+cover' with no spec  vs  '+cover=bcesft'"
puts $cf "===================================================================="
puts $cf ""
puts $cf "---- (a) compiled with  +cover=bcesft  (explicit) ----"
foreach l $l_expl { puts $cf $l }
puts $cf ""
puts $cf "---- (b) compiled with a plain  +cover  (tool default) ----"
foreach l $l_def { puts $cf $l }
puts $cf ""
if {$l_expl eq $l_def} {
    puts $cf "RESULT : IDENTICAL -- the default spec of +cover behaves exactly"
    puts $cf "         like +cover=bcesft on this tool."
} else {
    puts $cf "RESULT : DIFFERENT -- the default spec is NOT bcesft."
}
close $cf

puts ""
puts "---- PITFALL 1 : comparison ----"
puts [exec vcover report -summary -codeAll results/pitfall_default_spec.ucdb]
puts "---- the full comparison is in results/pitfall_cover_spec_comparison.txt ----"

puts "== LAB 10 : pitfall 1 done =="
