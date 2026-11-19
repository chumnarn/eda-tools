param(
  [switch]$SkipPdf
)
$ErrorActionPreference = 'Stop'

#=====================================================================
# tools\build-docs.ps1
#   Merge the Markdown parts into the full guide, then build HTML + PDF.
#
#   NOTE: Get-Content must be told to read UTF-8. PowerShell 5.1 reads a
#         file without a BOM as ANSI, which would corrupt the Thai text.
#   NOTE: the comments of this script are kept ASCII on purpose, because
#         PowerShell 5.1 reads a .ps1 file without a BOM as ANSI.
#=====================================================================
$root = Split-Path -Parent $PSScriptRoot
$docs = Join-Path $root 'docs'

$parts = @(
  (Join-Path $docs 'parts\01_intro.md'),
  (Join-Path $docs 'parts\02_setup_pages.md'),
  (Join-Path $docs 'parts\03_lab01-03.md'),
  (Join-Path $docs 'parts\04_lab04-06.md'),
  (Join-Path $docs 'parts\05_run_and_troubleshooting.md'),
  (Join-Path $docs 'parts\06_appendix.md')
)

$outMd = Join-Path $docs 'Lab_Guide_TDI.md'

# --- 1. merge ---------------------------------------------------------------
foreach ($p in $parts) {
  if (-not (Test-Path $p)) { throw "missing part: $p" }
}
$chunks = foreach ($p in $parts) { [System.IO.File]::ReadAllText($p) }
$all = ($chunks -join "`n")
Set-Content -LiteralPath $outMd -Value ($all.Trim() + "`n") -Encoding UTF8
Write-Output "merged markdown : $outMd ($((Get-Item $outMd).Length) bytes)"

# --- 2. stylesheet ----------------------------------------------------------
$cssSrc = Join-Path (Split-Path -Parent $root) 'questa_code_coverage_lab\docs\lab_style.css'
$cssDst = Join-Path $docs 'lab_style.css'
if (Test-Path $cssSrc) {
  Copy-Item -LiteralPath $cssSrc -Destination $cssDst -Force
  Write-Output "stylesheet      : $cssDst"
} else {
  Write-Output "stylesheet      : source not found, skipped"
}

# --- 3. HTML ----------------------------------------------------------------
$pandoc = 'C:\Program Files\Pandoc\pandoc.exe'
if (Test-Path $pandoc) {
  & $pandoc $outMd -f gfm -t html5 --standalone --toc --toc-depth=3 `
      --embed-resources --css=$cssDst `
      --metadata title="Tanner Digital Implementer (TDI) - Lab Guide" `
      --metadata lang="th" -o (Join-Path $docs 'Lab_Guide_TDI.html')
  if ($LASTEXITCODE -ne 0) { throw "pandoc failed ($LASTEXITCODE)" }
  Write-Output "html            : $(Join-Path $docs 'Lab_Guide_TDI.html')"
} else {
  Write-Output "pandoc not found - html skipped"
}

# --- 4. PDF -----------------------------------------------------------------
if (-not $SkipPdf) {
  $chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
  if (Test-Path $chrome) {
    $htmlPath = Join-Path $docs 'Lab_Guide_TDI.html'
    $pdfPath  = Join-Path $docs 'Lab_Guide_TDI.pdf'
    $uri = 'file:///' + ($htmlPath -replace '\\','/')
    # chrome always writes a warning to stderr, so do not fail on it
    $ErrorActionPreference = 'Continue'
    & $chrome --headless=new --disable-gpu --no-pdf-header-footer --disable-extensions `
        --print-to-pdf=$pdfPath $uri 2>&1 | Out-Null
    $ErrorActionPreference = 'Stop'
    if (Test-Path $pdfPath) {
      Write-Output "pdf             : $pdfPath ($((Get-Item $pdfPath).Length) bytes)"
    } else {
      Write-Output "pdf             : FAILED"
    }
  } else {
    Write-Output "chrome not found - pdf skipped"
  }
}
