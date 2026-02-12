# クリエイティブ案件管理 ドメインパターン集

## Metadata

| Field | Value |
|-------|-------|
| Category | integration |
| Keywords | htmx, auth, OAuth, logging, project, customer, Kanban, 商流, supply-chain, FastAPI |
| Last Verified | 2025-05-01 |
| Source | Extracted from spec research files |

## Overview

**クリエイティブ案件管理システムの実装ドメイン知識**

FastAPI + htmx + SQLite 構成のクリエイティブ企業向け案件管理システムにおける、各モジュール（app-foundation, auth, logging, project, customer）の設計判断と実装パターンを集約。

## Quick Reference

### モジュール別キーパターン

| モジュール | パターン | 要点 |
|-----------|---------|------|
| app-foundation | htmx パーシャルレンダリング | `HX-Request` ヘッダーでパーシャル/フル切替 |
| app-foundation | テンプレート構成 | 各モジュール内配置 + `ChoiceLoader` 統合 |
| app-foundation | DB セッション管理 | FastAPI `Depends` + generator(`yield`) |
| app-foundation | プラグイン依存検証 | 宣言的依存リスト + 起動時バリデーション |
| auth | OAuth ライブラリ | Authlib（Starlette統合 → FastAPI直接利用可） |
| auth | Open Redirect 防止 | 相対パスのみ許可、`//`・絶対URL・パストラバーサル拒否 |
| auth | OAuth state 管理 | OAuthState テーブルに一時保存 + 期限切れクリーンアップ |
| logging | ファイルログ | RotatingFileHandler (10MB, 5世代) |
| project | Kanban 通信 | Sortable.js `onEnd` → htmx `hx-patch` |
| project | タグ管理 | `get_or_create` + `trim` + lowercase 正規化 |
| customer | 商流 tier | 0=直接発注元, 1+=上流顧客, ギャップ許容 |

## Key Points

### app-foundation

#### htmx パーシャルレンダリング
- `HX-Request` ヘッダーの有無でパーシャル/フルページを切り替え
- ブラウザリフレッシュ問題: htmx なしのリクエストではフルレイアウトで返却必須
- キャッシュ分離: `Vary: HX-Request` ヘッダーを付与
- テンプレートは `base.html` + `partials/` 構成

#### テンプレートディレクトリ構成
- 各モジュール内にテンプレートを配置し、Jinja2 Loader で統合
- プラグイン無効時にテンプレートも読み込まれない（モジュール凝集度）
- `ChoiceLoader` で複数のテンプレートディレクトリを統合

#### DB セッション管理
- FastAPI `Depends` + generator（`yield`）パターンを採用
- テスト時にオーバーライド容易、明示的なライフサイクル
- 各ルートで明示的に `Depends` 宣言が必要

#### プラグイン依存検証
- 宣言的依存リスト + 起動時バリデーション
- プラグイン数が少ない（最大11）ため、トポロジカルソートは不採用
- 循環依存はエラーで通知（自動解決しない）
- 各プラグインは `__init__.py` で `register(app, engine)` を公開

### auth

#### Authlib 選定理由
- Starlette 統合が FastAPI と直接利用可能（FastAPI は Starlette ベース）
- `oauth.register()` で Google を OpenID Configuration URL 経由で設定
- `authorize_redirect()` / `authorize_access_token()` で OAuth フロー実行
- SessionMiddleware が前提（app-foundation で設定済み）

#### Open Redirect 防止パターン
- URL デコード後に検証
- 相対パス（`/` で始まる）のみ許可
- 拒否対象: スキーム相対 URL（`//`）、絶対 URL、パストラバーサル（`/../`）
- 不正な URL はダッシュボードにリダイレクト

#### OAuth state の SQLite 一時保存
- OAuthState テーブルに state + code_verifier を一時保存
- コールバック時に検証・削除
- 期限切れ state の定期クリーンアップが必要（起動時または定期タスク）

### logging

#### RotatingFileHandler 設定
- `logging.handlers.RotatingFileHandler` を使用
- `maxBytes=10*1024*1024` (10MB)、`backupCount=5`（5世代保持）
- settings.py に `log_file: str | None = None` を追加し、環境変数から取得

#### 汎用 + 固有メソッド共存パターン
- 汎用メソッド: `log_resource_created(resource_type, ...)` — 将来のモジュールが使用
- 固有メソッド: `log_group_created(...)` — 既存互換として維持
- 固有メソッドは内部で汎用メソッドを呼び出す形に統一可能

### project

#### Kanban 通信パターン
- Sortable.js `onEnd` イベント → htmx `hx-patch` でステータス更新を送信
- JS はライブラリ初期化のみ（steering/tech.md 方針準拠）
- Sortable.js の `onEnd` で `htmx.ajax()` を呼び出す形式

#### タグ管理
- `get_or_create` パターン: タグ名の完全一致で既存タグ再利用、なければ新規作成
- タグ名正規化: `trim` + 小文字化（lowercase）で表記揺れを防止
- Tag はグローバルマスタ（owner_group_id なし）

#### ステータス履歴
- `ProjectStatusHistory` テーブルでステータス遷移のみ記録
- 全フィールド変更の履歴化は不要（ステータス変更のみで十分）

#### アカウントマネージャー制約
- AM は `manager` 以上の権限を持つユーザーに限定
- `AccessLevelService.get_user_access_level()` で検証
- AM 未設定は許容（「未設定」表示）

### customer

#### 商流 tier モデル
- tier 値で階層を表現: 0=直接発注元/請求先、1以上=上流顧客
- 同一顧客が異なる案件で異なる tier に入る可能性あり（フラット顧客マスタ）
- tier 値に連番制約なし（0, 2, 3 は許容）、ギャップは参照情報として有効
- 同一案件内で同一顧客の複数 tier 配置は禁止

#### 支払サイト転記
- **新規 tier0 設定時**: 顧客の `default_payment_terms` → 案件の `payment_terms` に自動転記
- **tier0 差し替え時**: 案件の `payment_terms` は保持、新旧値の差異を警告表示
- 警告はフラッシュメッセージ（操作をブロックしない）
- `SupplyChainService.set_tier0()` で転記ロジックを実装

#### 顧客スコープ
- 顧客はグローバルマスタ（owner_group_id あり、ただし直接管理ではなく案件経由の間接判定も必要）
- `corporate` 以上: 全顧客アクセス可
- `executive`: 自社の全顧客（company_id ベース）
- `manager` 以下: 自グループスコープ内の顧客（owner_group_id ベース）

#### Cross-spec カスケード
- project 削除 → `ProjectSupplyChain` は DB 外部キー制約 `ON DELETE CASCADE` で自動削除
- サービス間呼び出し不要（循環依存を回避）
- トランザクション整合性は DB レベルで保証

#### 顧客名重複
- 重複は警告表示するが作成は許可
- 同名の異なる法人が存在する可能性があるため、一意制約は設けない

## Common Gotchas

| Gotcha | Impact | Mitigation |
|--------|--------|------------|
| htmx なしのブラウザリフレッシュ | パーシャルHTMLのみ返却されレイアウト崩壊 | `HX-Request` チェックでフル/パーシャル切替 |
| OAuth state 期限切れ | 認証フロー失敗 | 定期クリーンアップ（起動時 or 定期タスク） |
| タグ名の表記揺れ | 同一タグが重複作成される | `trim` + lowercase 正規化 |
| tier0 変更時の支払サイト不整合 | 案件の支払サイトが旧顧客のまま残る | 差し替え時に警告フラッシュメッセージ表示 |

## Sources

- Spec research files (app-foundation, auth, logging, project, customer) — Maneuver プロジェクトの各 spec 実装時の調査結果を集約
