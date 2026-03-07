# Claude Code 公式仕様準拠レビュー

**日付**: 2026-02-24
**レビュー対象**: sync-sdd フレームワーク v1.0.3
**参照ドキュメント**: [Claude Code SubAgents](https://code.claude.com/docs/en/sub-agents), [Claude Code Skills](https://code.claude.com/docs/en/skills), [Claude Code Settings](https://code.claude.com/docs/en/settings)

---

## 1. agents/ YAML フロントマター準拠状況

### 公式仕様 (code.claude.com/docs/en/sub-agents)

公式ドキュメントで定義されたフロントマターフィールド:

| フィールド | 必須 | 説明 |
|---|---|---|
| `name` | Yes | 小文字+ハイフンの一意識別子 |
| `description` | Yes | SubAgent の用途説明 |
| `tools` | No | 利用可能ツール (省略時: 全ツール継承) |
| `disallowedTools` | No | 拒否ツール |
| `model` | No | `sonnet`, `opus`, `haiku`, `inherit` (デフォルト: `inherit`) |
| `permissionMode` | No | パーミッションモード |
| `maxTurns` | No | 最大ターン数 |
| `skills` | No | プリロードするスキル |
| `mcpServers` | No | MCP サーバー設定 |
| `hooks` | No | ライフサイクルフック |
| `memory` | No | 永続メモリスコープ |
| `background` | No | バックグラウンド実行設定 |
| `isolation` | No | ワークツリー分離設定 |

### SDD フレームワーク使用フィールド

全 24 エージェントが以下のフィールドのみを使用:
- `name`: 全エージェントで定義済み -- **準拠**
- `description`: 全エージェントで定義済み -- **準拠**
- `model`: 全エージェントで定義済み (`opus` x 4, `sonnet` x 20) -- **準拠**
- `tools`: 全エージェントで定義済み -- **準拠**

**未使用の公式フィールド**: `disallowedTools`, `permissionMode`, `maxTurns`, `skills`, `mcpServers`, `hooks`, `memory`, `background`, `isolation` -- これらは未使用だが、省略可能なフィールドのため問題なし。

### エージェント別詳細

| エージェント | model | tools | 準拠 |
|---|---|---|---|
| sdd-architect | opus | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | OK |
| sdd-auditor-dead-code | opus | Read, Glob, Grep, Write | OK |
| sdd-auditor-design | opus | Read, Glob, Grep, Write | OK |
| sdd-auditor-impl | opus | Read, Glob, Grep, Write | OK |
| sdd-builder | sonnet | Read, Glob, Grep, Write, Edit, Bash | OK |
| sdd-taskgenerator | sonnet | Read, Glob, Grep, Write | OK |
| sdd-inspector-architecture | sonnet | Read, Glob, Grep, Write | OK |
| sdd-inspector-best-practices | sonnet | Read, Glob, Grep, Write | OK |
| sdd-inspector-consistency | sonnet | Read, Glob, Grep, Write | OK |
| sdd-inspector-holistic | sonnet | Read, Glob, Grep, Write | OK |
| sdd-inspector-rulebase | sonnet | Read, Glob, Grep, Write | OK |
| sdd-inspector-testability | sonnet | Read, Glob, Grep, Write | OK |
| sdd-inspector-impl-consistency | sonnet | Read, Glob, Grep, Write | OK |
| sdd-inspector-impl-holistic | sonnet | Read, Glob, Grep, Write | OK |
| sdd-inspector-impl-rulebase | sonnet | Read, Glob, Grep, Write | OK |
| sdd-inspector-interface | sonnet | Read, Glob, Grep, Write | OK |
| sdd-inspector-quality | sonnet | Read, Glob, Grep, Write | OK |
| sdd-inspector-test | sonnet | Read, Glob, Grep, Write, Bash | OK |
| sdd-inspector-e2e | sonnet | Read, Glob, Grep, Write, Bash | OK |
| sdd-inspector-visual | sonnet | Read, Glob, Grep, Write, Bash | OK |
| sdd-inspector-dead-code | sonnet | Read, Glob, Grep, Write | OK |
| sdd-inspector-dead-settings | sonnet | Read, Glob, Grep, Write | OK |
| sdd-inspector-dead-specs | sonnet | Read, Glob, Grep, Write | OK |
| sdd-inspector-dead-tests | sonnet | Read, Glob, Grep, Write | OK |

### ツール名の有効性検証

Claude Code で利用可能な内部ツール名 (公式ドキュメントおよびSDKリファレンスより確認):
`Read`, `Write`, `Edit`, `Bash`, `Glob`, `Grep`, `WebFetch`, `WebSearch`, `Task`, `AskUserQuestion`, `NotebookEdit`, `KillBash`, `TodoWrite`, `ExitPlanMode`, `ListMcpResources`, `ReadMcpResource`

SDD フレームワークで使用しているツール名:
- `Read` -- 有効
- `Write` -- 有効
- `Edit` -- 有効
- `Bash` -- 有効
- `Glob` -- 有効
- `Grep` -- 有効
- `WebFetch` -- 有効
- `WebSearch` -- 有効

**全ツール名が公式仕様に準拠。**

### model 値の有効性検証

公式で有効な値: `sonnet`, `opus`, `haiku`, `inherit`

SDD フレームワークで使用:
- `opus` (T2: Architect, Auditor x 3) -- 有効
- `sonnet` (T3: TaskGenerator, Builder, Inspector x 18) -- 有効

**全 model 値が公式仕様に準拠。**

### 判定: **PASS** -- 全 24 エージェントが公式仕様に完全準拠

---

## 2. Skills フロントマター準拠状況

### 公式仕様 (code.claude.com/docs/en/skills)

| フィールド | 必須 | 説明 |
|---|---|---|
| `name` | No | 表示名 (省略時: ディレクトリ名) |
| `description` | 推奨 | スキルの用途と使用タイミング |
| `argument-hint` | No | オートコンプリートヒント |
| `disable-model-invocation` | No | Claude による自動呼び出し無効化 |
| `user-invocable` | No | ユーザー呼び出し可能か |
| `allowed-tools` | No | 許可ツール |
| `model` | No | モデルオーバーライド |
| `context` | No | `fork` でサブエージェントコンテキスト |
| `agent` | No | `context: fork` 時のエージェントタイプ |
| `hooks` | No | スコープドフック |

### SDD フレームワーク Skills 詳細

| スキル | description | allowed-tools | argument-hint | 準拠 |
|---|---|---|---|---|
| sdd-roadmap | あり | Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | あり | OK |
| sdd-steering | あり | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | あり | OK |
| sdd-status | あり | Read, Glob, Grep | あり | OK |
| sdd-handover | あり | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | あり (空) | OK |
| sdd-knowledge | あり | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | あり | OK |
| sdd-release | あり | Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion | あり | OK |
| sdd-review-self | あり | Task, Bash, Read, Glob, Grep, WebSearch, WebFetch | あり | OK |

### Skills ツール名検証

`Task` -- 有効
`Bash` -- 有効
`Read` -- 有効
`Write` -- 有効
`Edit` -- 有効
`Glob` -- 有効
`Grep` -- 有効
`AskUserQuestion` -- 有効
`WebSearch` -- 有効
`WebFetch` -- 有効

**全ツール名が公式仕様に準拠。**

### `name` フィールド不使用について

全 SDD スキルは `name` フィールドを省略しており、ディレクトリ名 (`sdd-roadmap`, `sdd-steering` 等) が自動的にスキル名として使用される。公式ドキュメントに「省略時はディレクトリ名を使用」と明記されているため、これは正当な使用法。

### 判定: **PASS** -- 全 7 スキルが公式仕様に完全準拠

---

## 3. Task ツール使用: subagent_type パラメータ

### 公式仕様

Task ツールでサブエージェントを指定する際のパラメータ名は `subagent_type`。

### SDD フレームワーク使用箇所

- `CLAUDE.md`: `Task(subagent_type="sdd-architect", prompt="...")` -- **準拠**
- `refs/design.md`: `Task(subagent_type="sdd-architect", run_in_background=true)` -- **準拠**
- `refs/impl.md`: `Task(subagent_type="sdd-taskgenerator", ...)`, `Task(subagent_type="sdd-builder", ...)` -- **準拠**
- `refs/review.md`: `Task(subagent_type=..., run_in_background=true)` -- **準拠**
- `refs/run.md`: `Task(subagent_type="sdd-architect", run_in_background=true)` -- **準拠**
- `sdd-review-self/SKILL.md`: `Task(subagent_type="general-purpose")` -- **準拠**

### 判定: **PASS** -- subagent_type パラメータ使用が公式仕様に準拠

---

## 4. settings.json 準拠状況

### 公式仕様の有効キー (主要)

トップレベル: `permissions`, `env`, `hooks`, `model`, `language`, `sandbox`, `attribution`, `autoUpdatesChannel`, `companyAnnouncements` 等多数

`permissions` 内部: `allow`, `deny`, `ask`, `additionalDirectories`, `defaultMode`, `disableBypassPermissionsMode`

### SDD フレームワーク settings.json の内容

```json
{
  "permissions": {
    "allow": [
      "Bash(cat:*)",
      "Bash(echo:*)"
    ]
  }
}
```

**使用キー分析**:
- `permissions` -- 有効なトップレベルキー
- `permissions.allow` -- 有効な permissions 内キー
- `Bash(cat:*)`, `Bash(echo:*)` -- 有効なパーミッションルール構文 (ツール名 + パターン)

### 判定: **PASS** -- settings.json が公式仕様に完全準拠

---

## 5. install.sh パス準拠状況

### Claude Code が期待するディレクトリ構造

| パス | 目的 |
|---|---|
| `.claude/agents/` | プロジェクトレベルのサブエージェント定義 |
| `.claude/skills/` | プロジェクトレベルのスキル定義 |
| `.claude/CLAUDE.md` | プロジェクトメモリ / 指示 |
| `.claude/settings.json` | プロジェクト設定 |

### install.sh がインストールするパス

| ソース | インストール先 | 準拠 |
|---|---|---|
| `framework/claude/agents/sdd-*.md` | `.claude/agents/sdd-*.md` | OK |
| `framework/claude/skills/sdd-*/` | `.claude/skills/sdd-*/` | OK |
| `framework/claude/CLAUDE.md` | `.claude/CLAUDE.md` (マーカー管理) | OK |
| `framework/claude/settings.json` | `.claude/settings.json` | OK |
| `framework/claude/sdd/settings/rules/` | `.claude/sdd/settings/rules/` | OK (フレームワーク独自) |
| `framework/claude/sdd/settings/templates/` | `.claude/sdd/settings/templates/` | OK (フレームワーク独自) |
| `framework/claude/sdd/settings/profiles/` | `.claude/sdd/settings/profiles/` | OK (フレームワーク独自) |

### CLAUDE.md マーカー管理

install.sh は `<!-- sdd:start -->` / `<!-- sdd:end -->` マーカーでSDD セクションを管理。ユーザーの既存 CLAUDE.md コンテンツを保持しつつ、SDD 指示を追記/更新する。**公式仕様に沿った正当なアプローチ** -- Claude Code は `.claude/CLAUDE.md` の内容を自由形式で読み取るため、マーカー管理は干渉しない。

### 判定: **PASS** -- install.sh のパス構成が公式 Claude Code 構造に完全準拠

---

## 6. モデル選択の適切性

### SDD 3 層アーキテクチャとモデル割り当て

| Tier | ロール | model | 根拠 | 評価 |
|---|---|---|---|---|
| T1 | Lead | (inherit/opus) | ユーザーインタラクション、オーケストレーション、判断 | 適切 |
| T2 | Architect | opus | 設計生成は高度な推論力が必要 | 適切 |
| T2 | Auditor (design) | opus | 複数 Inspector 結果の統合・矛盾解決に高度判断必要 | 適切 |
| T2 | Auditor (impl) | opus | 同上 + SPEC-UPDATE-NEEDED 判定 | 適切 |
| T2 | Auditor (dead-code) | opus | クロスドメイン相関分析に高度判断必要 | 適切 |
| T3 | TaskGenerator | sonnet | タスク分解は構造化作業 | 適切 |
| T3 | Builder | sonnet | TDD 実装は構造化作業 | 適切 |
| T3 | Inspector (全種) | sonnet | 個別観点のレビューは構造化作業 | 適切 |

**コスト最適化の観点**: T2 (Opus) は判断・統合が必要な 4 エージェントのみ。T3 (Sonnet) はパターン化された実行タスク 20 エージェント。**適切な分離**。

### 判定: **PASS** -- モデル選択がロールに対して適切

---

## 7. ツールパーミッション: 最小必要権限

### エージェント別ツール権限分析

| ロール | 必要操作 | 付与ツール | 評価 |
|---|---|---|---|
| **Architect** | ファイル読み書き、設計生成、リサーチ | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | OK: WebSearch/WebFetch は設計リサーチに必要 |
| **Auditor (全種)** | Inspector 出力読み取り、Verdict 書き込み | Read, Glob, Grep, Write | OK: 最小権限 |
| **TaskGenerator** | 設計読み取り、tasks.yaml 生成 | Read, Glob, Grep, Write | OK: 最小権限 |
| **Builder** | コード実装、テスト実行 | Read, Glob, Grep, Write, Edit, Bash | OK: Bash はテスト実行に必要 |
| **Design Inspectors** (全 6) | 設計レビュー、結果書き込み | Read, Glob, Grep, Write | OK: 最小権限 |
| **Impl Inspectors** (4/6) | コードレビュー、結果書き込み | Read, Glob, Grep, Write | OK: 最小権限 |
| **sdd-inspector-test** | テスト実行 | Read, Glob, Grep, Write, Bash | OK: Bash はテスト実行に必要 |
| **sdd-inspector-e2e** | ブラウザ E2E テスト | Read, Glob, Grep, Write, Bash | OK: Bash は playwright-cli 実行に必要 |
| **sdd-inspector-visual** | スクリーンショット撮影・視覚評価 | Read, Glob, Grep, Write, Bash | OK: Bash は playwright-cli 実行に必要 |
| **Dead-code Inspectors** (全 4) | コード解析、結果書き込み | Read, Glob, Grep, Write | OK: 最小権限 |

### 権限の過不足チェック

- **Write が不要な可能性のあるエージェント**: 全 Inspector / Auditor が `Write` を持つのは CPF 出力ファイルを書き込むため。フレームワーク設計上必須。
- **Edit が不要なエージェント**: Edit は Architect (設計ファイル生成時に既存ファイル編集) と Builder (コード編集) のみ。**適切**。
- **WebSearch/WebFetch**: Architect のみ。設計リサーチに必要。sdd-review-self スキルも使用 (公式ドキュメント検証用)。**適切**。
- **Bash**: Builder (テスト実行)、Inspector-test (テスト実行)、Inspector-e2e (playwright-cli)、Inspector-visual (playwright-cli) のみ。**最小限に制限されている**。

### 判定: **PASS** -- 全エージェントが最小必要権限の原則に準拠

---

## 公式仕様準拠テーブル (総括)

| # | 検証項目 | 対象数 | 結果 | 詳細 |
|---|---|---|---|---|
| 1 | agents/ YAML フロントマター | 24 エージェント | **PASS** | name, description, model, tools 全て有効値 |
| 2 | Skills フロントマター | 7 スキル | **PASS** | description, allowed-tools, argument-hint 全て準拠 |
| 3 | Task ツール subagent_type | 6 箇所 | **PASS** | 公式パラメータ名と一致 |
| 4 | settings.json | 1 ファイル | **PASS** | permissions.allow のみ使用、有効キー |
| 5 | install.sh パス | 7 インストール先 | **PASS** | Claude Code 期待構造に一致 |
| 6 | モデル選択 | 24 エージェント | **PASS** | ロール別に適切な opus/sonnet 割り当て |
| 7 | ツールパーミッション | 24 エージェント + 7 スキル | **PASS** | 最小必要権限の原則に準拠 |

---

## Issues Found

### Confirmed OK

- [OK] 全 24 エージェントの name フィールドが小文字+ハイフン形式
- [OK] 全エージェントの description が明確な用途説明を含む
- [OK] model 値は `opus` と `sonnet` のみ (公式有効値)
- [OK] 全ツール名が Claude Code 公式内部ツール名と一致
- [OK] Skills の `allowed-tools` フィールド名が公式仕様と一致
- [OK] `argument-hint` フィールドが公式仕様どおり
- [OK] Skills に `name` フィールド未使用だがディレクトリ名がスキル名として機能 (公式仕様準拠)
- [OK] CLAUDE.md のマーカー管理が既存ユーザーコンテンツを保護
- [OK] install.sh のマイグレーション履歴 (v0.4.0 ~ v0.20.0) が正しくエージェントパスを更新
- [OK] stale ファイル除去ロジックがフレームワークファイルのみ対象 (ユーザーファイル保護)
- [OK] Inspector 数 (6 design + 6 impl + 2 web + 4 dead-code = 18) が CLAUDE.md の記述「6 design + 6 impl inspectors +2 web (web projects), 4 (dead-code)」と一致
- [OK] 総エージェント数 24 (Inspector 18 + Architect 1 + Auditor 3 + Builder 1 + TaskGenerator 1)
- [OK] 総スキル数 7 (CLAUDE.md の "Commands (6)" + sdd-review-self; 注: Commands テーブルは sdd-review-self を含まない -- これはフレームワーク内部用であり、意図的な除外)

### Issues

なし。公式仕様準拠に関する問題は検出されなかった。

---

## 補足: CLAUDE.md "Commands (6)" とスキル数 7 の差異

CLAUDE.md の `### Commands (6)` テーブルには 6 つのユーザー向けコマンドが列挙されている:
1. `/sdd-steering`
2. `/sdd-roadmap`
3. `/sdd-status`
4. `/sdd-handover`
5. `/sdd-knowledge`
6. `/sdd-release`

7 番目のスキル `sdd-review-self` は「SDD framework development (framework-internal use only)」と記載されており、フレームワーク自体の開発用ツールとして意図的にユーザー向けコマンドテーブルから除外されている。これはドキュメント上の不整合ではなく、意図的な設計判断。

---

## Overall Assessment

SDD フレームワーク v1.0.3 は Claude Code 公式仕様に **完全準拠** している。

- **エージェント定義**: 全 24 エージェントが公式 YAML フロントマター仕様に準拠。必須フィールド (name, description) は全て定義済み。model 値 (opus/sonnet) とツール名は全て公式有効値。
- **スキル定義**: 全 7 スキルが公式フロントマター仕様に準拠。description と allowed-tools が正しく定義。
- **Task ツール使用**: subagent_type パラメータが公式仕様どおりに使用。
- **settings.json**: 最小限の設定で公式スキーマに準拠。
- **install.sh**: Claude Code が期待するディレクトリ構造 (`.claude/agents/`, `.claude/skills/`, `.claude/CLAUDE.md`, `.claude/settings.json`) に正確にインストール。
- **モデル選択**: T2 (判断ロール) = Opus、T3 (実行ロール) = Sonnet の分離が適切。
- **ツール権限**: 全エージェントが最小必要権限の原則に従っている。

**新規エージェント (sdd-inspector-visual, sdd-inspector-e2e)**: 両方とも公式仕様に準拠。model: sonnet、tools: Read, Glob, Grep, Write, Bash -- Bash はplaywright-cli 実行に必要で、最小権限として適切。

**sdd-auditor-impl 更新**: フロントマター変更なし (model: opus, tools: Read, Glob, Grep, Write)。コンテンツ更新のみで公式仕様への影響なし。
