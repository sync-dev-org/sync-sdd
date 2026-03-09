# Agent Team Reference — Sources and Update Procedure

**Last Updated**: 2026-03-09

This file documents the information sources and research procedure used to create `agent-team-reference.md`. When the reference guide becomes stale, follow this procedure to update it.

---

## Update Procedure

1. Check the "Last Updated" date in `agent-team-reference.md`. If older than ~1 month, update is recommended.
2. For each source below, visit the URL and check for changes since the last update.
3. **特に重要**: Agent Team は Experimental。stable 化、新機能追加、breaking changes が起きやすい。Status が "experimental" から変わっていないか必ず確認
4. Check GitHub Issues for open bugs — Agent Team は活発にバグ報告がある
5. Update `agent-team-reference.md` content and its "Last Updated" date.
6. Update this file's "Last Verified" dates for each source.

---

## Primary Sources

### Official Documentation

| Source | URL | Last Verified |
|--------|-----|--------------|
| Agent teams documentation | https://code.claude.com/docs/en/agent-teams | 2026-03-09 |
| Costs (agent team section) | https://code.claude.com/docs/en/costs | 2026-03-09 |
| Hooks reference | https://code.claude.com/docs/en/hooks | 2026-03-09 |
| Settings reference | https://code.claude.com/docs/en/settings | 2026-03-09 |

Key facts: Token cost is documented as "approximately 7x more tokens than standard sessions when teammates run in plan mode" on the costs page. The agent-teams page does not give a specific multiplier — it says "significantly more tokens". The env var is `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`. teammateMode has 3 values: `auto`, `in-process`, `tmux`.

### GitHub Issues (Active Monitoring)

| Issue | Topic | Last Verified |
|-------|-------|--------------|
| #32276 | shutdown_request wakes idle agents, message to terminated peers (OPEN) | 2026-03-09 |
| #27556 | TaskUpdate metadata not persisted for background agents (OPEN) | 2026-03-09 |
| #32357 | Custom agent definitions for team recruitment (OPEN, FEATURE) | 2026-03-09 |
| #24384 | Windows Terminal as split-pane backend (OPEN, FEATURE) | 2026-03-09 |
| #32110 | Per-teammate model configuration (OPEN, FEATURE) | 2026-03-09 |

Search query: `gh search issues --repo anthropics/claude-code "agent team" --sort updated --limit 15`

### Agent SDK (Comparison)

| Source | URL | Last Verified |
|--------|-----|--------------|
| Agent SDK blog | https://anthropic.com/engineering/building-agents-with-the-claude-agent-sdk | 2026-03-09 |

Key fact: Agent Team is CLI-only. Agent SDK uses `query()` for subagents but has no team coordination API.

---

## Research Queries Used

### Official Docs
- WebFetch: https://code.claude.com/docs/en/agent-teams — full spec
- WebFetch: https://code.claude.com/docs/en/costs — exact token cost wording

### GitHub Issues
- `gh search issues --repo anthropics/claude-code "agent team" --sort updated --limit 15`
- `gh search issues --repo anthropics/claude-code "teammate" --sort updated --limit 10`
- `gh search issues --repo anthropics/claude-code "teammateMode" --sort updated --limit 5`

### Key Verification Points

1. **Experimental status**: May become stable. Check if `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env var name changes
2. **Token cost**: "approximately 7x" (plan mode) on costs page. May be updated with new data
3. **teammateMode values**: Currently `auto`, `in-process`, `tmux`. New backends may be added (#24384 Windows Terminal)
4. **Hooks**: TeammateIdle (command only) and TaskCompleted (all 4 types). New events may be added
5. **Limitations**: Session resumption, task status lag, 1 team/session — any of these may be fixed
6. **Agent SDK**: Agent Team may become available in SDK. Check blog/docs for announcements
7. **Per-teammate model**: Currently not supported at spawn time (#32110). May be added
8. **Display modes**: Split panes restrictions (VS Code, Windows Terminal, Ghostty) — may change
9. **Teammate の CLAUDE.md ロード**: 下記エビデンス参照。SubAgent との差異に注意

---

## 要注意エビデンス

### Teammate と SubAgent の Context 差異

Agent Team の Teammate は SubAgent (Agent tool) とは異なるコンテキストモデルを持つ。

**Teammate (Agent Team)** — 公式 agent-teams ページ:
> "Each teammate has its own context window. When spawned, a teammate loads the same project context as a regular session: **CLAUDE.md, MCP servers, and skills.**"

**SubAgent (Agent tool)** — 公式 sub-agents ページ:
> "Subagents receive **only this system prompt** (plus basic environment details like working directory), **not the full Claude Code system prompt.**"

→ CLAUDE.md をロードするのは **Teammate のみ**。SubAgent は CLAUDE.md を受け取らない (公式ドキュメント準拠)。

この差異は比較表 (SubAgent vs Agent Team) の Context 行に反映済み。更新時に混同しないよう注意。

### トークンコスト

**公式 costs ページ原文**:
> "Agent teams use **approximately 7x** more tokens than standard sessions when teammates run in plan mode"

**公式 agent-teams ページ原文**:
> "Agent teams use **significantly more** tokens than a single session."

→ "3-4x" という数値は公式ドキュメントに存在しない。"approximately 7x" は plan mode 限定の数値。

### Hooks タイプ制限

**公式 hooks ページ原文** (全4タイプサポート vs command のみ):

- **TaskCompleted**: 全4タイプ (`command`, `http`, `prompt`, `agent`)
- **TeammateIdle**: `command` のみ

エビデンス: hooks ページの "Prompt-based hooks" セクション末尾のイベント分類リスト。
