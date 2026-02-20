# Research & Design Decisions — release-automation (Revision)

## Summary
- **Feature**: `release-automation`
- **Discovery Scope**: Extension (adding post-release verification step)
- **Key Findings**:
  - hatch-vcs は editable install のメタデータをキャッシュするため、git tag 作成後も `importlib.metadata.version()` が旧バージョンを返す（既知の "footgun"）
  - `uv sync --reinstall-package {pkg}` で対象パッケージのメタデータを強制再構築できる。`uv pip install -e .` は不正確
  - `git describe --tags --abbrev=0` は全エコシステム共通のタグレベル検証に利用可能

## Research Log

### hatch-vcs メタデータキャッシュ問題

- **Context**: taskflow v0.3.0 リリース時に Lead が `importlib.metadata.version("taskflow")` で確認したところ `0.2.1.dev0+g335b23266.d20260220` が返された。タグ v0.3.0 は正しく作成済みだったにもかかわらず、旧バージョンが表示された。
- **Sources Consulted**:
  - [maresb/hatch-vcs-footgun-example](https://github.com/maresb/hatch-vcs-footgun-example) — hatch-vcs の "footgun" 問題を詳細に解説
  - [ofek/hatch-vcs#69](https://github.com/ofek/hatch-vcs/issues/69) — tag version と package version の不一致報告
  - [astral-sh/uv#7997](https://github.com/astral-sh/uv/issues/7997) — git tag 変更時に uv キャッシュが更新されない問題
  - [astral-sh/uv#9192](https://github.com/astral-sh/uv/issues/9192) — `--reinstall-package` でプロジェクト自体の再インストール対応
  - [uv caching docs](https://docs.astral.sh/uv/concepts/cache/) — uv のキャッシュ戦略と `--reinstall` フラグ
- **Findings**:
  - hatch-vcs は `setuptools-scm` を内部で使用し、git tag からバージョンを算出する
  - editable install (`-e .`) の場合、`_version.py` はインストール時にのみ生成される
  - git tag を追加してもキャッシュ済みメタデータは自動更新されない
  - `uv sync --reinstall-package {pkg}` がパッケージの再構築を強制する正しい方法
  - `uv pip install -e .` は editable install のやり直しであり、プロジェクト管理下の sync とは異なる操作（ロックファイルとの整合性が崩れるリスク）
- **Implications**:
  - Python (hatch-vcs) エコシステムでは、タグ作成後・main 復帰後にパッケージメタデータの再構築ステップが必須
  - uv.lock の存在で `uv sync` 系コマンドの使用を検出可能
  - pyproject.toml の `[project] name` フィールドからパッケージ名を取得する必要がある

### エコシステム別バージョン検証方法

- **Context**: 全エコシステムでリリース後の検証手段を特定する必要がある
- **Sources Consulted**: 各エコシステムのバージョン管理ドキュメント
- **Findings**:
  - **Git レベル**: `git describe --tags --abbrev=0` で最新タグ名を取得し、期待値と照合（全エコシステム共通）
  - **Python (hatch-vcs)**: `uv sync --reinstall-package {pkg}` 後に `{runtime} -c "import importlib.metadata; print(importlib.metadata.version('{pkg}'))"` で検証。runtime は steering の tech.md から取得（例: `uv run python`）
  - **Python (standard)**: `pyproject.toml` の `[project] version` フィールドを直接読み取り
  - **TypeScript**: `package.json` の `version` フィールドを直接読み取り
  - **Rust**: `Cargo.toml` の `[package] version` フィールドを直接読み取り
  - **SDD Framework**: `VERSION` ファイルの内容を直接読み取り
  - **Other**: `git describe --tags --abbrev=0` のみ（メタデータファイルがユーザー定義のため）
- **Implications**: メタデータファイルの直読みで十分なエコシステムと、ランタイム経由の検証が必要なエコシステム（hatch-vcs）を区別する

### uv.lock による uv 環境検出

- **Context**: hatch-vcs の検証ステップで `uv sync` が利用可能か判定する必要がある
- **Sources Consulted**: [uv locking and syncing docs](https://docs.astral.sh/uv/concepts/projects/sync/)
- **Findings**:
  - `uv.lock` ファイルの存在が uv 管理プロジェクトの指標
  - `uv.lock` がある場合、`uv sync --reinstall-package` が安全に使用可能
  - `uv.lock` がない場合は `pip install -e .` 等の代替手段が必要だが、本フレームワークのスコープでは uv 環境を前提とする
- **Implications**: 検出ロジックに `uv.lock` 存在チェックを追加

## Design Decisions

### Decision: メタデータ再構築に `uv sync --reinstall-package` を採用

- **Context**: hatch-vcs プロジェクトでタグ作成後のメタデータ更新方法
- **Alternatives Considered**:
  1. `uv pip install -e .` — editable install のやり直し
  2. `uv sync --reinstall` — 全パッケージの再インストール
  3. `uv sync --reinstall-package {pkg}` — 対象パッケージのみ再インストール
- **Selected Approach**: Option 3 (`uv sync --reinstall-package {pkg}`)
- **Rationale**: 対象パッケージのみ再構築するため高速。ロックファイルとの整合性を維持。ユーザー（taskflow インシデント）により正しい方法として確認済み
- **Trade-offs**: uv 管理プロジェクト前提（uv.lock 必須）。非 uv 環境では別途対応が必要だが、フレームワークのターゲット環境では問題なし
- **Follow-up**: パッケージ名を pyproject.toml の `[project] name` から動的に取得する実装が必要

### Decision: 検証ステップの配置を Step 8 と Step 9 の間に設定

- **Context**: 検証は全 git 操作完了後、レポート出力前に実行すべき
- **Alternatives Considered**:
  1. Step 9（Report）に統合 — 検証失敗時の報告が混在
  2. Step 8 の直後に独立ステップとして追加 — 明確な責務分離
- **Selected Approach**: Option 2（独立ステップ）
- **Rationale**: 検証は成功/失敗の判定を含む独立した操作。Report は常に成功ステータスを前提としているため、責務が異なる。検証失敗時は警告を含むレポートに切り替える
- **Trade-offs**: ステップ数が増える（Step 9 → Step 10 にずれる）が、責務の明確さが勝る

## Risks & Mitigations

- **Risk**: uv.lock が存在しない hatch-vcs プロジェクト — **Mitigation**: uv.lock 不在時は警告を出して検証をスキップ（git タグ検証のみ実施）
- **Risk**: pyproject.toml の `[project] name` フィールドが存在しない — **Mitigation**: name 取得失敗時は警告を出して Python ランタイム検証をスキップ（git タグ検証のみ実施）
- **Risk**: 検証失敗時にリリースが中途半端な状態 — **Mitigation**: 検証は git 操作完了後のため、リリース自体は完了している。検証失敗は警告として報告し、手動確認を促す

## References

- [maresb/hatch-vcs-footgun-example](https://github.com/maresb/hatch-vcs-footgun-example) — hatch-vcs の version footgun 問題と解決策
- [astral-sh/uv#7997](https://github.com/astral-sh/uv/issues/7997) — git tag 変更時の uv キャッシュ問題
- [astral-sh/uv#9192](https://github.com/astral-sh/uv/issues/9192) — `--reinstall-package` でプロジェクト自体の再インストール
- [uv sync docs](https://docs.astral.sh/uv/concepts/projects/sync/) — uv sync のオプションとロックファイル管理
- [uv caching docs](https://docs.astral.sh/uv/concepts/cache/) — uv のキャッシュ戦略
