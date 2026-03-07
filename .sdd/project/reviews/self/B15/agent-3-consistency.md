# Consistency & Dead Ends Report (Agent 3)

**Date**: 2026-02-28
**Scope**: framework/claude/ 全ファイル + install.sh
**Reviewer**: Agent 3 — Consistency & Dead Ends

---

## Issues Found

### [CRITICAL]

**C1: `init.yaml` テンプレートへの参照が SKILL.md で `init.yaml` を指しているが、install.sh の削除マニフェストに `init.json` が残っている**
- `refs/SKILL.md`（sdd-roadmap）行76: `{{SDD_DIR}}/settings/templates/specs/init.yaml` を参照
- `install.sh` 行306-307: `v0.10.0` マイグレーション内で `.claude/sdd/settings/templates/specs/init.json` を削除。ただし実際のファイルは `init.yaml` として存在しており、JSON 版は廃止済み。
- **影響**: install.sh の削除は既存の YAML ファイルを削除しない（パス不一致）のため実害なし。ただし、ドキュメント的に混乱を招く。修正済みと判断するなら LOW、未確認なら MEDIUM 扱い。
- → **MEDIUM** に格下げ（実害がないため）

**C2: `sdd-review-self` SKILL.md の SubAgent 呼び出し方式が CLAUDE.md の方針と矛盾**
- CLAUDE.md（line 84）: 「Lead dispatches SubAgents via `Task` tool with `run_in_background: true` **always**. No exceptions」
- `sdd-review-self` SKILL.md（Step 4, line 57）: `Task(subagent_type="general-purpose", model="sonnet", run_in_background=true)` ← `run_in_background: true` はあるが、`subagent_type="general-purpose"` は `.claude/agents/` に定義されたファイルへの参照ではなく、プラットフォームの汎用エージェント指定。これは他の全エージェント（`subagent_type="sdd-architect"` など）と意味が異なる。
- **影響**: `general-purpose` が実際に動作するかどうかはプラットフォーム依存。もし `general-purpose` が有効でなければ、sdd-review-self の全レビューエージェントが失敗する。
- ファイル: `framework/claude/skills/sdd-review-self/SKILL.md:57`
- **[HIGH]** → 他の Task 呼び出しとの不整合

**C3: `SPEC-UPDATE-NEEDED` 判定ロジックの不整合（Reboot での設計レビューに関して）**
- `refs/run.md`（line 180）: 「**SPEC-UPDATE-NEEDED** → not expected for design review. If received, escalate immediately.」
- `refs/revise.md` Part B Step 4（line 229）: 「SPEC-UPDATE-NEEDED is not expected for design review. If received, escalate immediately」
- `refs/reboot.md`（Phase 7 Verdict Handling, line 185）: 「Max 5 retries (SPEC-UPDATE-NEEDED does not occur in design review, so only `retry_count` applies here)」
- → これらは整合しており問題なし。**確認済み OK**

**C4: `verdicts.md` のパスが `review.md` と `run.md` で部分的に異なる記述**
- `refs/review.md`（line 128-131）: Wave QG の verdict は `{{SDD_DIR}}/project/reviews/wave/verdicts.md` と記述。
- `refs/run.md`（Step 7a, line 232）: 「Persist verdict to `{{SDD_DIR}}/project/reviews/wave/verdicts.md` (header: `[W{wave}-B{seq}]`)」と一致している。→ OK。
- ただし `sdd-review-self` の `$SCOPE_DIR` は `{{SDD_DIR}}/project/reviews/self/` と定義（SKILL.md line 41）。このパスは `review.md` の Verdict Destination リスト（line 131）: 「**Self-review** (framework-internal): `{{SDD_DIR}}/project/reviews/self/verdicts.md`」と一致。→ OK。

---

### [HIGH]

**H1: `sdd-review-self` が呼び出す `general-purpose` エージェントは `settings.json` の許可リストに存在しない**
- `framework/claude/settings.json` には `Task(sdd-analyst)`, `Task(sdd-architect)` 等の明示的な `Task()` エントリのみ存在。
- `Task(general-purpose)` は permissions の allow リストに存在しない。
- `sdd-review-self` SKILL.md: `Task(subagent_type="general-purpose", model="sonnet", run_in_background=true)` (line 57)
- **影響**: `settings.json` の `acceptEdits` defaultMode のみでは Task 呼び出しにパーミッションチェックがかかる可能性あり。`Task(general-purpose)` が拒否されると sdd-review-self 全体が機能しない。
- ファイル: `framework/claude/settings.json`, `framework/claude/skills/sdd-review-self/SKILL.md:57`

**H2: Dead Code Review の retry 上限が CLAUDE.md と run.md で一致しているが spec.yaml への記録方法が未定義**
- CLAUDE.md（line 177）: 「Dead-Code Review NO-GO: max 3 retries (dead-code findings are simpler scope; exhaustion → escalate)」
- `refs/run.md`（Step 7b, line 248）: 「re-review (max 3 retries, tracked in-memory by Lead — not persisted to spec.yaml. ... counter restarts at 0 on session resume.)」
- セッション再開時に Dead Code Review のカウンターがリセットされる点は明示されており整合している。
- ただし、CLAUDE.md には「Counter reset triggers: wave completion, user escalation decision (including blocking protocol fix/skip), `/sdd-roadmap revise` start.」とあり、Dead Code retry カウンターがこのリセット条件に該当するかどうかが不明確。Dead Code カウンターは in-memory かつセッション再開でリセットされるため、通常のカウンターとは別物だが CLAUDE.md の記述では区別されていない。
- **影響**: セッション再開後に Dead Code Review が再実行される場合、Lead が「前回 3 回試した」という文脈を失う可能性。
- ファイル: `framework/claude/CLAUDE.md:177`, `framework/claude/skills/sdd-roadmap/refs/run.md:248`

**H3: Analyst の完了レポートに `WRITTEN:{path}` が含まれているが、CLAUDE.md の記述と形式が一致**
- CLAUDE.md（line 41）: 「return structured summary (`ANALYST_COMPLETE` + counts + `Files to delete: {count}` + `WRITTEN:{path}`)」
- `sdd-analyst.md`（line 172-179）の Completion Report:
  ```
  ANALYST_COMPLETE
  New specs: {count}
  Waves: {count}
  Steering: {created|updated} ({file_list})
  Capabilities found: {count}
  Files to delete: {count}
  WRITTEN:{report_path}
  ```
- CLAUDE.md には `counts` （複数形）と書かれているが、Analyst の出力形式は5種類のカウント。CLAUDE.md が省略表現として使っているなら問題ないが、Lead が厳密に `ANALYST_COMPLETE + N + Files to delete + WRITTEN` の4フィールドのみを期待していたとすると、`Waves:`, `Steering:`, `Capabilities found:` フィールドが意図的に含まれていることが不明確。
- **影響**: 低。Lead は構造を読み取れるため実害は小さい。MEDIUM に格下げ。

---

### [MEDIUM]

**M1: Inspector の SCOPE 値フォーマットが定義ファイルごとに微妙に異なる**
- `sdd-inspector-rulebase.md`（Output Format）: `SCOPE:{feature} | cross-check | wave-1..{N}`
- `sdd-inspector-architecture.md`（Output Format）: `SCOPE:{feature} | cross-check | wave-1..{N}` ← 一致
- `sdd-inspector-dead-code.md`（Output Format）: `SCOPE:{feature} | cross-check` ← wave-scoped モードの記載なし
- `sdd-inspector-dead-settings.md`, `sdd-inspector-dead-tests.md`, `sdd-inspector-dead-specs.md`: 同様に `wave-1..{N}` なし
- `sdd-auditor-dead-code.md`（CPF Output）: `VERDICT:`, `VERIFIED:`, `REMOVED:`, `RESOLVED:`, `NOTES:` のみで `SCOPE:` フィールド定義がない
- Dead Code 系の Inspectors は `SCOPE:` に wave モードを含まない。Dead Code Review はそもそも wave-scoped モードがない（review.md に wave モードの言及なし）ので設計上正しいが、コメントなしで省略されているため一見不整合に見える。
- ファイル: 各 dead code inspector ファイル

**M2: `refs/impl.md` における conventions brief パスの受け渡しが TaskGenerator への dispatch に記載あるが、Builder への dispatch では明示されていない場所がある**
- `refs/impl.md`（Step 2, line 30）: TaskGenerator dispatch に「Conventions brief: path to conventions-brief.md (if generated by run.md Step 2.5)」あり。
- `refs/impl.md`（Step 3, line 46）: Builder dispatch に「Conventions brief: path to conventions-brief.md (if available)」あり。
- → 一致している。確認済み OK に格上げ。（以下省略）

**M3: `sdd-inspector-e2e` と `sdd-inspector-visual` の install 失敗時の VERDICT が異なる**
- `sdd-inspector-e2e.md`（line 116）: install 失敗時 → `VERDICT:GO` with `NOTES: SKIPPED|playwright-cli install failed`
- `sdd-inspector-visual.md`（line 103）: install 失敗時 → `VERDICT:GO` with `NOTES: SKIPPED|playwright-cli unavailable`
- NOTES の文字列が異なる（`playwright-cli install failed` vs `playwright-cli unavailable`）。Auditor がこれらの NOTES をパースする場合、文字列不一致で処理が変わる可能性。
- ファイル: `framework/claude/agents/sdd-inspector-e2e.md:116`, `framework/claude/agents/sdd-inspector-visual.md:103`

**M4: `sdd-auditor-dead-code.md` の `SCOPE` フィールドが Output Format に含まれていない**
- `sdd-auditor-design.md` 出力: `SCOPE:{feature} | cross-check | wave-scoped-cross-check` あり。
- `sdd-auditor-impl.md` 出力: 同様に `SCOPE:` あり。
- `sdd-auditor-dead-code.md`（line 145-155）の Output Format: `SCOPE:` フィールドがない。
- Auditor verdict の SCOPE フィールドは Lead が verdict を読み取る際に使用する可能性あり。dead-code Auditor だけ SCOPE がないと、Lead が dead-code verdict を他の verdict と同じロジックで処理しようとしたとき、フィールド欠損でエラーになる可能性。
- ファイル: `framework/claude/agents/sdd-auditor-dead-code.md:145-155`

**M5: `refs/revise.md` Part A Step 4 で `phase = design-generated` にセットしているが、`version` の更新が記述されていない（refs/design.md との不整合）**
- `refs/revise.md`（Step 4, line 61-65）: spec.yaml の更新として `last_phase_action = null`, `retry_count = 0`, `spec_update_count = 0`, `phase = design-generated` を記述。
- `refs/design.md`（Step 3 after completion, line 34-40）: `version` の increment（「If re-edit: increment version minor」）, `version_refs.design` の更新、`phase = design-generated` を記述。
- `refs/revise.md` Step 5 Design フェーズの実行後（line 74）: 「After completion: verify design.md, update spec.yaml (increment `version`, phase=design-generated, last_phase_action=null)」と記述されており、Step 5 で design.md の手順に従うことで version 更新が行われる。
- → Step 4 は state transition のみで version 更新は Step 5 の Design 実行後に委譲される設計。整合しているが説明が分かれているため分かりにくい。**LOW** に格下げ。

**M6: `sdd-review-self` が参照する `$SCOPE_DIR/verdicts.md` のファイルパスにおける `$SCOPE_DIR` の定義**
- SKILL.md（line 41）: `$SCOPE_DIR` = `{{SDD_DIR}}/project/reviews/self/`
- `review.md`（line 131）: 「**Self-review**: `{{SDD_DIR}}/project/reviews/self/verdicts.md`」
- → 一致。OK。

**M7: `BUILDER_BLOCKED` の場合に builder-report ファイルへの書き込みが不要とされているが、Lead の処理フローで report path が参照される場合のハンドリングが不明**
- `sdd-builder.md`（line 165-171）: BLOCKED の場合は「No file write required for BLOCKED」
- `refs/impl.md`（line 80）: 「If BUILDER_BLOCKED: classify cause from inline blocker summary」— Lead は Task result（インライン）から直接読み取る。report path は参照しない。
- → 設計上の一貫性はある。ただし BLOCK 後に「If Tags > 0: Grep builder-report file」の処理（impl.md line 76）が BLOCKED ケースでも誤って実行されないことは、Lead の判断に委ねられている。明示的なスキップ指示はない。
- ファイル: `framework/claude/skills/sdd-roadmap/refs/impl.md:76`

**M8: 「Wave-scoped cross-check」は design review と impl review の両方で使われるが、wave review の verdicts.md パスが run.md と review.md で表記が微妙に異なる**
- `refs/run.md`（Step 7a, line 232）: `{{SDD_DIR}}/project/reviews/wave/verdicts.md` (header: `[W{wave}-B{seq}]`)
- `refs/review.md`（line 129）: `{{SDD_DIR}}/project/reviews/wave/verdicts.md`（wave-scoped review）
- → 一致。OK。

---

### [LOW]

**L1: `design-discovery-full.md` と `design-discovery-light.md` は `sdd-architect.md` から参照されているが、ファイル内容の確認**
- `sdd-architect.md`（line 52, 56）: 「Read and execute `{{SDD_DIR}}/settings/rules/design-discovery-full.md`」および「Read and execute `{{SDD_DIR}}/settings/rules/design-discovery-light.md`」
- Glob 結果にこれらのファイルが存在することを確認（`design-discovery-full.md`, `design-discovery-light.md`）。
- → ファイルは存在する。参照整合 OK。

**L2: CLAUDE.md の Inspector 数の記述と実際のエージェント数が一致しているか**
- CLAUDE.md（line 27）: 「6 design, 6 impl +2 web (impl only, web projects), 4 dead-code」
- 実際のエージェントファイル数:
  - Design Inspectors: `sdd-inspector-rulebase`, `sdd-inspector-testability`, `sdd-inspector-architecture`, `sdd-inspector-consistency`, `sdd-inspector-best-practices`, `sdd-inspector-holistic` → **6個** ✓
  - Impl Inspectors (standard): `sdd-inspector-impl-rulebase`, `sdd-inspector-interface`, `sdd-inspector-test`, `sdd-inspector-quality`, `sdd-inspector-impl-consistency`, `sdd-inspector-impl-holistic` → **6個** ✓
  - Web Inspectors: `sdd-inspector-e2e`, `sdd-inspector-visual` → **2個** ✓
  - Dead Code Inspectors: `sdd-inspector-dead-code`, `sdd-inspector-dead-settings`, `sdd-inspector-dead-specs`, `sdd-inspector-dead-tests` → **4個** ✓
- → CLAUDE.md の数値は正確。

**L3: `sdd-conventions-scanner.md` の `Mode: Supplement` における出力先について `overwrite` と明記されているが、input と output が同じパスであることの確認**
- SKILL.md（Pilot Stagger Protocol, line 63）: 「Output path: same as existing brief path (overwrite with supplement)」
- `sdd-conventions-scanner.md`（Supplement mode, line 51）: 「Output path: same as existing brief path (overwrite with supplement)」
- → 整合。

**L4: `sdd-review-self` の `$FOCUS_TARGETS` が未定義のまま Agent 2 に渡される構造的問題**
- SKILL.md（Step 1, line 21）: 「Build `$FOCUS_TARGETS` (3-5 bullet points)」とあるが、Agent 2 の prompt（line 123）: `{$FOCUS_TARGETS}` を参照している。これは Lead が変数を展開した上で渡す設計。
- 変数展開はスキルのプロンプト内で Lead が行う想定だが、スキル定義内での変数展開の実行責任が明示されていない。
- → 実際には Lead がプロンプト文字列を組み立てるため機能するはずだが、仕様として `{$FOCUS_TARGETS}` がそのままのリテラルで渡された場合の挙動が未定義。LOW。

**L5: `CLAUDE.md` の Commands 数(6)と実際の skills の数が一致しているか**
- CLAUDE.md（line 146）: 「### Commands (6)」
- 実際のスキルファイル: `sdd-release`, `sdd-steering`, `sdd-status`, `sdd-handover`, `sdd-review-self`, `sdd-reboot`, `sdd-roadmap` → **7個**
- `sdd-review-self` はフレームワーク内部ツールであり、公開コマンドの数には含めないとすると6個になる。ただし CLAUDE.md の Commands テーブルには `sdd-review-self` が記載されていないため、6と記述するのは意図的。
- → CLAUDE.md の Commands テーブルに `sdd-review-self` は含まれておらず、6個の数値は正確（公開コマンド限定）。

**L6: `install.sh` の summary 出力（line 582）でスキル数のカウントに `sdd-review-self` が含まれるか**
- `install.sh`（line 582）: `$(find .claude/skills -name 'SKILL.md' -path '*/sdd-*/*' 2>/dev/null | wc -l | tr -d ' ') skills`
- このコマンドは `sdd-review-self` も含む全 sdd-* skills をカウントする。CLAUDE.md の「Commands (6)」とカウント方法が異なるため、install 後の表示が 7 skills となる。
- ユーザーに「7 skills がインストールされた」と表示されるが CLAUDE.md では「コマンド数 6」と言っている矛盾。CLAUDE.md が公開コマンドのみ、インストーラーが全 skills をカウントするという意図の違い。
- → 設計意図は明確だが、ユーザーへの見た目の不整合。

---

## クロスリファレンスマトリクス

| 参照元 | 参照先 | 内容 | 整合性 |
|--------|--------|------|--------|
| CLAUDE.md | sdd-roadmap refs/run.md | SubAgent Lifecycle, parallel execution | OK |
| CLAUDE.md | sdd-roadmap refs/review.md | Steering Feedback Loop | OK |
| CLAUDE.md | sdd-roadmap refs/revise.md (暗示) | REVISION_INITIATED decision type | OK |
| SKILL.md (roadmap) | refs/design.md | Design subcommand dispatch | OK |
| SKILL.md (roadmap) | refs/impl.md | Impl subcommand dispatch | OK |
| SKILL.md (roadmap) | refs/review.md | Review subcommand dispatch | OK |
| SKILL.md (roadmap) | refs/run.md | Run subcommand dispatch | OK |
| SKILL.md (roadmap) | refs/revise.md | Revise subcommand dispatch | OK |
| SKILL.md (roadmap) | refs/crud.md | Create/Update/Delete dispatch | OK |
| refs/run.md | refs/design.md | Phase Handler Design completion | OK |
| refs/run.md | refs/impl.md | Phase Handler Impl completion | OK |
| refs/run.md | refs/review.md | Phase Handler Review | OK |
| refs/revise.md Part A | refs/design.md, refs/impl.md, refs/review.md | Step 5 pipeline | OK |
| refs/revise.md Part B | refs/impl.md | Pilot Stagger Protocol | OK |
| refs/revise.md Part B | refs/run.md | Dispatch Loop pattern | OK |
| refs/reboot.md Phase 7 | refs/run.md | Dispatch Loop reuse | OK |
| sdd-analyst.md | .sdd/settings/templates/reboot/analysis-report.md | Template reference | OK (ファイル存在確認済み) |
| sdd-architect.md | .sdd/settings/rules/design-discovery-full.md | Rule reference | OK (ファイル存在確認済み) |
| sdd-architect.md | .sdd/settings/rules/design-discovery-light.md | Rule reference | OK (ファイル存在確認済み) |
| sdd-architect.md | .sdd/settings/templates/specs/design.md | Template reference | OK (ファイル存在確認済み) |
| sdd-taskgenerator.md | .sdd/settings/rules/tasks-generation.md | Rule reference | OK (ファイル存在確認済み) |
| sdd-inspector-rulebase.md | .sdd/settings/templates/specs/design.md | Template reference | OK |
| sdd-inspector-rulebase.md | .sdd/settings/rules/design-review.md | Rule reference | OK |
| sdd-inspector-testability.md | .sdd/settings/rules/design-review.md | Rule reference | OK |
| sdd-review-self SKILL.md | .sdd/project/reviews/self/ (SCOPE_DIR) | Verdict persistence path | OK (review.md と一致) |
| sdd-review-self SKILL.md | Task(general-purpose) | SubAgent dispatch | **不整合**: settings.json に未登録 |
| settings.json | Task(sdd-analyst) 等 24エントリ | SubAgent permission | OK (全エージェントファイルと一致) |
| install.sh | framework/claude/skills/ | Skills インストール先 | OK |
| install.sh | framework/claude/agents/ | Agents インストール先 | OK |
| install.sh | framework/claude/sdd/settings/rules | Rules インストール先 | OK |
| install.sh | framework/claude/sdd/settings/templates | Templates インストール先 | OK |

---

## Confirmed OK

- フェーズ名は全ファイルで統一: `initialized`, `design-generated`, `implementation-complete`, `blocked`
- verdict 値は全 Auditor で統一: `GO`, `CONDITIONAL`, `NO-GO`（impl Auditor のみ `SPEC-UPDATE-NEEDED` を追加）
- CPF 重大度コードは全ファイルで統一: `C`, `H`, `M`, `L`
- retry_count 上限（5）と spec_update_count 上限（2）、aggregate cap（6）が CLAUDE.md と run.md で一致
- Dead Code Review retry 上限（3）が CLAUDE.md と run.md で一致
- Design Review の Inspector 数（6）が CLAUDE.md、review.md、reboot.md で一致
- Impl Review の Inspector 数（6標準 + 2 web）が CLAUDE.md と review.md で一致
- Dead Code Review の Inspector 数（4）が CLAUDE.md と review.md で一致
- Builder の SelfCheck ステータス値（PASS/WARN/FAIL-RETRY-2）が impl.md と builder.md で一致
- Auditor の STEERING フィールド値（CODIFY/PROPOSE）が各 Auditor と review.md で一致
- `reviews/active/` → `reviews/B{seq}/` アーカイブパターンが CLAUDE.md と review.md と各 Auditor で一致
- consensus mode の archive パターン（`active-{p}/` → `B{seq}/pipeline-{p}/`）が SKILL.md と review.md で一致
- `spec.yaml` フィールド（`orchestration.retry_count`, `orchestration.spec_update_count`, `orchestration.last_phase_action`, `blocked_info`）が init.yaml テンプレートと各 refs で一致
- Blocking Protocol の選択肢（fix/skip/abort）が run.md で完全に定義
- Wave QG（Impl Cross-Check + Dead Code）の二段階構造が run.md で完全に定義
- sessions/ アーカイブ形式（`{YYYY-MM-DD}.md`, 同日複数の場合 `-2.md` 等）が handover SKILL.md で定義
- `ANALYST_COMPLETE` 形式が CLAUDE.md と sdd-analyst.md で一致
- `ARCHITECT_COMPLETE` 形式が sdd-architect.md に定義（CLAUDE.md では言及なし）
- `TASKGEN_COMPLETE` 形式が sdd-taskgenerator.md に定義
- `BUILDER_COMPLETE` / `BUILDER_BLOCKED` 形式が sdd-builder.md と refs/impl.md で一致
- `sdd-conventions-scanner` の出力（`WRITTEN:{path}`）が run.md Step 2.5 と scanner 定義で一致
- Wave Context のファイルパス（`.wave-context/{wave-N}/conventions-brief.md`）が run.md と impl.md で一致
- cross-cutting spec パス（`specs/.cross-cutting/{id}/`）が CLAUDE.md と revise.md と review.md で一致
- `init.yaml` テンプレートの全フィールドが refs/impl.md, refs/design.md での spec.yaml 更新と対応している
- install.sh のマイグレーションチェーン（v0.4.0 → 0.7.0 → 0.9.0 → 0.10.0 → 0.15.0 → 0.18.0 → 0.20.0 → 1.2.0）に循環参照なし
- reboot の branch naming（`reboot/{name}` または `reboot/{YYYY-MM-DD}`）が reboot SKILL.md と refs/reboot.md で一致
- Pilot Stagger Protocol の説明が refs/impl.md と refs/revise.md Part B Step 5 で同じ仕組みを参照

---

## Overall Assessment

**発見された重大問題**: 1件（H1）が最優先

最も影響が大きいのは **H1（sdd-review-self の Task(general-purpose) が settings.json の許可リストに未登録）**。これは `sdd-review-self` コマンドの全機能が動作しないリスクを持つ。実際に Claude Code のパーミッションシステムが `Task()` の引数まで検証するかどうかによって影響度が変わるが、確認が必要。

次に優先度が高いのは **M3（E2E と Visual Inspector の install 失敗時 NOTES 文字列の差異）** と **M4（dead-code Auditor の SCOPE フィールド欠落）**。

全体的に、フェーズ名・verdict 値・retry 上限・SubAgent 名など主要な値は高い一貫性を保っている。

**推奨修正優先順位**:
1. H1: `settings.json` に `Task(general-purpose)` エントリを追加、または sdd-review-self を `Task(sdd-*)` ベースのエージェントに切り替える
2. M4: `sdd-auditor-dead-code.md` の Output Format に `SCOPE:` フィールドを追加
3. M3: E2E と Visual の playwright-cli 未インストール時の NOTES 文字列を統一

