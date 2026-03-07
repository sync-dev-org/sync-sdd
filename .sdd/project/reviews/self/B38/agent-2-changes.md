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
- レビュー・エンジン周辺の再設計（staggered dispatch/rerouting、run_in_background 明示、SubAgent 読み取り委譲、sed 全廃）を sdd-review-self 系で再構成
- `sdd-resume` を新規追加し、既存セッション再開フローと `/clear` 対応を拡張
- `settings.json`・`CLAUDE.md`・`tmux-integration` を含む Inspector/Skill ディスパッチ運用と許可設定の整合性更新
- `sdd-review-self`, `sdd-roadmap`, `sdd-status`, `sdd-release`, `sdd-reboot`, `sdd-handover`, `sdd-steering` など主要 SKILL/refs と README 連携を更新
- `review-self` テンプレート群（prep/agent-1..4/auditor/engines.yaml）と運用スクリプトを改訂

Prioritize the focus targets. Only read files relevant to the changes -- do not read unchanged, unrelated files.

## Output Instructions
1. Write CPF to: .sdd/project/reviews/self/active/agent-2-changes.cpf
   SCOPE:agent-2-changes
   Example:
     SCOPE:agent-2-changes
     ISSUES:
     M|category|file.md:42|description

2. After writing, print to stdout:
   EXT_REVIEW_COMPLETE
   AGENT:2
   ISSUES: <number of issues found>
   WRITTEN:.sdd/project/reviews/self/active/agent-2-changes.cpf
