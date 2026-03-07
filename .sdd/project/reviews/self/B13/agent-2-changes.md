## Change-Focused Review Report

**対象コミット**: v1.5.0 (Reboot スキル) + v1.5.1 (Analyst 修正) + v1.4.0 (Context Budget) + v1.3.0 (Wave Context)
**レビュー日時**: 2026-02-27
**変更ファイル数**: 19ファイル (framework/ + install.sh)

---

### Issues Found

なし

---

### Confirmed OK

#### Focus Target 1: sdd-reboot スキル + sdd-analyst エージェント

**SKILL.md ルーティング整合性**
- `framework/claude/skills/sdd-reboot/SKILL.md` の Step 2 が `refs/reboot.md` を参照し、10フェーズの実行を委任している
- `refs/reboot.md` は Phase 3 で `Task(subagent_type="sdd-conventions-scanner", run_in_background=true)` を使用し正しくディスパッチ
- Phase 4 で `Task(subagent_type="sdd-analyst", run_in_background=true)` を使用し正しくディスパッチ
- `refs/reboot.md` の Phase 7 は `refs/run.md` Step 4 の設計ループを参照 ("Reuse the design dispatch loop from `refs/run.md` Step 4") — run.md に実際に Step 4 Parallel Dispatch Loop が存在することを確認済み

**sdd-analyst フロントマター整合性**
- `name: sdd-analyst` ← `subagent_type="sdd-analyst"` と一致
- `model: opus` ← T2 Brain 役割として適切 (CLAUDE.md Tier 2: Opus と一致)
- `tools: Read, Glob, Grep, Write, Edit, WebSearch, WebFetch` ← ステアリング・コードベース読み込み + Web検索に必要なツールセット
- `background: true` ← CLAUDE.md の「SubAgent は常に run_in_background: true」ルールに準拠

**CLAUDE.md 参照整合性**
- CLAUDE.md Tier 表に Analyst (T2) と ConventionsScanner (T3) が追加されている
- CLAUDE.md §Context Budget: `Analyst: write analysis report to {{SDD_DIR}}/project/reboot/analysis-report.md, return structured summary` ← sdd-analyst.md の Completion Report 形式 (ANALYST_COMPLETE + WRITTEN:{report_path}) と一致
- CLAUDE.md §SubAgent Failure Handling: `Analyst → analysis-report` が追加されており、SKILL.md エラー表「Analyst failure → Retry once」と一致
- `settings.json` に `Task(sdd-analyst)` が追加済み

**Analyst 完了レポート形式**
- sdd-analyst.md の Completion Report:
  ```
  ANALYST_COMPLETE
  New specs: {count}
  Waves: {count}
  Steering: {created|updated} ({file_list})
  Capabilities found: {count}
  WRITTEN:{report_path}
  ```
- `refs/reboot.md` Phase 4 Step 2: `Wait for ANALYST_COMPLETE via TaskOutput` ← 整合
- `refs/reboot.md` Phase 4 Step 3: `Verify: analysis-report.md exists at output path` ← ファイルベース検証と整合

#### Focus Target 2: Context Budget (v1.4.0) — ファイルベース出力プロトコル

**CLAUDE.md とエージェント定義の一致確認**

| エージェント | CLAUDE.md 指定 | エージェント定義の実際の動作 | 一致 |
|------------|--------------|--------------------------|------|
| Review SubAgents (Inspector/Auditor) | `return ONLY WRITTEN:{path}` | 全 Inspector/Auditor: `Return only WRITTEN:{output_file_path} as your final text to preserve Lead's context budget` | OK |
| Builder | `write full report to builder-report-{group}.md, return only structured summary` | sdd-builder.md: Step A (Write Full Report) + Step B (Output Minimal Summary), WRITTEN:{report_path} を含む | OK |
| Analyst | `write analysis report to reboot/analysis-report.md, return ANALYST_COMPLETE + WRITTEN:{path}` | sdd-analyst.md Completion Report: ANALYST_COMPLETE + WRITTEN:{report_path} | OK |
| ConventionsScanner | (CLAUDE.md に明示なし、but §SubAgent Failure Handling でファイルベース言及) | sdd-conventions-scanner.md: `Return ONLY WRITTEN:{output_path}` | OK |
| Architect/TaskGenerator | `current report format is already concise` | 変更なし (今回レビュー対象外) | OK |

**sdd-auditor-design.md / sdd-auditor-impl.md の出力プロトコル**
- 両 Auditor ともに: `Return only WRITTEN:{verdict_file_path} as your final text to preserve Lead's context budget` ← CLAUDE.md §Review SubAgents: `return ONLY WRITTEN:{path}` と一致

**sdd-inspector-best-practices.md の出力プロトコル**
- `Return only WRITTEN:{output_file_path} as your final text to preserve Lead's context budget` ← 正しい形式

#### Focus Target 3: sdd-conventions-scanner エージェント

**フロントマター整合性**
- `name: sdd-conventions-scanner` ← `subagent_type="sdd-conventions-scanner"` と一致
- `model: sonnet` ← T3 Execute 役割として適切
- `tools: Read, Glob, Grep, Write` ← パターンスキャン + ファイル書き込みに必要な最小ツールセット
- `background: true` ← 正しい

**ディスパッチ参照の整合性**
- `refs/run.md` Step 2.5: `Task(subagent_type="sdd-conventions-scanner", run_in_background=true)` ← 存在確認済み
- `refs/impl.md` Pilot Stagger Protocol Step 3: `Dispatch sdd-conventions-scanner SubAgent (mode: Supplement)` ← 存在確認済み
- `refs/reboot.md` Phase 3: `Task(subagent_type="sdd-conventions-scanner", run_in_background=true)` ← 存在確認済み
- `refs/revise.md`: `Dispatch sdd-conventions-scanner (mode: Generate) per run.md Step 2.5` ← run.md を正しく参照
- `settings.json`: `Task(sdd-conventions-scanner)` が追加済み

**エージェント定義の完全性**
- Mode: Generate / Mode: Supplement の2モード定義が存在し、reboot.md (Generate) と impl.md (Supplement) の要件を両方カバー
- Generate モード: ConventionsScanner がステアリング + バッファ + テンプレートパスを受け取る ← reboot.md/run.md のディスパッチパラメータと整合
- Supplement モード: builder-report パスと既存 brief パスを受け取る ← impl.md Pilot Stagger Protocol Step 3 のパラメータと整合
- Output: `WRITTEN:{output_path}` のみ返却 ← CLAUDE.md §SubAgent Failure Handling の「ConventionsScanner → conventions-brief」と整合

**Wave Context テンプレート**
- `framework/claude/sdd/settings/templates/wave-context/conventions-brief.md` が存在
- run.md Step 2.5 と reboot.md Phase 3 で `Template: {{SDD_DIR}}/settings/templates/wave-context/conventions-brief.md` を参照 ← テンプレートファイルが実在

#### Focus Target 4: Wave Context / Pilot Stagger — refs/run.md と refs/impl.md の整合性

**CLAUDE.md §Parallel Execution Model**
- `Wave Context: ... ConventionsScanner generates the conventions brief ... See sdd-roadmap refs/run.md Step 2.5 and refs/impl.md Pilot Stagger Protocol` ← run.md に Step 2.5 が存在、impl.md に Pilot Stagger Protocol が存在することを確認済み

**run.md Step 2.5 ← → CLAUDE.md 整合性**
- CLAUDE.md: `ConventionsScanner generates the conventions brief (codebase pattern scanning stays out of Lead's context)` ← run.md Step 2.5: `This keeps scan results out of Lead's context` と一致 (同一rationale)
- CLAUDE.md: `Pilot Stagger seeds conventions via ConventionsScanner supplement mode` ← impl.md: `Convention supplement: Dispatch sdd-conventions-scanner SubAgent (mode: Supplement)` と整合

**run.md → impl.md の Pilot Stagger 参照**
- run.md §Implementation completion: `Execute per refs/impl.md (Steps 1-3, skip Step 4 auto-draft when called from dispatch loop). Pass conventions brief path from Step 2.5 to impl.md` ← impl.md が conventions brief path を受け取りを前提とした設計 (Step 2 TaskGenerator dispatch / Step 3 Builder dispatch に含まれる)

**impl.md Pilot Stagger プロトコル完全性**
- ステップ 1〜4 (Pilot selection → dispatch → supplement → remaining dispatch) が明確に定義されている
- Pilot Builder の `WRITTEN:{path}` (builder-report パス) を ConventionsScanner Supplement モードに渡す手順が実装済み
- Skip conditions (Single Builder group, task re-execution mode) が明記されている

#### Focus Target 5: install.sh の変更

**スキル/エージェント追加とインストール対象の一致確認**

install.sh の主要インストールロジック:
```sh
install_dir "$SRC/framework/claude/skills" ".claude/skills"   # 全スキルディレクトリ
install_dir "$SRC/framework/claude/agents"  ".claude/agents"  # 全エージェントファイル
```

- 新規 `sdd-reboot/` スキルディレクトリ → `install_dir` が自動検出してインストール
- 新規 `sdd-analyst.md` エージェント → `install_dir` が自動検出してインストール
- 新規 `sdd-conventions-scanner.md` エージェント → `install_dir` が自動検出してインストール
- 新規 `sdd/settings/templates/reboot/analysis-report.md` → `install_dir "$SRC/framework/claude/sdd/settings/templates" ".sdd/settings/templates"` で自動インストール

**削除時の stale ファイルクリーンアップ**
- `remove_stale ".claude/agents" "$SRC/framework/claude/agents" "sdd-*.md"` ← 新規ファイルが source に存在するため削除対象にならない

**settings.json のパーミッション整合性**
- settings.json に追加された全エントリと対応するファイルが存在することを確認:
  - `Task(sdd-analyst)` ← `framework/claude/agents/sdd-analyst.md` 存在
  - `Task(sdd-conventions-scanner)` ← `framework/claude/agents/sdd-conventions-scanner.md` 存在
  - `Skill(sdd-reboot)` ← `framework/claude/skills/sdd-reboot/SKILL.md` 存在

#### その他確認項目

**sdd-reboot SKILL.md のエラー表**
- `Analyst failure` 行: "Retry once. Second failure → delete branch, return to main, report error" ← refs/reboot.md Phase 4 Step 3 の実際のフロー (retry once, then git checkout main && git branch -D) と整合

**analysis-report.md テンプレート整合性**
- テンプレートセクション構成 (Executive Summary, Codebase Assessment, Ideal Architecture, Steering Changes, Proposed Spec Decomposition, Wave Structure, Key Design Decisions, Risk Assessment) ← sdd-analyst.md Step 6 の「Write Analysis Report」ステップの各項目 (1〜8) と完全に整合

**sdd-analyst.md の「NEVER read existing specs」制約**
- `refs/reboot.md` Phase 4: `DO NOT pass specs path — Analyst must not read existing specs` ← 意図的な制約として一致

**sdd-conventions-scanner の Greenfield 対応**
- エージェント定義: `Greenfield projects: If no source files exist, generate from steering only.`
- run.md Step 2.5: `Greenfield projects: Scanner generates from steering only if no source files exist.` ← 一致

**CLAUDE.md コマンド数テーブル**
- 6コマンド: `sdd-steering`, `sdd-roadmap`, `sdd-reboot`, `sdd-status`, `sdd-handover`, `sdd-release`
- framework/claude/skills/ 内のスキル数: 7個 (`sdd-release`, `sdd-steering`, `sdd-status`, `sdd-roadmap`, `sdd-handover`, `sdd-review-self`, `sdd-reboot`)
- `sdd-review-self` は framework-internal ツールのため CLAUDE.md コマンド一覧には記載されていない ← 意図的

---

### Overall Assessment

**全フォーカスターゲットで問題なし**。

v1.5.0/v1.5.1 (sdd-reboot + sdd-analyst) の変更は整合性が保たれている:
- SKILL.md → refs/reboot.md → SubAgent ディスパッチの連鎖が完全
- sdd-analyst フロントマター・完了レポート形式・CLAUDE.md 記述が三者整合
- CLAUDE.md の Analyst output path (`reboot/analysis-report.md`) と refs/reboot.md Phase 4 の output path が一致

v1.4.0 (Context Budget) の変更はファイルベース出力プロトコルが全 SubAgent に正しく適用されている:
- Inspector/Auditor: `WRITTEN:{path}` のみ返却
- Builder: WRITTEN付き構造化サマリー
- Analyst: ANALYST_COMPLETE + WRITTEN:{path}
- ConventionsScanner: WRITTEN:{path} のみ返却

v1.3.0 (Wave Context) の ConventionsScanner は:
- run.md Step 2.5, impl.md Pilot Stagger, reboot.md Phase 3, revise.md の4箇所から一貫してディスパッチ参照されている
- エージェント定義の2モード (Generate/Supplement) が各呼び出し元の要件を正確にカバーしている

install.sh は `install_dir` による自動スキャンのため、新規ファイルが framework/ に追加されれば自動的にインストール対象となり、手動リスト管理が不要な設計になっている。今回の新規ファイルはすべて自動インストール対象に含まれる。

**重大な欠損・ダングリング参照・プロトコル不完全性は検出されなかった。**
