# Main entry point script - Get-MicrosoftTeamsChat.ps1

param(
    [Parameter(Mandatory = $true)]
    [string]$ExportFolder,

    [Parameter(Mandatory = $true)]
    [string]$ClientId,

    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$Domain,

    [switch]$AsJson,
    [switch]$AsCsv,
    [switch]$NoImages,
    [switch]$SplitByMonth
)

Import-Module "$PSScriptRoot\Modules\GraphAPI.psm1"
Import-Module "$PSScriptRoot\Modules\ChatExporter.psm1"
Import-Module "$PSScriptRoot\Modules\Utils.psm1"

New-Item -ItemType Directory -Force -Path $ExportFolder | Out-Null

Write-Log "Authenticating user..."
$Token = Get-GraphAccessToken -ClientId $ClientId -TenantId $TenantId -Domain $Domain

Write-Log "Retrieving chat list..."
$Chats = Get-UserChats -AccessToken $Token

foreach ($Chat in $Chats) {
    $ChatId = $Chat.id
    $ChatName = Get-ChatName -Chat $Chat
    $Messages = Get-ChatMessages -AccessToken $Token -ChatId $ChatId

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

Write-Log "Export complete. Files saved to $ExportFolder"
