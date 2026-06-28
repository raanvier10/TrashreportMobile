Add-Type -AssemblyName System.Drawing
$imagePath = "c:\Bootcamp\TrashReport\trashreport_mobile\assets\images\Group 14.png"
$outputPath = "c:\Bootcamp\TrashReport\trashreport_mobile\assets\images\icon_padded_ios.png"

$img = [System.Drawing.Image]::FromFile($imagePath)
$bmp = New-Object System.Drawing.Bitmap($img.Width, $img.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# Fill with white background for iOS
$g.Clear([System.Drawing.Color]::White)

# Scale down by 0.65
$newWidth = [math]::Round($img.Width * 0.65)
$newHeight = [math]::Round($img.Height * 0.65)
$x = [math]::Round(($img.Width - $newWidth) / 2)
$y = [math]::Round(($img.Height - $newHeight) / 2)

$g.DrawImage($img, $x, $y, $newWidth, $newHeight)
$bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$bmp.Dispose()
$img.Dispose()

Write-Host "iOS Image padded successfully!"
