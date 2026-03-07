## Flow Integrity Report

レビュー対象: sdd-roadmap Router → refs ディスパッチフロー
レビュー日時: 2026-03-01
レビュアー: Agent 1 (Flow Integrity)

---

### Issues Found

#### [HIGH] SKILL.md の allowed-tools に `Task` が記載されているが、refs ファイルは `Agent()` ツールを使用している

`framework/claude/skills/sdd-roadmap/SKILL.md:3`
`framework/claude/skills/sdd-reboot/SKILL.md:3`
`framework/claude/skills/sdd-review-self/SKILL.md:3`

**現状**: 3つのスキルの `allowed-tools` フィールドに `Task` が記載されている。

```
allowed-tools: Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion
```

**参照先の実際の呼び出し**:
- `refs/design.md:24` → `Agent(subagent_type="sdd-architect", run_in_background=true)`
- `refs/impl.md:26` → `Agent(subagent_type="sdd-taskgenerator", run_in_background=true)`
- `refs/review.md:94` → `Agent(subagent_type=..., run_in_background=true)`
- `refs/run.md:33` → `Agent(subagent_type="sdd-conventions-scanner", run_in_background=true)`
- `framework/claude/CLAUDE.md:32` → `Agent(subagent_type="sdd-architect", prompt="...")`

**問題**: `allowed-tools` は `Task` と記載されているが、実際の実行では `Agent` ツールを使う。Claude Code プラットフォームにおいて `Task` と `Agent` は別ツールである。`settings.json` の permissions セクションには `Agent(sdd-*)` は登録されているが、`Task(...)` エントリは存在しない。

**影響**: SKILL.md の frontmatter `allowed-tools: Task` が実際のツール使用（`Agent`）と不一致の場合、プラットフォームがツール権限チェックを厳密に行うと SubAgent dispatch が失敗する可能性がある。

---

#### [MEDIUM] revise.md Part B Step 7 の ConventionsScanner ディスパッチに `Agent()` 呼び出し形式が省略されている

`framework/claude/skills/sdd-roadmap/refs/revise.md:213`

**現状**:
```
- Dispatch `sdd-conventions-scanner` (mode: Generate) per run.md Step 2.5
```

**問題**: run.md Step 2.5 では `Agent(subagent_type="sdd-conventions-scanner", run_in_background=true)` の形式が明示されているが、revise.md での参照は「per run.md Step 2.5」と間接参照のみ。`run_in_background: true` であることも自明でない。他の Architect/Builder ディスパッチも同様に「`run_in_background: true`」の明示がなく、整合性がやや低い。

**影響**: 実行者が run.md Step 2.5 を参照せずにこの箇所のみ読んだ場合、ディスパッチ方法が不明確になる可能性がある。 (設計上は問題ないが、将来メンテナンス時の混乱リスク)

---

#### [MEDIUM] revise.md Part A Step 4 での phase 遷移が `design-generated` に設定しているが、design.md Step 3 ではそれを re-set する可能性がある

`framework/claude/skills/sdd-roadmap/refs/revise.md:62-66`

**現状**: revise.md Part A Step 4 は:
```
3. Set phase = design-generated
```
その後 Step 5 で design.md Step 3 を実行する。design.md Step 3 の後半:
```
Set phase = design-generated
Set orchestration.last_phase_action = null
```
と重複して設定する。これ自体は矛盾ではないが、revise.md Step 4 で `last_phase_action` を null に明示的にリセット後、design.md も null にするため二重操作になっている。

**問題**: 軽微な冗長性。混乱の原因にはならないが、何れかの変更で片方の null リセットが漏れると不整合が発生する。

---

#### [MEDIUM] Cross-Cutting Mode (revise.md Part B) のエスカレーションパスが run.md の Blocking Protocol を参照しているが、単一スペックの場合と同じ escalation options であることが明示されていない

`framework/claude/skills/sdd-roadmap/refs/revise.md:243-244`

**現状**:
```
- On exhaustion: escalate to user per run.md Step 6 blocking protocol (user chooses fix/skip/abort). Skip removes spec from tier; abort halts entire revision.
```

run.md Step 6 は単一スペックのパイプラインブロッキングを前提とした設計（downstream spec のブロック設定など）だが、Cross-Cutting Tier では「tier から除外する」という別の意味での skip が存在する。両者の skip の意味が異なる可能性がある。

**影響**: エスカレーション時の動作が「run.md Step 6 の通り」と解釈した場合、Cross-Cutting Tier のコンテキストでは downstream block 設定の必要性が不明確になる。

---

#### [MEDIUM] run.md Step 7a の Wave QG cross-check impl review のパスが review.md の Verdict Destination と一致していない

`framework/claude/skills/sdd-roadmap/refs/run.md:232-233`
`framework/claude/skills/sdd-roadmap/refs/review.md:142-147`

**run.md Step 7a**:
```
2. Persist verdict to `{{SDD_DIR}}/project/reviews/wave/verdicts.md` (header: `[W{wave}-B{seq}]`)
```

**review.md Verdict Destination**:
```
- **Wave-scoped review**: `{{SDD_DIR}}/project/reviews/wave/verdicts.md`
```

パスは一致しているが、SKILL.md Verdict Persistence Format では:
```
- Wave QG cross-check: `## [W{wave}-B{seq}] ...` (see run.md Step 7a)
- Wave QG dead-code: `## [W{wave}-DC-B{seq}] ...` (see run.md Step 7b)
```

これは一致している。ただし、**SKILL.md Verdict Persistence Format の step (a)** では:
```
a. Read existing file (or create with `# Verdicts: {feature}` header)
```
wave/verdicts.md に対するヘッダーが `# Verdicts: {feature}` となっているが、wave-scoped review の場合は feature 名でなく wave 番号が適切ではないか。この点が SKILL.md には記載されておらず、feature に対するヘッダー形式のみが示されている。

**影響**: Wave QG や Dead-code QG の verdicts.md ファイルに `# Verdicts: {feature}` という不適切なヘッダーが付与される可能性がある（軽微）。

---

#### [LOW] sdd-review-self/SKILL.md の Agent dispatch に `model="sonnet"` パラメータが指定されているが、CLAUDE.md および agents の frontmatter では model は frontmatter で定義されている

`framework/claude/skills/sdd-review-self/SKILL.md:57`

**現状**:
```
Each agent: `Agent(subagent_type="general-purpose", model="sonnet", run_in_background=true)`
```

self-review の Agent は `general-purpose` タイプ（専用 agent 定義なし）であり、`model="sonnet"` を dispatch 時に指定している。一方、sdd-roadmap が dispatch する Agents (sdd-architect, sdd-builder 等) は model を dispatch 時に指定せず、agent 定義の frontmatter `model: opus/sonnet` で管理している。

**影響**: 設計上の不一致だが機能的には問題ない。general-purpose agent は agent definition ファイルが存在せず、dispatch 時パラメータで model を指定する必要がある（正当な使用）。

---

#### [LOW] revise.md Part A Step 6 でのユーザー選択肢 (d) "Cross-cutting revision" → Part B への合流後、REVISION_INITIATED の (cross-cutting) 付記が重複して記録される可能性がある

`framework/claude/skills/sdd-roadmap/refs/revise.md:95`

**現状**:
- Part A Step 2 で `REVISION_INITIATED` を decisions.md に記録
- Part A Step 6, option (d) で `DIRECTION_CHANGE` を記録後、Part B Step 1 で再び `REVISION_INITIATED (cross-cutting)` を記録

Part A から Part B に移行する場合、REVISION_INITIATED が 2 回記録される（Part A での plain REVISION_INITIATED + Part B での REVISION_INITIATED (cross-cutting)）可能性がある。

**影響**: decisions.md のログが冗長になる可能性があるが、機能には影響しない。

---

### Confirmed OK

1. **Router サブコマンド → refs ディスパッチの網羅性**: SKILL.md Step 1 (Detect Mode) は design/impl/review/run/revise/create/update/delete の全サブコマンドをカバーし、Step 2 (Execution Reference) で各 ref ファイルへの dispatch が明示されている。

2. **フェーズゲートの整合性**: CLAUDE.md のフェーズ定義 (`initialized` → `design-generated` → `implementation-complete`, `blocked`) と各 ref ファイルのフェーズチェックが一致している。
   - design.md: `initialized`, `design-generated`, `implementation-complete` を正しくハンドル
   - impl.md: `design-generated` と `implementation-complete` のみ許可
   - review.md: Design Review は phase 制限なし（`blocked` のみブロック）、Impl Review は `implementation-complete` を要求

3. **NO-GO Auto-fix ループの整合性**: CLAUDE.md の `retry_count: max 5, aggregate cap: 6` と run.md の Phase Handler 実装、revise.md の Tier Checkpoint が一致している。

4. **SPEC-UPDATE-NEEDED ハンドリングの整合性**: Impl Auditor のみが SPEC-UPDATE-NEEDED を出力可能（Design Auditor は GO/CONDITIONAL/NO-GO のみ）。run.md Phase Handler の Impl Review completion は SPEC-UPDATE-NEEDED で `spec_update_count` をインクリメントし、Architect → TaskGenerator → Builder の cascade を実行する。CLAUDE.md `spec_update_count: max 2` と一致。

5. **Wave Quality Gate の完全性**: run.md Step 7a (Impl cross-check) → Step 7b (Dead-code) → Step 7c (Post-gate: counter reset, commit) の順序が確立されており、1-Spec Roadmap での Wave QG スキップも SKILL.md と run.md の両方で記載されている。

6. **Consensus Mode の矛盾なし**: SKILL.md のConsensus Mode プロトコル（N パイプライン、B{seq} 一括決定、閾値 ⌈N×0.6⌉）と review.md の実装が整合している。N=1 の場合のデフォルトパス (`active/` suffix なし) も両方に明記されている。

7. **Verdict Persistence フォーマットの一貫性**: SKILL.md の Verdict Persistence Format が review.md の Verdict Destination セクションで参照するすべてのパスをカバーしている（single-spec, dead-code, cross-check, wave, cross-cutting, self-review）。

8. **エッジケース: 空のロードマップ/1-spec**: SKILL.md で 1-Spec Roadmap Optimizations（Wave QG スキップ、cross-spec 分析スキップ）が明示されており、run.md Step 7 でも `1-Spec Roadmap: Skip this step` と明記されている。

9. **エッジケース: blocked spec**: review.md Step 2 で `blocked` フェーズを BLOCK。run.md Step 6 の Blocking Protocol で downstream spec を `blocked` に設定し、fix/skip/abort の選択肢を提示するフローが完全。revise.md Part A Step 1 でも `blocked` を BLOCK。

10. **エッジケース: retry limit 枯渇**: run.md Step 6 Blocking Protocol が詳述されており、aggregate cap 6 の到達で user escalation が発生する。revise.md Part B Tier Checkpoint も run.md Step 6 を参照した escalation パスを持っている。

11. **Ref 読み込みタイミングの明確性**: SKILL.md "Execution Reference" セクション (Line 96-104) に「After mode detection and roadmap ensure, Read the reference file for the detected mode」と明示されており、各 ref が読み込まれるタイミングが Router の実行フロー上で明確に定義されている。

12. **revise.md Detect Mode の Single-Spec/Cross-Cutting 判別**: SKILL.md Step 1 (Detect Mode) では「first word matches a spec name in specs/」で Single-Spec、マッチしない場合は Cross-Cutting として revise.md に dispatch。revise.md の Mode Detection セクションも同じロジックを繰り返し明示している。escalation パス（Single-Spec から 2+ specs 影響検出時に Cross-Cutting 提案）も revise.md Part A Step 3 に定義されている。

13. **Agent 定義の Frontmatter 整合性**: 全 SubAgent (sdd-architect, sdd-builder, sdd-taskgenerator, sdd-auditor-*, sdd-inspector-*, sdd-conventions-scanner, sdd-analyst) が有効な frontmatter (`name`, `description`, `model`, `tools`, `background: true`) を持っている。

14. **settings.json permissions の網羅性**: 全 26 Agent が `Agent(sdd-*)` エントリとして permissions に登録されている。Skill も 6 つ全て登録済み。

15. **impl.md Pilot Stagger Protocol**: 手順が明確（Pilot 選択 → Pilot dispatch → ConventionsScanner Supplement → 残り Builder 並列 dispatch）であり、run.md Phase Handler の "Implementation completion" が impl.md Steps 1-3 を参照して conventions brief path を渡すことが記載されている。

16. **Wave Bypass (Island Spec) フロー**: run.md Step 3 で Island Spec の検出ロジック（no dependencies, not depended upon）と Fast-track 実行（1-Spec optimizations 適用、Wave QG スキップ）が定義されており、波への組み戻し条件（file overlap 検出時）も記載されている。

17. **Design Lookahead の Staleness Guard**: run.md に lookahead spec の staleness guard（NO-GO で Architect 再 dispatch 時に依存 lookahead spec を `initialized` にリセット）が明示されており、セッション再開後の再評価も「動的に再計算」と記載されている。

18. **STEERING フィードバックループ**: review.md に `CODIFY`/`PROPOSE` の処理ルール（verdict handling 後、次フェーズ前に処理）が定義されており、CLAUDE.md の Steering Feedback Loop セクションと整合している。

---

### Overall Assessment

**総合評価: 概ね良好。1件の HIGH 問題（ツール名不一致）と複数の MEDIUM 問題（仕様のあいまいさ）を検出した。**

最重要の問題は `allowed-tools: Task` と実際の `Agent()` 呼び出しの不一致（HIGH）である。Claude Code プラットフォームでの動作に直接影響する可能性がある。`framework/claude/CLAUDE.md` は `Agent` ツールを使用する旨を明記しており、refs ファイルも `Agent()` を使用しているが、SKILL.md frontmatter が古い `Task` 表記のままである。

その他の問題はフロー整合性に直接影響しない軽微な曖昧さまたは冗長性である。

**修正優先度**:

| 優先度 | 問題 | 対象ファイル |
|--------|------|-------------|
| 1 (HIGH) | allowed-tools: Task → Agent に変更 | sdd-roadmap/SKILL.md, sdd-reboot/SKILL.md, sdd-review-self/SKILL.md |
| 2 (MEDIUM) | revise.md ConventionsScanner dispatch の Agent() 明示化 | refs/revise.md:213 |
| 3 (MEDIUM) | Wave QG verdicts.md ヘッダー形式の明示化 | SKILL.md Verdict Persistence Format |
| 4 (MEDIUM) | Cross-Cutting Tier の escalation options と run.md Step 6 の差異明示 | refs/revise.md:243-244 |
| 5 (LOW) | revise.md Part A→B 移行時の REVISION_INITIATED 重複記録 | refs/revise.md:95 |
