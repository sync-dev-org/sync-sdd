## Flow Integrity Report

---

### Issues Found

#### [MEDIUM] Design Subcommand: `implementation-complete` フェーズのPhase Gate処理に不整合の可能性 / `refs/design.md:17-18`

`refs/design.md` Step 2 のフェーズゲートでは `implementation-complete` の場合に「警告して再設計確認を求める」と定義しているが、`refs/revise.md` Part A Step 1 では「revision は `implementation-complete` のspecのみが対象」と定義しており競合しない。ただし、design.md では警告後ユーザーが拒否した場合の処理として「abort」とのみ記載しており、その後のspec.yaml状態（フェーズが変わらない点）が明示されていない。実害は少ないが、処理後の状態が曖昧。

---

#### [MEDIUM] `refs/revise.md` Part A Step 4: フェーズ遷移でphaseが `design-generated` にセットされるが、design Subcommandでは `initialized` → `design-generated` が標準フロー / `refs/revise.md:63-66`, `refs/design.md:10-13`

Part A Step 4 では `phase = design-generated` と直接セットするが、これはdesign Subcommand(refs/design.md Step 3後) と同じ結果となる。revise.md の Part A Step 5 の Design 手順では「after completion: verify design.md, update spec.yaml (increment version, phase=design-generated, last_phase_action=null)」と記載しており、その前のStep 4でも `phase = design-generated` にセットしている。これはdesign Subcommand実行前にphaseが先行してセットされることを意味する。Architectが失敗した場合 (design.md not produced)、refs/design.md Step 3では「do NOT update spec.yaml, escalate」とあるが、Step 4で既にphase遷移済みであるため矛盾する。revise.md Part A Step 4 の `phase = design-generated` セットをArchitect完了後に移動させるか、Architect失敗時にreverting処理を追加すべき。

---

#### [MEDIUM] Wave Quality Gate: Dead Code Review NO-GO のリトライカウンターが `spec.yaml` に永続化されない設計 / `refs/run.md:245-248`, `CLAUDE.md:171-177`

`refs/run.md` Step 7b では「Dead Code Review NO-GO: max 3 retries, tracked in-memory by Lead — not persisted to spec.yaml, restarts at 0 on session resume」と記載。これはCLAUDE.md §Auto-Fix Counter Limits の「Dead-Code Review NO-GO: max 3 retries; exhaustion → escalate」と整合している。しかし、セッション再開時にカウンターがリセットされることで、波のDead Codeレビューが延々とリトライし続けられる懸念がある。これはセッション再開後にLeadが同じwaveのDead Code NOGOに再遭遇した際の動作が未定義となる。仕様上は「意図的な設計」とも読めるが、ドキュメントとして明示的に「セッション再開時にリトライ上限が実質リセットされる」という注記があるとよい。

---

#### [MEDIUM] `refs/revise.md` Part B: Tier 7 内でのオートフィックスループの詳細が欠如 / `refs/revise.md:203-245`

Part B Step 7 の「Tier Checkpoint」では「Auto-fix loop applies per spec (standard counter limits); On exhaustion: escalate to user, block tier progression」と記載。しかし具体的な NO-GO / SPEC-UPDATE-NEEDED の挙動（どのカウンターをインクリメント、どのフェーズにロールバック）が記述されていない。`refs/run.md` のPhase Handlers のような詳細な記述が欠如しており、Leadがrevise Part Bパイプライン実行中にNO-GO verdict を受け取った際の正確な処理手順を参照できない。`refs/run.md` の Phase Handlers を参照するよう明示的なクロスリファレンスが必要。

---

#### [MEDIUM] `SKILL.md` Consensus Mode: B{seq}の決定タイミングとReview Execution Flowの Step 2 との関係が不明確 / `SKILL.md:115-116`, `refs/review.md:74`

`SKILL.md` §Consensus Mode では「Determine B{seq} from `{scope-dir}/verdicts.md`」と記載し、`refs/review.md` Step 2 では「For consensus mode: Router determines B{seq} once and passes it to all N pipelines (this step uses the Router-provided value instead of computing its own)」と記載している。Router (SKILL.md) が B{seq} を決定してから各 Inspectors pipeline に渡す流れは整合しているが、「SKILL.md Step 1」で B{seq} を読むタイミングが Consensus Mode 説明の中に記述されており（line 115-116）、一方 review.md はそれをRouter-provided値として受け取るとのみ記載。渡し方（promptに含めるのか）が未定義のため、Inspector/Auditorプロンプト生成時の実装が曖昧。

---

#### [LOW] `SKILL.md` Single-Spec Roadmap Ensure: `review dead-code` の `--wave N` フラグへの対応が不完全 / `SKILL.md:72-74`

`SKILL.md` Step 1 のDetect Mode テーブルには `review --wave N` が listed されているが（line 27-28）、Single-Spec Roadmap Ensure セクション（line 72-74）では例外として `review dead-code` と `review --cross-check` / `review --wave N` が listed。しかし、`review dead-code --wave N` という組み合わせが有効かどうかが `refs/review.md` の Step 1 Parse Arguments で明示されていない。Dead Code Review には `--wave N` フラグは適用外と思われるが、ユーザーが `review dead-code --wave N` と入力した場合の挙動が未定義。

---

#### [LOW] `refs/run.md` Design Lookahead: ロールバック（Staleness guard）後のfirst-wave依存specの再designタイミングが不明確 / `refs/run.md:163-166`

Staleness Guard では「Wave N specのdesignが変更された場合（NO-GO → Architect再dispatch）、Wave N+1のlookahead designを invalidate し、Wave N QG後に再design」と記載。しかし invalidate されたlookahead specが `design-generated` フェーズに達していた場合の spec.yaml の状態変更（`phase` をどこに戻すか）が記述されていない。再designのトリガーが「Wave N QG後」と記載されているが、Readiness Rules（run.md line 147-153）との連携が示されていない。

---

#### [LOW] `refs/review.md`: `SPEC-UPDATE-NEEDED` を Design Review Auditor が返した場合の対応が refs/run.md と review.md で一貫していない / `refs/run.md:180`, `refs/review.md:134-138`

`refs/run.md` Phase Handlers の「Design Review completion」では「SPEC-UPDATE-NEEDED → not expected for design review. If received, escalate immediately.」と記載。`refs/review.md` の「Next Steps by Verdict」では Design GO/CONDITIONAL → impl、NO-GO → auto-fix のみ記載され、SPEC-UPDATE-NEEDEDについては言及なし。Design Auditor (`sdd-auditor-design.md`) の出力フォーマットでは `VERDICT:{GO|CONDITIONAL|NO-GO}` のみで `SPEC-UPDATE-NEEDED` は含まれておらず、仕様上は発生しないことが保証されている。`refs/run.md` の「not expected」という記述で整合しているが、`refs/review.md` Next Steps にも「Design Reviewでは SPEC-UPDATE-NEEDED は発生しない」という注記があるとより明確。

---

### Confirmed OK

- **Router dispatch completeness**: SKILL.md Step 1 Detect Mode で全subcommand（design, impl, review design/impl, review dead-code, review --consensus, review --cross-check, review --wave, run, run --gate, run --consensus, revise {feature}, revise, create, update, delete, -y, ""）が明示的にリストされ、各refへの正確なルーティングが記述されている。

- **Phase gate consistency (design.md)**: design.md Step 2 のPhase Gate は `initialized`, `design-generated`, `implementation-complete`, `blocked` の4フェーズをカバーし、CLAUDE.md定義と一致している。

- **Phase gate consistency (impl.md)**: impl.md Step 1 のPhase Gate は `design-generated`（標準）、`implementation-complete`（再実行）、その他はBLOCKと明示しており、CLAUDE.md定義と一致している。

- **Phase gate consistency (review.md)**: review.md Step 2 のPhase Gate は Design Review用（design.md存在確認）、Impl Review用（tasks.yaml・phase=implementation-complete確認）、Dead Code用（フェーズゲートなし）と適切に分離されている。

- **Auto-fix loop: NO-GO/SPEC-UPDATE-NEEDED カウンター**: CLAUDE.md §Auto-Fix Counter Limits の `retry_count` max 5、`spec_update_count` max 2、aggregate cap 6 は refs/run.md の Phase Handlers（Design Review NO-GO: max 5、Impl Review NO-GO: max 5、SPEC-UPDATE-NEEDED: max 2、aggregate cap 6）と整合。

- **Auto-fix loop: CONDITIONAL = GO 扱い**: CLAUDE.md「CONDITIONAL = GO (proceed). Counters are NOT reset on intermediate GO/CONDITIONAL.」は refs/run.md Phase Handlers の「GO/CONDITIONAL → proceed (counters NOT reset)」と一致している。

- **Wave Quality Gate (Step 7) 完全性**: Wave QG は (a) Impl Cross-Check Review → (b) Dead Code Review → (c) Post-gate（counterリセット・commit・session.md）の3段階が順序立てて定義されており、1-spec roadmap スキップ条件も明記されている。

- **Consensus Mode一貫性**: SKILL.md §Consensus Mode と refs/review.md §Review Execution Flow の consensus 処理（`active-{p}/`ディレクトリ、B{seq}共有、アーカイブ先`B{seq}/pipeline-{p}/`）が整合している。

- **Verdict Persistence フォーマット一貫性**: SKILL.md §Verdict Persistence Format で定義されたフォーマットは review.md Step 8で参照（「see Router → Verdict Persistence Format」）、refs/run.md Step 7でも同様に参照しており、フォーマット定義は1箇所に集約されている。各レビュータイプのverdicts.mdパス（per-feature、dead-code、cross-check、wave、cross-cutting、self）はreview.md §Verdict Destination で網羅されている。

- **Blocked spec 処理**: CLAUDE.md Phase Gate、refs/run.md Step 6 Blocking Protocol、revise.md Part A Step 1（phase=blocked でのBLOCK）が整合しており、blocked specへの操作はすべてBLOCKされる。

- **1-spec roadmap最適化**: SKILL.md §1-Spec Roadmap Optimizations で Wave QG スキップ、Cross-Spec File Ownership Analysis スキップ、dead-code review スキップ（手動実行は可能）が明記。refs/run.md Step 7でも「1-Spec Roadmap: Skip this step」と整合。commit messageフォーマットも `{feature}: {summary}` と統一。

- **Revise Mode: Single-Spec → Cross-Cutting エスカレーション**: SKILL.md Detect Mode（line 34-35）と revise.md Mode Detection（line 7-16）が一致。Step 3 で2+spec影響時のCross-Cutting提案、受入時のPart B Step 2参加が明確に定義されている。

- **Revise Mode: Cross-Cutting → Step Escalation**: Part B Step 7 Tier 7 でのTier escalation、Part B Step 8 での cross-check review、Part B Step 9 post-completion commit（`cross-cutting: {summary}`）が定義されており、CLAUDE.md §Git Workflow と整合。

- **Inspector 数の一貫性**: Design Review (6 Inspectors: rulebase, testability, architecture, consistency, best-practices, holistic)、Impl Review (6 標準 + 2 web: impl-rulebase, interface, test, quality, impl-consistency, impl-holistic + e2e, visual)、Dead Code Review (4: dead-settings, dead-code, dead-specs, dead-tests) が review.md、各Auditorのinput handling、settings.json の Task() エントリと整合している。

- **SubAgent 終了後の output形式**: Review SubAgent（Inspector/Auditor）は `WRITTEN:{path}` のみを返す。Builder は minimal summary + `WRITTEN:{path}` を返す。Architect、TaskGenerator、ConventionsScanner はそれぞれの completion report（ARCHITECT_COMPLETE、TASKGEN_COMPLETE）または `WRITTEN:{path}` を返す。CLAUDE.md §SubAgent Lifecycle の方針と一致。

- **ConventionsScanner登録**: CLAUDE.md Tier 3 の役割リストに ConventionsScanner が追加されており（framework/claude/CLAUDE.md line 16）、settings.json には存在しないが、これは review agent ではなく Task dispatch なしで動作するためであり、settings.json の Task() には `sdd-conventions-scanner` のエントリが不要であることが確認済み（settings.json はTask()エントリを持たない設計でなく実際には `Task(sdd-conventions-scanner)` への許可エントリが見当たらない）。

- **`run_in_background: true` 強制**: CLAUDE.md §SubAgent Lifecycle「always. No exceptions」は refs/design.md（Task with run_in_background=true）、refs/impl.md（run_in_background=true）、refs/review.md（run_in_background=true）と整合。

- **Session Resume手順**: CLAUDE.md §Session Resume の7ステップと refs/run.md §Step 1 Load State（spec.yaml ground truth）が整合。spec.yaml が single source of truth の原則が一貫して適用されている。

- **CPF フォーマット一貫性**: すべてのInspector/Auditorがpipe-delimited CPF形式でverdictを出力し、cpf-format.md で定義されたフォーマットルールに従っている。severity codes (C/H/M/L) が一貫して使用されている。

- **既読タイミング明示性**: SKILL.md の「Execution Reference」セクション（line 96-105）で各モード検出後にrefを読む手順が明記されており、「After mode detection and roadmap ensure, Read the reference file for the detected mode:」として明確に記述されている。

- **Dead Code Review リトライ上限の分離**: CLAUDE.md「Dead-Code Review NO-GO: max 3 retries」と refs/run.md Step 7b「max 3 retries, tracked in-memory by Lead — not persisted to spec.yaml, separate from per-spec aggregate cap」が整合しており、dead code review のリトライは spec.yaml の aggregate cap（6）とは独立している。

---

### Overall Assessment

全体的なフロー設計は堅牢であり、主要な実行パス（Design → Review → Impl → Review → Wave QG）の整合性は概ね保たれている。SKILL.md Router から各 refs への dispatch は完全で、Phase Gateの一貫性も確認できた。

**最も重要な指摘事項**: `refs/revise.md` Part A Step 4 において `phase = design-generated` を Architect dispatch 前にセットしている点。Architect が失敗した場合に spec.yaml のフェーズが `design-generated` に残留し、後続の処理で設計なしの `design-generated` フェーズが露呈する危険がある。この問題は revise flow のみで発生し（通常の design flow では refs/design.md Step 3 で Architect 完了後に spec.yaml 更新）、設計の一貫性に影響する。

残り3件は MEDIUM: Tier 7 のオートフィックス詳細の参照不足、wave Dead Code カウンタのセッション永続化問題（意図的設計であれば注記追加を推奨）、Consensus Mode の B{seq} 渡し方の未定義箇所。

**推奨優先度**:
1. `refs/revise.md` Part A Step 4 の phase transition タイミング修正（Architect完了後に移動）
2. `refs/revise.md` Part B Step 7 に `refs/run.md` Phase Handlers への明示的参照追加
3. Wave Dead Code カウンタのセッション再開挙動に注記追加
4. Consensus Mode の B{seq} 渡し方の明示（Inspector promptに含めることを明記）
