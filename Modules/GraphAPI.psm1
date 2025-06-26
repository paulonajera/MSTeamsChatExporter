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


function Get-UserChats {
    param(
        [Parameter(Mandatory = $true)][string]$AccessToken
    )

    # Store all chats in an array
    $allChats = @() 

    $uri = "https://graph.microsoft.com/v1.0/me/chats"
    $headers = @{ Authorization = "Bearer $AccessToken" }


    # Loop to handle pagination
    do {
        try {
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

            # Add the chats from the current page
            $allChats += $response.value

            # Check for the nextLink
            $nextLink = $response.'@odata.nextLink'

            # Update for the next iteration
            if ($nextLink) {
                $uri = $nextLink
            } else {
                $uri = $null 
            }
        }
        catch {
            Write-Warning "Error fetching user chats: $_"
            $uri = $null 
        }
    } while ($uri -ne $null) 

    return $allChats
}



function Get-ChatMessages {
    param(
        [Parameter(Mandatory = $true)][string]$AccessToken,
        [Parameter(Mandatory = $true)][string]$ChatId
    )

    # Store all messages in an array
    $allMessages = @() 

    $uri = "https://graph.microsoft.com/v1.0/chats/$ChatId/messages?$top=50"
    $headers = @{ Authorization = "Bearer $AccessToken" }

    do {
        try {
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
            $allMessages += $response.value

            # Check for nextLink
            $nextLink = $response.'@odata.nextLink'

            # Update for next iteration
            if ($nextLink) {
                $uri = $nextLink
                # Write-Host "Fetching next page of messages: $uri"
            } else {
                # Exit the loop if no nextLink is present
                $uri = $null 
            }
        }
        catch {
            Write-Warning "Error fetching chat messages for Chat ID '$ChatId': $_"
            $uri = $null 
        }
    } while ($uri -ne $null)

    return $allMessages
}

function Get-ChatName {
    param(
    [Parameter(Mandatory = $true)]$Chat,
    [Parameter(Mandatory = $true)][string]$AccessToken,
    [Parameter(Mandatory = $true)][string]$CurrentUserId
    )

    # Use the topic if available
    if ($Chat.topic -ne $null -and $Chat.topic -ne "") {
        return $Chat.topic
    }

    # Fallback for 1-on-1 chats: use the other person's display name
    elseif ($Chat.chatType -eq "oneOnOne") {
        $chatId = $Chat.id

        $uri = "https://graph.microsoft.com/v1.0/chats/$chatId/members"
        $headers = @{ Authorization = "Bearer $AccessToken" }

        try {
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

            $members = $response.value 
            # Write-Log "Members found:"
            # foreach ($m in $members) {
            #     Write-Log " - DisplayName: $($m.displayName), UserID: $($m.userId)"
            # }

            # Find the user who is NOT the current user
            $otherMember = $members | Where-Object {
                $_.userId -ne $CurrentUserId -and $_.displayName -ne $null
            }
            # Write-Log "Other Members (after filtering):"
            # foreach ($o in $otherMember) {
            #     Write-Log " - DisplayName: $($o.displayName), UserID: $($o.userId)"
            # }

            # Returning the displayName of the filtered member or a default name if not found
            if ($otherMember) {
                return $otherMember.displayName
            } else {
                return "Chat_$($Chat.id.Substring(0, 8))"
            }
        }
        catch {
            Write-Warning "Could not fetch chat members for Chat ID $($Chat.id): $_"
            return "Chat_$($Chat.id.Substring(0, 8))"
        }
    }

    # Fallback for group chats
    else {
        return "Chat_$($Chat.id.Substring(0, 8))"
    }
}



# Retrieves the current user
function Get-User {
    param(
        [Parameter(Mandatory = $true)][string]$AccessToken
    )

    if (-not $AccessToken) {
        Write-Warning "AccessToken is null or empty"
        return $null
    }

    $uri = "https://graph.microsoft.com/v1.0/me"
    $headers = @{ Authorization = "Bearer $AccessToken" }

    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
        return $response
    }
    catch {
        Write-Warning "Failed to retrieve current user: $_"
        return $null
    }
}

