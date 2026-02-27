# Secure SIP/WebRTC Client for Asterisk

這是一個使用 Flutter 開發的加密 VoIP 客戶端範例，專門用來連接 Asterisk 伺服器 (透過 WSS 和 WebRTC)，支援加密的語音和視訊通話。

## 功能
- 透過 TLS (WSS) 安全連接到 Asterisk 伺服器。
- 支援高畫質的 WebRTC 視訊與語音通話。
- 自動要求麥克風與相機權限。
- 提供撥打、接聽與掛斷的基礎 UI。

## 開發環境與安裝步驟

因為這個儲存庫只包含核心的 Dart 程式碼與套件設定，請按照以下步驟在您的本機電腦上建立並運行這個專案：

### 1. 安裝開發環境
確保您的開發電腦已安裝以下環境：
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (並設定好系統環境變數)
- Android Studio (用於 Android 編譯) 或 Xcode (用於 iOS 編譯，需 macOS)

### 2. 建立 Flutter 專案
在您的電腦終端機執行：
```bash
flutter create secure_voip
cd secure_voip
```

### 3. 替換核心檔案
將這個儲存庫中的檔案覆蓋剛建立的專案檔案：
- 將 `pubspec.yaml` 覆蓋原本的 `pubspec.yaml`
- 將 `lib/main.dart` 覆蓋原本的 `lib/main.dart`

### 4. 加入 Android 權限
打開 `android/app/src/main/AndroidManifest.xml`，在 `<manifest>` 標籤內加入以下權限：
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### 5. 下載套件並編譯
```bash
flutter pub get
```

## 📦 打包成手機 App 進行實機測試

### Android (APK)
在終端機輸入以下指令打包 APK：
```bash
flutter build apk --release
```
編譯完成後，APK 會放在 `build/app/outputs/flutter-apk/app-release.apk`。
您可以將此檔案傳到手機上安裝，或是接上傳輸線並開啟「USB 偵錯」後直接執行：
```bash
flutter install
```

### iOS (iPhone)
*請注意：iOS 編譯必須使用 macOS 電腦*
1. 執行打包指令：
   ```bash
   flutter build ipa
   ```
2. 用 Xcode 打開專案裡的 `ios/Runner.xcworkspace`。
3. 接上 iPhone，選擇實機後按下編譯 (Play 鍵)。
4. 在手機的「設定 > 一般 > VPN 與裝置管理」中信任您的開發者憑證即可開啟。

## 注意事項
- 程式碼預設連線到 `wss://uk01.888168.de:8089/ws`，使用的測試分機為 `9001`。您可以自行在 `lib/main.dart` 中修改。
- 如果您的伺服器使用的是自簽憑證或憑證無效，代碼中已開啟 `allowBadCertificate = true` 以便測試。正式上線請改回 `false`。