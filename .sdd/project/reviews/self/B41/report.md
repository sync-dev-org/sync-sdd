# SDD Framework Self-Review Report
**Date**: 2026-03-06T17:56:18+0900
**Agents**: 6 dispatched (3 fixed + 3 dynamic), 6 completed

---

## False Positives Eliminated (7件)

| Finding | Agent | Reason |
|---|---|---|
| C\|undefined-tool sdd-handover SKILL.md:3 | Agent-2 | AskUserQuestion は allowed-tools 除外が設計仕様 (MEMORY.md: 含めると UI 非表示・空回答バグ) |
| C\|undefined-tool sdd-start SKILL.md:3 | Agent-2 | 同上 |
| H\|undefined-tool sdd-roadmap SKILL.md:3 | Agent-2 | 同上 |
| H\|undefined-tool sdd-reboot SKILL.md:3 | Agent-2 | 同上 |
| H\|value-contradiction CLAUDE.md:330 | Agent-2 | CLAUDE.md の Co-Authored-By は `sync-sdd <noreply@sync-sdd>` (フレームワーク署名)。settings.json の includeCoAuthoredBy:false は Anthropic 署名の抑制で別件。矛盾なし |
| H\|value-contradiction settings.json:2 | Agent-2 | 同上 (上と対になる FP ペア) |
| M\|install install.sh:523 engines.yaml 上書き | Dynamic-3 | D180 (2026-03-06): engines.yaml をフレームワーク管理ファイルに変更 — 無条件上書きが設計決定 |

---

## A) 自明な修正 (15件) — OK で全件修正します

| ID | Sev | Location | Summary | Fix |
|---|---|---|---|---|
| A-1 | H | framework/claude/skills/sdd-review-self/SKILL.md:194 (+ 197,284,313,333) | Agent dispatch 例で `description` パラメータが未指定 (公式必須仕様) | 各 dispatch 呼び出しに `description="..."` を追加 |
| A-2 | H | framework/claude/skills/sdd-review/SKILL.md:140 | Prep tmux 完了時に `status: idle` のみ更新 — `agent/engine/channel` フィールド除去が未規定 | idle リセット手順に `agent/engine/channel` フィールド削除を追記 |
| A-3 | H | framework/claude/skills/sdd-review/SKILL.md:359 | Auditor tmux 完了時も同様に `agent/engine/channel` 除去が欠落 | 同上 |
| A-4 | H | framework/claude/skills/sdd-review-self/SKILL.md:94 | self-review Prep tmux 復帰で `agent/engine/channel` クリアが未規定 | idle リセット手順に `agent/engine/channel` フィールド削除を追記 |
| A-5 | H | framework/claude/skills/sdd-review-self/SKILL.md:321 | self-review Auditor 完了時も `agent/engine/channel` 除去が欠落 | 同上 |
| A-6 | M | framework/claude/skills/sdd-reboot/refs/reboot.md:172 | `refs/run.md` 参照が reboot/refs 配下では実体なし (デッドリファレンス) | 正しい相対パスへ修正 (例: `../../sdd-roadmap/refs/run.md`) |
| A-7 | M | framework/claude/skills/sdd-roadmap/refs/run.md:184 | `refs/design.md` が同一 refs/ 配下で `refs/refs/design.md` に解決される二重パス | `design.md` (ファイル名のみ) に修正 |
| A-8 | M | framework/claude/skills/sdd-roadmap/refs/revise.md:71 | `refs/design.md` / `refs/impl.md` が同上の二重 refs パス | `design.md` / `impl.md` に修正 |
| A-9 | M | framework/claude/skills/sdd-review-self/SKILL.md:347 | ヘッダー例が `fixed:{N}` 可変形式 — fixed Inspector は仕様上常に 3 件 | `fixed:{N}` → `fixed:3` に固定 |
| A-10 | L | framework/claude/skills/sdd-roadmap/SKILL.md:117 | Cross-cutting verdict persistence 参照先が `Part B Step 8` だが実際は `Part B Step 9` | `Step 8` → `Step 9` に修正 |
| A-11 | L | framework/claude/skills/sdd-roadmap/SKILL.md:37 | `-y` フラグ使用時に Auto-Detect Step 2 の選択提示をスキップする旨の明示規定がなく Router 分岐が不明確 | `-y` 時は提示省略して `run` 実行する旨を 1 行追記 |
| A-12 | L | framework/claude/sdd/settings/templates/review/impl-rulebase.md:136 | CPF 例の `"status says implementing"` が公式 phase 語彙 (`implementation-complete` 等) と不一致 | 例示を正式 phase 名に修正 |
| A-13 | L | framework/claude/CLAUDE.md:32 | `Agent(subagent_type="sdd-architect", prompt="...")` 例が `description` 必須仕様を満たしていない | 例に `description="..."` を追加 |
| A-14 | L | framework/claude/skills/sdd-review/SKILL.md (参照箇所) | ドキュメント内で `framework/claude/skills/sdd-review.md` (実体なし) を参照。正は `sdd-review/SKILL.md` | 正しいパスに修正 |
| A-15 | L | install.sh:84 | Usage の「FRAMEWORK FILES/USER FILES」に `engines.yaml` の管理対象・上書き方針が未記載 (D180 以降の設計と不整合) | engines.yaml がフレームワーク管理で --update/--force 時に上書きされる旨を追記 |

---

## B) ユーザー判断が必要 (8件)

### B-1: Wave QG で SPEC-UPDATE-NEEDED カウンタ上限チェックが欠落
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:251
**Description**: Wave QG の `SPEC-UPDATE-NEEDED` 分岐において、`spec_update_count` 上限 (2) および aggregate cap (6) の到達判定が明示されていない。CLAUDE.md のカウンタ制約では NO-GO と同様のキャップが必要だが、Wave QG ロジックにはその分岐がなく、理論上ループが上限を超え得る。
**Impact**: SPEC-UPDATE-NEEDED 連続時に設計意図を超えた再実行が発生し、コスト・時間ロスが生じる。
**Recommendation**: Wave QG SPEC-UPDATE-NEEDED 分岐に `spec_update_count >= 2 || (retry_count + spec_update_count) >= 6` 判定を追加してエスカレーションフローへ誘導 — CLAUDE.md の記述と整合するための最小変更。

---

### B-2: Verdict ヘッダースキーマの cross-skill 不整合
**Location**: framework/claude/skills/sdd-review-self/SKILL.md:347; framework/claude/skills/sdd-review/SKILL.md:421; framework/claude/skills/sdd-roadmap/SKILL.md:114; .sdd/project/reviews/self/verdicts.md:171
**Description**: 3 箇所で異なるヘッダー形式が混在している。
- sdd-review-self 仕様: `self | ... | v{version} | fixed:{N} dynamic:{N}`
- 実データ (verdicts.md 最新バッチ): `prep/insp/aud | agents:6/6 (fixed:3, dynamic:3)` 形式
- sdd-review / sdd-roadmap: 旧来の `review-type | ISO-8601 | v... | fixed/conditional/dynamic` 形式
加えて sdd-roadmap SKILL.md:114 には Cross-Cutting 専用の `[CC-B{seq}]` フォーマット定義がなく、sdd-review Step 8 の永続化仕様と乖離している。
**Impact**: パーサが複数世代のヘッダーを誤読または欠落し、バッチ集計・seq 抽出が破綻するリスク。self-review と通常 review の verdicts.md を共有またはクロス参照する際に互換性が失われる。
**Recommendation**: 統一ヘッダースキーマを 1 箇所 (cpf-format.md 等) で定義し、sdd-review / sdd-review-self / sdd-roadmap の 3 SKILL.md から参照する構成へ移行 — 現行データと後方互換の移行規則も同時に定義することを推奨。

---

### B-3: 全 spec が blocked の場合の Wave 完了挙動が未定義
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:240
**Description**: Wave 完了条件で `blocked` spec を除外することは規定されているが、対象 spec が 0 件（全 spec が blocked）のケースで Cross-check / Dead-code を明示スキップして Post-gate へ進む分岐が存在しない。空スコープ実行の挙動が未定義のままである。
**Impact**: 全 spec blocked の Wave で Cross-check/Dead-code が誤起動するか、あるいは無期限待機となりパイプラインが停止する可能性がある。
**Recommendation**: Wave 完了チェック冒頭に「完了 spec 0 件の場合は Cross-check/Dead-code スキップ → ユーザーへ blocked 状態を報告して Wave QG を中断」の分岐を追加。

---

### B-4: settings.json に `Agent(general-purpose)` 実行権限エントリがない
**Location**: framework/claude/skills/sdd-review/SKILL.md:243; framework/claude/settings.json:16
**Description**: sdd-review の実装は `Agent` ツールの general-purpose dispatch を前提とするが、`settings.json` の `permissions.allow` に対応するエントリが存在しない。実行環境によって Agent 呼び出しが拒否される場合がある。
**Impact**: デフォルト設定では sdd-review の Inspector dispatch が環境依存で失敗するリスク。特に CI/CD や制限付きパーミッション環境で顕在化する。
**Recommendation**: `permissions.allow` に Agent(general-purpose) 実行エントリを追加するか、sdd-review が Skill 経由ではなく Lead から直接 dispatch されることを明記してドキュメントとの整合を確保する。

---

### B-5: tmux dispatch 完了通知が wait-for 前に送出される (6 箇所)
**Location**: framework/claude/skills/sdd-review/SKILL.md:139,277,358; framework/claude/skills/sdd-review-self/SKILL.md:98,229,320
**Description**: `Prep dispatched...` / `Dispatched {N} inspectors...` / `Auditor dispatched...` の進捗ログが、対応する `tmux wait-for` 完了前に送出される。これにより「投入済み」と「完了済み」が UI 上で区別できない。完了シグナリング遅延時に実態より先行した表示になる。
**Impact**: 実際の完了状態と進捗表示がずれ、オペレーターが次ステップを早期実行するリスクがある。現状は運用上の問題にとどまるが、自動化スクリプトが通知を完了シグナルとして扱う場合に破綻する。
**Recommendation**: 各通知ログを `tmux wait-for` の **後** へ移動するか、ログを「投入完了」と「処理完了」の 2 段階に分けて明示する。全 6 箇所を一括修正する。

---

### B-6: verdicts.md の複数世代ヘッダーに互換パース規則がない
**Location**: framework/claude/skills/sdd-review-self/SKILL.md:343
**Description**: 永続化手順に「既存 verdicts.md の複数ヘッダー世代（`full`, `self`, engine-only, agents 付き等）をどう読むか」の互換パース規則が定義されていない。B{seq} 抽出以外のメタデータを追加した場合に旧エントリで破綻しやすい状態。
**Impact**: B-2 の統一スキーマ移行と連動。スキーマ変更時に過去データの再解釈コストと破綻リスクが高まる。B-2 と同時対処推奨。
**Recommendation**: verdicts.md の「互換パース規則」セクションを追加し、世代識別子（フィールド数・特定キーワード）でヘッダー形式を判別するルールを明文化する。B-2 の統一スキーマ策定と同時に実施することで重複作業を排除できる。

---

### B-7: install.sh の stale template 除去スコープが広すぎる
**Location**: install.sh:569
**Description**: `remove_stale ".sdd/settings/templates" ... "*"` がローカル追加テンプレート（`.md`/`.yaml` 含む）を update/force 時に削除する。上流ソースに存在しないファイルがすべて除去対象となり、ユーザーが独自に追加した拡張テンプレートが失われる。
**Impact**: カスタムテンプレートを運用するプロジェクトで `install.sh --update` または `--force` 実行時にデータ消失が発生する。現状は許容されているかもしれないが、engines.yaml がフレームワーク管理に移行した (D180) 今後、テンプレートの扱いポリシーを明示する必要がある。
**Recommendation**: (a) remove_stale の glob を既知フレームワークファイル一覧に限定する allowlist 方式、または (b) ユーザー追加テンプレートを別ディレクトリ (`.sdd/settings/templates-local/`) に分離してスコープ外にする — (b) の方が将来の拡張に対して堅牢。

---

### B-8: tmux 併用時の stale slot 事前正規化がない (SubAgent 分岐)
**Location**: framework/claude/skills/sdd-review-self/SKILL.md:190
**Description**: SubAgent 分岐はタイトル変更を行わない設計だが、前セッションの stale slot 状態を明示的に正規化する前処理がない。tmux 併用セッションで既存 busy 表示が継続し得る。
**Impact**: 低 — 表示上の問題のみで実害はないが、Grid 可視性と運用確認の正確性が低下する。B-5 の slot リセット修正 (A-2〜A-5) と合わせて対処すれば統合解消できる。
**Recommendation**: SubAgent 分岐開始時に担当 slot の状態を `idle` に初期化 (または `agent: sdd-review-self-subagent` でラベリング) する前処理を 1 行追加。A-2〜A-5 の修正と同セッションで対処推奨。

---

## Platform Compliance

| Item | Status | Source |
|---|---|---|
| agent-frontmatter-model | OK | https://code.claude.com/docs/en/sub-agents |
| agent-frontmatter-tools | OK | https://code.claude.com/docs/en/sub-agents |
| agent-frontmatter-description | OK | https://code.claude.com/docs/en/sub-agents |
| skills-frontmatter-description | OK | https://docs.anthropic.com/en/docs/claude-code/skills |
| skills-frontmatter-allowed-tools | OK | https://docs.anthropic.com/en/docs/claude-code/skills |
| skills-frontmatter-argument-hint | OK | https://docs.anthropic.com/en/docs/claude-code/skills |
| agent-tool-subagent-type-general-purpose | OK | https://docs.anthropic.com/en/docs/claude-code/sdk |
| agent-tool-params-model-run_in_background | OK | https://docs.anthropic.com/en/docs/claude-code/sdk |
| agent-tool-params-description (sdd-review-self dispatch) | NG | Agent dispatch 例で description 未指定 (→ A-1) |
| agent-tool-params-description (CLAUDE.md example) | NG | CLAUDE.md:32 dispatch 例で description 未指定 (→ A-13) |
| settings-permission-format | OK | https://docs.anthropic.com/en/docs/claude-code/settings#permission-settings |
| settings-skill-permission-syntax | OK | https://docs.anthropic.com/en/docs/claude-code/skills#restrict-claudes-skill-access |
| settings-agent-skill-entries-match-files | OK | https://docs.anthropic.com/en/docs/claude-code/settings#permission-settings |
