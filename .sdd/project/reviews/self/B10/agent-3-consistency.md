## Consistency & Dead Ends Report

**対象バージョン**: v1.3.0
**レビュー日時**: 2026-02-27
**レビュー対象**: framework/claude/ 全ファイル + install.sh

---

### Issues Found

#### [HIGH] Inspectorカウント不一致: CLAUDE.md 記述と実際のエージェント定義

**説明**: `CLAUDE.md` L26 に「6 design, 6 impl +2 web (impl only, web projects), 4 dead-code」と記述されているが、実際のエージェント定義ファイル数と照合すると以下の通り：
- Design Inspectors: `sdd-inspector-rulebase`, `sdd-inspector-testability`, `sdd-inspector-architecture`, `sdd-inspector-consistency`, `sdd-inspector-best-practices`, `sdd-inspector-holistic` → 6個 ✓
- Impl Inspectors (基本): `sdd-inspector-impl-rulebase`, `sdd-inspector-interface`, `sdd-inspector-test`, `sdd-inspector-quality`, `sdd-inspector-impl-consistency`, `sdd-inspector-impl-holistic` → 6個 ✓
- Web Inspectors: `sdd-inspector-e2e`, `sdd-inspector-visual` → 2個 ✓
- Dead-code Inspectors: `sdd-inspector-dead-settings`, `sdd-inspector-dead-code`, `sdd-inspector-dead-specs`, `sdd-inspector-dead-tests` → 4個 ✓

この点は数値的に一致しているが、`sdd-auditor-impl.md` の Mission 文で「up to 8 independent review agents」と記述されている（L12）。これは正確（6基本 + 2web = 8）だが、`sdd-auditor-design.md` の Mission 文では「6 independent review agents」（L11）と記述されており、双方で表現スタイルが異なる（一方は "6", 他方は "up to 8"）。Minor inconsistency。

**場所**: `framework/claude/agents/sdd-auditor-design.md:11`, `framework/claude/agents/sdd-auditor-impl.md:12`

---

#### [HIGH] Dead-code Review リトライ上限の記述場所による表現揺れ

**説明**: Dead-code Review NO-GO の最大リトライ数がファイル間で微妙に不整合がある。

- `CLAUDE.md` L170: 「Dead-Code Review NO-GO: max 3 retries（exhaustion → escalate）」と記述
- `refs/run.md` Step 7b L247: 「re-review (max 3 retries, separate from per-spec aggregate cap → escalate)」と記述

これ自体は一致している。しかし `refs/run.md` L247 には「If findings reference files not owned by any wave spec: escalate those findings to user (cannot auto-fix unowned files)」という追加の escalation パスが存在するが、`CLAUDE.md` には「exhaustion → escalate」としか記述されていない。CLAUDE.md への Dead-code exhaust 時の詳細ルール（unowned files の扱い）の欠落により、Leadが詳細を知るには `refs/run.md` を読む必要がある。Cross-reference は存在するため致命的ではないが、CLAUDE.md の記述が不完全。

**場所**: `framework/claude/CLAUDE.md:170`, `framework/claude/skills/sdd-roadmap/refs/run.md:247`

---

#### [HIGH] Wave Context 生成パスの不整合

**説明**: `refs/run.md` Step 2.5 L41 で、Conventions Brief の書き込み先が以下の2パスで説明されている：
- マルチspecロードマップ: `.sdd/project/specs/.wave-context/{wave-N}/conventions-brief.md`
- 1-specロードマップ: `.sdd/project/specs/{feature}/conventions-brief.md`

しかし `refs/revise.md` Part B Step 7 L215 では「Store in `specs/.cross-cutting/{id}/`」と書かれており、`{{SDD_DIR}}/` プレフィックスが省略されている（クロスカッティングのコンテキスト生成場所）。Cross-cutting の Wave Context は `specs/.cross-cutting/{id}/conventions-brief.md` に保存されることが `refs/revise.md` L215 から読み取れるが、 `refs/run.md` は Cross-cutting シナリオを説明していないため、この2つのパス体系が完全には接続されていない。

さらに `CLAUDE.md` L96 の Wave Context の説明では「`refs/run.md` Step 2.5」と「`refs/impl.md` Pilot Stagger Protocol」を参照するよう指示しているが、Cross-cutting Revise シナリオにおける Conventions Brief の最終パスは不明確。

**場所**: `framework/claude/skills/sdd-roadmap/refs/run.md:41`, `framework/claude/skills/sdd-roadmap/refs/revise.md:215`

---

#### [HIGH] `verdicts.md` 参照パスの一部不整合

**説明**: `refs/review.md` L131 に Self-review の verdict 先として「`{{SDD_DIR}}/project/reviews/self/verdicts.md`」が記載されている。しかし `skills/sdd-review-self/SKILL.md` では `$SCOPE_DIR` を `{{SDD_DIR}}/project/reviews/self/` と定義しており（L41）、`verdicts.md` は `$SCOPE_DIR/verdicts.md` となる（L232）。これは一致する。

一方、`refs/run.md` Step 7b L244 では Wave QG の Dead Code Review の verdict を「`{{SDD_DIR}}/project/reviews/wave/verdicts.md` (header: `[W{wave}-DC-B{seq}]`)」に保存すると記述しているが、`refs/review.md` L129 では「`{{SDD_DIR}}/project/reviews/wave/verdicts.md`」となっており一致している。

ただし、`refs/review.md` の「Dead-code review」のスコープディレクトリが L71 で `{{SDD_DIR}}/project/reviews/dead-code/` と定義されているのに対し、Wave QG の Dead Code Review（`refs/run.md` Step 7b）の verdict は `reviews/wave/verdicts.md` に保存される。これは **意図的な設計**（wave QG 中の dead-code は wave スコープの一部）だが、スコープ dir としては `reviews/wave/` を使うのか `reviews/dead-code/` を使うのかが `refs/run.md` 内で明示されていない。スタンドアロンの `/sdd-roadmap review dead-code` は `reviews/dead-code/` を使い、Wave QG 内のは `reviews/wave/` を使う — この二重構造が読み手に混乱を与える可能性がある。

**場所**: `framework/claude/skills/sdd-roadmap/refs/review.md:71`, `framework/claude/skills/sdd-roadmap/refs/run.md:244`

---

#### [MEDIUM] `refs/review.md` の Impl Review Inspector リストと Auditor の期待リストの表現揺れ

**説明**: `refs/review.md` L33 の Impl Review セクションでは Inspectors を以下のように列挙:
```
sdd-inspector-{impl-rulebase,interface,test,quality,impl-consistency,impl-holistic}
```
一方、`sdd-auditor-impl.md` L44-52 では Inspector のファイル名を以下の順で期待:
1. `sdd-inspector-impl-rulebase.cpf`
2. `sdd-inspector-interface.cpf`
3. `sdd-inspector-test.cpf`
4. `sdd-inspector-quality.cpf`
5. `sdd-inspector-impl-consistency.cpf`
6. `sdd-inspector-impl-holistic.cpf`

順序は一致しているが、`refs/review.md` のブレース展開は `interface` と書かれているのに対し、 Auditor は `sdd-inspector-interface.cpf` と記述している（プレフィックス `sdd-inspector-` の省略パターンが混在）。読解上問題はないが表現統一性に欠ける。

**場所**: `framework/claude/skills/sdd-roadmap/refs/review.md:33`, `framework/claude/agents/sdd-auditor-impl.md:44-52`

---

#### [MEDIUM] `init.yaml` テンプレートへの参照があるが対象ファイルが存在しない

**説明**: `skills/sdd-roadmap/SKILL.md` の「Single-Spec Roadmap Ensure」L76 に以下の記述がある:
```
initialize spec.yaml from `{{SDD_DIR}}/settings/templates/specs/init.yaml`
```
しかし `framework/claude/sdd/settings/templates/specs/` ディレクトリには `design.md` と `research.md` しか存在せず、`init.yaml` は存在しない。

`install.sh` の v0.10.0 マイグレーション（L307）には「`rm -f .claude/sdd/settings/templates/specs/init.json`」という削除処理があり、旧バージョンの `init.json` が `init.yaml` に移行されたことが読み取れる。しかし現在の `framework/claude/sdd/settings/templates/specs/` には `init.yaml` が存在しない。Leadが `init.yaml` テンプレートを参照しようとすると「ファイルが見つからない」状況が発生する可能性がある。

**場所**: `framework/claude/skills/sdd-roadmap/SKILL.md:76`, `framework/claude/sdd/settings/templates/specs/` (ファイル不存在)

---

#### [MEDIUM] `sdd-review-self` の verdict バッチ番号決定タイミングの記述矛盾

**説明**: `skills/sdd-review-self/SKILL.md` Step 6.1 L232-233 では:
「Determine B{seq}: read `$SCOPE_DIR/verdicts.md`, increment max existing batch number (or start at 1)」

これは Step 4 でエージェントを並列起動する前（Step 3 でスコープを確定した後）に決まる。しかし Step 4 の各エージェントに対して「Output instruction: write to `{$SCOPE_DIR}/active/agent-{N}-{name}.md`」と指示されており、B{seq}は Step 6 まで確定しない。

Step 4 のエージェントはまだ B{seq} を知らないため `active/` ディレクトリに書き込む（B{seq} は archival 時に使用）— これ自体は問題ないが、Step 3 の「Build Compliance Cache」で「Read `$SCOPE_DIR/B{seq}/agent-4-compliance.md`」（L46）と書かれており、ここでは過去の B{seq} が参照される。新しい B{seq} は Step 6 で確定する設計であることが明確でない。矛盾というより説明の欠如。

**場所**: `framework/claude/skills/sdd-review-self/SKILL.md:46`, `framework/claude/skills/sdd-review-self/SKILL.md:232`

---

#### [MEDIUM] `refs/revise.md` Part A Step 4 フェーズ遷移の不整合

**説明**: `refs/revise.md` Part A Step 4 L63-65 では:
```
1. Reset orchestration.last_phase_action = null
2. Reset orchestration.retry_count = 0, orchestration.spec_update_count = 0
3. Set phase = design-generated
```
しかし `refs/design.md` Step 2 L18 では「`implementation-complete` の場合: warn して再設計を確認せよ」と書かれている。Revise フロー内で `implementation-complete` → `design-generated` に変更するのは Step 4 でしか行われていない（Step 5 で Architect を呼ぶ前）。

問題: Step 4 で `phase = design-generated` に変更した後、Step 5 で `refs/design.md` を実行する際、`refs/design.md` Step 2 の Phase Gate で「`implementation-complete` の場合: warn」は発火しない（既に `design-generated` に変わっているため）。ただし `refs/design.md` Step 2 が再チェックすることで「`design-generated` → proceed」となるため、実際には問題なく動作する。

一方、`refs/revise.md` Part A Step 1 L25-26 では「Verify `spec.yaml` exists and `phase` is `implementation-complete`」と検証しているが、Step 4 で phase を変更してから Step 5 で design を実行するという2段階の state transition が暗黙的で追いにくい。

**場所**: `framework/claude/skills/sdd-roadmap/refs/revise.md:63-65`, `framework/claude/skills/sdd-roadmap/refs/design.md:16-19`

---

#### [MEDIUM] `sdd-inspector-dead-code.md` の SCOPE フィールド定義と他 dead-code Inspectors の差異

**説明**: `sdd-inspector-dead-code.md` L55 の Output Format では:
```
SCOPE:{feature} | cross-check
```
同様に `sdd-inspector-dead-settings.md` L46、`sdd-inspector-dead-specs.md` L49、`sdd-inspector-dead-tests.md` L51 も同じ `SCOPE:{feature} | cross-check` を定義している。

しかし Dead-code review は通常 feature スコープを持たない全体レビューとして設計されており（`refs/review.md` L20「No phase gate (operates on entire codebase)」）、`{feature}` スコープを dead-code Inspector が使用するケースは実際には想定されていない。これらの CPF フォーマット定義に `{feature}` オプションが残っているのは混乱を招く可能性がある。`sdd-auditor-dead-code.md` の Input Handling（L36-43）でも feature 名の言及はない。

**場所**: `framework/claude/agents/sdd-inspector-dead-code.md:55`, `framework/claude/agents/sdd-inspector-dead-settings.md:46`, `framework/claude/agents/sdd-inspector-dead-specs.md:49`, `framework/claude/agents/sdd-inspector-dead-tests.md:51`

---

#### [MEDIUM] Consensus Mode における B{seq} の決定タイミングと複数パイプラインの関係

**説明**: `skills/sdd-roadmap/SKILL.md` の Consensus Mode（L115-127）と `refs/review.md` の Review Execution Flow（L69-91）の間で B{seq} の扱いに軽微な不整合がある。

`SKILL.md` L115 では「Determine B{seq} from `{scope-dir}/verdicts.md`」と記述。
`refs/review.md` L74 では「For consensus mode, B{seq} is determined once and shared across all N pipelines」と記述。

これは一致しているが、`SKILL.md` L116-117 では各パイプラインのディレクトリを `reviews/active-{p}/` とし、アーカイブ先を `reviews/B{seq}/pipeline-{p}/` としている。一方 `refs/review.md` L90 では「`active-{p}/` → `B{seq}/pipeline-{p}/`」とアーカイブを記述しており一致している。

N=1 の場合（デフォルト）: `SKILL.md` L126 では `reviews/active/` を使用（`-{p}` サフィックスなし）とし、アーカイブは `reviews/B{seq}/` となるとある。これは `refs/review.md` L126（N=1 は通常の `active/` を使用）と一致している。整合性は保たれている。

**場所**: `framework/claude/skills/sdd-roadmap/SKILL.md:115-127`, `framework/claude/skills/sdd-roadmap/refs/review.md:74`

---

#### [MEDIUM] `refs/run.md` Readiness Rules の Design Review 条件表現が曖昧

**説明**: `refs/run.md` L151 の Readiness Rules テーブルにおける「Design Review」の Conditions:
```
No GO/CONDITIONAL verdict in `verdicts.md` latest design batch (verdict absent or last is NO-GO).
```
この表現は「GO/CONDITIONAL が存在しない場合に Design Review が実行可能」と読める。これは「まだレビューしていない、またはNO-GOで再レビューが必要」を意味している。

しかし「verdict absent」と「last is NO-GO」が `or` でつながれているため:
- `verdict absent` → 初回設計レビューが未実施 → DR実施可能 ✓
- `last is NO-GO` → 直前のレビューがNO-GO → 再DR実施可能 ✓

Logic は正しいが、「`verdict absent` OR `last is NO-GO`」という条件式は「GO/CONDITIONAL が最新バッチに存在しない場合」と言い換えた方が明快。読み手が誤解しにくい。Minor ambiguity。

**場所**: `framework/claude/skills/sdd-roadmap/refs/run.md:151`

---

#### [LOW] `sdd-inspector-quality.md` と `sdd-inspector-dead-code.md` の役割重複

**説明**: `sdd-inspector-quality.md` Step 6 L113-120 で「Dead Code and Unused Imports」チェックを実施するよう記述されている。一方、`sdd-inspector-dead-code.md` は全体的に死コード検出を担う専用エージェントである。

ただし quality Inspector は impl review フェーズ（単一feature対象）、dead-code Inspector は Dead-Code Review フェーズ（全体対象）で使われるため、フェーズが異なり直接競合はしない。しかし質的なオーバーラップにより、Auditor が impl review で quality Inspector からの dead-code 指摘をどう扱うか（dead-code Inspector はない impl review フェーズでの扱い）が明示されていない。これは設計上許容されている重複と思われるが、明示的な note がない。

**場所**: `framework/claude/agents/sdd-inspector-quality.md:113-120`

---

#### [LOW] `sdd-auditor-design.md` の Steering Feedback CODIFY 定義が `refs/review.md` の定義と微妙に異なる

**説明**: `sdd-auditor-design.md` L208 の STEERING note:
```
STEERING: `CODIFY` = code/design already follows this pattern (auto-apply); `PROPOSE` = new constraint affecting future work (requires user approval)
```

`refs/review.md` L111 の STEERING 処理:
```
CODIFY | Update `steering/{target file}` directly + append to decisions.md
```

「code/design already follows this pattern」という説明は、既存パターンのコード化として説明されているが、`refs/review.md` では単に「直接適用する」と書かれており、「既存パターン」の条件は特に言及されていない。`sdd-auditor-impl.md` L266 も同様の説明。Nuanced difference but potentially confusing.

**場所**: `framework/claude/agents/sdd-auditor-design.md:208`, `framework/claude/agents/sdd-auditor-impl.md:266`, `framework/claude/skills/sdd-roadmap/refs/review.md:111`

---

#### [LOW] `install.sh` の summary 表示で `skills` と `agents` の説明が逆順

**説明**: `install.sh` L582-584 の summary 出力:
```sh
echo "  .claude/skills/      $(find .claude/skills ...) skills"
echo "  .claude/agents/      $(find .claude/agents ...) agent profiles"
```
これは機能的に正しいが、`framework/claude/CLAUDE.md` や他のドキュメントでは常に agents → skills の順（または Skills を先に記述）している。軽微な表示順の不整合。

**場所**: `install.sh:582-584`

---

#### [LOW] `refs/revise.md` Part B Step 2 の「only `implementation-complete` phase is eligible」ルールと Part A の pre-check 不整合

**説明**: `refs/revise.md` Part B Step 2 L123 では:
「Read all `spec.yaml` files (only `implementation-complete` phase is eligible for revision)」

Part A Step 1 L25 も同様に「Verify `spec.yaml` exists and `phase` is `implementation-complete`」としている。

しかし `refs/revise.md` Part A Step 4 では `phase = design-generated` にリセットしてから pipeline を実行する。Cross-cutting Mode (Part B) の Step 2 では FULL/AUDIT/SKIP の分類を `implementation-complete` の spec のみ対象にしているが、もし途中で Part A → Part B に移行する場合（Step 3の Cross-cutting escalation）、ターゲット spec の phase は Step 4 でリセット済みの可能性がある。この移行パスでの state の扱いが不明瞭。

**場所**: `framework/claude/skills/sdd-roadmap/refs/revise.md:123`, `framework/claude/skills/sdd-roadmap/refs/revise.md:47`

---

### クロスリファレンスマトリクス

| 参照元ファイル | 参照先 | 参照内容 | 整合性 |
|---|---|---|---|
| `CLAUDE.md` | `refs/run.md` | Step 2.5, Step 3-4 | ✓ |
| `CLAUDE.md` | `refs/impl.md` | Pilot Stagger Protocol | ✓ |
| `CLAUDE.md` | `refs/revise.md` Part B | Cross-cutting | ✓ |
| `CLAUDE.md` | `refs/review.md` | Steering Feedback Loop | ✓ |
| `CLAUDE.md` | `refs/crud.md` | Wave Scheduling | ✓ |
| `SKILL.md (roadmap)` | `refs/design.md` | Design サブコマンド | ✓ |
| `SKILL.md (roadmap)` | `refs/impl.md` | Impl サブコマンド | ✓ |
| `SKILL.md (roadmap)` | `refs/review.md` | Review サブコマンド | ✓ |
| `SKILL.md (roadmap)` | `refs/run.md` | Run モード | ✓ |
| `SKILL.md (roadmap)` | `refs/revise.md` | Revise モード | ✓ |
| `SKILL.md (roadmap)` | `refs/crud.md` | Create/Update/Delete | ✓ |
| `SKILL.md (roadmap)` | `{{SDD_DIR}}/settings/templates/specs/init.yaml` | spec.yaml 初期化 | **未解決 (ファイル不存在)** |
| `refs/run.md` | `refs/design.md` | Phase Handlers | ✓ |
| `refs/run.md` | `refs/impl.md` | Phase Handlers | ✓ |
| `refs/run.md` | `refs/review.md` | Review Decomposition | ✓ |
| `refs/revise.md` | `refs/design.md` | Revision context | ✓ |
| `refs/revise.md` | `refs/impl.md` | Impl execution | ✓ |
| `refs/revise.md` | `refs/review.md` | Review execution | ✓ |
| `refs/revise.md` | `refs/crud.md` | Spec creation logic | ✓ |
| `sdd-architect.md` | `{{SDD_DIR}}/settings/rules/design-discovery-full.md` | Full discovery | ✓ |
| `sdd-architect.md` | `{{SDD_DIR}}/settings/rules/design-discovery-light.md` | Light discovery | ✓ |
| `sdd-architect.md` | `{{SDD_DIR}}/settings/templates/specs/design.md` | Design template | ✓ |
| `sdd-architect.md` | `{{SDD_DIR}}/settings/templates/specs/research.md` | Research template | ✓ |
| `sdd-taskgenerator.md` | `{{SDD_DIR}}/settings/rules/tasks-generation.md` | Task rules | ✓ |
| `sdd-auditor-design.md` | `sdd-inspector-*.cpf` ファイル名 | CPF ファイル期待値 | ✓ (6 inspectors) |
| `sdd-auditor-impl.md` | `sdd-inspector-*.cpf` ファイル名 | CPF ファイル期待値 | ✓ (6+2 inspectors) |
| `sdd-auditor-dead-code.md` | `sdd-inspector-*.cpf` ファイル名 | CPF ファイル期待値 | ✓ (4 inspectors) |
| `settings.json` | `sdd-*` エージェント定義 | Task() 許可リスト | ✓ (全エージェント対応) |
| `CLAUDE.md` | `{{SDD_DIR}}/settings/rules/cpf-format.md` | CPF 仕様 | ✓ |
| `SKILL.md (review-self)` | `{{SDD_DIR}}/project/reviews/self/` | スコープディレクトリ | ✓ |
| `refs/review.md` | `{{SDD_DIR}}/project/reviews/self/verdicts.md` | Self-review verdict | ✓ (refs/review.md L131) |

---

### フェーズ名一貫性チェック

全ファイルで使用されているフェーズ名:
- `initialized` ✓ (全ファイルで一致)
- `design-generated` ✓ (全ファイルで一致)
- `implementation-complete` ✓ (全ファイルで一致)
- `blocked` ✓ (全ファイルで一致)

### Verdict 値一貫性チェック

Design Review: `GO`, `CONDITIONAL`, `NO-GO` ✓
Impl Review: `GO`, `CONDITIONAL`, `NO-GO`, `SPEC-UPDATE-NEEDED` ✓
Dead-code Review: `GO`, `CONDITIONAL`, `NO-GO` ✓ (SPEC-UPDATE-NEEDED は design 側で対応)
Inspector CPF: `GO`, `CONDITIONAL`, `NO-GO`, `ERROR` ✓

### SubAgent 名一貫性チェック

`settings.json` の Task() 許可リストと `framework/claude/agents/` のファイル名を照合:

| settings.json エントリ | 対応エージェントファイル | 整合性 |
|---|---|---|
| Task(sdd-architect) | sdd-architect.md | ✓ |
| Task(sdd-auditor-dead-code) | sdd-auditor-dead-code.md | ✓ |
| Task(sdd-auditor-design) | sdd-auditor-design.md | ✓ |
| Task(sdd-auditor-impl) | sdd-auditor-impl.md | ✓ |
| Task(sdd-builder) | sdd-builder.md | ✓ |
| Task(sdd-inspector-architecture) | sdd-inspector-architecture.md | ✓ |
| Task(sdd-inspector-best-practices) | sdd-inspector-best-practices.md | ✓ |
| Task(sdd-inspector-consistency) | sdd-inspector-consistency.md | ✓ |
| Task(sdd-inspector-dead-code) | sdd-inspector-dead-code.md | ✓ |
| Task(sdd-inspector-dead-settings) | sdd-inspector-dead-settings.md | ✓ |
| Task(sdd-inspector-dead-specs) | sdd-inspector-dead-specs.md | ✓ |
| Task(sdd-inspector-dead-tests) | sdd-inspector-dead-tests.md | ✓ |
| Task(sdd-inspector-e2e) | sdd-inspector-e2e.md | ✓ |
| Task(sdd-inspector-holistic) | sdd-inspector-holistic.md | ✓ |
| Task(sdd-inspector-impl-consistency) | sdd-inspector-impl-consistency.md | ✓ |
| Task(sdd-inspector-impl-holistic) | sdd-inspector-impl-holistic.md | ✓ |
| Task(sdd-inspector-impl-rulebase) | sdd-inspector-impl-rulebase.md | ✓ |
| Task(sdd-inspector-interface) | sdd-inspector-interface.md | ✓ |
| Task(sdd-inspector-quality) | sdd-inspector-quality.md | ✓ |
| Task(sdd-inspector-rulebase) | sdd-inspector-rulebase.md | ✓ |
| Task(sdd-inspector-test) | sdd-inspector-test.md | ✓ |
| Task(sdd-inspector-testability) | sdd-inspector-testability.md | ✓ |
| Task(sdd-inspector-visual) | sdd-inspector-visual.md | ✓ |
| Task(sdd-taskgenerator) | sdd-taskgenerator.md | ✓ |

**全 Task() エントリが対応エージェントファイルを持つ** ✓

---

### Confirmed OK

- フェーズ名（initialized / design-generated / implementation-complete / blocked）は全ファイルで統一されている
- Verdict 値（GO / CONDITIONAL / NO-GO / SPEC-UPDATE-NEEDED）は各レビュータイプで適切に定義されている
- CPF 重大度コード（C/H/M/L）は全エージェントで統一されている
- settings.json の全 Task() エントリは対応するエージェント定義ファイルを持つ
- `refs/run.md` → `refs/design.md` / `refs/impl.md` / `refs/review.md` の参照チェーンは完全
- `sdd-roadmap/SKILL.md` から 6 つの refs ファイルへの参照は全て存在する
- Architect の completion report フォーマット（`ARCHITECT_COMPLETE`）は `refs/design.md` で適切に処理される
- Builder の completion report フォーマット（`BUILDER_COMPLETE` / `BUILDER_BLOCKED`）は `refs/impl.md` で適切に処理される
- `sdd-review-self` の 4 エージェント並列実行パターンは `settings.json` で許可されている（`Task(sdd-auditor-design)` 等）
- Knowledge tags（`[PATTERN]` / `[INCIDENT]` / `[REFERENCE]`）の定義は CLAUDE.md と sdd-builder.md で一致
- `WRITTEN:{path}` の completion output 規約は全 Inspector/Auditor で統一されている
- Steering Feedback Loop（CODIFY/PROPOSE）の処理は `refs/review.md` と CLAUDE.md で一致
- Dead-code Review の max 3 retries ルールは CLAUDE.md と `refs/run.md` で一致
- 1-spec roadmap の最適化（Wave QG skip、cross-check skip、commit メッセージ形式）は SKILL.md と `refs/run.md` で一致
- Wave Bypass（Island specs）の定義は `refs/run.md` と CLAUDE.md で一致
- Auto-fix counter リセット条件は CLAUDE.md と `refs/run.md` / `refs/revise.md` で一致
- `sdd-auditor-design.md` と `sdd-auditor-impl.md` の「Verdict Output Guarantee」プロトコルは両者で同一
- install.sh のマイグレーション処理はバージョン順に整理されており循環参照はない
- `specs/.cross-cutting/{id}/` の用途（cross-cutting revision 用 brief/verdicts）は revise.md と refs/review.md で一致
- CPF フォーマットの SCOPE フィールド値（`{feature}`, `cross-check`, `wave-1..{N}`）は各 Inspector で統一されている

---

### Overall Assessment

**総合評価**: 概ね整合性が高く、フレームワークの一貫性は保たれている。

**主要リスク**:

1. **`init.yaml` テンプレート不存在** [MEDIUM]: `SKILL.md` が参照する `{{SDD_DIR}}/settings/templates/specs/init.yaml` が存在しない。Leadが新規spec作成時にこのファイルを読もうとするとエラーになる可能性がある。テンプレートファイルの作成、または参照先のコードインライン化が必要。

2. **Wave QG Dead-Code Review のスコープディレクトリ曖昧性** [HIGH]: スタンドアロンの `review dead-code` は `reviews/dead-code/` を使い、Wave QG の dead-code は `reviews/wave/` を使う二重構造が `refs/run.md` 内で明示されていない。`refs/run.md` Step 7b で `reviews/wave/verdicts.md` を明示的に指定しているため動作上の問題はないが、`refs/review.md` のスコープディレクトリ定義との関係が読み手に伝わりにくい。

3. **Cross-cutting Revise の Conventions Brief パス** [HIGH]: `refs/revise.md` Part B Step 7 の Conventions Brief 保存先が `specs/.cross-cutting/{id}/` とされているが、この情報は Builder/Architect dispatch時に正しくパスとして渡される必要があり、`{{SDD_DIR}}/` プレフィックスの明示が必要。

**推奨対処**: MEDIUM 以上の課題を次リリース前に修正することを推奨。特に `init.yaml` テンプレートの欠落は実際の操作で問題を引き起こす可能性がある。
