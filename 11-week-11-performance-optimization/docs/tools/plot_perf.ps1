# Membuat grafik bukti profiling dari data mentah integration test.
#
# Menerima lebih dari satu berkas JSON per kondisi dan merata-ratakan nilainya
# per frame, supaya grafik tidak bergantung pada satu run yang kebetulan bagus.
#
# Contoh:
#   pwsh -File docs/tools/plot_perf.ps1 `
#     -Before docs/measurements/baseline.json,docs/measurements/baseline-2.json `
#     -After docs/measurements/after.json,docs/measurements/after-2.json `
#     -BeforeRebuilds 5052 -AfterRebuilds 887 `
#     -OutDir Screenshots

param(
  [Parameter(Mandatory = $true)][string[]]$Before,
  [Parameter(Mandatory = $true)][string[]]$After,
  [Parameter(Mandatory = $true)][string]$OutDir,
  [int]$BeforeRebuilds = 0,
  [int]$AfterRebuilds = 0
)

Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force $OutDir | Out-Null

function Get-Runs([string[]]$paths) {
  $runs = @()
  foreach ($path in $paths) {
    $runs += (Get-Content $path -Raw | ConvertFrom-Json).performance
  }
  return $runs
}

function Get-MeanMetric($runs, [string]$name) {
  $sum = 0.0
  foreach ($run in $runs) { $sum += [double]$run.$name }
  return $sum / $runs.Count
}

function Get-MeanSeries($runs, [string]$name) {
  $series = @()
  $min = ($runs | ForEach-Object { $_.$name.Count } | Measure-Object -Minimum).Minimum
  for ($i = 0; $i -lt $min; $i++) {
    $sum = 0.0
    foreach ($run in $runs) { $sum += [double]$run.$name[$i] }
    $series += ($sum / $runs.Count)
  }
  return $series
}

$beforeRuns = Get-Runs $Before
$afterRuns = Get-Runs $After

$beforeBuild = Get-MeanSeries $beforeRuns 'frame_build_times'
$afterBuild = Get-MeanSeries $afterRuns 'frame_build_times'
$beforeRaster = Get-MeanSeries $beforeRuns 'frame_rasterizer_times'
$afterRaster = Get-MeanSeries $afterRuns 'frame_rasterizer_times'

$colBefore = [System.Drawing.Color]::FromArgb(239, 68, 68)
$colAfter = [System.Drawing.Color]::FromArgb(16, 185, 129)
$colBudget = [System.Drawing.Color]::FromArgb(148, 163, 184)
$colGrid = [System.Drawing.Color]::FromArgb(226, 232, 240)
$colText = [System.Drawing.Color]::FromArgb(15, 23, 42)
$colMuted = [System.Drawing.Color]::FromArgb(100, 116, 139)

function New-Canvas([int]$w, [int]$h) {
  $bmp = New-Object System.Drawing.Bitmap($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.Clear([System.Drawing.Color]::White)
  return @($bmp, $g)
}

function Draw-Panel {
  param($g, [int]$x, [int]$y, [int]$w, [int]$h, [string]$title, $before, $after)

  $fontTitle = New-Object System.Drawing.Font('Segoe UI', 13, [System.Drawing.FontStyle]::Bold)
  $fontLabel = New-Object System.Drawing.Font('Segoe UI', 9)
  $fontSmall = New-Object System.Drawing.Font('Segoe UI', 8)
  $g.DrawString($title, $fontTitle, (New-Object System.Drawing.SolidBrush($colText)), $x, $y)

  $plotX = $x + 46
  $plotY = $y + 30
  $plotW = $w - 66
  $plotH = $h - 66

  $all = @()
  $all += ($before | ForEach-Object { $_ / 1000.0 })
  $all += ($after | ForEach-Object { $_ / 1000.0 })
  $maxVal = ($all | Measure-Object -Maximum).Maximum
  $maxY = [Math]::Ceiling([Math]::Max($maxVal, 16.7) / 10.0) * 10

  for ($i = 0; $i -le 4; $i++) {
    $val = $maxY / 4 * $i
    $yy = $plotY + $plotH - ($plotH * ($val / $maxY))
    $pen = New-Object System.Drawing.Pen($colGrid, 1)
    if ($i -gt 0) { $g.DrawLine($pen, $plotX, $yy, $plotX + $plotW, $yy) }
    $pen.Dispose()
    $g.DrawString(("{0:0} ms" -f $val), $fontSmall, (New-Object System.Drawing.SolidBrush($colMuted)), $x, ($yy - 6))
  }

  $budgetY = $plotY + $plotH - ($plotH * (16.67 / $maxY))
  $penBudget = New-Object System.Drawing.Pen($colBudget, 1)
  $penBudget.DashStyle = 'Dash'
  $g.DrawLine($penBudget, $plotX, $budgetY, $plotX + $plotW, $budgetY)
  $penBudget.Dispose()
  $g.DrawString('16,67 ms (60 FPS)', $fontSmall, (New-Object System.Drawing.SolidBrush($colMuted)), ($plotX + $plotW - 110), ($budgetY - 14))

  function Draw-Series($series, $color) {
    $pen = New-Object System.Drawing.Pen($color, 1.2)
    $count = $series.Count
    $prevX = $plotX
    $prevY = $plotY + $plotH
    for ($i = 0; $i -lt $count; $i++) {
      $v = [Math]::Min($series[$i] / 1000.0, $maxY)
      $px = $plotX + ($plotW * ($i / [Math]::Max($count - 1, 1)))
      $py = $plotY + $plotH - ($plotH * ($v / $maxY))
      if ($i -gt 0) { $g.DrawLine($pen, $prevX, $prevY, $px, $py) }
      $prevX = $px
      $prevY = $py
    }
    $pen.Dispose()
  }

  Draw-Series $before $colBefore
  Draw-Series $after $colAfter

  $ly = $plotY + $plotH + 10
  $g.FillRectangle((New-Object System.Drawing.SolidBrush($colBefore)), $plotX, ($ly + 3), 14, 4)
  $g.DrawString('sebelum (rata-rata 2 run)', $fontLabel, (New-Object System.Drawing.SolidBrush($colText)), ($plotX + 20), $ly)
  $g.FillRectangle((New-Object System.Drawing.SolidBrush($colAfter)), ($plotX + 170), ($ly + 3), 14, 4)
  $g.DrawString('sesudah (rata-rata 2 run)', $fontLabel, (New-Object System.Drawing.SolidBrush($colText)), ($plotX + 190), $ly)
  $g.DrawString(("{0} frame" -f $before.Count), $fontLabel, (New-Object System.Drawing.SolidBrush($colMuted)), ($plotX + $plotW - 50), $ly)

  $fontTitle.Dispose(); $fontLabel.Dispose(); $fontSmall.Dispose()
}

# ---------- Grafik 1: frame time per frame ----------
$bmp, $g = New-Canvas 1400 980
$fontH1 = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
$fontSub = New-Object System.Drawing.Font('Segoe UI', 10)
$g.DrawString('Profil Performa Flutter - Sebelum vs Sesudah Optimasi', $fontH1, (New-Object System.Drawing.SolidBrush($colText)), 24, 18)
$g.DrawString('Skenario: 1.500 catatan, 6x fling, buka detail, pencarian 13 karakter. Device 2209116AG (Android 13, arm64), flutter drive --profile --no-dds, 2 run per kondisi.', $fontSub, (New-Object System.Drawing.SolidBrush($colMuted)), 26, 50)

Draw-Panel $g 24 84 1352 380 'UI thread - frame build time' $beforeBuild $afterBuild
Draw-Panel $g 24 480 1352 380 'Raster thread - frame rasterizer time' $beforeRaster $afterRaster

$bmp.Save((Join-Path $OutDir '03-frame-timings.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
$fontH1.Dispose(); $fontSub.Dispose()

# ---------- Grafik 2: ringkasan metrik ----------
$bmp, $g = New-Canvas 1400 760
$fontH1 = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
$fontValue = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)

$g.DrawString('Ringkasan Metrik - Semakin Kecil Semakin Baik', $fontH1, (New-Object System.Drawing.SolidBrush($colText)), 24, 18)
$g.DrawString('Rata-rata 2 run per kondisi. Sumber: integration_test/perf_test.dart (watchPerformance) dan test/rebuild_count_test.dart', (New-Object System.Drawing.Font('Segoe UI', 10)), (New-Object System.Drawing.SolidBrush($colMuted)), 26, 50)

$metrics = @(
  @{ label = 'Build rata-rata (ms)'; b = (Get-MeanMetric $beforeRuns 'average_frame_build_time_millis'); a = (Get-MeanMetric $afterRuns 'average_frame_build_time_millis') },
  @{ label = 'Build p99 (ms)'; b = (Get-MeanMetric $beforeRuns '99th_percentile_frame_build_time_millis'); a = (Get-MeanMetric $afterRuns '99th_percentile_frame_build_time_millis') },
  @{ label = 'Build terburuk (ms)'; b = (Get-MeanMetric $beforeRuns 'worst_frame_build_time_millis'); a = (Get-MeanMetric $afterRuns 'worst_frame_build_time_millis') },
  @{ label = 'Raster rata-rata (ms)'; b = (Get-MeanMetric $beforeRuns 'average_frame_rasterizer_time_millis'); a = (Get-MeanMetric $afterRuns 'average_frame_rasterizer_time_millis') },
  @{ label = 'Raster terburuk (ms)'; b = (Get-MeanMetric $beforeRuns 'worst_frame_rasterizer_time_millis'); a = (Get-MeanMetric $afterRuns 'worst_frame_rasterizer_time_millis') },
  @{ label = 'Frame lewat budget raster'; b = (Get-MeanMetric $beforeRuns 'missed_frame_rasterizer_budget_count'); a = (Get-MeanMetric $afterRuns 'missed_frame_rasterizer_budget_count') },
  @{ label = 'Old-gen GC'; b = (Get-MeanMetric $beforeRuns 'old_gen_gc_count'); a = (Get-MeanMetric $afterRuns 'old_gen_gc_count') },
  @{ label = 'Rebuild saat mengetik'; b = [double]$BeforeRebuilds; a = [double]$AfterRebuilds }
)

$maxMetric = ($metrics | ForEach-Object { [Math]::Max($_.b, $_.a) } | Measure-Object -Maximum).Maximum
$rowH = 60
$labelW = 250
$barMaxW = 800
$y = 96
foreach ($m in $metrics) {
  $g.DrawString($m.label, (New-Object System.Drawing.Font('Segoe UI', 10)), (New-Object System.Drawing.SolidBrush($colText)), 26, ($y + 10))

  $wBefore = [Math]::Max(1, $barMaxW * ($m.b / $maxMetric))
  $wAfter = [Math]::Max(1, $barMaxW * ($m.a / $maxMetric))
  $x = 26 + $labelW

  $g.FillRectangle((New-Object System.Drawing.SolidBrush($colBefore)), $x, $y, $wBefore, 16)
  $g.FillRectangle((New-Object System.Drawing.SolidBrush($colAfter)), $x, ($y + 20), $wAfter, 16)
  $g.DrawString(("{0:0.##}" -f $m.b), $fontValue, (New-Object System.Drawing.SolidBrush($colText)), ($x + $wBefore + 6), $y)
  $g.DrawString(("{0:0.##}" -f $m.a), $fontValue, (New-Object System.Drawing.SolidBrush($colText)), ($x + $wAfter + 6), ($y + 20))

  $y += $rowH
}

$g.FillRectangle((New-Object System.Drawing.SolidBrush($colBefore)), 26, ($y + 8), 14, 10)
$g.DrawString('sebelum', (New-Object System.Drawing.Font('Segoe UI', 10)), (New-Object System.Drawing.SolidBrush($colText)), 46, ($y + 5))
$g.FillRectangle((New-Object System.Drawing.SolidBrush($colAfter)), 120, ($y + 8), 14, 10)
$g.DrawString('sesudah', (New-Object System.Drawing.Font('Segoe UI', 10)), (New-Object System.Drawing.SolidBrush($colText)), 140, ($y + 5))

$bmp.Save((Join-Path $OutDir '04-ringkasan-metrik.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
$fontH1.Dispose(); $fontValue.Dispose()

Write-Output "Grafik tersimpan di $OutDir"
