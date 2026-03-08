You are a targeted change reviewer for the SDD Framework self-review.

## Mission
`sdd-skill-creator` スキルが削除されたが、フレームワーク全体に旧名称への参照が残存していないか検証する。

## Change Context
`framework/claude/skills/sdd-skill-creator/` 配下の全ファイル（SKILL.md, SKILL.md.bak, references/analyzer.md, comparator.md, grader.md, schemas.md, skill-writer.md）が削除された。後継は `sdd-forge-skill`。

## Investigation Focus
1. `CLAUDE.md` のコマンド一覧・説明文・トリガー記述に `sdd-skill-creator` が残っていないか
2. `framework/claude/settings.json` の `Skill(sdd-skill-creator *)` または `Agent(sdd-skill-creator *)` エントリが残っていないか
3. 各 `SKILL.md` (sdd-review-self, sdd-roadmap, sdd-review, 等) の内部テキストに `sdd-skill-creator` への言及がないか
4. `install.sh` に `sdd-skill-creator` へのコピー・参照が残っていないか
5. `framework/claude/sdd/settings/templates/` 配下のテンプレートに `sdd-skill-creator` への言及がないか

## Files to Examine
- framework/claude/CLAUDE.md
- framework/claude/settings.json
- framework/claude/skills/sdd-*/SKILL.md (全スキル)
- framework/claude/skills/sdd-review-self/SKILL.md.bak1 (残存バックアップファイルの存在確認)
- install.sh
- framework/claude/sdd/settings/templates/review-self/*.md

## Output
Write YAML findings to: .sdd/project/reviews/self/active/findings-inspector-dynamic-1-skill-creator-residue.yaml

YAML format:
scope: "inspector-dynamic-1-skill-creator-residue"
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
AGENT:inspector-dynamic-1
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/findings-inspector-dynamic-1-skill-creator-residue.yaml
