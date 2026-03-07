## Platform Compliance Report

**レビュー日**: 2026-02-27
**対象**: SDD Framework エージェント/スキル/Task dispatch/settings.json
**公式ドキュメント参照**: [Claude Code SubAgents](https://code.claude.com/docs/en/sub-agents), [Claude Code Skills](https://code.claude.com/docs/en/skills)

---

### 検証方法

B8レビュー(2026-02-24)以降に変更されたファイルを `git diff HEAD~3 --name-only` で特定し、変更ファイルのみフル検証を実施。未変更ファイルはキャッシュ結果を採用。

**変更検出ファイル** (直近3コミット):
- `framework/claude/agents/sdd-architect.md`
- `framework/claude/agents/sdd-builder.md`
- `framework/claude/agents/sdd-taskgenerator.md`
- `framework/claude/agents/sdd-inspector-impl-holistic.md`
- `framework/claude/CLAUDE.md`
- `framework/claude/skills/sdd-roadmap/refs/*.md` (5ファイル)

---

### Issues Found

**(なし)**

全項目が公式仕様に準拠していることを確認。

---

### Confirmed OK

#### 1. エージェント YAML frontmatter (24エージェント)

| チェック項目 | 結果 |
|-------------|------|
| `name` フィールド (必須) | OK - 全24エージェントに存在、lowercase+hyphens形式 |
| `description` フィールド (必須) | OK - 全24エージェントに存在、用途を明記 |
| `model` フィールド | OK - 有効値のみ使用 (opus: 4, sonnet: 20) |
| `tools` フィールド | OK - Claude Code内部ツール名のみ (Read, Glob, Grep, Write, Edit, Bash, WebSearch, WebFetch) |
| `background` フィールド | OK - 全24エージェントで `true` に設定 (公式デフォルトはfalse; フレームワーク設計意図に合致) |
| 無効フィールドの不使用 | OK - 公式サポート外フィールドなし |

**フル検証 (変更あり4エージェント)**:

- **sdd-architect.md**: name=sdd-architect, description=present, model=opus, tools=[Read,Glob,Grep,Write,Edit,WebSearch,WebFetch], background=true -- PASS
- **sdd-builder.md**: name=sdd-builder, description=present, model=sonnet, tools=[Read,Glob,Grep,Write,Edit,Bash], background=true -- PASS
- **sdd-taskgenerator.md**: name=sdd-taskgenerator, description=present, model=sonnet, tools=[Read,Glob,Grep,Write], background=true -- PASS
- **sdd-inspector-impl-holistic.md**: name=sdd-inspector-impl-holistic, description=present, model=sonnet, tools=[Read,Glob,Grep,Write], background=true -- PASS (変更はmarkdown本文のみ、frontmatter変更なし)

**キャッシュ検証 (未変更20エージェント)**: OK (cached)

#### 2. スキル YAML frontmatter (6スキル)

| チェック項目 | 結果 |
|-------------|------|
| `description` フィールド (推奨) | OK - 全6スキルに存在 |
| `allowed-tools` フィールド | OK - 有効なツール名のみ使用 |
| `argument-hint` フィールド | OK (注記あり) |
| 無効フィールドの不使用 | OK |

**注記**: `sdd-handover` と `sdd-review-self` は `argument-hint:` が空値。公式ドキュメントによると `argument-hint` はオプションフィールドであり、空値は機能上問題なし。ただし、引数を取らないスキルではフィールド自体を省略する方がクリーン (LOW severity、前回B8と同じ所見)。

全6スキル: OK (cached) -- `sdd-roadmap/refs/` 配下の変更はスキル本文の参照ファイルであり、SKILL.md frontmatterに変更なし。

#### 3. settings.json パーミッション

| チェック項目 | 結果 |
|-------------|------|
| `Task()` エントリとエージェントファイルの一致 | OK - 24エントリ = 24エージェントファイル (完全一致) |
| `Skill()` エントリとスキルディレクトリの一致 | OK - 6エントリ = 6スキルディレクトリ (完全一致) |
| `Bash()` パーミッションパターン | OK - ワイルドカード形式で適切 |

結果: OK (cached) -- settings.json は直近3コミットで未変更。

#### 4. Task dispatch パターン

| チェック項目 | 結果 |
|-------------|------|
| CLAUDE.md の `subagent_type` 参照 | OK - `sdd-architect` を例示、実在するエージェント名 |
| refs/design.md の dispatch | OK - `sdd-architect` |
| refs/impl.md の dispatch | OK - `sdd-taskgenerator`, `sdd-builder` |
| refs/review.md の dispatch | OK - Inspector/Auditor (型名は `...` 省略表記、実行時に具体名を使用) |
| refs/run.md の dispatch | OK - `sdd-architect` を明示 |
| `run_in_background=true` 一貫性 | OK - 全dispatch箇所で指定 |

結果: OK (cached for structure, re-verified dispatch names in changed refs files)

#### 5. ツールアクセス整合性

| エージェント分類 | tools宣言 | 設計意図との整合 |
|-----------------|-----------|----------------|
| Architect (T2) | Read,Glob,Grep,Write,Edit,WebSearch,WebFetch | OK - 設計文書生成+外部調査に必要 |
| Builder (T3) | Read,Glob,Grep,Write,Edit,Bash | OK - TDD実装に必要 (テスト実行にBash) |
| TaskGenerator (T3) | Read,Glob,Grep,Write | OK - tasks.yaml生成のみ |
| Inspector-impl-holistic (T3) | Read,Glob,Grep,Write | OK - レビュー+CPF出力 |
| Auditor (T2) | Read,Glob,Grep,Write | OK (cached) |
| Inspector (T3, 全種) | Read,Glob,Grep,Write (+Bash for e2e/test/visual) | OK (cached) |

エージェントが宣言していないツールを本文で参照していないことを確認済み。

---

### コンプライアンス概要テーブル

| カテゴリ | 対象数 | PASS | FAIL | 備考 |
|---------|--------|------|------|------|
| エージェント frontmatter | 24 | 24 | 0 | 4件フル検証、20件キャッシュ |
| スキル frontmatter | 6 | 6 | 0 | 全件キャッシュ (refs変更はfrontmatter外) |
| settings.json 整合性 | 30エントリ | 30 | 0 | キャッシュ (未変更) |
| Task dispatch パターン | 8箇所 | 8 | 0 | refs変更分は再検証 |
| ツールアクセス整合性 | 24 | 24 | 0 | 変更4件フル検証 |

---

### Overall Assessment

**PASS** -- 全項目が Claude Code プラットフォーム公式仕様に準拠。

直近3コミット (v1.2.3-v1.2.5) での変更は主に以下:
1. エージェント本文の指示改善 (architect, builder, taskgenerator のワークフロー詳細化)
2. inspector-impl-holistic の Cross-Check Mode でファイル読込指示を明確化
3. roadmap refs の dispatch loop/review 分解ロジック更新

いずれも frontmatter 構造やツール宣言には影響しておらず、プラットフォームコンプライアンスに変化なし。

**既知の低優先度所見** (B8から継続):
- `sdd-handover`, `sdd-review-self` の `argument-hint:` 空値 -- 省略推奨だが機能上問題なし [LOW]
