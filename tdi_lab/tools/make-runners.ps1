param(
  [string[]]$Only = @()
)
$ErrorActionPreference = 'Stop'
#=====================================================================
# tools\make-runners.ps1
#   Generate run.cmd for every lab from one template, so that all labs use
#   the same tool lookup and the same PASS/FAIL decision.
#
#   NOTE: a .cmd file has to be pure ASCII. Thai or UTF-8 text inside a
#         .cmd file makes cmd.exe mis-read the line structure.
#   NOTE: the comments of this script are kept ASCII on purpose, because
#         PowerShell 5.1 reads a .ps1 file without a BOM as ANSI.
#=====================================================================
$root = Split-Path -Parent $PSScriptRoot
$tpl  = Join-Path $PSScriptRoot 'run_template.cmd'

$plan = @(
  @{ lab='lab01_rtl_ports';    script='check01_rtl_ports.js';    name='LAB 01 : the RTL ports and the DEF pins have to agree' }
  @{ lab='lab02_def_boundary'; script='check02_def_boundary.js'; name='LAB 02 : the place and route boundary and the pin geometry' }
  @{ lab='lab03_tech_libs';    script='check03_tech_libs.js';    name='LAB 03 : the technology and the cell libraries' }
  @{ lab='lab04_timing';       script='check04_timing.js';       name='LAB 04 : the timing constraints' }
  @{ lab='lab05_scan';         script='check05_scan.js';         name='LAB 05 : the scan configuration' }
  @{ lab='lab06_settings';     script='check06_settings.js';     name='LAB 06 : the contract of the TDI settings file' }
)

foreach ($p in $plan) {
  if ($Only.Count -gt 0 -and ($Only -notcontains $p.lab)) { continue }
  $dir = Join-Path $root $p.lab
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
  New-Item -ItemType Directory -Force -Path (Join-Path $dir 'results') | Out-Null

  $txt = Get-Content $tpl -Raw
  $txt = $txt -replace '__SCRIPT__', $p.script
  $txt = $txt -replace '__LABNAME__', $p.name

  $out = Join-Path $dir 'run.cmd'
  Set-Content -LiteralPath $out -Value $txt -Encoding ASCII -NoNewline
  Write-Output "written: $($p.lab)/run.cmd"
}
