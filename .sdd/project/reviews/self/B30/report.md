# SDD Framework Self-Review Report (External Engine)
**Date**: 2026-03-04T05:34:19+0900 | **Engine**: codex [default] | **Agents**: 4 dispatched, 4 completed

## False Positives Eliminated (6件)

| Finding | Agent | Reason |
|---|---|---|
| Cross-Cutting verdict path inconsistency (H) | 1, 3 | D96 deferred (pre-existing backlog U-M1) |
| SPEC-UPDATE-NEEDED auto-fix loop missing Design Review (H) | 1 | D116 deferred (pre-existing backlog) |
| settings.json missing Bash(rm/claude/env) permissions (M) | 3 | dispatch uses Bash(tmux *) auto-approved; cleanup/install_check are one-time manual approval |
| subagent_type param not in public docs (UNCERTAIN) | 4 | Confirmed working by extensive daily usage |
| run_in_background param not in public docs (UNCERTAIN) | 4 | Confirmed working by extensive daily usage |
| model override param not in public docs (UNCERTAIN) | 4 | Confirmed working by extensive daily usage |

## A) 自明な修正 (3件)

| ID | Sev | Summary | Fix | Target |
|---|---|---|---|---|
| A1 | H | SKILL.md Step 5 の prompt file 名が `agent-{N}-prompt.txt` のまま (テンプレート化で `agent-{N}-{name}.md` に変更済み) | `agent-{N}-prompt.txt` → `agent-{N}-{name}.md` に修正 | framework/claude/skills/sdd-review-self-ext/SKILL.md:167 |
| A2 | H | Design Auditor の example が CONDITIONAL だが formula は C/H → NO-GO | example の VERDICT を NO-GO に変更 | framework/claude/agents/sdd-auditor-design.md:210 |
| A3 | L | install.sh stale cleanup で scripts/ 空ディレクトリが残る (templates/ profiles/ は削除している) | scripts/ も空なら rmdir | install.sh |

## B) ユーザー判断が必要 (5件)

### B1: Impl Auditor — test failures → CONDITIONAL → 通過
**Location**: framework/claude/agents/sdd-auditor-impl.md:220-228
**Description**: Impl Auditor formula で `>3 High OR test failures OR interface mismatches` が CONDITIONAL。CLAUDE.md で CONDITIONAL = GO (proceed) のため、テスト失敗が auto-fix ループを経ずに通過する。
**Impact**: テスト失敗を含む実装が implementation-complete になりうる。run.md の auto-fix は NO-GO のみトリガー。
**Recommendation**: test failures / interface mismatches を NO-GO に昇格 — テスト失敗は実装の根本問題であり自動修正対象にすべき。`>3 High` は CONDITIONAL のまま (多数の High は注意喚起だが blocking ではない) を推奨。

### B2: Dead-code Auditor — formula gap for 1-3 High
**Location**: framework/claude/agents/sdd-auditor-dead-code.md:129-134
**Description**: formula は `>3 High → CONDITIONAL`、`only M/L → GO` だが、1-3 High の分岐がない。example は High 2件で CONDITIONAL を返しており formula と矛盾。
**Impact**: 1-3 High の dead-code findings で verdict が不定。Auditor が独自判断するか formula gap にフォールバック。
**Recommendation**: `>=1 High → CONDITIONAL` に変更し gap を埋める — Dead-code の High は unused export/orphan fixture で CONDITIONAL (注意喚起) が妥当。

### B3: Design Review phase gate が phase=design-generated を要求しない
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md:22
**Description**: standalone design review の phase gate が design.md 存在確認と blocked 判定のみ。`initialized` phase の skeleton design.md でもレビューが通る。
**Impact**: 低リスク。skeleton design.md をレビューしても空の findings になるだけで害はない。ただし CLAUDE.md の phase gate 原則と不整合。
**Recommendation**: `phase ∈ {design-generated, implementation-complete}` を追加で検証。defer も可 — 実害が出るまで放置して問題ない。

### B4: Consensus mode + Web Inspector server 衝突
**Location**: framework/claude/skills/sdd-roadmap/SKILL.md:116, refs/review.md:58-89
**Description**: Consensus mode の N 本並列パイプラインで Web Inspector Server Protocol の pane title/port が衝突する。pipeline ID が server 名・port に反映されない。
**Impact**: Web project で `--consensus N` を使うと dev server が衝突。ただし consensus + web は稀な組み合わせ。
**Recommendation**: defer — consensus + web の需要が出たときに pipeline-indexed server naming を導入。

### B5: sed multiline placeholder 置換の脆弱性
**Location**: framework/claude/skills/sdd-review-self-ext/SKILL.md:127
**Description**: `${FOCUS_TARGETS}` と `${CACHED_OK}` に改行、`&`、`|` 等が含まれると sed 置換が壊れる。
**Impact**: 特殊文字を含む focus targets / compliance cache で壊れたプロンプトが生成される。現状は制御下で問題なし。
**Recommendation**: SKILL.md に「sed-safe 文字制限」の注記を追加するか、将来的に Write で直接生成する方式も検討 — 現時点では注記で十分。

## Platform Compliance

| Item | Status | Source |
|---|---|---|
| agent-frontmatter-fields | OK (cached B6) | https://docs.claude.com/en/docs/claude-code/sub-agents |
| agent-model-values | OK (cached B6) | https://docs.claude.com/en/docs/claude-code/sub-agents |
| skill-frontmatter-fields | OK (cached B6) | https://docs.claude.com/en/docs/claude-code/slash-commands |
| settings-permission-format | OK (cached B6) | https://docs.claude.com/en/docs/claude-code/settings |
| tool-availability-names | OK (cached B6) | https://docs.claude.com/en/docs/claude-code/settings |
| general-purpose-built-in-agent | OK (cached B6) | https://docs.claude.com/en/docs/claude-code/sub-agents |
| dispatch-existing-agent-definitions | OK (new) | https://docs.claude.com/en/docs/claude-code/sub-agents |
| settings-agent-skill-entry-match | OK (new) | https://docs.claude.com/en/docs/claude-code/settings |
| subagent_type / run_in_background / model | FP (UNCERTAIN) | Confirmed working by usage |
