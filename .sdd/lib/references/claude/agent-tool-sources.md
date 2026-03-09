# Agent Tool Reference — Sources and Update Procedure

**Last Updated**: 2026-03-09

This file documents the information sources and research procedure used to create `agent-tool-reference.md`. When the reference guide becomes stale, follow this procedure to update it.

---

## Update Procedure

1. Check the "Last Updated" date in `agent-tool-reference.md`. If older than ~1 month, update is recommended.
2. For each source below, visit the URL and check for changes since the last update.
3. Pay special attention to: new parameters, new built-in agent types, model alias changes, new environment variables, breaking changes to nesting/context/background behavior.
4. Check GitHub Issues for open bugs that contradict official docs (docs can lag behind actual behavior).
5. Update `agent-tool-reference.md` content and its "Last Updated" date.
6. Update this file's "Last Verified" dates for each source.

---

## Primary Sources

### Official Documentation

| Source | URL | Last Verified |
|--------|-----|--------------|
| Sub-agents documentation | https://code.claude.com/docs/en/sub-agents | 2026-03-09 |
| Model configuration | https://code.claude.com/docs/en/model-config | 2026-03-09 |
| Costs and token usage | https://code.claude.com/docs/en/costs | 2026-03-09 |
| Settings & env vars | https://code.claude.com/docs/en/settings | 2026-03-09 |
| Agent teams (for comparison) | https://code.claude.com/docs/en/agent-teams | 2026-03-09 |
| Hooks reference | https://code.claude.com/docs/en/hooks | 2026-03-09 |
| CLI reference | https://code.claude.com/docs/en/cli-reference | 2026-03-09 |

Key facts: Agent tool parameters are not directly documented as a parameter table — they are inferred from the built-in tool definition and usage patterns. Built-in agent types are listed under "Built-in subagents". Model aliases are on the model-config page.

### GitHub Issues (Active Monitoring)

| Issue | Topic | Last Verified |
|-------|-------|--------------|
| #5456 | Agent definition model ignored (CLOSED, DUPLICATE) | 2026-03-09 |
| #3903 | --model not inherited by sub-tasks (CLOSED, NOT_PLANNED) | 2026-03-09 |
| #27736 | skills field not rendered in Agent tool description (OPEN) | 2026-03-09 |
| #32340 | Skills invocation + nested spawning feature request (OPEN) | 2026-03-09 |

Search query for new issues: `gh search issues --repo anthropics/claude-code "subagent OR agent definition OR agent tool" --sort updated --limit 20`

### Release Tracking

| Source | URL | Last Verified |
|--------|-----|--------------|
| Claude Code updates | https://www.claudeupdates.dev | 2026-03-09 |
| Documentation index | https://code.claude.com/docs/llms.txt | 2026-03-09 |

---

## Research Queries Used

These queries were used during the initial research (2026-03-09). Reuse them for updates.

### Official Docs
- WebFetch: https://code.claude.com/docs/en/sub-agents — full spec extraction
- WebFetch: https://code.claude.com/docs/en/model-config — model aliases, env vars

### GitHub Issues
- `gh search issues --repo anthropics/claude-code "subagent" --sort updated --limit 20`
- `gh search issues --repo anthropics/claude-code "agent definition model ignored" --sort updated`
- `gh search issues --repo anthropics/claude-code "CLAUDE_CODE_SUBAGENT_MODEL" --sort updated`
- `gh search issues --repo anthropics/claude-code "agent tool parameter" --sort updated`

### Key Verification Points

On each update, verify these specific claims which are most likely to change:

1. **Built-in agent types**: New types may be added. Check "Built-in subagents" section
2. **Model aliases**: New aliases (e.g., `sonnet[1m]`) may be added. Check model-config page
3. **Nesting**: Currently prohibited. Feature request #32340 may change this
4. **Background behavior**: Permission pre-approval model may evolve
5. **CLAUDE_CODE_SUBAGENT_MODEL**: Behavior may change. Check model-config env vars table
6. **Agent Team comparison**: Agent Team is experimental — may become stable or get new capabilities
7. **CLAUDE.md 継承**: 下記「要注意エビデンス」参照

---

## 要注意エビデンス

### SubAgent の Context に CLAUDE.md は含まれるか

**結論 (2026-03-09)**: 公式ドキュメントに基づけば **含まれない**。

**公式ドキュメント原文** (sub-agents ページ, "Write subagent files" セクション):
> "The body becomes the system prompt that guides the subagent's behavior. **Subagents receive only this system prompt (plus basic environment details like working directory), not the full Claude Code system prompt.**"

CLAUDE.md は Claude Code の system prompt の一部であり、"full Claude Code system prompt" に含まれる。

**対照: Agent Team (Teammate)** (agent-teams ページ, "Context and communication" セクション):
> "Each teammate has its own context window. When spawned, a teammate loads the same project context as a regular session: **CLAUDE.md, MCP servers, and skills.**"
> "**CLAUDE.md works normally**: teammates read CLAUDE.md files from their working directory."

→ CLAUDE.md ロードが明記されているのは **Teammate のみ**。SubAgent については明記されていない。

**リサーチエージェントの誤報**: 2026-03-09 のリサーチエージェントが「SubAgent にも CLAUDE.md が読み込まれる」と報告したが、これは Teammate についての記述を SubAgent に混同した誤り。

**実動作の乖離可能性**: 公式ドキュメントの記述と実際の動作が異なる場合がある (Claude Code は活発に開発中)。次回更新時に実機テストで検証することを推奨。

**フレームワーク設計への影響**: sync-sdd は CLAUDE.md 非継承を前提として設計されている (SubAgent dispatch 時に必要なコンテキストを prompt で明示的に渡す)。この前提が正しい限り、影響はない。

### Model 優先順位は公式に未定義

**結論 (2026-03-09)**: agent-tool-reference.md の優先順位表は推定。

公式ドキュメントには model の優先順位を明示する表や記述がない。以下の情報から推定:
- Agent 定義の `model` フィールド: frontmatter table に記載、default は `inherit`
- `CLAUDE_CODE_SUBAGENT_MODEL`: model-config ページの環境変数テーブルに "The model to use for subagents" と記載
- dispatch 時の `model` パラメータ: Agent tool の built-in パラメータとして存在 (実際の動作から確認)
- #3903/#5456: Agent 定義の model が無視される報告 → dispatch 時パラメータが確実という推奨の根拠

次回更新時に公式ドキュメントに優先順位の明示が追加されていないか確認すること。
