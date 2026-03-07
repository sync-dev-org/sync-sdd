# リグレッション検出レビュー

**日付**: 2026-02-24
**対象コミット**: d340f18 (HEAD) + 未コミット変更
**レビュー範囲**: v1.0.1 (b50208c) ~ 現在の未コミット変更

---

## 1. 変更サマリー

### コミット済み変更 (v1.0.1 ~ v1.0.4)

| コミット | 内容 |
|---------|------|
| b50208c (v1.0.1) | Builder Self-Check + Steering-Aware TaskGenerator |
| 00dae92 (v1.0.2) | SubAgent dispatch を `run_in_background` デフォルト化 |
| f91949a (v1.0.3) | background-only dispatch 強制（foreground例外の削除） |
| ea1a23e (v1.0.4) | E2E Inspector を E2E + Visual に分割 |

### 未コミット変更

| ファイル | 変更内容 |
|---------|---------|
| `framework/claude/CLAUDE.md` | Cross-Cutting Parallelism 追加、REVISION_INITIATED 注記、cross-cutting コミットフォーマット |
| `framework/claude/skills/sdd-roadmap/SKILL.md` | argument-hint 更新、Detect Mode に2つの revise パターン追加 |
| `framework/claude/skills/sdd-roadmap/refs/design.md` | cross-cutting brief path サポート追加 |
| `framework/claude/skills/sdd-roadmap/refs/revise.md` | **全面書き換え** — Part A (Single-Spec) + Part B (Cross-Cutting) |

---

## 2. revise.md 書き換えのトレーサビリティ

### Part A: Single-Spec Mode（旧 Step 1-7 の保全確認）

| 旧 Step | 旧内容 | 新 Part A Step | 保全状態 | 備考 |
|---------|--------|---------------|----------|------|
| Step 1: Validate | roadmap.md存在、spec.yaml phase確認、wave確認、blocked BLOCK | Step 1: Validate | **完全保全** | 4項目すべて一致 |
| Step 2: Collect Revision Intent | 引数→直接使用 / AskUser / REVISION_INITIATED記録 / Steering更新 | Step 2: Collect Revision Intent | **完全保全** | 4項目すべて一致 |
| Step 3: Impact Preview | 依存グラフ走査 / 分類(1-hop/2+hops) / ユーザー提示 / 拒否→abort | Step 3: Impact Preview | **拡張あり・保全** | 旧 Step 3.3-3.4 → 新 Step 3.4-3.5 にリナンバリング。新 Step 3.3 に cross-cutting escalation が挿入。旧内容は全て存在 |
| Step 4: State Transition | last_phase_action reset / retry_count reset / phase = design-generated | Step 4: State Transition | **完全保全** | 3項目すべて一致 |
| Step 5: Execute Pipeline | Design(refs/design.md) / Design Review / Implementation(refs/impl.md) / Impl Review / Auto-fix loop | Step 5: Execute Pipeline | **完全保全** | 4パイプラインステップ + auto-fix loop すべて一致 |
| Step 6: Downstream Resolution | direct dependent確認 / Re-review,Re-implement,Skip選択 / decisions.md記録 / 順次実行 / transitive→session.md | Step 6: Downstream Resolution | **拡張あり・保全** | 旧選択肢 a,b,c → 新 a,b,c,d（d = cross-cutting revision 追加）。旧 Step 6.2-3 → 新 Step 6.2-4 にリナンバリング。旧内容は全て存在 |
| Step 7: Post-Revision | session.md auto-draft / roadmap run 再開 / /sdd-status 提案 | Step 7: Post-Revision | **完全保全** | 3項目すべて一致 |

### Part B: Cross-Cutting Mode（新規追加）

| Step | 内容 | 既存プロトコルとの整合性 |
|------|------|-------------------------|
| Step 1: Collect Intent | REVISION_INITIATED (cross-cutting) / Steering更新 | CLAUDE.md §decisions.md Recording の (cross-cutting) 注記と整合 |
| Step 2: Impact Analysis | FULL/AUDIT/SKIP 分類 / ユーザー確認 | 新規プロトコル。整合性問題なし |
| Step 3: Restructuring Check | crud.md Create/Update Mode 参照 | crud.md の Create/Update ロジックが存在することを確認済み |
| Step 4: Cross-Cutting Design Brief | specs/.cross-cutting/{id}/brief.md 作成 | design.md に brief path サポートが追加済み |
| Step 5: Triage | AUDIT→SKIP/FULL 昇降格 | USER_DECISION 記録あり。整合 |
| Step 6: Execution Tier Planning | 依存サブグラフ → topological sort → tier 割り当て | run.md の wave scheduling パターンと構造的に一致 |
| Step 7: Tier Execution | run.md Dispatch Loop パターン準拠 | Design Fan-Out, Builder 並列, Impl Review など既存パターン参照 |
| Step 8: Cross-Cutting Consistency Review | run.md Step 7a 準拠の cross-check review | run.md Wave QG a. と構造的に一致 |
| Step 9: Post-Completion | session.md / commit / /sdd-status | コミットフォーマット `cross-cutting: {summary}` が CLAUDE.md に追加済み |

---

## 3. ダングリング参照チェック

| 参照元 | 参照先 | 状態 |
|-------|--------|------|
| CLAUDE.md L82 | `sdd-roadmap refs/run.md` (operational details) | **OK** — refs/run.md は存在し、dispatch prompts, review protocol, incremental processing を含む |
| CLAUDE.md L88 | `sdd-roadmap refs/crud.md` (Foundation-First, wave scheduling) | **OK** — crud.md Step 4 に Foundation-First, topological sort, parallelism report あり |
| CLAUDE.md L95 | `sdd-roadmap refs/revise.md Part B` (Cross-Cutting Parallelism) | **OK** — revise.md Part B が存在し、tier-based parallel revision を定義 |
| CLAUDE.md L174 | `sdd-roadmap refs/run.md` (auto-fix loop, wave QG, blocking protocol) | **OK** — run.md Step 5,6,7 に該当内容あり |
| CLAUDE.md L204 | `sdd-roadmap refs/review.md` (Steering Feedback Loop) | **OK** — review.md §Steering Feedback Loop Processing に完全な処理規則あり |
| CLAUDE.md L238 | `{{SDD_DIR}}/settings/templates/handover/session.md` | **OK** — テンプレートファイル存在確認済み |
| CLAUDE.md L248 | `{{SDD_DIR}}/settings/templates/handover/buffer.md` | **OK** — テンプレートファイル存在確認済み |
| CLAUDE.md L330 | `{{SDD_DIR}}/settings/rules/cpf-format.md` | **OK** — ルールファイル存在確認済み |
| SKILL.md L76 | `{{SDD_DIR}}/settings/templates/specs/init.yaml` | **OK** — テンプレートファイル存在確認済み |
| SKILL.md L115 | `refs/review.md Step 1` | **OK** — review.md Step 1: Parse Arguments が存在 |
| revise.md Part B Step 4 L161 | `specs/.cross-cutting/{id}/brief.md` | **OK** — 新規パスだが revise.md 自身が作成ロジックを定義 |
| revise.md Part B Step 7 L202 | `run.md Dispatch Loop pattern` | **OK** — run.md Step 4 に Dispatch Loop が存在 |
| revise.md Part B Step 8 L242 | `run.md Step 7a` (cross-check impl review) | **OK** — run.md Step 7 a. に Impl Cross-Check Review が存在 |
| design.md L29 | cross-cutting brief path | **OK** — revise.md Part B Step 4 で作成、Part B Step 7.2 で Architect に渡す |

### 削除された参照

| 旧参照 | 削除箇所 | 状態 |
|--------|---------|------|
| `See sdd-roadmap refs/run.md Step 3-4 for dispatch loop details.` | CLAUDE.md §Parallel Execution Model 末尾 | **意図的削除** — Cross-Cutting Parallelism bullet に置換。refs/run.md Step 3-4 の参照は CLAUDE.md の各bullet項目の説明で代替されている。ただし下記「発見事項 F-01」参照 |

---

## 4. プロトコル完全性チェック

| プロトコル | 定義箇所 | 完全性 |
|-----------|---------|--------|
| Phase Gate | CLAUDE.md §Phase Gate + 各 refs/*.md Step 1/2 | **OK** |
| SubAgent Lifecycle (background-only dispatch) | CLAUDE.md §SubAgent Lifecycle | **OK** |
| Artifact Ownership | CLAUDE.md §Artifact Ownership | **OK** |
| Auto-Fix Counter Limits | CLAUDE.md §Auto-Fix Counter Limits + run.md Step 4/7 | **OK** |
| Consensus Mode | SKILL.md §Consensus Mode | **OK** |
| Verdict Persistence | SKILL.md §Verdict Persistence Format | **OK** |
| Steering Feedback Loop | CLAUDE.md §Steering Feedback Loop + review.md §Steering Feedback Loop Processing | **OK** |
| Blocking Protocol | run.md Step 6 | **OK** |
| Wave Quality Gate | run.md Step 7 | **OK** |
| Knowledge Auto-Accumulation | CLAUDE.md §Knowledge Auto-Accumulation | **OK** |
| Pipeline Stop Protocol | CLAUDE.md §Pipeline Stop Protocol | **OK** |
| Session Resume | CLAUDE.md §Session Resume | **OK** |
| Web Inspector Server Protocol | review.md §Web Inspector Server Protocol | **OK** |
| Builder Self-Check | impl.md Step 3 (Builder incremental processing) | **OK** |
| Cross-Cutting Revision Mode Detection | revise.md §Mode Detection | **OK** |
| Cross-Cutting Design Brief | revise.md Part B Step 4 | **OK** |
| Cross-Cutting Tier Execution | revise.md Part B Step 6-7 | **OK** |
| Cross-Cutting Consistency Review | revise.md Part B Step 8 | **OK** |

---

## 5. テンプレート整合性チェック

| CLAUDE.md 参照 | テンプレートパス | 存在 | 内容一致 |
|---------------|----------------|------|---------|
| session.md Format | `settings/templates/handover/session.md` | **OK** | テンプレートに Direction, Session Context, Accomplished, Resume Instructions セクションあり |
| buffer.md Format | `settings/templates/handover/buffer.md` | **OK** | Knowledge Buffer + Skill Candidates セクションあり |
| init.yaml (SKILL.md) | `settings/templates/specs/init.yaml` | **OK** | spec 初期化テンプレート |
| design.md (Architect) | `settings/templates/specs/design.md` | **OK** | 設計テンプレート |
| research.md (Architect) | `settings/templates/specs/research.md` | **OK** | リサーチテンプレート |

---

## 6. 発見事項

### F-01: `refs/run.md Step 3-4` 参照の削除 — 軽微

**種別**: ダングリング参照 → 修正済み（ただし代替が弱い）

**詳細**: CLAUDE.md の旧 `Parallel Execution Model` セクション末尾にあった `See sdd-roadmap refs/run.md Step 3-4 for dispatch loop details.` が削除され、Cross-Cutting Parallelism bullet に置換された。

旧状態:
```
- **Inspector parallelism**: ...

See sdd-roadmap `refs/run.md` Step 3-4 for dispatch loop details.
```

新状態:
```
- **Inspector parallelism**: ...
- **Cross-Cutting Parallelism**: ... See sdd-roadmap `refs/revise.md` Part B.
```

**影響**: refs/run.md Step 3-4（Wave Spec Scheduling + Parallel Dispatch Loop）への直接参照が Parallel Execution Model セクションから消失。ただし CLAUDE.md L82 `Operational details (dispatch prompts, review protocol, incremental processing): see sdd-roadmap refs/run.md.` が別途存在するため、run.md への参照自体は残っている。Dispatch Loop の詳細情報へのアクセスパスは間接的に維持されている。

**判定**: **軽微** — 情報へのアクセスパスは間接的に残存。ただし、旧参照はユーザーが Parallel Execution Model を読む際に dispatch loop の詳細に直接ナビゲートできる有用なリンクだった。

**推奨**: Parallel Execution Model セクション最後（Cross-Cutting Parallelism の後）に `Dispatch loop details: see sdd-roadmap refs/run.md Step 3-4.` を復元することを検討。

---

### F-02: review.md Verdict Destination に cross-cutting パスが未登録

**種別**: プロトコル不完全

**詳細**: revise.md Part B Step 8 で `specs/.cross-cutting/{id}/verdicts.md` に verdict を永続化するが、review.md §Verdict Destination by Review Type にはこのパスが記載されていない。

review.md の現在のリスト:
```
- Single-spec review
- Dead-code review
- Cross-check review
- Wave-scoped review
- Self-review
```

不足:
```
- Cross-cutting review: {{SDD_DIR}}/project/specs/.cross-cutting/{id}/verdicts.md
```

**影響**: cross-cutting consistency review は revise.md が独自に verdict path を定義しているため実行自体は可能。ただし review.md が「全 verdict ファイルの正規リスト」として機能しているため、ここに記載がないと Session Resume (CLAUDE.md §Session Resume Step 2a) で `specs/*/reviews/verdicts.md` を走査する際に `.cross-cutting` ディレクトリが見落とされる可能性がある。

**判定**: **中程度** — 運用上の影響は限定的だが、一貫性の観点で修正が望ましい。

**推奨**: review.md §Verdict Destination by Review Type に `- **Cross-cutting review**: {{SDD_DIR}}/project/specs/.cross-cutting/{id}/verdicts.md` を追加。

---

### F-03: Session Resume で cross-cutting review 状態が走査対象外

**種別**: プロトコル不完全（F-02 の派生）

**詳細**: CLAUDE.md §Session Resume Step 2a:
```
2a. Read `{{SDD_DIR}}/project/specs/*/reviews/verdicts.md` → active review state per spec
```

このグロブパターン `specs/*/reviews/verdicts.md` は `specs/.cross-cutting/{id}/verdicts.md` にマッチしない。cross-cutting revision が中断された場合、セッション再開時にその review 状態が復元されない。

**影響**: cross-cutting revision の途中でセッションが中断された場合、再開時に consistency review の verdict 状態が見えなくなる。ただし spec.yaml の phase は正しいため、パイプライン再開自体は可能。

**判定**: **軽微** — cross-cutting revision はまだ新機能で使用頻度が低い。spec.yaml ベースの復元は機能する。

**推奨**: Session Resume Step 2a のグロブパターンに `.cross-cutting` パスを追加するか、または「roadmap active 時は spec.yaml 走査で十分」という設計判断なら現状維持でもよい。

---

### F-04: CLAUDE.md §Artifact Ownership で revise 経路の記載が single-spec のみ

**種別**: ドキュメント不完全（軽微）

**詳細**: CLAUDE.md L64:
```
- Use `/sdd-roadmap revise {feature}` for completed specs
```

cross-cutting revision の場合のルート（`/sdd-roadmap revise [instructions]`）が Artifact Ownership セクションに記載されていない。

**影響**: Lead が cross-cutting な変更をリクエストされた際のルーティングガイダンスが不足。ただし SKILL.md の Detect Mode と revise.md の Mode Detection で十分カバーされている。

**判定**: **軽微** — 実運用上は SKILL.md 側で正しくルーティングされるため影響なし。

---

### F-05: 既存の問題なし確認項目

以下は問題が**発見されなかった**確認項目:

- revise.md Part A Step 1-7: 旧 Step 1-7 の全内容が保全されていることを確認
- revise.md Part A Step 3: cross-cutting escalation が追加されたが、旧 Step 3.3 (Present to user) と Step 3.4 (On rejection) は Step 3.4, Step 3.5 としてリナンバリングされただけで内容は同一
- revise.md Part A Step 6: option d (cross-cutting revision) が追加されたが、旧 option a,b,c と旧 Step 6.2-3 は Step 6.3-4 としてリナンバリングされただけで内容は同一
- CLAUDE.md の Cross-Cutting Parallelism bullet: revise.md Part B を正しく参照
- SKILL.md Detect Mode: 2つの revise パターンが正しく定義
- design.md: cross-cutting brief path の条件付きサポートが正しく追加
- コミットフォーマット: `cross-cutting: {summary}` が CLAUDE.md に追加済み
- REVISION_INITIATED: `(cross-cutting)` 注記が CLAUDE.md と revise.md で一致
- Agent 定義 (24個): 全て存在、v1.0.4 での E2E/Visual 分割も完了
- Skill 定義 (7個): 全て存在、refs/ ファイル (6個) も完備
- ルールファイル (7個): 全て存在
- テンプレートファイル (18個): 全て存在
- settings.json: 変更なし
- install.sh: 変更なし（v1.0.4 対応済み）

---

## 7. 総合判定

| カテゴリ | 結果 |
|---------|------|
| ダングリング参照 | **1件軽微** (F-01: dispatch loop 参照の間接化) |
| 分割ロス | **なし** — 旧 revise.md Step 1-7 の全内容が Part A に保全 |
| プロトコル完全性 | **2件** (F-02: review.md verdict destination 不足、F-03: Session Resume glob 不足) |
| テンプレート整合性 | **問題なし** |
| 新機能整合性 | **1件軽微** (F-04: Artifact Ownership の cross-cutting ルート未記載) |

### 優先度別まとめ

| 優先度 | 件数 | 項目 |
|--------|------|------|
| 高 | 0 | — |
| 中 | 1 | F-02 (review.md verdict destination) |
| 低 | 3 | F-01, F-03, F-04 |

**結論**: revise.md の全面書き換えにおいて旧コンテンツの分割ロスは発生していない。Part A は旧 Step 1-7 を完全に保全しており、Part B (Cross-Cutting Mode) は新規追加として既存プロトコルとの整合性が確認された。主要な発見事項は review.md の verdict destination リストに cross-cutting パスが未登録である点 (F-02) のみで、中程度の影響。
