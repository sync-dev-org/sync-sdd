# SDD Framework Self-Review Report
**Date**: 2026-03-06T16:09:47+0900
**Agents**: 6 dispatched (3 fixed + 3 dynamic), 6 completed

---

## False Positives Eliminated (10件)

| Finding | Agent | Reason |
|---|---|---|
| H\|agent-tool-parameters — `run_in_background` 指定が仕様外 (sdd-review/SKILL.md:117) | agent-3-compliance | D96: 「run_in_background: true は FP — 公式サポートフィールドと確認。保持」。`model` パラメータ部分は A4 として残置 |
| H\|agent-tool-parameters — `run_in_background` 指定が仕様外 (sdd-review-self/SKILL.md:92) | agent-3-compliance | 同上 (D96) |
| H\|protocol-consistency — `AskUserQuestion` が sdd-reboot/SKILL.md:3 allowed-tools にない | agent-2-consistency | MEMORY: 「AskUserQuestion を allowed-tools に含めてはいけない — スキルの allowed-tools に含めると自動承認パスに入り UI が表示されず空回答で返るバグがある」。allowed-tools に追加すること自体が誤り |
| H\|protocol-consistency — `AskUserQuestion` が sdd-start/SKILL.md:3 allowed-tools にない | agent-2-consistency | 同上 (MEMORY)。D150 でアクセス機構は別途修正済み |
| H\|protocol-consistency — `AskUserQuestion` が sdd-handover/SKILL.md:3 allowed-tools にない | agent-2-consistency | 同上 (MEMORY) |
| H\|protocol-consistency — `AskUserQuestion` が sdd-steering/SKILL.md:3 allowed-tools にない | agent-2-consistency | 同上 (MEMORY) |
| H\|protocol-consistency — `AskUserQuestion` が sdd-roadmap/SKILL.md:3 allowed-tools にない (refs/design.md:18参照) | agent-2-consistency | 同上 (MEMORY) |
| L\|tool-availability — `AskUserQuestion` の allowed-tools 記法が UNCERTAIN (sdd-handover/SKILL.md:26) | agent-3-compliance | MEMORY の確定情報で解決: allowed-tools には含めてはならないため「記法が存在しない」のが正常 |
| L\|tool-availability — `AskUserQuestion` の allowed-tools 記法が UNCERTAIN (sdd-start/SKILL.md:51) | agent-3-compliance | 同上 |
| L\|tool-availability — `AskUserQuestion` の allowed-tools 記法が UNCERTAIN (sdd-steering/SKILL.md:103) | agent-3-compliance | 同上 |

---

## A) 自明な修正 (14件) — OK で全件修正します

| ID | Sev | Location | Summary | Fix |
|---|---|---|---|---|
| A1 | CRITICAL | framework/claude/skills/sdd-reboot/refs/reboot.md:173-174 | `sdd-auditor-design` 参照（エージェント定義が存在しない）+ "6体(holistic含む)" カウントが現行 Inspector 構成と不整合 | 旧 Auditor 名 `sdd-auditor-design` を現行エージェント名（`sdd-auditor` 等）に修正。"6体(holistic含む)" の記述を現行構成（固定5体+動的）に合わせて書き直す |
| A2 | HIGH | framework/claude/skills/sdd-reboot/refs/reboot.md:30 | `branch_name` を `reboot/{name}` 形式で決定後に `git checkout -b reboot/{branch_name}` を実行するため `reboot/reboot/...` の二重 prefix が発生 | `git checkout -b reboot/{branch_name}` → `git checkout -b {branch_name}` に修正（branch_name に既に `reboot/` が含まれるため） |
| A3 | HIGH | framework/claude/skills/sdd-roadmap/SKILL.md:3 | `allowed-tools` に `Skill` がなく、同ファイル:98 で `Skill(skill="sdd-review", ...)` を必須呼び出しとしているため委譲手順がツール権限上到達不能 | `allowed-tools` に `Skill` を追加 |
| A4 | HIGH | framework/claude/skills/sdd-review/SKILL.md:117, framework/claude/skills/sdd-review-self/SKILL.md:92 | Agent 呼び出し例で `model` パラメータを指定しているが公式 SDK の Agent 互換入力は `description`/`prompt`/`subagent_type` のみ（`run_in_background` は FP/D96 にて除外） | 両ファイルの Agent 呼び出し例から `model` パラメータを削除 |
| A5 | MEDIUM | framework/claude/skills/sdd-review/SKILL.md:117, framework/claude/skills/sdd-review-self/SKILL.md:92 | 公式 SDK 仕様で Agent 互換入力に `description` が必要だが Agent 呼び出し例で未指定 | 両ファイルの Agent 呼び出し例に `description` フィールドを追加 |
| A6 | MEDIUM | framework/claude/skills/sdd-release/SKILL.md:134 | コマンド数検証ロジックで `sdd-review-self` を除外しているが CLAUDE.md:146-159 はコマンド数 10 に `sdd-review-self` を含む。リリース時にカウント照合が恒常的にズレる | sdd-review-self を検証対象コマンドに含め、基準値を 10 に整合させる |
| A7 | MEDIUM | framework/claude/skills/sdd-review-self/SKILL.md:26 | `--inspector-*` の説明が「Inspector ×4」となっているが固定 Inspector は agent-1/2/3 の 3 体（D175 で agent-2-changes 廃止 + リナンバリング後） | 「×4」→「×3」に修正 |
| A8 | MEDIUM | framework/claude/CLAUDE.md:39 | Review SubAgent 出力を「`WRITTEN:{path}` のみ」と規定しているが、`sdd-review-self` の外部エンジン Inspector テンプレートは `EXT_REVIEW_COMPLETE`/`AGENT`/`ISSUES` も stdout 出力する別プロトコルを採用しており、両規約が未区別で記述されている | CLAUDE.md の当該箇所に「ただし sdd-review-self の外部エンジン Inspector は別プロトコル（EXT_REVIEW_COMPLETE 等）を使用」旨の注記を追加 |
| A9 | LOW | framework/claude/skills/sdd-review/SKILL.md:389 | Verdict header 規約に wave 系は明記されているが cross-cutting 用の命名規約が未記載（router 側 Shared Protocol には記載あり） | cross-cutting verdict の header 命名規約を SKILL.md:389 付近に明示追記 |
| A10 | LOW | framework/claude/skills/sdd-roadmap/SKILL.md:2 | 同一コマンドで説明文が `implement`、実際のサブコマンドが `impl` と混在しており読解コストが上がる | 説明文を `impl` に統一 |
| A11 | LOW | framework/claude/CLAUDE.md:27 | Inspector 種別説明は `/sdd-review` 系の分類のみで、`/sdd-review-self` の固定 3 体（flow/consistency/compliance）への明示参照がない | CLAUDE.md の Inspector 説明に sdd-review-self 固定 3 体を明記 |
| A12 | LOW | framework/claude/skills/sdd-roadmap/refs/run.md:163 | `resume` という語が複数箇所で使われるが、セッション再開時の起点が `/sdd-start` であることが refs 側に未明示のため、`/sdd-roadmap run` 直接実行で初期化手順を迂回する解釈余地が残る | 該当箇所に「セッション再開は /sdd-start から開始すること」を明記 |
| A13 | LOW | framework/claude/sdd/settings/templates/review-self/prep.md:32 | self-review 対象収集が `framework/claude/sdd/settings/scripts/*.sh` 固定のため `.jq` 等の補助スクリプトが点検対象外 | 収集パターンを `*.sh` から補助スクリプト（`.jq` 等）も含む形に拡張 |
| A14 | LOW | framework/claude/sdd/settings/rules/tmux-integration.md:87 | 呼び出し例が `bash {{SDD_DIR}}/settings/scripts/...`、許可パターンが `Bash(bash .sdd/settings/scripts/*)` と表記体系が混在。`{{SDD_DIR}}` 展開が抜ける運用では許可パターン不一致を誘発しやすい | 呼び出し例の `{{SDD_DIR}}` を `.sdd` に展開した形で統一 |

---

## B) ユーザー判断が必要 (4件)

### B1: Cross-Cutting 整合レビューの影響 spec 集合渡し経路が未定義
**Location**: framework/claude/skills/sdd-roadmap/refs/revise.md:255
**Description**: Cross-Cutting 整合レビューで「ALL affected specs」を対象化するとあるが、`/sdd-review` の公開引数は `feature`/`cross-check`/`wave` のみで、影響 spec の集合を明示的に渡す経路が定義されていない。未影響 spec の混入または対象漏れのリスクがある。
**Impact**: Cross-Cutting Revision の整合レビュー精度に直結。影響 spec が多い場合に漏れや過剰レビューが発生する可能性がある。
**Recommendation**: `--cross-check` 引数に spec リストを渡す仕様を追加するか、Lead がループで個別 `--feature` 呼び出しに変換する手順を revise.md Step 9 に明記する — どちらもリスクを解消できるが、引数拡張は /sdd-review のシグネチャ変更を伴う。

---

### B2: install.sh `--update` で settings.json が保持され新規許可ルールが伝搬しない
**Location**: install.sh:498
**Description**: `--update` 実行時に既存 `.claude/settings.json` を常に保持するため、フレームワーク更新で追加された `Bash(bash .sdd/settings/scripts/*)` 等の許可ルールが既存ユーザー環境に反映されない。`bash .sdd/settings/scripts/*.sh` 呼び出しが承認待ち/失敗になる。
**Impact**: フレームワーク更新後に新機能の Bash 許可が機能しない。ユーザーが手動で settings.json を更新しないと問題に気づかない。特に --update 運用ユーザーに影響する。
**Recommendation**: `--update` 時に settings.json の `permissions.allow` 配列を既存エントリを保持しつつ新規エントリのみ追記するマージ処理を実装する — 単純な保持よりも安全性が高い。ただし jq 依存や既存エントリとの衝突ハンドリングが必要なため、設計工数を要する。

---

### B3: Cross-Cutting Revision における blocked spec の扱いが未明記
**Location**: framework/claude/skills/sdd-roadmap/refs/revise.md:122
**Description**: Cross-Cutting Step 2 で revision 対象を `implementation-complete` の spec のみとしており、`blocked` 状態の spec の扱い（通知/除外理由/解除導線）が明記されていないため、依存影響の可視化が欠ける。
**Impact**: 影響分析で `blocked` spec を検出しても処理方針がなく、ユーザーが blocked による依存波及に気づかない可能性がある。
**Recommendation**: `blocked` spec を「Cross-Cutting 対象外だが影響あり」として通知するプロトコルを追記する — 除外自体は妥当だが、可視化のみを追加することで運用コストは低い。

---

### B4: install.sh `--update` の stale 削除が `*.sh` のみ（非 .sh スクリプト未追跡）
**Location**: install.sh:568
**Description**: 更新時の stale ファイル削除が `*.sh` のみで、同ディレクトリの非 `.sh` スクリプト（例: `claude-stream-progress.jq`）を追跡しない。将来の改名/廃止時に旧ファイルが残留し、実行経路の実体とドキュメントが乖離する。
**Impact**: 現時点では `.jq` が 1 ファイル存在（フレームワーク管理対象）。今後スクリプトが増えると残留リスクが上がる。
**Recommendation**: stale 削除対象のパターンを拡張（例: `*.sh *.jq`）し、将来の補助スクリプト追加時に追記する規約をコメントで明示する — 低コストで解決可能。

---

## Platform Compliance

| Item | Status | Source |
|---|---|---|
| agent frontmatter: model | OK | agent-3-compliance (cached) |
| agent frontmatter: tools | OK | agent-3-compliance (cached) |
| agent frontmatter: description | OK | agent-3-compliance (cached) |
| skills frontmatter: description | OK | agent-3-compliance |
| skills frontmatter: allowed-tools | OK | agent-3-compliance |
| skills frontmatter: argument-hint | OK | agent-3-compliance |
| dispatch subagent_type (general-purpose) | OK | agent-3-compliance |
| settings.json permission format | OK | agent-3-compliance |
| settings.json skill/agent entries match files | OK | agent-3-compliance |
| Agent tool: run_in_background parameter | OK (FP confirmed) | D96: 公式サポートフィールドと確認 |
| Agent tool: model parameter | NG → A4 | agent-3-compliance (model は仕様外) |
| Agent tool: description field | NG → A5 | agent-3-compliance (必須フィールド未指定) |
