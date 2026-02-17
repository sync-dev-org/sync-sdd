# Language Profile: Rust

## Core Technologies
- **Language**: Rust (latest stable)
- **Package Manager**: Cargo
- **Runtime**: Native (compiled)

## Development Standards

### Type Safety
Compiler-enforced type safety. Minimize `unsafe` blocks; justify each use in comments.

### Code Quality
clippy for linting. rustfmt for formatting.

### Testing
Built-in `cargo test`. Unit tests in `#[cfg(test)]` modules within source files. Integration tests in `tests/` directory.

## Structure Conventions

### Naming
- **Files**: `snake_case.rs`
- **Types/Traits**: `PascalCase`
- **Functions/Methods**: `snake_case`
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Crates**: `kebab-case` (Cargo) / `snake_case` (code)

### Import Organization
```rust
// Standard library
use std::collections::HashMap;

// External crates
use serde::{Deserialize, Serialize};

// Crate-internal
use crate::models::User;
use super::helpers;
```

### Module Structure
- `mod.rs` or filename-as-module pattern
- `lib.rs` for library crate root
- `main.rs` for binary crate entry point
- Feature flags via `Cargo.toml` `[features]`

## Common Commands
```bash
# Dev: cargo run
# Build: cargo build --release
# Test: cargo test
# Lint: cargo clippy -- -D warnings
# Format: cargo fmt
# Check: cargo check
```

## Suggested Permissions
```
Bash(cargo:*)
Bash(rustup:*)
Bash(rustc:*)
```

## Version Management
`version` field in `Cargo.toml`. Workspace versioning for multi-crate projects.
