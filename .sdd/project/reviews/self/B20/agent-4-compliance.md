# Platform Compliance Report

**Generated**: 2026-03-03T15:06:37+0900
**Scope**: framework/claude/agents/sdd-*.md, framework/claude/skills/sdd-*/SKILL.md, framework/claude/settings.json, framework/claude/CLAUDE.md
**Review Batch**: B20 (自己レビュー Agent 4)

---

## 概要

26エージェント定義ファイル・8スキルファイル・settings.json を対象に、Claude Code プラットフォーム仕様への適合性を検証した。B19 でキャッシュ済みの 15 エージェント/スキルはファイル変更なしを確認し、変更対象（リネーム2件・CPFファイル名更新・E2Eステップ追加）のみフル検証した。

---

## Issues Found

問題は検出されなかった。

---

## Confirmed OK

### エージェント YAML フロントマター

Claude Code 公式仕様 ([code.claude.com/docs/en/sub-agents](https://code.claude.com/docs/en/sub-agents)) に基づく検証:
- 必須フィールド: `name`, `description` → 全26エージェントで存在確認
- `model` 有効値: `sonnet`, `opus`, `haiku`, `inherit` → 全エージェントで有効値を使用
- `tools` フィールド: Read, Glob, Grep, Write, Edit, Bash, WebSearch, WebFetch は有効なツール名
- `background: true` フィールド: 公式仕様で有効なフロントマターフィールドとして確認済み

#### モデル配分確認

| モデル | エージェント |
|--------|-------------|
| `opus` | sdd-analyst, sdd-architect, sdd-auditor-design, sdd-auditor-impl, sdd-auditor-dead-code |
| `sonnet` | その他21エージェント（Inspector系、Builder、TaskGenerator、ConventionsScanner） |

T2（Brain）= opus、T3（Execute）= sonnet の階層設計に完全準拠。

### 名前変更エージェント (フル検証)

**sdd-inspector-web-e2e** (`framework/claude/agents/sdd-inspector-web-e2e.md`):
- `name: sdd-inspector-web-e2e` ✓（ファイル名と一致）
- `description`: 存在、用途明記 ✓
- `model: sonnet` ✓
- `tools: Read, Glob, Grep, Write, Bash` ✓
- `background: true` ✓
- Playwright の使用ツール (Bash) が `tools` に含まれる ✓

**sdd-inspector-web-visual** (`framework/claude/agents/sdd-inspector-web-visual.md`):
- `name: sdd-inspector-web-visual` ✓（ファイル名と一致）
- `description`: 存在、用途明記 ✓
- `model: sonnet` ✓
- `tools: Read, Glob, Grep, Write, Bash` ✓
- `background: true` ✓
- Playwright の使用ツール (Bash) が `tools` に含まれる ✓

旧名（`sdd-inspector-e2e`, `sdd-inspector-visual`）は framework 全体に存在しないことを Grep で確認 ✓

### sdd-auditor-impl の CPF ファイル名 (フル検証)

`framework/claude/agents/sdd-auditor-impl.md` の CPF 参照リスト:
1. `sdd-inspector-impl-rulebase.cpf` ✓
2. `sdd-inspector-interface.cpf` ✓
3. `sdd-inspector-test.cpf` ✓
4. `sdd-inspector-quality.cpf` ✓
5. `sdd-inspector-impl-consistency.cpf` ✓
6. `sdd-inspector-impl-holistic.cpf` ✓
7. `sdd-inspector-web-e2e.cpf` ✓（新名称に更新済み）
8. `sdd-inspector-web-visual.cpf` ✓（新名称に更新済み）

`review.md` の dispatch 指示（`sdd-inspector-web-e2e`, `sdd-inspector-web-visual`）と整合 ✓

### sdd-inspector-test の E2E ステップ追加 (フル検証)

`framework/claude/agents/sdd-inspector-test.md`:
- Step 5「E2E Command Execution」を確認 ✓
- `steering/tech.md` の `# E2E:` 行を参照する仕様 ✓
- E2E コマンド成功時: NOTES へ記録 ✓
- E2E コマンド失敗時: `e2e-failure` (severity: C) を Flag ✓
- E2E コマンド未定義時: 潜在的スクリプト検索 + `e2e-not-configured` (L) の条件付き Flag ✓
- 出力フォーマット例に `e2e-failure` カテゴリが含まれる ✓
- tools に `Bash` が含まれる（E2E コマンド実行に必須） ✓
- `background: true` ✓

### settings.json 権限 (フル検証)

`framework/claude/settings.json` の Agent() エントリと実際のエージェントファイルの対応:

| settings.json エントリ | エージェントファイル | 状態 |
|------------------------|----------------------|------|
| `Agent(sdd-analyst)` | sdd-analyst.md | ✓ |
| `Agent(sdd-architect)` | sdd-architect.md | ✓ |
| `Agent(sdd-auditor-dead-code)` | sdd-auditor-dead-code.md | ✓ |
| `Agent(sdd-auditor-design)` | sdd-auditor-design.md | ✓ |
| `Agent(sdd-auditor-impl)` | sdd-auditor-impl.md | ✓ |
| `Agent(sdd-builder)` | sdd-builder.md | ✓ |
| `Agent(sdd-conventions-scanner)` | sdd-conventions-scanner.md | ✓ |
| `Agent(sdd-inspector-architecture)` | sdd-inspector-architecture.md | ✓ |
| `Agent(sdd-inspector-best-practices)` | sdd-inspector-best-practices.md | ✓ |
| `Agent(sdd-inspector-consistency)` | sdd-inspector-consistency.md | ✓ |
| `Agent(sdd-inspector-dead-code)` | sdd-inspector-dead-code.md | ✓ |
| `Agent(sdd-inspector-dead-settings)` | sdd-inspector-dead-settings.md | ✓ |
| `Agent(sdd-inspector-dead-specs)` | sdd-inspector-dead-specs.md | ✓ |
| `Agent(sdd-inspector-dead-tests)` | sdd-inspector-dead-tests.md | ✓ |
| `Agent(sdd-inspector-web-e2e)` | sdd-inspector-web-e2e.md | ✓（新名称）|
| `Agent(sdd-inspector-holistic)` | sdd-inspector-holistic.md | ✓ |
| `Agent(sdd-inspector-impl-consistency)` | sdd-inspector-impl-consistency.md | ✓ |
| `Agent(sdd-inspector-impl-holistic)` | sdd-inspector-impl-holistic.md | ✓ |
| `Agent(sdd-inspector-impl-rulebase)` | sdd-inspector-impl-rulebase.md | ✓ |
| `Agent(sdd-inspector-interface)` | sdd-inspector-interface.md | ✓ |
| `Agent(sdd-inspector-quality)` | sdd-inspector-quality.md | ✓ |
| `Agent(sdd-inspector-rulebase)` | sdd-inspector-rulebase.md | ✓ |
| `Agent(sdd-inspector-test)` | sdd-inspector-test.md | ✓ |
| `Agent(sdd-inspector-testability)` | sdd-inspector-testability.md | ✓ |
| `Agent(sdd-inspector-web-visual)` | sdd-inspector-web-visual.md | ✓（新名称）|
| `Agent(sdd-taskgenerator)` | sdd-taskgenerator.md | ✓ |

旧名 `Agent(sdd-inspector-e2e)`, `Agent(sdd-inspector-visual)` が残存しないことを確認 ✓
全 26 エージェントファイルが settings.json に登録済み ✓
settings.json の全 Agent() エントリが実ファイルに対応 ✓（過不足なし）

### スキル YAML フロントマター

Claude Code 公式仕様 ([code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills)) に基づく検証:
- `description`: 推奨フィールド（必須ではないが全スキルで存在） ✓
- `allowed-tools`: オプションフィールド、全スキルで適切に設定 ✓
- `argument-hint`: オプションフィールド、各スキルで適切に設定（不要なスキルは省略） ✓

| スキル | description | allowed-tools | argument-hint |
|--------|-------------|---------------|---------------|
| sdd-roadmap | ✓ | Agent, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | ✓ |
| sdd-steering | ✓ | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion, Skill | ✓ |
| sdd-status | ✓ | Read, Glob, Grep | ✓ |
| sdd-handover | ✓ | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | 省略（任意） |
| sdd-reboot | ✓ | Agent, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | ✓ |
| sdd-release | ✓ | Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion | ✓ |
| sdd-review-self | ✓ | Agent, Bash, Read, Glob, Grep | 省略（任意） |
| sdd-publish-setup | ✓ | Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion | 省略（任意） |

settings.json の Skill() エントリと実スキルファイルの対応:
- `Skill(sdd-roadmap)`, `Skill(sdd-steering)`, `Skill(sdd-status)`, `Skill(sdd-handover)`, `Skill(sdd-reboot)`, `Skill(sdd-release)`, `Skill(sdd-review-self)`, `Skill(sdd-publish-setup)` — 全8件、対応ファイルあり ✓

### CLAUDE.md の Agent ツール dispatch パターン

`framework/claude/CLAUDE.md` のSubAgent dispatch記述:
- `Agent(subagent_type="sdd-architect", prompt="...")` 形式 ✓
- `run_in_background: true` 必須化の記述 ✓（「Lead dispatches SubAgents via Agent tool with run_in_background: true always. No exceptions」）
- subagent_type として参照されるエージェント名はすべて実ファイルに対応 ✓

### キャッシュ済みエージェント (B19 検証済み、ファイル未変更)

以下は B19 で OK 確認済み、かつ本レビュー対象コミット差分に含まれないため、キャッシュとして承認:

- sdd-taskgenerator: OK (cached)
- sdd-auditor-design: OK (cached)
- sdd-conventions-scanner: OK (cached)
- sdd-inspector-architecture: OK (cached)
- sdd-inspector-best-practices: OK (cached)
- sdd-inspector-consistency: OK (cached)
- sdd-inspector-holistic: OK (cached)
- sdd-inspector-impl-consistency: OK (cached)
- sdd-inspector-impl-holistic: OK (cached)
- sdd-inspector-impl-rulebase: OK (cached)
- sdd-inspector-interface: OK (cached)
- sdd-inspector-quality: OK (cached)
- sdd-inspector-rulebase: OK (cached)
- sdd-inspector-testability: OK (cached)
- sdd-handover skill: OK (cached)

---

## Overall Assessment

**VERDICT: GO**

全26エージェント定義・8スキル・settings.json において、Claude Code プラットフォーム仕様への適合性に問題は検出されなかった。

重点検証項目（名称変更・CPF更新・E2Eステップ追加）の結果:

1. **sdd-inspector-web-e2e / sdd-inspector-web-visual のリネーム**: フロントマター `name` フィールド、ファイル名、settings.json の Agent() エントリ、auditor-impl の CPF 参照、review.md の dispatch 指示、旧名の残存なし — すべて整合。
2. **sdd-auditor-impl の CPF ファイル名更新**: 8件すべて新名称に更新済み、auditor-impl が読み取る `.cpf` ファイル名と Inspector の出力パス形式が整合。
3. **sdd-inspector-test の E2E ステップ追加**: Step 5 として正しく組み込まれ、Bash ツールが `tools` に含まれることも確認。E2E 失敗時の severity C フラグも適切。

プラットフォーム仕様上の制約（SubAgent は他の SubAgent を spawn できない）に対して、CLAUDE.md の「Subagents cannot spawn other subagents」記述が整合していることも確認した。

---

*参照: [Claude Code Sub-agents](https://code.claude.com/docs/en/sub-agents) | [Claude Code Skills](https://code.claude.com/docs/en/skills)*
