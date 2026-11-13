[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
Add-Type -AssemblyName System.Drawing

# Reproducible, code-drawn Millennium-inspired blue/white badge. No character
# artwork is cropped, regenerated, or used as an installer identity.
$assetRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'assets'
$source = New-Object System.Drawing.Bitmap 512, 512
$canvas = [System.Drawing.Graphics]::FromImage($source)
$shape = New-Object System.Drawing.Drawing2D.GraphicsPath
$background = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
  [System.Drawing.Point]::new(0, 0), [System.Drawing.Point]::new(512, 512),
  [System.Drawing.ColorTranslator]::FromHtml('#1479B8'),
  [System.Drawing.ColorTranslator]::FromHtml('#17426D')
)
$outline = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml('#76E4F4')), 10
$halo = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml('#9FEFFA')), 12
$mark = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$accent = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#76E4F4'))
try {
  $canvas.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $canvas.Clear([System.Drawing.Color]::Transparent)
  foreach ($arc in @(@(18,18,120,120,180,90), @(374,18,120,120,270,90), @(374,374,120,120,0,90), @(18,374,120,120,90,90))) {
    $shape.AddArc($arc[0], $arc[1], $arc[2], $arc[3], $arc[4], $arc[5])
  }
  $shape.CloseFigure()
  $canvas.FillPath($background, $shape)
  $canvas.DrawPath($outline, $shape)
  $canvas.DrawEllipse($halo, 157, 77, 198, 42)

  # The angular pair echoes the Millennium emblem used throughout the theme.
  $canvas.FillPolygon($mark, [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(100,170), [System.Drawing.PointF]::new(292,170),
    [System.Drawing.PointF]::new(165,386), [System.Drawing.PointF]::new(128,342),
    [System.Drawing.PointF]::new(195,225), [System.Drawing.PointF]::new(143,225)
  ))
  $canvas.FillPolygon($mark, [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(320,170), [System.Drawing.PointF]::new(431,170),
    [System.Drawing.PointF]::new(431,225), [System.Drawing.PointF]::new(338,386),
    [System.Drawing.PointF]::new(302,345), [System.Drawing.PointF]::new(372,225),
    [System.Drawing.PointF]::new(345,225), [System.Drawing.PointF]::new(248,384),
    [System.Drawing.PointF]::new(214,343)
  ))
  $canvas.FillRectangle($accent, 106, 419, 299, 9)
} finally {
  $shape.Dispose(); $background.Dispose(); $outline.Dispose()
  $halo.Dispose(); $mark.Dispose(); $accent.Dispose(); $canvas.Dispose()
}

$sizes = @(16, 20, 24, 32, 40, 48, 64, 128, 256)
$frames = @()
try {
  foreach ($size in $sizes) {
    $frame = New-Object System.Drawing.Bitmap $size, $size
    $graphics = [System.Drawing.Graphics]::FromImage($frame)
    $stream = New-Object System.IO.MemoryStream
    try {
      $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
      $graphics.DrawImage($source, 0, 0, $size, $size)
      $frame.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
      $frames += ,$stream.ToArray()
      if ($size -eq 256) {
        [System.IO.File]::WriteAllBytes((Join-Path $assetRoot 'yuuka-tray.png'), $stream.ToArray())
      }
    } finally { $graphics.Dispose(); $frame.Dispose(); $stream.Dispose() }
  }
} finally { $source.Dispose() }

$iconStream = New-Object System.IO.MemoryStream
$writer = New-Object System.IO.BinaryWriter $iconStream
try {
  $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$sizes.Count)
  $offset = 6 + 16 * $sizes.Count
  for ($i = 0; $i -lt $sizes.Count; $i++) {
    $dimension = if ($sizes[$i] -eq 256) { 0 } else { $sizes[$i] }
    $writer.Write([byte]$dimension); $writer.Write([byte]$dimension)
    $writer.Write([byte]0); $writer.Write([byte]0)
    $writer.Write([uint16]1); $writer.Write([uint16]32)
    $writer.Write([uint32]$frames[$i].Length); $writer.Write([uint32]$offset)
    $offset += $frames[$i].Length
  }
  foreach ($frame in $frames) { $writer.Write([byte[]]$frame) }
  $writer.Flush()
  foreach ($name in @('yuuka-tray.ico', 'codex-dream-skin.ico')) {
    [System.IO.File]::WriteAllBytes((Join-Path $assetRoot $name), $iconStream.ToArray())
  }
} finally { $writer.Dispose(); $iconStream.Dispose() }

Write-Host 'Built Yuuka PNG and nine-size ICO assets.'
