# Agent 3: Consistency & Dead Ends Report

**レビュー日時**: 2026-03-01
**対象**: SDD フレームワーク全ファイル
**レビュー担当**: Agent 3 (Consistency & Dead Ends)

---

## Issues Found

### [CRITICAL]

**C1: CLAUDE.md (framework) の Tool 名称不一致 — `Agent` vs `Task`**

- `framework/claude/CLAUDE.md` line 5: `SubAgent mode via Agent tool with subagent_type parameter`
- `framework/claude/CLAUDE.md` line 32: `Agent(subagent_type="sdd-architect", prompt="...")`
- `framework/claude/CLAUDE.md` line 84: `Lead dispatches SubAgents via Agent tool with run_in_background: true`
- インストール済み `CLAUDE.md`（`/Users/mia/.claude/projects/...CLAUDE.md`）: `SubAgent mode via Task tool with subagent_type parameter`、`Task(subagent_type=...)`
- `framework/claude/skills/sdd-roadmap/refs/run.md` line 33: `Agent(subagent_type="sdd-conventions-scanner", run_in_background=true)`
- `framework/claude/skills/sdd-roadmap/refs/run.md` line 154: `Agent(subagent_type="sdd-architect", run_in_background=true)`

**問題**: `framework/claude/CLAUDE.md` では `Agent` ツール名、`Agent()` 関数呼び出しを使用している。しかし、インストール先 `.claude/` の `CLAUDE.md`（ユーザー環境で実際に適用される文書）では `Task` ツール、`Task()` 呼び出しを使用している。また `refs/run.md` も `Agent(...)` を使用している。framework の CLAUDE.md と refs/*.md の間で一貫して `Agent` を使用しているが、インストール済み CLAUDE.md だけが `Task` を使用している。これはインストール手順の変換ミスか意図的な差異かが不明であり、Lead が実際にどちらのツールを使用すべきかが不明確。

- **ファイル**: `framework/claude/CLAUDE.md` 全体 vs インストール済み CLAUDE.md
- **深刻度**: CRITICAL — 正しい SubAgent ディスパッチ方法が不明になる

---

**C2: sdd-reboot/SKILL.md のステップ説明が refs/reboot.md と不一致**

- `framework/claude/skills/sdd-reboot/SKILL.md` Step 2 記述:
  ```
  3. **Conventions Brief**: Dispatch ConventionsScanner
  ```
- `framework/claude/skills/sdd-reboot/refs/reboot.md` Phase 3:
  ```
  **ConventionsScanner is NOT dispatched during reboot.**
  ```

**問題**: SKILL.md のステップ3に「ConventionsScanner をDispatch」と記載されているが、refs/reboot.md Phase 3 では「ConventionsScanner は reboot 中にはDispatchしない」と明示的に禁止している。Lead が SKILL.md の概要を参照した場合と refs/reboot.md の詳細を参照した場合で正反対の動作をする可能性がある。

- **ファイル**: `framework/claude/skills/sdd-reboot/SKILL.md` line 36 vs `framework/claude/skills/sdd-reboot/refs/reboot.md` Phase 3
- **深刻度**: CRITICAL — reboot時にConventionsScannerを誤って実行する可能性がある

---

**C3: analysis-report.md テンプレートが Analyst エージェント定義と不一致**

- `framework/claude/sdd/settings/templates/reboot/analysis-report.md` には「Strengths」「Weaknesses」「Current Architecture Assessment」「Ideal Architecture」セクションが含まれる
- `framework/claude/agents/sdd-analyst.md` Step 7 の出力形式では: Executive Summary, Requirements, Architecture Alternatives, Steering Changes, Proposed Spec Decomposition, Wave Structure, Deletion Manifest, Key Design Decisions, Risk Assessment — 「Strengths」「Weaknesses」「Current Architecture Assessment」「Ideal Architecture」セクションは存在しない

**問題**: Analyst エージェントが参照するテンプレートと、実際に Analyst が出力する構造が大きく異なる。テンプレートには「現在のアーキテクチャの強み・弱み評価」が含まれるが、Analyst 定義では「No preservation bias: Do NOT assess 'strengths' of the current architecture」と明示的に禁止している。テンプレートが Analyst の制約と矛盾している。

- **ファイル**: `framework/claude/sdd/settings/templates/reboot/analysis-report.md` vs `framework/claude/agents/sdd-analyst.md`
- **深刻度**: CRITICAL — テンプレートとエージェント定義が直接矛盾

---

### [HIGH]

**H1: Inspector のファイル出力パスの SCOPE フィールド不一致（Dead Code Inspectors）**

- `framework/claude/agents/sdd-inspector-dead-code.md` 出力例:
  ```
  SCOPE:dead-code
  ...
  SCOPE:cross-check
  ```
  (内部が矛盾: ヘッダーは `dead-code` だが例は `cross-check`)
- `framework/claude/agents/sdd-inspector-dead-tests.md` 出力例:
  ```
  SCOPE:dead-code
  ...
  SCOPE:cross-check
  ```
  (同様の矛盾)
- `framework/claude/agents/sdd-inspector-dead-settings.md` 出力例:
  ```
  SCOPE:dead-code
  ...
  SCOPE:cross-check
  ```
  (同様の矛盾)
- `framework/claude/agents/sdd-inspector-dead-specs.md` 出力例:
  ```
  SCOPE:dead-code
  ...
  SCOPE:cross-check
  ```
  (同様の矛盾)

**問題**: 4 つの Dead Code Inspector いずれも、出力フォーマット定義では `SCOPE:dead-code` と記載しているが、実際の使用例では `SCOPE:cross-check` を使用している。一貫したSCOPE値が不明。

- **ファイル**: `framework/claude/agents/sdd-inspector-dead-*.md` (4ファイル)
- **深刻度**: HIGH — Auditor が SCOPE フィールドをパースして動作を変える場合に問題になる

---

**H2: Verdict Persistence における Dead Code レビューのパス不一致**

- `framework/claude/skills/sdd-roadmap/refs/review.md` Verdict Destination:
  ```
  **Dead-code review**: {{SDD_DIR}}/project/reviews/dead-code/verdicts.md
  ```
- `framework/claude/skills/sdd-roadmap/refs/run.md` Step 7b:
  ```
  Persist verdict to {{SDD_DIR}}/project/reviews/wave/verdicts.md (header: [W{wave}-DC-B{seq}])
  ```
- `framework/claude/CLAUDE.md` Session Resume 2a:
  ```
  Also check {{SDD_DIR}}/project/reviews/*/verdicts.md for project-level review state (dead-code, cross-check, wave).
  ```

**問題**: Dead Code レビューの verdict 保存先が「wave 内 QG として実行した場合」と「スタンドアロンで実行した場合」で異なる (`reviews/dead-code/` vs `reviews/wave/`)。これは意図的だが、review.md の Verdict Destination テーブルには wave 内 QG ケースが記載されていない。また SKILL.md の `review dead-code` コマンドが standalone で実行した場合にどのパスを使うかが review.md と run.md で矛盾して見える。

- **ファイル**: `framework/claude/skills/sdd-roadmap/refs/review.md` lines 88-148 vs `refs/run.md` Step 7b
- **深刻度**: HIGH — dead-code レビューのアーカイブ先が不明確になる

---

**H3: sdd-review-self SKILL.md の Agent ディスパッチ方法が CLAUDE.md と不一致**

- `framework/claude/skills/sdd-review-self/SKILL.md` Step 4:
  ```
  Agent(subagent_type="general-purpose", model="sonnet", run_in_background=true)
  ```
- `framework/claude/CLAUDE.md`: SubAgent定義は `.claude/agents/` の YAML frontmatter で定義された named agents のみを使用する旨が記載されている

**問題**: `sdd-review-self` は `subagent_type="general-purpose"` という汎用タイプを使用しているが、他のすべての SubAgent ディスパッチは `subagent_type="sdd-architect"` 等の named agent タイプを使用する。`general-purpose` が有効な subagent_type であるかどうかが不明。

- **ファイル**: `framework/claude/skills/sdd-review-self/SKILL.md` line 57
- **深刻度**: HIGH — self-review の動作が不明確

---

**H4: Revise Mode の CLAUDE.md Auto-Fix Counter のリセットタイミングが revise.md と不一致**

- `framework/claude/CLAUDE.md` Auto-Fix Counter Limits:
  ```
  Counter reset triggers: wave completion, user escalation decision (including blocking protocol fix/skip), /sdd-roadmap revise start, session resume
  ```
- `framework/claude/skills/sdd-roadmap/refs/revise.md` Part A Step 4:
  ```
  Reset orchestration.retry_count = 0, orchestration.spec_update_count = 0
  Set phase = design-generated
  ```
  Part B Step 7 (Tier Checkpoint):
  ```
  Reset orchestration.retry_count = 0, spec_update_count = 0 (per spec)
  ```

**問題**: CLAUDE.md では `/sdd-roadmap revise start` がカウンターリセットトリガーとして記載されているが、revise.md では「状態遷移」ステップの一部としてリセットが行われている。これは整合しているが、CLAUDE.md の記載は `revise start` の「開始時」とも読め、Part A Step 4（Design前）のリセットとも、Part B Step 7（各 Tier 完了後）のリセットとも解釈できる。Cross-cutting mode の Tier 毎リセットが CLAUDE.md に記載されていない。

- **ファイル**: `framework/claude/CLAUDE.md` vs `framework/claude/skills/sdd-roadmap/refs/revise.md`
- **深刻度**: HIGH — リセットタイミングの誤解によりカウンター管理が不正確になる

---

**H5: Consensus Mode での B{seq} 決定が review.md と SKILL.md で記述が重複・不整合**

- `framework/claude/skills/sdd-roadmap/SKILL.md` Consensus Mode:
  ```
  Determine review scope directory (see refs/review.md Step 1) and B{seq} from {scope-dir}/verdicts.md (increment max existing, or start at 1)
  ```
- `framework/claude/skills/sdd-roadmap/refs/review.md` Step 2:
  ```
  For consensus mode: Router determines B{seq} once and passes it to all N pipelines (this step uses the Router-provided value instead of computing its own).
  ```

**問題**: B{seq} の決定が SKILL.md（Router）側で行われることが review.md で言及されているが、SKILL.md 自身の Consensus Mode セクション（line 115）は B{seq} を「Router determines」として記載している。一方 review.md Step 2 は「Router-provided value を使う」と記載しており方向性は合っているが、SKILL.md では実際の B{seq} 計算ロジック（increment max existing）が記載されており、これが「Router が計算する」か「Router 経由で渡される」かが不明確。

- **ファイル**: `framework/claude/skills/sdd-roadmap/SKILL.md` line 115 vs `refs/review.md` Step 2
- **深刻度**: HIGH — consensus モードでのバッチ番号が重複する可能性

---

### [MEDIUM]

**M1: Inspector 数のカウント不一致（CLAUDE.md の記述 vs 実際のエージェント数）**

- `framework/claude/CLAUDE.md` T3 Inspector 行:
  ```
  6 design, 6 impl +2 web (impl only, web projects), 4 dead-code
  ```
- `framework/claude/skills/sdd-roadmap/refs/review.md` Design Review:
  ```
  6 design Inspectors: sdd-inspector-rulebase, sdd-inspector-testability, sdd-inspector-architecture, sdd-inspector-consistency, sdd-inspector-best-practices, sdd-inspector-holistic
  ```
- `framework/claude/skills/sdd-roadmap/refs/review.md` Impl Review:
  ```
  Standard impl Inspectors (6, sonnet): sdd-inspector-impl-rulebase, sdd-inspector-interface, sdd-inspector-test, sdd-inspector-quality, sdd-inspector-impl-consistency, sdd-inspector-impl-holistic
  + web: sdd-inspector-e2e, sdd-inspector-visual (+2)
  ```
- `framework/claude/skills/sdd-roadmap/refs/review.md` Dead-Code Review:
  ```
  4 dead-code Inspectors: sdd-inspector-dead-settings, sdd-inspector-dead-code, sdd-inspector-dead-specs, sdd-inspector-dead-tests
  ```

カウントは一致しているが、`sdd-auditor-impl.md` の Mission 記載:
```
Cross-check, verify, and integrate findings from up to 8 independent review agents
```
は web 込みの最大数（6+2=8）を指しているため整合しているが、design auditor は:
```
findings from 6 independent review agents
```
と記載しており設計 Inspector 数と一致。これは問題ない。ただし CLAUDE.md の Inspector 記述は非常に簡潔で、設計 Inspector と impl Inspector の両方に「6」があることが混乱を招く可能性がある。

- **ファイル**: `framework/claude/CLAUDE.md` vs `framework/claude/agents/sdd-auditor-impl.md`
- **深刻度**: MEDIUM — 数字は整合しているが記述が混乱を招く

---

**M2: `refs/run.md` での `session.md` 自動ドラフトの例外説明が不完全**

- `framework/claude/CLAUDE.md` session.md Auto-draft Exception:
  ```
  Exception — run pipeline dispatch loop: Auto-draft only at Wave QG post-gate, user escalation, and pipeline completion. Skip at individual phase completions
  ```
- `framework/claude/skills/sdd-roadmap/refs/run.md` Phase Handlers:
  ```
  Auto-draft policy (dispatch loop): During run pipeline execution, auto-draft session.md only at: Wave QG post-gate, user escalation, pipeline completion.
  ```
- `framework/claude/skills/sdd-reboot/refs/reboot.md` Phase 7:
  ```
  Auto-draft policy: Auto-draft session.md only at wave completion (all specs in wave design-reviewed) and pipeline completion. Skip at individual spec phase completions
  ```

**問題**: reboot の auto-draft ポリシーは「user escalation」が含まれていないが、run モードには含まれている。reboot 中に user escalation が発生した場合の auto-draft 動作が不明。

- **ファイル**: `framework/claude/skills/sdd-reboot/refs/reboot.md` Phase 7 vs `refs/run.md` Phase Handlers
- **深刻度**: MEDIUM — reboot 中の escalation 時の session.md 動作が未定義

---

**M3: `sdd-inspector-dead-specs.md` の SCOPE フォーマット例が review.md の定義と不整合**

- `framework/claude/agents/sdd-inspector-dead-specs.md` 出力フォーマット:
  ```
  SCOPE:dead-code
  ```
  しかし例では:
  ```
  SCOPE:cross-check
  ```
- `framework/claude/skills/sdd-roadmap/refs/review.md` Verdict Destination:
  ```
  Dead-code review: {{SDD_DIR}}/project/reviews/dead-code/verdicts.md
  ```

SCOPE の値として `dead-code` と `cross-check` のどちらが正しいかが Inspector 定義内で矛盾している（H1 と関連）。加えて、review.md にはこれらの Inspector が何の SCOPE 値を出力すべきかの規定がない。

- **ファイル**: `framework/claude/agents/sdd-inspector-dead-specs.md` 出力フォーマット
- **深刻度**: MEDIUM（H1 の一部として HIGH に集約することも可）

---

**M4: `revise.md` Part B Step 8 の Cross-Cutting Consistency Review のカウンター上限が CLAUDE.md と不一致**

- `framework/claude/skills/sdd-roadmap/refs/revise.md` Part B Step 8:
  ```
  Max 5 retries (aggregate cap 6)
  ```
- `framework/claude/CLAUDE.md` Auto-Fix Counter Limits:
  ```
  retry_count: max 5 (NO-GO only). spec_update_count: max 2 (SPEC-UPDATE-NEEDED only). Aggregate cap: 6.
  ```

Step 8 は Cross-Cutting Consistency Review（cross-check 相当）の NO-GO 処理で「Max 5 retries (aggregate cap 6)」と記載。これ自体は CLAUDE.md と整合しているが、Step 8 には `spec_update_count` の処理が記載されておらず、SPEC-UPDATE-NEEDED 発生時の動作が未定義。run.md Step 7a の cross-check では SPEC-UPDATE-NEEDED への対処が記載されているが、revise.md Part B Step 8 には記載がない。

- **ファイル**: `framework/claude/skills/sdd-roadmap/refs/revise.md` Part B Step 8
- **深刻度**: MEDIUM — cross-cutting revise の cross-check で SPEC-UPDATE-NEEDED が発生した場合の処理が未定義

---

**M5: Steering テンプレートの `specs/init.yaml` への参照が検証できない**

- `framework/claude/skills/sdd-roadmap/SKILL.md` line 76:
  ```
  initialize spec.yaml from {{SDD_DIR}}/settings/templates/specs/init.yaml
  ```
- `framework/claude/skills/sdd-reboot/refs/reboot.md` Phase 6c:
  ```
  Initialize spec.yaml from {{SDD_DIR}}/settings/templates/specs/init.yaml
  ```

`init.yaml` テンプレートは `framework/claude/sdd/settings/templates/specs/` に存在しない（`design.md` と `research.md` のみ確認）。ターゲットファイルが実際に存在するかどうかが不明。

- **ファイル**: `framework/claude/skills/sdd-roadmap/SKILL.md` line 76、`refs/reboot.md` Phase 6c
- **深刻度**: MEDIUM — `init.yaml` が存在しない場合、spec 初期化が失敗する
<br>→ *注意: 実際のインストール先 `.sdd/` ディレクトリにも init.yaml が存在しない可能性があるが、本レビューの対象外のためファイル存在確認は未実施*

---

**M6: `sdd-conventions-scanner.md` の Supplement モード入力に Steering パスが含まれない**

- `framework/claude/agents/sdd-conventions-scanner.md` Mode: Supplement の Input:
  ```
  - Builder report path
  - Existing brief path
  - Output path
  ```
- `framework/claude/skills/sdd-roadmap/refs/impl.md` Pilot Stagger Protocol Step 3:
  ```
  Dispatch sdd-conventions-scanner SubAgent (mode: Supplement) with:
  - Builder report path: ...
  - Existing brief path: ...
  - Output path: ...
  ```

Supplement モードには Steering パスが渡されないが、Generate モードには渡される。Supplement モードでも Steering と conventions brief の矛盾を検出するために Steering を参照する必要があるかどうかが未定義。

- **ファイル**: `framework/claude/agents/sdd-conventions-scanner.md` Mode: Supplement
- **深刻度**: MEDIUM — Steering 参照なしで conventions が Steering と矛盾する可能性

---

**M7: `sdd-auditor-design.md` の SCOPE フィールド値が review.md の定義と部分的に不一致**

- `framework/claude/agents/sdd-auditor-design.md` 出力フォーマット:
  ```
  SCOPE:{feature} | cross-check | wave-scoped-cross-check
  ```
- `framework/claude/agents/sdd-auditor-impl.md` 出力フォーマット（同一）:
  ```
  SCOPE:{feature} | cross-check | wave-scoped-cross-check
  ```
- Inspector の SCOPE 出力フォーマット（sdd-inspector-rulebase.md 等）:
  ```
  SCOPE:{feature} | cross-check | wave-1..{N}
  ```

**問題**: Auditor は `wave-scoped-cross-check` を SCOPE に使用するが、Inspector は `wave-1..{N}` を使用する。Auditor が Inspector の CPF ファイルを読み取るときに SCOPE フィールドの解釈が異なる。Auditor の Input Handling では「wave number provided」時の処理を定義しているが、Inspector から受け取る SCOPE 値と Auditor が output する SCOPE 値が異なるフォーマット。

- **ファイル**: `framework/claude/agents/sdd-auditor-design.md` vs `framework/claude/agents/sdd-inspector-rulebase.md`
- **深刻度**: MEDIUM — SCOPE 値のフォーマット不統一

---

**M8: `sdd-review-self/SKILL.md` の Self-Review verdict パスが review.md Verdict Destination と不一致**

- `framework/claude/skills/sdd-review-self/SKILL.md` Step 3:
  ```
  $SCOPE_DIR = {{SDD_DIR}}/project/reviews/self/
  ```
  および Step 6.1:
  ```
  Append batch entry to $SCOPE_DIR/verdicts.md
  ```
- `framework/claude/skills/sdd-roadmap/refs/review.md` Verdict Destination:
  ```
  Self-review (framework-internal): {{SDD_DIR}}/project/reviews/self/verdicts.md
  ```

一致しているが、`sdd-review-self` は `sdd-roadmap` の一部ではないため、review.md での記載が何を意味するかが不明。`sdd-review-self` は独立したスキルであり、`sdd-roadmap` の `review.md` がその verdict パスを定義する必要があるかどうかが疑問。

- **ファイル**: `framework/claude/skills/sdd-roadmap/refs/review.md` Verdict Destination vs `framework/claude/skills/sdd-review-self/SKILL.md`
- **深刻度**: MEDIUM（設計上の整合性の問題、動作上の問題はない）

---

**M9: `buffer.md` テンプレートのソース形式が impl.md のタグ抽出と不一致**

- `framework/claude/sdd/settings/templates/handover/buffer.md`:
  ```
  (source: {spec} {role}, task {N})
  ```
- `framework/claude/skills/sdd-roadmap/refs/impl.md` Step 3:
  ```
  append to {{SDD_DIR}}/handover/buffer.md with source (source: {feature} Builder, group {G})
  ```

テンプレートでは `{role}` と `task {N}` が形式だが、impl.md の実際の書き込み形式は `Builder, group {G}` であり形式が一致しない。

- **ファイル**: `framework/claude/sdd/settings/templates/handover/buffer.md` vs `framework/claude/skills/sdd-roadmap/refs/impl.md`
- **深刻度**: MEDIUM — buffer.md の記録形式が不統一になる

---

### [LOW]

**L1: `design-review.md` の Severity 記述が CPF フォーマットと異なる表現を使用**

- `framework/claude/sdd/settings/rules/design-review.md` Section Severity Classification:
  ```
  ### Critical (🔴) / ### Warning (🟡)
  ```
  および CPF マッピング:
  ```
  Critical (🔴) → C or H
  Warning (🟡) → M or L
  ```
- `framework/claude/sdd/settings/rules/cpf-format.md`:
  ```
  Severity codes: C=Critical, H=High, M=Medium, L=Low
  ```

design-review.md は独自の 2 段階 severity（Critical/Warning）を使用し、CPF の C/H/M/L へのマッピングを提供している。ただし Inspector 定義ファイルは直接 C/H/M/L を使用しており、design-review.md の 2 段階システムが混乱を生む可能性がある。

- **ファイル**: `framework/claude/sdd/settings/rules/design-review.md` vs `framework/claude/sdd/settings/rules/cpf-format.md`
- **深刻度**: LOW — Inspector の出力には影響しないが、ルールファイルの不統一

---

**L2: `sdd-inspector-best-practices.md` に Wave-Scoped Cross-Check Mode は定義されているが、Cross-Check Mode のコンテキストロード手順が欠落**

- `framework/claude/agents/sdd-inspector-best-practices.md` Load Context:
  - Single Spec Mode: 定義あり
  - Wave-Scoped Cross-Check Mode: 定義あり
  - Cross-Check Mode: 定義あり（「All Specs」のみ）

Cross-Check Mode では steering 全体を読む旨の記載があるが、他の Inspector（rulebase 等）と比較して Cross-Check Mode のローカルロード手順が簡潔すぎる。動作に影響はないが記述の詳細度が不統一。

- **ファイル**: `framework/claude/agents/sdd-inspector-best-practices.md`
- **深刻度**: LOW

---

**L3: `sdd-inspector-impl-holistic.md` の Wave-Scoped モードで `tasks.yaml` を読むが、設計 Inspector は読まない**

- `framework/claude/agents/sdd-inspector-impl-holistic.md` Wave-Scoped Step 4:
  ```
  For each spec where wave <= N: Read design.md + tasks.yaml
  ```
- `framework/claude/agents/sdd-inspector-holistic.md`（design版）Wave-Scoped Step 4:
  ```
  For each spec where wave <= N: Read design.md
  ```

impl 版は tasks.yaml も読むが、holistic インスペクター定義として「tasks.yaml からの情報が holistic レビューに必要か」という理由が明記されていない。他の impl Inspector（consistency、interface）も Wave-Scoped で `design.md + tasks.yaml` を読むため、これは意図的な差異と考えられるが、明示的な説明がない。

- **ファイル**: `framework/claude/agents/sdd-inspector-impl-holistic.md` vs `framework/claude/agents/sdd-inspector-holistic.md`
- **深刻度**: LOW — 動作上の問題はなく意図的な差異と思われる

---

**L4: `sdd-conventions-scanner.md` の完了報告が他 SubAgent と形式が異なる**

- `framework/claude/agents/sdd-conventions-scanner.md` Output:
  ```
  Return ONLY WRITTEN:{output_path} as your final text.
  ```
- 他の SubAgent（sdd-builder.md、sdd-architect.md 等）:
  それぞれ独自の完了報告フォーマット（BUILDER_COMPLETE、ARCHITECT_COMPLETE 等）を使用

ConventionsScanner は `WRITTEN:{path}` のみを返し、Inspector/Auditor と同様のパターンを採用。これは意図的（CLAUDE.md の「SubAgent は結果を最小化すべき」方針に従う）だが、run.md の ConventionsScanner ディスパッチ後の処理が「Wait for WRITTEN:{path} response」と明記されており整合している。ただし sdd-review-self の Agent 4 や他の箇所での参照が一貫しているか確認が必要。

- **ファイル**: `framework/claude/agents/sdd-conventions-scanner.md`
- **深刻度**: LOW — 意図的な差異だが明示的な理由付けがない

---

**L5: `sdd-release/SKILL.md` に `Co-Authored-By` コミットシグネチャの言及がない**

- `framework/claude/CLAUDE.md` Git Workflow Commit Timing:
  ```
  All commits MUST end with Co-Authored-By: sync-sdd <noreply@sync-sdd>
  ```
- `framework/claude/skills/sdd-release/SKILL.md` Step 5:
  ```
  Stage all changed files and commit: {summary} (v{version})
  ```

release スキルのコミット手順には `Co-Authored-By` 署名の追加が記載されていない。CLAUDE.md の「all commits MUST end with」という要件が release コミットにも適用されるが、SKILL.md でこれを明示していない。

- **ファイル**: `framework/claude/skills/sdd-release/SKILL.md` Step 5
- **深刻度**: LOW — CLAUDE.md の全体ルールで覆われているが、SKILL.md での明示がない

---

**L6: `sdd-reboot/refs/reboot.md` Phase 10 のコミットメッセージフォーマット確認**

- `framework/claude/skills/sdd-reboot/refs/reboot.md` Phase 10 Step 2:
  ```
  reboot: {1-line summary of redesign}
  ```
- `framework/claude/CLAUDE.md` Commit Timing:
  ```
  reboot: {summary} (reboot redesign)
  ```

CLAUDE.md のコミットフォーマット記述では `(reboot redesign)` という括弧付き説明があるが、refs/reboot.md では `{1-line summary}` のみ。これは CLAUDE.md の記載が「形式の説明」か「実際のコミットメッセージ」かが不明。

- **ファイル**: `framework/claude/CLAUDE.md` Commit Timing vs `framework/claude/skills/sdd-reboot/refs/reboot.md` Phase 10
- **深刻度**: LOW — コミットメッセージ形式の軽微な不一致

---

## Cross-Reference Matrix

| ファイル | 参照先 | 参照の種類 | 問題 |
|---------|--------|-----------|------|
| `CLAUDE.md` | `sdd-roadmap refs/run.md` | 詳細参照 | Agent vs Task ツール名 (C1) |
| `CLAUDE.md` | `sdd-roadmap refs/review.md` | 詳細参照 | 整合 |
| `CLAUDE.md` | `sdd-roadmap refs/revise.md` | 詳細参照 | Counter reset 記述 (H4) |
| `sdd-reboot/SKILL.md` | `refs/reboot.md` | 詳細実行 | ConventionsScanner 矛盾 (C2) |
| `sdd-roadmap/SKILL.md` | `refs/design.md` | 実行参照 | 整合 |
| `sdd-roadmap/SKILL.md` | `refs/impl.md` | 実行参照 | 整合 |
| `sdd-roadmap/SKILL.md` | `refs/review.md` | 実行参照 | Consensus B{seq} (H5) |
| `sdd-roadmap/SKILL.md` | `refs/run.md` | 実行参照 | 整合 |
| `sdd-roadmap/SKILL.md` | `refs/revise.md` | 実行参照 | 整合 |
| `sdd-roadmap/SKILL.md` | `refs/crud.md` | 実行参照 | 整合 |
| `refs/run.md` | `refs/design.md` | Phase参照 | 整合 |
| `refs/run.md` | `refs/impl.md` | Phase参照 | 整合 |
| `refs/run.md` | `refs/review.md` | Phase参照 | Dead Code パス (H2) |
| `refs/revise.md` | `refs/run.md` | Protocol参照 | Step 8 SPEC-UPDATE (M4) |
| `refs/revise.md` | `refs/design.md` | Phase参照 | 整合 |
| `refs/revise.md` | `refs/impl.md` | Phase参照 | 整合 |
| `refs/revise.md` | `refs/review.md` | Phase参照 | 整合 |
| `sdd-auditor-design.md` | Inspector CPF | 読み取り | SCOPE形式不一致 (M7) |
| `sdd-auditor-impl.md` | Inspector CPF | 読み取り | SCOPE形式不一致 (M7) |
| `analysis-report.md` (template) | `sdd-analyst.md` | テンプレート使用 | 構造不一致 (C3) |
| `buffer.md` (template) | `refs/impl.md` | ソース形式 | 形式不一致 (M9) |
| `sdd-conventions-scanner.md` | `refs/run.md`, `refs/impl.md` | ディスパッチ参照 | Supplement入力 (M6) |
| `specs/init.yaml` | `SKILL.md`, `refs/reboot.md` | テンプレート参照 | ファイル未確認 (M5) |
| `sdd-review-self/SKILL.md` | `refs/review.md` | Verdict path | 意図的な独立 (M8) |
| `settings.json` | `agents/sdd-*.md` | Permission | 整合（全26エージェント一致） |

---

## Confirmed OK

- **Phase 名称**: `initialized` → `design-generated` → `implementation-complete` / `blocked` — CLAUDE.md、refs/*.md、全 Inspector 定義で統一されている
- **Verdict 値（設計・実装レビュー）**: `GO`, `CONDITIONAL`, `NO-GO`, `SPEC-UPDATE-NEEDED` — CLAUDE.md、Auditor 定義、run.md で統一
- **Verdict 値（Dead Code レビュー）**: `GO`, `CONDITIONAL`, `NO-GO`（SPEC-UPDATE-NEEDED なし）— Dead Code Auditor と整合
- **CPF フォーマット**: Severity コード C/H/M/L — cpf-format.md と全 Inspector/Auditor で統一
- **SubAgent 名称**: `sdd-architect`, `sdd-builder`, `sdd-taskgenerator`, `sdd-analyst`, `sdd-auditor-design`, `sdd-auditor-impl`, `sdd-auditor-dead-code`, `sdd-conventions-scanner` — CLAUDE.md、settings.json、refs/*.md で統一
- **settings.json の permissions**: 26エージェント全員が `framework/claude/agents/` に対応するファイルを持つ（sdd-inspector-* 14体、他 12体）
- **Inspector セット（設計レビュー）**: 6体 — CLAUDE.md、review.md、auditor-design.md で一致
- **Inspector セット（実装レビュー）**: 6+2(web) — CLAUDE.md、review.md、auditor-impl.md で一致
- **Inspector セット（Dead Code）**: 4体 — CLAUDE.md、review.md、auditor-dead-code.md で一致
- **retry_count 上限**: 5（NO-GO）— CLAUDE.md、run.md、revise.md で一致
- **spec_update_count 上限**: 2（SPEC-UPDATE-NEEDED）— CLAUDE.md、run.md で一致
- **aggregate cap**: 6 — CLAUDE.md、run.md、revise.md で一致
- **Dead Code NO-GO リトライ上限**: 3 — CLAUDE.md、run.md で一致（in-memory tracking の注記も一致）
- **SDD_DIR**: `.sdd` — CLAUDE.md、全 refs、全 agent 定義で統一
- **レビューアーカイブパス**: `reviews/B{seq}/` — review.md Step 9、CLAUDE.md で一致
- **Wave QG のアーカイブ先**: `reviews/wave/verdicts.md` — run.md Step 7、CLAUDE.md Session Resume で一致
- **Cross-cutting verdict パス**: `specs/.cross-cutting/{id}/verdicts.md` — revise.md Step 8、SKILL.md Verdict Persistence で一致
- **ConventionsScanner Generate モード**: run.md Step 2.5 と conventions-scanner.md で入力・出力が整合
- **Pilot Stagger Protocol**: impl.md と conventions-scanner.md の Supplement モードで整合
- **SubAgent の run_in_background**: 全ディスパッチポイントで `run_in_background: true` が明示されている（CLAUDE.md の「always」要件に整合）
- **spec.yaml の所有者**: Lead のみ — CLAUDE.md Artifact Ownership、全 SubAgent の「Do NOT update spec.yaml」記載で一致
- **decisions.md**: Append-only — CLAUDE.md、handover SKILL.md で一致
- **STEERING フィードバックループ**: CODIFY/PROPOSE — CLAUDE.md、review.md、auditor-design.md、auditor-impl.md で一致
- **tasks.yaml フォーマット**: tasks-generation.md の YAML 構造と taskgenerator.md の出力が整合
- **Wave Bypass（Island Spec）**: run.md Step 3 と CLAUDE.md Parallel Execution Model で整合
- **Design Lookahead**: run.md Step 4 と CLAUDE.md Parallel Execution Model で整合
- **reboot Phase 1-4**: SKILL.md のステップ説明と refs/reboot.md の Phase 1-2, 4 の詳細が整合
- **Builder completion report**: builder.md の BUILDER_COMPLETE フォーマットと impl.md の incremental processing が整合
- **知識タグ**: [PATTERN], [INCIDENT], [REFERENCE] — CLAUDE.md、builder.md、conventions-scanner.md で統一

---

## Overall Assessment

**深刻度 CRITICAL: 3件**

最も重要な問題は、`framework/claude/CLAUDE.md` と refs ファイルが `Agent` ツール、`Agent()` 呼び出しを使用しているが、インストール済み CLAUDE.md が `Task` ツールを使用している点（C1）。これはフレームワークの根幹であるSubAgentディスパッチ方法に関わる。次に `sdd-reboot/SKILL.md` が ConventionsScanner をDispatchすると記載しているが、`refs/reboot.md` が明示的に禁止している矛盾（C2）。また `analysis-report.md` テンプレートが Analyst エージェントの定義と構造的に矛盾している点（C3）も重要。

**深刻度 HIGH: 5件**

Dead Code Inspector の SCOPE 値の内部矛盾（H1）、Dead Code レビューの verdict 保存先の文脈依存性が不明確（H2）、self-review での `general-purpose` subagent_type（H3）、revise の Counter リセット記述の曖昧さ（H4）、Consensus Mode の B{seq} 決定ロジックの重複・不整合（H5）。

**推奨修正優先度**:
1. C1: `framework/claude/CLAUDE.md` のツール名を統一（Agent vs Task — どちらが正しいか確定する）
2. C2: `sdd-reboot/SKILL.md` Step 3 の記述を refs/reboot.md と一致させる
3. C3: `analysis-report.md` テンプレートを Analyst 定義に合わせて更新
4. H1/M3: Dead Code Inspector の SCOPE 値を統一する
5. H2: review.md の Verdict Destination に wave QG 内での dead-code パスを追加
6. M5: `specs/init.yaml` テンプレートの存在を確認・作成
