## Change-Focused Review Report

**対象コミット**: HEAD (未コミット変更含む)
**レビュー範囲**: framework/ および install.sh
**レビュー日**: 2026-02-27

---

### Issues Found

- [MEDIUM] M2: run.md Step 6 の `fix`/`skip` オプションへのカウンターリセット追加は機能的に正しいが、CLAUDE.md の counter reset triggers リストにこのシナリオが明示されていない。CLAUDE.md line 172 には「wave completion, user escalation decision, `/sdd-roadmap revise` start」の3つのみ記載。「ブロッキングプロトコルの fix/skip 選択」は user escalation decision に該当するとも読めるが、明示されていないため Lead が誤解する余地がある。

- [LOW] M4: `sdd-inspector-best-practices.md` に WebSearch / WebFetch がツールとして追加されたが、エージェント本文中に「WebSearch を使って最新情報を検索する」「WebFetch で外部URLを参照する」という明示的な使用指示が存在しない。`## Research Depth (Autonomous)` セクションで "research depth" を言及しているが、これは主に「既存コードと設計ドキュメントを深く読む」文脈であり、ウェブ検索の使い時が曖昧。他のエージェント（Agent 4 in sdd-review-self）では `Use WebSearch to verify...` と明示しているのに対し、本エージェントではその指示がない。

- [LOW] L1: review.md line 5 の「Triggered by」行変更により、パース上の問題は生じないが、Router (SKILL.md) が review.md を読んで解釈する際のロードマップとして若干詳細度が上がった。SKILL.md の Detect Mode テーブル (line 21-28) と review.md の Triggered by 記述の対応は保たれており、整合性の問題なし。ただし `review dead-code` 時に `{feature}` 引数が不要な点が、Step 1 の error メッセージ「Usage: `/sdd-roadmap review design|impl|dead-code {feature}`」に `{feature}` が残っており、dead-code には feature が不要なのに error ガイダンスが誤誘導的。これは今回の変更とは無関係な既存問題だが、変更により Triggered by との乖離が可視化されている。

- [LOW] L5: install.sh の v0.18.0 マイグレーション条件変更 (`&& version_lt "$NEW_VERSION" "0.20.0"` 追加) は正しいロジック。ただし、v0.18.0 マイグレーションが実行された場合の `info "Migrated agents/ -> sdd/settings/agents/ (v0.18.0)"` メッセージが今後実行されなくなる（v0.20.0 以降はスキップされる）ため、ユーザーが v0.17.x → v1.3.0 へ直接アップグレードした場合にこのメッセージが出ない。これは意図的な設計（net effect: no-op のためスキップ）だが、ユーザーに「何もしなかった」という透明性がやや欠ける。機能的には問題なし。

- [LOW] L6: `sdd-handover/SKILL.md` および `sdd-review-self/SKILL.md` のフロントマターから `argument-hint:` 行（空値）が削除された。YAML フロントマターとして `argument-hint:` に空値を持つことは有効な YAML だが、空の `argument-hint` はプラットフォームが「ヒントなし」として処理する。削除後のフロントマターは `description:` と `allowed-tools:` のみとなり、これは他の必須フィールドを持つファイル（sdd-roadmap が `argument-hint` を持つ）との非対称性がある。しかし Claude Code の Skill 仕様上、`argument-hint` はオプションフィールドであり、削除は問題ない。フロントマター構文として有効。

---

### Confirmed OK

- **M2 (run.md Step 6 カウンターリセット追加)**: `fix` および `skip` オプションへの `reset retry_count=0 and spec_update_count=0` 追加は、ブロック解除後に新しいパイプライン実行として扱うという設計に整合する。CLAUDE.md の「user escalation decision」というトリガー定義とも意味的に合致（ユーザーが fix/skip を選択することは escalation の解決）。run.md の Step 7c Post-gate でも同様のリセットが行われており、一貫性がある。

- **M4 (sdd-inspector-best-practices.md ツール追加)**: フロントマターの `tools: Read, Glob, Grep, Write, WebSearch, WebFetch` は有効な形式。エージェント本文の「Research Depth (Autonomous)」「Technology novelty」「Are there known issues with the versions/APIs referenced?」といった記述は、ウェブ検索が有用な文脈を示しており、ツール追加の根拠として十分。

- **L1 (review.md Triggered by 行変更)**: 変更後のフォーマット `"review design|impl {feature} [options]"` or `"review dead-code [options]"` は、Router の Detect Mode テーブルと整合している。Step 1 の parse ロジック、Step 2 の phase gate、各レビュータイプのセクションはすべて完全に存在し、プロトコルの完全性に問題なし。

- **L5 (install.sh v0.18.0 migration 条件化)**: v0.17.x 以下 → v0.20.0 以上へのアップグレードで v0.18.0 マイグレーション（エージェントを .claude/agents/ から削除）をスキップし、直接 v0.20.0 マイグレーション（.claude/sdd/settings/agents/ から .claude/agents/ に移動）を実行するロジックは正しい。`.claude/sdd/settings/agents/` が存在しない場合は v0.20.0 マイグレーションも何もしない（ディレクトリ存在チェックあり）。v0.18.0 から v0.19.x の間からのアップグレードは従来通り v0.20.0 マイグレーションのみ適用され正しい。

- **L6 (argument-hint 削除)**: sdd-handover と sdd-review-self の引数なし設計は正しい。sdd-handover は引数なしで起動し対話的に情報収集する。sdd-review-self も引数不要。不要なフィールドの削除はクリーンアップとして適切。

- **cpf-format.md Category values 追記**: 「Category values are Inspector-specific (not a global enum)」の追記は、各 Inspector が独自カテゴリを定義しているという既存設計の明文化であり、変更による破壊なし。

- **revise.md After each Architect completes 追記**: Step 7 の Design Fan-Out 後に「After each Architect completes: update spec.yaml per design.md Step 3」を追記。run.md の Phase Handlers > Design completion と整合（同様の記述あり）。

- **波コンテキスト生成 (run.md Step 2.5)**: conventions-brief.md テンプレートが `framework/claude/sdd/settings/templates/wave-context/conventions-brief.md` として実際に存在することを確認。CLAUDE.md の Parallel Execution Model > Wave Context 記述とも整合。impl.md の Pilot Stagger Protocol も conventions brief を参照しており一貫性あり。

- **Review Decomposition 追加 (run.md)**: Dispatch Loop のサブフェーズ分解は review.md の既存フローを参照しており、review.md の sequential flow との矛盾なし。DISPATCH-INSPECTORS が review.md steps 1-4 を、INSPECTORS-COMPLETE が steps 5/5a を、AUDITOR-COMPLETE が steps 7-9 を実行する対応が明確。

---

### Overall Assessment

今回の変更セット全体は、概して整合性が保たれており、重大な問題は検出されなかった。

**主要変更の評価**:

1. **M2 (run.md Step 6 カウンターリセット)**: 正しい修正。ブロッキングプロトコルの fix/skip 後にカウンターがリセットされないと、ダウンストリームが不当に少ないリトライ回数しか使えなくなるバグを防ぐ。MEDIUM 指摘は CLAUDE.md のドキュメントがそのシナリオを counter reset triggers に明示していないことによる軽微な不整合であり、機能的問題ではない。

2. **M4 (best-practices inspector WebSearch/WebFetch 追加)**: ツール自体の追加は正しい。エージェント本文に明示的な使用指示がない点は LOW だが、Research Depth セクションの文脈から推測可能。将来的に使用指示を追加することを推奨するが緊急性はない。

3. **L1 (review.md Triggered by 変更)**: パース問題なし。ただし Step 1 の error ガイダンスメッセージ (`dead-code {feature}`) は dead-code に feature 引数が不要な点で若干誤誘導的。今回の変更が原因ではなく既存問題。

4. **L5 (install.sh v0.18.0 conditional)**: ロジック正確。アップグレードパスのすべてのシナリオで正しく動作する。

5. **L6 (argument-hint 削除)**: 問題なし。クリーンアップとして適切。

**推奨アクション**:
- CLAUDE.md の「Counter reset triggers」リストに「blocking protocol fix/skip 選択時（ダウンストリームspec対象）」を追記することを検討（LOW priority）
- sdd-inspector-best-practices.md の Research Depth セクションまたは Investigation Approaches セクションに「WebSearch/WebFetch を使用してライブラリバージョン、セキュリティ勧告、最新プラクティスを検索できる」旨を1行追記することを検討（LOW priority）

WRITTEN:.sdd/project/reviews/self/active/agent-2-changes.md
