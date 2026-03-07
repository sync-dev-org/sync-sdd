## Flow Integrity Report

### Issues Found

- [MEDIUM] sdd-reboot SKILL.md の Phase 4 完了シグナルと reboot.md の記述が不一致。SKILL.md は「Wait for `ANALYST_COMPLETE` via `TaskOutput`」と記載しているが、reboot.md Phase 4 Step 2 も「Wait for `ANALYST_COMPLETE` via `TaskOutput`」と書いており内容は一致している。ただし、SKILL.md の Error Handling 表では「Analyst failure → Retry once. Second failure → delete branch, return to main, report error」と記載しているのに対し、reboot.md Phase 4 Step 3 は「retry once with same prompt. On second failure, BLOCK with error」と記載しており、**ブランチ削除・main へのチェックアウトがエラー処理に含まれていない**。ブランチを残したままの BLOCK は不整合。 / framework/claude/skills/sdd-reboot/SKILL.md:53 vs framework/claude/skills/sdd-reboot/refs/reboot.md:62-63

- [MEDIUM] reboot.md Phase 7 の Dispatch Loop EXIT 条件が不完全。EXIT 条件は「all specs in wave have design-generated + GO/CONDITIONAL verdict and active is empty」と明記されているが、一部の spec が NO-GO の auto-fix loop に入った場合の EXIT 条件が曖昧。特に retry_count 上限（5回）を超えた場合、「escalate to user (fix/skip/abort)」と書かれているが、skip 選択時に当該 spec の wave EXIT 条件をどう判定するかが規定されていない。run.md の Blocking Protocol（Step 6）には skip 処理が詳細に規定されているが、reboot.md はこれを参照していない。 / framework/claude/skills/sdd-reboot/refs/reboot.md:180

- [MEDIUM] sdd-roadmap SKILL.md の Revise Mode 検出ロジックと revise.md の Mode Detection が微妙にずれている可能性。SKILL.md では `"revise {feature} [instructions]"` → Single-Spec Mode、`"revise [instructions]"` → Cross-Cutting Mode と記載。revise.md は「first word after "revise" against existing spec names」でチェックすると記載している。**ただし、feature 名と同名の instruction 語が指定された場合の優先順位が不明確**。例えば `"revise auth improve security"` で "auth" がスペック名に一致する場合 → Single-Spec Mode になるが、これは SKILL.md のパターン定義と一致する。問題は instruction 語が既存 spec 名に偶然一致した場合（例: `"revise fix auth flow"` の "fix" は spec 名ではないが "auth" も spec 名である場合の挙動が未定義）。 / framework/claude/skills/sdd-roadmap/SKILL.md:34-35 vs framework/claude/skills/sdd-roadmap/refs/revise.md:8-11

- [MEDIUM] reboot.md Phase 6b において「Remove all spec directories under `{{SDD_DIR}}/project/specs/` (including dot-prefixed meta-dirs and `roadmap.md`)」と記載しているが、Phase 6a の Archive 対象は「excluding dot-prefixed like `.wave-context/`, `.cross-cutting/`」と明記しており、**dot-prefixed はアーカイブされない**。しかし削除時（6b）は dot-prefixed も削除対象。dot-prefixed ディレクトリ（`.wave-context/`, `.cross-cutting/`）内に有意義なデータ（cross-cutting brief、wave-context shared research）が存在するケースで、アーカイブせずに削除される点が設計上のリスク。意図的な設計である可能性はあるが明示的な注記がない。 / framework/claude/skills/sdd-reboot/refs/reboot.md:85-94

- [LOW] CLAUDE.md の Tier 2 ロール記述（framework/claude/CLAUDE.md）に Analyst が含まれているが、インストール先の CLAUDE.md（.claude/CLAUDE.md）の Tier 2 記述には Analyst が含まれていない（「Architect / Auditor」のみ）。これはインストール先のファイルが古いことを示しており、フレームワーク開発上の管理問題。ただし、framework 側が正であるため優先度は低い。 / framework/claude/CLAUDE.md:15-16 vs .claude/CLAUDE.md:14-15

- [LOW] review.md の Verdict Destination リストに「Self-review」の場合（`{{SDD_DIR}}/project/reviews/self/verdicts.md`）が記載されているが、sdd-review-self/SKILL.md では `$SCOPE_DIR/verdicts.md` として定義されており、SCOPE_DIR は `{{SDD_DIR}}/project/reviews/self/` と示されている。パス自体は一致しているが、review.md が self-review のパスを参照するのは設計上の意図が不明確（sdd-review-self は sdd-roadmap 経由では呼ばれない）。クロス参照としての記述であれば問題はないが、混乱の余地あり。 / framework/claude/skills/sdd-roadmap/refs/review.md:131

- [LOW] run.md Step 7b（Dead-Code Review NO-GO）において「max 3 retries, tracked in-memory by Lead — not persisted to spec.yaml, restarts at 0 on session resume」と明記されている。これは CLAUDE.md の「Dead-Code Review NO-GO: max 3 retries」と一致するが、「session resume 時にカウンタが 0 リセットされる」点について CLAUDE.md には記述がない。session resume 後の dead-code retry 動作についての一貫性が文書化されていない。 / framework/claude/skills/sdd-roadmap/refs/run.md:248

- [LOW] sdd-reboot の SKILL.md Error Handling 表「Design Review exhaustion → Escalate to user: fix / skip / abort」と reboot.md Phase 7 Verdict Handling の「On exhaustion: escalate to user (fix/skip/abort)」は一致しているが、reboot.md はその後の処理（fix/skip/abort それぞれの場合の spec.yaml 更新、pipeline 継続手順）を定義していない。run.md Step 6 Blocking Protocol が参照先として明示されていないため、Lead がどのプロトコルを使うかを自己判断する必要がある。 / framework/claude/skills/sdd-reboot/refs/reboot.md:180

### Confirmed OK

- **Router dispatch 完全性**: SKILL.md の全 `$ARGUMENTS` パターンが Execution Reference セクションで正しい refs ファイルにルーティングされている（design→refs/design.md、impl→refs/impl.md、review→refs/review.md、run→refs/run.md、revise→refs/revise.md、create/update/delete→refs/crud.md）。

- **フェーズゲート一貫性**: CLAUDE.md 定義のフェーズ（`initialized`、`design-generated`、`implementation-complete`、`blocked`）が design.md Step 2、impl.md Step 1、review.md Step 2 で正しく参照されている。各 ref での BLOCK 条件が CLAUDE.md と整合している。

- **Auto-fix ループ（NO-GO/SPEC-UPDATE-NEEDED）**: CLAUDE.md のカウンタ制限（retry_count: max 5、spec_update_count: max 2、aggregate cap 6）が run.md Phase Handlers（Design Review / Impl Review completion）に正確に反映されている。CONDITIONAL = GO の扱いも一貫している。

- **Wave Quality Gate 完全性**: run.md Step 7 が a（Impl Cross-Check Review）→ b（Dead Code Review）→ c（Post-gate: counter reset + commit + auto-draft）の順序で完全に定義されており、1-Spec Roadmap での Skip 条件（SKILL.md §1-Spec Roadmap Optimizations と run.md Step 7 冒頭）も一致している。

- **Consensus Mode**: SKILL.md の Shared Protocols（Consensus Mode）と review.md Step 3・Step 9 が一貫している。N 個のパイプラインを並列実行し、閾値 ⌈N×0.6⌉ による集約ロジックが両ファイルで同一の手順で記述されている。

- **Verdict Persistence Format**: SKILL.md §Verdict Persistence Format が review.md §Review Execution Flow Step 8 で参照されており、フォーマット（`## [B{seq}] {review-type} | {timestamp} | v{version} | runs:{N} | threshold:{K}/{N}`）が一貫して定義されている。Auditor CPF 形式（design/impl/dead-code 各 Auditor）は VERDICT:、VERIFIED:、REMOVED:、RESOLVED: セクションで統一されている。

- **エッジケース（空の Roadmap、blocked spec、retry 上限）**: SKILL.md §Error Handling にて各エラーケースへの対応メッセージが定義されている。blocked spec は全 refs（design.md、impl.md、review.md）で BLOCK 処理される。retry 上限到達時の escalation は run.md、revise.md でそれぞれ規定されている。

- **Ref 読み込みタイミングの明示**: SKILL.md §Execution Reference において「After mode detection and roadmap ensure, Read the reference file for the detected mode」と明示されており、Roadmap Ensure 完了後に対応する ref を読み込む手順が一行で明確に規定されている。

- **Revise Mode 基本ルーティング**: Single-Spec Mode（Part A）から Cross-Cutting Mode（Part B）へのエスカレーション（Step 3 で 2+ spec 影響）、逆方向（Part A Step 6 でオプション (d) 選択時に Part B Step 2 へ合流）が revise.md に明確に記載されており、SKILL.md の Detect Mode 定義と整合している。

- **sdd-reboot 基本フロー（Phase 1-10）**: Phase 1（Pre-Flight）→ Phase 2（Branch Setup）→ Phase 3（Conventions Brief）→ Phase 4（Deep Analysis）→ Phase 5（User Review）→ Phase 6（Roadmap Regeneration）→ Phase 7（Design Pipeline）→ Phase 8（Regression Check）→ Phase 9（Final Report）→ Phase 10（Post-Completion）の順序は内部的に一貫しており、Design-Only モードが Phase 7 において Impl フェーズを除外していることが Modified Readiness Rules で明示されている。

- **sdd-reboot Design-Only Pipeline**: reboot.md Phase 7 の Modified Readiness Rules から Implementation および Impl Review の readiness rule が除外されており、Design と Design Review のみが実行される設計が正しく実装されている。run.md の Review Decomposition プロトコルを再利用していることが明示されている。

- **settings.json 許可エントリ**: `Task(sdd-analyst)` が追加されており、sdd-reboot が dispatch する sdd-analyst SubAgent が適切に許可されている。`Skill(sdd-reboot)` も追加済み。全 Inspector、Auditor、Builder、Architect、ConventionsScanner、TaskGenerator が登録されている。

- **sdd-analyst Completion Report**: `ANALYST_COMPLETE` フォーマットが reboot.md Phase 4 Step 2 の「Wait for `ANALYST_COMPLETE` via `TaskOutput`」と一致している。また、`WRITTEN:{report_path}` を含む構造が CLAUDE.md の file-based output protocol に準拠している。

- **ConventionsScanner Supplement モード**: reboot.md には記述がないが、sdd-reboot は Pilot Stagger Protocol（impl.md）を使用しないため問題なし。Design-Only モードでは Builder が存在しないため Supplement は不要であり、これは正しい設計。

- **1-Spec Roadmap 最適化**: SKILL.md §1-Spec Roadmap Optimizations（Wave QG Skip、Cross-Spec File Ownership Analysis Skip、commit フォーマット変更）が run.md Step 7 冒頭（「1-Spec Roadmap: Skip this step」）と整合している。

- **Revise Counter Reset**: revise.md Part A Step 4 で retry_count と spec_update_count が 0 にリセットされ、Part B Step 7 でも各 spec の State Transition でリセットが明示されている。CLAUDE.md の「Counter reset triggers: `/sdd-roadmap revise` start」と一致。

- **cross-cutting 用 Verdict Persistence パス**: revise.md Part B Step 8 で `specs/.cross-cutting/{id}/verdicts.md` に persist することが明記されており、review.md §Verdict Destination by Review Type の cross-cutting エントリ（`{{SDD_DIR}}/project/specs/.cross-cutting/{id}/verdicts.md`）と一致している。

### Overall Assessment

**総合評価: 概ね良好。MEDIUM 級の問題が4件、LOW 級が4件検出された。CRITICAL および HIGH 級の問題は検出されなかった。**

主要なフロー（Router → refs dispatch、フェーズゲート、auto-fix ループ、Wave QG、Consensus Mode、Verdict Persistence）は正確に設計されており、各ファイル間の整合性は高い。

最も注意すべきは **sdd-reboot の Analyst 失敗時のエラー処理**（MEDIUM #1）：SKILL.md の Error Handling は「delete branch, return to main」と明記しているが reboot.md では「BLOCK with error」のみで branch cleanup が規定されていない。この差異により、Lead が実際の失敗時に SKILL.md と reboot.md のどちらを優先すべきかが曖昧になる。

次いで **reboot Design-Only Pipeline の skip 選択後の EXIT 条件**（MEDIUM #2）は、run.md の Blocking Protocol を明示的に参照することで解決できるが、現状では参照が省略されている。

**改善推奨**:
1. reboot.md Phase 4 のリトライ失敗時に「delete branch, checkout main, report error」を明示する（SKILL.md と一致させる）
2. reboot.md Phase 7 の NO-GO exhaustion 時に「run.md Step 6 Blocking Protocol に準じる（ただし skip = design 完了不可として次 wave に進まない）」の旨を追記する
3. revise.md の Mode Detection に「instruction 語が spec 名に偶然一致する可能性」についての tie-breaking ルールを追加する
4. reboot.md Phase 6b に dot-prefixed ディレクトリの削除が意図的である旨の注記を追加する
