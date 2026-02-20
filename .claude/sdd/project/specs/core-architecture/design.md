# Core Architecture

## Specifications

### Introduction
SDD フレームワークの基盤アーキテクチャ。Agent Teams モードによる 3-tier hierarchy、Phase Gate による状態遷移制御、spec.yaml 中心の状態管理、アーティファクト所有権モデル、チームメイトライフサイクル管理、リカバリプロトコル、行動規則、実行規約、Git ワークフローを定義する。全ての他スペックはこのアーキテクチャ定義に依存する。

### Spec 1: 3-Tier Role Hierarchy
**Goal:** Lead (T1/Command), Brain (T2: Architect/Auditor), Execute (T3: TaskGenerator/Builder/Inspector) の3層ロール階層と各ロールの責務を定義

**Acceptance Criteria:**
1. T1 Lead は以下の責務を持つ: ユーザーインタラクション、phase gate チェック、spawn 計画、progress tracking、teammate lifecycle 管理、spec.yaml 更新、Knowledge 集約
2. T2 Architect は design.md + research.md を生成する（設計生成、リサーチ、ディスカバリー）
3. T2 Auditor は Inspector の findings を merge して verdict (GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED) を出力し、Product Intent チェックを行う
4. T3 TaskGenerator は tasks.yaml を生成する（タスク分解、並列性分析、ファイル所有権、Builder グルーピングを含む）
5. T3 Builder は RED→GREEN→REFACTOR の TDD サイクルで実装し、`[PATTERN]`/`[INCIDENT]` タグを報告する
6. T3 Inspector は個別レビュー観点で CPF findings を出力する（design/impl: 6 inspectors 並列、dead-code: 4 inspectors 並列）
7. T2 ロールは Opus モデルで spawn される
8. T3 ロールは Sonnet モデルで spawn される

### Spec 2: Chain of Command
**Goal:** ロール間の指揮系統とコミュニケーション経路を定義

**Acceptance Criteria:**
1. Lead は `TeammateTool` を使って T2/T3 teammates を spawn する
2. `Task` tool は spawn に使用してはならない（`Task` は isolated subagent を作り、`SendMessageTool` が届かないため）
3. Teammates は作業完了後に structured completion report を最終テキストとして出力する
4. Lead は completion output を読み取り次のアクションを決定する
5. Inspector → Auditor のコミュニケーションは `SendMessageTool` を使用する（review pipeline 内のピアコミュニケーション）
6. Lead → Teammate のリカバリ通知は `SendMessageTool` を使用する

### Spec 3: State Management
**Goal:** spec.yaml を中心とした状態管理モデルを定義

**Acceptance Criteria:**
1. spec.yaml は Lead のみが更新可能（T2/T3 teammates は直接更新不可）
2. Teammates は作業アーティファクト（design.md, tasks.yaml, コード）を生成し、completion report を出力する
3. Lead は completion report から結果を抽出し、spec.yaml のメタデータ（phase, version_refs, changelog）を更新する
4. Pipeline state は spec.yaml が single source of truth（handover には保存しない）

### Spec 4: Artifact Ownership
**Goal:** 各アーティファクトの作成・変更権限と Lead の操作制限を定義

**Acceptance Criteria:**
1. design.md: Lead は read-only、Architect が作成・変更
2. research.md: Lead は read-only、Architect が作成・変更
3. tasks.yaml: Lead はタスクステータス更新（`done` マーキング）のみ、TaskGenerator が作成・構造変更
4. Implementation code: Lead は read-only、Builder が変更
5. Lead は design.md のコンテンツ書き換え、tasks.yaml のタスク定義変更、コードの直接編集を行ってはならない
6. ユーザーが設計・実装の変更を要求した場合、roadmap active なら `/sdd-roadmap revise {feature}`、standalone なら `/sdd-design {feature}` を経由する
7. コンテンツ変更は必ず担当 teammate 経由でルーティングされる

### Spec 5: Phase Gate System
**Goal:** `initialized` → `design-generated` → `implementation-complete` (+ `blocked`) のフェーズ遷移制御

**Acceptance Criteria:**
1. Teammate spawn 前に Lead は `spec.yaml.phase` が要求されたオペレーションに適切か検証する
2. phase が `blocked` の場合: `"{feature} is blocked by {blocked_info.blocked_by}"` でブロックする
3. phase が未知の値の場合: `"Unknown phase '{phase}'"` でブロックする
4. phase gate 検証失敗時はユーザーにエラーを報告し、teammate を不必要に spawn しない
5. フェーズ遷移は `initialized` → `design-generated` → `implementation-complete` の順序に従う
6. Revision フロー: `implementation-complete` → `design-generated` → (full pipeline) → `implementation-complete`
7. 各 phase gate は次のコマンドによって強制される

### Spec 6: Teammate Lifecycle
**Goal:** spawn → execute → idle notification → dismiss のライフサイクル管理

**Acceptance Criteria:**
1. Lead が `TeammateTool` で teammate を spawn し、spawn prompt にコンテキスト（feature, paths, scope, instructions）を渡す
2. Teammate は自律的に作業を実行する
3. Teammate は structured completion report を最終テキストとして出力する
4. Teammate は自動的に idle になり、idle notification を Lead に送信する
5. Lead は idle notification から結果を抽出する（artifacts created, test results, knowledge tags, blocker info）
6. Lead は spec.yaml メタデータを更新する（phase, version_refs, changelog）
7. Lead は session.md を auto-draft し、decisions.md に記録し、buffer.md を更新する
8. Lead は次のアクションを決定する（次の teammate spawn、ユーザーへのエスカレーション等）
9. Lead は teammate に shutdown request を送り、teammate が approve して終了する

### Spec 7: Review Pipeline Lifecycle
**Goal:** Inspector + Auditor のレビューパイプラインにおけるライフサイクル

**Acceptance Criteria:**
1. Lead は Inspectors + Auditor を同時に spawn する（全て `TeammateTool` 経由）
2. Inspectors は `SendMessageTool` で CPF findings を Auditor に送信する（ピアコミュニケーション）
3. Auditor は verdict を completion text として Lead に出力する

### Spec 8: Builder Parallel Coordination
**Goal:** 複数 Builder の並列実行とインクリメンタル処理

**Acceptance Criteria:**
1. 複数 Builder が並列実行される場合、Lead は各 Builder の completion report を到着順に読み取る
2. 各 completion 時: tasks.yaml の完了タスクを `done` にマーク、ファイル収集、knowledge tags 保存
3. 次 wave のタスクがアンブロックされた場合、完了した Builder を dismiss して次 wave の Builders を即座に spawn する
4. 最終的な spec.yaml 更新（phase, implementation.files_created）は全 Builders 完了後にのみ行う

### Spec 9: Agent Teams Known Constraints
**Goal:** Agent Teams プラットフォームの既知の制約をドキュメント化

**Acceptance Criteria:**
1. No shared memory: Teammates は会話コンテキストを共有しない。全コンテキストは spawn prompt または SendMessage payload で渡す
2. Messaging is bidirectional: Lead ↔ Teammate, Teammate ↔ Teammate 全てサポート。ただしフレームワークの標準パターンは Lead が idle notification output を読み取る（message-based ではない）
3. SendMessage の使用場面: Inspector → Auditor のピアコミュニケーション、Lead → Teammate のリカバリ通知
4. 同時 teammate 上限: 24（3 pipelines x 7 teammates + headroom）
5. Consensus mode (`--consensus N`) は N pipelines を並列 spawn する（7xN teammates）

### Spec 10: Inspector Recovery Protocol
**Goal:** Inspector が無応答・エラーになった場合のリカバリ手順

**Acceptance Criteria:**
1. Lead は他の Inspectors からの idle notification 到着状況を確認する
2. 無応答 Inspector に `requestShutdown` を試みる
3. 同一 agent type で新しい名前の Inspector を `TeammateTool` で再 spawn する（1回リトライ）
4. リトライも失敗した場合、Lead は `SendMessageTool` で Auditor に通知する: "Inspector {name} unavailable after retry. Proceed with {N-1}/{N} results."
5. Auditor は利用可能な結果のみで続行し、欠落した Inspector を NOTES に記録する

### Spec 11: Auditor Recovery Protocol
**Goal:** Auditor が verdict 出力前に idle になった場合のリカバリ手順

**Acceptance Criteria:**
1. Lead は `SendMessageTool` で Auditor にナッジを送る: "Output your verdict now with findings verified so far. Use NOTES: PARTIAL_VERIFICATION if incomplete."
2. Auditor が応答して verdict を出力した場合、通常フローに復帰する
3. 最初のナッジ後も verdict がない場合: `requestShutdown` で停止し、新しい名前で Auditor を再 spawn する（1回リトライ）。Inspector CPF results を spawn context に直接埋め込み、"RECOVERY MODE: Inspector results in spawn context. Skip SendMessage wait. Prioritize verdict output." の指示を付加する
4. リトライも失敗した場合: Lead が Inspector results から保守的 verdict を導出する（Critical/High カウントに基づく）。`NOTES: AUDITOR_UNAVAILABLE|lead-derived verdict` タグを付加する

### Spec 12: Behavioral Rules
**Goal:** Lead の自律性と compact 後の行動制約を定義

**Acceptance Criteria:**
1. Compact 操作後は常にユーザーの次の指示を待つ。compact 後に自律的にアクションを開始してはならない
2. Compact 後に進行中だったタスクを、ユーザーが明示的に指示しない限り継続・再開してはならない
3. ユーザーの指示に正確に従い、そのスコープ内で自律的に行動する: 必要なコンテキストを収集し、要求された作業を end-to-end で完了する
4. 質問はエッセンシャルな情報が欠落しているか、致命的に曖昧な場合にのみ行う

### Spec 13: Execution Conventions
**Goal:** Bash コマンド実行、ステアリング参照、インラインスクリプトの規約を定義

**Acceptance Criteria:**
1. Bash の `command` 引数は実行可能ファイルで始めなければならない。`#` コメント行をプリペンドしてはならない。人間可読なコンテキストは Bash tool の `description` パラメータを使用する
2. プロジェクトツール（test, lint, build, format, run）を実行する際は `steering/tech.md` の Common Commands の正確なコマンドパターンを使用する。代替の呼び出し方法を使用してはならない（例: tech.md が `uv run pytest` なら bare `pytest` や `python3 -m pytest` は不可）
3. インラインスクリプティング（`-c` フラグ、heredocs）は `steering/tech.md` のプロジェクトランタイムをプレフィックスする（例: `uv run python -c "..."` であり bare `python -c "..."` ではない）

### Spec 14: Git Workflow
**Goal:** Trunk-based development の Git ワークフローを定義

**Acceptance Criteria:**
1. Trunk-based development: main は常に HEAD
2. 全ての作業はデフォルトで main 上で行う
3. Feature/topic branches はオプショナル。常に main にマージして削除する
4. main は常に最新の状態を維持する
5. マージ済みブランチは即座に削除する（stale branches を残さない）
6. Wave completion 後のコミット: Wave Quality Gate パス後に Lead が直接コミットする
7. Standalone command completion 後のコミット: `/sdd-impl` または `/sdd-review` が roadmap 外で完了した後
8. コミットスコープ: 完了した作業の全 spec artifacts + implementation changes
9. コミットメッセージフォーマット: `Wave {N}: {summary}`（roadmap）または `{feature}: {summary}`（standalone）
10. Release flow: `/sdd-release <patch|minor|major> <summary>` で自動化。エコシステム自動検出（Python, TypeScript, Rust, SDD Framework, Other）
11. Release branch は snapshot であり、main にはマージバックしない

### Spec 15: Settings Configuration
**Goal:** Agent Teams 有効化と基本パーミッションの設定

**Acceptance Criteria:**
1. `settings.json` に `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` が環境変数として設定されている
2. `permissions.allow` にベースラインの Bash パーミッション（`Bash(cat:*)`, `Bash(echo:*)`）が定義されている
3. 設定は JSON 形式で `env` と `permissions` セクションに分かれている

### Non-Goals
- Agent Teams API 自体の実装（Claude Code プラットフォームのスコープ）
- Claude Code 本体の変更
- settings.json の動的更新メカニズム
- 個別コマンド（sdd-design, sdd-impl 等）のオーケストレーションロジック（各 spec のスコープ）
- Handover システムの詳細（session-persistence spec のスコープ）
- Knowledge 蓄積の詳細（knowledge-system spec のスコープ）
- Auto-Fix Loop の詳細（roadmap-orchestration spec のスコープ）
- レビューパイプラインの Inspector/Auditor 内部ロジック（design-review / impl-review spec のスコープ）

## Overview
フレームワーク全体の基盤定義。CLAUDE.md のコアセクション群と settings.json で構成される。全ての他スペック（design-pipeline, steering-system, roadmap-orchestration 等）はこのアーキテクチャ定義に依存する。

CLAUDE.md は Markdown ベースの「フレームワーク定義ドキュメント」として機能し、Lead（T1）が読み込んでフレームワーク全体の振る舞いを規定する。settings.json は Claude Code の Agent Teams 機能を有効化し、ベースラインのパーミッションを設定する。

このスペックは retroactive spec（既存実装の事後仕様化）であり、CLAUDE.md と settings.json の既存実装を正式な設計ドキュメントとして記述する。

## Architecture

### Architecture Pattern & Boundary Map

3-tier hierarchy パターン（Command / Brain / Execute）。各層の境界は以下の通り:

- **Command Layer (T1)**: Lead のみ。ユーザーとの唯一のインターフェース。全状態の所有者。
- **Brain Layer (T2)**: Architect と Auditor。高レベルの意思決定（設計生成、レビュー統合）を担当。Opus モデルで実行。
- **Execute Layer (T3)**: TaskGenerator, Builder, Inspector。具体的な実行作業を担当。Sonnet モデルで実行。複数インスタンスの並列 spawn が可能。

層間の通信は TeammateTool (spawn/shutdown) と idle notification (completion report) が標準。例外的に SendMessageTool をピアコミュニケーション（Inspector → Auditor）とリカバリ通知（Lead → Teammate）に使用する。

```mermaid
graph TB
    User["User"]

    subgraph T1["Tier 1: Command"]
        Lead["Lead (Opus)"]
    end

    subgraph T2["Tier 2: Brain"]
        Architect["Architect (Opus)"]
        Auditor["Auditor (Opus)"]
    end

    subgraph T3["Tier 3: Execute"]
        TaskGen["TaskGenerator (Sonnet)"]
        Builder1["Builder x N (Sonnet)"]
        Inspector1["Inspector x 4-6 (Sonnet)"]
    end

    User <-->|"interaction"| Lead
    Lead -->|"TeammateTool spawn"| Architect
    Lead -->|"TeammateTool spawn"| Auditor
    Lead -->|"TeammateTool spawn"| TaskGen
    Lead -->|"TeammateTool spawn"| Builder1
    Lead -->|"TeammateTool spawn"| Inspector1
    Architect -.->|"idle notification"| Lead
    Auditor -.->|"idle notification (verdict)"| Lead
    TaskGen -.->|"idle notification"| Lead
    Builder1 -.->|"idle notification"| Lead
    Inspector1 -->|"SendMessageTool (CPF)"| Auditor

    style T1 fill:#e8f4f8,stroke:#2196F3
    style T2 fill:#fff3e0,stroke:#FF9800
    style T3 fill:#e8f5e9,stroke:#4CAF50
```

### Phase State Machine

```mermaid
stateDiagram-v2
    [*] --> initialized : spec created
    initialized --> design_generated : /sdd-design completes
    design_generated --> implementation_complete : /sdd-impl completes
    implementation_complete --> design_generated : revision (user request)
    initialized --> blocked : upstream failure
    design_generated --> blocked : upstream failure
    blocked --> initialized : unblock (fix/skip) - restore blocked_at_phase
    blocked --> design_generated : unblock (fix/skip) - restore blocked_at_phase

    state blocked {
        [*] --> waiting
        waiting : blocked_by = {failed_spec}
        waiting : reason = upstream_failure
        waiting : blocked_at_phase saved
    }
```

### Teammate Lifecycle Sequence

```mermaid
sequenceDiagram
    participant U as User
    participant L as Lead (T1)
    participant TM as Teammate (T2/T3)

    U->>L: command request
    L->>L: Phase Gate check
    alt phase valid
        L->>TM: TeammateTool spawn<br/>(context: feature, paths, scope)
        TM->>TM: Execute work autonomously
        TM->>TM: Generate artifacts
        TM-->>L: Idle notification<br/>(completion report)
        L->>L: Extract results
        L->>L: Update spec.yaml
        L->>L: Auto-draft session.md
        L->>L: Update buffer.md
        L->>TM: requestShutdown
        TM-->>L: approve & terminate
        L->>U: Report results
    else phase invalid
        L->>U: BLOCK error
    end
```

### Review Pipeline Sequence

```mermaid
sequenceDiagram
    participant L as Lead (T1)
    participant I1 as Inspector 1
    participant I2 as Inspector 2
    participant IN as Inspector N
    participant A as Auditor

    L->>I1: TeammateTool spawn
    L->>I2: TeammateTool spawn
    L->>IN: TeammateTool spawn
    L->>A: TeammateTool spawn

    par Parallel Inspection
        I1->>I1: Review & generate CPF
        I2->>I2: Review & generate CPF
        IN->>IN: Review & generate CPF
    end

    I1->>A: SendMessageTool (CPF findings)
    I2->>A: SendMessageTool (CPF findings)
    IN->>A: SendMessageTool (CPF findings)
    A->>A: Merge findings + Product Intent check
    A-->>L: Idle notification (verdict)
    L->>L: Process verdict (GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED)
```

### Inspector Recovery Sequence

```mermaid
sequenceDiagram
    participant L as Lead
    participant Ix as Inspector (unresponsive)
    participant Ix2 as Inspector (retry)
    participant A as Auditor

    L->>L: Detect Inspector unresponsive
    L->>Ix: requestShutdown
    L->>Ix2: TeammateTool spawn (same type, new name)
    alt retry succeeds
        Ix2->>A: SendMessageTool (CPF)
    else retry fails
        L->>A: SendMessageTool<br/>("Inspector {name} unavailable.<br/>Proceed with N-1/N results.")
        A->>A: Record missing Inspector in NOTES
    end
```

### Auditor Recovery Sequence

```mermaid
sequenceDiagram
    participant L as Lead
    participant A1 as Auditor (unresponsive)
    participant A2 as Auditor (retry)

    L->>L: Detect Auditor idle without verdict
    L->>A1: SendMessageTool (nudge)
    alt responds with verdict
        A1-->>L: Verdict output
    else no response
        L->>A1: requestShutdown
        L->>A2: TeammateTool spawn (RECOVERY MODE,<br/>Inspector CPF in context)
        alt retry succeeds
            A2-->>L: Verdict output
        else retry fails
            L->>L: Derive conservative verdict<br/>from Inspector results
            Note over L: NOTES: AUDITOR_UNAVAILABLE<br/>lead-derived verdict
        end
    end
```

### Technology Stack
| Layer | Choice / Version | Role in Feature | Notes |
|-------|------------------|-----------------|-------|
| Agent API | Claude Code Agent Teams | `TeammateTool`, `SendMessageTool` による multi-agent orchestration | Experimental (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) |
| Configuration | `settings.json` (JSON) | Agent Teams 有効化、Bash パーミッション定義 | |
| Framework Definition | `CLAUDE.md` (Markdown) | フレームワーク全体の振る舞い定義 | テンプレート変数 `{{SDD_VERSION}}` 使用 |
| Model (T1/T2) | Opus | Lead, Architect, Auditor の推論 | 高精度な判断が必要なロール |
| Model (T3) | Sonnet | TaskGenerator, Builder, Inspector の実行 | コスト効率重視のロール |

## System Flows

### Flow 1: Phase Gate Enforcement
1. ユーザーがコマンドを発行する
2. Lead は対象 spec の `spec.yaml.phase` を読み取る
3. phase が `blocked` → `"{feature} is blocked by {blocked_info.blocked_by}"` でブロック
4. phase が未知の値 → `"Unknown phase '{phase}'"` でブロック
5. phase が要求オペレーションに適切でない → エラーを報告
6. phase が適切 → teammate spawn に進む

### Flow 2: Standard Teammate Lifecycle
1. Lead が `TeammateTool` で teammate を spawn（spawn prompt にコンテキストを含む）
2. Teammate が自律的に作業実行
3. Teammate が structured completion report を出力
4. Teammate が idle になり、idle notification を Lead に送信
5. Lead が idle notification から結果を抽出
6. Lead が spec.yaml を更新（phase, version_refs, changelog）
7. Lead が session.md を auto-draft、decisions.md に記録、buffer.md を更新
8. Lead が次のアクションを決定
9. Lead が teammate に `requestShutdown` を送信
10. Teammate が approve して終了

### Flow 3: Builder Parallel Coordination
1. Lead が複数 Builders を並列 spawn
2. 各 Builder が独立して作業を実行
3. Builder の completion report が到着するたびに:
   a. tasks.yaml の完了タスクを `done` にマーク
   b. ファイルを収集
   c. Knowledge tags を保存
4. 次 wave のタスクがアンブロックされた場合、完了した Builder を dismiss して次 wave Builders を即座に spawn
5. 全 Builders 完了後に spec.yaml を最終更新（phase, implementation.files_created）

### Flow 4: Inspector Recovery
1. Lead が Inspector の無応答を検出
2. 他の Inspectors の idle notification 到着状況を確認
3. 無応答 Inspector に `requestShutdown` を実行
4. 同一 agent type で新名前の Inspector を `TeammateTool` で再 spawn（1回リトライ）
5. リトライ成功 → 通常フロー継続
6. リトライ失敗 → Lead が `SendMessageTool` で Auditor に N-1/N 続行を通知

### Flow 5: Auditor Recovery
1. Auditor が verdict 出力前に idle になったことを検出
2. Lead が `SendMessageTool` でナッジ送信
3. 応答あり → 通常フロー復帰
4. 応答なし → `requestShutdown` で停止、RECOVERY MODE で Auditor を再 spawn
5. リトライ成功 → verdict 取得
6. リトライ失敗 → Lead が Inspector results から保守的 verdict を導出

## Components and Interfaces

| Component | Domain/Layer | Intent | Files |
|-----------|--------------|--------|-------|
| Role Architecture | CLAUDE.md / Framework Core | 3-Tier Hierarchy 定義、各ロールの責務、Tier-Model マッピング | `framework/claude/CLAUDE.md` (§Role Architecture) |
| Chain of Command | CLAUDE.md / Framework Core | TeammateTool/Task tool の使い分け、通信経路、completion report パターン | `framework/claude/CLAUDE.md` (§Chain of Command) |
| State Management | CLAUDE.md / Framework Core | spec.yaml 所有権、teammate の artifact 生成→Lead の metadata 更新フロー | `framework/claude/CLAUDE.md` (§State Management) |
| Artifact Ownership | CLAUDE.md / Framework Core | design.md/research.md/tasks.yaml/code の所有権マトリクス、Lead の操作制限 | `framework/claude/CLAUDE.md` (§Artifact Ownership) |
| Phase Gate | CLAUDE.md / Framework Core | phase 遷移制御、blocked/unknown phase ハンドリング、gate enforcement | `framework/claude/CLAUDE.md` (§Phase Gate) |
| Teammate Lifecycle | CLAUDE.md / Framework Core | spawn→execute→idle→dismiss サイクル、Builder 並列 coordination | `framework/claude/CLAUDE.md` (§Teammate Lifecycle) |
| Agent Teams Constraints | CLAUDE.md / Framework Core | No shared memory、messaging 方向性、concurrent limit、consensus mode | `framework/claude/CLAUDE.md` (§Agent Teams Known Constraints) |
| Inspector Recovery | CLAUDE.md / Recovery | Inspector 無応答時の shutdown→re-spawn→degrade フロー | `framework/claude/CLAUDE.md` (§Inspector Recovery) |
| Auditor Recovery | CLAUDE.md / Recovery | Auditor 無応答時の nudge→re-spawn(RECOVERY MODE)→lead-derived verdict フロー | `framework/claude/CLAUDE.md` (§Auditor Recovery) |
| Behavioral Rules | CLAUDE.md / Behavioral | Compact 後の行動制約、自律性スコープ、質問ポリシー | `framework/claude/CLAUDE.md` (§Behavioral Rules) |
| Execution Conventions | CLAUDE.md / Behavioral | Bash コマンドフォーマット、steering 参照、inline script runtime | `framework/claude/CLAUDE.md` (§Execution Conventions) |
| Git Workflow | CLAUDE.md / Workflow | Trunk-based development、branch strategy、commit timing、release flow | `framework/claude/CLAUDE.md` (§Git Workflow) |
| Settings Configuration | Configuration | Agent Teams 環境変数、Bash パーミッション | `framework/claude/settings.json` |
