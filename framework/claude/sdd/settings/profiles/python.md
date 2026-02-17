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
Bash(uv:*)
```

## Version Management
hatch-vcs or setuptools-scm for automatic version tracking from git tags.
