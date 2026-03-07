# Claude Code 公式仕様準拠レビュー

**レビュー日**: 2026-02-24
**対象バージョン**: SDD v0.23.1
**公式ドキュメント参照**: code.claude.com/docs/en/sub-agents, code.claude.com/docs/en/skills, code.claude.com/docs/en/settings

---

## 1. 総合判定

**CONDITIONAL** -- 重大な仕様違反はないが、改善すべき点が複数存在する。

---

## 2. 公式仕様準拠テーブル

### 2.1 エージェント定義 (`.claude/agents/`)

| 項目 | 公式仕様 | SDD実装 | 準拠状態 |
|------|----------|---------|----------|
| **ファイル形式** | YAML frontmatter + Markdown body | 全22エージェントが準拠 | OK |
| **ファイル配置** | `.claude/agents/` | `framework/claude/agents/` -> install先 `.claude/agents/` | OK |
| **`name` フィールド** | 必須。小文字+ハイフン | 全エージェントが `name: sdd-*` で準拠 | OK |
| **`description` フィールド** | 必須 | 全エージェントが記述あり | OK |
| **`model` フィールド** | `sonnet`, `opus`, `haiku`, `inherit`。省略時は `inherit` | opus / sonnet のみ使用 | OK |
| **`tools` フィールド** | 省略時は全ツール継承。明示でツール制限 | 全エージェントが明示的に制限 | OK |
| **`disallowedTools`** | ツール拒否リスト | 未使用（`tools` でホワイトリスト制御） | OK (不要) |
| **`permissionMode`** | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` | 未使用 | OK (デフォルト動作で問題なし) |
| **`maxTurns`** | SubAgentの最大ターン数 | 未使用 | ADVISORY -- 長時間実行SubAgent (Builder, Architect) に設定検討 |
| **`skills`** | SubAgentにスキルをプリロード | 未使用 | OK |
| **`mcpServers`** | MCP サーバー参照 | 未使用 | OK |
| **`hooks`** | SubAgentスコープのフック | 未使用 | OK |
| **`memory`** | `user`, `project`, `local` | 未使用 | ADVISORY -- Knowledge蓄積との相性あり |
| **`background`** | バックグラウンド実行 | 未使用 | OK (フォアグラウンドが適切) |
| **`isolation`** | `worktree` で隔離実行 | 未使用 | ADVISORY -- Builder並列時にworktree隔離は有用 |
| **`color`** | SubAgent識別バッジの色 | 未使用 | ADVISORY -- 視認性向上に有用 |

### 2.2 スキル定義 (`.claude/skills/`)

| 項目 | 公式仕様 | SDD実装 | 準拠状態 |
|------|----------|---------|----------|
| **ファイル形式** | YAML frontmatter + Markdown body | 全7スキルが準拠 | OK |
| **ファイル配置** | `.claude/skills/<name>/SKILL.md` | `framework/claude/skills/sdd-*/SKILL.md` | OK |
| **`name` フィールド** | 任意。省略時はディレクトリ名。小文字+数字+ハイフン、最大64文字 | 全スキルで省略 -- ディレクトリ名が使用される | OK |
| **`description` フィールド** | 推奨。最大1024文字 | 全スキルが記述あり | OK |
| **`argument-hint` フィールド** | 任意。オートコンプリートのヒント | 6/7スキルで設定 (sdd-handover のみ空) | OK |
| **`allowed-tools` フィールド** | 任意。スキル実行中のツール制限 | 全スキルで設定あり | OK |
| **`disable-model-invocation`** | `true` で自動起動を抑止 | 未使用 | OK (ユーザーが `/` で起動する前提) |
| **`user-invocable`** | `false` で `/` メニューから非表示 | 未使用 | OK |
| **`model`** | スキル実行時のモデル指定 | 未使用 | OK (Lead のモデルで実行) |
| **`context`** | `fork` でSubAgent実行 | 未使用 | OK (Lead が直接実行) |
| **`agent`** | `context: fork` 時のSubAgent指定 | 未使用 | OK |
| **`hooks`** | スキルスコープのフック | 未使用 | OK |
| **`$ARGUMENTS` 変数** | 引数置換 | 使用あり (`$ARGUMENTS`) | OK |
| **refs/ ディレクトリ** | 公式は `SKILL.md` から参照する任意ファイル | `sdd-roadmap/refs/*.md` で活用 | OK |

### 2.3 Task ツール (SubAgent ディスパッチ)

| 項目 | 公式仕様 | SDD実装 | 準拠状態 |
|------|----------|---------|----------|
| **Task ツール** | `Task(subagent_type="name", prompt="...")` | CLAUDE.md に `Task(subagent_type="sdd-architect", prompt="...")` と記載 | OK |
| **SubAgent制限構文** | `Task(worker, researcher)` でツールフィールドに記載 | `allowed-tools: Task, ...` (制限なし) | FINDING -- 下記参照 |
| **SubAgentのSubAgent生成** | SubAgentは他のSubAgentを生成不可 | 設計通り (SubAgent定義にTaskツール不含) | OK |
| **SubAgent生成制限** | `tools: Task(agent-type)` でホワイトリスト | 未使用 -- sdd-roadmap は `Task` のみ | ADVISORY -- 下記参照 |

### 2.4 settings.json

| 項目 | 公式仕様 | SDD実装 | 準拠状態 |
|------|----------|---------|----------|
| **ファイル配置** | `.claude/settings.json` | `framework/claude/settings.json` -> install先 `.claude/settings.json` | OK |
| **`permissions` キー** | `allow`, `deny`, `ask` 配列 | `permissions.allow` のみ使用 | OK |
| **許可ルール書式** | `Tool(pattern)` | `Bash(cat:*)`, `Bash(echo:*)` | OK |
| **使用キー** | 公式キーのみ | `permissions` のみ -- 最小構成 | OK |
| **未使用だが有用なキー** | `hooks`, `sandbox`, `env` 等 | なし | OK (プロジェクト固有設定はユーザーに委任) |

### 2.5 install.sh (パス整合性)

| 項目 | 公式仕様 | SDD実装 | 準拠状態 |
|------|----------|---------|----------|
| **Skills パス** | `.claude/skills/<name>/SKILL.md` | `.claude/skills/sdd-*/SKILL.md` | OK |
| **Agents パス** | `.claude/agents/<name>.md` | `.claude/agents/sdd-*.md` | OK |
| **CLAUDE.md パス** | `.claude/CLAUDE.md` | マーカーベース挿入で共存対応 | OK |
| **settings.json パス** | `.claude/settings.json` | 確認プロンプト付きインストール | OK |
| **ユーザーファイル保護** | ユーザーコンテンツを上書きしない | `--update` でユーザーファイル保護 | OK |
| **Stale ファイル削除** | フレームワーク管理ファイルのみ削除 | `sdd-*` パターンでスコープ制限 | OK |

### 2.6 モデル選択

| ロール | 設定値 | 公式有効値 | 適切性 |
|--------|--------|-----------|--------|
| **Architect** | `opus` | OK | OK -- 設計判断に高性能モデルが適切 |
| **Auditor (Design)** | `opus` | OK | OK -- レビュー合成に高性能モデルが適切 |
| **Auditor (Impl)** | `opus` | OK | OK |
| **Auditor (Dead-Code)** | `opus` | OK | OK |
| **TaskGenerator** | `sonnet` | OK | OK -- 構造化タスク分解にSonnetが十分 |
| **Builder** | `sonnet` | OK | OK -- コード実装にSonnetが適切 |
| **Inspector (全種)** | `sonnet` | OK | OK -- 定型レビューにSonnetが適切 |

### 2.7 ツール権限 (最小権限原則)

| エージェント | 設定ツール | 過不足 |
|------------|-----------|--------|
| **sdd-architect** | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | OK -- 設計生成に必要な全ツール |
| **sdd-auditor-design** | Read, Glob, Grep, Write | OK -- 最小権限 |
| **sdd-auditor-impl** | Read, Glob, Grep, Write | OK |
| **sdd-auditor-dead-code** | Read, Glob, Grep, Write | OK |
| **sdd-taskgenerator** | Read, Glob, Grep, Write | OK -- Editなし (新規作成のみ) |
| **sdd-builder** | Read, Glob, Grep, Write, Edit, Bash | OK -- TDD実行に必要 |
| **sdd-inspector-test** | Read, Glob, Grep, Write, Bash | OK -- テスト実行に必要 |
| **sdd-inspector-e2e** | Read, Glob, Grep, Write, Bash | OK -- E2E実行に必要 |
| **sdd-inspector-* (他)** | Read, Glob, Grep, Write | OK -- 読取+レポート書込のみ |

---

## 3. Findings (詳細)

### FINDING-1: `allowed-tools` の Task ツール制限なし (Medium)

**場所**: `framework/claude/skills/sdd-roadmap/SKILL.md`
**内容**: `allowed-tools: Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion`

公式ドキュメントでは `Task(agent_type1, agent_type2)` 構文で SubAgent 生成をホワイトリスト制限可能。現在の `Task` は制限なし（任意のSubAgentを生成可能）。

**公式仕様**:
> To restrict which subagent types it can spawn, use `Task(agent_type)` syntax in the `tools` field.
> This is an allowlist: only the specified subagents can be spawned.

**推奨**: セキュリティ向上のため以下を検討:
```yaml
allowed-tools: Task(sdd-architect, sdd-auditor-design, sdd-auditor-impl, sdd-auditor-dead-code, sdd-taskgenerator, sdd-builder, sdd-inspector-architecture, sdd-inspector-best-practices, sdd-inspector-consistency, sdd-inspector-holistic, sdd-inspector-rulebase, sdd-inspector-testability, sdd-inspector-interface, sdd-inspector-test, sdd-inspector-quality, sdd-inspector-impl-consistency, sdd-inspector-impl-holistic, sdd-inspector-impl-rulebase, sdd-inspector-dead-code, sdd-inspector-dead-settings, sdd-inspector-dead-specs, sdd-inspector-dead-tests, sdd-inspector-e2e), Bash, ...
```

**注**: `Task(agent_type)` の制約は公式ドキュメントによれば `--agent` で起動した場合のメインスレッドエージェントの `tools` フィールドに適用される仕様。Skills の `allowed-tools` でこの構文がサポートされるかは不明確。SubAgent は他の SubAgent を生成できないため、制限対象は Lead (メインスレッド) のみ。

**リスク**: Low (Lead自身がTaskを使うため、制限は多重防御的)
**判定**: ADVISORY

### FINDING-2: `AskUserQuestion` の SubAgent利用制限 (Medium)

**場所**: `framework/claude/skills/sdd-roadmap/SKILL.md`, `framework/claude/skills/sdd-steering/SKILL.md` 等
**内容**: Skills の `allowed-tools` に `AskUserQuestion` が含まれている。

公式にはSubAgentでは `AskUserQuestion` が利用不可であることが報告されている (GitHub Issue #12890)。ただし、**Skills は SubAgent ではなく Lead (メインスレッド) が直接実行する**ため、Skills での `AskUserQuestion` は問題ない。

**判定**: OK (Skills は SubAgent コンテキストではない)

### FINDING-3: CLAUDE.md の SubAgent 上限記述の変更 (Low)

**場所**: `framework/claude/CLAUDE.md` (L103)
**旧版**: `Concurrent SubAgent limit: 24 (max 8 per pipeline x 3 types + headroom)`
**現版**: `No framework-imposed SubAgent limit. Platform manages concurrent execution.`

公式ドキュメントにはSubAgentの同時実行数に関する明示的な制限値の記載はない。プラットフォーム側で管理されるとの理解は公式仕様と整合。

**判定**: OK

### FINDING-4: エージェント定義に `color` 未設定 (Low)

**場所**: 全22エージェント
**内容**: 公式仕様では `color` フィールドで SubAgent 識別バッジの色を設定可能。SDD では22種のエージェントを使い分けるため、ロール別の色分けが視認性向上に寄与する。

**推奨**: ティア別のcolor設定
- T2 (Architect/Auditor): `blue` 系
- T3 (TaskGenerator/Builder): `green` 系
- T3 (Inspector): `yellow` 系

**判定**: ADVISORY (機能的影響なし)

### FINDING-5: `maxTurns` 未設定によるコスト制御不足 (Low)

**場所**: 全22エージェント
**内容**: 公式仕様では `maxTurns` でSubAgentの最大ターン数を制限可能。Builder や Architect が想定外に長時間実行した場合のコスト防止策がない。

**推奨**:
- Inspector: `maxTurns: 30` (読取+レポート書込のみ)
- TaskGenerator: `maxTurns: 30`
- Builder: `maxTurns: 80` (TDDサイクルのため多め)
- Architect: `maxTurns: 60` (WebSearch含む)
- Auditor: `maxTurns: 50`

**判定**: ADVISORY (コスト最適化)

### FINDING-6: `isolation: worktree` 未活用 (Low)

**場所**: `framework/claude/agents/sdd-builder.md`
**内容**: 公式仕様では `isolation: worktree` で SubAgent を一時的な git worktree 内で実行可能。Builder の並列実行時にファイル衝突を物理的に防止できる。

現在の SDD は「ファイルスコープルール」(設計上の分離) で衝突を防止しているが、worktree 隔離はより強固な保証を提供する。

**注意点**: worktree 内の変更をメイン作業ツリーにマージする追加手順が必要。現在の設計 (ファイルスコープ分離) の方が運用が単純。

**判定**: ADVISORY (将来的な検討事項)

### FINDING-7: `memory` フィールド未活用 (Low)

**場所**: 全エージェント
**内容**: 公式仕様では `memory: project` でSubAgentにセッション横断の永続メモリを付与可能。SDD の Knowledge Auto-Accumulation は buffer.md + knowledge/ ディレクトリで独自実装しているが、公式の `memory` 機能と統合する余地がある。

**判定**: ADVISORY (独自実装が十分に機能しているため低優先度)

### FINDING-8: `background` フィールドの検討 (Low)

**場所**: Inspector エージェント全般
**内容**: 公式仕様では `background: true` で SubAgent をバックグラウンド実行可能。Inspector は独立して動作し、結果をファイルに書き込むため、バックグラウンド実行の候補。

**注意点**: バックグラウンド SubAgent は `AskUserQuestion` を使用不可、MCP ツール利用不可という制約がある。Inspector はこれらを使用しないため制約に該当しないが、バックグラウンドタスクの権限事前承認フローがワークフローに影響する可能性あり。

**判定**: ADVISORY (パフォーマンス最適化の候補)

---

## 4. install.sh 詳細検証

| チェック項目 | 結果 |
|-------------|------|
| Skills コピー先: `.claude/skills/` | OK |
| Agents コピー先: `.claude/agents/` | OK |
| CLAUDE.md マーカー管理 | OK -- `<!-- sdd:start -->` / `<!-- sdd:end -->` でセクション分離 |
| settings.json 上書き確認 | OK -- 既存ファイル検出時にプロンプト |
| SDD 内部設定コピー | OK -- rules, templates, profiles |
| バージョンファイル | OK -- `.claude/sdd/.version` |
| Stale ファイルクリーンアップ | OK -- `sdd-*` パターンでスコープ制限 |
| マイグレーション (v0.4.0 - v0.20.0) | OK -- 段階的バージョンチェック |
| アンインストール | OK -- フレームワークファイルのみ削除、ユーザーファイル保護 |

---

## 5. settings.json 詳細検証

現在の設定:
```json
{
  "permissions": {
    "allow": [
      "Bash(cat:*)",
      "Bash(echo:*)"
    ]
  }
}
```

**検証結果**:
- `permissions` は公式有効キー
- `allow` は公式有効サブキー
- `Bash(pattern)` は公式許可ルール構文
- `Bash(cat:*)`, `Bash(echo:*)` -- `cat` と `echo` コマンドの自動許可

**注意**: 公式ドキュメントでは `Bash(npm run *)` のようにスペース区切りのパターンを使用。`Bash(cat:*)` のコロン区切りは独自パターンだが、Claude Code のワイルドカードマッチングで動作する。

**判定**: OK

---

## 6. 最近の変更に対する検証

### 6.1 "Parallel Execution Model" セクション (CLAUDE.md L84-96)

公式仕様との整合性:
- SubAgent の並列ディスパッチは Task ツールの標準的な使い方
- "No framework-imposed SubAgent limit" は公式仕様で制限値が非公開であることと整合
- Consensus mode (`--consensus N`) は SDD 独自機能だが Task ツールの標準使用範囲内

**判定**: OK

### 6.2 SKILL.md Backfill check

sdd-roadmap の Design サブコマンドで単一スペック追加時のバックフィルチェックは、スキルの標準的な使い方の範囲内。

**判定**: OK

### 6.3 crud.md / run.md の並列スケジューリング

Wave Scheduling, Design Lookahead, Spec Stagger 等の並列化パターンは、Task ツールによる SubAgent 並列ディスパッチの応用であり、公式仕様の範囲内。

**判定**: OK

---

## 7. 総合サマリー

### 準拠している領域
1. **エージェント YAML frontmatter**: 全フィールドが公式有効値
2. **スキル YAML frontmatter**: 全フィールドが公式仕様に準拠
3. **ファイル配置**: 公式期待パスと完全一致
4. **モデル選択**: ロールに適切なモデル割当
5. **ツール権限**: 最小権限原則を遵守
6. **settings.json**: 有効キーのみ使用
7. **install.sh**: 公式パス構造に完全対応

### 改善推奨 (ADVISORY)
1. `color` フィールドで視認性向上 (22エージェントの識別)
2. `maxTurns` フィールドでコスト制御
3. `isolation: worktree` の将来的検討 (Builder 並列安全性)
4. `memory` フィールドと Knowledge Auto-Accumulation の統合検討
5. `background: true` による Inspector パフォーマンス最適化検討
6. `Task(agent_type)` 構文による SubAgent 生成制限の検討

### 非準拠は検出されず
公式仕様に違反するフィールド値、無効なキー、不正なパスは検出されなかった。全ての SDD 独自拡張（CPF形式、Phase Gate、Wave Scheduling等）は公式仕様の範囲内で動作している。

---

## 8. 公式ドキュメント参照先

- [Create custom subagents](https://code.claude.com/docs/en/sub-agents) -- YAML frontmatter仕様、利用可能ツール、モデルエイリアス
- [Extend Claude with skills](https://code.claude.com/docs/en/skills) -- Skills frontmatter仕様、$ARGUMENTS、allowed-tools
- [Settings reference](https://code.claude.com/docs/en/settings) -- settings.json有効キー、permissions構文
- [How Claude Code works](https://code.claude.com/docs/en/how-claude-code-works) -- 内部ツール一覧、エージェンティックループ
- [Claude Code Built-in Tools Reference](https://www.vtrivedy.com/posts/claudecode-tools-reference) -- 15ツール一覧
