# Dead Code Review

## Specifications

### Introduction
Dead code レビューパイプライン。コードベース全体を対象に、4つの専門 Dead-Code Inspector を並列 spawn し、未使用アーティファクト（設定、コード、仕様、テスト）を独立に検出。各 Inspector は CPF フォーマットで findings を `.review/{inspector-name}.cpf` ファイルに書き出す。全 Inspector 完了後に Dead-Code Auditor を spawn し、Auditor は `.review/` ディレクトリから全 `.cpf` ファイルを読み込み、クロスドメイン相関分析・偽陽性排除・重複排除・severity 再分類を行い、統合 verdict を `.review/verdict.cpf` に書き出す。Lead は `verdict.cpf` を読み取り、verdicts.md に永続化し、`.review/` ディレクトリをクリーンアップする。Design/Impl review と異なり、Phase Gate なし・Feature scope なし（コードベース全体が対象）の特殊なレビューモード。

Wave Quality Gate の一部として実行される場合、`.review-wave-{N}-dc/` ディレクトリを使用する。

### Spec 1: Review Skill (Dead-Code Mode)
**Goal:** `/sdd-roadmap review` の dead-code モード操作とモード分岐

**Acceptance Criteria:**
1. `dead-code` 引数で dead-code レビューモードが起動される
2. サブモード引数による Inspector 選択が機能する:
   - `dead-code` (引数なし): full モード — 4 Inspector 全員を spawn
   - `dead-code settings`: settings モード — dead-settings Inspector のみ
   - `dead-code code`: code モード — dead-code Inspector のみ
   - `dead-code specs`: specs モード — dead-specs Inspector のみ
   - `dead-code tests`: tests モード — dead-tests Inspector のみ
3. Phase Gate が適用されない（コードベース全体を対象とするため、spec.yaml.phase チェック不要）
4. 選択された Inspector を先に全て `TeammateTool` で spawn する。全 Inspector 完了後に `sdd-auditor-dead-code` を `TeammateTool` で spawn する（`Task` tool は使用しない）
5. Inspector は `.review/{inspector-name}.cpf` にファイル書き出し。Auditor は `.review/` から `.cpf` を読み込み `.review/verdict.cpf` を書き出す
6. Lead は `.review/verdict.cpf` を読み取る
7. verdict 読み取り後、`.review/` ディレクトリをクリーンアップし、全レビュー teammate を dismiss する
8. Verdict を `verdicts.md` に永続化（バッチ番号付き）
9. Verdict をユーザーに human-readable markdown レポートとして表示:
   - Executive Summary（verdict + severity 別 issue 数）
   - Prioritized Issues テーブル（Critical → High → Medium → Low）
   - Verification Notes（偽陽性排除、conflict 解決）
   - Recommended actions
10. session.md を auto-draft する

### Spec 2: Dead-Settings Inspector
**Goal:** プロジェクト設定の dead config 検出

**Acceptance Criteria:**
1. プロジェクト構造を自律的に探索し、設定ファイル・環境ファイル・設定モジュールを発見
2. `steering/tech.md` から project conventions をロード
3. 設定クラス/モジュールの全フィールドを列挙
4. 各フィールドについて定義→中間レイヤー→最終消費者へのパススルーチェーンをトレース
5. 以下のカテゴリの dead config を検出:
   - デフォルト値があり、パススルーが壊れているが静かに「動作」する設定
   - 定義されているが読み取られない環境変数
   - 常に on/off の Feature flag
   - 削除されたフィーチャー用の設定セクション
   - 複数ファイルにまたがる重複設定エントリ
6. Bash + project runtime で分析スクリプトを実行可能
7. CPF フォーマット (`VERDICT`, `SCOPE`, `ISSUES`, `NOTES`) で findings を `.review/inspector-dead-settings.cpf` に書き出す
8. Issue の category は `dead-config` を使用
9. ファイル書き出し後、即座に terminate（追加メッセージを待たない）

### Spec 3: Dead-Code Inspector
**Goal:** 未使用のコードシンボル（関数・クラス・メソッド・インポート）の検出

**Acceptance Criteria:**
1. プロジェクト構造を自律的に探索し、ソースディレクトリ・エントリポイント・モジュール境界を発見
2. `steering/tech.md` から project conventions をロード
3. public symbols（関数・クラス・メソッド・定数）を列挙
4. 各シンボルの call site を徹底的にトレース
5. exports と usage を比較（`__all__`、public API、re-exports）
6. 以下のカテゴリの dead code を検出:
   - モジュール外から呼ばれない関数/メソッド
   - インスタンス化されないクラス
   - テストからのみ使用され、production path にないコード
   - "将来用" として残されている実際には dead なコード
   - 未使用 import（re-exports と区別）
   - 条件分岐内の dead branch
7. False positive ガード:
   - Dynamic invocation (`getattr()`, decorators, framework hooks, signal handlers) を考慮
   - Entry points (CLI commands, celery tasks, API endpoints, scheduled jobs) を考慮
   - Plugin/extension points（外部消費者から呼ばれるコード）を考慮
   - Abstract/protocol implementations（基底クラスインターフェース経由の呼び出し）を考慮
8. 単純な grep を超えた実際の call relationship のトレース
9. クラスメソッドの継承経由の内部使用を確認
10. プロパティ、デコレータ、メタクラス経由の使用をチェック
11. CPF フォーマットで findings を `.review/inspector-dead-code.cpf` に書き出す
12. Issue の category は `dead-code` を使用
13. ファイル書き出し後、即座に terminate

### Spec 4: Dead-Specs Inspector
**Goal:** 仕様と実装の整合性検証、spec drift の検出

**Acceptance Criteria:**
1. プロジェクト構造を自律的に探索し、spec ディレクトリと実装ディレクトリを発見
2. `steering/tech.md` から project conventions をロード
3. 各 spec の design.md と tasks.yaml を読み取り、期待される実装を理解
4. Spec の promise と実際の実装をクロスリファレンス
5. tasks.yaml のタスクステータスと実際のコード状態を比較
6. 以下のカテゴリの spec drift を検出:
   - タスクが全てチェック済みだが実際の実装が欠落している spec
   - 対応する spec がない実装済みフィーチャー
   - Spec のインターフェース定義と実際のシグネチャの不一致
   - Spec の依存関係図と実際の import の不一致
   - 部分的・不完全な実装（一部タスク完了、他はスキップ）
   - リネーム/移動されたコードへの陳腐化した spec 参照
7. Spec のインターフェース定義と実際のシグネチャを比較
8. Spec の依存関係図と実際の import 関係を比較
9. spec.yaml の phase と実際の状態を確認
10. CPF フォーマットで findings を `.review/inspector-dead-specs.cpf` に書き出す
11. Issue の category は `spec-drift` を使用
12. ファイル書き出し後、即座に terminate

### Spec 5: Dead-Tests Inspector
**Goal:** 孤立テスト・陳腐化テスト・古いインターフェースに依存するテストの検出

**Acceptance Criteria:**
1. プロジェクト構造を自律的に探索し、テストディレクトリ・conftest ファイル・テストユーティリティを発見
2. `steering/tech.md` から project conventions をロード
3. Fixture 定義を列挙し、全テストファイルでの使用をトレース
4. テストの import とソースを比較し、テスト対象シンボルの存在を確認
5. 以下のカテゴリの dead test artifacts を検出:
   - 定義されているが使用されない fixture（conftest.py 継承チェーン含む）
   - 存在しない関数/クラスを import するテスト
   - 古いインターフェースに依存するテスト（不正なパラメータ名、削除されたメソッド）
   - クラス vs モジュール vs conftest レベルの重複 fixture
   - 削除されたフィーチャー用のテストファイル
   - 実際の実装と一致しない mock オブジェクト
   - 実装に関係なく常にパスするテスト（false confidence）
6. 全レベルの conftest.py fixture を含める
7. 間接的な fixture 使用（他の fixture 経由）をトレース
8. パラメータ化テストの参照をチェック
9. CPF フォーマットで findings を `.review/inspector-dead-tests.cpf` に書き出す
10. Issue の category は `orphaned-test` を使用
11. ファイル書き出し後、即座に terminate

### Spec 6: Dead-Code Auditor (Synthesis)
**Goal:** 4 Inspector の findings をクロスドメイン相関分析し、検証済み統合 verdict を出力

**Acceptance Criteria:**
1. `.review/` ディレクトリから全 `.cpf` ファイルを読み込む（4 Inspector の findings）
2. 利用可能な `.cpf` ファイルが期待数未満の場合、存在するファイルで処理を進行し、NOTES に `PARTIAL:{inspector-name}|not-available` を記録する
3. **Step 1: クロスドメイン相関** — 以下の6パターンを検出:
   - Dead function + Orphaned test (Code+Tests confirm) → severity upgrade、単一 finding にマージ
   - Dead config + Spec に言及なし (Settings+Specs confirm) → high confidence dead config
   - Spec に記載あるが実装なし (Specs alone) → tasks.yaml で将来実装予定か確認
   - Unused import + Spec で参照あり (Code+Specs contradict) → 未実装、dead code ではない → 再分類 or 除外
   - Dead function + Spec で参照あり (Code+Specs contradict) → 実装予定、dead ではない → finding 除外
   - Stale test + Dead code (Test+Code confirm) → high confidence removal candidate
4. **Step 2: エージェント間クロスチェック** — 各 finding について:
   - 他エージェントの finding が支持するか矛盾するかを確認
   - 複数エージェントが同一 issue を発見 → confidence 向上
   - 1エージェントのみが発見 → 検証が必要
   - エージェント間の severity 評価の一貫性を確認
5. **Step 3: False positive チェック** — 以下のパターンを確認:
   - Dynamic invocation（`getattr()`, decorators, framework hooks）
   - Entry points（CLI, signal handlers, celery tasks, API endpoints）
   - Test fixtures（parametrize/conftest 継承による使用）
   - Config defaults（明示的パススルーなしでも動作するデフォルト）
   - 将来の実装（spec に記載あるが未実装）
   - Plugin/extension points（外部消費者から呼ばれるコード）
6. **Step 4: 重複排除・マージ** — 同一シンボルの複数 finding を統合
7. **Step 5: Severity 再分類** — Auditor 独自の判断で以下に分類:
   - Critical: 積極的に有害な dead code（セキュリティリスク、誤解を招く、混乱を引き起こす）
   - High: 早期のクリーンアップが必要（メンテナンス負担）
   - Medium: メンテナンス時に対処（軽微な負担）
   - Low: あれば良い（cosmetic cleanup）
8. **Step 6: Conflict 解決** — エージェント間の矛盾を Auditor の判断で解決し、根拠を記録
9. **Step 7: Coverage チェック** — 全ソースディレクトリ、設定ファイル、spec ディレクトリ、テストディレクトリがカバーされているか確認
10. **Step 8: Verdict 合成** — 検証済み findings に基づき:
    - Critical issue あり → NO-GO
    - High issue 3件超 OR 重大な spec drift → CONDITIONAL
    - Medium/Low のみ → GO
    - Auditor は根拠付きでこの判定式をオーバーライド可能
11. CPF フォーマットで verdict を `.review/verdict.cpf` に書き出す:
    - `VERDICT:{GO|CONDITIONAL|NO-GO}` (SPEC-UPDATE-NEEDED は使用しない)
    - `VERIFIED:` セクション（検証済み findings: `{agents}|{sev}|{category}|{location}|{description}`）
    - `REMOVED:` セクション（除外した findings: `{agent}|{reason}|{original issue}`）
    - `RESOLVED:` セクション（解決した矛盾: `{agents}|{resolution}|{conflicting findings}`）
    - `NOTES:` セクション（合成の所見）
    - 空セクションは省略
12. Verdict Output Guarantee: processing budget が不足した場合、残りの検証ステップをスキップし、`NOTES: PARTIAL_VERIFICATION|steps completed: {1..N}` 付きで verdict を即座に出力する
13. Completion report を出力し、verdict ファイルのパスを含める
14. Verdict 出力後、即座に terminate

### Non-Goals
- コード品質レビュー（impl-review spec のスコープ）
- 設計品質レビュー（design-review spec のスコープ）
- Dead artifact の自動削除（本パイプラインは検出のみ）
- Auto-Fix Loop — このパイプラインは verdict 出力のみを行い、内部に自動修正ロジックを持たない。Wave Quality Gate の一部として実行される場合、post-verdict の Builder re-spawn による remediation は roadmap-orchestration (Lead) の責務
- Consensus mode（dead-code review では `--consensus N` 未対応）

## Overview

Dead code review は SDD フレームワークの3種類のレビュー（design / impl / dead-code）の1つ。他の2種類が feature-scoped（単一 spec 対象）であるのに対し、dead-code review はコードベース全体を対象とする横断的レビュー。Phase Gate を持たず、任意のタイミングで実行可能。

主な用途は2つ:
1. **Wave Quality Gate の一部**: Roadmap の Wave 完了後、Impl Cross-Check Review に続いて実行される品質ゲート。Wave Quality Gate 実行時は `.review-wave-{N}-dc/` ディレクトリを使用する
2. **Standalone 実行**: `/sdd-roadmap review dead-code` でユーザーが直接起動

4つの Inspector がそれぞれ異なるドメイン（Settings / Code / Specs / Tests）を独立に調査し、`.review/` ディレクトリに CPF findings をファイル出力する。全 Inspector 完了後に Auditor を spawn し、`.review/` から findings を読み込んでクロスドメイン相関分析で偽陽性を排除し、高信頼度の findings を統合した verdict を `.review/verdict.cpf` に書き出す。Design/Impl review の6 Inspector パターンと異なり、4 Inspector パターンを採用。また verdict に `SPEC-UPDATE-NEEDED` がなく、`GO / CONDITIONAL / NO-GO` の3種類のみ。

Inspector の検出方法論は「自律的・マルチアングル調査」を基本とし、機械的チェックリストに従わない。各 Inspector は project structure を自力で発見し、`steering/tech.md` から conventions をロードし、Bash + project runtime で分析スクリプトを実行する。

## Architecture

### Agent Topology

```
Lead (T1, Opus)
  |
  |-- spawn (TeammateTool) --> sdd-inspector-dead-settings  (T3, Sonnet)  --+
  |-- spawn (TeammateTool) --> sdd-inspector-dead-code      (T3, Sonnet)  --| .review/{name}.cpf
  |-- spawn (TeammateTool) --> sdd-inspector-dead-specs      (T3, Sonnet)  --| (file write)
  |-- spawn (TeammateTool) --> sdd-inspector-dead-tests      (T3, Sonnet)  --+
  |                                                                         |
  |   [All Inspectors complete → idle notifications received]               v
  |                                                                    .review/ directory
  |-- spawn (TeammateTool) --> sdd-auditor-dead-code         (T2, Opus)
  |                              reads .review/*.cpf → writes .review/verdict.cpf
  |                                                                         |
  <---- read verdict.cpf --------------------------------------------------+
```

### Architecture Pattern & Boundary Map

**Pattern**: Parallel Fan-Out / Fan-In + File-Based Communication

4 Inspector が Fan-Out で並列実行され、`.review/` ディレクトリへのファイル書き出しで findings を永続化する。全 Inspector 完了後に Auditor が spawn され、`.review/` ディレクトリから `.cpf` ファイルを読み込んで Fan-In 合成を行い、`verdict.cpf` を書き出す。Lead は `verdict.cpf` から verdict を読み取る。この pattern は Agent Teams mode の TeammateTool spawn とファイルシステムベースのデータ転送上に構築されている。

**Boundary Map**:
- **Orchestration Layer** (Lead): Pipeline lifecycle management, Phase Gate skip (dead-code は対象外), verdict handling, verdicts.md persistence, `.review/` directory cleanup
- **Inspection Layer** (4 Inspectors, T3): 独立した並列検査。各 Inspector は自身のスコープのみを検査し、他 Inspector と直接通信しない。findings を `.review/{inspector-name}.cpf` に書き出す
- **Synthesis Layer** (Auditor, T2): `.review/` から `.cpf` ファイルを読み込み、Cross-domain correlation, deduplication, severity reclassification, verdict を `.review/verdict.cpf` に書き出す
- **Communication Protocol**: CPF format over filesystem (Inspector → `.review/` → Auditor), verdict file (Auditor → `.review/verdict.cpf` → Lead)

**Steering Compliance**: Agent Teams architecture に準拠。TeammateTool で spawn。レビューデータ転送はファイルベース（`.review/` ディレクトリ）。Task tool は使用しない。

### Model Assignment

| Agent | Tier | Model | 根拠 |
|-------|------|-------|------|
| Lead | T1 | Opus | オーケストレーション、判断 |
| sdd-auditor-dead-code | T2 | Opus | クロスドメイン相関、severity 判断、偽陽性排除 |
| sdd-inspector-dead-settings | T3 | Sonnet | 設定トレース実行 |
| sdd-inspector-dead-code | T3 | Sonnet | コード解析実行 |
| sdd-inspector-dead-specs | T3 | Sonnet | Spec-コード比較実行 |
| sdd-inspector-dead-tests | T3 | Sonnet | テスト解析実行 |

### Technology Stack

| Layer | Choice / Version | Role in Feature | Notes |
|-------|------------------|-----------------|-------|
| Orchestration | Lead (Opus) | Pipeline spawn, verdict handling, persistence | T1 role |
| Synthesis | Auditor (Opus) | Finding cross-domain correlation, verdict generation | T2 role, requires higher reasoning |
| Inspection | 4 Inspectors (Sonnet) | Parallel dead-code review | T3 role, sufficient for focused inspection |
| Communication | CPF over filesystem (`.review/`) | Inter-agent structured data transfer | Token-efficient pipe-delimited format, file-based |
| Persistence | verdicts.md (Markdown) | Verdict history, issue tracking | Append-only batch structure |

### Tool Assignment

| Agent | Tools | 根拠 |
|-------|-------|------|
| Inspector (全4種) | Bash, Read, Glob, Grep | コードベース探索 + 分析スクリプト実行 + `.review/` へのファイル書き出し |
| Auditor | Read, Glob, Grep | `.review/` から `.cpf` ファイル読み込み + 独立検証 + `verdict.cpf` 書き出し |

### Communication Protocol

- **Inspector → `.review/`**: Inspector は findings を `.review/{inspector-name}.cpf` にファイル書き出し。Inspector はファイル書き出し後に即座に terminate。
- **Auditor ← `.review/`**: Auditor は `.review/` ディレクトリから全 `.cpf` ファイルを読み込み、合成後に `.review/verdict.cpf` を書き出す。
- **Lead ← `.review/verdict.cpf`**: Lead は Auditor の completion output（idle notification）から verdict ファイルパスを確認し、`verdict.cpf` を読み取る。

### Mode Selection Matrix

| コマンド | Inspector Set | Inspector 数 | Auditor |
|---------|---------------|-------------|---------|
| `dead-code` | settings, code, specs, tests | 4 | sdd-auditor-dead-code |
| `dead-code settings` | settings | 1 | sdd-auditor-dead-code |
| `dead-code code` | code | 1 | sdd-auditor-dead-code |
| `dead-code specs` | specs | 1 | sdd-auditor-dead-code |
| `dead-code tests` | tests | 1 | sdd-auditor-dead-code |

### Wave Quality Gate Directory

Wave Quality Gate の一部として実行される場合、standalone の `.review/` ではなく `.review-wave-{N}-dc/` ディレクトリを使用する:
- Inspector は `.review-wave-{N}-dc/{inspector-name}.cpf` に書き出す
- Auditor は `.review-wave-{N}-dc/` から読み込み、`.review-wave-{N}-dc/verdict.cpf` を書き出す
- Lead は `.review-wave-{N}-dc/verdict.cpf` を読み取り、完了後にディレクトリをクリーンアップする

## System Flows

### Primary Flow: Full Dead-Code Review

```mermaid
sequenceDiagram
    participant User
    participant Lead
    participant RD as .review/ directory
    participant Settings as Inspector<br/>dead-settings
    participant Code as Inspector<br/>dead-code
    participant Specs as Inspector<br/>dead-specs
    participant Tests as Inspector<br/>dead-tests
    participant Auditor as Auditor<br/>dead-code

    User->>Lead: /sdd-roadmap review dead-code
    Lead->>Lead: Parse arguments (mode=full)
    Lead->>Lead: Phase Gate skip (dead-code は対象外)

    par Spawn 4 Inspectors
        Lead->>Settings: TeammateTool spawn (sonnet)
        Lead->>Code: TeammateTool spawn (sonnet)
        Lead->>Specs: TeammateTool spawn (sonnet)
        Lead->>Tests: TeammateTool spawn (sonnet)
    end

    par 4 Inspectors investigate independently
        Settings->>Settings: Discover config files<br/>Load steering/tech.md<br/>Enumerate config fields<br/>Trace passthrough chains
        Code->>Code: Discover source dirs<br/>Load steering/tech.md<br/>Enumerate public symbols<br/>Trace call sites
        Specs->>Specs: Discover spec dirs<br/>Load steering/tech.md<br/>Read design.md + tasks.yaml<br/>Cross-reference with code
        Tests->>Tests: Discover test dirs<br/>Load steering/tech.md<br/>Enumerate fixtures<br/>Compare test imports with source
    end

    par Inspector → .review/ (File Write)
        Settings->>RD: Write inspector-dead-settings.cpf
        Code->>RD: Write inspector-dead-code.cpf
        Specs->>RD: Write inspector-dead-specs.cpf
        Tests->>RD: Write inspector-dead-tests.cpf
    end

    Note over Lead: All Inspectors complete<br/>(idle notifications received)

    Lead->>Lead: Dismiss all Inspectors
    Lead->>Auditor: TeammateTool spawn (opus)

    Auditor->>RD: Read all .cpf files
    Auditor->>Auditor: Step 1: Cross-domain correlation
    Auditor->>Auditor: Step 2: Cross-check between agents
    Auditor->>Auditor: Step 3: False positive check
    Auditor->>Auditor: Step 4: Deduplication and merge
    Auditor->>Auditor: Step 5: Re-categorize severity
    Auditor->>Auditor: Step 6: Resolve conflicts
    Auditor->>Auditor: Step 7: Coverage check
    Auditor->>Auditor: Step 8: Synthesize verdict
    Auditor->>RD: Write verdict.cpf

    Auditor-->>Lead: Completion output (verdict file path)

    Lead->>RD: Read verdict.cpf
    Lead->>Lead: Parse verdict
    Lead->>Lead: Persist to verdicts.md (B{seq})
    Lead->>Lead: Clean up .review/ directory
    Lead->>Lead: Dismiss Auditor
    Lead->>Lead: Format human-readable report
    Lead->>User: Display report
    Lead->>Lead: Auto-draft session.md
```

### Teammate Failure Handling

ファイルベースのレビュープロトコルにより全 teammate 出力が冪等（同じ `.review/` ディレクトリ、同じファイルパス）であるため、障害時は Lead が自身の判断でリトライ、スキップ、または利用可能なファイルから結果を導出する。

```mermaid
sequenceDiagram
    participant Lead
    participant RD as .review/ directory
    participant Auditor as Auditor<br/>dead-code

    Note over Lead: Inspector が .cpf ファイルを<br/>書き出さずに idle

    alt Lead がリトライを判断
        Lead->>Lead: 同一 agent type で re-spawn
        Note over Lead: 同じ .review/ ディレクトリに<br/>同じファイルパスで書き出し（冪等）
    else Lead がスキップを判断
        Note over Lead: 利用可能な .cpf ファイルで続行
    end

    Lead->>Auditor: TeammateTool spawn (opus)
    Auditor->>RD: Read available .cpf files
    Auditor->>Auditor: NOTES: PARTIAL:{name}|not-available
    Auditor->>RD: Write verdict.cpf

    Note over Lead: Auditor が verdict.cpf を<br/>書き出さずに idle

    alt Lead がリトライを判断
        Lead->>Lead: Auditor を再 spawn<br/>(.review/ に .cpf ファイルが残存<br/>しているため冪等に復旧可能)
    else Lead がリトライ失敗
        Lead->>Lead: Inspector 結果から<br/>conservative verdict を導出
        Note over Lead: NOTES: AUDITOR_UNAVAILABLE<br/>|lead-derived verdict
    end
```

## Components

### Component 1: `/sdd-roadmap review` (Dead-Code Mode Section)

**ファイル**: `framework/claude/skills/sdd-roadmap/SKILL.md` (sdd-review skill 内の分岐として実装。`/sdd-review` は `/sdd-roadmap review` にリダイレクト)

Dead-code モードは sdd-roadmap review 内の分岐として実装。Design/Impl review と同じ skill ファイル内に共存。

**責務**:
- 引数パース（`dead-code [settings|code|specs|tests]`）
- モード別 Inspector セットの決定
- TeammateTool による Inspector の並列 spawn → 全 Inspector 完了後に Auditor spawn
- `.review/verdict.cpf` の読み取り
- `.review/` ディレクトリのクリーンアップ
- verdicts.md への永続化
- human-readable レポートの生成・表示
- session.md の auto-draft

**Design/Impl review との差異**:
- Phase Gate なし（Step 2 をスキップ）
- Inspector 数: 4（Design/Impl は 6）
- Verdict に `SPEC-UPDATE-NEEDED` なし
- Auto-Fix Loop なし（パイプラインは verdict 出力のみ。Wave Quality Gate での post-verdict remediation は roadmap-orchestration の責務）
- Feature scope なし（コードベース全体）
- Consensus mode 未対応
- Wave Quality Gate 時は `.review-wave-{N}-dc/` ディレクトリを使用

### Component 2: sdd-inspector-dead-settings

**ファイル**: `framework/claude/sdd/settings/agents/sdd-inspector-dead-settings.md`

**検出方法論**:
設定の「定義 → 中間レイヤー → 最終消費者」パススルーチェーンをトレースし、途切れたチェーンを検出する。特にデフォルト値を持つ設定は、パススルーが壊れていても静かに「動作」するため、最も検出が難しい dead config パターン。

**検出カテゴリ**:
| カテゴリ | 説明 | 典型例 |
|---------|------|-------|
| デフォルト付き壊れたパススルー | 設定が定義され消費者にデフォルトがあるが、実際のパススルーが壊れている | `CACHE_BACKEND` が定義されているが消費者がハードコードされたデフォルトを使用 |
| 未読の環境変数 | `.env` に定義されているがコードで読み取られない | `.env:LEGACY_API_KEY` がコメントアウトされたコードからのみ参照 |
| 固定 Feature flag | 常に on or off の Feature flag | `ENABLE_V2=true` が常に true で条件分岐が dead |
| 削除フィーチャーの設定 | 削除されたフィーチャー用の設定セクション | `[legacy_api]` セクション全体が未使用 |
| 重複設定 | 複数ファイルにまたがる同一設定の重複 | `DEBUG` が settings.py と config.py の両方に定義 |

**出力**: `.review/inspector-dead-settings.cpf` にファイル書き出し、category = `dead-config`

### Component 3: sdd-inspector-dead-code

**ファイル**: `framework/claude/sdd/settings/agents/sdd-inspector-dead-code.md`

**検出方法論**:
public symbols を列挙し、call site を徹底的にトレースする。単純な grep を超え、実際の call relationship を追跡。クラスメソッドの継承経由の使用、プロパティ・デコレータ・メタクラス経由の使用を含む。

**検出カテゴリ**:
| カテゴリ | 説明 | 典型例 |
|---------|------|-------|
| 未呼び出し関数/メソッド | モジュール外からの call site がない | `parse_legacy()` — 45行、参照なし |
| 未インスタンス化クラス | インスタンス化されないクラス | `LegacyHandler` クラス全体 |
| テスト専用コード | テストからのみ使用される production コード | `_test_helper()` が production path にない |
| 将来用 dead code | "将来用" として残されているが実際には dead | `parse_v3()` — TODO コメント付きだが参照なし |
| 未使用 import | re-exports と区別した未使用 import | `import os` — os がモジュール内で未使用 |
| Dead branch | 条件分岐内の到達不能コード | `if False:` ブロック |

**False positive ガード**:
- Dynamic invocation: `getattr()`, decorators, framework hooks, signal handlers
- Entry points: CLI commands, celery tasks, API endpoints, scheduled jobs
- Plugin/extension points: 外部消費者から呼ばれるコード
- Abstract/protocol implementations: 基底クラスインターフェース経由の呼び出し

**出力**: `.review/inspector-dead-code.cpf` にファイル書き出し、category = `dead-code`

### Component 4: sdd-inspector-dead-specs

**ファイル**: `framework/claude/sdd/settings/agents/sdd-inspector-dead-specs.md`

**検出方法論**:
Spec ディレクトリの design.md + tasks.yaml を読み取り、実際のコードベースとクロスリファレンス。インターフェース定義、依存関係図、タスクステータスの3軸で整合性を検証。

**検出カテゴリ**:
| カテゴリ | 説明 | 典型例 |
|---------|------|-------|
| 空チェック spec | タスク全チェック済みだが実装が欠落 | tasks.yaml で done だが対応コードなし |
| 孤立実装 | Spec なしの実装済みフィーチャー | `user_export.py` に対応 spec なし |
| インターフェース不一致 | Spec の定義と実際のシグネチャの差異 | Spec: `create(name, email)` vs 実装: `create(data)` |
| 依存関係不一致 | Spec の依存関係図と実際の import の差異 | Spec: A→B→C だが実際は A→C (B をスキップ) |
| 部分実装 | 一部タスク完了、他がスキップ | tasks 2.3-2.5 が done だが対応コードなし |
| 陳腐化参照 | リネーム/移動されたコードへの参照 | Spec: `UserService` だが実装: `UserManager` |

**出力**: `.review/inspector-dead-specs.cpf` にファイル書き出し、category = `spec-drift`

### Component 5: sdd-inspector-dead-tests

**ファイル**: `framework/claude/sdd/settings/agents/sdd-inspector-dead-tests.md`

**検出方法論**:
テストディレクトリを探索し、fixture 定義の使用トレース、テスト import の存在確認、mock オブジェクトの実装一致確認を行う。conftest.py の継承チェーンを含む全レベルの fixture を対象とする。

**検出カテゴリ**:
| カテゴリ | 説明 | 典型例 |
|---------|------|-------|
| 未使用 fixture | 定義されているが使用されない fixture | `conftest.py:mock_legacy_api` — 参照なし |
| 存在しないシンボルの import | テストが削除された関数/クラスを import | `from src import LegacyAPI` — LegacyAPI は削除済み |
| 古いインターフェース依存 | 不正なパラメータ名、削除されたメソッド | `test_login` が古いシグネチャで mock |
| 重複 fixture | class vs module vs conftest レベルの重複 | 同一 fixture が conftest と test module の両方に定義 |
| 削除フィーチャーのテスト | 削除されたフィーチャー用のテストファイル全体 | `test_legacy.py` — LegacyAPI テスト全体が孤立 |
| 陳腐化 mock | 実装と一致しない mock オブジェクト | mock が古いシグネチャを再現 |
| False confidence テスト | 実装に関係なくパスするテスト | mock が全てを上書きし、実際のロジックをテストしない |

**出力**: `.review/inspector-dead-tests.cpf` にファイル書き出し、category = `orphaned-test`

### Component 6: sdd-auditor-dead-code

**ファイル**: `framework/claude/sdd/settings/agents/sdd-auditor-dead-code.md`

**合成プロセス**: 8-step verification pipeline

| Step | 名称 | 説明 |
|------|------|------|
| 1 | Cross-Domain Correlation | 4ドメイン間の相関パターン検出（6パターン） |
| 2 | Cross-Check Between Agents | エージェント間の一致/矛盾/単独発見の検証 |
| 3 | False Positive Check | 動的呼び出し、エントリポイント等の偽陽性パターン排除 |
| 4 | Deduplication and Merge | 同一シンボルの findings 統合、cross-domain 確認の統合 |
| 5 | Re-categorize Severity | Auditor 独自判断による4段階 severity 再分類 |
| 6 | Resolve Conflicts | エージェント間の矛盾解決、根拠の記録 |
| 7 | Coverage Check | 全ディレクトリ（source, config, spec, test）のカバレッジ確認 |
| 8 | Synthesize Verdict | 検証済み findings に基づく GO/CONDITIONAL/NO-GO 判定 |

**Verdict 判定ロジック**:
```
IF any Critical issues → NO-GO
ELSE IF >3 High issues OR significant spec drift → CONDITIONAL
ELSE IF only Medium/Low → GO
```
Auditor は根拠付きでこの判定式をオーバーライド可能。

**Severity 定義**:
| Level | Code | 定義 | 例 |
|-------|------|------|---|
| Critical | C | 積極的に有害な dead code | silent config、live code を shadow する dead code、false confidence テスト |
| High | H | 早期クリーンアップ推奨 | 明確な dead function/class、孤立テストファイル、混乱を招く spec drift |
| Medium | M | メンテナンス時に対処 | 未使用 import、冗長な config、軽微な spec 不一致 |
| Low | L | cosmetic cleanup | コメントアウトされたコード、未使用 type alias、簡略化可能なテストヘルパー |

**CPF Category 値**: `dead-config`, `dead-code`, `spec-drift`, `orphaned-test`, `unused-import`, `stale-fixture`, `unimplemented-spec`, `false-confidence-test`

**Agent 識別子**: `settings`, `code`, `specs`, `tests`（`+` 区切りで複数エージェント表記: `code+tests`）

**設計原則**:
- 単なるエージェント出力の連結ではなく、積極的なクロスドメイン検証を行う
- 慎重さを攻撃性より優先: dead code 削除にはリスクがある。不確実な findings は warning とし、critical にしない
- false dead code ガード: 動的呼び出し、デコレータ、エントリポイント、フレームワーク規約で使われるコードを確認してからフラグ

## Components and Interfaces

| Component | Domain/Layer | Intent | Files |
|-----------|--------------|--------|-------|
| `/sdd-roadmap review` | Skill | レビューオーケストレーション（共有） | `framework/claude/skills/sdd-roadmap/SKILL.md` |
| sdd-auditor-dead-code | Agent (T2) | Dead-code verdict 合成 | `framework/claude/sdd/settings/agents/sdd-auditor-dead-code.md` |
| sdd-inspector-dead-settings | Agent (T3) | 未使用設定検出 | `framework/claude/sdd/settings/agents/sdd-inspector-dead-settings.md` |
| sdd-inspector-dead-code | Agent (T3) | 未使用コード検出 | `framework/claude/sdd/settings/agents/sdd-inspector-dead-code.md` |
| sdd-inspector-dead-specs | Agent (T3) | 仕様乖離検出 | `framework/claude/sdd/settings/agents/sdd-inspector-dead-specs.md` |
| sdd-inspector-dead-tests | Agent (T3) | テスト陳腐化検出 | `framework/claude/sdd/settings/agents/sdd-inspector-dead-tests.md` |

## Error Handling

### Error Strategy

各レイヤーで独立したエラーハンドリングを実施し、パイプライン全体の resilience を確保する。ファイルベースのレビュープロトコルにより全 teammate 出力が冪等（同じ `.review/` ディレクトリ、同じファイルパス）であるため、障害時は Lead が自身の判断でリトライ、スキップ、または利用可能なファイルから結果を導出する。

### Error Categories and Responses

**Inspector Errors** (pipeline 実行中):
- Inspector が `.cpf` ファイルを書き出さずに idle: Lead は自身の判断でリトライ（同じフローで再 spawn）、スキップ、または利用可能な結果で続行する
- Missing context (no steering/tech.md): Inspector warns and proceeds with available context

**Auditor Errors** (pipeline 実行中):
- Auditor が `verdict.cpf` を書き出さずに idle: Lead は自身の判断でリトライ（Inspector `.cpf` ファイルが `.review/` に残っているため、Auditor を再 spawn するだけで冪等に復旧可能）
- Auditor リトライも失敗: Lead が Inspector 結果から conservative verdict を導出し、`NOTES: AUDITOR_UNAVAILABLE|lead-derived verdict` を付与する
- Processing budget exhaustion: Auditor outputs partial verdict (`NOTES: PARTIAL_VERIFICATION|steps completed: {1..N}`)

**全エージェントが "No Issues" を報告した場合**: Auditor がカバレッジを検証し、プロジェクトが真にクリーンか分析不足かを NOTES に記録する。

## Testing Strategy

### Agent Definition Verification
- 各 Inspector agent 定義（`framework/claude/sdd/settings/agents/sdd-inspector-dead-*.md`）に正しい tools リスト（Read, Glob, Grep, Bash）が含まれること
- Auditor agent 定義（`framework/claude/sdd/settings/agents/sdd-auditor-dead-code.md`）に正しい tools リスト（Read, Glob, Grep）と `model: opus` が含まれること

### Pipeline Integration Tests
- Full mode: 4 Inspector spawn → `.review/` ファイル書き出し → Auditor spawn → verdict.cpf 書き出しの E2E フロー
- Submode: 単一 Inspector + Auditor のフローが正しく動作すること
- Wave Quality Gate mode: `.review-wave-{N}-dc/` ディレクトリの使用が正しいこと

### Verdict Persistence Tests
- verdicts.md の batch 番号が正しくインクリメントされること
- Disposition 記録が正しいこと

### Failure Recovery Tests
- Inspector が `.cpf` ファイル未出力で idle → Lead がリトライまたはスキップで対処すること
- Auditor が `verdict.cpf` 未出力で idle → Lead が再 spawn（`.review/` に `.cpf` ファイルが残存しているため冪等復旧）すること
- Auditor リトライ失敗 → Lead が Inspector 結果から conservative verdict を導出すること
- Partial verification (Inspector 欠損) での verdict 出力

## Revision Notes

### Rev 1.1.0 (2026-02-21)

**変更箇所**: Non-Goals セクション — Auto-Fix Loop の記述を明確化

**変更理由**: D11 decision に基づく。従来の記述（「dead-code review は verdict 表示のみで自動修正を行わない」）はパイプライン内部のスコープとしては正確だが、Wave Quality Gate フロー全体における dead code issue の remediation が一切行われないかのような誤解を招く表現だった。

**変更内容**: パイプラインのスコープ（verdict 出力のみ、内部に自動修正ロジックなし）と、オーケストレーターのスコープ（Lead が post-verdict で Builder re-spawn による remediation を実行）を明確に分離する記述に変更。

**影響範囲**: Non-Goals の記述のみ。仕様（Spec 1-7）、アーキテクチャ、コンポーネント定義に変更なし。実装への影響なし。

### Rev 1.2.0 (2026-02-22) — v0.18.0 Retroactive Alignment

**背景**: v0.18.0 でレビューパイプラインが SendMessage ベースからファイルベースに移行し、Inspector/Auditor の spawn 順序が同時から順次に変更された。また Recovery Protocol が削除され、ファイルベースプロトコルの冪等性により Lead が自身の判断でリトライする方式に簡素化された。

**変更内容**:
- **Review pipeline: SendMessage ベース → ファイルベース (`.review/` ディレクトリ)**
  - Inspector → `.review/{inspector-name}.cpf` ファイル書き出し
  - Auditor → `.review/` から `.cpf` 読み込み + `.review/verdict.cpf` 書き出し
  - Lead → `verdict.cpf` 読み取り → verdicts.md 永続化 → `.review/` クリーンアップ
- **Inspector/Auditor spawn: 同時 → 順次**（Inspector 全完了後に Auditor spawn）
- **Spec 7 (Error Handling and Recovery) → Teammate Failure Handling**: ファイルベースプロトコルの冪等性により Recovery Protocol 不要。Lead が自身の判断でリトライ、スキップ、または利用可能なファイルから結果を導出する。SendMessage ベースの催促・不可通知は廃止
- **Auditor Spec (Spec 6)**: SendMessage 受信 → `.review/` ファイル読み込みに変更。`Expect: N` 待機ロジック → 利用可能な `.cpf` ファイル数で判断に変更。Completion report に verdict ファイルパスを含める
- **Agent 定義パス**: `framework/claude/agents/` → `framework/claude/sdd/settings/agents/`
- **コマンド参照**: `/sdd-review dead-code` → `/sdd-roadmap review dead-code`
- **Skill ファイル参照**: `framework/claude/skills/sdd-review/SKILL.md` → `framework/claude/skills/sdd-roadmap/SKILL.md`
- **Wave Quality Gate ディレクトリ**: `.review-wave-{N}-dc/` を明記
- **Tool Assignment**: Inspector/Auditor から SendMessage を削除
- **Architecture**: Agent Topology 図を SendMessage 矢印からファイルベース矢印に更新。Architecture Pattern & Boundary Map を追加
- **System Flows**: Primary Flow を SendMessage シーケンスからファイルベースシーケンスに更新。Inspector Recovery Flow / Auditor Recovery Flow → Teammate Failure Handling に置換
- **Error Handling**: Spec 7 ベースのエラー処理セクションをファイルベース冪等リトライに置換

**適用範囲**: 全レビュータイプ（design, impl, dead-code）に共通適用。

**既存 Revision Notes との関係**:
- v1.1.0 の Non-Goals 明確化は変更なし（内容はそのまま保持）
