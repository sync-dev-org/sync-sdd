# Session Handover
**Generated**: 2026-03-09T03:34:26+0900
**Branch**: main
**Session Goal**: sdd-review-self 改修計画の設計 — Engine Dispatch 共有化 + Briefer SubAgent 降格 + references/ lib/ 移動 + 変数廃止

## Direction

### Immediate Next Action
1. プランファイル (`.claude/plans/splendid-growing-snowglobe.md`) の実行順序に従い、sdd-review-self 改修を実装する
2. 最初に lib/references/ にファイルをコピー、次に dispatch/engine.md 新規作成、次に lib/prompts/review-self/ にファイル移動+修正、最後に SKILL.md 編集

### Active Goals
- **sdd-review-self 改修 (D227)**: 設計計画完成済み。実装待ち。7項目の設計決定を包括するプランファイルあり
- **Read-inline 移行 (Phase 2)**: sdd-review-self の 4箇所の `/sdd-log` Skill 呼び出しを Read-inline 化。本改修に含まれる
- **I33 lib/ マイグレーション**: D226 で初期判断済み。prompts/log/ 完了。review-self 改修で prompts/review-self/ + prompts/dispatch/ + lib/references/ が追加される
- **D223 Builder 廃止**: 試験中 — review-self 改修後の `/sdd-review-self` 実行で確定を兼ねる

### Key Decisions
**Continuing from previous sessions:**
- D2: 本リポは spec/steering/roadmap 不使用
- D10: SubAgent dispatch はデフォルト background
- D121: Lead は Auditor の監修役
- D197: Level chain 設計 L1-L7+L0
- D202: Session persistence restructure
- D214: sdd-log スキル
- D220: NL trigger 廃止 + 全記録パスを /sdd-log 経由に統一
- D223: sdd-review-self Builder 廃止 → Lead 直接修正 (試験中)
- D226: I33 初期判断 — .sdd/ 階層再設計で lib/ 導入

**Added this session:**
- D227: sdd-review-self 改修計画 — 7項目の設計決定を包括 (Engine Dispatch 共有化、Briefer SubAgent 降格、references/ lib/ 移動、変数廃止、compliance キャッシュ廃止、Briefer 簡素化、lib/references/ コピー対応)

**Superseded this session:**
- D222: references/ 自己完結化 → D227 の lib/ 移動で置換
- D224: Briefer 埋め込み配布 → D227 のパス参照方式で置換

### Warnings
- **プランファイルは `.claude/plans/splendid-growing-snowglobe.md`**: 全設計詳細がここにある。Appendix にも全文転記済み
- **lib/ マイグレーションは段階的**: 本改修で prompts/review-self/, prompts/dispatch/, lib/references/ が追加されるが、settings/ 配下の scripts, rules, templates, profiles は未移行 (I33)
- **lib/references/ のファイルはコピーで対応**: bash-security-heuristics.md と skill-reference.md は旧場所にも残す。旧ファイルの削除は I33 で一括実施
- **D223 は試験中**: 改修後の `/sdd-review-self` 実行で Lead Fix (Step 8) が動作することを確認して確定
- **SKILL.md.bak1 はまだ削除しない**: 修正確定後に削除する方針を維持
- **I36 は議論の結果「問題消滅」**: 変数廃止 + briefer-header.md 廃止により、ラベル/変数名不一致の問題自体がなくなった

## Session Context

### Tone and Nuance
- ユーザーは設計議論を重視する。選択肢を提示する前に十分な議論・分析を行うこと
- AskUserQuestion は入力しづらいため、テキストベースの議論を優先し、最終確認のみ AskUserQuestion を使う

### Steering Exceptions
なし

## Accomplished

### Work Summary (this session)
1. **sdd-review-self 改修の設計計画を完成**: 5論点について議論し、7項目の設計決定を包括する D227 を記録。プランファイル作成済み
2. **Engine Dispatch 共有ライブラリ設計**: `.sdd/lib/prompts/dispatch/engine.md` に resolve + commands + dispatch modes + escalation を 1 ファイル自己完結で抽出する設計。正常系/異常系の分離点、汎用 dispatcher vs 用途特化の議論を経て確定
3. **Briefer 設計の根本見直し**: 変数依存問題の分析から、(a) 全パスハードコード化、(b) Briefer SubAgent 降格、(c) 埋め込み廃止→パス参照、(d) Inspector コピー全廃 の 4 つの簡素化を導出
4. **references/ → lib/ 移動の設計**: ${CLAUDE_SKILL_DIR} が外部エンジンで解決できない問題を起点に、全ファイルを .sdd/lib/prompts/review-self/ に移動して固定パス化する設計
5. **compliance キャッシュ廃止**: 有効に動作していなかったキャッシュ機構を廃止し、.sdd/lib/references/ のリファレンス直読みに変更
6. **D222/D224 を superseded**: lib/ 移動とパス参照方式で置換
7. **I41/I42 新規登録**: sdd-review 改修、Command Dispatch 汎用プロンプト作成

### Previous Sessions (carry forward)
- v2.6.0 (session 15): I40 リサーチ + sdd-log Read-inline 化 + .sdd/lib/ 導入 + sdd-handover 改修
- v2.6.0 (session 14): B46 テスト実行 + codex/SKILL.md 問題検出 + Skill ネスト停止問題再発
- v2.6.0 (session 13): I28 修正実装 (7項目) + D223 Builder 廃止 + D224 ヒューリスティクス配布
- v2.6.0 (session 12): I30/I31 修正 + 前セッション文脈復元
- v2.6.0 (session 11): NL trigger 統一 (D220) + sdd-review-self reforge + Diff Analysis

### Modified Files
- `.sdd/session/decisions.yaml` — D227 追加, D222/D224 superseded + archived
- `.sdd/session/issues.yaml` — I41/I42 追加
- `.claude/plans/splendid-growing-snowglobe.md` — 改修計画プランファイル (新規)

## Open Issues
| ID | Sev | Type | Summary |
|----|-----|------|---------|
| **I34** | **H** | BUG | codex CLI `-q` フラグ拒否 — エンジンコマンドテンプレート不一致 |
| **I28** | **H** | BUG | sdd-review-self reforge: Lead Read 設計退化 (実装済み、resolve 待ち) |
| I27 | M | ENH | sdd-review-self reforge — エンジン仕様記述精度 (D225 で解決判断、resolve 待ち) |
| I29 | M | ENH | jq 可用性チェックを sdd-start に移動 |
| I32 | M | BUG | sdd-start がセキュリティヒューリスティクスを踏む |
| I33 | M | ENH | .sdd/settings/ 階層再設計 (D226 で初期判断、lib/ 段階的移行中) |
| I35 | M | BUG | pane タイトル未設定デグレ |
| I36 | M | ENH | briefer-header ラベル/変数名不一致 (D227 で問題消滅 — resolve 待ち) |
| I37 | M | ENH | hold-and-release 構造未記載 |
| I39 | M | FEAT | knowledge システム拡張 (索引化+ポインタ) |
| I41 | M | ENH | sdd-review を dispatch/engine.md 参照に改修 |
| I42 | M | FEAT | Command Dispatch 汎用プロンプト作成 |
| I18 | M | ENH | session データの SQLite 化検討 |
| I38 | L | ENH | close channel タイミング暗黙性 |
| I10 | L | ENH | ConventionsScanner が issues.yaml を参照しない |

## Resume Instructions
1. `/sdd-start` でセッション開始
2. プランファイル `.claude/plans/splendid-growing-snowglobe.md` を Read し、実行順序に従って実装を開始
3. 実装完了後 `bash install.sh --local --force` で同期
4. `/sdd-review-self` を実行して動作確認 (D223 Builder 廃止の確定を兼ねる)

---

## Appendix — Current Plan

以下は `.claude/plans/splendid-growing-snowglobe.md` の全文転記。次セッションの Lead はこの計画に従って実装する。

# sdd-review-self 改修計画

## Context

sdd-review-self SKILL.md (249行) の 3つの問題を解決する:
1. **Skill ネスト bug (K24)**: 4箇所の `/sdd-log` Skill 呼び出しが親停止リスク
2. **Issue 5件** (I34/I35/I37/I38 + I28 resolve): B46 で検出された不具合・曖昧さ
3. **エンジンロジック重複 + Briefer 設計問題**: 変数依存、不要なコピー処理、コンテキスト埋め込み

## 設計方針 (議論で合意済み)

- **自己完結 > DRY**: sdd-log パターンに倣い、重複を受け入れて単体で成立するプロンプト
- **Engine Dispatch は 1 ファイルに密結合**: resolve + commands + dispatch modes + escalation
- **prompt に変数を持たない**: パスはハードコード。動的値はパス参照に変更
- **Briefer を SubAgent に降格**: 外部エンジンではなく Agent tool (Sonnet, run_in_background)
- **tmux-integration.md は触らない**
- **sdd-start はスコープ外**
- **sdd-review への適用は issue 登録のみ**
- **lib/references/ のファイルはコピーで対応**: 旧ファイルは残す。I33 で削除

## 改修スコープ

### A. Read-inline化 (I40 Phase 2) — `/sdd-log` 4箇所

既存の `.sdd/lib/prompts/log/{record,flush}.md` を Read して inline 実行に変更。

| 箇所 | 現在 | 変更後 |
|------|------|--------|
| L118 (Step 5 Runtime Escalation) | `/sdd-log issue` | Read `.sdd/lib/prompts/log/record.md`, type=issue |
| L186 (Step 7 Deferred Items) | `/sdd-log issue` | Read `.sdd/lib/prompts/log/record.md`, type=issue |
| L238 (Step 9 Deferred Items) | `/sdd-log issue` | Read `.sdd/lib/prompts/log/record.md`, type=issue |
| L242 (Step 9 Auto-Draft) | `/sdd-log flush` | Read `.sdd/lib/prompts/log/flush.md` |

L242 以降の handover 更新手順 (carry forward, update next action 等) は SKILL.md にそのまま残す。

### B. Issue 修正

| Issue | 変更内容 |
|-------|---------|
| **I34** (H) | codex コマンドから `-q` 削除、末尾に `-` 追加 → dispatch/engine.md に反映 |
| **I35** (M) | Inspector tmux dispatch 前に `tmux select-pane -T` → dispatch/engine.md の tmux mode に含む |
| **I37** (M) | hold-and-release コマンドチェーンの具体例 → dispatch/engine.md の並列 dispatch に含む |
| **I38** (L) | Inspector Completion に「全 wait-for 完了確認後」の前提明記 → SKILL.md |
| **I36** | 問題消滅 (変数廃止により briefer-header.md 自体が不要に) |

### C. Engine Dispatch 共有プロンプト — `.sdd/lib/prompts/dispatch/engine.md`

1ファイル自己完結 (~120行)。sdd-review-self と sdd-review で共有。

```
[1. Engine Resolution]
  engines.yaml lookup
  argument override → sticky (state.yaml) → start_level
  install_check + インフラエスカレーション → L0
  sticky 永続化、timeout 解決

[2. Command Construction]
  codex: npx -y @openai/codex exec --full-auto -m {model} -c ... -
  claude: env -u CLAUDECODE claude -p - --model {model} ... | jq ...
  gemini: npx -y @google/gemini-cli -p --model {model} --yolo
  subagents: model mapping (spark/haiku→haiku, opus→opus, other→sonnet)
  effort 注入

[3. Dispatch Modes]
  SubAgent: Agent(run_in_background=true) + Read 指示
  tmux: slot 割当 → pane タイトル設定 → send-keys + wait-for → slot idle 復帰
  background: Bash(run_in_background=true)
  並列: staggered (0.5s) + hold-and-release (チェーン例付き)

[4. Runtime Escalation]
  障害分類: ENGINE_FAILURE vs LEVEL_FAILURE
  エスカレーション先: codex→claude L5, claude→L0
  issue 記録: Read .sdd/lib/prompts/log/record.md, type=issue
```

Skill 側は ROLE_NAME, STAGES, DEFAULT_TIMEOUT を指定してから dispatch/engine.md に従う。

### D. Briefer SubAgent 降格 + references/ → lib/ 移動

**Briefer を外部エンジンから組み込み SubAgent に変更:**
- Agent tool, model: sonnet, run_in_background: true
- Lead は briefer.md を Read しない — SubAgent に `Read .sdd/lib/prompts/review-self/briefer.md and follow its instructions` と指示
- Lead のコンテキスト保全を維持

**briefer-header.md 廃止:**
- パスが全てハードコード化されるため不要

**references/ 全ファイルを lib/ に移動:**

| 現在 (references/) | 移動先 (.sdd/lib/prompts/review-self/) |
|--------------------|-----------------------------------------|
| briefer.md | prompts/review-self/briefer.md |
| auditor.md | prompts/review-self/auditor.md |
| inspector-flow.md | prompts/review-self/inspector-flow.md |
| inspector-consistency.md | prompts/review-self/inspector-consistency.md |
| inspector-compliance.md | prompts/review-self/inspector-compliance.md |
| shared-prompt-structure.md | prompts/review-self/shared-prompt-structure.md |

→ references/ ディレクトリは空になり廃止。

### E. Briefer 簡素化

**廃止するステップ:**
- Step 3 (deny_patterns 読み込み埋め込み) → Inspector が engines.yaml を直接参照
- Step 3b (HEURISTICS_CONTENT 読み込み埋め込み) → Inspector がパス参照で直読み
- Step 5 (compliance cache) → 廃止。compliance は lib/references/ を直読み
- Step 6 (固定 Inspector テンプレートコピー) → 全廃。Inspector は lib/ から直接読む

**残るステップ:**
- Step 1: git diff 収集 + FOCUS_TARGETS 生成
- Step 2: ファイル一覧収集
- Step 4: shared-prompt.md 生成 (FILE_LIST + パス参照のみ)
- Step 7: 動的 Inspector プロンプト生成 (diff 分析ベース)
- Step 8: manifest + 検証

**shared-prompt.md の変更:**
- `{HEURISTICS_CONTENT}` 埋め込み → `Read .sdd/lib/references/bash-security-heuristics.md` パス参照
- `{deny_patterns}` 埋め込み → `Read .sdd/settings/engines.yaml deny_patterns section` パス参照
- `{FILE_LIST}` → 動的生成のまま (Briefer が glob で収集)

**Inspector dispatch の変更:**
```
現在: cat active/shared-prompt.md active/inspector-{name}.md | engine_cmd
変更: cat active/shared-prompt.md .sdd/lib/prompts/review-self/inspector-{name}.md | engine_cmd
```

**inspector-compliance.md の変更:**
- `{{CACHED_OK}}` セクション削除
- 代わりにリファレンス直読み指示をハードコード:
  ```
  ## Reference Documents
  Read for compliance context:
  - .sdd/lib/references/bash-security-heuristics.md
  - .sdd/lib/references/skill-reference.md
  ```

### F. lib/references/ 作成

| ファイル | コピー元 | 備考 |
|---------|---------|------|
| `.sdd/lib/references/bash-security-heuristics.md` | `.sdd/settings/rules/lead/bash-security-heuristics.md` | コピー。旧ファイルは I33 で削除 |
| `.sdd/lib/references/skill-reference.md` | `framework/claude/skills/sdd-forge-skill/references/skill-reference.md` | コピー。forge-skill 側は I33 で参照先変更 |

### G. 付随変更

- **allowed-tools**: `Skill` を削除 (Read-inline化で不要)
- **I28 resolve**: issues.yaml status → resolved
- **I27 resolve**: D225 で解決判断済み → issues.yaml status → resolved
- **I36 resolve**: 問題消滅 → issues.yaml status → resolved

## ファイル変更一覧

### 新規作成 (framework/ 配下)
| ファイル | 内容 |
|---------|------|
| `framework/claude/sdd/lib/prompts/dispatch/engine.md` | Engine Dispatch 手順 (自己完結) |
| `framework/claude/sdd/lib/prompts/review-self/briefer.md` | Briefer 指示書 (references/ から移動) |
| `framework/claude/sdd/lib/prompts/review-self/auditor.md` | Auditor 指示書 (references/ から移動) |
| `framework/claude/sdd/lib/prompts/review-self/inspector-flow.md` | (references/ から移動) |
| `framework/claude/sdd/lib/prompts/review-self/inspector-consistency.md` | (references/ から移動) |
| `framework/claude/sdd/lib/prompts/review-self/inspector-compliance.md` | (references/ から移動 + CACHED_OK 廃止 + references 直読み) |
| `framework/claude/sdd/lib/prompts/review-self/shared-prompt-structure.md` | (references/ から移動 + 変数廃止) |
| `framework/claude/sdd/lib/references/bash-security-heuristics.md` | コピー |
| `framework/claude/sdd/lib/references/skill-reference.md` | コピー |

### 削除
| ファイル | 理由 |
|---------|------|
| `framework/claude/skills/sdd-review-self/references/` | 全ファイル lib/ に移動済み。ディレクトリ廃止 |

### 編集
| ファイル | 変更内容 |
|---------|---------|
| `framework/claude/skills/sdd-review-self/SKILL.md` | A〜G 全変更適用 |

### 変更なし (参照のみ)
| ファイル | 理由 |
|---------|------|
| `.sdd/lib/prompts/log/record.md` | 既存 — Read-inline 参照先 |
| `.sdd/lib/prompts/log/flush.md` | 既存 — Read-inline 参照先 |
| `.sdd/settings/engines.yaml` | データソース |
| `.sdd/settings/rules/lead/bash-security-heuristics.md` | コピー元 (I33 まで残存) |
| `framework/claude/skills/sdd-forge-skill/references/skill-reference.md` | コピー元 (I33 まで残存) |

### 後続作業 (issue 登録)
- sdd-review を dispatch/engine.md 参照 + 同様のリファクタリングに改修
- Command Dispatch (汎用 tmux pane 実行) プロンプト作成
- I33: lib/ マイグレーション完了時に旧ファイル削除 + 参照更新

## 実行順序

1. lib/references/ にファイルをコピー
2. lib/prompts/dispatch/engine.md 新規作成
3. lib/prompts/review-self/ に references/ からファイルを移動 + 修正 (compliance, shared-prompt-structure, briefer)
4. SKILL.md 編集 (上から順に全変更適用)
5. references/ ディレクトリ削除
6. `bash install.sh --local --force`
7. 検証
8. issue 更新 (I28/I27/I34/I35/I36/I37/I38 resolved)
9. 後続 issue 登録

## 検証方法

1. `bash install.sh --local --force` 成功確認
2. `.sdd/lib/prompts/dispatch/engine.md` 存在確認
3. `.sdd/lib/prompts/review-self/` に 6ファイル存在確認
4. `.sdd/lib/references/` に 2ファイル存在確認
5. `framework/claude/skills/sdd-review-self/references/` が存在しないことを確認
6. SKILL.md 内に `/sdd-log` Skill 呼び出しが残っていないことを Grep
7. SKILL.md の allowed-tools に `Skill` が残っていないことを確認
8. `/sdd-review-self` を実行して動作確認 (D223 Builder 廃止の確定を兼ねる)
