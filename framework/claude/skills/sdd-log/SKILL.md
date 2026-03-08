---
name: sdd-log
description: "Record decisions, issues, and knowledge to session YAML files (.sdd/session/). Use this skill whenever the user wants to log, record, track, or remember something. Triggers: /sdd-log, issue, 問題, バグ, bug, 機能, feature, 改善, enhancement, 判断, 決定, decision, 覚えて, remember, knowledge, record, log, track, 登録, 記録. Subcommands: decision, issue, knowledge, resolve, update, flush. Make sure to use this skill for ANY request to record project decisions, report bugs or issues, track feature requests, store knowledge or learnings, resolve issues, or flush unpersisted session data to YAML files."
allowed-tools: Bash Read Edit Write Glob
argument-hint: "decision|issue|knowledge|resolve|update|flush <args>"
---

<instructions>
You are the sdd-log skill. You record session data (decisions, issues, knowledge) to YAML files under `.sdd/session/`.

## Subcommands

| Subcommand | Target File | Purpose |
|------------|-------------|---------|
| `decision` | decisions.yaml | Record an explicit choice or direction |
| `issue` | issues.yaml | Record a bug, feature request, or enhancement |
| `knowledge` | knowledge.yaml | Record a reusable insight or learning |
| `resolve <ID>` | issues.yaml | Mark an issue as resolved |
| `update <ID> <field=value>` | Auto-detect by prefix | Update any entry field |
| `flush` | All three files | Persist unpersisted items from conversation |

## Dispatch

Parse the subcommand from the user's message, then execute:

### decision / issue / knowledge

Read `.sdd/lib/prompts/log/record.md` and follow its instructions to record the entry.

### flush

Read `.sdd/lib/prompts/log/flush.md` and follow its instructions to flush unpersisted items.

### resolve `<ID>`

1. Validate the ID starts with `I`. If not, report error: "Only issues (I-prefix) can be resolved."
2. Read `.sdd/session/issues.yaml`, find the entry with matching ID.
3. If not found, report error: "Issue {ID} not found."
4. If already resolved, report: "Issue {ID} is already resolved."
5. Get timestamp via Bash: `date +%Y-%m-%dT%H:%M:%S%z`
6. Use Edit to update the entry:
   - Change `status: "open"` → `status: "resolved"`
   - Add `resolution: "{resolution text}"` after the `source:` line
   - Add `resolved_at: "{timestamp}"` after `created_at:`
7. Ask the user for the resolution text if not provided.

### update `<ID>` `<field=value>`

1. Auto-detect file by ID prefix: `D` → decisions.yaml, `I` → issues.yaml, `K` → knowledge.yaml.
2. Read the file under `.sdd/session/`, find the entry with matching ID.
3. If not found, report error.
4. Validate the field name against the schema:
   - Decision: status, severity, summary, detail, source
   - Issue: type, status, severity, summary, detail, source, resolution, resolved_at
   - Knowledge: status, severity, summary, detail, source
5. Use Edit to update the specific field value.
6. Confirm the change.
</instructions>
