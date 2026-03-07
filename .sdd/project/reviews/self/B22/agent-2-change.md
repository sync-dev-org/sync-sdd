## Change-Focused Review Report

**対象コミット範囲**: HEAD~5..HEAD + 未コミット作業ツリー変更

---

### Issues Found

- [HIGH] `sdd-review-self-codex` が `settings.json` の `Skill()` 許可リストに未登録 / `framework/claude/settings.json`

  `framework/claude/skills/sdd-review-self-codex/SKILL.md` が存在するが、`settings.json` には `Skill(sdd-review-self-codex)` エントリが追加されていない。`/sdd-review-self-codex` を呼び出すと実行時にユーザー確認が必要になる。

- [HIGH] `sdd-release` Step 3.3 の除外条件が `sdd-review-self-codex` を漏らしている / `framework/claude/skills/sdd-release/SKILL.md:134`

  Step 3.3 のコマンド数カウント除外指示は `(exclude sdd-review-self — internal tool, not a user command)` と書かれているが、同様に内部ツールである `sdd-review-self-codex` が除外対象に含まれていない。`framework/claude/skills/sdd-*/SKILL.md` は現在 9 ファイル存在し、`sdd-review-self` だけを除外すると 8 とカウントされ、CLAUDE.md の `### Commands (7)` と不一致になる。正しくは両方を除外する必要がある。

  - スキル全 9 件: sdd-handover, sdd-publish-setup, sdd-reboot, sdd-release, sdd-review-self, sdd-review-self-codex, sdd-roadmap, sdd-status, sdd-steering
  - 内部ツール 2 件: sdd-review-self, sdd-review-self-codex
  - ユーザー向けコマンド: 7 件 (CLAUDE.md 記載と一致)
  - 修正箇所: `sdd-release/SKILL.md:134` に `sdd-review-self-codex` も除外対象として追記

- [MEDIUM] `tmux-integration.md` と `sdd-review-self-codex/SKILL.md` が未コミット / 作業ツリー

  `framework/claude/sdd/settings/rules/tmux-integration.md` と `framework/claude/skills/sdd-review-self-codex/SKILL.md` (ディレクトリ含む) は untracked 状態。CLAUDE.md (未コミット変更) と review.md (未コミット変更) は両者を参照しているため、コミットを忘れると参照切れが発生する。同一コミットに含める必要がある。

- [MEDIUM] `review.md` Web Inspector Server Protocol のフォールバック詳細が省略 / `framework/claude/skills/sdd-roadmap/refs/review.md:52-64` (作業ツリー)

  変更後の `review.md` は「Apply **Server Lifecycle pattern** from `tmux-integration.md`」と委譲するのみで、フォールバックモード (`$TMUX` 未設定時: `Bash(run_in_background=true)`, PID 記録, URL ポーリング, PID kill) への明示的な言及がなくなった。`tmux-integration.md` の Pattern A Fallback セクションにはその内容が存在するため分割損失ではないが、Lead が review.md を読んでいるときに「フォールバックがある」と認識できる文言が消えている。Pattern A を参照するよう明記するか、Fallback の存在を示すコメントを残すことを推奨。

- [LOW] `Orphan Cleanup` のスコープが `sdd-devserver-*` から `sdd-*` 全体に拡大 / `framework/claude/sdd/settings/rules/tmux-integration.md:85-93` (未コミット)

  旧 CLAUDE.md では Orphan Cleanup で `sdd-devserver-` プレフィックスのペインのみを kill していたが、新しい `tmux-integration.md` の Orphan Cleanup セクションは `sdd-` プレフィックスを持つすべてのペインを kill する。これはスコープの拡大であり、セッション再開時に `sdd-codex-*` 等の進行中ペインも kill される可能性がある。意図的な変更ならドキュメントに理由を記載すること。

---

### Confirmed OK

- **sdd-inspector-e2e 新設 (agent ファイル)**: `sdd-inspector-e2e.md` は CLI ベース E2E 実行に完全に書き換えられ、playwright-cli 依存を削除済み。ミッション、制約、出力フォーマットが一貫している。
- **sdd-inspector-web-e2e 新設**: 旧 `sdd-inspector-e2e.md` のブラウザテスト内容が `sdd-inspector-web-e2e.md` に移植されており、内容の分割損失なし。
- **sdd-inspector-web-visual 新設**: 旧 `sdd-inspector-visual.md` の内容が `sdd-inspector-web-visual.md` に移植。旧名 `sdd-inspector-visual` への参照はフレームワーク全体で発見されなかった。
- **sdd-auditor-impl 更新**: Inspector リストが 8 件から 9 件に更新 (e2e + web-e2e + web-visual の 3 種) され、CPF ファイル名も `sdd-inspector-web-e2e.cpf` / `sdd-inspector-web-visual.cpf` に正しく更新。
- **settings.json 更新**: `Agent(sdd-inspector-web-e2e)` 追加、`Agent(sdd-inspector-visual)` → `Agent(sdd-inspector-web-visual)` リネーム済み。`Bash(curl *)` 追加済み。
- **review.md の Inspector dispatch 参照**: `sdd-inspector-web-e2e` / `sdd-inspector-web-visual` に正しく更新。`sdd-inspector-e2e` は E2E コマンド設定ありプロジェクト向けとして別途追加。
- **tmux-integration.md Pattern A の内容**: 旧 review.md tmux Mode の詳細手順 (既存ペイン確認、ポートオフセット、ペイン ID キャプチャ、readiness ポーリング、Kill) をすべてカバーしている。
- **CLAUDE.md tmux Integration 記述**: `Full patterns: tmux-integration.md` と参照先を明記しており、ダングリング参照なし (tmux-integration.md が実際に存在する前提)。
- **run.md E2E Gate 削除**: impl.md Step 3.5 (E2E Gate) が削除されたことに伴い、run.md の参照 (`Steps 1-3.5` → `Steps 1-3`) と revise.md の参照 (`E2E Gate per impl.md Step 3.5` → 削除) も整合的に更新済み。
- **CLAUDE.md Inspector 説明**: `6 impl +2 web (impl only, web projects)` → `6 impl +1 e2e +2 web (impl only; e2e/web are conditional)` に更新。実際の Inspector 構成と一致。
- **sdd-review-self SKILL.md 更新**: `general-purpose` は Claude Code 組み込みエージェントである旨の注記が Agent 3/4 プロンプトに追加済み。settings.json チェックから除外する記述も整合的。
- **sdd-release SKILL.md 更新**: `sdd-review-self` 除外条件追加は正しい (ただし `sdd-review-self-codex` の漏れは上記 HIGH で報告済み)。
- **sdd-inspector-test / sdd-builder 更新**: Built-in tool preference ルールが Constraints に追加済みで CLAUDE.md の方針と整合。
- **sdd-auditor-dead-code 更新**: SCOPE を `dead-code` に統一済み。
- **install.sh バージョン**: v1.14.0 に更新済み。

---

### Overall Assessment

今回の変更は主に 3 つのリファクタリングを含む:

1. **E2E Inspector 分離** (sdd-inspector-e2e = CLI 実行 / sdd-inspector-web-e2e = ブラウザ): 各ファイルの内容・参照・settings.json の整合性は概ね取れている。

2. **tmux 共通化** (tmux-integration.md 新設、CLAUDE.md / review.md 委譲): `tmux-integration.md` と `sdd-review-self-codex/SKILL.md` が未コミットのため、これらが含まれないと参照切れになる。コミット漏れに注意が必要。

3. **sdd-review-self-codex 新設**: `settings.json` への `Skill()` 登録と、`sdd-release` の除外リスト更新が両方とも漏れており、リリース時のコマンド数検証が誤った結果を返す。

**重大な動作障害を引き起こすバグはない** が、HIGH 2 件 (settings.json 未登録、release スキルのカウント誤り) と未コミットファイルの漏れリスク (MEDIUM) の対処が推奨される。
