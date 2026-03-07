## Flow Integrity Report

**対象バージョン**: v1.3.0
**レビュー日**: 2026-02-27
**レビュー対象**:
- framework/claude/CLAUDE.md
- framework/claude/skills/sdd-roadmap/SKILL.md (Router)
- framework/claude/skills/sdd-roadmap/refs/design.md
- framework/claude/skills/sdd-roadmap/refs/impl.md
- framework/claude/skills/sdd-roadmap/refs/review.md
- framework/claude/skills/sdd-roadmap/refs/run.md
- framework/claude/skills/sdd-roadmap/refs/revise.md
- framework/claude/skills/sdd-roadmap/refs/crud.md
- framework/claude/agents/sdd-*.md (全エージェント)
- framework/claude/settings.json
- framework/claude/sdd/settings/rules/*.md
- framework/claude/sdd/settings/templates/**/*.md
- install.sh

---

### Issues Found

#### [HIGH] run.md Step 6 カウンターリセット — CLAUDE.md との整合性確認 (Focus Target M2)

**ファイル**: `framework/claude/skills/sdd-roadmap/refs/run.md:221-222`

run.md Step 6 (Blocking Protocol) の **fix** オプションには以下が記述されている:
```
reset `retry_count=0` and `spec_update_count=0` for unblocked specs
```
**skip** オプションにも:
```
Reset counters (`retry_count=0`, `spec_update_count=0`) for affected downstream specs.
```

CLAUDE.md §Auto-Fix Counter Limits のカウンターリセットトリガーは以下の3つ:
```
wave completion, user escalation decision, `/sdd-roadmap revise` start.
```

**問題点**: Blocking Protocol での unblock (fix) / skip 操作によるカウンターリセットが、CLAUDE.md のリセットトリガーリストに含まれていない。

- `wave completion` — Wave QG 後の Post-gate でリセット (run.md Step 7c に明記)
- `user escalation decision` — exhaustion 後のユーザー選択
- `/sdd-roadmap revise` start — revise.md Step 4 に明記

しかし `Blocking Protocol での fix/skip` は CLAUDE.md のリストに存在しない。これは M2 fix (Step 6 に明示追加された) と CLAUDE.md 側の記述が同期されていない状態を示す。

**影響**: Lead が CLAUDE.md を参照した際にブロッキングプロトコルでのカウンターリセットを見落とすリスク。情報源として CLAUDE.md が不完全。

**推奨修正**: CLAUDE.md §Auto-Fix Counter Limits のリセットトリガーリストに `Blocking Protocol での fix/skip (run.md Step 6)` を追加する。

---

#### [MEDIUM] review.md "Triggered by" 行 — dead-code に `{feature}` 引数なし (Focus Target L1)

**ファイル**: `framework/claude/skills/sdd-roadmap/refs/review.md:5`

review.md 冒頭の Triggered by 行:
```
Triggered by: `$ARGUMENTS = "review design|impl {feature} [options]"` or `$ARGUMENTS = "review dead-code [options]"`
```

dead-code に `{feature}` 引数が記載されていないことは **正しい修正** (L1 fix)。

SKILL.md (Router) の Detect Mode では:
```
$ARGUMENTS = "review dead-code"  → Review Subcommand
```
feature 引数なしであり、review.md と整合している。

**確認結果**: L1 fix は正しく反映されている。問題なし。

---

#### [MEDIUM] revise.md Step 7 — Design Fan-Out 後の spec.yaml 更新明示 (Focus Target L2)

**ファイル**: `framework/claude/skills/sdd-roadmap/refs/revise.md:224`

revise.md Part B Step 7 (Tier Execution) の Step 3 (Design Fan-Out):
```
After each Architect completes: update spec.yaml per design.md Step 3
```

これは L2 fix で追加された記述。design.md Step 3 では:
- `version_refs.design` の更新
- `phase = design-generated`
- `orchestration.last_phase_action = null`
- `changelog` 更新

が明示されている。revise.md からの参照は正しい。

**確認結果**: L2 fix は正しく反映されている。ただし、以下の軽微な点を指摘する:

revise.md Part B Step 7 の Step 1 (State Transition) にて:
```
Set phase = design-generated
```
とあり、Step 3 の `update spec.yaml per design.md Step 3` でも `phase = design-generated` がセットされる。これは重複だが、State Transition (reset) と Design 完了後の確定 (set) という意味で意図的と解釈できる。矛盾ではない。

---

#### [MEDIUM] Consensus モード — B{seq} 決定のタイミング不整合

**ファイル**: `framework/claude/skills/sdd-roadmap/SKILL.md:115` vs `refs/review.md:74`

SKILL.md (Router) Consensus Mode:
```
Determine review scope directory (see `refs/review.md` Step 1) and B{seq} from `{scope-dir}/verdicts.md`
(increment max existing, or start at 1)
```

review.md Step 2:
```
Determine B{seq}: read `{scope-dir}/verdicts.md`, increment max existing batch number (or start at 1).
For consensus mode, B{seq} is determined once and shared across all N pipelines.
```

**問題点**: Router が B{seq} を自分で決定するよう記述されているが、review.md Step 2 でも B{seq} 決定手順がある。Consensus モード時に Router が先に B{seq} を決定し、review.md に渡す必要があるが、このハンドオフが明示されていない。

通常フロー (N=1) では review.md Step 2 が B{seq} を決定する。Consensus モード (N>1) では Router が決定して N パイプラインに共有するが、review.md Step 2 は「For consensus mode, B{seq} is determined once and shared」とあり、誰が決定するかが曖昧。

**推奨**: review.md に「Consensus mode の B{seq} は Router が決定して渡す」ことを明示する。

---

#### [MEDIUM] run.md Phase Handler — Design Review NO-GO フロー の未定義ケース

**ファイル**: `framework/claude/skills/sdd-roadmap/refs/run.md:178`

run.md §Design Review completion:
```
NO-GO → increment `retry_count`. Dispatch Architect with fix instructions. If Architect fails: escalate to user.
After fix: reset `orchestration.last_phase_action = null`, phase remains `design-generated`.
Re-run Design Review (max 5 retries, aggregate cap 6).
```

CLAUDE.md §Auto-Fix Counter Limits:
```
retry_count: max 5 (NO-GO only). spec_update_count: max 2 (SPEC-UPDATE-NEEDED only). Aggregate cap: 6.
```

**問題点**: run.md の Design Review NO-GO フローでは `retry_count` の exhaustion 後の動作 (escalation) が記述されていない。Impl Review の NO-GO フローには aggregate cap と escalation の説明があるが、Design Review NO-GO フローでは exhaustion 後の動作が欠落している。

Readiness Rules との関係:
```
Design Review | No GO/CONDITIONAL verdict in verdicts.md latest design batch (verdict absent or last is NO-GO).
```
retry 上限到達後に何が起きるかが design review フローでは不明確。

**推奨**: Design Review NO-GO フローに「max 5 retries 後: escalate to user」を明示する。

---

#### [MEDIUM] run.md Wave QG — Dead-Code Review の retry カウンター管理

**ファイル**: `framework/claude/skills/sdd-roadmap/refs/run.md:247`

run.md Step 7b (Dead Code Review) NO-GO フロー:
```
NO-GO → identify responsible Builder(s), re-dispatch with fix instructions, re-review
(max 3 retries, separate from per-spec aggregate cap → escalate)
```

CLAUDE.md §Auto-Fix Counter Limits:
```
Exception: Dead-Code Review NO-GO: max 3 retries (dead-code findings are simpler scope; exhaustion → escalate).
```

Dead-code review の 3 retry カウンターがどのフィールドに格納されるか、または格納されないか (一時的にメモリ上のみ) が両ファイルに記述されていない。「separate from per-spec aggregate cap」とあるため spec.yaml の `retry_count` とは別だが、カウンターの実体が不明。

**影響度**: LOW に近いが、resume 時の状態復元に影響する可能性がある。

---

#### [LOW] revise.md Part A Step 7 — pipeline resume 条件の曖昧さ

**ファイル**: `framework/claude/skills/sdd-roadmap/refs/revise.md:102`

revise.md Part A Step 7:
```
2. If roadmap run was in progress: resume from current position
```

「roadmap run was in progress」の判定方法が不明。CLAUDE.md §Session Resume では spec.yaml を ground truth として pipeline 状態を再構築するよう指示されている。revise.md はこの判定ロジックを参照していない。

**影響度**: 実害は少ないが、Lead の解釈に依存する部分が残る。

---

#### [LOW] revise.md Part B Step 7 — revise.md Counter reset タイミングと CLAUDE.md 整合

**ファイル**: `framework/claude/skills/sdd-roadmap/refs/revise.md:207-211`

revise.md Part B Step 7 (Tier Execution) Step 1:
```
Reset orchestration.retry_count = 0, spec_update_count = 0
```

CLAUDE.md §Auto-Fix Counter Limits:
```
Counter reset triggers: wave completion, user escalation decision, `/sdd-roadmap revise` start.
```

`/sdd-roadmap revise` start がトリガーとして正しく CLAUDE.md に記載されており、revise.md Part A Step 4 にも:
```
Reset `orchestration.retry_count = 0`, `orchestration.spec_update_count = 0`
```
と明示されている。Part B Step 7 も同様にリセットしており、整合している。

**問題なし** (確認のみ)。

---

#### [LOW] 1-spec ロードマップ最適化 — review dead-code の扱い

**ファイル**: `framework/claude/skills/sdd-roadmap/SKILL.md:87-90`

Router §1-Spec Roadmap Optimizations:
```
Skip wave-level dead-code review: User can still run `/sdd-roadmap review dead-code` manually
```

run.md Step 7b (Dead Code Review) では wave QG の一部として実行される。1-spec ロードマップでは Wave QG 自体をスキップするため、dead-code review も自動実行されない。ユーザーが手動で実行できる旨が記載されており、適切。

**問題なし** (確認のみ)。

---

#### [LOW] design.md refs — Session Resume 後の Phase Handler refs 参照

**ファイル**: `framework/claude/skills/sdd-roadmap/refs/run.md:171`

run.md §Design completion:
```
Execute per `refs/design.md` (Steps 1-3). After Architect completes, update spec.yaml per design.md Step 3.
```

design.md には Steps 1-3 が存在し (Step 1: Input Mode Detection, Step 2: Phase Gate, Step 3: Execute, Step 4: Post-Completion)、「Steps 1-3」という参照は Step 4 を除いたものとして解釈できる。ただし実際には Step 3 の「After Architect completion」部分 (spec.yaml 更新) のみが run.md から呼び出される動作であり、Step 1, 2 (Mode Detection, Phase Gate) は run.md のコンテキストでは Lead がすでに処理済み。

**軽微な曖昧さ**: 「Execute per refs/design.md (Steps 1-3)」は「dispatch Architect and handle completion per design.md Step 3」とより正確に表現できる。

---

### Confirmed OK

1. **Router → refs ディスパッチ完全性**: SKILL.md Detect Mode の全 subcommand (design/impl/review/run/revise/create/update/delete/-y) が正しい refs ファイルにルーティングされている。

2. **フェーズゲート一貫性**: CLAUDE.md で定義されたフェーズ (`initialized` → `design-generated` → `implementation-complete`、および `blocked`) が各 refs ファイルで一貫して使用されている。
   - design.md: initialized, design-generated, implementation-complete, blocked を処理
   - impl.md: design-generated, implementation-complete, blocked を処理
   - review.md: blocked を BLOCK、design/impl フェーズを検証
   - revise.md: implementation-complete を必須条件として確認

3. **Auto-fix ループ整合性 (Impl Review)**:
   - run.md: `retry_count` max 5, `spec_update_count` max 2, aggregate cap 6
   - CLAUDE.md: 同値が記載
   - CONDITIONAL = GO 扱いも両ファイルで一致

4. **Verdict Persistence フォーマット一貫性**:
   - SKILL.md §Verdict Persistence Format が正規定義
   - review.md は「see Router → Verdict Persistence Format」と参照
   - run.md Step 7a/7b は wave/verdicts.md への書き込みパスを明示
   - revise.md Part B Step 8 は cross-cutting 専用ディレクトリを使用
   - sdd-review-self は自前の verdicts.md を使用
   - 全て `{scope-dir}/verdicts.md` パターンに従っている

5. **Consensus モード — N=1 デフォルト動作**:
   - SKILL.md: `N=1 (default): use specs/{feature}/reviews/active/ (no -{p} suffix)`
   - review.md の通常フローと整合

6. **Inspector/Auditor 出力形式 (CPF) 一貫性**:
   - sdd-auditor-design: `VERDICT:{GO|CONDITIONAL|NO-GO}` (SPEC-UPDATE-NEEDED なし) — 設計レビューとして正しい
   - sdd-auditor-impl: `VERDICT:{GO|CONDITIONAL|NO-GO|SPEC-UPDATE-NEEDED}` — 実装レビューとして正しい
   - sdd-auditor-dead-code: `VERDICT:{GO|CONDITIONAL|NO-GO}` (SPEC-UPDATE-NEEDED なし) — デッドコードレビューとして正しい
   - Inspector 各ファイル: `VERDICT:{GO|CONDITIONAL|NO-GO}` を使用

7. **L1 fix 確認 (review.md Triggered by 行)**: dead-code の `{feature}` 引数が正しく除去されており、SKILL.md の detect pattern と整合している。

8. **L2 fix 確認 (revise.md Step 7 Design Fan-Out spec.yaml 更新)**: `After each Architect completes: update spec.yaml per design.md Step 3` が明示されており、design.md の Step 3 内容と整合している。

9. **Revise モード検出とエスカレーション**:
   - SKILL.md Detect Mode: `"revise <feature> [instructions]"` → Single-Spec Mode (Part A), `"revise [instructions]"` → Cross-Cutting Mode (Part B)
   - revise.md の Mode Detection と完全一致
   - Part A → Part B エスカレーション (2+ 影響 specs 検出時): Step 3 に明示されており、escalation パス (user accepts → join Part B Step 2) が完全

10. **Island Spec (Wave Bypass) — ファイル所有権競合検出**:
    - run.md: Fast-track と wave-bound の overlap 時は「demote the fast-track spec back to wave-bound and serialize」と明示
    - Layer 2 file ownership check との統合が記述されている

11. **Builder parallel coordination**:
    - CLAUDE.md: 「As each Builder completes, immediately update tasks.yaml, collect files, store knowledge tags. Final spec.yaml update only after ALL Builders complete.」
    - impl.md: 同じプロトコルが「Builder incremental processing」セクションで詳細に記述
    - 整合している

12. **Wave Context Generation (Step 2.5)**:
    - run.md Step 2.5 に conventions brief 生成手順が明示
    - 1-spec: `specs/{feature}/conventions-brief.md`
    - multi-spec: `specs/.wave-context/{wave-N}/conventions-brief.md`
    - revise.md Part B Step 7 にも同じ Step 2.5 参照がある

13. **Spec Stagger — Review Decomposition**:
    - run.md に DISPATCH-INSPECTORS / INSPECTORS-COMPLETE / AUDITOR-COMPLETE の 3 サブフェーズが明示
    - review.md との境界も「Standalone reviews use review.md's sequential flow as-is」と明確

14. **settings.json permissions 完全性**:
    - Task() エントリ: sdd-architect, sdd-auditor-{dead-code,design,impl}, sdd-builder, sdd-inspector-{all 12}, sdd-taskgenerator
    - 全エージェントファイルが framework/claude/agents/ に存在することを確認
    - Skill() エントリ: sdd-roadmap, sdd-steering, sdd-status, sdd-handover, sdd-release, sdd-review-self の 6 スキル全て

15. **Blocked spec 処理**:
    - CLAUDE.md: `phase=blocked` → BLOCK with "{feature} is blocked by {blocked_info.blocked_by}"
    - design.md, impl.md, review.md, revise.md 各 Phase Gate で BLOCK 処理が記載されている
    - run.md Step 6 Blocking Protocol でのブロック設定 (`blocked_info.blocked_by`, `blocked_info.reason`, `blocked_info.blocked_at_phase`) も明示

16. **Retry limit exhaustion — Impl Review**:
    - run.md: `max 5 retries, aggregate cap 6. Escalate at 6.`
    - CLAUDE.md: 同値
    - Wave QG cross-check でも「Max 5 retries per spec (aggregate cap 6 per spec)」と記述

17. **Steering Feedback Loop**:
    - CLAUDE.md: 「Auditor proposes CODIFY or PROPOSE via verdict. Process after handling verdict but before advancing」
    - review.md: §Steering Feedback Loop Processing に詳細処理ルールあり
    - run.md Phase Handler: 「Process STEERING: entries from verdict.」で両 Design/Impl Review 後に実行されることを明示

18. **Reader Clarity — refs の読み込みタイミング**:
    - SKILL.md §Execution Reference: 「After mode detection and roadmap ensure, Read the reference file for the detected mode: [list]. Then follow the instructions in the loaded file.」と明示されている

19. **Dead-Code Review retry カウンター CLAUDE.md との整合 (Exception 規定)**:
    - CLAUDE.md: 「Dead-Code Review NO-GO: max 3 retries」
    - run.md Step 7b: 「max 3 retries, separate from per-spec aggregate cap」
    - 数値・例外扱いが一致している

20. **Post-gate カウンターリセット**:
    - run.md Step 7c Post-gate: 「Reset counters: For each spec in wave: retry_count=0, spec_update_count=0」
    - CLAUDE.md リセットトリガー「wave completion」と整合

---

### Overall Assessment

**重大な問題**: なし。フレームワーク全体の Router → refs ディスパッチフローは概ね健全に機能する。

**主要な懸念事項 (HIGH 1件)**:
- M2 fix として run.md Step 6 (Blocking Protocol) にカウンターリセットが追加されたが、CLAUDE.md §Auto-Fix Counter Limits のリセットトリガーリストが更新されていない。CLAUDE.md は Lead の主要リファレンスであるため、情報源として不完全な状態。

**中程度の懸念事項 (MEDIUM 3件)**:
- Consensus モード B{seq} 決定の責任所在が Router と review.md の間で曖昧
- Design Review NO-GO フローで retry exhaustion 後の escalation が未記述
- Dead-code review の retry カウンターがどこに格納されるか未定義 (resume 時の問題)

**低影響の懸念事項 (LOW 3件)**:
- revise.md Part A Step 7 の roadmap resume 判定が曖昧
- design.md の「Steps 1-3」参照が dispatch コンテキストでやや不正確
- (revise.md カウンターリセットは問題なし — 確認のみ)

**Focus Targets の評価**:
- M2 (run.md Step 6 Blocking Protocol カウンターリセット): fix は run.md に適切に追加されているが、CLAUDE.md 側との同期が欠落 → HIGH 指摘
- L1 (review.md Triggered by 行 dead-code 引数修正): 正しく修正済み → 問題なし
- L2 (revise.md Step 7 Design Fan-Out spec.yaml 更新明示): 正しく追加済み → 問題なし

**推奨優先度**:
1. CLAUDE.md §Auto-Fix Counter Limits にブロッキングプロトコルのカウンターリセットを追記 (HIGH)
2. review.md に Consensus B{seq} 決定責任を明示 (MEDIUM)
3. run.md §Design Review NO-GO に exhaustion 後のエスカレーションを追記 (MEDIUM)
