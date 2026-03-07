## Flow Integrity Report

### Issues Found

- [MEDIUM] `review dead-code` のルーティング表記が SKILL.md と review.md で非対称 / SKILL.md:23, refs/review.md:5
  - SKILL.md の Detect Mode には `$ARGUMENTS = "review dead-code"` とあるが、review.md Step 1 の Triggered by には `$ARGUMENTS = "review dead-code [options]"` とあり表記ゆれがある。実害は軽微だが整合性上の問題。

- [MEDIUM] `revise` の Single-Spec から Cross-Cutting への昇格フロー: SKILL.md Detect Mode の記述と revise.md の昇格条件が異なるレベルで説明されている / SKILL.md:34-35, refs/revise.md:11-16
  - SKILL.md では「first word が spec name と一致するか否か」で判断するとあるが、revise.md Mode Detection では「Step 3 で 2+ specs が affected → Cross-Cutting 提案」という実行中の動的昇格も定義している。SKILL.md は静的な初期判定のみを記述しており、動的昇格パスが SKILL.md レベルでは不可視。ユーザーやレビュアーにとって昇格メカニズムが分かりにくい。

- [MEDIUM] Auto-Fix カウンタのリセットタイミングが refs/run.md と CLAUDE.md で微妙に異なる / CLAUDE.md:180, refs/run.md:261
  - CLAUDE.md では「Counter reset triggers: wave completion, user escalation decision (including blocking protocol fix/skip), /sdd-roadmap revise start, session resume (dead-code counters are in-memory only)」とあるが、refs/run.md Step 7c (Post-gate) では「For each spec in wave: retry_count=0, spec_update_count=0」とのみ書かれており、「user escalation decision」や「/sdd-roadmap revise start」によるリセットがrun.md内で明示されていない。参照先を読まないと全貌が分からない。

- [MEDIUM] Consensus モードにおける B{seq} の決定主体が Router と review.md で二重に定義されている / SKILL.md:115-116, refs/review.md:91
  - SKILL.md Shared Protocols では「Determine B{seq} (increment max existing, or start at 1)」と Router が決定するとある。refs/review.md Step 2 では「For consensus mode: Router determines B{seq} once and passes it to all N pipelines (this step uses the Router-provided value instead of computing its own)」と正しくフォローしているが、Router 側の SKILL.md には「passes it to all N pipelines」という手順が明記されていない。渡し方の手順が欠落している。

- [MEDIUM] Dead-Code Review のフォールバック: `review dead-code` を単体で呼んだ際の verdict 保存先と Wave QG 経由の保存先が混在 / refs/review.md:143-144
  - review.md の Verdict Destination セクションでは「Dead-code review (standalone): `project/reviews/dead-code/verdicts.md`」とあるが、「Wave QG context uses `reviews/wave/verdicts.md` with header `[W{wave}-DC-B{seq}]`」と注記されている。run.md Step 7b でも「Persist verdict to `project/reviews/wave/verdicts.md`」とあり一致はしているが、review.md の Verdict Destination 表にある説明が括弧注記で追記されており可読性が低い。

- [LOW] `review --wave N` と `review design --wave N` / `review impl --wave N` の引数形式が SKILL.md で定義されているが refs/review.md では明示的な wave-mode の parse 手順がない / SKILL.md:27-28, refs/review.md:9
  - SKILL.md では `$ARGUMENTS = "review design --wave N"` / `"review impl --wave N"` という形式が列挙されているが、refs/review.md Step 1 では `--wave N` オプションのパース方法が明示されていない。`--cross-check` と `--consensus N` は説明されているが `--wave N` の standalone parse 記述が欠落している。

- [LOW] `review design --cross-check` の 1-Spec Roadmap guard が SKILL.md と review.md 両方に記述されているが微妙に表現が異なる / SKILL.md:72, refs/review.md:14
  - SKILL.md では「review dead-code and review --cross-check / review --wave N operate on the whole codebase/wave, not a single spec → skip enrollment check」とある。refs/review.md Step 1 では「1-Spec Roadmap guard: If review type is --cross-check or --wave N AND roadmap.md contains exactly 1 spec: inform user...and abort.」とある。guard の意味が「スキップ」か「abort」かで一見矛盾するように読めるが、文脈上はどちらも「enrollment check をスキップし、そのうえで single-spec の場合は cross-check は意味がないと案内する」というフローで整合はしている。ただし表現の違いが混乱を招く可能性がある。

- [LOW] `sdd-publish-setup` が CLAUDE.md のコマンド一覧 (7) に含まれているが settings.json の allow リストにはエントリがない / CLAUDE.md:150-157, framework/claude/settings.json
  - `Skill(sdd-publish-setup)` が settings.json の permissions.allow に存在しない。他の全スキルは `Skill(...)` エントリを持つ。sdd-publish-setup は sdd-steering から内部的に呼び出される設計だが、ユーザーが直接 `/sdd-publish-setup` を実行した場合に権限許可が必要かどうか未定義。

- [LOW] refs/revise.md Part B Step 5.5 の Auto-Demotion で「Resume from Part A Step 4」と指示しているが、Part A Step 4 の前提条件 (Validate / Collect Intent / Impact Preview) がスキップされる / refs/revise.md:181
  - Auto-Demotion 後に「join Part A Step 4 (Architect dispatch) with the single FULL spec as the target」とあるが、Part A Step 4 は State Transition（フェーズリセット）ステップ。これは正しい意図だが、「Step 4 = Architect dispatch」という表現が refs/revise.md の Step 5 に書かれている「Design: Execute per refs/design.md with revision context」と混同される可能性がある。Step 4 は実際には `phase = design-generated` へのリセットであって Architect dispatch ではない。

### Confirmed OK

- Router dispatch completeness: SKILL.md の全サブコマンド (design, impl, review, run, revise, create, update, delete, -y, 空) が対応する refs ファイルに正しくルーティングされている。refs ファイルは存在し、対応する内容を持つ。
- Phase gate consistency: `initialized` → `design-generated` → `implementation-complete` (および `blocked`) の遷移が CLAUDE.md・refs/design.md・refs/impl.md・refs/run.md で一貫して定義されている。
- Auto-fix ループの基本構造: NO-GO → retry_count 増加 (max 5)、SPEC-UPDATE-NEEDED → spec_update_count 増加 (max 2)、aggregate cap 6 が refs/run.md Phase Handlers と CLAUDE.md Auto-Fix Counter Limits で一致している。
- Wave Quality Gate の完全性: refs/run.md Step 7 が Impl Cross-Check Review (7a)・Dead Code Review (7b)・Post-gate (7c) を網羅的に定義しており、run.md Phase Handlers および CLAUDE.md の記述と整合している。
- 1-Spec Roadmap Optimizations: Wave QG スキップ・Cross-Spec File Ownership Analysis スキップ・Wave-level dead-code review スキップ・コミットメッセージ形式変更が SKILL.md と refs/run.md の両方で一貫して定義されている。
- Verdict Persistence Format: SKILL.md の Shared Protocols セクションが B{seq}、W{wave}-B{seq}、W{wave}-DC-B{seq} のヘッダー形式を定義し、refs/review.md の scope ディレクトリ定義と整合している。
- Consensus mode の基本フロー: SKILL.md の `--consensus N` プロトコル (N パイプライン並列、閾値 ⌈N×0.6⌉、Consensus/Noise 分類) が refs/review.md から参照されており二重定義を避けている。
- Blocked spec 処理: CLAUDE.md Phase Gate・refs/run.md Step 6 Blocking Protocol・revise.md Part A Step 1 がすべて `blocked` フェーズを認識し適切に BLOCK または提示を行う。
- Revise Single-Spec から Cross-Cutting への昇格パス: refs/revise.md に「propose switch to Cross-Cutting Mode」の明示的な分岐が存在し、SKILL.md の Detect Mode が Cross-Cutting を「first word が spec name に不一致」として検出する静的判定と補完的に機能している。
- SubAgent ownership の整合性: spec.yaml の所有権が Lead のみに限定されており、全 SubAgent 定義 (sdd-architect, sdd-builder, sdd-taskgenerator 等) が「Do NOT update spec.yaml」を明示している。
- Inspector の CPF 出力形式: 全 Inspector が同一の CPF フォーマット (VERDICT / SCOPE / ISSUES / NOTES) を使用し、Auditor がそれを読み込む形になっており一貫している。
- Auditor の verdict 形式: sdd-auditor-design (GO/CONDITIONAL/NO-GO)、sdd-auditor-impl (GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED)、sdd-auditor-dead-code (GO/CONDITIONAL/NO-GO) がそれぞれの役割に適合した verdict セットを持つ。
- Review execution の File-based communication: Inspector が `reviews/active/{name}.cpf` に書き込み、Auditor が読み取り、Lead がアーカイブ (`reviews/B{seq}/`) するフローが refs/review.md と CLAUDE.md で一致している。
- Session Resume フロー: CLAUDE.md の Session Resume 手順 (handover 読み込み → decisions.md → buffer.md → spec.yaml スキャン → SESSION_START) が論理的に完結しており、pipeline stop protocol と整合している。
- 空ロードマップのエッジケース: `roadmap.md` 不在時のサブコマンド別 BLOCK 挙動が SKILL.md Error Handling で定義されており、run/update/revise は BLOCK、design/impl は auto-create に分岐する。
- retry limit 枯渇時: run.md Step 6 Blocking Protocol が exhaustion 後の fix/skip/abort 選択肢を完全に定義しており、blocked spec の downstream cascade も定義されている。
- settings.json の Agent エントリ: 全 26 Agent (sdd-analyst, sdd-architect, 全 Inspector, Auditor × 3, sdd-builder, sdd-taskgenerator, sdd-conventions-scanner) が settings.json の allow リストに含まれている。
- Revise refs の read タイミング: SKILL.md Step 2 の Execution Reference セクションに「After mode detection and roadmap ensure, Read the reference file for the detected mode」と明示されており、モード検出後に refs を読む順序が保証されている。
- Island spec (Wave Bypass): refs/run.md Step 3 で island spec の検出・fast-track 実行・Wave QG 除外が完全に定義されている。
- Design Lookahead: refs/run.md の Staleness guard が next-wave spec のリセット条件を明示しており、session resume 後も再評価される仕組みになっている。

### Overall Assessment

フロー整合性は全体として良好。致命的な欠落や矛盾は確認されなかった。

**主な懸念点（MEDIUM レベル）**:
1. Consensus mode における B{seq} の Router から pipeline への「渡し方」手順が SKILL.md レベルで省略されており、実装時に曖昧さが生じる可能性がある。
2. `--wave N` オプションのパース手順が refs/review.md Step 1 に記述されておらず、`--cross-check` との対称性が欠如している。
3. Dead-Code Review の verdict 保存先が standalone と Wave QG 経由で異なることが review.md 内でのみ注記形式で示されており、一見して混乱しやすい。
4. CLAUDE.md の Auto-Fix カウンタリセット条件 (全4条件) が refs/run.md には run.md 単体の条件しか記述されていないため、revise start やユーザー escalation によるリセットが run.md を読むだけでは不明。

**LOW レベルの問題**は全て表記揺れや参照整合性の軽微な問題であり、運用上の影響は限定的。

`sdd-publish-setup` の settings.json 未登録は、直接起動シナリオでの権限定義が曖昧という意味で確認が推奨される。
