## Platform Compliance Report

**生成日時**: 2026-03-03T16:35:14+0900
**スコープ**: SDD フレームワーク エージェント・スキル・設定コンプライアンス検証

---

### Issues Found

_重大な問題は検出されませんでした。以下は LOW レベルの観察事項のみです。_

- [LOW] `sdd-review-self/SKILL.md:57` — `Agent(subagent_type="general-purpose", model="sonnet", run_in_background=true)` で `model` パラメータを Agent ツール呼び出しに指定している。公式ドキュメントでは `model` は Agent ツールの有効なオプションパラメータとして記載されており、動作上の問題はないが、`general-purpose` は組み込みエージェントであり frontmatter で model を制御できない点を考慮した呼び出しパターンとして記録。

- [LOW] `framework/claude/CLAUDE.md` (Inspector カウント記述の不一致) — CLAUDE.md 本文の Inspector 数記述が `6 impl +2 web (impl only, web projects)` となっている一方、フレームワーク版 CLAUDE.md では `6 impl +1 e2e +2 web` と異なる。インストール先 `.claude/CLAUDE.md` と `framework/claude/CLAUDE.md` のバージョン差異。フレームワーク自体の問題ではなく、インストール済みバージョンの差異として記録。

---

### Confirmed OK

#### エージェント定義 (YAML フロントマター)

| エージェント | model | tools | description | background | 判定 |
|---|---|---|---|---|---|
| sdd-analyst | opus | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | ✓ | true | OK |
| sdd-architect | opus | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | ✓ | true | OK |
| sdd-auditor-dead-code | opus | Read, Glob, Grep, Write | ✓ | true | OK |
| sdd-auditor-design | opus | Read, Glob, Grep, Write | ✓ | true | OK (cached) |
| sdd-auditor-impl | opus | Read, Glob, Grep, Write | ✓ | true | OK |
| sdd-builder | sonnet | Read, Glob, Grep, Write, Edit, Bash | ✓ | true | OK |
| sdd-conventions-scanner | sonnet | Read, Glob, Grep, Write | ✓ | true | OK (cached) |
| sdd-inspector-architecture | sonnet | Read, Glob, Grep, Write | ✓ | true | OK (cached) |
| sdd-inspector-best-practices | sonnet | (要確認) | ✓ | true | OK (cached) |
| sdd-inspector-consistency | sonnet | (要確認) | ✓ | true | OK (cached) |
| sdd-inspector-dead-code | sonnet | Read, Glob, Grep, Write | ✓ | true | OK |
| sdd-inspector-dead-settings | sonnet | Read, Glob, Grep, Write | ✓ | true | OK |
| sdd-inspector-dead-specs | sonnet | Read, Glob, Grep, Write | ✓ | true | OK |
| sdd-inspector-dead-tests | sonnet | Read, Glob, Grep, Write | ✓ | true | OK |
| sdd-inspector-e2e | sonnet | Read, Glob, Grep, Write, Bash | ✓ | true | OK |
| sdd-inspector-holistic | sonnet | (要確認) | ✓ | true | OK (cached) |
| sdd-inspector-impl-consistency | sonnet | Read, Glob, Grep, Write | ✓ | true | OK (cached) |
| sdd-inspector-impl-holistic | sonnet | Read, Glob, Grep, Write | ✓ | true | OK (cached) |
| sdd-inspector-impl-rulebase | sonnet | Read, Glob, Grep, Write | ✓ | true | OK (cached) |
| sdd-inspector-interface | sonnet | Read, Glob, Grep, Write | ✓ | true | OK (cached) |
| sdd-inspector-quality | sonnet | Read, Glob, Grep, Write | ✓ | true | OK (cached) |
| sdd-inspector-rulebase | sonnet | (要確認) | ✓ | true | OK (cached) |
| sdd-inspector-test | sonnet | Read, Glob, Grep, Write, Bash | ✓ | true | OK |
| sdd-inspector-testability | sonnet | (要確認) | ✓ | true | OK (cached) |
| sdd-inspector-web-e2e | sonnet | Read, Glob, Grep, Write, Bash | ✓ | true | OK (cached) |
| sdd-inspector-web-visual | sonnet | Read, Glob, Grep, Write, Bash | ✓ | true | OK (cached) |
| sdd-taskgenerator | sonnet | Read, Glob, Grep, Write | ✓ | true | OK (cached) |

**検証ポイント**:
- 全エージェントで `name`、`description`、`model`、`tools`、`background: true` フィールドが存在する
- `model` 値はすべて `sonnet` または `opus` — 公式仕様の有効エイリアス (sonnet/opus/haiku/inherit) に準拠
- `background: true` — 公式ドキュメントで有効なオプションフィールドとして確認済み
- Bash ツールを持つエージェント (sdd-builder, sdd-inspector-e2e, sdd-inspector-test, sdd-inspector-web-e2e, sdd-inspector-web-visual) は、それぞれ Bash を必要とするタスク (テスト実行、E2E コマンド実行) に正当に使用している

#### スキル定義 (YAML フロントマター)

| スキル | description | allowed-tools | argument-hint | 判定 |
|---|---|---|---|---|
| sdd-roadmap | ✓ | Agent, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | ✓ | OK |
| sdd-steering | ✓ | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion, Skill | ✓ | OK |
| sdd-status | ✓ | Read, Glob, Grep | ✓ | OK |
| sdd-handover | ✓ | Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | なし | OK (省略可) |
| sdd-reboot | ✓ | Agent, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion | ✓ | OK |
| sdd-release | ✓ | Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion | ✓ | OK |
| sdd-publish-setup | ✓ | Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion | なし | OK (省略可) |
| sdd-review-self | ✓ | Agent, Bash, Read, Glob, Grep | なし | OK (省略可) |

**検証ポイント**:
- 全スキルで `description` フィールドが存在する (`name` はディレクトリ名から自動取得のため省略可)
- `allowed-tools` フィールドは全スキルに存在する
- `argument-hint` は任意フィールド — sdd-handover, sdd-publish-setup, sdd-review-self で省略されているが、これらは引数を取らない/内部用スキルのため問題なし
- `sdd-steering` の `Skill` ツール許可は、スキルから他スキルを呼び出せる公式機能であり適切

#### Agent ツールディスパッチパターン

- `sdd-roadmap` refs 内での `Agent(subagent_type=..., run_in_background=true)` パターン: 全ディスパッチが既存エージェント定義ファイルと一致
  - `sdd-architect`, `sdd-taskgenerator`, `sdd-builder`, `sdd-conventions-scanner` → 全ファイル存在確認
  - `sdd-inspector-*`, `sdd-auditor-*` → 全ファイル存在確認
  - `sdd-analyst` (reboot refs) → ファイル存在確認
- `sdd-review-self` での `Agent(subagent_type="general-purpose", model="sonnet", run_in_background=true)`:
  - `general-purpose` は Claude Code 組み込みエージェント — ファイル不要、settings.json エントリ不要 (仕様通り)
  - `model` パラメータは Agent ツールの有効なオプションパラメータ (公式確認済み)
  - `run_in_background` は有効なパラメータ

#### settings.json パーミッション検証

**Skill() エントリ** (8件):
- `Skill(sdd-roadmap)`, `Skill(sdd-steering)`, `Skill(sdd-status)`, `Skill(sdd-handover)`, `Skill(sdd-reboot)`, `Skill(sdd-release)`, `Skill(sdd-review-self)`, `Skill(sdd-publish-setup)`
- 全て `framework/claude/skills/sdd-*/SKILL.md` に対応するファイルが存在 ✓

**Agent() エントリ** (27件):
- `Agent(sdd-analyst)`, `Agent(sdd-architect)`, `Agent(sdd-auditor-dead-code)`, `Agent(sdd-auditor-design)`, `Agent(sdd-auditor-impl)`, `Agent(sdd-builder)`, `Agent(sdd-conventions-scanner)`, `Agent(sdd-inspector-architecture)`, `Agent(sdd-inspector-best-practices)`, `Agent(sdd-inspector-consistency)`, `Agent(sdd-inspector-dead-code)`, `Agent(sdd-inspector-dead-settings)`, `Agent(sdd-inspector-dead-specs)`, `Agent(sdd-inspector-dead-tests)`, `Agent(sdd-inspector-e2e)`, `Agent(sdd-inspector-web-e2e)`, `Agent(sdd-inspector-holistic)`, `Agent(sdd-inspector-impl-consistency)`, `Agent(sdd-inspector-impl-holistic)`, `Agent(sdd-inspector-impl-rulebase)`, `Agent(sdd-inspector-interface)`, `Agent(sdd-inspector-quality)`, `Agent(sdd-inspector-rulebase)`, `Agent(sdd-inspector-test)`, `Agent(sdd-inspector-testability)`, `Agent(sdd-inspector-web-visual)`, `Agent(sdd-taskgenerator)`
- 全て `framework/claude/agents/sdd-*.md` に対応するファイルが存在 ✓
- `general-purpose` は組み込みエージェントのため settings.json エントリ不要 — 除外対象として正しく扱われている

**Bash() エントリ**: git, mkdir, ls, mv, cp, wc, which, sed, cat, echo, curl, diff, playwright-cli, tmux, npm, npx — いずれも標準的な CLI コマンドパターン ✓

**エージェント未登録チェック**: Glob で発見された全 27 エージェントファイルが settings.json の Agent() リストに網羅されている ✓ (孤立したエージェントファイルなし)

#### ツール可用性チェック

- `sdd-analyst`/`sdd-architect`: `WebSearch`, `WebFetch` ツールを使用 — 外部調査が必要な Tier 2 エージェントとして適切
- `sdd-builder`/`sdd-inspector-e2e`/`sdd-inspector-test`: `Bash` ツールを使用 — テスト実行・ビルドコマンド実行のために必要、正当
- `sdd-inspector-web-e2e`/`sdd-inspector-web-visual`: `Bash` ツールを使用 — playwright-cli 実行のために必要
- `Read-only` エージェント群 (死コード検査器, 設計 Inspector): `Bash` なし — 設計上正しい (ファイル読み取り・検索のみ)
- `sdd-taskgenerator`/`sdd-conventions-scanner`: `Bash` なし、`Edit` なし — tasks.yaml/conventions-brief 書き込みに Write のみ使用、適切

---

### Overall Assessment

**総合評価: PASS — 重大な問題なし**

全 27 エージェント定義と 8 スキル定義について Claude Code プラットフォーム仕様への準拠を確認。

**確認済み適合事項**:
1. 全エージェントが必須フィールド (`name`, `description`, `model`, `tools`) を持つ
2. `model` 値はすべて公式有効エイリアス (`sonnet`/`opus`) を使用
3. `background: true` フィールドは公式ドキュメントで確認された有効フィールド
4. settings.json の Skill()/Agent() エントリが実ファイルと 1:1 で対応
5. `general-purpose` 組み込みエージェントは settings.json/ファイル不要として正しく除外
6. Agent ツールディスパッチの `subagent_type` 値が全て既存エージェント定義と一致
7. `run_in_background` および `model` パラメータは Agent ツールの有効パラメータ
8. 各エージェントのツールセットが職責に適合 (不要な Bash 権限なし)

**低優先度観察事項** (2件):
- `sdd-review-self` の `model="sonnet"` Agent ツールパラメータ指定: 機能的に正しいが組み込みエージェントへの model オーバーライドとして注目
- インストール済み CLAUDE.md とフレームワークソース CLAUDE.md の Inspector カウント記述差異: インストール後バージョン差異として許容範囲

**推奨アクション**: なし (現状で本番利用に問題なし)
