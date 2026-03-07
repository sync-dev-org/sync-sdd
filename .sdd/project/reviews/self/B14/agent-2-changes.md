# SDD フレームワーク変更レビュー — agent-2-changes

**対象コミット**: HEAD~5..HEAD (v1.5.0 + v1.5.1)
**対象ファイル**: framework/ および install.sh
**未コミット差分**: あり (HEAD の uncommitted diff = 現在の変更内容)

---

## 変更ファイル一覧

変更が確認されたファイル:

| ファイル | コミット | 種別 |
|---------|---------|------|
| `framework/claude/CLAUDE.md` | v1.5.0, v1.5.1 | 更新 |
| `framework/claude/agents/sdd-analyst.md` | v1.5.0 (新規), v1.5.1 (更新) | 新規→更新 |
| `framework/claude/skills/sdd-reboot/SKILL.md` | v1.5.0 (新規), v1.5.1 (更新) | 新規→更新 |
| `framework/claude/skills/sdd-reboot/refs/reboot.md` | v1.5.0 (新規), v1.5.1 (更新) | 新規→更新 |
| `framework/claude/sdd/settings/templates/reboot/analysis-report.md` | v1.5.1 | 更新 |

---

## フォーカスターゲット別レビュー結果

---

### FT-1: Analyst Step 6 (Deletion Manifest) 追加 + Step 7 番号付け変更

#### 変更概要
- 旧 Step 6「Write Analysis Report」を Step 7 に繰り下げ
- 新 Step 6「Deletion Manifest」を挿入
- Step 7 の報告書セクション番号リストに「7. Deletion Manifest」を追加 (8,9 に繰り下がり)

#### 確認結果

**PASS** — 内部参照の一貫性

- `sdd-analyst.md` の Step 7 報告書構造リストは正しく更新されている:
  ```
  7. Deletion Manifest: Files to DELETE and files to KEEP, from Step 6
  8. Key Design Decisions: ...
  9. Risk Assessment: ...
  ```
- Step 6 の手順と Step 7 の「From Step 6」参照は整合している
- Completion Report の `Files to delete: {count}` フィールドも一致して追加されている

**PASS** — テンプレート整合性

`framework/claude/sdd/settings/templates/reboot/analysis-report.md` のセクション順序:
```
## Wave Structure
## Deletion Manifest  ← 追加済み
## Key Design Decisions
## Risk Assessment
```
テンプレートの順序は Analyst Step 7 のリスト (6=Wave Structure, 7=Deletion Manifest, 8=Key Design Decisions, 9=Risk Assessment) と一致している。

**問題なし。**

---

### FT-2: reboot.md Phase 9 ユーザー決定ゲート + Phase 10 削除確認

#### 変更概要 (v1.5.1 の未コミット変更)
- Phase 9: 「Final Report」→「Final Report & User Decision」に変更
  - `AskUserQuestion` による Accept/Iterate/Reject の 3 択を追加
  - Reject 時のブランチ削除処理 + decisions.md 記録を追加
  - 旧: スキル終了 (DO NOT merge/checkout)
  - 新: ユーザー決定後に Phase 10 へ進む (Accept の場合のみ)
- Phase 10: 「Post-Completion」に削除確認ステップを追加
  - `AskUserQuestion` による Delete/Skip deletion/Cancel の 3 択
  - Cancel 時はスキル終了 (ブランチは保持)
  - DO NOT merge / DO NOT checkout main の明示

#### ユーザー承認をスキップできるパスの確認

**PASS** — Phase 9 の全パスがユーザー確認を経由している

```
Phase 9, Step 4: AskUserQuestion (必須)
  Accept → Phase 10 へ
  Iterate → スキル終了 (ユーザーが branch 上で編集継続)
  Reject → git checkout main && git branch -D → スキル終了
```

「-y」フラグは Phase 5 (Analysis User Review) のみをスキップする定義であり、Phase 9 の `AskUserQuestion` をスキップするパスは存在しない。

**PASS** — Phase 10 の削除確認もユーザー確認を経由している

```
Phase 10, Step 1: AskUserQuestion (必須)
  Delete → 削除実行 → Step 2 へ
  Skip deletion → Step 2 へ (削除なし)
  Cancel → スキル終了 (コミットなし)
```

**PASS** — DO NOT merge は両フェーズで明示されている

Phase 9 の旧「DO NOT merge. DO NOT checkout main. Skill terminates here.」は削除されたが、Phase 10 Step 5 に「DO NOT merge to main. DO NOT checkout main.」が明示されている。

**問題なし。**

---

### FT-3: CLAUDE.md ↔ reboot.md の一貫性確認

#### 確認項目 A: Analyst の completion report フォーマット

`CLAUDE.md` の記述:
```
- **Analyst**: write analysis report to `{{SDD_DIR}}/project/reboot/analysis-report.md`,
  return structured summary (`ANALYST_COMPLETE` + counts + `WRITTEN:{path}`).
```

`sdd-analyst.md` Completion Report 定義:
```
ANALYST_COMPLETE
New specs: {count}
Waves: {count}
Steering: {created|updated} ({file_list})
Capabilities found: {count}
Files to delete: {count}
WRITTEN:{report_path}
```

`reboot.md` Phase 4 の待機条件:
```
2. Wait for `ANALYST_COMPLETE` via `TaskOutput`
```

**PASS** — CLAUDE.md の記述 (`ANALYST_COMPLETE` + counts + `WRITTEN:{path}`) は Analyst の Completion Report と整合している。ただし CLAUDE.md は `Files to delete: {count}` フィールドを明示していない。

**軽微な不整合**: CLAUDE.md では counts の内訳を列挙していないため、新規追加の `Files to delete: {count}` が記載されていない。機能的な問題ではないが、ドキュメントの完全性の観点では不足。

#### 確認項目 B: reboot フェーズ記述の一貫性

`CLAUDE.md` の `/sdd-reboot` コマンド説明:
```
/sdd-reboot | Zero-based project redesign (analysis + design pipeline on feature branch)
```

`SKILL.md` フェーズリスト (v1.5.1 現在):
```
9. **Final Report & User Decision**: Present report, user chooses Accept/Iterate/Reject
10. **Post-Completion**: Commit on branch (only if accepted). Never auto-merges.
```

**PASS** — CLAUDE.md のコマンド説明は概要レベルであり、フェーズ詳細は SKILL.md と reboot.md に委譲されている。矛盾はない。

---

### FT-4: sdd-reboot SKILL.md Phase リスト ↔ reboot.md Phase 定義

#### SKILL.md フェーズリスト (v1.5.1 後):
```
1. Pre-Flight
2. Branch Setup
3. Conventions Brief
4. Deep Analysis
5. User Review
6. Roadmap Regeneration
7. Design Pipeline
8. Regression Check
9. Final Report & User Decision
10. Post-Completion: Commit on branch (only if accepted). Never auto-merges.
```

#### reboot.md Phase 定義 (v1.5.1 後):
```
Phase 1: Pre-Flight
Phase 2: Branch Setup
Phase 3: Conventions Brief
Phase 4: Deep Analysis
Phase 5: User Review Checkpoint
Phase 6: Roadmap Regeneration
Phase 7: Design Pipeline (Design-Only Mode)
Phase 8: Regression Check
Phase 9: Final Report & User Decision
Phase 10: Post-Completion (Only reached if user chose Accept in Phase 9)
```

**PASS** — 全 10 フェーズの名称・順序・説明が一致している。

**PASS** — Phase 9 の「user chooses Accept/Iterate/Reject」は reboot.md の `AskUserQuestion` の選択肢と一致。

**PASS** — Phase 10 の「Commit on branch (only if accepted). Never auto-merges.」は reboot.md Phase 10 の「Only reached if user chose Accept in Phase 9」「DO NOT merge to main. DO NOT checkout main.」と一致。

**問題なし。**

---

### FT-5: Deletion Manifest エンドツーエンドフロー

フロー検証:
```
Analyst (Step 6) → analysis-report.md → Phase 9 final-report.md → Phase 10 実行
```

#### ステップ A: Analyst Step 6 が生成する

`sdd-analyst.md` Step 6 にて:
- 現在のソースファイルを収集 (Step 2 で発見したもの)
- DELETE / KEEP に分類
- 分析報告書 (Step 7) に含める

**PASS** — 生成ロジックが定義されている。

#### ステップ B: analysis-report テンプレートにセクションがある

`framework/claude/sdd/settings/templates/reboot/analysis-report.md`:
```markdown
## Deletion Manifest

Files to delete before implementation (clean slate for Builder):

### DELETE
| File | Reason |
|------|--------|
| {{FILE_PATH}} | {{REASON}} |

### KEEP
| File | Reason |
|------|--------|
| {{FILE_PATH}} | {{REASON}} |
```

**PASS** — テンプレートにセクションが存在する。

#### ステップ C: Phase 9 の final-report に Deletion Manifest が含まれる

`reboot.md` Phase 9 の final-report 構造:
```markdown
## Deletion Manifest
{Summary: N files to delete, N files to keep}
{List of files to delete — from Analyst's analysis report}
```

**PASS** — 参照元は「Analyst's analysis report」と明示されており、analysis-report.md の Deletion Manifest セクションへの参照が明確。

#### ステップ D: Phase 10 が Deletion Manifest を参照して実行する

`reboot.md` Phase 10 Step 1:
```
Show the Deletion Manifest summary (file count and list)
  ↓
Delete all files listed under DELETE in the analysis report.
```

**PASS** — Phase 10 が analysis-report の Deletion Manifest を参照していることが明示されている (「from analysis report」)。

#### データ流れのまとめ

```
Analyst Step 6: 分類実施
  → analysis-report.md §Deletion Manifest (DELETE/KEEP テーブル)
    → Phase 9 final-report.md §Deletion Manifest (サマリー + DELETE リスト)
      → Phase 10 Step 1: ユーザー確認後、analysis-report の DELETE リストを実行
```

**PASS** — エンドツーエンドの流れは一貫している。

---

## 総合評価

### 発見された問題

| 重大度 | 対象 | 内容 |
|--------|------|------|
| 軽微 | CLAUDE.md | Analyst Completion Report の説明で `Files to delete: {count}` フィールドが未記載。機能上の問題はなし。 |

### 確認された正常項目

| 確認項目 | 結果 |
|---------|------|
| Analyst Step 6→7 番号付け整合性 | PASS |
| analysis-report テンプレートのセクション追加 | PASS |
| Completion Report の `Files to delete` フィールド追加 | PASS |
| Phase 9 のユーザー承認ゲート (全パス) | PASS |
| Phase 10 の削除確認ゲート | PASS |
| Phase 10 の DO NOT merge 明示 | PASS |
| CLAUDE.md ↔ reboot.md Analyst フォーマット整合 | PASS (軽微不整合あり) |
| SKILL.md フェーズリスト ↔ reboot.md フェーズ定義 | PASS |
| Deletion Manifest エンドツーエンドフロー | PASS |

### 判定

**CONDITIONAL** — 機能的な問題なし。軽微な CLAUDE.md ドキュメント不足 (Analyst completion report のフィールド列挙) のみ。

---

## 付記: 前バージョン (v1.5.0) からの変更で失われたコンテンツの確認

旧 Phase 9 の「DO NOT merge. DO NOT checkout main. Skill terminates here.」という文言は削除されているが、これは仕様変更 (Phase 10 の追加) により意図的に削除されたものであり、代替の制約 (Phase 10 Step 5) が存在するため、コンテンツの損失ではない。

旧 Phase 10 は「Stage and commit → session.md → decisions.md」の 3 ステップのみだったが、新 Phase 10 は「削除確認 → commit → session.md → decisions.md → DO NOT merge」の 5 ステップに拡張されており、旧コンテンツはすべて新バージョンに引き継がれている。
