You are a targeted change reviewer for the SDD Framework self-review.

## Mission
Validate the handover→session ディレクトリ移行（`session/decisions.yaml`, `session/knowledge.yaml`, `session/state.yaml`）が、全実行パスで旧 `handover/` 想定と矛盾なく反映されているかを確認します。

## Change Context
`install.sh` に移行処理が追加され、関連する SKILL/Agent が新パスを参照するよう更新されています。移行処理に未対応の実行スクリプトが残ると実データ喪失や再開不能が起きます。

## Investigation Focus
1. install.sh のバージョン判定条件と移行実行条件が、`session/` への実ファイル移し替えと一致しているか
2. `sdd-start` / `sdd-handover` / `sdd-review` / `sdd-review-self` の各 SKILL/Agent で `decisions.yaml`, `knowledge.yaml`, `state.yaml` の参照先が一致しているか
3. 旧 `decisions.md`, `buffer.md`, `session.md`, `.sdd/handover` の残存参照を含む箇所があるか
4. `session/state.yaml` の上書き・再利用ロジックで `run` 再開時に SID/window が破損しないか

## Files to Examine
install.sh
framework/claude/CLAUDE.md
framework/claude/skills/sdd-start/SKILL.md
framework/claude/skills/sdd-start/SKILL.md
framework/claude/skills/sdd-handover/SKILL.md
framework/claude/skills/sdd-review/SKILL.md
framework/claude/skills/sdd-review-self/SKILL.md
framework/claude/skills/sdd-roadmap/SKILL.md
framework/claude/sdd/settings/rules/tmux-integration.md

## Output
Write YAML findings to: .sdd/project/reviews/self/active/findings-inspector-dynamic-2-session-migration.yaml

YAML format:
```yaml
scope: "inspector-dynamic-2-session-migration"
issues:
  - id: "F1"
    severity: "H"
    category: "{category}"
    location: "{file}:{line}"
    summary: "{one-line summary}"    detail: "{what}"
    impact: "{why}"
    recommendation: "{how}"
notes: |
  Additional context
```
