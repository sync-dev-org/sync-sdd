# SDD Framework Self-Review Report (External Engine)
**Date**: 2026-03-04T04:11:06+0900 | **Engine**: codex [default] | **Agents**: 4 dispatched, 4 completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| C\|permissions\|settings.json:16 (Agent vs Task) | A4 | Claude Code のツールは `Agent` が正式名称。公式 docs の "Task" は概念名 |
| H\|dispatch-doc\|CLAUDE.md:5 (Agent vs Task) | A4 | 同上 |
| H\|skill-frontmatter\|SKILL.md:3 (allowed-tools Agent) | A4 | `Agent` は正式ツール名 |
| M\|skill-frontmatter\|sdd-reboot/SKILL.md:3 | A4 | 同上 |
| M\|skill-frontmatter\|sdd-review-self/SKILL.md:3 | A4 | 同上 |
| L\|review-rulebase\|sdd-review-self/SKILL.md:182 | A4 | 同上 |
| UNCERTAIN\|background:true | A4 | D99/B2 で確認済みの公式フィールド |
| UNCERTAIN\|subagent_type,run_in_background,TaskOutput | A4 | システムプロンプトの正式パラメータ名 |
| UNCERTAIN\|general-purpose built-in | A4 | Claude Code 組み込み agent type |

## A) 自明な修正 (3件) — OK で全件修正します

| ID | Sev | Summary | Fix | Target |
|---|---|---|---|---|
| A1 | H | engine_cmd 二重 cat パイプ | send-keys の engine_cmd 定義を engine binary のみに明確化 | sdd-review-self-ext/SKILL.md:180 |
| A2 | M | pane title ≠ slot title 混在 | "Pane title = Channel" を削除、channel は wait-for 専用 | sdd-review-self-ext/SKILL.md:170 |
| A3 | L | install サマリーテキスト未更新 | "Rules + templates" → "Rules, templates, profiles, scripts" | install.sh:590 |

## B) ユーザー判断が必要 (10件)

### B1: Compliance Cache 到達不能
**Location**: sdd-review-self-ext/SKILL.md:144
**Description**: Agent 4 キャッシュが `Confirmed OK` 項目を CPF から抽出する前提だが、CPF フォーマットは ISSUES のみ定義。OK 項目は report.md の表に書かれるが CPF には入らない。キャッシュが実質到達不能。
**Impact**: 毎回フル Web 検索が実行される（機能的には壊れていない、性能劣化のみ）
**Recommendation**: Agent 4 CPF に `COMPLIANT:` セクション追加 — 出力指示に `COMPLIANT:item|OK|source-url` 形式を定義

### B2: multiview-grid.sh Lead count チェック
**Location**: multiview-grid.sh:7
**Description**: スクリプトは全 Lead を数えて `>=2` でエラー。仕様は「自分以外 2 以上」なのでスクリプトの閾値は `>=3` が正しい。ただし 2-Lead レイアウトはスクリプト未実装のため、現状は実質正しい動作。
**Impact**: 2-Lead 環境で grid 作成不可（ただし未実装機能）
**Recommendation**: defer — 2-Lead レイアウト実装時にまとめて修正

### B3: consensus mode multi-pipeline 機構
**Location**: review.md:85
**Description**: `--consensus N` で N pipeline 並行実行するが、active ディレクトリ / verdict 保存先のマルチ対応が未定義。
**Impact**: consensus 未使用なら影響なし
**Recommendation**: defer — consensus 実使用時に対応 (pre-existing B4 L1 の拡張)

### B4: Design Review phase gate 不完全
**Location**: review.md:22
**Description**: `create` が skeleton design.md を作るため、`initialized` フェーズの spec でも design review が通る可能性。CLAUDE.md の Phase Gate は Lead が事前チェックする規約だが、review.md 側に redundant guard がない。
**Impact**: Lead が Phase Gate を正しく実行する限り問題なし（defense-in-depth の欠如）
**Recommendation**: defer — Lead の Phase Gate が防御線。review.md に redundant check を追加する利点は限定的

### B5: Cross-Cutting review verdict パス二重定義
**Location**: review.md:84 / revise.md:256
**Description**: cross-cutting review の scope-dir `specs/.cross-cutting/{id}/reviews/` と verdict 保存先 `specs/.cross-cutting/{id}/verdicts.md` が 2 系統に分岐。
**Impact**: cross-cutting revision 実行時に verdict 読み取りパスが不一致になる可能性
**Recommendation**: review.md の cross-cutting scope-dir を verdicts.md 直上に統一 (pre-existing B4 H2)

### B6: blocked spec が revise で phase gate 規約外
**Location**: revise.md:27
**Description**: Single-Spec revise が最初に `implementation-complete` を要求し、`blocked` を後段で判定。CLAUDE.md の blocked 専用エラーに到達しない。
**Impact**: blocked spec に revise を試みるとエラーメッセージが不適切
**Recommendation**: revise Validate の先頭に blocked チェックを追加 (pre-existing-adjacent B4 H4)

### B7: 空 roadmap 拒否なし
**Location**: run.md:7
**Description**: spec 件数 0 の空 roadmap を明示的に拒否せず、dispatch なしで完了扱いの余地。
**Impact**: 実運用で空 roadmap が作られることは稀
**Recommendation**: run.md 冒頭に spec count > 0 ガード追加

### B8: VERDICT:ERROR と Inspector の C-level finding 衝突
**Location**: review.md:132
**Description**: review protocol は VERDICT:ERROR で findings を無視するが、inspector-impl-rulebase は Missing Spec を ERROR + Critical finding で返す。Critical setup failure が黙殺される。
**Impact**: spec ファイル欠損時に Inspector の重大 finding が消える
**Recommendation**: VERDICT:ERROR でも C-level findings は Auditor に渡す例外ルールを追加

### B9: cross-cutting review trigger 未記載
**Location**: review.md:5
**Description**: Triggered by 一覧に cross-cutting review の呼び出し形が欠如。
**Impact**: ドキュメント可読性のみ
**Recommendation**: defer — L severity, 機能影響なし

### B10: reviews パス 3 系統の明示不足
**Location**: CLAUDE.md:36
**Description**: per-feature / project-level / cross-cutting の 3 系統スコープが抽象表現に留まる。
**Impact**: ドキュメント可読性のみ
**Recommendation**: defer — L severity, 機能影響なし

## Platform Compliance

| Item | Status | Source |
|---|---|---|
| Agent YAML frontmatter | OK (cached) | B4 |
| Skills frontmatter | OK (cached) | B4 |
| Agent() permission format | OK | Claude Code system prompt |
| subagent_type / run_in_background | OK | Claude Code system prompt |
| TaskOutput | OK | Claude Code system prompt |
| background: true | OK | D99/B2 confirmed |
| general-purpose built-in | OK | Claude Code built-in agent |
