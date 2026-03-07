## Platform Compliance Report

**日時**: 2026-02-28
**対象**: sdd-builder.md, sdd-inspector-test.md (フル検証) + キャッシュ済み項目の変更確認
**公式ドキュメント参照**: https://code.claude.com/docs/en/sub-agents, https://code.claude.com/docs/en/skills

---

### Issues Found

(該当なし)

---

### Confirmed OK

#### sdd-builder.md (フル検証 — 非キャッシュ対象)

- **name フィールド**: `sdd-builder` — 小文字英字+ハイフン形式。有効。
- **description フィールド**: 存在し、内容あり (`"SDD framework Builder. Implements tasks using TDD..."`)。有効。
- **model フィールド**: `sonnet` — 公式許容値 (sonnet/opus/haiku/inherit) に合致。有効。
- **tools フィールド**: `Read, Glob, Grep, Write, Edit, Bash` — 公式 internal tools に含まれる標準ツール。有効。
- **background フィールド**: `background: true` — 公式ドキュメント確認済み。サポートされるオプションフィールド (デフォルト: false)。有効。
- **permissionMode フィールド**: なし (デフォルト動作)。設定なしは許容。
- **未知フィールドなし**: 公式スキーマ外フィールドは使用されていない。

#### sdd-inspector-test.md (フル検証 — 非キャッシュ対象)

- **name フィールド**: `sdd-inspector-test` — 小文字英字+ハイフン形式。有効。
- **description フィールド**: 存在し、内容あり (`"SDD impl review inspector (test)..."`)。有効。
- **model フィールド**: `sonnet` — 公式許容値に合致。有効。
- **tools フィールド**: `Read, Glob, Grep, Write, Bash` — 標準ツール。Edit を持たないのは Inspector の性質 (CPF 書き込みは Write のみ) に適切。有効。
- **background フィールド**: `background: true` — 公式ドキュメント確認済みの有効フィールド。有効。
- **permissionMode フィールド**: なし (デフォルト動作)。有効。
- **未知フィールドなし**: 公式スキーマ外フィールドは使用されていない。

#### キャッシュ済み項目 — 変更確認 (B14, 2026-02-27)

- **その他 24 エージェント定義** (sdd-builder.md / sdd-inspector-test.md 以外): git diff にて B14 (b91da97) 以降の変更なし。キャッシュ検証を継続適用。OK (cached)。
- **7 スキル定義** (sdd-*/SKILL.md): git diff にて B14 (b91da97) 以降の SKILL.md ファイルへの変更なし。キャッシュ検証を継続適用。OK (cached)。
- **Task ディスパッチパターン**: `subagent_type` の値はすべて既存エージェント名または組み込み型 (`general-purpose`) に合致。有効。OK (cached)。
- **SubAgent 非ネスト制約**: 公式ドキュメント確認「Subagents cannot spawn other subagents」。フレームワーク設計 (Lead が T2/T3 をディスパッチ、T2/T3 間のネストなし) は準拠。OK (cached)。

#### settings.json 変更確認 (B14 以降の差分)

B14 (b91da97) 以降の変更: `Bash(sed *)`, `Bash(cat *)`, `Bash(echo *)` の 3 エントリが追加。

- **追加エントリの妥当性**: いずれも標準 Bash コマンド。`Bash(*pattern*)` 形式は公式サポート。有効。
- **Task() エントリ 26 件**: framework/claude/agents/ のエージェントファイル 26 件と完全一致。有効。
- **Skill() エントリ 7 件**: framework/claude/skills/ のスキルディレクトリ 7 件と完全一致。有効。
- **settings.json 全体**: OK (cached + 差分確認済み)。

#### sdd-review-self スキルの Task(general-purpose) 使用

- `sdd-review-self/SKILL.md` の `allowed-tools: Task` (括弧なし) により、スキル実行中はすべてのサブエージェント型へのディスパッチが無制限で許可される。
- `Task(general-purpose)` が settings.json allow リストにない点について: 公式ドキュメント「Your permission settings still govern baseline approval behavior」だが、スキルレベルの `allowed-tools: Task` がスキルアクティブ時の Tool 使用承認を担保するため、実行上の問題なし。有効。

---

### Overall Assessment

**PASS** — 全チェック項目に問題なし。

今回フル検証した `sdd-builder.md` および `sdd-inspector-test.md` はいずれも公式 Claude Code プラットフォーム仕様に完全準拠している。`background: true` フィールドは公式ドキュメントで明示的にサポート確認済み (デフォルト false)。B14 以降のキャッシュ済み項目 (24 エージェント、7 スキル SKILL.md) に変更はなく、キャッシュ検証の継続適用は適切。settings.json の B14 以降変更 (Bash 3 エントリ追加) は適正フォーマット。

**CRITICAL/HIGH/MEDIUM/LOW 問題: 0 件**
