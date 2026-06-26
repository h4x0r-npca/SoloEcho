# SoloEcho

SoloEcho is a private solo SNS-style Flutter app for Android and Windows. It signs in with the user's Google account, creates a `SoloEcho` folder and a `SoloEcho Timeline` Google Sheet in the user's Drive, then stores text entries in that sheet.

## Google Cloud setup

1. Create a Google Cloud project.
2. Enable Google Drive API and Google Sheets API.
3. Configure the OAuth consent screen.
4. Create OAuth clients:
   - Android client for package `com.soloecho.app` and your signing certificate SHA-1.
   - Desktop client for Windows.
5. Run with client IDs:

```powershell
flutter run -d android `
  --dart-define=SOLOECHO_ANDROID_CLIENT_ID="<android-client-id>.apps.googleusercontent.com"

flutter run -d windows `
  --dart-define=SOLOECHO_DESKTOP_CLIENT_ID="<desktop-client-id>.apps.googleusercontent.com"
```

If the project is located under a path with Korean or other non-ASCII
characters, Windows/MSBuild may fail to read generated Flutter files. In that
case run through the helper script, which mirrors the project to an ASCII path
under `%LOCALAPPDATA%` first:

```powershell
.\scripts\windows_ascii_build.ps1 `
  -DesktopClientId "<desktop-client-id>.apps.googleusercontent.com" `
  -DesktopClientSecret "<desktop-client-secret>" `
  -Mode run
```

The app requests `openid`, `email`, `profile`, and `https://www.googleapis.com/auth/drive.file`.

## Data layout

The app uses the `Log` sheet:

| Timestamp | Content |
| --- | --- |
| `yyyy-MM-dd HH:mm:ss.SSS` | Text content |

Rows are appended chronologically in Google Sheets and displayed newest-first in the app.
