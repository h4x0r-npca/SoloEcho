# SoloEcho

Languages: [English](#english) | [한국어](#한국어) | [日本語](#日本語)

## English

SoloEcho is a private solo SNS-style Flutter app for Android, Windows, and macOS. It signs in with the user's Google account, creates a `SoloEcho` folder and a `SoloEcho Timeline` Google Sheet in the user's Drive, then stores text entries in that sheet.

### Google Cloud Setup

1. Create a Google Cloud project.
2. Enable Google Drive API and Google Sheets API.
3. Configure the OAuth consent screen.
4. Create OAuth clients:
   - Android client for package `com.soloecho.app` and the signing certificate SHA-1.
   - Desktop client for Windows and macOS.

For local Android debug builds on this Mac:

| Field | Value |
| --- | --- |
| Package name | `com.soloecho.app` |
| SHA-1 | `86:E4:02:A7:AF:49:98:7D:16:D1:3B:A5:07:EC:E9:D9:AC:19:9F:6F` |

Android does not need a client secret JSON file in the app. Google Play services matches the installed app by package name and SHA-1. If sign-in fails with `ApiException: 10`, the Android OAuth client is missing or was created with a different package name or SHA-1.

### Run

```sh
flutter run -d android
```

```powershell
flutter run -d windows `
  --dart-define=SOLOECHO_DESKTOP_CLIENT_ID="<desktop-client-id>.apps.googleusercontent.com"
```

```sh
flutter run -d macos \
  --dart-define=SOLOECHO_DESKTOP_CLIENT_ID="<desktop-client-id>.apps.googleusercontent.com"
```

If the project is located under a path with Korean or other non-ASCII characters, Windows/MSBuild may fail to read generated Flutter files. In that case run through the helper script:

```powershell
.\scripts\windows_ascii_build.ps1 `
  -DesktopClientId "<desktop-client-id>.apps.googleusercontent.com" `
  -DesktopClientSecret "<desktop-client-secret>" `
  -Mode run
```

The app requests `openid`, `email`, `profile`, and `https://www.googleapis.com/auth/drive.file`.

### Data Layout

The app uses the `Log` sheet:

| Timestamp | Content |
| --- | --- |
| `yyyy-MM-dd HH:mm:ss.SSS` | Text content |

Rows are appended chronologically in Google Sheets and displayed newest-first in the app.

## 한국어

SoloEcho는 Android, Windows, macOS에서 동작하는 개인용 solo SNS 스타일 Flutter 앱입니다. Google 계정으로 로그인한 뒤 사용자의 Drive에 `SoloEcho` 폴더와 `SoloEcho Timeline` Google Sheet를 만들고, 텍스트 기록을 해당 시트에 저장합니다.

### Google Cloud 설정

1. Google Cloud 프로젝트를 만듭니다.
2. Google Drive API와 Google Sheets API를 활성화합니다.
3. OAuth 동의 화면을 설정합니다.
4. OAuth 클라이언트를 만듭니다.
   - Android 클라이언트: package `com.soloecho.app`과 서명 인증서 SHA-1 사용
   - Desktop 클라이언트: Windows와 macOS 실행용

이 Mac의 Android debug 빌드 값:

| 항목 | 값 |
| --- | --- |
| Package name | `com.soloecho.app` |
| SHA-1 | `86:E4:02:A7:AF:49:98:7D:16:D1:3B:A5:07:EC:E9:D9:AC:19:9F:6F` |

Android 앱 안에는 client secret JSON 파일을 넣지 않습니다. Google Play services가 설치된 앱의 package name과 SHA-1을 Google Cloud의 Android OAuth client와 매칭합니다. 로그인 시 `ApiException: 10`이 나오면 Android OAuth client가 없거나 package name/SHA-1이 다르게 만들어진 상태입니다.

### 실행

```sh
flutter run -d android
```

```powershell
flutter run -d windows `
  --dart-define=SOLOECHO_DESKTOP_CLIENT_ID="<desktop-client-id>.apps.googleusercontent.com"
```

```sh
flutter run -d macos \
  --dart-define=SOLOECHO_DESKTOP_CLIENT_ID="<desktop-client-id>.apps.googleusercontent.com"
```

프로젝트 경로에 한글 등 non-ASCII 문자가 있으면 Windows/MSBuild가 Flutter 생성 파일을 읽지 못할 수 있습니다. 그 경우 아래 helper script를 사용합니다.

```powershell
.\scripts\windows_ascii_build.ps1 `
  -DesktopClientId "<desktop-client-id>.apps.googleusercontent.com" `
  -DesktopClientSecret "<desktop-client-secret>" `
  -Mode run
```

앱은 `openid`, `email`, `profile`, `https://www.googleapis.com/auth/drive.file` 권한을 요청합니다.

### 데이터 구조

앱은 `Log` 시트를 사용합니다.

| Timestamp | Content |
| --- | --- |
| `yyyy-MM-dd HH:mm:ss.SSS` | 텍스트 내용 |

행은 Google Sheets에 시간순으로 추가되고, 앱에서는 최신 기록이 먼저 보이도록 표시합니다.

## 日本語

SoloEcho は Android、Windows、macOS で動作する個人用の solo SNS 風 Flutter アプリです。Google アカウントでログインし、ユーザーの Drive に `SoloEcho` フォルダと `SoloEcho Timeline` Google Sheet を作成して、テキスト記録をそのシートに保存します。

### Google Cloud 設定

1. Google Cloud プロジェクトを作成します。
2. Google Drive API と Google Sheets API を有効にします。
3. OAuth 同意画面を設定します。
4. OAuth クライアントを作成します。
   - Android クライアント: package `com.soloecho.app` と署名証明書の SHA-1 を使用
   - Desktop クライアント: Windows と macOS 実行用

この Mac の Android debug ビルド値:

| 項目 | 値 |
| --- | --- |
| Package name | `com.soloecho.app` |
| SHA-1 | `86:E4:02:A7:AF:49:98:7D:16:D1:3B:A5:07:EC:E9:D9:AC:19:9F:6F` |

Android アプリ内に client secret JSON ファイルを入れる必要はありません。Google Play services が、インストールされたアプリの package name と SHA-1 を Google Cloud の Android OAuth client と照合します。ログイン時に `ApiException: 10` が出る場合は、Android OAuth client が存在しないか、package name/SHA-1 が一致していません。

### 実行

```sh
flutter run -d android
```

```powershell
flutter run -d windows `
  --dart-define=SOLOECHO_DESKTOP_CLIENT_ID="<desktop-client-id>.apps.googleusercontent.com"
```

```sh
flutter run -d macos \
  --dart-define=SOLOECHO_DESKTOP_CLIENT_ID="<desktop-client-id>.apps.googleusercontent.com"
```

プロジェクトのパスに韓国語などの non-ASCII 文字が含まれる場合、Windows/MSBuild が Flutter 生成ファイルを読めないことがあります。その場合は helper script を使います。

```powershell
.\scripts\windows_ascii_build.ps1 `
  -DesktopClientId "<desktop-client-id>.apps.googleusercontent.com" `
  -DesktopClientSecret "<desktop-client-secret>" `
  -Mode run
```

アプリは `openid`, `email`, `profile`, `https://www.googleapis.com/auth/drive.file` の権限を要求します。

### データ構造

アプリは `Log` シートを使用します。

| Timestamp | Content |
| --- | --- |
| `yyyy-MM-dd HH:mm:ss.SSS` | テキスト内容 |

行は Google Sheets に時系列で追加され、アプリでは新しい記録から表示されます。
