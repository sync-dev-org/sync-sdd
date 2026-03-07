# Consistency & Dead Ends Report

**Agent**: Agent 3 — Consistency & Dead Ends
**Date**: 2026-03-01
**Scope**: framework/claude/CLAUDE.md, skills/sdd-*/SKILL.md, skills/sdd-*/refs/*.md, agents/sdd-*.md, settings.json, sdd/settings/rules/*.md, sdd/settings/templates/**/*.md, install.sh

---

## Issues Found

### [CRITICAL]

**C1: Analyst の出力パスの不一致**
`CLAUDE.md` (L41): Analyst は `{{SDD_DIR}}/project/reboot/analysis-report.md` に書き込むと記述。
`reboot.md` Phase 4 (L57): 同じパス `{{SDD_DIR}}/project/reboot/analysis-report.md` を指定。
`sdd-analyst.md` 完了レポート (L179): `WRITTEN:{report_path}` と返す。
**→ 一致しているが**、`CLAUDE.md` の Analyst 節で `{{SDD_DIR}}/project/reboot/analysis-report.md` と書かれている一方、`reboot.md` Phase 3 (L43-45) は Conventions Brief の出力先として `{{SDD_DIR}}/project/reboot/conventions-brief.md` を使う。この部分は整合。ただし `CLAUDE.md` の Analyst 完了レポート説明 (`ANALYST_COMPLETE` + counts + `Files to delete: {count}` + `WRITTEN:{path}`) と `sdd-analyst.md` 完了レポートフォーマット (L172-180) は完全一致 — **問題なし**。

**C2: `init.yaml` テンプレート参照 — ファイル存在確認済みだが SKILL.md 内に記述矛盾**
`sdd-roadmap/SKILL.md` (L76): `{{SDD_DIR}}/settings/templates/specs/init.yaml` を参照。
ファイル: `framework/claude/sdd/settings/templates/specs/init.yaml` が存在する。
**→ 問題なし**。

**C3: `verdicts.md` パス — self-review スコープディレクトリの不一致**
`review.md` (L131): `{{SDD_DIR}}/project/reviews/self/verdicts.md` とある。
`sdd-review-self/SKILL.md` Step 3 (L41): `$SCOPE_DIR/verdicts.md`、`$SCOPE_DIR` = `{{SDD_DIR}}/project/reviews/self/` と明示。
`sdd-review-self/SKILL.md` Step 6.1 (L232): `$SCOPE_DIR/verdicts.md` → `$SCOPE_DIR/active/report.md`。
→ `review.md` がリストする `{{SDD_DIR}}/project/reviews/self/verdicts.md` は他の review タイプと同形式で、実際の self-review では `sdd-review-self` の SKILL.md が `$SCOPE_DIR/active/` を使う。
**→ 問題なし（self-review は review.md の Verdict Destination リストに追加情報として存在するが、両方のパスは一致）**。

**C4: Revise Mode Part B Step 7 の Cross-Cutting Consistency Review — 反復上限の不一致 [HIGH]**
`revise.md` Part B Step 8 (L255): "Max 5 retries (aggregate cap 6)." と記述。
`run.md` Step 7a (L238): "Max 5 retries per spec (aggregate cap 6 per spec)." と記述。
`CLAUDE.md` Auto-Fix Counter Limits (L176): "`retry_count`: max 5 (NO-GO only). `spec_update_count`: max 2 (SPEC-UPDATE-NEEDED only). Aggregate cap: 6."
→ 数値は一致。問題なし。

**C5: `sdd-inspector-rulebase.md` が Wave-Scoped モードで `tasks.yaml` を読まない**
`review.md` (L33): Impl Review は 6 impl Inspectors を使う。Cross-check/wave-scoped でも同じ Inspector セット。
`sdd-inspector-rulebase.md` (design review inspector) は Impl Inspector ではない。
`sdd-inspector-impl-rulebase.md` は impl review 専用。
→ 問題なし（設計 Inspector と実装 Inspector は別 set）。

---

### [HIGH]

**H1: Inspector カウントの不一致 — CLAUDE.md vs review.md**
`CLAUDE.md` (L27): Inspector として "6 design, 6 impl +2 web (impl only, web projects), 4 dead-code" と記述。
`review.md` Design Review (L25): 6 design Inspectors — `sdd-inspector-rulebase`, `sdd-inspector-testability`, `sdd-inspector-architecture`, `sdd-inspector-consistency`, `sdd-inspector-best-practices`, `sdd-inspector-holistic` → 6個、一致。
`review.md` Impl Review (L33-34): 6 standard + `sdd-inspector-e2e` + `sdd-inspector-visual` (web only) → 6+2、一致。
`review.md` Dead-Code Review (L44): 4 dead-code Inspectors → 4個、一致。
**→ 数値は一致しているが**、`sdd-auditor-impl.md` (L13) は "up to 8 independent review agents" と記述し、`sdd-auditor-design.md` (L13) は "6 independent review agents" と記述している。これは正しい（impl は web 時 8 になるため）。
→ **問題なし**。

**H2: `run.md` Step 7 (Wave QG) での dead-code retry カウンターの永続化非整合**
`run.md` Step 7b (L248): "max 3 retries, tracked in-memory by Lead — not persisted to spec.yaml. Dead-code findings are wave-scoped and resolved within a single execution window; counter restarts at 0 on session resume."
`CLAUDE.md` (L177): "Exception: Dead-Code Review NO-GO: max 3 retries (dead-code findings are simpler scope; exhaustion → escalate)."
`CLAUDE.md` (L179): "Counter reset triggers: wave completion, user escalation decision ..., session resume (dead-code counters are in-memory only; see `refs/run.md`)."
→ CLAUDE.md の説明と run.md の動作は一致している。
→ しかし、`refs/run.md` への参照が CLAUDE.md 内で `refs/run.md` と書かれているが、実際のファイルパスは `framework/claude/skills/sdd-roadmap/refs/run.md` である。CLAUDE.md の文書内では `see sdd-roadmap \`refs/run.md\`` と表現するのが正確な参照方法であり、これは慣習的に使われている。**問題なし**。

**H3: Session Resume ステップ 2a の `verdicts.md` パス**
`CLAUDE.md` Session Resume (L276): `{{SDD_DIR}}/project/specs/*/reviews/verdicts.md` を読む。
`review.md` Verdict Destination (L126-131): per-feature は `{{SDD_DIR}}/project/specs/{feature}/reviews/verdicts.md`、dead-code/cross-check/wave は `{{SDD_DIR}}/project/reviews/*/verdicts.md`。
→ Session Resume は per-feature の verdicts.md のみを読んでいる。wave-level や dead-code level は参照していない。
**→ MEDIUM 相当の問題**: pipeline resume 時に wave-level review 状態が復元されない可能性がある。ただし `run.md` は spec.yaml を ground truth とするため、wave-level verdict の再読は不要という設計意図かもしれない。設計意図は明記されていないため **曖昧さ** がある。
**場所**: `CLAUDE.md:276`, `review.md:126-131`

**H4: `reboot.md` Phase 7 Dispatch Loop の EXIT 条件が run.md とわずかに異なる**
`reboot.md` Phase 7 (L165): "EXIT: If all non-skipped specs in wave have design-generated + GO/CONDITIONAL verdict in `verdicts.md` and active is empty → next wave (or Phase 8)"
`run.md` Step 4 Dispatch Loop (L116): "EXIT: If no spec has a dispatchable next phase (per Readiness Rules) and active is empty → Wave QG (Step 7)"
→ reboot.md は "all non-skipped specs...design-generated + GO/CONDITIONAL verdict" と明示的に条件を書いているが、run.md は Readiness Rules に委ねている。reboot.md では Design のみでよく、Impl Readiness は評価されない（Modified Readiness Rules で明示）。
→ **不一致の深刻度は LOW**: reboot.md は設計フェーズのみを対象とするため別の EXIT 条件を持つのは自然。ただしスキップされた spec の扱いが `run.md` Readiness Rules には明示されていない（run.md の Blocking Protocol でのみ blocked として扱われる）。
**場所**: `reboot.md:165`, `run.md:116`

**H5: `sdd-review-self/SKILL.md` の Agent 3 出力パスとタスクのメタ整合**
`sdd-review-self/SKILL.md` Step 4, Agent 3 (L136-158): 出力パスを `{$SCOPE_DIR}/active/agent-3-consistency.md` と指示。
このレポートのタスク定義: "Write your full report to `.sdd/project/reviews/self/active/agent-3-consistency.md` AND return it as your Task result."
→ `$SCOPE_DIR` = `{{SDD_DIR}}/project/reviews/self/` であり、`.sdd/project/reviews/self/active/agent-3-consistency.md` は `{{SDD_DIR}}/project/reviews/self/active/agent-3-consistency.md` と等価。
**→ 問題なし**。

**H6: `sdd-auditor-dead-code.md` の SCOPE フォーマット — wave-scoped モードなし**
`sdd-auditor-dead-code.md` 出力フォーマット (L145-156): `SCOPE:{feature} | cross-check` のみ。wave-scoped を含まない。
`sdd-auditor-design.md` および `sdd-auditor-impl.md`: SCOPE に `wave-scoped-cross-check` を含む。
`review.md` Dead-Code Review 節: wave-scoped モードの記述なし（dead-code は no phase gate で全コードベース対象）。
→ dead-code は wave-scoped を実施しないという設計なので、`sdd-auditor-dead-code.md` が wave-scoped を持たないのは一貫。
**→ 問題なし**。

---

### [MEDIUM]

**M1: `sdd-inspector-e2e.md` / `sdd-inspector-visual.md` が playwright-cli auto-install 時に VERDICT:GO を返す**
`sdd-inspector-e2e.md` Error Handling (L189): playwright-cli install 失敗時 "output GO verdict with NOTES: SKIPPED, terminate (non-blocking)"
`sdd-inspector-visual.md` Error Handling (L217): 同様。
→ Auditor は Inspector の結果を読む際、GO verdict かつ `NOTES: SKIPPED` の場合を特別扱いするロジックが `sdd-auditor-impl.md` に明記されていない。Auditor は通常 GO として処理するため false-positive 防止の観点では安全だが、web inspector がスキップされた事実が verdict に明示されないリスクがある。
**場所**: `sdd-inspector-e2e.md:189`, `sdd-inspector-visual.md:217`, `sdd-auditor-impl.md` (該当記述なし)

**M2: `sdd-roadmap/SKILL.md` の `review dead-code` 引数と `review.md` の対応**
`SKILL.md` (L23): `$ARGUMENTS = "review dead-code"` → Review Subcommand。
`review.md` Step 1 (L9): `review type ("design"/"impl"/"dead-code")` として受け付ける。
`review.md` (L11-12): 最初の引数が `design`, `impl`, `dead-code` でない場合はエラー。
→ しかし SKILL.md では `review dead-code` の次に `[options]` は `[flags]` として表現されているが `review.md` では `[options]` と表現している。微細な記述の違いだが影響なし。
**→ 実質的に問題なし**。

**M3: `run.md` Step 2.5 で Conventions Brief の出力先パスに 1-spec と multi-spec の差異あり — CLAUDE.md に未記述**
`run.md` Step 2.5 (L38): multi-spec: `{{SDD_DIR}}/project/specs/.wave-context/{wave-N}/conventions-brief.md`、1-spec: `{{SDD_DIR}}/project/specs/{feature}/conventions-brief.md`。
`CLAUDE.md` (L102): "Pilot Stagger seeds conventions via ConventionsScanner supplement mode. See sdd-roadmap `refs/run.md` Step 2.5 and `refs/impl.md` Pilot Stagger Protocol." — パスの違いには言及なし。
→ 詳細は refs へ委譲しているため問題ではないが、 CLAUDE.md を参照するだけでは conventions brief の保存先が分からない。
**場所**: `CLAUDE.md:102`, `run.md:38`

**M4: `sdd-analyst.md` が `{{SDD_DIR}}` 変数を使用しているが template 変数未展開の可能性**
`sdd-analyst.md` Step 1 (L36): `{{SDD_DIR}}/project/specs/` を禁止対象として明記。
→ Agent は Lead からプロンプトで受け取るため、Lead が `{{SDD_DIR}}` を実際のパス (`.sdd`) に展開してから渡す必要がある。これが暗黙的で、明示されていない。
→ 他の agent でも同様のパターンが使われているため、フレームワーク全体での慣習として許容される範囲。
**場所**: `sdd-analyst.md:36`（および全 agent ファイル）

**M5: `revise.md` Part A Step 4 State Transition と Part B Step 7 State Transition の相違**
`revise.md` Part A Step 4 (L63-65): `phase = design-generated` に設定。
`revise.md` Part B Step 7.1 (L207-210): 同様 `phase = design-generated` に設定。
→ どちらも `orchestration.last_phase_action = null` にリセット。一致している。
**→ 問題なし**。

**M6: `run.md` Blocking Protocol (Step 6) でリセット対象の counter が `revise.md` と異なる**
`run.md` Step 6 skip オプション (L222-223): "Reset counters (`retry_count=0`, `spec_update_count=0`) for affected downstream specs."
`run.md` Step 6 fix オプション (L221): "reset `retry_count=0` and `spec_update_count=0` for unblocked specs"
`revise.md` Part A Step 4 (L63-64): `retry_count = 0`, `spec_update_count = 0` のみリセット。`last_phase_action = null` も追加。
→ Blocking Protocol からのカウンターリセットは revise と同様に last_phase_action もリセットすべきかどうか不明確。
**場所**: `run.md:221-223`, `revise.md:63-65`

**M7: `sdd-conventions-scanner.md` の Supplement モードで steering パスが受け取られない**
Generate モード (L20-23): steering path, buffer path, template path, output path, identifier を受け取る。
Supplement モード (L46-48): builder report path, existing brief path, output path のみ。
→ Supplement モードでは steering 参照が不要な設計（pilot Builder の実際のコードをスキャンするため）。
**→ 問題なし（意図的な省略）**。

**M8: `crud.md` Delete Mode が `{{SDD_DIR}}/project/reviews/` を削除するが cross-cutting は記述なし**
`crud.md` Delete Mode (L80-82): "Delete roadmap.md, all spec directories, and project-level reviews directory (`{{SDD_DIR}}/project/reviews/`)"
→ `specs/.cross-cutting/{id}/` ディレクトリは cross-cutting revisions のアーティファクトを含むが、Delete Mode での明示的な扱いが記述されていない。`all spec directories` に `.cross-cutting` が含まれるかどうか不明確。
**場所**: `crud.md:80-82`

---

### [LOW]

**L1: `sdd-auditor-dead-code.md` Agent 名の省略形が統一されていない**
`sdd-auditor-dead-code.md` 出力例 (L167-183): `settings`, `code`, `specs`, `tests` を agent 名として使用。
`sdd-auditor-design.md`/`sdd-auditor-impl.md`: `rulebase+consistency` のような `name-part+name-part` 形式。
→ dead-code Auditor は Inspector 短縮名を使い、他の Auditor は Inspector の `sdd-inspector-*` 名前のサブセットを使う。CPF 仕様 (L15) には "each Inspector defines relevant categories" とあり、agent 識別名の形式は統一仕様として定義されていない。
**場所**: `sdd-auditor-dead-code.md:160-162`, `cpf-format.md:15`

**L2: `sdd-inspector-dead-code.md` の SCOPE — `cross-check` のみで `feature` の使用例なし**
Dead-code Inspector 群の SCOPE: `{feature} | cross-check`。
→ review.md Dead-Code Review 節 (L44): dead-code は `sdd-inspector-dead-settings`, `sdd-inspector-dead-code`, `sdd-inspector-dead-specs`, `sdd-inspector-dead-tests` を使い、phase gate なし。
→ Single feature モードで dead-code review を実行することがあるかどうかが不明。`review dead-code` コマンドは feature を取らない (review.md L5)。つまり `{feature}` SCOPE は実質的に到達不能。
**場所**: `sdd-inspector-dead-code.md:55`, `sdd-inspector-dead-settings.md:44`, `sdd-inspector-dead-specs.md:49`, `sdd-inspector-dead-tests.md:49`

**L3: `design.md` テンプレートと `design-review.md` ルールの "System Flows" セクション名の微妙な差異**
`design.md` テンプレート (L94): セクション名 "## System Flows"
`design-review.md` (L30): "Has System Flows section (if applicable)"
`design-principles.md` (L68): "Default flow: Specifications → Overview → Architecture → System Flows → ..."
→ 一致している。**問題なし**。

**L4: `sdd-release/SKILL.md` での `Co-Authored-By` コミットの扱い**
`CLAUDE.md` Git Workflow (L330): "All commits MUST end with `Co-Authored-By: sync-sdd <noreply@sync-sdd>`"
`sdd-release/SKILL.md` Step 5 (L163-165): コミットメッセージフォーマット `{summary} (v{version})` のみ記述。`Co-Authored-By` の付与は記述されていない。
→ `sdd-release` はフレームワーク自体のリリース用スキルであり、この場合の `Co-Authored-By` の扱いが CLAUDE.md ルールと矛盾する可能性がある。ただし `settings.json` の `"includeCoAuthoredBy": false` により、プラットフォームレベルでは自動付与が無効化されている。
**場所**: `CLAUDE.md:330`, `sdd-release/SKILL.md:163-165`, `settings.json:2`

**L5: `sdd-steering/SKILL.md` でプロファイルの言語数が不明確**
`sdd-steering/SKILL.md` (L36-40): プロファイルは `{{SDD_DIR}}/settings/profiles/` から読み込む。`_index.md` を除外。
実際のプロファイル: `python.md`, `typescript.md`, `rust.md`（3個）。
→ SKILL.md はプロファイル数を明記していないが、`(exclude _index.md)` が正しく機能すれば問題ない。**問題なし**。

**L6: `sdd-reboot/SKILL.md` のエラーハンドリングと `reboot.md` Phase 5 の Modify ラウンド数の相違**
`sdd-reboot/SKILL.md` Error Handling (L52): "User chooses Iterate (Phase 9) → Skill terminates."
`reboot.md` Phase 5 (L76): "Max 2 modification rounds."
→ Modify は Phase 5 (User Review)、Iterate は Phase 9 (Final Decision)。これらは別フェーズ。
**→ 問題なし**。

**L7: `sdd-roadmap/SKILL.md` の Verdict Persistence Format と `review.md` の記述順序の微妙な差異**
`SKILL.md` (L133-137): a→b→c→d→e→f→g→h の手順でフォーマットを記述。
`review.md` Step 8 (L89): `Persist verdict to {scope-dir}/verdicts.md (see Router → Verdict Persistence Format)` と参照のみ。
→ review.md は SKILL.md へ委譲しているため整合。**問題なし**。

**L8: `sdd-analyst.md` の完了レポートと CLAUDE.md での記述の軽微な表記差異**
`CLAUDE.md` (L41): `ANALYST_COMPLETE + counts + Files to delete: {count} + WRITTEN:{path}`
`sdd-analyst.md` (L172-180):
```
ANALYST_COMPLETE
New specs: {count}
Waves: {count}
Steering: {created|updated} ({file_list})
Capabilities found: {count}
Files to delete: {count}
WRITTEN:{report_path}
```
→ CLAUDE.md の `counts` は `New specs`, `Waves`, `Capabilities found` などを指すと解釈できる。
**→ 実質的に一致。低影響**。

---

## Cross-Reference Matrix

| 参照元 | 参照先 | 参照内容 | 状態 |
|--------|--------|----------|------|
| CLAUDE.md | sdd-roadmap/refs/run.md | SubAgent Lifecycle details | OK |
| CLAUDE.md | sdd-roadmap/refs/run.md | Auto-Fix Counter Limits | OK |
| CLAUDE.md | sdd-roadmap/refs/review.md | Steering Feedback Loop | OK |
| CLAUDE.md | sdd-roadmap/refs/revise.md | Cross-Cutting revisions | OK |
| CLAUDE.md | sdd-roadmap/refs/impl.md | Pilot Stagger Protocol | OK |
| CLAUDE.md | sdd-roadmap/refs/crud.md | Wave Scheduling | OK |
| CLAUDE.md | sdd/settings/rules/cpf-format.md | CPF format spec | OK |
| CLAUDE.md | sdd/settings/templates/handover/session.md | session.md template | OK |
| CLAUDE.md | sdd/settings/templates/handover/buffer.md | buffer.md template | OK |
| sdd-roadmap/SKILL.md | refs/design.md | Design subcommand | OK |
| sdd-roadmap/SKILL.md | refs/impl.md | Impl subcommand | OK |
| sdd-roadmap/SKILL.md | refs/review.md | Review subcommand | OK |
| sdd-roadmap/SKILL.md | refs/run.md | Run subcommand | OK |
| sdd-roadmap/SKILL.md | refs/revise.md | Revise subcommand | OK |
| sdd-roadmap/SKILL.md | refs/crud.md | Create/Update/Delete | OK |
| refs/run.md | refs/design.md | Design completion handler | OK |
| refs/run.md | refs/impl.md | Impl completion handler | OK |
| refs/run.md | refs/review.md | Review completion handler | OK |
| refs/impl.md | sdd-conventions-scanner | Pilot Stagger | OK |
| refs/revise.md | refs/run.md | Step 2, Wave Context | OK |
| refs/revise.md | refs/design.md | Design execution | OK |
| refs/revise.md | refs/impl.md | Impl execution | OK |
| refs/revise.md | refs/review.md | Review execution | OK |
| refs/revise.md | refs/crud.md | Restructuring Check | OK |
| refs/reboot.md | refs/run.md | Phase 7 Design Loop | OK |
| sdd-roadmap/SKILL.md | sdd/settings/templates/specs/init.yaml | Spec initialization | OK (ファイル存在) |
| sdd-architect.md | sdd/settings/rules/design-discovery-full.md | Full discovery | OK |
| sdd-architect.md | sdd/settings/rules/design-discovery-light.md | Light discovery | OK |
| sdd-architect.md | sdd/settings/templates/specs/design.md | Design template | OK |
| sdd-architect.md | sdd/settings/templates/specs/research.md | Research template | OK |
| sdd-taskgenerator.md | sdd/settings/rules/tasks-generation.md | Task rules | OK |
| sdd-auditor-design.md | sdd-inspector-*.cpf files | Inspector results | OK |
| sdd-auditor-impl.md | sdd-inspector-*.cpf files | Inspector results | OK |
| sdd-auditor-dead-code.md | sdd-inspector-dead-*.cpf files | Inspector results | OK |
| sdd-inspector-rulebase.md | sdd/settings/templates/specs/design.md | Design template | OK |
| sdd-inspector-rulebase.md | sdd/settings/rules/design-review.md | Review rules | OK |
| sdd-inspector-testability.md | sdd/settings/rules/design-review.md | Review rules | OK |
| sdd-review-self/SKILL.md | sdd/project/reviews/self/ | Self-review scope dir | OK |
| sdd-reboot/SKILL.md | refs/reboot.md | Execution phases | OK |
| sdd-steering/SKILL.md | sdd/settings/rules/steering-principles.md | Steering rules | OK |
| sdd-steering/SKILL.md | sdd/settings/templates/steering/ | Steering templates | OK |
| sdd-steering/SKILL.md | sdd/settings/templates/steering-custom/ | Custom templates | OK |
| sdd-steering/SKILL.md | sdd/settings/profiles/ | Language profiles | OK |
| settings.json | Task(sdd-analyst) | Agent: sdd-analyst.md | OK |
| settings.json | Task(sdd-architect) | Agent: sdd-architect.md | OK |
| settings.json | Task(sdd-auditor-dead-code) | Agent exists | OK |
| settings.json | Task(sdd-auditor-design) | Agent exists | OK |
| settings.json | Task(sdd-auditor-impl) | Agent exists | OK |
| settings.json | Task(sdd-builder) | Agent exists | OK |
| settings.json | Task(sdd-conventions-scanner) | Agent exists | OK |
| settings.json | Task(sdd-inspector-architecture) | Agent exists | OK |
| settings.json | Task(sdd-inspector-best-practices) | Agent exists | OK |
| settings.json | Task(sdd-inspector-consistency) | Agent exists | OK |
| settings.json | Task(sdd-inspector-dead-code) | Agent exists | OK |
| settings.json | Task(sdd-inspector-dead-settings) | Agent exists | OK |
| settings.json | Task(sdd-inspector-dead-specs) | Agent exists | OK |
| settings.json | Task(sdd-inspector-dead-tests) | Agent exists | OK |
| settings.json | Task(sdd-inspector-e2e) | Agent exists | OK |
| settings.json | Task(sdd-inspector-holistic) | Agent exists | OK |
| settings.json | Task(sdd-inspector-impl-consistency) | Agent exists | OK |
| settings.json | Task(sdd-inspector-impl-holistic) | Agent exists | OK |
| settings.json | Task(sdd-inspector-impl-rulebase) | Agent exists | OK |
| settings.json | Task(sdd-inspector-interface) | Agent exists | OK |
| settings.json | Task(sdd-inspector-quality) | Agent exists | OK |
| settings.json | Task(sdd-inspector-rulebase) | Agent exists | OK |
| settings.json | Task(sdd-inspector-test) | Agent exists | OK |
| settings.json | Task(sdd-inspector-testability) | Agent exists | OK |
| settings.json | Task(sdd-inspector-visual) | Agent exists | OK |
| settings.json | Task(sdd-taskgenerator) | Agent exists | OK |
| settings.json | Skill(sdd-roadmap) | Skill exists | OK |
| settings.json | Skill(sdd-steering) | Skill exists | OK |
| settings.json | Skill(sdd-status) | Skill exists | OK |
| settings.json | Skill(sdd-handover) | Skill exists | OK |
| settings.json | Skill(sdd-reboot) | Skill exists | OK |
| settings.json | Skill(sdd-release) | Skill exists | OK |
| settings.json | Skill(sdd-review-self) | Skill exists | OK |
| install.sh | framework/claude/CLAUDE.md | Source file | OK |
| install.sh | framework/claude/settings.json | Source file | OK |
| install.sh | framework/claude/skills/ | Skills directory | OK |
| install.sh | framework/claude/agents/ | Agents directory | OK |
| install.sh | framework/claude/sdd/settings/rules/ | Rules directory | OK |
| install.sh | framework/claude/sdd/settings/templates/ | Templates directory | OK |
| install.sh | framework/claude/sdd/settings/profiles/ | Profiles directory | OK |

---

## Confirmed OK

- フェーズ名の統一: `initialized`, `design-generated`, `implementation-complete`, `blocked` — 全ファイルで統一されている
- Verdict 値の統一: `GO`, `CONDITIONAL`, `NO-GO`, `SPEC-UPDATE-NEEDED` — 設計/実装 Auditor で統一；dead-code Auditor は `SPEC-UPDATE-NEEDED` を持たず設計通り
- CPF severity codes: `C`, `H`, `M`, `L` — 全ファイルで統一されている
- SubAgent 名称の統一: `sdd-architect`, `sdd-builder`, `sdd-analyst`, `sdd-taskgenerator`, `sdd-conventions-scanner`, `sdd-auditor-design`, `sdd-auditor-impl`, `sdd-auditor-dead-code` — settings.json の Task() リストと完全一致
- settings.json の Task() エントリと実際の agent ファイル — 全 26 エントリが存在確認済み
- settings.json の Skill() エントリと実際の skill ディレクトリ — 全 7 エントリが存在確認済み
- retry_count 上限 (5) / spec_update_count 上限 (2) / aggregate cap (6) — CLAUDE.md, run.md, revise.md で一致
- dead-code retry 上限 (3) — CLAUDE.md, run.md で一致
- `{{SDD_DIR}}` = `.sdd` の定義 — CLAUDE.md とすべてのファイルで一致
- decisions.md Decision types 統一: `USER_DECISION`, `STEERING_UPDATE`, `DIRECTION_CHANGE`, `ESCALATION_RESOLVED`, `REVISION_INITIATED`, `STEERING_EXCEPTION`, `SESSION_START`, `SESSION_END` — CLAUDE.md とすべての skill ファイルで一致
- init.yaml テンプレートの存在: `framework/claude/sdd/settings/templates/specs/init.yaml` — 存在確認済み
- design.md テンプレート、research.md テンプレート、buffer.md テンプレート — 全て存在確認済み
- analysis-report.md テンプレート、conventions-brief.md テンプレート — 存在確認済み
- steering テンプレート (product.md, tech.md, structure.md) および custom テンプレート群 — 全て存在確認済み
- install.sh が `{{SDD_VERSION}}` を VERSION ファイルから注入する仕組みが CLAUDE.md (L1) の `{{SDD_VERSION}}` プレースホルダーと整合
- Tier 分類 (T1: Lead/Opus, T2: Brain/Opus, T3: Execute/Sonnet) — CLAUDE.md と全 agent frontmatter で一致
- `background: true` frontmatter — 全 agent ファイルに存在
- Inspector ファイルが全て `WRITTEN:{output_file_path}` を返す規約 — 全 Inspector で確認済み
- Auditor ファイルが全て `WRITTEN:{verdict_file_path}` を返す規約 — 全 Auditor で確認済み
- Builder が `builder-report-{group}.md` に書き込む規約 — `sdd-builder.md` と `refs/impl.md` で一致
- Wave bypass (island spec) の定義 — `run.md` のみに存在（CLAUDE.md にも言及）、一致
- ConventionsScanner の 2 モード (Generate / Supplement) — `sdd-conventions-scanner.md` と `run.md`, `refs/impl.md` で一致
- Pilot Stagger Protocol — `refs/impl.md` と `CLAUDE.md` の参照が一致
- Cross-cutting revision の verdicts 保存先 `specs/.cross-cutting/{id}/verdicts.md` — `revise.md` と `review.md` で一致
- Self-review スコープディレクトリ `{{SDD_DIR}}/project/reviews/self/` — `review.md` と `sdd-review-self/SKILL.md` で一致
- 循環参照なし: skill → refs → (agents への参照なし) の単方向構造を確認

---

## Overall Assessment

フレームワーク全体の整合性は **高水準** である。26 個の agent ファイル、7 個の skill ファイル、refs 群、rules、templates、settings.json および install.sh の間で、フェーズ名・verdict 値・retry 上限・パス定義・SubAgent 名称はほぼ統一されている。

**主要な発見事項**:

1. **[MEDIUM] H3 が最も実用的な懸念事項**: Session Resume が per-feature の `verdicts.md` のみを読み、wave-level の review 状態を復元しない点は、pipeline resume 時に潜在的な情報欠落を引き起こす可能性がある。ただし `run.md` が spec.yaml を ground truth とする設計のため、実際の影響は限定的と考えられる。

2. **[LOW] L2 の dead-code Inspector の SCOPE における `{feature}` は実質到達不能**: `review dead-code` は feature を取らないため、Inspector の SCOPE フォーマットに `{feature}` が残っているのは過剰な定義と言える。

3. **[LOW] L4 の sdd-release コミットの Co-Authored-By 欠落**: CLAUDE.md の Git Workflow ルールに従えばリリースコミットにも `Co-Authored-By` が必要だが、`sdd-release/SKILL.md` ではこれが明記されていない。settings.json の `"includeCoAuthoredBy": false` との関係も不明確。

4. **[MEDIUM] M8 の Delete Mode での `.cross-cutting` ディレクトリの扱い**: `crud.md` の Delete Mode が `specs/.cross-cutting/` を明示的に削除対象としていない点は、残留アーティファクトの原因になりうる。

全体として重大な整合性の破綻は検出されない。運用上の問題を引き起こす可能性のある項目は H3 と M8 に限られる。
