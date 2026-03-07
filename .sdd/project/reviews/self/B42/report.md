# SDD Framework Self-Review Report
**Date**: 2026-03-06T21:31:06+0900
**Agents**: 6 dispatched (3 fixed + 3 dynamic), 6 completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| L\|archive-schema-drift\|.sdd/project/reviews/self/verdicts.md:179 | inspector-dynamic-1 | verdicts.md は append-only ログ。"prep:" 見出しは B41 バッチ実行時点の名前を正確に反映しており、遡及修正は履歴を改ざんする |
| L\|deleted-ref-residue\|.sdd/project/reviews/self/B41/dynamic-manifest.md:2 | inspector-dynamic-3 | B41 は過去レビューのアーカイブスナップショット。manifest は当時のファイル名 (`agent-dynamic-*`) を正確に記録しており、アーカイブは変更しない |

## A) 自明な修正 (8件) — OK で全件修正します

| ID | Sev | Location | Summary | Fix |
|---|---|---|---|---|
| A1 | HIGH | framework/claude/CLAUDE.md:88 | `refs/run.md` 相対参照が未解決（実体は `skills/sdd-roadmap/refs/run.md`） | `skills/sdd-roadmap/refs/run.md` への明示パスに修正 |
| A2 | HIGH | framework/claude/skills/sdd-reboot/refs/reboot.md:120 | `refs/run.md` が `sdd-reboot/refs/refs/run.md` 解決で到達不能 | `../sdd-roadmap/refs/run.md`（または絶対パス）に修正 |
| A3 | HIGH | framework/claude/sdd/settings/templates/review-self/briefer.md:68 | キャッシュ再利用手順が旧ファイル名 `agent-3-compliance.cpf` を参照し、現行名 `inspector-compliance.cpf` と不一致 | `inspector-compliance.cpf` に更新 |
| A4 | MEDIUM | framework/claude/sdd/settings/templates/review-self/inspector-flow.md:15 | `refs/revise.md` がテンプレート基準で未定義、参照先一意解決不可 | `skills/sdd-roadmap/refs/revise.md`（または同等の明示パス）に修正 |
| A5 | MEDIUM | framework/claude/skills/sdd-review/SKILL.md:211 | `steering/tech.md` が `{{SDD_DIR}}/project/` プレフィックスなし表記で同ファイル内の絶対パス表記と混在 | `{{SDD_DIR}}/project/steering/tech.md` に正規化 |
| A6 | MEDIUM | framework/claude/sdd/settings/templates/review-self/briefer.md:66 | 旧ロール名 "Agent 3 (Platform Compliance)" が残存。現行名 `inspector-compliance` と不一致 | `inspector-compliance` に置換 |
| A7 | LOW | framework/claude/skills/sdd-roadmap/SKILL.md:113 | Shared Protocol の Verdict Persistence に Cross-Cutting ヘッダー書式が未記載 | `[CC-B{seq}]` フォーマット例を Verdict Persistence セクションに追記 |
| A8 | LOW | framework/claude/sdd/settings/scripts/ensure-playwright-cli.sh:4 | Usage コメントが自身のスクリプトパスを参照する自己循環 | Usage コメントを非循環表現に修正 |

## B) ユーザー判断が必要 (6件)

### B1: `review impl --cross-cutting` の Router Detect Mode 未定義
**Location**: framework/claude/skills/sdd-roadmap/SKILL.md:15
**Description**: Detect Mode の入力パターン一覧に `sdd-review review impl --cross-cutting {specs}` の明示ルートが存在しない。`sdd-review` 側サブコマンド (`review impl --cross-cutting`) との対応が暗黙依存となっており、Router 経由で直接呼び出せるか否かが曖昧。
**Impact**: Router 経由で cross-cutting impl レビューを実行しようとした場合にルーティングミスが起きる可能性。HIGH。
**Recommendation**: Detect Mode に `review impl --cross-cutting {specs}` エントリを明示追加 — cross-cutting レビューは通常の `review impl` と異なる引数パターンを持つため、Router が受け取った場合の処理パスを明確化すべき。

---

### B2: Dead-Code Wave QG での `SPEC-UPDATE-NEEDED` 未定義
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:255
**Description**: Wave QG の Dead-Code 分岐は GO/CONDITIONAL/NO-GO の3種のみを処理し、`SPEC-UPDATE-NEEDED` verdict への対応が未定義。Dead-Code Inspector が spec の誤参照を発見して SPEC-UPDATE-NEEDED を返した場合、Lead の処理が不定になる。
**Impact**: Dead-Code レビューで SPEC-UPDATE-NEEDED が返された際に Lead の動作が未規定。D116 (SPEC-UPDATE-NEEDED ループへの Design Review 追加) はこの分岐とは別スコープで defer 済み。MEDIUM。
**Recommendation**: Dead-Code QG に SPEC-UPDATE-NEEDED 分岐を追記し、通常の SPEC-UPDATE-NEEDED フローへ誘導する — Dead-Code Inspector も spec 参照の誤りを検出しうるため、SPEC-UPDATE-NEEDED は有効な返り値として扱う必要がある。

---

### B3: `sdd-review-self` verdicts.md フォーマットと `sdd-review` 形式の不統一
**Location**: framework/claude/skills/sdd-review-self/SKILL.md:343
**Description**: `sdd-review-self` の verdicts.md 追記形式（集計行中心）が、`sdd-review`/Router Shared Protocol で定義された Raw+Disposition+Tracked/Resolved 形式と異なる。review type 間で持続化フォーマットが二系統化している。
**Impact**: review-self と review の verdict 履歴を横断参照・統合する際に解析コードや Lead の読み取りロジックが二重化する。MEDIUM。
**Recommendation**: 統一するか意図的に分けるかを決定 — (a) sdd-review-self も Shared Protocol 形式に揃える、または (b) 「self-review は簡易集計形式」と CLAUDE.md に明示して意図的差異として文書化。現状の無言の不統一が最も問題。

---

### B4: `sdd-review` SKILL.md の version 取得元が `VERSION` ファイルを参照、実体は `.sdd/.version`
**Location**: framework/claude/skills/sdd-review/SKILL.md:420
**Description**: レビュー履歴の `v{version}` を "VERSION ファイル" から取得と定義しているが、install.sh:526-530 は `.sdd/.version` にフレームワークバージョンを書き込む。project 側の `VERSION` ファイル（存在すれば project version）と framework 管理の `.sdd/.version` は別物。
**Impact**: version 値がプロジェクトによって異なる（VERSION 未保有の場合 404）。レビュー履歴に記録されるバージョンが意図と異なる可能性。MEDIUM。
**Recommendation**: `.sdd/.version` を正規のバージョン参照先として SKILL.md を修正 — sdd-review はフレームワーク操作であり、記録すべきは framework version（`.sdd/.version`）であることを明確化する。

---

### B5: Dead-Code NO-GO retry 上限到達時のユーザー選択肢が未規定
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:260
**Description**: Dead-Code NO-GO の retry が上限（3回）に達した際のエスカレーションで、ユーザーに提示する具体的な選択肢（proceed/abort/manual fix 等）が記載されていない。通常の Cross-Check 分岐のような選択肢提示が欠落。
**Impact**: Lead がユーザーに対して何を提案すべきかが不定で、エスカレーション時のインタラクション品質が低下する。LOW。
**Recommendation**: 通常 NO-GO 上限到達と同形式で選択肢（例: a) dead-code を手動対処して continue, b) skip dead-code review, c) abort pipeline）を明示追加 — 運用上の判断の一貫性を確保するため。

---

### B6: Spec Stagger と Revise tier 内 phase 完了バリアの例外条件が不明確
**Location**: framework/claude/CLAUDE.md:96
**Description**: CLAUDE.md:96 は Spec Stagger（specs が同一 wave 内で異なる phase を並走可能）を強調するが、`refs/revise.md:206` は cross-cutting revision の tier 内で phase 完了バリアを要求する。両ルールが同文書内で矛盾なく共存できる条件（Stagger は通常 run、バリアは revise に限定等）が明示されていない。
**Impact**: Lead が新しい run/revise パターンを判断する際に、どちらのルールを優先するか解釈が分岐する可能性。LOW。
**Recommendation**: "Spec Stagger は通常 run pipeline に適用、cross-cutting revise tier 内では phase 完了バリアが優先" と例外スコープを明記 — 現状は暗黙のスコープ分離を読み手に委ねており、明文化で誤解を防げる。

## Platform Compliance

| Item | Status | Source |
|---|---|---|
| agent-frontmatter-model | COMPLIANT | cached |
| agent-frontmatter-tools | COMPLIANT | cached |
| agent-frontmatter-description | COMPLIANT | cached |
| skills-frontmatter-description | COMPLIANT | verified |
| skills-frontmatter-allowed-tools | COMPLIANT | verified |
| skills-frontmatter-argument-hint-format | COMPLIANT | verified |
| agent-tool-subagent-type-general-purpose | COMPLIANT | verified |
| agent-tool-params-model-run_in_background | COMPLIANT | verified |
| agent-tool-dispatch-subagent-type-matches-definitions | COMPLIANT | verified |
| settings-permission-format | COMPLIANT | cached |
| settings-skill-permission-syntax | COMPLIANT | cached |
| settings-agent-skill-entries-match-files | COMPLIANT | verified |
| agent-tool-availability | COMPLIANT | verified |
