You are a targeted change reviewer for the SDD Framework self-review.

## Mission
検証は、CPF/Markdown 由来のレビュー資産名から YAML 形式への移行で、実行時参照と保存先が一致しているかを確認することに限定します。

## Change Context
今回の変更で `verdicts.md`・`verdict.cpf`・`findings CPF` といった旧参照が大幅に `verdicts.yaml` / `findings-inspector-*.yaml` へ更新されています。ドキュメント側と実行側の接続を合わせるため、未更新の参照が残るとレビュー保存失敗や Inspector 読み取り漏れが起きます。

## Investigation Focus
1. `framework/claude/CLAUDE.md`、`framework/claude/settings.json`、`framework/claude/sdd/settings/rules/verdict-format.md` 間で、保存先と命名規則が一致しているか
2. self/通常 review 両方の SKILL とテンプレートで、旧ファイル名 (`.cpf`, `verdict.cpf`, `verdicts.md`) の使用が残存していないか
3. install.sh が配布する対象ファイル（特に `.sdd/settings/rules/cpf-format.md`）と実運用の期待フォーマットが矛盾していないか
4. 既存のレビュー実行パスから `findings-inspector-{name}.yaml` を読む実装にズレがないか

## Files to Examine
framework/claude/CLAUDE.md
framework/claude/settings.json
framework/claude/sdd/settings/rules/verdict-format.md
framework/claude/sdd/settings/rules/cpf-format.md
framework/claude/sdd/settings/templates/review-self/inspector-compliance.md
framework/claude/sdd/settings/templates/review-self/inspector-consistency.md
framework/claude/sdd/settings/templates/review-self/inspector-flow.md
framework/claude/skills/sdd-review/SKILL.md
framework/claude/skills/sdd-review-self/SKILL.md
install.sh

## Output
Write YAML findings to: .sdd/project/reviews/self/active/findings-inspector-dynamic-1-template-migration.yaml

YAML format:
```yaml
scope: "inspector-dynamic-1-template-migration"
issues:
  - id: "F1"
    severity: "H"
    category: "{category}"
    location: "{file}:{line}"
    summary: "{one-line summary}"    detail: "{what}"
    impact: "{why}"
    recommendation: "{how}"
notes: |
  Additional context
```
