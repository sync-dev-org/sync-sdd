## Change-Focused Review Report

調査対象コミット: 未コミット変更 (HEAD の上に存在する差分)

### Issues Found

- [MEDIUM] CLAUDE.md の SubAgent Failure Handling セクション (行115) が Analyst を列挙していない。
  該当箇所: `framework/claude/CLAUDE.md` 行115
  内容: "This applies to all file-writing SubAgents (Inspectors → CPF files, Auditors → verdict.cpf, Builders → builder-report files, ConventionsScanner → conventions-brief)"
  問題: Analyst も `analysis-report.md` をファイル出力として書くが、このリストに含まれていない。
  補足: Analyst のリトライロジックは `refs/reboot.md` Phase 4 Step 3 と SKILL.md Error Handling テーブルで個別に定義されているため実害は小さいが、CLAUDE.md の説明として不完全であり、将来的な混乱の原因になりうる。

- [LOW] CLAUDE.md の Analyst コンテキストバジェット説明と実際の完了レポート形式に軽微な表現ズレがある。
  該当箇所: `framework/claude/CLAUDE.md` 行41
  CLAUDE.md: "return only structured summary (spec count, wave count, steering changes, report path)"
  実際の agent 出力: `ANALYST_COMPLETE` トークン + フィールド群 + `WRITTEN:{path}` (Builder 同様の structured summary 形式)
  問題: "WRITTEN:{path} のみ返す" という Review SubAgents の説明パターンと表現が似ているため、Analyst が WRITTEN のみを返すと誤読される可能性がある。実際は Builder と同様の構造化サマリーを返す。機能的影響はないが、説明の精度が低い。

### Confirmed OK

- **sdd-analyst エージェント frontmatter**: `name: sdd-analyst`, `model: opus`, `background: true`, `tools: Read, Glob, Grep, Write, Edit, WebSearch, WebFetch` — CLAUDE.md の T2/Opus 定義と一致。
- **sdd-analyst 説明文**: agent の description フィールド "Performs holistic project analysis and proposes zero-based redesign (spec decomposition + steering reform). Invoked by sdd-reboot skill." は CLAUDE.md ロール定義 ("Holistic project analysis, zero-based redesign proposal, steering reform/generation.") と一致。
- **settings.json Task(sdd-analyst)**: `framework/claude/settings.json` に `Task(sdd-analyst)` が追加されており、`framework/claude/agents/sdd-analyst.md` が実在する。対応整合。
- **settings.json Skill(sdd-reboot)**: `framework/claude/settings.json` に `Skill(sdd-reboot)` が追加されており、`framework/claude/skills/sdd-reboot/SKILL.md` が実在する。対応整合。
- **SKILL.md refs パス**: SKILL.md Step 2 は `refs/reboot.md` を参照し、ファイルが `framework/claude/skills/sdd-reboot/refs/reboot.md` として実在する。ダングリングなし。
- **CLAUDE.md 階層テーブル Analyst 行**: Tier 列 T2、責務説明 "Holistic project analysis, zero-based redesign proposal, steering reform/generation. Produces analysis-report.md + updated steering." は agent 定義と整合。
- **CLAUDE.md Commands (5→6)**: コマンドテーブルに 6 エントリ (sdd-steering, sdd-roadmap, sdd-reboot, sdd-status, sdd-handover, sdd-release) が存在し、見出し "Commands (6)" と一致。sdd-reboot の説明 "Zero-based project redesign (analysis + design pipeline on feature branch)" は SKILL.md Core Task と整合。
- **reboot.md の run.md 参照**: "refs/run.md Step 4" (Phase 7) および "refs/run.md §Review Decomposition" (Phase 7) は run.md の `## Step 4: Parallel Dispatch Loop` および `### Review Decomposition` セクションが実在する。ダングリングなし。
- **reboot.md の crud.md 参照 (Foundation-First)**: reboot.md の Analyst agent 定義 Step 5 が "Foundation-First heuristic" を参照しており、crud.md に "Foundation-First" セクションが実在する。
- **reboot.md Review Decomposition エージェント名**: sdd-auditor-design が参照され、`framework/claude/agents/sdd-auditor-design.md` が実在する。6 design Inspector 名 (rulebase, testability, architecture, consistency, best-practices, holistic) に対応するエージェントが実在する。
- **sdd-conventions-scanner の dispatch**: reboot.md Phase 3 が `Task(subagent_type="sdd-conventions-scanner")` を使用し、`framework/claude/agents/sdd-conventions-scanner.md` の `name: sdd-conventions-scanner` と一致。
- **analysis-report.md テンプレート**: `framework/claude/sdd/settings/templates/reboot/analysis-report.md` が実在し、install.sh の `install_dir "$SRC/framework/claude/sdd/settings/templates" ".sdd/settings/templates"` でインストール対象に含まれる。Analyst の Template path 指定先 `{{SDD_DIR}}/settings/templates/reboot/analysis-report.md` と整合。
- **install.sh の新ファイル対応**: install.sh は glob ベースで `framework/claude/skills/**` と `framework/claude/agents/**` を全コピーするため、sdd-reboot/、sdd-analyst.md は追加設定なしで自動的にインストール対象になる。
- **Analyst の完了レポートトークン**: reboot.md Phase 4 Step 2 が `Wait for ANALYST_COMPLETE` としており、agent の Completion Report が `ANALYST_COMPLETE` を先頭に出力する定義と一致。
- **reboot.md の DIRECTION_CHANGE 記録**: Phase 2 と Phase 10 で decisions.md への DIRECTION_CHANGE 記録が定義されており、CLAUDE.md decisions.md Recording の "DIRECTION_CHANGE: spec split, wave restructure, scope change" 定義と整合。

### Overall Assessment

重大な欠陥はない。新規追加された sdd-analyst エージェント、sdd-reboot スキル、refs/reboot.md は、CLAUDE.md 定義・settings.json・install.sh のインストールフローと全体的に整合している。

指摘事項は 2 件、いずれも MEDIUM/LOW レベル:

1. **SubAgent Failure Handling リストへの Analyst 未追加 (MEDIUM)**: CLAUDE.md 行 115 のファイル書き込み SubAgent 一覧に Analyst が欠落している。実害は小さいが、ドキュメントの完全性の観点で修正推奨。Analyst のリトライは reboot.md と SKILL.md で個別定義済みのため機能には影響しない。

2. **コンテキストバジェット説明の表現精度 (LOW)**: CLAUDE.md の Analyst 説明が "return only structured summary" と書かれているが、Review SubAgents の "return ONLY WRITTEN:{path}" と紛らわしい。"ANALYST_COMPLETE + structured fields + WRITTEN:{path}" であることを明示するとより正確。
