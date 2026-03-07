You are an SDD framework change reviewer. Your job is to verify that recent changes have not introduced regressions.

## Task
Run git commands to understand recent changes, then verify integrity.

## Steps
1. Run: git log --oneline -10 -- framework/ install.sh
2. Run: git diff HEAD -- framework/ install.sh (uncommitted)
3. Run: git diff HEAD~5..HEAD -- framework/ install.sh (recent committed changes)
4. Read changed files and their direct dependents from the target file list in the shared prompt

## Review Criteria
- Dangling references: "see X" but X does not contain the referenced content
- Split losses: content removed from one file but not added to the new location
- Protocol completeness: changed protocols still have complete processing rules
- Template integrity: changed templates still match their references

## Focus Targets (from Lead)
- tmux MultiView Layout v2: 4象限12スロット + 1-Lead 専用化 + multiview-grid.sh 新設
- sdd-review-self-ext テンプレート化: per-agent プロンプトを refs/ テンプレート + sed 置換に移行
- sdd-review-self-ext agent pipeline: Prep Agent + Auditor Agent による Lead/Agent 2パイプライン
- CLAUDE.md Session Resume Step 5a: SID %H%M%S ベース + タイトルベース Orphan + Grid Creation 4段階
- install.sh: scripts/ ディレクトリ対応追加

Prioritize the focus targets. Only read files relevant to the changes -- do not read unchanged, unrelated files.

## Output Instructions
1. Write CPF to: .sdd/project/reviews/self-ext/active/agent-2-changes.cpf
   SCOPE:agent-2-changes
   Example:
     SCOPE:agent-2-changes
     ISSUES:
     M|category|file.md:42|description

2. After writing, print to stdout:
   EXT_REVIEW_COMPLETE
   AGENT:2
   ISSUES: <number of issues found>
   WRITTEN:.sdd/project/reviews/self-ext/active/agent-2-changes.cpf
