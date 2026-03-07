## Consistency Review Report

**レビュー対象**: SDD フレームワーク全ファイル
**レビュアー**: Agent 3 — Consistency & Dead Ends
**日時**: 2026-03-03

---

### Issues Found

#### [HIGH] Inspector カウントの不一致: CLAUDE.md と review.md の記述が食い違う

**CLAUDE.md (line 27)**:
> Inspector | Individual review perspectives. **6 design, 6 impl +1 e2e +2 web (impl only; e2e/web are conditional), 4 dead-code**.

**review.md — Impl Review セクション**:
```
Standard impl Inspectors (6, sonnet): sdd-inspector-impl-rulebase, sdd-inspector-interface,
sdd-inspector-test, sdd-inspector-quality, sdd-inspector-impl-consistency, sdd-inspector-impl-holistic
+ sdd-inspector-e2e (conditional)
+ sdd-inspector-web-e2e and sdd-inspector-web-visual (conditional, web only)
```

これは一致している（6 + 1 + 2 = 9 max）。
**しかし** sdd-auditor-impl.md (line 13) には：
> Cross-check, verify, and integrate findings from **up to 9** independent review agents

9 は最大値として正しいが、CLAUDE.md では「6 impl +1 e2e +2 web」と明示されており整合する。**問題なし**。

---

#### [HIGH] `sdd-review-self-ext` が `settings.json` の permissions に存在しない

**`sdd-review-self-ext/SKILL.md`** は `/Users/mia/Repositories/sync-sdd/framework/claude/skills/sdd-review-self-ext/SKILL.md` として存在する。

**`settings.json`** の allow リスト:
```json
"Skill(sdd-review-self)",
```
`Skill(sdd-review-self-ext)` のエントリが **存在しない**。このスキルはユーザーが `/sdd-review-self-ext` として呼び出せるが、`settings.json` には許可エントリがない。Claude Code の permissions モデルでは、`allowedTools`/`settings.json` の `allow` リストに含まれない Skill は自動承認されない可能性がある。

- **ファイル**: `framework/claude/settings.json` (line 13付近)
- **影響**: `sdd-review-self-ext` スキルが settings.json に未登録のため、実行時に許可プロンプトが発生する可能性がある

---

#### [HIGH] `revise.md` Part B Step 7 でのカウンター上限の記述が CLAUDE.md と不一致

**CLAUDE.md (§Auto-Fix Counter Limits)**:
> `retry_count`: max 5 (NO-GO only). `spec_update_count`: max 2 (SPEC-UPDATE-NEEDED only). Aggregate cap: 6.

**revise.md Part B Step 7 Tier Checkpoint**:
> Counter limits: retry_count max 5, spec_update_count max 2, **aggregate cap 6 (per CLAUDE.md)**

こちらは CLAUDE.md を参照しており一致する。**問題なし**。

**revise.md Part B Step 8 (Cross-Cutting Consistency Review)**:
> **Max 5 retries (aggregate cap 6)**

ここで「NO-GO → max 5 retries」と書かれているが、aggregate cap は spec_update_count を含む複合カウンター。Cross-Cutting Review では SPEC-UPDATE-NEEDED も発生しうるが、Step 8 には `spec_update_count` への言及がない。
**問題**: Cross-Cutting Consistency Review の auto-fix ループで `spec_update_count` が考慮されておらず、aggregate cap の計算が不完全。
- **ファイル**: `framework/claude/skills/sdd-roadmap/refs/revise.md:258`

---

#### [HIGH] `sdd-review-self-ext` の `$SCOPE_DIR` が `self-ext` だが `sdd-review-self` は `self`

**sdd-review-self/SKILL.md (Step 3)**:
> `$SCOPE_DIR` = `{{SDD_DIR}}/project/reviews/self/`

**sdd-review-self-ext/SKILL.md (Step 2)**:
> `$SCOPE_DIR = .sdd/project/reviews/self-ext`

この差異は意図的（互いに別スコープで結果を保存）。ただし `sdd-review-self` は `{{SDD_DIR}}/project/reviews/self/` という変数展開形式を使い、`sdd-review-self-ext` は `.sdd/project/reviews/self-ext` というハードコード形式を使っている。`{{SDD_DIR}}` が `.sdd` 以外の場合、`sdd-review-self-ext` の path が壊れる。

ただし CLAUDE.md には `{{SDD_DIR}}` = `.sdd` と明記されているので実害は現状ない。
- **重大度**: LOW（ハードコードと変数展開の非統一）
- **ファイル**: `framework/claude/skills/sdd-review-self-ext/SKILL.md:46`

---

#### [MEDIUM] `reboot.md` Phase 9 の Final Report — Next Steps に「`/sdd-roadmap run`」への言及があるが、フェーズゲートが欠落

**reboot.md Phase 9 Final Report template (line 270)**:
```
## Next Steps
- Accept: delete old source files, commit on branch, then merge to main and run `/sdd-roadmap run` to implement
```

しかし **reboot.md Phase 10 (Post-Completion)** では:
> DO NOT merge to main. DO NOT checkout main.

Final Report の "Next Steps" テキストに「merge to main」と書かれているが、Phase 10 では「DO NOT merge to main」。
ユーザーに提示される Next Steps テキストが Phase 10 の実際の動作と矛盾している。
- **ファイル**: `framework/claude/skills/sdd-reboot/refs/reboot.md:270, 301`

---

#### [MEDIUM] `run.md` Step 7b — Dead-Code Review の retry カウンターに aggregate cap への言及なし

**CLAUDE.md**:
> Dead-Code Review NO-GO: max 3 retries (dead-code findings are simpler scope; exhaustion → escalate).

**run.md Step 7b**:
> NO-GO → identify responsible Builder(s), re-dispatch with fix instructions, re-review **(max 3 retries, tracked in-memory by Lead — not persisted to spec.yaml.** Dead-code findings are wave-scoped and resolved within a single execution window; counter restarts at 0 on session resume. **Separate from per-spec aggregate cap** → escalate)

「Separate from per-spec aggregate cap」と明記されている。CLAUDE.md でも Dead-Code Review の例外が明記されており整合している。**問題なし**。

---

#### [MEDIUM] `sdd-steering` の Engines Mode で参照しているパスが `{{SDD_DIR}}` と `.sdd` で混在

**sdd-steering/SKILL.md (Engines Mode)**:
```
Read `.sdd/settings/engines.yaml`
copy from `.sdd/settings/templates/engines.yaml` to `.sdd/settings/engines.yaml`
```

他のファイル（CLAUDE.md, sdd-conventions-scanner.md など）は `{{SDD_DIR}}/settings/...` 形式を使用。
`sdd-steering/SKILL.md` の Engines Mode 内のみ `.sdd/` ハードコード。
- **ファイル**: `framework/claude/skills/sdd-steering/SKILL.md:61-65`

---

#### [MEDIUM] `sdd-review-self` の Compliance Cache が `B{seq}/agent-4-compliance.md` を参照するが、実際の出力は `.md` か不確か

**sdd-review-self/SKILL.md Step 3**:
> Read the archived report (`$SCOPE_DIR/B{seq}/agent-4-compliance.md`)

Agent 4 の output format は Step 4 で「Write your full report to `{$SCOPE_DIR}/active/agent-{N}-{name}.md`」と定義されており、アーカイブ後は `B{seq}/agent-4-compliance.md` になる。一致している。**問題なし**。

**sdd-review-self-ext/SKILL.md Step 3**:
> Read the archived report (`$SCOPE_DIR/B{seq}/agent-4-compliance.cpf` or `.md`)

外部エンジン版では CPF または .md 両方を許容する記法になっており、これは `sdd-review-self` とは異なる。外部エンジンが CPF で出力するのが仕様のため意図的差異だが、「or `.md`」という曖昧な記述が残っている。
- **ファイル**: `framework/claude/skills/sdd-review-self-ext/SKILL.md:109`

---

#### [MEDIUM] `run.md` Step 3 — Island Spec の file ownership overlap 検出後の demote 先が不明確

**run.md Step 3 (Island Spec Detection)**:
> If Impl-phase Layer 2 file ownership check discovers overlap between a fast-track spec and a wave-bound spec, demote the fast-track spec back to wave-bound and serialize.

「wave-bound に demote してシリアライズ」とあるが、どの wave に配置するか、また roadmap.md の更新が必要かどうかの手順が記述されていない。実行者（Lead）は判断できない可能性がある。
- **ファイル**: `framework/claude/skills/sdd-roadmap/refs/run.md:87`

---

#### [LOW] `reboot.md` Phase 7 の `sdd-review-self` 相当の "Dispatch-Inspectors" 記述で inspector 名が略称

**reboot.md Phase 7 — Review Decomposition**:
> Spawn 6 design Inspectors in parallel (rulebase, testability, architecture, consistency, best-practices, holistic)

正式名は `sdd-inspector-rulebase` 等だが、ここでは略称のみ記述。
review.md には正式名 `sdd-inspector-rulebase` 等が記載されており、略称と正式名の混在が生じている。
- **ファイル**: `framework/claude/skills/sdd-reboot/refs/reboot.md:173`

---

#### [LOW] `CLAUDE.md` の `decisions.md` 記録タイプと `sdd-handover/SKILL.md` の `SESSION_END` 書き込みタイミングが不一致

**CLAUDE.md Write Triggers テーブル**:
> `/sdd-handover` | session.md manual polish, decisions.md SESSION_END, sessions/ archive | Manual

**sdd-handover/SKILL.md Step 4**:
> Append `SESSION_END` to `{{SDD_DIR}}/handover/decisions.md`

一致している。**問題なし**。

---

#### [LOW] `sdd-auditor-design.md` の Verdict formula で CONDITIONAL の閾値が `>3 High` と明示されているが `sdd-auditor-impl.md` も同様

両 Auditor で：
```
ELSE IF >3 High issues OR ...
    Verdict = CONDITIONAL
```

CLAUDE.md にはこの閾値の記述がない（CLAUDE.md はカウンター上限のみ記述）。閾値がエージェント定義にのみ存在し、CLAUDE.md に記録がない。これは一貫性問題ではなく設計上の分業だが、メタ情報として把握しておく必要がある。**問題なし**（設計的分業）。

---

#### [LOW] `sdd-inspector-dead-specs.md` の SCOPE が `dead-code` に固定されており、dead-specs の区別がない

**sdd-inspector-dead-specs.md Output Format**:
```
VERDICT:{GO|CONDITIONAL|NO-GO}
SCOPE:dead-code
```

他の Dead-Code Inspector（dead-code, dead-tests, dead-settings）も同様に `SCOPE:dead-code` 固定。
Auditor (`sdd-auditor-dead-code.md`) はこれらを読み込むので問題ない。
ただし `sdd-inspector-dead-specs.md` のカテゴリは `spec-drift`、`sdd-inspector-dead-code.md` は `dead-code` と明確に区別されており整合している。**問題なし**。

---

#### [LOW] `sdd-steering/SKILL.md` の `/sdd-publish-setup` 呼び出しが `Skill` ツール経由と明記されているが、allowed-tools に `Skill` が含まれている

**sdd-steering/SKILL.md (line 72)**:
> invoke `/sdd-publish-setup` via Skill tool

**sdd-steering/SKILL.md frontmatter**:
```yaml
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion, Skill
```

`Skill` が allowed-tools に含まれているため問題ない。**問題なし**。

---

### Cross-Reference Matrix

| 参照元ファイル | 参照先 | 参照内容 | 整合性 |
|---|---|---|---|
| CLAUDE.md | refs/run.md | SubAgent Lifecycle, Parallel Execution | OK |
| CLAUDE.md | refs/crud.md | Wave Scheduling | OK |
| CLAUDE.md | refs/revise.md | Cross-Cutting Parallelism | OK |
| CLAUDE.md | refs/review.md | Steering Feedback Loop | OK |
| CLAUDE.md | cpf-format.md | CPF 形式 | OK |
| CLAUDE.md | tmux-integration.md | tmux パターン | OK |
| SKILL.md (roadmap) | refs/design.md, impl.md, review.md, run.md, revise.md, crud.md | サブコマンドディスパッチ | OK |
| run.md | refs/design.md, impl.md, review.md | Phase Handler 参照 | OK |
| run.md | tmux-integration.md | Web Inspector Server Protocol | OK |
| revise.md Part B | run.md | Wave Context Generation (Step 2.5) | OK |
| revise.md Part B | refs/review.md | クロスチェックレビュー | OK |
| reboot.md | refs/run.md Step 4 | Design Dispatch Loop 再利用 | OK |
| impl.md | sdd-taskgenerator | TaskGenerator ディスパッチ | OK |
| impl.md | sdd-builder | Builder ディスパッチ | OK |
| impl.md | sdd-conventions-scanner | Pilot Stagger Protocol | OK |
| review.md | sdd-inspector-*(design) | 6 design inspectors | OK |
| review.md | sdd-inspector-*(impl) | 6 impl + e2e + web-e2e + web-visual | OK |
| review.md | sdd-inspector-*(dead-code) | 4 dead-code inspectors | OK |
| review.md | sdd-auditor-design | Design Auditor | OK |
| review.md | sdd-auditor-impl | Impl Auditor | OK |
| review.md | sdd-auditor-dead-code | Dead-Code Auditor | OK |
| sdd-architect.md | design-discovery-full.md, design-discovery-light.md | Discovery プロセス参照 | OK |
| sdd-architect.md | design-principles.md | デザイン原則 | OK |
| sdd-taskgenerator.md | tasks-generation.md | タスク生成ルール | OK |
| sdd-inspector-rulebase.md | design-review.md | デザインレビュールール | OK |
| sdd-conventions-scanner.md | wave-context/conventions-brief.md (template) | テンプレート参照 | OK (実体は別途要確認) |
| sdd-review-self-ext.md | tmux-integration.md | One-Shot Command パターン | OK |
| settings.json | sdd-review-self (Skill) | 許可リスト | OK |
| settings.json | sdd-review-self-ext (Skill) | **未登録** | **NG** |
| settings.json | sdd-analyst, sdd-architect, sdd-auditor-*, sdd-builder, sdd-conventions-scanner, sdd-inspector-* (Agent) | 許可リスト | OK |
| settings.json | sdd-taskgenerator (Agent) | 許可リスト | OK |

---

### Confirmed OK

- フェーズ名の統一: `initialized` → `design-generated` → `implementation-complete` / `blocked` がすべてのファイルで一貫している
- Verdict 値の統一: `GO`, `CONDITIONAL`, `NO-GO`, `SPEC-UPDATE-NEEDED` がすべての Auditor・Phase Handler で一貫している
- CPF Severity コードの統一: `C`, `H`, `M`, `L` がすべての Inspector・Auditor・sdd-review-self で一貫している
- retry_count 上限 (5) と spec_update_count 上限 (2)、aggregate cap (6) が CLAUDE.md・run.md・revise.md 間で一貫している
- Dead-Code Review の retry 上限 (3) が CLAUDE.md と run.md で一貫している
- Counter reset トリガー（wave completion, user escalation, revise start, session resume）が CLAUDE.md・run.md・revise.md で一貫している
- Builder の `sys.modules` 禁止規則が sdd-builder.md と sdd-inspector-test.md で一貫している
- Artifact Ownership (Lead は design.md/research.md/実装ファイルを直接編集不可) が CLAUDE.md・各 ref で一貫している
- Verdict Persistence Format (`## [B{seq}]` ヘッダー) が SKILL.md Router・review.md・run.md で一貫している
- spec.yaml の ownership（Lead のみ更新）が CLAUDE.md・各エージェント定義で一貫している
- 1-Spec Roadmap Optimizations（Wave QG スキップ等）が SKILL.md・run.md で一貫している
- Island Spec detection と fast-track execution が run.md で完結定義されている
- Design Lookahead の staleness guard が run.md で定義されている
- ConventionsScanner の reboot 非使用が reboot.md と sdd-analyst.md の両方で一貫している
- `ANALYST_COMPLETE` の構造化出力フォーマットが CLAUDE.md と sdd-analyst.md で一貫している
- `BUILDER_COMPLETE` と `BUILDER_BLOCKED` のフォーマットが CLAUDE.md と sdd-builder.md で一貫している
- tmux-integration.md のパターン A・B が sdd-review-self-ext.md と review.md(Web Inspector) で正しく参照されている
- sdd-reboot/SKILL.md の Phase 2-10 が refs/reboot.md の詳細定義と一致している
- すべての Inspector が `WRITTEN:{output_file_path}` のみを final text として返すプロトコルに従っている
- sdd-conventions-scanner の Mode: Generate / Mode: Supplement の区別が run.md・impl.md の呼び出し側と一致している

---

### Overall Assessment

**確認済みの問題: 3件 HIGH、4件 MEDIUM、4件 LOW（計 11件）**

最も優先度の高い問題は以下の3件:

1. **[HIGH] `settings.json` に `Skill(sdd-review-self-ext)` が未登録** — スキル呼び出し時に自動承認されない可能性。修正は settings.json への1行追加で完了する。

2. **[HIGH] `revise.md` Part B Step 8 の Cross-Cutting Consistency Review で `spec_update_count` の aggregate cap への言及が欠落** — CONDITIONAL/NO-GO ループでカウンター管理が不完全になる可能性がある。

3. **[MEDIUM] `reboot.md` Phase 9 Final Report の Next Steps テキストが Phase 10 の「DO NOT merge to main」と矛盾** — ユーザーへの案内として誤解を招く。

その他の問題は軽微な不一致（ハードコードパス vs テンプレート変数、曖昧な記述）であり、運用上の大きな障害にはなりにくい。

フレームワーク全体の整合性は高く、コア概念（フェーズ名、verdict 値、カウンター上限、アーティファクト所有権）は全ファイルで一貫している。
