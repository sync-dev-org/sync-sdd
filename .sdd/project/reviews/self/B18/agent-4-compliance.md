## Platform Compliance Report

**レビュー日時**: 2026-03-01
**対象バージョン**: v1.9.0 (commit: aaa13ef)
**キャッシュ基準**: B17レビュー (2026-03-01)

---

### Issues Found

なし。重大・高・中・低 いずれの区分にも問題は検出されなかった。

---

### Confirmed OK

#### エージェント定義フロントマター (フル検証対象)

**sdd-analyst.md** (最新コミット aaa13ef で変更あり — フル検証実施)

| フィールド | 値 | 判定 |
|-----------|-----|------|
| `name` | `sdd-analyst` | OK (小文字ハイフン形式) |
| `description` | 存在・非空 | OK |
| `model` | `opus` | OK (有効モデルエイリアス) |
| `tools` | `Read, Glob, Grep, Write, Edit, WebSearch, WebFetch` | OK (Claude Code内蔵ツール) |
| `background` | `true` | OK (有効フィールド・正しい値) |

ツール可用性: `WebSearch` / `WebFetch` はClaude Code内蔵ツールとして公式ドキュメントに記載されており、問題なし。

**sdd-builder.md** (コミット fe85f84 で変更あり — フル検証実施)

| フィールド | 値 | 判定 |
|-----------|-----|------|
| `name` | `sdd-builder` | OK (小文字ハイフン形式) |
| `description` | 存在・非空 | OK |
| `model` | `sonnet` | OK (有効モデルエイリアス) |
| `tools` | `Read, Glob, Grep, Write, Edit, Bash` | OK (Claude Code内蔵ツール) |
| `background` | `true` | OK (有効フィールド・正しい値) |

ツール可用性: `Bash` はClaude Code内蔵ツール。BuilderがBashを使用するのはステアリング `tech.md` の Common Commands 実行のためであり、適切。

#### エージェント定義フロントマター (キャッシュ確認対象: 24エージェント)

以下のエージェントはB17レビュー以降、変更なし (git log で確認)。
B17検証結果を流用し、OK (cached) とする。

| エージェント | model | tools | background | 判定 |
|------------|-------|-------|------------|------|
| sdd-architect | opus | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | true | OK (cached) |
| sdd-taskgenerator | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-auditor-design | opus | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-auditor-impl | opus | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-auditor-dead-code | opus | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-conventions-scanner | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-architecture | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-best-practices | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-consistency | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-dead-code | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-dead-settings | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-dead-specs | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-dead-tests | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-e2e | sonnet | Read, Glob, Grep, Write, Bash | true | OK (cached) |
| sdd-inspector-holistic | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-impl-consistency | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-impl-holistic | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-impl-rulebase | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-interface | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-quality | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-rulebase | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-test | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-testability | sonnet | Read, Glob, Grep, Write | true | OK (cached) |
| sdd-inspector-visual | sonnet | Read, Glob, Grep, Write, Bash | true | OK (cached) |

全26エージェントの `name` フィールド: 小文字・ハイフン形式で統一。OK。
全26エージェントの `description` フィールド: 存在・非空。OK。

#### スキルフロントマター (全7件: キャッシュ確認 + 実ファイル読み取りで二重確認)

| スキル | description | allowed-tools | argument-hint | 判定 |
|-------|------------|--------------|--------------|------|
| sdd-roadmap | 存在 | Agent, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | 存在 | OK (cached) |
| sdd-steering | 存在 | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | 存在 | OK (cached) |
| sdd-status | 存在 | Read, Glob, Grep | 存在 | OK (cached) |
| sdd-handover | 存在 | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | なし (任意) | OK (cached) |
| sdd-release | 存在 | Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion | 存在 | OK (cached) |
| sdd-reboot | 存在 | Agent, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | 存在 | OK (cached) |
| sdd-review-self | 存在 | Agent, Bash, Read, Glob, Grep | なし (任意) | OK (cached) |

スキルフロントマター: `argument-hint` は任意フィールドにつき未記載でも適合。`allowed-tools` はClaude Code公式スキル仕様に準拠。OK。

#### settings.json パーミッション整合性

`settings.json` はB17以降変更なし。
`Agent()` エントリ: 26件 → 実在するエージェントファイル26件と完全一致。
`Skill()` エントリ: 7件 (sdd-roadmap, sdd-steering, sdd-status, sdd-handover, sdd-reboot, sdd-release, sdd-review-self) → 実在するスキルファイル7件と完全一致。
OK (cached)。

#### SubAgentネスト禁止

CLAUDE.md の SubAgent ディスパッチ記述: `Agent(subagent_type="sdd-architect", prompt="...")` 形式。
公式仕様: 「Subagents cannot spawn other subagents」。
SDD設計ではLeadがSubAgentを呼び出す構造であり、SubAgentがSubAgentを呼び出す構造はない (CLAUDE.md Chain of Command 参照)。
OK (cached)。

#### ツール可用性

変更対象エージェント分のみ再検証:

- **sdd-analyst**: `WebSearch`, `WebFetch` → 公式ドキュメントに内蔵ツールとして記載。Architectも同一ツールセットで既に運用中。OK。
- **sdd-builder**: `Bash` → 公式ドキュメントに内蔵ツールとして記載。OK。

---

### Compliance Status Table

| 検証項目 | 対象 | 結果 | 方法 |
|---------|------|------|------|
| エージェントフロントマター (model) | 全26件 | PASS | フル(2件) + cached(24件) |
| エージェントフロントマター (tools) | 全26件 | PASS | フル(2件) + cached(24件) |
| エージェントフロントマター (description) | 全26件 | PASS | フル(2件) + cached(24件) |
| エージェントフロントマター (background) | 全26件 | PASS | フル(2件) + cached(24件) |
| スキルフロントマター | 全7件 | PASS | cached(7件) + 実ファイル読み取り確認 |
| settings.json Agent()整合 | 26エントリ | PASS | cached |
| settings.json Skill()整合 | 7エントリ | PASS | cached |
| SubAgentネスト禁止 | CLAUDE.md | PASS | cached |
| ツール可用性 | 変更2件 | PASS | フル(2件) |

---

### Overall Assessment

**全項目 PASS。問題なし。**

v1.9.0 (aaa13ef) の変更内容:
- `sdd-analyst.md`: フロントマター変更なし。本文のみ変更 (要件抽出厳格化 + 代替アーキテクチャ案義務化 + ConventionsScannerスキップ追加)。フロントマター適合性に影響なし。
- `sdd-builder.md`: コミット da1937b (B16修正) および fe85f84 (TDD古典派原則) で変更済み。フロントマター変更は fe85f84 で確認済み (`background: true` 追加)。現在の状態は完全適合。

SDD フレームワーク全体 (26エージェント + 7スキル + settings.json) において、Claude Code プラットフォーム仕様への非準拠項目はゼロ。

---

*参考: Claude Code 公式ドキュメント*
- [Create custom subagents](https://code.claude.com/docs/en/sub-agents)
- [Extend Claude with skills](https://code.claude.com/docs/en/skills)
