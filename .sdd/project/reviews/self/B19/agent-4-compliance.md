# Agent 4: Platform Compliance Report

**日付**: 2026-03-03
**対象バージョン**: v1.11.0 (フレームワーク開発リポ現行)
**レビュー対象**: B18以降に変更されたエージェント・スキル・settings.json・CLAUDE.md

---

## 調査方針

- WebSearchおよびWebFetch（公式ドキュメント）で Claude Code プラットフォーム仕様を確認
- 変更ファイルのみ詳細検証、キャッシュ済み項目はファイル変更有無を確認後マーク
- 参照ドキュメント:
  - https://code.claude.com/docs/en/sub-agents (Subagent フォーマット)
  - https://code.claude.com/docs/en/skills (Skills フォーマット)
  - https://platform.claude.com/docs/en/agent-sdk/subagents (Agent tool パラメータ)

---

## 1. 公式仕様サマリー（レビュー基準）

### 1.1 エージェント YAML フロントマター

| フィールド | 必須 | 有効値/注記 |
|-----------|------|-------------|
| `name` | 必須 | 小文字・ハイフンのみ |
| `description` | 必須 | エージェント用途の説明 |
| `model` | 任意 | `sonnet`, `opus`, `haiku`, `inherit` または省略（デフォルト: `inherit`） |
| `tools` | 任意 | ツール名のリスト（カンマ区切り）。省略時は全ツール継承 |
| `background` | 任意 | `true` で常時バックグラウンド実行 |
| `disallowedTools` | 任意 | 拒否ツールリスト |
| `permissionMode` | 任意 | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `maxTurns` | 任意 | 最大ターン数 |
| `skills` | 任意 | 起動時注入するスキルリスト |
| `mcpServers` | 任意 | MCP サーバー設定 |
| `hooks` | 任意 | ライフサイクルフック |
| `memory` | 任意 | `user`, `project`, `local` |
| `isolation` | 任意 | `worktree` |

### 1.2 Skills YAML フロントマター

| フィールド | 必須 | 有効値/注記 |
|-----------|------|-------------|
| `name` | 任意（省略時はディレクトリ名） | 小文字・ハイフン・数字のみ（最大64文字） |
| `description` | 推奨 | スキル用途の説明（最大1024文字） |
| `argument-hint` | 任意 | オートコンプリートのヒント（例: `[path] [format]`） |
| `allowed-tools` | 任意 | スキル有効時に許可ツール |
| `disable-model-invocation` | 任意 | `true` でClaudeによる自動呼び出し禁止 |
| `user-invocable` | 任意 | `false` でスラッシュメニューから非表示 |
| `model` | 任意 | スキル実行時のモデル |
| `context` | 任意 | `fork` でサブエージェントとして実行 |
| `agent` | 任意 | `context: fork` 時のエージェントタイプ |
| `hooks` | 任意 | スキルライフサイクルフック |

### 1.3 Agent ツール パラメータ

公式 SDK ドキュメントによると、Agent ツール（旧Task ツール）の主要パラメータは:
- `subagent_type`: 起動するエージェントの名前（`.claude/agents/` 内の `name` フィールドに対応）
- `prompt`: エージェントへの指示
- `run_in_background`: バックグラウンド実行フラグ（`true`/`false`）

**重要**: Claude Code 2.1.63以降、`Task` ツールは `Agent` ツールにリネームされた。`Task(...)` は後方互換として引き続き機能する。

### 1.4 settings.json パーミッション形式

```json
{
  "permissions": {
    "allow": [
      "Skill(skill-name)",
      "Agent(agent-name)",
      "Bash(command-pattern *)"
    ]
  }
}
```

---

## 2. キャッシュ済み検証項目（B18以降変更なし）

以下のエージェントはB18レビュー（2026-03-01）で検証済み、かつB18以降ファイル変更なし:

| エージェント | キャッシュ状態 |
|-------------|--------------|
| sdd-taskgenerator | OK (cached) |
| sdd-auditor-design | OK (cached) |
| sdd-auditor-impl | OK (cached) |
| sdd-conventions-scanner | OK (cached) |
| sdd-inspector-architecture | OK (cached) |
| sdd-inspector-best-practices | OK (cached) |
| sdd-inspector-consistency | OK (cached) |
| sdd-inspector-holistic | OK (cached) |
| sdd-inspector-impl-consistency | OK (cached) |
| sdd-inspector-impl-holistic | OK (cached) |
| sdd-inspector-impl-rulebase | OK (cached) |
| sdd-inspector-interface | OK (cached) |
| sdd-inspector-quality | OK (cached) |
| sdd-inspector-rulebase | OK (cached) |
| sdd-inspector-testability | OK (cached) |
| sdd-inspector-e2e | OK (cached) |
| sdd-handover スキル | OK (cached) |

---

## 3. 変更エージェントの詳細検証

### 3.1 sdd-analyst

**ファイル**: `framework/claude/agents/sdd-analyst.md`

```yaml
name: sdd-analyst
description: "SDD Analyst. Performs holistic project analysis and proposes zero-based redesign..."
model: opus
tools: Read, Glob, Grep, Write, Edit, WebSearch, WebFetch
background: true
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `name` フィールド | OK | 小文字・ハイフン形式 |
| `description` フィールド | OK | 有効な文字列 |
| `model: opus` | OK | 有効なモデルエイリアス |
| `tools` リスト | OK | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch — すべて有効 |
| `background: true` | OK | 公式仕様に存在するフィールド |
| ツール使用一致 | OK | 使用ツールはフロントマターと一致 |

**判定: PASS**

---

### 3.2 sdd-architect

**ファイル**: `framework/claude/agents/sdd-architect.md`

```yaml
name: sdd-architect
description: "SDD framework Architect. Generates design.md for spec-driven features..."
model: opus
tools: Read, Glob, Grep, Write, Edit, WebSearch, WebFetch
background: true
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `name` フィールド | OK | 小文字・ハイフン形式 |
| `description` フィールド | OK | 有効な文字列 |
| `model: opus` | OK | 有効なモデルエイリアス |
| `tools` リスト | OK | すべて有効 |
| `background: true` | OK | 公式仕様フィールド |
| ツール使用一致 | OK | 本文でWebSearch/WebFetch使用、フロントマターに含まれる |

**判定: PASS**

---

### 3.3 sdd-builder

**ファイル**: `framework/claude/agents/sdd-builder.md`

```yaml
name: sdd-builder
description: "SDD framework Builder. Implements tasks using TDD..."
model: sonnet
tools: Read, Glob, Grep, Write, Edit, Bash
background: true
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `name` フィールド | OK | 小文字・ハイフン形式 |
| `description` フィールド | OK | 有効な文字列 |
| `model: sonnet` | OK | 有効なモデルエイリアス（T3 Sonnet 設計に準拠） |
| `tools` リスト | OK | Read, Glob, Grep, Write, Edit, Bash — すべて有効 |
| `background: true` | OK | 公式仕様フィールド |
| ツール使用一致 | OK | 本文でBash使用（テスト実行等）、フロントマターに含まれる |
| `sys.modules` 禁止ルール | OK | 本文に明示的禁止制約あり |

**判定: PASS**

---

### 3.4 sdd-inspector-test

**ファイル**: `framework/claude/agents/sdd-inspector-test.md`

```yaml
name: sdd-inspector-test
description: "SDD impl review inspector (test). Executes tests and evaluates coverage quality..."
model: sonnet
tools: Read, Glob, Grep, Write, Bash
background: true
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `name` フィールド | OK | 小文字・ハイフン形式 |
| `description` フィールド | OK | 有効な文字列 |
| `model: sonnet` | OK | 有効なモデルエイリアス |
| `tools` リスト | OK | Read, Glob, Grep, Write, Bash — すべて有効 |
| `background: true` | OK | 公式仕様フィールド |
| ツール使用一致 | OK | テスト実行にBash使用、フロントマターに含まれる |

**判定: PASS**

---

### 3.5 sdd-auditor-dead-code

**ファイル**: `framework/claude/agents/sdd-auditor-dead-code.md`

```yaml
name: sdd-auditor-dead-code
description: "SDD dead code review Auditor. Synthesizes dead code Inspector findings..."
model: opus
tools: Read, Glob, Grep, Write
background: true
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `name` フィールド | OK | 小文字・ハイフン形式 |
| `description` フィールド | OK | 有効な文字列 |
| `model: opus` | OK | 有効なモデルエイリアス（T2 Brain Opus 設計に準拠） |
| `tools` リスト | OK | Read, Glob, Grep, Write — すべて有効 |
| `background: true` | OK | 公式仕様フィールド |
| ツール使用一致 | OK | CPFファイル読み書きにRead/Write使用 |

**判定: PASS**

---

### 3.6 sdd-inspector-dead-code

**ファイル**: `framework/claude/agents/sdd-inspector-dead-code.md`

```yaml
name: sdd-inspector-dead-code
description: "SDD dead code inspector (code). Detects unused functions, classes, and imports..."
model: sonnet
tools: Read, Glob, Grep, Write
background: true
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `name` フィールド | OK | 小文字・ハイフン形式 |
| `description` フィールド | OK | 有効な文字列 |
| `model: sonnet` | OK | 有効なモデルエイリアス |
| `tools` リスト | OK | Read, Glob, Grep, Write — すべて有効 |
| `background: true` | OK | 公式仕様フィールド |
| ツール使用一致 | OK | Bash なし（静的解析のみ、Grep/Glob で対応） |

**判定: PASS**

---

### 3.7 sdd-inspector-dead-settings

**ファイル**: `framework/claude/agents/sdd-inspector-dead-settings.md`

```yaml
name: sdd-inspector-dead-settings
description: "SDD dead code inspector (settings). Detects dead configuration and broken passthrough..."
model: sonnet
tools: Read, Glob, Grep, Write
background: true
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `name` フィールド | OK | 小文字・ハイフン形式 |
| `description` フィールド | OK | 有効な文字列 |
| `model: sonnet` | OK | 有効なモデルエイリアス |
| `tools` リスト | OK | すべて有効 |
| `background: true` | OK | 公式仕様フィールド |

**判定: PASS**

---

### 3.8 sdd-inspector-dead-specs

**ファイル**: `framework/claude/agents/sdd-inspector-dead-specs.md`

```yaml
name: sdd-inspector-dead-specs
description: "SDD dead code inspector (specs). Detects spec-implementation drift..."
model: sonnet
tools: Read, Glob, Grep, Write
background: true
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `name` フィールド | OK | 小文字・ハイフン形式 |
| `description` フィールド | OK | 有効な文字列 |
| `model: sonnet` | OK | 有効なモデルエイリアス |
| `tools` リスト | OK | すべて有効 |
| `background: true` | OK | 公式仕様フィールド |

**判定: PASS**

---

### 3.9 sdd-inspector-dead-tests

**ファイル**: `framework/claude/agents/sdd-inspector-dead-tests.md`

```yaml
name: sdd-inspector-dead-tests
description: "SDD dead code inspector (tests). Detects orphaned fixtures and stale test code..."
model: sonnet
tools: Read, Glob, Grep, Write
background: true
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `name` フィールド | OK | 小文字・ハイフン形式 |
| `description` フィールド | OK | 有効な文字列 |
| `model: sonnet` | OK | 有効なモデルエイリアス |
| `tools` リスト | OK | すべて有効 |
| `background: true` | OK | 公式仕様フィールド |

**判定: PASS**

---

### 3.10 sdd-inspector-visual

**ファイル**: `framework/claude/agents/sdd-inspector-visual.md`

```yaml
name: sdd-inspector-visual
description: "SDD impl review inspector (visual). Design system compliance and aesthetic quality review..."
model: sonnet
tools: Read, Glob, Grep, Write, Bash
background: true
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `name` フィールド | OK | 小文字・ハイフン形式 |
| `description` フィールド | OK | 有効な文字列 |
| `model: sonnet` | OK | 有効なモデルエイリアス |
| `tools` リスト | OK | Read, Glob, Grep, Write, Bash — すべて有効 |
| `background: true` | OK | 公式仕様フィールド |
| ツール使用一致 | OK | playwright-cli 実行に Bash 使用、フロントマターに含まれる |
| playwright-cli 依存 | OK | `playwright-cli` は外部npmパッケージ（Bash経由）、ツールリストに追加不要 |

**判定: PASS**

---

## 4. 変更スキルの詳細検証

### 4.1 sdd-publish-setup (NEW)

**ファイル**: `framework/claude/skills/sdd-publish-setup/SKILL.md`

```yaml
description: Set up CI/CD publish pipeline (GitHub Actions + Trusted Publisher)
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `description` フィールド | OK | 有効な文字列（1024文字以下） |
| `allowed-tools` | OK | すべて有効なツール名 |
| `argument-hint` | なし | オプションフィールドのため省略OK |
| `name` フィールド | なし（省略） | ディレクトリ名 `sdd-publish-setup` から自動導出 — OK |
| settings.json エントリ | **欠落** | `Skill(sdd-publish-setup)` が settings.json の allow リストにない |

**判定: WARN — settings.json に Skill エントリ欠落（後述 §6 参照）**

---

### 4.2 sdd-reboot

**ファイル**: `framework/claude/skills/sdd-reboot/SKILL.md`

```yaml
description: Reboot project design from zero (analysis, steering reform, new roadmap + specs on feature branch)
allowed-tools: Agent, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion
argument-hint: [name] [-y]
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `description` フィールド | OK | 有効な文字列 |
| `allowed-tools` | OK | `Agent` を含む — reboot が Analyst を dispatch することに対応 |
| `argument-hint` | OK | 有効な形式 |
| 内部 Agent dispatch | OK | `Agent(subagent_type="sdd-analyst", run_in_background=true)` を refs/reboot.md で使用 |
| sdd-analyst エントリ | OK | settings.json の `Agent(sdd-analyst)` エントリ存在 |

**判定: PASS**

---

### 4.3 sdd-release

**ファイル**: `framework/claude/skills/sdd-release/SKILL.md`

```yaml
description: Create a versioned release (branch, tag, push)
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: [patch|minor|major|vX.Y.Z] [summary]
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `description` フィールド | OK | 有効な文字列 |
| `allowed-tools` | OK | すべて有効 |
| `argument-hint` | OK | 有効な形式 |

**判定: PASS**

---

### 4.4 sdd-review-self

**ファイル**: `framework/claude/skills/sdd-review-self/SKILL.md`

```yaml
description: Self-review for SDD framework development (framework-internal use only)
allowed-tools: Agent, Bash, Read, Glob, Grep
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `description` フィールド | OK | 有効な文字列 |
| `allowed-tools` | OK | `Agent` 含む — 4つのサブエージェント dispatch に対応 |
| `argument-hint` | なし | オプションのため省略OK |
| 内部 Agent dispatch | **要注意** | `Agent(subagent_type="general-purpose", model="sonnet", run_in_background=true)` を使用 |

**general-purpose に関する考察**:
公式ドキュメントによると `general-purpose` はビルトインサブエージェント。`.claude/agents/` にファイル定義は不要。しかしエージェント定義にない `model="sonnet"` パラメータを Agent ツールに渡している点が懸念対象。

公式 SDK ドキュメントの `Task`/`Agent` ツール入力スキーマでは `subagent_type` と `prompt` が主要パラメータ。`model` パラメータが Agent ツール呼び出し時に有効かどうかは公式ドキュメントに明示記載なし。フロントマターの `model` フィールド（エージェント定義レベル）と混同の可能性あり。

ただし、この問題はB18以前から存在しており（sdd-review-self自体はB18キャッシュ対象外だが、dispatch パターンの変更は今回検出）、実際の動作に影響があるかは不明。LOW扱いとする。

**判定: PASS (LOW 注記あり)**

---

### 4.5 sdd-roadmap

**ファイル**: `framework/claude/skills/sdd-roadmap/SKILL.md`

```yaml
description: Unified spec lifecycle (design, implement, review, roadmap management)
allowed-tools: Agent, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion
argument-hint: design <feature> | impl <feature> [tasks] | review design|impl <feature> [flags] | review dead-code [flags] | run [--gate] [--consensus N] | revise [feature] [instructions] | create [-y] | update | delete | -y
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `description` フィールド | OK | 有効な文字列 |
| `allowed-tools` | OK | `Agent` 含む — 多数のサブエージェント dispatch に対応 |
| `argument-hint` | OK | 有効な形式 |
| refs/ ファイル参照 | OK | design.md, impl.md, review.md, run.md, revise.md, crud.md — すべて存在確認済み |

**判定: PASS**

---

### 4.6 sdd-status

**ファイル**: `framework/claude/skills/sdd-status/SKILL.md`

```yaml
description: Check progress and analyze downstream impact
allowed-tools: Read, Glob, Grep
argument-hint: [feature-name] [--impact]
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `description` フィールド | OK | 有効な文字列 |
| `allowed-tools` | OK | 読み取り専用ツールのみ（適切） |
| `argument-hint` | OK | 有効な形式 |
| SubAgent dispatch なし | OK | Lead が直接処理（SubAgent 不要） |

**判定: PASS**

---

### 4.7 sdd-steering

**ファイル**: `framework/claude/skills/sdd-steering/SKILL.md`

```yaml
description: Set up project-wide context (create, update, delete, custom)
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion
argument-hint: [-y] [custom]
```

| 検証項目 | 結果 | 備考 |
|---------|------|------|
| `description` フィールド | OK | 有効な文字列 |
| `allowed-tools` | OK | すべて有効 |
| `argument-hint` | OK | 有効な形式 |
| `/sdd-publish-setup` Skill 呼び出し | **注意** | 本文内で Skill ツール呼び出しを記述しているが、`allowed-tools` に `Skill` が含まれない |

**Skill ツール呼び出しの考察**:
`sdd-steering/SKILL.md` の Step 2 (Create Mode) Step 10 に:
> `invoke /sdd-publish-setup via Skill tool`

という記述がある。スキルから別スキルを呼び出す場合、呼び出し元スキルの `allowed-tools` に `Skill(target-skill-name)` の記述が必要。公式ドキュメントによると `allowed-tools` でスキル呼び出しを制御できる（`Skill(commit)`, `Skill(review-pr *)` など）。

`sdd-steering` の `allowed-tools` に `Skill(sdd-publish-setup)` が含まれていないため、実行時に permission エラーが発生する可能性がある。

**判定: WARN — Skill ツール呼び出しが allowed-tools に未記載**

---

## 5. settings.json 検証

**ファイル**: `framework/claude/settings.json`

### 5.1 Skill エントリ確認

| settings.json の Skill エントリ | 対応ファイル存在 | 状態 |
|--------------------------------|----------------|------|
| `Skill(sdd-roadmap)` | `framework/claude/skills/sdd-roadmap/SKILL.md` | OK |
| `Skill(sdd-steering)` | `framework/claude/skills/sdd-steering/SKILL.md` | OK |
| `Skill(sdd-status)` | `framework/claude/skills/sdd-status/SKILL.md` | OK |
| `Skill(sdd-handover)` | `framework/claude/skills/sdd-handover/SKILL.md` | OK |
| `Skill(sdd-reboot)` | `framework/claude/skills/sdd-reboot/SKILL.md` | OK |
| `Skill(sdd-release)` | `framework/claude/skills/sdd-release/SKILL.md` | OK |
| `Skill(sdd-review-self)` | `framework/claude/skills/sdd-review-self/SKILL.md` | OK |
| `Skill(sdd-publish-setup)` | **存在しない** — ファイルは存在するがエントリなし | **MISSING** |

### 5.2 Agent エントリ確認

| settings.json の Agent エントリ | 対応ファイル存在 | 状態 |
|--------------------------------|----------------|------|
| `Agent(sdd-analyst)` | `framework/claude/agents/sdd-analyst.md` | OK |
| `Agent(sdd-architect)` | `framework/claude/agents/sdd-architect.md` | OK |
| `Agent(sdd-auditor-dead-code)` | `framework/claude/agents/sdd-auditor-dead-code.md` | OK |
| `Agent(sdd-auditor-design)` | `framework/claude/agents/sdd-auditor-design.md` | OK |
| `Agent(sdd-auditor-impl)` | `framework/claude/agents/sdd-auditor-impl.md` | OK |
| `Agent(sdd-builder)` | `framework/claude/agents/sdd-builder.md` | OK |
| `Agent(sdd-conventions-scanner)` | `framework/claude/agents/sdd-conventions-scanner.md` | OK |
| `Agent(sdd-inspector-architecture)` | `framework/claude/agents/sdd-inspector-architecture.md` | OK |
| `Agent(sdd-inspector-best-practices)` | `framework/claude/agents/sdd-inspector-best-practices.md` | OK |
| `Agent(sdd-inspector-consistency)` | `framework/claude/agents/sdd-inspector-consistency.md` | OK |
| `Agent(sdd-inspector-dead-code)` | `framework/claude/agents/sdd-inspector-dead-code.md` | OK |
| `Agent(sdd-inspector-dead-settings)` | `framework/claude/agents/sdd-inspector-dead-settings.md` | OK |
| `Agent(sdd-inspector-dead-specs)` | `framework/claude/agents/sdd-inspector-dead-specs.md` | OK |
| `Agent(sdd-inspector-dead-tests)` | `framework/claude/agents/sdd-inspector-dead-tests.md` | OK |
| `Agent(sdd-inspector-e2e)` | `framework/claude/agents/sdd-inspector-e2e.md` | OK |
| `Agent(sdd-inspector-holistic)` | `framework/claude/agents/sdd-inspector-holistic.md` | OK |
| `Agent(sdd-inspector-impl-consistency)` | `framework/claude/agents/sdd-inspector-impl-consistency.md` | OK |
| `Agent(sdd-inspector-impl-holistic)` | `framework/claude/agents/sdd-inspector-impl-holistic.md` | OK |
| `Agent(sdd-inspector-impl-rulebase)` | `framework/claude/agents/sdd-inspector-impl-rulebase.md` | OK |
| `Agent(sdd-inspector-interface)` | `framework/claude/agents/sdd-inspector-interface.md` | OK |
| `Agent(sdd-inspector-quality)` | `framework/claude/agents/sdd-inspector-quality.md` | OK |
| `Agent(sdd-inspector-rulebase)` | `framework/claude/agents/sdd-inspector-rulebase.md` | OK |
| `Agent(sdd-inspector-test)` | `framework/claude/agents/sdd-inspector-test.md` | OK |
| `Agent(sdd-inspector-testability)` | `framework/claude/agents/sdd-inspector-testability.md` | OK |
| `Agent(sdd-inspector-visual)` | `framework/claude/agents/sdd-inspector-visual.md` | OK |
| `Agent(sdd-taskgenerator)` | `framework/claude/agents/sdd-taskgenerator.md` | OK |

### 5.3 逆引き確認（ファイルは存在するがエントリなし）

| エージェント/スキルファイル | settings.json エントリ | 状態 |
|---------------------------|----------------------|------|
| `framework/claude/skills/sdd-publish-setup/SKILL.md` | なし | **MISSING** |

### 5.4 Bash パーミッション確認

`settings.json` に含まれる Bash パーミッション:
- `Bash(git *)`, `Bash(mkdir *)`, `Bash(ls *)`, `Bash(mv *)`, `Bash(cp *)`, `Bash(wc *)`, `Bash(which *)`, `Bash(sed *)`, `Bash(cat *)`, `Bash(echo *)`, `Bash(diff *)`, `Bash(playwright-cli *)`, `Bash(tmux *)`, `Bash(npm *)`, `Bash(npx *)`

いずれも有効な形式。不審なワイルドカードパターンなし。`curl` などの外部通信コマンドは含まれていない（適切）。

---

## 6. CLAUDE.md Agent dispatch パターン検証

### 6.1 subagent_type と既存エージェント定義の照合

`CLAUDE.md` および refs ファイルで使用される `subagent_type` 値:

| `subagent_type` 値 | 対応エージェントファイル存在 | settings.json エントリ |
|--------------------|--------------------------|----------------------|
| `sdd-architect` | OK | OK |
| `sdd-analyst` | OK | OK |
| `sdd-builder` | OK | OK |
| `sdd-taskgenerator` | OK | OK |
| `sdd-auditor-design` | OK | OK |
| `sdd-auditor-impl` | OK | OK |
| `sdd-auditor-dead-code` | OK | OK |
| `sdd-conventions-scanner` | OK | OK |
| `sdd-inspector-*` (各種) | OK | OK |
| `general-purpose` | ビルトイン（ファイル不要） | 不要 |

すべての `subagent_type` 参照は既存のエージェント定義または公式ビルトインエージェントに対応している。

### 6.2 `run_in_background: true` の義務化確認

CLAUDE.md:
> "Lead dispatches SubAgents via `Agent` tool with `run_in_background: true` **always**. No exceptions"

refs ファイル内のすべての Agent dispatch 呼び出しで `run_in_background=true` が指定されていることを確認:
- `refs/design.md`: `Agent(subagent_type="sdd-architect", run_in_background=true)` — OK
- `refs/impl.md`: `Agent(subagent_type="sdd-taskgenerator", run_in_background=true)` / `Agent(subagent_type="sdd-builder", run_in_background=true)` — OK
- `refs/run.md`: `Agent(subagent_type="sdd-conventions-scanner", run_in_background=true)` — OK

**判定: PASS**

---

## 7. コンプライアンス状態テーブル

### Issues Found

| 重要度 | 対象 | 問題 | 場所 |
|--------|------|------|------|
| [MEDIUM] | settings.json | `Skill(sdd-publish-setup)` エントリが allow リストに存在しない | `framework/claude/settings.json` |
| [MEDIUM] | sdd-steering/SKILL.md | `Skill(sdd-publish-setup)` Skill 呼び出しが `allowed-tools` に未記載 | `framework/claude/skills/sdd-steering/SKILL.md:66` |
| [LOW] | sdd-review-self/SKILL.md | `Agent(subagent_type="general-purpose", model="sonnet", ...)` — Agent ツール呼び出し時の `model` パラメータが公式仕様に明示されていない | `framework/claude/skills/sdd-review-self/SKILL.md:57` |

### Confirmed OK

| 検証項目 | 状態 |
|---------|------|
| 全エージェントの必須フィールド (`name`, `description`) | OK |
| 全エージェントの `model` フィールド値（sonnet/opus）| OK |
| 全エージェントの `tools` リスト（有効なツール名のみ） | OK |
| 全エージェントの `background: true` フィールド | OK |
| 全スキルの `description` フィールド | OK |
| 全スキルの `allowed-tools` フィールド値 | OK |
| `argument-hint` フィールド形式 | OK |
| settings.json 全 Agent エントリと対応ファイルの一致 | OK（26エージェント全） |
| settings.json 全既存 Skill エントリと対応ファイルの一致 | OK（sdd-publish-setup 除く） |
| Agent dispatch の `subagent_type` 値と対応エージェント名の一致 | OK |
| `run_in_background: true` の全 dispatch への適用 | OK |
| B18キャッシュ済みエージェント（16体）: 変更なし | OK (cached) |
| sdd-handover スキル: 変更なし | OK (cached) |

---

## 8. 総合評価

### Overall Assessment

**検出された問題: 2件のMEDIUM + 1件のLOW**

**MEDIUM 1: `Skill(sdd-publish-setup)` が settings.json の allow リストに未登録**

`sdd-publish-setup` は v1.11.0 で新規追加されたスキルだが、`framework/claude/settings.json` の `permissions.allow` リストに `Skill(sdd-publish-setup)` エントリが存在しない。インストール後のプロジェクト環境でこのスキルが permission ブロックを受ける可能性がある。

修正: `framework/claude/settings.json` の `permissions.allow` に `"Skill(sdd-publish-setup)"` を追加する。

**MEDIUM 2: `sdd-steering` スキルの `allowed-tools` に `Skill(sdd-publish-setup)` 呼び出しが未記載**

`sdd-steering/SKILL.md` の Step 2 Create Mode Step 10 では Python プロファイル選択時に `/sdd-publish-setup` を Skill ツール経由で呼び出すことを規定しているが、`allowed-tools` フィールドに `Skill(sdd-publish-setup)` が含まれていない。公式ドキュメントに基づけば、スキルから別スキルを呼び出すには `allowed-tools` への明示的なエントリが必要。

修正: `sdd-steering/SKILL.md` の `allowed-tools` に `Skill(sdd-publish-setup)` を追加する。

**LOW: `Agent` ツール呼び出し時の `model` パラメータ**

`sdd-review-self/SKILL.md` では `Agent(subagent_type="general-purpose", model="sonnet", run_in_background=true)` というパターンを使用している。公式の Agent/Task ツールのパラメータとして `subagent_type`, `prompt`, `run_in_background` は明示されているが、`model` パラメータのツール呼び出し時指定については公式ドキュメントに明示記載がない。エージェント定義レベルの `model` フィールドとの混同リスクがある。ただし実際の動作に影響が出ていない可能性が高く、低優先度とする。

---

## 推奨修正優先度

| 優先度 | ID | 概要 | 対象ファイル |
|--------|-----|------|------------|
| P1 | M1 | settings.json に `Skill(sdd-publish-setup)` 追加 | `framework/claude/settings.json` |
| P1 | M2 | sdd-steering allowed-tools に `Skill(sdd-publish-setup)` 追加 | `framework/claude/skills/sdd-steering/SKILL.md` |
| P3 | L1 | general-purpose dispatch の `model` パラメータ動作確認（または削除検討） | `framework/claude/skills/sdd-review-self/SKILL.md:57` |
