param(
  [string[]]$Only = @()
)

$ErrorActionPreference = 'Stop'
#=====================================================================
# tools\make-runners.ps1
#   สร้าง run.cmd ของทุก lab จากเทมเพลต
#   เพื่อให้ทุกไฟล์ใช้วิธีหาเครื่องมือ (tools\pick_tool.cmd ที่สแกน license)
#   และการตัดสิน PASS/FAIL แบบเดียวกัน
#
#   template = run_template.cmd       -> lab ที่จำลองครั้งเดียว
#   template = run_template_2step.cmd -> lab ที่ต้องรันสองครั้ง (RTL และ gate level)
#                                     ต้องเป็นสอง process ของ vsim แยกกัน
#=====================================================================
$root = Split-Path -Parent $PSScriptRoot
$tpl  = Join-Path $PSScriptRoot 'run_template.cmd'
$tpl2 = Join-Path $PSScriptRoot 'run_template_2step.cmd'

$plan = @(
  @{ lab='lab01_rtl_baseline';   file='run.cmd'; script='run_batch.do'; extra=''; expect='PASS'; name='LAB 01 : the RTL baseline'; two=$false }
  @{ lab='lab02_synth_netlist';  file='run.cmd'; script='run_batch.do'; extra=''; expect='PASS'; name='LAB 02 : the netlist that Yosys produced'; two=$false }
  @{ lab='lab03_cell_library';   file='run.cmd'; script='run_batch.do'; extra=''; expect='PASS'; name='LAB 03 : the SG13G2 cell library'; two=$false }
  @{ lab='lab04_gls_first';      file='run.cmd'; script='run_batch.do'; extra=''; expect='PASS'; name='LAB 04 : the first gate level simulation'; two=$false }
  @{ lab='lab05_rtl_vs_gate';    file='run.cmd'; script1='run_rtl.do'; script2='run_gls.do'; extra=''; expect='PASS -- RTL and gate level give the same trace'; name='LAB 05 : one testbench, two levels'; two=$true }
  @{ lab='lab06_x_propagation';  file='run.cmd'; script1='run_rtl.do'; script2='run_gls.do'; extra=''; expect='PASS -- the gate level sees the x, the RTL does not'; name='LAB 06 : an x behaves differently at gate level'; two=$true }
  @{ lab='lab07_netlist_bug';    file='run.cmd'; script1='run_rtl.do'; script2='run_gls.do'; extra=''; expect='PASS -- the RTL is green and the gate level is red'; name='LAB 07 : a bug only the gate level simulation sees'; two=$true }
)

$enc = New-Object System.Text.UTF8Encoding($false)

foreach ($p in $plan) {
  if ($Only.Count -gt 0 -and ($Only -notcontains $p.lab)) { continue }
  $dir = Join-Path $root $p.lab
  if (-not (Test-Path $dir)) { Write-Output "skip (missing): $($p.lab)"; continue }

  if ($p.two) {
    $txt = Get-Content $tpl2 -Raw
    $txt = $txt -replace '__SCRIPT1__', $p.script1
    $txt = $txt -replace '__SCRIPT2__', $p.script2
  } else {
    $txt = Get-Content $tpl -Raw
    $txt = $txt -replace '__SCRIPT__', $p.script
  }
  $txt = $txt -replace '__LABNAME__', $p.name
  $txt = $txt -replace '__EXTRA__', $p.extra
  $txt = $txt -replace '__EXPECT__', $p.expect

  $out = Join-Path $dir $p.file
  [System.IO.File]::WriteAllText($out, $txt, $enc)
  Write-Output "written: $($p.lab)/$($p.file)"
}
