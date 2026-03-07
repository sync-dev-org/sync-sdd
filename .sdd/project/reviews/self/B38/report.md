# SDD Framework Self-Review Report
**Date**: 2026-03-05T04:50:55+0900
**Agents**: 4 dispatched, 4 completed

---

## False Positives Eliminated (3件)

| Finding | Agent | Reason |
|---|---|---|
| H\|auto-fix-loop\|run.md:204 — SPEC-UPDATE-NEEDED カスケードが Design Review を通らない | Agent 1 | D116: 「フル Design Review をループに追加 (defer)」として既知・延期済み。pre-existing, deferred |
| UNCERTAIN\|agent-tool-params\|CLAUDE.md:32 — subagent_type 等パラメータ名の準拠性 | Agent 4 | Agent tool の公式スキーマ定義 (subagent_type / model / run_in_background) で正式定義済み。FP |
| UNCERTAIN\|agent-frontmatter-extra-key\|sdd-analyst.md:7 — background キー受理可否 | Agent 4 | D96: 「background: true は FP — 公式サポートフィールドと確認」として既に解決済み |

---

## A) 自明な修正 (5件) — OK で全件修正します

| ID | Sev | Location | Summary | Fix |
|---|---|---|---|---|
| A-1 | LOW | framework/claude/skills/sdd-roadmap/SKILL.md:44 | Auto-Detect 提示オプションが「Reset」だが正式サブコマンドは `delete` | 表示語を「Reset」→「Delete」に修正 |
| A-2 | MED | framework/claude/sdd/settings/rules/tmux-integration.md:198 | Fallback 手順が `2>/dev/null` を推奨し、共通規約（CLAUDE.md）のリダイレクト回避方針と衝突 | `2>/dev/null` を除去、エラー許容または専用ツール代替への書き換え |
| A-3 | LOW | framework/claude/skills/sdd-review-self/SKILL.md:157 | `jq` 必須化を追記したが Step 0 の可用性チェックに `jq` 未検証 | Step 0 の依存ツールチェックに `jq --version` 確認を追加 |
| A-4 | LOW | framework/claude/skills/sdd-roadmap/refs/run.md:148 | Review Decomposition の説明が GO/CONDITIONAL/NO-GO のみ列挙し、Impl Auditor の SPEC-UPDATE-NEEDED 遷移が欠落 | 同セクションに SPEC-UPDATE-NEEDED → Architect cascade の遷移を追記 |
| A-5 | LOW | framework/claude/skills/sdd-roadmap/refs/review.md:88 | `Agent(subagent_type=...)` の省略記法が残り、静的な 1 対 1 照合が困難 | 省略記法に正式記法への参照注記を追加（または正式記法に統一） |

---

## B) ユーザー判断が必要 (10件)

### B-1: Run の Readiness Rules と review.md の Design Review フェーズ前提が不整合
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:160
**Description**: Run の Readiness Rules は Design Review 遷移を `phase=design-generated` に限定しているが、review.md は `implementation-complete` でも Design Review を許可（review.md:22）。結果として「Run では Design/Impl Review 必須」（run.md:94）という宣言と、既実装完了 spec 再投入時の実動線が一致しない。
**Impact**: Run パイプラインで既完了 spec を再投入した場合に Design Review をスキップするケースが発生しうる（中程度）
**Recommendation**: run.md の Readiness Rules に「既 `implementation-complete` spec の再投入では Design Review フェーズをスキップ可」という例外条件を明記するか、review.md 側の許可を Run 文脈で制限する — どちらの動作を正式とするか方針確定が必要

---

### B-2: Cross-Cutting 昇格ルーティング欠陥（依存グラフ非経由横断変更）
**Location**: framework/claude/skills/sdd-roadmap/SKILL.md:32
**Description**: Revise Detect Mode が「先頭語がspec名なら常に Single-Spec」に固定され、Cross-Cutting への昇格条件が依存グラフ起点（revise.md:42）に寄っている。依存関係に現れない横断変更（命名規則変更、共通設定変更など）は、spec 名で指定されるとCross-Cutting に到達しにくい。
**Impact**: 横断変更が意図せず Single-Spec として処理され、関連 spec が置き去りになるリスク（中程度）
**Recommendation**: Revise Detect Mode に「spec 名指定でも依存グラフ外の横断変更パターンを Cross-Cutting に昇格させる条件」を追加するか、ユーザーに明示的な `--cross-cutting` フラグを提供する

---

### B-3: sdd-reboot フローが AskUserQuestion を必須化しているが allowed-tools から除外
**Location**: framework/claude/skills/sdd-reboot/SKILL.md:3
**Description**: allowed-tools から AskUserQuestion を削除した一方で、reboot フロー本体（refs/reboot.md:66, 69, 276, 286）は AskUserQuestion 前提の分岐を必須化しており、非 `-y` 実行で対話分岐が承認プロンプト待ちになる。AskUserQuestion を allowed-tools に含めるとバグがある（MEMORY.md / D150 既知）という制約との板挟み。
**Impact**: 非自動実行時にスキル実行フローで確認ダイアログが自動承認されず、ユーザー操作が必要になる（高：フロー詰まりリスク）
**Recommendation**: (A) reboot.md の AskUserQuestion 前提分岐を除去し、`-y` 以外でも自動続行できる設計に変更 / (B) 既知バグ解消後に allowed-tools へ復帰 — 現状は A が安全

---

### B-4: sdd-steering engines モードが AskUserQuestion を必須化しているが allowed-tools から除外
**Location**: framework/claude/skills/sdd-steering/SKILL.md:3 (sdd-steering/SKILL.md:103-104)
**Description**: B-3 と同じ構造的問題。sdd-steering の engines モードが AskUserQuestion を明示必須にしているが allowed-tools から除外されており、設定更新フローで承認プロンプトが介在する。
**Impact**: engines モード実行時の設定更新フローが詰まるリスク（高）
**Recommendation**: B-3 と同じ方針で統一対応。engines モードの手順を AskUserQuestion 非依存に書き直す

---

### B-5: sdd-resume Orphan 判定が他の稼働中 pane を誤 kill するリスク
**Location**: framework/claude/skills/sdd-resume/SKILL.md:51
**Description**: Orphan 判定を「現在 SID と不一致」で定義しており、他の稼働中セッションの pane まで孤児候補に含める。tmux-integration の正規判定（`sdd-{SID}-lead` の実在確認で判定、rules/tmux-integration.md:206-207）と矛盾し、マルチセッション環境で誤 kill を誘発するリスクがある。
**Impact**: マルチ tmux セッション環境で他セッションの Agent pane が誤終了する可能性（高：データ損失リスク）
**Recommendation**: Orphan 判定条件を tmux-integration.md の正規手順（`sdd-{SID}-lead` 実在確認）に揃え、現在 SID 比較のみの判定を廃止する

---

### B-6: sdd-review-self tmux dispatch テンプレートでの jq 引用符破綻リスク
**Location**: framework/claude/skills/sdd-review-self/SKILL.md:154
**Description**: claude エンジンコマンドに `jq -rj '...'` の単引用符を導入したが、tmux dispatch テンプレートは全体を単引用符で包む前提（同ファイル:91, 197, 280）。そのまま埋め込むとクォート破綻し、`send-keys` 実行が失敗しうる。
**Impact**: tmux モードで sdd-review-self の dispatch が静かに失敗する可能性（高：レビュー実行不能）
**Recommendation**: jq のシングルクォートをダブルクォートまたはエスケープ形式に変換するか、dispatch テンプレートの引用符戦略を再設計する

---

### B-7: sdd-auditor-impl の VERDICT 未定義ケース（High 1-3 件でその他条件クリア）
**Location**: framework/claude/agents/sdd-auditor-impl.md:226
**Description**: 最終判定ロジックが `>3 High` のみ CONDITIONAL のため、High が 1-3 件でかつ CRITICAL なし・テスト成功・spec 欠陥なしのケースがどの分岐にも入らず VERDICT 未定義になる。
**Impact**: Impl Review で High 発見数が少ない場合に Auditor が判定不能に陥る可能性（高：レビューパイプライン停止）
**Recommendation**: `1-3 High → CONDITIONAL` の分岐を明示的に追加し、全ケースの VERDICT カバレッジを確保する

---

### B-8: sdd-auditor-design の判定式に CONDITIONAL 経路が存在しない
**Location**: framework/claude/agents/sdd-auditor-design.md:168
**Description**: design 監査の判定式は「Critical/High → NO-GO / それ以外 → GO」の 2 値だが（D104 対応後）、同ファイルの出力仕様は `GO|CONDITIONAL|NO-GO` の 3 値で、review フロー側も CONDITIONAL を前提としている。CONDITIONAL を返す経路が存在しない。
**Impact**: Design Review の CONDITIONAL 判定が実質的に到達不能（中程度：仕様と実動線の乖離）
**Recommendation**: (A) CONDITIONAL の判定条件（例: Medium が多数、High が 1 件）を設計に追加 / (B) 出力仕様を GO/NO-GO に絞り review.md の CONDITIONAL 前提を変更 — 設計思想の確認が必要

---

### B-9: cross-check/wave モード時の review.md Step 2 位相ゲートが未定義
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md:22
**Description**: Step 2 の位相ゲートが feature 単位の `design.md/tasks.yaml/spec.yaml` を前提に記述される一方、同ファイルは `--cross-check/--wave`（feature なし）を正式サポートし、run.md はこの Step 1-4 実行を指示しているため、cross-check/wave 時の適用規則が未定義。
**Impact**: cross-check/wave モードのレビューで位相ゲートが何を確認すべきか不明（中程度：運用の曖昧さ）
**Recommendation**: review.md に cross-check/wave 時の位相ゲート代替手順（例: Wave の全 spec が同 phase 以上であることを確認）を明記する

---

### B-10: VERDICT:ERROR の共通契約が Inspector 定義と CPF 仕様で分岐
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md:130
**Description**: `VERDICT:ERROR` を Inspector CPF の有効状態として扱うが、Inspector 各定義の VERDICT 列挙と CPF 仕様側に ERROR の共通契約がなく、値体系が分岐している。
**Impact**: Inspector が ERROR を返したとき Auditor がそれを正しく解釈できない可能性（中程度）
**Recommendation**: CPF 仕様（cpf-format.md または review.md）に `VERDICT:ERROR` の正式定義（意味、期待される Auditor の扱い）を追加し、すべての Inspector 定義にも列挙する

---

## Platform Compliance

| Item | Status | Source |
|---|---|---|
| agent-frontmatter-model | OK | 公式 Sub-Agents ドキュメント |
| agent-frontmatter-tools | OK | 公式 Settings ドキュメント |
| agent-frontmatter-description | OK | 公式 Sub-Agents ドキュメント |
| skills-frontmatter-description-and-allowed-tools | OK | 公式 Skills ドキュメント |
| skills-frontmatter-argument-hint-format | OK | 公式 Skills ドキュメント |
| dispatch-subagent-type-to-existing-agents | OK | 公式 Sub-Agents ドキュメント |
| settings-permission-format-skill-agent | OK | 公式 Settings ドキュメント |
| settings-skill-agent-entries-vs-files | OK | 公式 Settings ドキュメント |
| agent-tool-availability-vs-declared-tools | OK | 公式 Settings ドキュメント |
| agent-tool-params (subagent_type 等) | OK (FP) | Agent tool 公式スキーマ定義で確認済み |
| agent-frontmatter-extra-key (background) | OK (FP) | D96: 公式サポートフィールドと確認済み |
