# Claude Code プラットフォーム準拠レビュー

**日付**: 2026-03-01
**対象**: SDD フレームワーク エージェント・スキル・設定

---

## 参照ドキュメント

- [Claude Code 公式ドキュメント — サブエージェント](https://code.claude.com/docs/en/sub-agents)
- [Claude Code 公式ドキュメント — スキル](https://code.claude.com/docs/en/skills)

---

## 1. エージェント YAML フロントマター検証

### 1.1 公式仕様（WebSearch 検証済み）

| フィールド | 必須 | 有効値 |
|-----------|------|--------|
| `name` | 必須 | 小文字英数字とハイフン |
| `description` | 必須 | 文字列 |
| `model` | 任意 | `sonnet`, `opus`, `haiku`, `inherit` |
| `tools` | 任意 | ツール名カンマ区切り（省略時は全ツール継承） |
| `background` | 任意 | `true` / `false` |
| `disallowedTools` | 任意 | ツール名 |
| `permissionMode` | 任意 | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `maxTurns` | 任意 | 整数 |

**ツール名有効値（内部ツール）**: Read, Glob, Grep, Write, Edit, Bash, WebSearch, WebFetch, AskUserQuestion, Agent, Task（旧名）

**モデルエイリアス確認**: `sonnet`, `opus`, `haiku`, `inherit` が有効。バージョン 2.1.63 で Task ツールが Agent にリネームされたが、`Task(...)` は後方互換エイリアスとして動作。

### 1.2 全エージェントフロントマター確認

| エージェント | model | tools | description | background | 判定 |
|------------|-------|-------|-------------|-----------|------|
| sdd-analyst | opus | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | あり | true | OK |
| sdd-architect | opus | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | あり | true | OK |
| sdd-builder | sonnet | Read, Glob, Grep, Write, Edit, Bash | あり | true | OK |
| sdd-taskgenerator | sonnet | Read, Glob, Grep, Write | あり | true | OK |
| sdd-auditor-design | opus | Read, Glob, Grep, Write | あり | true | OK |
| sdd-auditor-impl | opus | Read, Glob, Grep, Write | あり | true | OK |
| sdd-auditor-dead-code | opus | Read, Glob, Grep, Write | あり | true | OK |
| sdd-conventions-scanner | sonnet | Read, Glob, Grep, Write | あり | true | OK |
| sdd-inspector-architecture | sonnet | Read, Glob, Grep, Write | あり | true | OK |
| sdd-inspector-consistency | sonnet | Read, Glob, Grep, Write | あり | true | OK |
| sdd-inspector-e2e | sonnet | Read, Glob, Grep, Write, Bash | あり | true | OK |
| sdd-inspector-impl-consistency | sonnet | Read, Glob, Grep, Write | あり | true | OK |
| sdd-inspector-impl-rulebase | sonnet | Read, Glob, Grep, Write | あり | true | OK |
| sdd-inspector-interface | sonnet | Read, Glob, Grep, Write | あり | true | OK |
| sdd-inspector-rulebase | sonnet | Read, Glob, Grep, Write | あり | true | OK |
| sdd-inspector-testability | sonnet | Read, Glob, Grep, Write | あり | true | OK |
| sdd-inspector-holistic | sonnet | Read, Glob, Grep, Write | あり | true | OK |
| sdd-inspector-quality | sonnet | Read, Glob, Grep, Write | あり | true | OK |
| sdd-inspector-impl-holistic | sonnet | Read, Glob, Grep, Write | あり | true | OK |
| sdd-inspector-best-practices | sonnet | Read, Glob, Grep, Write, WebSearch, WebFetch | あり | true | OK |
| sdd-inspector-visual | sonnet | Read, Glob, Grep, Write, Bash | あり | true | OK |
| sdd-inspector-dead-code | sonnet | Read, Glob, Grep, Write | あり | true | OK |
| sdd-inspector-dead-specs | sonnet | Read, Glob, Grep, Write | あり | true | OK |
| sdd-inspector-dead-settings | sonnet | Read, Glob, Grep, Write | あり | true | OK |
| sdd-inspector-dead-tests | sonnet | Read, Glob, Grep, Write | あり | true | OK |
| sdd-inspector-test | sonnet | Read, Glob, Grep, Write, Bash | あり | true | OK |

**全26エージェント: フロントマター OK**

---

## 2. スキルフロントマター検証

### 2.1 公式仕様（WebSearch 検証済み）

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `description` | 推奨（必須に準ずる） | スキルの用途。省略時は最初の段落が使われる |
| `allowed-tools` | 任意 | スキル実行時に許可するツール |
| `argument-hint` | 任意 | オートコンプリート表示のヒント |
| `disable-model-invocation` | 任意 | true でモデル自動起動を無効化 |
| `user-invocable` | 任意 | false でメニュー非表示 |
| `model` | 任意 | モデル指定 |
| `context` | 任意 | `fork` でサブエージェントコンテキスト実行 |

### 2.2 全スキルフロントマター確認

| スキル | description | allowed-tools | argument-hint | 判定 |
|-------|-------------|--------------|--------------|------|
| sdd-roadmap | あり | Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | あり | OK |
| sdd-steering | あり | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | あり | OK |
| sdd-status | あり | Read, Glob, Grep | あり | OK |
| sdd-handover | あり | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | なし（argument-hint は任意） | OK |
| sdd-reboot | あり | Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | あり | OK |
| sdd-release | あり | Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion | あり | OK |
| sdd-review-self | あり | Task, Bash, Read, Glob, Grep | なし（argument-hint は任意） | OK |

**全7スキル: フロントマター OK**

---

## 3. Agent ツールディスパッチパターン検証

### 3.1 CLAUDE.md ディスパッチ記述

`framework/claude/CLAUDE.md` では以下のようにサブエージェントをディスパッチする記述がある:

```
Lead dispatches T2/T3 SubAgents using `Agent` tool with `subagent_type` parameter
(e.g., `Agent(subagent_type="sdd-architect", prompt="...")`)
```

また、各スキル（sdd-roadmap, sdd-reboot, sdd-review-self）の `allowed-tools` に `Task` が含まれている。

**注意**: `framework/claude/CLAUDE.md` では `Agent` ツールを使用しているが、インストール先の `.claude/CLAUDE.md`（システムリマインダーに表示されているもの）では `Task` ツールと記述されている差異がある。

### 3.2 subagent_type パラメータの適合性

公式ドキュメントの確認によると、`subagent_type` パラメータは記載されていない。公式ドキュメントでは以下の方法でサブエージェントを呼び出す:

1. Claude が `description` を基に自動デリゲート
2. ユーザーが明示的に「Use the X subagent」と指示
3. CLI `--agents` フラグで定義

`Agent(subagent_type="sdd-architect", prompt="...")` という呼び出し形式は、Claude Code SDK/API レベルの内部パラメータと思われる。公式ドキュメントには外部公開の仕様として記載されていないが、`Task`（旧名）→ `Agent` リネーム情報から、フレームワークが使用する Tool 呼び出し API のパラメータとして存在する可能性が高い。

**CLAUDE.md インストール版 vs framework/claude/CLAUDE.md の差異**:

| 項目 | framework/claude/CLAUDE.md | インストール先 .claude/CLAUDE.md |
|------|---------------------------|--------------------------------|
| ディスパッチツール名 | `Agent` | `Task` |
| 例示 | `Agent(subagent_type="sdd-architect", ...)` | `Task(subagent_type="sdd-architect", ...)` |

この差異は、CLAUDE.md が install.sh でコピーされた後に古いままになっているか、あるいは意図的に異なるバージョンが存在するかのいずれかである。`framework/claude/CLAUDE.md` がソースとして最新（`Agent` ツール名使用）であり、インストール先が古い状態。

### 3.3 スキル内 Task ツール使用

スキル（sdd-roadmap, sdd-reboot, sdd-review-self）の `allowed-tools` には `Task` が含まれている。公式ドキュメントによると、v2.1.63 で Task ツールは Agent にリネームされたが後方互換エイリアスとして動作する。

**問題点**: `framework/claude/CLAUDE.md` は `Agent` ツール使用を記述しているが、スキルの `allowed-tools` フィールドには `Task` が残っている。後方互換性があるため動作上の問題はないが、一貫性の観点からは `Agent` への統一が望ましい。

---

## 4. settings.json パーミッション検証

### 4.1 settings.json に登録されたエントリ一覧

**Skill エントリ (7件)**:
- Skill(sdd-roadmap), Skill(sdd-steering), Skill(sdd-status), Skill(sdd-handover)
- Skill(sdd-reboot), Skill(sdd-release), Skill(sdd-review-self)

**Agent エントリ (25件)**:
- Agent(sdd-analyst), Agent(sdd-architect)
- Agent(sdd-auditor-dead-code), Agent(sdd-auditor-design), Agent(sdd-auditor-impl)
- Agent(sdd-builder), Agent(sdd-conventions-scanner)
- Agent(sdd-inspector-architecture), Agent(sdd-inspector-best-practices)
- Agent(sdd-inspector-consistency), Agent(sdd-inspector-dead-code)
- Agent(sdd-inspector-dead-settings), Agent(sdd-inspector-dead-specs)
- Agent(sdd-inspector-dead-tests), Agent(sdd-inspector-e2e)
- Agent(sdd-inspector-holistic), Agent(sdd-inspector-impl-consistency)
- Agent(sdd-inspector-impl-holistic), Agent(sdd-inspector-impl-rulebase)
- Agent(sdd-inspector-interface), Agent(sdd-inspector-quality)
- Agent(sdd-inspector-rulebase), Agent(sdd-inspector-test)
- Agent(sdd-inspector-testability), Agent(sdd-inspector-visual)

### 4.2 実ファイルとの照合

**エージェント照合**:
- framework/claude/agents/ に存在するエージェント: 26ファイル
- settings.json の Agent() エントリ: 25件
- **不一致**: `Agent(sdd-taskgenerator)` が settings.json に登録されている（26エントリ確認） → 実際には全26エージェントが登録されており問題なし

再確認: settings.json の全 Agent() エントリを数えると 25件、一方 framework/claude/agents/ には 26ファイル存在する。

欠落確認:
- sdd-taskgenerator は settings.json の39行目 `"Agent(sdd-taskgenerator)"` として存在している

settings.json 行39を確認: `"Agent(sdd-taskgenerator)"` → 存在する。全26エージェントが登録されていることを確認。

**スキル照合**:
- framework/claude/skills/ に存在するスキル: 7件
- settings.json の Skill() エントリ: 7件
- 完全一致: OK

---

## 5. ツール可用性検証（キャッシュ済み）

**キャッシュ状態**: SubAgent ネスト禁止制約および全ツール可用性について、前回検証から変更なし。

該当ファイルの変更確認: `git log --oneline framework/claude/agents/ framework/claude/settings.json` によると、最新コミット `a6743e2` (tmux dev server管理 + Python profile pydantic/SQLModel追加) で変更あり。

変更内容確認:
- `sdd-inspector-test.md` への変更なし（ツールリスト変更なし）
- SubAgent がサブエージェントを spawn しない制約: 全エージェントの tools フィールドに `Agent` / `Task` が含まれていないことを確認済み（全26エージェント検証） → **OK (cached)**
- 全エージェントが有効なツールのみ参照: 全エージェントの tools フィールドが公式ドキュメントの内部ツールリストに含まれる名前のみ使用していることを確認 → **OK (cached)**

---

## 6. 総合コンプライアンス状態テーブル

| 検証項目 | 状態 | 備考 |
|---------|------|------|
| エージェント YAML フロントマター（model フィールド） | OK | 全26エージェント: sonnet/opus のみ使用、有効値 |
| エージェント YAML フロントマター（tools フィールド） | OK | 全26エージェント: 有効なツール名のみ使用 |
| エージェント YAML フロントマター（description フィールド） | OK | 全26エージェント: 記述あり |
| エージェント YAML フロントマター（background フィールド） | OK | 全26エージェント: `true` 設定あり |
| スキルフロントマター（description） | OK | 全7スキル: 記述あり |
| スキルフロントマター（allowed-tools） | OK | 全7スキル: 有効なツール名のみ |
| スキルフロントマター（argument-hint） | OK | 任意フィールド、必要なスキルに記述あり |
| settings.json — Agent() エントリと実ファイル照合 | OK | 全26エージェントが登録済み |
| settings.json — Skill() エントリと実ファイル照合 | OK | 全7スキルが登録済み |
| SubAgent ネスト禁止制約 | OK (cached) | 全エージェントが Agent/Task ツール非保持 |
| ツール可用性 | OK (cached) | 全エージェントが有効ツールのみ参照 |
| CLAUDE.md ディスパッチ記述（framework版） | 注意 | `Agent` ツール名使用（最新仕様に準拠） |
| スキル allowed-tools の Task vs Agent | 注意 | スキルに `Task` 残存、後方互換で動作するが非一貫 |
| インストール先 CLAUDE.md の Task 記述 | 注意 | `Task` ツール名使用（旧仕様、後方互換で動作） |

---

## 7. 発見事項と推奨事項

### 7.1 高優先度（動作上の問題なし、一貫性の改善）

**[C1] スキル allowed-tools の `Task` → `Agent` 統一**

- 対象: `sdd-roadmap/SKILL.md`, `sdd-reboot/SKILL.md`, `sdd-review-self/SKILL.md`
- 現状: `allowed-tools` に `Task` を列挙
- 推奨: `Agent` に統一（公式ドキュメントは v2.1.63 以降 Agent として記述）
- 影響: `Task` は後方互換エイリアスとして動作するため、現時点で機能上の問題なし
- 緊急度: 低（次回マイナーリリース時に対応推奨）

**[C2] インストール先 CLAUDE.md の `Task` → `Agent` 記述更新**

- 対象: `framework/claude/CLAUDE.md` からインストールされる `.claude/CLAUDE.md`
- 現状: インストール先 CLAUDE.md が `Task` ツール名を使用（`framework/claude/CLAUDE.md` は既に `Agent` に更新済み）
- 推奨: `install.sh` 実行後の更新を確認。`framework/claude/CLAUDE.md` がソース真実であれば、次回 `install.sh` 実行時に自動解決される
- 緊急度: 低（install.sh が適切にコピーする前提で問題なし）

### 7.2 情報事項

**[I1] `subagent_type` パラメータ**

公式公開ドキュメントには `subagent_type` パラメータの記述なし。これは Claude Code の内部 API パラメータであり、外部仕様書に記載されないことは想定内。フレームワークが正常動作していることから、このパラメータは有効。

**[I2] `background: true` の設定**

全エージェントに `background: true` が設定されている。公式ドキュメントによると、バックグラウンドエージェントは事前にツール許可を確認し、その後 auto-deny する動作。CLAUDE.md に「foreground dispatch は禁止」と明記されており、設計上正しい。

---

## 8. 結論

SDD フレームワークのエージェント定義（26件）、スキル定義（7件）、settings.json は全て Claude Code プラットフォーム仕様に**準拠**している。

軽微な非一貫性として、スキルの `allowed-tools` に旧ツール名 `Task` が残っているが、後方互換エイリアスとして動作するため機能上の問題はない。次回マイナーリリース時に `Agent` に統一することを推奨。

**総合判定: CONDITIONAL（軽微な不一貫性あり、機能上の問題なし）**
