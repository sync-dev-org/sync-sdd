# Product Overview

Spec-Driven Development (SDD) framework for Claude Code. AI-DLC (AI Development Life Cycle) を実現する3-tier Agent Teamアーキテクチャ。

## User Intent

### Vision

Claude Codeのエージェント機能を活用し、仕様駆動・フェーズゲート付きの開発ワークフローを提供する。人間の開発者がSpecificationを起点に、設計→レビュー→実装→レビューの一貫したパイプラインをAIチームに委譲できる世界。

### Success Criteria

- 9つのスキルコマンドで設計〜リリースまでの全フェーズをカバー
- 3-tier Agent Teams (Lead/Brain/Execute) による自律的なタスク遂行
- Phase gateによる品質保証（フェーズ飛ばし不可）
- Auto-fix loopによる自動修復（NO-GO → 自動リトライ → エスカレーション）
- Knowledge auto-accumulationによるプロジェクト横断の学習
- install.shによるワンライナーインストール・アップデート

### Anti-Goals

- Claude Code以外のAIツールへの対応（Cursor, Copilot等）
- ランタイムやビルドシステムの提供（フレームワークはMarkdown + YAML + Bashのみ）
- GUIやWebダッシュボード
- spec.yamlの自動マージ・コンフリクト解消（Lead手動管理）
- Agent Teams API以外の通信機構

## Spec Rationale

15 spec / 6 wave 構成。パイプライン単位で分割し、改修時の影響範囲を最小化。

- **Wave 1 (Foundation)**: core-architecture, cpf-protocol — 全体の基盤。他の全スペックが依存
- **Wave 2 (Steering & Design)**: steering-system, design-pipeline — プロジェクトコンテキストと設計生成
- **Wave 3 (Review & Tasks)**: design-review, task-generation — 設計品質ゲートとタスク分解
- **Wave 4 (Execution & Code Review)**: tdd-execution, impl-review, dead-code-review — 実装とコードレビュー
- **Wave 5 (Orchestration & Operations)**: roadmap-orchestration, session-persistence, knowledge-system, status-progress — マルチフィーチャー統合と運用
- **Wave 6 (Distribution)**: release-automation, installer — リリースと配布

分割基準: 独立して変更可能な単位。例えば Inspector の追加は該当する review spec のみに影響。

## Decision Log

- [2026-02-20] 粒度選択: 細かめ (14-16個) を採用。改修・機能追加への強さとミス防止を優先

---
_Lead updates this file as user intent evolves. Auditor references it during every review._
