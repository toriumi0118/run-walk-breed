# Run Walk Breed

ランナー・ウォーカー向けモバイルゲームアプリ（iOS / Android）。

実際の歩数・走行距離・ルートを使ってロボット風ペットを育成し、他のユーザーと1対1のオートバトルで対戦する。

## コンセプト

- **歩いて育てる** — 日々の歩数や走行距離がペットの成長に直結
- **スキルを選んで戦わせる** — 育成で習得したスキルを装備し、バトルはオート進行
- **ルートを記録する** — GPSで走行ルートを記録・可視化

## ゲームシステム

| 要素 | 概要 |
|------|------|
| 育成 | 歩数・距離 → 経験値 → レベルアップ → ステータス成長 |
| スキル | レベルに応じて習得、最大4つを装備してバトルに臨む |
| バトル | 1v1オートファイト。パラメータとスキル構成で勝敗が決まる |
| ペットタイプ | Runner（素早さ型）/ Walker（バランス型）/ Sprinter（攻撃型） |

## 技術スタック

| 項目 | 技術 |
|------|------|
| ゲームエンジン | Godot 4.x（GDScript） |
| プラットフォーム | iOS / Android |
| CI/CD | GitHub Actions |
| ヘルスケア連携 | HealthKit (iOS) / Health Connect (Android) |
| GPS | Core Location (iOS) / PraxisMapper GPS Plugin (Android) |
| 地図 | WebView overlay + OpenStreetMap / Google Maps |

## プロジェクト構成

```
src/
├── autoload/       # シングルトン（GameManager, AudioManager, DataManager）
├── models/         # データモデル（PetData, SkillData, PetFactory, SkillDatabase）
├── systems/        # ゲームロジック（BattleEngine, NurtureSystem, SaveManager）
├── scenes/         # シーン＆スクリプト
│   ├── ui/         #   メニュー、ホーム、スキル編成
│   ├── pet/        #   ペット表示
│   ├── battle/     #   バトル画面
│   └── map/        #   地図・ルート表示
├── native/         # ネイティブブリッジ（health, gps, map）
└── utils/          # 定数、列挙型
```

## 開発

```bash
# Godot エディタで開く
godot project.godot

# テスト実行（GdUnit4）
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add "res://tests"

# エクスポート
godot --headless --export-release "Android" build/android/run-walk-breed.apk
godot --headless --export-release "iOS" build/ios/run-walk-breed.ipa
```

## CI/CD

| ワークフロー | トリガー | 内容 |
|-------------|---------|------|
| `test.yml` | push / PR to main | GdUnit4 テスト実行 |
| `android-build.yml` | タグ `v*` | Android APK ビルド |
| `ios-build.yml` | タグ `v*` | iOS IPA ビルド |
| `release.yml` | タグ `v*` | テスト → ビルド → GitHub Release |

## ロードマップ

詳細は [docs/ROADMAP.md](docs/ROADMAP.md) を参照。

| Phase | 内容 | 状態 |
|-------|------|------|
| 0 | 基盤構築（プロジェクト初期化、CI/CD） | 完了 |
| 1 | コアゲームループ（ペット、育成、スキル、オートバトル） | 完了 |
| 2 | ネイティブ連携（ヘルスケア、GPS、地図） | 未着手 |
| 3 | マルチプレイ / 対戦 | 未着手 |
| 4 | 仕上げ・ストア公開 | 未着手 |
| Asset | アセット制作（グラフィック、UI、エフェクト、サウンド） | 未着手 |

## ライセンス

TBD
