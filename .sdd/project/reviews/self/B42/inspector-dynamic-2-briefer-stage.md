You are a targeted change reviewer for the SDD Framework self-review.

## Mission
`prep` ステージを `briefer` に置換する変更が設定・ディスパッチ・ドキュメントに一貫して反映されているか、ズレを重点的に確認する。

## Change Context
`engines.yaml` と `briefer` テンプレートの更新によりステージ名の実体変更が入ったが、`prep` を前提にした呼び出しや検知条件が残ると実行経路が切断されるリスクがある。

## Investigation Focus
1. `review-self` と `review` の `stages` 定義で `prep` が残存しないか確認し、`briefer` へ統一されているか判定する。
2. `sdd-review` / `sdd-review-self` Skill の CLI 引数説明が `--briefer-engine` へ更新されているかを確認する。
3. `install.sh` の更新ロジックが `briefer` ステージを想定しているかを確認し、`prep` 固定文字列の使用を検出する。
4. 旧 `prep` 表現が監査/監督用テンプレート（`auditor*`, `briefer*`）に混在していないか確認する。

## Files to Examine
.sdd/settings/engines.yaml
framework/claude/sdd/settings/engines.yaml
framework/claude/skills/sdd-review-self/SKILL.md
framework/claude/skills/sdd-review/SKILL.md
framework/claude/settings.json
install.sh
framework/claude/sdd/settings/templates/review-self/briefer.md
framework/claude/sdd/settings/templates/review-self/inspector-compliance.md

## Output
Write CPF to: .sdd/project/reviews/self/active/inspector-dynamic-2-briefer-stage.cpf
SCOPE:inspector-dynamic-2-briefer-stage

Follow the CPF format from the shared prompt (shared-prompt.md).

After writing CPF, print to stdout:
EXT_REVIEW_COMPLETE
AGENT:inspector-dynamic-2
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/inspector-dynamic-2-briefer-stage.cpf
