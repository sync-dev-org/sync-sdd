# SDD Framework Self-Review Report (External Engine)
**Date**: 2026-03-04 | **Engine**: codex [default] | **Agents**: 4 dispatched, 4 completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| M-agent-dispatch-policy (`framework/claude/CLAUDE.md:84`) | agent-4-compliance | `USER_DECISION` D10 で `run_in_background` デフォルト運用を採用済み。加えて D96 で同論点を FP と再判定済み。 |
| L-built-in-agent-doc (`framework/claude/skills/sdd-review-self/SKILL.md:157`) | agent-4-compliance | 公式 Claude Code docs に built-in subagent として `General-purpose` が明記されているため FP（https://docs.claude.com/en/docs/claude-code/subagents）。 |

## A) 自明な修正 (14件) — OK で全件修正します

| ID | Sev | Summary | Fix | Target |
|---|---|---|---|---|
| AF-01 | HIGH | Cross-Cutting verdict 保存先が `reviews/verdicts.md` と `verdicts.md` で分岐 | `scope-dir` と Step 8 保存先を単一仕様に統一（`specs/.cross-cutting/{id}/verdicts.md` へ揃える） | framework/claude/skills/sdd-roadmap/refs/review.md:84 |
| AF-02 | MEDIUM | `run [--gate] [--consensus N]` の複合フラグ dispatch が未定義 | SKILL.md Detect Mode に複合フラグ分岐を明記 | framework/claude/skills/sdd-roadmap/SKILL.md:4 |
| AF-03 | MEDIUM | `review dead-code [flags]` 宣言に対し flags 付き dispatch が未定義 | `review dead-code --consensus N` 等の分岐を明文化 | framework/claude/skills/sdd-roadmap/SKILL.md:4 |
| AF-04 | MEDIUM | Design Review gate に `phase=design-generated` 必須条件がない | Phase Gate に phase 検証を追加し CLAUDE.md 規約へ整合 | framework/claude/skills/sdd-roadmap/refs/review.md:22 |
| AF-05 | LOW | B{seq} 決定責務の説明が二重化 | 「Router 事前決定」か「review.md 算出」どちらかに記述統一 | framework/claude/skills/sdd-roadmap/refs/review.md:85 |
| AF-06 | HIGH | review-self-ext の FILE_LIST から `settings/scripts/*.sh` が欠落 | `prep.md` と `SKILL.md` の対象一覧に `multiview-grid.sh` を含める | framework/claude/skills/sdd-review-self-ext/refs/prep.md:23 |
| AF-07 | MEDIUM | tmux チャネル例が旧形式（B{seq}なし） | 例を `sdd-{SID}-B{seq}-...` 形式へ更新 | framework/claude/sdd/settings/rules/tmux-integration.md:115 |
| AF-08 | MEDIUM | auditor テンプレートが旧列定義/旧ヘッダ | `SKILL.md` の現行テンプレートへ同期（Pipeline 行・列構成更新） | framework/claude/skills/sdd-review-self-ext/refs/auditor.md:65 |
| AF-09 | LOW | `$SCOPE_DIR` 参照が定義記述より先に現れる | 変数定義順を前倒しして手順曖昧性を解消 | framework/claude/skills/sdd-review-self-ext/SKILL.md:66 |
| AF-10 | HIGH | Compliance inspector 指示が CPF と Markdown 表を同時必須化して矛盾 | 出力仕様を CPF へ一本化（表は任意/別出力へ分離） | framework/claude/skills/sdd-review-self-ext/refs/agent-4-compliance.md:40 |
| AF-11 | MEDIUM | 「ISSUES と COMPLIANT 両方必須」が CPF 空セクション省略規則と矛盾 | いずれか空の場合は省略可に統一 | framework/claude/skills/sdd-review-self-ext/refs/agent-4-compliance.md:43 |
| AF-12 | MEDIUM | `verdict-data.txt` 欠落時の分岐がなく集計フェーズがデッドエンド化 | 完了条件に `verdict-data.txt` 存在確認を追加し欠落時は再生成へ分岐 | framework/claude/skills/sdd-review-self-ext/SKILL.md:356 |
| AF-13 | LOW | run/review 相互参照で循環依存が読解負荷を増加 | 片側を「参照先の要点要約」に置換し循環を緩和 | framework/claude/skills/sdd-roadmap/refs/run.md:185 |
| AF-14 | LOW | create 後の `design.md` 初期状態説明が CRUD 定義と不一致 | design.md 側の説明を CRUD 定義に合わせる | framework/claude/skills/sdd-roadmap/refs/design.md:13 |

## B) ユーザー判断が必要 (2件)

### DR-01: Wave cross-check で blocked spec を含めるかの運用ポリシー不整合
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:240  
**Description**: Wave 完了条件は `implementation-complete` または `blocked` だが、wave cross-check 側に `blocked` 除外規則がなく、`--wave N` review 収集条件（`wave<=N`）と組み合わせると blocked spec が判定ノイズとして混入しうる。  
**Impact**: Wave 判定の NO-GO/再試行が過剰発火する可能性があり、意思決定品質に影響（MEDIUM）。  
**Recommendation**: `blocked` を cross-check 対象から除外するか、別カテゴリで集計する方針を明文化 — 運用ポリシー依存で自動修正の一意性がないため。  

### DR-02: Task 呼び出しで `model` 指定を許容するか（SDK 仕様準拠 vs 独自運用）
**Location**: framework/claude/skills/sdd-review-self/SKILL.md:58  
**Description**: Agent 4 指摘では Task 入力が `description/prompt/subagent_type` 前提で、`model` 指定は仕様外。現行実装は `model` を渡しており、プラットフォーム互換性方針の確定が必要。  
**Impact**: 実行環境差で dispatch 挙動が変わる可能性があり、誤判定/失敗時の再現性に影響（HIGH）。  
**Recommendation**: 公式 Task 仕様に合わせて `model` を外すか、互換レイヤーを導入して feature-flag 化 — どちらを標準運用にするかは設計判断が必要。  

## Platform Compliance

| Item | Status | Source |
|---|---|---|
| Built-in `general-purpose` subagent の存在 | OK (verified) | https://docs.claude.com/en/docs/claude-code/subagents |
| Subagent の foreground/background 実行概念 | OK (verified) | https://docs.claude.com/en/docs/claude-code/subagents |
| Agent SDK `Task` 入力フィールド（`description`/`prompt`/`subagent_type`） | NG against current usage (`model`) | https://docs.claude.com/en/docs/agent-sdk/python |
