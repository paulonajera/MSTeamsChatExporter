# Microsoft Teams Chat Exporter (Refactored Fork)

> ⚠️ This is a refactored fork of [telstrapurple/MSTeamsChatExporter](https://github.com/telstrapurple/MSTeamsChatExporter). See [MODIFICATIONS.txt](./MODIFICATIONS.txt) for a detailed list of changes.

## Overview
This tool allows Microsoft 365 users to export their personal Microsoft Teams 1:1 and group chat history using Microsoft Graph APIs. This version is modular, supports CLI parameters, and includes multiple output formats.

![Example of Export HTML file](example-of-export.png)
![Example of Exports in directory](example-of-exports.png)

## Features
- ✅ Export personal chat history via Microsoft Graph API
- 📂 Output formats: HTML (default), JSON, CSV
- 🧰 Modular structure for easier maintenance
- 💡 CLI parameters for better scripting and automation
- 📅 (Planned) Options to split exports by date

## Requirements
- PowerShell 7 ([Install Guide](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-7))
- Microsoft 365 account
- Azure AD App Registration with delegated permissions:
  - `Chat.Read`
  - `User.Read`
  - `User.ReadBasic.All`

Follow these guides to register and configure the app:
- [Register an application](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
- [Configure permissions](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-configure-app-access-web-apis)

## Getting Started

### Steps
1. Download this repository
2. Create a folder where you'd like to export your chat history
3. Open PowerShell 7
4. Run the script with the `Get-Help` command to view available parameters:

```powershell
PS> Get-Help ./Get-MicrosoftTeamsChat.ps1
```

5. Run the script with required arguments:

```powershell
PS> ./Get-MicrosoftTeamsChat.ps1 -ExportFolder C:\Users\<you>\OneDrive\ExportChat \ 
    -ClientId "0728c136-cc8c-4b29-bbb7-e20c5c35f53a" \ 
    -TenantId "b2541388-a22b-4b8d-b027-883ad6b445a7" \ 
    -Domain "contoso.com"
```

### Optional Switches
- `-AsJson` — export chats to JSON format
- `-AsCsv` — export chats to CSV format
- `-NoImages` — skips embedding images in HTML
- `-SplitByMonth` — (planned) split messages into monthly files

## File Structure
```text
MSTeamsChatExporter/
├── Get-MicrosoftTeamsChat.ps1       # Entry point
├── Modules/
│   ├── GraphAPI.psm1                # Handles MS Graph auth + data
│   ├── ChatExporter.psm1            # HTML / JSON / CSV output
│   └── Utils.psm1                   # Logging, sanitization
├── MODIFICATIONS.txt                # Summary of changes
├── README.md                        # This file
├── LICENSE                          # MIT License
```

## Contribution
Feel free to contribute and make this script better. Suggestions and improvements are welcome!

## Original Improvement Ideas from Upstream
- Add PowerShell 5.1 support for broader compatibility
- Refactor loops to improve export speed with async or parallel operations
- Handle HTTP 429 throttling gracefully ([Microsoft Graph throttling](https://docs.microsoft.com/en-us/graph/throttling))
- Improve HTML efficiency by optionally skipping base64 image embedding
- Add full code documentation and inline comments

## License
MIT (same as the original project)
