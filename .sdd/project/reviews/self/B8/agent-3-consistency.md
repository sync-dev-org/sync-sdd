## Consistency & Dead Ends Report

**レビュー日時**: 2026-02-24
**対象**: SDD フレームワーク全ファイル
**エージェント**: Agent 3 — Consistency & Dead Ends

---

### Issues Found

#### [HIGH] Commands テーブルの数値不一致
- **ファイル**: `framework/claude/CLAUDE.md:139`
- **内容**: `### Commands (5)` と記載されているが、実際には `sdd-roadmap`, `sdd-steering`, `sdd-status`, `sdd-handover`, `sdd-release`, `sdd-review-self` の **6スキル** が存在する。
- `sdd-review-self` は `settings.json` に登録されており (`Skill(sdd-review-self)`)、`framework/claude/skills/sdd-review-self/SKILL.md` も存在する。しかし CLAUDE.md の Commands テーブルにはエントリがなく、数値も `(5)` のまま。
- Lead がコマンド体系を把握する際に `/sdd-review-self` の存在を認識できない。

#### [HIGH] `install.sh` v0.18.0 移行コードが誤方向
- **ファイル**: `install.sh:362-371`
- **内容**: v0.18.0 の移行コードは「エージェント定義を `.claude/agents/` から `.claude/sdd/settings/agents/` へ移動する」と記述しているが (`info "Migrated agents/ -> sdd/settings/agents/ (v0.18.0)"`)、直後の v0.20.0 コード (l.372-384) が「`.claude/sdd/settings/agents/` から `.claude/agents/` へ戻す」処理をしている。
- 実際の現在の正規インストール先は `.claude/agents/` (v0.20.0 以降)。
- v0.18.0 → v0.20.0 の間の一時的な移動を表すコードであり機能的には問題ないが、コメントのみ見ると「v0.18.0 で agents/ から移動した」と読め、v0.20.0 のコードとの意図が分かりにくい。実害は限定的だが保守上の混乱要因。

#### [MEDIUM] `sdd-review-self` エージェントが `general-purpose` subagent_type を使用
- **ファイル**: `framework/claude/skills/sdd-review-self/SKILL.md:58`
- **内容**: `Task(subagent_type="general-purpose", model="sonnet", run_in_background=true)` を使用している。他のすべての SubAgent ディスパッチは `subagent_type="sdd-{name}"` 形式。`general-purpose` が有効な subagent_type かどうかはプラットフォーム仕様依存。
- `settings.json` にも `Task(general-purpose)` エントリがなく、パーミッション設定が不完全な可能性がある。
- Agent 4 (Platform Compliance) で詳細確認が必要。

#### [MEDIUM] Impl Review フェーズゲート: `run.md` で `retry_count` max 5 の記述が不完全
- **ファイル**: `framework/claude/skills/sdd-roadmap/refs/run.md:128`
- **内容**: Impl Review NO-GO 処理に `(max 5 retries)` とあるが、後の `Aggregate cap` 記述が欠けている (`Aggregate cap: 6` が明示されていない行に aggregate cap が書かれていない)。一方 Design Review NO-GO (l.113) は `(max 5 retries, aggregate cap 6)` と両方明記されている。
- CLAUDE.md:168 の定義と矛盾はないが、run.md 内の記述の一貫性が欠ける。Lead が Impl Review の aggregate cap を見落とす可能性。
- ただし l.130 に `Aggregate cap: Total cycles (retry_count + spec_update_count) MUST NOT exceed 6.` と別行で記載されているため、実害は低い。

#### [MEDIUM] Wave QG 内 Impl Cross-Check の retry_count reset タイミング不明確
- **ファイル**: `framework/claude/skills/sdd-roadmap/refs/run.md:170-175`
- **内容**: Wave QG Step 7a で Cross-Check Review が NO-GO になった場合 `retry_count` をインクリメントするが、このカウントが「どのスペックのカウント」なのかが曖昧。クロスチェックは複数スペックをまたぐため、`target spec(s)` にマップする処理はあるが、aggregate cap (6) の計算が spec ごとなのかウェーブ全体として適用するのかが明記されていない。
- CLAUDE.md の Auto-Fix Counter Limits セクションは spec 単位を想定しているが、wave QG は wave 単位の操作であり、整合性の説明が不足。

#### [MEDIUM] `sdd-inspector-impl-holistic` の Cross-Check Mode で tasks.yaml 読み込みが記載されているが不要な可能性
- **ファイル**: `framework/claude/agents/sdd-inspector-impl-holistic.md:83-84`
- **内容**: Cross-Check Mode の Load Context で `design.md` のみ言及しているが、Wave-Scoped Cross-Check Mode では `design.md + tasks.yaml` を読む (l.74)。Single Spec Mode では `design.md` と `spec.yaml` および implementation files を読む (l.41-55)。
- Cross-Check Mode での implementation files 読み込みに関する明示的な指示がなく、他の実装系 Inspector (interface, quality 等) が実装ファイルを読むのに対して holistic が読まない場合、クロスカッティングな runtime リスクを発見できない可能性がある。
- 他の実装系 Inspector (例: `sdd-inspector-quality.md`) は Cross-Check Mode でも実装ファイルを明示的に読む (`Glob + Read`)。

#### [LOW] Design Review と Impl Review の Auditor CPF 出力ファイル名の非対称性
- **ファイル**:
  - `framework/claude/agents/sdd-auditor-design.md` (cpf ファイル名未指定)
  - `framework/claude/agents/sdd-auditor-impl.md` (同)
  - `framework/claude/skills/sdd-roadmap/refs/review.md:83`
- **内容**: review.md では Auditor 出力パスを `{scope-dir}/active/verdict.cpf` と指定。Auditor エージェント定義では「spawn context の verdict output path に書く」とだけ記載。これ自体は問題ないが、Inspector が `{your-inspector-name}.cpf` というファイル名を出力する際、Auditor が `verdict.cpf` を読む際のファイル名衝突リスクはない (Inspector は `sdd-inspector-*.cpf`、Auditor は `verdict.cpf` と区別されている)。問題なし、確認のみ。

#### [LOW] `sdd-steering` SKILL.md の `-y` フラグ処理 — `update` と `roadmap` のコマンドテーブル記述の差異
- **ファイル**: `framework/claude/skills/sdd-roadmap/SKILL.md:39`
- **内容**: `$ARGUMENTS = "-y"` は「Auto-detect: run if roadmap exists, create if not」と定義。`sdd-steering` の引数では `-y` は「Auto-approve update mode」。両スキルで `-y` が異なる意味を持つが、スキルが独立しているため実害なし。ただし、ユーザードキュメントで混乱する可能性。

#### [LOW] Wave Quality Gate の Dead-Code Review カウンタと CLAUDE.md の Exception 記述の関係
- **ファイル**: `framework/claude/CLAUDE.md:169` と `framework/claude/skills/sdd-roadmap/refs/run.md:182`
- **内容**: CLAUDE.md では「Dead-Code Review NO-GO: max 3 retries」と明記。run.md:182 も「max 3 retries」と一致。整合性はとれている。ただし、この Dead-Code の 3 retries が aggregate cap 6 に含まれるのかが CLAUDE.md には書かれていない (「Exception」として別扱いされている)。Aggregate cap は通常の NO-GO + SPEC-UPDATE のカウント計算であり、Dead-Code は別スペックのレビューのため別カウンタが適切だが、明示されていない。

---

### Confirmed OK

- **フェーズ名の統一**: `initialized` / `design-generated` / `implementation-complete` / `blocked` が CLAUDE.md、design.md、impl.md、review.md、run.md、revise.md、sdd-status SKILL.md 全体で一貫して使用されている。
- **Verdict 値の統一**: `GO` / `CONDITIONAL` / `NO-GO` / `SPEC-UPDATE-NEEDED` が Auditor エージェント、review.md、run.md、revise.md で一貫して使用されている。Dead-code Auditor は `SPEC-UPDATE-NEEDED` を使用しない (3値) ことも設計通り。
- **SubAgent 名称の統一**: `sdd-architect`, `sdd-builder`, `sdd-taskgenerator`, `sdd-auditor-design`, `sdd-auditor-impl`, `sdd-auditor-dead-code`, `sdd-inspector-{*}` が settings.json の Task() エントリ、review.md のディスパッチリスト、エージェント定義ファイル名で一致している。
- **CPF 形式の統一**: 全 Inspector/Auditor が同一の CPF 出力構造 (VERDICT / SCOPE / ISSUES / NOTES / VERIFIED / REMOVED / RESOLVED / STEERING) を使用しており、cpf-format.md の仕様と整合。Severity コード (C/H/M/L) も統一。
- **パス変数 `{{SDD_DIR}}` の一貫使用**: 全ファイルを通じて `{{SDD_DIR}}` が一貫して使用されており、CLAUDE.md の定義 (`{{SDD_DIR}}` = `.sdd`) と整合している。
- **レビューディレクトリのパス命名**: `reviews/active/` → `reviews/B{seq}/` のアーカイブフロー、および `reviews/cross-check/`, `reviews/dead-code/`, `reviews/wave/`, `reviews/self/` の各スコープパスが CLAUDE.md、review.md、run.md、sdd-review-self SKILL.md で一貫している。
- **Inspector セット数の一致**: CLAUDE.md (「6 design, 6 impl +2 web, 4 dead-code」)と review.md のディスパッチリストが完全に一致している。settings.json の Task() エントリもすべての Inspector を網羅している。
- **retry_count max 5 / spec_update_count max 2 / aggregate cap 6**: CLAUDE.md と run.md (Design Review/Impl Review 両方) で数値が一貫している。revise.md も同じ cap を参照している。
- **Builder SelfCheck ステータス (`PASS` / `WARN` / `FAIL-RETRY-{N}`)**: builder.md の定義と impl.md の処理ロジックが一致。Auditor へのアテンションポイント伝達も review.md Step 6 と整合。
- **spec.yaml 所有権**: Architect/Builder/TaskGenerator はいずれも「spec.yaml を更新しない」と明記されており、CLAUDE.md の State Management 方針と一致。
- **knowledge tags `[PATTERN]/[INCIDENT]/[REFERENCE]`**: builder.md の定義、impl.md の収集ロジック、buffer.md テンプレート、CLAUDE.md の Knowledge Auto-Accumulation セクションで一貫。
- **Verdict Persistence Format (B{seq})**: SKILL.md (Router)、review.md Step 8、sdd-review-self Step 6 で、`verdicts.md` への追記形式が統一されている。
- **`decisions.md` 決定タイプ**: CLAUDE.md と revise.md で同一の型 (USER_DECISION, STEERING_UPDATE, DIRECTION_CHANGE, ESCALATION_RESOLVED, REVISION_INITIATED, STEERING_EXCEPTION, SESSION_START/SESSION_END) が使用されている。
- **Design Inspector の cpf ファイル名**: Auditor design.md のリスト (rulebase, testability, architecture, consistency, best-practices, holistic) と review.md の Inspector ディスパッチリスト、および各 Inspector エージェント名が完全に対応している。
- **Impl Inspector の cpf ファイル名**: Auditor impl.md のリスト (impl-rulebase, interface, test, quality, impl-consistency, impl-holistic, e2e, visual) と review.md のディスパッチリスト、各 Inspector エージェントが完全に対応している。
- **Playwright ツール指定**: E2E Inspector と Visual Inspector の両エージェントが `playwright-cli` (npm) を指定し、CLAUDE.md の Playwright セクションと整合。Python Playwright の禁止も一致。
- **Buffer.md テンプレートの参照**: CLAUDE.md:246 (`Template: {{SDD_DIR}}/settings/templates/handover/buffer.md`) と実際のテンプレートが存在する。
- **Session.md テンプレートの参照**: CLAUDE.md:236 と sdd-handover SKILL.md Step 3 が同じテンプレートパスを参照。
- **init.yaml テンプレートの参照**: SKILL.md (Single-Spec Roadmap Ensure Step 3a) が `{{SDD_DIR}}/settings/templates/specs/init.yaml` を参照し、実ファイルが存在する。
- **steering-custom テンプレートの列挙**: sdd-steering SKILL.md のリスト (api-standards, authentication, database, deployment, error-handling, security, testing, ui) と `framework/claude/sdd/settings/templates/steering-custom/` の実ファイルが一致している。
- **Language Profile の参照**: sdd-steering SKILL.md が `{{SDD_DIR}}/settings/profiles/` を参照し、実際に `python.md`, `typescript.md`, `rust.md`, `_index.md` が存在する。
- **`WRITTEN:{path}` 返却規約**: すべての Inspector と Auditor が「Return only `WRITTEN:{path}` as your final text」という同一の規約に従っており、CLAUDE.md の Review SubAgents 説明と一致。
- **Cross-Cutting revise パス**: revise.md Part B が `specs/.cross-cutting/{id}/brief.md` と `specs/.cross-cutting/{id}/verdicts.md` を使用し、review.md の Verdict Destination リスト (`{{SDD_DIR}}/project/specs/.cross-cutting/{id}/verdicts.md`) と一致。
- **`1-Spec Roadmap Optimizations`**: SKILL.md (Router) に定義され、run.md Step 7 でも「1-Spec Roadmap: Skip this step」と一致。
- **Circular reference がない**: ファイル参照チェーン (CLAUDE.md → refs/*.md → agent files → rules/*.md → templates) に循環参照なし。
- **install.sh のインストール先**: `framework/claude/skills/` → `.claude/skills/`、`framework/claude/agents/` → `.claude/agents/`、`framework/claude/sdd/settings/` → `.sdd/settings/` と CLAUDE.md のパス定義 (`.claude/agents/`、`.sdd/settings/`) と一致。

---

### Cross-Reference Matrix

| 参照元 | 参照先 | 参照内容 | 整合性 |
|--------|--------|----------|--------|
| CLAUDE.md | refs/run.md | dispatch loop, auto-fix, wave QG | OK |
| CLAUDE.md | refs/review.md | Steering Feedback Loop 処理 | OK |
| CLAUDE.md | refs/crud.md | Wave Scheduling | OK |
| CLAUDE.md | refs/revise.md | Cross-Cutting Parallelism | OK |
| SKILL.md (sdd-roadmap) | refs/design.md | Design mode | OK |
| SKILL.md (sdd-roadmap) | refs/impl.md | Impl mode | OK |
| SKILL.md (sdd-roadmap) | refs/review.md | Review mode | OK |
| SKILL.md (sdd-roadmap) | refs/run.md | Run mode | OK |
| SKILL.md (sdd-roadmap) | refs/revise.md | Revise mode | OK |
| SKILL.md (sdd-roadmap) | refs/crud.md | Create/Update/Delete mode | OK |
| refs/review.md | sdd-inspector-{*} | Inspector名、cpfファイル名 | OK |
| refs/review.md | sdd-auditor-design/impl/dead-code | Auditor名 | OK |
| sdd-auditor-design.md | sdd-inspector-{rulebase,testability,architecture,consistency,best-practices,holistic}.cpf | cpf読み込みリスト | OK |
| sdd-auditor-impl.md | sdd-inspector-{impl-rulebase,interface,test,quality,impl-consistency,impl-holistic,e2e,visual}.cpf | cpf読み込みリスト | OK |
| sdd-auditor-dead-code.md | sdd-inspector-{dead-settings,dead-code,dead-specs,dead-tests}.cpf | cpf読み込みリスト | OK |
| CLAUDE.md (Commands) | settings.json (Skill()) | コマンド数: CLAUDE.md=5, Skill=6 | **不一致 (HIGH)** |
| settings.json (Skill) | framework/claude/skills/sdd-*/SKILL.md | スキルファイルの存在 | OK (sdd-review-self含む全6個あり) |
| settings.json (Task) | framework/claude/agents/sdd-*.md | エージェントファイルの存在 | OK (全24個一致) |
| sdd-review-self SKILL.md | general-purpose subagent_type | Task dispatch | settings.json に Task(general-purpose) エントリなし — **MEDIUM** |
| sdd-architect.md | {{SDD_DIR}}/settings/templates/specs/design.md | テンプレート参照 | OK (ファイル存在) |
| sdd-architect.md | {{SDD_DIR}}/settings/templates/specs/research.md | テンプレート参照 | OK (ファイル存在) |
| sdd-architect.md | {{SDD_DIR}}/settings/rules/design-principles.md | ルール参照 | OK (ファイル存在) |
| sdd-architect.md | {{SDD_DIR}}/settings/rules/design-discovery-full.md | ルール参照 | OK (ファイル存在) |
| sdd-architect.md | {{SDD_DIR}}/settings/rules/design-discovery-light.md | ルール参照 | OK (ファイル存在) |
| sdd-taskgenerator.md | {{SDD_DIR}}/settings/rules/tasks-generation.md | ルール参照 | OK (ファイル存在) |
| sdd-inspector-rulebase.md | {{SDD_DIR}}/settings/rules/design-review.md | ルール参照 | OK (ファイル存在) |
| sdd-steering SKILL.md | {{SDD_DIR}}/settings/rules/steering-principles.md | ルール参照 | OK (ファイル存在) |
| CLAUDE.md | {{SDD_DIR}}/settings/rules/cpf-format.md | CPF仕様参照 | OK (ファイル存在) |
| sdd-handover SKILL.md | {{SDD_DIR}}/settings/templates/handover/session.md | テンプレート参照 | OK (ファイル存在) |
| CLAUDE.md | {{SDD_DIR}}/settings/templates/handover/buffer.md | テンプレート参照 | OK (ファイル存在) |
| refs/run.md Step 7 (wave QG Dead-Code) | CLAUDE.md (Dead-Code retry max 3) | retry上限 | OK |
| CLAUDE.md (retry_count max 5) | refs/run.md Design/Impl Review handler | retry上限 | OK |
| revise.md Part A | refs/design.md | Design実行参照 | OK |
| revise.md Part A | refs/review.md | Review実行参照 | OK |
| revise.md Part A | refs/impl.md | Impl実行参照 | OK |
| revise.md Part B | run.md Step 2 (File Ownership) | Cross-Spec File Ownership | OK |
| revise.md Part B | run.md Step 7a (Cross-Check) | Consistency Review mechanism | OK |
| install.sh | framework/claude/CLAUDE.md | CLAUDE.md インストール | OK |
| install.sh | framework/claude/settings.json | settings.json インストール | OK |
| install.sh | framework/claude/skills/ | スキルインストール先 | OK |
| install.sh | framework/claude/agents/ | エージェントインストール先 | OK |
| install.sh | framework/claude/sdd/settings/ | rules/templates/profiles インストール | OK |
| install.sh v0.18.0 migration | .claude/agents/ | 移行方向 (agents → sdd/settings/agents) | 機能的には v0.20.0 で解消済みだが記述が混乱の元 (MEDIUM相当) |

---

### Overall Assessment

全体としてフレームワークの整合性は高く、フェーズ名・バーディクト値・SubAgent 名称・CPF 形式・パス変数などの主要な値が一貫して使用されている。ファイル参照の循環もなく、undefined reference も最小限。

**優先度の高い修正対象:**

1. **CLAUDE.md の Commands テーブルに `sdd-review-self` を追加し、数値を (5) → (6) に更新** (HIGH)
   - ユーザーと Lead が `/sdd-review-self` コマンドの存在を認識できない状態になっている。

2. **`sdd-review-self` での `general-purpose` subagent_type の検証** (MEDIUM)
   - プラットフォーム仕様として有効かどうかを Agent 4 (Platform Compliance) で確認し、必要であれば settings.json に `Task(general-purpose)` エントリを追加するか、または専用エージェント定義を用いる方式に変更する。

3. **install.sh の v0.18.0/v0.20.0 マイグレーションコメントの明確化** (LOW-MEDIUM)
   - コードの機能は正しいが、コメントが「一時的な移動 → 元に戻す」という意図を示しておらず、保守時の混乱を招く可能性がある。コメントに「v0.18.0 では一時移動、v0.20.0 で最終位置に戻す」旨を明記することを推奨。
