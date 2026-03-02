# Language Profile: Python

## Core Technologies
- **Language**: Python 3.12+
- **Package Manager**: uv (required)
- **Runtime**: CPython
- **Project Config**: `pyproject.toml` (uv-managed)

## Development Standards

### Type Safety
Type hints required for all public interfaces. Type checker is project-specific (configure in `pyproject.toml` if needed).

### Code Quality
Ruff for linting and formatting. PEP 8 compliance.

### Data Modeling
Prefer pydantic over dataclasses. pydantic is the default choice for data classes.
For SQL/ORM, prefer SQLModel (pydantic-compatible).

### Testing
pytest with coverage requirements.

## Structure Conventions

### Naming
- **Files**: `snake_case.py`
- **Classes**: `PascalCase`
- **Functions/Methods**: `snake_case`
- **Constants**: `UPPER_SNAKE_CASE`
- **Packages**: `lowercase` (no underscores preferred)

### Import Organization
```python
# Standard library
import os
from pathlib import Path

# Third-party
import requests

# Local
from .module import something
```

### Module Structure
- `__init__.py` for packages
- `py.typed` marker for typed packages
- `src/` layout recommended for libraries

## Project Config (`pyproject.toml`)

uv uses `[dependency-groups]` (PEP 735) for dev dependencies, not `[project.optional-dependencies]`.

```toml
[project]
name = "my-package"
requires-python = ">=3.12"
dependencies = [
    "httpx",
]

[dependency-groups]
dev = [
    "pytest",
    "ruff",
    "pytest-cov",
]

[tool.ruff]
line-length = 88

[tool.pytest.ini_options]
testpaths = ["tests"]
```

- Lockfile: `uv.lock` (commit to git)
- Virtual env: `.venv/` (managed by uv, gitignore)

## Common Commands
```bash
# Init: uv init
# Add dep: uv add {package}
# Add dev dep: uv add --group dev {package}
# Sync env: uv sync
# Run: uv run python -m {package}
# Build: uv build
# Test: uv run pytest
# Lint: uv run ruff check .
# Format: uv run ruff format .
```

## Suggested Permissions
```
Bash(uv *)
```

## Version Management
hatch-vcs or setuptools-scm for automatic version tracking from git tags.

## Known Pitfalls

Collected from real projects. Lead transfers only items relevant to the project's dependencies/domain into `tech.md ## Pitfalls`.

### SQLModel / SQLAlchemy

**Phantom Tables — `create_all` は必ず `tables=` でフィルタする**
- Don't: `SQLModel.metadata.create_all(engine)` — global metadata が import 済み全モデルを含むため、別パッケージのテーブルまで作られる
- Do: `SQLModel.metadata.create_all(engine, tables=[Model.__table__ for Model in MY_MODELS])` — 回帰テスト `len(MY_TABLES) == N` も推奨

**DetachedInstanceError — フィクスチャから ORM オブジェクトを返さない**
- Don't: `return user` (Session 終了後に属性アクセスで DetachedInstanceError)
- Do: `return user.id, org.slug` — スカラー値を抽出して返す

**Relationship 型注釈に PEP 604 union を使えない**
- Don't: `created_by: "User | None" = Relationship()` — SQLAlchemy string resolver が `|` を解釈できない
- Do: `created_by: "User" = Relationship(...)` + FK 側で `Field(default=None)` で nullable を表現

**同一テーブルへの複数 FK → AmbiguousForeignKeysError**
- Do: `sa_relationship_kwargs={"foreign_keys": "Model.column"}` を文字列参照で指定

**SQLite naive datetime と aware datetime の比較で TypeError**
- Don't: `if expires_at < datetime.now(timezone.utc):` — SQLite は naive datetime を返す場合がある
- Do: `if dt.tzinfo is None: dt = dt.astimezone()` で比較前に正規化

**SQLite 動的型付け — TDD RED が効かないケース**
- SQLite は TEXT カラムに integer を黙って受け入れる。型変更の TDD RED フェーズで失敗を観測できない場合がある。型安全性は Python/SQLModel 層でのみ保証される

**テーブル数 exact count アサーションは壊れやすい**
- Don't: `assert len(tables) == 4`
- Do: `assert "tablename" in tables` — cross-spec でモデル追加時に壊れない

### FastAPI / Starlette

**StaticFiles は symlink をデフォルトで 404 にする**
- Don't: `StaticFiles(directory=path)` — symlink ファイルに 404 を返す
- Do: `StaticFiles(directory=path, follow_symlink=True)` (Starlette 0.20+)

**import 時 fail-fast する config は pytest 収集を壊す**
- Don't: `tests/conftest.py` で env var を設定 (モジュール import が先に走るため手遅れ)
- Do: **root-level conftest.py** で `os.environ.setdefault("KEY", "value")` — pytest 収集前に実行される

### pydantic-ai (OpenRouter 経由)

**PromptedOutput が最も安定 — OpenRouter 経由限定の知見**
- OpenRouter 経由で検証: ToolOutput/NativeOutput はプロバイダにより 502/404 が出る。PromptedOutput が最も安定。直接 API (公式エンドポイント) では未検証。OpenRouter の中継レイヤーに起因する可能性あり

**Retry はフレームワークに委譲**
- Don't: アプリ層でリトライロジックを追加
- Do: pydantic-ai の HTTP Transport 層 (429/timeout/5xx) + Agent validation 層に委譲

**Agent インスタンスは使い捨て**
- Don't: Agent を再利用 (キャッシュにゴースト状態が残る)
- Do: create → use → discard。プーリングしない

### pytest / mock

**mock の side_effect lambda は `*a, **kw` にする**
- Don't: `Mock(side_effect=lambda e: None)` — 将来の kwarg 追加で TypeError
- Do: `Mock(side_effect=lambda *a, **kw: None)`

**sys.modules 操作の罠 (3パターン)**
- `setdefault("pkg", mock)`: import 済みだと no-op
- `sys.modules["pkg"] = mock` + reload 後に未復元: `__spec__` 欠落で後続テスト汚染
- mock exception の identity 不一致: `except` は import 時のオブジェクト identity で照合
- Do: (1) save → (2) replace → (3) reload → (4) 明示的 `mod.attr = mock` → (5) **即座に** sys.modules 復元 → (6) atexit で最終 reload

**RuntimeWarning "coroutine was never awaited" は GC 時に発火**
- Don't: `pytest.warns(RuntimeWarning)` (テスト実行中ではなく GC 時に発火するため効かない)
- Do: `@pytest.mark.filterwarnings("ignore::RuntimeWarning")` をテストに付与

### asyncio / スレッド境界

**async/sync 境界の streaming には queue.Queue + asyncio.to_thread**
- Don't: asyncio.Queue (worker スレッドにイベントループがないため put_nowait が QueueFull で黙って失敗)
- Do: Worker は `queue.put(item)` (blocking)、Consumer は `await asyncio.to_thread(q.get)`

**Queue streaming の early-exit — 3ステップ cleanup**
- (1) `stop_event.set()` → (2) `get_nowait()` ループで drain → (3) `await worker_task`。drain が join より前でないと worker が put() でデッドロック

**Python 例外の except 順序 (MRO)**
- Don't: 親クラスの except を先に書く (サブクラスが吸われて到達不能)
- Do: サブクラス例外は常に親クラスより先に catch

### 外部 SDK バージョン地雷

**MagicMock は SDK breaking change を隠す**
- MagicMock は存在しない属性を黙って受け入れるため、SDK のメソッドリネームや引数変更をユニットテストで検出できない。実 API テストまたは SDK changelog の定期監視が必要

**型注釈を信じるな、実行時挙動を信じる**
- 例: google-genai の `generate_content_stream()` は型注釈 AsyncIterator だが実行時は coroutine を返す。await してから async for

### ruff

**`src` は `[tool.ruff]` トップレベルに配置**
- Don't: `[tool.ruff.lint]` 下に `src = [...]`
- Do: `[tool.ruff]` 直下に `src = ["src", "tests"]`

**CSS/HTML ファイルに invalid-syntax エラーを出す**
- Do: `ruff check src/ tests/` のように Python ファイルのみに絞って実行

### GitHub Actions / CI publish

**hatch-vcs の `_version.py` は ruff exclude 必須**
- `uv sync` が CI 上で `_version.py` を生成し、`ruff check src/` が拾って I001 (import sort) で失敗する
- Do: `pyproject.toml` の `[tool.ruff]` に `exclude = ["src/{package}/_version.py"]` を追加

**optional deps のテストは CI で `--ignore` する**
- テストファイルが `import speechflow.engines.kokoro` 等でモジュールを直接インポートすると、モジュールレベルの `import torch` がトリガーされ CI で `ModuleNotFoundError`
- `engines/__init__.py` の import guard は `__init__.py` 経由のアクセスのみを保護し、直接モジュールインポートは保護しない
- Do: `uv run pytest --ignore=tests/unit/test_xxx.py` で optional deps 依存テストを除外
- sys.modules mock 注入パターンのテストでも、モジュールインポート自体が collection 時に失敗するため回避不可

**`fetch-depth: 0` は hatch-vcs 必須**
- hatch-vcs は `git describe --tags` でバージョンを算出するため、shallow clone ではバージョンが `0.0.0` になる
- Do: `actions/checkout@v4` に `fetch-depth: 0` を指定

### htmx + Alpine.js (Python fullstack)

**htmx settling が Alpine の x-show state を破壊する**
- innerHTML swap 後の settling (20ms) が安定 ID を持つ Alpine コンポーネントの state を初期値にリセットする
- Don't: swap 対象内の Alpine コンポーネントに安定 ID を付与
- Do: swap 対象内の `role="menu"` 等の要素から ID を除去
