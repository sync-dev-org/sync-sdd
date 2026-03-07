## Consistency & Dead Ends Report

**Agent**: 3 — Consistency & Dead Ends
**Scope**: framework/claude/ 全ファイル + install.sh
**Date**: 2026-03-03

---

### Issues Found

---

#### [MEDIUM] SCOPE フィールドの形式が Inspector と Auditor で不一致

**該当ファイル**:
- `framework/claude/agents/sdd-inspector-architecture.md` (他全 design/impl Inspector 共通)
- `framework/claude/agents/sdd-auditor-design.md`
- `framework/claude/agents/sdd-auditor-impl.md`

**詳細**:
Wave スコープ review における CPF の `SCOPE:` フィールドの値が Inspector と Auditor で異なる。

- Inspector の出力例: `SCOPE:wave-1..{N}` （例: `wave-1..3`）
- Auditor の出力形式: `SCOPE:{feature} | cross-check | wave-scoped-cross-check`

Auditor が Inspector の CPF を読み込んで統合する設計において、SCOPE フィールドの値が揃っていないと CPF パーサーや将来的なツール実装で混乱が生じる。Auditor が受け取る `prompt` コンテキストとして「wave-scoped-cross-check with wave number」を受け取るのは一貫しているが、CPF の SCOPE 出力値が `wave-1..3` (Inspector) と `wave-scoped-cross-check` (Auditor) で統一されていない。

---

#### [MEDIUM] `sdd-review-self-codex` が settings.json に未登録

**該当ファイル**:
- `framework/claude/skills/sdd-review-self-codex/SKILL.md` (存在する)
- `framework/claude/settings.json`

**詳細**:
settings.json の `permissions.allow` に `Skill(sdd-review-self)` は登録されているが、`Skill(sdd-review-self-codex)` が存在しない。

```json
"Skill(sdd-review-self)",
// Skill(sdd-review-self-codex) が存在しない
```

スキルファイルは存在し、install.sh も `sdd-review-self-codex` を `framework/claude/skills/` から `.claude/skills/` にコピーするため、ファイルはインストールされるが Claude Code からの呼び出しには権限エラーが発生する可能性がある。

---

#### [MEDIUM] コマンド数の不整合 (CLAUDE.md 7 vs 実際の非内部スキル数 8)

**該当ファイル**:
- `framework/claude/CLAUDE.md` (Commands テーブル)
- `framework/claude/skills/sdd-release/SKILL.md` (コマンド数チェック指示)

**詳細**:
CLAUDE.md の Commands テーブルに 7 コマンドが記載されている:
`sdd-steering`, `sdd-roadmap`, `sdd-reboot`, `sdd-status`, `sdd-handover`, `sdd-release`, `sdd-publish-setup`

`sdd-release` SKILL.md のリリース手順内のコマンド数確認指示:
> "exclude `sdd-review-self` — internal tool, not a user command"

実際のスキルファイル一覧 (9個):
- sdd-roadmap, sdd-steering, sdd-status, sdd-handover, sdd-reboot, sdd-release, sdd-publish-setup (=7)
- sdd-review-self (内部ツール、除外)
- sdd-review-self-codex (位置づけ未明記)

`sdd-review-self` のみ除外すると 8 となり、CLAUDE.md の "7" と合わない。`sdd-review-self-codex` も内部ツールとして除外すべきか明示されておらず、カウントルールに ambiguity がある。

---

#### [LOW] Dead-Code Auditor に `STEERING:` セクションが存在しない

**該当ファイル**:
- `framework/claude/agents/sdd-auditor-dead-code.md`
- `framework/claude/CLAUDE.md` (Steering Feedback Loop セクション)

**詳細**:
CLAUDE.md §Steering Feedback Loop:
> "Auditor verdicts may include `STEERING:` entries"

しかし sdd-auditor-dead-code.md の出力フォーマットに `STEERING:` セクションが存在しない（設計/実装 Auditor には存在する）。

dead-code の指摘が Steering 更新を引き起こすケースは稀だが、CLAUDE.md の一般的な表明と実際の dead-code Auditor の出力仕様が不一致。意図的な省略であれば、CLAUDE.md の記述を「Design/Impl Auditor verdicts may include...」と限定するか、dead-code Auditor の除外理由を明記すべき。

---

#### [LOW] `{{SDD_DIR}}/settings/templates/specs/init.yaml` の参照 (確認不可)

**該当ファイル**:
- `framework/claude/skills/sdd-roadmap/SKILL.md` (Single-Spec Roadmap Ensure)
- `framework/claude/skills/sdd-reboot/refs/reboot.md` (Phase 6c)

**詳細**:
両ファイルが `{{SDD_DIR}}/settings/templates/specs/init.yaml` を参照しているが、このファイルはレビュー対象リストに含まれておらず存在確認ができなかった。テンプレートが実際に存在しない場合、Single-Spec Roadmap 作成時と reboot Phase 6c でランタイムエラーになる。

（注: テンプレートファイルが存在する場合はこの Issue は FP として消滅する）

---

### Confirmed OK

以下の項目についてクロスリファレンスを行い、一貫性を確認した:

**フェーズ名の統一**
- `initialized` → `design-generated` → `implementation-complete` (+ `blocked`)
- CLAUDE.md, design.md, impl.md, revise.md, run.md, SKILL.md すべてで一致 ✓

**Inspector 種類とカウント**
- Design: 6 (rulebase, testability, architecture, consistency, best-practices, holistic) ✓
- Impl: 6 標準 + e2e (条件付き) + web-e2e + web-visual (Web プロジェクト条件付き) = 最大 9 ✓
- Dead-code: 4 (dead-settings, dead-code, dead-specs, dead-tests) ✓
- CLAUDE.md 記述「6 design, 6 impl +1 e2e +2 web, 4 dead-code」と review.md の Inspector リスト、agent ファイル数が一致 ✓

**Audit 判定値の統一**
- Design Auditor: GO / CONDITIONAL / NO-GO ✓
- Impl Auditor: GO / CONDITIONAL / NO-GO / SPEC-UPDATE-NEEDED ✓
- Dead-Code Auditor: GO / CONDITIONAL / NO-GO ✓
- CLAUDE.md, 各 Auditor 定義、review.md で一致 ✓

**Auto-Fix カウンター上限**
- retry_count max 5, spec_update_count max 2, aggregate cap 6
- Dead-code NO-GO のみ max 3
- CLAUDE.md, run.md §Phase Handlers, revise.md Part B Step 7 すべてで一致 ✓

**CPF severity コード**
- C / H / M / L の 4 値が全 Inspector / Auditor / sdd-review-self 系で統一 ✓

**Verdict 永続化フォーマット**
- B{seq} 採番、verdicts.md append-only、`{scope-dir}/B{seq}/` アーカイブ
- SKILL.md Router, review.md, run.md Step 8, sdd-review-self/SKILL.md すべてで一致 ✓

**レビュースコープディレクトリとパス**
| レビュー種別 | パス |
|---|---|
| Per-feature | `{{SDD_DIR}}/project/specs/{feature}/reviews/` |
| Dead-code (standalone) | `{{SDD_DIR}}/project/reviews/dead-code/` |
| Dead-code (Wave QG) | `{{SDD_DIR}}/project/reviews/wave/` (header: `[W{wave}-DC-B{seq}]`) |
| Cross-check | `{{SDD_DIR}}/project/reviews/cross-check/` |
| Wave-scoped | `{{SDD_DIR}}/project/reviews/wave/` |
| Cross-cutting | `{{SDD_DIR}}/project/specs/.cross-cutting/{id}/` |
| Self-review | `{{SDD_DIR}}/project/reviews/self/` |

review.md, run.md Step 7b, revise.md Part B Step 8 すべてで一致 ✓

**Consensus Mode の B{seq} 決定**
- SKILL.md Router が B{seq} を一度決めて全パイプラインに渡す
- review.md Step 2 が「Router-provided value instead of computing its own」と明記
- 一致 ✓

**Analyst 完了レポートのフォーマット**
- `ANALYST_COMPLETE` + `New specs:` + `Waves:` + `Steering:` + `Requirements identified:` + `Files to delete:` + `WRITTEN:{path}`
- CLAUDE.md と sdd-analyst.md 完了レポート仕様が一致 ✓

**Builder 完了レポートのフォーマット**
- BUILDER_COMPLETE / BUILDER_BLOCKED
- CLAUDE.md, sdd-builder.md, impl.md で一致 ✓

**SubAgent subagent_type 値とファイル名の対応**
- skill/ref ファイルで使用される全 subagent_type 値が settings.json および `.claude/agents/` のエントリと一致 ✓
- `general-purpose` は Claude Code 組み込み型（ファイル不要）— 注記あり ✓

**tmux 統合**
- CLAUDE.md §tmux Integration は `{{SDD_DIR}}/settings/rules/tmux-integration.md` に委譲 ✓
- tmux-integration.md: Pattern A (Server Lifecycle) / Pattern B (One-Shot Command) / Orphan Cleanup の 3 パターン ✓
- セッション再開 Step 5a が tmux-integration.md の Orphan Cleanup に委譲 ✓
- pane ID ベース (`%N` 形式) のターゲット指定（インデックス不使用）が全パターンで一致 ✓

**Wave QG Dead-Code レビュー**
- run.md Step 7b: `reviews/wave/verdicts.md` (header: `[W{wave}-DC-B{seq}]`) ✓
- review.md Verdict Destination 注記と一致 ✓

**Cross-cutting Review の verdict パス**
- revise.md Part B Step 8: `specs/.cross-cutting/{id}/verdicts.md` ✓
- review.md Verdict Destination と一致 ✓

**Steering Feedback Loop の処理順序**
- CLAUDE.md, review.md ともに「verdict 処理後・次フェーズ前」に STEERING エントリを処理 ✓
- CODIFY → Lead が直接適用 / PROPOSE → ユーザー承認要求 — 一致 ✓

**Builder sys.modules 違反スキャン**
- impl.md の違反スキャン手順と sdd-builder.md の制約が一致 ✓

**ConventionsScanner の出力**
- WRITTEN:{path} のみ返却（CLAUDE.md 規約と一致）✓
- Generate / Supplement の 2 モード — sdd-conventions-scanner.md と run.md Step 2.5 / impl.md Pilot Stagger で一致 ✓

**decisions.md の決定種別**
- USER_DECISION, STEERING_UPDATE, DIRECTION_CHANGE, ESCALATION_RESOLVED, REVISION_INITIATED, STEERING_EXCEPTION, SESSION_START/END
- CLAUDE.md の列挙と各 SKILL.md の記録タイミング指示が一致 ✓

**install.sh のコピー対象**
- `framework/claude/skills/sdd-*/SKILL.md` → `.claude/skills/sdd-*/SKILL.md`
- `framework/claude/agents/sdd-*.md` → `.claude/agents/sdd-*.md`
- `sdd-review-self-codex` を含む全スキルがコピー対象 ✓
- CLAUDE.md マーカー (`<!-- sdd:start -->` / `<!-- sdd:end -->`) ベースの更新ロジック ✓

---

### クロスリファレンスマトリックス

| チェック項目 | CLAUDE.md | SKILL.md | review.md | run.md | revise.md | agents/* | settings.json | 判定 |
|---|---|---|---|---|---|---|---|---|
| フェーズ名 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | — | OK |
| Inspector カウント | ✓ | — | ✓ | — | — | ✓ (数一致) | ✓ | OK |
| Audit 判定値 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | — | OK |
| Auto-Fix カウンター | ✓ | — | — | ✓ | ✓ | — | — | OK |
| CPF severity | ✓ | — | — | — | — | ✓ | — | OK |
| B{seq} 採番 | — | ✓ | ✓ | ✓ | — | — | — | OK |
| SCOPE フィールド値 | — | — | — | — | — | ✓(差異あり) | — | **MEDIUM** |
| subagent_type 対応 | — | ✓ | ✓ | ✓ | ✓ | — | ✓ | OK |
| settings.json スキル登録 | — | ✓ | — | — | — | — | ✓(欠落) | **MEDIUM** |
| コマンド数 (7) | ✓(7) | — | — | — | ✓(除外ルール) | — | — | **MEDIUM** |
| Steering セクション | ✓(全般) | — | ✓ | — | — | ✓(dead-code 欠) | — | **LOW** |
| init.yaml テンプレート | — | ✓(参照) | — | — | ✓(参照) | — | — | **LOW** |
| tmux pane ID 方式 | ✓ | — | ✓ | — | — | — | — | OK |
| Wave QG dead-code パス | — | — | ✓ | ✓ | — | — | — | OK |
| Cross-cutting verdict パス | — | — | ✓ | — | ✓ | — | — | OK |

---

### Overall Assessment

**全体評価**: 軽微な不整合が 3 件 (MEDIUM)、低優先度の問題が 2 件 (LOW)。CRITICAL / HIGH は検出されなかった。

**主要リスク**:

1. **SCOPE フィールド不一致** (MEDIUM): Inspector の `wave-1..{N}` と Auditor の `wave-scoped-cross-check` の乖離は、現状の人間可読ファイルベース通信では機能的問題を引き起こさないが、将来的に CPF を機械処理する場合に問題になる。統一が推奨される。

2. **sdd-review-self-codex の権限未登録** (MEDIUM): スキルファイルが存在しているにもかかわらず settings.json に Skill() エントリがない。実験的スキルとして意図的に除外するならその旨を SKILL.md 内か README に明記すべき。使用可能にする場合は settings.json への追加が必要。

3. **コマンド数 7 の不整合** (MEDIUM): sdd-release の除外ルールが `sdd-review-self` のみを対象としており `sdd-review-self-codex` の扱いが不明確。CLAUDE.md の「7」に合わせるには両方を除外対象とする明示が必要。

**低リスク**:
- Dead-code Auditor の STEERING 省略は機能的に問題ないが、CLAUDE.md の一般的な記述と齟齬がある。
- `init.yaml` テンプレート参照は、ファイルが存在すれば問題なし（レビュースコープ外につき未確認）。

**推奨修正優先度**:

| 優先度 | ID | 概要 | 対象ファイル |
|---|---|---|---|
| 1 | SCOPE 不一致 | Inspector/Auditor の SCOPE フィールド値を統一 | 全 design/impl Inspector、Auditor-design、Auditor-impl |
| 2 | settings.json 欠落 | sdd-review-self-codex の Skill() 追加、または意図的除外を明記 | settings.json、sdd-review-self-codex/SKILL.md |
| 3 | コマンド数ルール | sdd-release の除外ルールに sdd-review-self-codex を明記 | sdd-release/SKILL.md、CLAUDE.md |
| 4 | STEERING 記述 | CLAUDE.md の Steering Feedback Loop 記述を Design/Impl Auditor 限定に絞る | CLAUDE.md |
| 5 | init.yaml 確認 | テンプレートファイルの存在確認と、なければ作成 | settings/templates/specs/init.yaml |
