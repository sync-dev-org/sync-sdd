# SDD Framework Self-Review Report — B13

**Date**: 2026-02-27 | **Version**: v1.5.1 | **Agents**: 4 dispatched, 4 completed

---

## False Positives Eliminated (5)

| Finding | Agent | Reason |
|---|---|---|
| `general-purpose` が settings.json に未登録 | Agent 3 (H2) | `general-purpose` は Claude Code 組み込みの SubAgent タイプ。カスタムエージェント用の `Task()` 許可エントリは不要。 |
| Analyst `WRITTEN:{path}` 返却仕様の曖昧さ | Agent 3 (H3) | reboot.md Phase 4: Step 2 で `ANALYST_COMPLETE` 待機（WRITTEN: 含む） → Step 3 でファイル存在確認。フロー完全。 |
| revise.md Part A Step 6(d) → Part B Step 2 フェーズ不適格 | Agent 3 (M7) | Step 6 は「パイプライン完了後（spec は `implementation-complete` に復帰）」に実行される。Part B Step 2 の適格条件を満たす。 |
| sdd-review-self エージェント出力形式の非統一 | Agent 3 (M8) | 意図的設計。各エージェントは異なるレビュースコープを持ち、異なる出力セクション（Cross-Reference Matrix, Compliance Table 等）が適切。 |
| sdd-reboot SKILL.md の refs/reboot.md 参照 | Agent 4 (L2) | ファイルは実在する。Agent 4 もスコープ外と明記。 |

---

## CRITICAL (0)

Agent 3 の CRITICAL 2件は、SubAgent Failure Handling（CLAUDE.md §SubAgent Failure Handling: 「SubAgent が出力ファイルを生成せずに失敗した場合、Lead は retry/skip/derive を判断する」）によりカバーされるため MEDIUM に降格。

---

## HIGH (1)

### H1: Dead-Code Review NO-GO retry_count がセッション再開時にリセットされることが CLAUDE.md に未記載
**Location**: `framework/claude/CLAUDE.md:177`, `framework/claude/skills/sdd-roadmap/refs/run.md:248`
**Agents**: Agent 1 (MEDIUM), Agent 3 (HIGH)
**Description**: run.md Step 7b に「tracked in-memory by Lead — not persisted to spec.yaml, restarts at 0 on session resume」と明記されているが、CLAUDE.md §Auto-Fix Counter Limits には「max 3 retries」としか記載がない。セッション再開後にカウンタがリセットされる挙動が CLAUDE.md に反映されておらず、Lead がリセットを意識せずに制限が実質無効化されるリスク。
**Evidence**: CLAUDE.md line 177 「Dead-Code Review NO-GO: max 3 retries」のみ。in-memory / session resume の記述なし。

---

## MEDIUM (9)

### M1: VERDICT:ERROR の出力仕様が Inspector 間で非均一
**Location**: `framework/claude/agents/sdd-inspector-impl-rulebase.md:156`, `framework/claude/skills/sdd-roadmap/refs/review.md:120`
**Agent**: Agent 3 (CRITICAL → MEDIUM に降格)
**Description**: `VERDICT:ERROR` を定義しているのは `sdd-inspector-impl-rulebase.md` のみ。他の Inspector はエラー時に CPF ファイルを出力せず「terminate」する。review.md はファイル不在時に `PARTIAL:{inspector-name}|file not found` で対処し、SubAgent Failure Handling がリトライ/スキップを担保するため運用は機能する。ただし Inspector のエラー出力仕様の明示性が不足。

### M2: BUILDER_BLOCKED 時の Pilot Stagger / Conventions Supplement フロー未定義
**Location**: `framework/claude/skills/sdd-roadmap/refs/impl.md:63,81`
**Agent**: Agent 3 (HIGH → MEDIUM に降格)
**Description**: Pilot Builder が `BUILDER_BLOCKED` を返した場合、`WRITTEN:{path}` が返らないため ConventionsScanner Supplement モードへの入力が存在しない。汎用 BUILDER_BLOCKED ハンドリング（escalate/re-dispatch）が適用されるため機能は停止しないが、Pilot Stagger セクションに BLOCKED 時のフォールバック（Supplement スキップ → 残りグループを brief のみで dispatch）が未記載。

### M3: Reboot Phase 7 の verdicts.md scope-dir が暗黙的
**Location**: `framework/claude/skills/sdd-reboot/refs/reboot.md:177`
**Agent**: Agent 3 (HIGH → MEDIUM に降格)
**Description**: Phase 7 §Review Decomposition は「Same protocol as refs/run.md」と参照しているが、reboot で新規作成された各 spec の `reviews/` ディレクトリパスが reboot.md 内で明示されていない。標準パターン（`{{SDD_DIR}}/project/specs/{feature}/reviews/`）が暗黙的に継承されるため機能するが、standalone で reboot.md を読む際に不明確。

### M4: Cross-Cutting Mode の conventions-brief 出力パス未指定
**Location**: `framework/claude/skills/sdd-roadmap/refs/revise.md:214`
**Agent**: Agent 3 (HIGH → MEDIUM に降格)
**Description**: revise.md Part B Step 7 「Dispatch sdd-conventions-scanner (mode: Generate) per run.md Step 2.5」と記述。run.md Step 2.5 のパスは wave-context（multi-spec）or feature dir（1-spec）で定義されているが、Cross-Cutting は wave/1-spec のどちらでもない。`.cross-cutting/{id}/conventions-brief.md` が自然だが明示なし。

### M5: Revise Part A Step 6(d) で target spec が Part B で再処理される可能性の曖昧さ
**Location**: `framework/claude/skills/sdd-roadmap/refs/revise.md:91-95`
**Agent**: Agent 1 (MEDIUM)
**Description**: Option (d) で Part B に合流する際、target spec は `implementation-complete` だが Part B Step 7 で全 FULL spec を `design-generated` にリセットする。target spec が FULL に分類されると、既に revised 済みのスペックが再度 Architect にかけられる。「completed target spec + affected dependents pre-populated」の記述は target spec を SKIP/完了済みとする意図だが明示的でない。

### M6: Cross-Cutting Review の scope dir が review.md Execution Flow Step 1 に未記載
**Location**: `framework/claude/skills/sdd-roadmap/refs/review.md:68-73`
**Agent**: Agent 1 (MEDIUM)
**Description**: review.md Step 1 の scope directory リストに cross-cutting パスが含まれていない。Verdict Destination セクション（line 129-131）と revise.md Step 8.2 には記載があるが、Execution Flow の入口から辿れない。

### M7: Revise Mode Detection の `revise [instructions]` 曖昧さ
**Location**: `framework/claude/skills/sdd-roadmap/SKILL.md:34-35`
**Agent**: Agent 1 (MEDIUM)
**Description**: SKILL.md は `revise {feature} [instructions]` → Single-Spec、`revise [instructions]` → Cross-Cutting と定義。refs/revise.md にのみ「first word が existing spec name と一致するか」の判定ロジックが記載。SKILL.md にはモード判定の具体的ロジックが不足しており、Lead が ref を読む前に誤判定するリスク。

### M8: 1-Spec Roadmap の `review dead-code` BLOCK パス不整合
**Location**: `framework/claude/skills/sdd-roadmap/SKILL.md:74,88-91`
**Agent**: Agent 1 (MEDIUM)
**Description**: SKILL.md §Single-Spec Roadmap Ensure Step 3 では roadmap なしで `review dead-code` を BLOCK。一方 §1-Spec Roadmap Optimizations では「Skip wave-level dead-code review; user can still run manually」。2箇所の情報が分散しており、1-spec での dead-code review の可否が一読で分かりにくい。

### M9: reboot.md Phase 8 で NO-GO skip されたスペックの handling
**Location**: `framework/claude/skills/sdd-reboot/refs/reboot.md:201-232`
**Agent**: Agent 3 (MEDIUM)
**Description**: Phase 8 Regression Check で「Phase 7 completed spec design.md files」から capability 抽出する際、NO-GO で最終的に skip されたスペックの design.md は seeded skeleton のまま。このスペックの扱い（抽出対象外とするか）が Phase 8 に明記されていない。

---

## LOW (8)

### L1: SKILL.md review --wave N のポインタなし
**Location**: `framework/claude/skills/sdd-roadmap/SKILL.md:96-106`
**Agent**: Agent 1
**Description**: Execution Reference で「Review → Read refs/review.md」としか示されず、wave モード固有セクションへのポインタがない。

### L2: reboot.md Phase 7 Blocking Protocol の options
**Location**: `framework/claude/skills/sdd-reboot/refs/reboot.md:182`
**Agent**: Agent 1
**Description**: run.md Step 6 参照時、reboot に impl フェーズがないため「fix = Architect re-dispatch のみ」が暗黙的。

### L3: argument-hint に --cross-check / --wave N 未記載
**Location**: `framework/claude/skills/sdd-roadmap/SKILL.md:4`
**Agent**: Agent 1
**Description**: `[flags]` という汎用表現でカバーされているが、具体的フラグが不明。

### L4: CLAUDE.md の run_in_background vs background フィールド記述
**Location**: `framework/claude/CLAUDE.md:32`
**Agent**: Agent 4
**Description**: Task ツールの `run_in_background` パラメータとエージェント frontmatter の `background` フィールドの使い分け記述が紛らわしい。機能的問題なし。

### L5: Auditor 出力形式の `|` と CPF 区切り文字の混同リスク
**Location**: `framework/claude/agents/sdd-auditor-design.md:189`
**Agent**: Agent 3
**Description**: Output Format の `SCOPE:{feature} | cross-check | wave-scoped-cross-check` は選択肢表現だが、CPF の `|` フィールド区切りと視覚的に紛らわしい。

### L6: sdd-status の --impact フラグと cross-cutting スキャンの関係が曖昧
**Location**: `framework/claude/skills/sdd-status/SKILL.md:1-6`
**Agent**: Agent 3
**Description**: cross-cutting スキャンが常時実行されるかフラグ依存かが argument-hint と本文で不統一。

### L7: impl.md COMPLETED WITHOUT TASK SPEC の A/B/C オプション後続動作
**Location**: `framework/claude/skills/sdd-roadmap/refs/impl.md:22-23`
**Agent**: Agent 3
**Description**: A（task-numbers 再実行）と B（re-design cascade）の後続ステップが明示されていない。

### L8: design.md テンプレートの Supporting References と rulebase チェックの不一致
**Location**: `framework/claude/sdd/settings/templates/specs/design.md:298-302`
**Agent**: Agent 3
**Description**: テンプレートに Optional セクションがあるが、Inspector rulebase チェックリストに存在確認が含まれていない。

---

## Platform Compliance

| Item | Status |
|---|---|
| Agent frontmatter (26 agents) | OK (25 cached + 1 full check) |
| Skill frontmatter (7 skills) | OK (6 cached + 1 full check) |
| sdd-analyst.md (new) | OK (full check) |
| sdd-reboot/SKILL.md (new) | OK (full check) |
| settings.json Skill() entries (7) | OK |
| settings.json Task() entries (26) | OK |
| settings.json Bash() entries | OK (cached) |
| Task subagent_type parameter | OK |
| background policy consistency | OK |
| SubAgent non-nesting constraint | OK |

---

## Overall Assessment

v1.5.1 のフレームワーク全体整合性は **良好**。v1.5.0/v1.5.1 で追加された sdd-reboot スキルと sdd-analyst エージェントはプラットフォーム仕様に完全準拠し、既存フローとの統合にも重大な矛盾なし。

主なリスク領域:
1. **Dead-Code Review カウンタのセッション非永続化** (H1): CLAUDE.md への注記追加で対処可能
2. **Inspector エラー出力の非均一性** (M1): 運用上は SubAgent Failure Handling でカバーされるが、明示性向上が望ましい
3. **Pilot Stagger の BLOCKED 時フォールバック** (M2): エッジケースだが実装フローで遭遇し得る

5件の false positive を正しく排除。B12 からの新規指摘は主に reboot/revise のエッジケースとドキュメント明確性に集中している。

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 | H1 | Dead-Code Review retry_count の in-memory 挙動を CLAUDE.md に注記 | CLAUDE.md |
| 2 | M1 | 全 Inspector に VERDICT:ERROR 出力仕様を追加、または review.md に「ファイル不在 = Inspector 失敗」を明確化 | review.md or sdd-inspector-*.md |
| 3 | M2 | Pilot Stagger に BUILDER_BLOCKED 時フォールバック記述追加 | refs/impl.md |
| 4 | M5 | revise.md Part A Step 6(d) に target spec の Part B での扱いを注記 | refs/revise.md |
| 5 | M3-M4 | reboot.md verdicts.md パス明示、Cross-Cutting conventions-brief パス明示 | refs/reboot.md, refs/revise.md |
| 6 | M6-M8 | review.md cross-cutting scope dir、Revise Mode Detection ロジック、1-spec dead-code パス統合 | refs/review.md, SKILL.md |
| 7 | M9 | reboot.md Phase 8 skip 済みスペック扱い明記 | refs/reboot.md |
| 8 | L1-L8 | ドキュメント明確性改善（LOW backlog） | 各ファイル |
