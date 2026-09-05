# Sideloadlyによる実機インストール手順(Windows)

CIが生成したunsigned `.ipa` を、Windows上のSideloadlyで無料Apple IDを使って
署名し、iPhoneにインストールする手順。[02_environment.md](02_environment.md)
で決定したワークフローの最終ステップにあたる。

## 前提

- Windows PCとiPhoneをLightning/USB-Cケーブルで接続できること。
- iTunes、またはApple Mobile Device Support(iTunesに同梱)がインストール
  済みであること。Sideloadlyのインストーラーが自動で要求する。
- Apple ID(無料のもので可。2ファクタ認証が有効なものが必要)。

## 手順

1. GitHub Actionsの該当ワークフロー実行(`build.yml`)のArtifact欄から
   `CalendarExporter-unsigned-ipa` をダウンロードし、`CalendarExporter.ipa`
   を展開する。
2. [Sideloadly](https://sideloadly.io/) をダウンロード・インストールする。
3. iPhoneをUSBでPCに接続し、iPhone側で「このコンピュータを信頼する」を
   選択する。
4. Sideloadlyを起動し、接続したiPhoneが認識されていることを確認する。
5. `.ipa` を選択(ドラッグ&ドロップまたはIPAアイコンをクリックしてファイル
   選択)し、Apple IDのメールアドレスを入力欄に入力する。
6. 「Start」を押すと、Apple IDでのサインインを求められる(2ファクタ認証の
   確認コード入力が必要な場合がある)。
7. Sideloadlyが自動でIPAを無料Apple IDの開発者証明書で再署名し、iPhoneへ
   インストールする。
8. iPhone側で初回起動時に「信頼されていないデベロッパ」の警告が出る場合、
   設定アプリ →「一般」→「VPNとデバイス管理」から該当のApple IDを選択し
   「信頼」をタップする。

## 制約: 7日ごとの再インストールが必要

無料Apple IDで署名したアプリの有効期限は**7日間**。期限が切れると起動できな
くなる。延長したい場合は以下のいずれか:

- 7日以内に同じ手順でSideloadlyから再インストールする(データは保持され
  ない場合があるため、エクスポート自体は都度実行すればよく問題ない)。
- Sideloadlyの「Anisette Server」設定と組み合わせ、期限切れ前に自動再署名
  する仕組みを組む(このMVPではスコープ外)。
- 恒久的に使いたくなった場合は、Apple Developer Program(年額)へ加入して
  署名の有効期間を1年に延ばす([02_environment.md](02_environment.md)で
  却下済みだが、必要になれば再検討)。

## トラブルシューティング

- **iPhoneが認識されない**: iTunes/Apple Mobile Device Supportの再インス
  トール、ケーブル・USBポートの変更を試す。
- **「デベロッパApple IDに無料枠の上限」エラー**: 無料Apple IDは同時に
  インストールできるアプリ数(Bundle ID数)に上限(10個/7日)があるため、
  Bundle IDが枯渇していないか確認する。このMVPは
  `com.schizo61.study.calendarexporter` 固定なので通常は問題にならない。
- **カレンダーのアクセス許可が出ない**: Info.plistの
  `NSCalendarsFullAccessUsageDescription` が正しく反映されているか、
  `xcodegen generate` が最新の `project.yml` から再生成されているかを
  確認する。
