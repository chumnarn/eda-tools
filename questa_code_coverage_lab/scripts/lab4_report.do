#=====================================================================
# lab4_report.do  --  Lab 4 : generate the coverage reports
#---------------------------------------------------------------------
#   1) summary report   (one line per metric)
#   2) detailed report  (every bin, with the source line that missed)
#   3) HTML report      (browser-friendly, with the source code annotated)
#   4) rank test        (which test contributed what to the merged result)
#=====================================================================

if {[file exists ./modelsim.ini] == 0} {
    cd [file normalize [file join [file dirname [info script]] ..]]
}

if {![file exists results]} { file mkdir results }

puts "== Lab 4 : reports =="

#---------------------------------------------------------------------
# 1) summary
#---------------------------------------------------------------------
puts ""
puts "---- [1] summary report ----"
exec vcover report -summary -codeAll results/merged.ucdb

#---------------------------------------------------------------------
# 2) detailed text report : shows every uncovered bin
#---------------------------------------------------------------------
puts ""
puts "---- [2] detailed report -> results/merged_detail.txt ----"
exec vcover report -details -codeAll -output results/merged_detail.txt results/merged.ucdb

#---------------------------------------------------------------------
# 3) HTML report
#---------------------------------------------------------------------
puts ""
puts "---- [3] HTML report -> results/html_report/index.html ----"
if {[file exists results/html_report]} { file delete -force results/html_report }
exec vcover report -html -codeAll -output results/html_report results/merged.ucdb

#---------------------------------------------------------------------
# 4) rank test : which test covered what
#---------------------------------------------------------------------
puts ""
puts "---- [4] rank test ----"
exec vcover ranktest -verbose -add -rank 10 results/merged.ucdb

puts "== Lab 4 : done =="
