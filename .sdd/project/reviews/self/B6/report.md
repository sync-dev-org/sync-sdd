# SDD Framework Self-Review Consolidated Report

**Date**: 2026-02-24
**Mode**: full
**Batch**: B6
**Version**: v1.1.2+sdd-root-move (uncommitted)
**Agents**: 5 dispatched, 5 completed

---

## Raw Findings Summary

| Agent | Role | C | H | M | L |
|-------|------|---|---|---|---|
| 1 | Flow Integrity | 0 | 0 | 4 | 2 |
| 2 | Regression Detection | 0 | 0 | 0 | 1 |
| 3 | Consistency & Dead Ends | 0 | 3 | 3 | 2 |
| 4 | Claude Code Compliance | 0 | 0 | 1 | 4 |
| 5 | Dead Code & Unused Refs | 0 | 0 | 1 | 1 |
| **Total (raw)** | | **0** | **3** | **9** | **10** |
| **Merged** | Agent 2 L1 + Agent 5 M1 | | | | -1 |
| **Unique** | | **0** | **3** | **8** | **10** |

---

## False Positives Eliminated (19)

| # | Finding | Reporting Agent(s) | Elimination Reason |
|---|---------|--------------------|--------------------|
| 1 | install.sh .gitignore timing in v1.2.0 migration | Agent 3 (H) | .gitignore管理はinstallフェーズで無条件実行。migrationフェーズの責務外。順序は正しい |
| 2 | Session Resume で wave-level verdicts 未復元 | Agent 3 (H) | wave/verdicts.md は review.md L39 でレビュー実行時にオンデマンド読み込み。Session Resume時のキャッシュ不要 |
| 3 | sdd-review-self が Task(general-purpose) を使用、settings.json に未許可 | Agent 3 (H) | framework-internal ツール。標準パーミッションモデル外。ユーザー承認で動作 |
| 4 | v1.2.0 migration で profiles が暗黙的 | Agent 1 (M) | `mv` はディレクトリツリー全体を移動。profiles/ は settings/ の配下であり自動的に移動される |
| 5 | {{SDD_DIR}} 解決がSubAgent profilesで暗黙的 | Agent 1 (M) | CLAUDE.md がプロジェクト指示としてSubAgentコンテキストに注入される。意図された設計パターン |
| 6 | revise.md Part A Step 4 の phase 遷移が design 実行前 | Agent 1 (M) | design.md のphase gateは revision mode で design-generated を受け入れる。正しい revision フロー |
| 7 | Cross-cutting aggregate cap のスコープ未明示 | Agent 1 (M) | カウンターは spec.yaml.orchestration に格納 = per-spec。データ構造からスコープは自明 |
| 8 | design-review.md に System Flows / Specifications Traceability 欠落 | Agent 3 (M) | テンプレートで条件付きオプション ("Skip this section entirely for simple CRUD changes", "Omit when single component")。必須チェックに含めない設計 |
| 9 | Inspector 数表記が紛らわしい | Agent 3 (M) | "6 impl +2 web (impl only, web projects)" は正確。括弧でスコープ説明済み |
| 10 | Task(subagent_type=...) 記法が公式未文書化 | Agent 4 (M) | subagent_type は Task tool の実際のパラメータ名（システムプロンプトで定義）。フレームワーク文書は正しい |
| 11 | Commands (6) vs 実際 7 スキル | Agent 2 (L) + Agent 5 (M) | 意図的設計 (D2)。CLAUDE.md はユーザー向け6コマンド。sdd-review-self は framework-internal。B5で既に FP 判定済み |
| 12 | review.md verdict destinations に cross-cutting/self-review | Agent 1 (L) | Verdict Destination は参照カタログ。Router dispatch テーブルではない |
| 13 | acceptEdits + Builder Bash プロンプト | Agent 1 (L) | 設計通り。最小デフォルト権限 + profiles の Suggested Permissions で拡張 |
| 14 | VERDICT:ERROR ハンドリングの非対称性 | Agent 3 (L) | review.md L118 でプロトコルレベルで統一ハンドリング。各 Inspector に個別 ERROR 出力例不要 |
| 15 | Skills に name フィールド未設定 | Agent 4 (L) | Claude Code 公式仕様でオプショナル。ディレクトリ名で代替 |
| 16 | sdd-review-self allowed-tools に Write 未設定 | Agent 4 (L) | Lead が skill を実行し、Lead は全ツール使用可能。skill は正常に動作 |
| 17 | settings.json に deny/ask セクション未設定 | Agent 4 (L) | 設計上の選択。allow リスト + acceptEdits で十分 |
| 18 | AskUserQuestion が SubAgent で未使用 | Agent 4 (L) | background SubAgent はインタラクティブツール使用不可。正しいアーキテクチャ制約 |
| 19 | Wave-Scoped Cross-Check が14 Inspector に重複 | Agent 5 (L) | アーキテクチャ上の必然。SubAgent は共有コンテキストなし (CLAUDE.md "No shared memory") |

---

## CRITICAL (0)

(なし)

## HIGH (0)

(なし)

## MEDIUM (0)

(なし)

## LOW (2)

### L1: design-principles.md のセクション名表記不統一
**Location**: framework/claude/sdd/settings/rules/design-principles.md:68
**Description**: `Components & Interfaces` と記載。テンプレート (design.md L117) および design-review.md (L31) は `Components and Interfaces`。機能的影響なし（Inspector は design-review.md を参照）が、フレームワーク内テキストの統一性に影響。
**Evidence**: design.md L117: `## Components and Interfaces`, design-review.md L31: `Has Components and Interfaces section`, design-principles.md L68: `Components & Interfaces`

### L2: install.sh uninstall で空の .sdd/ ディレクトリが残存
**Location**: install.sh:162
**Description**: uninstall 時に `.sdd/settings/` は rmdir されるが、`.sdd/` 自体の rmdir がない。ユーザーファイル (project/, handover/) がない場合に空ディレクトリが残る。
**Evidence**: L162: `rmdir .sdd/settings .claude/sdd/settings .claude/sdd 2>/dev/null || true` — `.sdd` の rmdir が欠落

---

## Claude Code Compliance Status

| Item | Status |
|------|--------|
| agents/ YAML frontmatter (24) | OK — 全フィールド公式仕様準拠 |
| skills/ SKILL.md frontmatter (7) | OK — description, allowed-tools, argument-hint 準拠 |
| settings.json 構造 | OK — 有効キーのみ |
| settings.json permission 記法 | OK — Skill(), Task(), Bash() 準拠 |
| install.sh パス構造 | OK — .claude/ 公式ディレクトリ構造に一致 |
| Model 選択 | OK — T2: opus, T3: sonnet (有効値) |
| Tool permissions | OK — 最小権限の原則 |
| SubAgent background 実行 | OK — 全24 agent に background: true |

---

## Overall Assessment

v1.2.0 の `.claude/sdd/` → `.sdd/` パス移行は完全かつ正確に実施されている。`{{SDD_DIR}}` テンプレート変数による間接参照パターンが一貫して機能しており、フレームワーク全体で旧パスの残存はゼロ。install.sh のマイグレーションチェーン (v0.4.0 → v1.2.0) は正しく連鎖している。

5エージェント全完了（B5 では 1/5 のみ完了）。21件のユニーク指摘から19件を証拠ベースで FP 除去。残り2件は LOW（表記不統一 + uninstall 空ディレクトリ）で、フレームワーク動作には影響なし。

Claude Code 公式仕様準拠は全項目 OK。

---

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|----------|-----|---------|-------------|
| P3 (cosmetic) | L1 | `Components & Interfaces` → `Components and Interfaces` | framework/claude/sdd/settings/rules/design-principles.md |
| P3 (cosmetic) | L2 | uninstall に `rmdir .sdd 2>/dev/null \|\| true` 追加 | install.sh |
