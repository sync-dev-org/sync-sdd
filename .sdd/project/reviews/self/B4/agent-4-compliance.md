# Claude Code 公式仕様準拠レビューレポート

**日付**: 2026-02-24
**レビュー対象**: SDD Framework v1.0.4
**公式ドキュメント参照**: https://code.claude.com/docs/en/sub-agents, https://code.claude.com/docs/en/skills, https://code.claude.com/docs/en/settings

---

## 1. エージェント定義 (`.claude/agents/`) YAML フロントマター準拠

### 1.1 公式仕様

公式ドキュメント（https://code.claude.com/docs/en/sub-agents）によると、サポートされるフロントマターフィールドは以下:

| フィールド | 必須 | 型 | 説明 |
|---|---|---|---|
| `name` | Yes | string | 一意識別子（小文字+ハイフン） |
| `description` | Yes | string | いつ委譲するかの説明 |
| `tools` | No | list | 使用可能ツール（省略時は全ツール継承） |
| `disallowedTools` | No | list | 拒否ツール |
| `model` | No | string | `sonnet`, `opus`, `haiku`, `inherit` |
| `permissionMode` | No | string | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `maxTurns` | No | number | 最大ターン数 |
| `skills` | No | list | プリロードするスキル |
| `mcpServers` | No | object | MCP サーバー設定 |
| `hooks` | No | object | ライフサイクルフック |
| `memory` | No | string | `user`, `project`, `local` |
| `background` | No | boolean | バックグラウンド実行 |
| `isolation` | No | string | `worktree` |

有効なツール名: `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash`, `WebSearch`, `WebFetch`, `Task`, `AskUserQuestion` 等（Claude Code 内部ツール全般）

有効なモデル値: `sonnet`（Claude Sonnet 4.5）, `opus`（Claude Opus 4.6）, `haiku`（Claude Haiku 4.5）, `inherit`

### 1.2 フレームワーク全エージェント一覧と準拠状況

| エージェント | name | description | model | tools | 準拠 |
|---|---|---|---|---|---|
| sdd-architect | `sdd-architect` | OK | `opus` | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | OK |
| sdd-builder | `sdd-builder` | OK | `sonnet` | Read, Glob, Grep, Write, Edit, Bash | OK |
| sdd-taskgenerator | `sdd-taskgenerator` | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-auditor-design | `sdd-auditor-design` | OK | `opus` | Read, Glob, Grep, Write | OK |
| sdd-auditor-impl | `sdd-auditor-impl` | OK | `opus` | Read, Glob, Grep, Write | OK |
| sdd-auditor-dead-code | `sdd-auditor-dead-code` | OK | `opus` | Read, Glob, Grep, Write | OK |
| sdd-inspector-rulebase | `sdd-inspector-rulebase` | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-testability | `sdd-inspector-testability` | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-architecture | `sdd-inspector-architecture` | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-consistency | `sdd-inspector-consistency` | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-best-practices | `sdd-inspector-best-practices` | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-holistic | `sdd-inspector-holistic` | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-impl-rulebase | `sdd-inspector-impl-rulebase` | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-interface | `sdd-inspector-interface` | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-test | `sdd-inspector-test` | OK | `sonnet` | Read, Glob, Grep, Write, Bash | OK |
| sdd-inspector-quality | `sdd-inspector-quality` | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-impl-consistency | `sdd-inspector-impl-consistency` | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-impl-holistic | `sdd-inspector-impl-holistic` | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-e2e | `sdd-inspector-e2e` | OK | `sonnet` | Read, Glob, Grep, Write, Bash | OK |
| sdd-inspector-visual | `sdd-inspector-visual` | OK | `sonnet` | Read, Glob, Grep, Write, Bash | OK |
| sdd-inspector-dead-code | `sdd-inspector-dead-code` | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-dead-settings | `sdd-inspector-dead-settings` | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-dead-specs | `sdd-inspector-dead-specs` | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-dead-tests | `sdd-inspector-dead-tests` | OK | `sonnet` | Read, Glob, Grep, Write | OK |

**結果**: 24エージェント全て準拠。

### 1.3 詳細分析

#### モデル選択の妥当性

| ティア | ロール | 設定モデル | 公式推奨 | 評価 |
|---|---|---|---|---|
| T2 | Architect | `opus` | Opus = 最も高性能、複雑な推論向け | 適切 |
| T2 | Auditor (x3) | `opus` | 複雑な判断・合成が必要 | 適切 |
| T3 | TaskGenerator | `sonnet` | バランス型、大半のエージェント向け | 適切 |
| T3 | Builder | `sonnet` | 実装タスク、バランス型 | 適切 |
| T3 | Inspector (x14) | `sonnet` | レビュー実行、バランス型 | 適切 |

**所見**: ティア階層に沿った適切なモデル配置。Opus は判断力が必要な T2 ロールに、Sonnet は実行力が必要な T3 ロールに割り当てられている。公式ドキュメントの推奨（Opus = 複雑推論、Sonnet = バランス型）と整合。

#### ツール権限の最小原則

| ロール | 付与ツール | 不要ツール有無 | 評価 |
|---|---|---|---|
| Architect | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | なし（設計生成+調査に全て必要） | OK |
| Builder | Read, Glob, Grep, Write, Edit, Bash | なし（TDD実装に全て必要） | OK |
| TaskGenerator | Read, Glob, Grep, Write | なし（読み取り+YAML生成のみ） | OK |
| Auditor (x3) | Read, Glob, Grep, Write | なし（読み取り+verdict出力のみ） | OK |
| Inspector (読み取り系) | Read, Glob, Grep, Write | なし（読み取り+CPF出力のみ） | OK |
| Inspector (test) | Read, Glob, Grep, Write, Bash | なし（テスト実行にBash必要） | OK |
| Inspector (e2e/visual) | Read, Glob, Grep, Write, Bash | なし（playwright-cli実行にBash必要） | OK |

**所見**: 全エージェントが最小権限原則に従っている。特に、Auditor や読み取り専用 Inspector が `Edit` や `Bash` を持たない点は適切。

### 1.4 指摘事項

**[MEDIUM] フロントマターに未使用の公式フィールドが活用されていない**

公式ドキュメントでは `maxTurns`, `permissionMode`, `background`, `hooks` などのフィールドがサポートされている。SDD フレームワークは以下を活用していない:

- `maxTurns`: Inspector/Builder のターン数制限に有用な可能性あり
- `background: true`: CLAUDE.md で「常に `run_in_background: true`」と規定しているが、エージェント定義自体に `background: true` を設定すれば Lead 側の dispatch 時指定が不要になる
- `permissionMode`: Inspector 系は `plan`（読み取り専用）を設定することで追加の安全保証が可能

ただし、これらは改善提案であり準拠違反ではない。省略時はデフォルト値が適用される。

---

## 2. スキル定義 (`.claude/skills/*/SKILL.md`) 準拠

### 2.1 公式仕様

公式ドキュメント（https://code.claude.com/docs/en/skills）によると、サポートされるフロントマターフィールドは:

| フィールド | 必須 | 説明 |
|---|---|---|
| `name` | No | 表示名（省略時はディレクトリ名） |
| `description` | 推奨 | 何をするか、いつ使うか |
| `argument-hint` | No | 引数ヒント（オートコンプリート時表示） |
| `disable-model-invocation` | No | Claude の自動呼び出し禁止 |
| `user-invocable` | No | ユーザーメニュー非表示 |
| `allowed-tools` | No | アクティブ時に許可するツール |
| `model` | No | スキルアクティブ時のモデル |
| `context` | No | `fork` でサブエージェントコンテキスト実行 |
| `agent` | No | `context: fork` 時のサブエージェント型 |
| `hooks` | No | スキルスコープフック |

### 2.2 フレームワーク全スキル一覧と準拠状況

| スキル | description | allowed-tools | argument-hint | 準拠 |
|---|---|---|---|---|
| sdd-roadmap | OK | Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | OK | OK |
| sdd-steering | OK | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | OK | OK |
| sdd-status | OK | Read, Glob, Grep | OK | OK |
| sdd-handover | OK | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | OK (空文字) | OK |
| sdd-knowledge | OK | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | OK | OK |
| sdd-release | OK | Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion | OK | OK |
| sdd-review-self | OK | Task, Bash, Read, Glob, Grep, WebSearch, WebFetch | OK | OK |

**結果**: 7スキル全て準拠。

### 2.3 詳細分析

#### スキル構造

| スキル | SKILL.md | refs/ サブファイル | 評価 |
|---|---|---|---|
| sdd-roadmap | あり（メインルーター） | 6ファイル (crud, run, impl, review, revise, design) | OK（公式の refs パターン準拠） |
| sdd-steering | あり | なし | OK |
| sdd-status | あり | なし | OK |
| sdd-handover | あり | なし | OK |
| sdd-knowledge | あり | なし | OK |
| sdd-release | あり | なし | OK |
| sdd-review-self | あり | なし | OK |

公式ドキュメントの推奨構造: `SKILL.md`（必須エントリポイント）+ オプションの refs/scripts/assets ディレクトリ。sdd-roadmap が refs/ サブディレクトリを使用しており、公式のサポーティングファイルパターンに合致。

#### `$ARGUMENTS` 置換

公式仕様: `$ARGUMENTS`, `$ARGUMENTS[N]`, `$N` が使用可能。SDD フレームワークのスキルは `$ARGUMENTS` を使用しており準拠。

#### `allowed-tools` 検証

公式仕様: `allowed-tools` は「スキルアクティブ時に許可なく使えるツール」を定義。

- sdd-roadmap: `Task` を含む — SubAgent ディスパッチに必要。OK。
- sdd-review-self: `Task` を含む — レビューエージェントディスパッチに必要。OK。
- sdd-status: `Read, Glob, Grep` のみ — 読み取り専用。OK。
- その他: 実行に必要なツールセット。OK。

### 2.4 指摘事項

**[LOW] `name` フィールドの省略**

全スキルのフロントマターに `name` フィールドが記載されていない。公式仕様では「省略時はディレクトリ名を使用」とあるため準拠違反ではないが、明示的に `name` を設定することで意図が明確になる。

**[LOW] `disable-model-invocation` の未設定**

sdd-release など、ユーザーが明示的にトリガーすべきスキルに `disable-model-invocation: true` が設定されていない。Claude が「コードの準備ができたからデプロイしよう」と自動判断するリスクがある。ただし、SDD フレームワークはスラッシュコマンドベースの運用を前提としており、実際のリスクは低い。

---

## 3. Task ツール使用 (`subagent_type` パラメータ)

### 3.1 公式仕様

公式ドキュメントによると、Task ツールは `subagent_type` パラメータで `.claude/agents/` 配下のエージェントを指定して呼び出す。

### 3.2 フレームワーク内の Task 使用パターン

CLAUDE.md での記述:
```
Task(subagent_type="sdd-architect", prompt="...")
```

refs/design.md での記述:
```
Task(subagent_type="sdd-architect", run_in_background=true)
```

refs/impl.md での記述:
```
Task(subagent_type="sdd-taskgenerator", run_in_background=true)
Task(subagent_type="sdd-builder", run_in_background=true)
```

sdd-review-self での記述:
```
Task(subagent_type="general-purpose")
```

### 3.3 準拠状況

| 使用箇所 | subagent_type 値 | エージェント存在 | 評価 |
|---|---|---|---|
| design.md | `sdd-architect` | OK | OK |
| impl.md | `sdd-taskgenerator` | OK | OK |
| impl.md | `sdd-builder` | OK | OK |
| review.md | `sdd-inspector-*` (14種) | OK | OK |
| review.md | `sdd-auditor-*` (3種) | OK | OK |
| sdd-review-self | `general-purpose` | ビルトイン | OK |

**結果**: 全ての `subagent_type` 参照が有効なエージェント定義に対応。

### 3.4 指摘事項

**なし** — 全て準拠。

---

## 4. settings.json 準拠

### 4.1 公式仕様

公式ドキュメント（https://code.claude.com/docs/en/settings）による有効なトップレベルキー:
`$schema`, `permissions`, `env`, `hooks`, `model`, `attribution`, `sandbox`, `companyAnnouncements`, `availableModels`, `respectGitignore`, `outputStyle`, `statusLine`, `fileSuggestion`, `language`, `autoUpdatesChannel`, `enabledPlugins`, `extraKnownMarketplaces`, 他多数。

`permissions` オブジェクト内の有効キー: `allow`, `ask`, `deny`, `additionalDirectories`, `defaultMode`, `disableBypassPermissionsMode`

### 4.2 フレームワークの settings.json

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

### 4.3 準拠状況

| 検証項目 | 結果 | 詳細 |
|---|---|---|
| トップレベルキー | OK | `permissions` のみ — 有効なキー |
| permissions 構造 | OK | `allow` 配列 — 有効 |
| ツールパターン構文 | OK | `Bash(pattern)` — 公式構文準拠 |
| パターン値 | **要確認** | `Bash(cat:*)` と `Bash(echo:*)` — コロン区切りは非標準（後述） |

### 4.4 指摘事項

**[MEDIUM] `Bash(cat:*)` / `Bash(echo:*)` パターン構文の妥当性**

公式ドキュメントの Bash パーミッションパターン例:
- `Bash(npm run lint)` — コマンド完全一致
- `Bash(npm run test *)` — ワイルドカード
- `Bash(git diff *)` — コマンド+引数パターン

SDD フレームワークでは `Bash(cat:*)` と `Bash(echo:*)` を使用。コロン(`:`)区切りのパターンは公式ドキュメントに明示的な例がない。Claude Code のパーミッションシステムが内部的にこのパターンをサポートしている可能性はあるが、公式ドキュメントのスタイルとは異なる。`Bash(cat *)` や `Bash(echo *)` が公式ドキュメントに近い形式。

ただし、SDD フレームワークの CLAUDE.md 自体（Execution Conventions）では「`command` 引数は実行可能ファイルで始めること」と規定しており、`cat` / `echo` の使用自体は Bash ツールの `description` パラメータでのコンテキスト提供を推奨しつつも、パーミッション設定としては必要。

---

## 5. install.sh パス準拠

### 5.1 公式パス期待値

Claude Code の公式パス:
- `.claude/agents/` — プロジェクトサブエージェント
- `.claude/skills/` — プロジェクトスキル
- `.claude/CLAUDE.md` — プロジェクトメモリ
- `.claude/settings.json` — プロジェクト設定
- `~/.claude/agents/` — ユーザーレベルエージェント
- `~/.claude/skills/` — ユーザーレベルスキル

### 5.2 install.sh のインストール先

| ソース | インストール先 | 公式パス準拠 |
|---|---|---|
| `framework/claude/skills/` | `.claude/skills/` | OK |
| `framework/claude/agents/` | `.claude/agents/` | OK |
| `framework/claude/CLAUDE.md` | `.claude/CLAUDE.md` | OK |
| `framework/claude/settings.json` | `.claude/settings.json` | OK |
| `framework/claude/sdd/settings/rules/` | `.claude/sdd/settings/rules/` | OK（カスタムデータ） |
| `framework/claude/sdd/settings/templates/` | `.claude/sdd/settings/templates/` | OK（カスタムデータ） |
| `framework/claude/sdd/settings/profiles/` | `.claude/sdd/settings/profiles/` | OK（カスタムデータ） |

**結果**: 全パスが Claude Code の公式ディレクトリ構造に準拠。`.claude/sdd/` 配下はフレームワーク固有のデータ領域であり、Claude Code の機能とは干渉しない。

### 5.3 マーカーベース CLAUDE.md 管理

install.sh は `<!-- sdd:start -->` / `<!-- sdd:end -->` マーカーを使用して `.claude/CLAUDE.md` 内の SDD セクションを管理。ユーザーの既存コンテンツを保持しつつフレームワーク部分のみ更新する仕組み。

**評価**: 適切。公式ドキュメントでは `.claude/CLAUDE.md` の内容構造について制約を設けていないため、マーカーベースの管理は安全。

### 5.4 マイグレーション

install.sh には以下のバージョンマイグレーションが含まれる:
- v0.4.0: `.kiro/` → `.claude/sdd/` 移行
- v0.7.0: sdd-coordinator 削除（3ティアアーキテクチャ）
- v0.9.0: handover ファイルリネーム
- v0.10.0: spec.json → spec.yaml 変換
- v0.15.0: commands → skills ディレクトリ移行
- v0.18.0: agents → sdd/settings/agents 移行
- v0.20.0: sdd/settings/agents → .claude/agents 移行（公式パスに復帰）

**評価**: v0.20.0 で `.claude/agents/` に復帰しており、最終的に公式パスに準拠。

### 5.5 指摘事項

**なし** — 全て準拠。

---

## 6. CLAUDE.md 内容分析

### 6.1 SubAgent アーキテクチャ記述

CLAUDE.md は以下を正しく記述:
- `Task` ツール + `subagent_type` パラメータによる SubAgent ディスパッチ
- `.claude/agents/` 配下の YAML フロントマター定義
- `run_in_background: true` の必須化

**評価**: 公式の SubAgent 機能を正しく活用している。

### 6.2 スキル呼び出し記述

CLAUDE.md は `/sdd-roadmap`, `/sdd-steering` 等をスラッシュコマンドとして記述。公式仕様では `.claude/skills/*/SKILL.md` がスラッシュコマンドとして自動登録される。

**評価**: 正しい動作を期待できる。

### 6.3 指摘事項

**[LOW] SubAgent のネスト制約への対応**

公式ドキュメントに「Subagents cannot spawn other subagents」という制約が明記されている。SDD フレームワークでは Lead（T1）が全ての SubAgent をディスパッチし、SubAgent 同士が互いを呼び出すことはない。この設計は公式制約に完全に準拠している。ただし、CLAUDE.md に「SubAgent は他の SubAgent をスポーンできない」という制約を明記すると、将来の設計変更時に公式制約への注意喚起になる。

---

## 7. 公式仕様準拠サマリーテーブル

| # | 検証項目 | ステータス | 詳細 |
|---|---|---|---|
| 1 | agents/ YAML フロントマター: `name` フィールド | OK | 全24エージェントに存在 |
| 2 | agents/ YAML フロントマター: `description` フィールド | OK | 全24エージェントに存在 |
| 3 | agents/ YAML フロントマター: `model` 値 | OK | `opus` / `sonnet` のみ使用 — 有効値 |
| 4 | agents/ YAML フロントマター: `tools` 値 | OK | 全ツール名が公式内部ツールに一致 |
| 5 | agents/ YAML フロントマター: 不正フィールド | OK | 全て公式サポートフィールドのみ |
| 6 | skills/ SKILL.md: `description` フィールド | OK | 全7スキルに存在 |
| 7 | skills/ SKILL.md: `allowed-tools` フィールド | OK | 有効なツール名のみ |
| 8 | skills/ SKILL.md: `argument-hint` フィールド | OK | 引数ヒント適切 |
| 9 | skills/ SKILL.md: 不正フィールド | OK | 全て公式サポートフィールドのみ |
| 10 | skills/ ディレクトリ構造 | OK | `{name}/SKILL.md` + optional refs/ |
| 11 | Task ツール: `subagent_type` 参照 | OK | 全参照が有効なエージェントに対応 |
| 12 | settings.json: トップレベルキー | OK | `permissions` のみ — 有効 |
| 13 | settings.json: permissions 構造 | OK | `allow` 配列 — 有効 |
| 14 | settings.json: パーミッションパターン構文 | **要確認** | `Bash(cat:*)` のコロン構文が公式例と異なる |
| 15 | install.sh: エージェントインストール先 | OK | `.claude/agents/` — 公式パス |
| 16 | install.sh: スキルインストール先 | OK | `.claude/skills/` — 公式パス |
| 17 | install.sh: CLAUDE.md インストール先 | OK | `.claude/CLAUDE.md` — 公式パス |
| 18 | install.sh: settings.json インストール先 | OK | `.claude/settings.json` — 公式パス |
| 19 | モデル選択: T2 ロール | OK | Opus — 複雑推論に適切 |
| 20 | モデル選択: T3 ロール | OK | Sonnet — バランス型に適切 |
| 21 | ツール権限: 最小原則 | OK | 全エージェントが必要最小限 |
| 22 | SubAgent ネスト制約 | OK | Lead のみが dispatch、ネスト発生なし |
| 23 | CLAUDE.md マーカー管理 | OK | ユーザーコンテンツ非破壊 |
| 24 | `$ARGUMENTS` 置換 | OK | 公式パターン準拠 |

---

## 8. 指摘事項一覧

### CRITICAL (0件)

なし。

### HIGH (0件)

なし。

### MEDIUM (2件)

**M1: settings.json の `Bash(cat:*)` / `Bash(echo:*)` パターン構文**
- **場所**: `framework/claude/settings.json`
- **説明**: コロン(`:`)区切りのパーミッションパターンは公式ドキュメントの例に存在しない。`Bash(cat *)` / `Bash(echo *)` が公式スタイルに近い。動作に影響がないか実環境での検証を推奨。
- **推奨**: パターン構文を `Bash(cat *)` / `Bash(echo *)` に変更するか、動作を検証

**M2: `background: true` フロントマターフィールドの未活用**
- **場所**: 全エージェント定義
- **説明**: CLAUDE.md で「SubAgent dispatch は常に `run_in_background: true`」と規定しているが、公式仕様では `background: true` フロントマターフィールドで同等の効果を得られる。エージェント定義に設定すれば、Lead 側のディスパッチミスを防止できる。
- **推奨**: 全エージェント定義に `background: true` の追加を検討

### LOW (3件)

**L1: スキルの `name` フィールド省略**
- **場所**: 全7スキルの SKILL.md フロントマター
- **説明**: 公式仕様では省略時にディレクトリ名が使用されるため機能上の問題なし。明示的な設定は保守性向上に寄与。

**L2: `disable-model-invocation` の未設定**
- **場所**: sdd-release, sdd-handover 等のユーザートリガー型スキル
- **説明**: Claude が自動的にこれらのスキルを呼び出すリスクを排除するために `disable-model-invocation: true` の設定を推奨。実際のリスクは低い。

**L3: SubAgent ネスト制約の CLAUDE.md 明記**
- **場所**: `framework/claude/CLAUDE.md` SubAgent Platform Constraints セクション
- **説明**: 公式制約「Subagents cannot spawn other subagents」を明記すると将来の設計変更への注意喚起になる。現在の設計は制約に準拠しているが、明示的な記述がない。

---

## 9. 全体評価

### 準拠レベル: **HIGH（高準拠）**

SDD フレームワーク v1.0.4 は Claude Code 公式仕様にほぼ完全に準拠している。

**強み**:
- 全24エージェント定義が公式 YAML フロントマター仕様に完全準拠
- 全7スキル定義が公式 SKILL.md フォーマットに準拠
- install.sh のパス構造が全て公式ディレクトリ規約に一致
- モデル選択がティア階層と公式推奨に整合
- ツール権限が最小原則に従い、全ツール名が有効
- Task ツールの subagent_type 参照が全て有効
- SubAgent のネスト制約に設計レベルで準拠

**改善ポイント**:
- settings.json のパーミッションパターン構文の検証（MEDIUM）
- `background: true` フロントマターの活用検討（MEDIUM）
- 軽微なフロントマターフィールドの明示化（LOW x3）

**リスク**: CRITICAL / HIGH 指摘なし。MEDIUM 2件はいずれも動作に直接影響する可能性は低く、検証ベースでの対応が適切。
