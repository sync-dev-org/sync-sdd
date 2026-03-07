# SDD Framework Consistency & Dead Ends Review Report

**Date**: 2026-02-24
**Reviewer**: Agent 3 (Consistency & Dead Ends)
**Scope**: Full framework review

---

## Issues Found

### [HIGH] H1: Web Inspector Server Protocol — dev server コマンドが tech.md に存在しない場合のエラーハンドリングが未定義

**Location**: `framework/claude/skills/sdd-roadmap/refs/review.md:51`
**Description**: review.md Web Inspector Server Protocol Step 1:
> Read dev server command from `steering/tech.md` Common Commands

tech.md テンプレート (`framework/claude/sdd/settings/templates/steering/tech.md`) に dev server コマンドのデフォルト記載はない。ユーザーが tech.md に dev server コマンドを記載していない場合の Lead の振る舞いが未定義。

review.md line 62 では「server fails to start」のフォールバックがある:
> If server fails to start: dispatch web inspectors anyway (they will report the error in their CPF output and terminate gracefully).

ただし「server fails to start」はコマンドが存在した上で起動に失敗した場合のハンドリング。**dev server コマンド自体が tech.md に見つからない場合**は別のエラーパスであり、この場合の振る舞いが明記されていない。

**Impact**: Web project の impl review でサーバー起動ができず、E2E/Visual Inspector が意味のある結果を返せない可能性。
**Recommended Fix**: review.md に「dev server command not found in tech.md」のケースを追加。例: コマンド不明 → ユーザーに確認、またはサーバーなしで dispatch（現在の fail-to-start フォールバックと同じ扱い）。

### [MEDIUM] M1: Auditor failure のエラーハンドリングが明示されていない

**Location**: `framework/claude/skills/sdd-roadmap/refs/review.md`
**Description**: Review Execution Flow (Step 5-7) では:
- Inspector failure: VERDICT:ERROR として定義 (line 117)、Lead が retry/skip/proceed を判断
- Auditor: Step 7 で `verdict.cpf` の読み取りを前提としている

CLAUDE.md の SubAgent Failure Handling (line 107) は汎用ルールとして「Lead uses its own judgment to retry, skip, or derive results from available files」と記載しているが、Auditor が verdict.cpf を生成しなかった場合の具体的なハンドリングが review.md に明示されていない。

Inspector failure とは異なり、Auditor failure は verdict 自体が存在しないため、review pipeline が完了できない。Inspector は N 人中一部が欠けても Auditor が残りから verdict を出せるが、Auditor 自体が失敗すると verdict がない。

**Impact**: Auditor failure 時に Lead がどうすべきか（再dispatch? 全 Inspector の CPF を直接読んで Lead が verdict を出す? ユーザーエスカレーション?）が不明確。
**Recommended Fix**: review.md に Auditor failure のケースを追加。例: 「Auditor failure → retry once. If retry fails → Lead reads Inspector CPFs directly and makes a simplified verdict (GO if no C/H issues, CONDITIONAL otherwise), or escalates to user.」

### [LOW] L1: CLAUDE.md Commands (6) と実際の skill ファイル数 (7) の不一致

**Location**: `framework/claude/CLAUDE.md:141`
**Description**: CLAUDE.md の `### Commands (6)` テーブルには 6 コマンドが記載されているが、実際の skill ファイルは 7 (sdd-review-self を含む)。sdd-review-self はフレームワーク内部用 (`framework-internal use only`) であり、ユーザー向けコマンドではないため意図的な除外。

ただし、sdd-review-self は `.claude/skills/` にインストールされるため、ユーザーが `/sdd-review-self` を実行すること自体は可能。コマンドテーブルに注釈として「Note: sdd-review-self is available for framework development only」を追記することで混乱を防げる。

**Impact**: ユーザーが skill ファイルを直接数えた場合に混乱する可能性（軽微）。

### [LOW] L2: revise.md の phase 設定の冗長性

**Location**: `framework/claude/skills/sdd-roadmap/refs/revise.md:39,48`
**Description**: revise.md Step 4 で `phase = design-generated` に設定した後、Step 5 の Design サブステップ完了後に再度 `spec.yaml (phase=design-generated, last_phase_action=null)` と設定。

Step 4 の設定は `implementation-complete` → `design-generated` への遷移（Architect dispatch の前提条件）。Step 5 の設定は design.md ref の標準手順に従った確認更新。二重設定は冗長だが矛盾ではない。

**Impact**: 実行上の問題なし。ドキュメントの明確性のみ。

---

## Confirmed OK

### 1. Phase名の統一性

| Phase | CLAUDE.md | init.yaml | design.md ref | impl.md ref | run.md ref | revise.md ref |
|-------|-----------|-----------|---------------|-------------|------------|---------------|
| `initialized` | line 153 | line 10 | line 11 | - | line 85 | - |
| `design-generated` | line 153 | - | line 35 | line 13 | line 86,87 | line 39 |
| `implementation-complete` | line 153 | - | line 18 | line 61 | line 76 | line 8 |
| `blocked` | line 153 | - | line 17 | line 10 | line 76,152-153 | line 10 |

**Result**: 全て一致。

### 2. SubAgent名の統一性 (24 agents)

| Agent Name | agents/ file | review.md dispatch | Auditor expected CPF |
|---|---|---|---|
| sdd-architect | OK | design.md:24 | N/A |
| sdd-taskgenerator | OK | impl.md:26 | N/A |
| sdd-builder | OK | impl.md:39 | N/A |
| sdd-inspector-rulebase | OK | review.md:25 | auditor-design:42 |
| sdd-inspector-testability | OK | review.md:25 | auditor-design:43 |
| sdd-inspector-architecture | OK | review.md:25 | auditor-design:44 |
| sdd-inspector-consistency | OK | review.md:25 | auditor-design:45 |
| sdd-inspector-best-practices | OK | review.md:25 | auditor-design:46 |
| sdd-inspector-holistic | OK | review.md:25 | auditor-design:47 |
| sdd-inspector-impl-rulebase | OK | review.md:33 | auditor-impl:44 |
| sdd-inspector-interface | OK | review.md:33 | auditor-impl:45 |
| sdd-inspector-test | OK | review.md:33 | auditor-impl:46 |
| sdd-inspector-quality | OK | review.md:33 | auditor-impl:47 |
| sdd-inspector-impl-consistency | OK | review.md:33 | auditor-impl:48 |
| sdd-inspector-impl-holistic | OK | review.md:33 | auditor-impl:49 |
| sdd-inspector-e2e | OK | review.md:34 | auditor-impl:50 |
| sdd-inspector-visual | OK | review.md:34 | auditor-impl:51 |
| sdd-inspector-dead-settings | OK | review.md:44 | auditor-dead-code:37 |
| sdd-inspector-dead-code | OK | review.md:44 | auditor-dead-code:38 |
| sdd-inspector-dead-specs | OK | review.md:44 | auditor-dead-code:39 |
| sdd-inspector-dead-tests | OK | review.md:44 | auditor-dead-code:40 |
| sdd-auditor-design | OK | review.md:26 | N/A |
| sdd-auditor-impl | OK | review.md:35 | N/A |
| sdd-auditor-dead-code | OK | review.md:45 | N/A |

**Result**: 24 agents、全ファイルで統一。

### 3. Verdict値の統一性

| Verdict | Design Auditor | Impl Auditor | Dead-Code Auditor | CLAUDE.md | run.md |
|---|---|---|---|---|---|
| GO | OK | OK | OK | line 23 | line 112,127 |
| CONDITIONAL | OK | OK | OK | line 23 | line 112,127 |
| NO-GO | OK | OK | OK | line 23 | line 113,128 |
| SPEC-UPDATE-NEEDED | - | OK | - | line 23 | line 129 |

**Result**: 全て一致。SPEC-UPDATE-NEEDED は Impl Auditor のみ（設計意図通り）。

### 4. Severity Code の統一性 (C/H/M/L)

全 Inspector、全 Auditor、cpf-format.md で統一。design-review.md の 2-level → 4-level マッピングも明示。

### 5. Retry Limit の統一性

| Parameter | CLAUDE.md | run.md |
|---|---|---|
| retry_count max | 5 | 5 |
| spec_update_count max | 2 | 2 |
| Aggregate cap | 6 | 6 |
| Dead-Code retry max | 3 | 3 |

**Result**: 全て一致。

### 6. Inspector数の統一性

| Review Type | CLAUDE.md | review.md | Auditor | README.md |
|---|---|---|---|---|
| Design | 6 | 6 | 6 | - |
| Impl (non-web) | 6 | 6 | up to 8 | 6+2 |
| Impl (web) | +2 web | +e2e +visual | items 7,8 | +2 |
| Dead-code | 4 | 4 | 4 | - |

**Result**: 全て一致。

### 7. Agent総数

| Source | Count |
|---|---|
| Actual agents/ files | 24 |
| README.md | 24 (3 places) |

**Result**: 一致。

### 8. ファイルパス参照

全 `{{SDD_DIR}}` 展開が一貫 (`.claude/sdd`)。Templates, rules, profiles パスが CLAUDE.md Paths、各 agent/skill、install.sh で統一。

### 9. Template/Rule 参照の完全性

全 20 の参照先ファイルが実際に存在。参照孤立なし。

### 10. install.sh の整合性

- Skills/agents/rules/templates/profiles のインストールパスが全て正確
- CLAUDE.md マーカー管理 (`<!-- sdd:start -->` / `<!-- sdd:end -->`) 正常
- Migration chain (v0.4.0→v0.7.0→v0.9.0→v0.10.0→v0.15.0→v0.18.0→v0.20.0) 順序正しい
- Stale file 削除が sdd-* パターンでスコープ限定

### 11. Phase Transition の完全性

```
initialized → design-generated (via /sdd-roadmap design)
design-generated → implementation-complete (via /sdd-roadmap impl)
implementation-complete → design-generated (via /sdd-roadmap revise)
any → blocked (via Blocking Protocol)
blocked → original phase (via unblock in run.md Step 6)
```

Dead end なし。全 phase から適切な遷移パスが存在。

### 12. Circular Reference 分析

ファイル間の参照関係は DAG（有向非循環グラフ）を形成。循環参照なし。

---

## Cross-Reference Matrix (Summary)

| Dimension | Files Checked | Result |
|---|---|---|
| Phase names | CLAUDE.md, init.yaml, design/impl/run/revise refs | Consistent |
| SubAgent names | 24 agent files, review.md, 3 Auditors | Consistent |
| Verdict values | 3 Auditors, CLAUDE.md, review.md, run.md | Consistent |
| Severity codes | cpf-format.md, all Inspectors, all Auditors, design-review.md | Consistent |
| Retry limits | CLAUDE.md, run.md | Consistent |
| Inspector counts | CLAUDE.md, review.md, 3 Auditors, README.md | Consistent |
| Agent total count | agent files (24), README.md (24) | Consistent |
| File paths | CLAUDE.md Paths, all agents/skills, install.sh | Consistent |
| Template/rule refs | 20 referenced files, all exist | Complete |
| install.sh paths | 7 install targets | Correct |
| Phase transitions | design/impl/run/revise refs, Blocking Protocol | Complete |
| Circular references | All inter-file references | None (DAG) |

---

## Overall Assessment

### 整合性評価: **GOOD**

フレームワーク全体の整合性は非常に高い。最近の変更（E2E Inspector → functional testing 専用化、Visual Inspector 新規追加、Inspector数 "+1 E2E" → "+2 web"、SubAgent数 23→24）は全ファイルで正しく反映されている。

12 の一貫性次元すべてで整合性が確認された。発見された問題は 4 件のみ（HIGH 1, MEDIUM 1, LOW 2）で、いずれも運用を阻害する致命的な問題ではない。

### Recommended Fix Priority

| Priority | ID | Severity | Summary | Target Files |
|---|---|---|---|---|
| 1 | H1 | HIGH | review.md に dev server コマンド不明時のフォールバックを追加 | `refs/review.md` |
| 2 | M1 | MEDIUM | review.md に Auditor failure のエラーハンドリングを追加 | `refs/review.md` |
| 3 | L1 | LOW | CLAUDE.md Commands テーブルに sdd-review-self 注釈（任意） | `CLAUDE.md` |
| 4 | L2 | LOW | revise.md の冗長な phase 設定にコメント（任意） | `refs/revise.md` |
