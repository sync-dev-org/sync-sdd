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
  location: "framework/claude/skills/sdd-roadmap/refs/run.md:276-283"
  description: "verdicts.yaml 永続化記述でレガシー角括弧ヘッダー記法が残留"
  fix: "run.md L276 を 'Persist verdict to verdicts.yaml (type: \"dead-code\", scope: \"wave-{wave}\", wave: {wave})' に、L283 を 'Persist verdict to verdicts.yaml (type: \"cross-check\", scope: \"wave-{wave}\", wave: {wave})' に修正"

- id: "A2"
  location: "framework/claude/skills/sdd-roadmap/refs/revise.md:43-49"
  description: "Single→Cross-Cutting エスカレーション時に Steering update がスキップされるリスク"
  fix: "エスカレーション指示を「Skip Part B Step 1 の REVISION_INITIATED recording のみスキップ。Steering update (Part B Step 1.3) は必ず実行する」に変更"

- id: "A4"
  location: "framework/claude/sdd/settings/templates/review-self/briefer.md:57,146 + auditor.md:80,89 + inspector-flow.md:27 + inspector-consistency.md:30 + inspector-compliance.md:52"
  description: "全テンプレートで summary と detail が同一行 — 不正な YAML 構文"
  fix: "全テンプレートおよび YAML 例示で summary と detail を別行に分離する。verdict-format.md §1 Inspector Findings の記法に合わせる"

- id: "A5"
  location: "install.sh:413"
  description: "v2.6.0 移行が .sdd/handover 存在時にしか走らず state.yaml 取りこぼし"
  fix: ".sdd/state.yaml の移動を if [ -d .sdd/handover ] ブロックの外側に独立分岐として配置: [ -f .sdd/state.yaml ] && mkdir -p .sdd/session && mv .sdd/state.yaml .sdd/session/state.yaml"

- id: "A6"
  location: "install.sh:416"
  description: "decisions.md → session/decisions.md だがフレームワークは .yaml を期待 + v2.5.x ケース未処理"
  fix: "(1) v2.5.x ユーザー: [ -f .sdd/handover/decisions.yaml ] && mv .sdd/handover/decisions.yaml .sdd/session/decisions.yaml を追加。(2) v2.5.0 以前: decisions.md はリネームして session/decisions-legacy.md にアーカイブ。decisions.yaml は新規テンプレートから生成しない（sdd-start が不在時に新規作成する）"

- id: "A7"
  location: "install.sh:417"
  description: "buffer.md → knowledge.yaml でフォーマット変換なし + v2.5.x ケース未処理"
  fix: "(1) [ -f .sdd/handover/knowledge.yaml ] && mv .sdd/handover/knowledge.yaml .sdd/session/knowledge.yaml を追加し buffer.md より優先する。(2) buffer.md は session/knowledge-legacy.md にリネームしてアーカイブ"

- id: "A8-B2"
  location: "framework/claude/skills/sdd-roadmap/refs/run.md:279 + framework/claude/CLAUDE.md"
  description: "Dead-Code NO-GO の再レビュー有無矛盾。D188 #9 の設計意図は再レビューなし"
  fix: "(1) run.md L279 から 'Max 3 retries (tracked in-memory, not persisted; restarts at 0 on session resume). On retry exhaustion: escalate to user with choices: (a) manually fix remaining dead-code and continue, (b) skip dead-code review and proceed to cross-check, (c) abort pipeline.' を削除。(2) CLAUDE.md の Auto-Fix Counter Limits から 'Exception: Dead-Code Review NO-GO: max 3 retries (dead-code findings are simpler scope; exhaustion → escalate).' を削除。(3) CLAUDE.md の Auto-Fix Counter Limits の counter reset triggers から 'session resume (dead-code counters are in-memory only; see refs/run.md)' を削除。(4) run.md の counter reset triggers の同じ文言も削除"

- id: "A9"
  location: "framework/claude/skills/sdd-roadmap/refs/run.md:283 + framework/claude/skills/sdd-review/SKILL.md"
  description: "wave cross-check の type が cross-check に正規化されない"
  fix: "sdd-review SKILL.md の Step 9 永続化で impl --wave N の場合は type: \"cross-check\" に正規化する旨を明記。run.md Step 8b もこの正規化後の type を参照するよう修正"

- id: "A10-B3"
  location: "framework/claude/skills/sdd-roadmap/SKILL.md:104"
  description: "Review の standalone vs dispatch-loop 二重パスの説明不足"
  fix: "SKILL.md の Execution Reference の Review 項目に「dispatch-loop 内では Review Decomposition (run.md §Review Decomposition) に従い sub-phase 分解で実行。standalone 呼び出し時のみ /sdd-review skill に委譲」と追記"

- id: "A11-B4"
  location: "framework/claude/skills/sdd-roadmap/refs/run.md:275-279 + framework/claude/skills/sdd-roadmap/SKILL.md + framework/claude/skills/sdd-review/SKILL.md"
  description: "wave dead-code の --wave N 引数が sdd-review に未定義"
  fix: "(1) sdd-roadmap router の review dead-code 引数定義に --wave N を追加 (2) run.md Step 8a を /sdd-review dead-code --wave N に更新 (3) sdd-review SKILL.md の引数パースと Scope Directory テーブルに dead-code --wave N を追加"

- id: "A12-B5"
  location: "framework/claude/skills/sdd-roadmap/SKILL.md:33-39"
  description: "revise モード検出の曖昧性"
  fix: "prefix match 後に AskUserQuestion で確認するよう追記。caveat テキストの後に「曖昧な場合は AskUserQuestion で Single-Spec か Cross-Cutting かを確認する」を追加"

- id: "A13"
  location: "framework/claude/sdd/settings/rules/verdict-format.md:64"
  description: "Auditor verdict の review_type 列挙が cross-check/cross-cutting を含まない"
  fix: "verdict-auditor.yaml と verdict.yaml の review_type 説明・例を cross-check / cross-cutting まで含めて更新し、§4 と同じ列挙集合に統一"

- id: "A14"
  location: "framework/claude/skills/sdd-roadmap/refs/run.md Phase Handlers"
  description: "dispatch-loop 内での refs 再読込タイミングが不明"
  fix: "run.md の Phase Handlers セクション冒頭に「Phase Handler 実行時、refs の内容が context window に残っていない場合は再度 Read する」旨のガイダンスを追加"

- id: "A15"
  location: "framework/claude/skills/sdd-roadmap/refs/run.md:259-264"
  description: "Blocking Protocol skip で keep blocked spec の counter reset が不明瞭"
  fix: "run.md Step 7 の skip オプションに「counter reset は proceed を選択した downstream spec に対してのみ即座に実行。keep blocked の spec は counter を保持（unblock 時に fix オプションで reset）」と明記"

- id: "A16-B6"
  location: "framework/claude/CLAUDE.md:223"
  description: "decisions.yaml の append-only と controlled rewrite の矛盾"
  fix: "CLAUDE.md の Session Persistence テーブルで decisions.yaml の Behavior を 'Append-only (consolidation rewrite at /sdd-handover only)' に変更。session/decisions/ ディレクトリをテーブルに追加: '| decisions/ | Archive | Dated archives of pruned decisions.yaml entries from consolidation |'"

- id: "A17"
  location: "framework/claude/skills/sdd-start/SKILL.md:39"
  description: "ステップ番号に欠番 (Step 5 なし)"
  fix: "Step 6 → Step 5, Step 7 → Step 6, Step 8 → Step 7, Step 9 → Step 8 に再ナンバリング"

- id: "A18"
  location: "framework/claude/sdd/settings/templates/review-self/briefer.md:45"
  description: "Briefer ファイル収集に存在しない inspector-brief.md が含まれる"
  fix: "inspector-brief.md への参照を削除"

- id: "A19"
  location: "framework/claude/CLAUDE.md:316"
  description: "Consolidation 記述に Flush ステップが欠落"
  fix: "'Consolidation occurs at /sdd-handover time (Step 4b):' を 'Flush + consolidation occurs at /sdd-handover time (Step 4b): flush pending decisions/knowledge,' に変更"

- id: "A20"
  location: "framework/claude/skills/sdd-review-self/SKILL.md:78"
  description: "BATCH_SEQ 決定が B{N} 文字列 vs seq 数値で二重定義"
  fix: "L78 を 'Read $SCOPE_DIR/verdicts.yaml, find max batches[].seq → $BATCH_SEQ = max+1. If absent → 1.' に統一"

- id: "A21"
  location: "install.sh:415"
  description: "v2.6.0 移行が handover.md (v2.5.0 後) を処理しない"
  fix: "L415 の後に [ -f .sdd/handover/handover.md ] && mv .sdd/handover/handover.md .sdd/session/handover.md を追加。session.md と handover.md の両方が存在する場合は handover.md を優先"

- id: "A22"
  location: "install.sh:418"
  description: "sessions/ → handovers/ リネームが v2.6.0 移行に未反映"
  fix: "[ -d .sdd/handover/handovers ] && mv .sdd/handover/handovers .sdd/session/handovers を L418 の後に追加"

- id: "A23-B7"
  location: "framework/claude/skills/sdd-roadmap/refs/run.md:272,294"
  description: "all-blocked 時のカウンタリセットが不適切"
  fix: "Post-gate (L294) のカウンタリセットに条件を追加: 'Reset counters for each spec that reached implementation-complete in this wave. blocked specs retain their counters (resolved via Blocking Protocol user decision).'"

- id: "A24"
  location: "framework/claude/skills/sdd-roadmap/refs/run.md:148"
  description: "AUDITOR-COMPLETE が sdd-review Step 8 を誤参照"
  fix: "Step 参照を 'Execute sdd-review Steps 8-9 (Lead supervision, verdict persist to verdicts.yaml, archive active → B{seq})' に修正"

- id: "A25-B8"
  location: "framework/claude/skills/sdd-start/SKILL.md:53"
  description: "grid 再利用条件を緩和し busy slot 保持で再利用可能にする"
  fix: "Step 7d (現 Step 6d) の再利用条件を「全 slot 生存」のみに変更。busy slot がある場合も再利用可能とし、idle slot のみ使用対象にする旨を明記。Step 7e の busy slot metadata 保持ロジックを有効化する"

- id: "A26-B9"
  location: "framework/claude/skills/sdd-start/SKILL.md:52"
  description: "grid 再利用時の window_id 検証がない"
  fix: "reuse 判定の前に window_id 検証を追加。ヘルパースクリプト経由で現在の lead pane の window_id を取得し、grid.window_id と一致する場合のみ reuse。不一致なら fresh grid を作成。具体的な取得方法: orphan-detect.sh に window_id 取得モードを追加するか、新規 window-id.sh スクリプトを作成"

- id: "A27"
  location: "framework/claude/skills/sdd-roadmap/refs/design.md:19"
  description: "design.md の追加 Phase Gate 条件が CLAUDE.md に未記載"
  fix: "CLAUDE.md の Phase Gate セクションに「各 ref が追加の phase-specific gate を定義しうる」旨の注記を追加"

- id: "A28"
  location: "framework/claude/skills/sdd-roadmap/refs/run.md:190-191"
  description: "Design Review NO-GO の counter 非 reset が GO 行にのみ記載"
  fix: "run.md の NO-GO ハンドリング行にも counter は retry 中 reset されない旨を追記"

- id: "A29"
  location: "framework/claude/skills/sdd-roadmap/refs/revise.md:8-10"
  description: "revise モード検出の prefix-match 仕様が refs に省略"
  fix: "refs/revise.md の Mode Detection に prefix-match 仕様参照を追記するか、Router の Detect Mode 記述を参照する旨を明記"

- id: "A30"
  location: "framework/claude/skills/sdd-roadmap/refs/run.md:8"
  description: "空 roadmap ガードのエラーメッセージが不正確"
  fix: "エラーメッセージを 'No spec directories found. Use /sdd-roadmap update to sync or /sdd-roadmap delete to reset.' に変更"

- id: "A31"
  location: "framework/claude/sdd/settings/templates/review-self/briefer.md:41,46,85,86"
  description: "shared-prompt.md にファイル重複エントリ"
  fix: "briefer.md Step 2 の glob パターンから重複を排除"

- id: "A32"
  location: "framework/claude/CLAUDE.md:36,110"
  description: "アーカイブ先 reviews/B{seq}/ が scope-dir 起点でなく曖昧"
  fix: "{scope-dir}/B{seq}/ 記法に統一"

- id: "A35"
  location: "framework/claude/sdd/settings/templates/review-self/briefer.md:76"
  description: "compliance キャッシュが verdicts.yaml の inspector 単位エントリを前提"
  fix: "verdicts.yaml では最新の type:self batch の seq と date を取得し、B{seq}/findings-inspector-compliance.yaml を参照する手順に修正"

- id: "A36"
  location: "framework/claude/skills/sdd-start/SKILL.md:16-17"
  description: "初回セッションで tmux 初期化がスキップされる"
  fix: "'Absent → first session: skip to Step 8' を 'Absent → first session: skip to Step 7' に変更 (再ナンバリング後は 'skip to Step 6')"

- id: "A37"
  location: "framework/claude/skills/sdd-roadmap/refs/run.md:163"
  description: "Readiness Rules で verdicts.yaml の type フィルタリングが未指定"
  fix: "'check verdicts.yaml latest batch where type=\"design\" on resume' のように type フィルタリングを明示"

- id: "A39-B11"
  location: "framework/claude/skills/sdd-start/SKILL.md:53"
  description: "busy slot metadata に Pattern A の url 属性が未記載"
  fix: "保持リストを agent/engine/channel/url に拡張し Pattern A/B 両方をカバー"

- id: "A40"
  location: "framework/claude/skills/sdd-review-self/SKILL.md:449"
  description: "Builder slot release で agent/engine/channel 除去が明記なし"
  fix: "Builder 完了後の slot release 記述に agent/engine/channel 除去と pane タイトルリセットを追記"

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
