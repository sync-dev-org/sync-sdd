# Claude Code プラットフォーム準拠レビュー

**実施日**: 2026-02-27
**レビュー対象**: SDD フレームワーク エージェント定義、スキル定義、Task ツール使用
**レビュアー**: Claude Code Platform Compliance Reviewer
**前回キャッシュ (B13)**: 25エージェント定義のうち sdd-analyst.md 以外全OK、6スキルのうち sdd-reboot 以外全OK

---

## 検証方針

- **キャッシュ済み項目**: ファイル変更がない場合は「OK (cached)」として再検証省略
- **未コミット変更あり (要フル検証)**:
  - `framework/claude/agents/sdd-analyst.md`
  - `framework/claude/skills/sdd-reboot/SKILL.md`
- **WebSearch 検証**: 上記2ファイルについて公式ドキュメント（code.claude.com）で仕様照合を実施

---

## 公式仕様サマリー（WebSearch 検証結果）

### エージェント定義フォーマット（code.claude.com/docs/en/sub-agents）

**必須フィールド**: `name`、`description`
**オプションフィールド**: `tools`、`disallowedTools`、`model`、`permissionMode`、`maxTurns`、`skills`、`mcpServers`、`hooks`、`memory`、`background`、`isolation`

**model 有効値**: `sonnet`、`opus`、`haiku`、`inherit`（省略時は `inherit` がデフォルト）
**background フィールド**: `true` で常に background task として実行。これは公式サポート済みのオプションフィールド。

### スキル定義フォーマット（code.claude.com/docs/en/skills）

**推奨フィールド**: `description`（必須ではないが推奨）
**オプションフィールド**: `name`、`argument-hint`、`disable-model-invocation`、`user-invocable`、`allowed-tools`、`model`、`context`、`agent`、`hooks`

**allowed-tools**: ツール名のカンマ区切りリスト。`Bash(gh *)` のような制約表記も有効。
**argument-hint**: 例: `[issue-number]`、`[filename] [format]`

---

## 1. sdd-analyst.md — フル検証

**ファイル**: `framework/claude/agents/sdd-analyst.md`

```yaml
---
name: sdd-analyst
description: "SDD Analyst. Performs holistic project analysis and proposes zero-based redesign (spec decomposition + steering reform). Invoked by sdd-reboot skill."
model: opus
tools: Read, Glob, Grep, Write, Edit, WebSearch, WebFetch
background: true
---
```

| 項目 | 値 | 判定 | 備考 |
|------|-----|------|------|
| `name` | `sdd-analyst` | OK | 英小文字・ハイフン形式 |
| `description` | 存在、明確 | OK | 必須フィールド充足 |
| `model` | `opus` | OK | 有効値（sonnet/opus/haiku/inherit） |
| `tools` | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | OK | Claude Code 標準ツール、全て有効 |
| `background` | `true` | OK | 公式サポート済みオプションフィールド |

**結果**: PASS — 全フィールドが公式仕様に準拠。

---

## 2. sdd-reboot SKILL.md — フル検証

**ファイル**: `framework/claude/skills/sdd-reboot/SKILL.md`

```yaml
---
description: Reboot project design from zero (analysis, steering reform, new roadmap + specs on feature branch)
allowed-tools: Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion
argument-hint: [name] [-y]
---
```

| 項目 | 値 | 判定 | 備考 |
|------|-----|------|------|
| `description` | 存在、明確 | OK | 推奨フィールド充足 |
| `allowed-tools` | Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | OK | 公式ドキュメント記載の有効ツール |
| `argument-hint` | `[name] [-y]` | OK | 公式仕様の形式に準拠 |

**注意点**: `Task` が `allowed-tools` に制約なしで記載されている。公式仕様では `Task` を tools に含める場合、`Task(worker, researcher)` 形式で特定 subagent_type への制限が可能だが、制限なし `Task` も有効（全 subagent type を許可）。スキルは Lead（メインスレッド）が実行するため、Task の spawn 能力は適切。

**結果**: PASS — 全フィールドが公式仕様に準拠。

---

## 3. 全エージェント定義 — キャッシュ済み検証

**対象**: 25エージェント中 sdd-analyst.md 以外の24ファイル（B13 で全OK確認済み）

git status により上記24ファイルに変更なし。キャッシュ検証有効。

**結果**: OK (cached) — 全24ファイル準拠（B13 検証結果を継承）

---

## 4. 全スキル定義 — キャッシュ済み検証

**対象**: 7スキル中 sdd-reboot 以外の6ファイル（B13 で全OK確認済み）

git status により上記6ファイルに変更なし。キャッシュ検証有効。

**結果**: OK (cached) — 全6ファイル準拠（B13 検証結果を継承）

---

## 5. settings.json permissions — キャッシュ済み検証

**Bash() エントリ**: OK (cached)
**defaultMode**: OK (cached)

**Skill() エントリ検証**:

| settings.json エントリ | 対応ファイル | 存在確認 |
|------------------------|-------------|---------|
| `Skill(sdd-roadmap)` | `framework/claude/skills/sdd-roadmap/SKILL.md` | OK |
| `Skill(sdd-steering)` | `framework/claude/skills/sdd-steering/SKILL.md` | OK |
| `Skill(sdd-status)` | `framework/claude/skills/sdd-status/SKILL.md` | OK |
| `Skill(sdd-handover)` | `framework/claude/skills/sdd-handover/SKILL.md` | OK |
| `Skill(sdd-reboot)` | `framework/claude/skills/sdd-reboot/SKILL.md` | OK |
| `Skill(sdd-release)` | `framework/claude/skills/sdd-release/SKILL.md` | OK |
| `Skill(sdd-review-self)` | `framework/claude/skills/sdd-review-self/SKILL.md` | OK |

**Task() エントリ検証**:

| settings.json エントリ | 対応 agents ファイル | 存在確認 |
|------------------------|---------------------|---------|
| `Task(sdd-analyst)` | `sdd-analyst.md` | OK |
| `Task(sdd-architect)` | `sdd-architect.md` | OK |
| `Task(sdd-auditor-dead-code)` | `sdd-auditor-dead-code.md` | OK |
| `Task(sdd-auditor-design)` | `sdd-auditor-design.md` | OK |
| `Task(sdd-auditor-impl)` | `sdd-auditor-impl.md` | OK |
| `Task(sdd-builder)` | `sdd-builder.md` | OK |
| `Task(sdd-conventions-scanner)` | `sdd-conventions-scanner.md` | OK |
| `Task(sdd-inspector-architecture)` | `sdd-inspector-architecture.md` | OK |
| `Task(sdd-inspector-best-practices)` | `sdd-inspector-best-practices.md` | OK |
| `Task(sdd-inspector-consistency)` | `sdd-inspector-consistency.md` | OK |
| `Task(sdd-inspector-dead-code)` | `sdd-inspector-dead-code.md` | OK |
| `Task(sdd-inspector-dead-settings)` | `sdd-inspector-dead-settings.md` | OK |
| `Task(sdd-inspector-dead-specs)` | `sdd-inspector-dead-specs.md` | OK |
| `Task(sdd-inspector-dead-tests)` | `sdd-inspector-dead-tests.md` | OK |
| `Task(sdd-inspector-e2e)` | `sdd-inspector-e2e.md` | OK |
| `Task(sdd-inspector-holistic)` | `sdd-inspector-holistic.md` | OK |
| `Task(sdd-inspector-impl-consistency)` | `sdd-inspector-impl-consistency.md` | OK |
| `Task(sdd-inspector-impl-holistic)` | `sdd-inspector-impl-holistic.md` | OK |
| `Task(sdd-inspector-impl-rulebase)` | `sdd-inspector-impl-rulebase.md` | OK |
| `Task(sdd-inspector-interface)` | `sdd-inspector-interface.md` | OK |
| `Task(sdd-inspector-quality)` | `sdd-inspector-quality.md` | OK |
| `Task(sdd-inspector-rulebase)` | `sdd-inspector-rulebase.md` | OK |
| `Task(sdd-inspector-test)` | `sdd-inspector-test.md` | OK |
| `Task(sdd-inspector-testability)` | `sdd-inspector-testability.md` | OK |
| `Task(sdd-inspector-visual)` | `sdd-inspector-visual.md` | OK |
| `Task(sdd-taskgenerator)` | `sdd-taskgenerator.md` | OK |

**結果**: OK (cached + 全エントリ対応ファイル存在確認済み)

---

## 6. Task ツール dispatch パターン — キャッシュ済み検証

**subagent_type パラメータ名**: OK (cached)
**run_in_background 使用ポリシー**: OK (cached)
**SubAgent 非ネスト制約**: OK (cached)

CLAUDE.md の記述 `Task(subagent_type="sdd-architect", prompt="...")` は公式 Task ツールの仕様に準拠。全 subagent_type 値は settings.json の `Task()` エントリおよび agents/ ファイルと一致。

---

## 準拠状況サマリー

| カテゴリ | 項目 | 件数 | 結果 |
|---------|------|------|------|
| エージェント定義 | sdd-analyst.md (未コミット変更・フル検証) | 1 | PASS |
| エージェント定義 | その他24ファイル (キャッシュ) | 24 | OK (cached) |
| スキル定義 | sdd-reboot SKILL.md (未コミット変更・フル検証) | 1 | PASS |
| スキル定義 | その他6ファイル (キャッシュ) | 6 | OK (cached) |
| settings.json | Skill() エントリ ↔ ファイル対応 | 7 | OK |
| settings.json | Task() エントリ ↔ ファイル対応 | 26 | OK |
| settings.json | Bash() エントリ | — | OK (cached) |
| settings.json | defaultMode | — | OK (cached) |
| Task ツール dispatch | subagent_type パラメータ・run_in_background | — | OK (cached) |
| SubAgent 制約 | 非ネスト制約 | — | OK (cached) |

**総合判定: PASS — 全項目プラットフォーム仕様準拠**

---

## 所見・特記事項

1. **sdd-analyst.md の `background: true`**: B13 時点では未検証の新フィールドだったが、公式ドキュメントで明示的にサポートされていることを確認。CLAUDE.md の「Lead dispatches SubAgents via `Task` tool with `run_in_background: true` always」という運用ポリシーを、エージェント定義レベルでも補強している。問題なし。

2. **sdd-reboot SKILL.md の `allowed-tools: Task`**: 制約なし `Task` は全 subagent type の spawn を許可する。スキルは Lead（メインスレッド）が実行し、sdd-reboot は Analyst、ConventionsScanner、Architect 等を dispatch する必要があるため、制限なし Task は設計上適切。

3. **settings.json の sdd-reboot エントリ**: `Skill(sdd-reboot)` として登録済み。スキルファイルの存在も確認。整合性あり。

4. **未コミット変更ファイル**: 4ファイル（sdd-analyst.md、analysis-report.md テンプレート、sdd-reboot SKILL.md、refs/reboot.md）が未コミット状態。コンプライアンス上の問題はないが、次回コミット時に含めること。

---

*WRITTEN:/Users/mia/Repositories/sync-sdd/.sdd/project/reviews/self/active/agent-4-compliance.md*
