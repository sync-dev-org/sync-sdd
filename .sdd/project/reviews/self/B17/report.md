# SDD Framework Self-Review Report B17
**Date**: 2026-03-01 | **Agents**: 4 dispatched, 4 completed | **Version**: v1.8.0+reboot-improvements

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| C1: installed CLAUDE.md が Task 使用 | Agent 3 | `.claude/` はインストール先コピー。framework ソースが正 (Agent 使用)。install.sh 再実行で同期 |
| H3: sdd-review-self の general-purpose subagent_type | Agent 3 | 設計判断。general-purpose は Claude Code 組み込み agent type。D2 (sdd-review-self は framework-internal) |
| L2: 同上 | Agent 1 | 同上 |
| H5: Consensus B{seq} 重複記述 | Agent 3 | SKILL.md が計算し review.md が受け取る形式。動作は正しい |

## CRITICAL (2)

### C1: sdd-reboot/SKILL.md Phase 3 が refs/reboot.md と矛盾
**Location**: `framework/claude/skills/sdd-reboot/SKILL.md:35`
**Description**: SKILL.md は「Conventions Brief: Dispatch ConventionsScanner」と記載しているが、refs/reboot.md Phase 3 は「ConventionsScanner is NOT dispatched during reboot」と明示的に禁止。Lead が SKILL.md を読んだ場合、ConventionsScanner を誤って実行する。
**Evidence**: Agent 2, Agent 3 が共に検出
**Source**: 当セッションの変更（ConventionsScanner スキップ）

### C2: analysis-report.md テンプレートが Analyst 定義と構造的に矛盾
**Location**: `framework/claude/sdd/settings/templates/reboot/analysis-report.md`
**Description**: テンプレートには「Strengths/Weaknesses/Current Architecture Assessment/Ideal Architecture」セクションがあるが、Analyst は「No preservation bias: Do NOT assess 'strengths'」と禁止し、Step 7 で「Requirements (abstract)/Architecture Alternatives」を要求。テンプレートが Analyst の制約と直接矛盾。
**Evidence**: Agent 2, Agent 3 が共に検出
**Source**: 当セッションの変更（Analyst 要件抽出厳格化）

## HIGH (2)

### H1: reboot.md Phase 5 の selected_alternative パラメータが Analyst に未定義
**Location**: `framework/claude/skills/sdd-reboot/refs/reboot.md:68`
**Description**: 非推奨アーキテクチャ案選択時に `selected_alternative={name}` を Analyst に渡す指示があるが、sdd-analyst.md の Input セクションにこのパラメータの定義がない。Analyst が受け取り方・処理方法を知らないため、非推奨案選択フローが機能しない。
**Evidence**: Agent 2
**Source**: 当セッションの変更（代替案選択フロー追加）

### H2: SKILL.md allowed-tools に Task が残存
**Location**: `framework/claude/skills/sdd-roadmap/SKILL.md:3`, `sdd-reboot/SKILL.md:3`, `sdd-review-self/SKILL.md:3`
**Description**: v1.7.0 で CLAUDE.md/settings.json は Agent に移行済みだが、3 スキルの frontmatter allowed-tools が `Task` のまま。後方互換エイリアスで動作するが不一致。
**Evidence**: Agent 1, Agent 4

## MEDIUM (2)

### M1: CLAUDE.md tmux Integration 参照にスキル修飾子が欠落
**Location**: `framework/claude/CLAUDE.md:315`
**Description**: "See `refs/review.md`" と記載。他の参照は "see sdd-roadmap `refs/review.md`" と修飾子付き。
**Evidence**: Agent 2

### M2: _index.md に Data Modeling セクション未定義
**Location**: `framework/claude/sdd/settings/profiles/_index.md`
**Description**: python.md に `### Data Modeling` 追加したが、プロファイルフォーマット定義の _index.md に未記載。他言語プロファイルとのフォーマット不統一。
**Evidence**: Agent 2

## LOW (1)

### L1: Session Resume 5a の tmux cleanup コマンド例が不完全
**Location**: `framework/claude/CLAUDE.md:280`
**Description**: 孤児 pane の kill 方法が "Kill any found" のみで、pane_id 取得→kill の具体的コマンドが未記載。review.md の pane_id キャプチャ方式と対照的。
**Evidence**: Agent 2

## Pre-existing (carry forward from B15/B16)

| ID | Severity | Summary | Source |
|---|---|---|---|
| H4 | HIGH | Dead Code Inspector SCOPE 値の内部矛盾 (dead-code vs cross-check) | B15 |
| H5 | HIGH | Dead Code verdict 保存先の文脈依存性が不明確 | B16 |
| H7 | HIGH | Revise counter reset timing の記述曖昧さ | B14 |
| M3-M9 | MEDIUM | 各種 pre-existing (SCOPE形式, init.yaml, buffer.md形式等) | B8-B16 |
| L3-L6 | LOW | 各種 pre-existing | B10-B16 |

## Platform Compliance

| Item | Status |
|---|---|
| Agent YAML frontmatter (26 agents) | PASS |
| Skills YAML frontmatter (7 skills) | PASS (allowed-tools `Task` 残存 → H2) |
| settings.json permissions | PASS (Agent() 形式に移行済み) |
| SubAgent nesting constraint | PASS (cached) |
| Tool availability | PASS (cached) |

## Overall Assessment

当セッションの 3 つの変更（Analyst 多案提示、ConventionsScanner スキップ、tmux dev server）に起因する問題が 7 件検出された。最も重要なのは **SKILL.md の同期漏れ** (C1) と **テンプレート未更新** (C2)。いずれも Analyst が誤った指示を受ける可能性がある。`selected_alternative` パラメータの未定義 (H1) も非推奨案選択フローの欠落を意味する。

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 | C1 | SKILL.md Phase 3 → ConventionsScanner 削除 | sdd-reboot/SKILL.md |
| 2 | C2 | analysis-report.md テンプレート更新 | templates/reboot/analysis-report.md |
| 3 | H1 | selected_alternative を Analyst Input に追加 | sdd-analyst.md, reboot.md |
| 4 | H2 | SKILL.md allowed-tools Task → Agent | 3 SKILL.md files |
| 5 | M1 | tmux 参照にスキル修飾子追加 | CLAUDE.md |
| 6 | M2 | _index.md に Data Modeling 追加 | profiles/_index.md |
| 7 | L1 | Session Resume 5a コマンド例追加 | CLAUDE.md |
