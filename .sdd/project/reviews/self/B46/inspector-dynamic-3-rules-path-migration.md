You are a targeted change reviewer for the SDD Framework self-review.

## Mission
`rules/` フラット構造から `rules/agent/` + `rules/lead/` への再編成が完全に反映されているか検証する。

## Change Context
以下のファイルが `framework/claude/sdd/settings/rules/` 直下から各サブディレクトリへ移動した:
- `rules/agent/`: design-discovery-full.md, design-discovery-light.md, design-principles.md, design-review.md, steering-principles.md, tasks-generation.md, verdict-format.md
- `rules/lead/`: bash-security-heuristics.md, tmux-integration.md

## Investigation Focus
1. `framework/claude/CLAUDE.md` 内のすべての rules ファイル参照が新パス (`rules/agent/` or `rules/lead/`) を使っているか — 旧パス (`rules/verdict-format.md` 等) が残っていないか
2. 各 `SKILL.md` ファイル (sdd-roadmap, sdd-review, sdd-review-self, sdd-architect 等) 内の rules ファイル参照が新パスを使っているか
3. `framework/claude/agents/sdd-*.md` 内の rules ファイル参照が新パスを使っているか
4. `install.sh` の copy コマンド群が新ディレクトリ構造に対応しているか（`rules/` 配下のコピー先・コピー元が正しいか）
5. `framework/claude/sdd/settings/templates/` 内のテンプレートに旧パスが残っていないか

## Files to Examine
- framework/claude/CLAUDE.md
- framework/claude/skills/sdd-roadmap/SKILL.md
- framework/claude/skills/sdd-review/SKILL.md
- framework/claude/skills/sdd-review-self/SKILL.md
- framework/claude/agents/sdd-architect.md
- framework/claude/agents/sdd-taskgenerator.md
- framework/claude/agents/sdd-builder.md
- install.sh

## Output
Write YAML findings to: .sdd/project/reviews/self/active/findings-inspector-dynamic-3-rules-path-migration.yaml

YAML format:
scope: "inspector-dynamic-3-rules-path-migration"
issues:
  - id: "F1"
    severity: "H"
    category: "{category}"
    location: "{file}:{line}"
    summary: "{one-line summary}"
    detail: "{what}"
    impact: "{why}"
    recommendation: "{how}"
notes: |
  Additional context

After writing, print to stdout:
EXT_REVIEW_COMPLETE
AGENT:inspector-dynamic-3
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/findings-inspector-dynamic-3-rules-path-migration.yaml
