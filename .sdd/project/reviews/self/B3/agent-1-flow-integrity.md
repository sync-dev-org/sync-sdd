# Flow Integrity Review Report

## Issues Found

### [MEDIUM] CLAUDE.md Inspector数表記「+2 web」の曖昧さ
**Location**: `framework/claude/CLAUDE.md:26`
**Description**: 変更後の表記 `6 design + 6 impl inspectors +2 web (web projects), 4 (dead-code)` は、+2 web が impl review 専用であることを明示していない。Design review は 6 inspectors のみであり、web inspectors (E2E + Visual) は impl review のみで dispatch される。現在の表記だと「design にも web inspector が付く」と誤読される可能性がある。
**Suggested fix**: `6 design + 6 impl inspectors + 2 web-impl (web projects), 4 (dead-code)` または `6 design, 6+2 impl (web projects: +E2E +visual), 4 dead-code` のように impl 専用であることを明示する。
**Evidence**: `refs/review.md` の Design Review セクションは 6 inspectors のみを列挙。Impl Review セクションのみが `sdd-inspector-e2e` と `sdd-inspector-visual` を含む。

---

### [LOW] README.md の変更がスコープ外だが整合性は保たれている
**Location**: `README.md`
**Description**: diff に README.md の変更が含まれているが、フレームワーク内部フローには影響しない。ただし README のエージェント数が 24 になっているか確認が必要。
**Evidence**: `ls framework/claude/agents/ | wc -l` = 24 (sdd-inspector-visual.md を含む)。README が正しく更新されていれば問題なし。

---

## Confirmed OK

### 1. Router dispatch completeness
全サブコマンドが正しい refs にルーティングされている:
- `design {feature}` -> `refs/design.md` -- OK
- `impl {feature}` -> `refs/impl.md` -- OK
- `review design|impl|dead-code {feature}` -> `refs/review.md` -- OK
- `run` / `run --gate` / `run --consensus N` -> `refs/run.md` -- OK
- `revise {feature}` -> `refs/revise.md` -- OK
- `create` / `update` / `delete` -> `refs/crud.md` -- OK
- `-y` -> auto-detect (Router 内で直接処理) -- OK
- `""` -> auto-detect with user choice -- OK

Router (SKILL.md) の「Execution Reference」セクションが全モードをカバーしている。

### 2. Phase gate consistency

各 ref のフェーズゲートが CLAUDE.md の定義と一致:

| ref | 要求フェーズ | CLAUDE.md 定義との整合 |
|-----|------------|----------------------|
| design.md | `initialized` (標準), `design-generated`/`implementation-complete` (再生成) | OK: `blocked` -> BLOCK, 不明フェーズ -> BLOCK |
| impl.md | `design-generated` (標準), `implementation-complete` (再実行) | OK: `blocked` -> BLOCK |
| review.md (design) | `design.md` 存在 + `blocked` でない | OK |
| review.md (impl) | `implementation-complete` + `blocked` でない | OK |
| review.md (dead-code) | フェーズゲートなし | OK: 全コードベース対象 |
| revise.md | `implementation-complete` + completed wave | OK |

CLAUDE.md Phase Gate: `blocked` -> BLOCK, 不明フェーズ -> BLOCK が全 ref で遵守されている。

### 3. Auto-fix loop

CLAUDE.md Auto-Fix Counter Limits と refs の整合:

| パラメータ | CLAUDE.md | run.md | 整合 |
|-----------|-----------|--------|------|
| retry_count max | 5 | Step 4: "max 5 retries" | OK |
| spec_update_count max | 2 | Step 4: "max 2" | OK |
| aggregate cap | 6 | Step 4: "MUST NOT exceed 6" | OK |
| Dead-Code max retries | 3 | Step 7b: "max 3 retries" | OK |
| CONDITIONAL = GO | 明記 | Step 4: "GO/CONDITIONAL -> advance" (counters NOT reset) | OK |
| Counter NOT reset on GO/CONDITIONAL | 明記 | Step 4: "counters NOT reset" | OK |
| Counter reset triggers | wave completion, user escalation, revise start | run.md Step 7c: "Reset counters" / revise.md Step 4: "Reset retry_count=0, spec_update_count=0" | OK |

NO-GO 処理フロー:
- Design Review NO-GO -> Architect 再 dispatch + retry_count++ (run.md Step 4) -- OK
- Impl Review NO-GO -> Builder 再 dispatch + retry_count++ (run.md Step 4) -- OK
- SPEC-UPDATE-NEEDED -> spec_update_count++ + phase reset + cascade (run.md Step 4) -- OK

Standalone review (review.md Standalone Verdict Handling): auto-fix なし、verdict 表示のみ -- OK。パイプラインオーケストレーション内のみで auto-fix ループ発動。

### 4. Wave Quality Gate (run.md Step 7)

完全なフロー:
1. 全 spec が `implementation-complete` or `blocked` -> Wave QG 開始
2. Impl Cross-Check Review (wave-scoped) -> verdict 処理
3. Dead Code Review -> verdict 処理
4. Post-gate: counter reset, knowledge flush, commit

1-Spec Roadmap: Skip (Router 1-Spec Roadmap Optimizations) -- OK
run.md Step 7: "1-Spec Roadmap: Skip this step" -- OK

Wave QG NO-GO 処理:
- Cross-check NO-GO: target spec 特定 -> Builder 再 dispatch -> retry (max 5, aggregate cap 6) -- OK
- Exhaustion: escalate (Proceed / Abort wave / Manual fix) -- OK
- SPEC-UPDATE-NEEDED: identify target spec(s), cascade -- OK
- Dead-code NO-GO: max 3 retries -> escalate -- OK

### 5. Consensus mode

SKILL.md (Router) Consensus Mode が一貫:
- `active-{p}/` ディレクトリ分離 -- OK
- N=1 (default): `active/` (suffix なし) -- OK
- Threshold: ceil(N*0.6) -- OK
- Archive: `B{seq}/pipeline-{p}/` -- OK
- review.md: "If `--consensus N`, apply Consensus Mode protocol (see Router)" -- 正しく Router に委譲

run.md Step 4: "--consensus N" 参照 -- Router Consensus Mode にリダイレクト -- OK
矛盾なし。

### 6. Verdict persistence format

Router Verdict Persistence Format が全レビュータイプで統一:
- ヘッダー: `## [B{seq}] {review-type} | {timestamp} | v{version} | runs:{N} | threshold:{K}/{N}`
- Sections: Raw, Consensus, Noise, Disposition, Tracked, Resolved

review.md Verdict Destination by Review Type:
- Single-spec: `specs/{feature}/reviews/verdicts.md` -- OK
- Dead-code: `project/reviews/dead-code/verdicts.md` -- OK
- Cross-check: `project/reviews/cross-check/verdicts.md` -- OK
- Wave-scoped: `project/reviews/wave/verdicts.md` -- OK
- Self-review: `project/reviews/self/verdicts.md` -- OK

run.md Step 7: wave verdict ヘッダー `[W{wave}-B{seq}]` / `[W{wave}-DC-B{seq}]` -- Wave QG 固有だが Verdict Persistence Format の拡張として整合。

### 7. Edge cases

#### Empty roadmap
- Router Step 2: roadmap なし -> 検出、Create flow 提示 -- OK
- `review dead-code` / `--cross-check` / `--wave N`: BLOCK "No roadmap found" -- OK
- Lifecycle subcommands: auto-create 1-spec roadmap -- OK

#### 1-Spec roadmap
- Router 1-Spec Roadmap Optimizations: Wave QG skip, cross-spec 分析 skip, dead-code skip, commit format `{feature}: {summary}` -- OK
- run.md Step 7: "1-Spec Roadmap: Skip this step" -- OK
- review.md: "1-Spec Roadmap guard" for cross-check/wave -- OK
- impl.md Step 4: 1-spec only -> knowledge flush 直接実行 -- OK

#### Blocked spec
- Phase gate: 全 ref で `blocked` -> BLOCK + error message -- OK
- Blocking Protocol (run.md Step 6): downstream traverse, phase save, blocked_info 設定 -- OK
- Unblock: upstream `implementation-complete` 確認 -> restore phases -- OK

#### Retry limit exhaustion
- run.md Step 4: aggregate cap 6 -> escalate -- OK
- run.md Step 7: Wave QG exhaustion -> escalate with options (Proceed / Abort wave / Manual fix) -- OK
- Dead-code: max 3 -> escalate -- OK
- revise.md Step 4: counters reset -- OK (CLAUDE.md Counter reset triggers: `/sdd-roadmap revise` start)

### 8. Read clarity (Router -> refs 読み込みタイミング)

Router (SKILL.md) Execution Reference:
> After mode detection and roadmap ensure, Read the reference file for the detected mode

明示的に「モード検出 + roadmap ensure 完了後に Read」と指定されている。各 ref ファイルの冒頭にも「Assumes Single-Spec Roadmap Ensure already completed by router」と明記 -- OK。

### 9. Web Inspector 変更の Flow Integrity (未コミット変更)

#### sdd-inspector-visual.md (NEW FILE)
- Agent 定義: name, description, model(sonnet), tools(Read, Glob, Grep, Write, Bash) -- 他の Inspector と整合
- Mission: visual design quality (E2E と明確に分離) -- OK
- playwright-cli 使用 (Bash tool 必要) -- tools に Bash あり -- OK
- 「Dev server is managed by Lead」明記 -- OK
- CPF output format: VERDICT/SCOPE/ISSUES/NOTES -- 標準 CPF 準拠 -- OK
- Categories: `visual-system`, `visual-quality`, `visual-a11y` -- Auditor のリストと整合 -- OK
- Error handling: playwright-cli 未インストール -> GO + NOTES:SKIPPED -- E2E inspector と同パターン -- OK

#### sdd-inspector-e2e.md (REWRITE)
- Server management: 削除 (Lead に移管) -- review.md Web Inspector Server Protocol と整合 -- OK
- Visual design evaluation: 削除 (Visual Inspector に分離) -- OK
- E2E-only focus: functional correctness のみ -- OK
- Category: `e2e-flow` のみ -- OK
- server URL を spawn context で受け取る -- review.md Step 4 "Web inspectors: also include server URL" と整合 -- OK

#### sdd-auditor-impl.md (UPDATE)
- Mission: "up to 8 independent review agents" (7->8) -- OK
- Inspector list: #7 e2e + #8 visual (分離) -- OK
- Cross-check hints: E2E/Visual 間の cross-check ルール追加 -- 新規追加、既存ルールと矛盾なし -- OK

#### refs/review.md (UPDATE)
- Impl Review: `sdd-inspector-e2e` and `sdd-inspector-visual` -- OK
- Web Inspector Server Protocol: Lead manages server lifecycle -- OK
- Review Execution Flow:
  - Step 3a: Server Start (before dispatch) -- OK
  - Step 4: web inspectors に server URL 含める -- OK
  - Step 5a: Server Stop (after inspectors complete, before Auditor) -- OK
- Server failure: "dispatch web inspectors anyway" -- graceful degradation -- OK

#### ui.md template (UPDATE)
- Footer: "referenced by sdd-inspector-visual" -- OK (旧: sdd-inspector-e2e から分離)

### 10. SubAgent Lifecycle (background-only dispatch)

CLAUDE.md SubAgent Lifecycle: `run_in_background: true` **always**。全 ref を確認:
- design.md Step 3: `run_in_background=true` -- OK
- impl.md Step 2: `run_in_background=true` -- OK
- impl.md Step 3: `run_in_background=true` -- OK
- review.md Step 4: `run_in_background=true` -- OK
- review.md Step 6: `run_in_background=true` -- OK
- run.md Step 4: `run_in_background: true` -- OK

### 11. Artifact Ownership

CLAUDE.md Artifact Ownership の制約が各 ref で遵守:
- design.md: spec.yaml は Lead が更新 (Architect は design.md/research.md のみ) -- OK
- impl.md: spec.yaml は Lead が更新 (TaskGenerator は tasks.yaml のみ, Builder はコード+テストのみ) -- OK
- review.md: Inspector は CPF のみ, Auditor は verdict.cpf のみ -- OK
- revise.md Step 1: "Lead follows CLAUDE.md Artifact Ownership" 明記 -- OK

### 12. Handover auto-draft

CLAUDE.md Write Triggers: コマンド完了後に session.md auto-draft。全 ref で確認:
- design.md Step 4: "Auto-draft session.md" -- OK
- impl.md Step 4: "Auto-draft session.md" -- OK
- review.md Standalone: "Auto-draft session.md" -- OK
- run.md Step 4: "Auto-draft session.md" (各 phase handler) -- OK
- run.md Step 7c: "Auto-draft session.md" (Post-gate) -- OK
- revise.md Step 7: "Auto-draft session.md" -- OK
- crud.md: Create Step 10, Update Step 5 -- OK

### 13. Steering Feedback Loop

CLAUDE.md Steering Feedback Loop: "Process after handling verdict but before advancing"。
- review.md Steering Feedback Loop Processing: CODIFY/PROPOSE 処理ルール -- OK
- run.md Step 4: "Process STEERING entries from verdict" (Design Review / Impl Review completion) -- OK
- revise.md: 直接の STEERING 処理記述はないが、"Handle verdict per CLAUDE.md counter limits" 経由で review.md の処理が適用される -- OK

### 14. Knowledge Auto-Accumulation

CLAUDE.md Knowledge Auto-Accumulation フロー:
- Builder -> tags -> Lead collects -> buffer.md -- OK
- impl.md Step 3: "Store knowledge tags in buffer.md" -- OK
- impl.md Step 4: 1-spec -> flush to knowledge/ -- OK
- run.md Step 7c: wave completion -> flush + clear buffer.md -- OK
- Wave bypass (fast-track): 1-Spec Optimizations 適用 -> impl.md で flush -- OK

### 15. Consensus Mode と Wave QG の整合

Consensus mode は review subcommand のオプション。Wave QG (run.md Step 7) は `--consensus N` なしで cross-check を実行するが、run mode に `--consensus N` が渡された場合のフローを確認:
- run.md: "`--consensus N`" は run mode のオプション -- OK
- Router SKILL.md: `run --consensus N` -> Run Mode -- OK
- run.md Step 4: "For `--consensus N`, apply Consensus Mode protocol (see Router)" -- OK
- Wave QG (Step 7a) は `--consensus N` の明示的言及なし -> run 全体の `--consensus N` が全レビューに波及するか不明確だが、run.md Step 4 の Phase Handlers で各レビューに対して "For `--consensus N`, apply Consensus Mode protocol" と記述されているため問題なし。

---

## Overall Assessment

### 総合評価: GOOD

フレームワークのフロー整合性は高いレベルで維持されている。Router -> refs dispatch は全モードで正しくルーティングされ、Phase gate、Auto-fix loop、Wave QG のカウンタ管理が CLAUDE.md と各 ref 間で一致している。

### 未コミット変更の評価

E2E/Visual inspector 分離の変更は適切に統合されている:
- review.md に Web Inspector Server Protocol が追加され、Lead の server lifecycle 管理が明確化
- sdd-auditor-impl.md に E2E/Visual cross-check hints が追加
- sdd-inspector-visual.md は E2E inspector と同一パターンで作成されており、CPF format も整合
- Server URL の受け渡しフローが review.md Step 4 -> Inspector spawn context で一貫

### 検出された問題

| Priority | ID | Summary | Severity |
|----------|-----|---------|----------|
| 1 | M1 | CLAUDE.md の "+2 web" 表記が impl 専用であることを明示していない | MEDIUM |
| 2 | L1 | README.md エージェント数の確認 (スコープ外) | LOW |
