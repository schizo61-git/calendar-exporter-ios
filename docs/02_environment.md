# ビルド環境の決定

Windowsマシンのみで開発するため、iOS向けビルド(コンパイル・コード署名・
実機インストール)にはmacOS(Xcode)が必要という制約に対する方針をまとめる。

## 制約

- Swift/SwiftUIのソースコード自体はWindows上で書ける(テキストファイル)。
- iOSターゲットへのコンパイル・リンク・コード署名にはXcode(=macOS)が必須。
  Windows上に非公式のiOS向けSwiftツールチェーンは実用的でない。
- App Store配布はしない。自分のiPhoneへのサイドロードのみが目的。
- 使い捨てアプリのため、コストは無料に抑えたい。

## 決定

1. **XcodeGenで`.xcodeproj`をテキストから生成する**
   - `.xcodeproj`(pbxproj)はバイナリに近い独自形式で、Windows上で手書き
     すると破損しやすい。
   - 代わりに`project.yml`(YAML)でターゲット構成を定義し、ビルド時に
     `xcodegen generate`で`.xcodeproj`を都度生成する。
   - `project.yml`はテキストなのでWindows上でも編集・レビューできる。
   - `.xcodeproj`自体はリポジトリにコミットしない(生成物のため)。

2. **GitHub ActionsのmacOSランナーでビルドする(無料)**
   - GitHub Actionsは**パブリックリポジトリなら無制限無料**でmacOS
     ランナーを使える。
   - GitLab.com(このワークスペースの本来のリモート)の無料枠にはmacOS
     ランナーが無いため、CI用に別途**新規の公開GitHubリポジトリ**を
     作成し、`01_workspace/iphone_study/CalendarExporter/`の中身のみを
     そこに置く(ユーザー承認済み、2026-09-05)。
   - このアプリはAPIキー等の秘密情報を一切扱わないため、公開リポジトリ
     にしてよいと判断した。
   - CIでは`CODE_SIGNING_ALLOWED=NO`でビルドし、`.app`をZIPして
     unsigned `.ipa`としてArtifactに保存する(Apple Developer Program
     への加入は不要)。

3. **Windows上のSideloadlyで無料Apple IDによる署名・実機インストールを行う**
   - [Sideloadly](https://sideloadly.io/)はWindows/macOS対応のツールで、
     unsigned/他人署名済みの`.ipa`を**無料のApple ID**で再署名し、USB
     経由でiPhoneにインストールできる。
   - 無料Apple IDでの署名は**7日間で失効**するため、7日ごとにSideloadly
     で再インストールが必要(有料Apple Developer Programに入れば
     1年間に延長できるが、このプロジェクトでは不要と判断)。
   - 手順の詳細は[03_sideload_install.md](03_sideload_install.md)を参照。

## 結果として得られるワークフロー

```text
Windows: Swiftコード編集・commit・push
   ↓
GitHub Actions (macOS runner, 無料・公開repo):
   xcodegen generate → xcodebuild (CODE_SIGNING_ALLOWED=NO) → unsigned .ipa
   ↓ (Actions Artifactとしてダウンロード)
Windows: Sideloadlyで無料Apple IDにより署名・iPhoneへ実機インストール
   (7日ごとに再インストールが必要)
```

## 却下した選択肢

- **クラウドMacレンタル(MacStadium/MacinCloud等)**: 月額・時間課金の
  追加費用が発生するため、無料を希望する今回の用途には合わない。
- **知人/中古の実機Mac**: 追加費用はほぼ無いが、調達の手間と即応性の
  低さから見送り。今後CI環境で解決できない問題が出た場合の代替案として
  保留する。
