# Reference: taskflow Cross-Cutting Changes — Empirical Analysis

## Metadata

| Field | Value |
|-------|-------|
| Category | integration |
| Keywords | cross-cutting, multi-spec, revision, empirical, file-ownership, impact-analysis, taskflow |
| Last Verified | 2026-02-24 |
| Source | taskflow project (7 specs, 5 Waves, v0.5.2, 669 tests) |
| Related | `reference-integration-sdd-cross-cutting-changes.md` (フレームワーク比較) |

## Overview

**taskflow 実運用における横断的変更の実態分析**

taskflow プロジェクト（7 spec, 5 Waves, v0.5.2）で発生した横断的変更 8 件の実データに基づく分析。フレームワーク比較（別 knowledge エントリ）を補完する実証的データとして、sync-sdd の cross-cutting 仕組み設計の入力とする。

## Quick Reference

### 横断的変更の分類体系

| Type | 名称 | 伝播パス | 予測可能性 | taskflow 実例 |
|------|------|---------|-----------|-------------|
| **A** | 共有データモデル変更 | model → service → BFF（固定） | 高 | Fractional Indexing (#6), Field-clear (#7) |
| **B** | インフラ/フレームワーク置換 | 不定（隠れた依存が事後発覚） | 低 | UI stack 変更 (#1,#4), Auth 移行 (#5) |
| **C** | 共有サービス契約変更 | service → 直接呼び出し元（1 hop） | 中 | QG tracked issues (#2) |
| **D** | 同一根本原因の並列バグ | なし（各 spec 独立） | 高 | Edit dialog (#3), ISSUES batch (#8) |

### 全 8 件のサマリー

| # | 変更 | Decision | Type | 影響 spec | 戦略 | 問題 |
|---|------|----------|------|----------|------|------|
| 1 | daisyUI→Basecoat | D16 | B | 2R+2F | 依存順 seq | Wave 4 未実装で低コスト |
| 2 | QG tracked issues | D25,D41,D42 | C | 3R+1L | upstream→down | conftest.py Lead 直接例外 |
| 3 | Edit dialog 二重ネスト | D47 | D | 2R | 並列 | なし |
| 4 | Basecoat 完全除去 | D57-D59 | B | spec+hotfix | spec + Lead 介入 | @theme 隠れ依存で緊急 hotfix |
| 5 | Auth HTTP→ライブラリ | D80 | B | 1R(6file) | 単一 spec 吸収 | downstream re-review 欠落 |
| 6 | Fractional Indexing | D87-D90 | A | 4R | model→svc→BFF | todo-list は変更不要でも pipeline 実行 |
| 7 | Field-clear + UX | D93-D94 | A+C | 3R | task-crud→BFF並列 | なし |
| 8 | ISSUES batch | D74-D77 | D | 2R | 並列 | なし |

凡例: R=revise pipeline, F=fresh design, L=Lead direct

## Key Points

### 1. ファイル所有権の実態

**19 ファイルが複数 spec の `files_created` に重複登録**されている。

重複の構造:

| パターン | 件数 | 代表例 | 原因 |
|---------|------|--------|------|
| Foundation + Integration | 5 | main.py, config.py, database.py | auth-integration v2.0.0 が foundation ファイルを大規模書き換え |
| BFF + Design | 3 | task_card.html, _task_row.html | behavior owner と visual owner が同一ファイル |
| 3-owner | 1 | base.html | project-setup + auth-integration + design-system |
| Integration + Consumer (test) | 10 | test_board_router.py 等 | auth v2.0.0 が全 downstream テストを修正 |

**マイグレーション特異点**: auth-integration v2.0.0 (commit `f08c883`) は 1 パイプラインで 6 spec のファイルを修正。プロジェクト史上最大の cross-spec タッチ。

### 2. 依存グラフと blast radius

```
project-setup (blast: 5 downstream)
    ↓
auth-integration (blast: 4)
    ↓
task-crud (blast: 3)
    ↓         ↓
kanban-board  todo-list (blast: 1 each)
    ↓         ↓
    design-system (blast: 0, terminal)

shared-task-form [island, roadmap: null]
```

project-setup の変更は全 6 spec に波及する。Wave 1 が最大 blast radius ノード。

### 3. Architect 重複作業の定量分析

Fractional Indexing（4 spec revise）での重複:

| 重複コンテンツ | 出現数 | 例 |
|-------------|-------|---|
| SQLite TEXT 辞書順ソート説明 | 4 回 | "TEXT 型は辞書順比較をネイティブサポート" |
| `"a0"` デフォルト値の説明 | 6 回 | "Base62 キー空間の先頭付近" |
| "辞書順ソート可能な文字列キー" フレーズ | 8 回 | 全 spec に散在 |

**Cross-cutting design brief** が存在すれば、~500 語の共有ドキュメントで ~1,500-2,000 語の重複を排除可能。Architect 作業量の **~40% を削減**。

対照: Auth 移行（contract-stable）では downstream spec が変更を acknowledge する必要なし — 正しい動作。**contract が変わらない cross-cutting 変更は、downstream audit 不要**。

### 4. Lead 直接介入の記録

| 介入 | Decision | ファイル | 理由 | 結果 |
|------|----------|---------|------|------|
| conftest.py 共通化 | D25 | tests/conftest.py | spec 横断テスト基盤、owner 不在 | 成功（steering exception） |
| @theme hotfix | D59 | base.html | Basecoat 除去後の隠れ依存発覚 | 成功（steering exception + CODIFY） |
| D&D dropdown hotfix ×4 | D63 | task_card.html | 付け焼き刃修正 4 回試行 | **全失敗**（全除去→正規 pipeline） |
| pyproject.toml 直接編集 | D73 | pyproject.toml | 不要パッケージ追加 | **インシデント**（除去済み） |

教訓: Lead 直接介入は **構造的に owner 不在のファイル** に限り正当化される。ロジックを含むファイルへの直接 hotfix は高確率で失敗する（D63）。

## Confirmed Issues

### 課題 1: 「変更不要」確認のパイプラインコスト
- todo-list v1.5.0 は Architect が「変更不要」を確認するためだけに pipeline 実行
- **頻度**: 4-spec 変更で 1 回（25%）
- **要件 → R2**: audit-only 軽量パスが必要

### 課題 2: 中間状態のテスト整合性
- project-setup 完了〜task-crud 完了の間、テストが壊れうる
- 今回は task-crud が外部 IF を維持したため問題なし
- **リスク**: 外部 IF を変える変更では中間テスト失敗が不可避

### 課題 3: Downstream re-review 欠落
- Auth v2.0.0 で kanban-board / todo-list の formal re-review なし
- Builder が downstream ファイルも修正したが review は auth-integration 内のみ
- **要件 → R5**: cross-spec consistency review

### 課題 4: Architect 重複作業
- 4 Architect が同一背景を独立記述（定量分析参照）
- **要件 → R3**: cross-spec design brief

### 課題 5: 共有ファイルの owner 不在
- conftest.py, base.html 等に明確な単一 owner がいない
- **要件 → R6**: shared infrastructure ownership model

## Derived Requirements

sync-sdd フレームワークに求められる仕組み（実運用根拠付き）:

| Req | 名称 | 根拠 | 対応する Type |
|-----|------|------|-------------|
| **R1** | Impact Analysis | Lead が手動で影響 spec 特定（#6 で 4 spec）。spec 数増加で見落としリスク | A, B, C |
| **R2** | Triage | todo-list v1.5.0 は audit-only で十分だったが full pipeline 実行（課題 1） | A, C |
| **R3** | Cross-Spec Design Phase | 4 Architect が同一背景を重複記述（課題 4, ~40% 削減可能） | A, B |
| **R4** | Orchestrated Execution | 依存順 seq + 独立 parallel の実行計画を Lead が手動管理 | A, C |
| **R5** | Cross-Spec Consistency Review | Auth 移行で downstream re-review 欠落（課題 3） | B, C |
| **R6** | Shared Infrastructure Ownership | conftest.py, base.html の owner 不在（課題 5, 19 ファイル重複） | B |

### Type D は対応不要
同一根本原因の並列バグ（#3, #8）は現行の parallel revise で問題なく処理されている。cross-cutting 仕組みの対象外。

## Ownership Recommendations

taskflow の files_created 整理に関する推奨（実運用データに基づく）:

| ファイル | 現状 | 推奨 primary owner | ルーティングルール |
|---------|------|-------------------|----------------|
| `main.py` | project-setup + auth | auth-integration | 変更を駆動する spec の Builder が修正 |
| `config.py` | project-setup + auth | auth-integration | 同上 |
| `database.py` | project-setup + auth | auth-integration | 同上 |
| `base.html` | 3 spec | design-system | 全 visual/structural 変更は design-system 経由 |
| `templating.py` | kanban + auth | kanban-board | 安定。変更稀 |
| `task_card.html` | kanban + design | visual=design-system, behavior=kanban | 変更種別で分岐 |
| `_task_row/card.html` | todo + design | visual=design-system, behavior=todo | 同上 |
| `conftest.py` | auth (+ D25 例外) | Lead 直接例外を維持 | fixtures 増大時に test-infra spec 検討 |

## Open Design Decisions

sync-sdd 側で検討すべき設計判断:

| 判断 | 選択肢 | taskflow 実績 | 推奨 |
|------|--------|-------------|------|
| Cross-cutting の起点 | A: 新 spec type / B: revise 拡張 / C: roadmap-level op | B（4 個別 revise） | 要検討 |
| 設計の共有方法 | A: cross-cutting design.md / B: steering 追記 / C: 最初の spec を参照 | B+C 混合 | A（design brief） |
| 中間状態の管理 | A: 全 spec 同時切替 / B: 依存順 seq / C: feature branch | B | B（IF 維持前提） |
| 「変更不要」の扱い | A: audit-only 軽量パス / B: 通常 pipeline / C: skip + justification | B | A |
| contract-stable 変更 | A: downstream audit 必須 / B: downstream skip | 暗黙的 B | B を明文化 |

## Sources

- taskflow decisions.md D16-D98 (100 decisions across 15+ sessions)
- taskflow spec.yaml × 7 (`implementation.files_created`, `dependencies`)
- taskflow design.md × 7 (revision notes analysis)
- taskflow roadmap.md (wave structure, dependency graph)
- `reference-integration-sdd-cross-cutting-changes.md` (companion entry: framework comparison)
