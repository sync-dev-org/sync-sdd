---
description: Generate session handover document for cross-session continuity
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: [output-path]
---

# SDD Session Handover

<background_information>
- **Mission**: セッション終了時に、次のセッションがスムーズに作業を継続できる構造化されたハンドオーバー文書を生成する
- **Success Criteria**:
  - プロジェクトの現在状態を正確に自動収集する
  - セッション中の作業内容・意思決定・未解決事項を捕捉する
  - 次セッションが読むだけで即座にコンテキストを復元できる
  - トークン効率の良いフォーマットで、必要十分な情報量を維持する
- **Design Principles** (Community Best Practices):
  - **Goal-Directed Handoff**: 何が起きたか (history) ではなく、何をしようとしているか (intent) を優先保存する
  - **Two-Layer Approach**: 戦略的方向性 (direction) + 技術的詳細 (details) の二層構造
  - **External File Persistence**: コンテキストウィンドウに依存せず、ファイルに永続化する
  - **Concise Over Complete**: 次セッションがコードを読み直せる情報は省略し、コードから読み取れない情報に集中する
</background_information>

<instructions>

## Core Task
現在のセッション状態を収集・構造化し、ハンドオーバー文書を生成する。

## Execution Steps

### Step 1: プロジェクト状態の自動収集

以下を**並列で**収集する:

#### 1a. Git 状態
```bash
git branch --show-current          # 現在のブランチ
git status --short                 # 未コミットの変更
git log --oneline -10              # 直近コミット
git diff --stat HEAD               # 未ステージの変更サマリー
git stash list                     # スタッシュ一覧
```

#### 1b. Roadmap・Spec 状態
- `{{KIRO_DIR}}/specs/roadmap.md` を読み、Wave 構造を把握
- `{{KIRO_DIR}}/specs/*/spec.json` を全て読み、各 spec の phase を収集
- 各 spec の `tasks.md` をスキャンし、タスク完了状況 (`- [x]` vs `- [ ]`) を集計

#### 1c. テスト状態
```bash
# テストを実行して結果を取得（プロジェクトのテストコマンドを使用）
uv run pytest --tb=no -q 2>&1 | tail -5
```

#### 1d. Steering 変更
- `{{KIRO_DIR}}/steering/` のファイル一覧と最終更新日を確認

### Step 2: セッションコンテキストの収集

**AskUserQuestion で対話的に収集する** (省略可能な項目あり):

#### Question 1: セッションの目的と成果
```
このセッションで何を達成しましたか？
（会話履歴から推測した内容を提示し、ユーザーに確認・修正を求める）
```
- 会話コンテキストから自動推測した成果リストを提示
- ユーザーが修正・追加・承認

#### Question 2: 未完了タスクと次のアクション
```
次のセッションで最初にやるべきことは何ですか？
```
- Options:
  - A. "ロードマップの次のステップを続行" (自動検出した次ステップを表示)
  - B. "特定のタスクから再開" (タスク番号を指定)
  - C. "自由記述で指定"

#### Question 3: 重要な意思決定・注意事項 (任意)
```
次のセッションに引き継ぐべき重要な判断や注意事項はありますか？
（なければスキップ可）
```
- Options:
  - A. "特になし"
  - B. "あり（記述する）"

### Step 3: ハンドオーバー文書の生成

以下の構造でマークダウン文書を生成する:

```markdown
# Session Handover

**Generated**: {ISO 8601 timestamp}
**Branch**: {current branch}
**Session Goal**: {1文でセッションの目的}

## Direction (次セッションへの指示)

### Immediate Next Action
{次セッションが最初に実行すべき具体的アクション}
{可能なら実行コマンドも記載: `/sdd-impl feature 3.1` など}

### Active Goals
{現在進行中の目標。roadmap の wave 進行状況と紐付け}

### Key Decisions
{このセッションで行った重要な意思決定とその理由}
{次セッションが覆すべきでない判断を明記}

### Warnings
{既知の問題、罠、注意すべき点}
{なければセクション省略}

## State (プロジェクト状態スナップショット)

### Roadmap Progress
| Wave | Name | Progress | Status |
|------|------|----------|--------|
{自動収集データからテーブル生成}

### Spec Status
| Spec | Phase | Tasks | Notes |
|------|-------|-------|-------|
{自動収集データからテーブル生成}

### Git State
- **Branch**: {branch}
- **Uncommitted Changes**: {count} files
- **Recent Commits**:
{直近5件のコミットログ}

### Test Status
{テスト実行結果サマリー}

## Session Log (実施内容)

### Accomplished
{箇条書きで完了した作業}

### Modified Files
{主要な変更ファイル一覧 - git diff --stat から}

## Resume Instructions

次のセッションでは以下を実行してください:
1. `Read .claude/handover.md` でこの文書を読み込む
2. {具体的な再開手順}
```

### Step 4: ファイル書き出し

1. **デフォルト出力先**: `.claude/handover.md` (常に最新のハンドオーバーで上書き)
2. **引数で出力先指定可能**: `$1` が指定された場合はそのパスに書き出す
3. **アーカイブ**: 既存の `.claude/handover.md` がある場合:
   - 内容が異なれば `.claude/handovers/{YYYY-MM-DD-HHMM}.md` にコピーしてからoverwrite
   - アーカイブディレクトリが存在しない場合は作成

### Step 5: CLAUDE.md への参照追加 (初回のみ)

`.claude/CLAUDE.md` に以下が含まれていない場合、末尾に追加する:

```markdown
## Session Handover
- セッション開始時: `.claude/handover.md` が存在すれば読み込み、前回の状態を復元する
- セッション終了時: `/sdd-handover` でハンドオーバー文書を生成する
```

</instructions>

## Tool Guidance

### 並列実行
- Step 1 の Git 状態取得、Spec スキャン、テスト実行は**並列で実行**する
- Step 2 の対話は Step 1 完了後に行う

### ファイル操作
- **Glob**: `{{KIRO_DIR}}/specs/*/spec.json`, `{{KIRO_DIR}}/specs/*/tasks.md` の一括検索
- **Read**: spec.json, tasks.md, roadmap.md の読み込み
- **Bash**: Git コマンド実行、テスト実行
- **Write**: ハンドオーバー文書の書き出し
- **Edit**: CLAUDE.md への参照追加 (初回のみ)

### 対話
- **AskUserQuestion**: セッションコンテキスト収集
- 自動収集できる情報は自動で、人間しか知らない情報のみ対話で収集
- ユーザーが急いでいる場合は最小限の対話 (Question 1 のみ) で生成可能

## Output Description

ハンドオーバー文書生成後、以下を表示:

```
## Handover Generated

**File**: .claude/handover.md
**Archive**: .claude/handovers/YYYY-MM-DD-HHMM.md (if applicable)

### Summary
- Wave N: X/Y specs complete
- Next action: {具体的な次のアクション}
- Uncommitted changes: {count} files
- Tests: {pass/fail status}

### Resume in Next Session
> Read .claude/handover.md でコンテキストを復元してください
```

**Format**: 簡潔 (200 words 以内)

## Safety & Fallback

### Error Scenarios

**Git リポジトリ未初期化**:
- Git 関連の情報収集をスキップ
- Warning を表示して続行

**Roadmap 未作成**:
- Roadmap Progress セクションを省略
- 個別 Spec Status のみ表示

**テスト実行失敗**:
- エラーメッセージをそのまま Test Status に記録
- 生成は中断しない

**既存ハンドオーバーとの競合**:
- 常にアーカイブしてから上書き
- アーカイブは日時でソートされ、古いものから参照可能

### Integration

**セッション開始時 (次セッションの推奨フロー)**:
1. `.claude/handover.md` を読む
2. Direction セクションに従って作業を開始
3. 不明点があれば State セクションを参照

**セッション終了時**:
1. `/sdd-handover` を実行
2. 必要に応じてコミット
3. セッションを終了

think
