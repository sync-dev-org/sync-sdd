## Flow Integrity Report

### Issues Found

- [HIGH] `revise` モードのモード検出ロジックに曖昧さがある / SKILL.md:34-35
  SKILL.md の Detect Mode セクションでは、`"revise {feature} [instructions]"` の判定を「最初の単語が specs/ のスペック名と一致するか」で行うと明記されている。しかし revise.md の Mode Detection（refs/revise.md:8-10）では同様に「first word after 'revise' against existing spec names」と記述されている。この一致は問題ではないが、**指示のみ（スペック名なし）を引数として渡した場合**に最初の単語が偶然スペック名と一致してしまうリスクについて言及がなく、フォールバック動作が未定義である。具体的には、スペック名が `add`、`fix`、`update` のような一般的な動詞になっている場合、Cross-Cutting を意図したユーザーが誤ってSingle-Spec Modeにルーティングされる可能性がある。

- [HIGH] `review dead-code` の1-Spec Roadmapガード条件が review.md と SKILL.md で一致していない / SKILL.md:72-74 vs review.md:14
  SKILL.md の Single-Spec Roadmap Ensure セクションでは、`review dead-code` について「skip enrollment check」としている（例外扱い）。一方 review.md Step 1 の **1-Spec Roadmap guard** は `--cross-check` と `--wave N` のみを対象とし、`dead-code` には明示的なガードが記述されていない。SKILL.md の「If no roadmap for run/update/revise」エラーには dead-code は含まれていないが、「If no roadmap → If subcommand is `review dead-code`... → BLOCK」（SKILL.md:73-74）と記述されており、ロードマップがない場合はBLOCKされる。review.md の Dead Code Review セクションには「No phase gate (operates on entire codebase)」と記載されているが、ロードマップ存在チェックについての記述がないため、review.md を読んだ際に一貫性が不明確になる。

- [HIGH] `revise` の Cross-Cutting Mode から Single-Spec Mode への**逆方向エスカレーション**パスが未定義 / refs/revise.md
  revise.md の Mode Detection では、Single-Spec → Cross-Cutting（Part A Step 3 → Part B）の昇格パスは定義されている。しかし、Cross-Cutting Mode (Part B) に進んだ後にユーザーが「やはり1スペックだけ修正する」と判断した場合の**降格パス**が定義されていない。Part B Step 2 でユーザーが分類を確認する機会があるが（「Abort」は定義されているが「Single-Spec に戻る」はない）、単一スペックのみが FULL として残った場合の自動降格も言及されていない。

- [HIGH] `run.md` の Design Lookahead において、Staleness Guard 後の次-wave spec の `version_refs.design` クリアが spec.yaml の他フィールドとの整合性を壊す可能性がある / refs/run.md:166-167
  run.md:166-167 では「If a Wave N spec's design changes → reset the lookahead spec's `phase` to `initialized` and clear `version_refs.design`」とある。しかし `orchestration.last_phase_action` のリセットについての明示がない。design.md Step 3 では「Set `orchestration.last_phase_action` = null (ensures next impl triggers REGENERATE)」とあり、この整合性の処理が Staleness Guard 時に必要だが run.md には言及がない。`phase = initialized` に戻しても `last_phase_action` が残っている場合、impl.md Step 2 の REGENERATE/RESUME 判定に影響する可能性がある（ただし phase が initialized の場合は impl には到達しないため実害は限定的）。

- [MEDIUM] Verdict Persistence Format の `runs:{N}` フィールドが Standalone レビューでは定義されていない / SKILL.md:131-138
  SKILL.md の Verdict Persistence Format では batch entry header に `runs:{N}` を含めるよう定義している（Consensus mode の場合 N=実行パイプライン数）。しかし Consensus なし（N=1）の場合について「N=1 (default): use `specs/{feature}/reviews/active/`」とのみ記述されており、`threshold:{K}/{N}` の値（K=1, N=1 で threshold=1/1 となるべきか）について明確な記述がない。review.md Step 8 は「Persist verdict to verdicts.md」と指示しているが、format の詳細は Router (SKILL.md) を参照している。Standalone 単一レビューで `runs:1 | threshold:1/1` を付与すべきか、省略すべきかが曖昧。

- [MEDIUM] `impl.md` Step 3.5 E2E Gate の失敗時 Builder 再ディスパッチが `spec.yaml` を更新後に実行されるという順序の問題 / refs/impl.md:104-113
  impl.md の処理順序は「全Builder完了 → spec.yaml を `implementation-complete` に更新 → E2E Gate」である（Step 3 → Step 3.5）。E2E Gate 失敗時の「targeted Builder fix」後に spec.yaml を再更新する指示がないため、E2E 修正後のファイルが `implementation.files_created` に含まれない可能性がある。run.md の Implementation completion handler（run.md:188）では「After ALL Builders complete, update spec.yaml per impl.md Step 3, then execute E2E Gate per impl.md Step 3.5」と記述されており同じ順序を踏襲している。E2E 修正で新規ファイルが作成された場合の `files_created` 更新手順が未記述。

- [MEDIUM] `revise.md` Part B Step 7 の Tier Execution で E2E Gate への明示的な参照がない / refs/revise.md:200-245
  run.md の Readiness Rules では「E2E Gate」を `Impl Review` の前提条件として定義し、impl.md Step 3.5 に詳細がある。revise.md Part B Step 7 の Tier Execution では「5. Implementation: ... refs/impl.md (includes ... Pilot Stagger Protocol)」と記述しているが、E2E Gate（impl.md Step 3.5）への参照が明示されていない。Tier Checkpoint に「All specs must reach implementation-complete」とあるが、E2E Gate を経由しているかどうかの確認がない。

- [MEDIUM] `run.md` の Wave QG Dead Code Review でカウンターが `in-memory` 管理されるとの記述が CLAUDE.md のカウンターリセット条件と一貫性がない / run.md:249 vs CLAUDE.md:179
  run.md:249 では「max 3 retries, tracked in-memory by Lead — not persisted to spec.yaml. Dead-code findings are wave-scoped and resolved within a single execution window; counter restarts at 0 on session resume.」と記述されている。CLAUDE.md:179 では「Counter reset triggers: wave completion, user escalation decision, `/sdd-roadmap revise` start, **session resume** (dead-code counters are in-memory only; see `refs/run.md`)」と一致しているため矛盾はないが、session resume 時に dead-code カウンターがリセットされることで、前セッションで NO-GO が出ていた場合でも最大3回の再試行機会が与えられる。この動作が意図的であることは run.md:249 の「resolved within a single execution window」で読み取れるが、resume 後の動作についてユーザーへの明示的な通知手順が定義されていない（CLAUDE.md の Session Resume には言及なし）。

- [MEDIUM] `reboot.md` Phase 7 の Design Review NO-GO 時のエスカレーションが `run.md` Step 6 Blocking Protocol を参照しているが、reboot コンテキストでの Blocking Protocol の適用が不完全 / refs/reboot.md:180
  reboot.md:180 では「On exhaustion: escalate to user per `refs/run.md` Step 6 Blocking Protocol (fix/skip/abort)」とある。run.md Step 6 の Blocking Protocol は `spec.yaml.phase = blocked` に設定し downstream spec をブロックする手順を含む。しかし reboot コンテキストでは実装フェーズが存在せず、「fix / skip / abort」のみが意味を持つ。reboot.md の Verdict Handling:「Skip → exclude spec from wave EXIT condition」と記述があり、これは run.md の skip とは異なる（run.md の skip は `retry_count=0` リセットや downstream 確認を含む）。参照による委譲は理解できるが、reboot 固有の動作差分についての注記がない。

- [MEDIUM] `SKILL.md` の Detect Mode で `"-y"` フラグが `Auto-detect` に分類されているが、`impl`/`review` サブコマンドと組み合わせた場合の動作が定義されていない / SKILL.md:39
  SKILL.md の Detect Mode で `$ARGUMENTS = "-y"` は「Auto-detect: run if roadmap exists, create if not」と定義されている。しかし `design {feature} -y` や `impl {feature} -y` のような `-y` 付きサブコマンドの扱いは、Single-Spec Roadmap Ensure の `[-y]` フラグ（Backfill デフォルト動作として使用）としてのみ登場する。`-y` の解釈が「トップレベルの Auto-detect」と「サブコマンドレベルのフラグ」で二重の意味を持っており、`design feature -y` が「Design サブコマンド + フラグ」として正しく解釈されるかどうかが明確でない。

- [LOW] `SKILL.md` の `Consensus Mode` セクションで、`--consensus N` を `review dead-code` と組み合わせた場合の動作が未定義 / SKILL.md:112-125
  SKILL.md の Detect Mode では `"review dead-code"` と `"review {type} {feature} --consensus N"` が別パターンとして記述されている。Consensus Mode の説明（SKILL.md:112-125）では `specs/{feature}/reviews/active-{p}/` 構造を使うが、dead-code レビューのスコープディレクトリは `{{SDD_DIR}}/project/reviews/dead-code/`（review.md:89）であり、consensus と dead-code の組み合わせパスが矛盾する可能性がある。`review dead-code --consensus N` というコマンドが想定されているかどうかが不明。

- [LOW] `revise.md` Part B Step 8 の Cross-Cutting Consistency Review で verdict が `specs/.cross-cutting/{id}/verdicts.md` に保存されるが、`/sdd-status` でのクロスカッティング状態確認が `verdicts.md` を参照するかどうかが sdd-status/SKILL.md に明示されていない / sdd-status/SKILL.md vs refs/revise.md:252
  sdd-status の Step 2 では `specs/.cross-cutting/*/` をスキャンするが、`verdicts.md` の表示について Cross-Cutting Revisions セクションに「verdict status (from verdicts.md if exists)」と記述されており概ね整合している。ただし revise.md Part B Step 8 で保存されるパスが `specs/.cross-cutting/{id}/verdicts.md`（SKILL.md の Verdict Persistence Format では `specs/.cross-cutting/{id}/verdicts.md` と一致）であることの確認が必要。sdd-status/SKILL.md Step 2 では `specs/.cross-cutting/*/` として glob するため、サブディレクトリのファイルを読む実装が必要だが記述は曖昧。

- [LOW] `run.md` の Blocking Protocol（Step 6）では blocked スペックの `retry_count` と `spec_update_count` のリセットが「fix/skip」時にのみ行われるが、CLAUDE.md のカウンターリセット条件との対応が部分的 / run.md:224 vs CLAUDE.md:179
  run.md:224 では「reset `retry_count=0` and `spec_update_count=0` for unblocked specs」（fix 時）および「Reset counters for affected downstream specs」（skip 時）と記述されている。CLAUDE.md:179 のリセットトリガーには「user escalation decision (including blocking protocol fix/skip)」が含まれており一致する。ただし「abort」オプション選択時のカウンターリセットについての記述がなく、abort 後に再開した場合の動作が不明。

### Confirmed OK

- Router Dispatch Completeness: SKILL.md の Detect Mode が全サブコマンド（design, impl, review design/impl/dead-code, run, revise, create, update, delete, -y）を網羅しており、各モードに対応する refs ファイルへの参照が「Execution Reference」セクションに明示されている。読み込みタイミングも「After mode detection and roadmap ensure, Read the reference file」と明確に指定されている。
- Phase Gate Consistency（Design）: design.md Step 2 が `blocked`, `implementation-complete`（警告あり）, `initialized`, `design-generated` の全フェーズを処理し、CLAUDE.md の Phase-Driven Workflow（`initialized → design-generated → implementation-complete`）と一致している。
- Phase Gate Consistency（Impl）: impl.md Step 1 が `blocked`, `design-generated`（許可）, `implementation-complete`（再実行許可）, それ以外（BLOCK）を処理し、フェーズ定義と一致。
- Phase Gate Consistency（Review Design）: review.md Step 2 が `blocked` を確認し、`design.md` 存在確認を行っている。
- Phase Gate Consistency（Review Impl）: review.md Step 2 が `implementation-complete` であることと `blocked` でないことを確認している。
- Auto-Fix Loop（NO-GO）: run.md の Design Review completion と Impl Review completion の両方で `retry_count` インクリメントと最大5回の再試行が定義されており、CLAUDE.md の「max 5 (NO-GO only)」と一致している。
- Auto-Fix Loop（SPEC-UPDATE-NEEDED）: run.md の Impl Review completion で `spec_update_count` インクリメントと最大2回、aggregate cap 6 が定義されており、CLAUDE.md と一致している。
- Auto-Fix Loop（Revise Part A）: revise.md Step 5 で「Auto-fix loop applies normally (retry_count, spec_update_count)」と記述し、CLAUDE.md カウンター制限を参照している。
- Wave Quality Gate（完全性）: run.md Step 7 で Impl Cross-Check Review (7a) → Dead Code Review (7b) → Post-gate (7c) の3段階が定義され、各ステップの成功条件・失敗時対処・カウンター管理が記述されている。
- 1-Spec Roadmap Optimizations: SKILL.md で明示的に「Skip Wave Quality Gate」「Skip Cross-Spec File Ownership Analysis」等が定義されており、run.md Step 7 冒頭の「1-Spec Roadmap: Skip this step」と一致している。
- Consensus Mode（基本フロー）: SKILL.md の Consensus Mode セクション（112-125）と review.md Step 2/3/9 が一致しており、N=1 の場合のデフォルト動作も明確。
- Verdict Persistence Format（一貫性）: SKILL.md に集中管理されており、review.md Step 8 が「see Router → Verdict Persistence Format」と参照しているため、重複定義がなく一貫性が保たれている。
- Verdict Destination（全レビュータイプ）: review.md の「Verdict Destination by Review Type」テーブルが全6種（single-spec, dead-code, cross-check, wave, cross-cutting, self-review）のパスを網羅している。
- Blocked Spec 処理: CLAUDE.md の Phase Gate、design.md Step 2、impl.md Step 1、revise.md Part A Step 1 の全員が `blocked` フェーズを明示的に処理している。
- SubAgent Lifecycle（バックグラウンド必須）: CLAUDE.md「run_in_background: true always. No exceptions」の原則が、design.md Step 3、impl.md Step 3、review.md Step 4/6、run.md dispatch loop の全箇所で遵守されている。
- Builder Parallel Coordination: CLAUDE.md「As each Builder completes, immediately update tasks.yaml, collect files, store knowledge tags. Final spec.yaml update only after ALL Builders complete」が impl.md Step 3 の incremental processing で具体的に実装されている。
- ConventionsScanner Skip（Reboot）: reboot.md Phase 3 および reboot/SKILL.md Step 2 で「ConventionsScanner is NOT dispatched」と明示されており、CLAUDE.md の記述とも一致。
- Inspector Parallelism: review.md Step 4 で全Inspectorを一括ディスパッチし、run.md の Review Decomposition（DISPATCH-INSPECTORS）でも並列ディスパッチが保証されている。
- Revise Mode Detection（Single-Spec vs Cross-Cutting）: SKILL.md の Detect Mode（34-35行）と revise.md の Mode Detection（8-10行）が一致しており、「first word matches spec name → Single-Spec, otherwise → Cross-Cutting」のロジックが両ファイルで同一。
- Single-Spec → Cross-Cutting エスカレーション: revise.md Part A Step 3 で「2+ specs affected → propose switch to Cross-Cutting」と定義され、Part B への接続（「join Part B Step 2」）が明示されている。
- Revise Post-Completion（パイプライン継続）: revise.md Part A Step 7 で「If roadmap run was in progress: resume via `refs/run.md` dispatch loop from current spec.yaml state」と定義されており、中断したロードマップへの復帰が保証されている。
- session.md Auto-Draft Policy（run パイプライン例外）: CLAUDE.md、run.md Phase Handlers、reboot.md Phase 7 の3箇所で「Wave QG 後・ユーザーエスカレーション・パイプライン完了時のみ auto-draft」という一貫したポリシーが定義されている。
- settings.json の Agent 許可リスト: framework/claude/agents/ に存在する全エージェント（sdd-analyst, sdd-architect, sdd-auditor-*, sdd-builder, sdd-conventions-scanner, sdd-inspector-*, sdd-taskgenerator）が settings.json の allow リストに含まれており、不足がない。
- Skill 許可リスト: framework/claude/skills/ に存在する全7スキル（sdd-roadmap, sdd-steering, sdd-status, sdd-handover, sdd-reboot, sdd-release, sdd-review-self）が settings.json に含まれている。
- CPF フォーマット一貫性: Inspector 出力（.cpf ファイル）および Auditor 出力（verdict.cpf）がすべて `VERDICT:`, `SCOPE:`, `ISSUES:`/`VERIFIED:`, `NOTES:` の同一構造を使用。cpf-format.md のルールに従っている。
- Auditor の WRITTEN 返却: sdd-auditor-design.md と sdd-auditor-impl.md、sdd-auditor-dead-code.md のすべてが「Return only `WRITTEN:{verdict_file_path}`」を最終テキストとして指示しており、CLAUDE.md の「Review SubAgents: return ONLY `WRITTEN:{path}`」と一致。
- Design Review Inspector 数: review.md では「6 design Inspectors」と記述。実際の agents ファイルを確認すると、sdd-inspector-rulebase, sdd-inspector-testability, sdd-inspector-architecture, sdd-inspector-consistency, sdd-inspector-best-practices, sdd-inspector-holistic の6エージェントが存在し一致している。
- Impl Review Inspector 数: review.md では「6 impl Inspectors + 2 web」と記述。sdd-inspector-impl-rulebase, sdd-inspector-interface, sdd-inspector-test, sdd-inspector-quality, sdd-inspector-impl-consistency, sdd-inspector-impl-holistic の6と sdd-inspector-e2e, sdd-inspector-visual の2が確認でき一致。
- Dead-Code Inspector 数: review.md「4 dead-code Inspectors」。sdd-inspector-dead-settings, sdd-inspector-dead-code, sdd-inspector-dead-specs, sdd-inspector-dead-tests の4が確認でき一致。
- Pilot Stagger Protocol: impl.md Step 3 と run.md の Implementation completion handler（188行）が整合しており、ConventionsScanner Supplement モードの呼び出し手順も一致している。

### Overall Assessment

フロー整合性の観点では、ルーターから各 ref ファイルへのディスパッチ、フェーズゲート、自動修正ループ、Wave QG の基本構造は**概ね正確**に実装されている。特に Verdict Persistence の一元管理（SKILL.md 集中）、SubAgent バックグラウンド必須原則の遵守、Inspector/Auditor 数の一致は高品質に維持されている。

主要な懸念事項として以下の3点を優先対応として推奨する：

1. **[HIGH] revise モードのスペック名衝突リスク**（SKILL.md:34-35）— 一般的な動詞がスペック名として使われた場合の誤ルーティング防止策が未定義。最初の単語がスペック名と一致する場合に確認プロンプトを挟む、または `specs/` 内のディレクトリ一覧を事前にチェックして曖昧な場合はユーザーに確認する手順を追加することを推奨。

2. **[HIGH] Cross-Cutting → Single-Spec への降格パスの欠如**（revise.md Part B）— Part B に移行後に単一スペックしか残らない場合の扱いが未定義。ユーザーに「Single-Spec Mode に戻るか継続するか」を提示する手順を追加することを推奨。

3. **[HIGH] Staleness Guard 後の `last_phase_action` リセット欠如**（run.md:166-167）— 実害は限定的（initialized フェーズに戻るため impl には到達しない）だが、spec.yaml の状態整合性のために `orchestration.last_phase_action = null` のリセット指示を追加することを推奨。

その他の MEDIUM 項目（E2E Gate 後のファイル追記、dead-code カウンターの resume 後通知、revise Part B E2E Gate 参照）についても、実装上の edge case で予期しない動作を引き起こす可能性があり、早期の文書化を推奨する。
