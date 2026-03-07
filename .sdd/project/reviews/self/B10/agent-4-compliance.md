## Platform Compliance Report

**日付**: 2026-02-27
**対象**: SDD フレームワーク エージェント・スキル・設定ファイル
**検証方法**: WebSearch + WebFetch (code.claude.com 公式ドキュメント参照)

---

### Issues Found

なし。全チェック項目が準拠を確認。

---

### Confirmed OK

#### 1. エージェント YAML フロントマター (24ファイル) — OK (cached)

キャッシュ済み検証 (2026-02-27)。関連ファイルの変更を確認:

**変更あり**: `framework/claude/agents/sdd-inspector-best-practices.md`
→ 下記「non-cached 検証」にて再確認実施。

**変更なし (cached)**: 残り 23 エージェント。フロントマター構造変更なし。

必須フィールド確認済み (全 24 エージェント):
- `name`: 存在、`lowercase-hyphen` 形式 ✓
- `description`: 存在、説明文あり ✓
- `model`: `sonnet` または `opus` — 有効なエイリアス ✓
  - Opus 使用: sdd-architect, sdd-auditor-dead-code, sdd-auditor-design, sdd-auditor-impl (T2 設計・審査担当)
  - Sonnet 使用: 残り 20 エージェント (T3 実行担当)
- `tools`: Claude Code 内部ツール名のみ使用 ✓
- `background: true`: 全エージェントで設定済み ✓

#### 2. sdd-inspector-best-practices.md — ツール変更 WebSearch/WebFetch 追加 — OK (新規検証)

**ファイル**: `framework/claude/agents/sdd-inspector-best-practices.md` 行 5
```yaml
tools: Read, Glob, Grep, Write, WebSearch, WebFetch
```

**検証結果**: WebSearch および WebFetch はいずれも Claude Code 内部ツールとして有効。

公式ドキュメント (code.claude.com/docs/en/sub-agents) の `--agents` フラグ JSON サンプルおよび設定例にて `Grep`, `Glob`, `Read`, `Write`, `Bash`, `Edit`, `Task` の使用を確認。加えて WebSearch は公式の内部ツール一覧 (Bash, Glob, Grep, LS, Read, Edit, MultiEdit, Write, NotebookRead, NotebookEdit, WebFetch, TodoRead, TodoWrite, WebSearch) に含まれることを確認済み。WebFetch は権限設定ドキュメントに `WebFetch(domain:example.com)` 形式で明示記載あり。

判定: **両ツール名とも有効** ✓

#### 3. スキル フロントマター (6ファイル) — OK (cached + 新規検証)

キャッシュ済み (変更なし): sdd-steering, sdd-roadmap, sdd-status, sdd-release

**新規検証**: sdd-handover/SKILL.md および sdd-review-self/SKILL.md

公式ドキュメント (code.claude.com/docs/en/skills) のフロントマターリファレンスより:
- `description`: recommended (必須ではないが推奨) ✓
- `allowed-tools`: optional ✓
- `argument-hint`: optional — 削除しても問題なし ✓

**sdd-handover/SKILL.md** (行 1-4):
```yaml
---
description: Generate session handover document
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion
---
```
`argument-hint` なし → 仕様上 optional フィールドのため問題なし ✓

**sdd-review-self/SKILL.md** (行 1-4):
```yaml
---
description: Self-review for SDD framework development (framework-internal use only)
allowed-tools: Task, Bash, Read, Glob, Grep
---
```
`argument-hint` なし → 同様に問題なし ✓

`allowed-tools` に `Task` を含む → スキルが SubAgent を dispatch する場合の正当な設定 ✓
`AskUserQuestion` → Claude Code 内部ツール (settings ドキュメントで確認済み) ✓

#### 4. Task tool dispatch パターン — OK (cached)

キャッシュ済み検証 (2026-02-27)。`subagent_type` 名称と `.claude/agents/` ファイル名の対応を確認。

CLAUDE.md での dispatch 例:
```
Task(subagent_type="sdd-architect", prompt="...")
```

全 24 エージェント名が `settings.json` の `Task()` エントリと完全一致 ✓
(下記「設定ファイル照合」参照)

#### 5. settings.json パーミッション — OK (cached)

キャッシュ済み検証 (2026-02-27)。ファイル変更なし。

`Skill()` エントリ (6件) と実際のスキルディレクトリ (6件) が完全一致:
- sdd-handover, sdd-release, sdd-review-self, sdd-roadmap, sdd-status, sdd-steering ✓

`Task()` エントリ (24件) と実際のエージェントファイル名 (24件) が完全一致 ✓

`defaultMode: acceptEdits` → 有効な permissionMode 値 ✓

その他 `Bash()` エントリ: git, mkdir, ls, mv, cp, wc, which, diff, playwright-cli, npm, npx
→ Bash ツールの glob 形式パターン、仕様に準拠 ✓

#### 6. ツール可用性 — 全エージェントでアクセス可能なツールのみ参照 ✓

| エージェント | tools フィールド | 備考 |
|---|---|---|
| sdd-architect | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | 全て内部ツール ✓ |
| sdd-builder | Read, Glob, Grep, Write, Edit, Bash | 全て内部ツール ✓ |
| sdd-taskgenerator | Read, Glob, Grep, Write | 全て内部ツール ✓ |
| sdd-auditor-* (3件) | Read, Glob, Grep, Write | 全て内部ツール ✓ |
| sdd-inspector-architecture/consistency/holistic/impl-*/interface/quality/rulebase/testability (10件) | Read, Glob, Grep, Write | 全て内部ツール ✓ |
| sdd-inspector-e2e/test/visual (3件) | Read, Glob, Grep, Write, Bash | 全て内部ツール ✓ |
| sdd-inspector-dead-* (4件) | Read, Glob, Grep, Write | 全て内部ツール ✓ |
| sdd-inspector-best-practices | Read, Glob, Grep, Write, WebSearch, WebFetch | 全て内部ツール ✓ |

---

### コンプライアンス状態テーブル

| チェック項目 | 状態 | 備考 |
|---|---|---|
| エージェント YAML フロントマター構造 (24件) | OK (cached) | 変更なし (23件) + 再確認 (1件) |
| sdd-inspector-best-practices WebSearch/WebFetch | OK (新規検証) | 両ツール名とも有効な内部ツール |
| sdd-handover/SKILL.md argument-hint 削除 | OK (新規検証) | optional フィールド — 削除問題なし |
| sdd-review-self/SKILL.md argument-hint 削除 | OK (新規検証) | optional フィールド — 削除問題なし |
| スキル フロントマター (4件変更なし) | OK (cached) | sdd-steering/roadmap/status/release |
| Task dispatch subagent_type 名称一致 | OK (cached) | 全 24 エージェント名が一致 |
| settings.json Skill() エントリ | OK (cached) | 6件完全一致 |
| settings.json Task() エントリ | OK (cached) | 24件完全一致 |
| settings.json 形式 | OK (cached) | defaultMode, allow 配列構造 |
| モデル値 (sonnet/opus/haiku/inherit) | OK | sonnet/opus のみ使用、全て有効 |
| background フィールド | OK | 全エージェントで `true` に設定 |

---

### Overall Assessment

**総合判定: PASS — 問題なし**

全 24 エージェント定義、6 スキル定義、settings.json がいずれも Claude Code プラットフォーム仕様に準拠していることを確認した。

今回の非キャッシュ検証 3 件:
1. **sdd-inspector-best-practices.md の WebSearch/WebFetch 追加**: WebSearch は Claude Code 内部ツール一覧 (Bash, Glob, Grep, Read, Edit, Write, WebFetch, WebSearch 等) に含まれる正規ツール名。WebFetch も権限設定ドキュメントに明示記載あり。いずれも `tools` フィールドで有効に使用可能。
2. **sdd-handover/SKILL.md の argument-hint 削除**: 公式スキルドキュメントで `argument-hint` は optional フィールドと明記。削除後もフロントマターとして完全に有効。
3. **sdd-review-self/SKILL.md の argument-hint 削除**: 同上。

キャッシュ済みの 8 件はいずれも該当ファイルに変更がなく、前回検証結果をそのまま維持。

**潜在的な注意事項** (問題ではないが記録):
- `sdd-review-self/SKILL.md` の `allowed-tools` に `Task` を含む: スキルが SubAgent を dispatch するために必要な正当な設定。ただしスキル実行時にはユーザーの `settings.json` パーミッション (`Task()` エントリ) も適用されるため、二重の安全装置が機能している。
- `sdd-handover/SKILL.md` の `allowed-tools` に `AskUserQuestion` を含む: インタラクティブなハンドオーバー生成に必要。foreground 実行を前提とした正当な設定。
