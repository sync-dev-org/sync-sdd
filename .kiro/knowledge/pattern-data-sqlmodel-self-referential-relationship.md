# Pattern Knowledge: SQLModel Self-Referential Relationship

---
**Purpose**: Document recommended patterns and best practices discovered through development experience.

**Usage**:
- Record successful approaches that should be replicated.
- Provide guidance for common scenarios.
- Enable proactive pattern application during `sdd-review-*` commands.

**Naming Convention**: `pattern-{category}-{name}.md`
---

## Metadata

| Field | Value |
|-------|-------|
| Category | data |
| Keywords | SQLModel, SQLAlchemy, self-referential, relationship, type annotation, Optional, parent-child, hierarchy |
| Applicable Phases | design, impl |

## Pattern Summary

**SQLModel 自己参照リレーションシップの型アノテーション制約**

SQLModel + SQLAlchemy 2.0 で自己参照（親子階層）リレーションシップを実装する際、型アノテーションに `| None` や `Optional[...]` を使用するとエラーになる。Nullable 性は FK フィールドで制御し、リレーションシップ属性は単純な文字列参照で記述する。

## Problem Context

### When to Apply
- SQLModel で親子階層（Organization, Category, Folder など）を実装する場合
- 自己参照 FK（parent_id → same_table.id）を持つエンティティを定義する場合
- SQLAlchemy 2.0 + SQLModel 0.0.22 以降の環境

### Symptoms Without This Pattern
- `TypeError: unsupported operand type(s) for |: 'str' and 'NoneType'` が発生
- `InvalidRequestError: expression "relationship("Optional['Entity']")" seems to be using a generic class` が発生
- 設計書通りに実装してもモデル定義時にエラー

## Solution

### Core Principle

**リレーションシップの Nullable 性は FK フィールドで決まる**

FK フィールド（例: `parent_id: int | None`）が `None` を許容すれば、対応するリレーションシップ属性も実行時に `None` になりうる。リレーションシップ属性の型アノテーションに `| None` や `Optional` を明示する必要はない（むしろ動作しない）。

### Implementation Approach

```python
from sqlmodel import Field, Relationship, SQLModel

class Organization(SQLModel, table=True):
    __tablename__ = "organizations"

    id: int | None = Field(default=None, primary_key=True)
    name: str
    parent_id: int | None = Field(
        default=None,
        foreign_key="organizations.id",
        index=True
    )

    # Self-referential relationships
    children: list["Organization"] = Relationship(
        back_populates="parent",
        sa_relationship_kwargs={"lazy": "selectin"},  # N+1 prevention
    )
    parent: "Organization" = Relationship(
        back_populates="children",
        sa_relationship_kwargs={"remote_side": "Organization.id"},
    )
```

### Key Points
1. **FK フィールドで Nullable 制御**: `parent_id: int | None` が None を許容
2. **リレーションシップは単純型**: `parent: "Organization"` と記述（`| None` なし）
3. **remote_side 必須**: 自己参照では方向を明示するため `remote_side` を指定
4. **lazy="selectin" 推奨**: children 側に指定して N+1 クエリを防止

## Examples

### Good Example
```python
# FK フィールドで Nullable を制御
parent_id: int | None = Field(default=None, foreign_key="organizations.id")

# リレーションシップは単純な文字列参照
parent: "Organization" = Relationship(
    back_populates="children",
    sa_relationship_kwargs={"remote_side": "Organization.id"},
)
```

### Anti-Pattern (Avoid)
```python
# ❌ 文字列内の | は演算子として解釈されない
parent: "Organization | None" = Relationship(...)

# ❌ TypeError: 文字列と None の | 演算不可
parent: "Organization" | None = Relationship(...)

# ❌ SQLAlchemy がジェネリック型として拒否
parent: Optional["Organization"] = Relationship(...)
```

## Application Checklist

- [ ] FK フィールドに `int | None` を指定（Nullable 制御はここで行う）
- [ ] リレーションシップ属性は `"Entity"` の単純な文字列参照で記述
- [ ] 自己参照の場合、parent 側に `remote_side` を指定
- [ ] children 側に `lazy="selectin"` を検討（N+1 防止）
- [ ] 設計書（design.md）に DD（Design Decision）として制約を記載

## Related Patterns

| Pattern | Relationship |
|---------|--------------|
| SQLAlchemy Adjacency List | 本パターンの基盤となるSQLAlchemy公式パターン |
| TYPE_CHECKING Import | 循環参照回避パターン（本パターンでは不要な場合が多い） |

## References

- [SQLAlchemy 2.0 Self-Referential Relationships](https://docs.sqlalchemy.org/en/20/orm/self_referential.html)
- [SQLModel GitHub Issue #127](https://github.com/fastapi/sqlmodel/issues/127) - Self-referential table discussion
- [SQLModel Relationships Tutorial](https://sqlmodel.tiangolo.com/tutorial/relationship-attributes/)
