# Research & Design Decisions: design-review

## Summary
- **Feature**: design-review
- **Discovery Scope**: Extension (Spec 15 addition to existing design)
- **Key Findings**:
  - Agent Teams の SendMessage は各メッセージが新しいターンを生成するため、Auditor 側で全 Inspector 結果到着を確実に検知する仕組みがない
  - Lead は Inspector の idle notification を通じて全 Inspector の完了状態を既に把握しており、明示的トリガーの送信元として最適
  - 既存の Auditor Recovery Protocol（nudge → re-spawn → lead-derived verdict）はトリガー後の安全ネットとして維持可能

## Research Log

### Agent Teams メッセージ配信の非決定性
- **Context**: Auditor が Inspector からの SendMessage を受信する際、全件到着の検知方法に課題がある
- **Sources Consulted**: CLAUDE.md Agent Teams Known Constraints セクション、tech.md Key Technical Decisions
- **Findings**:
  - Agent Teams では各 SendMessage が新しいターンを生成する
  - メッセージ配信順序はプラットフォーム依存で非決定的
  - Auditor は "何件の Inspector が存在するか" を spawn context から知っているが、全件到着をタイムアウト以外で判定する標準的な仕組みがない
  - tech.md に "Auditor timeout: Inspector 結果待ちのタイムアウトは実装裁量（固定値なし）" と記載あり
- **Implications**: Lead から明示的な completion trigger を送ることで、Auditor のタイムアウト依存を排除し、合成開始タイミングを確定できる

### Lead の Inspector 完了状態の把握
- **Context**: Lead が全 Inspector 完了を検知できる根拠の確認
- **Sources Consulted**: CLAUDE.md Teammate Lifecycle セクション、Teammate Recovery Protocol セクション
- **Findings**:
  - Lead は各 teammate の idle notification を読み取る（標準の通信パターン）
  - Inspector Recovery Protocol において、Lead は既に "idle notification の到着状況を確認" している（Step 1）
  - Recovery Protocol 完了後も Lead は最終的な Inspector 可用状況を把握している
- **Implications**: Inspector completion tracking は Lead の既存責務の自然な拡張であり、新しいインフラは不要

### 全レビュータイプへの適用
- **Context**: Spec 15 が design review 以外にも適用されるかの確認
- **Sources Consulted**: spec.yaml implementation.files_created、sdd-review SKILL.md の構造
- **Findings**:
  - sdd-review SKILL.md は design/impl/dead-code の3モードを共通で処理する
  - Inspector → Auditor の通信パターンは3モード共通
  - impl-review は6 Inspector、dead-code-review は4 Inspector だが、completion trigger のロジックは Inspector 数に依存しない（N/N 形式）
- **Implications**: Spec 15 は sdd-review SKILL.md の共通ロジックとして実装され、全3モードに自動的に適用される

## Design Decisions

### Decision: Lead-initiated completion trigger
- **Context**: Auditor が Inspector 結果の全件到着を確実に検知できない問題
- **Alternatives Considered**:
  1. Auditor 側タイムアウト — 一定時間経過後に到着済み結果で処理開始
  2. Inspector カウンタ — Auditor が受信カウントを管理し、期待数と比較
  3. Lead-initiated trigger — Lead が全 Inspector 完了を検知し、Auditor に明示的に合成開始を指示
- **Selected Approach**: Option 3 (Lead-initiated trigger)
- **Rationale**: Lead は idle notification の受信により全 Inspector の完了を確実に把握している。タイムアウトベースは不必要な待機または早期打ち切りのリスクがある。Inspector カウンタは Agent Teams のターン生成メカニズムにより信頼性が低い
- **Trade-offs**: Lead → Auditor の追加 SendMessage が1回増えるが、確実な合成開始と引き換えに許容範囲内
- **Follow-up**: Consensus mode での各パイプライン個別トリガーの実装確認

## Risks & Mitigations
- Risk: トリガー SendMessage 自体が配信されない可能性 — 既存の Auditor Recovery Protocol（nudge → re-spawn）が安全ネットとして機能する
- Risk: 部分的な Inspector 結果でのトリガー送信が早すぎる可能性 — Recovery Protocol の処理完了を待ってからトリガーを送信する設計で対処

## References
- CLAUDE.md Teammate Recovery Protocol セクション — Inspector/Auditor Recovery の既存仕様
- CLAUDE.md Agent Teams Known Constraints — メッセージング制約
- tech.md Key Technical Decisions — Auditor timeout の設計方針
- D14 decision (decisions.md) — この仕様追加の決定根拠
