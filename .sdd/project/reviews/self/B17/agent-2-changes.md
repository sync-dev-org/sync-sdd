## Change-Focused Review Report

### Issues Found

- [HIGH] `framework/claude/skills/sdd-reboot/SKILL.md:35` — Phase 3 の説明が "**Conventions Brief**: Dispatch ConventionsScanner" のまま残っている。`refs/reboot.md` では Phase 3 を "Setup" にリネームし ConventionsScanner を廃止したが、SKILL.md のフェーズ一覧（Step 2 箇条書き）が更新されていない。Lead が SKILL.md の概要を読んで実際には存在しない ConventionsScanner 呼び出しを実行しようとするリスクがある。

- [HIGH] `framework/claude/sdd/settings/templates/reboot/analysis-report.md` — テンプレートが旧フォーマットのまま。sdd-analyst.md Step 7 は新セクション構成（"Requirements (abstract)" / "Architecture Alternatives" / "Comparison Table"）を要求しているが、テンプレートは旧構成（"Codebase Assessment > Strengths/Weaknesses" / "Ideal Architecture"）を定義している。Analyst がテンプレートを "format reference" として読み込むため（Step 1）、テンプレートとの齟齬がレポート構造の不一致を引き起こす。

- [HIGH] `framework/claude/skills/sdd-reboot/refs/reboot.md:68` — 非推奨アーキテクチャ代替案が選択された場合の re-dispatch において `selected_alternative={name}` パラメータを Analyst に渡すよう指示しているが、`sdd-analyst.md` の Input セクションにはこのパラメータの定義がない。Analyst は `selected_alternative` の受け取り方・処理方法を知らないため、非推奨案選択時のフローが機能しない。

- [MEDIUM] `framework/claude/CLAUDE.md:315` — tmux Integration の参照先が "See `refs/review.md` Web Inspector Server Protocol" と書かれているが、同ファイルの他の参照は "see sdd-roadmap `refs/review.md`" と一貫して `sdd-roadmap` スキル修飾子を付けている。修飾子が欠けていると、Lead が参照先を特定する際に曖昧さが生じる（低リスクだが他箇所と不整合）。

- [MEDIUM] `framework/claude/sdd/settings/profiles/_index.md` — Profile Format の Development Standards セクションに "Data Modeling" が定義されていない。しかし `framework/claude/sdd/settings/profiles/python.md` では `### Data Modeling` セクションを追加している。TypeScript・Rust プロファイルには同セクションがなく、プロファイル間でフォーマットが統一されていない。_index.md の Profile Format 仕様にも記載がない。

- [LOW] `framework/claude/CLAUDE.md:280` (Session Resume Step 5a) — tmux orphaned pane のクリーンアップで `tmux list-panes -a -F '#{pane_title}'` を使用しているが、実際に pane を kill する際の ID 特定方法（`tmux kill-pane -t` の対象）が未定義。review.md の tmux Mode では pane_id を作成時にキャプチャして使用するよう厳密に定義されているのに対し、Session Resume Step 5a は "Kill any found" とだけ書かれており kill コマンドの引数が不明確。

### Confirmed OK

- reboot.md Phase 4 Analyst dispatch: `conventions brief path` の引数が削除されており、sdd-analyst.md Input セクションとの整合性が取れている。
- reboot.md Phase 7 Architect Dispatch: conventions brief path の記述が削除されており（"Standard context: feature name, mode=new, steering path"）、ConventionsScanner スキップと整合している。
- sdd-analyst.md Step 1: "NO conventions brief" の明示的な禁止ルールが追加されており、誤読を防いでいる。
- sdd-analyst.md Step 4（旧 Step 4 Current Implementation Assessment を Step 4 External Dependencies Inventory に変更）: Step 3/5/7 との整合性が取れている。Step 4 はアーキテクチャ提案（Step 3）の constraints 入力として位置付けられ、Step 5 Spec Decomposition は "recommended architecture (Step 3)" を起点とする。
- sdd-analyst.md Step 7 の Completion Report フォーマット: Lead が期待するフィールド（ANALYST_COMPLETE / New specs / Waves / Steering / Requirements identified / Files to delete / WRITTEN:path）は変更なく維持されている。
- CLAUDE.md の Task→Agent リネーム: CLAUDE.md 内の `Task` ツール参照は全て `Agent` に更新されている（Architecture/Chain of Command/SubAgent Lifecycle）。
- review.md の tmux プロトコル: Server Start / Inspector Dispatch / Server Stop の 3 ステップが完全に記述されており、run.md の DISPATCH-INSPECTORS / INSPECTORS-COMPLETE との参照整合性が取れている。
- CLAUDE.md Session Resume Step 5a の tmux cleanup: reboot と通常 run.md フローには存在せず、Session Resume のみに限定されており、スコープは適切。
- Python profile の pydantic/SQLModel 追加: "Data Modeling" セクションの内容（pydantic をデフォルト、SQLModel を SQL/ORM 用途に推奨）は steering 使用時に Architect/Builder へ適切なデフォルトを提供する内容として妥当。
- settings.json の `Bash(tmux *)` 追加: review.md tmux プロトコルで使用する `tmux split-window`、`tmux list-panes`、`tmux kill-pane`、`tmux capture-pane` コマンドを許可するために必要であり、整合している。
- sdd-analyst.md の "No preservation bias" Critical Constraint 追加: Step 2/3 の変更（アーキテクチャ代替案強制・"strengths" 評価禁止）との整合性が取れている。

### Overall Assessment

今回の変更は 3 つの観点から構成されている：(1) sdd-analyst 多案提示への転換、(2) reboot ConventionsScanner スキップ、(3) tmux dev server 管理の追加。

主要な問題は **SKILL.md の同期漏れ**（ConventionsScanner 廃止がサマリーに反映されていない）と **analysis-report.md テンプレートの未更新**（Analyst の新フォーマット要件と乖離）の 2 件で、どちらも実行時に不整合を引き起こす可能性がある。

特に `selected_alternative` パラメータが Analyst の Input に定義されていない問題は、非推奨アーキテクチャ案を選択したユーザーへのサポートが実質的に欠落していることを意味し、新機能の核心部分に関わる HIGH 問題である。

tmux プロトコル自体（review.md / run.md / CLAUDE.md）は内部的に整合しており、settings.json の Bash 許可も適切に追加されている。Python profile の pydantic/SQLModel 追加はフォーマット上の厳密性は欠くが（_index.md に Data Modeling セクションが未定義）、内容として問題はない。
