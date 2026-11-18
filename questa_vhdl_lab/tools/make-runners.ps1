param(
  [string[]]$Only = @()
)

$ErrorActionPreference = 'Stop'
#=====================================================================
# tools\make-runners.ps1
#   สร้าง run.cmd / run_fail.cmd / run_debug.cmd ของทุก lab จากเทมเพลต
#   เพื่อให้ทุกไฟล์ใช้วิธีหาเครื่องมือ (tools\pick_tool.cmd ที่สแกน license)
#   และการตัดสิน PASS/FAIL แบบเดียวกัน
#
#   ตารางด้านล่างคือ "ของจริง" ของแต่ละ lab :
#     file    = ชื่อไฟล์ที่จะสร้าง
#     script  = ไฟล์ .do ที่ vsim จะเรียก
#     extra   = อาร์กิวเมนต์เพิ่มเติมของ vsim (เช่น plusarg)
#     expect  = ผลลัพธ์ที่คาดหวัง  (ใช้แค่เป็นข้อความบอกผู้เรียน)
#     name    = บรรทัดชื่อ lab ที่พิมพ์ออกมา
#=====================================================================
$root = Split-Path -Parent $PSScriptRoot
$tpl  = Join-Path $PSScriptRoot 'run_template.cmd'

$plan = @(
  @{ lab='lab01_first_simulation'; file='run.cmd';       script='run_batch.do'; extra=''; expect='PASS'; name='LAB 01 : first simulation' }
  @{ lab='lab02_libraries';       file='run.cmd';       script='run_batch.do'; extra=''; expect='PASS'; name='LAB 02 : design libraries' }
  @{ lab='lab03_selfchecking_tb'; file='run.cmd';       script='run_batch.do'; extra=''; expect='PASS'; name='LAB 03 : self-checking testbench' }
  @{ lab='lab04_waveform';        file='run.cmd';       script='run_batch.do'; extra=''; expect='PASS'; name='LAB 04 : waveform analysis' }
  @{ lab='lab05_debugging';       file='run.cmd';       script='run_batch.do'; extra=''; expect='FAIL on purpose -- the DUT really has a bug (use run_debug.cmd)'; name='LAB 05 : debugging -- the failing test' }
  @{ lab='lab05_debugging';       file='run_debug.cmd'; script='run_debug.do'; extra=''; expect='PASS -- the bug is located'; name='LAB 05 : debugging session' }
  @{ lab='lab06_dataflow';        file='run.cmd';       script='run_batch.do'; extra=''; expect='PASS'; name='LAB 06 : dataflow and X tracing' }
  @{ lab='lab07_memory';          file='run.cmd';       script='run_batch.do'; extra=''; expect='PASS'; name='LAB 07 : memory and RAM debugging' }
  @{ lab='lab08_stimulus';        file='run.cmd';       script='run_batch.do'; extra='+NUM_RANDOM=4 +SEED1=777 +SEED2=888'; expect='PASS'; name='LAB 08 : file, random and parameterised stimulus' }
  @{ lab='lab09_psl';             file='run.cmd';       script='run_batch.do'; extra=''; expect='PASS'; name='LAB 09 : PSL assertions -- scenario GOOD' }
)

$enc = New-Object System.Text.UTF8Encoding($false)

foreach ($p in $plan) {
  $key = "$($p.lab)/$($p.file)"
  if ($Only.Count -gt 0 -and ($Only -notcontains $p.lab)) { continue }
  $dir = Join-Path $root $p.lab
  if (-not (Test-Path $dir)) { Write-Output "skip (missing): $key"; continue }

  $txt = Get-Content $tpl -Raw
  $txt = $txt -replace '__SCRIPT__', $p.script
  $txt = $txt -replace '__LABNAME__', $p.name
  $txt = $txt -replace '__EXTRA__', $p.extra
  $txt = $txt -replace '__EXPECT__', $p.expect

  $out = Join-Path $dir $p.file
  [System.IO.File]::WriteAllText($out, $txt, $enc)
  Write-Output "written: $key  ->  $p.script $('(extra: ' + $p.extra + ')')"
}
