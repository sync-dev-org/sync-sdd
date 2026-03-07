# Regression Detection Report

**Date**: 2026-02-24
**Scope**: v1.0.0 ~ v1.0.3 + uncommitted changes (E2E/Visual inspector split)
**Reviewer**: Agent 2 (Regression Detection)

---

## Summary

v1.0.0-v1.0.3 では以下の変更が行われた:
1. **v1.0.0**: Parallel Execution Model (Design Fan-Out, Spec Stagger, etc.)
2. **v1.0.1**: Builder Self-Check quality gate, Steering-Aware TaskGenerator
3. **v1.0.2**: SubAgent dispatch default を `run_in_background` に変更
4. **v1.0.3**: Background-only dispatch を強制 (foreground exception 削除)
5. **Uncommitted**: E2E inspector の Phase B (visual design) 分離 → 新規 `sdd-inspector-visual.md` 作成、Web Inspector Server Protocol 追加

---

## Issues Found

### Confirmed OK

- [OK] CLAUDE.md Inspector 行: `+2 web (web projects)` に更新済み — `sdd-inspector-e2e` + `sdd-inspector-visual` を反映
- [OK] `sdd-auditor-impl.md`: 7→8 inspectors に更新、visual.cpf 追加、E2E/Visual 間のクロスチェックルール 3 件追加
- [OK] `review.md`: Web Inspector Server Protocol 追加 (Steps 3a, 4 web context, 5a)
- [OK] `review.md`: `sdd-inspector-e2e` と `sdd-inspector-visual` の両方を spawn する記述あり
- [OK] `sdd-inspector-e2e.md`: Phase B (visual design) 完全除去、カテゴリ `e2e-flow` のみに変更
- [OK] `sdd-inspector-e2e.md`: サーバー管理責任を Lead に移譲 (dev server の起動/停止コード削除)
- [OK] `sdd-inspector-visual.md`: Phase B の全機能を引き継ぎ (Design System, Aesthetic, Accessibility) + 新規追加 (Responsive, Cross-Page Consistency)
- [OK] `sdd-inspector-visual.md`: `steering/ui.md` 参照あり、欠落時の fallback 定義あり
- [OK] `ui.md` テンプレート: footer 参照を `sdd-inspector-visual` に更新
- [OK] `README.md`: 24 SubAgents に更新、`6+2 for implementation (web projects)` に更新
- [OK] Version 一貫性: `VERSION` = 1.0.3, `install.sh` = v1.0.3, `README.md` = v1.0.3
- [OK] v1.0.1 Builder Self-Check: `sdd-builder.md` に SELF-CHECK ステップ追加、`impl.md` に SelfCheck 処理追加、`sdd-auditor-impl.md` に SelfCheck warnings context 追加
- [OK] v1.0.2/v1.0.3 `run_in_background`: `design.md`, `impl.md`, `review.md`, `run.md` 全ての dispatch に `run_in_background=true` 追加
- [OK] CLAUDE.md SubAgent Lifecycle: foreground dispatch 禁止を明記
- [OK] v1.0.1 TaskGenerator steering integration: `sdd-taskgenerator.md` と `tasks-generation.md` に Steering Integration セクション追加
- [OK] Template 整合性: `handover/session.md`, `handover/buffer.md` — CLAUDE.md から参照、実ファイル存在確認
- [OK] CPF format: `cpf-format.md` 存在、CLAUDE.md から正しく参照
- [OK] Skills 数: 7 (README.md "7 skills" = 実ファイル 7 個: steering, roadmap, status, handover, knowledge, release, review-self)
- [OK] Commands 数: CLAUDE.md "Commands (6)" = 6 (sdd-review-self は CLAUDE.md Commands テーブルに含まれないが、README Commands テーブルには含まれる — これは既存の意図的な設計: review-self はフレームワーク開発専用)
- [OK] `refs/run.md`, `refs/crud.md`, `refs/review.md` — CLAUDE.md からの参照先は全て存在し内容が対応
- [OK] `sdd-inspector-e2e.md` から `Phase A`/`Phase B` のラベルは完全除去済み
- [OK] `e2e-visual-system`/`e2e-visual-quality` カテゴリは全ファイルから除去済み

### [LOW] CLAUDE.md Commands テーブルと README Commands テーブルの差異

**Location**: `framework/claude/CLAUDE.md:141` / `README.md:143-153`
**Description**: CLAUDE.md は "Commands (6)" で `sdd-review-self` を含まない。README.md は 7 コマンドをリスト。これは意図的な設計 (review-self はフレームワーク開発専用ツール) だが、README には 7 個リストされているのに CLAUDE.md では 6 個と明記されており、不慣れな開発者が混乱する可能性がある。
**Impact**: ドキュメント上の軽微な不整合。機能に影響なし。
**Evidence**: CLAUDE.md は Lead 向けの実行指示、README はユーザー向けドキュメント。役割が異なるため、含むコマンドが異なること自体は合理的。

---

## Split Traceability Table (E2E → E2E + Visual 分離)

旧 `sdd-inspector-e2e.md` の全機能が、分離後の2ファイル + review.md に完全に移行されたかの追跡表。

| 旧 E2E Inspector の機能 | 移行先 | 状態 |
|---|---|---|
| **Phase A: E2E Functional Testing** | `sdd-inspector-e2e.md` (E2E Functional Testing) | OK - 機能強化 (screenshot による視覚的確認、Navigation Completeness、Form validation 追加) |
| **Phase B: Design System Compliance** | `sdd-inspector-visual.md` (Design System Compliance) | OK - 完全移行 + 詳細化 (hex-level deviations, breakpoints 追加) |
| **Phase B: Aesthetic Quality Assessment** | `sdd-inspector-visual.md` (Aesthetic Quality) | OK - 完全移行 + 拡充 (Polish, Cross-page 追加) |
| **Phase B: Design-Spec Alignment** | `sdd-inspector-visual.md` (Design-Spec Alignment) | OK - 完全移行 + over-implementation チェック追加 |
| **steering/ui.md 読み込み** | `sdd-inspector-visual.md` (Load Context) | OK - Visual が ui.md を読む。E2E は不要 |
| **steering/tech.md dev server 起動** | `review.md` (Web Inspector Server Protocol) | OK - Lead 責任に移譲 |
| **dev server 停止** | `review.md` (Web Inspector Server Protocol Step 3) | OK - Lead 責任に移譲 |
| **カテゴリ: `e2e-flow`** | `sdd-inspector-e2e.md` | OK - 維持 |
| **カテゴリ: `e2e-visual-system`** | `sdd-inspector-visual.md` → `visual-system` | OK - リネーム |
| **カテゴリ: `e2e-visual-quality`** | `sdd-inspector-visual.md` → `visual-quality` | OK - リネーム |
| **カテゴリ: (新規) `visual-a11y`** | `sdd-inspector-visual.md` | OK - 新規追加 (アクセシビリティ) |
| **エラーハンドリング: playwright-cli not installed** | 両 Inspector | OK - 同一プロトコル |
| **エラーハンドリング: Dev server fails to start** | `review.md` + 両 Inspector (Server URL not accessible) | OK - 責任分離 |
| **エラーハンドリング: Page timeout** | 両 Inspector | OK |
| **エラーハンドリング: No steering/ui.md** | `sdd-inspector-visual.md` のみ | OK - E2E は ui.md 不要 |
| **Auditor CPF ファイルリスト** | `sdd-auditor-impl.md` (7→8) | OK - visual.cpf 追加 |
| **Auditor クロスチェックルール** | `sdd-auditor-impl.md` (3 rules 追加) | OK - E2E/Visual 間の整合性チェック |
| **CLAUDE.md Inspector 数** | `+2 web (web projects)` | OK - 更新済み |
| **README Inspector 数** | `6+2 for implementation (web projects)` | OK - 更新済み |
| **Viewport/Responsive testing** | `sdd-inspector-visual.md` (Desktop 1280x800, Mobile 390x844) | OK - 新規追加 (旧 E2E にはなかった明示的 viewport 指定) |

### 分離の検証結論

旧 `sdd-inspector-e2e.md` に存在した全機能が、分離後のファイルに完全に移行されていることを確認。機能損失なし。むしろ以下の点で強化されている:
- E2E: screenshot による視覚的確認追加、Navigation Completeness チェック追加、Form validation 追加
- Visual: Accessibility (`visual-a11y`) カテゴリ新設、明示的 viewport 設定、Cross-Page Consistency チェック追加
- Auditor: E2E/Visual 間のクロスチェックルール 3 件追加
- Server Protocol: Lead によるサーバー管理の一元化

---

## v1.0.0-v1.0.3 Split Traceability (コミット済み変更)

| 変更内容 | 移行元 | 移行先 | 状態 |
|---|---|---|---|
| Builder TDD cycle 拡張 (SELF-CHECK) | なし (新規) | `sdd-builder.md` Step 5 | OK |
| Builder SelfCheck completion report | なし (新規) | `sdd-builder.md` Completion Report | OK |
| SelfCheck processing in impl | なし (新規) | `refs/impl.md` Builder incremental processing | OK |
| SelfCheck warnings to Auditor | なし (新規) | `refs/review.md` Step 6, `sdd-auditor-impl.md` Input Handling | OK |
| TaskGenerator steering integration | なし (新規) | `sdd-taskgenerator.md` Step 2, `tasks-generation.md` Steering Integration | OK |
| `run_in_background` dispatch | 各 ref の bare dispatch | 各 ref の `run_in_background=true` | OK - 6 箇所全て更新 |
| CLAUDE.md SubAgent Lifecycle | "Lead dispatches SubAgents via Task tool" | "run_in_background: true always" | OK |
| SubAgent Lifecycle foreground exception | v1.0.2 "Prefer run_in_background" | v1.0.3 "No exceptions" | OK |

---

## Protocol Completeness Check

| Protocol | 定義場所 | 処理ルール場所 | 状態 |
|---|---|---|---|
| Phase Gate | CLAUDE.md §Phase Gate | `refs/design.md` Step 2, `refs/impl.md` Step 1, `refs/review.md` Step 2 | OK |
| SubAgent Lifecycle | CLAUDE.md §SubAgent Lifecycle | `refs/design.md`, `refs/impl.md`, `refs/review.md`, `refs/run.md` | OK |
| File-based Review | CLAUDE.md §Chain of Command | `refs/review.md` Review Execution Flow | OK |
| Auto-Fix Counter | CLAUDE.md §Auto-Fix Counter Limits | `refs/run.md` Step 4 Phase Handlers | OK |
| Blocking Protocol | CLAUDE.md reference | `refs/run.md` Step 6 | OK |
| Wave Quality Gate | CLAUDE.md reference | `refs/run.md` Step 7 | OK |
| Steering Feedback Loop | CLAUDE.md §Steering Feedback Loop | `refs/review.md` Steering Feedback Loop Processing | OK |
| Session Resume | CLAUDE.md §Session Resume | Steps 1-7 in CLAUDE.md (self-contained) | OK |
| Knowledge Auto-Accumulation | CLAUDE.md §Knowledge Auto-Accumulation | `refs/impl.md` Step 3 + `refs/run.md` Post-gate | OK |
| Pipeline Stop Protocol | CLAUDE.md §Pipeline Stop Protocol | Self-contained in CLAUDE.md | OK |
| Builder Self-Check | CLAUDE.md §Builder row + `sdd-builder.md` | `refs/impl.md` SelfCheck processing | OK |
| Web Inspector Server Protocol | `refs/review.md` §Web Inspector Server Protocol | `refs/review.md` Steps 3a/4/5a | OK |
| Consensus Mode | `SKILL.md` §Consensus Mode | Self-contained in SKILL.md | OK |
| Verdict Persistence | `SKILL.md` §Verdict Persistence Format | Self-contained in SKILL.md | OK |
| CPF Format | CLAUDE.md reference | `settings/rules/cpf-format.md` | OK |

---

## Dangling Reference Check

| 参照元 | 参照先 | 状態 |
|---|---|---|
| CLAUDE.md "see sdd-roadmap `refs/run.md`" | `refs/run.md` | OK - 存在、内容一致 |
| CLAUDE.md "see sdd-roadmap `refs/crud.md`" | `refs/crud.md` | OK - 存在、内容一致 |
| CLAUDE.md "see sdd-roadmap `refs/review.md`" | `refs/review.md` | OK - 存在、内容一致 |
| CLAUDE.md "Full specification: cpf-format.md" | `settings/rules/cpf-format.md` | OK - 存在 |
| CLAUDE.md "Template: session.md" | `settings/templates/handover/session.md` | OK - 存在 |
| CLAUDE.md "Template: buffer.md" | `settings/templates/handover/buffer.md` | OK - 存在 |
| `sdd-inspector-e2e.md` "the Visual inspector handles those" | `sdd-inspector-visual.md` | OK - 存在 |
| `sdd-inspector-visual.md` "the E2E inspector handles those" | `sdd-inspector-e2e.md` | OK - 存在 |
| `review.md` "see Web Inspector Server Protocol below" | `review.md` §Web Inspector Server Protocol | OK - 同一ファイル内 |
| `ui.md` "referenced by sdd-inspector-visual" | `sdd-inspector-visual.md` | OK - 存在、ui.md を参照 |
| `sdd-auditor-impl.md` → `sdd-inspector-visual.cpf` | `sdd-inspector-visual.md` が出力 | OK |
| `refs/run.md` "see Design Lookahead below" | `refs/run.md` §Design Lookahead | OK - 同一ファイル内 |
| `refs/run.md` "see Phase Handlers below" | `refs/run.md` §Phase Handlers | OK - 同一ファイル内 |

---

## Template Integrity Check

| テンプレート | CLAUDE.md 記述 | 実ファイル | 一致 |
|---|---|---|---|
| `handover/session.md` | session.md Format セクションで参照 | 存在、セクション構造が CLAUDE.md 記述と一致 | OK |
| `handover/buffer.md` | buffer.md Format セクションで参照 | 存在、Knowledge Buffer + Skill Candidates 構造 | OK |
| `specs/design.md` | Architect が使用 (暗黙) | 存在 | OK |
| `specs/research.md` | Architect が使用 (暗黙) | 存在 | OK |
| `steering-custom/ui.md` | `sdd-inspector-visual.md` が参照 | 存在、footer 更新済み | OK |

---

## Overall Assessment

**リグレッションなし。** v1.0.0-v1.0.3 のコミット済み変更、および未コミットの E2E/Visual 分離変更の両方において、機能損失、プロトコル欠落、dangling reference は検出されなかった。

未コミット変更 (E2E/Visual split) は特に綺麗に実行されている:
1. 旧 E2E の全機能が新ファイルに追跡可能
2. Auditor のクロスチェックルールが E2E/Visual 間の整合性を担保
3. Web Inspector Server Protocol による責任分離が明確
4. カテゴリ名の整理 (`e2e-visual-*` → `visual-*`) が一貫

唯一の指摘は LOW severity の CLAUDE.md Commands (6) vs README Commands (7) の差異だが、これは意図的な設計として許容範囲内。
