## Flow Integrity Report

### Issues Found

- [MEDIUM] M1: install.sh v1.2.0 マイグレーションでプロファイルディレクトリが移行対象外 / install.sh:388
  - **詳細**: v1.2.0 マイグレーションブロック (`version_lt "$INSTALLED_VERSION" "1.2.0"`) では `settings`, `project`, `handover` の3ディレクトリを `.claude/sdd/` から `.sdd/` に移行する。しかしインストール先は `rules`, `templates`, `profiles` の3つ (`install_dir` 呼び出し、行513-515)。`profiles` は `settings/profiles/` としてネストされているため `settings/` の移行で含まれるが、**移行対象リスト (`for dir in settings project handover`) に明示されていない点が紛らわしい**。機能上は `settings/` が移行されれば `settings/profiles/` も移行されるため実害はないが、可読性の観点で `settings` の移行が profiles を包含することを明示すべき。

- [MEDIUM] M2: CLAUDE.md `{{SDD_DIR}}` 定義と refs 内の `{{SDD_DIR}}` 展開タイミングの未定義 / framework/claude/CLAUDE.md:113
  - **詳細**: CLAUDE.md は `{{SDD_DIR}}` = `.sdd` と定義する。refs ファイル群 (design.md, impl.md, review.md, run.md, revise.md, crud.md) および agent 定義すべてで `{{SDD_DIR}}` が使用されている。この変数は CLAUDE.md が install.sh により `.claude/CLAUDE.md` に書き込まれる際に `sed` で `{{SDD_VERSION}}` のみ展開されるが、`{{SDD_DIR}}` は展開されずテンプレート変数として残る。Lead が読み取り時にインラインで `.sdd` に解決する前提だが、この解決メカニズムは CLAUDE.md に宣言されているだけで、各 SubAgent が `{{SDD_DIR}}` をどう解決するかは明示されていない。SubAgent は CLAUDE.md を読まない (Lead が Task prompt でパスを渡す) ため、SubAgent 側では Agent プロファイル内の `{{SDD_DIR}}` がそのまま残る。
  - **影響**: Agent プロファイル (sdd-architect.md 等) が `{{SDD_DIR}}/project/specs/...` を参照しているが、SubAgent は CLAUDE.md を読まないため `{{SDD_DIR}}` が未展開の可能性がある。ただし Claude Code プラットフォームが CLAUDE.md を全コンテキストに注入する仕組みなら問題ない。

- [MEDIUM] M3: Revise Mode (Part A) Step 4 で `phase = design-generated` に設定するが design.md はまだ更新されていない / framework/claude/skills/sdd-roadmap/refs/revise.md:63-65
  - **詳細**: Part A Step 4 (State Transition) で `phase = design-generated` に設定し、Step 5 で Design pipeline を実行する。Design pipeline の refs/design.md Step 2 は `phase` が `design-generated` の場合を「Otherwise: no phase restriction」として通過させる。しかし、Step 5 で Architect を呼び出す際の refs/design.md は `spec.yaml.phase` = `design-generated` を見る。refs/design.md Step 2 は `design-generated` なら通過するが、これは「re-designing」ではないため `implementation-complete` 時の警告メッセージは出ない。このフローは正常に動作するが、revise.md 独自の state transition + design.md の phase gate の相互作用が暗黙的。revise モードからの呼び出しであることを refs/design.md が認識する仕組みがない。
  - **影響**: 機能的には問題なし (design-generated で通過する)。ただし、refs/design.md Step 2 の phase gate と revise.md の state transition の整合性が暗黙的。

- [MEDIUM] M4: Cross-Cutting Mode (Part B) Step 7 Tier Execution で counter reset が各 spec 個別だが、aggregate cap はどのスコープで計算するか不明確 / framework/claude/skills/sdd-roadmap/refs/revise.md:207-209
  - **詳細**: Step 7 の State Transition で `retry_count = 0`, `spec_update_count = 0` をリセットする。CLAUDE.md は「Counter reset triggers: wave completion, user escalation decision, `/sdd-roadmap revise` start」と記述。revise 開始時のリセットは Part A Step 4 および Part B Step 7 で実施。Tier 内の auto-fix loop は run.md の counter limits (retry max 5, spec_update max 2, aggregate cap 6) を参照。Cross-Cutting Mode の Tier 実行中に spec A が retry 5 回消費し、同じ Tier の spec B も retry を必要とする場合、aggregate cap はスペック単位で独立なのか Tier 単位で共有なのかが不明確。
  - **影響**: CLAUDE.md の aggregate cap 定義は spec 単位 (`retry_count + spec_update_count`) と読めるが、Cross-Cutting Mode での明示的な言及がない。実際は spec 単位であり問題はないと推察されるが、明文化されていない。

- [LOW] L1: CLAUDE.md Inspector カウントが 6+6+2+4 だが、agent ファイルは正確に一致するか要確認 / framework/claude/CLAUDE.md:26
  - **詳細**: CLAUDE.md は「6 design, 6 impl +2 web (impl only, web projects), 4 dead-code」と記載。
    - Design inspectors (6): rulebase, testability, architecture, consistency, best-practices, holistic -- 6 agents 確認済 OK
    - Impl inspectors (6+2): impl-rulebase, interface, test, quality, impl-consistency, impl-holistic + e2e, visual -- 8 agents 確認済 OK
    - Dead-code inspectors (4): dead-settings, dead-code, dead-specs, dead-tests -- 4 agents 確認済 OK
  - **結果**: カウント一致。問題なし (Confirmed OK に移動可能)。

- [LOW] L2: review.md Verdict Destination に `cross-cutting` と `self-review` が含まれるが、SKILL.md Router には cross-cutting review の直接ルートがない / framework/claude/skills/sdd-roadmap/refs/review.md:128-129
  - **詳細**: review.md は verdict destination として `specs/.cross-cutting/{id}/verdicts.md` と `{{SDD_DIR}}/project/reviews/self/verdicts.md` を記載。cross-cutting review は revise.md Part B Step 8 から呼び出される (run.md Step 7a と同じメカニズム)。self-review は sdd-review-self skill から呼び出される。これらは SKILL.md Router 経由ではなく他のスキルから呼び出されるため、Router にルートがないのは正しい。ただし、review.md にこれらの destination が列挙されていることで、「Router からすべてアクセス可能」と誤解されうる。
  - **影響**: 情報の完全性としては正しい (review.md はすべての verdict destination のカタログとして機能している) が、注記があるとより明確。

- [LOW] L3: settings.json に test/lint/build 系 Bash コマンドの許可がない / framework/claude/settings.json
  - **詳細**: settings.json の `permissions.allow` には `Bash(git *)`, `Bash(mkdir *)`, `Bash(playwright-cli *)`, `Bash(npm *)` 等があるが、プロジェクト固有のテスト・ビルドコマンド (例: `Bash(uv *)`, `Bash(pytest *)`, `Bash(cargo *)`) は含まれていない。これはフレームワークのデフォルト設定であり、プロジェクト固有のコマンドはユーザーが `settings.local.json` で追加する想定。しかし、Builder agent (`sdd-builder.md`) は `Bash` ツールを持ち、テスト実行が TDD サイクルの核心。`defaultMode: acceptEdits` により Bash 全般は承認モードで動作するが、未許可コマンドはユーザーに確認を求める。
  - **影響**: フレームワークとしての設計は正しい (プロジェクト固有コマンドは含めない)。ただし `defaultMode: acceptEdits` の意味は「ファイル編集は自動承認、Bash は未許可なら確認」であるため、Builder のテスト実行はユーザー確認が必要になる。profiles/ の Suggested Permissions で対応する設計。

### Confirmed OK

- **Router dispatch completeness**: SKILL.md の Detect Mode (Step 1) で全サブコマンドが正しく refs にルーティングされている
  - `design` -> refs/design.md
  - `impl` -> refs/impl.md
  - `review design|impl|dead-code` -> refs/review.md
  - `run` / `run --gate` / `run --consensus N` -> refs/run.md
  - `revise {feature}` -> refs/revise.md (Part A: Single-Spec)
  - `revise [instructions]` (feature なし) -> refs/revise.md (Part B: Cross-Cutting)
  - `create` / `update` / `delete` -> refs/crud.md
  - `-y` -> auto-detect
  - `""` -> auto-detect with user choice

- **Phase gate consistency**: 各 refs の phase gate は CLAUDE.md の phase 定義 (`initialized`, `design-generated`, `implementation-complete`, `blocked`) と整合
  - design.md: blocked -> BLOCK, implementation-complete -> warn+confirm, initialized/design-generated -> proceed, unknown -> BLOCK
  - impl.md: blocked -> BLOCK, design-generated -> proceed, implementation-complete -> proceed (re-execution), other -> BLOCK
  - review.md: design review requires design.md + not blocked, impl review requires phase=implementation-complete + not blocked, dead-code has no phase gate
  - revise.md: requires phase=implementation-complete + not blocked (both Part A and Part B)

- **Auto-fix loop consistency**: CLAUDE.md の counter limits と refs の処理が整合
  - `retry_count` max 5 (NO-GO): run.md Step 4 Design Review handler (line 113), Impl Review handler (line 128), Wave QG (line 171), Dead-code (line 182)
  - `spec_update_count` max 2 (SPEC-UPDATE-NEEDED): run.md Impl Review handler (line 129)
  - Aggregate cap 6: run.md line 130
  - Dead-code max 3: run.md line 182
  - CONDITIONAL = GO: run.md line 112, 127 (counters NOT reset)
  - Counter reset on wave completion: run.md Post-gate (line 185)
  - Counter reset on revise start: revise.md Part A Step 4 (line 63-64), Part B Step 7 (line 207-209)

- **Wave Quality Gate flow**: run.md Step 7 は完全
  - a. Impl Cross-Check Review (wave-scoped) + verdict handling (GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED)
  - b. Dead Code Review + verdict handling (GO/CONDITIONAL/NO-GO, max 3 retries)
  - c. Post-gate: counter reset, knowledge flush, commit, session.md auto-draft
  - 1-Spec Roadmap: Step 7 スキップ (line 162)

- **Consensus mode**: SKILL.md Shared Protocols に定義、review.md から参照。矛盾なし
  - active-{p}/ ディレクトリ分離
  - N=1 (default) は active/ (suffix なし)
  - Threshold: ceil(N*0.6)
  - Archive: active-{p}/ -> B{seq}/pipeline-{p}/

- **Verdict persistence format**: SKILL.md で定義されたフォーマットが全 review type で一貫
  - B{seq} ベースのバッチ番号
  - verdicts.md への追記
  - review.md Step 8 で persist、Step 9 で archive
  - run.md Wave QG で `[W{wave}-B{seq}]` と `[W{wave}-DC-B{seq}]` のヘッダー
  - revise.md Cross-Cutting で `specs/.cross-cutting/{id}/verdicts.md` に persist

- **Edge cases 処理**:
  - Empty roadmap: SKILL.md Single-Spec Roadmap Ensure が auto-create する
  - 1-spec roadmap: SKILL.md §1-Spec Roadmap Optimizations (Wave QG skip, cross-spec skip, dead-code skip, commit format)
  - Blocked spec: phase gate で BLOCK
  - Retry limit exhaustion: run.md Blocking Protocol (Step 6) で downstream cascade + user options (fix/skip/abort)

- **Read clarity**: SKILL.md Execution Reference (line 96-105) で明示的に「Read the reference file for the detected mode」と記載。refs ファイルの読み込みタイミングが明確。

- **Revise modes routing**: revise.md の Mode Detection が SKILL.md Detect Mode と正しく接続
  - `revise {feature} [instructions]` -> feature matches known spec -> Part A (Single-Spec)
  - `revise [instructions]` -> no feature name -> Part B (Cross-Cutting)
  - Escalation: Part A Step 3 -> 2+ affected specs -> propose switch to Part B (user choice)
  - Part A Step 6 option (d) -> switch to Part B (user choice)

- **File-based review protocol**: Inspector -> active/ directory -> Auditor reads -> verdict.cpf -> Lead reads -> verdicts.md persist -> archive to B{seq}/. 完全な循環。

- **SubAgent dispatch**: すべてのエージェントが `run_in_background: true` で dispatch される規約が CLAUDE.md で明記 (line 78) され、refs で一貫して使用。

- **Artifact ownership**: CLAUDE.md の制約と refs の実装が整合。Lead は spec.yaml のみ更新、SubAgent は artifacts を生成して返却。

- **Builder incremental processing**: impl.md Step 3 で Builder 完了ごとに即座に tasks.yaml 更新 + knowledge tags 収集。最終 spec.yaml 更新は ALL Builders 完了後。

- **Knowledge auto-accumulation**: Builder -> tags in completion report -> Lead writes buffer.md -> wave completion (run.md Post-gate) or 1-spec (impl.md Step 4) -> knowledge/ directory. 完全。

- **Handover write triggers**: CLAUDE.md の table と各 refs の Post-Completion section が整合。

- **Session resume**: CLAUDE.md の Resume protocol が verdicts.md の読み取り (step 2a) を含む。

- **install.sh path migration**: v1.2.0 マイグレーションが `.claude/sdd/` -> `.sdd/` を正しく実装。CLAUDE.md, steering-principles.md, install.sh の全ファイルで path が更新済み。framework ソース内に `.claude/sdd` 参照残存なし。

- **settings.json**: 全 24 agent プロファイルが `Task(sdd-*)` として許可されている。全 7 skill が `Skill(sdd-*)` として許可されている。`defaultMode: acceptEdits` により、未許可の Bash コマンドはユーザー確認で実行可能。

- **Agent frontmatter**: 全 agent の `background: true` が設定されている (v1.0.3 で追加確認済み)。

- **CPF format**: cpf-format.md の定義と全 Auditor/Inspector の output format が整合。

- **Steering Feedback Loop**: review.md の Steering Feedback Loop Processing が CLAUDE.md の定義と整合。CODIFY は auto-apply、PROPOSE は user approval。Auditor 出力の STEERING セクションと一致。

- **Cross-Cutting revision flow**: revise.md Part B は以下の完全なフローを定義:
  Step 1 (Intent) -> Step 2 (Impact Analysis) -> Step 3 (Restructuring Check) -> Step 4 (Brief) -> Step 5 (Triage) -> Step 6 (Tier Planning) -> Step 7 (Tier Execution) -> Step 8 (Consistency Review) -> Step 9 (Post-Completion)

- **Design Lookahead**: run.md Step 4 の Dispatch Loop に Design Lookahead が統合。Staleness guard (NO-GO 時の lookahead invalidation) も定義。

- **Island Spec (Wave Bypass)**: run.md Step 3 で island spec 検出、fast-track lane で並列実行、file ownership overlap 検出時に wave-bound にデモート。

### Overall Assessment

**全体評価: 良好 (Good)**

sdd-roadmap Router から refs への dispatch flow は正確かつ完全に機能している。主要なフロー (design -> impl -> review -> run, revise single-spec, revise cross-cutting) はすべて整合性が取れており、phase gate, auto-fix loop, verdict persistence, consensus mode, wave quality gate のいずれも CLAUDE.md の定義と矛盾がない。

v1.2.0 の path migration (`.claude/sdd/` -> `.sdd/`) は framework ソース内で完全に適用されており、install.sh のマイグレーションブロックも正しく実装されている。

検出された MEDIUM 4件は主に暗黙的な設計判断の明文化不足であり、実行時のフロー破綻を引き起こすものではない。最も注目すべきは M2 (SubAgent での `{{SDD_DIR}}` 解決メカニズム) だが、これは Claude Code プラットフォームが CLAUDE.md を全コンテキストに注入する場合は問題にならない。

Cross-Cutting Mode (v1.1.0 で追加) は revise.md に完全に定義されており、Single-Spec Mode からのエスカレーションパス (Part A Step 3, Step 6 option d) も双方向で機能する。Tier-based 並列実行モデルは run.md の Dispatch Loop パターンを正しく参照している。
