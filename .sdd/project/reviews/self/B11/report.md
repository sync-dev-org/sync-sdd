# SDD Framework Self-Review Report
**Date**: 2026-02-28 | **Agents**: 4 dispatched, 4 completed | **Version**: v1.3.2+context-budget

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| Dead-code retry counter in-memory reset = limit bypass | Agent 1 M3 | 明示的設計。run.md L247 に "restarts at 0 on session resume" と文書化済み。B10 L5 で明示化確認済み |
| Consensus B{seq} Inspector prompt 未指定 | Agent 1 M4 | B10 L3 で "Router が決定して渡す" と review.md に明記済み。Inspector prompt の具体的記述は実装時裁量 |
| sdd-auditor-dead-code SCOPE フィールド欠如 | Agent 3 H2 | Pre-existing (今回変更なし) |
| sdd-inspector-testability Wave-Scoped design-review.md 未読 | Agent 3 H3 | Pre-existing (今回変更なし) |
| SKILL.md Consensus Mode パス混在 | Agent 3 M1 | Pre-existing (B3/B4 既知) |
| design-review.md と Inspector rulebase 重複 | Agent 3 M2 | Pre-existing (今回変更なし) |
| Dead-code Inspector SCOPE wave-scoped 未明示 | Agent 3 M3 | Pre-existing (今回変更なし) |
| revise.md Part A Step 4 phase transition timing | Agent 1 M1 | Pre-existing (今回変更なし) |
| design.md Step 2 abort 後の状態未明示 | Agent 1 M5 | Pre-existing |
| sdd-inspector-interface tasks.yaml 不要読み込み | Agent 3 M5 | Pre-existing |
| review dead-code --wave N 未定義 | Agent 1 L1 | Pre-existing |
| Lookahead Staleness Guard 戻り先未定義 | Agent 1 L2 | Pre-existing |
| review.md SPEC-UPDATE-NEEDED 注記欠如 | Agent 1 L3 | Pre-existing |
| sdd-inspector-testability Wave-Scoped 手順省略 | Agent 3 L1 | Pre-existing |
| initialized フェーズ遷移ルート未文書 | Agent 3 L2 | Pre-existing |
| crud.md Delete spec reviews 暗黙削除 | Agent 3 L3 | Pre-existing |

## CRITICAL (1)

### C1: settings.json に Task(sdd-conventions-scanner) 未登録
**Location**: `framework/claude/settings.json`
**Description**: 新 Agent `sdd-conventions-scanner` が settings.json の allow リストに未登録。dispatch 時に権限エラーとなり、Wave Context 生成、Pilot Stagger、Cross-Cutting conventions brief 生成が全てブロックされる。
**Evidence**: Agent 2, 3, 4 が同一問題を独立検出。run.md:33, impl.md:62, revise.md:213 で dispatch を指示。
**Fix**: `"Task(sdd-conventions-scanner)"` を allow 配列に追加

## HIGH (1)

### H1: CLAUDE.md Knowledge Auto-Accumulation が旧プロトコルを記述
**Location**: `framework/claude/CLAUDE.md:287`
**Description**: 「Lead collects tagged reports from SubAgent Task results」と記述されているが、Builder は minimal summary に `Tags: {count}` のみ返し、詳細は `builder-report-{group}.md` に書き出す新プロトコル。impl.md:75 の Grep ベースの抽出が正しい。
**Evidence**: Agent 2 H1
**Fix**: "Task results" → "builder-report files (via targeted Grep)" に修正

## MEDIUM (2)

### M1: impl.md Step 4 auto-draft スキップ条件が impl.md 本体に未記載
**Location**: `framework/claude/skills/sdd-roadmap/refs/impl.md:93-96`
**Description**: run.md:187 の外部注釈 `skip Step 4 auto-draft when called from dispatch loop` に依存。impl.md 単体を読んだだけではスキップ条件が不明。
**Evidence**: Agent 2 H2
**Fix**: impl.md Step 4 に条件注記を追加

### M2: revise.md Part B Step 7 NO-GO 処理フローが不完全
**Location**: `framework/claude/skills/sdd-roadmap/refs/revise.md:241-244`
**Description**: run.md Phase Handlers への明示的参照が欠如。NO-GO 時のカウンターインクリメント、Architect 再 dispatch 等の詳細が省略。
**Evidence**: Agent 1 M2, Agent 3 M4 (重複)
**Fix**: "Handle per run.md Phase Handlers" への参照追加 (pre-existing だが今回の変更で顕在化)

## LOW (2)

### L1: ConventionsScanner Supplement モード output path が impl.md dispatch に未記載
**Location**: `framework/claude/skills/sdd-roadmap/refs/impl.md:62-66`
**Description**: Scanner agent 定義では output path が必要 input だが、impl.md の dispatch prompt テンプレートに含まれていない。Scanner は既存 brief path を overwrite するため実質問題ないが、明示性が不足。
**Evidence**: Agent 2 L1

### L2: CLAUDE.md SubAgent Failure Handling が Builder ファイルベース化に未対応
**Location**: `framework/claude/CLAUDE.md` SubAgent Failure Handling セクション
**Description**: idempotent 記述が review SubAgent のみ前提。Builder の retry は impl.md で定義されているが CLAUDE.md との対応付けがない。
**Evidence**: Agent 2 M1

## Platform Compliance

| Item | Status |
|---|---|
| エージェント YAML フロントマター (25件) | OK (24 cached + 1 new verified) |
| sdd-conventions-scanner フロントマター | OK (model: sonnet, tools: Read/Glob/Grep/Write, background: true) |
| スキル フロントマター (6件) | OK (cached) |
| Task dispatch subagent_type 一致 | **FAIL** — sdd-conventions-scanner が settings.json に未登録 |
| settings.json 構造 | OK (cached) |
| settings.json Task エントリ完全性 | **FAIL** — 25 agents, 24 entries |
| モデル値 | OK (sonnet/opus のみ) |
| background フィールド | OK (全 agent true) |

## Overall Assessment

**リリースブロッカー 1 件** (C1): settings.json の Task 許可欠如。修正しないと ConventionsScanner が実行不可。
**HIGH 1 件** (H1): Knowledge Auto-Accumulation の記述が旧プロトコルのまま。Lead が旧方式で動作する可能性。
MEDIUM/LOW 4 件は動作への直接影響が限定的だが、修正推奨。

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 (blocker) | C1 | settings.json に Task(sdd-conventions-scanner) 追加 | framework/claude/settings.json |
| 2 | H1 | Knowledge Auto-Accumulation 記述を新プロトコルに更新 | framework/claude/CLAUDE.md |
| 3 | M1 | impl.md Step 4 にスキップ条件注記追加 | framework/claude/skills/sdd-roadmap/refs/impl.md |
| 4 | M2 | revise.md Step 7 に Phase Handlers 参照追加 | framework/claude/skills/sdd-roadmap/refs/revise.md |
| 5 | L1 | impl.md Supplement dispatch に output path 追記 | framework/claude/skills/sdd-roadmap/refs/impl.md |
| 6 | L2 | Failure Handling に Builder 言及追加 | framework/claude/CLAUDE.md |
