param(
  [string]$Root = 'C:\Users\000148\Documents\MiniMax\eda-tools\questa_gls_vhdl_lab',
  [string]$Out  = 'C:\Users\000148\Documents\MiniMax\eda-tools\questa_gls_vhdl_lab.zip'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (Test-Path $Out) { Remove-Item -LiteralPath $Out -Force }

# โฟลเดอร์ไลบรารีที่คอมไพล์แล้ว (binary ของ ModelSim) ไม่ต้องแนบ
$skipDir  = @('work', 'work2', 'work_rtl', 'work_gls', 'cells_lib', 'sg13g2', '_scratch')
$skipFile = @('modelsim.ini', 'transcript', 'work-obj08.cf', '.DS_Store')

$fs  = [System.IO.File]::Open($Out, [System.IO.FileMode]::CreateNew)
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
try {
  $files = Get-ChildItem -LiteralPath $Root -Recurse -File | Where-Object {
    $rel = $_.FullName.Substring($Root.Length + 1)
    $parts = $rel -split '\\'
    -not ($parts | Where-Object { $skipDir -contains $_ }) -and
    -not ($skipFile -contains $_.Name)
  }
  foreach ($f in $files) {
    $rel = $f.FullName.Substring($Root.Length + 1).Replace('\', '/')
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
      $zip, $f.FullName, $rel, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
  }
  Write-Output ("files added : {0}" -f $files.Count)
} finally {
  $zip.Dispose()
  $fs.Dispose()
}
Write-Output ("archive     : {0} ({1:N0} bytes)" -f $Out, (Get-Item $Out).Length)
