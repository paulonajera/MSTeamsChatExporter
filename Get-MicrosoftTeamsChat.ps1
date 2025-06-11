# Main entry point script - Get-MicrosoftTeamsChat.ps1

# Define mandatory and optional parameters
param(
    [Parameter(Mandatory = $true)]
    [string]$ExportFolder,     # Path where chat exports will be saved

    [Parameter(Mandatory = $true)]
    [string]$ClientId,         # Azure AD Application Client ID

    [Parameter(Mandatory = $true)]
    [string]$TenantId,         # Azure AD Tenant ID

    [Parameter(Mandatory = $true)]
    [string]$Domain,           # User domain (e.g., yourcompany.com)

    [switch]$AsJson,           # Optional flag: export chats as JSON
    [switch]$AsCsv,            # Optional flag: export chats as CSV
    [switch]$NoImages,         # Optional flag: skip embedding images in HTML
    [switch]$SplitByMonth      # (Planned) Optional flag: split messages by month
)

# Load internal modules
Import-Module "$PSScriptRoot\Modules\GraphAPI.psm1"       # Handles authentication and Graph API calls
Import-Module "$PSScriptRoot\Modules\ChatExporter.psm1"   # Contains logic for exporting chats
Import-Module "$PSScriptRoot\Modules\Utils.psm1"          # Logging and helper functions

# Create the export directory if it doesn't exist
New-Item -ItemType Directory -Force -Path $ExportFolder | Out-Null

# Authenticate user and get access token
Write-Log "Authenticating user..."
$Token = Get-GraphAccessToken -ClientId $ClientId -TenantId $TenantId -Domain $Domain

# Fetch list of chats the user is part of
Write-Log "Retrieving chat list..."
$Chats = Get-UserChats -AccessToken $Token

# Loop through each chat and export messages
foreach ($Chat in $Chats) {
    $ChatId = $Chat.id
    $ChatName = Get-ChatName -Chat $Chat
    $Messages = Get-ChatMessages -AccessToken $Token -ChatId $ChatId

    # Determine export format
    if ($AsJson) {
        Export-ChatAsJson -ChatName $ChatName -Messages $Messages -ExportFolder $ExportFolder
    }
    elseif ($AsCsv) {
        Export-ChatAsCsv -ChatName $ChatName -Messages $Messages -ExportFolder $ExportFolder
    }
    else {
        Export-ChatAsHtml -ChatName $ChatName -Messages $Messages -ExportFolder $ExportFolder -EmbedImages:$(!($NoImages))
    }

    Write-Log "Exported chat: $ChatName"
}

# Completion message
Write-Log "Export complete. Files saved to $ExportFolder"
