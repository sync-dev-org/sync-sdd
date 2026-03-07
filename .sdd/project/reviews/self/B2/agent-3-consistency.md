# Consistency & Dead Ends Report

## Issues Found

### [HIGH] Builder TDD サイクルのステップ数不整合 (CLAUDE.md vs sdd-builder.md)

**Location**: `framework/claude/CLAUDE.md:25` / `framework/claude/agents/sdd-builder.md:33-68`

**Description**: CLAUDE.md のRole Architecture テーブルでは Builder を「TDD implementation. RED->GREEN->REFACTOR cycle.」と3ステップで記述しているが、sdd-builder.md の実際の実行ステップは6ステップ構成に拡張されている:

1. RED - Write Failing Test
2. GREEN - Write Minimal Code
3. REFACTOR - Clean Up
4. VERIFY - Validate Quality
5. SELF-CHECK - Pre-Review Quality Gate (新規追加)
6. MARK COMPLETE

CLAUDE.md は「RED->GREEN->REFACTOR cycle」という記述を維持しており、Step 4 (VERIFY)、Step 5 (SELF-CHECK)、Step 6 (MARK COMPLETE) の存在を反映していない。特に SELF-CHECK は完了レポートに `SelfCheck` フィールドを追加する重要な変更であり、この不整合は Lead が Builder の出力を正しく解釈する際のリスクとなる。

**補足**: refs/impl.md (Builder incremental processing) は SelfCheck の処理 (PASS/WARN/FAIL-RETRY) を正しく記述しており、実行フローとしては整合している。不整合は CLAUDE.md のハイレベル記述のみ。

---

### [MEDIUM] SelfCheck フィールド: Builder -> Lead 連携パターンの不完全記述

**Location**: `framework/claude/agents/sdd-builder.md:117` / `framework/claude/skills/sdd-roadmap/refs/impl.md:49-56`

**Description**: sdd-builder.md の完了レポート形式:
```
SelfCheck: {PASS | WARN({items}) | FAIL-RETRY-{N}({items})}
```

refs/impl.md の Builder incremental processing:
```
- Process SelfCheck result:
  - PASS -> normal processing
  - WARN({items}) -> log items, pass to Auditor
  - FAIL-RETRY-2({items}) -> Lead judgment
```

refs/impl.md では `FAIL-RETRY-2` と固定数値 (2) で記述しているが、sdd-builder.md では `FAIL-RETRY-{N}` (max 2 internal retries) と記述。`N` は 1 または 2 のみ取り得る (内部リトライが最大2回)。refs/impl.md は `FAIL-RETRY-2` のみを例示しているが、`FAIL-RETRY-1` ケースも発生しうる。

**影響**: 実用上は問題が少ない (Lead は FAIL-RETRY パターンマッチで処理すればよい) が、`FAIL-RETRY-1` ケースの処理が明示されていない。

---

### [LOW] Dead Code Review のパス使い分け曖昧性

**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:177-179` / `framework/claude/skills/sdd-roadmap/refs/review.md:49-53`

**Description**: refs/run.md Step 7b Dead Code Review は `{{SDD_DIR}}/project/reviews/wave/verdicts.md` に書き込むと記述。refs/review.md の Verdict Destination では standalone dead-code review の宛先は `{{SDD_DIR}}/project/reviews/dead-code/verdicts.md`。

Wave QG 内の Dead Code Review は wave スコープであるため wave ディレクトリが正しいが、standalone の `/sdd-roadmap review dead-code` は dead-code ディレクトリに書くべき。refs/run.md は明示的に wave パスを指定しているため実運用では問題は小さいが、この使い分けが refs/review.md 側で明文化されていない。

---

### [LOW] Commands 数: "6" vs 実際の skill 数 "7"

**Location**: `framework/claude/CLAUDE.md:141`

**Description**: CLAUDE.md は「Commands (6)」と記述し、テーブルに 6 コマンドを列挙: sdd-steering, sdd-roadmap, sdd-status, sdd-handover, sdd-knowledge, sdd-release。

`framework/claude/skills/` には 7 つの skill ディレクトリがある (sdd-review-self が追加)。sdd-review-self は「framework-internal use only」と明示されており CLAUDE.md テーブルから意図的に除外されていると解釈できるが、Lead がこのコマンドの存在を認識できない可能性がある。

**影響**: sdd-review-self はフレームワーク開発時にのみ使用されるため、影響は限定的。

---

### [LOW] TaskGenerator 失敗時のエラーハンドリング未明示

**Location**: `framework/claude/skills/sdd-roadmap/refs/impl.md:32`

**Description**: refs/impl.md は「Verify tasks.yaml exists」とだけ記述しており、TaskGenerator が tasks.yaml を生成できなかった場合のエラー処理 (リトライ or エスカレーション) が明示されていない。他の SubAgent (Architect, Builder, Inspector) には失敗時の処理が定義されている。

Lead の判断に委ねる設計思想と整合するため実用上の問題は小さいが、他の SubAgent との処理一貫性の観点で記述が不足している。

---

## Confirmed OK

- **Inspector 数**: CLAUDE.md (6+6+1+4=17) = 実ファイル数 (17) = refs/review.md 記述
- **Auditor 数**: CLAUDE.md (design, impl) + dead-code = 実ファイル数 (3)
- **Phase 名**: `initialized`, `design-generated`, `implementation-complete`, `blocked` が全ファイルで統一
- **Verdict 値**: GO/CONDITIONAL/NO-GO + SPEC-UPDATE-NEEDED (impl only) が全ファイルで統一
- **Auto-Fix Counter Limits**: retry_count max 5, spec_update_count max 2, aggregate cap 6, dead-code max 3 が全ファイルで統一
- **Counter reset triggers**: wave completion, user escalation, revise start が CLAUDE.md, refs/run.md, refs/revise.md で統一
- **Severity コード**: C/H/M/L が全 Inspector/Auditor/CPF ルール/design-review ルールで統一
- **Agent 名 (CPF)**: `+` セパレータが全 Auditor で統一
- **Verdict Persistence Format**: Router 定義と refs/review.md が整合
- **`orchestration.last_phase_action`**: null -> tasks-generated -> impl-complete の遷移が全ファイルで整合
- **STEERING フィードバック**: CODIFY/PROPOSE の定義が CLAUDE.md, Auditor 3種, refs/review.md で統一
- **Profiles パス**: `{{SDD_DIR}}/settings/profiles/` が CLAUDE.md, sdd-steering, install.sh で整合
- **Template パス**: `{{SDD_DIR}}/settings/templates/` 配下の全参照が実ファイルと一致
- **Knowledge tags**: `[PATTERN]`, `[INCIDENT]`, `[REFERENCE]` が CLAUDE.md, sdd-builder.md, buffer.md テンプレートで統一
- **Decision types**: 7種が CLAUDE.md 内で2箇所記述されており、両方とも一致
- **SubAgent dispatch 方式**: `Task(subagent_type="sdd-xxx")` 形式が全ファイルで統一
- **Session Resume 手順**: CLAUDE.md の7ステップが handover テンプレートと整合
- **CPF フォーマット**: cpf-format.md のルールが全 Inspector/Auditor の出力形式仕様と整合
- **spec.yaml テンプレート**: init.yaml のフィールドが全ファイルの参照と一致
- **install.sh のインストール対象**: skills, agents, sdd/settings/ がフレームワークソースと一致
- **install.sh のマイグレーション**: v0.4.0 (kiro->sdd), v0.7.0 (coordinator), v0.9.0 (handover redesign), v0.10.0 (spec.json->yaml), v0.15.0 (commands->skills), v0.18.0 (agents->sdd/settings/agents), v0.20.0 (agents->claude/agents) がバージョン順で適切にチェーン
- **Blocked Protocol**: blocked_info フィールド (blocked_by, blocked_at_phase, reason) が refs/run.md と spec init.yaml (null) で整合
- **1-Spec Roadmap Optimizations**: SKILL.md と refs/run.md で同一の最適化 (skip Wave QG, skip cross-check) を記述
- **Consensus Mode**: threshold ⌈N×0.6⌉ が SKILL.md で定義、refs/review.md が参照

---

## Cross-Reference Matrix

### SubAgent 名の相互参照

| SubAgent 名 | CLAUDE.md | Agent File | refs/review.md | refs/run.md | refs/impl.md | refs/design.md |
|-------------|-----------|------------|---------------|------------|-------------|---------------|
| sdd-architect | T2 | OK | -- | OK | -- | OK |
| sdd-auditor-design | T2 | OK | OK | OK | -- | -- |
| sdd-auditor-impl | T2 | OK | OK | OK | -- | -- |
| sdd-auditor-dead-code | T2 | OK | OK | OK | -- | -- |
| sdd-taskgenerator | T3 | OK | -- | OK | OK | -- |
| sdd-builder | T3 | OK | -- | OK | OK | -- |
| sdd-inspector-rulebase | T3 | OK | OK | -- | -- | -- |
| sdd-inspector-testability | T3 | OK | OK | -- | -- | -- |
| sdd-inspector-architecture | T3 | OK | OK | -- | -- | -- |
| sdd-inspector-consistency | T3 | OK | OK | -- | -- | -- |
| sdd-inspector-best-practices | T3 | OK | OK | -- | -- | -- |
| sdd-inspector-holistic | T3 | OK | OK | -- | -- | -- |
| sdd-inspector-impl-rulebase | T3 | OK | OK | -- | -- | -- |
| sdd-inspector-interface | T3 | OK | OK | -- | -- | -- |
| sdd-inspector-test | T3 | OK | OK | -- | -- | -- |
| sdd-inspector-quality | T3 | OK | OK | -- | -- | -- |
| sdd-inspector-impl-consistency | T3 | OK | OK | -- | -- | -- |
| sdd-inspector-impl-holistic | T3 | OK | OK | -- | -- | -- |
| sdd-inspector-e2e | T3 | OK | OK (web) | -- | -- | -- |
| sdd-inspector-dead-settings | T3 | OK | OK | -- | -- | -- |
| sdd-inspector-dead-code | T3 | OK | OK | -- | -- | -- |
| sdd-inspector-dead-specs | T3 | OK | OK | -- | -- | -- |
| sdd-inspector-dead-tests | T3 | OK | OK | -- | -- | -- |

**全 23 agent が定義元と参照元の両方で確認済。未参照 agent なし。**

### ファイルパス相互参照

| パス (テンプレート変数使用) | 参照元 | 実ファイル |
|---------------------------|--------|-----------|
| `{{SDD_DIR}}/settings/rules/cpf-format.md` | CLAUDE.md | OK |
| `{{SDD_DIR}}/settings/rules/design-review.md` | inspector-rulebase, inspector-testability | OK |
| `{{SDD_DIR}}/settings/rules/design-principles.md` | sdd-architect | OK |
| `{{SDD_DIR}}/settings/rules/design-discovery-full.md` | sdd-architect | OK |
| `{{SDD_DIR}}/settings/rules/design-discovery-light.md` | sdd-architect | OK |
| `{{SDD_DIR}}/settings/rules/tasks-generation.md` | sdd-taskgenerator | OK |
| `{{SDD_DIR}}/settings/rules/steering-principles.md` | sdd-steering | OK |
| `{{SDD_DIR}}/settings/templates/specs/design.md` | sdd-architect, inspector-rulebase | OK |
| `{{SDD_DIR}}/settings/templates/specs/research.md` | sdd-architect | OK |
| `{{SDD_DIR}}/settings/templates/specs/init.yaml` | sdd-roadmap SKILL.md | OK |
| `{{SDD_DIR}}/settings/templates/handover/session.md` | CLAUDE.md, sdd-handover | OK |
| `{{SDD_DIR}}/settings/templates/handover/buffer.md` | CLAUDE.md | OK |
| `{{SDD_DIR}}/settings/templates/knowledge/{type}.md` | sdd-knowledge | OK (3 files) |
| `{{SDD_DIR}}/settings/templates/steering/*.md` | sdd-steering | OK (3 files) |
| `{{SDD_DIR}}/settings/templates/steering-custom/*.md` | sdd-steering | OK (8 files) |
| `{{SDD_DIR}}/settings/profiles/` | sdd-steering, CLAUDE.md | OK (4 files) |

**全参照パスが実ファイルに対応。未定義参照なし。**

### Protocol 相互参照

| Protocol | 定義元 | 参照元 | 整合 |
|----------|-------|--------|------|
| Phase Gate | CLAUDE.md | refs/design.md, refs/impl.md | OK |
| Verdict Persistence | SKILL.md (Router) | refs/review.md, refs/run.md | OK |
| Consensus Mode | SKILL.md (Router) | refs/review.md, refs/run.md | OK |
| Blocking Protocol | refs/run.md Step 6 | CLAUDE.md (reference) | OK |
| Auto-Fix Loop | CLAUDE.md, refs/run.md | refs/review.md (standalone=no auto-fix) | OK |
| Steering Feedback Loop | CLAUDE.md | refs/review.md (processing rules) | OK |
| Knowledge Auto-Accumulation | CLAUDE.md | refs/impl.md, sdd-knowledge | OK |
| Session Resume | CLAUDE.md | sdd-handover (manual polish) | OK |
| Pipeline Stop Protocol | CLAUDE.md | refs/run.md (implicit) | OK |
| Builder Parallel Coordination | CLAUDE.md | refs/impl.md (incremental) | OK |
| Wave Quality Gate | refs/run.md Step 7 | SKILL.md (1-spec skip) | OK |
| SelfCheck Processing | sdd-builder.md | refs/impl.md | OK (minor gap) |

---

## Unreachable Paths / Dead Ends 分析

### Phase 遷移の完全性

```
initialized
  -> design-generated       (via /sdd-roadmap design)
  -> blocked                (via Blocking Protocol)

design-generated
  -> implementation-complete  (via /sdd-roadmap impl)
  -> design-generated         (via NO-GO auto-fix: re-design)
  -> blocked                  (via Blocking Protocol)

implementation-complete
  -> design-generated       (via SPEC-UPDATE-NEEDED, /sdd-roadmap revise)
  -> blocked                (via Blocking Protocol)

blocked
  -> {blocked_at_phase}     (via unblock after upstream fix)
  -> blocked                (remains if not resolved)
```

**Dead End 検査結果**: Dead End なし。全 phase から次の phase への遷移が定義されている。

### Error Handling Gaps

| エラーシナリオ | 処理定義 | ファイル | 完全性 |
|--------------|---------|---------|-------|
| Architect 失敗 | Escalate to user | refs/design.md | OK |
| TaskGenerator 失敗 | "Verify tasks.yaml exists" | refs/impl.md | 不完全 (LOW) |
| Builder BLOCKED | Classify cause, reorder/escalate | refs/impl.md | OK |
| Inspector 失敗 | Retry, skip, or proceed | CLAUDE.md, refs/review.md | OK |
| Auditor verdict 未出力 | Verdict Output Guarantee | sdd-auditor-*.md | OK |
| DAG cycle | BLOCK with error message | refs/run.md | OK |
| Retry exhaustion | Escalate to user | refs/run.md, CLAUDE.md | OK |
| SPEC-UPDATE-NEEDED (design review) | Escalate immediately | refs/run.md | OK |

---

## Circular References 分析

ファイル参照関係を検査:

```
CLAUDE.md -> refs/run.md, refs/review.md (via "see sdd-roadmap")
SKILL.md -> refs/{design,impl,review,run,revise,crud}.md
refs/run.md -> refs/design.md, refs/impl.md, refs/review.md
refs/review.md -> SKILL.md (Router: Verdict Persistence, Consensus Mode)
refs/revise.md -> refs/design.md, refs/impl.md, refs/review.md
```

**潜在的循環**: refs/review.md -> SKILL.md -> refs/review.md

実際にはセクション参照であり実行時循環ではない (refs/review.md は SKILL.md の Shared Protocols セクションを参照、SKILL.md は refs/review.md を Mode detection 後にロード)。

**結果**: Circular reference なし。

---

## Overall Assessment

フレームワーク全体の整合性は極めて高い。23 agent 定義、7 skill、7 ルール、18+ テンプレートにわたり、値定義・パス定義・プロトコル定義がほぼ完全に統一されている。

**確認済み issue サマリー**:
- **HIGH**: 1件 (Builder TDD サイクル記述の不整合)
- **MEDIUM**: 1件 (SelfCheck FAIL-RETRY パターンの不完全記述)
- **LOW**: 3件 (Dead Code Review パス曖昧性、Commands 数、TaskGenerator エラーハンドリング)

**最優先修正推奨**: CLAUDE.md の Builder 説明を「TDD implementation. RED->GREEN->REFACTOR->VERIFY->SELF-CHECK cycle.」に更新、または「TDD implementation with pre-review self-check.」に変更する。
