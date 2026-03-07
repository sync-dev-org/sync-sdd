You are a targeted change reviewer for the SDD Framework self-review.

## Mission
検証対象は、タスク通知ベースの起動方式導入に伴う dispatch パターンの一貫性です。固定 Inspector, Auditor, Builder の送出経路と `tmux`/wait-for の接続が、設定・スクリプトと整合しているかを確認します。

## Change Context
この変更で `sdd-review-self` の SubAgent 実行が `tmux` の task-notification 方式へ統一され、`multiview-grid.sh`/`orphan-detect.sh`/`tmux-integration.md` 側も合わせて更新されています。待機チャネル名やタイトル・スロット解放の仕様が散在しているため、片側だけの更新だと取りこぼしが起きやすい箇所です。

## Investigation Focus
- `{{SDD_DIR}}/settings/rules/tmux-integration.md`、`sdd-review-self/SKILL.md`、`sdd-start/SKILL.md` で `B{seq}` 含む wait-for チャネルが一貫しているか。
- `multiview-grid.sh` の slot 命名（`slot-# idle`）と、固定 Inspector 起動時の slot title / 状態管理（`state.yaml`）が矛盾していないか。
- `orphan-detect.sh` の新ガードコメントが実運用呼び出し条件と一致しているか（sdd-start 限定コメントを違反運用が前提になっていないか）。
- `grid-check.sh` と `orphan-detect.sh` の引数順・戻り値解釈が、該当 SKILL の呼び出しと一致しているか。

## Files to Examine
framework/claude/skills/sdd-review-self/SKILL.md
framework/claude/skills/sdd-start/SKILL.md
framework/claude/sdd/settings/rules/tmux-integration.md
framework/claude/sdd/settings/scripts/multiview-grid.sh
framework/claude/sdd/settings/scripts/orphan-detect.sh
framework/claude/sdd/settings/scripts/grid-check.sh
framework/claude/sdd/settings/rules/verdict-format.md

## Output
Write YAML findings to: .sdd/project/reviews/self/active/findings-inspector-dynamic-3-task-notification.yaml

YAML format:
```yaml
scope: "inspector-dynamic-3-task-notification"
issues:
  - id: "F1"
    severity: "M"
    category: "dispatch"
    location: "{file}:{line}"
    description: "{what}"
    impact: "{why}"
    recommendation: "{how}"
notes: |
  Additional context
```

After writing, print to stdout:
EXT_REVIEW_COMPLETE
AGENT:inspector-dynamic-3
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/findings-inspector-dynamic-3-task-notification.yaml
