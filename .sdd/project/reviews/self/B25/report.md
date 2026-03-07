# SDD Framework Self-Review Report (External Engine)
**Date**: 2026-03-03T21:38:35+0900 | **Engine**: Codex CLI [default] | **Agents**: 4 dispatched, 4 completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| run.md ↔ review.md bidirectional reference cycle | Agent 3 | 設計上の委譲パターン。双方向参照は意図的 |
| argument-hint BNF format (UNCERTAIN) | Agent 4 | argument-hint は freeform 文字列。複合記法は単なる値として機能。Lead 確認済み |

## HIGH (6)

### H1: Cross-cutting review protocol 不完全
**Location**: review.md:84, review.md:142, revise.md:255-256
**Description**: Cross-cutting review の scope-dir が `.cross-cutting/{id}/reviews/` と定義される一方、verdict 保存先が `.cross-cutting/{id}/verdicts.md` で分岐。実行プロトコル（起動引数、{id} 受け渡し、対象 spec 絞り込み）が review.md に未移設
**Detected by**: Agent 1 + Agent 2 + Agent 3

### H2: sdd-inspector-e2e trigger が steering のみ
**Location**: review.md:38, sdd-inspector-e2e.md
**Description**: E2E inspector の起動条件が steering/tech.md の `# E2E` セクション有無だけ。design.md の per-spec E2E コマンドを見ていないため、design.md のみに E2E を定義する spec では inspector が起動されない
**Detected by**: Agent 2

### H3: Design Auditor NO-GO threshold
**Location**: sdd-auditor-design.md:168, design-review.md:209-212
**Description**: Design Auditor は Critical 残件時のみ NO-GO を返すが、design-review.md は blocker-level の SDD drift/missing info を H にも割り当てる。High のみの重大設計欠陥が CONDITIONAL で実装に進みうる
**Detected by**: Agent 3

### H4: Design Review phase gate が loose
**Location**: review.md:22
**Description**: Design Review の phase gate が design.md 存在確認と blocked 判定だけ。initialized の skeleton design.md でも review 開始可能。CLAUDE.md の「spec.yaml.phase が適切か確認」と不整合
**Detected by**: Agent 1

### H5: Blocking Protocol と Design Review 失敗パスの矛盾
**Location**: run.md:231, run.md:186-189
**Description**: Blocking Protocol の fix は upstream が implementation-complete に戻ることを前提に downstream を unblock するが、Design Review 失敗で retry 枯渇した場合に設計段階で止まった spec を正しく復旧できない
**Detected by**: Agent 1

### H6: sdd-review-self-ext Step 4 tmux 無条件実行
**Location**: sdd-review-self-ext/SKILL.md:119
**Description**: Fallback mode を定義しているのに Step 4 で無条件に tmux display-message / list-panes を実行。$TMUX 未設定環境では Step 5 の fallback 分岐前に失敗する
**Detected by**: Agent 2

## MEDIUM (6)

### M1: Consensus mode scope 曖昧
**Location**: CLAUDE.md:111, SKILL.md(roadmap)
**Description**: CLAUDE.md は `--consensus N` を「N pipelines in parallel」と定義する一方、Router の Shared Protocol は review 用 Inspector/Auditor セットの複製だけを定義。全体 pipeline 複製 vs review-only consensus が未確定
**Detected by**: Agent 1

### M2: Consensus active-{p}/ パス衝突
**Location**: review.md:89
**Description**: Review Execution Flow は Step 3 で consensus 用に active-{p}/ を作成した後も Step 4-7 で入出力先を active/ のまま記述。multi-pipeline の出力先が衝突する
**Detected by**: Agent 1

### M3: Session Resume が .cross-cutting verdicts を未読
**Location**: CLAUDE.md:277
**Description**: Session Resume が読む verdict は per-spec と project/reviews/*/verdicts.md だけ。.cross-cutting/{id}/verdicts.md を再読しないため、compact/再開時に revise パイプラインの review 状態を完全復元できない
**Detected by**: Agent 3

### M4: sdd-inspector-test frontmatter に Edit 欠落
**Location**: sdd-inspector-test.md:5,17
**Description**: Constraint で Edit 使用を指示しているが frontmatter tools には Edit が含まれていない。定義と利用可能ツールが矛盾
**Detected by**: Agent 3 + Agent 4

### M5: sdd-inspector-e2e wave-scoped 入力契約不在
**Location**: sdd-inspector-e2e.md:25
**Description**: E2E inspector は single-spec / cross-check しか入力契約を定義しておらず、wave-scoped impl review の受け口がない。出力例に wave-1..{N} があるのに wave 番号の受け取り方が欠落
**Detected by**: Agent 2

### M6: reboot.md refs/run.md 参照が曖昧
**Location**: reboot.md:120,180
**Description**: reboot.md が `refs/run.md` を参照するがこれは sdd-roadmap/refs/run.md のクロススキル参照。reboot skill 配下には refs/run.md が存在せず、パスが相対表記のため解決不能
**Detected by**: Agent 3

## LOW (5)

### L1: revise Detect Mode 衝突リスク
**Location**: SKILL.md(roadmap):34
**Description**: revise の Detect Mode が先頭語の spec 名一致だけで Single-Spec/Cross-Cutting を分岐。cross-cutting 指示文が既存 spec 名で始まると誤判定
**Detected by**: Agent 1

### L2: Pane Cleanup format string 不一致
**Location**: sdd-review-self-ext/SKILL.md:329
**Description**: Pane Cleanup が pane_current_command から sdd-ext-review- タイトルを探すが、pane_current_command には pane title が含まれない
**Detected by**: Agent 2

### L3: CPF schema UNCERTAIN 二重定義
**Location**: sdd-review-self-ext/SKILL.md:76
**Description**: CPF 共通定義の severity は C/H/M/L のみ。Agent 4 に UNCERTAIN を ISSUES に直接書く指示を追加したことでスキーマが二重化
**Detected by**: Agent 2

### L4: review.md type/options 用語混線
**Location**: review.md:18
**Description**: 1-spec guard が「review type is --cross-check or --wave N」とするが、review type は design/impl/dead-code。オプションと型の用語が混在
**Detected by**: Agent 3

### L5: sdd-review-self yaml scope 未含
**Location**: sdd-review-self/SKILL.md:35
**Description**: 内部 self-review の scope が templates/**/*.md までで templates/**/*.yaml を含まない。engines.yaml テンプレートが通常 self-review の対象外
**Detected by**: Agent 3

## Platform Compliance

| Item | Status | Source |
|---|---|---|
| agent-frontmatter | OK (cached) | https://docs.anthropic.com/en/docs/claude-code/sub-agents |
| skill-frontmatter | OK | https://docs.anthropic.com/en/docs/claude-code/skills |
| dispatch | OK (cached) | https://docs.anthropic.com/en/docs/claude-code/sub-agents |
| settings-permission-format | OK | https://docs.anthropic.com/en/docs/claude-code/settings#permissions |
| settings-skill-agent-parity | OK | https://docs.anthropic.com/en/docs/claude-code/settings#permissions |
| tool-availability | NG → M4 | https://docs.anthropic.com/en/docs/claude-code/sub-agents |
| argument-hint-format | UNCERTAIN → FP (Lead resolved) | https://docs.anthropic.com/en/docs/claude-code/skills |

## Overall Assessment

34 ファイル変更 (E2E Inspector 分離、review.md 仕様整備、tmux 共通化、engines.yaml) に対して H6 M6 L5 = 17 findings。前回 B1 (H4 M5 L0 = 9) より finding 数は増加したが、LOW が 5 件報告されるようになり検出幅が拡大。

最大のリスクは **H1 (cross-cutting review protocol 不完全)** — 3 Agent が独立に検出した高確度の finding。Cross-cutting review の実行パスが review.md に未定義のまま。

**UNCERTAIN/LOW 改善の効果**: B1 ではL=0だったが B2 ではL=5。Citation 義務化により Agent 4 が argument-hint を正しく UNCERTAIN で報告し、background:true のような FP-NG は発生しなかった。

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 | H1 | Cross-cutting review 実行プロトコル完成 | review.md, revise.md |
| 2 | H6 | Step 4 を tmux conditional に修正 | sdd-review-self-ext/SKILL.md |
| 3 | H2,M5 | E2E inspector trigger + wave 入力契約 | review.md, sdd-inspector-e2e.md |
| 4 | M4 | inspector-test frontmatter に Edit 追加 | sdd-inspector-test.md |
| 5 | H4,H5 | Design Review phase gate + blocking protocol | review.md, run.md |
| 6 | H3 | Design Auditor NO-GO threshold 見直し | sdd-auditor-design.md, design-review.md |
| 7 | M1,M2 | Consensus mode 仕様確定 | CLAUDE.md, review.md |
| 8 | M3 | Session Resume .cross-cutting verdict 対応 | CLAUDE.md |
| 9 | M6 | reboot.md refs/run.md パス明示化 | reboot.md |
| 10 | L1-L5 | LOW findings 修正 | 各該当ファイル |
