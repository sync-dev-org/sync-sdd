## Flow Integrity Report

### Issues Found

---

#### [HIGH] Reboot Phase 7 の設計レビューで wave 完了判定が実装フェーズなしの場合に不完全

**Location**: `framework/claude/skills/sdd-reboot/refs/reboot.md` Phase 7 EXIT 条件
**Description**:
Phase 7 (Design Pipeline) の Dispatch Loop EXIT 条件は次のとおり:
```
5. EXIT: If all specs in wave have design-generated + GO/CONDITIONAL verdict
   and active is empty → next wave (or Phase 8)
```
この条件は `run.md` の EXIT 条件と若干異なる。`run.md` では:
```
5. EXIT: If no spec has a dispatchable next phase (per Readiness Rules) and active is empty → Wave QG (Step 7)
```
reboot.md では「すべてのスペックが design-generated + GO/CONDITIONAL」を必要とするが、NO-GO → Blocking Protocol → skip された spec は `design-generated` にならない可能性がある。blocked spec の場合の EXIT 条件が未定義。`run.md` のブロッキングプロトコル参照が明示されているが (`refs/run.md` Step 6)、skip されたスペックを wave EXIT 条件から除外する記述が不完全。

**Evidence**: reboot.md Phase 7 §Verdict Handling:
> "Skip → exclude spec from wave EXIT condition; remaining specs must still meet completion condition."

ただし、EXIT 条件の本文には「if all specs in wave have...」とあり、スキップされたスペックの扱いが本文と補足で矛盾する可能性がある。軽微だが、"all specs" と "remaining specs" の齟齬がある。

---

#### [HIGH] Phase 5 の `-y` フラグ時の分析レポート読み込みが省略される

**Location**: `framework/claude/skills/sdd-reboot/refs/reboot.md` Phase 5
**Description**:
Phase 5 は `-y` フラグ存在時にスキップされる。しかし Phase 6 (Roadmap Regeneration) の 6c で「Read the analysis report to extract proposed spec decomposition」とあり、Phase 5 をスキップしても Lead は分析レポートを読む必要がある。`-y` の場合はユーザーレビューをスキップするだけで、Lead によるレポート読み込みは依然として Phase 6 で実施される。これ自体は問題ないが、Phase 5 の説明に「Skip if `-y` flag is present」とだけ書かれており、Lead が Phase 6 でレポートを読むべきであることが明示されていない。Lead が `-y` 時に Phase 5 全体をスキップしてレポートを読まないリスクがある。

---

#### [MEDIUM] Revise Mode Cross-Cutting のコミット前にユーザー確認ゲートがない

**Location**: `framework/claude/skills/sdd-roadmap/refs/revise.md` Part B Step 9
**Description**:
Cross-Cutting Mode の Step 9 (Post-Completion) には次の記述がある:
```
3. Commit: `cross-cutting: {summary}`
```
この commit は自動実行される。ユーザー確認なしで commit が実行される。一方、reboot.md の Phase 10 では commit 前に Phase 9 の Accept が必要で、merge は行わない。revise (Cross-Cutting) はより大規模な変更にもかかわらず、wave 完了コミット (`run.md` Step 7c post-gate) と同様に自動コミットする設計になっている。これ自体は CLAUDE.md の「Wave completion: Lead commits directly」ポリシーと一致するが、cross-cutting 変更は特に影響範囲が大きいため、コミット前にユーザー確認を求めるべきか否かが曖昧。

---

#### [MEDIUM] Dead-Code Review の NO-GO リトライカウントがセッション再開後にリセットされる

**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md` Step 7b
**Description**:
Dead-Code Review の NO-GO リトライカウントについて:
```
max 3 retries (tracked in-memory by Lead — not persisted to spec.yaml, restarts at 0 on session resume; separate from per-spec aggregate cap → escalate)
```
このカウントはインメモリのみで spec.yaml に永続化されない。セッション再開後にカウントがリセットされるため、理論上は無限にリトライできる。CLAUDE.md にもこの挙動が明示されている:
> "Dead-Code Review NO-GO: max 3 retries (dead-code findings are simpler scope; exhaustion → escalate)."

ただし CLAUDE.md では「exhaustion → escalate」としているが、run.md では「not persisted to spec.yaml, restarts at 0 on session resume」と記しており、永続化しないことを意図的に文書化している。矛盾はないが、セッション再開後の挙動がユーザーに不透明。

---

#### [MEDIUM] Review Decomposition と run.md の web server 停止タイミング

**Location**: `framework/claude/skills/sdd-roadmap/refs/review.md` および `refs/run.md`
**Description**:
`review.md` の Web Inspector Server Protocol では:
```
3. Server Stop (after all Inspectors complete, before Auditor dispatch):
   - Kill the background dev server process
```
`run.md` の §Review Decomposition では:
```
2. INSPECTORS-COMPLETE:
   - Execute review.md steps 5, 5a (handle failures, stop web server if applicable)
   - Spawn Auditor
```
これは一致している。しかし、`run.md` の Review Decomposition コンテキスト注記 (`review.md` Web Inspector Server Protocol 末尾) の:
> "Within `run.md` dispatch loop, this flow is decomposed into dispatch-loop events (see run.md §Review Decomposition). The sequential flow below applies to standalone review invocations."

という注記が `review.md` の Review Execution Flow セクションではなく、Web Inspector Server Protocol の末尾に配置されている。これは曖昧で、読者が「Sequential flow (review.md)」が dispatch loop にも適用されると誤解する可能性がある。ただし実質的な動作の矛盾はない。

---

#### [MEDIUM] SKILL.md の Revise Mode 判定でスペック名未存在の場合の処理未定義

**Location**: `framework/claude/skills/sdd-roadmap/SKILL.md` Step 1 Detect Mode
**Description**:
```
$ARGUMENTS = "revise {feature} [instructions]" → Revise Mode (Single-Spec)
$ARGUMENTS = "revise [instructions]"            → Revise Mode (Cross-Cutting)
```
SKILL.md では `revise.md` に:
```
"revise <feature> [instructions]" → feature matches known spec name → Single-Spec Mode (Part A)
"revise [instructions]"            → no feature name match          → Cross-Cutting Mode (Part B)
```
SKILL.md の Detect Mode では「feature が既知のスペック名に一致するか」というチェックが明示されていない。SKILL.md は引数の形式だけで判定しているが、revise.md は「既知のスペック名への照合」を判定基準としている。

例えば `revise "change authentication logic"` の場合、SKILL.md は最初の単語 `change` をスペック名として評価するのか、それとも文全体を instruction として評価するのかが不明確。SKILL.md の dispatch route と revise.md の Mode Detection が統一されていない。

**Recommendation**: SKILL.md の `revise` 行に「first word checked against known spec names」という説明を追加する。

---

#### [MEDIUM] Phase Gate の `spec.yaml.roadmap` が null の場合の impl/review ルーティング

**Location**: `framework/claude/skills/sdd-roadmap/SKILL.md` §Single-Spec Roadmap Ensure
**Description**:
```
If spec exists but spec.yaml.roadmap is null → BLOCK: "{feature} exists but is not enrolled..."
```
この BLOCK は `impl` と `review` の場合に発生するが、`review dead-code` と `review --cross-check` / `review --wave N` については enrollment check をスキップする:
```
Exception: review dead-code and review --cross-check / review --wave N → skip enrollment check
```
ただし、Roadmap が存在しない場合の `review dead-code` については:
```
If no roadmap:
  - If review dead-code, review --cross-check, or review --wave N → BLOCK: "No roadmap found."
```
「roadmap なし → BLOCK」だが「roadmap あり、spec が未登録 → enrollment check skip」という非対称な扱いがある。これは意図的な設計だが、`review dead-code` がロードマップなしで動作しない一方でスペック未登録では動作する理由が文書化されていない。

---

#### [LOW] Builder のグループ ID 命名規則が refs と agent 定義で不統一

**Location**: `framework/claude/agents/sdd-builder.md` vs `refs/impl.md`
**Description**:
`refs/impl.md` では Builder dispatch に「Group ID: {group identifier from execution plan}」とあり、例として「wave1-a」「wave2-b」を示す。`sdd-builder.md` の Input 節では「Group ID: your assigned Builder group (e.g., "wave1-a", "wave2-b")」と同一の例を使っている。ただし、`builder-report-{group}.md` のファイル名規則については refs/impl.md は `WRITTEN:{report_path}` のみを参照し、builder.md が実際のファイル名を定義している。minor なずれだが、Group ID の実際の生成規則は TaskGenerator が決定するため、暗黙的な依存がある。

---

#### [LOW] Reboot Phase 6d での product.md 更新の重複可能性

**Location**: `framework/claude/skills/sdd-reboot/refs/reboot.md` Phase 6d
**Description**:
```
2. Update {{SDD_DIR}}/project/steering/product.md Spec Rationale section
   (Analyst may have already updated this — verify and supplement if needed)
```
Analyst は Phase 4 で steering を直接書き込む（`sdd-analyst.md` Step 4: "Write steering files directly to..."）。Phase 6d では Lead が再度 product.md を確認・補完する。Analyst による更新と Lead による更新の責任境界が曖昧で、重複書き込みや競合のリスクがある。「verify and supplement if needed」という表現で対処しているが、具体的な重複回避手順がない。

---

### Confirmed OK

- **Router dispatch completeness**: 全 subcommand (design, impl, review design, review impl, review dead-code, run, revise, create, update, delete, -y) が SKILL.md Step 1 に正しくマッピングされ、対応する refs ファイルへの読み込みが明示されている (SKILL.md §Execution Reference)
- **Phase gate consistency**: CLAUDE.md のフェーズ定義 (initialized → design-generated → implementation-complete, blocked) が design.md, impl.md, review.md, run.md で一貫して参照されている
- **Auto-fix loop (NO-GO/SPEC-UPDATE-NEEDED)**: retry_count max 5, spec_update_count max 2, aggregate cap 6 が CLAUDE.md と run.md で一致している。CONDITIONAL = GO (proceed) の扱いも一致。
- **Wave Quality Gate**: run.md Step 7 の Impl Cross-Check → Dead-Code → Post-gate (commit, session.md) フローが完全に記述されている
- **1-spec roadmap optimizations**: Wave QG スキップ、cross-spec file ownership analysis スキップが SKILL.md と run.md で一致して定義されている
- **Verdict persistence format**: SKILL.md §Verdict Persistence Format が review.md Step 8 で参照されており、format が一致している
- **Consensus mode**: SKILL.md §Consensus Mode と review.md の処理が矛盾なく定義されている。N=1 のデフォルトケースも明示されている
- **Blocked spec handling**: run.md Step 6 Blocking Protocol と CLAUDE.md Phase Gate が一致している
- **Design Lookahead staleness guard**: run.md に lookahead 設計変更時の無効化処理が記述されている
- **Pilot Stagger Protocol**: impl.md と run.md §Wave Context の参照が整合している
- **SubAgent background dispatch**: CLAUDE.md 「run_in_background: true always. No exceptions」が sdd-roadmap, sdd-reboot SKILL.md で遵守されている
- **Analyst output contract**: sdd-analyst.md の completion report 形式 (ANALYST_COMPLETE + WRITTEN:{path}) が reboot.md Phase 4 の待受条件と一致している
- **ConventionsScanner output contract**: WRITTEN:{path} のみを返す規則が agent 定義と refs (run.md, reboot.md) で一致
- **Reboot Phase 9 user gate (AskUserQuestion)**: Phase 9 が AskUserQuestion を使用し、Accept/Iterate/Reject の 3 択を提示している
- **Reboot Phase 10 deletion confirmation (AskUserQuestion)**: Phase 10 が AskUserQuestion を使用し、Delete/Skip/Cancel の 3 択を提示している
- **Reboot no auto-merge**: SKILL.md の Core Task「Never auto-merges」および reboot.md Phase 10 Step 5「DO NOT merge to main. DO NOT checkout main.」が明示されており、自動マージのリスクなし
- **Reboot commit only on Accept**: reboot.md Phase 10「Only reached if user chose Accept in Phase 9」が明確に記述されている
- **Cross-Cutting revise escalation path**: Single-Spec の Step 3 から Cross-Cutting への昇格手順が revise.md に明示されており、SKILL.md の Detect Mode と整合している
- **decisions.md recording triggers**: CLAUDE.md の記録トリガーが各 refs で適切に参照されている (REVISION_INITIATED, USER_DECISION, DIRECTION_CHANGE, STEERING_UPDATE)
- **Steering Feedback Loop**: review.md に CODIFY/PROPOSE の処理フローが定義されており、CLAUDE.md の記述と一致している
- **session.md auto-draft policy (run mode)**: run.md 「Auto-draft only at: Wave QG post-gate, user escalation, pipeline completion」が CLAUDE.md と一致している
- **settings.json permissions**: Task() エントリが framework/claude/agents/ の全エージェント (26 個) をカバーしており、Skill() エントリが framework/claude/skills/sdd-*/ の全スキル (7 個) をカバーしている
- **Builder spec.yaml/tasks.yaml 更新禁止**: sdd-builder.md で「Do NOT update spec.yaml or tasks.yaml」が明示されており、CLAUDE.md の Artifact Ownership と一致
- **Architect spec.yaml 更新禁止**: sdd-architect.md で「Do NOT update spec.yaml」が明示されている
- **CPF format consistency**: Auditor 3 種 (design, impl, dead-code) の出力形式が cpf-format.md の規則に準拠している
- **Verdict destination consistency**: review.md §Verdict Destination by Review Type が各スコープで正確にパスを定義している
- **reboot.md Phase 1 pre-flight**: dirty tree, main branch, existing branch, codebase check の全チェックが定義されており、いずれもユーザー操作なしに自動処理または BLOCK する

---

### Overall Assessment

フレームワーク全体のフローは堅牢に設計されており、主要な安全装置 (user approval gate, AskUserQuestion, auto-merge 禁止) は正しく配置されている。特に reboot フローは Phase 9・10 の両方にユーザー承認ゲートがあり、Phase 10 のコミットは Accept 選択後のみ到達可能であることが明確に保証されている。

重要な指摘事項:

1. **HIGH**: reboot Phase 5 `-y` フラグ時にレポート読み込みが省略されるリスク (Lead 実行時の解釈次第)
2. **HIGH**: reboot Phase 7 の EXIT 条件でスキップ spec の扱いが本文と補足で微妙に矛盾
3. **MEDIUM**: SKILL.md と revise.md の Mode Detection 判定基準の不統一 (スペック名照合ロジックが SKILL.md に記述なし)
4. **MEDIUM**: dead-code レビューリトライカウントのインメモリのみ永続化によるセッション再開後リセット (設計上意図的だが不透明)

これらはいずれも critical な動作不正を引き起こすものではなく、Lead の解釈や特定のエッジケースで問題が顕在化する可能性のある曖昧さである。
