param(
  [string]$Root = 'C:\Users\000148\Documents\MiniMax\eda-tools\tdi_lab',
  [string]$Out  = 'C:\Users\000148\Documents\MiniMax\eda-tools\tdi_lab.zip'
)
$ErrorActionPreference = 'Stop'
#=====================================================================
# tools\make-zip.ps1
#   Package the lab for delivery.
#
#   tar.exe (bsdtar, ships with Windows 10 and 11) is used because
#   Compress-Archive on PowerShell 5.1 writes the entry names with a
#   BACKSLASH, which is not a valid ZIP path separator and confuses some
#   extractors. tar writes a standard archive with forward slashes.
#
#   NOTE: the comments of this script are kept ASCII on purpose, because
#         PowerShell 5.1 reads a .ps1 file without a BOM as ANSI.
#=====================================================================
if (-not (Test-Path $Root)) { throw "root not found: $Root" }

# folders that are build output and not part of the deliverable
$skipDir  = @('node_modules')
$skipFile = @('.DS_Store')

$files = Get-ChildItem -LiteralPath $Root -Recurse -File | Where-Object {
  $rel = $_.FullName.Substring($Root.Length + 1)
  $parts = $rel -split '\\'
  -not ($parts | Where-Object { $skipDir -contains $_ }) -and
  -not ($skipFile -contains $_.Name)
}

if (Test-Path $Out) { Remove-Item -LiteralPath $Out -Force }

$tar = Get-Command tar -ErrorAction SilentlyContinue
if ($tar) {
  & $tar.Source -a -c -f $Out -C $Root .
  if ($LASTEXITCODE -ne 0) { throw "tar failed ($LASTEXITCODE)" }
  Write-Output "packager        : tar ($($tar.Source))"
} else {
  Compress-Archive -Path (Join-Path $Root '*') -DestinationPath $Out -Force
  Write-Output "packager        : Compress-Archive (entries use a backslash)"
}

Write-Output ("files added : {0}" -f $files.Count)
Write-Output ("archive     : {0} ({1:N0} bytes)" -f $Out, (Get-Item $Out).Length)
