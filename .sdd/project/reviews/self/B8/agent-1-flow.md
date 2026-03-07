## Flow Integrity Report

### Issues Found

- [HIGH] `refs/impl.md` Step 4 に番号の欠落あり: ステップ番号が `1. Auto-draft` → `3. Report to user` とスキップしており、`2.` が欠落している / framework/claude/skills/sdd-roadmap/refs/impl.md:72-73

- [HIGH] `refs/revise.md` Part B Step 7のタイアー実行内で「Design Review」ハンドリングが不完全: NO-GO時のカウンター増加・再試行は「counter limits」参照と書かれているが、SPEC-UPDATE-NEEDED が Design Review から返却された場合の扱いが明記されていない。`refs/run.md` Design Review completion では `SPEC-UPDATE-NEEDED` について「not expected for design review. If received, escalate immediately.」と記載されているが、`refs/revise.md` のタイアー実行（Step 7 Design Review）にはこの旨の記述がなく、Lead が同じ判断を知らない可能性がある / framework/claude/skills/sdd-roadmap/refs/revise.md:218-221

- [HIGH] `refs/revise.md` Part B Step 8 (Cross-Cutting Consistency Review) のベルディクトパーシステンス先が通常のインペルレビューパスと異なる: `specs/.cross-cutting/{id}/verdicts.md` に書かれているが、`refs/review.md` の「Verdict Destination by Review Type」では `Cross-cutting review` の宛先として同パスが記載されており整合は取れているものの、`run.md` Step 7a (Wave QG Impl Cross-Check Review) は `reviews/wave/verdicts.md` に書く。`refs/revise.md` Step 8 はこれとは別のクロスカッティング専用パスを使うことが明示されていないため、Lead が誤って `wave/verdicts.md` に書く可能性がある / framework/claude/skills/sdd-roadmap/refs/revise.md:241-243

- [MEDIUM] `SKILL.md` の Detect Mode セクションで `revise [instructions]` (feature名なし) が Cross-Cutting Mode にルーティングされると定義されているが、`refs/revise.md` の Mode Detection ではこれが「feature matches known spec name」かどうかで判断されると書かれている。feature名が省略された場合に Lead が spec ディレクトリ名と一致するかをどのように判断するかの境界条件が曖昧 — 例えばユーザーが feature 名に一致する単語を instruction に含めた場合の誤検出リスクがある / framework/claude/skills/sdd-roadmap/SKILL.md:34-35 / framework/claude/skills/sdd-roadmap/refs/revise.md:8-16

- [MEDIUM] Wave QG Dead Code Review の retry 上限が CLAUDE.md と `refs/run.md` で説明レベルが異なる: CLAUDE.md では「Dead-Code Review NO-GO: max 3 retries」と明記されているが、`refs/run.md` Step 7b の NO-GO ハンドリングには「max 3 retries → escalate」とあり一致している。ただし aggregate cap (6) が Dead-Code Review にも適用されるかどうかが `refs/run.md` には記述がなく、CLAUDE.md のみに「Exception」として記載されている。Dead-Code は独立カウンターで aggregate cap の対象外という意図が `refs/run.md` に反映されていない / framework/claude/CLAUDE.md§Auto-Fix Counter Limits / framework/claude/skills/sdd-roadmap/refs/run.md:182-183

- [MEDIUM] `refs/review.md` Consensus Mode の参照先が Router の `Shared Protocols` セクションのみになっている (`If --consensus N, apply Consensus Mode protocol (see Router).`): しかし `SKILL.md` (Router) には Consensus Mode プロトコルが詳細定義されている。この `refs/review.md` の参照は正しいが、Review Execution Flow Step 1 で B{seq} を決定する際に Consensus 時は `active-{p}/` ディレクトリを使うと Router で定義されている。しかし `refs/review.md` のステップ 2 (Determine B{seq}) はシングルパス前提で書かれており、Consensus 時の B{seq} 決定フローが Review ref 内で完結していない。Router の Step 1 を先に読まないと誤った dir を作る可能性がある / framework/claude/skills/sdd-roadmap/refs/review.md:90

- [MEDIUM] `refs/revise.md` Part A Step 4 の State Transition で `phase = design-generated` にリセットするが、`spec.yaml.version` のインクリメントについて記載がない。`refs/design.md` Step 3 では「If re-edit: increment version minor」とあり、Architect 完了後に Lead が version を上げる。しかし revise フローの Step 5-1 (Design) ではこの処理を明示しておらず「Execute per refs/design.md」と参照しているだけ。refs/design.md 内の処理が適用されるのかが不明瞭 — refs/design.md は phase が `design-generated` を前提に書かれており、revise の State Transition 後も同じ手順が機能するが、spec.yaml の version 更新タイミングが revise フロー上で追いにくい / framework/claude/skills/sdd-roadmap/refs/revise.md:71-74

- [MEDIUM] `refs/revise.md` Part A Step 6 (Downstream Resolution) において option (b) "Re-implement" の処理として `Architect re-designs against updated upstream → Design Review → TaskGenerator → Builder → Impl Review` と書かれているが、spec.yaml の phase をどのフェーズにリセットするかが記載されていない。option (b) を選んだ場合 Lead が dependent spec の `phase = design-generated`、`last_phase_action = null` にリセットする必要があるが、その手順が暗示的にしか読めない / framework/claude/skills/sdd-roadmap/refs/revise.md:91

- [LOW] `refs/run.md` の Readiness Rules テーブルにて「Impl Review」の条件が「All Builders for this spec have completed.」のみ記載されているが、`implementation-complete` phase であることも前提条件のはず。`refs/impl.md` Step 1 では phase が `implementation-complete` でないと Impl Review に進めない (Phase Gate) が、run.md のテーブルには phase 条件が書かれていない / framework/claude/skills/sdd-roadmap/refs/run.md:87

- [LOW] `refs/review.md` の「Verdict Destination by Review Type」に `Cross-cutting review` のパス (`specs/.cross-cutting/{id}/verdicts.md`) が記載されているが、この `{id}` がどのように決定されるかへの言及がない。`refs/revise.md` Part B Step 4 で `{id}` は kebab-case identifer と定義されているが、review.md 内からは refs/revise.md を参照していないため review 単体から見ると情報が欠如している / framework/claude/skills/sdd-roadmap/refs/review.md:128

- [LOW] `refs/crud.md` Delete Mode の説明が「Delete roadmap.md, all spec directories, and project-level reviews directory」と書いているが、`{{SDD_DIR}}/project/reviews/` への参照パス定義が CLAUDE.md には存在しない。Paths セクションには `{{SDD_DIR}}/project/specs/` と `{{SDD_DIR}}/project/steering/` は定義されているが `{{SDD_DIR}}/project/reviews/` は定義されておらず、実際のパスはコンテキストから推察するしかない / framework/claude/skills/sdd-roadmap/refs/crud.md:81 / framework/claude/CLAUDE.md§Paths

---

### Confirmed OK

- Router → refs dispatch 完全性: SKILL.md の Detect Mode で全サブコマンド（design, impl, review design/impl/dead-code, run, revise Single-Spec/Cross-Cutting, create, update, delete）が対応する refs ファイルに正しくルーティングされている
- Phase gate 一貫性: `design-generated`/`implementation-complete`/`blocked`/`initialized` の 4 フェーズが CLAUDE.md と各 refs で一貫して使われている
- Auto-fix ループのカウンター: CLAUDE.md の `retry_count` max 5、`spec_update_count` max 2、aggregate cap 6 が `refs/run.md` Phase Handlers に正確に反映されている
- Wave QG フロー完全性: `refs/run.md` Step 7 に impl cross-check → dead-code → post-gate (counter reset + commit) の流れが完結して記述されている
- Consensus モードの並列パイプライン: SKILL.md の Shared Protocols セクションで N パイプラインの独立実行 (`active-{p}/`)、N verdict のアーカイブ (`B{seq}/pipeline-{p}/`)、集計・閾値適用が定義されており、`refs/review.md` からの参照も正しい
- Verdict persistence フォーマット: SKILL.md の Verdict Persistence Format (a-h) が全レビュータイプで共通使用されている。`refs/review.md` Step 8 でこのフォーマットへの参照が明示されている
- Inspector/Auditor 名称整合性: `settings.json` の `Task()` 許可リストが `framework/claude/agents/sdd-*.md` のすべてのエージェントを網羅しており、漏れはない (sdd-inspector-impl-holistic 含む)
- 1-Spec Roadmap Optimizations: SKILL.md § 1-Spec Roadmap Optimizations に Wave QG スキップ・cross-spec ownership スキップが定義され、`refs/run.md` Step 7 冒頭でも「1-Spec Roadmap: Skip this step」と明示されており整合している
- Island spec (Wave Bypass): `refs/run.md` Step 3 Island Spec Detection が定義されており、fast-track lane の独立動作・Wave QG 不参加が記述されている
- Blocked spec フロー: `refs/run.md` Step 6 Blocking Protocol で downstream spec への blocked_info 設定・修復オプション (fix/skip/abort) が完結して記述されている
- Retry 上限消耗後のエスカレーション: `refs/run.md` Step 7a で exhaustion → escalate (Proceed/Abort wave/Manual fix) の3択が記述されており、CLAUDE.md § Auto-Fix Counter Limits と整合している
- Session Resume フロー: CLAUDE.md § Session Resume の spec.yaml ground truth 扱いと pipeline 継続ルールが正確に記述されている
- Revise Single-Spec → Cross-Cutting エスカレーション: `refs/revise.md` Part A Step 3 で 2+ affected specs 検出時に Cross-Cutting Mode (Part B) 提案が記述されており、SKILL.md の Detect Mode からも `revise <feature>` → Single-Spec として正しくルーティングされている
- Revise Cross-Cutting のティア実行: Part B Step 7 で run.md Dispatch Loop パターンに準拠したティア逐次・ティア内並列実行が記述されている
- STEERING フィードバックループ: `refs/review.md` で CODIFY/PROPOSE の処理ルールが定義され、`refs/run.md` Phase Handlers でも `Process STEERING: entries from verdict` が各フェーズに明示されている
- Auditor output の最小化: 全 Auditor エージェント定義で `WRITTEN:{path}` のみを返却するよう指示されており、CLAUDE.md § Review SubAgents の token-efficiency ルールと整合している
- CPF フォーマット: `settings/rules/cpf-format.md` で定義されたフォーマットが Inspector/Auditor エージェント全体で一貫して使用されている

---

### Overall Assessment

全体的にフレームワークのフロー設計は堅牢であり、主要な dispatch ルート、phase gate、auto-fix ループ、wave QG はすべて動作可能な状態にある。

重要度の高い問題として、`refs/impl.md` のステップ番号欠落（軽微だが混乱を招く）、`refs/revise.md` Part B の Design Review における SPEC-UPDATE-NEEDED ハンドリングの未明示（CLAUDE.md§Auto-Fix Counter Limits や refs/run.md と組み合わせれば推察可能だが、明示的でない）、および Cross-Cutting revise の verdict 保存先の不明確さが挙げられる。

Dead-Code Review の retry 上限の aggregate cap 除外について、`refs/run.md` への反映が欠けている点は、Lead が誤って aggregate cap を適用するリスクがある。

`refs/revise.md` Part A のダウンストリーム解決 (Step 6 option b) での spec.yaml フェーズリセット手順の暗示的表現は、実装者の判断に依存する部分があり、将来的に明示化することが望ましい。

クリティカルなブロッカーは存在しない。HIGH 問題を優先的に修正することでフレームワークの堅牢性が向上する。
