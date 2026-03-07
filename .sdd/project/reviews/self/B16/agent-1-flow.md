## Flow Integrity Report

### Issues Found

---

#### [MEDIUM] Revise モード — Cross-Cutting 移行後のフェーズ前提が未定義
**ファイル**: `framework/claude/skills/sdd-roadmap/refs/revise.md` Part A Step 3 / Part B Step 2

**問題**:
SKILL.md の Detect Mode は、`revise <feature>` が Single-Spec、`revise [instructions]` が Cross-Cutting として判定される。

revise.md Part A Step 3 の escalation パス:
> "User accepts → join Part B Step 2 with pre-populated target spec (Step 4 has NOT executed — target spec's phase is still `implementation-complete`, eligible for Part B classification)"

Part B に合流した際、対象 spec の phase は `implementation-complete` のままである。Part B Step 7 の State Transition (各 spec の `phase = design-generated` への変更) は Tier 実行フロー内で行われるため、合流後の Impact Analysis (Step 2) と Triage (Step 5) の時点では `implementation-complete` であることが保証されている。これは設計上正しい。

ただし、Part A Step 6 (Downstream Resolution) の option (d) でも Part B Step 2 に合流するケースがある。この場合、対象 spec の phase は Step 4/5 を経て `design-generated` に遷移済みであり、さらに Step 5 実行後は `implementation-complete` ではなくなっている可能性がある。Part B Step 2 では `only implementation-complete phase is eligible for revision` とあるが、すでに pipeline を進めた target spec が Step 6 (d) 合流時に適格性をどう扱うかが明示されていない。

**リスク**: Step 6 (d) からの合流ケースでは、合流時点の Phase Gate 整合性が曖昧。

---

#### [MEDIUM] run.md — Design Lookahead の波グループ除外が spec.yaml に記録されない
**ファイル**: `framework/claude/skills/sdd-roadmap/refs/run.md` Step 4 § Design Lookahead

**問題**:
Lookahead で事前に Design が生成された Wave N+1 の spec が、Wave N の設計変更 (NO-GO → Architect re-dispatch) によって無効化される「Staleness guard」の処理として「invalidate lookahead design, mark for re-design after Wave N QG」と記述されているが、この「re-design マーク」の実装方法が未定義である。

- spec.yaml に専用フィールドがない (`orchestration` 配下には `retry_count`, `spec_update_count`, `last_phase_action` のみ)
- Lead がメモリ内でのみ追跡する場合、セッション中断・再開時に状態が消失する

**リスク**: セッション再開後、Lookahead 設計が stale でも再設計されず、整合性エラーが検出されない。

---

#### [MEDIUM] Consensus モード — B{seq} の二重カウント
**ファイル**: `framework/claude/skills/sdd-roadmap/SKILL.md` § Consensus Mode (Router) と `refs/review.md` Step 2

**問題**:
review.md Step 2:
> "For consensus mode: Router determines B{seq} once and passes it to all N pipelines (this step uses the Router-provided value instead of computing its own)."

Router (SKILL.md § Consensus Mode) Step 1:
> "Determine review scope directory and B{seq} from `{scope-dir}/verdicts.md` (increment max existing, or start at 1)"

Router が B{seq} を決定し、review.md に渡すことは明確。ただし Router の Step 7 (Archive) に:
> "rename `reviews/active-{p}/` → `reviews/B{seq}/pipeline-{p}/`"

とあるが、review.md Step 9:
> "Archive: rename `{scope-dir}/active/` → `{scope-dir}/B{seq}/` (consensus: `active-{p}/` → `B{seq}/pipeline-{p}/`)"

実質同じ処理が両方に記述されており、どちらが実行主体かが不明瞭。

**リスク**: 実装時に二重アーカイブ処理が発生する可能性。

---

#### [MEDIUM] run.md Phase Handler — NO-GO 時の Counter リセット境界が曖昧
**ファイル**: `framework/claude/skills/sdd-roadmap/refs/run.md` § Design Review completion / § Impl Review completion

**問題**:
CLAUDE.md § Auto-Fix Counter Limits:
> "CONDITIONAL = GO (proceed). Counters are NOT reset on intermediate GO/CONDITIONAL."
> "Counter reset triggers: wave completion, user escalation decision (including blocking protocol fix/skip), `/sdd-roadmap revise` start, session resume (dead-code counters are in-memory only; see `refs/run.md`)"

run.md Step 7c (Post-gate):
> "Reset counters: For each spec in wave: `retry_count=0`, `spec_update_count=0`"

一方、run.md の Design Review completion は:
> "NO-GO → increment `retry_count`. ... After fix: reset `orchestration.last_phase_action = null`, phase remains `design-generated`."

Blocking Protocol (Step 6) の `fix` オプションでは:
> "unblock downstream (restore phases, clear blocked_info, reset `retry_count=0` and `spec_update_count=0` for unblocked specs)"

ブロック解除時には対象 spec のカウンターがリセットされるが、CLAUDE.md の Counter reset trigger 一覧にこのケースは含まれており整合する。

**追記**: CLAUDE.md 本文中の `session resume` は dead-code カウンターのみ in-memory と記述しているが、run.md Step 7b Dead Code Review では「tracked in-memory by Lead — not persisted to spec.yaml」と明記されており整合。ただし、`session resume` トリガーが CLAUDE.md の Counter reset triggers に含まれているが、「session resume (dead-code counters are in-memory only; see `refs/run.md`)」の注釈が dead-code 固有なのか全カウンターに適用されるのかが若干読みにくい。

**リスク**: 低。意味は読み取れるが、将来の編集で誤解が生じる可能性がある。

---

#### [LOW] Verdict Persistence — Wave QG cross-check の B{seq} ヘッダー形式の記述が分散
**ファイル**: `framework/claude/skills/sdd-roadmap/refs/run.md` Step 7a / `refs/review.md` § Verdict Destination

**問題**:
run.md Step 7a:
> "Persist verdict to `{{SDD_DIR}}/project/reviews/wave/verdicts.md` (header: `[W{wave}-B{seq}]`)"

run.md Step 7b:
> "Persist verdict to `{{SDD_DIR}}/project/reviews/wave/verdicts.md` (header: `[W{wave}-DC-B{seq}]`)"

SKILL.md § Verdict Persistence Format:
> "Append batch entry: `## [B{seq}] {review-type} | {timestamp} | v{version} | runs:{N} | threshold:{K}/{N}`"

Wave QG の場合は `[W{wave}-B{seq}]` 形式を使うが、SKILL.md の Verdict Persistence Format のテンプレートは `[B{seq}]` 形式のみ記載されており、Wave QG 時の特殊フォーマットが Router の共通テンプレートに反映されていない。

**リスク**: Wave QG verdicts.md への書き込み時にフォーマットの迷いが生じる可能性。

---

#### [LOW] Cross-Cutting revise.md — Consistency Review の Verdict Persistence が SKILL.md テンプレートを参照していない
**ファイル**: `framework/claude/skills/sdd-roadmap/refs/revise.md` Part B Step 8

**問題**:
revise.md Step 8:
> "Persist verdict to `specs/.cross-cutting/{id}/verdicts.md`"

SKILL.md Verdict Persistence Format は cross-cutting scope の存在を明示していない (Listed in review.md § Verdict Destination: `specs/.cross-cutting/{id}/verdicts.md`) が、SKILL.md のテンプレート説明ではこの scope に対する特別な処理 (B{seq} の計算方法など) が述べられていない。

**リスク**: 軽微。review.md が正典として Verdict Destination を列挙しており、実際の処理は review.md が担う。

---

#### [LOW] revise.md Part B Step 7 — Tier Checkpoint の Auto-Fix ループが CLAUDE.md カウンター上限と暗黙結合
**ファイル**: `framework/claude/skills/sdd-roadmap/refs/revise.md` Part B Step 7 (Tier Checkpoint)

**問題**:
> "Auto-fix loop applies per spec: handle NO-GO/SPEC-UPDATE-NEEDED per run.md Phase Handlers (counter increment, Architect/Builder re-dispatch, phase transitions)"

run.md Phase Handlers を参照することで暗黙的に CLAUDE.md の retry_count ≤ 5、aggregate cap 6 が適用される。参照連鎖は機能するが、revise.md 自体には上限値が記載されていない。

**リスク**: 非常に低い。run.md Phase Handlers を読めば把握できる。

---

### Confirmed OK

1. **Router Dispatch 完全性**: SKILL.md Step 1 の全サブコマンド (design, impl, review, run, revise, create, update, delete, -y, empty) が正しい ref ファイルにルーティングされている。"Execution Reference" セクションが明示的にどの ref を読むかを指示しており、読み込みタイミングも明確。

2. **Phase Gate 一貫性**: 各 ref が CLAUDE.md 定義フェーズ (`initialized`, `design-generated`, `implementation-complete`, `blocked`) のみを使用している。設計.md Step 2、impl.md Step 1、review.md Step 2 はそれぞれ適切なフェーズゲートを実装している。

3. **Auto-Fix ループ — NO-GO 処理**: run.md Phase Handlers は CLAUDE.md の retry_count ≤ 5、aggregate cap 6 と整合している。CONDITIONAL = GO の処理が review.md Standalone Verdict Handling と run.md Phase Handlers の両方で一貫している。

4. **Auto-Fix ループ — SPEC-UPDATE-NEEDED 処理**: CLAUDE.md の spec_update_count ≤ 2、aggregate cap 6 の記述が run.md Impl Review completion で正確に実装されている。Design Review における SPEC-UPDATE-NEEDED は「not expected, escalate immediately」として両 ref で一致している。

5. **Wave Quality Gate — 完全性**: run.md Step 7 が (a) Impl Cross-Check、(b) Dead-Code Review、(c) Post-gate の 3 フェーズを網羅し、それぞれの NO-GO/CONDITIONAL 処理が定義されている。1-Spec Roadmap の Skip 処理が SKILL.md と run.md で一致している。

6. **Consensus モード — Inspector 並列実行**: N セットのインスペクターを並列実行し、各 pipeline の verdict.cpf を集約してコンセンサス判定する流れが SKILL.md で一貫して定義されている。閾値計算 (⌈N×0.6⌉) が明記されている。

7. **Verdict Persistence フォーマット**: SKILL.md の Verdict Persistence Format (a-h ステップ) が canonical であり、review.md Step 8 がこれを参照している。review.md § Verdict Destination が全 scope (single-spec / dead-code / cross-check / wave / cross-cutting / self-review) のパスを網羅している。

8. **1-Spec Roadmap 最適化**: SKILL.md § 1-Spec Roadmap Optimizations が Wave QG skip / Cross-Check skip / Dead-Code skip / コミット形式の変更を明示。run.md Step 7 冒頭で「1-Spec Roadmap: Skip this step」と明示されており整合。

9. **Blocked Spec 処理**: CLAUDE.md Phase Gate、design.md Step 2、impl.md Step 1、review.md Step 2、revise.md Part A Step 1 すべてで `phase == blocked` → BLOCK の処理が一致している。

10. **Retry 上限枯渇時のエスカレーション**: run.md Step 6 Blocking Protocol (fix/skip/abort) が retry 枯渇後の全オプションを網羅。Dead-Code NO-GO は max 3 retries が run.md Step 7b で CLAUDE.md と一貫して記述されている。

11. **Revise モード — Single-Spec → Cross-Cutting エスカレーション**: SKILL.md Detect Mode の `revise <feature> [instructions]` → Part A が正しくルーティング。Part A Step 3 の「2+ specs affected → propose Cross-Cutting mode」の escalation パスが revise.md 内で self-contained に定義されている。

12. **Router ref 読み込みタイミング**: SKILL.md "Execution Reference" セクションで「After mode detection and roadmap ensure, Read the reference file for the detected mode」と明記されており、読み込みタイミングが明示されている。

13. **SubAgent 並列実行 — always run_in_background**: CLAUDE.md で `run_in_background: true` が例外なく必須と明記。各 ref (design.md Step 3, impl.md Step 2, review.md Step 4) で Task spawn 時に準拠している。

14. **Verdicts.md の Tracked セクション**: SKILL.md Verdict Persistence Format step (g) が CONDITIONAL の M/L 課題を Tracked として追記し、step (h) で前バッチとの比較を行う仕様が定義されている。sdd-auditor-design/impl の出力フォーマット (VERIFIED/REMOVED/RESOLVED/STEERING/NOTES) と整合している。

15. **Inspector セット完全性**: review.md § Design Review が 6 Inspector を列挙し、sdd-auditor-design Input Handling のファイルリスト (1-6) と一致。Impl Review が 6 + 2 web Inspector で、sdd-auditor-impl Input Handling (1-8) と一致。Dead-Code Review が 4 Inspector で、sdd-auditor-dead-code Input Handling (1-4) と一致。

16. **settings.json 権限との整合**: settings.json の `Task(sdd-*)` 許可リストが framework/claude/agents/ の全エージェント定義と一致している (sdd-analyst, sdd-architect, sdd-builder, sdd-taskgenerator, sdd-conventions-scanner, 全 inspector, 全 auditor)。

17. **Reboot フロー**: sdd-reboot SKILL.md が refs/reboot.md を読むことを明示。reboot.md の 10 フェーズが SKILL.md のサマリーと一致。Phase 9 ユーザー承認ゲート、Phase 10 削除確認の 2 段階ゲートが設計されている。

---

### Overall Assessment

全体的なフロー整合性は高い水準にある。Router → ref ディスパッチのすべてのパスが機能し、Phase Gate・Auto-Fix ループ・Consensus モード・1-Spec 最適化・Blocked spec 処理はいずれも CLAUDE.md と refs 間で一貫している。

主要な懸念点は 2 件:

1. **Lookahead Stale マークの永続化欠如** (MEDIUM): セッション再開後に Wave N+1 の stale な Lookahead 設計が見逃される可能性がある。spec.yaml の orchestration フィールドに `lookahead_stale: true` などを追加するか、セッション再開時に Wave N の最終 Design バージョンと Wave N+1 の `version_refs.design` を突合する再評価ステップを明示することで解消できる。

2. **Part B 合流後の Phase 前提の曖昧さ** (MEDIUM): revise.md Part A Step 6 (d) → Part B Step 2 の合流ケースで、合流時点の target spec フェーズが `design-generated` になっている場合の適格性が未定義。「合流時の Phase に関わらず FULL として扱う」という明示的な注記を追加することで解消できる。

残り 3 件は LOW レベルであり、機能的な障害にはならない。Verdict Persistence のヘッダー形式 (`[W{N}-B{seq}]`) を SKILL.md の共通テンプレートに補足することで可読性が向上する。
