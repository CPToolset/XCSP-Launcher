$ErrorActionPreference = 'Stop'

Write-Host "Installing XCSP Launcher..."
$packageDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$exePath = Join-Path $packageDir "xcsp.exe"

# Copy the executable to Program Files
$targetDir = "${env:ProgramFiles}\XCSP"
if (!(Test-Path -Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir
}
Copy-Item $exePath -Destination $targetDir -Force
Copy-Item $packageDir\configs -Destination $targetDir\configs -Recurse -Force

# Bootstrap solveurs
Start-Process -FilePath "$targetDir\\xcsp.exe" -ArgumentList "--bootstrap" -Wait -NoNewWindow
