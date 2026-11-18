# =====================================================================
# check_signoff.tcl — เกณฑ์ตรวจรับงาน (sign-off gate) ก่อนสร้าง bitstream
#
# ไฟล์นี้ถูกเรียกจาก run_pnr.tcl หลัง route เสร็จ
# เกณฑ์ที่ตรวจ (ปรับค่าตามข้อกำหนดจริงของโปรเจกต์ได้)
#   1) Setup slack ของเส้นทางวิกฤต ต้อง >= 0
#   2) Hold  slack ของเส้นทางวิกฤต ต้อง >= 0
#   3) จำนวน DRC error ต้องเป็น 0
#   4) ต้องไม่มีเส้นทางที่ไม่ถูกจำกัดเวลา (unconstrained)
#
# ผลลัพธ์: เขียนไฟล์ $out_dir/signoff_report.txt
#          และตั้งตัวแปร signoff_ok เป็น 1 (ผ่าน) หรือ 0 (ไม่ผ่าน)
# =====================================================================

# ---------------------------------------------------------------------
# ค่าเกณฑ์
# ---------------------------------------------------------------------
set min_setup_slack 0.0
set min_hold_slack  0.0
set max_drc_errors  0

# ---------------------------------------------------------------------
# ฟังก์ชันช่วยดึงค่า
# ---------------------------------------------------------------------
proc worst_slack {dt} {
    set paths [get_timing_paths -delay_type $dt -max_paths 1 -nworst 1]
    if {[llength $paths] == 0} {
        return "NA"
    }
    return [get_property SLACK [lindex $paths 0]]
}

# ---------------------------------------------------------------------
# เก็บค่า
# ---------------------------------------------------------------------
set setup_slack [worst_slack max]
set hold_slack  [worst_slack min]

# จำนวนเส้นทางที่ไม่ถูกจำกัดเวลา
set unconstrained [get_timing_paths -unconstrained -nworst 100]
set n_unconstrained [llength $unconstrained]

# จำนวนข้อผิดพลาดของ DRC
set drc_text [report_drc -return_string]
set n_drc_error [regexp -count -nocase {ERROR} $drc_text]

# ตรวจเงื่อนไข
set signoff_ok 1
set reasons {}

if {$setup_slack eq "NA"} {
    lappend reasons "no setup path found"
    set signoff_ok 0
} elseif {$setup_slack < $min_setup_slack} {
    lappend reasons "setup slack $setup_slack < $min_setup_slack"
    set signoff_ok 0
}

if {$hold_slack eq "NA"} {
    lappend reasons "no hold path found"
    set signoff_ok 0
} elseif {$hold_slack < $min_hold_slack} {
    lappend reasons "hold slack $hold_slack < $min_hold_slack"
    set signoff_ok 0
}

if {$n_drc_error > $max_drc_errors} {
    lappend reasons "DRC errors = $n_drc_error (limit $max_drc_errors)"
    set signoff_ok 0
}

if {$n_unconstrained > 0} {
    lappend reasons "unconstrained paths = $n_unconstrained"
    set signoff_ok 0
}

# ---------------------------------------------------------------------
# เขียนรายงาน
# ---------------------------------------------------------------------
set fh [open $out_dir/signoff_report.txt w]
puts $fh "Sign-off report"
puts $fh "================================================"
puts $fh "setup slack (worst) : $setup_slack ns"
puts $fh "hold  slack (worst) : $hold_slack ns"
puts $fh "DRC errors          : $n_drc_error"
puts $fh "unconstrained paths : $n_unconstrained"
puts $fh "------------------------------------------------"
if {$signoff_ok} {
    puts $fh "RESULT: PASS"
} else {
    puts $fh "RESULT: FAIL"
    foreach r $reasons {
        puts $fh "  - $r"
    }
}
close $fh

puts "---- sign-off: setup=$setup_slack hold=$hold_slack drc_err=$n_drc_error unconstrained=$n_unconstrained ----"
