# GraphAPI.psm1 - Handles Microsoft Graph authentication and API calls

# Retrieves a delegated access token using the device code flow
function Get-GraphAccessToken {
    param(
        [Parameter(Mandatory = $true)][string]$ClientId,
        [Parameter(Mandatory = $true)][string]$TenantId,
        [Parameter(Mandatory = $true)][string]$Domain
    )

    # Required scopes for Teams chat access
    $Scopes = "https://graph.microsoft.com/Chat.Read User.Read User.ReadBasic.All"
    $RedirectUri = "http://localhost"

    # OAuth endpoints
    $AuthUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/authorize"
    $TokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"

    # Request device code to prompt user for login
    $DeviceCodeResponse = Invoke-RestMethod -Method POST -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/devicecode" `
        -ContentType "application/x-www-form-urlencoded" -Body @{ 
            client_id = $ClientId
            scope     = $Scopes
        }

    # Display login message to user
    Write-Host $DeviceCodeResponse.message

    # Poll for token until granted
    do {
        Start-Sleep -Seconds 5
        $TokenResponse = Invoke-RestMethod -Method POST -Uri $TokenUrl `
            -ContentType "application/x-www-form-urlencoded" -Body @{ 
                grant_type = "urn:ietf:params:oauth:grant-type:device_code"
                client_id  = $ClientId
                device_code = $DeviceCodeResponse.device_code
            } -ErrorAction SilentlyContinue
    } while (-not $TokenResponse.access_token)

    return $TokenResponse.access_token
}

# Retrieves a list of the signed-in user's chat threads
function Get-UserChats {
    param(
        [Parameter(Mandatory = $true)][string]$AccessToken
    )

    $uri = "https://graph.microsoft.com/v1.0/me/chats"
    $headers = @{ Authorization = "Bearer $AccessToken" }
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    return $response.value
}

# Retrieves messages for a specific chat ID
function Get-ChatMessages {
    param(
        [Parameter(Mandatory = $true)][string]$AccessToken,
        [Parameter(Mandatory = $true)][string]$ChatId
    )

    $uri = "https://graph.microsoft.com/v1.0/chats/$ChatId/messages"
    $headers = @{ Authorization = "Bearer $AccessToken" }
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    return $response.value
}

# Generates a display-friendly chat name based on topic or members
function Get-ChatName {
    param(
        [Parameter(Mandatory = $true)]$Chat
    )

    # Use the topic if available
    if ($Chat.topic -ne $null -and $Chat.topic -ne "") {
        return $Chat.topic
    }
    # Fallback for 1-on-1 chats: use the other person's display name
    elseif ($Chat.chatType -eq "oneOnOne") {
        return ($Chat.members | Where-Object { $_.user.displayName -ne $env:USERNAME }).user.displayName
    }
    # Fallback for group chats: truncate the chat ID
    else {
        return "Chat_$($Chat.id.Substring(0, 8))"
    }
}