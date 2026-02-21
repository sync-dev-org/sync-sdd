# Status & Progress

## Specifications

### Introduction
進捗確認と影響分析の read-only レポーティングスキル。Lead が直接実行（teammate spawn 不要）。個別フィーチャーの phase 状態・version alignment・変更履歴・レビュー履歴、ロードマップ全体の Wave 別進捗、変更の下流影響分析を人間可読な markdown レポートとして出力する。

### Spec 1: Argument Parsing & Context Loading
**Goal:** コマンド引数の解析と必要データの読み込み

**Acceptance Criteria:**
1. 引数なし（`$ARGUMENTS = ""`）でロードマップ全体 + 全 spec サマリーモードに入る
2. `$ARGUMENTS = "{feature}"` で個別 spec ステータスモードに入る
3. `$ARGUMENTS = "{feature} --impact"` または `$ARGUMENTS = "--impact {feature}"` で個別 spec ステータス + 影響分析モードに入る
4. `{{SDD_DIR}}/project/specs/roadmap.md` を読み込む（存在する場合）
5. `{{SDD_DIR}}/project/specs/*/spec.yaml` を glob スキャンして全 spec のメタデータを収集する
6. feature 指定時、該当する spec ディレクトリが存在しない場合は "Spec '{feature}' not found." エラーを表示する
7. spec が1件も見つからない場合は "No specs found. Run `/sdd-roadmap design \"description\"` to create." メッセージを表示する

### Spec 2: Overall Progress Report
**Goal:** ロードマップ全体の進捗サマリー表示

**Acceptance Criteria:**
1. roadmap.md が存在する場合、Wave 単位でグルーピングして進捗を表示する
2. 各 Wave の完了率（completion percentage）を計算する（`implementation-complete` の spec 数 / Wave 内の総 spec 数）
3. 各 Wave 内の spec を phase 別に分類して表示する（`initialized`, `design-generated`, `implementation-complete`, `blocked`）
4. `blocked` 状態の spec は `blocked_info` の詳細（`blocked_by`, `reason`）を併記する
5. roadmap.md が存在しない場合は、Wave コンテキストなしで個別 spec のステータスを一覧表示する
6. 出力は人間可読な markdown 形式とする

### Spec 3: Individual Spec Status
**Goal:** 指定フィーチャーの詳細ステータス表示

**Acceptance Criteria:**
1. spec.yaml から `phase` と `version` を読み取り表示する
2. design.md の存在確認と `version_refs.design` バージョンを表示する
3. tasks.yaml をパースし、タスク数の内訳（total, done, pending, optional）を表示する
4. `implementation.files_created` から作成済みファイル一覧を表示する
5. spec.yaml の `changelog` から最新5件のエントリを表示する（version, action, timestamp）
6. `verdicts.md` が存在する場合、バッチ単位でレビュー履歴を表示する（B{seq}, review-type, date, runs, verdict/consensus-verdict, tracked open count）
7. `blocked_info` が null でない場合、ブロック状態の詳細（blocked_by, reason, blocked_at_phase）を表示する
8. `orchestration` セクション（retry_count, spec_update_count, last_phase_action）を表示する

### Spec 4: Version Alignment Check
**Goal:** design と implementation のバージョン整合性検証

**Acceptance Criteria:**
1. `version_refs.design` と `version_refs.implementation` の一致を検証する
2. `version` フィールドと `version_refs` の各値の整合性を確認する
3. 不一致がある場合、警告（warning）として明示的に表示する
4. changelog から変更の追跡経路を表示し、バージョン不一致の原因特定を支援する

### Spec 5: Impact Analysis
**Goal:** `--impact` フラグによる変更の下流影響分析

**Acceptance Criteria:**
1. roadmap.md の dependency graph から forward map（下流依存）と reverse map（上流依存）を構築する
2. 対象 spec の changelog と version bump から変更内容を特定する
3. 変更の安定性を分類する: `BREAKING`（破壊的変更）, `INTERFACE`（インターフェース変更）, `COMPATIBLE`（互換性のある変更）, `UNKNOWN`（分類不能）
4. 下流の各依存 spec について、version alignment と design references の整合性をチェックする
5. re-review または re-implementation が必要な spec を特定する
6. アクション推奨付きの影響レポートを生成する

### Non-Goals
- ステータスの自動更新（各 skill/Lead が phase 遷移時に spec.yaml を更新する責務）
- CI/CD 連携やビルドステータスの表示
- spec.yaml への書き込み（純粋な read-only 操作）
- テスト結果の再実行や検証（既存の記録を表示するのみ）

## Overview

`/sdd-status` は SDD フレームワークの観測系コマンド。Lead が直接実行する read-only 操作であり、teammate の spawn は不要。spec.yaml を single source of truth として、プロジェクトのパイプライン状態を再構築・表示する。

主な利用場面:
- セッション開始時のパイプライン状態把握（Session Resume の Step 5 と連携）
- ロードマップ実行中の進捗モニタリング
- 変更の影響範囲分析（spec 改訂前の事前調査）
- バージョン drift の検出

## Architecture

### Data Flow

```
Input Sources                    Processing                     Output
─────────────                    ──────────                     ──────
spec.yaml (per spec)  ──┐
                        ├──→  Argument Parser  ──→  Report Generator  ──→  Markdown Report
roadmap.md            ──┤       ↓                      ↓
                        │   Context Loader         Version Checker
tasks.yaml (per spec) ──┤                              ↓
                        │                         Impact Analyzer
verdicts.md (per spec)──┘                        (--impact only)
```

### Data Model (spec.yaml fields read)

| Field | Type | 用途 |
|-------|------|------|
| `feature_name` | string | spec 識別子 |
| `phase` | enum | 現在のフェーズ（initialized / design-generated / implementation-complete / blocked） |
| `version` | string | spec バージョン |
| `version_refs.design` | string | design.md のバージョン |
| `version_refs.implementation` | string | 実装のバージョン |
| `changelog` | array | 変更履歴（version, action, timestamp） |
| `implementation.files_created` | array | 作成済みファイルパス一覧 |
| `orchestration.retry_count` | int | NO-GO リトライ回数 |
| `orchestration.spec_update_count` | int | SPEC-UPDATE-NEEDED 回数 |
| `orchestration.last_phase_action` | string/null | 最後の phase 操作 |
| `blocked_info` | object/null | ブロック情報（blocked_by, reason, blocked_at_phase） |
| `roadmap.wave` | int | 所属 Wave 番号 |
| `roadmap.dependencies` | array | 上流依存 spec リスト |

### Supplementary Data Sources

| Source | 用途 |
|--------|------|
| `roadmap.md` | Wave 構成と依存グラフの全体像 |
| `tasks.yaml` | タスク完了状況の内訳（total/done/pending/optional） |
| `verdicts.md` | レビュー履歴とバッチ情報 |
| `design.md` | 存在確認（design status 判定） |

## System Flows

### Flow 1: Overall Progress (引数なし)

```
1. Read roadmap.md
2. Glob scan: specs/*/spec.yaml
3. For each spec.yaml:
   a. Parse phase, version, blocked_info, roadmap.wave
4. If roadmap exists:
   a. Group specs by wave
   b. For each wave:
      - Count specs per phase
      - Calculate completion % = implementation-complete / total
      - List blocked specs with blocked_info details
5. If no roadmap:
   a. List all specs with phase, version
6. Output markdown report
```

### Flow 2: Individual Spec Status (feature 指定)

```
1. Locate specs/{feature}/spec.yaml
2. If not found → error: "Spec '{feature}' not found."
3. Parse spec.yaml:
   a. phase, version, version_refs, changelog, blocked_info, orchestration
   b. implementation.files_created
4. Check design.md existence
5. Parse tasks.yaml (if exists):
   a. Count: total, done, pending, optional
6. Version alignment check:
   a. Compare version_refs.design vs version_refs.implementation
   b. Compare version vs version_refs
   c. Flag mismatches as warnings
7. Read changelog → display latest 5 entries
8. If verdicts.md exists:
   a. Parse batches: B{seq}, review-type, date, runs, verdict, tracked open count
9. Output markdown report
```

### Flow 3: Impact Analysis (--impact フラグ)

```
1. Execute Flow 2 (individual spec status)
2. Build dependency graph from roadmap.md:
   a. Forward map: spec → [downstream dependents]
   b. Reverse map: spec → [upstream dependencies]
3. Identify changes in target spec:
   a. Parse changelog for recent changes
   b. Detect version bumps
4. Classify change stability:
   a. BREAKING: major version bump, structural changes
   b. INTERFACE: minor version bump, API changes
   c. COMPATIBLE: patch version bump, internal changes
   d. UNKNOWN: insufficient data for classification
5. Trace downstream impact:
   a. For each direct dependent:
      - Check version_refs alignment with target spec
      - Check design.md references
      - Determine if re-review or re-implementation needed
   b. For each transitive dependent:
      - Propagate impact classification
6. Generate impact report with action recommendations
```

## Components and Interfaces

| Component | Domain/Layer | Intent | Files |
|-----------|--------------|--------|-------|
| sdd-status skill | Skill | 進捗レポーティング・影響分析 | `framework/claude/skills/sdd-status/SKILL.md` |

### External Interfaces

| Interface | Direction | Description |
|-----------|-----------|-------------|
| spec.yaml | Read | 各 spec の phase, version, changelog 等のメタデータ |
| roadmap.md | Read | Wave 構成と依存グラフ |
| tasks.yaml | Read | タスク完了状況 |
| verdicts.md | Read | レビュー履歴とバッチ情報 |
| design.md | Read (existence check) | 設計ドキュメントの存在確認 |

### Execution Context

- **実行者**: Lead（T1）が直接実行
- **Teammate spawn**: 不要（read-only 操作）
- **Phase gate**: なし（任意のタイミングで実行可能）
- **Tools**: Read, Glob, Grep のみ使用

## Revision Notes
### v1.1.0 (2026-02-22) — v0.18.0 Retroactive Alignment
- 個別コマンド参照を `/sdd-roadmap` サブコマンドに更新
