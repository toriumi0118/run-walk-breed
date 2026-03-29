# Run Walk Breed

## プロジェクト概要

ランナー・ウォーカー向けのモバイルゲームアプリ（iOS / Android）。
歩数・走行距離・ルートなどの実際のヘルスケアデータを使って、ロボット風のペットを育成し、他のユーザーと対戦できるゲーム。

### ゲームシステム

- **育成**: 実際の歩数・距離がペットのパラメータ（HP, 攻撃, 防御, 素早さ等）の成長に直結
- **スキル**: ペットは技・スキルを習得し、バトル前にスキル構成を選択
- **バトル**: 1対1のオートファイト。バトル中はプレイヤー操作なし（観戦）。育成で得たパラメータとスキル選択が勝敗を決める
- **対戦**: 他のユーザーのペットとマッチングして対戦

## 技術スタック

- **ゲームエンジン**: Godot 4.x（GDScript）
- **対象プラットフォーム**: iOS / Android
- **CI/CD**: GitHub Actions
- **ネイティブ連携**:
  - ヘルスケアデータ: iOS → HealthKit（SwiftGodot）/ Android → Health Connect（Android Plugin v2）
  - GPS/位置情報: iOS → Core Location（SwiftGodot）/ Android → PraxisMapper GPS Plugin
  - 地図表示: WebView overlay + OpenStreetMap or Google Maps API

## ディレクトリ構成

```
run-walk-breed/
├── project.godot
├── export_presets.cfg
├── CLAUDE.md
├── .gitignore
│
├── src/
│   ├── autoload/                # Singletons（グローバルマネージャー）
│   │   ├── game_manager.gd
│   │   ├── audio_manager.gd
│   │   └── data_manager.gd     # ヘルスケア/GPS データの管理
│   ├── scenes/
│   │   ├── ui/                  # UI シーン
│   │   ├── pet/                 # ペット育成シーン
│   │   ├── battle/              # 対戦シーン
│   │   ├── map/                 # 地図・ルート表示
│   │   └── common/              # 共通コンポーネント
│   ├── utils/
│   │   ├── constants.gd
│   │   └── enums.gd
│   └── native/                  # ネイティブプラグインとの橋渡し
│       ├── health_bridge.gd
│       ├── gps_bridge.gd
│       └── map_bridge.gd
│
├── assets/
│   ├── images/
│   ├── audio/
│   ├── fonts/
│   ├── shaders/
│   └── animations/
│
├── themes/
│   └── ui_theme.tres
│
├── plugins/                     # ネイティブプラグイン
│   ├── android/                 # Android Plugin v2（Java/Kotlin）※後回し
│   └── ios/                     # SwiftGodot Extensions + build.sh
│       ├── Package.swift
│       ├── Sources/             # HealthKitPlugin, LocationPlugin, MapViewPlugin
│       ├── build.sh             # ビルドスクリプト
│       └── ios_plugins.gdextension.template
│
├── tests/                       # GdUnit4 テスト
│   └── ...
│
├── export/
│   ├── android/
│   └── ios/
│
└── .github/
    └── workflows/
        ├── test.yml             # push/PR 時にテスト実行
        ├── android-build.yml    # Android ビルド & エクスポート
        ├── ios-build.yml        # iOS ビルド & エクスポート
        └── release.yml          # リリース作成
```

## ビルド・テスト・デプロイ

### ローカル開発

```bash
# Godot エディタで開く
godot project.godot

# ヘッドレスでテスト実行
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add "res://tests"

# iOS Swift プラグインビルド
cd plugins/ios && ./build.sh release && cd ../..

# iOS エクスポート（Xcode プロジェクト生成）
godot --headless --export-release "iOS" export/ios/RunWalkBreed.xcodeproj
```

**iOS ビルドの詳細手順**: [docs/IOS_BUILD.md](docs/IOS_BUILD.md)

### CI/CD（GitHub Actions）

- **テスト**: `test.yml` — push/PR ごとに GdUnit4 テスト実行
- **Android ビルド**: `android-build.yml` — タグ push で APK/AAB エクスポート
- **iOS ビルド**: `ios-build.yml` — タグ push で IPA エクスポート（macOS ランナー）
- **リリース**: `release.yml` — 全プラットフォームビルド + GitHub Release 作成

### 必要な GitHub Secrets

```
# Android
SECRET_RELEASE_KEYSTORE_BASE64
SECRET_RELEASE_KEYSTORE_USER
SECRET_RELEASE_KEYSTORE_PASSWORD

# iOS
IOS_DEVELOPER_CERT_B64
IOS_DEVELOPER_CERT_PASSWORD
IOS_PROVISIONING_PROFILE_B64

# ストア公開（任意）
PLAY_STORE_SERVICE_ACCOUNT
APPSTORE_ISSUER_ID
APPSTORE_API_KEY_ID
APPSTORE_API_PRIVATE_KEY
```

## GDScript コーディング規約

### 命名規則

| 対象 | スタイル | 例 |
|------|---------|-----|
| クラス名 | PascalCase | `class_name PlayerCharacter` |
| 変数・関数 | snake_case | `var player_health`, `func get_position()` |
| 定数 | CONSTANT_CASE | `const MAX_SPEED = 300` |
| Enum | PascalCase (名前), CONSTANT_CASE (値) | `enum State { IDLE, RUNNING }` |
| ファイル名 | snake_case | `player_character.gd`, `main_menu.tscn` |
| シグナルハンドラ | `_on_` prefix | `func _on_button_pressed()` |
| プライベート | `_` prefix | `var _internal_state`, `func _calculate()` |

### ファイル内の記述順序

```gdscript
extends Node2D
class_name MyClass

# 1. Signals
signal health_changed(new_health: int)

# 2. Enums
enum State { IDLE, RUNNING }

# 3. Constants
const SPEED = 200

# 4. @export 変数
@export var max_health: int = 100

# 5. 通常の変数
var current_health: int

# 6. @onready 変数
@onready var sprite = %Sprite2D

# 7. ライフサイクル (_ready, _process, _input)
func _ready() -> void:
    pass

# 8. Public メソッド
func take_damage(amount: int) -> void:
    pass

# 9. シグナルハンドラ (_on_*)
func _on_animation_finished() -> void:
    pass

# 10. Private メソッド (_*)
func _calculate_damage() -> int:
    return 0
```

### 型付け

- **全ての関数に戻り値の型を付ける**: `func foo() -> void:`
- **引数には型を付ける**: `func bar(amount: int) -> void:`
- **変数は型推論またはアノテーション**: `var health: int = 100`
- **型付けと非型付けを混在させない**

## Godot ベストプラクティス

### シーン・ノード構成

- **Composition over Inheritance**: コンポーネントパターンを使う（HealthComponent, MovementComponent 等）
- **シグナルで上方向に通信**: 子 → 親はシグナル、親 → 子は直接呼び出し
- **Scene Unique Names（%）でノード参照**: `@onready var sprite = %Sprite2D`
- **グループで分類**: `add_to_group("enemies")`
- **シーングラフは浅く**: 3-4 階層まで

### モバイル最適化

- **FPS**: モバイルは 30 FPS ターゲット（`Engine.max_fps = 30`）
- **オブジェクトプーリング**: 頻繁に生成・破棄するノードはプールする
- **queue_free()**: `free()` ではなく常に `queue_free()` を使う
- **不要な処理を止める**: `set_process(false)`, `set_physics_process(false)`
- **テクスチャアトラス**: ドローコール削減のためバッチング
- **サウンド**: 同時再生は 8-16 に制限

### UI / タッチ入力

- **Base Resolution**: 1080×1920 (Portrait)
- **Stretch Mode**: `canvas_items`
- **タッチボタンサイズ**: 最低 88px（44pt）
- **Safe Area**: ノッチ・角丸を考慮
- **Container ノード**: VBoxContainer, HBoxContainer 等で柔軟レイアウト

## ネイティブ機能の連携方針

### ヘルスケアデータ（歩数・距離）

| Platform | 方式 | API |
|----------|------|-----|
| Android | Godot Android Plugin v2（Java/Kotlin） | Health Connect |
| iOS | GDExtension via SwiftGodot | HealthKit |

GDScript 側は `health_bridge.gd` で抽象化し、プラットフォーム差を吸収する。

### GPS / 位置情報

| Platform | 方式 | ツール |
|----------|------|--------|
| Android | 既存プラグイン | PraxisMapper GPS Plugin |
| iOS | カスタム GDExtension | SwiftGodot + Core Location |

ルート記録は GDScript 層で GPS 座標の配列として管理し、距離計算は Haversine 式で行う。

### 地図表示

| アプローチ | 特徴 | 用途 |
|-----------|------|------|
| WebView overlay | 実装が速い、フル機能 | プロトタイプ・通常利用 |
| OpenStreetMap in-engine | Godot と完全統合 | ゲーム世界との融合が必要な場合 |

基本は WebView overlay（Android: godot-webview / iOS: WKWebView wrapper）で Google Maps or OSM を表示。

## テスト

- **フレームワーク**: GdUnit4
- **テスト配置**: `res://tests/` 以下に配置
- **命名**: `test_` prefix（例: `test_player.gd`）
- **CI**: `godot-gdunit-labs/gdUnit4-action@v1` で自動実行

## 重要な注意事項

- `export_presets.cfg` は Git にコミットする（署名情報は除く）
- キーストア、証明書、プロビジョニングプロファイルは Git にコミットしない
- `.tres`（テキスト形式）を `.res`（バイナリ）より優先する（差分が見やすい）
- ファイルリネーム前には必ずコミットする（Godot のリファクタリングは不安定）
- 全ファイル名は snake_case（クロスプラットフォーム互換性）
