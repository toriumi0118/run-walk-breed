# iOS ビルドガイド

Run Walk Breed を iOS 実機にビルド・デプロイするための手順書。

> 参考: [Godot 公式 — Exporting for iOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)

---

## 前提条件

| 項目 | 要件 |
|------|------|
| macOS | 最新版推奨 |
| Xcode | 15.0 以上（`xcode-select --install` でコマンドラインツールも必要） |
| Apple Developer Program | 有料メンバーシップ（$99/年）— App Store 公開に必要 |
| Godot | 4.3 以上、iOS エクスポートテンプレートをインストール済み |
| 実機 | iPhone（Apple Silicon Mac ではシミュレータも利用可能） |
| Swift | 5.9 以上（ネイティブプラグインビルド用） |

---

## 1. Godot エクスポートテンプレートのインストール

Godot エディタで:

1. **Editor → Manage Export Templates** を開く
2. 使用中の Godot バージョンのテンプレートを **Download and Install** する
3. 「iOS」テンプレートが含まれていることを確認

または手動で:
```bash
# テンプレートのダウンロード先
~/.local/share/godot/export_templates/<version>/
```

---

## 2. iOS エクスポートプリセットの設定

### エクスポートプリセットの作成

1. **Project → Export** を開く
2. **Add...** → **iOS** を選択
3. 以下を設定:

### Application セクション

| 項目 | 設定値 | 説明 |
|------|--------|------|
| Bundle Identifier | `com.yourcompany.runwalkbreed` | 逆ドメイン形式。Apple Developer で登録した App ID と一致させる |
| App Store Team ID | `XXXXXXXXXX` | Apple Developer アカウントの Team ID |
| Version | `1.0.0` | セマンティックバージョニング |
| Short Version | `1.0.0` | ストアに表示されるバージョン |
| Signature | 下記参照 | コード署名設定 |

### Required Icons / Launch Screen

- アプリアイコン: 1024x1024 PNG（角丸なし、App Store が自動処理）
- Launch Screen: Storyboard が自動生成される（Godot 4.3+）

### Capabilities（本プロジェクトで必要）

| Capability | 理由 |
|-----------|------|
| HealthKit | 歩数・距離データの取得 |
| Location Updates (Background Mode) | バックグラウンド GPS 追跡 |

### Info.plist に追加が必要なキー

Godot のエクスポート設定、または生成された Xcode プロジェクト内で以下を設定:

```xml
<!-- HealthKit -->
<key>NSHealthShareUsageDescription</key>
<string>歩数と走行距離を読み取り、ペットの育成に使用します</string>

<!-- Location -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>走行ルートの記録に位置情報を使用します</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>バックグラウンドでもルートを記録するために位置情報を使用します</string>
```

---

## 3. コード署名

### 3-1. Apple Developer Portal での準備

1. [Apple Developer → Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/) にアクセス

2. **Identifier（App ID）の作成**:
   - Identifiers → `+` → App IDs → App
   - Bundle ID: `com.yourcompany.runwalkbreed`（Explicit）
   - Capabilities: HealthKit にチェック

3. **Certificate（証明書）の作成**:
   - Certificates → `+`
   - **開発用**: Apple Development
   - **配布用**: Apple Distribution
   - CSR ファイルをアップロード（Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority）
   - ダウンロードしてダブルクリックで Keychain に登録

4. **Device（デバイス）の登録**（開発時）:
   - Devices → `+`
   - デバイスの UDID を登録（Finder で iPhone を選択 → シリアル番号をクリックして UDID 表示）

5. **Provisioning Profile の作成**:
   - Profiles → `+`
   - **開発用**: iOS App Development → App ID を選択 → 証明書を選択 → デバイスを選択
   - **配布用**: App Store Connect → App ID を選択 → 証明書を選択
   - ダウンロードしてダブルクリックで登録

### 3-2. Godot エクスポート設定でのコード署名

**自動署名（推奨）**:
- Godot 4.3+ では Xcode の自動署名が利用可能
- エクスポート後に Xcode で自動署名を設定する方が確実

**手動署名**:
- Godot のエクスポート設定で Profile と Identity を指定
- 開発・配布で異なるプロファイルを使う場合は手動が必要

---

## 4. ネイティブプラグインのビルド（本プロジェクト固有）

iOS エクスポート前に、SwiftGodot プラグインをビルドする必要がある:

```bash
# プロジェクトルートから
cd plugins/ios
./build.sh release
```

これにより:
- HealthKitPlugin、LocationPlugin、MapViewPlugin がビルドされる
- `bin/ios/release/` にライブラリが配置される
- `addons/ios_plugins.gdextension` がコピーされる

---

## 5. エクスポートと Xcode ビルド

### 5-1. Godot からエクスポート

```bash
# CLI からエクスポート（Xcode プロジェクトとして出力）
godot --headless --export-release "iOS" export/ios/RunWalkBreed.xcodeproj

# または Godot エディタから:
# Project → Export → iOS → Export Project
```

**重要**: Godot の iOS エクスポートは `.ipa` を直接出力するのではなく、**Xcode プロジェクト** を生成する。最終ビルドは Xcode で行う。

### 5-2. Xcode でプロジェクトを開く

```bash
open export/ios/RunWalkBreed.xcodeproj
```

### 5-3. Xcode での設定確認

1. **Signing & Capabilities** タブ:
   - Team: 自分の Apple Developer Team を選択
   - 「Automatically manage signing」にチェック（推奨）
   - Bundle Identifier が正しいことを確認

2. **Capabilities の追加**:
   - `+ Capability` → **HealthKit** を追加
   - `+ Capability` → **Background Modes** → **Location updates** にチェック

3. **Info.plist の確認**:
   - `NSHealthShareUsageDescription` が設定されていること
   - `NSLocationWhenInUseUsageDescription` が設定されていること
   - `NSLocationAlwaysAndWhenInUseUsageDescription` が設定されていること

4. **Deployment Target**:
   - iOS 17.0 以上に設定（SwiftGodot の要件）

### 5-4. 実機ビルド・転送

1. iPhone を Mac に USB 接続
2. Xcode 上部のデバイス選択で接続した iPhone を選択
3. **Product → Run**（⌘R）でビルド＆実機転送
4. 初回は iPhone 側で「デベロッパを信頼」する必要あり:
   - 設定 → 一般 → VPN とデバイス管理 → デベロッパ APP → 信頼

### 5-5. トラブルシューティング（実機ビルド）

| 問題 | 対処 |
|------|------|
| `Signing requires a development team` | Xcode の Signing & Capabilities で Team を選択 |
| `No provisioning profile` | Xcode の自動署名を有効にするか、手動でプロファイルを指定 |
| `Device not registered` | Apple Developer Portal でデバイス UDID を登録 |
| `Untrusted Developer` | iPhone の設定 → デバイス管理で信頼 |
| HealthKit が動作しない | Capabilities に HealthKit が追加されているか確認。シミュレータでは一部機能が動作しない |
| GPS が動作しない | Info.plist の Usage Description が設定されているか確認 |
| プラグインが読み込まれない | `build.sh` を実行して `addons/ios_plugins.gdextension` が存在するか確認 |

---

## 6. App Store 提出

### 6-1. App Store Connect での準備

1. [App Store Connect](https://appstoreconnect.apple.com/) にアクセス
2. **My Apps → `+` → New App** で新規アプリを作成:
   - Platform: iOS
   - Name: Run Walk Breed
   - Primary Language: 日本語
   - Bundle ID: `com.yourcompany.runwalkbreed`
   - SKU: `runwalkbreed`

3. **App Information** を入力:
   - カテゴリ: ゲーム → カジュアル（or ヘルスケア＆フィットネス）
   - コンテンツ対象年齢: 適切に設定
   - プライバシーポリシー URL: 必須

4. **Prepare for Submission**:
   - スクリーンショット（6.7インチ / 6.5インチ / 5.5インチ）
   - アプリの説明文
   - キーワード
   - サポート URL
   - ビルドのアップロード（下記参照）

### 6-2. Archive & Upload

1. **Xcode でスキーム設定**:
   - Product → Scheme → Edit Scheme → Archive → Build Configuration: **Release**

2. **Archive 作成**:
   - Product → Archive（⌘⇧B ではない）
   - デバイス選択を「Any iOS Device」に変更してから実行

3. **App Store Connect にアップロード**:
   - Archive 完了後 → Organizer が開く
   - **Distribute App** → **App Store Connect** → **Upload**
   - 署名の確認 → アップロード実行

4. **または Transporter アプリを使用**:
   ```bash
   # CLI からも可能
   xcrun altool --upload-app -f RunWalkBreed.ipa -t ios -u "apple-id" -p "app-specific-password"
   ```

### 6-3. TestFlight（内部テスト）

- Archive をアップロード後、App Store Connect の TestFlight タブに表示される
- **内部テスター**（最大 25 名）を追加して配信
- 審査なしで即テスト可能
- 外部テスターは App Review が必要（通常 24-48 時間）

### 6-4. 審査提出

1. App Store Connect → Prepare for Submission
2. ビルドを選択
3. **App Review Information** を入力（審査チームへの備考）:
   - HealthKit を使用する旨を記載
   - テスト用アカウントが不要な場合はその旨を記載
4. **Submit for Review**
5. 審査期間: 通常 24-48 時間

### 6-5. 審査時の注意事項

| 項目 | 注意 |
|------|------|
| HealthKit | 使用する全てのデータタイプとその理由を明記。不要なデータへのアクセスは拒否される |
| Location | バックグラウンド位置追跡を使う場合、ユーザーへの明確な説明が必須 |
| プライバシーポリシー | HealthKit データの取り扱いについて明記必須 |
| Guideline 2.5.1 | HealthKit 使用アプリはデータの正確性と適切な使用が求められる |
| Guideline 5.1.1 | ヘルスケアデータの収集・保存について透明性が必要 |

---

## 7. CI/CD（GitHub Actions）

iOS ビルドの自動化は `.github/workflows/ios-build.yml` を参照。

主な注意点:
- **macOS ランナーが必須**（GitHub Actions の macOS ランナーは Linux の 10 倍のコスト）
- 証明書・プロビジョニングプロファイルは Base64 エンコードして GitHub Secrets に保存
- Godot 4.3+ では `godot --headless --export-release "iOS"` で Xcode プロジェクトを生成
- その後 `xcodebuild` で Archive → Export → Upload の流れ

---

## クイックリファレンス

### 開発ビルド（実機テスト）

```bash
# 1. プラグインビルド
cd plugins/ios && ./build.sh release && cd ../..

# 2. Godot エクスポート
godot --headless --export-debug "iOS" export/ios/RunWalkBreed.xcodeproj

# 3. Xcode で開いてビルド
open export/ios/RunWalkBreed.xcodeproj
# Xcode: ⌘R で実機転送
```

### リリースビルド（App Store 提出）

```bash
# 1. プラグインビルド
cd plugins/ios && ./build.sh release && cd ../..

# 2. Godot エクスポート
godot --headless --export-release "iOS" export/ios/RunWalkBreed.xcodeproj

# 3. Xcode で Archive
open export/ios/RunWalkBreed.xcodeproj
# Xcode: Product → Archive → Distribute App → App Store Connect
```
