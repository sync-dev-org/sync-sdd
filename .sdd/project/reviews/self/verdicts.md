# Self-Review Verdicts

## [B1] full | 2026-02-24 | v0.23.1 | agents:5/5
C:1 H:2 M:3 L:2 | FP:4 eliminated
Files: framework/claude/skills/sdd-roadmap/refs/run.md, install.sh, framework/claude/CLAUDE.md

## [B2] full | 2026-02-24 | v1.0.0+uncommitted | agents:5/5
C:0 H:1 M:2 L:3 | FP:5 eliminated
Files: framework/claude/CLAUDE.md, framework/claude/agents/sdd-builder.md, framework/claude/skills/sdd-roadmap/refs/impl.md, framework/claude/skills/sdd-roadmap/refs/review.md

## [B3] full | 2026-02-24 | v1.0.3+uncommitted | agents:5/5
C:0 H:0 M:2 L:2 | FP:3 eliminated
Files: framework/claude/CLAUDE.md, framework/claude/skills/sdd-roadmap/refs/review.md

## [B4] full | 2026-02-24 | v1.0.4+cross-cutting | agents:5/5
C:0 H:0 M:2 L:2 | FP:7 eliminated
Files: framework/claude/CLAUDE.md, framework/claude/skills/sdd-roadmap/refs/review.md

## [B5] full | 2026-02-24 | v1.1.2+sdd-root-move | agents:1/5
C:0 H:0 M:0 L:0 | FP:3 eliminated
Files: (none — all findings were false positives)
Note: 4/5 agents hit usage limits. Only Regression Detection completed.

## [B6] full | 2026-02-24 | v1.1.2+sdd-root-move | agents:5/5
C:0 H:0 M:0 L:2 | FP:19 eliminated
Files: framework/claude/sdd/settings/rules/design-principles.md, install.sh

## [B7] full | 2026-02-24 | v1.2.0+compact-fix | agents:5/5
C:0 H:0 M:0 L:2 | FP:12 eliminated
Files: framework/claude/sdd/settings/rules/design-discovery-full.md, framework/claude/skills/sdd-roadmap/SKILL.md

## [B8] full | 2026-02-24 | v1.2.3 | agents:4/4
C:0 H:3 M:9 L:7 | FP:3 eliminated
Files: refs/impl.md, refs/revise.md, refs/run.md, refs/review.md, README.md, agents/sdd-inspector-impl-holistic.md, SKILL.md(sdd-roadmap)

## [B9] full | 2026-02-27 | v1.2.5+wave-context | agents:4/4
C:0 H:0 M:4 L:6 | FP:1 eliminated
Files: refs/revise.md, refs/run.md, refs/impl.md, agents/sdd-inspector-best-practices.md
Note: M1,M3,L3 fixed in-session. M2,M4 pre-existing.

## [B10] full | 2026-02-27 | v1.3.0+b9-fixes | agents:4/4
C:0 H:0 M:1 L:10 | FP:5 eliminated
Files: CLAUDE.md, refs/review.md, agents/sdd-inspector-best-practices.md
Note: M1,L1,L2 fixed in-session. L3-L10 pre-existing backlog.

## [B11] full | 2026-02-28 | v1.3.2+context-budget | agents:4/4
C:1 H:1 M:2 L:2 | FP:16 eliminated
Files: settings.json, CLAUDE.md, refs/impl.md, refs/revise.md

## [B12] full | 2026-02-27 | v1.4.0+sdd-reboot | agents:4/4
C:0 H:1 M:6 L:1 | FP:7 eliminated
Files: refs/reboot.md, CLAUDE.md, sdd-analyst.md, SKILL.md(sdd-reboot)

## [B13] full | 2026-02-27 | v1.5.1 | agents:4/4
C:0 H:1 M:9 L:8 | FP:5 eliminated
Files: CLAUDE.md, refs/impl.md, refs/reboot.md, refs/revise.md, refs/review.md, SKILL.md(sdd-roadmap), sdd-inspector-*.md

## [B14] full | 2026-02-27 | v1.5.1+uncommitted | agents:4/4
C:0 H:0 M:4 L:8 | FP:3 eliminated
Files: refs/run.md, settings.json, refs/reboot.md, CLAUDE.md

## [B15] full | 2026-02-28 | v1.5.3+tdd-improvement | agents:4/4
C:0 H:3 M:10 L:4 | FP:3 eliminated
Files: sdd-inspector-test.md, refs/revise.md, conventions-brief.md, design.md(template), SKILL.md(sdd-roadmap)
Note: H3,L3 from current TDD changes (fix in-session). M5,M6 related. H1,H2,M1-M4,M7-M10 pre-existing.

## [B16] full | 2026-03-01 | v1.6.1+release-content-review | agents:4/4
C:0 H:1 M:6 L:8 | FP:1 eliminated
Files: README.md, sdd-analyst.md, SKILL.md(sdd-release)
Note: H1 (README sdd-reboot 欠落) は Step 3.2 改善の有効性を裏付ける好例。M4 from current changes. M1-M3,M5-M6,L2-L8 pre-existing.

## [B17] full | 2026-03-01 | v1.8.0+reboot-improvements | agents:4/4
C:2 H:2 M:2 L:1 | FP:4 eliminated
Files: sdd-reboot/SKILL.md, analysis-report.md(template), sdd-analyst.md, sdd-roadmap/SKILL.md, sdd-review-self/SKILL.md, CLAUDE.md, profiles/_index.md
Note: C1,C2,H1 from current session changes (Analyst strictification + ConventionsScanner skip). H2 pre-existing (Task→Agent in allowed-tools). M1,M2,L1 from current session (tmux + profile).

## [B18] full | 2026-03-01 | v1.9.0+e2e-gate | agents:4/4
C:0 H:2 M:4 L:0 | FP:0 eliminated
Files: sdd-analyst.md, refs/run.md, CLAUDE.md, refs/impl.md, refs/revise.md
Note: All 6 findings from current session changes (E2E Gate + dependency management). All fixed in-session. Pre-existing backlog: H3 M8 L6.

## [B19] full | 2026-03-03 | v1.11.0+sdk-drift | agents:4/4
C:0 H:1 M:5 L:8 | FP:9 eliminated
Files: settings.json, sdd-steering/SKILL.md, sdd-architect.md, refs/impl.md, sdd-inspector-dead-specs.md, sdd-inspector-dead-tests.md, sdd-inspector-rulebase.md, refs/run.md
Note: H1 from v1.11.0 publish-setup permissions oversight. M4,M5 from current SDK drift commit. M1,M2,M3 pre-existing. Pre-existing backlog: H3 M8 L6.

## [B20] full | 2026-03-03T15:21:32+0900 | v1.12.1+e2e-gate-integration | agents:4/4
C:0 H:0 M:0 L:0 | FP:2 eliminated
Files: (none — all findings were pre-existing backlog)
Note: E2E Gate → sdd-inspector-test 統合 + Inspector リネーム (web-e2e, web-visual)。変更起因の問題なし。Pre-existing backlog: H0 M8 L10.

## [B21] full | 2026-03-03T16:42:03+0900 | v1.13.1+inspector-e2e | agents:4/4
C:0 H:0 M:1 L:0 | FP:3 eliminated
Files: framework/claude/agents/sdd-inspector-e2e.md
Note: sdd-inspector-e2e 新設 + inspector-test E2E 分離。M1 (design.md placeholder filter) fixed in-session。README カウント更新はリリース時。Pre-existing backlog: H2 M8 L10.

## [B22] full | 2026-03-03T19:21:47+0900 | v1.14.0+tmux-codex | agents:4/4
C:0 H:2 M:1 L:1 | FP:4 eliminated
Files: settings.json, sdd-release/SKILL.md, review.md, tmux-integration.md
Note: H1 (settings.json Skill 未登録), H2 (sdd-release 除外リスト漏れ) from current session (sdd-review-self-codex 新設)。M1 (review.md fallback 言及削除) from tmux 共通化。L1 (Orphan Cleanup スコープ拡大) 意図的だが注記推奨。Pre-existing backlog: H2 M8 L5.

## [B23] full | 2026-03-03T21:01:23+0900 | v1.14.1+review-self-ext | agents:4/4
C:0 H:3 M:7 L:5 | FP:0 eliminated
Files: settings.json, SKILL.md(sdd-roadmap), revise.md, reboot.md, engines.yaml, sdd-steering/SKILL.md, run.md
Note: S-H1 (settings.json Skill 未登録) persistent since B22。S-H2 (review dead-code routing), S-H3 (Cross-Cutting spec_update_count) new。S-M5 (reboot merge contradiction) pre-existing。Pre-existing backlog: H2 M8 L5.

## [B24] 2026-03-03T20:50:42+0900 | codex | agents:4/4
C:0 H:4 M:5 L:0 | FP:0 eliminated
Files: framework/claude/settings.json, framework/claude/skills/sdd-roadmap/refs/review.md, framework/claude/skills/sdd-roadmap/SKILL.md, framework/claude/skills/sdd-review-self-ext/SKILL.md, framework/claude/skills/sdd-reboot/refs/reboot.md, framework/claude/agents/sdd-*.md

## [B25] 2026-03-03T21:38:35+0900 | codex | agents:4/4
C:0 H:6 M:6 L:5 | FP:2 eliminated
Files: framework/claude/skills/sdd-roadmap/refs/review.md, framework/claude/skills/sdd-roadmap/refs/run.md, framework/claude/skills/sdd-roadmap/refs/revise.md, framework/claude/skills/sdd-review-self-ext/SKILL.md, framework/claude/agents/sdd-inspector-e2e.md, framework/claude/agents/sdd-inspector-test.md, framework/claude/agents/sdd-auditor-design.md, framework/claude/skills/sdd-reboot/refs/reboot.md, framework/claude/CLAUDE.md, framework/claude/skills/sdd-review-self/SKILL.md

## [B26] 2026-03-03T23:48:59+0900 | gemini [gemini-3-flash-preview] | agents:4/4
C:0 H:1 M:2 L:10 | FP:8 eliminated
Files: framework/claude/skills/sdd-roadmap/refs/review.md, framework/claude/agents/sdd-auditor-impl.md, framework/claude/agents/sdd-inspector-impl-rulebase.md, framework/claude/skills/sdd-review-self-ext/SKILL.md, framework/claude/sdd/settings/rules/tmux-integration.md, framework/claude/skills/sdd-handover/SKILL.md, framework/claude/agents/sdd-builder.md, framework/claude/agents/sdd-auditor-dead-code.md, framework/claude/skills/sdd-*/SKILL.md

## [B27] 2026-03-04T01:15:23+0900 | codex | agents:4/4
C:0 H:5 M:4 L:2 | FP:3 eliminated
Files: framework/claude/skills/sdd-review-self-ext/SKILL.md, framework/claude/sdd/settings/rules/tmux-integration.md, framework/claude/skills/sdd-roadmap/refs/review.md, framework/claude/skills/sdd-roadmap/refs/revise.md, framework/claude/skills/sdd-roadmap/refs/run.md, framework/claude/agents/sdd-builder.md, framework/claude/skills/sdd-publish-setup/SKILL.md, framework/claude/settings.json

## [B28] 2026-03-04T04:11:06+0900 | codex | agents:4/4
C:0 H:5 M:5 L:3 | FP:9 eliminated
Files: framework/claude/skills/sdd-review-self-ext/SKILL.md, framework/claude/skills/sdd-roadmap/refs/review.md, framework/claude/skills/sdd-roadmap/refs/revise.md, framework/claude/skills/sdd-roadmap/refs/run.md, framework/claude/sdd/settings/scripts/multiview-grid.sh, install.sh, framework/claude/CLAUDE.md

## [B29] 2026-03-04T04:40:54+0900 | codex | agents:4/4
C:0 H:4 M:2 L:4 | FP:4 eliminated
Files: framework/claude/sdd/settings/rules/tmux-integration.md, framework/claude/skills/sdd-roadmap/refs/run.md, framework/claude/skills/sdd-roadmap/refs/revise.md, framework/claude/skills/sdd-roadmap/refs/review.md

## [B30] 2026-03-04T05:34:19+0900 | codex | agents:4/4
C:0 H:2 M:3 L:1 | FP:6 eliminated
Files: framework/claude/skills/sdd-review-self-ext/SKILL.md, framework/claude/agents/sdd-auditor-design.md, framework/claude/agents/sdd-auditor-impl.md, framework/claude/agents/sdd-auditor-dead-code.md, install.sh

## [B31] 2026-03-04T06:00:36+0900 | codex (agent pipeline) | agents:4/4+prep+auditor
C:0 H:5 M:4 L:3 | FP:3 eliminated
Files: framework/claude/skills/sdd-roadmap/refs/review.md, framework/claude/skills/sdd-roadmap/SKILL.md, framework/claude/skills/sdd-review-self-ext/SKILL.md, framework/claude/skills/sdd-roadmap/refs/run.md, framework/claude/agents/sdd-auditor-impl.md, framework/claude/CLAUDE.md, framework/claude/settings.json, framework/claude/skills/sdd-reboot/refs/reboot.md

## [B32] 2026-03-04T11:45:12+0900 | codex | agents:4/4
C:0 H:3 M:5 L:4 | FP:4 eliminated | ALL DEFERRED
Files: framework/claude/skills/sdd-review-self-ext/SKILL.md, framework/claude/skills/sdd-roadmap/SKILL.md, framework/claude/skills/sdd-roadmap/refs/review.md, framework/claude/skills/sdd-roadmap/refs/run.md, framework/claude/skills/sdd-roadmap/refs/revise.md, framework/claude/agents/sdd-inspector-test.md, framework/claude/skills/sdd-review-self-ext/refs/auditor.md, framework/claude/skills/sdd-review-self-ext/refs/prep.md

## [B33] 2026-03-04T15:03:58+0900 | codex (agent pipeline, prep:codex-spark) | agents:4/4+prep+auditor
C:0 H:3 M:4 L:2 | FP:3 eliminated | ALL DEFERRED
Files: framework/claude/skills/sdd-review-self-ext/refs/prep.md, framework/claude/sdd/settings/rules/tmux-integration.md, framework/claude/skills/sdd-review-self-ext/SKILL.md, framework/claude/skills/sdd-review-self-ext/refs/agent-4-compliance.md, framework/claude/skills/sdd-roadmap/refs/review.md, framework/claude/skills/sdd-roadmap/refs/run.md

## [B34] 2026-03-04T15:40:59+0900 | codex (agent pipeline, prep:codex-spark, inspectors:codex-spark) | agents:4/4+prep+auditor
C:0 H:0 M:0 L:0 | FP:3 eliminated
Files: (none — all findings eliminated as FP)

## [B35] 2026-03-05T01:14:58+0900 | codex (agent pipeline, prep:codex-spark, auditor:claude-sonnet-4-6) | agents:4/4+prep+auditor
C:0 H:1 M:5 L:3 | FP:4 eliminated
Files: framework/claude/skills/sdd-review-self/SKILL.md, framework/claude/sdd/settings/templates/review-self/agent-4-compliance.md, framework/claude/sdd/settings/templates/review-self/agent-1-flow.md, framework/claude/skills/sdd-status/SKILL.md, framework/claude/skills/sdd-roadmap/SKILL.md
Note: A9 fixed in-session. B5 (H1 M4) all pre-existing backlog, deferred.

## [B36] 2026-03-05T01:42:32+0900 | codex (agent pipeline, prep:codex-spark, auditor:claude-sonnet-4-6) | agents:4/4+prep+auditor
C:0 H:0 M:0 L:0 | FP:6 eliminated (1 Auditor + 5 Lead supervisory)
Files: (none — all findings eliminated as FP or deferred)
Note: Auditor reported H2 M1 L2 A5 B3. Lead supervisory: A5 all FP (A-1,A-2 fabricated non-existent commands; A-3 historical migration context; A-4 intentional defensive programming; A-5 standard shorthand). B3 all deferred (B-1 theoretical per-stage engine gap, B-2 orphan spec edge case, B-3 grid slot validation edge case). Pre-existing backlog: H1 M4 (carry from B35).

## [B37] 2026-03-05T03:39:36+0900 | prep:codex-spark insp:codex aud:claude-sonnet-4-6 | agents:4/4+prep+auditor
C:0 H:1 M:2 L:2 | FP:6 eliminated (2 Auditor + 4 Lead supervisory)
Files: framework/claude/skills/sdd-roadmap/SKILL.md, framework/claude/sdd/settings/templates/review-self/prep.md, framework/claude/skills/sdd-review-self/SKILL.md, framework/claude/agents/sdd-inspector-impl-rulebase.md
Note: A4 fixed in-session (A-1 router exception, A-2 BLOCK list, A-3 prep --count, A-4 step numbering). F11 (VERDICT enum) fixed in-session. B3 deferred (B-1 impl auditor High 1-3, B-2 Wave QG SPEC-UPDATE-NEEDED, B-3 revise override). Backlog: F03,F06 FIXED. F09,F10 still present (defer). Pre-existing backlog: H1 M2 (F02→B-2, F09, F10).

## [B38] 2026-03-05T04:54:27+0900 | prep:codex-spark insp:codex aud:claude-sonnet-4-6 | agents:4/4+prep+auditor
C:0 H:5 M:6 L:4 | FP:7 eliminated (3 Auditor + 4 Lead supervisory)
Files: framework/claude/skills/sdd-roadmap/SKILL.md, framework/claude/sdd/settings/rules/tmux-integration.md, framework/claude/skills/sdd-review-self/SKILL.md, framework/claude/skills/sdd-roadmap/refs/run.md, framework/claude/skills/sdd-roadmap/refs/review.md, framework/claude/agents/sdd-auditor-impl.md, framework/claude/agents/sdd-auditor-design.md
Note: A5 fixed in-session (A-1 Reset→Delete, A-2 2>/dev/null除去, A-3 jqチェック追加, A-4 SPEC-UPDATE-NEEDED追記, A-5 jqクォート注記). B5 all pre-existing backlog, deferred (B-1 Readiness Rules不整合, B-2 Cross-Cutting昇格, B-3 impl auditor High 1-3, B-4 design auditor CONDITIONAL, B-5 VERDICT:ERROR未定義). Pre-existing backlog: H1 M4 (carry from B37).

## [B39] 2026-03-06T11:23:07+0900 | prep:codex-spark insp:codex aud:claude-sonnet-4-6 | agents:6/6 (fixed:3, dynamic:3)
C:0 H:5 M:10 L:8 | FP:2 eliminated
Files: framework/claude/skills/sdd-roadmap/refs/run.md, framework/claude/skills/sdd-roadmap/SKILL.md, framework/claude/CLAUDE.md, framework/claude/sdd/settings/templates/review/sdd-inspector-e2e.md, framework/claude/settings.json, framework/claude/sdd/settings/templates/review-self/agent-3-compliance.md, framework/claude/sdd/settings/templates/review-self/prep.md, install.sh, framework/claude/sdd/settings/scripts/multiview-grid.sh, framework/claude/skills/sdd-review-self/SKILL.md, framework/claude/skills/sdd-start/SKILL.md, framework/claude/sdd/settings/rules/tmux-integration.md, framework/claude/sdd/settings/scripts/orphan-detect.sh

## [B40] 2026-03-06T16:37:22+0900 | prep:codex-spark insp:codex aud:claude-sonnet-4-6 | agents:6/6 (fixed:3, dynamic:3)
C:1 H:2 M:3 L:6 | FP:12 eliminated (10 Auditor + 2 Lead supervisory)
Files: framework/claude/skills/sdd-reboot/refs/reboot.md, framework/claude/skills/sdd-roadmap/SKILL.md, framework/claude/skills/sdd-review/SKILL.md, framework/claude/skills/sdd-review-self/SKILL.md, framework/claude/skills/sdd-release/SKILL.md, framework/claude/CLAUDE.md, framework/claude/sdd/settings/templates/review-self/prep.md, framework/claude/sdd/settings/rules/tmux-integration.md, framework/claude/skills/sdd-roadmap/refs/run.md, framework/claude/skills/sdd-roadmap/refs/revise.md, install.sh

## [B41] self | 2026-03-06T17:58:51+0900 | v2.4.0 | prep:gpt-5.3-codex-spark insp:gpt-5.3-codex aud:claude-sonnet-4-6 | fixed:3 dynamic:3
C:0 H:7 M:13 L:8 | FP:7 eliminated
Files: framework/claude/skills/sdd-review-self/SKILL.md, framework/claude/skills/sdd-review/SKILL.md, framework/claude/skills/sdd-roadmap/SKILL.md, framework/claude/skills/sdd-roadmap/refs/run.md, framework/claude/skills/sdd-roadmap/refs/revise.md, framework/claude/skills/sdd-reboot/refs/reboot.md, framework/claude/sdd/settings/templates/review/impl-rulebase.md, framework/claude/CLAUDE.md, framework/claude/settings.json, install.sh
Note: A12 fixed in-session. B2 (settings.json --update migration) deferred — by design (--force required). B1 (cross-cutting spec list), B3 (blocked spec notification), B4 (stale pattern) fixed. ISSUE-1 (Prep state.yaml), ISSUE-2 (dynamic Inspector report) fixed.

## [B42] self | 2026-03-06T21:34:40+0900 | v2.5.0 | briefer:gpt-5.3-codex-spark insp:gpt-5.3-codex aud:claude-sonnet-4-6 | fixed:3 dynamic:3
C:0 H:1 M:4 L:2 | FP:9 eliminated (2 Auditor + 7 Lead supervisory)
Files: framework/claude/sdd/settings/templates/review-self/briefer.md, framework/claude/skills/sdd-roadmap/SKILL.md, framework/claude/skills/sdd-roadmap/refs/run.md, framework/claude/skills/sdd-review/SKILL.md

## [B43] self | 2026-03-07T01:25:45+0900 | v2.5.0 | briefer:gpt-5.3-codex-spark insp:gpt-5.3-codex aud:claude-sonnet-4-6 builder:claude-sonnet-4-6 | fixed:3 dynamic:3
C:0 H:3 M:3 L:4 | FP:4 eliminated (3 Auditor + 1 Lead supervisory)
Files: framework/claude/settings.json, install.sh, framework/claude/skills/sdd-review-self/SKILL.md, framework/claude/skills/sdd-roadmap/SKILL.md, framework/claude/skills/sdd-roadmap/refs/run.md, framework/claude/skills/sdd-roadmap/refs/revise.md, framework/claude/skills/sdd-review/SKILL.md, framework/claude/skills/sdd-steering/SKILL.md, README.md
### Raw
C:0 H:5 M:5 L:5 | FP:3 eliminated
Files: framework/claude/sdd/settings/templates/review-self/briefer.md,install.sh,framework/claude/settings.json,framework/claude/skills/sdd-start/SKILL.md,framework/claude/skills/sdd-review-self/SKILL.md,framework/claude/skills/sdd-roadmap/SKILL.md,framework/claude/skills/sdd-roadmap/refs/run.md,framework/claude/skills/sdd-roadmap/refs/revise.md,framework/claude/skills/sdd-steering/SKILL.md,README.md
### Disposition
A1 rejected: cache for old naming — discard is fine
A2 rejected: unconditional overwrite is correct for framework defaults
A3 fixed: Added jq/env/kill to settings.json allow list
A5 fixed: Changed scripts stale removal to *.sh only
A6 fixed: Moved $SCOPE_DIR definition before first reference
A7 fixed: Re-numbered Verdict Persistence steps (no gaps)
A8 fixed: Agent Prompts → Inspector Prompts (D185)
A9 fixed: Removed engines mode from sdd-steering
A10 fixed: 5 SubAgents → 5 agent profiles
A11 fixed: Added revise Detect Mode documentation
B1 fixed: Added --context wave/standalone to dead-code review
B2 fixed: Added Cross-Cutting ID generation rule + --id parameter
B3 fixed: Added explicit counter reset after ESCALATION_RESOLVED
B4 deferred: run.md ⇄ sdd-review circular reference — defer until Review Pipeline unification
FP: 4 eliminated (3 Auditor + 1 Lead supervisory)
### Builder
Engine: claude [claude-sonnet-4-6]
Fixed: 11/11 | Skipped: 0
### Tracked
B4: L | run.md ⇄ sdd-review circular reference | framework/claude/skills/sdd-roadmap/refs/run.md
