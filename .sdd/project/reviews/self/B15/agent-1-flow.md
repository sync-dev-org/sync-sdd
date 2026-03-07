## Flow Integrity Report

**対象バージョン**: v1.5.3
**レビュー日**: 2026-02-28
**Agent**: Agent 1 — フロー整合性レビュー

---

### Issues Found

#### [HIGH] revise.md Part A Step 4 でフェーズが誤って設定される

**説明**: `refs/revise.md` Part A Step 4 において、State Transition で `phase = design-generated` に設定している。しかし CLAUDE.md の Phase-Driven Workflow では「Revision: `implementation-complete` → `design-generated` → (full pipeline) → `implementation-complete`」と定義しており、この遷移は正しい。問題は Step 5（Execute Pipeline）の Design ステップ説明：

> "After completion: verify design.md, update spec.yaml (increment `version`, phase=design-generated, last_phase_action=null)"

`refs/design.md` Step 3 では Architect 完了後に `phase = design-generated` を設定すると書かれており、Step 4 の State Transition でも `phase = design-generated` を先設定している。つまり Design が完了する前に `design-generated` に設定され、実行途中の状態が `design-generated` に見える。これは Step 5 の Design Review Readiness Rule（`phase is design-generated`）により、Architect がまだ実行中の段階で Design Review がトリガー可能になる潜在的競合状態を生む。

**場所**: `framework/claude/skills/sdd-roadmap/refs/revise.md:63-65` / Step 4 と Step 5

**補足**: 実際には Part A は `refs/run.md` の Dispatch Loop を経由しないため単一スレッドで実行されリスクは限定的だが、Part B（Cross-Cutting）は Dispatch Loop パターンを使用するため、Tier Execution Step 1 で先に `phase = design-generated` に設定するとLoop の Readiness Rule が誤って Design Review eligible と判定する可能性がある。

---

#### [HIGH] revise.md Part B Tier Execution: Design Review の NO-GO ハンドリングが未定義

**説明**: `refs/revise.md` Part B Step 7（Tier Execution）のステップ 4（Design Review）では:

> "Handle verdicts per CLAUDE.md counter limits"

と書かれているが、NO-GO の場合の具体的なフロー（Architect 再ディスパッチ、retry_count インクリメント等）が明示されていない。`refs/run.md` Phase Handlers には NO-GO → Architect with fix instructions → re-run Design Review と詳述されているが、`refs/revise.md` Step 7 からはそれを参照するような記述がなく、LeadがどのPhase Handlerを使うか曖昧。

`refs/run.md` Step 4（Dispatch Loop）の Review Decomposition が参照されているのは Tier Execution Step 7 コメント（"Follows run.md Dispatch Loop pattern"）のみで、`refs/run.md` の Phase Handlers セクション（NO-GO/SPEC-UPDATE-NEEDED フロー詳細）への明示的参照がない。

**場所**: `framework/claude/skills/sdd-roadmap/refs/revise.md:229,243` — Step 7, steps 4 and 6

---

#### [MEDIUM] Revise Mode: 単一スペックか Cross-Cutting かの判別が SKILL.md の引数パースに依存するが曖昧なケースがある

**説明**: `SKILL.md` Step 1 Detect Mode に:

```
"revise <feature> [instructions]"  → feature matches known spec name → Single-Spec Mode
"revise [instructions]"            → no feature name match           → Cross-Cutting Mode
```

と定義されている。しかし「revise」の後の最初の単語が既存スペック名と偶然一致する自然言語の指示（例: `revise auth service should be extracted`）では `auth` がスペック名に一致した場合、Cross-Cutting として扱うべき変更が Single-Spec として誤解される。

`refs/revise.md` Mode Detection では同じ仕様だが「first word after "revise" against existing spec names」と記述しており、`SKILL.md` のパースロジックとの一致は確認できる。ただし、この曖昧さに対するフォールバック（ユーザーへの確認等）は定義されていない。

**場所**: `framework/claude/skills/sdd-roadmap/SKILL.md:34-35` / `refs/revise.md:8-11`

---

#### [MEDIUM] Wave QG の Dead-Code Review NO-GO: retry_count が spec.yaml に永続化されない

**説明**: CLAUDE.md Auto-Fix Counter Limits:

> "Dead-Code Review NO-GO: max 3 retries (dead-code findings are simpler scope; exhaustion → escalate)."

`refs/run.md` Step 7b では:

> "re-review (max 3 retries, tracked in-memory by Lead — not persisted to spec.yaml. Dead-code findings are wave-scoped and resolved within a single execution window; counter restarts at 0 on session resume."

この「counter restarts at 0 on session resume」の動作が CLAUDE.md に記述されていない。CLAUDE.md は dead-code 3-retry 例外を記述しているが、セッション再開時のリセット動作については触れていない。セッション中断後に再開した場合、Lead は dead-code retry カウンターを 0 から再開するが、これが意図的設計であることが CLAUDE.md から判断できない。

**場所**: `framework/claude/CLAUDE.md` Auto-Fix Counter Limits セクション / `refs/run.md:248`

---

#### [MEDIUM] review.md Standalone Verdict Handling: STEERING エントリの処理でパイプライン進行がブロックされる定義が曖昧

**説明**: `refs/review.md` Steering Feedback Loop Processing の表：

| Level | Action | Blocks pipeline |
|-------|--------|----------------|
| `CODIFY` | Update directly | No |
| `PROPOSE` | Present to user | Yes |

Standalone review（`/sdd-roadmap review design {feature}`）では「No auto-fix」と定義されているが、PROPOSE の「Blocks pipeline」は何を指すのか。Standalone context では pipeline が存在しない。PROPOSE に対しユーザーが応答しない場合の動作（タイムアウト、スキップ）が未定義。

**場所**: `framework/claude/skills/sdd-roadmap/refs/review.md:105-117`

---

#### [MEDIUM] Consensus Mode: B{seq} の二重計算リスク

**説明**: `refs/review.md` Step 2:

> "For consensus mode: Router determines B{seq} once and passes it to all N pipelines (this step uses the Router-provided value instead of computing its own)."

一方 `SKILL.md` Consensus Mode Step 1:

> "Determine review scope directory (see `refs/review.md` Step 1) and B{seq} from `{scope-dir}/verdicts.md` (increment max existing, or start at 1)"

Router（SKILL.md）が B{seq} を決定して review.md に渡すフローは正しい。しかし SKILL.md では「Step 1」として記述されており、これが review.md Step 2 の「Router-provided value」と同一であることの対応関係が明示されていない（参照先の記述が曖昧）。並行パイプラインが同時に verdicts.md を読んだ場合に B{seq} の衝突が発生しないよう、Router が先に B{seq} を決定・ロックする必要があるが、その排他制御メカニズムが明示されていない。

**場所**: `framework/claude/skills/sdd-roadmap/SKILL.md:115-127` / `refs/review.md:74`

---

#### [MEDIUM] sdd-reboot SKILL.md と refs/reboot.md: Phase 9 の「Iterate」選択後の動作が SKILL.md に記載なし

**説明**: `refs/reboot.md` Phase 9:

> "Iterate: Skill terminates. User continues editing on the branch. Re-run `/sdd-reboot` to resume."

しかし `sdd-reboot/SKILL.md` Step 2 の Phase 9 説明:

> "Final Report & User Decision: Present report, user chooses Accept/Iterate/Reject"

では Iterate の動作詳細が記載されていない。SKILL.md は概要のみで詳細は refs/reboot.md を参照する設計だが、Error Handling テーブルにも Iterate ケースがなく、ユーザーが SKILL.md のみを見た場合に Iterate 後の状態が不明。

**場所**: `framework/claude/skills/sdd-reboot/SKILL.md:36-42` Error Handling テーブル

---

#### [LOW] design.md Phase Gate: `implementation-complete` でのユーザー確認後 reject 時に decisions.md への記録がない

**説明**: `refs/design.md` Step 2:

> "If `spec.yaml.phase` is `implementation-complete`: warn user that re-designing will invalidate existing implementation. Use AskUser to confirm... If rejected, abort."

abort 時に `USER_DECISION` を decisions.md に記録する指示がない。CLAUDE.md では USER_DECISION は「when user makes an explicit choice」に記録すると定義されており、reject も明示的選択。`refs/revise.md` Part A Step 5 では「On rejection → abort, record `USER_DECISION` in decisions.md」と明示されているが、design.md の同等フローでは省略されている。

**場所**: `framework/claude/skills/sdd-roadmap/refs/design.md:18`

---

#### [LOW] run.md Step 7 Wave QG: SPEC-UPDATE-NEEDED でのカスケード後の cross-check 再実行タイミングが不明確

**説明**: `refs/run.md` Step 7a:

> "SPEC-UPDATE-NEEDED → identify target spec(s), increment `spec_update_count`, cascade: Architect → TaskGenerator → Builder → individual Impl Review → re-run cross-check"

この「individual Impl Review」は単一スペックのレビューを指すが、それが GO/CONDITIONAL になった後に cross-check を re-run するのか、それとも SPEC-UPDATE-NEEDED の cascade 全体が完了した後に re-run するのかが文脈から判断しにくい。`refs/run.md` Phase Handlers の SPEC-UPDATE-NEEDED フローでは「re-run Impl Review」→「spec becomes `implementation-complete`」→「dispatch loop ADVANCE re-evaluates」というフローが示唆されるが、Wave QG コンテキストでの cross-check 再実行タイミングは明示されていない。

**場所**: `framework/claude/skills/sdd-roadmap/refs/run.md:241`

---

#### [LOW] refs が存在しないパス参照: sdd-reboot SKILL.md の「refs/reboot.md」

**説明**: `sdd-reboot/SKILL.md`:

> "Read and follow `refs/reboot.md` for the complete 10-phase execution"

`refs/reboot.md` は実際に `framework/claude/skills/sdd-reboot/refs/reboot.md` として存在しており問題なし。ただし SKILL.md に記述されている「10-phase execution」と refs/reboot.md の実際のフェーズ数が一致するか確認すると、Phase 1〜10 が定義されており一致。問題なし（念のため確認済み）。

**場所**: 問題なし（記録のみ）

---

### Confirmed OK

- **Router dispatch completeness**: design/impl/review/run/revise/create/update/delete の全サブコマンドが正しく refs にルーティングされている。SKILL.md Step 1 の Detect Mode は全パターンを網羅し、「After mode detection and roadmap ensure, Read the reference file」という明示的な読み込みトリガーがある。
- **Phase gate consistency**: CLAUDE.md の3フェーズ定義（`initialized` → `design-generated` → `implementation-complete` + `blocked`）が design.md、impl.md、run.md の各 Phase Gate と一致している。
- **Auto-fix loop基本フロー**: NO-GO max 5 retries、SPEC-UPDATE-NEEDED max 2 の上限が CLAUDE.md と refs/run.md Phase Handlers で一致。Aggregate cap 6 も一致。
- **Wave QG フロー完全性**: Step 7a（Impl Cross-Check）→ Step 7b（Dead-Code Review）→ Step 7c（Post-gate: reset counters + commit）の順序が明確。
- **1-spec roadmap 最適化**: SKILL.md と run.md の両方で Wave QG skip、Cross-check skip、コミットメッセージ形式変更（`{feature}: {summary}`）が一致して定義されている。
- **Verdict persistence format**: SKILL.md の Verdict Persistence Format セクションが review.md からも参照され（"see Router → Verdict Persistence Format"）、一貫した形式。
- **Consensus mode 基本フロー**: N パイプライン並行実行、Threshold ⌈N×0.6⌉、active-{p}/ ディレクトリ分離、B{seq}/pipeline-{p}/ アーカイブが SKILL.md と review.md で一致。
- **Blocked spec ハンドリング**: CLAUDE.md の Phase Gate（blocked → BLOCK）が design.md、impl.md で実装され、run.md Step 6 Blocking Protocol が詳細フロー（downstream 特定、options 提示、unblock 手順）を定義。
- **Revise Single-Spec → Cross-Cutting エスカレーション**: revise.md Part A Step 3 の「2+ specs affected → propose Cross-Cutting」から Part B Step 2 への join が明示されている。Cross-Cutting → Single-Spec のダウングレードは想定されない（正しい）。
- **Verdict destination by review type**: review.md に全タイプの verdicts.md パスが集約されており一貫している。self-review パスも含む。
- **SubAgent の spec.yaml 非更新ルール**: CLAUDE.md、architect.md、builder.md、taskgenerator.md で「Do NOT update spec.yaml」が明示されており一致。
- **Builder 並行 coordination**: impl.md の pilot stagger、taskyaml 更新（done marking）、files 集約後の spec.yaml 更新順序が明示されている。
- **Read clarity**: SKILL.md では「After mode detection and roadmap ensure, Read the reference file for the detected mode」と明示。各 ref には「Assumes Single-Spec Roadmap Ensure already completed by router」の注記があり、読み込みタイミングが明確。
- **inspector 並行ディスパッチ**: run.md Review Decomposition と review.md Review Execution Flow の両方で「spawn all Inspectors via Task(run_in_background=true)」が定義され一致。
- **CPF フォーマット**: cpf-format.md の仕様が auditor/inspector 各エージェントの Output Format と一致している。
- **sdd-reboot Phase 10 削除確認ゲート**: reboot.md Phase 10 で Deletion confirmation（Delete/Skip/Cancel）が定義されており、CLAUDE.md の Phase 10 説明と一致。
- **settings.json の Task() 権限**: 全 24 エージェント（sdd-analyst, sdd-architect, sdd-auditor-dead-code, sdd-auditor-design, sdd-auditor-impl, sdd-builder, sdd-conventions-scanner, 全 Inspector 系 17）が settings.json の allow リストに含まれている。
- **ConventionsScanner 2モード**: Generate / Supplement の両モードが agent 定義に明示されており、呼び出し元（run.md Step 2.5、impl.md Pilot Stagger）の dispatch prompt と一致。
- **Design Lookahead**: run.md の Lookahead は「wave N+1 deps all `design-generated`」条件で動的評価、staleness guard（NO-GO 後の無効化）も定義されており、reboot.md の Dispatch Loop でも同じルールが参照されている。

---

### Overall Assessment

**全体評価**: フレームワーク全体のフロー整合性は高い水準にある。Router → refs のディスパッチは全サブコマンドで正しく定義され、フェーズゲート・カウンター上限・判決永続化のコアロジックは CLAUDE.md と各 ref の間で一致している。

**主要懸念点**:

1. **HIGH x2**: Cross-Cutting Mode（revise.md Part B）の Tier Execution において、フェーズ遷移の競合状態リスクと Design Review NO-GO フロー詳細への参照欠如がある。これらは multi-spec cross-cutting 改訂を実行した場合に Lead の判断が曖昧になるリスクを生む。

2. **MEDIUM x4**: Consensus mode の B{seq} 排他制御の非明示化、Standalone review の PROPOSE ブロッキング定義の不明確さ、Dead-code retry カウンターのセッション再開リセット動作の CLAUDE.md 非記述、revise 引数パースの曖昧ケース。これらはいずれも edge case だが、修正することでドキュメントの完全性が向上する。

3. **LOW x2**: decisions.md 記録の省略（design.md abort）、Wave QG SPEC-UPDATE-NEEDED 後の cross-check タイミング。運用上の影響は小さい。

**推奨アクション（優先度順）**:
1. `refs/revise.md` Part B Step 7 に `refs/run.md` Phase Handlers（NO-GO/SPEC-UPDATE-NEEDED）への明示的参照を追加
2. `refs/revise.md` Part B Step 1 の State Transition（`phase = design-generated` 先設定）が Dispatch Loop Readiness Rule と競合しないよう、タイミングを Architect 完了後に移動するかコメントで明示
3. CLAUDE.md Auto-Fix Counter Limits に dead-code セッション再開リセット動作を補足記載
4. `refs/design.md` Step 2 abort 時の `USER_DECISION` 記録を追加
