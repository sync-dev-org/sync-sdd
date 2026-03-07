## Change-Focused Review Report

レビュー対象コミット (HEAD~5..HEAD): aaa13ef, a6743e2, da1937b, e2d8493, fe85f84

---

### Issues Found

- [HIGH] **Analyst Step 3 内のナンバリング重複**: `framework/claude/agents/sdd-analyst.md` の Step 3 (Architecture Proposals) 内で、Dependency Strategy 追加により Comparison Table が `4.` に移動したが、その直後の "Recommendation" も `4.` のままになっている。結果として `4. Comparison Table` と `4. Recommendation` が重複。`5. Design Principles` は正しく繰り下がっているが、Recommendation が `5.` に更新されていない。
  - ファイル: `framework/claude/agents/sdd-analyst.md` 行 89-102
  - 該当箇所:
    ```
    4. **Comparison Table** (mandatory):  ← 4に正しく移動
    ...
    4. **Recommendation**: ...            ← 重複。5. になるべき
    5. **Design Principles**              ← 6. になるべき
    ```

- [HIGH] **E2E Gate の Dispatch Loop 統合欠落**: `run.md` の Readiness Rules テーブルに "E2E Gate" が独立フェーズとして追加されたが、Dispatch Loop の Phase Handlers セクションに "E2E Gate completion" ハンドラが存在しない。`Implementation completion` ハンドラが impl.md Step 3.5 を含むよう更新されているため、E2E Gate は impl.md 内部で実行される設計だが、Readiness Rules テーブルが E2E Gate を独立フェーズとして列挙している点が矛盾を生む。
  - 具体的問題: Readiness Rules の E2E Gate 行の条件「E2E command defined in steering/tech.md」は、E2E コマンドが存在しない場合に E2E Gate がスキップされる処理と矛盾する可能性がある。E2E なしプロジェクトでは E2E Gate が Readiness Rules 上「条件未充足」として永遠に通過しない読み方ができる。
  - Impl Review の条件「E2E gate passed (if E2E command defined)」は正しいが、E2E Gate 行の Readiness Rule が「E2E command defined」を前提条件にしているため、E2E 未定義プロジェクトでは E2E Gate 行が存在する意味がなく混乱を招く。
  - ファイル: `framework/claude/skills/sdd-roadmap/refs/run.md` 行 152-153

- [MEDIUM] **CLAUDE.md Execution Conventions の Common Commands 参照が不完全**: `framework/claude/CLAUDE.md` の "Use steering Common Commands" の説明文が「test, lint, build, format, run」のみを列挙しており、今回追加された `# Install:` と `# E2E:` コマンドが含まれていない。Lead が Install や E2E コマンドを実行する際にこの規則を参照した場合、Install/E2E も同じ精度で tech.md から読み取るべきという明示的な指示がない。
  - ファイル: `framework/claude/CLAUDE.md` 行 312
  - 現状: `"When running project tools (test, lint, build, format, run), use the exact command patterns from steering/tech.md Common Commands."`
  - Install と E2E が列挙から漏れている。

- [MEDIUM] **E2E Gate の自動修正ループがカウンタ管理ルールと連携していない**: `impl.md` Step 3.5 の E2E 失敗時フローで「Max 3 E2E fix attempts」と記述されているが、このカウンタが spec.yaml のどのフィールドに記録されるか、セッション再開時にどう扱われるかが未定義。Dead-Code Review の「in-memory only」パターン（run.md 行 249参照）と同様の扱いなのか不明。他の retry_count / spec_update_count との区別も不明瞭。
  - ファイル: `framework/claude/skills/sdd-roadmap/refs/impl.md` 行 112

- [LOW] **reboot.md の "Analyst Step 3" 参照**: `framework/claude/skills/sdd-reboot/refs/reboot.md` 行 62 が「Architecture alternatives with comparison table (from Analyst Step 3)」と参照しているが、Analyst の Step 3 (Architecture Proposals) は今回の変更でも変わっておらず参照は有効。ただし Comparison Table のサブ番号が 3→4 に変わったため、細粒度の参照があれば将来問題になる可能性がある（現時点では単に "Step 3" を参照しているため問題なし）。
  - 軽微な懸念として記録。

---

### Confirmed OK

- **analysis-report.md テンプレートと sdd-analyst.md の Comparison Table 行が一致**: テンプレート (`framework/claude/sdd/settings/templates/reboot/analysis-report.md`) と Analyst 定義 (`framework/claude/agents/sdd-analyst.md`) の Comparison Table に `Dependency strategy` と `Install complexity` の2行が同時に追加されており、内容が整合している。
- **analysis-report.md テンプレートに Dependency Strategy セクション追加**: Alternative A・B の両方に `#### Dependency Strategy` セクション（`{{DEPENDENCY_STRATEGY_A/B}}`）が追加されており、Analyst Step 3 の3項目とテンプレート構造が対応している。
- **Builder の No dependency management ルールと impl.md Step 2.5 の整合**: `sdd-builder.md` の "No dependency management" 制約と `impl.md` Step 2.5 "Environment Setup" が論理的に整合している。Lead が事前インストールを実行するため Builder は禁止される、という理由付けが両ファイルで一致している。
- **tech.md テンプレートの `# Install:` / `# E2E:` 追加**: `framework/claude/sdd/settings/templates/steering/tech.md` の Common Commands ブロックに両コメントが追加されており、impl.md Step 2.5 と Step 3.5 が参照するフォーマット（`# Install:` 行、`# E2E:` 行）と一致している。
- **run.md Implementation completion ハンドラの更新**: "Steps 1-3" から "Steps 1-3.5" への更新と "then execute E2E Gate per impl.md Step 3.5" の追記が行われており、impl.md との整合が取れている。
- **Builder Optional dependencies ルール追加**: `sdd-builder.md` に追加された `pytest.importorskip()` パターンと `sys.modules` ハック禁止は、TDD 古典派アプローチとの整合が取れており、既存ルールを補完している。
- **Analyst の re-dispatch (selected_alternative) フロー**: Step 2-3 をスキップして Step 4-5 を再生成するロジックは、新しい Dependency Strategy (Step 3-3) を含む形で既に Step 4 (Comparison Table → Step 4 へ移動後) も再生成対象に含まれるため、論理は維持されている。
- **Task→Agent リネーム**: CLAUDE.md, run.md, impl.md, design.md, review.md 全体で Task → Agent ツール名が統一されている（前コミット da1937b）。

---

### Overall Assessment

今回の変更セット（v1.9.0, v1.8.0, v1.7.0）は全体的に整合しているが、**2件の HIGH 問題**が存在する。

**最重要**: `sdd-analyst.md` の Step 3 内ナンバリング重複（Comparison Table と Recommendation が両方 `4.`）は、Analyst が実行時に Recommendation を誤って省略または重複して出力するリスクがある。即座に修正が必要。

**次点**: E2E Gate の Readiness Rules 定義は、「E2E command defined」を条件としているため、E2E コマンド未定義プロジェクトでは E2E Gate 行が Readiness Rules テーブル上でデッドコード化する。設計意図は「E2E あり → E2E Gate → Impl Review」「E2E なし → 直接 Impl Review」だが、テーブル表現が混乱を招く。E2E Gate 行を削除し、Impl Review 行の条件のみで表現するか、E2E Gate を「条件付きサブステップ」として注釈を加えることを推奨する。

CLAUDE.md の Common Commands 参照更新（Install/E2E 追加）は LOW〜MEDIUM の改善事項。E2E カウンタのライフサイクル仕様明確化も推奨。
