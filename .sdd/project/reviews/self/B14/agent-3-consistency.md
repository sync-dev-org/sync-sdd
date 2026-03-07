# Consistency & Dead Ends Report (Agent 3)

**Date**: 2026-02-27
**Scope**: framework/claude/ 全ファイル（CLAUDE.md, skills/sdd-*/SKILL.md, skills/sdd-*/refs/*.md, agents/sdd-*.md, settings.json, sdd/settings/rules/*.md, sdd/settings/templates/**/*.md, install.sh）

---

## Issues Found

---

### [MEDIUM] M1: run.md に `.sdd/` ハードコードパスが混在

**ファイル**: `framework/claude/skills/sdd-roadmap/refs/run.md` 行 38、54

**説明**:
ほぼすべてのパスが `{{SDD_DIR}}` テンプレート変数を使用しているが、Conventions Brief の出力パスと Shared Research の出力パスのみ `.sdd/` をハードコードしている。

```
行38: `.sdd/project/specs/.wave-context/{wave-N}/conventions-brief.md`
行54: `.sdd/project/specs/.wave-context/{wave-N}/shared-research.md`
```

他のすべてのパスは `{{SDD_DIR}}/project/specs/...` 形式を使用している（同ファイル内の行 35、37、234、245 など）。

**影響**: `{{SDD_DIR}}` が `.sdd` 以外に変更された場合にパスが壊れる。一貫性の欠如がメンテナンス時に混乱を招く。

**修正案**: `.sdd/project/specs/.wave-context/` → `{{SDD_DIR}}/project/specs/.wave-context/`

---

### [MEDIUM] M2: sdd-review-self が `general-purpose` subagent_type を使用するが settings.json に権限なし

**ファイル**: `framework/claude/skills/sdd-review-self/SKILL.md` 行 57、`framework/claude/settings.json`

**説明**:
`sdd-review-self` は各レビューエージェントを以下のように起動する:

```
Task(subagent_type="general-purpose", model="sonnet", run_in_background=true)
```

しかし `settings.json` の `allow` リストには `Task(general-purpose)` エントリが存在しない。リストされているのはすべて `Task(sdd-*)` 形式の名前付きサブエージェントのみ。

**影響**: `general-purpose` サブエージェント起動が settings.json の permissions によってブロックされる可能性がある。ただし `defaultMode: "acceptEdits"` の場合の実際の動作は実装依存のため、確認が必要。

**修正案**: `settings.json` に `"Task(general-purpose)"` を追加するか、`sdd-review-self` が具体的な named agent を使用するよう変更する。

---

### [MEDIUM] M3: revise.md Part A にコミット指示なし（Part B と非対称）

**ファイル**: `framework/claude/skills/sdd-roadmap/refs/revise.md`

**説明**:
Cross-Cutting Mode (Part B) の Step 9 は明示的にコミットを指示している:
```
3. Commit: `cross-cutting: {summary}`
```

しかし Single-Spec Mode (Part A) の Step 7 (Post-Revision) にはコミット指示が存在しない:
```
1. Auto-draft {{SDD_DIR}}/handover/session.md
2. If roadmap run was in progress: resume via refs/run.md dispatch loop
3. Suggest: /sdd-status to verify state
```

CLAUDE.md の「Commit Timing」セクションには「Pipeline completion (1-spec roadmap): After individual pipeline completes, Lead commits」とあるが、revise が "pipeline completion" に該当するかどうかが revise.md 内で明示されていない。

**影響**: Lead がシングルスペックリビジョン後にコミットするかどうかが不明確。動作が不統一になる可能性。

**修正案**: revise.md Part A Step 7 に明示的なコミット指示を追加する（`{feature}: {summary}` フォーマット）、または CLAUDE.md の Commit Timing セクションに revise ユースケースを明示的に記述する。

---

### [LOW] L1: Analyst の出力パスの記述が CLAUDE.md と実際の Analyst エージェント間でわずかに表現が異なる

**ファイル**: `framework/claude/CLAUDE.md` 行 41、`framework/claude/agents/sdd-analyst.md` 行 25

**説明**:
CLAUDE.md は Analyst の出力パスを以下のように記述:
```
{{SDD_DIR}}/project/reboot/analysis-report.md
```

Analyst エージェントの Input セクションは「Output path: where to write the analysis report」と書いており、固定パスを述べていない。実際のパスは `reboot.md` Phase 4 が決定する（`{{SDD_DIR}}/project/reboot/analysis-report.md`）。

この三者間の記述は実質一致しているが、CLAUDE.md が具体的なパスを固定的に記述している点は、reboot 以外のコンテキストで Analyst を呼び出す場合に混乱を招く可能性がある（Analyst は汎用的にパスを受け取る設計）。

**影響**: 軽微。現状の唯一の呼び出し元（reboot）では正しく機能している。

---

### [LOW] L2: CLAUDE.md の Parallel Execution Model に `refs/impl.md` への参照があるが、同セクションでは「Pilot Stagger Protocol」を指す

**ファイル**: `framework/claude/CLAUDE.md` 行 102

**説明**:
「Wave Context」の説明に以下が含まれる:
```
See sdd-roadmap refs/run.md Step 2.5 and refs/impl.md Pilot Stagger Protocol.
```

`refs/impl.md` は存在し「Pilot Stagger Protocol」セクションも存在するため参照は有効。ただし `refs/run.md` Step 2.5 は「Wave Context Generation」を指しており、impl.md の Pilot Stagger は Wave Context の「補完」であることを考えると、参照順序（run.md Step 2.5 → impl.md）は適切である。

**問題なし** — このアイテムは確認後に正確であることを確認。

---

### [LOW] L3: `design.md` テンプレートと `design-review.md` ルールの間でセクション順序の記述に微妙な差異

**ファイル**: `framework/claude/sdd/settings/templates/specs/design.md`、`framework/claude/sdd/settings/rules/design-review.md`

**説明**:
`design-principles.md` の Global Ordering セクションは以下の順序を定義:
```
Specifications → Overview → Architecture → System Flows → Specifications Traceability → Components and Interfaces → Data Models → Error Handling → Testing Strategy
```

`design.md` テンプレートの実際の構造は上記順序と一致している。

`design-review.md` の Template Conformance Check はセクションを列挙しているが、「Specifications Traceability」を Impl inspector の設計上では明示的に順序チェックしていない。

**影響**: 軽微。実際の運用に影響しない可能性が高い。

---

### [LOW] L4: reboot.md Phase 7 の Verdict Handling に `aggregate cap` への言及がない

**ファイル**: `framework/claude/skills/sdd-reboot/refs/reboot.md` 行 182

**説明**:
reboot.md の Phase 7 Verdict Handling は以下のように記述:
```
NO-GO → increment retry_count. ... Max 5 retries (aggregate cap 6).
```

`aggregate cap 6` = `retry_count` (max 5) + `spec_update_count` (max 2) の合計というのが CLAUDE.md の定義だが、reboot では `SPEC-UPDATE-NEEDED` は Design Review では発生しないとされている（run.md 行 180: "not expected for design review. If received, escalate immediately."）。

したがって reboot では `spec_update_count` は常に 0 となるため、aggregate cap 6 の実質的な制限は retry_count の max 5 のみになる。この記述自体は矛盾ではないが、やや misleading。

**影響**: 軽微。

---

## Confirmed OK（問題なし確認項目）

- **フェーズ名の統一**: `initialized` / `design-generated` / `implementation-complete` / `blocked` — CLAUDE.md、すべての refs/*.md、spec.yaml テンプレート、agents/*.md で一貫して使用されている。
- **Verdict 値の統一**: `GO` / `CONDITIONAL` / `NO-GO` / `SPEC-UPDATE-NEEDED` — すべての Auditor エージェント、review.md、run.md、CLAUDE.md で一貫している。
- **CPF 重大度コード**: `C/H/M/L` — cpf-format.md で定義され、すべての Inspector/Auditor エージェントで一貫して使用されている。
- **リトライ上限の一致**: CLAUDE.md (retry_count: max 5、spec_update_count: max 2、aggregate cap: 6、dead-code: max 3) — run.md の各箇所で完全一致。
- **Inspector 数の一致**: CLAUDE.md「6 design, 6 impl +2 web, 4 dead-code」— review.md のリスト（Design: 6、Impl: 6 + E2E/Visual: 2、Dead-code: 4）、agents/ ファイル 18 個と一致。
- **settings.json と agents/ の一致**: settings.json の `Task(sdd-*)` エントリ 18 個がすべて agents/sdd-*.md ファイルに対応している（general-purpose を除く — M2 で指摘済み）。
- **SubAgent 名の一致**: CLAUDE.md の Role Architecture テーブル、SKILL.md の dispatch 記述、agents/*.md の name フィールド — 全一致。
- **テンプレートファイルの存在確認**: `init.yaml`、`design.md`、`research.md`、`session.md`、`buffer.md`、`analysis-report.md`、`conventions-brief.md`、steering テンプレート群 — すべて `framework/claude/sdd/settings/templates/` に実在する。
- **ルールファイルの存在確認**: `cpf-format.md`、`design-review.md`、`design-principles.md`、`design-discovery-full.md`、`design-discovery-light.md`、`tasks-generation.md`、`steering-principles.md` — すべて `framework/claude/sdd/settings/rules/` に実在する。
- **SKILL.md refs 参照の一致**: sdd-roadmap/SKILL.md が参照する `refs/design.md`、`refs/impl.md`、`refs/review.md`、`refs/run.md`、`refs/revise.md`、`refs/crud.md` — すべて実在する。
- **sdd-reboot refs 参照の一致**: sdd-reboot/SKILL.md が参照する `refs/reboot.md` — 実在する。
- **init.yaml パスの一致**: SKILL.md 行 76 と reboot.md 行 102 が参照する `{{SDD_DIR}}/settings/templates/specs/init.yaml` — 実在する。
- **Conventions Brief テンプレートパスの一致**: run.md、reboot.md が参照する `{{SDD_DIR}}/settings/templates/wave-context/conventions-brief.md` — 実在する。
- **Analysis Report テンプレートパスの一致**: reboot.md が参照する `{{SDD_DIR}}/settings/templates/reboot/analysis-report.md` — 実在する。
- **Builder レポートパスの一致**: CLAUDE.md (`builder-report-{group}.md`) vs sdd-builder.md (`{{SDD_DIR}}/project/specs/{feature}/builder-report-{group}.md`) — 一致（CLAUDE.md は省略形）。
- **Verdict ファイル名の一致**: CLAUDE.md (`verdict.cpf`)、review.md、auditor agents（`verdict output path` として `verdict.cpf`）— 一貫している。
- **verdicts.md パスの一致**: review.md の Verdict Destination テーブルと各 refs ファイルの参照 — 一致している。
- **フェーズ遷移の到達可能性**: `initialized` → `design-generated` (design)、`design-generated` → `implementation-complete` (impl)、`implementation-complete` → `blocked` (blocking protocol) — すべての遷移が各 refs ファイルでカバーされている。
- **デッドエンド検証**: `blocked` フェーズからの回復パス（blocking protocol fix/skip/abort）が run.md Step 6 に定義されている。
- **循環参照なし**: refs ファイル間の参照関係（run.md → design.md、run.md → impl.md、run.md → review.md、reboot.md → run.md を参照）— 循環なし。
- **Design Review での SPEC-UPDATE-NEEDED の処理**: run.md 行 180「not expected for design review. If received, escalate immediately」— 正しく定義されている。
- **Counter Reset トリガーの一致**: CLAUDE.md（wave completion、user escalation、/sdd-roadmap revise start）— revise.md Step 4 で reset が実行されることで一致。
- **Wave Context の格納先（revise.md Part B）**: revise.md Step 7 が run.md Step 2.5 の Conventions Brief ディスパッチを呼び出す — 正しく一貫している。
- **Cross-cutting verdict パス**: revise.md が `specs/.cross-cutting/{id}/verdicts.md` を使用し、review.md の Verdict Destination テーブルとも一致。
- **Steering Feedback Loop処理タイミング**: CLAUDE.md（verdict 処理後、次フェーズ進行前）とreview.md（同様の記述）— 一致。
- **CLAUDE.md Commands 数**: テーブルに 6 コマンド（sdd-steering、sdd-roadmap、sdd-reboot、sdd-status、sdd-handover、sdd-release）— skills/ に 7 ディレクトリがあるが sdd-review-self はフレームワーク内部用で公開コマンドには含まれない（CLAUDE.md のコマンド表から除外）。この扱いは意図的と判断。
- **install.sh のファイルコピー対象**: `framework/claude/skills/sdd-*/`、`framework/claude/agents/sdd-*.md`、`framework/claude/CLAUDE.md`、`framework/claude/settings.json`、`framework/claude/sdd/settings/rules/`、`framework/claude/sdd/settings/templates/`、`framework/claude/sdd/settings/profiles/` — すべてのフレームワークファイルが正しくコピーされる。

---

## 相互参照マトリクス

| 参照元 | 参照先 | 参照内容 | 状態 |
|--------|--------|----------|------|
| CLAUDE.md | sdd-roadmap refs/run.md | Step 2.5, Step 3-4 dispatch loop | OK |
| CLAUDE.md | sdd-roadmap refs/review.md | Steering Feedback Loop | OK |
| CLAUDE.md | sdd-roadmap refs/crud.md | Wave Scheduling | OK |
| CLAUDE.md | sdd-roadmap refs/revise.md | Cross-Cutting Parallelism Part B | OK |
| CLAUDE.md | sdd-roadmap refs/impl.md | Pilot Stagger Protocol | OK |
| sdd-roadmap/SKILL.md | refs/design.md | Design subcommand | OK |
| sdd-roadmap/SKILL.md | refs/impl.md | Impl subcommand | OK |
| sdd-roadmap/SKILL.md | refs/review.md | Review subcommand | OK |
| sdd-roadmap/SKILL.md | refs/run.md | Run mode | OK |
| sdd-roadmap/SKILL.md | refs/revise.md | Revise mode | OK |
| sdd-roadmap/SKILL.md | refs/crud.md | Create/Update/Delete | OK |
| refs/run.md | refs/design.md | Design completion handler | OK |
| refs/run.md | refs/impl.md | Implementation completion | OK |
| refs/run.md | refs/review.md | Review Decomposition | OK |
| refs/revise.md Part B Step 7 | refs/run.md Step 2.5 | Wave Context Generation | OK |
| refs/revise.md Part B Step 8 | refs/run.md Step 7a | Cross-Check review | OK |
| sdd-reboot/SKILL.md | refs/reboot.md | 10-phase execution | OK |
| refs/reboot.md Phase 7 | refs/run.md Step 4 | Dispatch loop reuse | OK |
| refs/reboot.md Phase 7 | refs/run.md Step 6 | Blocking Protocol | OK |
| sdd-architect.md | {{SDD_DIR}}/settings/rules/design-principles.md | Design principles | OK |
| sdd-architect.md | {{SDD_DIR}}/settings/rules/design-discovery-full.md | Full discovery | OK |
| sdd-architect.md | {{SDD_DIR}}/settings/rules/design-discovery-light.md | Light discovery | OK |
| sdd-architect.md | {{SDD_DIR}}/settings/templates/specs/design.md | Design template | OK |
| sdd-architect.md | {{SDD_DIR}}/settings/templates/specs/research.md | Research template | OK |
| sdd-inspector-rulebase.md | {{SDD_DIR}}/settings/rules/design-review.md | Review rules | OK |
| sdd-taskgenerator.md | {{SDD_DIR}}/settings/rules/tasks-generation.md | Task rules | OK |
| sdd-conventions-scanner.md | {{SDD_DIR}}/settings/templates/wave-context/conventions-brief.md | Brief template | OK |
| refs/run.md line 38 | .sdd/project/specs/.wave-context/ | conventions-brief output | WARN: ハードコード (M1) |
| refs/run.md line 54 | .sdd/project/specs/.wave-context/ | shared-research output | WARN: ハードコード (M1) |
| sdd-review-self/SKILL.md | Task(general-purpose) | Self-review agents | WARN: settings.json未定義 (M2) |
| revise.md Part A Step 7 | (コミット指示) | Post-revision commit | GAP: 明示なし (M3) |
| revise.md Part B Step 9 | cross-cutting: commit | Cross-cutting commit | OK |

---

## Overall Assessment

フレームワーク全体の整合性は高い。フェーズ名・バーディクト値・CPF 重大度コード・エージェント名・リトライ上限・テンプレートパスはすべて一貫している。

主要な問題は中程度（MEDIUM）3件、軽微（LOW）2件で、クリティカルな矛盾や到達不能パスは存在しない。

最も影響が大きいのは M2（`general-purpose` subagent_type の permissions 未登録）で、`sdd-review-self` の実行時に影響する可能性がある。次いで M1（`.sdd/` ハードコード）は将来的な SDD_DIR 変更時のリスクとなる。M3（revise.md Part A のコミット指示欠如）は動作上の非対称性をもたらすが、CLAUDE.md の一般ルールで補完される可能性がある。

---

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|----------|----|---------|-----------:|
| 1 | M2 | `general-purpose` を settings.json permissions に追加 | `framework/claude/settings.json` |
| 2 | M1 | `.sdd/` ハードコードを `{{SDD_DIR}}` に統一 | `framework/claude/skills/sdd-roadmap/refs/run.md` 行38、54 |
| 3 | M3 | revise.md Part A Step 7 にコミット指示を追加 | `framework/claude/skills/sdd-roadmap/refs/revise.md` |
| 4 | L4 | reboot.md の aggregate cap 説明を clarify | `framework/claude/skills/sdd-reboot/refs/reboot.md` |
