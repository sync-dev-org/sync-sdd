# SDD Framework Self-Review Report
**Date**: 2026-02-27 | **Agents**: 4 dispatched, 4 completed | **Version**: v1.4.0+sdd-reboot

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| .claude/ にsdd-analyst未インストール | Agent 4 | 開発リポでは framework/ がソース。install.sh 実行前は .claude/ に未反映が正常 |
| .claude/ にsdd-reboot未インストール | Agent 4 | 同上 |
| .claude/settings.json に新エントリ未反映 | Agent 4 | 同上 |
| .claude/CLAUDE.md にAnalyst未記載 | Agent 4 | 同上 |
| sdd-review-self にreboot/analyst固有検証項目なし | Agent 3 | self-review は general-purpose agents に動的プロンプトを渡すため、基準は静的リストではない |
| Revise mode tie-breaking ルール欠如 | Agent 1 | v1.4.0以前からの既存課題。今回の変更に起因しない |
| run.md ConventionsScanner パス表記混在 | Agent 3 | v1.4.0以前からの既存課題。今回の変更に起因しない |

## CRITICAL (0)

## HIGH (1)

### H1: Analyst失敗時のbranch cleanup矛盾
**Location**: `framework/claude/skills/sdd-reboot/SKILL.md:52` vs `refs/reboot.md:63`
**Description**: SKILL.md は「delete branch, return to main, report error」と規定するが、reboot.md Phase 4 は「BLOCK with error」のみ。reboot.mdに従った場合、ブランチが残留したままBLOCKされる。
**Evidence**: Agent 1, Agent 3 が同一問題を検出
**Fix**: reboot.md Phase 4 Step 3 を SKILL.md と一致させる（branch削除 + main checkout + エラー報告）

## MEDIUM (6)

### M1: CLAUDE.md SubAgent Failure Handling からAnalystが漏れている
**Location**: `framework/claude/CLAUDE.md:115`
**Description**: file-writing SubAgent列挙にAnalystが含まれない（Inspectors/Auditors/Builders/ConventionsScannerのみ）
**Evidence**: Agent 2, Agent 3
**Fix**: Analystを列挙に追加

### M2: CLAUDE.md commit format に `reboot:` プレフィックスが未記載
**Location**: `framework/claude/CLAUDE.md:329`
**Description**: コミットメッセージ形式は3種（Wave/feature/cross-cutting）のみ記載。reboot.md で使用する `reboot: {summary}` が漏れている
**Evidence**: Agent 3
**Fix**: commit format一覧に追加

### M3: sdd-analyst.md Step 1 にテンプレート読み込み指示が欠落
**Location**: `framework/claude/agents/sdd-analyst.md:29-34`
**Description**: Step 6 で「following the template structure」と要求するが、Step 1 Context Absorption にテンプレートパスの読み込み指示がない
**Evidence**: Agent 3
**Fix**: Step 1 にテンプレート読み込みを追加

### M4: reboot.md Phase 7 のwave境界session.md auto-draftルール未定義
**Location**: `framework/claude/skills/sdd-reboot/refs/reboot.md:131-175`
**Description**: run.md では Wave QG post-gate で auto-draft が規定されるが、reboot.md の design-only pipeline には wave 境界でのルールがない
**Evidence**: Agent 3
**Fix**: Phase 7 に wave 完了時の auto-draft ポリシーを明記

### M5: reboot.md Phase 6a/6b のdot-prefixedディレクトリ扱いの非対称性
**Location**: `framework/claude/skills/sdd-reboot/refs/reboot.md:85-94`
**Description**: Phase 6a はdot-prefixed dirs（.wave-context/, .cross-cutting/）をアーカイブ対象外とするが、Phase 6b はspecs/全体を削除するため含まれる
**Evidence**: Agent 1, Agent 3
**Fix**: Phase 6a にdot-prefixed dirsも含めるか、不要であることを明記

### M6: reboot.md NO-GO exhaustion後のskip時EXIT条件が不明確
**Location**: `framework/claude/skills/sdd-reboot/refs/reboot.md:180`
**Description**: NO-GO retry上限到達 → escalation → skip選択時、当該specのwave EXIT条件判定が未規定。run.md Step 6 Blocking Protocolへの明示的参照もない
**Evidence**: Agent 1
**Fix**: escalation時の参照先をrun.md Step 6として明記、skip時のspec状態ハンドリングを追加

## LOW (1)

### L1: CLAUDE.md Analyst context budget説明と完了レポート形式の表現ズレ
**Location**: `framework/claude/CLAUDE.md:41`
**Description**: 「return only structured summary」と述べるが、Analyst は `ANALYST_COMPLETE` + フィールド群 + `WRITTEN:{path}` の複合形式。Builder形式と同様だが、「WRITTEN のみ」パターンと誤読される可能性
**Evidence**: Agent 2, Agent 3
**Fix**: 表現を明確化（「return structured summary with WRITTEN:{path}」等）

## Platform Compliance

| Item | Status |
|---|---|
| sdd-analyst.md フロントマター | OK (verified) |
| sdd-reboot/SKILL.md フロントマター | OK (verified) |
| Task dispatch パターン | OK (verified) |
| settings.json (framework版) 完全性 | OK (verified) |
| CLAUDE.md (framework版) 内部整合 | OK (verified) |
| 既存25エージェント フロントマター | OK (cached) |
| 既存6スキル フロントマター | OK (cached) |
| model値/background/ツール適切性 | OK (cached) |

## Overall Assessment

新規 sdd-reboot スキルと sdd-analyst エージェントは全体的に良好に統合されている。プラットフォーム準拠は完全。主要な問題は H1（Analyst失敗時のbranch cleanup矛盾）のみで、SKILL.md と refs/reboot.md の整合を取れば解消する。M1-M6 は全てドキュメント/仕様の軽微な欠落で、機能的影響は小さい。

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 | H1 | Analyst失敗時branch cleanup | refs/reboot.md |
| 2 | M3 | Analyst template読み込み指示追加 | sdd-analyst.md |
| 3 | M6 | NO-GO exhaustion escalation明確化 | refs/reboot.md |
| 4 | M1 | SubAgent Failure Handling にAnalyst追加 | CLAUDE.md |
| 5 | M2 | commit format に reboot: 追加 | CLAUDE.md |
| 6 | M4 | wave境界 auto-draft policy追加 | refs/reboot.md |
| 7 | M5 | dot-prefixed dir handling明記 | refs/reboot.md |
| 8 | L1 | Analyst context budget表現修正 | CLAUDE.md |
