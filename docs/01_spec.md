# iPhone Calendar Exporter MVP仕様

## 1. 目的

iPhoneのApple標準カレンダーに保存されているイベントを、ファイルとして一括エクスポートする。

主対象：

- 「このiPhone内」のローカルカレンダー
- 必要に応じてiCloud / Google等のカレンダー

App Store公開は目的としない。
自分のiPhoneにサイドロードして使用する。

---

## 2. 技術

- Swift
- SwiftUI
- EventKit
- 外部ライブラリなし
- ネットワーク通信なし
- Google API等は使用しない

Deployment Target：

iOS 17以上

---

## 3. 基本機能

アプリ起動後、

1. カレンダーへのFull Accessを要求
2. iPhoneに登録されているカレンダー一覧を表示
3. エクスポート対象カレンダーを選択
4. 対象期間を指定
5. イベント件数を取得
6. CSVまたはJSONへ変換
7. iOS標準のファイル保存画面を表示
8. 「このiPhone内」またはiCloud Drive等へ保存

コピー元カレンダーには一切変更を加えない。

---

## 4. UI

```text
Calendar Exporter

対象カレンダー
[ このiPhone内 / カレンダー ▼ ]

期間
[ 2000/01/01 ]
～
[ 2040/12/31 ]

[ イベントを検索 ]

------------------

394件見つかりました

出力形式

○ CSV
○ JSON

[ エクスポート ]

------------------

完了
394件を書き出しました
```

---

## 5. カレンダー表示

カレンダー名だけではなく、

```text
Source名 / Calendar名
```

で表示する。

例：

```text
このiPhone内 / カレンダー
Google / 個人
Google / 会社
iCloud / Calendar
```

---

## 6. イベント取得

`EKEventStore`

と

`predicateForEvents(withStart:end:calendars:)`

を使用する。

指定期間の全イベントを取得する。

大量イベントを想定し、UIスレッドを長時間ブロックしないこと。

取得後は開始日時順に並べる。

---

## 7. CSV形式

文字コード：

UTF-8

可能ならExcel互換性のためUTF-8 BOM付きも検討する。

ヘッダー：

```csv
calendar_source,
calendar_name,
title,
start_date,
end_date,
is_all_day,
location,
notes,
url,
time_zone,
event_identifier,
calendar_item_external_identifier,
is_detached
```

実際のCSVでは1行のヘッダーとして出力する。

日時形式：

ISO 8601

例：

```text
2026-09-03T10:00:00+09:00
```

終日予定についてもstart/endを出力し、

```text
is_all_day=true
```

とする。

CSV内の

- カンマ
- ダブルクォート
- 改行

はRFC 4180に準じて適切にエスケープする。

---

## 8. JSON形式

JSONはイベント配列とする。

例：

```json
{
  "exportedAt": "2026-09-03T08:00:00+09:00",
  "calendar": {
    "source": "このiPhone内",
    "name": "カレンダー"
  },
  "range": {
    "start": "2000-01-01T00:00:00+09:00",
    "end": "2040-12-31T23:59:59+09:00"
  },
  "events": [
    {
      "title": "美容院",
      "startDate": "2026-09-10T10:00:00+09:00",
      "endDate": "2026-09-10T11:00:00+09:00",
      "isAllDay": false,
      "location": "梅田",
      "notes": null,
      "url": null,
      "timeZone": "Asia/Tokyo"
    }
  ]
}
```

---

## 9. JSONで追加保存する情報

取得可能な範囲で以下を保存する。

- title
- startDate
- endDate
- isAllDay
- location
- structuredLocation
- notes
- URL
- timeZone
- availability
- eventIdentifier
- calendarItemIdentifier
- calendarItemExternalIdentifier
- creationDate
- lastModifiedDate
- hasAttendees
- isDetached
- alarms
- recurrenceRules

値を取得できない場合はnullとする。

---

## 10. Alarm

アラームはJSONのみ詳細保存する。

例：

```json
"alarms": [
  {
    "relativeOffset": -600,
    "absoluteDate": null
  }
]
```

CSVでは必要なら、

```text
alarm_count
```

程度でよい。

---

## 11. 繰り返しイベント

MVPでは**取得されたOccurrenceをそのまま出力してよい**。

例えば毎週月曜の予定が検索期間内に52回存在する場合、

52行としてCSVに出力されても構わない。

これは「バックアップ／データ抽出」を目的としているためである。

ただしJSONには可能であれば

```text
recurrenceRules
calendarItemExternalIdentifier
isDetached
```

を保存する。

これにより将来的にシリーズ単位へ再構築できる余地を残す。

---

## 12. ファイル保存

iOS標準のファイル保存UIを使用する。

保存先はユーザーが選択できるようにする。

例：

```text
このiPhone内
iCloud Drive
Downloads
```

デフォルトファイル名：

CSV：

```text
CalendarExport_20260903.csv
```

JSON：

```text
CalendarExport_20260903.json
```

---

## 13. 安全性

このアプリはカレンダーに対する書き込み処理を持たない。

禁止：

```swift
eventStore.save(...)
eventStore.remove(...)
```

EventKitは読み取り専用用途として使用する。

元カレンダーを変更するコードを実装しない。

---

## 14. プライバシー

以下を禁止する。

- HTTP通信
- Analytics
- Firebase
- 外部サーバー
- Google API
- データアップロード

すべてiPhone内で処理する。

---

## 15. 完了条件

以下を満たせばMVP完成。

- iPhoneで起動する
- Calendar Full Accessを取得できる
- ローカルカレンダーが表示される
- カレンダーを選択できる
- 開始日・終了日を指定できる
- 全イベントを取得できる
- 件数を表示できる
- CSVを書き出せる
- JSONを書き出せる
- iPhoneの「ファイル」へ保存できる
- コピー元カレンダーを一切変更しない
- ネットワーク通信しない

---

## 16. 実装優先順位

Phase 1：

```text
権限取得
↓
カレンダー一覧
↓
カレンダー選択
↓
期間指定
↓
イベント取得
↓
CSV出力
↓
ファイル保存
```

Phase 2：

```text
JSON出力
↓
Alarm
↓
RecurrenceRule詳細
↓
エクスポート結果表示
```

ICS出力はMVPには含めない。
