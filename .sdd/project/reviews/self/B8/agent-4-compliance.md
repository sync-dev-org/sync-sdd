## Platform Compliance Report

**対象**: SDD framework エージェント・スキル・Task ツール使用のプラットフォーム準拠確認
**調査日**: 2026-02-24
**調査対象ファイル数**: エージェント定義 24個、スキル定義 6個、settings.json 1個、CLAUDE.md 1個

---

### Issues Found

- [MEDIUM] Task tool の `model` パラメータが現在 Claude Code 2.1.12+ でバグにより機能しない / `framework/claude/skills/sdd-review-self/SKILL.md:58`
  - `Task(subagent_type="general-purpose", model="sonnet", run_in_background=true)` という記述があるが、`model` パラメータは GitHub Issue #18873 によると 404 エラーを引き起こす既知バグが存在 (2026-01-17 時点で未修正)
  - **影響**: `sdd-review-self` スキルは model 指定を試みるが、実際はエラーになるかパラメータが無視される可能性がある
  - **推奨**: `model` パラメータをプラットフォームが修正するまで省略するか、エージェント定義側の `model: sonnet` フィールドに依存する

- [LOW] `sdd-inspector-best-practices` エージェントは `WebSearch` / `WebFetch` ツールを宣言していないが、調査深度を「自律的に判断」するよう設計されている / `framework/claude/agents/sdd-inspector-best-practices.md`
  - ツール一覧: `Read, Glob, Grep, Write` — WebSearch/WebFetch が含まれない
  - CLAUDE.md では「最新情報が必要な場合は WebSearch/WebFetch を使用」と記述されるが、このエージェントはツールとして宣言していないため実行時に利用できない
  - **推奨**: 設計意図が「コードベース・ステアリングのみ検査」であれば問題なし。ただし `Research Depth (Autonomous)` セクションの記述が誤解を生む可能性がある

- [LOW] `argument-hint` フィールド: `sdd-handover/SKILL.md` で `argument-hint:` が存在するが値が空文字列 / `framework/claude/skills/sdd-handover/SKILL.md:4`
  - 公式仕様では `argument-hint` は省略可能フィールド。値が空の場合の動作は未定義だが、省略と同等に扱われる可能性が高い
  - **推奨**: 引数不要のスキルは `argument-hint` フィールド自体を省略することを推奨

---

### Confirmed OK

**エージェント定義 (24個) - YAML frontmatter 検証**

- `name` フィールド: 全24エージェントで小文字英数字・ハイフンのみの適切な名前を使用 — OK
- `description` フィールド: 全24エージェントで存在・非空 — OK
- `model` フィールド:
  - `opus` 使用: sdd-architect, sdd-auditor-dead-code, sdd-auditor-design, sdd-auditor-impl (4個、Tier2 Brain 相当) — OK (有効値)
  - `sonnet` 使用: sdd-builder, sdd-taskgenerator, 全 Inspector 16個 (20個、Tier3 Execute 相当) — OK (有効値)
  - `haiku` 使用: なし
  - `inherit` 使用: なし
  - 公式仕様の有効値 `sonnet | opus | haiku | inherit` に全て準拠 — OK
- `tools` フィールド: 全エージェントで定義あり。使用ツール名は公式ドキュメントの Internal Tools と一致 — OK
  - Read, Glob, Grep, Write, Edit: 静的ファイル操作ツール — OK
  - Bash: sdd-builder, sdd-inspector-e2e, sdd-inspector-test, sdd-inspector-visual の4エージェントのみ使用 — OK
  - WebSearch, WebFetch: sdd-architect のみ使用 — OK
  - 不正なツール名: なし
- `background: true`: 全24エージェントで設定 — OK (公式仕様の任意フィールドとして有効)
- `Task` ツール: 全エージェントの tools に含まれない — OK (公式仕様: サブエージェントは別のサブエージェントを spawn できない)

**スキル定義 (6個) - frontmatter 検証**

- `description` フィールド: 全6スキルで存在・非空 — OK
- `allowed-tools` フィールド: 全6スキルで適切なツール名を使用 — OK
  - `sdd-roadmap`: `Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion` — OK
  - `sdd-steering`: `Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion` — OK
  - `sdd-handover`: `Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion` — OK
  - `sdd-status`: `Read, Glob, Grep` — OK
  - `sdd-release`: `Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion` — OK
  - `sdd-review-self`: `Task, Bash, Read, Glob, Grep` — OK
- `argument-hint` フィールド: 構文は全て正しい形式 — OK (空値の1件は [LOW] として記録)
- スキルファイルは全て `.claude/skills/<name>/SKILL.md` 形式に準拠 — OK

**settings.json permissions 検証**

- `Skill()` エントリ (6個): `sdd-roadmap, sdd-steering, sdd-status, sdd-handover, sdd-release, sdd-review-self`
  - 実際に存在するスキルファイル (`framework/claude/skills/sdd-*/SKILL.md`) と完全一致 — OK
- `Task()` エントリ (24個): 全エントリが実際のエージェント定義ファイル (`framework/claude/agents/sdd-*.md`) と完全一致 — OK
  - `Task(sdd-architect)` から `Task(sdd-taskgenerator)` まで全24エージェント — OK
- 余分な `Task()` エントリ (存在するが対応ファイルなし): なし — OK
- 欠落する `Task()` エントリ (ファイルはあるが permissions に未記載): なし — OK
- `defaultMode: "acceptEdits"`: 公式仕様の有効な permissionMode 値 — OK

**Task ツール dispatch パターン検証**

- `sdd-roadmap` refs (design.md, impl.md, review.md, run.md) での dispatch パターン:
  - `Task(subagent_type="sdd-architect", run_in_background=true)` — OK (エージェント定義あり)
  - `Task(subagent_type="sdd-taskgenerator", run_in_background=true)` — OK
  - `Task(subagent_type="sdd-builder", run_in_background=true)` — OK
  - `Task(subagent_type="sdd-inspector-*", run_in_background=true)` — OK (全 Inspector)
  - `Task(subagent_type="sdd-auditor-*", run_in_background=true)` — OK (全 Auditor)
  - `run_in_background=true` の使用: 全ての dispatch で一貫して使用 — OK (CLAUDE.md の設計方針と一致)
- `sdd-review-self` での `Task(subagent_type="general-purpose", ...)`:
  - `general-purpose` は Claude Code 組み込みの built-in subagent — OK
- CLAUDE.md と dispatch refs の間でのエージェント名の一貫性 — OK

**ツール可用性 (エージェントが宣言ツールにアクセス可能か)**

- `sdd-builder` と `sdd-inspector-test` の Bash 使用: settings.json で `Bash(git *)` 等のパターンが許可されている。これらエージェントが Bash を使用するのは適切 — OK
- `sdd-inspector-e2e` と `sdd-inspector-visual` の `playwright-cli` 使用: settings.json で `Bash(playwright-cli *)` が許可 — OK
- WebSearch/WebFetch の `sdd-architect` 使用: settings.json に特別な記述なし (デフォルト許可対象) — OK

---

### Compliance Status Table

| 確認項目 | ステータス | 備考 |
|---|---|---|
| エージェント `name` フィールド (24個) | PASS | 全件小文字英数字・ハイフンのみ |
| エージェント `description` フィールド (24個) | PASS | 全件存在・非空 |
| エージェント `model` フィールド有効値 (24個) | PASS | sonnet/opus のみ使用、全て有効値 |
| エージェント `tools` フィールド有効ツール名 (24個) | PASS | 不正なツール名なし |
| エージェント `background: true` 設定 (24個) | PASS | 全件設定済み |
| エージェントに `Task` ツール非含有 (24個) | PASS | 公式制約準拠 |
| スキル `description` フィールド (6個) | PASS | 全件存在・非空 |
| スキル `allowed-tools` フォーマット (6個) | PASS | 全件有効なツール名 |
| スキル `argument-hint` フォーマット | WARN | sdd-handover の空値は推奨外 |
| settings.json `Skill()` とファイル整合性 | PASS | 6件完全一致 |
| settings.json `Task()` とファイル整合性 | PASS | 24件完全一致 |
| dispatch `subagent_type` とエージェント名整合性 | PASS | 全参照先が実在 |
| `run_in_background=true` 一貫使用 | PASS | 全 dispatch で使用 |
| Task ツール `model` パラメータ使用 | WARN | GitHub Issue #18873 の既知バグ (sdd-review-self のみ影響) |
| `sdd-inspector-best-practices` ツール宣言と設計意図 | WARN | WebSearch 未宣言だが設計上は許容範囲内 |

---

### Overall Assessment

**評価: 概ね準拠 (Minor Issues)**

24個のエージェント定義および6個のスキル定義は、Claude Code プラットフォーム仕様に対して高い準拠性を示している。

**主な適合点:**
1. 全エージェントの YAML frontmatter は公式仕様 (`name`, `description`, `model`, `tools`, `background`) を正しい値で使用している
2. モデル選択がアーキテクチャの役割に適切に対応 (Tier2=opus, Tier3=sonnet) している
3. settings.json の Skill/Task エントリが実際のファイルと完全に一致している
4. Task dispatch で `run_in_background=true` を一貫して使用するフレームワーク設計は、CLAUDE.md の設計方針および公式仕様と整合している
5. サブエージェントの tools に `Task` を含まないことで、公式制約 (サブエージェントは別サブエージェントを spawn できない) を正しく遵守している

**注意が必要な点:**
1. **[MEDIUM]** `sdd-review-self` スキルが使用する `model="sonnet"` パラメータは、プラットフォームの既知バグ (Issue #18873) により機能しない可能性がある。このバグは 2026-01 時点で未修正。影響は `sdd-review-self` の self-review パイプラインに限定される。main ロードマップ機能 (sdd-roadmap, sdd-builder 等) には影響しない。
2. **[LOW]** `sdd-inspector-best-practices` の設計説明に「技術調査の深度を自律的に判断」とあるが、ツール宣言に WebSearch/WebFetch がない。エージェントが実際にコードベース・ステアリングのみを検査する場合は問題ないが、設計ドキュメントの文言が誤解を招く。
3. **[LOW]** `sdd-handover` の空の `argument-hint:` は動作上の問題はないが、公式推奨スタイルから外れる。

これらの問題はいずれも Critical または High には分類されず、フレームワークのコア機能 (設計・実装・レビューパイプライン) への影響は最小限である。

---

**参照した公式ドキュメント:**
- [Create custom subagents - Claude Code Docs](https://code.claude.com/docs/en/sub-agents)
- [Extend Claude with skills - Claude Code Docs](https://code.claude.com/docs/en/skills)
- [Subagents in the SDK - Claude API Docs](https://platform.claude.com/docs/en/agent-sdk/subagents)
- [Task tool model parameter bug - GitHub Issue #18873](https://github.com/anthropics/claude-code/issues/18873)
