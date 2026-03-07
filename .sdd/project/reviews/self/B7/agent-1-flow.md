## Flow Integrity Report

### Issues Found

- [MEDIUM] Router → refs/review.md: `review dead-code` のサブコマンド書式不整合 / review.md Step 1 triggers
- [MEDIUM] Revise Cross-Cutting Mode: Step 7 Tier Execution の State Transition で `phase = design-generated` に設定しているが、直後に Design Fan-Out で Architect を dispatch しており、design.md Step 2 Phase Gate の `design-generated` パスでは「proceed」になるので機能的に正しいが、revise.md 固有の意図（implementation-complete から戻す）と文面の整合が曖昧
- [LOW] CLAUDE.md Inspector 数表記 "6 impl +2 web" vs review.md の実際の Inspector リスト (6 standard + 2 web) は一致しているが、dead-code は CLAUDE.md で "4 dead-code" と書きつつ review.md の Dead-Code Review セクションでも 4 Inspector を列挙しており、これは整合
- [LOW] Verdict Persistence Format: SKILL.md Router の Disposition 値 `NO-GO-FIXED` は run.md / revise.md の auto-fix loop 完了後に Lead が設定する想定だが、この Disposition 値のセマンティクスを明示的に定義しているファイルが Router のみ

### Confirmed OK

- Router dispatch completeness: 全 subcommand が正しい ref にルーティングされている
- Phase gate consistency: 各 ref の Phase Gate が CLAUDE.md の phase 定義と整合
- Auto-fix loop: NO-GO / SPEC-UPDATE-NEEDED の処理が refs と CLAUDE.md 間で一貫
- Wave quality gate: 完全なフロー（Cross-Check → Dead-Code → Post-gate）
- Consensus mode: 矛盾なし
- Verdict persistence: 全レビュータイプで一貫したフォーマット
- Edge cases: 1-spec / blocked / retry exhaustion の処理完備
- Read clarity: Router が refs を読むタイミングが明示
- Revise modes: Single-Spec / Cross-Cutting の Detect Mode と escalation path が正常
- 未コミット変更: Session Resume Step 7 / Behavioral Rules の改訂は整合的

### Overall Assessment

フレームワーク全体のフロー整合性は良好。重大な断絶や矛盾は検出されなかった。

---

## 詳細分析

### 1. Router Dispatch Completeness (全サブコマンドのルーティング検証)

SKILL.md (Router) の Step 1: Detect Mode で定義される全サブコマンドと、Step 2 の Execution Reference セクションの ref ファイルマッピングを照合した。

| サブコマンド | 検出モード | ルーティング先 | 検証結果 |
|---|---|---|---|
| `design {feature}` | Design Subcommand | `refs/design.md` | OK |
| `impl {feature} [tasks]` | Impl Subcommand | `refs/impl.md` | OK |
| `review design {feature}` | Review Subcommand | `refs/review.md` | OK |
| `review impl {feature} [tasks]` | Review Subcommand | `refs/review.md` | OK |
| `review dead-code` | Review Subcommand | `refs/review.md` | OK |
| `review {type} --consensus N` | Review Subcommand | `refs/review.md` | OK |
| `review design --cross-check` | Review Subcommand | `refs/review.md` | OK |
| `review impl --cross-check` | Review Subcommand | `refs/review.md` | OK |
| `review design --wave N` | Review Subcommand | `refs/review.md` | OK |
| `review impl --wave N` | Review Subcommand | `refs/review.md` | OK |
| `run` / `run --gate` / `run --consensus N` | Run Mode | `refs/run.md` | OK |
| `revise {feature} [instructions]` | Revise Mode (Single-Spec) | `refs/revise.md` | OK |
| `revise [instructions]` | Revise Mode (Cross-Cutting) | `refs/revise.md` | OK |
| `create` / `create -y` | Create Mode | `refs/crud.md` | OK |
| `update` | Update Mode | `refs/crud.md` | OK |
| `delete` | Delete Mode | `refs/crud.md` | OK |
| `-y` | Auto-detect | Router 内処理 | OK |
| `""` (空) | Auto-detect | Router 内処理 | OK |

**結論**: 全サブコマンドが正しい ref にルーティングされている。漏れなし。

### 2. Phase Gate Consistency (Phase Gate の整合性)

CLAUDE.md で定義されるフェーズ:
- `initialized` -> `design-generated` -> `implementation-complete`
- `blocked`

各 ref ファイルの Phase Gate を CLAUDE.md と照合:

**refs/design.md Step 2**:
- `blocked` -> BLOCK (CLAUDE.md と一致)
- `implementation-complete` -> warn + confirm (revise 提案付き)
- `initialized` / `design-generated` -> proceed
- 未知フェーズ -> BLOCK "Unknown phase"

**refs/impl.md Step 1**:
- `blocked` -> BLOCK (一致)
- `design-generated` -> proceed (一致)
- `implementation-complete` -> proceed (re-execution)
- その他 -> BLOCK "Phase is '{phase}'"

**refs/review.md Step 2**:
- Design Review: `design.md` 存在確認 + `blocked` BLOCK
- Impl Review: `design.md` + `tasks.yaml` 存在確認 + `phase == implementation-complete` + `blocked` BLOCK
- Dead-Code: No phase gate (正当)

**refs/revise.md Step 1**:
- `implementation-complete` のみ許可
- `blocked` -> BLOCK

**結論**: 全 ref の Phase Gate が CLAUDE.md のフェーズ定義と整合している。`blocked` は全箇所で適切にブロックされ、未知フェーズは design.md で明示的にハンドルされている。impl.md の「その他 -> BLOCK」は暗黙的に未知フェーズもカバーしている。

### 3. Auto-Fix Loop Consistency (自動修正ループの整合性)

**CLAUDE.md の定義**:
- `retry_count`: max 5 (NO-GO)
- `spec_update_count`: max 2 (SPEC-UPDATE-NEEDED)
- Aggregate cap: 6
- Dead-Code: max 3
- CONDITIONAL = GO (proceed)
- Counter reset: wave completion, user escalation, `/sdd-roadmap revise` start

**refs/run.md Phase Handlers**:
- Design Review NO-GO: `retry_count` increment, max 5, aggregate cap 6 -- 一致
- SPEC-UPDATE-NEEDED at Design Review: "not expected, escalate immediately" -- 合理的
- Impl Review NO-GO: `retry_count` increment, max 5 -- 一致
- Impl Review SPEC-UPDATE-NEEDED: `spec_update_count` increment, max 2, cascade -- 一致
- "Total cycles (retry_count + spec_update_count) MUST NOT exceed 6" -- 一致
- GO/CONDITIONAL: "counters NOT reset" -- 一致

**refs/run.md Wave QG**:
- Cross-Check NO-GO: max 5 retries (aggregate cap 6) -- 一致
- Dead-Code NO-GO: max 3 retries -- 一致

**refs/run.md Post-gate**:
- Counter reset: `retry_count=0`, `spec_update_count=0` -- 一致（wave completion reset）

**refs/revise.md Step 4**:
- Counter reset: `retry_count=0`, `spec_update_count=0` -- 一致（revise start reset）

**結論**: 完全に整合。全カウンタ制限と reset トリガーが CLAUDE.md と refs 間で一致している。

### 4. Wave Quality Gate Flow (Wave QG フロー)

refs/run.md Step 7 の Wave QG フロー:
1. **1-Spec Roadmap**: Skip (Router の 1-Spec Optimizations と一致)
2. **a. Impl Cross-Check Review**: wave-scoped、verdict persistence `[W{wave}-B{seq}]`
3. **b. Dead Code Review**: verdict persistence `[W{wave}-DC-B{seq}]`
4. **c. Post-gate**: Counter reset + Knowledge flush + Commit + session.md

CLAUDE.md §Parallel Execution Model は "Wave QG" に言及し、run.md Step 7 を参照。

**結論**: Wave QG フローは完全。全ステップが定義され、verdict persistence format も一貫している。

### 5. Consensus Mode (コンセンサスモード)

Router (SKILL.md) の Shared Protocols §Consensus Mode で定義:
- N パイプライン並列、threshold ⌈N×0.6⌉
- `active-{p}/` ディレクトリ分離
- Auditor は各パイプラインの `active-{p}/verdict.cpf` に書き込み
- 集約: frequency-based consensus
- Archive: `B{seq}/pipeline-{p}/`
- N=1: suffix なし (`active/`)

refs/review.md Step 9:
- "If `--consensus N`, apply Consensus Mode protocol (see Router)." -- Router 参照

refs/run.md:
- Design Review / Impl Review のハンドラで: "For `--consensus N`, apply Consensus Mode protocol (see Router)." -- 一致

CLAUDE.md §SubAgent Platform Constraints:
- "Consensus mode (`--consensus N`) dispatches N pipelines in parallel." -- 一致

**結論**: コンセンサスモードに矛盾なし。Router が canonical source として正しく参照されている。

### 6. Verdict Persistence Format (判定永続化フォーマット)

Router (SKILL.md) の §Verdict Persistence Format:
- Header: `## [B{seq}] {review-type} | {timestamp} | v{version} | runs:{N} | threshold:{K}/{N}`
- Sections: Raw, Consensus, Noise, Disposition, Tracked, Resolved
- Disposition 値: `GO-ACCEPTED`, `CONDITIONAL-TRACKED`, `NO-GO-FIXED`, `SPEC-UPDATE-CASCADED`, `ESCALATED`

refs/review.md Step 8:
- "Persist verdict to `{scope-dir}/verdicts.md` (see Router → Verdict Persistence Format)" -- Router 参照

refs/review.md §Verdict Destination by Review Type:
- Single-spec: `specs/{feature}/reviews/verdicts.md`
- Dead-code: `project/reviews/dead-code/verdicts.md`
- Cross-check: `project/reviews/cross-check/verdicts.md`
- Wave-scoped: `project/reviews/wave/verdicts.md`
- Cross-cutting: `specs/.cross-cutting/{id}/verdicts.md`
- Self-review: `project/reviews/self/verdicts.md`

run.md Step 7:
- Cross-Check verdict: `project/reviews/wave/verdicts.md` (header `[W{wave}-B{seq}]`) -- 一致
- Dead-Code verdict: `project/reviews/wave/verdicts.md` (header `[W{wave}-DC-B{seq}]`) -- 一致

revise.md Step 8 (Cross-Cutting Consistency Review):
- verdict: `specs/.cross-cutting/{id}/verdicts.md` -- 一致

**結論**: Verdict persistence format は全レビュータイプで一貫している。

**[LOW] 注意点**: Disposition 値のセマンティクス（`NO-GO-FIXED` = auto-fix 完了後に設定、`SPEC-UPDATE-CASCADED` = spec 更新カスケード完了後等）は Router のみで暗黙的に定義されており、refs で明示的に「この Disposition を設定する」という記述はない。Lead の判断に委ねられているが、機能的に問題はない。

### 7. Edge Cases (エッジケース)

**空の roadmap**:
- Router: `review dead-code`, `review --cross-check`, `review --wave N` で roadmap なし -> BLOCK (正常)
- 他のサブコマンドは 1-spec roadmap を auto-create (正常)

**1-Spec Roadmap**:
- Router §1-Spec Roadmap Optimizations: Wave QG スキップ、cross-check スキップ、commit format `{feature}: {summary}`
- run.md Step 7: "1-Spec Roadmap: Skip this step" -- 一致
- review.md: 1-Spec guard for cross-check/wave review -- 一致
- impl.md Step 4: 1-spec のみ Knowledge flush -- 正常

**Blocked spec**:
- design.md, impl.md, review.md, revise.md: 全て `blocked` を BLOCK -- 一致
- run.md Step 6 Blocking Protocol: downstream spec を blocked に設定 + 復旧フロー -- 完全

**Retry limit exhaustion**:
- run.md: "Escalate at 6" + Blocking Protocol -- 一致
- Dead-Code: max 3 -> escalate -- 一致
- 3つのオプション (fix / skip / abort) -- 完全

**結論**: エッジケースは適切にハンドルされている。

### 8. Read Clarity (refs 読み込みタイミング)

Router (SKILL.md) §Execution Reference:
```
After mode detection and roadmap ensure, Read the reference file for the detected mode:
- Design → Read refs/design.md
- Impl → Read refs/impl.md
- Review → Read refs/review.md
- Run → Read refs/run.md
- Revise → Read refs/revise.md
- Create / Update / Delete → Read refs/crud.md
Then follow the instructions in the loaded file.
```

**明確にステップ化されている**: Mode Detection → Roadmap Ensure → Read ref → Execute

各 ref ファイルの冒頭:
- design.md: "Phase execution reference. Assumes Single-Spec Roadmap Ensure already completed by router."
- impl.md: "Phase execution reference. Assumes Single-Spec Roadmap Ensure already completed by router."
- review.md: "Phase execution reference. Canonical source for ALL review types. Assumes Single-Spec Roadmap Ensure already completed by router (except dead-code/cross-check/wave which skip enrollment)."
- run.md: "Orchestration reference. Lead handles pipeline execution directly."
- revise.md: "Orchestration reference. Two modes: Single-Spec and Cross-Cutting."
- crud.md: "Interactive operations reference. Lead handles directly."

**結論**: 読み込みタイミングは明示的かつ一貫している。

### 9. Revise Modes (改訂モード)

**SKILL.md Detect Mode**:
```
"revise {feature} [instructions]" → Revise Mode (Single-Spec)
"revise [instructions]"           → Revise Mode (Cross-Cutting)
```

**refs/revise.md Mode Detection**:
```
"revise <feature> [instructions]"  → feature matches known spec name → Single-Spec Mode (Part A)
"revise [instructions]"            → no feature name               → Cross-Cutting Mode (Part B)
```

Router と revise.md の Mode Detection は整合。feature 名の判定ロジック（既知 spec 名かどうか）は revise.md 側で具体化されている。

**Escalation path**:
- Part A Step 3: 2+ specs 影響 -> Cross-Cutting 提案 -> User accepts -> Part B Step 2 に join
- Part A Step 6: downstream resolution で option (d) -> Part B Step 2 に join
- 両方のエスカレーションパスが `decisions.md` に記録 (`DIRECTION_CHANGE`)

**CLAUDE.md との整合**:
- `REVISION_INITIATED` decision type: 定義済み、`(cross-cutting)` suffix 付き
- Counter reset: revise.md Step 4 で `retry_count=0, spec_update_count=0` -- CLAUDE.md §Auto-Fix Counter Limits と一致
- Commit format: revise.md Step 9 で `cross-cutting: {summary}` -- CLAUDE.md §Commit Timing と一致

**結論**: Revise modes のルーティングとエスカレーションパスは正常に機能する。

### 10. 未コミット変更の影響分析

**変更1: Session Resume Step 7 の改訂**

旧:
```
7. Resume from session.md Immediate Next Action (or await user instruction if first session)
```

新:
```
7. If roadmap pipeline was active (session.md indicates run/revise in progress):
     - Continue pipeline from spec.yaml state. Treat spec.yaml as ground truth.
     - Do NOT manually update spec.yaml to "recover" or "fix" perceived inconsistencies.
     - If spec.yaml state vs actual artifacts seem inconsistent: report to user, do not auto-fix.
   Otherwise: await user instruction.
```

**フロー整合性への影響**: run.md §Pipeline Stop Protocol の "Resume: `/sdd-roadmap run` scans all spec.yaml files to rebuild pipeline state" と整合。spec.yaml を ground truth として扱う原則が両方で一致。revise.md も同様に spec.yaml ベースで再開可能。

**変更2: Behavioral Rules の改訂**

旧:
```
- After a compact operation, ALWAYS wait for the user's next instruction.
- Do not continue or resume previously in-progress tasks after compact unless the user explicitly instructs you to do so.
```

新:
```
- After a compact operation: If a roadmap pipeline (run/revise) was in progress, perform Session Resume steps 1-6 to reload context, then continue the pipeline from spec.yaml state.
- Do not continue or resume non-pipeline tasks after compact unless the user explicitly instructs you to do so.
```

**フロー整合性への影響**: Session Resume Step 7 の変更と整合。pipeline 実行中の compact では自動再開し、非 pipeline タスクでは user 指示を待つ。この区別は合理的で、run.md / revise.md のパイプラインフローと矛盾しない。

**変更3: Builder に "No workspace-wide git operations" 制約追加**

`git stash`, `git checkout .`, `git restore .`, `git reset`, `git clean` を禁止。ファイルスコープ内の `git checkout -- <file>` のみ許可。

**フロー整合性への影響**: Builder の File Scope Rules と一致。並列 Builder 実行時に他の Builder や Lead が管理する spec.yaml / design.md を破壊するリスクを排除。run.md の Builder parallel coordination と整合。

**結論**: 3つの未コミット変更は全てフロー整合性を維持しており、既存のプロトコルと矛盾しない。

---

### [MEDIUM] 検出事項の詳細

#### M1: `review dead-code` のルーティング書式

SKILL.md Step 1 の Detect Mode:
```
$ARGUMENTS = "review dead-code"              → Review Subcommand
```

review.md の Triggered by 行:
```
Triggered by: $ARGUMENTS = "review design|impl|dead-code {feature} [options]"
```

ここで `review dead-code` は `{feature}` を取らない（codebace全体が対象）。しかし Triggered by 行の書式は `{feature}` が必須に見える。実際には review.md Step 1 で parse 処理が行われ、dead-code の場合は feature 不要として処理される。review.md Step 2 でも Dead-Code Review は "No phase gate" と明示されており、機能的に正しいが、Triggered by 行の書式が dead-code の実態を正確に反映していない。

**影響**: 軽微。Lead が review.md を読んだ際に混乱する可能性は低いが、正確性のためには `review design|impl {feature} [options]` と `review dead-code` を Triggered by で分けて記載するのが理想的。

#### M2: Revise Cross-Cutting Tier Execution の State Transition

revise.md Step 7 Tier Execution:
```
1. State Transition (per spec):
   - Reset orchestration.retry_count = 0, spec_update_count = 0
   - Reset orchestration.last_phase_action = null
   - Set phase = design-generated
```

直後:
```
2. Design Fan-Out:
   - Dispatch Architects in parallel (run_in_background: true)
```

ここで `phase = design-generated` に設定してから Architect を dispatch しているが、design.md Step 2 Phase Gate では:
- `design-generated` -> "no phase restriction" (proceed)

なので機能的に正しい。しかし revise.md の文脈では `implementation-complete` から戻すための状態遷移であり、Architect 実行後に再度 `phase = design-generated` + `last_phase_action = null` が design.md Step 3 で設定される。つまり State Transition での `phase = design-generated` 設定は、Architect dispatch 前の準備として冗長ではないが、意図が曖昧。

Single-Spec Mode (Part A Step 4) では同じ処理を行っているので、パターンとしては一貫している。

**影響**: 軽微。Lead がフローを正しく追える範囲内。
