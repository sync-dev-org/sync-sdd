You are a targeted change reviewer for the SDD Framework self-review.

## Mission
検証対象は、旧来の `agent-*` 前段・CPF ベース前提から `inspector-*` と YAML ベースへの移行で発生する参照崩れです。新旧名称の混在で、削除済みファイルを参照している箇所がないかを重点確認します。

## Change Context
この更新で `sdd-review-self` のテンプレート群、Skill 定義、`settings.json`、および `CLAUDE.md` の出力命名が `agent-*` から `inspector-*` に置換され、監査/準備役の命名体系と実体が同時に変わっています。

## Investigation Focus
- `framework/claude/skills/sdd-review-self/SKILL.md` と `framework/claude/settings.json` が、削除済みの `agent-*` 命名を参照していないか。
- `framework/claude/sdd/settings/templates/review-self/*.md` のうち、実際に存在しない旧テンプレート名（`agent-1-flow`, `agent-2-changes`, `agent-3-consistency`, `agent-4-compliance`, `auditor`, `prep`）を参照していないか。
- `framework/claude/CLAUDE.md` のコマンド回数・Inspector 名称と、SKILL 側で起動される固定/動的 Inspector 数が一致しているか。
- 削除済みの `framework/claude/agents/sdd-auditor-*.md`・`sdd-inspector-*-holistic.md` が、固定 Inspector の契約先として新規命名に追従しているか。

## Files to Examine
framework/claude/skills/sdd-review-self/SKILL.md
framework/claude/settings.json
framework/claude/CLAUDE.md
framework/claude/sdd/settings/templates/review-self/*.md
framework/claude/agents/

## Output
Write YAML findings to: .sdd/project/reviews/self/active/findings-inspector-dynamic-1-template-migration.yaml

YAML format:
```yaml
scope: "inspector-dynamic-1-template-migration"
issues:
  - id: "F1"
    severity: "H"
    category: "migration"
    location: "{file}:{line}"
    description: "{what}"
    impact: "{why}"
    recommendation: "{how}"
notes: |
  Additional context
```

After writing, print to stdout:
EXT_REVIEW_COMPLETE
AGENT:inspector-dynamic-1
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/findings-inspector-dynamic-1-template-migration.yaml
