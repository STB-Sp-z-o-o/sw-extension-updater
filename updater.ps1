$repoApi = "https://api.github.com/repos/STB-Sp-z-o-o/sw-extension/contents/manifest.json"
# Use current directory to build path instead of hardcoded path to avoid encoding issues
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$localManifest = Join-Path $scriptPath "sw-extension\manifest.json"

# Get remote manifest.json (get raw content)
try {
    $remoteManifestResponse = Invoke-RestMethod -Uri $repoApi
    $remoteManifestContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($remoteManifestResponse.content))
    $remoteVersion = ($remoteManifestContent | ConvertFrom-Json).version
    Write-Host "Successfully retrieved remote version: $remoteVersion"
} catch {
    Write-Host "Error getting remote manifest: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Get local manifest.json
try {
    if (Test-Path $localManifest) {
        $localVersion = (Get-Content $localManifest -Raw | ConvertFrom-Json).version
        Write-Host "Local version found: $localVersion"
    } else {
        Write-Host "Local manifest.json not found at: $localManifest" -ForegroundColor Red
        Write-Host "Please make sure the sw-extension directory exists and contains manifest.json" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "Error reading local manifest: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Local version: $localVersion"
Write-Host "Remote version: $remoteVersion"

if ($remoteVersion -ne $localVersion) {
    Write-Host "New version available! Downloading update..." -ForegroundColor Green
    
    try {
        # Download and update
        $repoUrl = "https://github.com/STB-Sp-z-o-o/sw-extension/archive/refs/heads/master.zip"
        $localExtensionPath = Split-Path $localManifest
        $zipPath = "$env:TEMP\sw-extension-latest.zip"
        
        Write-Host "Downloading from: $repoUrl"
        Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath
        
        $extractPath = "$env:TEMP\sw-extension-latest"
        Write-Host "Extracting to: $extractPath"
        
        # Remove existing extract path if it exists
        if (Test-Path $extractPath) {
            Remove-Item $extractPath -Recurse -Force
        }
        
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        $sourcePath = Join-Path $extractPath "sw-extension-master"
        
        Write-Host "Copying files from $sourcePath to $localExtensionPath"
        Copy-Item -Path "$sourcePath\*" -Destination $localExtensionPath -Recurse -Force
        
        # Cleanup
        Remove-Item $zipPath -Force
        Remove-Item $extractPath -Recurse -Force
        
        Write-Host "Extension files updated successfully! Please reload the extension in your browser." -ForegroundColor Green
    } catch {
        Write-Host "Error during update: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "You already have the latest version." -ForegroundColor Cyan
}
