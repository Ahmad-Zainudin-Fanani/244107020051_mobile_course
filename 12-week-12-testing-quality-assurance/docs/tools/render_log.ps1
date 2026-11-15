# Merender keluaran perintah (teks asli) menjadi PNG agar mudah dilampirkan
# di laporan. Bukan tangkapan layar aplikasi; isinya persis log yang diberikan.
#
# Contoh:
#   powershell -File docs/tools/render_log.ps1 `
#     -InputPath build/logs/flutter_test.txt `
#     -OutputPath Screenshots/01-hasil-flutter-test.png `
#     -Title "flutter test --coverage" -Tail 30

param(
  [Parameter(Mandatory = $true)][string]$InputPath,
  [Parameter(Mandatory = $true)][string]$OutputPath,
  [string]$Title = "terminal",
  [int]$MaxLines = 34,
  [int]$Width = 1500,
  [switch]$Tail
)

Add-Type -AssemblyName System.Drawing

$all = Get-Content -Path $InputPath -Encoding UTF8 |
  ForEach-Object { $_.TrimEnd() }

if ($Tail) {
  $lines = @($all | Select-Object -Last $MaxLines)
} else {
  $lines = @($all | Select-Object -First $MaxLines)
}

$font = New-Object System.Drawing.Font("Consolas", 15)
$titleFont = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$lineHeight = 24
$pad = 26
$header = 44
$height = $header + ($pad * 2) + ([Math]::Max($lines.Count, 1) * $lineHeight)

$bitmap = New-Object System.Drawing.Bitmap($Width, $height)
$g = [System.Drawing.Graphics]::FromImage($bitmap)
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

$bg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(12, 14, 16))
$bar = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(32, 36, 42))
$text = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 224, 228))
$ok = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(126, 231, 135))
$warn = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 196, 87))
$dim = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(140, 148, 158))

$g.FillRectangle($bg, 0, 0, $Width, $height)
$g.FillRectangle($bar, 0, 0, $Width, $header)
$g.DrawString($Title, $titleFont, $text, 18, 12)

# Tiga titik ala jendela terminal.
$dotColors = @(255, 95, 86), @(255, 189, 46), @(39, 201, 63)
for ($i = 0; $i -lt 3; $i++) {
  $c = $dotColors[$i]
  $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, $c[0], $c[1], $c[2]))
  $g.FillEllipse($brush, ($Width - 96 + ($i * 26)), 16, 12, 12)
  $brush.Dispose()
}

$y = $header + $pad
foreach ($line in $lines) {
  $brush = $text
  if ($line -match "All tests passed|No issues found|ok\b|\+[0-9]+:") { $brush = $ok }
  elseif ($line -match "failed|Error|Exception|\[E\]") { $brush = $warn }
  elseif ($line -match "^\s*#|^\s*$") { $brush = $dim }

  # Bungkus baris panjang supaya tidak terpotong di tepi kanan.
  $remaining = $line
  $maxChars = 118
  do {
    if ($remaining.Length -gt $maxChars) {
      $chunk = $remaining.Substring(0, $maxChars)
      $remaining = "    " + $remaining.Substring($maxChars).TrimStart()
    } else {
      $chunk = $remaining
      $remaining = $null
    }
    $g.DrawString($chunk, $font, $brush, $pad, $y)
    $y += $lineHeight
  } while ($null -ne $remaining -and $remaining.Length -gt 0 -and $y -lt ($height - $pad))
}

$dir = Split-Path -Parent $OutputPath
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
$bitmap.Save((Resolve-Path -LiteralPath (Split-Path -Parent $OutputPath)).Path + "\" + (Split-Path -Leaf $OutputPath),
  [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$bitmap.Dispose()
$font.Dispose()
$titleFont.Dispose()

Write-Output "Ditulis: $OutputPath"
