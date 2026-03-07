## Flow Integrity Report

**Agent**: Agent 1 — Flow Integrity Review
**Date**: 2026-03-03
**Scope**: sdd-roadmap Router → refs dispatch flow, all modes

---

### Issues Found

#### [HIGH] `review dead-code` サブコマンドのルーター登録が不完全

- **場所**: `framework/claude/skills/sdd-roadmap/SKILL.md:23`
- **内容**: Detect Mode テーブルに `$ARGUMENTS = "review dead-code"` が列挙されているが、Router が `review dead-code` をどの refs（→ `refs/review.md`）にルーティングするかが "Execution Reference" セクション（行 96-105）に **明示されていない**。他の `review design {feature}` / `review impl {feature}` は "Review Subcommand → Read `refs/review.md`" と同じ行に包括されるが、`review dead-code` が `review` に属することは文脈上類推可能なものの、明記がない。読み手は「dead-code は Review に含まれるのか、それとも別 ref があるか」と疑問を持つ可能性がある。
- **影響**: MEDIUM（設計上は動くが、明示性が低い）

#### [MEDIUM] `run` パイプライン中の Design Review の auto-fix ループで SPEC-UPDATE-NEEDED の扱いが CLAUDE.md と部分的に齟齬

- **場所**: `framework/claude/skills/sdd-roadmap/refs/run.md:188-189`
- **内容**: `run.md` Phase Handlers — Design Review completion で「`SPEC-UPDATE-NEEDED` → not expected for design review. If received, escalate immediately.」と記載されている。これは `CLAUDE.md` の「CONDITIONAL = GO (proceed)」や Auto-Fix Counter Limits との整合性は保たれているが、`revise.md` Part B Step 7 — Tier Execution にも「Design Review: SPEC-UPDATE-NEEDED is not expected for design review. If received, escalate immediately.」と同じ記述が独立して存在しており、仕様の重複がある。問題は、どちらかが変更されたときにもう一方が漏れるリスクが構造上存在すること。この重複自体は一致しているので現時点では矛盾ではないが、保守リスクとして分類する。
- **影響**: LOW（現状は一致）

#### [MEDIUM] Revise Mode の Detect Mode — `revise` サブコマンド名判定の曖昧さ

- **場所**: `framework/claude/skills/sdd-roadmap/SKILL.md:34-35`
- **内容**: SKILL.md Detect Mode で `"revise {feature} [instructions]"` vs `"revise [instructions]"` の区別は「first word matches a spec name in specs/」で行うと定義されている。しかし `refs/revise.md` の Mode Detection では「Arguments parsing (Lead checks first word after "revise" against existing spec names)」とほぼ同じロジックを別途記述している。これ自体は矛盾ではないが、**SKILL.md が refs/revise.md を Read する前に** Route 判定を終わらせる（SKILL.md 上の文脈推断）か、refs/revise.md を Read してから判定するか、の順序が SKILL.md では明示されていない。SKILL.md の "Execution Reference" セクション（行 96-105）には "Revise → Read `refs/revise.md`" と書かれており、refs を読んで判定するという解釈になるが、refs に入る前に「Single-Spec か Cross-Cutting か」を知るために spec 名照合が必要というジレンマがある。
- **影響**: MEDIUM（Run 時に Lead が両方読む前提で問題ないが、明示的な「いつ判定するか」の説明が不足）

#### [MEDIUM] Consensus モードの B{seq} 決定タイミングの記述が二重管理

- **場所**: `framework/claude/skills/sdd-roadmap/SKILL.md:115-116` と `refs/review.md:80`
- **内容**: SKILL.md の Consensus Mode セクション（行 115）で「Determine B{seq} from `{scope-dir}/verdicts.md` (increment max existing, or start at 1)」と記述。一方 `refs/review.md` Step 2（行 80）では「Determine B{seq}: read `{scope-dir}/verdicts.md`, increment max existing batch number (or start at 1). **For consensus mode: Router determines B{seq} once and passes it to all N pipelines (this step uses the Router-provided value instead of computing its own).**」と記述されており、consensus 時は review.md が Router 値を使うべきと明記されている。ただし SKILL.md 側には「review.md Step 2 を使うなら Router から渡すこと」を促す説明がなく、review.md を読まなければ Router 側の責務が不明。
- **影響**: LOW（review.md を読めば理解できるが、SKILL.md 単体では不明確）

#### [LOW] `1-Spec Roadmap` の Wave QG スキップ条件が SKILL.md と run.md で重複表現

- **場所**: `framework/claude/skills/sdd-roadmap/SKILL.md:87-90` および `refs/run.md:237`
- **内容**: SKILL.md の「1-Spec Roadmap Optimizations」と run.md Step 7 の「1-Spec Roadmap: Skip this step」は同じ内容を繰り返している。一致しているため矛盾はないが、将来の変更で一方を見落とすリスクがある。
- **影響**: LOW

#### [LOW] `sdd-review-self-ext` の `$SCOPE_DIR` が `self-ext` なのに verdicts.md の B{seq} 決定では `$SCOPE_DIR` を参照

- **場所**: `framework/claude/skills/sdd-review-self-ext/SKILL.md:45-46`, Step 8.1
- **内容**: ext の `$SCOPE_DIR = .sdd/project/reviews/self-ext` であり、`sdd-review-self` の `$SCOPE_DIR = .sdd/project/reviews/self/` と異なる。これは意図的な分離であり問題ない。ただし `sdd-review-self` Step 6.1 では verdicts.md のフォーマットにヘッダー行 `## [B{seq}] {ISO-8601} | v{version} | agents:{completed}/{dispatched}` を使うのに対し、`sdd-review-self-ext` Step 8.1 では `## [B{seq}] {ISO-8601} | {ENGINE_NAME} | agents:{completed}/{dispatched}` と `ENGINE_NAME` フィールドが追加されている。同一ファイルを共有しない（別ディレクトリ）ので矛盾ではないが、ドキュメント上の Verdict Persistence Format（SKILL.md 行 127-140）は「per-feature/standalone」等の共通フォーマットを説明しており、self-review の独自フォーマットは記述されていない。
- **影響**: LOW（動作上の問題はないが、ドキュメントの網羅性がやや低い）

#### [LOW] `settings.json` の `Agent(sdd-inspector-web-visual)` エントリが存在するが、対応するエージェント定義の `name` フィールドが `sdd-inspector-web-visual` と一致している点を確認

- **場所**: `framework/claude/settings.json:39`
- **内容**: settings.json に `"Agent(sdd-inspector-web-visual)"` が含まれており、`framework/claude/agents/sdd-inspector-web-visual.md` の frontmatter `name: sdd-inspector-web-visual` と一致。問題なし（確認 OK）。

---

### Confirmed OK

1. **Router dispatch completeness**: SKILL.md Detect Mode の全サブコマンド（design, impl, review design, review impl, review dead-code, review --consensus N, review --cross-check, review --wave N, run, run --gate, run --consensus N, revise {feature}, revise [instructions], create, update, delete, -y, ""）が網羅されており、それぞれ対応する refs にルーティングされる。

2. **Phase gate consistency**: 各 ref の Phase Gate が CLAUDE.md の定義するフェーズ（`initialized` → `design-generated` → `implementation-complete`, `blocked`）と一致している。
   - `refs/design.md` Step 2: `blocked` → BLOCK, `implementation-complete` → 警告, その他 OK
   - `refs/impl.md` Step 1: `blocked` → BLOCK, `design-generated` および `implementation-complete` → proceed, 他 → BLOCK
   - `refs/review.md` Step 2: Design Review = `design.md` 存在確認 + blocked 確認; Impl Review = phase `implementation-complete` 確認

3. **Auto-fix loop（NO-GO）**: CLAUDE.md の retry_count 上限 5、aggregate cap 6 が `refs/run.md` Phase Handlers (行 188, 203-205)、`refs/revise.md` Part A Step 5 (行 81-82)、Part B Step 7 Tier Checkpoint (行 247)、`refs/reboot.md` Phase 7 Verdict Handling (行 180) と整合している。

4. **Auto-fix loop（SPEC-UPDATE-NEEDED）**: spec_update_count 上限 2、aggregate cap 6 が run.md Phase Handlers (行 204)、revise.md Part A (行 82)、Part B Step 7 (行 247) と一致。CONDITIONAL = GO の扱いも run.md (行 187, 202) で明示。

5. **Wave Quality Gate**: run.md Step 7 の構造（7a Impl Cross-Check → 7b Dead Code Review → 7c Post-gate）が完全で、各サブステップの verdict 処理（GO/CONDITIONAL → 次へ、NO-GO → retry, SPEC-UPDATE-NEEDED → cascade）が定義されている。1-Spec Roadmap での Skip も明示。

6. **Consensus モードの動作**: SKILL.md Shared Protocols（行 111-125）で N パイプライン並列、閾値 ⌈N×0.6⌉、集約ロジック（Confirmed/Noise分類）が定義されており、review.md Step 99 で `refs/review.md` へ委譲。一貫している。

7. **Verdict persistence format**: SKILL.md の Verdict Persistence Format（行 127-140）が review.md と整合。per-feature、Wave QG cross-check `[W{wave}-B{seq}]`、Dead Code `[W{wave}-DC-B{seq}]`、cross-cutting `specs/.cross-cutting/{id}/verdicts.md` の各ヘッダーが run.md (行 243, 254) と一致。

8. **エッジケース — 空ロードマップ**: review dead-code と review --cross-check / --wave N は roadmap.md 不在時に SKILL.md が BLOCK（行 73-74）。その他の lifecycle サブコマンドは auto-create（行 75-82）。

9. **エッジケース — 1-spec ロードマップ**: SKILL.md に「1-Spec Roadmap Optimizations」セクションがあり、Wave QG スキップ、Cross-Spec File Ownership スキップ、wave-level dead-code スキップ、commit message フォーマット変更の 4 点が明示されている。

10. **エッジケース — blocked スペック**: 各 ref で `phase == blocked` → BLOCK、Blocking Protocol（run.md Step 6）で downstream スペックの blocked 設定・復元・skip・abort が完全に定義されている。

11. **エッジケース — retry 上限到達**: CLAUDE.md §Auto-Fix Counter Limits と run.md Step 6 Blocking Protocol が整合。Dead-code は 上限 3 で別計上（in-memory）と明記（run.md 行 257、CLAUDE.md 行 178）。

12. **refs 読み込みタイミングの明示**: SKILL.md Execution Reference セクション（行 94-106）で「After mode detection and roadmap ensure, Read the reference file for the detected mode」と明示されており、Read clarity は満たされている。

13. **Revise モード — Single-Spec から Cross-Cutting へのエスカレーション**: revise.md Part A Step 3 (行 47) に「User accepts → join Part B Step 2」のパスが明示。Part B Step 5.5 Auto-Demotion Check (行 179-181) で逆方向（Cross-Cutting → Single-Spec）も定義。SKILL.md Detect Mode（行 34-35）の記述と整合。

14. **Revise モード — decisions.md 記録**: Part A Step 2 で `REVISION_INITIATED`、Part B Step 1 で `REVISION_INITIATED (cross-cutting)` の記録が指定されており CLAUDE.md §decisions.md Recording と一致。

15. **Agent frontmatter**: 全エージェント（sdd-architect, sdd-auditor-design, sdd-auditor-impl, sdd-auditor-dead-code, sdd-builder, sdd-taskgenerator, sdd-conventions-scanner, sdd-analyst, 各 Inspector）の YAML frontmatter に `model`, `tools`, `background`, `description` が存在し、モデルは opus または sonnet で適切。

16. **SubAgent dispatch pattern**: 全ての dispatch が `Agent(subagent_type=..., run_in_background=true)` 形式で記述されており、CLAUDE.md の「foreground dispatch is prohibited」要件と整合。

17. **ConventionsScanner モード**: Generate モードと Supplement モードが sdd-conventions-scanner.md に定義され、run.md Step 2.5 (Generate) および impl.md Pilot Stagger Protocol (Supplement) から正しくディスパッチされる。reboot.md では ConventionsScanner が使用されないことが Phase 3 で明示されている（バイアス防止）。

18. **CPF フォーマット**: 各 Inspector の output format が cpf-format.md の規則（KEY:VALUE, pipe-delimited rows, section omission）と一致。

19. **Verdict destination by review type**: review.md 末尾の Verdict Destination 表（行 130-138）が run.md の各パス（wave verdicts: `reviews/wave/verdicts.md`、standalone dead-code: `reviews/dead-code/verdicts.md`）と整合。

20. **settings.json の Agent 許可リスト**: 全 SubAgent（sdd-analyst, sdd-architect, sdd-auditor-*, sdd-builder, sdd-conventions-scanner, sdd-inspector-*）が settings.json の allow リストに登録されており、sdd-review-self-ext は登録なし（外部エンジン使用のため Agent ツール不要）。また `Skill(sdd-review-self-ext)` も settings.json にない（意図的）。

21. **sdd-review-self の $SCOPE_DIR**: SKILL.md 行 41 で `$SCOPE_DIR = {{SDD_DIR}}/project/reviews/self/` と定義されており、Agent 1-4 の出力先 `$SCOPE_DIR/active/agent-{N}-{name}.md` も整合。

---

### Overall Assessment

フレームワークのフロー整合性は概ね良好。主要なパイプライン（Design → Review Design → Impl → Review Impl → Wave QG → Dead Code Review → Post-gate → Commit）は各 refs 間で一貫して定義されており、auto-fix ループのカウンター管理、Blocking Protocol、Consensus モード、Revise の Single-Spec/Cross-Cutting 切り替えも正しく実装されている。

**重要度の高い指摘（HIGH 1件）**: `review dead-code` の Review サブコマンドへのルーティングが SKILL.md の Execution Reference セクションで明示的に列挙されていない点は、読み手の誤解リスクがある。他のサブコマンドが review 型として `refs/review.md` を参照することは文脈上明確だが、`dead-code` の明示的な言及を追加することでより堅牢になる。

**中程度の指摘（MEDIUM 2件）**: (1) Revise Mode の「いつ spec 名照合するか」の順序説明不足、(2) SPEC-UPDATE-NEEDED 処理の run.md/revise.md 間重複（保守リスク）。いずれも現時点では動作に影響しない。

**低優先度（LOW 3件）**: 1-Spec 最適化の重複記述、self/self-ext の verdicts.md フォーマット差異のドキュメント未記載、Consensus B{seq} 委譲の SKILL.md 側説明不足。

致命的な Flow Integrity 問題（情報欠損によるパイプライン停止リスク）はなし。
