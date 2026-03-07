# SDD Framework Self-Review Report (External Engine)
**Date**: 2026-03-03T23:48:59+0900 | **Engine**: gemini [gemini-3-flash-preview] | **Agents**: 4 dispatched, 4 completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| Blocking Protocol 定義ファイル不在 | 3 | run.md 内に Blocking Protocol セクションが存在。別ファイルではなく同一ファイル内参照 |
| auto-draft policy 定義場所不明確 | 3 | CLAUDE.md session.md セクションに明記済み |
| SPEC-UPDATE-NEEDED が設計監査に無い | 3 | 意図的設計。設計レビューでは仕様自体を評価するため不要 |
| cross-check 時の Auditor 判断基準不明 | 3 | review.md Step 1 に type ごとのディスパッチ記載済み |
| tools リストがカンマ区切り文字列 | 4 | Claude Code はカンマ区切り文字列を正常パース。公式ドキュメントでもこの形式 |
| allowed-tools がカンマ区切り文字列 | 4 | 同上 |
| `background: true` フィールド非標準 | 4 | Claude Code 公式サポートフィールド (D96 で確認済み) |
| `Skill` ツールが allowed-tools に含まれる | 4 (UNCERTAIN) | Skill は Claude Code 標準ツール |

## CRITICAL (0)

(none)

## HIGH (1)

### F1: コンセンサスモードの閾値と合成ロジックの矛盾
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md
**Description**: SKILL.md の argument-hint で定義されたコンセンサス閾値(⌈N×0.6⌉)と、review.md Step 8 の合成ロジックが「いずれかのパイプラインが NO-GO なら NO-GO」という Strict Veto 方式になっている。多数決によるハルシネーション抑制というコンセンサスモードの意図が損なわれている。
**Agent**: 1

## MEDIUM (2)

### F2: FAIL-RETRY-{N} 解釈ロジック不足
**Location**: framework/claude/agents/sdd-auditor-impl.md
**Description**: Builder が報告する「FAIL-RETRY-{N}」形式を Auditor が適切に解釈・検証するためのロジックの記述が不足。
**Agent**: 3

### F3: AC Grep パターン不完全
**Location**: framework/claude/agents/sdd-inspector-impl-rulebase.md
**Description**: 「AC: {feature}」パターンでの Grep を指示しているが、他ファイルでは「AC: {feature}.S{N}.AC{M}」が標準であり、不完全なマッチングを招く恐れ。
**Agent**: 3

## LOW (10)

### F4: wait-for チャネル名例示の不一致
**Location**: framework/claude/skills/sdd-review-self-ext/SKILL.md:160-163
**Description**: Step 5 の例示で `ch-1` を使用しているが、冒頭で推奨されている `sdd-ext-review-N` と不一致。
**Agent**: 2

### F5: AC マーカーチェック重複
**Location**: sdd-inspector-impl-rulebase.md / sdd-inspector-test.md
**Description**: 両 Inspector が類似の AC トレース確認を行い冗長。
**Agent**: 1

### F6: SPEC-UPDATE-NEEDED vs NO-GO の優先順位記述
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md
**Description**: Step 8 合成ロジックで SPEC-UPDATE-NEEDED が NO-GO より優先度が低いにもかかわらず記述順序が紛らわしい。
**Agent**: 1

### F7: エラーメッセージに新オプション未反映
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md:14
**Description**: Step 1 エラーメッセージに --cross-check, --wave N オプションが含まれていない。
**Agent**: 2

### F8: One-Shot 例と ext 実装の命名規則不一致
**Location**: tmux-integration.md / sdd-review-self-ext/SKILL.md
**Description**: tmux-integration.md の One-Shot Command パターン例示と SKILL.md の実装例で命名規則が異なる。
**Agent**: 2

### F9: {{SDD_DIR}} 変数未使用
**Location**: framework/claude/skills/sdd-handover/SKILL.md:18
**Description**: decisions.md 参照で {{SDD_DIR}} 変数が使用されていない。
**Agent**: 3

### F10: Builder リトライ回数の曖昧さ
**Location**: framework/claude/agents/sdd-builder.md
**Description**: Builder 内部リトライ(2回)と roadmap リトライ制限(3回)の整合性が不明確。
**Agent**: 3

### F11: CPF カテゴリ名の乖離
**Location**: framework/claude/agents/sdd-auditor-dead-code.md
**Description**: Auditor が期待する CPF カテゴリ名と Inspector 指示書内の例が一部乖離。
**Agent**: 3

### F12: codex stdin クォート処理の言及不足
**Location**: framework/claude/skills/sdd-review-self-ext/SKILL.md:126
**Description**: tmux split-window 内での codex コマンドのクォート処理に関する言及がない。
**Agent**: 2

### F13: argument-hint YAML 特殊文字未クォート
**Location**: framework/claude/skills/sdd-{roadmap,reboot,release,status,steering}/SKILL.md
**Description**: argument-hint 値に YAML 特殊文字 (`[`, `|`) が含まれているが引用符で囲まれていない (5件)。
**Agent**: 4

## Platform Compliance

| Item | Status | Source |
|---|---|---|
| agent-frontmatter | OK (cached) | docs.anthropic.com/en/docs/claude-code/sub-agents |
| skill-frontmatter | OK (cached) | docs.anthropic.com/en/docs/claude-code/skills |
| dispatch (subagent_type) | OK (cached) | docs.anthropic.com/en/docs/claude-code/sub-agents |
| settings-permission-format | OK (cached) | docs.anthropic.com/en/docs/claude-code/settings#permissions |
| settings-skill-agent-parity | OK | Verified: all files match settings.json |
| argument-hint quoting | LOW | YAML special chars should be quoted for safety |
| tools comma-delimited | FP | Claude Code accepts comma-delimited strings |
| background field | FP (D96) | Confirmed as official supported field |
| Skill in allowed-tools | FP (UNCERTAIN→resolved) | Skill is a standard Claude Code tool |

## Overall Assessment

Gemini 3 Flash (Preview) で 4 Agent 全完了。429 クォータエラーが頻発したが、Gemini CLI の自動リトライにより全 Agent が成果物を生成。

**品質**: H1 M2 L10。HIGH の F1 (コンセンサス Strict Veto) は B2 (Codex) でも未検出の新規 finding。MEDIUM 2件は Agent 定義の記述精度に関する改善点。LOW 10件は文書整合性の軽微な問題。

**Gemini Flash 評価**: ファイル読み込みと分析は正確。LOW findings を適切に報告（10件）。FP 率は高め（8件除外）だが、新規 finding の発見力あり。

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 | F1 | コンセンサス閾値 vs Strict Veto 矛盾 | refs/review.md |
| 2 | F2 | FAIL-RETRY 解釈ロジック追加 | sdd-auditor-impl.md |
| 3 | F3 | AC Grep パターン修正 | sdd-inspector-impl-rulebase.md |
| 4 | F4,F8 | チャネル名/命名規則統一 | SKILL.md, tmux-integration.md |
| 5 | F7 | review.md エラーメッセージ更新 | refs/review.md |
| 6 | F13 | argument-hint クォート追加 | skills/sdd-*/SKILL.md (5件) |
