## Platform Compliance Report

**生成日時**: 2026-03-03T19:15:15+0900
**レビュー対象**: SDD framework agents, skills, settings.json, CLAUDE.md (SubAgent dispatch sections)
**キャッシュ適用**: B21 検証済みアイテムは "OK (cached)" としてスキップ

---

### Issues Found

- [HIGH] `Skill(sdd-review-self-codex)` が `settings.json` の `permissions.allow` に未登録。スキルファイル `framework/claude/skills/sdd-review-self-codex/SKILL.md` は存在するが、対応する許可エントリがなく、Claude Code が当スキルを `Skill()` ツールで呼び出す際にブロックされる可能性がある。
  - **ファイル**: `framework/claude/settings.json`（`Skill(sdd-review-self-codex)` エントリ欠落）

- [LOW] `sdd-review-self-codex` の SKILL.md に `argument-hint` フィールドがない。他の引数を取るスキル（`sdd-review-self` を除く有引数スキル）はすべて `argument-hint` を持つが、本スキルは省略されている。プラットフォーム仕様上は optional であり動作上の問題はないが、コマンドピッカーでのヒント表示が欠落する。
  - **ファイル**: `framework/claude/skills/sdd-review-self-codex/SKILL.md`（行 1-4 のフロントマター）

---

### Confirmed OK

| カテゴリ | 対象 | ステータス | 備考 |
|---------|------|-----------|------|
| Agent frontmatter (model) | 全 27 エージェント | OK (cached) | B21 検証済み |
| Agent frontmatter (tools) | 全 27 エージェント | OK (cached) | B21 検証済み |
| Agent frontmatter (description) | 全 27 エージェント | OK (cached) | B21 検証済み |
| Agent frontmatter (background) | 全 27 エージェント | OK (cached) | B21 検証済み |
| Skills frontmatter (sdd-roadmap) | `sdd-roadmap/SKILL.md` | OK (cached) | description, allowed-tools, argument-hint 全項目確認済み |
| Skills frontmatter (sdd-steering) | `sdd-steering/SKILL.md` | OK (cached) | B21 検証済み |
| Skills frontmatter (sdd-status) | `sdd-status/SKILL.md` | OK (cached) | B21 検証済み |
| Skills frontmatter (sdd-handover) | `sdd-handover/SKILL.md` | OK (cached) | B21 検証済み |
| Skills frontmatter (sdd-reboot) | `sdd-reboot/SKILL.md` | OK (cached) | B21 検証済み |
| Skills frontmatter (sdd-release) | `sdd-release/SKILL.md` | OK (cached) | B21 検証済み |
| Skills frontmatter (sdd-review-self) | `sdd-review-self/SKILL.md` | OK (cached) | B21 検証済み |
| Skills frontmatter (sdd-publish-setup) | `sdd-publish-setup/SKILL.md` | OK (cached) | B21 検証済み |
| Skills frontmatter (sdd-review-self-codex) | `sdd-review-self-codex/SKILL.md` | OK (新規検証) | description あり: `"Self-review (Codex CLI experiment): 4-agent parallel review via OpenAI Codex"`, allowed-tools あり: `Bash, Read, Glob, Grep, Write`。プラットフォーム仕様上 required フィールドはすべて揃っている。`argument-hint` は省略 (optional フィールド、LOW 指摘) |
| Agent dispatch patterns | CLAUDE.md, skills/refs/ | OK (cached) | B21 検証済み。`general-purpose` はビルトインのため Agent() エントリ不要 |
| settings.json — Agent() エントリ数 | 27 エントリ | OK | agent ファイル 27 個と一致。全エントリ確認済み |
| settings.json — Skill() エントリ数 | 8 エントリ / 9 スキル | ISSUE | `sdd-review-self-codex` 欠落 (HIGH 指摘済み) |
| settings.json — Bash() エントリ | git, mkdir, ls, mv, cp, wc, which, sed, cat, echo, curl, diff, playwright-cli, tmux, npm, npx | OK (cached) | B21 検証済み |
| NEW: `tmux-integration.md` | `framework/claude/sdd/settings/rules/tmux-integration.md` | OK (新規検証) | ルールファイル (非スキル/非エージェント)。パーミッション登録不要。`Bash(tmux *)` は settings.json に登録済み。ファイル内容: Pattern A (Server Lifecycle), Pattern B (One-Shot Command), Orphan Cleanup, Shared Operations を定義。適切な pane ID ベース操作を採用 (インデックスベース禁止を明示) |
| MODIFIED: CLAUDE.md Session Resume 5a | `framework/claude/CLAUDE.md` | OK (新規検証) | 旧版の inline tmux コマンド (`tmux list-panes ... kill-pane`) を廃止し、`tmux-integration.md` の Orphan Cleanup パターンへ委譲する形式に変更。参照先ファイルは存在確認済み。クリーンアップ範囲が `sdd-devserver-*` のみから `sdd-*` 全体に拡大された点は tmux-integration.md の記述と整合 |
| MODIFIED: CLAUDE.md tmux Integration 規約 | `framework/claude/CLAUDE.md` | OK (新規検証) | "Server Lifecycle" と "One-Shot Command" の 2 パターンを参照する形式に更新。`tmux-integration.md` の Pattern A/B と一致 |
| MODIFIED: review.md Web Inspector Server Protocol | `framework/claude/skills/sdd-roadmap/refs/review.md` | OK (新規検証) | "Apply **Server Lifecycle pattern** from `{{SDD_DIR}}/settings/rules/tmux-integration.md`" へのリファクタリング。旧版の inline 手順を外部ルールに委譲。Start/Stop/Fallback の骨格は review.md 内に保持されており、参照の一貫性を維持 |
| Tool availability — agents | 全 27 エージェント | OK (cached) | B21 検証済み。各エージェントの tools リストは プラットフォームで有効なツール名のみ |
| `general-purpose` ビルトイン | CLAUDE.md, sdd-review-self-codex/SKILL.md | OK | ビルトインエージェントのため Agent() エントリ不要。sdd-review-self-codex では Agent 名に `sdd-codex-agent-{N}` を使用しており Codex CLI プロセスを指す (Claude Code Agent ではない)。問題なし |

---

### Overall Assessment

**重大度サマリー**: CRITICAL 0件 / HIGH 1件 / MEDIUM 0件 / LOW 1件

**HIGH — settings.json Skill() エントリ欠落**:
`sdd-review-self-codex` スキルが `framework/claude/settings.json` の `permissions.allow` リストに登録されていない。Claude Code の `acceptEdits` モード下では Skill ツールの実行に許可エントリが必要であり、このエントリがなければ `/sdd-review-self-codex` の呼び出し時にユーザー承認プロンプトが発生するか、または実行がブロックされる。
**修正内容**: `"Skill(sdd-review-self-codex)"` を `framework/claude/settings.json` の `permissions.allow` 配列に追加する。

**LOW — argument-hint 省略**:
スキルの動作に影響はない。コマンドピッカーでの UI ヒント表示が欠落するのみ。必要であれば追加を検討。

**新規ファイル・変更ファイルの総評**:
- `tmux-integration.md` (新規): 適切に設計されており、パーミッション上の問題なし
- `CLAUDE.md` の tmux 変更: 外部ルールへの委譲が一貫して実施されており、内容的矛盾なし
- `review.md` の Web Inspector Server Protocol リファクタリング: 参照整合性を維持しており問題なし

**推奨アクション**: `framework/claude/settings.json` に `Skill(sdd-review-self-codex)` を追加した後、`install.sh` で `.claude/settings.json` へ反映する。

---

*Sources (WebSearch):*
- [Extend Claude with skills - Claude Code Docs](https://code.claude.com/docs/en/skills)
- [Create custom subagents - Claude Code Docs](https://code.claude.com/docs/en/sub-agents)
- [Skill authoring best practices - Claude API Docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [Claude Code settings - Claude Code Docs](https://code.claude.com/docs/en/settings)
