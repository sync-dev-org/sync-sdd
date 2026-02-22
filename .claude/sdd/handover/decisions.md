[2026-02-20T00:00:00Z] D1: SESSION_START | Retroactive spec creation session
- Context: 既存実装 (v0.17.0) に対する後追いスペック作成
- Decision: ステアリング + ロードマップ + スペックを SDD スキルで作成
- Reason: 今後の改修・機能追加の管理基盤として
- Impact: .claude/sdd/project/ 配下に全アーティファクト生成

[2026-02-20T00:01:00Z] D2: USER_DECISION | 細かめ粒度 (15 spec) を採用
- Context: 粗め (8-9個) vs 細かめ (14-16個) vs 最小 (5-6個) の選択
- Decision: 細かめ (15 spec / 6 wave) を採用
- Reason: 改修・機能追加への強さとミス防止を優先。変更スコープが明確で、レビュー精度が高い
- Impact: 管理するスペック数は多いが、SDD 自体が管理する仕組みなので問題にならない
- Source: ユーザー判断

[2026-02-20T12:00:00Z] D3: SESSION_START | release-automation revision session
- Context: sdd-release スキルの改善
- Reason: hatch-vcs プロジェクトでリリース後のバージョン検証が不足

[2026-02-20T12:01:00Z] D4: REVISION_INITIATED | release-automation にバージョン検証ステップを追加
- Context: Python (hatch-vcs) プロジェクトでリリース後に `importlib.metadata.version()` が古いバージョンを返す問題。パッケージメタデータのリフレッシュ (`uv sync --reinstall-package`) が必要
- Decision: release-automation spec を revise し、リリース後バージョン検証ステップを全エコシステムに追加。hatch-vcs 向けには明示的なメタデータリフレッシュ手順を含める
- Reason: ユーザーがリリース時に手動で問題を発見・修正する必要があった。`uv pip install -e` は誤りで `uv sync --reinstall-package` が正しい
- Impact: sdd-release SKILL.md に検証ステップ追加。downstream: installer (影響軽微)
- Source: ユーザー報告

[2026-02-20T12:30:00Z] D5: USER_DECISION | installer downstream Skip
- Context: release-automation revision (Step 9 追加) 完了後の downstream 対応
- Decision: installer (Wave 6) は Skip — 現状のまま受け入れ
- Reason: Step 9 (Post-Release Verification) の追加は install.sh のスコープに影響しない
- Impact: installer は implementation-complete のまま。再レビュー不要
- Source: ユーザー判断

[2026-02-20T13:00:00Z] D6: SESSION_END | release-automation revision + Change Request Triage ルール追加
- Context: /sdd-handover executed
- Decision: Session ended, handover archived

[2026-02-20T14:00:00Z] D7: SESSION_START | Resume session
- Context: 前セッション完了後の再開。全15 spec implementation-complete、MINOR 12件未修正

[2026-02-21T14:58:00Z] D8: STEERING_UPDATE | Auto-Fix Loop ownership を tech.md に CODIFY
- Context: Design cross-check review (B1) — Auditor STEERING:CODIFY
- Decision: Auto-Fix Loop は各レビュー spec（design-review, impl-review）にスタンドアロン用の完全な定義を持ち、roadmap-orchestration が Wave レベルの調整層として機能する
- Reason: 3 spec に Auto-Fix Loop の完全定義が分散しているが、これは意図的な設計（standalone vs roadmap context）
- Impact: tech.md Key Technical Decisions に記録。実装者が「どの spec が canonical か」を判断できる
- Source: Auditor verdict (B1 cross-check)

[2026-02-21T15:00:00Z] D9: STEERING_UPDATE | Auditor timeout 方針を tech.md に PROPOSE承認
- Context: Design cross-check review (B1) — Auditor STEERING:PROPOSE
- Decision: 「合理的な待機後」タイムアウトは実装裁量とし固定値を規定しない。Agent Teams メッセージ配信は非決定的でプラットフォーム依存。Lead Recovery Protocol が障害ケースを処理する
- Reason: 固定タイムアウトは aggressive/conservative のどちらにも偏るリスク
- Impact: tech.md Key Technical Decisions に記録
- Source: Auditor PROPOSE → ユーザー承認

[2026-02-21T15:00:01Z] D10: STEERING_UPDATE | Agent Teams API 依存方針を tech.md に PROPOSE承認
- Context: Design cross-check review (B1) — Auditor STEERING:PROPOSE
- Decision: Agent Teams experimental API 依存をフォールバックなしで受け入れる。フレームワークは Agent Teams 専用設計であり graceful degradation は根本的に異なるアーキテクチャを要する。install.sh のバージョン固定でリスク軽減
- Reason: フォールバック設計はコスト対効果が不合理
- Impact: tech.md Key Technical Decisions に記録
- Source: Auditor PROPOSE → ユーザー承認

[2026-02-21T15:02:00Z] D11: STEERING_UPDATE | dead-code review Auto-Fix スコープ明確化を PROPOSE承認
- Context: Design cross-check review (B1) — Auditor STEERING:PROPOSE
- Decision: dead-code review pipeline は verdict 出力のみ。post-verdict の Builder re-spawn は roadmap-orchestration (Lead) の責務。dead-code-review Non-Goals の「Auto-Fix Loop なし」を明確化する
- Reason: dead-code-review spec 単体では auto-fix なしだが、roadmap context では Lead が外部的に auto-fix を実行する。現状の表現は misleading
- Impact: tech.md に方針記録。design.md の実際の変更は `/sdd-roadmap revise dead-code-review` で Architect 経由で実施
- Source: Auditor PROPOSE → ユーザー承認

[2026-02-21T15:10:00Z] D12: REVISION_INITIATED | dead-code-review Non-Goals Auto-Fix スコープ明確化
- Context: D11 で承認された PROPOSE を design.md に反映するための revision
- Decision: Non-Goals の「Auto-Fix Loop なし」を「このパイプラインは verdict 出力のみ。Wave Quality Gate での post-verdict remediation は roadmap-orchestration の責務」に明確化
- Reason: dead-code-review spec 単体読みで誤解を招く表現の修正
- Impact: dead-code-review design.md Non-Goals セクションの1行修正。downstream 影響なし
- Source: ユーザー指示 (`/sdd-roadmap revise dead-code-review`)

[2026-02-21T15:22:00Z] D13: USER_DECISION | dead-code-review revision downstream Skip
- Context: dead-code-review revision (Non-Goals 表現修正) 完了後の downstream 対応
- Decision: roadmap-orchestration, installer ともに Skip — 現状のまま受け入れ
- Reason: インターフェースや振る舞いの変更なし。Non-Goals の表現明確化のみ
- Impact: downstream specs は implementation-complete のまま。再レビュー不要
- Source: ユーザー判断

[2026-02-21T15:30:00Z] D14: REVISION_INITIATED | design-review Inspector Completion Trigger 追加
- Context: Auditor が verdict テキスト出力に失敗するパターンを2回観測。Inspector 全完了後に Lead が Auditor に明示的トリガーを送信する仕組みを追加
- Decision: SKILL.md Step 3 に Inspector Completion Trigger プロトコルを追加
- Reason: Agent Teams の multi-turn message handling で Auditor が「全結果到着」を確実に検知できない問題
- Impact: sdd-review SKILL.md に共通サブセクション追加。impl-review, dead-code-review も自動カバー
- Source: ユーザー指示

[2026-02-21T15:35:00Z] D15: STEERING_UPDATE | Revision Notes convention を tech.md に CODIFY
- Context: Design review (B1) for design-review v1.1.0 — Auditor STEERING:CODIFY
- Decision: design.md の Revision Notes セクションは revision 単位の変更履歴として使用する（テンプレート拡張）
- Reason: dead-code-review, design-review の revision で既に使用中のパターンを正式化
- Impact: tech.md Key Technical Decisions に記録
- Source: Auditor verdict (design-review B1)

[2026-02-21T15:38:00Z] D16: STEERING_UPDATE | SendMessage discrimination 方針を tech.md に PROPOSE承認
- Context: Design review (B1) for design-review v1.1.0 — Auditor STEERING:PROPOSE
- Decision: 現時点では message-type discriminator を導入せず content pattern match で区別。将来の再検討を妨げない
- Reason: Inspector CPF と Lead トリガーの内容は明確に異なり、実際の誤判別は発生していない。ただし channel 複雑化時には再検討の余地あり
- Impact: tech.md Key Technical Decisions に記録。将来の PROPOSE を自動却下するものではない
- Source: Auditor PROPOSE → ユーザー承認（条件付き: 将来の見直し可）

[2026-02-21T17:30:00Z] D17: SESSION_END | Design cross-check + Inspector Completion Trigger + v0.17.2 release
- Context: /sdd-handover executed
- Decision: Session ended, handover archived

[2026-02-21T18:00:00Z] D18: SESSION_START | Resume session
- Context: v0.17.2 リリース完了後の再開。全15 spec implementation-complete

[2026-02-22T00:00:00Z] D19: DIRECTION_CHANGE | Roadmap Router化 + ファイルベースレビュー + SubAgent防止 (v0.18.0)
- Context: roadmap run 動作から外れた際に個別コマンドが使われ、roadmap.md 乖離・Agent Teams 不使用が発生
- Decision: (1) /sdd-roadmap を統合エントリポイント化、個別コマンド廃止 (2) Agent定義を sdd/settings/agents/ に移動（SubAgent spawn 構造的排除）(3) ファイルベースレビュー（SendMessage 排除）(4) Recovery Protocol 廃止
- Reason: SendMessage ベースの Inspector→Auditor 通信が Auditor idle の根本原因。SubAgent spawn が Agent Teams 通信不成立の原因。個別コマンドの存在が roadmap コンテキスト離脱の原因
- Impact: v0.18.0 リリース。全 skill/agent/CLAUDE.md を更新。既存 retroactive spec 15件は旧アーキテクチャ前提のまま（改修時に revise で更新）
- Source: ユーザー指示

[2026-02-22T03:30:00Z] D20: SESSION_END | Roadmap Router + file-based review + v0.18.0 release
- Context: /sdd-handover executed
- Decision: Session ended, handover archived

[2026-02-22T10:00:00Z] D21: USER_DECISION | v0.18.0 Spec Retroactive Alignment — Architect 経由・実装変更なし
- Context: v0.18.0 構造変更 (Router化, ファイルベースレビュー, agent移動, Recovery廃止) が spec を通さず Lead 直接で行われていた。12 spec の design.md/spec.yaml が実装と乖離
- Decision: Architect を各 spec に spawn し design.md を現実装に追従。Review/Builder skip（実装変更なし）。Lead が spec.yaml メタデータを更新
- Reason: 正規パイプラインを通す（option 1）が、実装は変えない。Architect が design.md を書くことで Artifact Ownership ルールを遵守
- Impact: 12 spec の design.md + spec.yaml 更新、roadmap.md に Alignment History 追加。release-automation, cpf-protocol, session-persistence は変更不要
- Source: ユーザー判断

[2026-02-22T12:00:00Z] D22: USER_DECISION | .gitignore: インストール済みフレームワーク除外
- Context: .claude/ 配下のインストール先ファイルが git tracked で混乱を招いていた
- Decision: .claude/CLAUDE.md, settings.json, skills/, sdd/settings/, sdd/.version を gitignore。project/ と handover/ は tracked 維持
- Reason: framework/ がソース、.claude/ はインストール先。二重管理の解消
- Impact: git rm --cached でトラッキング除外。ファイルは残るが git 管理外に
- Source: ユーザー指示

[2026-02-22T12:30:00Z] D23: SESSION_END | v0.18.0 spec alignment + gitignore cleanup
- Context: /sdd-handover executed
- Decision: Session ended, handover archived

[2026-02-22T14:00:00Z] D24: SESSION_START | Resume session
- Context: v0.18.1 リリース完了後の再開。全15 spec implementation-complete、ワークツリーclean
