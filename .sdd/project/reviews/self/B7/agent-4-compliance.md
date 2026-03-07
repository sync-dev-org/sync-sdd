# Claude Code 公式ドキュメント準拠レビュー

レビュー日: 2026-02-24
対象バージョン: v1.2.0 (commit 6a0a69b + uncommitted changes)
レビュアー: Agent-4 (Compliance Reviewer)

## 参照した公式ドキュメント

- [Create custom subagents - Claude Code Docs](https://code.claude.com/docs/en/sub-agents)
- [Extend Claude with skills - Claude Code Docs](https://code.claude.com/docs/en/skills)
- [Claude Code settings - Claude Code Docs](https://code.claude.com/docs/en/settings)
- [Configure permissions - Claude Code Docs](https://code.claude.com/docs/en/permissions)

---

## 1. エージェント YAML フロントマター準拠

### 公式仕様 (code.claude.com/docs/en/sub-agents)

| フィールド | 必須 | 説明 |
|---|---|---|
| `name` | Yes | ユニーク識別子 (小文字+ハイフン) |
| `description` | Yes | 委譲判断に使用される説明文 |
| `model` | No | `sonnet`, `opus`, `haiku`, `inherit` (デフォルト: `inherit`) |
| `tools` | No | 許可ツールリスト (省略時: 全ツール継承) |
| `disallowedTools` | No | 拒否ツールリスト |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `maxTurns` | No | 最大エージェントターン数 |
| `skills` | No | プリロードするスキル |
| `mcpServers` | No | MCP サーバー設定 |
| `hooks` | No | ライフサイクルフック |
| `memory` | No | 永続メモリスコープ (`user`, `project`, `local`) |
| `background` | No | `true` でバックグラウンド実行 (デフォルト: `false`) |
| `isolation` | No | `worktree` でワークツリー隔離 |

### 全エージェントファイル検証結果

| エージェント | name | description | model | tools | background | 準拠 |
|---|---|---|---|---|---|---|
| `sdd-architect` | OK | OK | `opus` | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | `true` | OK |
| `sdd-auditor-dead-code` | OK | OK | `opus` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-auditor-design` | OK | OK | `opus` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-auditor-impl` | OK | OK | `opus` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-builder` | OK | OK | `sonnet` | Read, Glob, Grep, Write, Edit, Bash | `true` | OK |
| `sdd-taskgenerator` | OK | OK | `sonnet` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-inspector-architecture` | OK | OK | `sonnet` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-inspector-best-practices` | OK | OK | `sonnet` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-inspector-consistency` | OK | OK | `sonnet` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-inspector-dead-code` | OK | OK | `sonnet` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-inspector-dead-settings` | OK | OK | `sonnet` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-inspector-dead-specs` | OK | OK | `sonnet` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-inspector-dead-tests` | OK | OK | `sonnet` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-inspector-e2e` | OK | OK | `sonnet` | Read, Glob, Grep, Write, Bash | `true` | OK |
| `sdd-inspector-holistic` | OK | OK | `sonnet` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-inspector-impl-consistency` | OK | OK | `sonnet` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-inspector-impl-holistic` | OK | OK | `sonnet` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-inspector-impl-rulebase` | OK | OK | `sonnet` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-inspector-interface` | OK | OK | `sonnet` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-inspector-quality` | OK | OK | `sonnet` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-inspector-rulebase` | OK | OK | `sonnet` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-inspector-test` | OK | OK | `sonnet` | Read, Glob, Grep, Write, Bash | `true` | OK |
| `sdd-inspector-testability` | OK | OK | `sonnet` | Read, Glob, Grep, Write | `true` | OK |
| `sdd-inspector-visual` | OK | OK | `sonnet` | Read, Glob, Grep, Write, Bash | `true` | OK |

**総数: 24 エージェント / 全件準拠**

### 詳細所見

#### A. フロントマターフィールド値の妥当性

- **name**: 全エージェントが小文字+ハイフンの命名規則に準拠
- **description**: 全エージェントが説明文を持ち、委譲トリガーとして機能する内容
- **model**: `opus` (T2: Architect/Auditor) と `sonnet` (T3: TaskGenerator/Builder/Inspector) の2値のみ使用。公式仕様の有効値 (`sonnet`, `opus`, `haiku`, `inherit`) の範囲内
- **tools**: 全ツール名が公式の内部ツール名に合致 (Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch)
- **background**: 全エージェントが `true` を設定。公式仕様で `true`/`false`(デフォルト `false`)が有効値

#### B. ツール名の公式準拠

以下のツール名がエージェントで使用されており、全て Claude Code 公式内部ツール:

| ツール名 | 使用箇所 | 公式ドキュメント |
|---|---|---|
| `Read` | 全エージェント | OK |
| `Glob` | 全エージェント | OK |
| `Grep` | 全エージェント | OK |
| `Write` | 全エージェント | OK |
| `Edit` | Architect, Builder | OK |
| `Bash` | Builder, E2E Inspector, Test Inspector, Visual Inspector | OK |
| `WebSearch` | Architect | OK |
| `WebFetch` | Architect | OK |

**指摘事項なし**

#### C. model 選択の適切性

| Tier | ロール | model | 妥当性 |
|---|---|---|---|
| T2 | Architect | `opus` | 適切: 設計判断に高い推論力が必要 |
| T2 | Auditor (3種) | `opus` | 適切: 矛盾検出・判断統合に高い推論力が必要 |
| T3 | TaskGenerator | `sonnet` | 適切: 構造化タスク分解は Sonnet で十分 |
| T3 | Builder | `sonnet` | 適切: TDD 実装はバランス重視 |
| T3 | Inspector (14種) | `sonnet` | 適切: 個別観点のレビューは Sonnet で十分 |

**コスト最適化の観点**: Inspector は `haiku` にダウングレード可能な候補だが、コード品質分析の精度と `sonnet` のバランスは妥当。現行設定に問題なし。

#### D. ツール権限の最小性

| エージェント群 | 不要ツールの有無 | 評価 |
|---|---|---|
| Architect | WebSearch/WebFetch は discovery に必要。Edit は design.md 生成に必要 | 最小限 |
| Auditor (3種) | Write のみ (verdict 出力用)。Edit 不要で付与されていない | 最小限 |
| TaskGenerator | Write のみ (tasks.yaml 生成用)。Edit/Bash 不要で付与されていない | 最小限 |
| Builder | Edit + Bash が必要 (コード編集+テスト実行) | 最小限 |
| Inspector (Read-only群) | Write のみ (CPF 出力用)。Edit/Bash 不要で付与されていない | 最小限 |
| Inspector (E2E/Visual/Test) | Bash が必要 (playwright-cli/テスト実行) | 最小限 |

**指摘事項なし**: 全エージェントが必要最小限のツールのみ付与されている。

---

## 2. スキル SKILL.md フロントマター準拠

### 公式仕様 (code.claude.com/docs/en/skills)

| フィールド | 必須 | 説明 |
|---|---|---|
| `name` | No | 表示名。省略時はディレクトリ名 (小文字/数字/ハイフン, 最大64文字) |
| `description` | 推奨 | スキルの説明。Claude が自動呼出しの判断に使用 |
| `argument-hint` | No | オートコンプリート時のヒント |
| `disable-model-invocation` | No | `true` で Claude の自動呼出しを無効化 |
| `user-invocable` | No | `false` で `/` メニューから非表示 |
| `allowed-tools` | No | スキル実行時に許可されるツール |
| `model` | No | スキル実行時のモデル |
| `context` | No | `fork` でサブエージェントコンテキストで実行 |
| `agent` | No | `context: fork` 時のサブエージェント指定 |
| `hooks` | No | スキルライフサイクルフック |

### 全スキルファイル検証結果

| スキル | description | allowed-tools | argument-hint | 準拠 |
|---|---|---|---|---|
| `sdd-roadmap` | OK | Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | OK | OK |
| `sdd-steering` | OK | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | OK | OK |
| `sdd-status` | OK | Read, Glob, Grep | OK | OK |
| `sdd-handover` | OK | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | (空) | OK |
| `sdd-knowledge` | OK | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | OK | OK |
| `sdd-release` | OK | Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion | OK | OK |
| `sdd-review-self` | OK | Task, Bash, Read, Glob, Grep, WebSearch, WebFetch | OK | OK |

**総数: 7 スキル / 全件準拠**

### 詳細所見

#### A. フロントマターフィールド値の妥当性

- **description**: 全スキルが説明文を持ち、Claude の自動呼出し判断に十分な情報を含む
- **allowed-tools**: 全ツール名が Claude Code 公式内部ツール名に合致
- **argument-hint**: ユーザーが `/sdd-xxx` 入力時のヒントとして適切な内容
- **name フィールド不使用**: 全スキルが `name` フィールドを省略。公式仕様上、省略時はディレクトリ名が使用されるため問題なし。ディレクトリ名 (`sdd-roadmap` 等) が命名規則に準拠

#### B. `name` フィールド省略について

公式仕様では `name` は Optional で、省略時はディレクトリ名が使われる。SDD フレームワークのスキルは全てディレクトリ名が命名規則 (小文字/数字/ハイフン) に準拠しているため、省略は正当。

#### C. allowed-tools のツール名

| ツール名 | 使用スキル | 公式ドキュメント |
|---|---|---|
| `Task` | sdd-roadmap, sdd-review-self | OK (SubAgent ディスパッチ用) |
| `Bash` | sdd-roadmap, sdd-steering, sdd-handover, sdd-knowledge, sdd-release, sdd-review-self | OK |
| `Read` | 全スキル | OK |
| `Write` | sdd-roadmap, sdd-steering, sdd-handover, sdd-knowledge, sdd-release | OK |
| `Edit` | sdd-roadmap, sdd-steering, sdd-handover, sdd-knowledge, sdd-release | OK |
| `Glob` | 全スキル | OK |
| `Grep` | 全スキル | OK |
| `AskUserQuestion` | sdd-roadmap, sdd-steering, sdd-handover, sdd-knowledge, sdd-release | OK |
| `WebSearch` | sdd-review-self | OK |
| `WebFetch` | sdd-review-self | OK |

**指摘事項なし**

---

## 3. Task ツール使用法の準拠

### 公式仕様

CLAUDE.md および SKILL.md 内で `Task(subagent_type="sdd-architect", prompt="...")` という記法を使用。

公式ドキュメントでは、Task ツールは `subagent_type` パラメータで呼び出すサブエージェントを指定する。エージェント定義は `.claude/agents/` に配置。

### 検証結果

- **CLAUDE.md**: `Task(subagent_type="sdd-architect", prompt="...")` の記法で言及 -- **準拠**
- **settings.json**: `Task(sdd-architect)` 形式の permission rule -- **準拠** (公式の `Task(agent_type)` 構文に合致)
- **sdd-roadmap SKILL.md**: `allowed-tools: Task` で全 SubAgent ディスパッチを許可 -- **準拠**
- **sdd-review-self SKILL.md**: `allowed-tools: Task` で全 SubAgent ディスパッチを許可 -- **準拠**

### 注意点: `subagent_type` vs `agent_type` の用語

公式ドキュメント (code.claude.com/docs/en/sub-agents) では `Task(agent_type)` という用語を使用:

> To restrict which subagent types it can spawn, use `Task(agent_type)` syntax in the `tools` field

SDD フレームワークの CLAUDE.md では `Task(subagent_type="sdd-architect", prompt="...")` という表記を使用している。

**評価**: `subagent_type` は Task ツールの実際のパラメータ名として機能しているため、公式ドキュメントの `agent_type` は permission rule 構文の説明であり、Task ツール API のパラメータ名とは別の文脈。CLAUDE.md の記述はユーザー向けの概念説明として問題ない。ただし、公式ドキュメントとの用語の一貫性を高めるために `agent_type` への統一を検討してもよい。

**重要度: LOW** (機能的な問題なし、用語統一の提案のみ)

---

## 4. settings.json 準拠

### 公式仕様の有効キー

公式ドキュメント (code.claude.com/docs/en/settings) で定義されている settings.json のトップレベルキー:

`$schema`, `apiKeyHelper`, `attribution`, `alwaysThinkingEnabled`, `autoUpdatesChannel`, `availableModels`, `awsAuthRefresh`, `awsCredentialExport`, `cleanupPeriodDays`, `companyAnnouncements`, `disableAllHooks`, `allowManagedHooksOnly`, `allowManagedPermissionRulesOnly`, `enableAllProjectMcpServers`, `enabledMcpjsonServers`, `disabledMcpjsonServers`, `allowedMcpServers`, `deniedMcpServers`, `strictKnownMarketplaces`, `env`, `enabledPlugins`, `extraKnownMarketplaces`, `fileSuggestion`, `forceLoginMethod`, `forceLoginOrgUUID`, `hooks`, `language`, `model`, `otelHeadersHelper`, `outputStyle`, `permissions`, `plansDirectory`, `prefersReducedMotion`, `respectGitignore`, `sandbox`, `showTurnDuration`, `spinnerTipsEnabled`, `spinnerTipsOverride`, `spinnerVerbs`, `statusLine`, `teammateMode`, `terminalProgressBarEnabled`

`permissions` 内の有効キー: `allow`, `ask`, `deny`, `additionalDirectories`, `defaultMode`, `disableBypassPermissionsMode`

### SDD フレームワークの settings.json 検証

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Skill(sdd-roadmap)",
      "Skill(sdd-steering)",
      "Skill(sdd-status)",
      "Skill(sdd-handover)",
      "Skill(sdd-knowledge)",
      "Skill(sdd-release)",
      "Skill(sdd-review-self)",
      "Task(sdd-architect)",
      "Task(sdd-auditor-dead-code)",
      ... (24 Task entries),
      "Bash(git *)",
      "Bash(mkdir *)",
      "Bash(ls *)",
      "Bash(mv *)",
      "Bash(cp *)",
      "Bash(wc *)",
      "Bash(which *)",
      "Bash(diff *)",
      "Bash(playwright-cli *)",
      "Bash(npm *)",
      "Bash(npx *)"
    ]
  }
}
```

| 項目 | 値 | 公式仕様 | 準拠 |
|---|---|---|---|
| トップレベルキー `permissions` | 使用 | 有効キー | OK |
| `permissions.defaultMode` | `"acceptEdits"` | 有効値: `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` | OK |
| `permissions.allow` | 配列 | 有効キー | OK |
| `Skill(name)` 構文 | 7 件 | 公式: `Skill(name)` で exact match | OK |
| `Task(name)` 構文 | 24 件 | 公式: `Task(AgentName)` で subagent 制御 | OK |
| `Bash(pattern)` 構文 | 11 件 | 公式: `Bash(command pattern)` でワイルドカード対応 | OK |
| 不明なキー | なし | - | OK |

**指摘事項なし**: settings.json は公式仕様に完全準拠。

---

## 5. install.sh パス準拠

### Claude Code が期待するパス

| パス | 用途 | 公式ドキュメント |
|---|---|---|
| `.claude/agents/` | プロジェクトレベルサブエージェント | code.claude.com/docs/en/sub-agents |
| `.claude/skills/` | プロジェクトレベルスキル | code.claude.com/docs/en/skills |
| `.claude/CLAUDE.md` | プロジェクトメモリ/指示 | code.claude.com/docs/en/memory |
| `.claude/settings.json` | プロジェクト設定 | code.claude.com/docs/en/settings |

### install.sh のインストール先検証

| install.sh のコピー先 | 期待されるパス | 準拠 |
|---|---|---|
| `.claude/skills/sdd-*/` | `.claude/skills/<skill-name>/SKILL.md` | OK |
| `.claude/agents/sdd-*.md` | `.claude/agents/<name>.md` | OK |
| `.claude/CLAUDE.md` | `.claude/CLAUDE.md` (マーカーベース追記) | OK |
| `.claude/settings.json` | `.claude/settings.json` | OK |
| `.sdd/settings/rules/` | フレームワーク独自パス (Claude Code 仕様外) | OK (独自拡張) |
| `.sdd/settings/templates/` | フレームワーク独自パス (Claude Code 仕様外) | OK (独自拡張) |
| `.sdd/settings/profiles/` | フレームワーク独自パス (Claude Code 仕様外) | OK (独自拡張) |
| `.sdd/.version` | フレームワーク独自パス (Claude Code 仕様外) | OK (独自拡張) |

**指摘事項なし**: 全てのインストール先が Claude Code の期待するパスに合致。`.sdd/` 配下は SDD フレームワーク固有のデータであり、Claude Code の仕様に抵触しない。

### マーカーベース CLAUDE.md 管理

install.sh は `<!-- sdd:start -->` / `<!-- sdd:end -->` マーカーを使用して CLAUDE.md 内の SDD セクションを管理。ユーザーのカスタムコンテンツを保持しつつ、フレームワーク部分のみを更新する。

**評価**: 公式ドキュメントでは CLAUDE.md のフォーマットに特定の制約はなく、マーカーベースの管理は安全かつ推奨されるパターン。

---

## 6. モデル選択の適切性

| ロール | 設定モデル | 推論要件 | 評価 |
|---|---|---|---|
| Lead (T1) | (ユーザー環境依存) | 全体オーケストレーション、判断 | N/A (フレームワーク外) |
| Architect (T2) | `opus` | 複雑な設計判断、調査統合 | 適切 |
| Auditor (T2, 3種) | `opus` | 矛盾検出、false positive 排除、判断統合 | 適切 |
| TaskGenerator (T3) | `sonnet` | 構造化分解、ファイル割当 | 適切 |
| Builder (T3) | `sonnet` | TDD 実装、コード生成 | 適切 |
| Inspector (T3, 14種) | `sonnet` | 個別観点レビュー、パターン検出 | 適切 |

**コスト/品質トレードオフ**: T2 に `opus` (高品質判断)、T3 に `sonnet` (コスト効率の良い実行) という分離は Claude Code のモデル選択ベストプラクティスに合致。

---

## 7. ツール権限の最小性

### 原則

公式ドキュメント:
> Design focused subagents: each subagent should excel at one specific task
> Limit tool access: grant only necessary permissions for security and focus

### 検証結果

| カテゴリ | ツール構成 | 最小性評価 |
|---|---|---|
| Read-only エージェント (Inspector 10種, Auditor 3種, TaskGenerator) | Read, Glob, Grep, Write | OK: Write は CPF/verdict/tasks.yaml 出力に必要 |
| Read+Edit エージェント (Architect) | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | OK: design.md 生成に Edit、調査に Web ツールが必要 |
| 実行エージェント (Builder) | Read, Glob, Grep, Write, Edit, Bash | OK: コード生成に Edit、テスト実行に Bash が必要 |
| ブラウザエージェント (E2E, Visual, Test Inspector) | Read, Glob, Grep, Write, Bash | OK: playwright-cli/テスト実行に Bash が必要 |

**全エージェントが最小権限原則に準拠。不必要なツール付与は検出されなかった。**

---

## 公式仕様準拠テーブル (総合)

| # | 検証項目 | 対象数 | 準拠数 | 非準拠数 | 結果 |
|---|---|---|---|---|---|
| 1 | agents/ YAML フロントマター: 有効フィールド値 | 24 | 24 | 0 | PASS |
| 2 | agents/ name: 小文字+ハイフン命名規則 | 24 | 24 | 0 | PASS |
| 3 | agents/ model: 有効値 (sonnet/opus/haiku/inherit) | 24 | 24 | 0 | PASS |
| 4 | agents/ tools: 公式内部ツール名のみ使用 | 24 | 24 | 0 | PASS |
| 5 | agents/ background: 有効値 (true/false) | 24 | 24 | 0 | PASS |
| 6 | skills/ SKILL.md フロントマター: 有効フィールド値 | 7 | 7 | 0 | PASS |
| 7 | skills/ description: 存在する | 7 | 7 | 0 | PASS |
| 8 | skills/ allowed-tools: 公式内部ツール名のみ使用 | 7 | 7 | 0 | PASS |
| 9 | skills/ argument-hint: 有効形式 | 7 | 7 | 0 | PASS |
| 10 | settings.json: 有効トップレベルキーのみ使用 | 1 | 1 | 0 | PASS |
| 11 | settings.json permissions: 有効サブキーのみ使用 | 1 | 1 | 0 | PASS |
| 12 | settings.json defaultMode: 有効値 | 1 | 1 | 0 | PASS |
| 13 | settings.json allow[]: 有効ツール構文 | 42 rules | 42 | 0 | PASS |
| 14 | Task ツール呼出し: subagent_type パラメータ使用 | - | - | - | PASS |
| 15 | install.sh: Claude Code 期待パスへのインストール | 4 paths | 4 | 0 | PASS |
| 16 | モデル選択: ロールに適切なモデル | 24 | 24 | 0 | PASS |
| 17 | ツール権限: 最小必要ツールのみ付与 | 24 | 24 | 0 | PASS |

**総合結果: 全項目 PASS**

---

## 改善提案 (非準拠ではなく品質向上の提案)

### LOW: 用語の一貫性

**対象**: `framework/claude/CLAUDE.md` 30行目

```
Task(subagent_type="sdd-architect", prompt="...")
```

公式ドキュメントでは permission rule 構文として `Task(agent_type)` を使用。API パラメータ名は別だが、ドキュメント間の用語統一のために `agent_type` への統一を検討してもよい。

**影響**: なし (機能的な問題はない)

### INFO: 未使用の公式機能

以下の公式機能は現在 SDD フレームワークで未使用だが、将来的に有用な可能性がある:

| 機能 | 説明 | 潜在的用途 |
|---|---|---|
| `memory` (agent frontmatter) | サブエージェントの永続メモリ | Builder/Inspector の学習蓄積 |
| `isolation: worktree` | ワークツリー隔離 | 並列 Builder のファイル衝突防止 |
| `maxTurns` | ターン数制限 | Inspector のコスト制御 |
| `skills` (agent frontmatter) | プリロードスキル | SubAgent へのルール注入 |
| `context: fork` (skill) | サブエージェントでスキル実行 | 大規模スキルの隔離実行 |
| `disable-model-invocation` (skill) | 自動呼出し無効化 | `/sdd-release` 等の手動限定化 |
| `hooks` (agent/skill) | ライフサイクルフック | Builder の PreToolUse でファイルスコープ強制 |

---

## Uncommitted Changes の影響評価

### framework/claude/CLAUDE.md

**Session Resume Step 7 改訂**:
```
7. If roadmap pipeline was active (session.md indicates run/revise in progress):
     - Continue pipeline from spec.yaml state. Treat spec.yaml as ground truth.
     - Do NOT manually update spec.yaml to "recover" or "fix" perceived inconsistencies.
     - If spec.yaml state vs actual artifacts seem inconsistent: report to user, do not auto-fix.
   Otherwise: await user instruction.
```

**評価**: CLAUDE.md のコンテンツ変更であり、Claude Code の仕様への準拠に影響なし。フレームワークの動作ロジックの改善。

**Behavioral Rules 改訂**:
```
- After a compact operation: If a roadmap pipeline (run/revise) was in progress, perform Session Resume steps 1-6 to reload context, then continue the pipeline from spec.yaml state (do NOT manually "recover" or patch spec.yaml -- treat it as ground truth). If no pipeline was active, wait for the user's next instruction.
- Do not continue or resume non-pipeline tasks after compact unless the user explicitly instructs you to do so.
```

**評価**: CLAUDE.md のコンテンツ変更であり、Claude Code の仕様への準拠に影響なし。compact 後の動作をより明確化した改善。

### framework/claude/agents/sdd-builder.md

**追加制約**:
```
- **No workspace-wide git operations**: Do NOT use `git stash`, `git checkout .`, `git restore .`, `git reset`, or `git clean`. These affect files outside your file scope (spec.yaml, design.md, etc. that Lead manages). If you need to undo your own changes, use file-level `git checkout -- <your-file>` only within your assigned scope.
```

**評価**: エージェントのシステムプロンプト (Markdown body) への追記であり、YAML フロントマターの変更なし。Claude Code の仕様への準拠に影響なし。Builder の安全性向上のための適切な制約追加。

---

## 結論

SDD フレームワーク v1.2.0 (+ uncommitted changes) は **Claude Code 公式ドキュメントに完全準拠** している。

- 24 エージェント定義: 全て有効な YAML フロントマターフィールドと値を使用
- 7 スキル定義: 全て有効なフロントマターフィールドと値を使用
- settings.json: 有効なキーとパーミッション構文のみ使用
- install.sh: Claude Code が期待するパスに正しくインストール
- モデル選択: ロール階層に応じた適切なモデル割当
- ツール権限: 最小権限原則に準拠

改善提案は全て LOW/INFO レベルであり、機能的な非準拠は検出されなかった。
