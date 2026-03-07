# Unified Self-Review Report: Codex (B1) + Sonnet (B23)
**Date**: 2026-03-03T21:01:23+0900
**Sources**: sdd-review-self-ext B1 (Codex, 4 agents) + sdd-review-self B23 (Sonnet, 4 agents)

## Unified Findings (deduplicated, 18 unique)

### HIGH (5)

| ID | Finding | Detected By | Location |
|---|---|---|---|
| U-H1 | settings.json に Skill(sdd-review-self-ext) 未登録 | Codex+Sonnet | settings.json |
| U-H2 | Router feature-less --cross-check/--wave vs review.md 入力仕様不整合 | Codex only | review.md:5, SKILL.md:21-28 |
| U-H3 | review dead-code ルーティングが SKILL.md Execution Reference に未記載 | Sonnet only | SKILL.md:96-105 |
| U-H4 | sdd-review-self-ext Review Scope に engines.yaml テンプレート未含 | Codex only | sdd-review-self-ext/SKILL.md:52 |
| U-H5 | revise.md Part B Step 8 Cross-Cutting spec_update_count が aggregate cap に未言及 | Sonnet only | revise.md:258 |

### MEDIUM (10)

| ID | Finding | Detected By | Location |
|---|---|---|---|
| U-M1 | SPEC-UPDATE-NEEDED 処理が run.md/revise.md に重複 | Sonnet | run.md:189, revise.md |
| U-M2 | Cross-cutting scope-dir が review execution flow で未定義 | Codex | review.md:75,137 |
| U-M3 | Consensus mode の scope-dir / B{seq} 責務が不明確 | Codex+Sonnet | SKILL.md:116, review.md |
| U-M4 | Revise Mode spec 名照合の順序が SKILL.md で不明確 | Sonnet | SKILL.md:34-35 |
| U-M5 | Agent frontmatter background: true は Claude Code 公式仕様外 | Codex | agents/sdd-*.md |
| U-M6 | engines.yaml テンプレートコメント "NOT overwritten" が曖昧 | Sonnet | engines.yaml:4 |
| U-M7 | Standalone review auto-fix 記述矛盾 | Codex | review.md:103 |
| U-M8 | reboot.md Phase 9/10 の merge 矛盾 + skip/completion 矛盾 | Codex+Sonnet | reboot.md:194,270,301 |
| U-M9 | run.md Island Spec demote 先 wave が未規定 | Sonnet | run.md:87 |
| U-M10 | sdd-steering Engines Mode が .sdd/ ハードコード | Sonnet | sdd-steering/SKILL.md:61-65 |

### LOW (5)

| ID | Finding | Detected By |
|---|---|---|
| U-L1 | 1-Spec Wave QG スキップ条件が重複記述 | Sonnet |
| U-L2 | verdicts.md ヘッダーフォーマットが self/self-ext で異なる | Sonnet |
| U-L3 | tmux 並行 wait-for パターンが tmux-integration.md に未記載 | Sonnet |
| U-L4 | sdd-inspector-e2e wave scope 書式が不明瞭 | Sonnet |
| U-L5 | sdd-review-self-ext compliance cache ".cpf or .md" が曖昧 | Sonnet |

## Comparison Summary

| Metric | Codex | Sonnet | Overlap |
|---|---|---|---|
| Total unique findings | 9 (H4 M5) | 15 (H3 M7 L5) | 3 shared |
| Codex-only | 5 (H2 M3) | — | — |
| Sonnet-only | — | 10 (H2 M4 L5) | — (L5 all Sonnet) |
| Depth (review.md) | Deep (4 findings) | Shallow (1 finding) | — |
| Breadth | Narrow (2-3 files) | Wide (7+ files) | — |
| LOW sensitivity | None | 5 items | — |

## Recommended Fix Priority (Unified)

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 | U-H1 | settings.json に Skill(sdd-review-self-ext) 追加 | settings.json |
| 2 | U-H4 | Review Scope に engines.yaml パターン追加 | sdd-review-self-ext/SKILL.md |
| 3 | U-H5 | Cross-Cutting Review に spec_update_count 言及追加 | revise.md |
| 4 | U-H2,U-H3 | review.md / SKILL.md ルーティング仕様整備 | review.md, SKILL.md |
| 5 | U-M5 | Agent frontmatter background: true 削除 | agents/sdd-*.md (27 files) |
| 6 | U-M8 | reboot.md Phase 9/10 矛盾解消 | reboot.md |
| 7 | U-M2,U-M3,U-M7 | review.md cross-check/cross-cutting/standalone 仕様整備 | review.md |
| 8 | U-M6,U-M10 | パス/コメント整合 | engines.yaml, sdd-steering |
