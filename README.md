# SoloEcho

Languages: [English](#english) | [한국어](#한국어) | [日本語](#日本語)

## English

SoloEcho is a private solo SNS-style Flutter app for Android, iOS, Windows, and macOS. It signs in with the user's Google account, creates a `SoloEcho` folder and a `SoloEcho Timeline` Google Sheet in the user's Drive, then stores text entries in that sheet.

### Why SoloEcho Exists

#### A private mental restroom

Most animals instinctively hide when they perform physical excretion. Humans, as their sense of self develops, also treat physical excretion as something that belongs in an isolated private space.

Mental excretion, however, has developed a strange imbalance. Modern people often pour raw emotions, anger, anxiety, and unfinished thoughts into public SNS spaces where other people can see them. For many people, open social networks have become the only available substitute for a mental restroom in the digital world.

SoloEcho was created to solve that mismatch. It offers the safest possible private room inside the internet: a place only the user can enter, write into, and return to.

#### Expressive writing and catharsis

Academic work on expressive writing has long explored how writing about difficult emotions can support mental health and emotional processing.

Research associated with James W. Pennebaker has suggested that honestly writing about deep emotions and stress, without being constrained by form, can be connected to improvements in stress processing, anxiety, depressive symptoms, and health-related outcomes. The important condition is psychological safety: the writer must be free from the gaze and evaluation of others.

SoloEcho removes the audience effect. In public writing spaces, people tend to censor, package, or beautify their thoughts because someone else may read them. That creates another layer of stress. By removing the audience, SoloEcho helps create a psychologically safe zone where the user can experience a cleaner form of catharsis.

#### Privacy and data sovereignty

SoloEcho is designed around the modern right to privacy and personal control over data.

The "right to be let alone," introduced by Warren and Brandeis in 1890 and later treated as a foundation of modern privacy rights, matters even more in the digital era. In a society that constantly demands connection, users need a place where their thoughts can remain completely separate from public performance.

Modern data protection principles, including ideas reflected in GDPR and CCPA, emphasize that the data a person creates should remain under that person's control. SoloEcho follows that direction technically. It does not store the user's writing on a developer-operated server. Instead, entries are written directly into a spreadsheet inside the user's own Google Drive.

#### The essence of the program

SoloEcho does not ask for a complicated format.

It records only two things: time and content.

The content can be a diary entry, a quick memo, a negative feeling from that moment, or a secret the user cannot tell anyone else. There is no character limit, no social pressure, and no need for decorative presentation.

To protect our mental health, we need a private internet storage space where thoughts can be pressed down, released, and organized without passing through another person's gaze. SoloEcho focuses on exactly that essence.

### Writing Modes

SoloEcho supports two writing modes. Chat mode keeps the current bottom composer and chat-style timeline. Thread mode uses a top composer and shows the newest entries first in a feed-style list. Thread mode shows the user's Google profile image in both the composer and each entry card.

The writing mode is saved locally on each device. It does not change the Google Sheet layout; both modes use the same `Timestamp` and `Content` columns.

### Google Cloud Setup

1. Create a Google Cloud project.
2. Enable Google Drive API and Google Sheets API.
3. Configure the OAuth consent screen.
4. Create OAuth clients:
   - Android client for package `com.soloecho.app` and the signing certificate SHA-1.
   - iOS client for bundle id `com.soloecho.app`.
   - Desktop client for Windows and macOS.

For local Android debug builds on this Mac:

| Field | Value |
| --- | --- |
| Package name | `com.soloecho.app` |
| SHA-1 | `86:E4:02:A7:AF:49:98:7D:16:D1:3B:A5:07:EC:E9:D9:AC:19:9F:6F` |

Android does not need a client secret JSON file in the app. Google Play services matches the installed app by package name and SHA-1. If sign-in fails with `ApiException: 10`, the Android OAuth client is missing or was created with a different package name or SHA-1.

For iOS simulator and device builds, create `ios/Flutter/GoogleSignIn.local.xcconfig` locally:

```xcconfig
GOOGLE_IOS_CLIENT_ID = <ios-client-id>.apps.googleusercontent.com
GOOGLE_IOS_REVERSED_CLIENT_ID = com.googleusercontent.apps.<reversed-ios-client-id>
```

Do not commit that local file. The iOS client must be an iOS OAuth client for bundle id `com.soloecho.app`.

### Run

```sh
flutter run -d android
```

For a quick Android phone install and launch from macOS:

```sh
./scripts/android_run.sh
```

If more than one Android device is connected, pass the device id:

```sh
./scripts/android_run.sh 192.168.219.100:44345
```

For an iOS simulator or connected iPhone:

```sh
flutter run -d ios
```

For a one-command iOS run:

```sh
./scripts/ios_run.sh
```

```powershell
flutter run -d windows `
  --dart-define=SOLOECHO_DESKTOP_CLIENT_ID="<desktop-client-id>.apps.googleusercontent.com"
```

```sh
flutter run -d macos \
  --dart-define=SOLOECHO_DESKTOP_CLIENT_ID="<desktop-client-id>.apps.googleusercontent.com"
```

For a one-command macOS run:

```sh
./scripts/macos_run.sh \
  -DesktopClientId "<desktop-client-id>.apps.googleusercontent.com" \
  -DesktopClientSecret "<desktop-client-secret>" \
  -Mode run
```

If the project is located under a path with Korean or other non-ASCII characters, Windows/MSBuild may fail to read generated Flutter files. In that case run through the helper script:

```powershell
.\scripts\windows_ascii_build.ps1 `
  -DesktopClientId "<desktop-client-id>.apps.googleusercontent.com" `
  -DesktopClientSecret "<desktop-client-secret>" `
  -Mode run
```

The app requests `openid`, `email`, `profile`, and `https://www.googleapis.com/auth/drive.file`.

### Version Management

SoloEcho uses the Flutter version in `pubspec.yaml`, the release notes in `CHANGELOG.md`, and Git tags on GitHub together.

For each release:

1. Update `version` in `pubspec.yaml`.
2. Add release notes to `CHANGELOG.md`.
3. Commit the changes.
4. Create and push a tag such as `v0.2.1`.

Current version: `0.2.1+3`.

### Data Layout

The app uses the `Log` sheet:

| Timestamp | Content |
| --- | --- |
| `yyyy-MM-dd HH:mm:ss.SSSSSS` | Text content |

Rows are appended chronologically in Google Sheets and displayed newest-first in the app.

## 한국어

SoloEcho는 Android, iOS, Windows, macOS에서 동작하는 개인용 solo SNS 스타일 Flutter 앱입니다. Google 계정으로 로그인한 뒤 사용자의 Drive에 `SoloEcho` 폴더와 `SoloEcho Timeline` Google Sheet를 만들고, 텍스트 기록을 해당 시트에 저장합니다.

### 개발 의의: 왜 SoloEcho인가?

#### 정신적 배설을 위한 독립된 화장실

모든 동물은 육체적인 배설을 할 때 본능적으로 자신을 숨기려 합니다. 인간 역시 자아가 형성됨에 따라 육체적 배설만큼은 고립된 사적 공간에서 혼자 처리하는 것을 자연스러운 규칙으로 삼고 있습니다.

그러나 정신적 영역의 배설은 기이한 불균형을 이룹니다. 현대인들은 가공되지 않은 감정, 분노, 불안, 날것의 생각을 타인에게 고스란히 노출되는 공적인 공간인 SNS에 쏟아내곤 합니다. 디지털 세상에서 인간의 정신적 화장실 역할을 대신할 수 있는 유일한 대안이 기존의 오픈형 SNS처럼 보였기 때문입니다.

SoloEcho는 이 문제를 해결하기 위해 탄생했습니다. 이 앱은 인터넷이라는 광활한 공간 속에 오직 나만 출입할 수 있는 안전하고 독립된 정신적 화장실을 제공합니다.

#### 표현적 글쓰기와 카타르시스

학계에서는 글쓰기를 통한 감정의 배출이 인간의 정신 건강과 감정 처리에 줄 수 있는 긍정적 효과를 오랜 기간 연구해 왔습니다.

텍사스 대학교의 제임스 W. 페네베이커(James W. Pennebaker) 교수의 표현적 글쓰기 연구는, 깊은 감정과 스트레스를 형식에 구애받지 않고 솔직하게 기록하는 행위가 스트레스 처리, 불안, 우울감, 건강 관련 지표와 연결될 수 있음을 보여 주었습니다. 단, 이 효과가 온전히 발휘되려면 타인의 시선이나 평가에서 자유로운 심리적 안전감이 필요합니다.

SoloEcho는 관객 효과를 차단합니다. 기존 SNS처럼 누군가가 볼 수 있는 공간에 글을 쓰면 인간은 무의식적으로 스스로를 검열하거나 보기 좋은 형태로 생각을 포장하게 됩니다. 이는 또 다른 스트레스를 만듭니다. SoloEcho는 관객을 제거함으로써 사용자가 더 온전한 정신적 카타르시스를 경험할 수 있는 심리적 안전지대를 지향합니다.

#### 프라이버시와 데이터 주권

SoloEcho는 현대 법학이 중시하는 프라이버시와 개인의 데이터 통제권을 기술적으로 존중하는 방향으로 설계되었습니다.

1890년 미국의 법학자 워런과 브랜다이스가 제창한 "홀로 있을 권리"는 현대 프라이버시 권리의 중요한 출발점으로 여겨집니다. 끊임없는 연결을 요구하는 디지털 시대에는 자신의 생각을 공적인 수행으로부터 완전히 분리해 둘 수 있는 권리가 더욱 절실합니다.

GDPR, CCPA 등 현대의 데이터 보호 원칙은 개인이 생성한 데이터의 통제권이 기업이 아니라 개인에게 있어야 한다는 방향을 강조합니다. SoloEcho는 이 방향을 구조적으로 따릅니다. 개발자의 서버를 거치지 않고, 사용자가 로그인한 개인 Google Drive 내부의 스프레드시트에 직접 데이터를 적재합니다.

#### 프로그램의 본질

SoloEcho는 복잡한 형식을 요구하지 않습니다.

기록되는 것은 시간과 내용, 오직 두 가지입니다.

일기, 가벼운 메모, 그 순간 느낀 부정적인 감정, 혹은 아무에게도 말하지 못할 비밀 등 어떤 형태든 상관없습니다. 글자 수 제한도, 화려한 디자인도, 타인의 반응을 의식할 필요도 없습니다.

온전한 정신 건강을 지키기 위해서는 타인의 시선을 거치지 않는 나만의 인터넷 저장소에 생각을 꾹꾹 눌러 담아 정리하는 공간이 필요합니다. SoloEcho는 바로 그 본질에 집중합니다.

### 글쓰기 방식

SoloEcho는 두 가지 글쓰기 방식을 지원합니다. 채팅방식은 현재의 하단 입력창과 채팅형 타임라인을 그대로 사용합니다. 스레드방식은 상단 작성 영역을 사용하고, 최신 글이 맨 위에 오는 피드형 목록으로 기록을 보여줍니다. 스레드방식에서는 작성 영역과 각 글 카드에 사용자의 Google 프로필 이미지를 표시합니다.

글쓰기 방식 설정은 기기별 로컬 설정으로 저장됩니다. Google Sheet 구조는 바꾸지 않으며, 두 방식 모두 같은 `Timestamp`와 `Content` 열을 사용합니다.

### Google Cloud 설정

1. Google Cloud 프로젝트를 만듭니다.
2. Google Drive API와 Google Sheets API를 활성화합니다.
3. OAuth 동의 화면을 설정합니다.
4. OAuth 클라이언트를 만듭니다.
   - Android 클라이언트: package `com.soloecho.app`과 서명 인증서 SHA-1 사용
   - iOS 클라이언트: bundle id `com.soloecho.app` 사용
   - Desktop 클라이언트: Windows와 macOS 실행용

이 Mac의 Android debug 빌드 값:

| 항목 | 값 |
| --- | --- |
| Package name | `com.soloecho.app` |
| SHA-1 | `86:E4:02:A7:AF:49:98:7D:16:D1:3B:A5:07:EC:E9:D9:AC:19:9F:6F` |

Android 앱 안에는 client secret JSON 파일을 넣지 않습니다. Google Play services가 설치된 앱의 package name과 SHA-1을 Google Cloud의 Android OAuth client와 매칭합니다. 로그인 시 `ApiException: 10`이 나오면 Android OAuth client가 없거나 package name/SHA-1이 다르게 만들어진 상태입니다.

iOS 시뮬레이터와 실제 iPhone 빌드에서는 `ios/Flutter/GoogleSignIn.local.xcconfig` 파일을 로컬에 만듭니다.

```xcconfig
GOOGLE_IOS_CLIENT_ID = <ios-client-id>.apps.googleusercontent.com
GOOGLE_IOS_REVERSED_CLIENT_ID = com.googleusercontent.apps.<reversed-ios-client-id>
```

이 로컬 파일은 Git에 올리지 않습니다. iOS 클라이언트는 bundle id `com.soloecho.app`으로 만든 iOS OAuth client여야 합니다.

### 실행

```sh
flutter run -d android
```

macOS에서 Android 휴대폰에 빠르게 설치하고 실행하려면:

```sh
./scripts/android_run.sh
```

Android 기기가 여러 개 잡히면 device id를 직접 전달합니다.

```sh
./scripts/android_run.sh 192.168.219.100:44345
```

iOS 시뮬레이터나 연결된 iPhone에서 실행하려면:

```sh
flutter run -d ios
```

iOS를 한 번에 실행하려면:

```sh
./scripts/ios_run.sh
```

```powershell
flutter run -d windows `
  --dart-define=SOLOECHO_DESKTOP_CLIENT_ID="<desktop-client-id>.apps.googleusercontent.com"
```

```sh
flutter run -d macos \
  --dart-define=SOLOECHO_DESKTOP_CLIENT_ID="<desktop-client-id>.apps.googleusercontent.com"
```

macOS에서 한 번에 실행하려면:

```sh
./scripts/macos_run.sh \
  -DesktopClientId "<desktop-client-id>.apps.googleusercontent.com" \
  -DesktopClientSecret "<desktop-client-secret>" \
  -Mode run
```

프로젝트 경로에 한글 등 non-ASCII 문자가 있으면 Windows/MSBuild가 Flutter 생성 파일을 읽지 못할 수 있습니다. 그 경우 아래 helper script를 사용합니다.

```powershell
.\scripts\windows_ascii_build.ps1 `
  -DesktopClientId "<desktop-client-id>.apps.googleusercontent.com" `
  -DesktopClientSecret "<desktop-client-secret>" `
  -Mode run
```

앱은 `openid`, `email`, `profile`, `https://www.googleapis.com/auth/drive.file` 권한을 요청합니다.

### 버전 관리

SoloEcho는 `pubspec.yaml`의 Flutter 앱 버전, `CHANGELOG.md`의 변경 이력, GitHub의 Git 태그를 함께 사용해 버전을 관리합니다.

새 버전을 만들 때는 다음 순서를 사용합니다.

1. `pubspec.yaml`의 `version` 값을 올립니다.
2. `CHANGELOG.md`에 변경사항을 적습니다.
3. 변경사항을 커밋합니다.
4. `v0.2.1` 같은 태그를 만들고 GitHub에 푸시합니다.

현재 버전: `0.2.1+3`

### 데이터 구조

앱은 `Log` 시트를 사용합니다.

| Timestamp | Content |
| --- | --- |
| `yyyy-MM-dd HH:mm:ss.SSSSSS` | 텍스트 내용 |

행은 Google Sheets에 시간순으로 추가되고, 앱에서는 최신 기록이 먼저 보이도록 표시합니다.

## 日本語

SoloEcho は Android、iOS、Windows、macOS で動作する個人用の solo SNS 風 Flutter アプリです。Google アカウントでログインし、ユーザーの Drive に `SoloEcho` フォルダと `SoloEcho Timeline` Google Sheet を作成して、テキスト記録をそのシートに保存します。

### SoloEcho が必要な理由

#### 精神的な排出のための独立した個室

多くの動物は、身体的な排出を行うとき本能的に身を隠します。人間も自我が形成されるにつれて、身体的な排出は隔離された私的空間で一人で行うものとして扱うようになります。

しかし精神的な領域の排出には、奇妙な不均衡があります。現代の人々は、加工されていない感情、怒り、不安、生の思考を、他人の目に触れる公開 SNS にそのまま流し込むことがあります。デジタル世界において、精神的な個室の代わりになる場所が既存のオープンな SNS しかないように見えていたからです。

SoloEcho はこの不均衡を解決するために生まれました。インターネットという広大な空間の中に、自分だけが入れる安全で独立した精神的な個室を提供します。

#### 表現的筆記とカタルシス

学術分野では、困難な感情を書き出すことが精神的健康や感情処理を支える可能性について、長く研究されてきました。

テキサス大学の James W. Pennebaker 教授に関連する表現的筆記の研究は、深い感情やストレスを形式に縛られず正直に書くことが、ストレス処理、不安、抑うつ感、健康関連の指標と関係し得ることを示してきました。ただし、その効果を十分に得るには、他人の視線や評価から自由でいられる心理的安全性が重要です。

SoloEcho は観客効果を遮断します。既存の SNS のように誰かが見る可能性のある場所で書くと、人は無意識に自分を検閲したり、見栄えのよい形に考えを整えたりします。それは別のストレスを生みます。SoloEcho は観客を取り除くことで、より純粋な精神的カタルシスを得られる心理的安全地帯を目指します。

#### プライバシーとデータ主権

SoloEcho は、現代法が重視するプライバシーと個人のデータ統制権を技術的に尊重する設計です。

1890 年に Warren と Brandeis が提唱した "right to be let alone" は、現代のプライバシー権の重要な出発点とされています。常につながることを求められるデジタル時代には、自分の思考を公共的な演出から完全に切り離しておける権利がさらに重要になります。

GDPR や CCPA などに見られる現代のデータ保護原則は、個人が作成したデータの統制権は企業ではなく本人にあるべきだという方向を強調しています。SoloEcho はこの方向性を構造として採用しています。開発者のサーバーを経由せず、ユーザー自身の Google Drive 内にあるスプレッドシートへ直接データを書き込みます。

#### プログラムの本質

SoloEcho は複雑な形式を求めません。

記録されるのは、時間と内容の二つだけです。

日記、短いメモ、その瞬間に感じた否定的な感情、誰にも言えない秘密など、どのような形でもかまいません。文字数制限も、華やかな装飾も、他人の反応を意識する必要もありません。

心の健康を守るためには、他人の視線を通さず、自分だけのインターネット上の保存場所に思考を押し込み、吐き出し、整理できる空間が必要です。SoloEcho はその本質に集中します。

### 書き込みモード

SoloEcho は二つの書き込みモードをサポートします。チャット方式は現在の下部入力欄とチャット型タイムラインをそのまま使います。スレッド方式は上部の入力欄を使い、新しい記録を上から表示するフィード型の一覧にします。スレッド方式では、入力欄と各カードにユーザーの Google プロフィール画像を表示します。

書き込みモードは端末ごとのローカル設定として保存されます。Google Sheet の構造は変更せず、どちらの方式も同じ `Timestamp` と `Content` 列を使います。

### Google Cloud 設定

1. Google Cloud プロジェクトを作成します。
2. Google Drive API と Google Sheets API を有効にします。
3. OAuth 同意画面を設定します。
4. OAuth クライアントを作成します。
   - Android クライアント: package `com.soloecho.app` と署名証明書の SHA-1 を使用
   - iOS クライアント: bundle id `com.soloecho.app` を使用
   - Desktop クライアント: Windows と macOS 実行用

この Mac の Android debug ビルド値:

| 項目 | 値 |
| --- | --- |
| Package name | `com.soloecho.app` |
| SHA-1 | `86:E4:02:A7:AF:49:98:7D:16:D1:3B:A5:07:EC:E9:D9:AC:19:9F:6F` |

Android アプリ内に client secret JSON ファイルを入れる必要はありません。Google Play services が、インストールされたアプリの package name と SHA-1 を Google Cloud の Android OAuth client と照合します。ログイン時に `ApiException: 10` が出る場合は、Android OAuth client が存在しないか、package name/SHA-1 が一致していません。

iOS シミュレーターおよび実機ビルドでは、`ios/Flutter/GoogleSignIn.local.xcconfig` をローカルに作成します。

```xcconfig
GOOGLE_IOS_CLIENT_ID = <ios-client-id>.apps.googleusercontent.com
GOOGLE_IOS_REVERSED_CLIENT_ID = com.googleusercontent.apps.<reversed-ios-client-id>
```

このローカルファイルは Git にコミットしません。iOS クライアントは bundle id `com.soloecho.app` 用に作成した iOS OAuth client である必要があります。

### 実行

```sh
flutter run -d android
```

macOS から Android 端末へすばやくインストールして起動する場合:

```sh
./scripts/android_run.sh
```

Android 端末が複数検出される場合は device id を指定します。

```sh
./scripts/android_run.sh 192.168.219.100:44345
```

iOS シミュレーターまたは接続済み iPhone で実行する場合:

```sh
flutter run -d ios
```

iOS を一つのコマンドで実行する場合:

```sh
./scripts/ios_run.sh
```

```powershell
flutter run -d windows `
  --dart-define=SOLOECHO_DESKTOP_CLIENT_ID="<desktop-client-id>.apps.googleusercontent.com"
```

```sh
flutter run -d macos \
  --dart-define=SOLOECHO_DESKTOP_CLIENT_ID="<desktop-client-id>.apps.googleusercontent.com"
```

macOS で一つのコマンドとして実行する場合:

```sh
./scripts/macos_run.sh \
  -DesktopClientId "<desktop-client-id>.apps.googleusercontent.com" \
  -DesktopClientSecret "<desktop-client-secret>" \
  -Mode run
```

プロジェクトのパスに韓国語などの non-ASCII 文字が含まれる場合、Windows/MSBuild が Flutter 生成ファイルを読めないことがあります。その場合は helper script を使います。

```powershell
.\scripts\windows_ascii_build.ps1 `
  -DesktopClientId "<desktop-client-id>.apps.googleusercontent.com" `
  -DesktopClientSecret "<desktop-client-secret>" `
  -Mode run
```

アプリは `openid`, `email`, `profile`, `https://www.googleapis.com/auth/drive.file` の権限を要求します。

### バージョン管理

SoloEcho は `pubspec.yaml` の Flutter アプリバージョン、`CHANGELOG.md` の変更履歴、GitHub の Git タグを組み合わせてバージョンを管理します。

新しいバージョンを作るときは、次の流れを使います。

1. `pubspec.yaml` の `version` を更新します。
2. `CHANGELOG.md` に変更内容を書きます。
3. 変更をコミットします。
4. `v0.2.1` のようなタグを作成して GitHub に push します。

現在のバージョン: `0.2.1+3`

### データ構造

アプリは `Log` シートを使用します。

| Timestamp | Content |
| --- | --- |
| `yyyy-MM-dd HH:mm:ss.SSSSSS` | テキスト内容 |

行は Google Sheets に時系列で追加され、アプリでは新しい記録から表示されます。
