# Compact Pipe-Delimited Format (CPF)

> **Legacy format** - retained for historical reference only. Current inter-agent communication uses YAML format defined in `verdict-format.md`.

Token-efficient structured text format formerly used for inter-agent communication (superseded by YAML).

## Notation Rules

| Element | Format | Example |
|---------|--------|---------|
| Metadata | `KEY:VALUE` (no space) | `VERDICT:CONDITIONAL` |
| Structured row | `field1\|field2\|field3` | `H\|ambiguity\|Spec 1\|not quantified` |
| Freeform text | Plain lines (no decoration) | `Domain research suggests...` |
| List identifiers | `+` separated | `rulebase+consistency` |
| Empty sections | Omit header entirely | _(do not output)_ |
| Severity codes | C/H/M/L | C=Critical, H=High, M=Medium, L=Low |
| Compliance codes | OK/NG/UNCERTAIN | Compliance Inspector 専用。仕様準拠判定に使用 (D99)。Citation 必須 |
| Category values | Inspector-specific | Not a global enum; each Inspector defines relevant categories (e.g., `security-concern`, `ambiguity`, `dead-export`) |

## Writing CPF

- Section headers (`ISSUES:`, `NOTES:`, etc.) followed by one record per line
- No decoration characters (`- [`, `] `, `: `, ` - `)
- Omit empty sections (do not output the header)
- No spaces in metadata lines (`KEY:VALUE`)

## Parsing CPF

```
1. Line starts with known keyword + `:` → metadata or section start
2. Lines under a section → split by `|` to extract fields
3. Field containing `+` → split as identifier list
4. Section not present → no data of that type (not an error)
```

## Minimal Example

```
VERDICT:GO
SCOPE:my-feature
ISSUES:
M|ambiguity|Spec 1.AC1|"quickly" not quantified
NOTES:
No critical issues found
```
