# Utils.psm1 - Shared utility functions for logging, formatting, etc.

# Logs a timestamped message to the console
function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

# Converts a string into a safe file name (optional helper)
function Sanitize-FileName {
    param(
        [Parameter(Mandatory = $true)][string]$Name
    )
    return ($Name -replace '[^a-zA-Z0-9_-]', '_')
}

# Ensures a directory exists
function Ensure-DirectoryExists {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}