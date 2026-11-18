param(
  [switch]$SkipPdf
)
$ErrorActionPreference = 'Stop'

#=====================================================================
# tools\build-docs.ps1
#   รวมไฟล์ Markdown ส่วนย่อยเป็นคู่มือฉบับเต็ม แล้วสร้าง HTML + PDF
#=====================================================================
$root = Split-Path -Parent $PSScriptRoot
$docs = Join-Path $root 'docs'

$parts = @(
  (Join-Path $docs 'parts\01_intro_lab01-06.md'),
  (Join-Path $docs 'parts\02_lab07-10.md'),
  (Join-Path $docs 'parts\03_lab11.md'),
  (Join-Path $docs 'parts\04_appendix.md')
)

$outMd = Join-Path $docs 'Lab_Guide_QuestaSim_VHDL.md'
$enc = New-Object System.Text.UTF8Encoding($false)

# --- 1. รวมไฟล์ -------------------------------------------------------
foreach ($p in $parts) {
  if (-not (Test-Path $p)) { throw "missing part: $p" }
}
$all = ($parts | ForEach-Object { [System.IO.File]::ReadAllText($_) }) -join "`n"
[System.IO.File]::WriteAllText($outMd, $all.Trim() + "`n", $enc)
Write-Output "merged markdown : $outMd ($((Get-Item $outMd).Length) bytes)"

# --- 2. stylesheet -----------------------------------------------------
$cssSrc = Join-Path (Split-Path -Parent $root) 'questa_code_coverage_lab\docs\lab_style.css'
$cssDst = Join-Path $docs 'lab_style.css'
if (Test-Path $cssSrc) {
  Copy-Item $cssSrc $cssDst -Force
  Write-Output "stylesheet      : $cssDst"
} else {
  Write-Output "stylesheet      : source not found, skipped"
}

# --- 3. HTML ------------------------------------------------------------
$pandoc = 'C:\Program Files\Pandoc\pandoc.exe'
if (Test-Path $pandoc) {
  & $pandoc $outMd -f gfm -t html5 --standalone --toc --toc-depth=3 `
      --embed-resources --css=$cssDst `
      --metadata title="QuestaSim VHDL Simulation - Lab Guide" `
      --metadata lang="th" -o (Join-Path $docs 'Lab_Guide_QuestaSim_VHDL.html')
  if ($LASTEXITCODE -ne 0) { throw "pandoc failed ($LASTEXITCODE)" }
  Write-Output "html            : $(Join-Path $docs 'Lab_Guide_QuestaSim_VHDL.html')"
} else {
  Write-Output "pandoc not found - html skipped"
}

# --- 4. PDF -------------------------------------------------------------
if (-not $SkipPdf) {
  $chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
  if (Test-Path $chrome) {
    $htmlPath = Join-Path $docs 'Lab_Guide_QuestaSim_VHDL.html'
    $pdfPath  = Join-Path $docs 'Lab_Guide_QuestaSim_VHDL.pdf'
    $uri = 'file:///' + ($htmlPath -replace '\\','/')
    # chrome เขียน warning ลง stderr เสมอ (เรื่อง extension) จึงต้องปิด
    # $ErrorActionPreference ไว้ชั่วคราว ไม่ให้สคริปต์ล้มเหลว
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
