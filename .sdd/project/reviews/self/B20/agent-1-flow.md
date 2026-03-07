## Flow Integrity Report

### Issues Found

- [MEDIUM] **Review Readiness Rule: Design Review ありの条件が逆転している** / `refs/run.md:160`

  Readiness Rules テーブルにて:
  ```
  | Design Review | Phase is `design-generated`. No GO/CONDITIONAL verdict in `verdicts.md` latest design batch (verdict absent or last is NO-GO). |
  ```
  これは「最新バッチに GO/CONDITIONAL がない場合」= 「verdict がないか、最後が NO-GO の場合」に Design Review を実行する、という条件。言い換えると「すでに GO/CONDITIONAL が出たなら再レビュー不要」という意味であり、論理的には正しい。ただし文章が二重否定的でわかりにくく、**Design Review を「まだ通過していないとき」に実施するという意味**が一見逆に読める。誤解のリスクはあるが機能上の問題はない。LOW 寄りだが MEDIUM とする（誤読による不正なスキップリスクがあるため）。

- [MEDIUM] **impl.md の Phase Gate: design.md が存在しない場合のエラー分岐が未定義** / `refs/impl.md:9`

  impl.md Step 1:
  ```
  1. Read `{{SDD_DIR}}/project/specs/{feature}/spec.yaml`, verify `design.md` exists
  ```
  と書かれているが、`design.md` が存在しない場合の具体的なエラーアクション（BLOCK メッセージや次のステップ）が impl.md 内に記述されていない。SKILL.md の Error Handling セクションには:
  ```
  - **Missing design.md (impl)**: "Run `/sdd-roadmap design {feature}` first."
  ```
  という記述があるため、最終的には機能する。しかし **impl.md 自体はこのエラーハンドリングを定義していない** — SKILL.md のエラーテーブルへの参照もない。Leadが refs を読む際に impl.md だけを見た場合、BLOCKすべき状況でも継続してしまう可能性がある。

- [MEDIUM] **Revise Part A: Step 3 の Cross-Cutting 昇格後、Part B Step 2 への接合点で revision intent の引き継ぎが曖昧** / `refs/revise.md:47`

  Step 3 の Cross-Cutting 昇格パス:
  ```
  User accepts → record `DIRECTION_CHANGE` in decisions.md, join Part B Step 2 with revision intent and target spec pre-populated (Step 4 has NOT executed — target spec's phase is still `implementation-complete`, eligible for Part B classification)
  ```
  Part B Step 1 には:
  ```
  - If joining from Part A: use revision intent already collected
  ```
  という記述があり整合は取れている。しかし「join Part B Step 2」と書きながら、**Step 1 の処理（decisions.md への REVISION_INITIATED 記録）をスキップするか否か**が明示されていない。Part A Step 2 で既に `REVISION_INITIATED` を記録しているため、Part B Step 1 の記録は重複することになる。Leadが両方実行した場合、decisions.md に重複エントリが作られる可能性がある。

- [MEDIUM] **Revise Part A Step 6 (d) オプション選択後の Part B への接合で、target spec の phase が design-generated になっている問題** / `refs/revise.md:95`

  Step 6(d) の Cross-cutting 昇格:
  ```
  2. If option (d) selected → record `DIRECTION_CHANGE` in decisions.md, join Part B Step 2 with completed target spec + affected dependents pre-populated
  ```
  しかし Step 5 のパイプライン（Design → Impl Review）が完了していれば、target spec は既に `implementation-complete` に戻っているはず。Part B Step 2 の Impact Analysis は `implementation-complete` フェーズのスペックのみを対象とするため問題ない。一方、Step 5 が未完了（例: Impl Review NO-GO で retry 中）の場合、target spec が `design-generated` 等の中間フェーズにある状態で Part B に接合される可能性がある。Part B Step 2:
  ```
  1. Read all `spec.yaml` files (only `implementation-complete` phase is eligible for revision)
  ```
  という制約があるため、中間フェーズのスペックは Impact Analysis からスキップされてしまう。これにより対象スペックが分類されないまま処理が進む可能性がある。実際には Step 6 は「revision pipeline completes」後に実行されるため頻度は低いが、エッジケースとして存在する。

- [LOW] **Consensus Mode: SKILL.md と review.md の archive パス記述が微妙にずれている** / `SKILL.md:125, refs/review.md:107`

  SKILL.md:
  ```
  N=1 (default): use `specs/{feature}/reviews/active/` (no `-{p}` suffix). Archive handled by review.md Step 9.
  ```
  review.md Step 9:
  ```
  Archive: rename `{scope-dir}/active/` → `{scope-dir}/B{seq}/` (consensus: `active-{p}/` → `B{seq}/pipeline-{p}/`)
  ```
  N=1 の場合は `active/` → `B{seq}/` であり、SKILL.md の「Archive handled by review.md Step 9」への委譲は正しい。しかし SKILL.md の Consensus Mode セクション:
  ```
  7. Proceed to verdict handling with consensus verdict (archive is handled by review.md Step 9)
  ```
  と書かれており、N>1 のコンセンサスモードでも「archive は review.md Step 9 が担う」とされているが、review.md Step 9 のアーカイブ処理は `{scope-dir}/active/` → `{scope-dir}/B{seq}/` という単一パスを前提としている。Consensus モード（N>1）では複数の `active-{p}/` が存在するため、review.md Step 9 の「consensus: `active-{p}/` → `B{seq}/pipeline-{p}/`」という記述が対応している。機能上の矛盾はないが、SKILL.md からの委譲記述が「N=1 の場合のみ」なのか「N>1 も含む」のかが不明確。

- [LOW] **design.md Phase Gate (revise.md Part A): `initialized` フェーズのスペックに revise を実行した場合の挙動が未定義** / `refs/revise.md:24-28`

  Part A Step 1 の検証条件:
  ```
  2. Verify `spec.yaml` exists and `phase` is `implementation-complete`
  ```
  これは `implementation-complete` 以外のフェーズ（`initialized`, `design-generated`）に対して revise を実行しようとした場合、BLOCK することを意味する。ただし BLOCK 時のエラーメッセージが revise.md に明記されていない。SKILL.md の Error Handling には:
  ```
  - **Wrong phase (impl)**: "Phase is '{phase}'. Run `/sdd-roadmap design {feature}` first."
  ```
  という記述があるが、revise コマンドに対する phase エラーメッセージは定義されていない。機能上は BLOCK されるが、ユーザーへのメッセージが不明確。

- [LOW] **Wave Quality Gate Dead Code Review の retry カウンタがセッション非永続** / `refs/run.md:258, CLAUDE.md:180`

  run.md Step 7b:
  ```
  max 3 retries, tracked in-memory by Lead — not persisted to spec.yaml. Dead-code findings are wave-scoped and resolved within a single execution window; counter restarts at 0 on session resume.
  ```
  CLAUDE.md:
  ```
  Counter reset triggers: wave completion, user escalation decision (including blocking protocol fix/skip), `/sdd-roadmap revise` start, session resume (dead-code counters are in-memory only; see `refs/run.md`).
  ```
  両ファイルに「セッション再開時にカウンタがリセットされる」という記述があり整合性あり。設計上意図的なトレードオフだが、セッション中断・再開を繰り返すと dead code review を無限リトライできる抜け穴が存在する。これはドキュメント上の問題というよりは設計上の既知トレードオフ（LOW）。

- [LOW] **review.md の "Verdict Destination by Review Type" テーブルに cross-cutting review のパスが記載されているが、run.md Step 7a との対応が明示されていない** / `refs/review.md:147, refs/run.md:244`

  review.md:
  ```
  - **Wave-scoped review**: `{{SDD_DIR}}/project/reviews/wave/verdicts.md`
  ```
  run.md Step 7a:
  ```
  2. Persist verdict to `{{SDD_DIR}}/project/reviews/wave/verdicts.md` (header: `[W{wave}-B{seq}]`)
  ```
  これは一致している。一方、revise.md Part B Step 8:
  ```
  2. Persist verdict to `specs/.cross-cutting/{id}/verdicts.md` (NOT `reviews/wave/verdicts.md` — cross-cutting uses its own scope directory)
  ```
  review.md の Verdict Destination テーブルにも:
  ```
  - **Cross-cutting review**: `{{SDD_DIR}}/project/specs/.cross-cutting/{id}/verdicts.md`
  ```
  と記載があり整合している。ただし revise.md Part B Step 8 が review.md の cross-check impl review を「same mechanism as run.md Step 7a」と呼んでいる点が若干誤解を招く可能性がある（Step 7a は `reviews/wave/` に保存するが、cross-cutting は `specs/.cross-cutting/{id}/` に保存するため）。この差異を revise.md Step 8 が明示的に注記しているので問題は軽微。

### Confirmed OK

- **Router dispatch completeness**: 全サブコマンド（design, impl, review design|impl|dead-code, run, revise, create, update, delete, -y）が正しい refs ファイルへルーティングされている（SKILL.md Step 1, Execution Reference セクション）
- **Phase gate consistency**: CLAUDE.md で定義された 3 フェーズ（`initialized` → `design-generated` → `implementation-complete`、`blocked`）が design.md, impl.md, review.md, revise.md, run.md すべてで一貫して参照されている
- **Auto-fix counter limits の一貫性**: retry_count max 5、spec_update_count max 2、aggregate cap 6 が CLAUDE.md と run.md Phase Handlers で整合している。Dead-code は max 3 という例外も両ファイルに明記
- **NO-GO ループ (Design Review)**: run.md Phase Handler → Architect 再投入 → Design Review 再実行、最大 5 回まで、の流れが明確
- **NO-GO ループ (Impl Review)**: run.md Phase Handler → Builder(s) 再投入 → Impl Review 再実行、最大 5 回まで、の流れが明確
- **SPEC-UPDATE-NEEDED ループ**: Impl Review でのみ発生、spec_update_count をインクリメント、phase を `design-generated` にリセット、Architect → TaskGenerator → Builder → Impl Review のカスケードが run.md に定義されている。Design Review では「escalate immediately」と明記
- **Wave Quality Gate 完全性**: Impl Cross-Check Review (7a) → Dead-Code Review (7b) → Post-gate の 3 ステップが run.md Step 7 に定義されている。1-spec ロードマップでのスキップも明記
- **Consensus Mode の並列実行**: SKILL.md の Consensus Mode セクションが review.md Step 3 の `active-{p}/` ディレクトリ構造と整合している。B{seq} の決定が Router 側（SKILL.md）で行われ、review.md に渡されることが明記されている
- **Verdict Persistence Format**: SKILL.md の Verdict Persistence Format セクションがすべてのレビュータイプ（per-feature、Wave QG cross-check、Wave QG dead-code、cross-cutting revision）をカバーしている
- **1-spec ロードマップ最適化**: Wave Quality Gate スキップ、Cross-Spec File Ownership Analysis スキップ等が SKILL.md に明記され、run.md Step 7 でも参照されている
- **blocked スペックのハンドリング**: design.md, impl.md, review.md, revise.md すべてで `phase=blocked` 時の BLOCK が定義されている。revise.md Part A Step 1 でも BLOCK が明記
- **Retry 上限到達時の Blocking Protocol**: run.md Step 6 に fix/skip/abort オプションが定義され、revise.md Part B Tier Checkpoint からも参照されている
- **Single-Spec → Cross-Cutting 昇格パス**: revise.md の Mode Detection ブロックおよび Part A Step 3 に昇格条件と Part B Step 2 への接合が定義されている
- **Cross-Cutting → Single-Spec 降格**: revise.md Part B Step 5.5（Auto-Demotion Check）に 1 スペックのみ FULL の場合の降格ロジックが定義されている
- **Refs 読み込みタイミング**: SKILL.md Execution Reference セクションに「After mode detection and roadmap ensure, Read the reference file for the detected mode」と明示されており、読み込みタイミングが明確
- **Dispatch Loop の Review Decomposition**: run.md §Review Decomposition が Inspector/Auditor の非同期分解（DISPATCH-INSPECTORS / INSPECTORS-COMPLETE / AUDITOR-COMPLETE）を定義しており、Spec Stagger の継続性を保証している
- **Design Lookahead**: run.md に Staleness Guard（Wave N スペックの design が変更された場合、依存する Lookahead スペックをリセット）が定義されている
- **Island Spec（Wave Bypass）**: run.md Step 3 に島スペックの検出と fast-track 実行ロジックが定義されている
- **Steering Feedback Loop**: review.md の CODIFY/PROPOSE 処理が CLAUDE.md §Steering Feedback Loop と整合しており、「verdict 処理後、次フェーズ前に処理」という順序が明確
- **sdd-review-self との整合**: review.md の Verdict Destination テーブルに `reviews/self/verdicts.md` が定義されており、sdd-review-self スキルのアーカイブ先と一致
- **Agent 定義とSettings.json の整合性**: settings.json の Agent() 許可リストに全 26 エージェント定義ファイルが対応している（sdd-analyst, sdd-architect, sdd-auditor-*×3, sdd-builder, sdd-conventions-scanner, sdd-inspector-*×16, sdd-taskgenerator）
- **install.sh のインストール対象**: framework/claude/skills/, framework/claude/agents/, framework/claude/sdd/settings/ が正しく .claude/skills/, .claude/agents/, .sdd/settings/ にコピーされる

### Overall Assessment

フロー全体として設計は一貫しており、主要な制御パス（Router → refs ディスパッチ、フェーズゲート、auto-fix ループ、Wave QG）は正しく動作する。

検出した問題はすべて MEDIUM 以下であり、クリティカルな不整合や機能停止につながる欠陥は見当たらなかった。主な懸念点：

1. **impl.md の design.md 欠損時エラーハンドリング未定義（MEDIUM）**: SKILL.md のエラーテーブルに依存しているが、impl.md 単体でのエラーフローが不完全。refs ファイルが単独読み込みされる場合に問題となりうる。
2. **Revise Part A → Part B 接合における decisions.md 重複リスク（MEDIUM）**: `REVISION_INITIATED` が Part A Step 2 と Part B Step 1 の両方で記録される可能性がある。
3. **Readiness Rules の二重否定表現（MEDIUM）**: 機能的問題ではないが可読性の低さによる誤読リスク。

全体的な品質評価: **CONDITIONAL（軽微な問題あり、運用継続可能）**
