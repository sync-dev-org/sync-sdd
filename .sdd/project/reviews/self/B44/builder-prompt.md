You are a Builder in fix mode — your job is to fix specific review findings.

## Input

Approved findings to fix are listed below. Each has an ID, location, description, and recommended fix.

## Rules

1. Fix ONLY the listed items — do not refactor, improve, or change anything else
2. Each fix should be minimal and targeted — change only what is necessary
3. Preserve existing code style, indentation, and conventions
4. If a fix requires changing multiple files, change all of them
5. If a recommended fix is unclear or would break something, skip it and report why

## Prohibited Commands

- "rm -rf /"
- "rm -rf ~"
- "rm -rf ."
- "rm -rf *"
- "git push --force"
- "git push -f"
- "git reset --hard"
- "shutdown"
- "reboot"
- "> /dev/"
- "mkfs"
- "dd if="
- ":(){:|:&};:"

## Findings to Fix

- id: "A1"
  location: "framework/claude/skills/sdd-roadmap/SKILL.md:115"
  description: "Router 共有プロトコルが verdicts.yaml を旧ヘッダ追記型として説明しており、現行 YAML batches スキーマと矛盾。"
  fix: "Shared Protocols の Verdict Persistence Format セクション (lines 115-129) を削除し、verdict-format.md §4 への参照に置き換える。例: '### Verdict Persistence Format\n\nverdicts.yaml の永続化スキーマは `{{SDD_DIR}}/settings/rules/verdict-format.md` §4 Verdict Index に準拠する。'"

- id: "A2"
  location: "framework/claude/skills/sdd-review/SKILL.md:162"
  description: "wave-scoped review の scope directory が project/reviews/wave/ 固定で wave-{N} と不一致。"
  fix: "scope table の Dead-code (wave) と Wave-scoped の行で project/reviews/wave/ を project/reviews/wave-{N}/ に変更。{N} は wave 番号。"

- id: "A3"
  location: "framework/claude/skills/sdd-roadmap/refs/run.md:276,283"
  description: "Wave QG の verdict 保存先が project/reviews/wave/ で wave-{N}/ と不一致。"
  fix: "run.md 内の project/reviews/wave/verdicts.yaml を全て project/reviews/wave-{N}/verdicts.yaml に変更。{N} は wave 番号変数 ({wave} が既に使われている箇所はそれを使う)。"

- id: "A4"
  location: "framework/claude/skills/sdd-roadmap/refs/revise.md:161,255"
  description: "Cross-Cutting revise で 2 つの ID 体系が使用 — Step 4 は kebab-case、Step 9 は timestamp。brief と verdict が別ディレクトリに格納される。"
  fix: "Step 3 (Impact Analysis) の後、Step 4 の前に CC_ID 生成ステップを追加: '$CC_ID を生成。format: {kebab-case-revision-name} (e.g., fractional-indexing)。以降の全ステップでこの CC_ID を使用する。' Step 4 の {id} を {CC_ID} に統一。Step 9 の '$CC_ID = cc-$(date ...)' 生成を削除し、Step 4 前で生成済みの CC_ID を参照するよう変更。Step 10 の {id} も {CC_ID} に統一。"

- id: "A5"
  location: "framework/claude/skills/sdd-start/SKILL.md:53"
  description: "grid 再利用時に state.yaml 生成例が全 slot を idle 再初期化し busy metadata が消失。"
  fix: "Step 7e に分岐を追加: 'grid 再利用時: 既存 state.yaml の grid セクションから busy slot の metadata (agent, engine, channel) を保持し、lead と sid のみ更新する。fresh grid 作成時: 全 slot を idle で初期化する。' YAML 例の前にこの分岐説明を追加。"

- id: "A6"
  location: "framework/claude/skills/sdd-review/SKILL.md:3"
  description: "argument-hint に --cross-cutting --id や dead-code --context wave が未表現。"
  fix: "argument-hint を更新。現在: 'design|impl <feature> [--cross-check] [--wave N] | dead-code [--briefer-engine ...' を 'design|impl <feature> [--cross-check] [--wave N] [--cross-cutting <specs> --id <cc_id>] | dead-code [--context standalone|wave] [--briefer-engine ...' に変更。"

- id: "A7"
  location: "framework/claude/skills/sdd-reboot/refs/reboot.md:120"
  description: "refs/run.md を参照するが reboot 配下に不在。実体は sdd-roadmap/refs/run.md。"
  fix: "reboot.md:120 の 'refs/run.md' を 'sdd-roadmap の refs/run.md' (フルパス: .claude/skills/sdd-roadmap/refs/run.md) に書き換え。同ファイル内の同種参照も統一。"

- id: "A8"
  location: "framework/claude/CLAUDE.md (Behavioral Rules section)"
  description: "AskUserQuestion を Skills の allowed-tools に含めてはならない制約がフレームワーク未記録。"
  fix: "CLAUDE.md の Behavioral Rules セクション末尾に追加: '- **AskUserQuestion exclusion**: Skills の `allowed-tools` に `AskUserQuestion` を含めてはならない。自動承認パスに入ると UI が表示されず空回答で返るバグがある。Skills は main context で実行されるため `allowed-tools` になくても通常の承認フローで動作する。'"

- id: "A9"
  location: "framework/claude/skills/sdd-roadmap/refs/revise.md:24-30"
  description: "revise の Validate が blocked_info.blocked_by や unknown phase を未処理。"
  fix: "Step 1 Validate の item 4 'BLOCK if phase is blocked' を拡張: '4. If phase is `blocked`: BLOCK with \"{feature} is blocked by {blocked_info.blocked_by}\"\n5. If phase is unrecognized: BLOCK with \"Unknown phase ''{phase}''\"'"

- id: "A11"
  location: "framework/claude/sdd/settings/templates/review-self/briefer.md:87"
  description: "Fixed Agent Prompts / agent template の旧用語が残存。"
  fix: "briefer.md 内の 'Fixed Agent Prompts' を 'Fixed Inspector Prompts' に、'agent template' を 'inspector template' に変更。全出現箇所を置換。"

- id: "A12"
  location: "framework/claude/sdd/settings/rules/cpf-format.md:1-3"
  description: "cpf-format.md が CPF を現行フォーマットとして説明。YAML 移行済み。"
  fix: "cpf-format.md の冒頭 (line 1-3) を変更。'# Compact Pipe-Delimited Format (CPF)' の次行に注記追加: '> **Legacy format** — retained for historical reference only. Current inter-agent communication uses YAML format defined in `verdict-format.md`.' 'Token-efficient structured text format used for inter-agent communication.' を 'Token-efficient structured text format formerly used for inter-agent communication (superseded by YAML).' に変更。"

- id: "A13+B1"
  location: "framework/claude/sdd/settings/scripts/multiview-grid.sh:50, framework/claude/sdd/settings/rules/tmux-integration.md:95, framework/claude/skills/sdd-review-self/SKILL.md, framework/claude/skills/sdd-review/SKILL.md, framework/claude/skills/sdd-start/SKILL.md"
  description: "slot title 規約の不整合。tmux-integration.md は sdd-{SID}-slot-{N} と記述、multiview-grid.sh は slot-{N} idle を使用。B1(b) の決定で sdd-{SID}-slot-{N} に統一。"
  fix: "1. multiview-grid.sh:50 — title 文字列を 'slot-$((i+1)) idle' から 'sdd-${SID}-slot-$((i+1))' に変更 ($SID はスクリプトの第1引数、変数名を確認のこと)。2. sdd-review-self/SKILL.md — slot リセット時の pane title を 'slot-{N} idle' から 'sdd-{SID}-slot-{N}' に全て変更。3. sdd-review/SKILL.md — 同様にリセット時 title を統一。4. sdd-start/SKILL.md — orphan 検出の fallback 説明は sdd- prefix 前提なので変更不要だが、もし slot-{N} idle への言及があれば統一。5. tmux-integration.md:95 は既に sdd-{SID}-slot-{N} なので変更不要。"

## Steps

1. Read each target file before editing
2. Apply the fix as described in the recommendation
3. After all fixes, run the test command if provided: none
4. If tests fail, identify which fix caused the failure and revert that specific fix
5. Run `git diff --stat` and include the output in your report as `diff_summary`

## Output

Write your report to: .sdd/project/reviews/self/active/builder-report.yaml

Format:
```yaml
status: "complete"          # complete/partial
items:
  - id: "A1"
    result: "fixed"         # fixed/skipped
    files_modified:
      - "path/to/file"
    note: ""                # What was done, or why skipped
tests:
  ran: false
  passed: false
  output: ""
diff_summary: |             # Output of git diff --stat
  file1 | 3 ++-
  file2 | 5 +++--
```

Print to stdout:
```
BUILDER_FIX_COMPLETE
Fixed: {N}/{total}
Skipped: {N}
Tests: not-run
WRITTEN:.sdd/project/reviews/self/active/builder-report.yaml
```
