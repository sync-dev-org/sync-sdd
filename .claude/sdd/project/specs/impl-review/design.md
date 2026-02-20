# Implementation Review

## Specifications

### Introduction
実装レビューパイプライン。6つの Implementation Inspector を並列 spawn し、CPF フォーマットで Auditor に findings を送信。Auditor が cross-check・検証・合成を行い、最終 verdict (GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED) を出力する。Stage 2 (Implementation) の品質ゲートとして機能し、コードが設計通りに実装されているか、品質基準を満たしているかを多角的に検証する。

### Spec 1: Review Skill (Impl Mode)
**Goal:** sdd-review skill の impl モードオーケストレーション

**Acceptance Criteria:**
1. `impl {feature}` 引数で実装レビューモードが起動する
2. `impl {feature} {tasks}` で特定タスクのみスコープ指定できる
3. `impl --cross-check` で全 spec の横断レビューが実行できる
4. `impl --wave N` で Wave スコープレビューが実行できる
5. Phase Gate: `design.md` と `tasks.yaml` の存在を確認し、`phase` が `implementation-complete` であることを検証する
6. `phase` が `blocked` の場合は "{feature} is blocked by {blocked_info.blocked_by}" でブロックする
7. 6 Inspector + 1 Auditor を `TeammateTool` で並列 spawn する
8. 各 Inspector に "Feature: {feature}, Report to: sdd-auditor-impl" のコンテキストを渡す
9. Auditor に "Feature: {feature}, Expect: 6 Inspector results via SendMessage" のコンテキストを渡す
10. Auditor spawn 時に `handover/session.md` の Steering Exceptions セクションを含める
11. Auditor の verdict を completion output から読み取る
12. 全レビュー Teammate を dismiss する

### Spec 2: Consensus Mode
**Goal:** `--consensus N` オプションによる複数パイプライン並列実行と合意形成

**Acceptance Criteria:**
1. `--consensus N` 指定時、N 個のパイプラインを並列 spawn する (各パイプライン: 6 Inspector + 1 Auditor)
2. 各パイプラインの Auditor に一意の名前を付与する: `auditor-impl-1`, `auditor-impl-2`, ...
3. 各 Inspector に対応する Auditor 名を "Report to: auditor-impl-{n}" で指定する
4. N 個の Auditor verdict を全て読み取る
5. VERIFIED セクションの findings を `{category}|{location}` をキーに集約する
6. 閾値 (デフォルト: ceil(N*0.6)) 以上の frequency で出現する finding を Consensus に分類する
7. 閾値未満の finding を Noise に分類する
8. 合意 verdict の決定: 全 N 個が GO → GO、Consensus に C/H issue → NO-GO、Consensus に M/L のみ → CONDITIONAL
9. N=1 (デフォルト) の場合は集約をスキップし、単一パイプラインとして直接実行する

### Spec 3: Rulebase Inspector (`sdd-inspector-impl-rulebase`)
**Goal:** Spec 準拠検証 -- タスク完了、spec traceability、ファイル構造の検証

**Acceptance Criteria:**
1. `spec.yaml`, `design.md`, `tasks.yaml` を自律的に読み込む
2. **Task Completion Check**: 各タスクの `done` ステータスを tasks.yaml で確認し、未完了タスクを "Task not marked complete" でフラグする
3. **Specifications Traceability**: design.md の各 Specification について、実装ファイル内に対応するコードの存在を Grep で検証し、"Spec not implemented" / "Partial implementation" でフラグする
4. **File Structure Verification**: design.md で定義されたファイルパスの存在を Glob で確認し、"Missing file" / "Unexpected file" でフラグする
5. **AC-Test Traceability**: テストファイル内の `AC: {feature}.S{N}.AC{M}` マーカーを Grep で検索し、各 AC のテストカバレッジ率を報告する。マーカーが一切見つからない場合は advisory として報告する
6. **Spec Metadata Integrity**: spec.yaml のステータスと tasks.yaml の実際の完了状態の整合性を確認する
7. Wave-Scoped Cross-Check Mode: `roadmap.wave <= N` の spec のみスコープに含め、将来 wave の機能不足をフラグしない
8. CPF フォーマットで findings を Auditor に `SendMessageTool` 経由で送信し、即座に terminate する
9. Severity は C/H/M/L の 4 段階、カテゴリは `task-incomplete`, `traceability-missing`, `file-missing`, `file-unexpected`, `metadata-mismatch` 等

### Spec 4: Interface Inspector (`sdd-inspector-interface`)
**Goal:** インターフェース契約検証 -- 設計定義と実装コードの文字レベル一致確認

**Acceptance Criteria:**
1. design.md からインターフェース定義を抽出し、spec.yaml からファイルパスを特定し、全実装ファイルを Read で読み込む
2. Steering コンテキスト (`product.md`, `tech.md`, `structure.md`) を読み込む
3. **Signature Verification**: design.md の各 function/method について、パラメータ名・型・順序・数・return type・default value を実装コードと EXACTLY に比較する
4. **Call Site Verification**: 各インターフェースの全呼び出し箇所を Grep で検索し、引数の数・順序・型の互換性を確認する
5. **Dependency Import Verification**: design.md の Outbound 依存関係について、実際のソースファイルの export と import の一致を確認する
6. **Cross-Module Interface Check**: feature 内のモジュール間インターフェースが設計と一致することを確認する
7. Common Failure Modes の検出: 引数数不一致、引数順序間違い、return type 不一致、Optional/Required の混同、型境界不一致
8. Mock を信頼せず、ACTUAL source code を読んで比較する (Core Philosophy: "DO NOT TRUST mocks")
9. CPF フォーマットで findings を Auditor に送信し、即座に terminate する
10. カテゴリは `signature-mismatch`, `call-site-error`, `dependency-wrong` 等。signature mismatch は Critical として分類

### Spec 5: Test Inspector (`sdd-inspector-test`)
**Goal:** テスト実行・カバレッジ・品質評価

**Acceptance Criteria:**
1. design.md (Testing Strategy セクション), spec.yaml, steering `tech.md` (テストコマンド) を読み込む
2. **Test File Existence**: 各実装ファイルに対応するテストファイルの存在を Glob で確認する
3. **Test Execution**: `steering/tech.md` Common Commands のテストコマンドを Bash で実行し、pass/fail/skip/error 数を記録する
4. **Regression Check**: フルテストスイートを実行し、既存テストの regression を検出する
5. **Mock Quality Check**: mock が呼び出し引数を検証しているか、mock の return value が現実的か確認し、"False positive risk" でフラグする
6. **Assertion Quality**: テストが具体的な期待値を assert しているか、edge case をテストしているか確認し、"Weak assertions" でフラグする
7. **Integration vs Unit Balance**: integration test の存在を確認し、unit test のみの場合 "Missing integration tests" でフラグする
8. **Coverage Assessment**: coverage tool が設定されている場合に実行し、カバレッジパーセンテージを報告する
9. **AC Marker Coverage**: テストファイル内の `AC: {feature}.S{N}.AC{M}` マーカーを Grep し、coverage < 80% の場合 severity H でフラグする。Stale マーカーは severity L でフラグする
10. **Design Testing Strategy Alignment**: 実際のテストと design.md の Testing Strategy セクションを比較し、不足カテゴリを "Strategy not implemented" でフラグする
11. tools に `Bash` を含み、`permissionMode: bypassPermissions` でテスト実行の権限を持つ
12. CPF フォーマットで findings を Auditor に送信し、即座に terminate する

### Spec 6: Quality Inspector (`sdd-inspector-quality`)
**Goal:** コード品質評価 -- エラー処理、命名、コード組織、steering 準拠

**Acceptance Criteria:**
1. design.md, spec.yaml, steering コンテキスト、全実装ファイル、knowledge の incident エントリを読み込む
2. **Error Handling Pattern Check**: design.md の Error Handling セクションと実装を比較し、エラー型、エラー境界、伝播戦略の drift を検出する。空 catch ブロック (swallowed exception) をフラグする
3. **Naming Convention Check**: steering conventions に基づき、変数/関数/クラス/ファイルの命名規則違反を検出する
4. **Code Organization Check**: design.md Architecture セクションとの乖離（モジュール境界違反、循環依存、レイヤリング違反）を検出する
5. **Logging and Monitoring Pattern Check**: steering `tech.md` のログパターンとの乖離、機密データのログ出力を検出する
6. **Dead Code and Unused Imports**: 未使用 import、到達不能コード、コメントアウトされたコード、未使用変数/関数を検出する
7. **Design Pattern Compliance**: design.md で指定されたデザインパターン（singleton, factory 等）の正確な実装を検証する
8. Cross-Check Mode で feature 横断の品質一貫性を評価する
9. CPF フォーマットで findings を Auditor に送信し、即座に terminate する
10. カテゴリは `error-handling-drift`, `dead-code`, `naming-violation`, `logging-violation`, `pattern-violation`, `organization-drift` 等

### Spec 7: Consistency Inspector (`sdd-inspector-impl-consistency`)
**Goal:** クロスフィーチャー整合性検証 -- インターフェース使用、型境界、エラー処理、パターンの一貫性

**Acceptance Criteria:**
1. 対象 spec の design.md, spec.yaml, 実装ファイルに加え、他 feature の design.md も読み込む
2. **Integration Points 特定**: 共有モジュール/ライブラリの使用箇所、feature 外部への import/export を特定する
3. **Interface Usage Consistency**: 共有モジュールの呼び出しパターン（import 方法、呼び出し規約）が feature 間で統一されているか検証する
4. **Type Consistency at Boundaries**: feature 間で受け渡される型（Optional/nullable 含む）の一致を確認する
5. **Error Handling Consistency**: 同一例外に対する catch/handle ロジックが feature 間で一致しているか確認する
6. **Pattern Consistency**: 初期化、クリーンアップ、コンフィグアクセス、ロギングのパターンが統一されているか検証する
7. **Shared Resource Access Patterns**: database、cache、config、logging への統一的なアクセスパターンを検証する
8. Cross-Check Mode で全 feature の体系的な一貫性評価を実行する
9. 単一 feature の場合は他の codebase との比較でレビュー（比較対象がない場合は skip して報告）
10. CPF フォーマットで findings を Auditor に送信し、即座に terminate する
11. カテゴリは `type-mismatch`, `interface-inconsistency`, `error-handling-inconsistency`, `import-pattern` 等

### Spec 8: Holistic Inspector (`sdd-inspector-impl-holistic`)
**Goal:** 横断的・創発的実装課題の検出 -- 他 Inspector の死角をカバーする制約なしレビュー

**Acceptance Criteria:**
1. design.md, spec.yaml, steering コンテキスト、全実装ファイル、knowledge の incident/pattern エントリを読み込む
2. **スコープ無制限**: 他の Inspector が持つ制約（「このドメインのみ」）を持たず、全角度からレビューする
3. **Design Intent vs Implementation Reality**: インターフェース一致を超えて、コードが設計の「意図」を実現しているか（正しいアルゴリズム、正しい実行順序、正しいセマンティクス）を確認する
4. **Resource and Lifecycle Audit**: ファイル/接続/ハンドルの open/close、エラーフローでの cleanup パス、unbounded growth を検出する
5. **Concurrency and Timing Review**: race condition、順序依存性の未強制、同期なし共有可変状態を検出する
6. **Integration Seam Inspection**: モジュール間のデータ互換性仮定、エラー伝播完全性、暗黙的結合（globals, singletons, env vars）を検出する
7. **Operational Readiness**: 障害モードの graceful/catastrophic 評価、設定処理の堅牢性、ハードコード値の検出、本番デバッグ可能性を評価する
8. tools に `WebSearch`, `WebFetch` を含み、ライブラリ/API のランタイム動作を検証する権限を持つ
9. `permissionMode: bypassPermissions` で WebSearch/WebFetch のネットワークアクセス制限を回避する
10. 他の Inspector が明らかに検出する問題は重複報告を避け、cross-cutting な findings を優先する
11. CPF フォーマットで findings を Auditor に送信し、即座に terminate する
12. カテゴリは `blind-spot`, `semantic-drift`, `resource-leak`, `race-condition`, `implicit-coupling`, `integration-gap`, `operational-risk`

### Spec 9: Implementation Auditor (`sdd-auditor-impl`)
**Goal:** 6 Inspector の findings を cross-check・検証・合成し、最終 verdict を出力する

**Acceptance Criteria:**
1. 6 Inspector の CPF 結果を `SendMessageTool` 経由で受信する。全結果到着前の timeout 処理と Lead recovery notification 対応を持つ
2. **Step 1 - Cross-Check Between Agents**: findings 間の支持・矛盾を検出し、複数 agent 確認で confidence 上昇、単一 agent 発見で要検証とする
3. **Spec Defect Detection**: 複数 agent が仕様を unimplementable と判定した場合、`specifications` or `design` phase に分類する。曖昧な場合は `specifications` を優先する
4. **Step 2 - Contradiction Detection**: Agent 間の矛盾パターン（signature matches vs call fails、all passing vs wrong arg count 等）を 5 つのルールで解決する
5. **Step 3 - False Positive Check**: 各 finding の actual applicability を検証し、common false positives（optional parameters flagging、intentional deviations、feature-specific patterns）を除去する
6. **Step 4 - Coverage Verification**: agents が design 記載の全ファイル、全インターフェース、全エラーシナリオ、全タスク、cross-feature integration points をカバーしたか確認する
7. **Step 5 - Deduplication and Merge**: 同一 issue を "confirmed by N agents" でマージし、類似 issue を統合する
8. **Step 6 - Re-categorize by Verified Severity**: Auditor 独自の判断で Critical/High/Medium/Low に再分類する
9. **Step 7 - Resolve Conflicts**: Inspector 間のコンフリクトを解決する。single-feature かつ 3 件以下の場合のみソースコードを読む。cross-check/wave-scoped では Inspector evidence のみで判断し、解決不能なものは `UNRESOLVED` とする
10. **Step 8 - Over-Implementation Check**: scope creep、defensive excess、premature utility、config externalization、unrequested abstraction、phantom resilience の 6 パターンを検出する。Inspector の推奨事項に対しても "design に指定があるか?" を適用する
11. **Step 9 - Decision Suggestions**: 実装選択を Steering Decision（project-wide）または Spec Design Decision（feature-specific）として文書化を提案する
12. **Step 10 - Synthesize Final Verdict**: Critical → NO-GO、Spec defect → SPEC-UPDATE-NEEDED、>3 High/test failure/interface mismatch → CONDITIONAL、M/L のみかつテスト pass → GO。優先度: NO-GO > SPEC-UPDATE-NEEDED > CONDITIONAL > GO。正当化があればオーバーライド可能
13. **Verdict Output Guarantee**: verdict 出力が最優先義務。processing budget 枯渇時は即座に Step 10 に飛び、`NOTES: PARTIAL_VERIFICATION|steps completed: {1..N}` で出力する
14. **Budget Strategy for Large-Scope**: wave-scoped-cross-check/cross-check では Steps 1-6 を Inspector evidence のみで実行し、ソースファイルを読まない
15. **Simplicity Bias**: AI complexity bias（過剰なエラー処理、ヘルパー、設定可能化の推奨）に対抗し、"Does the design specify this?" で判断する
16. CPF verdict フォーマットで出力: `VERDICT`, `SCOPE`, `VERIFIED`, `REMOVED`, `RESOLVED`, `SPEC_FEEDBACK`, `STEERING`, `NOTES`, `ROADMAP_ADVISORY` (wave-scoped のみ)
17. **STEERING セクション**: `CODIFY` (暗黙パターンの文書化、自動適用) / `PROPOSE` (新制約、ユーザー承認必要) の 2 レベル
18. Verdict 出力後は即座に terminate する

### Spec 10: Verdict Persistence
**Goal:** verdicts.md への verdict 永続化と issue tracking

**Acceptance Criteria:**
1. `specs/{feature}/verdicts.md` にバッチエントリを追記する（存在しない場合は `# Verdicts: {feature}` ヘッダーで新規作成）
2. バッチ番号 B{seq} をインクリメント（既存の最大値 +1、または 1 から開始）
3. バッチヘッダー: `## [B{seq}] impl | {timestamp} | v{version} | runs:{N} | threshold:{K}/{N}`
4. Raw セクション: N 個の Auditor CPF verdict を V1, V2, ... として verbatim 記録する
5. Consensus セクション: freq >= threshold の findings を記録する
6. Noise セクション: freq < threshold の findings を記録する
7. Disposition: `GO-ACCEPTED`, `CONDITIONAL-TRACKED`, `NO-GO-FIXED`, `SPEC-UPDATE-CASCADED`, `ESCALATED` のいずれか
8. CONDITIONAL の場合: Consensus の M/L issues を Tracked セクションに追記する
9. 前バッチに Tracked セクションが存在する場合: 現在の Consensus と比較し、解消された issues を `Resolved since B{prev}` として記録する

### Spec 11: Verdict Handling & Auto-Fix Loop
**Goal:** verdict に基づく後処理 -- human-readable レポート、auto-fix loop、STEERING 処理

**Acceptance Criteria:**
1. Auditor CPF output を human-readable markdown レポートに変換する: Executive Summary (verdict + severity 別 issue 数)、Prioritized Issues table (Critical → Low)、Verification Notes、Recommended actions
2. レポートをユーザーに表示する
3. **Auto-Fix Loop (NO-GO)**: `retry_count` をインクリメント (max 3)、Builder(s) を fix instructions 付きで spawn、fix 後に review pipeline を再 spawn する
4. **Auto-Fix Loop (SPEC-UPDATE-NEEDED)**: `spec_update_count` をインクリメント (max 2)、`orchestration.last_phase_action = null` にリセット、`phase = design-generated` に設定、Architect (SPEC_FEEDBACK 付き) → TaskGenerator → Builder のカスケードを実行する
5. **Aggregate Cap**: `retry_count + spec_update_count` が 4 に達した場合はユーザーにエスカレーションする
6. GO/CONDITIONAL verdict で `retry_count` と `spec_update_count` を 0 にリセットする
7. CONDITIONAL = GO として扱い、remaining issues を verdicts.md Tracked セクションに永続化する
8. **STEERING 処理**: verdict 後、次フェーズ進行前に実行する。CODIFY → steering ファイル更新 + decisions.md 追記。PROPOSE → ユーザーに提示し承認/拒否を記録する
9. コマンド完了後に `handover/session.md` を auto-draft する

### Spec 12: Recovery Protocols (Impl Review)
**Goal:** Inspector/Auditor の無応答時のリカバリ

**Acceptance Criteria:**
1. **Inspector Recovery**: Lead が idle notification 到着状況を確認 → `requestShutdown` → 同一タイプで re-spawn (1回) → 失敗時は Auditor に "Inspector {name} unavailable after retry. Proceed with {N-1}/{N} results." を SendMessage する
2. **Auditor Recovery**: Lead が "Output your verdict now" を SendMessage → 応答なければ `requestShutdown` → RECOVERY MODE で re-spawn (Inspector CPF を spawn context に埋め込み、SendMessage wait をスキップ) → 失敗時は Lead が Inspector results から保守的 verdict を導出し `NOTES: AUDITOR_UNAVAILABLE|lead-derived verdict` とする
3. Auditor は missing Inspector を `NOTES: PARTIAL:{inspector-name}|{reason}` で記録し、カバレッジ縮小時は verdict に "partial coverage" qualifier を付与する

### Non-Goals
- 設計レビュー（design-review spec のスコープ）
- Dead code レビュー（dead-code-review spec のスコープ）
- テストの実行自体（Test Inspector が Bash 経由で実行するが、テストフレームワーク自体の設計は対象外）
- Agent Teams API の実装（フレームワークが提供する TeammateTool/SendMessageTool を使用するのみ）

## Overview

Stage 2 (Implementation) の品質ゲート。設計レビュー（design-review spec）と同じ 6+1 Inspector-Auditor パターンを踏襲するが、実装コードの品質に特化した Inspector セットを使用する。

レビューの基本単位は **feature** (single spec) だが、`--cross-check`/`--wave N` による複数 spec 横断レビューと、`--consensus N` による統計的合意形成もサポートする。

**Verdict 意味論**:
- `GO`: 問題なし。Feature complete として進行可能
- `CONDITIONAL`: GO と同等。M/L の残存 issues は verdicts.md の Tracked セクションに永続化される
- `NO-GO`: Critical issues が存在。Auto-Fix Loop で Builder を re-spawn して修正を試みる (max 3 回)
- `SPEC-UPDATE-NEEDED`: 仕様自体に欠陥。Architect レベルからの全カスケード再実行 (max 2 回)

## Architecture

### Architecture Pattern & Boundary Map

```
6+1 Fan-Out/Fan-In Review Pipeline
==================================

  Lead (T1, Dispatcher)
    |
    |── TeammateTool spawn ──┬── Inspector-Impl-Rulebase (T3, Sonnet)  ──┐
    |                        ├── Inspector-Interface (T3, Sonnet)        │
    |                        ├── Inspector-Test (T3, Sonnet)             ├── SendMessageTool ──→ Auditor-Impl (T2, Opus)
    |                        ├── Inspector-Quality (T3, Sonnet)          │
    |                        ├── Inspector-Impl-Consistency (T3, Sonnet) │
    |                        ├── Inspector-Impl-Holistic (T3, Sonnet)    ┘
    |                        └── Auditor-Impl (T2, Opus)  ──→ verdict (completion output) ──→ Lead
    |
    ├── Read verdict
    ├── Persist to verdicts.md
    ├── Display report to user
    ├── Auto-Fix Loop (if NO-GO/SPEC-UPDATE-NEEDED)
    └── Process STEERING entries
```

Inspector は全て並列実行（互いに独立）。各 Inspector は自律的にコンテキストを読み込み、独自の視点でレビューを実行し、CPF フォーマットで Auditor に直接送信する。Auditor は T2 (Opus) モデルで cross-check と合成を行い、最終的な verdict を Lead に返す。

### Technology Stack

| Layer | Choice / Version | Role in Feature | Notes |
|-------|------------------|-----------------|-------|
| Orchestration | sdd-review skill (SKILL.md) | Dispatch & verdict handling | Design/Impl/Dead-Code 共有 |
| Inspector Runtime | Claude Sonnet (T3) | 6 並列レビュー実行 | 各 Inspector が独自スコープを持つ |
| Auditor Runtime | Claude Opus (T2) | Cross-check & verdict 合成 | 10-step verification process |
| Communication | SendMessageTool (CPF) | Inspector → Auditor | Peer messaging |
| Lifecycle | TeammateTool | Spawn / Shutdown | Lead が全 teammate を管理 |
| Persistence | verdicts.md (Markdown) | Verdict 履歴 & issue tracking | Batch 番号付き追記 |

### Communication Protocol

Inspector → Auditor 間の通信は **CPF (Compact Pipe-Delimited Format)** を使用する。

```
VERDICT:{GO|CONDITIONAL|NO-GO}
SCOPE:{feature} | cross-check | wave-1..{N}
ISSUES:
{sev}|{category}|{location}|{description}
NOTES:
{advisory observations}
```

Auditor の出力も CPF フォーマット（拡張版）:

```
VERDICT:{GO|CONDITIONAL|NO-GO|SPEC-UPDATE-NEEDED}
SCOPE:{feature} | cross-check | wave-scoped-cross-check
VERIFIED:
{agents}|{sev}|{category}|{location}|{description}
REMOVED:
{agent}|{reason}|{original issue}
RESOLVED:
{agents}|{resolution}|{conflicting findings}
SPEC_FEEDBACK:
{phase}|{spec}|{description}
STEERING:
{CODIFY|PROPOSE}|{target file}|{decision text}
NOTES:
{synthesis observations}
```

## System Flows

### Main Flow: Single Feature Implementation Review

```mermaid
sequenceDiagram
    participant U as User
    participant L as Lead (T1)
    participant IR as Impl-Rulebase (T3)
    participant II as Interface (T3)
    participant IT as Test (T3)
    participant IQ as Quality (T3)
    participant IC as Consistency (T3)
    participant IH as Holistic (T3)
    participant A as Auditor-Impl (T2)

    U->>L: /sdd-review impl {feature}

    Note over L: Phase Gate Check
    L->>L: Verify design.md exists
    L->>L: Verify tasks.yaml exists
    L->>L: Verify phase == implementation-complete
    L->>L: Verify phase != blocked

    Note over L: Spawn Review Pipeline (7 teammates)
    par Parallel Spawn
        L->>IR: TeammateTool spawn (Feature: {feature}, Report to: sdd-auditor-impl)
        L->>II: TeammateTool spawn (Feature: {feature}, Report to: sdd-auditor-impl)
        L->>IT: TeammateTool spawn (Feature: {feature}, Report to: sdd-auditor-impl)
        L->>IQ: TeammateTool spawn (Feature: {feature}, Report to: sdd-auditor-impl)
        L->>IC: TeammateTool spawn (Feature: {feature}, Report to: sdd-auditor-impl)
        L->>IH: TeammateTool spawn (Feature: {feature}, Report to: sdd-auditor-impl)
        L->>A: TeammateTool spawn (Feature: {feature}, Expect: 6 results)
    end

    Note over IR,IH: Inspectors load own context & review independently

    par Inspector Execution (Parallel)
        IR->>IR: Load spec.yaml, design.md, tasks.yaml
        IR->>IR: Task Completion + Traceability + File Structure + AC-Test + Metadata
        IR->>A: SendMessage (CPF findings)

        II->>II: Load design.md, all impl files, steering
        II->>II: Signature + Call Site + Dependency + Cross-Module
        II->>A: SendMessage (CPF findings)

        IT->>IT: Load design.md, steering/tech.md, test files
        IT->>IT: Execute tests + Regression + Quality + Coverage + AC Markers
        IT->>A: SendMessage (CPF findings)

        IQ->>IQ: Load design.md, steering, impl files, knowledge
        IQ->>IQ: Error Handling + Naming + Organization + Logging + Dead Code + Patterns
        IQ->>A: SendMessage (CPF findings)

        IC->>IC: Load feature + other features' design.md
        IC->>IC: Interface Usage + Type + Error Handling + Pattern Consistency
        IC->>A: SendMessage (CPF findings)

        IH->>IH: Load all context + knowledge
        IH->>IH: Intent vs Reality + Resource + Concurrency + Integration + Operational
        IH->>A: SendMessage (CPF findings)
    end

    Note over A: Auditor 10-Step Verification
    A->>A: Step 1: Cross-Check Between Agents
    A->>A: Step 2: Contradiction Detection
    A->>A: Step 3: False Positive Check
    A->>A: Step 4: Coverage Verification
    A->>A: Step 5: Deduplication & Merge
    A->>A: Step 6: Re-categorize Severity
    A->>A: Step 7: Resolve Conflicts
    A->>A: Step 8: Over-Implementation Check
    A->>A: Step 9: Decision Suggestions
    A->>A: Step 10: Synthesize Final Verdict

    A-->>L: Completion output (CPF verdict)

    Note over L: Post-Verdict Processing
    L->>L: Dismiss all 7 teammates
    L->>L: Persist verdict to verdicts.md (B{seq})
    L->>L: Format human-readable report
    L->>U: Display report (Executive Summary + Issues + Notes)

    alt Verdict == GO or CONDITIONAL
        L->>L: CONDITIONAL issues → verdicts.md Tracked
        L->>L: Reset retry_count & spec_update_count to 0
        L->>U: Feature complete (or proceed)
    else Verdict == NO-GO
        L->>L: Increment retry_count (max 3)
        L->>L: Spawn Builder(s) with fix instructions
        L->>L: Re-spawn review pipeline
    else Verdict == SPEC-UPDATE-NEEDED
        L->>L: Increment spec_update_count (max 2)
        L->>L: Reset phase → design-generated
        L->>L: Cascade: Architect → TaskGenerator → Builder → Re-review
    end

    opt STEERING section in verdict
        L->>L: Process CODIFY (auto-apply) / PROPOSE (ask user)
    end

    L->>L: Auto-draft session.md
```

### Consensus Mode Flow

```mermaid
sequenceDiagram
    participant L as Lead (T1)
    participant P1 as Pipeline 1 (6I + 1A)
    participant P2 as Pipeline 2 (6I + 1A)
    participant PN as Pipeline N (6I + 1A)

    L->>L: Parse --consensus N

    par Parallel Pipelines
        L->>P1: Spawn 6 Inspectors + auditor-impl-1
        L->>P2: Spawn 6 Inspectors + auditor-impl-2
        L->>PN: Spawn 6 Inspectors + auditor-impl-N
    end

    P1-->>L: Verdict V1 (CPF)
    P2-->>L: Verdict V2 (CPF)
    PN-->>L: Verdict VN (CPF)

    L->>L: Dismiss all teammates (7*N)

    Note over L: Consensus Aggregation
    L->>L: Key findings by {category}|{location}
    L->>L: Count frequency across N verdicts
    L->>L: Threshold = ceil(N * 0.6)
    L->>L: freq >= threshold → Consensus
    L->>L: freq < threshold → Noise

    Note over L: Determine Consensus Verdict
    L->>L: All GO → GO
    L->>L: C/H in Consensus → NO-GO
    L->>L: M/L only in Consensus → CONDITIONAL

    L->>L: Persist to verdicts.md (runs:N, threshold:K/N)
```

### Recovery Flow

```mermaid
sequenceDiagram
    participant L as Lead (T1)
    participant I as Inspector (unresponsive)
    participant I2 as Inspector (retry)
    participant A as Auditor-Impl (T2)

    Note over L,I: Inspector Recovery
    L->>L: Detect: Inspector idle but no output
    L->>I: requestShutdown
    L->>I2: TeammateTool spawn (same type, new name)

    alt Retry succeeds
        I2->>A: SendMessage (CPF findings)
    else Retry fails
        L->>A: SendMessage "Inspector {name} unavailable. Proceed with N-1/N."
        A->>A: Record NOTES: PARTIAL:{name}|{reason}
    end

    Note over L,A: Auditor Recovery
    L->>L: Detect: Auditor idle without verdict
    L->>A: SendMessage "Output verdict now. PARTIAL_VERIFICATION if incomplete."

    alt Nudge succeeds
        A-->>L: Verdict (CPF)
    else No response
        L->>A: requestShutdown
        L->>A: Re-spawn (RECOVERY MODE: CPF in spawn context)
        alt Recovery Auditor succeeds
            A-->>L: Verdict (CPF)
        else Recovery also fails
            L->>L: Derive conservative verdict from Inspector results
            L->>L: Tag: NOTES: AUDITOR_UNAVAILABLE|lead-derived verdict
        end
    end
```

## Components and Interfaces

### Component Overview

| Component | Domain/Layer | Intent | Files |
|-----------|--------------|--------|-------|
| sdd-review skill | Skill (Dispatcher) | レビューオーケストレーション（design/impl/dead-code 共有）| `framework/claude/skills/sdd-review/SKILL.md` |
| sdd-auditor-impl | Agent (T2, Opus) | Impl verdict 合成 -- 10-step verification process | `framework/claude/agents/sdd-auditor-impl.md` |
| sdd-inspector-impl-rulebase | Agent (T3, Sonnet) | SDD 準拠チェック -- タスク完了、traceability、ファイル構造 | `framework/claude/agents/sdd-inspector-impl-rulebase.md` |
| sdd-inspector-interface | Agent (T3, Sonnet) | インターフェース契約検証 -- signature、call site、依存関係 | `framework/claude/agents/sdd-inspector-interface.md` |
| sdd-inspector-test | Agent (T3, Sonnet) | テスト品質 -- 実行、カバレッジ、mock品質、AC markers | `framework/claude/agents/sdd-inspector-test.md` |
| sdd-inspector-quality | Agent (T3, Sonnet) | コード品質 -- エラー処理、命名、組織、logging、dead code | `framework/claude/agents/sdd-inspector-quality.md` |
| sdd-inspector-impl-consistency | Agent (T3, Sonnet) | クロスフィーチャー整合性 -- 型、パターン、共有リソースアクセス | `framework/claude/agents/sdd-inspector-impl-consistency.md` |
| sdd-inspector-impl-holistic | Agent (T3, Sonnet) | 横断的課題 -- semantic drift、resource leak、race condition、blind spot | `framework/claude/agents/sdd-inspector-impl-holistic.md` |
| verdicts.md | Artifact | Verdict 履歴 & issue tracking | `specs/{feature}/verdicts.md` |

### Inspector Detail Matrix

| Inspector | Tools | permissionMode | Reads Source Code | Runs Commands | Key Categories |
|-----------|-------|---------------|-------------------|---------------|----------------|
| impl-rulebase | Read, Glob, Grep, SendMessage | default | Grep で検索のみ | No | task-incomplete, traceability-missing, file-missing, file-unexpected, metadata-mismatch |
| interface | Read, Glob, Grep, SendMessage | default | Yes (全ファイル Read) | No | signature-mismatch, call-site-error, dependency-wrong |
| test | Read, Glob, Grep, Bash, SendMessage | bypassPermissions | Yes | Yes (テスト実行) | test-failure, missing-test-file, false-positive-risk, weak-assertion, strategy-gap |
| quality | Read, Glob, Grep, SendMessage | default | Yes (全ファイル Read) | No | error-handling-drift, dead-code, naming-violation, logging-violation, pattern-violation |
| impl-consistency | Read, Glob, Grep, SendMessage | default | Yes (feature + 他 feature) | No | type-mismatch, interface-inconsistency, error-handling-inconsistency, import-pattern |
| impl-holistic | Read, Glob, Grep, WebSearch, WebFetch, SendMessage | bypassPermissions | Yes (全ファイル + knowledge) | No (WebSearch/Fetch のみ) | blind-spot, semantic-drift, resource-leak, race-condition, implicit-coupling, integration-gap, operational-risk |

### Auditor Verification Steps

| Step | Name | 概要 | Source File Access |
|------|------|------|-------------------|
| 1 | Cross-Check Between Agents | 支持・矛盾の検出、confidence 評価 | No |
| 2 | Contradiction Detection | 5 パターンの矛盾解決ルール | No |
| 3 | False Positive Check | 誤検出除去（optional params、intentional deviations 等）| No |
| 4 | Coverage Verification | agents のカバレッジ確認 | No |
| 5 | Deduplication & Merge | 同一/類似 issue の統合 | No |
| 6 | Re-categorize Severity | Auditor 独自判断での severity 再分類 | No |
| 7 | Resolve Conflicts | Inspector 間コンフリクト解決。single-feature かつ <=3 件のみソース参照可 | Conditional |
| 8 | Over-Implementation Check | 6 パターンの過剰実装検出 + Agent 推奨事項への適用 | No |
| 9 | Decision Suggestions | Steering Decision / Spec Design Decision の提案 | No |
| 10 | Synthesize Final Verdict | Verdict 決定 (NO-GO > SPEC-UPDATE-NEEDED > CONDITIONAL > GO) | No |

### Auditor Verdict Decision Logic

```
IF any Critical issues remain after verification:
    Verdict = NO-GO
ELSE IF spec defect detected in Step 1:
    Verdict = SPEC-UPDATE-NEEDED
ELSE IF >3 High issues OR test failures OR interface mismatches:
    Verdict = CONDITIONAL
ELSE IF only Medium/Low issues AND tests pass:
    Verdict = GO

Precedence: NO-GO > SPEC-UPDATE-NEEDED > CONDITIONAL > GO
Override: Auditor MAY override with justification
```

### Spec Defect Detection Signals

| Signal | Classified Phase | Rationale |
|--------|-----------------|-----------|
| 複数 agent が仕様を unimplementable と判定 | `specifications` | AC が矛盾または不可能 |
| Interface が設計契約を実装不可と判定 | `design` | アーキテクチャ/インターフェース不一致 |
| Test が実際の動作と仕様の矛盾を検出 | `specifications` | AC が現実と不一致 |
| Design component が存在しない spec ID を参照 | `design` | トレーサビリティ破損 |
| AC が曖昧で実装が一つの解釈を選択 | `specifications` | AC の精密化が必要 |
| Design が orphan component を指定 | `design` | spec 裏付けなしの過剰設計 |
| Consistency が仕様レベルの依存関係違反を検出 | `specifications` | Spec 依存関係の欠陥 |

### Over-Implementation Detection Patterns

| Pattern | Symptom | Auditor Action |
|---------|---------|----------------|
| Scope creep | 設計にない機能の実装 | Flag as over-implementation |
| Defensive excess | 設計が指定しないケースのエラー処理 | Downgrade or remove finding |
| Premature utility | 単一用途の helper/utility 抽出 | Suggest inline |
| Config externalization | 設計でハードコードの値を外部化 | Flag as over-implementation |
| Unrequested abstraction | 設計が concrete を指定する箇所の interface/base class | Suggest concrete |
| Phantom resilience | 設計にない retry/fallback/circuit-breaker | Flag as over-implementation |

### STEERING Output Levels

| Level | Meaning | Lead の処理 | Pipeline ブロック |
|-------|---------|------------|------------------|
| `CODIFY` | 既存の暗黙パターンの文書化 | steering ファイル直接更新 + decisions.md 追記 | No |
| `PROPOSE` | 将来の作業に影響する新制約 | ユーザーに提示して承認/拒否 | Yes |

### Operation Modes

| Mode | Arguments | Inspector Scope | Auditor Scope Field |
|------|-----------|----------------|---------------------|
| Single Feature | `impl {feature}` | 単一 feature の実装ファイル | `SCOPE:{feature}` |
| Task-Scoped | `impl {feature} {tasks}` | 指定タスクのファイルのみ | `SCOPE:{feature}` |
| Cross-Check | `impl --cross-check` | 全 spec の実装ファイル | `SCOPE:cross-check` |
| Wave-Scoped | `impl --wave N` | wave <= N の全 spec | `SCOPE:wave-scoped-cross-check` |
| Consensus | `impl {feature} --consensus N` | N 並列パイプライン | Aggregated consensus |

### Error Handling

| Error Condition | Response |
|----------------|----------|
| Spec not found | "Spec '{feature}' not found. Run `/sdd-design \"description\"` first." |
| design.md missing | "Design required. Run `/sdd-design {feature}` first." |
| Phase != implementation-complete | "Phase is '{phase}'. Run `/sdd-impl {feature}` first." |
| Phase == blocked | "{feature} is blocked by {blocked_info.blocked_by}." |
| No specs found (cross-check) | "No specs found. Create specs first." |
| Inspector timeout/failure | Inspector Recovery Protocol (re-spawn 1 回 → partial coverage) |
| Auditor timeout/failure | Auditor Recovery Protocol (nudge → re-spawn → Lead-derived verdict) |
| retry_count >= 3 | User escalation |
| spec_update_count >= 2 | User escalation |
| Aggregate cap >= 4 | User escalation |

## Testing Strategy

本 spec はフレームワーク定義ファイル（Markdown agent definitions）で構成されるため、従来のユニットテストではなく、以下の検証方法を適用:

1. **Integration Test**: `/sdd-review impl {feature}` を実際に実行し、7 teammate が spawn され、verdict が verdicts.md に永続化されることを確認
2. **Agent Definition Validation**: 各 agent ファイルの YAML frontmatter (name, description, tools, model, permissionMode) が正しく設定されていることを確認
3. **CPF Format Compliance**: Inspector 出力と Auditor 出力が CPF 仕様に準拠していることを確認
4. **Verdict Logic Verification**: Auditor の verdict 決定ロジック（Critical → NO-GO、Spec defect → SPEC-UPDATE-NEEDED 等）が仕様通りであることを確認
5. **Recovery Protocol Test**: Inspector/Auditor の無応答シナリオでリカバリが正しく動作することを確認

## Dependencies

| Dependency | Type | Description |
|------------|------|-------------|
| core-architecture | Framework | 3-tier hierarchy, TeammateTool, SendMessageTool, Phase Gate, Recovery Protocol |
| cpf-protocol | Protocol | Inspector ↔ Auditor 間の通信フォーマット |
| design-review | Sibling | 同一 sdd-review skill を共有。設計レビュー用の Inspector/Auditor セット |
| dead-code-review | Sibling | 同一 sdd-review skill を共有。Dead code レビュー用の Inspector/Auditor セット |
| steering-system | Data | product.md, tech.md, structure.md (Inspector/Auditor が参照) |
| session-persistence | Integration | session.md auto-draft, decisions.md recording, Steering Exceptions |
| tdd-execution | Auto-Fix | NO-GO 時の Builder re-spawn |
| design-pipeline | Auto-Fix | SPEC-UPDATE-NEEDED 時の Architect re-spawn |
| task-generation | Auto-Fix | SPEC-UPDATE-NEEDED 時の TaskGenerator re-spawn |
