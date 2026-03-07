## Flow Integrity Report

レビュー対象: sdd-roadmap Router -> refs dispatch flow (全モード)
レビュー日: 2026-02-27

---

### Issues Found

- [MEDIUM] **revise.md Part B (Cross-Cutting Mode) Step 7.4でconventions brief言及なし**
  - `refs/revise.md` Step 7 (Tier Execution) の Implementation (Step 4) は `TaskGenerator -> Builder (parallel per spec, serialize on file overlap)` と記述しているが、conventions brief パスの生成・受け渡しについて言及がない。run.md Step 2.5 では conventions brief 生成が明示され、impl.md でも TaskGenerator/Builder dispatch に conventions brief パスが含まれるが、revise.md の cross-cutting tier 実行ではこのステップがスキップされている。
  - Single-Spec revise (Part A Step 5) は `refs/impl.md` を参照するため問題なし。Cross-Cutting Mode のみの問題。
  - `refs/revise.md:224-227`
  - 影響: Cross-cutting revision で並列 Builder が conventions brief なしで実行される可能性があり、命名規則やパターンの不整合が生じうる。
  - 推奨: Step 7 の Implementation 箇所に「Conventions brief generation (run.md Step 2.5) before TaskGenerator dispatch」を追記、または「Execute per refs/impl.md (which includes conventions brief)」と明記。

- [MEDIUM] **Counter reset trigger「user escalation decision」のrun.md側定義不足**
  - CLAUDE.md (L172) は `Counter reset triggers: wave completion, user escalation decision, /sdd-roadmap revise start` と定義。
  - run.md Step 6 (Blocking Protocol) の `fix`/`skip` オプション選択時にカウンタリセットが明示されていない。Wave QG の `Manual fix` (L239) のみカウンタリセットが記述されている。
  - Blocking Protocol の `fix` 選択肢は「Verify upstream `implementation-complete` → unblock downstream → resume pipeline」とだけ記述。upstream spec のカウンタをリセットすべきかどうか不明。
  - `refs/run.md:220-223`
  - 影響: Blocking Protocol 後に pipeline 再開した際、exhaust 済みカウンタでまたすぐ escalate される可能性。
  - 推奨: Step 6 の `fix` オプションに「Reset target spec's retry_count and spec_update_count to 0」を追記。

- [LOW] **review.md Triggered by 行のフォーマット不一致**
  - `refs/review.md` L6: `Triggered by: \`$ARGUMENTS = "review design|impl|dead-code {feature} [options]"\``
  - dead-code は `{feature}` を取らない。正確には `review dead-code [options]`。Router の Detect Mode (SKILL.md L23) では `"review dead-code"` で feature なし。
  - `refs/review.md:6`
  - 影響: 軽微。review.md Step 1 の Parse で正しく処理されるため実害なし。

- [LOW] **revise.md Cross-Cutting Step 7 の State Transition で phase が design-generated に設定されるが、Architect は "existing" mode で呼ばれる**
  - `refs/revise.md:210` で `Set phase = design-generated` としたあと、Step 7.2 で Architect を `Mode: existing` で dispatch する。design.md Step 2 の Phase Gate は `design-generated` フェーズで re-design 警告を出さない（`implementation-complete` のみ）。整合性あり。ただし、run.md の Design completion handler (L171) は `design.md Step 3` を参照しているが、revise.md の Step 7 は直接 spec.yaml 更新を言及しない。
  - revise.md Step 7.2 が design.md に委譲し、design.md Step 3 (Post-Architect) で spec.yaml 更新が行われることは暗黙的。
  - `refs/revise.md:212-217`
  - 影響: 軽微。refs/design.md に委譲するため動作上は問題ないが、明示性がやや不足。

---

### Confirmed OK

- **Router dispatch completeness**: SKILL.md の全サブコマンド (design, impl, review design/impl/dead-code, run, revise, create, update, delete, -y, 空) が Step 1 Detect Mode で網羅され、Step 2 Auto-Detect で未指定ケースもカバー。Execution Reference セクションで全モードが正しい refs ファイルにルーティングされている。

- **Phase gate consistency**: 各 refs ファイルの Phase Gate が CLAUDE.md (L150-151) のフェーズ定義 (`initialized -> design-generated -> implementation-complete`, `blocked`) と整合。
  - design.md: blocked → BLOCK, implementation-complete → warn + confirm, unknown → BLOCK
  - impl.md: blocked → BLOCK, design-generated → proceed, implementation-complete → proceed (re-execution), other → BLOCK
  - review.md: Design Review は design.md 存在 + blocked チェック、Impl Review は phase=implementation-complete、Dead Code は gate なし
  - revise.md: phase=implementation-complete 必須、blocked → BLOCK

- **Auto-fix loop整合性**: NO-GO/SPEC-UPDATE-NEEDED ハンドリングが CLAUDE.md (L167-173) と run.md Phase Handlers で一致。
  - retry_count: max 5 (NO-GO) — CLAUDE.md L169, run.md L178/L193/L236
  - spec_update_count: max 2 (SPEC-UPDATE-NEEDED) — CLAUDE.md L169, run.md L194
  - Aggregate cap: 6 — CLAUDE.md L169, run.md L195/L236, revise.md L247
  - Dead-code max 3 — CLAUDE.md L170, run.md L247
  - CONDITIONAL = GO — CLAUDE.md L171, run.md L177/L192
  - Counter NOT reset on GO/CONDITIONAL — CLAUDE.md L171, run.md L177/L192

- **Wave Quality Gate フロー完全性**: run.md Step 7 が完全なフロー (a. Cross-Check → b. Dead Code → c. Post-gate) を定義。1-Spec Roadmap skip ルール (run.md L227, SKILL.md L87-90) が整合。Post-gate でカウンタリセット、コミット、session.md auto-draft。

- **Consensus mode整合性**: Router の Shared Protocols で N=1 デフォルト、N>1 の場合の active-{p} ディレクトリ分離、B{seq} 共有、threshold 計算 (⌈N×0.6⌉) が定義。review.md L92 で Router 参照。run.md Phase Handlers でも Router 参照。矛盾なし。

- **Verdict persistence format整合性**: Router の Verdict Persistence Format (SKILL.md L129-138) が唯一の定義ソース。review.md L89 で「Router → Verdict Persistence Format」と正しく参照。review.md Verdict Destination (L124-131) で全レビュータイプの出力先を定義。revise.md Cross-Cutting (L244) で独自スコープディレクトリを使用。run.md Wave QG (L233/L244) で wave-specific ヘッダー形式。

- **Edge cases**:
  - Empty roadmap: SKILL.md L73-74 で review dead-code/cross-check/wave N は BLOCK、それ以外は auto-create
  - 1-spec: SKILL.md L84-91 で Wave QG skip、cross-check skip、commit format 変更
  - Blocked spec: 全 refs ファイルで BLOCK 処理。run.md Step 6 Blocking Protocol で downstream cascade
  - Retry limit exhaustion: run.md L195 で aggregate cap 6 → escalate。Step 6 で downstream blocking

- **Read clarity**: SKILL.md Execution Reference (L96-105) で「After mode detection and roadmap ensure, Read the reference file for the detected mode」と明示。各モードの refs ファイルが明確に指定されている。

- **Revise modes routing**: SKILL.md Detect Mode (L34-35) で Single-Spec (`revise {feature} [instructions]`) と Cross-Cutting (`revise [instructions]`) を分離。revise.md Mode Detection (L8-16) で第一引数を既存 spec 名と照合してモード判定。Single-Spec Step 3 (L42-48) で 2+ spec 影響時に Cross-Cutting へのエスカレーション提案。Single-Spec Step 6 (L93-95) で option (d) による Cross-Cutting 合流。Part B Step 2 で pre-populated target spec 受け入れ。エスカレーションパス完全。

- **SubAgent dispatch patterns**: 全 agent 定義が settings.json の Task() パーミッションに対応。
  - Design: sdd-architect (opus) ✓
  - TaskGen: sdd-taskgenerator (sonnet) ✓
  - Builder: sdd-builder (sonnet) ✓
  - Design Inspectors (6): rulebase, testability, architecture, consistency, best-practices, holistic ✓
  - Impl Inspectors (6+2): impl-rulebase, interface, test, quality, impl-consistency, impl-holistic + e2e, visual ✓
  - Dead-code Inspectors (4): dead-settings, dead-code, dead-specs, dead-tests ✓
  - Auditors (3): auditor-design (opus), auditor-impl (opus), auditor-dead-code (opus) ✓

- **Inspector/Auditor count**: CLAUDE.md L26「6 design, 6 impl +2 web (impl only, web projects), 4 dead-code」= review.md の各セクションで列挙される agent 数と一致。

- **File-based review protocol**: Inspector → active/ ディレクトリに CPF 書込み → Auditor が読取り → verdict.cpf 書込み → Lead が読取り → verdicts.md にpersist → active/ を B{seq}/ にリネーム。CLAUDE.md L34, review.md Steps 3-9 で完全に一貫。

- **Review Decomposition (Spec Stagger)**: run.md L120-142 で 3 sub-phase (DISPATCH-INSPECTORS → INSPECTORS-COMPLETE → AUDITOR-COMPLETE) が定義。Standalone review は review.md の sequential flow を使用 (L122)。NO-GO flow は PROCESS から直接 Architect dispatch (L142)。

- **SPEC-UPDATE-NEEDED の Design Review 排除**: run.md L179、revise.md L222 で「not expected for design review. If received, escalate immediately」が一貫。Impl Auditor のみ SPEC-UPDATE-NEEDED 判定可能 (auditor-impl.md L221-228)。

- **Verdict output format**: 3 Auditor (design/impl/dead-code) の CPF 出力フォーマットが cpf-format.md ルールに準拠。VERDICT, SCOPE, VERIFIED, REMOVED, RESOLVED, STEERING, NOTES セクション。impl-auditor のみ追加で SPEC_FEEDBACK セクション。

- **Web Inspector Server Protocol**: review.md L47-65 で完全なライフサイクル (Start → Dispatch → Stop) 定義。Inspector dispatch 前に server start、全 Inspector 完了後に server stop。dispatch loop context での分解 (L127 step 3a, L132 step 5a) も整合。

- **Design Lookahead**: run.md L157-167 で条件 (依存先が design-generated)、動的計算 (persistent tracking 不要)、staleness guard が定義。Impl は Wave QG 後にゲート (L165)。

- **Island Spec Detection (Wave Bypass)**: run.md L66-79 で検出条件、fast-track 実行フロー、overlap 検出時の demote ロジックが完全。

- **Builder parallel coordination**: CLAUDE.md L80、impl.md L70-83 で incremental processing (done marking, knowledge tags, SelfCheck handling) が詳細に定義。

- **Steering Feedback Loop**: CLAUDE.md L201-203、review.md L102-117 で CODIFY/PROPOSE 処理ルールが整合。verdict handling 後、次フェーズ前に処理。

- **install.sh**: 全 framework ファイル (skills, agents, CLAUDE.md, settings.json, rules, templates, profiles) のインストールパスが framework/ ディレクトリ構造と一致。マイグレーション (kiro→sdd, v0.7.0, v0.9.0, v0.10.0, v0.15.0, v0.18.0, v0.20.0, v1.2.0) が順序通り。stale file removal が正しいパターンマッチ。

---

### Overall Assessment

**総合判定: 良好 (CRITICAL/HIGH なし)**

sdd-roadmap Router から各 refs ファイルへの dispatch フローは高い整合性を持っている。CLAUDE.md での定義と各 refs ファイルでの実装が一貫しており、Phase Gate、Auto-Fix Loop、Verdict Persistence、Counter Management のいずれも矛盾なく定義されている。

検出された問題は MEDIUM 2件、LOW 2件のみ:
1. Cross-Cutting revise の Tier Execution で conventions brief 生成ステップが欠落 — 並列 Builder の一貫性に影響しうる
2. Blocking Protocol の `fix` 選択肢でカウンタリセットが未明記 — CLAUDE.md の「user escalation decision」reset trigger との微妙な不整合

いずれも動作上は Lead の判断で補完可能な範囲であり、フレームワークの core flow を壊すものではない。修正推奨だが緊急性は低い。
