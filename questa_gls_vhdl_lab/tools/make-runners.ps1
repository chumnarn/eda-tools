param(
  [string]$Root = 'C:\Users\000148\Documents\MiniMax\eda-tools\questa_gls_vhdl_lab'
)
$ErrorActionPreference = 'Stop'

#=====================================================================
# tools\make-runners.ps1
#   สร้าง run.cmd ของทุก lab จากเทมเพลตใน tools\
#   (แก้ที่เทมเพลต ไม่แก้ที่สำเนา)
#=====================================================================

$oneStep = Join-Path $Root 'tools\run_template.cmd'
$twoStep = Join-Path $Root 'tools\run_template_2step.cmd'

# lab : @{ template ; script1 ; script2 ; labname ; expect }
$labs = @(
  @{ dir = 'lab01_rtl_baseline';     tpl = $oneStep; s1 = 'run_batch.do'; s2 = '';               name = 'LAB 01 : RTL baseline (VHDL)';                    expect = 'PASS -- 9 checks, 0 errors' },
  @{ dir = 'lab02_synth_netlist';    tpl = $oneStep; s1 = 'run_batch.do'; s2 = '';               name = 'LAB 02 : the gate netlist of cnt4';               expect = 'PASS -- every cell exists in the library' },
  @{ dir = 'lab03_cell_library';     tpl = $oneStep; s1 = 'run_batch.do'; s2 = '';               name = 'LAB 03 : the SG13G2 cell library';                expect = 'PASS -- 84 cells, 5 groups' },
  @{ dir = 'lab04_gls_first';        tpl = $oneStep; s1 = 'run_batch.do'; s2 = '';               name = 'LAB 04 : GLS for the first time';                 expect = 'PASS -- the gate level trace is written' },
  @{ dir = 'lab05_rtl_vs_gate';      tpl = $twoStep; s1 = 'run_rtl.do';   s2 = 'run_gls.do';     name = 'LAB 05 : RTL against gate level';                expect = 'PASS -- the two traces are IDENTICAL' },
  @{ dir = 'lab06_x_propagation';    tpl = $twoStep; s1 = 'run_rtl.do';   s2 = 'run_gls.do';     name = 'LAB 06 : the propagation of X';                    expect = 'PASS -- RTL holds, the gate level sees x' },
  @{ dir = 'lab07_netlist_bug';      tpl = $twoStep; s1 = 'run_rtl.do';   s2 = 'run_gls.do';     name = 'LAB 07 : a defect inside the netlist';           expect = 'PASS -- RTL = PASS and GLS = FAIL' }
)

$enc = New-Object System.Text.UTF8Encoding($false)

foreach ($lab in $labs) {
  $tplPath = $lab.tpl
  $tpl = [System.IO.File]::ReadAllText($tplPath)

  $tpl = $tpl.Replace('__LABNAME__', $lab.name)
  $tpl = $tpl.Replace('__EXPECT__',  $lab.expect)

  if ($lab.s2 -eq '') {
    $tpl = $tpl.Replace('__SCRIPT__', $lab.s1)
    $tpl = $tpl.Replace('__SCRIPT1__', '__SCRIPT__')
    $tpl = $tpl.Replace('__SCRIPT2__', '__SCRIPT__')
  } else {
    $tpl = $tpl.Replace('__SCRIPT1__', $lab.s1)
    $tpl = $tpl.Replace('__SCRIPT2__', $lab.s2)
    $tpl = $tpl.Replace('__SCRIPT__',  $lab.s1)
  }

  $dst = Join-Path (Join-Path $Root $lab.dir) 'run.cmd'
  [System.IO.File]::WriteAllText($dst, $tpl, $enc)
  Write-Output ("run.cmd written : {0}" -f $dst)
}

Write-Output ""
Write-Output ("labs with a generated run.cmd : {0}" -f $labs.Count)
