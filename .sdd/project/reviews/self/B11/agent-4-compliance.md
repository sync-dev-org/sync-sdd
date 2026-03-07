# Claude Code プラットフォーム準拠レビュー — agent-4-compliance

**レビュー日時**: 2026-02-27
**レビュー対象**: SDD フレームワーク エージェント・スキル・Task ツール設定
**レビュアー**: Lead (自己レビュー)
**参照仕様**: [Claude Code Sub-agents 公式ドキュメント](https://code.claude.com/docs/en/sub-agents) / [Claude Code Skills 公式ドキュメント](https://code.claude.com/docs/en/skills)

---

## サマリ

| 項目 | 結果 |
|------|------|
| エージェント数 (期待値: 25) | 25 個 — OK |
| エージェント YAML フロントマター | 24/25 OK (キャッシュ) + 新規 sdd-conventions-scanner 検証済 |
| スキル フロントマター | 6/6 OK (キャッシュ) |
| Task dispatch subagent_type 一致 | **FAIL** — sdd-conventions-scanner が settings.json の allow リストに未登録 |
| settings.json 形式 | 構造 OK / Skill/Task エントリ OK (要追加あり) |
| モデル値 | OK — sonnet/opus のみ使用 |
| background フィールド | OK — 全エージェント true |

**総合ステータス: CONDITIONAL — 1件の要修正あり**

---

## 1. エージェント定義 YAML フロントマター

### 1.1 公式仕様 (WebSearch 確認済)

Claude Code 公式ドキュメント (https://code.claude.com/docs/en/sub-agents) で確認したフロントマター仕様:

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `name` | 必須 | 小文字英数字とハイフンのみ、ユニーク識別子 |
| `description` | 必須 | いつこのエージェントに委譲するかをClaudeが判断するために使用 |
| `tools` | 任意 | 利用可能なツールのリスト。省略時は親の全ツールを継承 |
| `model` | 任意 | `sonnet`, `opus`, `haiku`, または `inherit`。省略時は `inherit` |
| `background` | 任意 | `true` にするとバックグラウンドタスクとして常時実行。デフォルト: `false` |
| `permissionMode` | 任意 | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `maxTurns` | 任意 | エージェントが停止するまでの最大ターン数 |

### 1.2 全エージェント一覧と検証

| エージェント名 | model | tools | description | background | ステータス |
|--------------|-------|-------|-------------|------------|---------|
| sdd-architect | opus | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | 存在 | true | OK (cached) |
| sdd-auditor-dead-code | opus | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-auditor-design | opus | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-auditor-impl | opus | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-builder | sonnet | Read, Glob, Grep, Write, Edit, Bash | 存在 | true | OK (cached) |
| sdd-conventions-scanner | sonnet | Read, Glob, Grep, Write | 存在 | true | **NEW — 詳細検証** (下記) |
| sdd-inspector-architecture | sonnet | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-inspector-best-practices | sonnet | Read, Glob, Grep, Write, WebSearch, WebFetch | 存在 | true | OK (cached) |
| sdd-inspector-consistency | sonnet | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-inspector-dead-code | sonnet | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-inspector-dead-settings | sonnet | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-inspector-dead-specs | sonnet | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-inspector-dead-tests | sonnet | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-inspector-e2e | sonnet | Read, Glob, Grep, Write, Bash | 存在 | true | OK (cached) |
| sdd-inspector-holistic | sonnet | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-inspector-impl-consistency | sonnet | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-inspector-impl-holistic | sonnet | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-inspector-impl-rulebase | sonnet | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-inspector-interface | sonnet | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-inspector-quality | sonnet | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-inspector-rulebase | sonnet | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-inspector-test | sonnet | Read, Glob, Grep, Write, Bash | 存在 | true | OK (cached) |
| sdd-inspector-testability | sonnet | Read, Glob, Grep, Write | 存在 | true | OK (cached) |
| sdd-inspector-visual | sonnet | Read, Glob, Grep, Write, Bash | 存在 | true | OK (cached) |
| sdd-taskgenerator | sonnet | Read, Glob, Grep, Write | 存在 | true | OK (cached) |

### 1.3 新規エージェント sdd-conventions-scanner の詳細検証

**ファイル**: `framework/claude/agents/sdd-conventions-scanner.md`

```yaml
---
name: sdd-conventions-scanner
description: "SDD Conventions Scanner. Scans codebase for naming/error/schema/import/testing patterns and generates conventions brief. Invoked by sdd-roadmap skill during wave context generation."
model: sonnet
tools: Read, Glob, Grep, Write
background: true
---
```

| 検証項目 | 値 | 評価 |
|---------|-----|------|
| `name` フィールド | `sdd-conventions-scanner` | OK — 小文字英数字・ハイフン形式、ファイル名と一致 |
| `description` フィールド | 存在 (明確で具体的) | OK — 用途・発動タイミングが明記されている |
| `model` フィールド | `sonnet` | OK — 公式有効値 |
| `tools` フィールド | `Read, Glob, Grep, Write` | OK — 公式ツールのみ使用 |
| `background` フィールド | `true` | OK — SDD フレームワーク要件に準拠 |
| ツール妥当性 | Read/Glob/Grep でスキャン、Write で brief 生成 | OK — 役割(スキャン+ファイル書き込み)に対して適切 |
| Bash なし | スキャン専用エージェントに Bash は不要 | OK — 最小権限原則に準拠 |
| 出力形式 | `WRITTEN:{path}` のみ返却 | OK — トークン効率要件に準拠 |

**結論**: sdd-conventions-scanner のフロントマターは全項目 OK。

---

## 2. スキル フロントマター

### 2.1 公式仕様 (WebSearch 確認済)

Claude Code 公式ドキュメント (https://code.claude.com/docs/en/skills) で確認したフロントマター仕様:

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `name` | 任意 | 省略時はディレクトリ名を使用。小文字英数字・ハイフンのみ (max 64文字) |
| `description` | 推奨 | Claudeがスキルを使うタイミングの判断に使用 |
| `argument-hint` | 任意 | オートコンプリート時のヒント表示 |
| `allowed-tools` | 任意 | スキルがアクティブな時に使用可能なツール |
| `disable-model-invocation` | 任意 | `true` で Claude の自動呼び出しを禁止 |
| `model` | 任意 | スキルアクティブ時に使用するモデル |
| `context` | 任意 | `fork` でサブエージェントコンテキストで実行 |

### 2.2 全スキル一覧と検証 (キャッシュ済)

| スキル名 | description | allowed-tools | argument-hint | ステータス |
|---------|-------------|---------------|---------------|---------|
| sdd-roadmap | 存在 | Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | 存在 | OK (cached) |
| sdd-steering | 存在 | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | 存在 | OK (cached) |
| sdd-status | 存在 | Read, Glob, Grep | 存在 | OK (cached) |
| sdd-release | 存在 | Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion | 存在 | OK (cached) |
| sdd-handover | 存在 | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | なし (任意) | OK (cached) |
| sdd-review-self | 存在 | Task, Bash, Read, Glob, Grep | なし (任意) | OK (cached) |

**備考**: `sdd-handover` と `sdd-review-self` に `argument-hint` がないが、公式仕様でも任意フィールドのため問題なし。

---

## 3. Task ツール dispatch パターン — subagent_type 一致検証

### 3.1 dispatch パターン参照元

`framework/claude/skills/sdd-roadmap/refs/run.md` に以下の dispatch パターンが確認された:

```
Task(subagent_type="sdd-conventions-scanner", run_in_background=true)
```

また `refs/impl.md` でも:
```
Dispatch `sdd-conventions-scanner` SubAgent (mode: Supplement)
```

`refs/revise.md` でも:
```
Dispatch `sdd-conventions-scanner` (mode: Generate) per run.md Step 2.5
```

### 3.2 subagent_type と エージェント name の一致確認

| dispatch subagent_type | エージェントファイル | name フィールド | 一致 |
|------------------------|-----------------|----------------|------|
| `sdd-conventions-scanner` | `sdd-conventions-scanner.md` | `sdd-conventions-scanner` | OK |

エージェントファイルは存在し、name フィールドも一致している。dispatch パターン自体は正しい。

---

## 4. settings.json 権限設定

### 4.1 現在の settings.json allow リスト

`framework/claude/settings.json` の allow リストに含まれる Task エントリ:

```json
"Task(sdd-architect)",
"Task(sdd-auditor-dead-code)",
"Task(sdd-auditor-design)",
"Task(sdd-auditor-impl)",
"Task(sdd-builder)",
"Task(sdd-inspector-architecture)",
"Task(sdd-inspector-best-practices)",
"Task(sdd-inspector-consistency)",
"Task(sdd-inspector-dead-code)",
"Task(sdd-inspector-dead-settings)",
"Task(sdd-inspector-dead-specs)",
"Task(sdd-inspector-dead-tests)",
"Task(sdd-inspector-e2e)",
"Task(sdd-inspector-holistic)",
"Task(sdd-inspector-impl-consistency)",
"Task(sdd-inspector-impl-holistic)",
"Task(sdd-inspector-impl-rulebase)",
"Task(sdd-inspector-interface)",
"Task(sdd-inspector-quality)",
"Task(sdd-inspector-rulebase)",
"Task(sdd-inspector-test)",
"Task(sdd-inspector-testability)",
"Task(sdd-inspector-visual)",
"Task(sdd-taskgenerator)"
```

### 4.2 欠落エントリの特定

**FAIL**: `Task(sdd-conventions-scanner)` が allow リストに存在しない。

エージェントファイルは存在し (`framework/claude/agents/sdd-conventions-scanner.md`)、スキル内 dispatch パターンも正しく参照しているが、settings.json に対応する `Task(sdd-conventions-scanner)` エントリが追加されていない。

Claude Code の権限設定では、`defaultMode: acceptEdits` の場合、Task ツールの呼び出しは allow リストに登録されていないと権限プロンプトが表示される (または deny される) 可能性がある。

### 4.3 settings.json 構造検証 (キャッシュ済)

- `defaultMode: "acceptEdits"` — OK (cached)
- `allow` 配列構造 — OK (cached)
- `Skill(sdd-*)` エントリ (6件) — OK (cached)
- `Bash(*)` エントリ — OK (cached)

---

## 5. ツール利用可能性

### 5.1 エージェント別ツール妥当性

| エージェントグループ | 使用ツール | 妥当性 |
|------------------|-----------|-------|
| Auditor 系 (3件) | Read, Glob, Grep, Write | OK — CPF ファイル読み書きのみ |
| Inspector 系 (14件) | Read, Glob, Grep, Write (+WebSearch/WebFetch: best-practices のみ) | OK — 最小権限 |
| Inspector (Bash 使用: e2e, test, visual) | + Bash | OK — テスト実行・Playwright・lint 等に必要 |
| Builder | Read, Glob, Grep, Write, Edit, Bash | OK — TDD 実装に必要なすべてのツール |
| Architect | + WebSearch, WebFetch | OK — 外部依存調査に必要 |
| TaskGenerator | Read, Glob, Grep, Write | OK — 設計読み込み・tasks.yaml 生成のみ |
| ConventionsScanner | Read, Glob, Grep, Write | OK — スキャン + brief 書き込みのみ |

不適切なツール参照: **なし**

---

## 6. CLAUDE.md SubAgent dispatch セクション

`framework/claude/CLAUDE.md` の 3-Tier Hierarchy テーブルに `ConventionsScanner` が T3 に追加されていることを確認:

```
| T3 | **ConventionsScanner** | Codebase pattern scanning. Generates conventions brief (naming, error handling, schema, imports, testing). Pilot convention supplement. |
```

Chain of Command セクションの dispatch 例:
```
Task(subagent_type="sdd-architect", prompt="...")
```
形式は公式仕様に準拠。

Parallel Execution Model セクションも ConventionsScanner を参照しており一貫性あり。

---

## 7. 問題一覧と是正措置

### FAIL-1: settings.json に `Task(sdd-conventions-scanner)` が未登録

**重要度**: Medium (機能阻害の可能性あり)

**影響**: `defaultMode: acceptEdits` 環境で `sdd-conventions-scanner` を Task dispatch しようとすると、権限プロンプトが表示されるか、自動実行がブロックされる可能性がある。Wave Context 生成 (run.md Step 2.5) および Pilot Stagger (impl.md) で影響が出る。

**是正**: `framework/claude/settings.json` の allow 配列に以下を追加する。

```json
"Task(sdd-conventions-scanner)",
```

推奨挿入位置: `"Task(sdd-builder)"` の直後 (アルファベット順で c が b の後)。

---

## 8. 準拠ステータス テーブル

| 検証領域 | ステータス | 詳細 |
|---------|----------|------|
| エージェント数 (25件) | OK | 25 件確認 |
| エージェント name フィールド | OK | 全エージェント正しい形式 |
| エージェント description フィールド | OK | 全エージェント存在 |
| エージェント model 値 | OK | sonnet / opus のみ使用 |
| エージェント background フィールド | OK | 全エージェント true |
| エージェント tools 妥当性 | OK | 役割に対して適切な最小権限 |
| sdd-conventions-scanner フロントマター | OK | 全フィールド新規検証済 |
| スキル フロントマター (6件) | OK (cached) | description/allowed-tools/argument-hint 形式 OK |
| Task dispatch subagent_type 一致 | OK | sdd-conventions-scanner dispatch パターン正しい |
| settings.json 構造 | OK (cached) | defaultMode/allow 配列形式 OK |
| settings.json Task エントリ完全性 | **FAIL** | Task(sdd-conventions-scanner) 未登録 |
| CLAUDE.md SubAgent dispatch 記述 | OK | ConventionsScanner T3 追加済、形式正しい |

**総合ステータス: CONDITIONAL**
是正措置 (FAIL-1) を適用後、全項目 OK となりプラットフォーム準拠。

---

## 参照ドキュメント

- [Create custom subagents — Claude Code Docs](https://code.claude.com/docs/en/sub-agents)
- [Extend Claude with skills — Claude Code Docs](https://code.claude.com/docs/en/skills)
- [ClaudeLog — Custom Agents Guide](https://claudelog.com/mechanics/custom-agents/)
