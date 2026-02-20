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
