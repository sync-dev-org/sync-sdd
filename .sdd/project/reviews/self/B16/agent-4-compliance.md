## Platform Compliance Report

**対象バージョン**: SDD Framework (framework/claude/)
**レビュー日**: 2026-03-01
**参照ドキュメント**: https://code.claude.com/docs/en/sub-agents, https://code.claude.com/docs/en/skills (WebSearch + WebFetch 実施済み)
**キャッシュ基準日**: 2026-02-28

---

### 変更検出結果

`git log --since="2026-02-28"` で以下ファイルを確認:
- `framework/claude/agents/` — 変更なし
- `framework/claude/skills/` — 変更なし
- `framework/claude/settings.json` — 変更なし
- `framework/claude/CLAUDE.md` — 変更なし

キャッシュ対象（sdd-release/SKILL.md 以外）はすべて 2026-02-28 以降に変更なし。
ただし sdd-release/SKILL.md も `git log` 確認の結果、2026-02-28 以降に変更なし（最新コミットは v1.1.0, v0.17.0 相当の過去コミット）。

→ 全ファイルについてキャッシュ検証を適用可。ただし公式ドキュメントの再確認を行ったため、新たに判明した仕様変更との照合も実施。

---

### Issues Found

#### [LOW] Task ツール名称: `Task` → `Agent` リネーム（後方互換あり）

**詳細**:
公式ドキュメント (sub-agents ページ) に以下の注記が存在する:

> "In version 2.1.63, the Task tool was renamed to Agent. Existing `Task(...)` references in settings and agent definitions still work as aliases."

現在のフレームワークでは:
- `framework/claude/CLAUDE.md`: `Task(subagent_type="sdd-architect", ...)` という表記を使用
- `framework/claude/settings.json`: `"Task(sdd-analyst)"` 等 26 エントリが `Task()` 形式
- 各スキルの `refs/` ファイル: `Task(subagent_type=..., run_in_background=true)` を使用
- スキルの `allowed-tools`: `Task` として記述 (sdd-roadmap, sdd-reboot, sdd-review-self)

**影響**: `Task(...)` はエイリアスとして引き続き動作するため、機能上の問題はない。ただし公式推奨は `Agent` に移行しつつある。将来バージョンでエイリアスが削除されるリスクは低いが、長期的には移行を検討すべき。

**ファイル/行**: `framework/claude/CLAUDE.md:5,32`, `framework/claude/settings.json:14-39`, `framework/claude/skills/sdd-roadmap/SKILL.md:3`

---

#### [LOW] CLAUDE.md の Commands カウント不一致

**詳細**:
`framework/claude/CLAUDE.md` の `### Commands (6)` は 6 コマンドを列挙しているが、実際には `framework/claude/skills/` に 7 つの SKILL.md が存在する:
- sdd-steering, sdd-roadmap, sdd-reboot, sdd-status, sdd-handover, sdd-release （6 つ → Commands (6) に列挙）
- **sdd-review-self** （フレームワーク内部用スキル — Commands テーブルに未掲載）

**評価**: `sdd-review-self` はフレームワーク開発者向けの内部ツールであり、ユーザー向けコマンドとしての列挙は不要。CLAUDE.md のカウント "6" は意図的な設計と判断できる。ただし `settings.json` に `Skill(sdd-review-self)` が含まれており齟齬が生じている — カウントが "6" を指すのは「ユーザー向けコマンド数」であることを明示するコメントがないため、将来的に混乱を招く可能性がある。

**ファイル/行**: `framework/claude/CLAUDE.md:146`, `framework/claude/settings.json:13`

---

### Confirmed OK

#### エージェント YAML フロントマター（26 エージェント全件）

公式仕様（必須フィールド: `name`, `description`; オプション: `model`, `tools`, `background` 等）に照らして確認:

| チェック項目 | 結果 |
|---|---|
| `name` フィールド存在 (全 26 ファイル) | OK — 全ファイルで確認済み |
| `description` フィールド存在 (全 26 ファイル) | OK — 全ファイルで確認済み |
| `model` の有効値 (sonnet/opus/inherit/省略) | OK — T2 Agents: `opus`, T3 Agents: `sonnet` (有効値) |
| `tools` 記述形式 | OK — カンマ区切り文字列形式 (Read, Glob, Grep, Write, Edit, Bash, WebSearch, WebFetch) |
| `background: true` の使用 | OK — 全 26 エージェントで設定済み（公式サポートフィールド） |
| 無効フィールドの混入 | OK — 未検出 |

**個別確認済みエージェント**:
- `sdd-analyst.md`: model=opus, tools=Read/Glob/Grep/Write/Edit/WebSearch/WebFetch, background=true ✓
- `sdd-architect.md`: model=opus, tools=Read/Glob/Grep/Write/Edit/WebSearch/WebFetch, background=true ✓
- `sdd-auditor-design.md`: model=opus, tools=Read/Glob/Grep/Write, background=true ✓
- `sdd-auditor-impl.md`: model=opus, tools=Read/Glob/Grep/Write, background=true ✓
- `sdd-auditor-dead-code.md`: model=opus, tools=Read/Glob/Grep/Write, background=true ✓
- `sdd-builder.md`: model=sonnet, tools=Read/Glob/Grep/Write/Edit/Bash, background=true ✓
- `sdd-taskgenerator.md`: model=sonnet, tools=Read/Glob/Grep/Write, background=true ✓
- `sdd-conventions-scanner.md`: model=sonnet, tools=Read/Glob/Grep/Write, background=true ✓
- `sdd-inspector-architecture.md` 〜 `sdd-inspector-visual.md` (18 ファイル): model=sonnet, background=true ✓
- Web 系 Inspector (e2e, visual, test): tools に Bash 追加 — 適切 ✓

キャッシュ: 2026-02-28 全件 PASS — 変更なし → **OK (cached)**

#### スキル YAML フロントマター（7 スキル全件）

公式仕様（推奨: `description`; オプション: `argument-hint`, `allowed-tools`, `model`, 等）に照らして確認:

| スキル | description | allowed-tools | argument-hint |
|---|---|---|---|
| sdd-roadmap | ✓ | Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | ✓ |
| sdd-steering | ✓ | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | ✓ |
| sdd-status | ✓ | Read, Glob, Grep | ✓ |
| sdd-handover | ✓ | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | 未設定（任意フィールド） |
| sdd-reboot | ✓ | Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | ✓ |
| sdd-release | ✓ | Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion | ✓ (`<patch|minor|major|vX.Y.Z> <summary>`) |
| sdd-review-self | ✓ | Task, Bash, Read, Glob, Grep | 未設定（任意フィールド） |

- `description` フィールド: 全 7 スキルで存在 ✓
- `allowed-tools` 形式: カンマ区切り文字列（公式形式）✓
- `argument-hint` フォーマット: 設定スキルでは適切な形式で記述 ✓
- `name` フィールド: スキルでは省略可（ディレクトリ名から自動導出） — 省略は仕様準拠 ✓

**sdd-release/SKILL.md フルレビュー** (キャッシュ範囲外として実施):
- フロントマター: description ✓, allowed-tools ✓, argument-hint ✓
- コンテンツ: エコシステム検出フロー、バージョン計算、リリース手順が完備 ✓
- AskUserQuestion: 引数不足時に使用 — 仕様準拠 ✓

**キャッシュ**: 6 スキル (sdd-release 以外) — OK (cached) / sdd-release — フルレビュー実施: **PASS**

#### Task ディスパッチパターン: subagent_type とエージェント定義の一致

全 `Task(subagent_type="sdd-*")` 呼び出しのエージェント定義照合:

| 呼び出しパターン | エージェントファイル |
|---|---|
| `Task(subagent_type="sdd-analyst")` | `sdd-analyst.md` ✓ |
| `Task(subagent_type="sdd-architect")` | `sdd-architect.md` ✓ |
| `Task(subagent_type="sdd-builder")` | `sdd-builder.md` ✓ |
| `Task(subagent_type="sdd-taskgenerator")` | `sdd-taskgenerator.md` ✓ |
| `Task(subagent_type="sdd-conventions-scanner")` | `sdd-conventions-scanner.md` ✓ |
| `Task(subagent_type="sdd-inspector-*")` (18 種) | 全件一致 ✓ |
| `Task(subagent_type="sdd-auditor-*")` (3 種) | 全件一致 ✓ |
| `Task(subagent_type="general-purpose")` (sdd-review-self) | Claude Code 組み込みエージェント ✓ |

**キャッシュ**: OK (cached) — 変更なし

#### settings.json 権限エントリ

`framework/claude/settings.json` 確認:
- `Skill()` エントリ: 7 件 (sdd-roadmap, sdd-steering, sdd-status, sdd-handover, sdd-reboot, sdd-release, sdd-review-self) — スキルファイルと完全一致 ✓
- `Task()` エントリ: 26 件 — エージェントファイル 26 件と完全一致 ✓
- `Bash()` エントリ: 14 件 (git, mkdir, ls, mv, cp, wc, which, sed, cat, echo, diff, playwright-cli, npm, npx) — 適切 ✓
- `defaultMode: "acceptEdits"` — 有効な権限モード ✓

**キャッシュ**: OK (cached) — 変更なし

#### SubAgent ネスト禁止制約の準拠

公式仕様: "Subagents cannot spawn other subagents."

- T3 Builder は `Bash` ツールのみ使用（`Task` ツールなし）→ ネスト試行なし ✓
- T3 Inspector 群はすべて `Task` ツールを含まない ✓
- T2 Auditor 群はすべて `Task` ツールを含まない ✓
- T2 Architect / Analyst は `Task` ツールを含まない ✓
- T3 TaskGenerator は `Task` ツールを含まない ✓
- T3 ConventionsScanner は `Task` ツールを含まない ✓

**結論**: 全 SubAgent が `Task`/`Agent` ツールを tools リストに持たない → 非ネスト制約に完全準拠 ✓

**キャッシュ**: OK (cached)

#### ツール可用性チェック

エージェントが参照するツールはすべて Claude Code 内部ツール:
- `Read, Glob, Grep, Write, Edit, Bash, WebSearch, WebFetch, AskUserQuestion` — すべて有効なツール名 ✓
- `sdd-inspector-best-practices.md` の `WebSearch, WebFetch`: 設計検討で外部参照が必要な Inspector のみに付与 — 適切 ✓
- `sdd-architect.md` の `WebSearch, WebFetch`: 設計フェーズでの外部調査に必要 — 適切 ✓
- `sdd-analyst.md` の `WebSearch, WebFetch`: ゼロベース再設計でのリサーチに必要 — 適切 ✓
- `sdd-builder.md` の `Bash`: TDD サイクルのテスト実行に必要 — 適切 ✓
- Web 系 Inspector (`e2e`, `visual`, `test`) の `Bash`: テスト実行/Playwright CLI に必要 — 適切 ✓

---

### コンプライアンスステータステーブル

| チェック項目 | ステータス | 備考 |
|---|---|---|
| エージェント YAML フロントマター (name) | PASS | 26/26 ✓ |
| エージェント YAML フロントマター (description) | PASS | 26/26 ✓ |
| エージェント YAML フロントマター (model) | PASS | opus/sonnet — 有効値 |
| エージェント YAML フロントマター (tools) | PASS | 全件有効ツール名 |
| エージェント YAML フロントマター (background) | PASS | 全件 true |
| スキル YAML フロントマター (description) | PASS | 7/7 ✓ |
| スキル YAML フロントマター (allowed-tools) | PASS | 7/7 ✓ |
| スキル YAML フロントマター (argument-hint) | PASS | 該当スキルで設定済み |
| Task ディスパッチ — subagent_type 一致 | PASS | 全呼び出しで一致 |
| settings.json — Skill() エントリ | PASS | 7/7 一致 |
| settings.json — Task() エントリ | PASS | 26/26 一致 |
| settings.json — 構造・形式 | PASS | JSON 有効, 権限形式準拠 |
| SubAgent ネスト禁止制約 | PASS | 全 SubAgent が Task ツール非保持 |
| ツール可用性 | PASS | 全エージェントが有効ツールのみ参照 |
| Task ツール名称 (Task vs Agent) | WARN (LOW) | エイリアス互換あり、将来移行要検討 |
| CLAUDE.md Commands カウント | WARN (LOW) | "6" は意図的（sdd-review-self は内部ツール）だが明示なし |

---

### Overall Assessment

**総合判定: PASS（軽微な LOW 指摘 2 件）**

SDDフレームワークのエージェント定義・スキル定義・settings.json・CLAUDE.md は、Claude Code プラットフォーム仕様に対して実質的に準拠している。

**CRITICAL / HIGH / MEDIUM 問題: なし**

**LOW 問題: 2 件**

1. **Task ツール名のエイリアス利用**: v2.1.63 以降、公式ツール名は `Agent` に移行しているが、フレームワーク全体が `Task` を使用している。公式ドキュメントでは後方互換が保証されており、現時点で機能上の問題はない。将来のメジャーバージョンアップ時に移行を検討すること。

2. **CLAUDE.md の Commands カウント**: `### Commands (6)` と記載があるが、スキルファイルは 7 件存在する。`sdd-review-self` はフレームワーク内部ツールとして意図的に除外されているが、その旨の説明がないため将来の混乱源となりうる。コメントによる明示化を推奨。

**2026-02-28 以降に変更されたファイルは検出されなかった**ため、すべてのキャッシュ検証は有効である。sdd-release/SKILL.md についてフルレビューを実施した結果、フロントマター・コンテンツ共に仕様準拠を確認した。
