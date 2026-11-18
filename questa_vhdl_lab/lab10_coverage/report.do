#=====================================================================
#  report.do  --  LAB 10 : generate the coverage reports
#---------------------------------------------------------------------
#   1) summary report   (one line per metric)
#   2) detailed report  (every bin, with the source line that was missed)
#   3) HTML report      (browser friendly, source code annotated)
#=====================================================================

onerror {puts "!! ERROR : a step failed"; quit -code 90}

if {![file exists src/alu_fsm.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

if {![file exists results]} { file mkdir results }

puts "===================================================================="
puts " LAB 10 : reports"
puts "===================================================================="

#---------------------------------------------------------------------
# 1) summary  ->  results/merged_report.txt
#---------------------------------------------------------------------
exec vcover report -summary -codeAll -output results/merged_report.txt results/merged.ucdb
puts ""
puts "---- [1] summary report ----"
puts [exec vcover report -summary -codeAll results/merged.ucdb]

#---------------------------------------------------------------------
# 2) details  ->  results/merged_detail.txt
#---------------------------------------------------------------------
exec vcover report -details -codeAll -output results/merged_detail.txt results/merged.ucdb
puts ""
puts "---- [2] detailed report -> results/merged_detail.txt ----"
puts "       (open that file to see which bin was NOT covered)"

#---------------------------------------------------------------------
# 3) html  ->  results/html_report/index.html
#---------------------------------------------------------------------
if {[file exists results/html_report]} { file delete -force results/html_report }
exec vcover report -html -codeAll -output results/html_report results/merged.ucdb
puts ""
puts "---- [3] HTML report -> results/html_report/index.html ----"

puts "== LAB 10 : reports done =="
