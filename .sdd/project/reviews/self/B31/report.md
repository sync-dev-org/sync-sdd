# SDD Framework Self-Review Report (External Engine)
**Date**: 2026-03-03T20:59:25Z | **Engine**: codex [default] | **Agents**: 4 dispatched, 4 completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| `subagent_type` parameter undocumented | 4 | FP. Verified in Anthropic's official Claude Code SDK `TaskTool_20250919` type, which includes `subagent_type`: https://github.com/anthropics/claude-code/blob/main/sdk-ts/src/api.ts |
| `run_in_background` parameter undocumented | 4 | FP. Verified in Anthropic's official Claude Code SDK `TaskTool_20250919` type, which includes `run_in_background`: https://github.com/anthropics/claude-code/blob/main/sdk-ts/src/api.ts |
| `model` override undocumented | 4 | FP. Verified in Anthropic's official Claude Code SDK `TaskTool_20250919` type, which includes `model`: https://github.com/anthropics/claude-code/blob/main/sdk-ts/src/api.ts |

## A) 自明な修正 (7件) — OK で全件修正します

| ID | Sev | Summary | Fix | Target |
|---|---|---|---|---|
| A1 | HIGH | Cross-cutting review だけ scope-dir が `/reviews/` 配下を向き、verdict 保存先とずれる | `framework/claude/skills/sdd-roadmap/refs/review.md` の cross-cutting scope-dir を framework 全体の規約に合わせて `specs/.cross-cutting/{id}/` に統一する | framework/claude/skills/sdd-roadmap/refs/review.md:84 |
| A2 | HIGH | `sdd-review-self-ext` の lead pipeline で `${CACHED_OK}` を生成前に使用している | Step 2/3 の順序を入れ替えるか、Step 2 では未使用にして `CACHED_OK` 構築後に Agent 4 prompt を生成する | framework/claude/skills/sdd-review-self-ext/SKILL.md:141 |
| A3 | HIGH | reboot が存在しない相対 `refs/run.md` を参照している | 参照先を `framework/claude/skills/sdd-roadmap/refs/run.md` に修正する | framework/claude/skills/sdd-reboot/refs/reboot.md:120 |
| A4 | MEDIUM | external self-review の shared prompt scope から `scripts/*.sh` が漏れている | `$FILE_LIST` に `framework/claude/sdd/settings/scripts/*.sh` を追加する | framework/claude/skills/sdd-review-self-ext/SKILL.md:86 |
| A5 | LOW | 基準ドキュメントの Path 一覧から `.sdd/settings/scripts/` が欠落している | `CLAUDE.md` の管理パス一覧へ scripts ディレクトリを追記する | framework/claude/CLAUDE.md:119 |
| A6 | LOW | wave scope 名が `wave-scoped-cross-check` と `wave-1..N` で揺れている | 1 つの正規表記に統一し、review.md 側にも明示する | framework/claude/agents/sdd-auditor-impl.md:242 |
| A7 | HIGH | default permission allowlist に `Bash(rm *)` がなく、documented cleanup 手順を満たせない | `settings.json` に `Bash(rm *)` を追加する | framework/claude/settings.json:43 |

## B) ユーザー判断が必要 (5件)

### B1: `review impl {feature} [tasks]` の公開インターフェースと実装が不一致
**Location**: framework/claude/skills/sdd-roadmap/SKILL.md:22
**Description**: Router は impl review が task 番号入力を受け付けると宣言していますが、`refs/review.md` は `--consensus` `--cross-check` `--wave` しか解釈せず、task 指定の処理経路がありません。  
**Impact**: HIGH。利用者は task-scoped impl review があると誤認し、実際には全体 review が走るか、未定義動作になります。  
**Recommendation**: 公開インターフェースから task 指定を削除するか、review ref に task-scoped dispatch を正式実装する — どちらを製品機能として残すかの判断が先です。

### B2: `revise` の Single-Spec / Cross-Cutting 自動判定が誤 route しうる
**Location**: framework/claude/skills/sdd-roadmap/SKILL.md:34
**Description**: 先頭語が spec 名と一致すると即 Single-Spec に落ちますが、cross-cutting への昇格判定は downstream dependency 探索に依存しています。依存を持たない複数 spec 横断変更や、説明文先頭語の偶然一致を正しく扱えません。  
**Impact**: MEDIUM。複数 spec をまたぐ改修が単一 spec revision として処理され、レビュー/保存先/影響分析を誤る可能性があります。  
**Recommendation**: 先頭語一致だけで確定せず、影響 spec 数の事前解析またはユーザー確認を追加する — routing policy の UX と精度のトレードオフがあるため設計判断が必要です。

### B3: Wave QG が `blocked` spec を含む wave でも review/commit に進みうる
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:240
**Description**: Wave 完了条件は `implementation-complete` または `blocked` ですが、その直後の Wave QG は wave 全体の impl cross-check / dead-code review を前提に進みます。`blocked` spec を除外する規則も、QG 中断条件も定義されていません。  
**Impact**: MEDIUM。未完了 spec を含む wave に対して品質ゲートと commit が走る解釈になり、運用判断を誤らせます。  
**Recommendation**: `blocked` spec を QG 対象から除外するか、wave 自体を未完了として QG を止めるかを決めて明文化する — これは backlog policy と release semantics に関わるためユーザー判断が必要です。

### B4: `--pipeline agent` の Prep dispatch 手順が tmux / 非 tmux の両方で完結していない
**Location**: framework/claude/skills/sdd-review-self-ext/SKILL.md:160
**Description**: Prep Agent dispatch が `{slot_pane_id}` と `{SID}` の確定前に置かれており、tmux 経路では必要値が揃っていません。さらに background Bash fallback は説明だけで、実行可能な具体手順がありません。  
**Impact**: HIGH。agent pipeline の Prep 経路が documented procedure だけでは再現不能で、self-review orchestration が途中で止まります。  
**Recommendation**: tmux slot 確定後に dispatch する前提へ組み替え、非 tmux fallback を実行可能レベルで仕様化する — pipeline architecture 全体の整理を伴うため、対症修正より設計判断を優先すべきです。

### B5: auto-fix authority の canonical source が相互参照ループになっている
**Location**: framework/claude/CLAUDE.md:180
**Description**: `CLAUDE.md` は auto-fix の運用詳細を `refs/run.md` に委譲し、`refs/run.md` は counter limit と reset trigger を `CLAUDE.md` に戻しています。単一の正本がなく、retry semantics の検証が難しくなっています。  
**Impact**: LOW。即時故障ではありませんが、今後の変更で仕様差分を生みやすく、保守コストが増えます。  
**Recommendation**: canonical source を 1 ファイルに寄せ、他方は要約参照にする — 仕様の責務分割をどう置くかは文書設計の判断が必要です。

## Platform Compliance

| Item | Status | Source |
|---|---|---|
| agent-frontmatter-fields | OK (cached) | https://docs.claude.com/en/docs/claude-code/sub-agents |
| agent-model-values | OK (cached) | https://docs.claude.com/en/docs/claude-code/sub-agents |
| skill-frontmatter-fields | OK | https://docs.claude.com/en/docs/claude-code/skills |
| dispatch-existing-agent-definitions | OK (cached) | https://docs.claude.com/en/docs/claude-code/sub-agents |
| general-purpose-built-in-agent | OK (cached) | https://docs.claude.com/en/docs/claude-code/sub-agents |
| settings-permission-format | OK (cached) | https://docs.claude.com/en/docs/claude-code/settings |
| settings-agent-skill-entry-match | OK (cached) | https://docs.claude.com/en/docs/claude-code/settings |
| tool-availability-names | OK (cached) | https://docs.claude.com/en/docs/claude-code/settings |
| agent-tool-parameter-subagent_type | FP eliminated | https://github.com/anthropics/claude-code/blob/main/sdk-ts/src/api.ts |
| agent-tool-parameter-run_in_background | FP eliminated | https://github.com/anthropics/claude-code/blob/main/sdk-ts/src/api.ts |
| agent-tool-parameter-model-override | FP eliminated | https://github.com/anthropics/claude-code/blob/main/sdk-ts/src/api.ts |
