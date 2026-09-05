# Calendar Exporter (iPhone学習用)

iPhone標準カレンダーのイベントをCSV/JSONへ一括エクスポートするための、
サイドロード専用アプリ。App Store配布は行わない。

- 仕様: [docs/01_spec.md](docs/01_spec.md)
- ビルド環境の決定(なぜGitHub Actions + Sideloadlyなのか): [docs/02_environment.md](docs/02_environment.md)
- 実機へのインストール手順: [docs/03_sideload_install.md](docs/03_sideload_install.md)

## 現在の状態

Phase 1(権限取得→カレンダー一覧→選択→期間指定→イベント取得→CSV出力→
ファイル保存)を実装し、実機での動作を確認済み(2026-09-05)。JSON出力・
Alarm詳細・RecurrenceRule詳細はPhase 2で対応予定(未着手)。

## リポジトリ構成

このディレクトリ(`01_workspace/iphone_study/CalendarExporter/`)は、
CI(GitHub Actions macOSランナー)を無料で使うため、本ワークスペースの
GitLabリポジトリとは別に、専用の公開GitHubリポジトリへミラーしている。
理由の詳細は[docs/02_environment.md](docs/02_environment.md)を参照。

- `project.yml`: XcodeGen定義。`.xcodeproj`はここから生成する生成物なので
  コミットしない。
- `CalendarExporter/`: Swiftソース一式。
- `.github/workflows/build.yml`: push時にunsigned `.ipa`をビルドし
  Artifactとして保存するCI。
