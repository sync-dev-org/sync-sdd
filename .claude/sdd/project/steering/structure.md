# Project Structure

## Organization Philosophy

配布対象のフレームワーク（`framework/`）と、自身が使用するローカル環境（`.claude/`）を分離。`framework/` が開発対象、`.claude/` は dogfooding 環境（install.sh でコピーされる）。

## Directory Patterns

### Framework Source（開発対象）
**Location**: `framework/claude/`
**Purpose**: install.sh が配布する全ファイルのソース
**構成**:
- `CLAUDE.md` — フレームワーク本体（Lead指示書、ワークフロー定義）
- `skills/sdd-*/SKILL.md` — 9つのスキル定義
- `agents/sdd-*.md` — 22のエージェント定義
- `sdd/settings/` — ルール、テンプレート、プロファイル
- `settings.json` — Agent Teams有効化設定

### Settings
**Location**: `framework/claude/sdd/settings/`
**Purpose**: フレームワーク管理下の設定ファイル（ユーザーが直接編集しない）
**構成**:
- `rules/` — 設計原則、レビュー基準、タスク生成ルール、CPFフォーマット
- `templates/` — steering/specs/knowledge のテンプレート
- `profiles/` — 言語プロファイル（Python, TypeScript, Rust）

### Distribution
**Location**: プロジェクトルート
**Purpose**: インストーラーとバージョン管理
**構成**:
- `install.sh` — インストール/アップデート/アンインストール
- `VERSION` — 現在のバージョン番号
- `README.md` — ドキュメント

## Naming Conventions

- **Skills**: `sdd-{verb/noun}` (kebab-case) → `SKILL.md` ファイル
- **Agents**: `sdd-{role}[-{specialization}].md` (kebab-case)
- **Rules**: `{topic}.md` (kebab-case)
- **Templates**: ディレクトリで分類 (`steering/`, `specs/`, `knowledge/`)
- **Profiles**: `{language}.md`

## Import Organization

N/A（Markdownベースのため import なし。Cross-reference は `{{SDD_DIR}}` パス変数で解決）

## Code Organization Principles

- **1ファイル1責務**: 各スキル/エージェントは1つの `.md` ファイルに完結
- **テンプレート駆動**: steering/specs/knowledge の生成はテンプレートから
- **パス変数**: `{{SDD_DIR}}` で SDD ルートを抽象化
- **開発対象 ≠ 実行環境**: `framework/` を編集し、`.claude/` に install で反映

---
_Document patterns, not file trees. New files following patterns shouldn't require updates_
