## Consistency & Dead Ends Report

**Date**: 2026-02-24
**Scope**: 全ファイル (framework/claude/ + install.sh)
**Focus**: v1.2.0 パス移行 (.claude/sdd/ -> .sdd/) + 既存の整合性

---

### Issues Found

#### CRITICAL

(なし)

#### HIGH

- [HIGH] **install.sh: v1.2.0 マイグレーション後の .gitignore 管理不整合**
  - `install.sh` は新規インストール時に `.sdd/` を `.gitignore` に追加するロジックがある (L525-530)
  - しかし v1.2.0 マイグレーションブロック (L387-406) にはこのロジックがない
  - **影響**: v1.1.x -> v1.2.0 へアップデートした既存ユーザーは `.claude/sdd/` が `.gitignore` されていたが、`.sdd/` は `.gitignore` に追加されない可能性がある (.claude/ ディレクトリ全体がignoreされている場合のみ間接的にカバーされる)
  - **ファイル**: `install.sh` L387-406 (マイグレーションブロック) vs L524-530 (gitignore管理)
  - **修正案**: v1.2.0 マイグレーションブロック内にも `.sdd/` の gitignore チェックを追加する。ただし、新規インストールフローの L524-530 はマイグレーションの後に実行されるため、`--update` や `--force` でも通過する箇所であればこれでカバーされる可能性がある。確認すると、L524-530 は無条件に実行されるため、実際にはマイグレーション後にもgitignoreは追加される。**結論: 実動作上は問題ない** が、マイグレーションブロック内で明示的にログ出力するとユーザー体験が向上する

- [HIGH] **CLAUDE.md と review.md: review scope directory パスの不一致**
  - `refs/review.md` L69-71 で project-level review ディレクトリを定義:
    - Dead-code: `{{SDD_DIR}}/project/reviews/dead-code/`
    - Cross-check: `{{SDD_DIR}}/project/reviews/cross-check/`
    - Wave: `{{SDD_DIR}}/project/reviews/wave/`
  - `refs/run.md` L168 で wave verdict パスを参照: `{{SDD_DIR}}/project/reviews/wave/verdicts.md`
  - `refs/review.md` L39 で wave-scoped の `PREVIOUSLY_RESOLVED` を参照: `{{SDD_DIR}}/project/reviews/wave/verdicts.md`
  - しかし `refs/crud.md` L80 の Delete Mode では `{{SDD_DIR}}/project/reviews/` をまとめて削除する指示がある
  - **問題**: `sdd-status/SKILL.md` L28 では `spec.yaml` スキャンのみ行い、project-level reviews ディレクトリの存在は確認しない。session resume (CLAUDE.md L272) は `specs/*/reviews/verdicts.md` のみ読む。project-level reviews のステートは session resume で復元されない。
  - **影響**: session resume 後に wave-level の previously-resolved tracking が失われる可能性がある。ただし `spec.yaml` からパイプライン状態は再構築できるため、致命的ではない。
  - **修正案**: CLAUDE.md Session Resume ステップ 2a に `{{SDD_DIR}}/project/reviews/wave/verdicts.md` の読み取りを追加する

- [HIGH] **sdd-review-self SKILL.md: `$SCOPE_DIR` パス定義のハードコード問題**
  - `sdd-review-self/SKILL.md` L63: `Set $SCOPE_DIR = {{SDD_DIR}}/project/reviews/self/`
  - しかし `refs/review.md` L129 で self-review のverdict path を定義: `{{SDD_DIR}}/project/reviews/self/verdicts.md`
  - この2つは整合している。ただし sdd-review-self は `Task(subagent_type="general-purpose")` を使用しており (L65)、settings.json には `Task(general-purpose)` の許可が**存在しない**
  - **影響**: sdd-review-self は framework 開発リポジトリ内でのみ使用されるため、そのリポの settings.json (`.claude/settings.json`) には別の設定がある可能性がある。framework 配布先の settings.json (L1-49) にはこのエントリがない
  - **結論**: sdd-review-self がフレームワーク内部ツールとして意図されている (settings.json に Skill 許可はある) が、SubAgent dispatch に `general-purpose` を使う場合、ユーザーの settings.json には自動的に許可されない。framework 自体の開発では `.claude/settings.local.json` で対応できるが、ドキュメントに明記すべき

#### MEDIUM

- [MEDIUM] **CLAUDE.md Inspector 数とレビュータイプの記述精度**
  - CLAUDE.md L26: `6 design, 6 impl +2 web (impl only, web projects), 4 dead-code`
  - review.md L25-26: design review で 6 Inspectors + Design Auditor = 正確
  - review.md L33-35: impl review で 6 standard + 2 web (条件付き) + Impl Auditor = 正確
  - review.md L44: dead-code で 4 Inspectors + Dead-code Auditor = 正確
  - **確認結果**: 数値は一貫している。ただし auditor-impl.md L13 で "up to 8 independent review agents" と記載があり、これは 6 standard + 2 web = 8 で正確
  - **軽微な曖昧さ**: CLAUDE.md の "6 impl +2 web" は括弧内に条件があるが、初見では "8 impl inspectors" と誤読される可能性がある

- [MEDIUM] **spec.yaml テンプレート (init.yaml) と refs での version_refs フィールド整合性**
  - `init.yaml` L7-9: `version_refs: design: null, implementation: null`
  - `refs/design.md` L34-35: `version_refs.design` を参照
  - `refs/impl.md` L63: `version_refs.implementation` を参照
  - `sdd-architect.md` L33-34: `version_refs` 全体を参照
  - **確認結果**: 一貫している。`version_refs.tasks` は削除済み (v0.10.0 マイグレーション)

- [MEDIUM] **Verdict 値の一貫性**
  - CLAUDE.md L23: `GO/CONDITIONAL/NO-GO` (design auditor), `GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED` (impl auditor)
  - auditor-design.md L167-174: `GO/CONDITIONAL/NO-GO` = 一致
  - auditor-impl.md L218-231: `GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED` = 一致
  - auditor-dead-code.md L128-135: `GO/CONDITIONAL/NO-GO` = 一致
  - Inspector verdict: 全 inspector が `GO/CONDITIONAL/NO-GO` のみ出力 (SPEC-UPDATE-NEEDED は Auditor のみ) = 一致
  - **Inspector に `VERDICT:ERROR` もある** (review.md L118): impl-rulebase.md L155-162 で定義。他の Inspector にはこのパターンが明示されていないが、review.md L118 で統一的にハンドルされる
  - **確認結果**: 一貫している

- [MEDIUM] **Cross-cutting brief パスの一貫性**
  - revise.md L161: `specs/.cross-cutting/{id}/brief.md`
  - CLAUDE.md L115: `specs/.cross-cutting/{id}/`
  - review.md L128: `specs/.cross-cutting/{id}/verdicts.md`
  - sdd-status/SKILL.md L28: `specs/.cross-cutting/*/`
  - **確認結果**: パスは一貫している

- [MEDIUM] **Retry limit の Dead-Code 例外の記載範囲**
  - CLAUDE.md L173: `Dead-Code Review NO-GO: max 3 retries`
  - run.md L182: `max 3 retries → escalate`
  - **確認結果**: 一貫している。Dead-code の 3 は aggregate cap 6 とは独立 (dead-code review は波内の QG の一部であり、spec-level の retry とは別カウント)

- [MEDIUM] **design.md テンプレートの section 順序とレビュールール (design-review.md) の不一致**
  - design-principles.md L68: `Specifications → Overview → Architecture → System Flows → Specifications Traceability → Components & Interfaces → Data Models → Error Handling → Testing Strategy`
  - design.md テンプレート: `Specifications → Overview → Architecture → System Flows → Specifications Traceability → Components and Interfaces → Data Models → Error Handling → Testing Strategy → Optional Sections → Supporting References`
  - design-review.md L29-35: `Overview → Architecture → Components and Interfaces → Data Models → Error Handling → Testing Strategy` (Specifications は上で別セクション扱い)
  - **問題**: design-review.md のセクションリストに `System Flows` と `Specifications Traceability` が含まれていない。これらはテンプレートと principles では必須セクションだが、review ルールでは確認対象外になっている
  - **影響**: rulebase inspector がこれらのセクション欠如を見逃す可能性

- [MEDIUM] **install.sh の uninstall で `.sdd/` ディレクトリ自体は削除しない問題**
  - install.sh uninstall (L128-171): `.sdd/settings/` 配下と `.sdd/.version` は削除するが、`.sdd/` ディレクトリ自体の rmdir は L162 で `.sdd/settings` のみ
  - `.sdd/project/` と `.sdd/handover/` はユーザーファイルとして意図的に残す (L170: "User files (.sdd/project/) were preserved")
  - **しかし**: `.sdd/settings/` が完全に空になった後、`.sdd/settings` の rmdir はあるが `.sdd/` 自体の rmdir がない。ユーザーファイルがない場合、空の `.sdd/` ディレクトリが残る
  - **修正案**: uninstall の最後に `rmdir .sdd 2>/dev/null || true` を追加 (中身があれば失敗して残る)

#### LOW

- [LOW] **CLAUDE.md Handover paths テーブルの sessions/ 記述**
  - CLAUDE.md L217: `sessions/ | Archive | Dated copies of session.md created by /sdd-handover`
  - handover/SKILL.md L60-61: `{{SDD_DIR}}/handover/sessions/{YYYY-MM-DD}.md`
  - **確認結果**: 一貫している (sessions/ は {{SDD_DIR}}/handover/sessions/ の相対参照)

- [LOW] **knowledge テンプレートファイルの参照一貫性**
  - sdd-knowledge/SKILL.md L43: `{{SDD_DIR}}/settings/templates/knowledge/{type}.md`
  - 実在テンプレート: `pattern.md`, `incident.md`, `reference.md`
  - Knowledge types (L29): `incident`, `pattern`, `reference`
  - **確認結果**: 1対1で対応している

- [LOW] **steering テンプレートの custom file リストの一貫性**
  - sdd-steering/SKILL.md L68-69: `api-standards.md, authentication.md, database.md, deployment.md, error-handling.md, security.md, testing.md, ui.md`
  - 実在テンプレート: `api-standards.md, authentication.md, database.md, deployment.md, error-handling.md, security.md, testing.md, ui.md`
  - **確認結果**: 完全一致

- [LOW] **Phase 名の一貫性**
  - CLAUDE.md L154: `initialized -> design-generated -> implementation-complete (+ blocked)`
  - init.yaml L10: `phase: initialized`
  - design.md (ref) L19: `initialized, design-generated, implementation-complete, blocked`
  - impl.md (ref) L13-14: `design-generated, implementation-complete`
  - run.md readiness rules: `initialized, design-generated, implementation-complete, blocked`
  - **確認結果**: 全ファイルで一貫

- [LOW] **Decision types の一貫性**
  - CLAUDE.md L180-187: `USER_DECISION, STEERING_UPDATE, DIRECTION_CHANGE, ESCALATION_RESOLVED, REVISION_INITIATED, STEERING_EXCEPTION, SESSION_START, SESSION_END`
  - CLAUDE.md L246: 同じリストを decisions.md Format セクションで再掲
  - handover/SKILL.md L63-68: `SESSION_END` のみ使用
  - revise.md: `REVISION_INITIATED, DIRECTION_CHANGE, USER_DECISION` を使用
  - run.md L173: `ESCALATION_RESOLVED` を使用
  - **確認結果**: 一貫している

- [LOW] **Builder completion report フォーマットの SelfCheck 値**
  - sdd-builder.md L118: `SelfCheck: {PASS | WARN({items}) | FAIL-RETRY-{N}({items})}`
  - impl.md L52-56: `PASS`, `WARN({items})`, `FAIL-RETRY-2({items})` を処理
  - **確認結果**: FAIL-RETRY-{N} の N は builder 内で max 2 retries (builder.md L65) なので、Lead が受け取る値は `FAIL-RETRY-2` のみ。一貫

- [LOW] **CPF 形式のセクションヘッダーの一貫性**
  - cpf-format.md: `ISSUES:`, `NOTES:` をセクション例として挙げる
  - 全 Inspector: `VERDICT:`, `SCOPE:`, `ISSUES:`, `NOTES:` を使用
  - Design Auditor: 追加で `VERIFIED:`, `REMOVED:`, `RESOLVED:`, `STEERING:`, `ROADMAP_ADVISORY:`
  - Impl Auditor: 追加で `SPEC_FEEDBACK:`
  - Dead-code Auditor: `VERIFIED:`, `REMOVED:`, `RESOLVED:`, `NOTES:`
  - cpf-format.md は Inspector レベルの基本仕様のみ。Auditor 追加セクションは各 Auditor プロファイルで定義
  - **確認結果**: cpf-format.md を拡張しているが矛盾はない

---

### Confirmed OK

- **{{SDD_DIR}} の解決**: 全34ファイルで `{{SDD_DIR}}` を使用し、CLAUDE.md で `.sdd` と定義。ハードコードされた `.claude/sdd/` パスは framework/ 内に残っていない (uncommitted changes 適用後)
- **install.sh の .claude/sdd/ -> .sdd/ 移行**: v1.2.0 マイグレーションブロック、install先パス、stale file 削除パス、uninstall パスが全て `.sdd/` に更新済み。旧パスのフォールバック (.claude/sdd/.version) も正しく処理
- **steering-principles.md**: `.claude/sdd/` 参照が `.sdd/` に更新済み (2箇所)
- **Agent 名と settings.json の一致**: settings.json に24個の Task 許可 + 7個の Skill 許可。agents/ に24個のエージェントファイル。skills/ に7個のスキルファイル。全て1対1で対応
- **Phase gate の一貫性**: CLAUDE.md, design.md ref, impl.md ref, run.md が同一の phase 遷移ルールを参照
- **Counter limits**: CLAUDE.md (retry_count max 5, spec_update_count max 2, aggregate cap 6, dead-code max 3) と run.md の記述が完全一致
- **Verdict persistence format**: SKILL.md Router と review.md の記述が一致
- **Consensus mode**: SKILL.md Router と review.md の記述が一致
- **Artifact ownership**: CLAUDE.md の制約表と design.md ref, impl.md ref の SubAgent 動作が一貫
- **SubAgent lifecycle**: `run_in_background: true` 必須ルールが CLAUDE.md, design.md ref, impl.md ref, review.md, run.md, revise.md で一貫して記載
- **Knowledge tags**: `[PATTERN]`, `[INCIDENT]`, `[REFERENCE]` が CLAUDE.md, builder.md, knowledge SKILL.md, buffer.md テンプレートで一致
- **Steering feedback loop**: CLAUDE.md, review.md, auditor-design.md, auditor-impl.md で `CODIFY/PROPOSE` プロトコルが一致
- **File-based review protocol**: CLAUDE.md, review.md, 全 Inspector/Auditor が `reviews/active/` -> `reviews/B{seq}/` パターンを共有
- **Cross-cutting revision**: revise.md Part B の全ステップが CLAUDE.md 概要と一致
- **Blocking protocol**: CLAUDE.md と run.md Step 6 が一致
- **Wave Quality Gate**: run.md Step 7 の a/b/c が CLAUDE.md 概要と一致
- **Commit message format**: CLAUDE.md (`Wave {N}:`, `{feature}:`, `cross-cutting:`) と run.md, revise.md が一致
- **init.yaml テンプレート**: phase 名、orchestration フィールド、roadmap フィールドが全参照元と一致
- **Counter reset triggers**: CLAUDE.md L175 と run.md Post-gate (L185)、revise.md Step 4 (L63-64) が一致

---

### Cross-Reference Matrix

| Source File | References | Referenced By | Status |
|---|---|---|---|
| CLAUDE.md | refs/run.md, refs/crud.md, refs/revise.md, refs/review.md | 全 SKILL.md ({{SDD_DIR}} 定義), 全 agents ({{SDD_DIR}} パス) | OK |
| SKILL.md (roadmap) | refs/design.md, refs/impl.md, refs/review.md, refs/run.md, refs/revise.md, refs/crud.md | CLAUDE.md (Commands table) | OK |
| refs/design.md | agents/sdd-architect.md | SKILL.md router, refs/run.md, refs/revise.md | OK |
| refs/impl.md | agents/sdd-taskgenerator.md, agents/sdd-builder.md | SKILL.md router, refs/run.md, refs/revise.md | OK |
| refs/review.md | agents/sdd-inspector-*.md, agents/sdd-auditor-*.md | SKILL.md router, refs/run.md, refs/revise.md | OK |
| refs/run.md | refs/design.md, refs/impl.md, refs/review.md | SKILL.md router | OK |
| refs/revise.md | refs/design.md, refs/impl.md, refs/review.md, refs/crud.md, refs/run.md | SKILL.md router | OK |
| refs/crud.md | (self-contained) | SKILL.md router, refs/revise.md | OK |
| settings.json | 24 agent names, 7 skill names | install.sh (コピー対象) | OK |
| init.yaml | (テンプレート) | refs/design.md (SKILL.md Roadmap Ensure), refs/impl.md | OK |
| cpf-format.md | (仕様定義) | CLAUDE.md, 全 Inspector/Auditor | OK |
| design-review.md | (ルール定義) | agents/sdd-inspector-rulebase.md, agents/sdd-inspector-testability.md | OK* |
| design-principles.md | (ルール定義) | agents/sdd-architect.md | OK |
| design-discovery-full.md | (手順定義) | agents/sdd-architect.md | OK |
| design-discovery-light.md | (手順定義) | agents/sdd-architect.md | OK |
| tasks-generation.md | (ルール定義) | agents/sdd-taskgenerator.md | OK |
| steering-principles.md | (ルール定義) | skills/sdd-steering/SKILL.md | OK |
| templates/specs/design.md | (テンプレート) | agents/sdd-architect.md, agents/sdd-inspector-rulebase.md | OK |
| templates/specs/research.md | (テンプレート) | agents/sdd-architect.md | OK |
| templates/handover/session.md | (テンプレート) | CLAUDE.md (Session Resume), skills/sdd-handover/SKILL.md | OK |
| templates/handover/buffer.md | (テンプレート) | CLAUDE.md (buffer.md Format) | OK |
| templates/steering/product.md | (テンプレート) | skills/sdd-steering/SKILL.md | OK |
| templates/knowledge/*.md | (テンプレート) | skills/sdd-knowledge/SKILL.md | OK |
| install.sh | framework/claude/* (全ソース) | (外部エントリポイント) | OK |

(*) design-review.md で System Flows / Specifications Traceability セクションの言及が不足 (MEDIUM issue)

---

### Overall Assessment

**全体的な整合性**: 非常に高い。v1.2.0 のパス移行 (`.claude/sdd/` -> `.sdd/`) は framework/ ソースファイル全体で完了しており、`{{SDD_DIR}}` テンプレート変数による間接参照が正しく機能している。

**主な懸念点**:
1. **(HIGH, 実影響なし)**: install.sh の v1.2.0 マイグレーションと gitignore 管理の実行順序は問題ないが、明示性が低い
2. **(HIGH)**: Session resume で project-level reviews (wave/cross-check/dead-code) の previously-resolved 情報が復元されない。spec.yaml ベースの再構築はできるが、wave-level verdict 追跡には明示的なステップが必要
3. **(HIGH)**: sdd-review-self が `general-purpose` SubAgent を使うが、配布先 settings.json にその許可がない (framework 開発専用ツールとしては妥当だが未ドキュメント)
4. **(MEDIUM)**: design-review.md のセクションチェックリストに System Flows と Specifications Traceability が含まれていない

**デッドエンド**: 検出なし。全 phase 遷移パスが定義済みで、エラーハンドリングパスも網羅されている。

**循環参照**: 検出なし。refs/ 間の参照は DAG 構造 (router -> refs, run -> design/impl/review, revise -> design/impl/review/crud/run)。

**未定義参照**: 検出なし。全エージェント名、スキル名、テンプレートパス、ルールファイルパスが実際のファイルと一致。
