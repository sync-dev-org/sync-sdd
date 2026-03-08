You are a targeted change reviewer for the SDD Framework self-review.

## Mission
`sdd-review-self` の大規模リフォージ後、新アーキテクチャ（Briefer → Inspector × N → Auditor 委譲モデル）が CLAUDE.md 記述・references/ テンプレート群・SKILL.md 間で整合しているか検証する。

## Change Context
`framework/claude/skills/sdd-review-self/SKILL.md` が全面リライトされ、新たに以下の references/ が追加された:
- briefer.md, auditor.md, inspector-flow.md, inspector-consistency.md, inspector-compliance.md, shared-prompt-structure.md

旧 SKILL.md は `SKILL.md.bak1` として残存している。

## Investigation Focus
1. CLAUDE.md の `sdd-review-self` 説明（Inspector: 3 fixed + 1-4 dynamic）が SKILL.md の実装と一致しているか
2. SKILL.md 内の Briefer ディスパッチ手順が `references/briefer.md` のステップと矛盾していないか（ファイル名、出力先パス、出力形式）
3. SKILL.md 内の Auditor ディスパッチ手順が `references/auditor.md` の内容と整合しているか
4. `references/shared-prompt-structure.md` の Template 定義が Briefer の shared-prompt 生成ロジックと一致しているか
5. `SKILL.md.bak1` が `framework/claude/skills/sdd-review-self/` に残存していることの問題有無（バックアップファイルが install.sh でコピーされる場合は問題）

## Files to Examine
- framework/claude/skills/sdd-review-self/SKILL.md
- framework/claude/skills/sdd-review-self/references/briefer.md
- framework/claude/skills/sdd-review-self/references/auditor.md
- framework/claude/skills/sdd-review-self/references/shared-prompt-structure.md
- framework/claude/skills/sdd-review-self/references/inspector-flow.md
- framework/claude/skills/sdd-review-self/references/inspector-compliance.md
- framework/claude/CLAUDE.md (sdd-review-self 記述箇所)
- install.sh (sdd-review-self コピーロジック)

## Output
Write YAML findings to: .sdd/project/reviews/self/active/findings-inspector-dynamic-4-review-self-architecture.yaml

YAML format:
scope: "inspector-dynamic-4-review-self-architecture"
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
AGENT:inspector-dynamic-4
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/findings-inspector-dynamic-4-review-self-architecture.yaml
