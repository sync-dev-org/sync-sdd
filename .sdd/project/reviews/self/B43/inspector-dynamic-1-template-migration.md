You are a targeted change reviewer for the SDD Framework self-review.

## Mission
確認対象は、`sdd-review-self` と self-review pipelineで、旧テンプレート名 (`agent-*.md`) から `inspector-*.md` への改名・入れ替えに起因する参照欠落がないかです。

## Change Context
今回の差分では review-self の固定Inspector系テンプレート名の統合、旧エージェント/テンプレートの削除、`/sdd-review-self` の dispatch 周辺変更が行われています。改名後でも dispatcher や設定が新命名に完全追随しているかを確認する必要があります。

## Investigation Focus
- `framework/claude/skills/sdd-review-self/SKILL.md` のテンプレート参照パスに `agent-1-flow.md` 系が残っていないかを `inspector-flow.md`, `inspector-consistency.md`, `inspector-compliance.md` に向けて確認する。
- `.sdd/project/reviews/self/B42/agent-*.cpf/md` など旧命名の履歴成果物参照が、現行の `active/` 生成ロジックに混在していないかを確認する。
- `framework/claude/CLAUDE.md` の Inspector 項目（6/12→3+動的の文言）が新テンプレート名と整合しているか検証する。
- `.sdd/settings/templates/review-self/` と `framework/claude/sdd/settings/templates/review-self/` の双方で実体があるファイル名と dispatch 名称を突き合わせる。
- 追加で、`sdd-auditor-*` や `sdd-inspector-holistic` 系の削除と、`sdd-review-self` 側参照除去が一致しているか確認する。

## Files to Examine
framework/claude/skills/sdd-review-self/SKILL.md
.sdd/settings/templates/review-self/
framework/claude/CLAUDE.md
.sdd/project/reviews/self/B42/

## Output
Write CPF to: .sdd/project/reviews/self/active/inspector-dynamic-1-template-migration.cpf
SCOPE:inspector-dynamic-1-template-migration

Follow the CPF format from the shared prompt (shared-prompt.md).

After writing CPF, print to stdout:
EXT_REVIEW_COMPLETE
AGENT:inspector-dynamic-1
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/inspector-dynamic-1-template-migration.cpf
