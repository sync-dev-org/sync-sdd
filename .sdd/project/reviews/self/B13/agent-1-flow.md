## Flow Integrity Report

**対象**: sdd-roadmap Router → refs ディスパッチフロー全モード
**レビュー日**: 2026-02-27
**レビュアー**: Agent 1 (Flow Integrity)

---

### Issues Found

- [MEDIUM] **Revise モードの Mode Detection: `revise [instructions]` の曖昧さ** / `framework/claude/skills/sdd-roadmap/SKILL.md:34-35`

  SKILL.md Step 1 の Detect Mode は:
  ```
  "revise {feature} [instructions]"  → Revise Mode (Single-Spec)
  "revise [instructions]"            → Revise Mode (Cross-Cutting)
  ```
  と定義している。`refs/revise.md` の Mode Detection では「first word after "revise" が existing spec name と一致するか」で分岐する。しかし、instructions がそれ自体スペックに似た単語（例: "auth", "api"）だった場合に Single-Spec と誤認するリスクがある。これは SKILL.md 側には明示的に記載されておらず、refs/revise.md にのみ「Lead checks first word against existing spec names」と書かれている。SKILL.md のコメントが不足しているため Lead が ref を読む前に誤ったモードを選択する可能性がある。

  具体的リスク: `revise add-index-for-performance` を Cross-Cutting インテントで入力すると、`add-index-for-performance` という spec が存在しない場合は正しく Cross-Cutting になるが、偶然一致する spec 名がある場合は Single-Spec になる。これはフロー整合性上の軽微な曖昧性。

- [MEDIUM] **Dead-Code Review の NO-GO リトライカウントが in-memory のみで session resume 後にリセットされる** / `framework/claude/skills/sdd-roadmap/refs/run.md:248`

  run.md Step 7b に「max 3 retries, tracked in-memory by Lead — not persisted to spec.yaml, restarts at 0 on session resume」と明記されている。これは仕様上意図的な設計ではあるが、CLAUDE.md §Auto-Fix Counter Limits には「Dead-Code Review NO-GO: max 3 retries」とのみ記載されており、session resume でリセットされることが CLAUDE.md には記載されていない。CLAUDE.md を読んだ Lead がセッション再開後に「3 回まで」と信じてカウントが 0 に戻ることを意識しない可能性がある。

  影響: セッション再開後に Dead-Code NO-GO が再発した場合、Lead が「まだ 3 回猶予がある」と判断してしまい実質的に制限が機能しなくなる。

- [MEDIUM] **1-Spec Roadmap で `review dead-code` が BLOCK されるパスの不一致** / `framework/claude/skills/sdd-roadmap/SKILL.md:74`

  SKILL.md §Single-Spec Roadmap Ensure Step 3 には「If subcommand is `review dead-code` ... AND no roadmap → BLOCK」とある。しかし §1-Spec Roadmap Optimizations（line 88-91）には「Skip wave-level dead-code review」とのみ書かれており、「ユーザーは `/sdd-roadmap review dead-code` を手動で実行できる」と記されている。すなわち:

  - roadmap があれば dead-code review は許可される（1-spec でも手動実行可能）
  - roadmap がなければ BLOCK される

  この挙動は論理的に一貫しているが、SKILL.md §1-Spec Roadmap Optimizations の「User can still run manually」という記述と、review.md の「Dead Code Review: No phase gate」が整合しているかについて、review.md には 1-spec 特例の注記がない。2 か所の情報が分散しており Lead が混乱する可能性がある。

- [MEDIUM] **Cross-Cutting Review の verdict 保存先が review.md に記載されていない** / `framework/claude/skills/sdd-roadmap/refs/review.md:129-131`

  review.md §Verdict Destination by Review Type に cross-cutting review のパスが記載されている（`specs/.cross-cutting/{id}/verdicts.md`）が、このパスへの書き込みタイミングと orchestration（revise.md Step 8.2）の整合確認が必要。revise.md Step 8 では `specs/.cross-cutting/{id}/verdicts.md` に保存と明記されており一致しているが、review.md の Execution Flow §Step 1 の scope directory リストには cross-cutting が含まれていない。cross-cutting review の scope dir は revise.md 側にのみ定義されており、review.md の Step 1 を読んだだけでは分からない。

  影響: review.md Execution Flow を standalone で実行する際、cross-cutting の scope dir が不明確。revise.md を読んだ後で初めて明確になる。

- [MEDIUM] **Revise Part A Step 6(d): Cross-Cutting モードへの合流は Phase 不整合を生じさせる可能性** / `framework/claude/skills/sdd-roadmap/refs/revise.md:91-95`

  Step 6 Downstream Resolution で Option (d) として「Cross-cutting revision → join Part B Step 2」が示されている。このとき target spec はすでに `implementation-complete` に戻っており、Part B Step 2 Impact Analysis では「only `implementation-complete` phase is eligible」とある（Part B Step 2, line 1）ので整合する。しかし Part B Step 7 Tier Execution では「State Transition: Set phase = design-generated」と全 FULL スペックをリセットする。target spec がすでに revised pipeline を完了しているため、Part B でもう一度 `phase = design-generated` にリセットされる可能性がある。

  これは仕様として「もう一度 Architect を走らせる」という意図ならば OK だが、「すでに完了した spec を再度設計させる」ことになるため、Lead に対して明示的な注記（「target spec が既に revised 済みなら Architect をスキップするか確認」）があると良い。現状は曖昧。

- [LOW] **SKILL.md の `review design --wave N` / `review impl --wave N` ディスパッチ先が明示されていない** / `framework/claude/skills/sdd-roadmap/SKILL.md:27-28`

  SKILL.md Detect Mode に `review design --wave N` と `review impl --wave N` が review subcommand としてリストされているが、Execution Reference（line 96-106）では単に「Review → Read `refs/review.md`」とだけ記されている。wave スコープ特有の処理（cumulative re-inspection, PREVIOUSLY_RESOLVED tracking）が review.md の Impl Review §Cross-check / wave-scoped mode に記載されているが、SKILL.md からは「review の ref を読め」としか書かれておらず、wave モードに対する特別な注意点へのポインタがない。Lead が refs/review.md の wave-scoped セクションを見落とすリスクがある。

- [LOW] **reboot.md Phase 7 の Verdict Handling: `retry_count` の aggregate cap 参照が省略されている** / `framework/claude/skills/sdd-reboot/refs/reboot.md:182`

  reboot.md Phase 7 §Verdict Handling には「Max 5 retries (aggregate cap 6). On exhaustion: escalate to user per `refs/run.md` Step 6 Blocking Protocol」と記されている。run.md Step 6 Blocking Protocol はスペックが exhausted した後の options を定義しているが、reboot context では「skip → exclude spec from wave EXIT condition」としか書かれておらず、「fix / skip / abort」の全 3 オプションが使えるかどうか run.md に委ねられている。reboot では impl フェーズがないため、「fix」= Architect re-dispatch のみが有効な選択肢であることが暗黙的。明示的な記述があると良い。

- [LOW] **SKILL.md `review design --cross-check` と `review impl --cross-check` のパターンが SKILL.md に記載されているが、引数ヒントに含まれていない** / `framework/claude/skills/sdd-roadmap/SKILL.md:1-5`

  SKILL.md の `argument-hint` フィールドは:
  ```
  design <feature> | impl <feature> [tasks] | review design|impl <feature> [flags] | review dead-code [flags] | run [--gate] [--consensus N] | revise [feature] [instructions] | create [-y] | update | delete | -y
  ```
  と記されているが、`--cross-check` と `--wave N` フラグが argument-hint に明示されていない（`[flags]` という汎用表現でカバーされているが具体性が薄い）。ユーザーが使えるフラグを把握しにくい。

---

### Confirmed OK

- **Router → refs ディスパッチ完全性**: すべてのサブコマンド（design, impl, review, run, revise, create, update, delete）が対応する refs ファイルへ正しくルーティングされている。SKILL.md §Execution Reference（line 96-106）でモードと refs の対応が明示されている。

- **Phase Gate 一貫性**:
  - design.md Step 2: `initialized`, `design-generated`, `implementation-complete` を許可、`blocked` は BLOCK — CLAUDE.md の phase 定義と一致。
  - impl.md Step 1: `design-generated`, `implementation-complete` を許可、その他は BLOCK — 一致。
  - review.md Step 2: 設計レビューは `design.md` 存在確認のみ、実装レビューは `implementation-complete` 確認 — 一致。
  - CLAUDE.md §Phase Gate の定義（`initialized` → `design-generated` → `implementation-complete` / `blocked`）と全 ref が整合している。

- **Auto-Fix ループの一貫性**:
  - CLAUDE.md §Auto-Fix Counter Limits: `retry_count` max 5 (NO-GO only), `spec_update_count` max 2, aggregate cap 6。
  - run.md Phase Handlers でも同じ上限（max 5 retries, aggregate cap 6, spec_update_count max 2）が設定されている。
  - revise.md Part A Step 5 でも「Handle verdict per CLAUDE.md counter limits」と参照している。
  - Counter reset タイミング: CLAUDE.md「wave completion, user escalation decision, `/sdd-roadmap revise` start」と run.md Step 7c §Post-gate「Reset counters」が一致。

- **Wave Quality Gate の完全性**:
  - run.md Step 7 に a. Impl Cross-Check Review → b. Dead Code Review → c. Post-gate の順序が定義されている。
  - Step 7a の NO-GO で「map to target spec(s), increment retry_count, re-dispatch Builder(s)」、SPEC-UPDATE-NEEDED で「cascade」が明記されている。
  - Step 7b の Dead-Code NO-GO で「max 3 retries」という CLAUDE.md 例外条件と一致。
  - Step 7c で「Reset counters + Commit + Auto-draft session.md」が定義されており完全。

- **Consensus Mode の一貫性**:
  - SKILL.md §Consensus Mode（Shared Protocols）と review.md の記述が整合している。
  - B{seq} の決定: Router が一元的に決定し各 pipeline に渡す（review.md Step 2 に「For consensus mode: Router determines B{seq} once」と記載）。
  - アーカイブ: `reviews/B{seq}/pipeline-{p}/` — 一貫している。
  - 閾値計算 `⌈N×0.6⌉` が SKILL.md に定義されており review.md が参照。

- **Verdict Persistence フォーマットの一貫性**:
  - SKILL.md §Verdict Persistence Format でフォーマット定義（header `## [B{seq}] ...` → Raw → Consensus → Noise → Disposition → Tracked → Resolved since）。
  - review.md §Review Execution Flow Step 8 が「Router → Verdict Persistence Format」を参照。
  - run.md Step 7 では `[W{wave}-B{seq}]` と `[W{wave}-DC-B{seq}]` という wave-level ヘッダーを使用 — wave verdict と per-spec verdict を区別しており一貫。

- **エッジケース処理**:
  - **空の roadmap**: SKILL.md §Error Handling に「No roadmap for run/update/revise」でブロック処理が定義されている。
  - **1-spec roadmap**: SKILL.md §1-Spec Roadmap Optimizations に Wave QG スキップ、cross-spec analysis スキップ、dead-code review スキップ（手動実行可能）、コミットメッセージ形式が明記されている。
  - **blocked spec**: CLAUDE.md §Phase Gate と各 ref（design.md Step 2, impl.md Step 1, review.md Step 2）で BLOCK 処理が一貫して定義されている。run.md Step 6 §Blocking Protocol でブロック設定と downstream cascade が定義されている。
  - **retry limit 枯渇**: run.md Step 6 §Blocking Protocol（fix/skip/abort の 3 選択）と CLAUDE.md §Auto-Fix Counter Limits が一致。escalation 後の counter reset も両ファイルで一致。

- **refs を読むタイミングの明示性**:
  - SKILL.md §Execution Reference（line 94-106）に「After mode detection and roadmap ensure, Read the reference file for the detected mode」と明確に記されている。
  - refs は「モード検出」と「Single-Spec Roadmap Ensure」の完了後に読まれる。この順序が明示されており Lead が refs を先読みしてしまう誤操作を防いでいる。

- **Revise モードの主要フロー**:
  - SKILL.md Detect Mode の `revise {feature} [instructions]` → Single-Spec Mode (Part A)、`revise [instructions]` → Cross-Cutting Mode (Part B) のマッピングが revise.md Mode Detection と一致。
  - Single-Spec → Cross-Cutting へのエスカレーション（Part A Step 3 で 2+ スペック影響時）が revise.md に定義されており、`DIRECTION_CHANGE` の decisions.md 記録も指示されている。
  - Cross-Cutting → Single-Spec ダウングレードのパスはなく（ユーザーは Part B で任意に SKIP 分類できる）、これは意図的設計として正しい。

- **agent 定義と settings.json の整合性**:
  - settings.json の `Task()` エントリが全 agent ファイル（sdd-analyst, sdd-architect, sdd-auditor-*, sdd-builder, sdd-conventions-scanner, sdd-inspector-*, sdd-taskgenerator）と一致している。
  - SKILL.md の `allowed-tools` に `Task` が含まれており、SubAgent dispatch が可能。

- **Verdict フォーマット（CPF）の一貫性**:
  - sdd-auditor-design: `VERDICT:{GO|CONDITIONAL|NO-GO}` — `SPEC-UPDATE-NEEDED` は design auditor には存在しない（正しい）。
  - sdd-auditor-impl: `VERDICT:{GO|CONDITIONAL|NO-GO|SPEC-UPDATE-NEEDED}` — impl auditor のみが SPEC-UPDATE-NEEDED を出力できる（CLAUDE.md と一致）。
  - sdd-auditor-dead-code: `VERDICT:{GO|CONDITIONAL|NO-GO}` — dead-code では SPEC-UPDATE-NEEDED なし（正しい）。
  - run.md の Phase Handlers が SPEC-UPDATE-NEEDED を impl review のみで処理し、design review では「not expected, escalate immediately」としているのと一致。

- **SubAgent バックグラウンド実行ルール**:
  - CLAUDE.md §SubAgent Lifecycle「Lead dispatches SubAgents via Task tool with `run_in_background: true` always. No exceptions」。
  - 各 refs ファイルでの dispatch 指示がすべて `run_in_background=true` を含んでいる（design.md Step 3, impl.md Step 2-3, review.md Step 4,6, run.md Dispatch Loop, revise.md Part B Step 7 Step 3）。

- **spec.yaml の ownership**:
  - CLAUDE.md §State Management「spec.yaml is owned by Lead. T2/T3 SubAgents MUST NOT update spec.yaml directly」。
  - sdd-architect, sdd-builder, sdd-taskgenerator の全 agent 定義に「Do NOT update spec.yaml — Lead manages all metadata」が明記されている。

- **install.sh との整合性**:
  - install.sh が framework/claude/skills/ → .claude/skills/、framework/claude/agents/ → .claude/agents/ にコピーする。CLAUDE.md §Project Context §Paths で「Agent Profiles: `.claude/agents/`」と定義されており一致。
  - `Task(subagent_type="sdd-xxx")` での参照先が .claude/agents/ であり、settings.json の `Task(sdd-xxx)` 権限と対応している。

---

### Overall Assessment

フロー全体の整合性は **良好** である。主要なパス（Router → refs ディスパッチ、Phase Gate、Auto-Fix ループ、Wave QG、Consensus Mode、Verdict Persistence、Revise モード）はすべて一貫して定義されており、CLAUDE.md の定義と各 refs の実装に重大な矛盾は検出されなかった。

検出された問題はいずれも MEDIUM または LOW であり、フローの正常動作を妨げるものではない。主なリスクは以下の 3 点:

1. **セッション再開後の Dead-Code NO-GO カウンターリセット**（MEDIUM）: in-memory 管理という仕様が CLAUDE.md に記載されておらず、Lead がセッション再開時に制限を誤認するリスク。
2. **revise.md Part A Step 6(d) での target spec 二重 pipeline 問題**（MEDIUM）: すでに完了した revised spec が Cross-Cutting モード合流時に再度 Architect にかけられる可能性の曖昧さ。
3. **Cross-Cutting Review の scope dir が review.md Execution Flow に含まれていない**（MEDIUM）: standalone で review.md だけを読んでも cross-cutting の scope dir が不明。

推奨優先度: MEDIUM 3 件は次回改訂時に対処。LOW 4 件は documentation 改善として将来対処可。

