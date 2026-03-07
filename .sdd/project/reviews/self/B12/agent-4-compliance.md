## Platform Compliance Report

**対象バージョン**: v1.4.0
**レビュー日時**: 2026-02-27
**キャッシュ参照**: B11 (2026-02-28 検証済み項目)
**新規検証対象**: sdd-analyst.md, sdd-reboot/SKILL.md, settings.json差分, CLAUDE.md差分

---

### Issues Found

- [HIGH] インストール未実施: `sdd-analyst.md` が `.claude/agents/` に存在しない。フレームワーク (`framework/claude/agents/sdd-analyst.md`) は追加済みだが `install.sh` が未実行。`/sdd-reboot` スキルが `Task(subagent_type="sdd-analyst")` を dispatch しようとした場合、エージェントが見つからずエラーになる。
  - framework source: `framework/claude/agents/sdd-analyst.md` (存在)
  - installed: `.claude/agents/sdd-analyst.md` (不在)

- [HIGH] インストール未実施: `sdd-reboot` スキルが `.claude/skills/` に存在しない。フレームワーク (`framework/claude/skills/sdd-reboot/`) は追加済みだが `install.sh` が未実行。`/sdd-reboot` コマンドが使用不可。
  - framework source: `framework/claude/skills/sdd-reboot/SKILL.md` (存在)
  - installed: `.claude/skills/sdd-reboot/` (不在)

- [HIGH] インストール未実施: `.claude/settings.json` に `Skill(sdd-reboot)` および `Task(sdd-analyst)` が存在しない。フレームワーク `framework/claude/settings.json` では追加済みだが未反映。これにより：
  - `/sdd-reboot` スキル呼び出し時に permissions エラーが発生する可能性がある
  - `Task(sdd-analyst)` が許可リストにないため、dispatch が拒否される可能性がある
  - 差分: `.claude/settings.json` は `Skill(sdd-reboot)` と `Task(sdd-analyst)` が欠落

- [MEDIUM] インストール未実施: `.claude/CLAUDE.md` が v1.4.0 フレームワーク変更を反映していない。具体的には：
  - Tier 2 ヒエラルキーに `Analyst` が未記載（`.claude/CLAUDE.md` は旧版 `Architect / Auditor` のまま）
  - コマンド数が「5」のまま（フレームワーク版は「6」）
  - `/sdd-reboot` コマンドが Commands テーブルに未記載
  - Analyst の context budget ルールが未反映

---

### Confirmed OK

#### フレームワークソース検証 (新規対象)

**sdd-analyst.md フロントマター検証 (新規・完全検証)**
- `name: sdd-analyst` — 有効 (verified: 公式ドキュメント「name: unique identifier using lowercase letters and hyphens」)
- `description` — 存在・適切な説明あり (verified OK)
- `model: opus` — 有効値 (verified: 公式ドキュメント「opus, sonnet, haiku, inherit」)
- `tools: Read, Glob, Grep, Write, Edit, WebSearch, WebFetch` — 全て有効なツール名 (verified OK)
- `background: true` — 有効フィールド (verified: 公式ドキュメント「background: Set to true to always run this subagent as a background task」)
- T2 Brain tier に適切に配置 (Opus モデル使用) (verified OK)

**sdd-reboot/SKILL.md フロントマター検証 (新規・完全検証)**
- `description` — 存在 (verified: 公式ドキュメント「recommended field」)
- `allowed-tools: Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion` — 有効フィールド・適切なツールリスト (verified OK)
- `argument-hint: [name] [-y]` — 有効フィールド (verified: 公式ドキュメント「hint shown during autocomplete」)
- `Task` ツールを allowed-tools に含む — sdd-analyst, sdd-conventions-scanner を dispatch するため必要 (verified OK)
- `AskUserQuestion` — 有効ツール (Phase 5 User Review Checkpoint で使用) (verified OK)
- `name` フィールド省略 — 有効 (公式ドキュメント: 「If omitted, uses the directory name」= `sdd-reboot`) (verified OK)

**Task dispatch パターン検証 (新規)**
- `refs/reboot.md:53`: `Task(subagent_type="sdd-analyst", run_in_background=true)` — 有効なパラメータ (verified OK)
- `refs/reboot.md:40`: `Task(subagent_type="sdd-conventions-scanner", run_in_background=true)` — 有効 (verified OK)
- `sdd-analyst` エージェント定義が `framework/claude/agents/sdd-analyst.md` に存在 — フレームワーク内整合性 OK (verified OK)

**settings.json フレームワーク版検証 (新規差分のみ)**
- `Task(sdd-analyst)` — framework/claude/settings.json に追加済み、対応する agent ファイルあり (verified OK)
- `Skill(sdd-reboot)` — framework/claude/settings.json に追加済み、対応する SKILL.md あり (verified OK)
- `Task(sdd-conventions-scanner)` — framework/claude/settings.json に追加済み (v1.3.0 以降)、対応 agent あり (verified OK)
- 全エントリの agent/skill ファイル対応: settings.json の Task/Skill エントリと実ファイルが完全一致 (verified OK)

**CLAUDE.md フレームワーク版検証 (新規差分のみ)**
- Tier 2 に Analyst 追加: `Analyst / Architect / Auditor` — 3-tier 定義と整合 (verified OK)
- Tier 3 に ConventionsScanner 追加: `TaskGenerator / Builder / Inspector / ConventionsScanner` (verified OK)
- Commands (6) — sdd-reboot 追加後の正確なコマンド数 (verified OK)
- Analyst の context budget ルール (`WRITTEN:{path}` 返却) — sdd-analyst.md の Completion Report セクションと一致 (verified OK)
- `run_in_background: true` ルール — SubAgent Lifecycle セクションで継続保持 (verified OK)

#### キャッシュ済み項目 (B11 2026-02-28 検証済み・変更なし)

- **Agent frontmatter (既存 25 エージェント)**: sdd-architect, sdd-auditor-dead-code, sdd-auditor-design, sdd-auditor-impl, sdd-builder, sdd-conventions-scanner, sdd-inspector-* (全 16), sdd-taskgenerator — 全て OK (cached)
- **Skill frontmatter (既存 6 スキル)**: sdd-roadmap, sdd-steering, sdd-status, sdd-release, sdd-handover, sdd-review-self — 全て OK (cached)
- **model 値**: 全エージェントで `opus` または `sonnet` のみ使用 — OK (cached)
- **background フィールド**: 全エージェントで `background: true` — OK (cached)
- **ツール適切性**: 各エージェントの role に対してツールリストが適切 — OK (cached)
- **settings.json 基本構造**: `defaultMode: acceptEdits`、`allow` 配列形式 — OK (cached)
- **Bash エントリ**: `git *`, `mkdir *`, `ls *`, `mv *`, `cp *`, `wc *`, `which *`, `diff *`, `playwright-cli *`, `npm *`, `npx *` — OK (cached)

---

### Overall Assessment

**フレームワーク内部整合性: 合格**
`framework/` ディレクトリ内の全ファイルは Claude Code プラットフォーム仕様に準拠している。新規追加の `sdd-analyst.md` と `sdd-reboot/SKILL.md` のフロントマターは仕様通りに記述されており、settings.json も agent/skill ファイルと完全に対応している。

**インストール状態: 要対処**
v1.4.0 で追加された 2 つの新機能 (`sdd-analyst` エージェント、`sdd-reboot` スキル) が `.claude/` 環境にインストールされていない。`install.sh` を実行するか手動でコピーしないと、`/sdd-reboot` コマンドは使用できない。

**推奨アクション**: `install.sh` を実行して `.claude/` 環境を v1.4.0 に同期する。

| カテゴリ | 結果 |
|----------|------|
| フレームワーク内部整合性 | 合格 |
| エージェント定義フロントマター | 合格 (26/26) |
| スキル定義フロントマター | 合格 (7/7) |
| settings.json (framework版) | 合格 |
| Task dispatch パターン | 合格 |
| インストール状態 | 要対処 (HIGH×3, MEDIUM×1) |
