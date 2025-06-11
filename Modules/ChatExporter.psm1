# ChatExporter.psm1 - Handles exporting chat messages in various formats

function Export-ChatAsHtml {
    param(
        [Parameter(Mandatory = $true)][string]$ChatName,
        [Parameter(Mandatory = $true)]$Messages,
        [Parameter(Mandatory = $true)][string]$ExportFolder,
        [switch]$EmbedImages
    )

    # Sanitize file name
    $SafeName = ($ChatName -replace '[^a-zA-Z0-9_-]', '_') + ".html"
    $FilePath = Join-Path -Path $ExportFolder -ChildPath $SafeName

    $Html = @"
<!DOCTYPE html>
<html><head><meta charset='UTF-8'><title>$ChatName</title></head><body>
<h1>$ChatName</h1>
"@

    foreach ($msg in $Messages) {
        $Sender = $msg.from.user.displayName
        $Time = [datetime]$msg.createdDateTime
        $Text = $msg.body.content

        $Html += "<div><strong>$Sender</strong> [$Time]:<br>$Text</div><hr>"
    }

    $Html += "</body></html>"
    $Html | Out-File -FilePath $FilePath -Encoding UTF8
}

function Export-ChatAsJson {
    param(
        [Parameter(Mandatory = $true)][string]$ChatName,
        [Parameter(Mandatory = $true)]$Messages,
        [Parameter(Mandatory = $true)][string]$ExportFolder
    )

    # Sanitize and build path
    $SafeName = ($ChatName -replace '[^a-zA-Z0-9_-]', '_') + ".json"
    $FilePath = Join-Path -Path $ExportFolder -ChildPath $SafeName

    # Convert messages to JSON and write
    $Messages | ConvertTo-Json -Depth 5 | Out-File -FilePath $FilePath -Encoding UTF8
}

function Export-ChatAsCsv {
    param(
        [Parameter(Mandatory = $true)][string]$ChatName,
        [Parameter(Mandatory = $true)]$Messages,
        [Parameter(Mandatory = $true)][string]$ExportFolder
    )

    # Sanitize and build path
    $SafeName = ($ChatName -replace '[^a-zA-Z0-9_-]', '_') + ".csv"
    $FilePath = Join-Path -Path $ExportFolder -ChildPath $SafeName

    # Create CSV-ready objects
    $Rows = foreach ($msg in $Messages) {
        [PSCustomObject]@{
            Sender    = $msg.from.user.displayName
            Time      = $msg.createdDateTime
            Message   = $msg.body.content -replace '<.*?>', ''
        }
    }

    # Export to CSV
    $Rows | Export-Csv -Path $FilePath -NoTypeInformation -Encoding UTF8
}