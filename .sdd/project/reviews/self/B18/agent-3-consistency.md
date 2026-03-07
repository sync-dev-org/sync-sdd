## Consistency & Dead Ends Report

レビュー対象: SDD フレームワーク全ファイル
実行日: 2026-03-01
レビュアー: Agent 3 (Consistency & Dead Ends)

---

### Issues Found

---

#### [MEDIUM] Inspectorカウントの不整合: CLAUDE.md vs review.md

**CLAUDE.md** (L27):
> `6 design, 6 impl +2 web (impl only, web projects), 4 dead-code`

**refs/review.md** Design Review section (L25-26):
> `- 6 design Inspectors`

これは一致している。しかし **sdd-auditor-design.md** (L13) は:
> `6 independent review agents`

一方 **sdd-auditor-impl.md** (L14) は:
> `up to 8 independent review agents`（6 standard + 2 web）

一致している。ただし **sdd-review-self/SKILL.md** Step 4 (L55) は:
> `4 agents` を dispatch

CLAUDE.md T3 Inspector 行の記述 `6 design, 6 impl +2 web (impl only, web projects), 4 dead-code` は self-review の 4 agents を含まない記述になっている。これは self-review が通常のフレームワーク Inspector とは別物であるため意図的とも読めるが、説明がない。

**ファイル**: `framework/claude/CLAUDE.md:27`

---

#### [MEDIUM] sdd-inspector-dead-code.md の SCOPE 出力値が不整合

**sdd-inspector-dead-code.md** の Output Format (L55) 例:
```
SCOPE:dead-code
```

しかし **sdd-inspector-dead-settings.md**, **sdd-inspector-dead-specs.md**, **sdd-inspector-dead-tests.md** の Output Format 例も同様に `SCOPE:dead-code` と記述している。

一方 **sdd-auditor-dead-code.md** の Input Handling (L37) は、それぞれのファイルを `sdd-inspector-dead-settings.cpf`, `sdd-inspector-dead-code.cpf`, `sdd-inspector-dead-specs.cpf`, `sdd-inspector-dead-tests.cpf` として参照している。

さらに **sdd-inspector-dead-code.md** の例 (L69) では:
```
SCOPE:cross-check
```
という値が使われており、同一ファイル内で `dead-code` と `cross-check` の両方が例として存在する。Dead Code Review の正しい SCOPE 値が不明確。

**ファイル**: `framework/claude/agents/sdd-inspector-dead-code.md:55,69`
`framework/claude/agents/sdd-inspector-dead-settings.md:55,63`

---

#### [MEDIUM] refs/review.md の Dead-Code Review verdict パスの不整合

**refs/review.md** Verdict Destination (L143-144):
```
- **Dead-code review**: `{{SDD_DIR}}/project/reviews/dead-code/verdicts.md`
```

しかし **refs/run.md** Step 7b (L246):
```
2. Persist verdict to `{{SDD_DIR}}/project/reviews/wave/verdicts.md` (header: `[W{wave}-DC-B{seq}]`)
```

Wave QG 内での Dead-Code Review は `reviews/wave/verdicts.md` に書かれるが、スタンドアロン `review dead-code` は `reviews/dead-code/verdicts.md` に書かれる。この2つのパスは異なる。スタンドアロン実行とWave QG実行で保存先が異なることは意図的かもしれないが、**Session Resume** (CLAUDE.md L276) にて:
```
Also check `{{SDD_DIR}}/project/reviews/*/verdicts.md` for project-level review state
```
このグロブパターンは `reviews/dead-code/`, `reviews/wave/`, `reviews/cross-check/` などをカバーするため実質的には問題ないが、明示的に記述されていない。

**ファイル**: `framework/claude/skills/sdd-roadmap/refs/review.md:143-144`
`framework/claude/skills/sdd-roadmap/refs/run.md:246`

---

#### [MEDIUM] sdd-reboot/refs/reboot.md Phase 7 の ConventionsScanner 欠落

**refs/reboot.md** Phase 7 Shared Research (L183-188):
```
### Shared Research
If 2+ Architects dispatch in parallel (Design Fan-Out):
1. Extract common technology decisions from steering
2. Identify shared dependencies across wave specs
3. Write to `{{SDD_DIR}}/project/specs/.wave-context/{wave-N}/shared-research.md`
```

`run.md` Step 2.5 では Wave Context Generation として ConventionsScanner を `sdd-conventions-scanner` SubAgent として dispatch するが、**reboot.md Phase 7 には ConventionsScanner dispatch の記述がない**。

**SKILL.md** (sdd-reboot/SKILL.md L35) は明示的に:
> `ConventionsScanner is NOT dispatched — zero-based redesign`

しかし reboot.md Phase 7 の Shared Research セクションは run.md Step 2.5 を参照しているかのような構造で、実際には ConventionsScanner をスキップして Lead が直接共有リサーチを生成する。この差異が明示されていない。

**ファイル**: `framework/claude/skills/sdd-reboot/refs/reboot.md:183-188`

---

#### [MEDIUM] revise.md Part B Step 7 での conventions brief パスの不整合

**refs/revise.md** Part B Step 7.2 (L213):
```
2. Wave Context Generation:
   - Dispatch `sdd-conventions-scanner` (mode: Generate) per run.md Step 2.5
   - Generate shared research if 2+ Architects in tier (include cross-cutting brief as additional context)
   - Store in specs/.cross-cutting/{id}/ alongside brief.md
```

Cross-cutting の conventions brief を `specs/.cross-cutting/{id}/` に保存するとあるが、`run.md` Step 2.5 では:
- Multi-spec roadmap: `{{SDD_DIR}}/project/specs/.wave-context/{wave-N}/conventions-brief.md`
- 1-spec roadmap: `{{SDD_DIR}}/project/specs/{feature}/conventions-brief.md`

Cross-cutting の場合のパスが `specs/.cross-cutting/{id}/` となっており、これは通常の wave context パスと異なる独自パスだが、ConventionsScanner の dispatch prompt に渡すパスの確認が必要。

**ファイル**: `framework/claude/skills/sdd-roadmap/refs/revise.md:213`

---

#### [MEDIUM] sdd-auditor-design.md の最終返却形式の矛盾

**sdd-auditor-design.md** (L231):
> `Return only \`WRITTEN:{verdict_file_path}\` as your final text to preserve Lead's context budget.`

しかし **CLAUDE.md** (L39) は:
> `**Review SubAgents** (Inspector/Auditor): return ONLY \`WRITTEN:{path}\`. All analysis goes into CPF output files.`

これは一致している。しかし **sdd-auditor-dead-code.md** の Output Format (L145) と比較すると、`WRITTEN:` ではなく実際の CPF を verdict output path に書いて `WRITTEN:` を返す構造になっている。いずれも一致しているが、Auditor が CPF を write してから `WRITTEN:` を返すという二段階の動作の説明が各 Auditor で統一されているか確認が必要 — 実際には統一されており問題ない。

**確認結果**: OK (重複チェックのため LOW に格下げ)

---

#### [LOW] CLAUDE.md の Session Resume ステップ番号の不整合

**CLAUDE.md** Session Resume (L272-286):
```
1. Detect: ...
2. Read session.md ...
2a. Read verdicts.md ...
3. Read decisions.md ...
4. Read buffer.md ...
5. If roadmap active ...
5a. If inside tmux ...
6. Append SESSION_START ...
7. If roadmap pipeline was active ...
```

ステップ `2a`, `5a` が中間番号として挿入されており、連続番号ではない。これは読み取り上の混乱をまねく可能性があるが、動作上の問題はない。

**ファイル**: `framework/claude/CLAUDE.md:272-286`

---

#### [LOW] sdd-analyst.md の Completion Report の `Steering:` フィールド記述

**sdd-analyst.md** Completion Report (L200-207):
```
ANALYST_COMPLETE
New specs: {count}
Waves: {count}
Steering: {created|updated} ({file_list})
Requirements identified: {count}
Files to delete: {count}
WRITTEN:{report_path}
```

**CLAUDE.md** (L41) では:
```
return structured summary (`ANALYST_COMPLETE` + counts + `Files to delete: {count}` + `WRITTEN:{path}`)
```

CLAUDE.md は `Steering:` フィールドと `Waves:` フィールドを省略した記述になっており、若干の不整合がある。ただし「counts」という表現が包括的に示しているとも読める。

**ファイル**: `framework/claude/CLAUDE.md:41` / `framework/claude/agents/sdd-analyst.md:200-207`

---

#### [LOW] sdd-status/SKILL.md の verdicts.md パス記述の不整合

**sdd-status/SKILL.md** Step 2 (L27-29):
```
1. Read `{{SDD_DIR}}/project/specs/roadmap.md` (if exists)
2. Scan `{{SDD_DIR}}/project/specs/*/spec.yaml` for all specs
3. Scan `{{SDD_DIR}}/project/specs/.cross-cutting/*/` for active/archived cross-cutting revisions
```

**sdd-status/SKILL.md** Step 3 (L46):
```
- **Review history**: If `reviews/verdicts.md` exists, display per batch: ...
```

`reviews/verdicts.md` という相対パスが記述されているが、完全パスは `{{SDD_DIR}}/project/specs/{feature}/reviews/verdicts.md` であるべき。他のファイルでは完全パスを使用しており、一貫性に欠ける。

**ファイル**: `framework/claude/skills/sdd-status/SKILL.md:46`

---

#### [LOW] install.sh の Profiles ディレクトリの uninstall 漏れ

**install.sh** uninstall セクション (L133-141):
```sh
rm -rf .claude/skills/sdd-*/
rm -f .claude/commands/sdd-*.md   # legacy cleanup
rm -f .claude/agents/sdd-*.md
rm -rf .sdd/settings/rules/ \
       .sdd/settings/templates/ \
       .sdd/settings/profiles/
```

`.sdd/settings/profiles/` は削除されるが、install セクション (L515) は:
```sh
install_dir "$SRC/framework/claude/sdd/settings/profiles"   ".sdd/settings/profiles"
```

これはインストール・アンインストール共に profiles を対象にしているため整合している。ただし、CLAUDE.md の Paths セクション (L126) では:
```
- Profiles: `{{SDD_DIR}}/settings/profiles/`
```
と記述されており、profiles は正式なフレームワークパスとして定義されている。問題なし。

---

### クロスリファレンスマトリックス

| ファイル A | 参照内容 | ファイル B | 整合性 |
|-----------|---------|-----------|--------|
| CLAUDE.md | `refs/run.md` Step 2.5, Step 3-4 | `sdd-roadmap/refs/run.md` | OK |
| CLAUDE.md | `refs/review.md` Steering Feedback Loop | `sdd-roadmap/refs/review.md` | OK |
| CLAUDE.md | Inspector counts: 6 design, 6+2 impl, 4 dead | `refs/review.md` | OK |
| CLAUDE.md | retry_count max 5, aggregate cap 6 | `refs/run.md` Phase Handlers | OK |
| CLAUDE.md | dead-code max 3 retries | `refs/run.md` Step 7b | OK |
| CLAUDE.md | ANALYST_COMPLETE format | `sdd-analyst.md` | 軽微な不整合 (LOW) |
| CLAUDE.md | Inspector数カウント | `sdd-review-self/SKILL.md` | self-review agents 未反映 (MEDIUM) |
| `refs/review.md` | dead-code verdict path | `refs/run.md` | Wave QG との違いが未明示 (MEDIUM) |
| `refs/review.md` | 6 design inspectors | `sdd-auditor-design.md` | OK |
| `refs/review.md` | impl inspector list (6+2 web) | `sdd-auditor-impl.md` | OK |
| `refs/review.md` | dead-code inspector list (4) | `sdd-auditor-dead-code.md` | OK |
| `refs/run.md` | Wave QG cross-check → `reviews/wave/verdicts.md` | `refs/review.md` | OK |
| `refs/run.md` | ConventionsScanner dispatch | `sdd-conventions-scanner.md` | OK |
| `refs/run.md` | Pilot Stagger → Supplement mode | `sdd-conventions-scanner.md` | OK |
| `refs/design.md` | Architect dispatch | `sdd-architect.md` | OK |
| `refs/impl.md` | TaskGenerator dispatch | `sdd-taskgenerator.md` | OK |
| `refs/impl.md` | Builder dispatch | `sdd-builder.md` | OK |
| `refs/impl.md` | E2E Gate | `refs/run.md` Phase Handlers | OK |
| `refs/revise.md` Part B | cross-cutting verdicts path | `SKILL.md` Verdict Persistence | OK |
| `refs/revise.md` Part B | conventions brief path | `refs/run.md` Step 2.5 | 軽微な不整合 (MEDIUM) |
| `refs/crud.md` | roadmap.md 構造 | `sdd-status/SKILL.md` | OK |
| `sdd-reboot/SKILL.md` | ConventionsScanner NOT dispatched | `refs/reboot.md` Phase 7 | 明示なし (MEDIUM) |
| `refs/reboot.md` | design loop → `refs/run.md` Step 4 | `refs/run.md` | OK |
| `settings.json` | Agent permissions list | `framework/claude/agents/sdd-*.md` | OK — 全エージェントが登録済み |
| `settings.json` | Skill permissions list | `framework/claude/skills/sdd-*/SKILL.md` | OK — 全スキルが登録済み |
| `install.sh` | `framework/claude/agents` → `.claude/agents` | `settings.json` Agent permissions | OK |
| `install.sh` | `framework/claude/skills` → `.claude/skills` | `settings.json` Skill permissions | OK |
| `install.sh` | version migrations | `sdd-release/SKILL.md` | OK |
| `design-review.md` (rules) | CPF severity mapping | `cpf-format.md` | OK |
| `tasks-generation.md` | spec IDs N.M形式 | `design-principles.md` | OK |
| `sdd-inspector-dead-code.md` | SCOPE例: dead-code/cross-check 混在 | 他の dead-code Inspectors | 軽微な不整合 (MEDIUM) |

---

### Confirmed OK

- **フェーズ名の統一**: `initialized` → `design-generated` → `implementation-complete` → `blocked` がすべてのファイルで一致している
- **Verdict値の統一**: `GO`, `CONDITIONAL`, `NO-GO`, `SPEC-UPDATE-NEEDED` がすべての Auditor と Phase Handler で一致している
- **CPF severity codes**: `C/H/M/L` (Critical/High/Medium/Low) がすべての Inspector・Auditor で一致している
- **retry_count 上限**: CLAUDE.md L176, run.md Phase Handlers いずれも max 5 で一致
- **aggregate cap**: CLAUDE.md L176, run.md Phase Handlers いずれも 6 で一致
- **spec_update_count 上限**: CLAUDE.md L176, run.md Phase Handlers いずれも max 2 で一致
- **dead-code retry 上限**: CLAUDE.md L177, run.md Step 7b いずれも max 3 で一致
- **Builder の返却フォーマット**: `BUILDER_COMPLETE` / `BUILDER_BLOCKED` が sdd-builder.md と CLAUDE.md L40 で一致
- **SubAgent dispatch**: `run_in_background: true` が CLAUDE.md L84 と各 refs ファイルで一致
- **Architect返却フォーマット**: `ARCHITECT_COMPLETE` が sdd-architect.md と design.md で一致
- **TaskGenerator返却フォーマット**: `TASKGEN_COMPLETE` が sdd-taskgenerator.md で定義
- **ConventionsScanner返却フォーマット**: `WRITTEN:{path}` のみが sdd-conventions-scanner.md と run.md Step 2.5 で一致
- **Analyst返却フォーマット**: `ANALYST_COMPLETE` が sdd-analyst.md と CLAUDE.md L41 で一致（細部に LOW issue あり）
- **STEERING feedback loop**: `CODIFY` / `PROPOSE` が Auditor 全3体と refs/review.md で一致
- **settings.json のエージェント登録**: 26エージェントファイルすべてが settings.json の permissions に登録済み
- **settings.json のスキル登録**: 7スキルすべてが settings.json の permissions に登録済み
- **init.yaml のフィールド**: spec.yaml 参照フィールド (orchestration, blocked_info, roadmap, version_refs等) が init.yaml と一致
- **{{SDD_DIR}} パス**: `.sdd` と定義され、すべてのファイルで一貫している
- **install.sh の install/uninstall 対称性**: 各インストール先と削除先が対称的になっている
- **循環参照**: SKILL.md → refs/*.md → agent/*.md の参照方向は一方向で循環なし
- **Wave Bypass (島スペック)**: run.md Step 3 で定義され、Wave QG をスキップする記述が一貫している
- **Design Lookahead**: run.md Step 4 で定義、staleness guard も記述あり
- **Blocking Protocol**: run.md Step 6 と CLAUDE.md Auto-Fix Counter Limits が一致
- **STEERING_EXCEPTION**: decisions.md の型として CLAUDE.md L190 と handover/SKILL.md で一致
- **sdd-review-self の 4エージェント**: general-purpose モデルで dispatch、フレームワーク SubAgent とは別体系として明示

---

### Overall Assessment

全体的に SDD フレームワークの整合性は高い水準にある。クリティカルな問題は検出されなかった。

検出された問題の概要:
- **MEDIUM 4件**: 主に死角エリアの明示不足（reboot での ConventionsScanner スキップの未明示、dead-code SCOPE 値の揺れ、cross-cutting conventions brief パスの仕様不明確、dead-code 保存先パスの Wave QG/スタンドアロン間の差異）
- **LOW 3件**: 軽微な記述の不整合（CLAUDE.md Analyst summary 記述の省略、Session Resume ステップ番号のスタイル、sdd-status の相対パス記述）

最も注意が必要な点は、**Dead-Code Review の verdict 保存先パス**が run コンテキスト（Wave QG）とスタンドアロン実行で異なること。これは意図的な設計だが、説明が不足している。Session Resume のグロブパターン (`reviews/*/verdicts.md`) がこれをカバーするよう設計されているため動作上の問題はない。

フェーズ名・Verdict 値・リトライカウント・エージェント名・ファイルパスはすべての参照箇所で統一されており、実運用上の問題はない。
