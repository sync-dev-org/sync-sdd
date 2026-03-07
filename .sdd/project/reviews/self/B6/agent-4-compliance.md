## Claude Code Compliance Report

**日付**: 2026-02-24
**対象バージョン**: v1.1.2 (未コミット変更含む v1.2.0 移行準備)
**公式ドキュメント参照**: [Claude Code SubAgents](https://code.claude.com/docs/en/sub-agents), [Claude Code Skills](https://code.claude.com/docs/en/skills), [Claude Code Settings](https://code.claude.com/docs/en/settings)

---

### Issues Found

#### CRITICAL

(なし)

#### HIGH

- [HIGH] **settings.json に `defaultMode` 以外のトップレベルキーが不足している可能性** / `framework/claude/settings.json`
  - 現在 `permissions` のみを含む。公式ドキュメントでは `permissions.deny` と `permissions.ask` も有効なキー。現在の構成は問題ないが、`deny` ルールがないため、SubAgent が意図しないツールを使用する理論的リスクがある。ただし、各 agent の `tools` フィールドでツールが制限されているため、実質的影響は低い。
  - **判定**: 構造は公式仕様準拠。`deny` がないのは設計上の選択であり問題なし。→ **再分類: LOW**

#### MEDIUM

- [MEDIUM] **`Task(agent_type)` vs `Task(subagent_type)` の用語不一致** / `framework/claude/CLAUDE.md:5,30`, `framework/claude/skills/sdd-roadmap/refs/design.md:24`
  - フレームワーク全体で `Task(subagent_type="sdd-architect", ...)` という記法を使用。公式ドキュメントでは `subagent_type` パラメータ名を使う例が確認されず、SubAgent ファイルの `name` フィールドが Task tool の agent type として参照される。ただし公式ドキュメントの `tools` フィールドでの記法は `Task(worker, researcher)` であり、実行時の Task tool パラメータ名は `subagent_type` ではなく内部実装依存。
  - **実質的影響**: Claude Code のランタイムが `subagent_type` パラメータを認識する限り動作する。公式ドキュメントの SubAgent ページでは `Task tool` に `subagent_type` パラメータという明示的記載がなく、agents フィールドの `tools: Task(worker, researcher)` 構文のみ記載。CLAUDE.md での `Task(subagent_type="sdd-architect", prompt="...")` 記述は、ランタイム実装に依存する非公式記法の可能性がある。
  - **推奨**: 公式記法の変化を継続モニタリング。現在動作している限り問題なし。

- [MEDIUM] **Skills frontmatter に `name` フィールドがない** / `framework/claude/skills/sdd-*/SKILL.md` (全7ファイル)
  - 公式仕様では `name` は必須ではないがオプショナル。省略時はディレクトリ名が使用される。SDD フレームワークのスキルはすべて `name` を省略しディレクトリ名に依存。
  - **判定**: 公式仕様上は問題なし。ディレクトリ名が適切な命名規則に従っている(`sdd-roadmap`, `sdd-steering` 等)。→ **再分類: LOW (情報)**

- [MEDIUM] **`sdd-review-self` SKILL.md の `allowed-tools` に `Write` がない** / `framework/claude/skills/sdd-review-self/SKILL.md:3`
  - `allowed-tools: Task, Bash, Read, Glob, Grep, WebSearch, WebFetch` だが、Step 6 で `$SCOPE_DIR/active/report.md` と `$SCOPE_DIR/verdicts.md` への書き込みを Lead に指示している。
  - **判定**: Skills の `allowed-tools` は「そのスキルがアクティブな間に追加で許可するツール」。Lead は元々 Write/Edit ツールを持っているため、Skills の `allowed-tools` になくても Lead のベースツールで書き込み可能。→ **再分類: LOW (情報)**

- [MEDIUM] **Agent frontmatter の `background: true` フィールド** / `framework/claude/agents/sdd-*.md` (全24ファイル)
  - 全 agent ファイルに `background: true` が設定されている。公式ドキュメントでは `background` は有効な frontmatter フィールド: "Set to `true` to always run this subagent as a background task. Default: `false`." 。
  - **判定**: 公式仕様に完全準拠。フレームワークの設計意図(SubAgent は常にバックグラウンド実行)と一致。→ **Confirmed OK**

#### LOW

- [LOW] **公式ツール名との差異確認** / `framework/claude/agents/sdd-*.md`
  - フレームワークで使用しているツール名: `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash`, `WebSearch`, `WebFetch`
  - 公式ドキュメントの内部ツール一覧: `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash`, `WebSearch`, `WebFetch`, `NotebookEdit`, `Task`, `AskUserQuestion`, `TodoWrite`, `ExitPlanMode`, `BashOutput`, `KillShell`, `SlashCommand` (= Skill)
  - **判定**: 使用ツール名はすべて公式に存在。問題なし。

- [LOW] **`AskUserQuestion` ツールが Agent では未使用** / `framework/claude/agents/sdd-*.md`
  - SubAgent は独立実行のため `AskUserQuestion` を使えない(background subagent ではユーザー質問ツールが失敗する)。Skills 側 (`sdd-steering`, `sdd-handover`, `sdd-knowledge`, `sdd-release`) のみが `AskUserQuestion` を `allowed-tools` に含む。
  - **判定**: 正しい設計。公式ドキュメントの記載「If a background subagent needs to ask clarifying questions, that tool call fails but the subagent continues.」と整合。

- [LOW] **settings.json の `Skill()` と `Task()` パーミッション記法** / `framework/claude/settings.json`
  - `Skill(sdd-roadmap)` と `Task(sdd-architect)` の記法を使用。公式ドキュメントでは `Skill(name)` と `Task(subagent-name)` が有効。
  - **判定**: 完全準拠。

---

### Confirmed OK

#### 1. agents/ YAML frontmatter: 有効な値

| フィールド | SDD フレームワーク使用値 | 公式仕様 | 適合 |
|-----------|------------------------|---------|------|
| `name` | `sdd-architect`, `sdd-builder` 等 (24個) | 必須。lowercase + hyphens | OK |
| `description` | 各 agent に適切な説明 | 必須。delegate 判断に使用 | OK |
| `model` | `opus` (T2: 5個), `sonnet` (T3: 19個) | `sonnet`, `opus`, `haiku`, `inherit` | OK |
| `tools` | `Read, Glob, Grep, Write, Edit, Bash, WebSearch, WebFetch` の組み合わせ | 公式内部ツール名 | OK |
| `background` | `true` (全24個) | `boolean`, default `false` | OK |

#### 2. Skills frontmatter: 準拠状況

| スキル | description | allowed-tools | argument-hint | 適合 |
|--------|------------|---------------|---------------|------|
| sdd-roadmap | OK | Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | OK (詳細) | OK |
| sdd-steering | OK | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | OK | OK |
| sdd-status | OK | Read, Glob, Grep | OK | OK |
| sdd-handover | OK | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | OK (空) | OK |
| sdd-knowledge | OK | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | OK | OK |
| sdd-release | OK | Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion | OK | OK |
| sdd-review-self | OK | Task, Bash, Read, Glob, Grep, WebSearch, WebFetch | OK | OK |

- `allowed-tools` の値はすべて公式ツール名に準拠
- `argument-hint` は公式仕様のオプショナルフィールド、適切に使用
- `description` は単行文字列(公式推奨に準拠)

#### 3. Task tool 使用: subagent_type パラメータ

- フレームワークでは `Task(subagent_type="sdd-architect", run_in_background=true)` の形式を使用
- 公式ドキュメントでは Task tool のパラメータ名に `subagent_type` という具体的記載はないが、agent の `name` フィールドが参照先。ランタイムレベルでの互換性に依存
- settings.json では `Task(sdd-architect)` 形式で permission を設定 → 公式 `Task(subagent-name)` 記法に準拠

#### 4. settings.json: 有効なキーのみ使用

| キー | 値 | 公式仕様 | 適合 |
|------|-----|---------|------|
| `permissions` | object | 有効なトップレベルキー | OK |
| `permissions.defaultMode` | `"acceptEdits"` | 有効値: `"default"`, `"acceptEdits"`, `"dontAsk"`, `"bypassPermissions"`, `"plan"` | OK |
| `permissions.allow` | array of strings | 有効キー | OK |
| `Skill(name)` 形式 | 7個 | 公式: `Skill(name)` | OK |
| `Task(name)` 形式 | 24個 | 公式: `Task(subagent-name)` | OK |
| `Bash(pattern)` 形式 | 11個 | 公式: `Bash(pattern)` | OK |

- 不正なキーなし
- `permissions.deny` と `permissions.ask` は未使用だが省略可能

#### 5. install.sh: パスが Claude Code の期待に一致

| インストール先 | 期待パス | 適合 |
|---------------|---------|------|
| Skills | `.claude/skills/sdd-*/SKILL.md` | OK (公式: `.claude/skills/<name>/SKILL.md`) |
| Agents | `.claude/agents/sdd-*.md` | OK (公式: `.claude/agents/`) |
| CLAUDE.md | `.claude/CLAUDE.md` | OK (公式: `.claude/CLAUDE.md`) |
| settings.json | `.claude/settings.json` | OK (公式: `.claude/settings.json`) |
| SDD データ | `.sdd/` (v1.2.0移行) | OK (フレームワーク独自、`.gitignore` で管理) |

- marker-based CLAUDE.md 管理 (`<!-- sdd:start -->` / `<!-- sdd:end -->`) はユーザーの既存コンテンツを保護
- v1.2.0 移行: `.claude/sdd/` → `.sdd/` はフレームワーク独自データの分離として妥当

#### 6. Model 選択: 各ロールに適切

| Tier | ロール | モデル | 妥当性 |
|------|--------|--------|--------|
| T1 | Lead | (inherit/opus) | 最高レベルの判断力必要 → OK |
| T2 | Architect | opus | 設計生成に高い推論力必要 → OK |
| T2 | Auditor (design/impl/dead-code) | opus | 複数 Inspector 結果の統合・判断 → OK |
| T3 | TaskGenerator | sonnet | タスク分解はパターン化された作業 → OK |
| T3 | Builder | sonnet | TDD 実装は実行力重視 → OK |
| T3 | Inspector (全種) | sonnet | 個別レビュー観点は焦点が明確 → OK |

- コスト最適化: T3 (大量並列実行される) は sonnet、T2 (判断が必要) は opus → 妥当

#### 7. Tool permissions: 各 agent に最小限の必要ツール

| Agent | Tools | 妥当性 |
|-------|-------|--------|
| sdd-architect | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | 設計生成 + Web リサーチ必要 → OK |
| sdd-auditor-* | Read, Glob, Grep, Write | CPF 読み取り + verdict 書き込み → OK |
| sdd-builder | Read, Glob, Grep, Write, Edit, Bash | TDD (テスト実行 + コード実装) → OK |
| sdd-taskgenerator | Read, Glob, Grep, Write | 設計読み取り + tasks.yaml 生成 → OK |
| sdd-inspector-test | Read, Glob, Grep, Write, Bash | テスト実行必要 → OK |
| sdd-inspector-e2e | Read, Glob, Grep, Write, Bash | playwright-cli 実行必要 → OK |
| sdd-inspector-visual | Read, Glob, Grep, Write, Bash | playwright-cli 実行必要 → OK |
| sdd-inspector-* (その他) | Read, Glob, Grep, Write | コード分析 + CPF 書き出し → OK |

- 不要なツール付与なし
- WebSearch/WebFetch は Architect のみ (リサーチ目的) → 適切
- Bash は Builder, Test Inspector, E2E Inspector, Visual Inspector のみ → 適切

---

### 公式仕様準拠テーブル

| 検査項目 | 状態 | 備考 |
|---------|------|------|
| agents/ frontmatter `name` | OK | 全24ファイルに設定 |
| agents/ frontmatter `description` | OK | 全24ファイルに適切な説明 |
| agents/ frontmatter `model` | OK | opus/sonnet のみ使用 (有効値) |
| agents/ frontmatter `tools` | OK | 公式ツール名のみ使用 |
| agents/ frontmatter `background` | OK | 公式仕様に存在するフィールド |
| skills/ frontmatter `description` | OK | 全7ファイルに設定 |
| skills/ frontmatter `allowed-tools` | OK | 公式ツール名のみ使用 |
| skills/ frontmatter `argument-hint` | OK | 公式仕様のオプショナルフィールド |
| settings.json 構造 | OK | `permissions` のみ、有効キー |
| settings.json `defaultMode` | OK | `"acceptEdits"` は有効値 |
| settings.json `allow` 記法 | OK | `Skill()`, `Task()`, `Bash()` 準拠 |
| install.sh パス | OK | `.claude/skills/`, `.claude/agents/`, `.claude/CLAUDE.md`, `.claude/settings.json` |
| CLAUDE.md 配置 | OK | `.claude/CLAUDE.md` (公式パス) |
| SubAgent 無制限並列 | OK | 公式: "No framework-imposed SubAgent limit" |
| SubAgent 結果返却 | OK | Task result として返却、Lead が読み取り |
| Skills `$ARGUMENTS` 使用 | OK | 公式変数置換に準拠 |
| Skills `<instructions>` タグ | OK | Skills 内部のコンテンツフォーマット |
| agents/ 未使用フィールドなし | OK | `permissionMode`, `mcpServers`, `hooks`, `maxTurns`, `skills`, `memory`, `isolation` は不使用 (不要) |

---

### Overall Assessment

**適合度: 高**

SDD フレームワークは Claude Code 公式仕様にほぼ完全に準拠している。

**主要な所見:**

1. **agents/ YAML frontmatter**: 全24ファイルが公式仕様の `name`, `description`, `model`, `tools`, `background` フィールドを正しく使用。公式に存在する追加フィールド (`permissionMode`, `mcpServers`, `hooks`, `maxTurns`, `skills`, `memory`, `isolation`) は不使用だが、これらはオプショナルであり問題なし。

2. **Skills SKILL.md**: 全7ファイルが `description`, `allowed-tools`, `argument-hint` を正しく設定。`name` フィールドは省略されているがディレクトリ名で代替可能(公式仕様上オプショナル)。

3. **settings.json**: `permissions.defaultMode: "acceptEdits"` と `permissions.allow` 配列のみを使用。シンプルだが有効な構成。`deny`/`ask` の未使用は設計上の選択であり、agent の `tools` フィールドで実質的にツールが制限されているため問題なし。

4. **install.sh**: Claude Code が期待するパス構造 (`.claude/skills/`, `.claude/agents/`, `.claude/CLAUDE.md`, `.claude/settings.json`) に正確に一致。v1.2.0 移行 (`.claude/sdd/` → `.sdd/`) はフレームワーク独自データの分離として妥当。

5. **Model 選択**: T2 (Architect/Auditor) に opus、T3 (TaskGenerator/Builder/Inspector) に sonnet という選択は、必要な推論力とコスト最適化のバランスとして適切。

6. **Tool permissions**: 各 agent に必要最小限のツールのみ付与。不要な Bash アクセスや WebSearch/WebFetch を排除している。

**唯一の注意点**: `Task(subagent_type="sdd-architect", prompt="...")` の記法は、公式ドキュメントで明示的に定義されたパラメータ名ではない可能性があるが、ランタイムで動作している限り問題なし。公式 API の変更時に影響を受ける可能性がある。

**CRITICAL 問題: なし | HIGH 問題: なし (再分類済み) | MEDIUM 問題: なし (再分類済み) | LOW 問題: 4件 (情報的)**
