## Flow Integrity Report

**日時**: 2026-03-03
**対象バージョン**: v1.14.0
**レビュー担当**: Agent 1 — Flow Integrity

---

### Issues Found

#### [HIGH] Revise Mode: SKILL.md の Detect Mode と refs/revise.md の Mode Detection に軽微な表現ズレ
**場所**: `framework/claude/skills/sdd-roadmap/SKILL.md` L34-35 / `framework/claude/skills/sdd-roadmap/refs/revise.md` L8-10

SKILL.md Detect Mode:
```
$ARGUMENTS = "revise {feature} [instructions]" → Revise Mode (Single-Spec) — first word matches a spec name in specs/
$ARGUMENTS = "revise [instructions]"            → Revise Mode (Cross-Cutting) — first word does not match any spec name
```

refs/revise.md Mode Detection:
```
"revise <feature> [instructions]"  → feature matches known spec name → Single-Spec Mode (Part A)
"revise [instructions]"            → no feature name match           → Cross-Cutting Mode (Part B)
```

**問題**: SKILL.md では「first word matches a spec name in specs/」と記述されているが、refs/revise.md では「feature matches known spec name」と記述されており、「specs/ ディレクトリ内の spec 名と照合する」という具体的な照合先が refs 側に欠如している。Lead が実際にどのディレクトリを参照してスペック名を確認するかが refs 側では曖昧。実害は小さいが、セッション再開時に Lead が revise の引数を誤解するリスクがある。

---

#### [HIGH] Cross-Cutting Mode から Single-Spec Mode へのエスカレーション逆方向パスが SKILL.md Detect Mode に未記載
**場所**: `framework/claude/skills/sdd-roadmap/SKILL.md` Step 1 / `framework/claude/skills/sdd-roadmap/refs/revise.md` L179-181

refs/revise.md Part B Step 5.5 には「Auto-Demotion Check: FULL spec が 1 件だけになった場合は自動的に Single-Spec Mode に降格し、Part A Step 4 から再開する」という規則がある。しかし SKILL.md の Detect Mode テーブルにはこの自動降格パスが記載されていない。Lead が SKILL.md だけを読むと、Cross-Cutting → Single-Spec の自動降格フローを知らないままになる可能性がある。refs を読んで初めて気づく設計になっているが、Detect Mode セクション（SKILL.md 読み込み時の最初のステップ）にも概要注記を入れるべきである。

---

#### [MEDIUM] run.md Step 7b Dead-Code Review の NO-GO 再試行カウンター「in-memory only」の明示が CLAUDE.md と run.md 間で不一致
**場所**: `framework/claude/CLAUDE.md` L178-180 / `framework/claude/skills/sdd-roadmap/refs/run.md` L257

CLAUDE.md:
> Dead-Code Review NO-GO: max 3 retries (dead-code findings are simpler scope; exhaustion → escalate).
> Counter reset triggers: ... session resume (dead-code counters are in-memory only; see refs/run.md).

run.md L257:
> max 3 retries, tracked in-memory by Lead — not persisted to spec.yaml. Dead-code findings are wave-scoped and resolved within a single execution window; counter restarts at 0 on session resume.

**問題**: 両ファイルとも「in-memory only」「セッション再開時にリセット」であることを記述しているが、CLAUDE.md では「see refs/run.md」と参照を逆向きに指定している一方、run.md 側でも完全な説明を持っている。これ自体は問題ないが、CLAUDE.md の当該行は「Dead-code counters are in-memory only; see refs/run.md」と書いており、run.md を確認して初めて「counter restarts at 0 on session resume」であることが明確になる。CLAUDE.md 側の記述だけでは「セッション再開時に 0 に戻る」が曖昧なため、Lead が再開時に誤ってカウンターを維持する可能性がある。

---

#### [MEDIUM] run.md Step 7a Wave QG Cross-Check の SPEC-UPDATE-NEEDED カスケード後の re-run タイミングが曖昧
**場所**: `framework/claude/skills/sdd-roadmap/refs/run.md` L250-251

run.md:
> SPEC-UPDATE-NEEDED → identify target spec(s), increment spec_update_count, cascade per spec: Architect → TaskGenerator → Builder → individual Impl Review. After ALL target spec cascades complete → re-run cross-check

**問題**: 「individual Impl Review」が GO/CONDITIONAL であることを確認してから cross-check を再実行する手順が明示されていない。個別 Impl Review の結果ハンドリング（GO/NO-GO）とそれに伴う counter 更新が省略されている。run.md Phase Handlers（Impl Review completion）にあるカウンター更新ロジック（retry_count, spec_update_count, aggregate cap）がこのパスでも適用されるのかが不明確。Lead が SPEC-UPDATE-NEEDED → cascade → 個別 Impl Review → NO-GO の場合の処理を誤る可能性がある。

---

#### [MEDIUM] review.md の Verdict Destination: dead-code standalone のパスが run.md Step 7b と微妙に異なる
**場所**: `framework/claude/skills/sdd-roadmap/refs/review.md` L77, L134 / `framework/claude/skills/sdd-roadmap/refs/run.md` L252-254

review.md:
```
Project-level (dead-code): {{SDD_DIR}}/project/reviews/dead-code/ (standalone). When called from Wave QG (run.md Step 7b): use {{SDD_DIR}}/project/reviews/wave/ instead.
```

run.md Step 7b:
```
Persist verdict to {{SDD_DIR}}/project/reviews/wave/verdicts.md (header: [W{wave}-DC-B{seq}])
```

**問題**: 整合しているが、review.md の Step 1「Determine review scope directory」の記述（L77）では:
```
Project-level (dead-code): {{SDD_DIR}}/project/reviews/dead-code/ (standalone)
Project-level (wave): {{SDD_DIR}}/project/reviews/wave/
```
と分かれており、Wave QG から呼ばれる場合は `wave/` を使うことが review.md の Step 1 本文からは読み取れない（説明が L134 の Verdict Destination テーブルにのみある）。Step 1 にも Wave QG 文脈の条件分岐を追記するとより明確になる。

---

#### [MEDIUM] revise.md Part A Step 6: 「Cross-cutting revision」選択時の Part B への合流手順が不完全
**場所**: `framework/claude/skills/sdd-roadmap/refs/revise.md` L92-96

```
4. (d) Cross-cutting revision: Switch to cross-cutting mode for coordinated downstream revision
   - Record DIRECTION_CHANGE in decisions.md, join Part B Step 2 with completed target spec + affected dependents pre-populated
```

**問題**: Part A Step 3（Impact Preview）でのエスカレーション記述（L47）では「join Part B Step 2 with revision intent and target spec pre-populated. Skip Part B Step 1 (REVISION_INITIATED already recorded in Part A Step 2)」と明記されているが、Step 6 の Option d の合流先では「Skip Part B Step 1」の指示が欠けている。Step 3 からと Step 6 からでは合流先が同じ Part B Step 2 であっても、状態（REVISION_INITIATED の記録有無、target spec の phase）が異なる可能性があり、Step 6 からの合流には「対象 spec は already implementation-complete から再度 implementation-complete に戻った直後」という文脈が重要。この差異が明記されていない。

---

#### [MEDIUM] SKILL.md Execution Reference と refs読み込みタイミングの明示不足
**場所**: `framework/claude/skills/sdd-roadmap/SKILL.md` L96-105

```
After mode detection and roadmap ensure, Read the reference file for the detected mode:
- Design → Read refs/design.md
- Impl → Read refs/impl.md
- Review → Read refs/review.md
- Run → Read refs/run.md
- Revise → Read refs/revise.md
- Create / Update / Delete → Read refs/crud.md
```

**確認済み**: 読み込みタイミング（mode detection と roadmap ensure の後）は明示されており問題なし。ただし、run.md が refs/design.md、refs/impl.md、refs/review.md を「参照」することが run.md 内に記述されているが、run.md 読み込み後に Lead が design.md/impl.md/review.md を別途読み込む必要があるかどうかが不明確。run.md の Phase Handlers には「Execute per refs/design.md Step 3」「Execute per refs/impl.md」等の記述があり、これらを参照しながら実行することが前提だが、Lead が run.md 読み込み後に明示的に各 refs を再読する必要があるか（すでに知識として持っているとみなすか）の指示がない。

---

#### [MEDIUM] Consensus Mode: B{seq} の決定主体が SKILL.md と review.md で齟齬
**場所**: `framework/claude/skills/sdd-roadmap/SKILL.md` L115 / `framework/claude/skills/sdd-roadmap/refs/review.md` L80

SKILL.md（Consensus Mode セクション）L115:
> Determine review scope directory (see refs/review.md Step 1) and B{seq} from {scope-dir}/verdicts.md (increment max existing, or start at 1)

review.md Step 2:
> For consensus mode: Router determines B{seq} once and passes it to all N pipelines (this step uses the Router-provided value instead of computing its own).

**問題**: これ自体は設計として矛盾しない（Router が決めて review.md Step 2 は Router 提供値を使う）。ただし review.md Step 3（Create review directory）には「For consensus mode: {scope-dir}/active-{p}/」とあり、B{seq} の値がどのように各パイプラインの Auditor に渡されるかが明示されていない。SKILL.md Step 4（Spawn N sets of Inspectors）の後で Auditor をスポーンする際に B{seq} を含める必要があるが、Auditor プロンプトへの B{seq} 引き渡し手順が記述されていない。

---

#### [LOW] revise.md Part B Step 7.5 と run.md Phase Handlers の SPEC-UPDATE-NEEDED カスケード手順の微妙な差異
**場所**: `framework/claude/skills/sdd-roadmap/refs/revise.md` L243-244 / `framework/claude/skills/sdd-roadmap/refs/run.md` L204

revise.md Step 7 Tier Checkpoint:
> on SPEC-UPDATE-NEEDED: cascade per run.md

run.md Phase Handlers（Impl Review completion）:
> SPEC-UPDATE-NEEDED → increment spec_update_count (max 2). Reset orchestration.last_phase_action = null, set phase = design-generated. Cascade: Architect (with SPEC_FEEDBACK) → TaskGenerator → Builder → re-run Impl Review. All tasks fully re-implemented.

**問題**: revise.md が「cascade per run.md」と参照しているため、run.md を読まないと詳細が不明。問題はないが、revise.md での SPEC_FEEDBACK の引き渡し（Architect へ）が明示されていない。run.md には「Architect (with SPEC_FEEDBACK)」とあるが、revise.md のカスケードでも SPEC_FEEDBACK（Auditor の SPEC_FEEDBACK セクション内容）を Architect に渡すべきことが revise.md 内に記述されていない。

---

#### [LOW] 1-Spec Roadmap Optimizations: review dead-code の手動実行可否と Wave QG スキップの整合性
**場所**: `framework/claude/skills/sdd-roadmap/SKILL.md` L87-91

```
1-Spec Roadmap Optimizations:
- Skip Wave Quality Gate: Cross-check review is meaningless with 1 spec
- Skip Cross-Spec File Ownership Analysis: No overlap possible
- Skip wave-level dead-code review: User can still run /sdd-roadmap review dead-code manually
```

**確認済み問題なし**: run.md Step 7 に「1-Spec Roadmap: Skip this step (see Router §1-Spec Roadmap Optimizations). Proceed to Post-gate.」とあり整合している。ただし「User can still run /sdd-roadmap review dead-code manually」とある場合、SKILL.md の Review Subcommand 節に `review dead-code` の 1-spec 動作（スタンドアロン実行はOK）の確認が review.md Step 1 の「Dead Code Review: No phase gate」に依存していることが SKILL.md 本文からは追いにくい。軽微。

---

#### [LOW] session.md Auto-Draft の「run pipeline dispatch loop」例外条件の記述場所
**場所**: `framework/claude/CLAUDE.md` L238 / `framework/claude/skills/sdd-roadmap/refs/run.md` L178

CLAUDE.md:
> Exception — run pipeline dispatch loop: Auto-draft only at Wave QG post-gate, user escalation, and pipeline completion. Skip at individual phase completions.

run.md Phase Handlers:
> Auto-draft policy (dispatch loop): During run pipeline execution, auto-draft session.md only at: Wave QG post-gate, user escalation, pipeline completion. Skip auto-draft at individual phase completions.

**確認済み**: 両ファイルで記述が一致しており問題なし。ただし revise.md には同様の auto-draft 例外ポリシーへの明示的な言及がなく、revise pipeline 実行中の auto-draft タイミングが曖昧。revise.md Part A Step 7 と Part B Step 9 には「Auto-draft session.md」があるが、パイプライン実行中の個別フェーズ完了時のスキップポリシーは記載されていない。

---

### Confirmed OK

- **Router dispatch completeness**: SKILL.md Step 1 Detect Mode テーブルがすべてのサブコマンド（design, impl, review, run, revise, create, update, delete, -y, 空）を網羅し、正確な refs にルーティングしている。
- **Phase gate consistency**: design.md の Phase Gate（initialized/design-generated/implementation-complete/blocked）、impl.md の Phase Gate（design-generated/implementation-complete）、review.md の Phase Gate（design.md 存在確認、blocked チェック）がすべて CLAUDE.md の Phase-Driven Workflow 定義と整合している。
- **Auto-fix loop (NO-GO)**: run.md Phase Handlers の Design Review completion / Impl Review completion における retry_count max 5、aggregate cap 6 の記述が CLAUDE.md §Auto-Fix Counter Limits と完全に一致している。
- **Auto-fix loop (SPEC-UPDATE-NEEDED)**: run.md の spec_update_count max 2、aggregate cap 6 の記述が CLAUDE.md と一致。CONDITIONAL = GO（カウンターをリセットしない）も一致。
- **Wave quality gate completeness**: run.md Step 7 が (a) Impl Cross-Check → (b) Dead Code Review → (c) Post-gate の順序を正確に定義しており、各ステップの verdict ハンドリングが完備されている。
- **Consensus mode consistency**: SKILL.md Consensus Mode セクションと review.md Step 99（「If --consensus N, apply Consensus Mode protocol (see Router)」）が相互参照しており矛盾なし。N=1 の場合（デフォルト）のフォールバック動作も両ファイルで一致。
- **Verdict persistence format**: SKILL.md Verdict Persistence Format セクションが per-feature、Wave QG cross-check（[W{wave}-B{seq}]）、Wave QG dead-code（[W{wave}-DC-B{seq}]）、Cross-cutting（specs/.cross-cutting/{id}/verdicts.md）を網羅。review.md の Verdict Destination テーブルと完全一致。
- **Blocked spec handling**: Phase Gate で `phase=blocked` の場合のブロック動作が design.md、impl.md、review.md、revise.md Part A Step 1 のすべてで一貫して記述されている。run.md Step 6 Blocking Protocol もダウンストリーム spec への `phase=blocked` 設定手順を明確に定義。
- **Retry limit exhaustion**: run.md Step 6 Blocking Protocol が retry exhaustion 時の user escalation（fix/skip/abort）を定義。revise.md Part B Step 7 Tier Checkpoint も「exhaustion → escalate to user per run.md Step 6 blocking protocol」と参照しており整合。
- **Empty roadmap edge case**: SKILL.md の `review dead-code` / `review --cross-check` / `review --wave N` で roadmap なし → BLOCK（L74）が明示されている。
- **1-spec optimization skip conditions**: SKILL.md §1-Spec Roadmap Optimizations が Wave QG スキップ、Cross-Spec File Ownership スキップ、dead-code review スキップを明記。run.md Step 7「1-Spec Roadmap: Skip this step」と整合。
- **Single-Spec Roadmap Ensure**: design/impl/review サブコマンドの roadmap ensure フロー（roadmap あり/なし、spec 登録済み/未登録、auto-add to roadmap with Backfill）が SKILL.md に完備。
- **Revise Single-Spec → Cross-Cutting escalation**: revise.md Part A Step 3（2+ specs 影響 → Cross-Cutting 提案）→ Part B Step 2 合流の路は明確に定義されている。Step 4 が実行前（target spec まだ implementation-complete）のまま Part B に合流する条件も明記（L47: "Step 4 has NOT executed"）。
- **Cross-Cutting → Single-Spec auto-demotion**: revise.md Part B Step 5.5 に Auto-Demotion Check が定義されており、FULL spec が 1 件のみ残った場合の Part A Step 4 への合流も記述済み。
- **SubAgent dispatch all run_in_background: true**: CLAUDE.md §SubAgent Lifecycle の「Lead dispatches SubAgents via Agent tool with run_in_background: true always. No exceptions」と、各 refs の Spawn 手順が一致。
- **SubAgent result minimization**: Builder（WRITTEN:{path} + minimal summary）、Review SubAgents（WRITTEN:{path} のみ）、Analyst（WRITTEN:{path} + structured summary）のプロトコルが CLAUDE.md §SubAgent Lifecycle と各 Agent 定義（sdd-builder.md、sdd-auditor-impl.md 等）で一致。
- **Artifact ownership constraints**: CLAUDE.md §Artifact Ownership の「Lead は design.md/tasks.yaml/実装ファイルを直接編集しない」規則が、revise.md Part A Step 5（「Execute per refs/design.md with revision context」= Architect が実行）と整合している。
- **Knowledge Auto-Accumulation**: Builder の [PATTERN]/[INCIDENT]/[REFERENCE] タグ → impl.md Step 3 で Lead が grep → buffer.md へ追記、という流れが CLAUDE.md と impl.md で一致。
- **Dead-code review Inspector set**: review.md が `sdd-inspector-dead-settings`, `sdd-inspector-dead-code`, `sdd-inspector-dead-specs`, `sdd-inspector-dead-tests` の 4 体を定義。sdd-auditor-dead-code.md の Input Handling（CPF ファイル 1-4）と一致。
- **Design review Inspector set**: review.md が 6 体（rulebase, testability, architecture, consistency, best-practices, holistic）を定義。sdd-auditor-design.md の Input Handling と一致。
- **Impl review Inspector set**: review.md が 6 体 + E2E（条件付き）+ Web 2 体（条件付き）を定義。sdd-auditor-impl.md の Input Handling（CPF ファイル 1-9）と一致。
- **Steering Feedback Loop**: review.md §Steering Feedback Loop Processing（CODIFY → 直接適用、PROPOSE → ユーザー承認）が CLAUDE.md §Steering Feedback Loop と整合。
- **tmux Integration**: review.md §Web Inspector Server Protocol が `{{SDD_DIR}}/settings/rules/tmux-integration.md` の Pattern A を参照しており、tmux-integration.md に Server Lifecycle pattern（Pattern A）が定義されている。整合。
- **CLAUDE.md tmux-integration.md 参照**: CLAUDE.md L317 の「Full patterns: {{SDD_DIR}}/settings/rules/tmux-integration.md」と、tmux-integration.md のパターン定義が対応。
- **Session Resume protocol**: CLAUDE.md §Session Resume の 7 ステップが網羅的に定義されており、tmux Orphan Cleanup（Step 5a）も tmux-integration.md §Orphan Cleanup に対応するパターンが存在。
- **CPF format consistency**: cpf-format.md の仕様（KEY:VALUE、pipe 区切り、severity C/H/M/L）が sdd-auditor-impl.md、sdd-auditor-design.md、sdd-auditor-dead-code.md の Output Format と一致。
- **reboot.md Phase 7の Design-only dispatch loop**: reboot.md が run.md Step 4 の dispatch loop を再利用（impl フェーズをスキップ）するよう記述しており、review.md §Review Decomposition も同一プロトコルを参照している。
- **settings.json Agent() エントリ**: 全 27 エージェント定義ファイル（sdd-analyst, sdd-architect, sdd-auditor-*, sdd-builder, sdd-conventions-scanner, sdd-inspector-* 全体）が settings.json の allow リストに対応する Agent() エントリを持っている。
- **settings.json Skill() エントリ**: sdd-roadmap, sdd-steering, sdd-status, sdd-handover, sdd-reboot, sdd-release, sdd-review-self, sdd-publish-setup の 8 スキルが settings.json に登録されており、framework/claude/skills/ 内の実ファイルと対応。（sdd-review-self-codex は内部実験的ツールのため settings.json 未登録だが、これは意図的と判断。）

---

### Overall Assessment

**全体評価**: フレームワーク全体のフロー整合性は高い水準にある。Router → refs のディスパッチチェーンはすべてのサブコマンドで正確に機能しており、phase gate、auto-fix loop、verdict persistence、edge case 処理のいずれも major な矛盾は検出されなかった。

**主要リスク**:
1. **[HIGH] Revise Mode Detect の照合先曖昧性**: refs/revise.md の Mode Detection に「specs/ ディレクトリで照合する」という具体的な手順が明記されていないため、Lead が初めて revise コマンドを処理する際に実装の判断に迷う可能性がある。SKILL.md 側の表現を revise.md にも反映することで解消できる。
2. **[HIGH] Cross-Cutting Auto-Demotion の SKILL.md 非掲載**: Part B Step 5.5 の Auto-Demotion フローが SKILL.md の Detect Mode に未記載のため、Cross-Cutting として起動されたパイプラインが単一 FULL spec に縮退した場合の挙動を Lead が見落とすリスクがある。
3. **[MEDIUM] Wave QG SPEC-UPDATE-NEEDED → cascade 後の 個別 Impl Review 失敗ハンドリング**: パスの分岐が run.md に明示されておらず、Lead の実装判断に依存している。

**修正優先度**:

| 優先度 | 問題 | 対象ファイル |
|--------|------|------------|
| 1 | Revise Mode 照合先の明記 | refs/revise.md L8-10 |
| 2 | Auto-Demotion フロー SKILL.md 掲載 | SKILL.md Step 1 Detect Mode |
| 3 | Wave QG SPEC-UPDATE-NEEDED cascade の個別 Impl Review NO-GO 処理明記 | refs/run.md L250-251 |
| 4 | review.md Step 1 に Wave QG 文脈の dead-code ディレクトリ分岐追記 | refs/review.md L75-79 |
| 5 | revise.md Part A Step 6 Option d の「Skip Part B Step 1」追記 | refs/revise.md L92-96 |
| 6 | revise pipeline 実行中の auto-draft ポリシー明記 | refs/revise.md |
