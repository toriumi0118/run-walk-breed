# iOS ビルドガイド

Run Walk Breed を iOS 実機 / App Store 向けにビルドする手順。

## 前提条件

| 項目 | 要件 |
|------|------|
| macOS | 必須（iOS ビルドは macOS のみ） |
| Xcode | 最新版推奨（初回起動して iOS Support をインストールすること） |
| iOS SDK | Xcode 経由で自動インストール |
| Python | 3.8 以上 |
| SCons | 4.0 以上（`pip install scons`） |
| Apple Developer | $99/年。証明書・プロビジョニングプロファイル発行に必要 |
| Godot | 4.3+ のエクスポートテンプレートが必要 |

```bash
# ツール確認
xcode-select -p
python3 --version
scons --version
```

## ビルドの全体フロー

```
1. Swift プラグインビルド（plugins/ios/build.sh）
2. Godot エクスポートテンプレート準備
3. Godot から iOS エクスポート → Xcode プロジェクト生成
4. Xcode でコード署名・権限設定
5. Xcode でアーカイブ → 実機 or App Store
```

---

## Step 1: Swift プラグインのビルド

HealthKit / CoreLocation / MapView の SwiftGodot プラグインをビルドする。

```bash
cd plugins/ios
./build.sh release
```

これにより以下が行われる:
- Swift Package のビルド（iOS arm64）
- ライブラリを `bin/ios/release/` にコピー
- `ios_plugins.gdextension` を `addons/` にコピー

**初回ビルド時**: SwiftGodot の依存解決に時間がかかる（数分）。

## Step 2: Godot エクスポートテンプレートの準備

### 公式テンプレートを使う場合（推奨）

Godot エディタで:
```
Editor → Manage Export Templates → Download
```

または CLI で:
```bash
# エクスポートテンプレートの場所
~/.local/share/godot/export_templates/4.3.stable/
```

### カスタムテンプレートをビルドする場合

Godot のソースコードが必要。通常は不要。

```bash
# Godot ソースのクローン
git clone https://github.com/godotengine/godot.git
cd godot
git checkout 4.3-stable

# iOS テンプレートのビルド
scons p=ios target=template_debug arch=arm64
scons p=ios target=template_release arch=arm64

# シミュレータ用（開発時のみ）
scons p=ios target=template_debug ios_simulator=yes arch=arm64
```

## Step 3: Godot から iOS エクスポート

### エクスポートプリセットの作成

Godot エディタで:
```
Project → Export → Add → iOS
```

### エクスポート設定

| 設定項目 | 値 | 備考 |
|---------|------|------|
| Bundle Identifier | `com.yourcompany.runwalkbreed` | 逆ドメイン形式 |
| Version | `1.0.0` | セマンティックバージョニング |
| Team ID | Apple Developer の Team ID | |
| App Category | `games` | |
| Min iOS Version | `16.0` | SwiftGodot + HealthKit 要件 |
| Orientation | Portrait | |

### 権限設定（必須）

エクスポート設定の Privacy セクションで以下を設定:

| 権限キー | 説明テキスト（日本語例） | 用途 |
|---------|----------------------|------|
| `NSHealthShareUsageDescription` | 「歩数と走行距離を読み取り、ペットの育成に反映します」 | HealthKit |
| `NSLocationWhenInUseUsageDescription` | 「走行ルートを記録するために位置情報を使用します」 | GPS |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | 「バックグラウンドでもルートを記録するために位置情報を使用します」 | GPS（常時） |

### エクスポート実行

#### GUI から
```
Project → Export → iOS → Export Project
```

→ Xcode プロジェクト（`.xcodeproj`）が生成される

#### CLI から
```bash
# Xcode プロジェクトとしてエクスポート
godot --headless --export-release "iOS" export/ios/RunWalkBreed.xcodeproj
```

## Step 4: Xcode でのビルド

### プロジェクトを開く

```bash
open export/ios/RunWalkBreed.xcodeproj
```

### コード署名の設定

Xcode で:
1. プロジェクトナビゲータでターゲットを選択
2. **Signing & Capabilities** タブ
3. **Automatically manage signing** をチェック
4. **Team** を選択（Apple Developer アカウント）
5. Bundle Identifier がユニークであることを確認

### Capability の追加

Signing & Capabilities で以下を追加:

| Capability | 用途 |
|-----------|------|
| **HealthKit** | 歩数・距離データへのアクセス |
| **Background Modes** → Location updates | バックグラウンド GPS 追跡（任意） |

### Info.plist の確認

エクスポート時に設定した権限テキストが `Info.plist` に含まれていることを確認:

```xml
<key>NSHealthShareUsageDescription</key>
<string>歩数と走行距離を読み取り、ペットの育成に反映します</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>走行ルートを記録するために位置情報を使用します</string>
```

### 実機ビルド

1. iPhone を USB で接続
2. Xcode の実行先で接続したデバイスを選択
3. `Cmd + R` でビルド＆実行

### アーカイブ（App Store / TestFlight 提出用）

1. **Product → Archive**
2. Organizer が開く
3. **Distribute App** → App Store Connect を選択
4. 署名とプロビジョニングを確認
5. アップロード

---

## GitHub Actions での iOS ビルド

`.github/workflows/ios-build.yml` で自動化済み。以下の Secrets が必要:

| Secret 名 | 内容 |
|-----------|------|
| `IOS_DEVELOPER_CERT_B64` | 配布用証明書（.p12）の Base64 |
| `IOS_DEVELOPER_CERT_PASSWORD` | .p12 のパスワード |
| `IOS_PROVISIONING_PROFILE_B64` | プロビジョニングプロファイルの Base64 |

```bash
# 証明書を Base64 エンコード
base64 -i distribution.p12 | pbcopy

# プロビジョニングプロファイルを Base64 エンコード
base64 -i profile.mobileprovision | pbcopy
```

---

## Swift プラグインの構成

`plugins/ios/` 以下の SwiftGodot GDExtension:

| プラグイン | 機能 | 必要フレームワーク |
|-----------|------|-------------------|
| HealthKitPlugin | 歩数・距離取得、権限管理 | HealthKit |
| LocationPlugin | GPS リアルタイム追跡、権限管理 | CoreLocation |
| MapViewPlugin | 地図表示（WKWebView + Leaflet/OSM） | WebKit |

### プラグインの更新・再ビルド

```bash
# ソースを修正後
cd plugins/ios
./build.sh release

# Godot で再エクスポート
```

### プラグインのデバッグ

```bash
# デバッグビルド
cd plugins/ios
./build.sh debug

# Xcode でブレークポイント設定してデバッグ可能
```

---

## トラブルシューティング

### エディタで GDExtension エラーが出る

```
No GDExtension library found for current OS and architecture (macos.arm64)
```

→ `ios_plugins.gdextension.template` が `.gdextension` に変更されていないか確認。macOS エディタでは iOS プラグインは読み込めないため、拡張子を `.template` にしてスキャン対象外にしている。

### Swift ビルドが失敗する

```bash
# Xcode CLI ツールが正しく設定されているか確認
xcode-select -p

# リセットして再設定
sudo xcode-select --reset

# SwiftGodot の依存キャッシュクリア
cd plugins/ios
swift package clean
swift package resolve
```

### コード署名エラー

- **自動署名**: Xcode で「Automatically manage signing」をオンにして Team を選択
- **手動署名**: Provisioning Profile UUID を正しく設定
- **証明書期限切れ**: Apple Developer ポータルで更新

### HealthKit が動かない（シミュレータ）

- HealthKit はシミュレータでは**制限付き動作**。テストデータを手動で投入する必要あり
- Health アプリ → Browse → 各データタイプ → Add Data
- バックグラウンドデリバリーはシミュレータでは動作しない

### 位置情報がシミュレータで取れない

- Xcode: **Features → Location → Custom Location** でテスト座標を設定
- または GPX ファイルで移動をシミュレート

---

## 参考リンク

- [Compiling for iOS — Godot Engine docs](https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_ios.html)
- [Exporting for iOS — Godot Engine docs](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)
- [SwiftGodot — GitHub](https://github.com/migueldeicaza/SwiftGodot)
- [Apple Developer — Certificates & Profiles](https://developer.apple.com/account/resources/certificates/list)
