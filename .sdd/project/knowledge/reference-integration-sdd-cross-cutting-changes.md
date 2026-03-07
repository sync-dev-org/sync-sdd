# Reference: Cross-Cutting Changes in SDD Frameworks

## Metadata

| Field | Value |
|-------|-------|
| Category | integration |
| Keywords | SDD, cross-cutting, spec-driven, multi-spec, revision, architecture, framework comparison |
| Last Verified | 2026-02-24 |
| Source | Multiple (see Sources section) |

## Overview

**AI SDD フレームワークにおける横断的変更の扱い**

複数の spec に跨る変更（例: 共有モデルの型変更、インフラ層の刷新）をどう管理するかは、AI SDD フレームワーク全体で **未解決の課題** として認識されている。2026年2月時点の主要フレームワーク調査結果をまとめる。

## Quick Reference

### フレームワーク横断的変更対応の比較

| フレームワーク | 横断的変更の対応 | ファイルオーナーシップ | 評価 |
|---|---|---|---|
| **Kiro** (AWS) | 仕組みなし。各spec独立。`#spec` で参照可能だが依存管理なし | なし | 未対応 |
| **spec-kit** (GitHub) | Constitution（上位ルール）で制約するのみ | 暗黙的（フェーズ別） | 未対応 |
| **OpenSpec** (Fission-AI) | `specs/`(正) + `changes/`(差分) の delta 方式。`project.md` がグローバル制約 | delta ベース分離 | 部分的 |
| **Tessl** | 1:1 spec-to-file マッピング。複数ファイル変更に構造的に不向き | 明確（human=spec, AI=code） | 構造的に不向き |
| **Spec Kitty** | WP（WorkPackage）依存宣言 + git worktree 隔離 | レビューゲート | 部分的 |
| **cc-sdd (rhuss)** | `/sdd:evolve` でドリフト検知・修復 | なし | 事後対応のみ |
| **cc-sdd (gotalab)** | テンプレート統一 + validation gap チェック | なし | 手続き的 |
| **BMAD** | 実装前のマルチエージェント計画（Analyst/PM/Architect） | ロール別 | 予防的、実行時は未対応 |
| **本 SDD** | Roadmap wave + steering + spec.yaml phase gate + files_created | 明示的（ロール別） | 最も構造化、ただし横断仕組みなし |

### spec フォーマット比較

| フレームワーク | spec 構成 | 多spec管理 |
|---|---|---|
| Kiro | requirements.md + design.md + tasks.md (EARS) | フォルダ別、独立 |
| spec-kit | Constitution + Spec + Plan + Tasks (MD) | ブランチ別 |
| OpenSpec | specs/(正) + changes/(delta) | capability フォルダ |
| Tessl | .spec.md (YAML frontmatter + [@test]) | 1:1 ファイル対応 |
| Spec Kitty | spec/plan/tasks + WP files (lane frontmatter) | worktree 隔離 |
| 本 SDD | spec.yaml + design.md + tasks.yaml + reviews/ | Roadmap wave |

## Key Points

### 業界コンセンサス: 未解決の課題

Martin Fowler (2025):
> "SDD tools have not yet addressed cross-spec coordination, calling it an open problem."

InfoQ Enterprise SDD:
> "When your feature requires changes across six different repositories, where does the spec live?"

spec-kit Discussion #152 (GitHub):
- spec 実装後に現実が断片化する問題を議論
- 提案: spec の定期的 compaction / rollup、capability ベースの構造化、target-state spec
- **いずれも未実装**

### OpenSpec の delta 方式（最も構造的なアプローチ）

```
openspec/
  specs/           ← source of truth（現在の正）
    auth-login/spec.md
    payment/spec.md
  changes/         ← 変更提案（隔離）
    add-oauth-login/
      proposal.md  ← 理由とスコープ
      design.md    ← 技術的アプローチ
      specs/       ← 影響を受ける spec への DELTA
```

- 変更完了後 `/opsx:archive` で delta を正の spec にマージ
- cross-spec 依存宣言の仕組みはないが、delta の隔離により安全に変更を管理
- ADDED / MODIFIED / REMOVED の明示的なマーキング

### 本 SDD フレームワークの強み

他フレームワークに対して既に持っている差別化要素:
1. **Roadmap + Wave**: 複数 spec の実行順序制御
2. **spec.yaml phase gate**: 状態管理（initialized → design-generated → implementation-complete）
3. **implementation.files_created**: ファイルオーナーシップの明示的追跡
4. **Steering**: グローバル制約（product.md, tech.md, structure.md）
5. **Artifact Ownership**: Lead/Architect/Builder のロール別所有権

### 本 SDD フレームワークの課題

横断的変更に対する公式な仕組みがない:
- 1つの論理的変更を複数 spec にルーティングする標準手順がない
- `files_created` が spec 間で重複する場合の解決策がない
- 横断的変更の設計レビュー（全影響 spec を俯瞰した整合性チェック）の仕組みがない

## Common Gotchas

| 問題 | 影響 | 緩和策 |
|------|------|--------|
| 横断的変更を1つの spec で扱う | 他 spec の files_created を侵害（artifact ownership 違反） | spec 間で明示的な合意 or フレームワーク拡張 |
| 複数 spec を個別に revise | 4パイプライン実行でコスト大。中間状態でテストが壊れる | 依存順に実行。model → logic → consumer の順序遵守 |
| 横断的変更を spec 外で直接実装 | spec が嘘になる（ドリフト） | 実装後に必ず spec を更新 |

## 今回の判断記録

### コンテキスト
Task テーブルの `position: int` → Fractional Indexing (`position: str`) への変更。4つの spec（project-setup, task-crud, kanban-board, todo-list）に跨る。

### 判断
**C: 4 spec 個別 revise** を選択。

理由:
- "spec が唯一の真実" の原則を遵守するため
- artifact ownership の既存ルールを破らない
- 横断的変更の仕組みは別途設計する（この判断は暫定的措置）
- 依存順に実行することで中間状態のリスクを管理: project-setup → task-crud → kanban-board + todo-list

### 今後の検討課題
- OpenSpec の delta 方式を参考にした cross-cutting spec type の導入
- `files_created` の cross-spec 参照メカニズム
- 横断的設計レビュー（影響を受ける全 spec を俯瞰した整合性チェック）の仕組み

## Sources

- [Martin Fowler: Understanding SDD — Kiro, spec-kit, and Tessl](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)
- [spec-kit Discussion #152: Evolving Specs](https://github.com/github/spec-kit/discussions/152)
- [InfoQ: Enterprise Spec-Driven Development](https://www.infoq.com/articles/enterprise-spec-driven-development/)
- [Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec) / [OpenSpec Guide](https://redreamality.com/garden/notes/openspec-guide/)
- [Priivacy-ai/spec-kitty](https://github.com/Priivacy-ai/spec-kitty)
- [gotalab/cc-sdd](https://github.com/gotalab/cc-sdd) / [rhuss/cc-sdd](https://github.com/rhuss/cc-sdd)
- [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)
- [Kiro Documentation](https://kiro.dev/docs/specs/)
- [Tessl: 10 Things About Specs](https://tessl.io/blog/spec-driven-development-10-things-you-need-to-know-about-specs/)
- [ThoughtWorks: SDD Unpacking 2025](https://www.thoughtworks.com/en-us/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices)
