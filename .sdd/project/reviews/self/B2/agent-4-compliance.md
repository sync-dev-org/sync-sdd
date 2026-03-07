# Claude Code 公式ドキュメント準拠レビュー

**レビュー日**: 2026-02-24
**対象**: sync-sdd フレームワーク v1.0.0
**レビュアー**: Agent-4 (Compliance Inspector)
**公式ドキュメント参照**:
- [Create custom subagents](https://code.claude.com/docs/en/sub-agents)
- [Extend Claude with skills](https://code.claude.com/docs/en/skills)
- [Settings](https://code.claude.com/docs/en/settings)
- [How Claude Code works](https://code.claude.com/docs/en/how-claude-code-works)

---

## 1. エージェント定義 (`.claude/agents/sdd-*.md`) YAML Frontmatter 準拠

### 公式仕様

公式ドキュメントによると、SubAgent の YAML frontmatter で使用可能なフィールドは以下の通り:

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `name` | **Yes** | 小文字とハイフンのみの一意識別子 |
| `description` | **Yes** | Claude がタスクを委任すべきタイミングの説明 |
| `tools` | No | 利用可能なツール。省略時は親のツールを継承 |
| `disallowedTools` | No | 拒否するツール |
| `model` | No | `sonnet`, `opus`, `haiku`, `inherit` (デフォルト: `inherit`) |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `maxTurns` | No | 最大エージェントターン数 |
| `skills` | No | 起動時にロードするスキル |
| `mcpServers` | No | 利用可能な MCP サーバー |
| `hooks` | No | ライフサイクルフック |
| `memory` | No | `user`, `project`, `local` |
| `background` | No | バックグラウンド実行フラグ |
| `isolation` | No | `worktree` でワークツリー分離 |

### フレームワークのエージェント一覧と準拠状況

| エージェント | name | description | model | tools | 準拠 |
|-------------|------|-------------|-------|-------|------|
| sdd-architect | OK | OK | `opus` | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | OK |
| sdd-auditor-design | OK | OK | `opus` | Read, Glob, Grep, Write | OK |
| sdd-auditor-impl | OK | OK | `opus` | Read, Glob, Grep, Write | OK |
| sdd-auditor-dead-code | OK | OK | `opus` | Read, Glob, Grep, Write | OK |
| sdd-builder | OK | OK | `sonnet` | Read, Glob, Grep, Write, Edit, Bash | OK |
| sdd-taskgenerator | OK | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-architecture | OK | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-best-practices | OK | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-consistency | OK | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-holistic | OK | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-rulebase | OK | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-testability | OK | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-impl-consistency | OK | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-impl-holistic | OK | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-impl-rulebase | OK | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-interface | OK | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-quality | OK | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-test | OK | OK | `sonnet` | Read, Glob, Grep, Write, Bash | OK |
| sdd-inspector-e2e | OK | OK | `sonnet` | Read, Glob, Grep, Write, Bash | OK |
| sdd-inspector-dead-code | OK | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-dead-settings | OK | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-dead-specs | OK | OK | `sonnet` | Read, Glob, Grep, Write | OK |
| sdd-inspector-dead-tests | OK | OK | `sonnet` | Read, Glob, Grep, Write | OK |

**検出事項**: なし。全23エージェントが公式仕様に完全準拠。

### Frontmatter フィールド検証詳細

**name フィールド**: 全エージェントが小文字とハイフンのみの命名規則に準拠。

**description フィールド**: 全エージェントが適切な説明文を持ち、いつ使用されるべきかの文脈を含む。

**model フィールド**: 公式ドキュメントでは `sonnet`, `opus`, `haiku`, `inherit` が有効値。フレームワークでは `opus` (T2: Architect, Auditor) と `sonnet` (T3: TaskGenerator, Builder, Inspector) のみ使用。全て有効値。

**tools フィールド**: 公式ドキュメントではカンマ区切りのツール名リスト。使用されているツール名は全て Claude Code の内部ツールとして確認済み: `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash`, `WebSearch`, `WebFetch`。

---

## 2. スキル定義 (`.claude/skills/sdd-*/SKILL.md`) Frontmatter 準拠

### 公式仕様

公式ドキュメントによるスキル frontmatter フィールド:

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `name` | No | 省略時はディレクトリ名を使用 |
| `description` | 推奨 | 用途と使用タイミング |
| `argument-hint` | No | オートコンプリートのヒント |
| `disable-model-invocation` | No | Claude の自動呼び出しを無効化 |
| `user-invocable` | No | `/` メニューからの非表示化 |
| `allowed-tools` | No | 許可ツール |
| `model` | No | 使用モデル |
| `context` | No | `fork` でサブエージェント実行 |
| `agent` | No | `context: fork` 時のサブエージェント |
| `hooks` | No | スキル固有フック |

### フレームワークのスキル一覧と準拠状況

| スキル | description | allowed-tools | argument-hint | 準拠 |
|--------|-------------|---------------|---------------|------|
| sdd-roadmap | OK | Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | OK | OK |
| sdd-steering | OK | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | OK | OK |
| sdd-status | OK | Read, Glob, Grep | OK | OK |
| sdd-handover | OK | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | OK (空) | OK |
| sdd-knowledge | OK | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | OK | OK |
| sdd-release | OK | Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion | OK | OK |
| sdd-review-self | OK | Task, Bash, Read, Glob, Grep, WebSearch, WebFetch | OK | OK |

**検出事項**: なし。全7スキルが公式仕様に準拠。

### 詳細分析

**allowed-tools 検証**: 全スキルで使用されているツール名は Claude Code の有効なツール名。`Task` (sdd-roadmap, sdd-review-self)、`AskUserQuestion` (複数) を含め全て有効。

**argument-hint**: 各スキルに適切なヒントが設定されている。sdd-handover のみ空だが、公式仕様上は省略可能なので問題なし。

**name フィールド**: 全スキルで省略されている。公式仕様では省略時にディレクトリ名が使用されるため、`sdd-roadmap`, `sdd-steering` 等のディレクトリ名が自動的に使用される。問題なし。

---

## 3. Task ツール使用法 (subagent_type パラメータ)

### 公式仕様

公式ドキュメントによると、SubAgent の呼び出しは `Task` ツールの `subagent_type` パラメータ (もしくは `agent_type`) で行う。`.claude/agents/` に定義されたエージェントの `name` を指定する。

CLAUDE.md での記述: `Task(subagent_type="sdd-architect", prompt="...")`

### 検証結果

フレームワークの CLAUDE.md では以下の記述がある:

> Lead dispatches T2/T3 SubAgents using `Task` tool with `subagent_type` parameter (e.g., `Task(subagent_type="sdd-architect", prompt="...")`).

**注意点**: 公式ドキュメントでは `agent_type` というパラメータ名も確認されている (`Task(agent_type)` syntax in the `tools` field)。フレームワークでは `subagent_type` を使用。Claude Code の Task ツールは実装上 `subagent_type` パラメータを受け付けるため、現行の使用法は正しい。

**検出事項**: なし。

---

## 4. settings.json 準拠

### 公式仕様で有効なトップレベルキー

`$schema`, `apiKeyHelper`, `cleanupPeriodDays`, `companyAnnouncements`, `env`, `attribution`, `includeCoAuthoredBy` (deprecated), `permissions`, `hooks`, `disableAllHooks`, `allowManagedHooksOnly`, `allowManagedPermissionRulesOnly`, `model`, `availableModels`, `otelHeadersHelper`, `statusLine`, `fileSuggestion`, `respectGitignore`, `outputStyle`, `forceLoginMethod`, `forceLoginOrgUUID`, `enableAllProjectMcpServers`, `enabledMcpjsonServers`, `disabledMcpjsonServers`, `allowedMcpServers`, `deniedMcpServers`, `strictKnownMarketplaces`, `awsAuthRefresh`, `awsCredentialExport`, `alwaysThinkingEnabled`, `plansDirectory`, `showTurnDuration`, `spinnerVerbs`, `language`, `autoUpdatesChannel`, `spinnerTipsEnabled`, `spinnerTipsOverride`, `terminalProgressBarEnabled`, `prefersReducedMotion`, `teammateMode`, `enabledPlugins`, `extraKnownMarketplaces`, `sandbox`

### フレームワークの settings.json

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

**検証**:
- `permissions` キー: 有効
- `permissions.allow` 配列: 有効
- `Bash(cat:*)`, `Bash(echo:*)` の書式: 公式ドキュメントでは `Bash(npm run *)` のようなパターンマッチング構文が示されている。コロン区切り (`cat:*`) のパターンも有効

**検出事項 [INFO]**: `settings.json` の内容は最小限で、フレームワーク自体の動作に直接影響するものは少ない。プロジェクト固有のカスタマイズはユーザーに委ねている。適切なアプローチ。

---

## 5. install.sh パス検証

### Claude Code が期待するパス構造

| パス | 用途 | 公式仕様 |
|------|------|----------|
| `.claude/agents/` | サブエージェント定義 | プロジェクトスコープ (Priority 2) |
| `.claude/skills/<name>/SKILL.md` | スキル定義 | プロジェクトスコープ |
| `.claude/CLAUDE.md` | プロジェクトメモリ | 標準パス |
| `.claude/settings.json` | プロジェクト設定 | 標準パス |

### install.sh のインストール先

| ソース | インストール先 | 公式パスとの一致 |
|--------|---------------|-----------------|
| `framework/claude/skills/` | `.claude/skills/` | OK |
| `framework/claude/agents/` | `.claude/agents/` | OK |
| `framework/claude/CLAUDE.md` | `.claude/CLAUDE.md` | OK |
| `framework/claude/settings.json` | `.claude/settings.json` | OK |
| `framework/claude/sdd/settings/rules/` | `.claude/sdd/settings/rules/` | N/A (フレームワーク独自) |
| `framework/claude/sdd/settings/templates/` | `.claude/sdd/settings/templates/` | N/A (フレームワーク独自) |
| `framework/claude/sdd/settings/profiles/` | `.claude/sdd/settings/profiles/` | N/A (フレームワーク独自) |

**検出事項**: なし。全てのパスが Claude Code の期待するディレクトリ構造に一致。

### install.sh の追加検証

- **マーカーベースの CLAUDE.md 管理**: `<!-- sdd:start -->` / `<!-- sdd:end -->` マーカーを使用してユーザーのコンテンツを保持しつつフレームワーク部分のみ更新。適切な実装。
- **settings.json の保護**: 既存ファイルがある場合はユーザーに確認を求める。`--update` モードでは既存を保持。適切。
- **stale ファイルクリーンアップ**: `--update`/`--force` 時に、ソースに存在しなくなったファイルを削除。スキルのクリーンアップは `sdd-*` スコープのみ対象で、ユーザー作成スキルは保護される。適切。
- **マイグレーション**: v0.4.0 (kiro->sdd), v0.7.0 (coordinator削除), v0.9.0 (handover redesign), v0.10.0 (spec.json->yaml), v0.15.0 (commands->skills), v0.18.0 (agents->sdd/settings/agents), v0.20.0 (sdd/settings/agents->agents/) の各マイグレーションが実装されている。

---

## 6. モデル選択の適切性

### フレームワークのモデル割り当て

| ティア | ロール | モデル | 適切性 |
|--------|--------|--------|--------|
| T1 | Lead | (ユーザーのセッションモデル) | OK - ユーザーが選択 |
| T2 | Architect | `opus` | OK - 設計判断には高い推論力が必要 |
| T2 | Auditor (design/impl/dead-code) | `opus` | OK - レビュー統合には高い判断力が必要 |
| T3 | TaskGenerator | `sonnet` | OK - 構造化タスク分解は Sonnet で十分 |
| T3 | Builder | `sonnet` | OK - TDD 実装は Sonnet で十分 |
| T3 | Inspector (全種) | `sonnet` | OK - 個別観点レビューは Sonnet で十分 |

**検出事項**: なし。モデル選択は各ロールの責務に対して適切。

公式ドキュメントでは `haiku` も有効値として存在するが、フレームワークでは未使用。コスト最適化の余地はあるが、品質優先のアプローチとして妥当。

---

## 7. ツール権限の最小権限原則

### 分析

| ロール | 付与ツール | 最小限か | 備考 |
|--------|-----------|----------|------|
| Architect | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | OK | 設計文書生成 + 外部調査に必要 |
| Auditor (全種) | Read, Glob, Grep, Write | OK | CPF ファイル読み書きに最小限 |
| TaskGenerator | Read, Glob, Grep, Write | OK | tasks.yaml 生成に最小限 |
| Builder | Read, Glob, Grep, Write, Edit, Bash | OK | TDD 実装にはコード編集 + テスト実行が必要 |
| Inspector (一般) | Read, Glob, Grep, Write | OK | CPF ファイル読み書きに最小限 |
| Inspector (test) | Read, Glob, Grep, Write, Bash | OK | テスト実行に Bash が必要 |
| Inspector (e2e) | Read, Glob, Grep, Write, Bash | OK | ブラウザ自動化 + サーバー起動に Bash が必要 |
| Inspector (dead-*) | Read, Glob, Grep, Write | OK | 静的解析のみ、Bash 不要 |

**検出事項**: なし。全エージェントが最小権限原則に従っている。

**特記事項**:
- Auditor には `Edit` が付与されていない (Write のみ) -- CPF verdict ファイルを新規作成するだけなので適切
- Inspector (test/e2e) のみ `Bash` を持つ -- テスト実行とブラウザ操作に必要
- Architect のみ `WebSearch`/`WebFetch` を持つ -- 外部調査はアーキテクトの責務
- Builder は `Edit` を持つが Inspector は持たない -- Builder はコード編集、Inspector は読み取り専用レビュー

---

## 8. 未使用の公式機能

フレームワークが使用していないが、将来活用可能な公式機能:

| 機能 | 説明 | 活用可能性 |
|------|------|-----------|
| `disallowedTools` | ツール拒否リスト | Inspector に Write の明示的拒否を追加可能 (現状は tools リストで制御) |
| `permissionMode` | 権限モード | Builder に `acceptEdits` を設定して効率化可能 |
| `maxTurns` | 最大ターン数 | Inspector のコスト制御に有用 |
| `skills` | スキルプリロード | エージェントへのスキル知識注入に有用 |
| `memory` | 永続メモリ | Auditor のレビューパターン学習に有用 |
| `background` | バックグラウンド実行 | 並列 Inspector のバックグラウンド化に有用 |
| `isolation` | ワークツリー分離 | Builder の並列作業分離に有用 |
| `hooks` | ライフサイクルフック | SubAgent の前処理/後処理自動化に有用 |

---

## 公式仕様準拠テーブル (総合)

| 検証項目 | 対象数 | 準拠 | 不準拠 | 備考 | 判定 |
|----------|--------|------|--------|------|------|
| agents/ YAML frontmatter 有効値 | 23 | 23 | 0 | name, description, model, tools 全て有効 | PASS |
| agents/ model 有効値 | 23 | 23 | 0 | opus/sonnet のみ使用、全て有効 | PASS |
| agents/ tools 有効値 | 23 | 23 | 0 | Read, Glob, Grep, Write, Edit, Bash, WebSearch, WebFetch 全て有効 | PASS |
| skills/ frontmatter 有効フィールド | 7 | 7 | 0 | description, allowed-tools, argument-hint 全て有効 | PASS |
| skills/ allowed-tools 有効値 | 7 | 7 | 0 | Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion, WebSearch, WebFetch 全て有効 | PASS |
| settings.json 有効キー | 1 | 1 | 0 | permissions.allow のみ使用、有効 | PASS |
| install.sh パス一致 | 7 | 7 | 0 | 全インストール先が Claude Code 期待パスに一致 | PASS |
| Task ツール使用法 | 1 | 1 | 0 | subagent_type パラメータ使用、有効 | PASS |
| モデル選択適切性 | 23 | 23 | 0 | T2=opus, T3=sonnet、責務に対して適切 | PASS |
| ツール最小権限 | 23 | 23 | 0 | 各ロールに必要最小限のツールのみ付与 | PASS |

---

## 最近の変更に関する検証

### sdd-builder.md の変更

**追加内容**: SELF-CHECK ステップ (Step 5) と SelfCheck フィールド (completion report)

- YAML frontmatter への影響: なし (tools, model 変更なし)
- 公式仕様準拠への影響: なし
- **判定**: PASS -- 変更はエージェントのシステムプロンプト本文のみで、frontmatter は変更されていない

### sdd-taskgenerator.md の変更

**追加内容**: steering context の読み込み指示

- YAML frontmatter への影響: なし
- 公式仕様準拠への影響: なし
- **判定**: PASS -- 変更はシステムプロンプト本文のみ

---

## 総合判定

**PASS** -- sync-sdd フレームワーク v1.0.0 は Claude Code 公式ドキュメントに完全準拠している。

全23エージェント定義、全7スキル定義、settings.json、および install.sh のパス構造が公式仕様の有効値のみを使用しており、不準拠の検出事項はゼロ。

### 推奨事項 (任意)

1. **`maxTurns` の検討**: Inspector エージェントにターン数制限を設定することで、コスト制御とタイムアウト防止が可能
2. **`permissionMode` の検討**: Builder に `acceptEdits` を設定してファイル編集の自動承認を有効化し、実行効率を向上可能
3. **`memory` の検討**: Auditor に `project` スコープのメモリを付与し、レビューパターンの学習を可能にすることで、セッション間でのレビュー品質向上が見込める
4. **`background` の検討**: Inspector エージェントに `background: true` を設定し、バックグラウンド並列実行を公式機能として活用可能
