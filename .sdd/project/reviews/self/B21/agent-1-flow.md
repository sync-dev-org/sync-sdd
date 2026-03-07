## Flow Integrity Report

> Agent 1: Router → refs ディスパッチフロー整合性レビュー

---

### Issues Found

- [MEDIUM] README.md と CLAUDE.md の impl Inspector カウント説明が不一致 / README.md:79 vs CLAUDE.md:27

  **詳細**: README.md には `6+2 for implementation (web projects)` と記載されているが、CLAUDE.md では `6 impl +1 e2e +2 web (impl only; e2e/web are conditional)` と記載されており、E2E Inspector の存在が README に反映されていない。review.md 実装は正確（6 標準 + 1 E2E 条件付き + 2 web 条件付き = 最大9）。ただし README はフレームワークソースではなくユーザー向けドキュメントなので動作には影響なし。

- [LOW] revise.md Mode Detection の「Escalation」ブロックと Part A Step 3 の記述が軽微な重複を持つ / refs/revise.md:8-16 および refs/revise.md:43-47

  **詳細**: Mode Detection セクションに `Single-Spec Mode Step 3 detects 2+ affected specs → propose switch to Cross-Cutting Mode / User accepts → join Part B Step 2` とあるが、これは Step 3 の詳細説明が前倒しで書かれたもの。Part A Step 3 ではより詳細な手順が説明されており矛盾はない。ただし Mode Detection セクションに "Escalation" として書かれている内容は「refs を読む前に概要として提示される」という設計と解釈できる。実害はなし。

- [LOW] `review dead-code` のスタンドアロン実行における verdicts.md パスと Wave QG コンテキストの文書化が review.md の Step 1 と Verdict Destination セクションで二重になっている / refs/review.md:89 および refs/review.md:146

  **詳細**: `{{SDD_DIR}}/project/reviews/dead-code/` の説明が Step 1 の scope directory 決定ロジックと "Verdict Destination by Review Type" セクションの両方に記載されている。情報の重複自体は問題ではなく整合しているが、変更時に両箇所を更新する必要がある保守リスクが微小にある。

---

### Confirmed OK

1. **Router dispatch completeness**: SKILL.md Step 1 の全サブコマンド（design, impl, review design/impl, review dead-code, review --consensus, review --cross-check, review --wave, run, run --gate, run --consensus, revise, create, update, delete, -y, 空）が Execution Reference セクションで適切な refs に対応している。

2. **Phase gate consistency**: 各 ref の Phase Gate が CLAUDE.md 定義のフェーズ（`initialized`, `design-generated`, `implementation-complete`, `blocked`）と一致している。
   - design.md: `initialized`/`design-generated`/`implementation-complete`/`blocked` を正しく処理
   - impl.md: `design-generated`/`implementation-complete`/`blocked`/その他をブロック
   - review.md: Design Review は `design.md` 存在確認 + `blocked` チェック、Impl Review は `phase == implementation-complete` 確認
   - revise.md Part A: `implementation-complete` + `blocked` チェック

3. **Auto-fix loop 整合性**:
   - NO-GO: CLAUDE.md の `retry_count` max 5 と run.md Phase Handlers の「Max 5 retries, aggregate cap 6」が整合
   - SPEC-UPDATE-NEEDED: CLAUDE.md の `spec_update_count` max 2 と run.md Phase Handlers が整合
   - Aggregate cap 6: run.md「Total cycles (retry_count + spec_update_count) MUST NOT exceed 6」がCLAUDE.md「Aggregate cap: 6」と整合
   - Dead-Code Review: CLAUDE.md「max 3 retries」と run.md Step 7b「max 3 retries, tracked in-memory」が整合
   - CONDITIONAL = GO (proceed): CLAUDE.md と run.md Phase Handlers の両方で確認済み

4. **Readiness Rules の CONDITIONAL 処理**: Design Review Readiness（「absent or NO-GO」）と Impl Review Readiness（「absent or NO-GO」）はともに CONDITIONAL を「passed」として扱う（CONDITIONAL は GO 扱いなので NO-GO でなく、かつ「absent」でもないため再レビューをトリガーしない）。無限ループなし。

5. **Wave quality gate 完全性**:
   - run.md Step 7 が (a) Impl Cross-Check Review → (b) Dead Code Review → (c) Post-gate の順に完全に定義されている
   - 1-Spec Roadmap での Skip が SKILL.md §1-Spec Roadmap Optimizations と run.md Step 7 の冒頭で整合している
   - Wave completion condition（all specs `implementation-complete` or `blocked`）が明示されている
   - Post-gate のカウンターリセット・コミット・session.md auto-draft が定義されている

6. **Consensus mode**: SKILL.md §Consensus Mode が review.md Step 2 の B{seq} 委譲（「Router determines B{seq} once and passes it to all N pipelines」）と整合。N=1 のデフォルトケースでサフィックスなし (`active/`) が明示されている。

7. **Verdict persistence フォーマット**:
   - SKILL.md §Verdict Persistence Format が per-feature / Wave QG cross-check / Wave QG dead-code / cross-cutting のヘッダー形式を定義
   - review.md の Step 8 が SKILL.md のフォーマットを参照している
   - sdd-auditor-impl.md、sdd-auditor-design.md、sdd-auditor-dead-code.md の各 Output Format が CPF 仕様（cpf-format.md）と整合している
   - design Auditor は `SPEC-UPDATE-NEEDED` verdict を出力しない（design.md で定義どおり）
   - impl Auditor は `SPEC-UPDATE-NEEDED` を出力する（CLAUDE.md §Role Architecture と整合）
   - dead-code Auditor は `GO/CONDITIONAL/NO-GO` のみ（SPEC-UPDATE-NEEDED は出力しない）

8. **Edge cases**:
   - **空のロードマップ / ロードマップなし**: SKILL.md Error Handling に `run/update/revise` に対して「No roadmap found」エラーが定義。`review dead-code` / `review --cross-check` / `review --wave N` もロードマップ必須でBLOCKされる（SKILL.md line 74）。
   - **1-spec roadmap**: §1-Spec Roadmap Optimizations で Wave QG Skip・Cross-Spec File Ownership Analysis Skip・コミットメッセージ形式変更が明示されている。run.md Step 7 冒頭にも Skip 指示あり。
   - **blocked spec**: design.md・impl.md・revise.md Part A で `phase == blocked` の BLOCK 処理が定義されている。run.md Step 6 Blocking Protocol で downstream への伝播・ユーザーへのオプション提示（fix/skip/abort）が完全に定義されている。
   - **retry limit exhaustion**: run.md が Phase Handler レベルと Wave QG レベルで exhaustion → escalate パスを定義。CLAUDE.md §Auto-Fix Counter Limits と整合。

9. **Ref読み込みタイミング**: SKILL.md §Execution Reference に「After mode detection and roadmap ensure, Read the reference file for the detected mode:」と明示されており、ロードマップ確認後に ref を読む順序が明確。

10. **Revise modes — SKILL.md Detect Mode と revise.md Mode Detection の整合**:
    - SKILL.md: `revise {feature} [instructions]` → first word matches spec name → Single-Spec Mode
    - SKILL.md: `revise [instructions]` → first word does not match → Cross-Cutting Mode
    - revise.md Mode Detection: Lead が "revise" 直後の最初の単語を既存 spec 名と照合する、と明示
    - 両者の判定ロジックが一致している

11. **Revise escalation paths**:
    - Part A Step 3 → Cross-Cutting escalation（2+ affected specs）: `join Part B Step 2` へ（REVISION_INITIATED は Part A Step 2 で記録済み、Skip Part B Step 1 と明示）
    - Part A Step 6 option (d) → Cross-Cutting escalation（downstream resolution 時）: `join Part B Step 2` へ（DIRECTION_CHANGE 記録後）
    - Auto-demotion: Part B Step 5.5 で FULL spec が 1 つに絞られた場合 → Part A Step 4 へ復帰（DIRECTION_CHANGE 記録後）
    - 全エスカレーションパスが decisions.md 記録を含んでいる

12. **Inspector カウントと settings.json の整合**:
    - design Inspectors 6種: rulebase, testability, architecture, consistency, best-practices, holistic → settings.json に全て登録済み
    - impl Inspectors 6種: impl-rulebase, interface, test, quality, impl-consistency, impl-holistic → settings.json に全て登録済み
    - E2E Inspector: sdd-inspector-e2e → settings.json に登録済み
    - Web Inspectors 2種: sdd-inspector-web-e2e, sdd-inspector-web-visual → settings.json に登録済み
    - dead-code Inspectors 4種: dead-settings, dead-code, dead-specs, dead-tests → settings.json に全て登録済み

13. **Agent frontmatter 整合性**: 全 Agent（Auditor 3種、Architect、Builder、TaskGenerator、ConventionsScanner、Analyst、全 Inspector）が `name`, `description`, `model` (sonnet/opus), `tools`, `background: true` を持つ適切な YAML フロントマターを持っている。

14. **run_in_background: true の遵守**: CLAUDE.md §SubAgent Lifecycle に「always」と明示。各 ref の Agent dispatch 呼び出しは全て `run_in_background=true` を指定している。

15. **spec.yaml 所有権ルール**: Architect・Builder・TaskGenerator が spec.yaml を更新しないことが各エージェント定義で明示されている（「Do NOT update spec.yaml — Lead manages all metadata updates」）。

16. **Builder sys.modules 検出**: impl.md Step 3 に「sys.modules violation scan」が定義され、Builder 定義でも禁止ルールが明示されている。整合している。

17. **tmux 統合 / Web Inspector Server Protocol**: review.md Web Inspector Server Protocol が tmux モードとフォールバックモードを定義。CLAUDE.md §Execution Conventions に tmux 統合方針が記載されている。dev server の開始・停止タイミング（Inspector dispatch 前後）が明確。

18. **Conventions Brief フロー**: run.md Step 2.5 が ConventionsScanner の dispatch prompt・出力先・Greenfield 処理・Steering precedence を定義。impl.md §Pilot Stagger Protocol が ConventionsScanner の Supplement モード dispatch を正確に参照している。revise.md Part B Step 7-2 で Cross-Cutting revision 時にも実施されることが定義されている。

19. **Design Lookahead の Staleness guard**: run.md に実装されており、Wave N spec の NO-GO → Architect 再dispatch 時に lookahead spec の phase リセット処理が定義されている。

20. **Cross-cutting review の verdict パス**: revise.md Part B Step 8 が `specs/.cross-cutting/{id}/verdicts.md` に永続化することを定義。review.md §Verdict Destination が同パスを「Cross-cutting review」として一覧に含めている。整合している。

---

### Overall Assessment

フロー整合性は全体的に高い。発見された問題は中程度1件・軽微2件で、いずれも動作に影響しない文書化上の不一致または軽微な保守リスクにとどまる。

**主な確認事項**:
- Router → refs のディスパッチパスは全サブコマンドで完全
- Phase gate・Auto-fix loop・Wave QG のカウンター管理は CLAUDE.md と refs 間で整合
- Verdict persistence フォーマットは全レビュータイプで一貫している
- Revise の Single-Spec / Cross-Cutting 切り替えおよびエスカレーションパスは完全に定義されている
- 1-spec roadmap・blocked spec・retry exhaustion の各エッジケースが適切に処理されている

**修正推奨**:
1. [MEDIUM] README.md の Inspector カウント説明を `6 標準 +1 E2E(条件付き) +2 web(条件付き)` に更新することで CLAUDE.md との整合性を確保する。
