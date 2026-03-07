## Change-Focused Review Report

**対象コミット**: 未コミット変更 (HEAD未コミット diff)
**変更ファイル**:
- `framework/claude/agents/sdd-builder.md` — RED/GREEN ステップへの古典派テスト原則追加
- `framework/claude/agents/sdd-inspector-test.md` — 新カテゴリ E (Test Duplication)追加、旧E→F リナンバー
- `framework/claude/sdd/settings/templates/steering-custom/testing.md` — Unit 定義変更 + Testing School + Anti-Patterns セクション追加

---

### Issues Found

- [HIGH] **sdd-inspector-test.md セクション C との矛盾** (`framework/claude/agents/sdd-inspector-test.md:117`)

  セクション C「Integration vs Unit Balance」に `"Do unit tests properly isolate the unit under test?"` という問いが残っている。この表現は London/Mockist 学派的な「完全な孤立 (isolation)」を前提とする問いであり、今回追加された Classical/Detroit school の原則（内部コラボレーターは real instance を使う）と意味的に矛盾する。

  - 新原則では「unit テストで内部依存をモックしない → 単体テストは完全に孤立しない」ことが正しい。
  - しかし `"properly isolate the unit under test"` というフレーズは「内部依存もモック化して孤立させることが正しい」と読める。
  - Inspector がこの問いを判断基準にした場合、classical school 準拠のテスト（内部コラボレーターが real）を「隔離が不十分」と誤判定するリスクがある。

  **推奨修正**: セクション C の該当行を `"Do unit tests test observable behavior rather than isolating every dependency?"` などに改め、classical school との整合性を取る。

- [MEDIUM] **testing.md テンプレートの Unit 定義と design.md Testing Strategy の表記不一致** (`framework/claude/sdd/settings/templates/specs/design.md:275`)

  `design.md` テンプレートの Testing Strategy セクションには:
  ```
  - Unit Tests: 3–5 items from core functions/modules (e.g., auth methods, subscription logic)
  ```
  と記載されており、Unit テストの定義（real collaborators vs mocked dependencies）について言及がない。

  一方 `testing.md` テンプレートでは Unit の定義が:
  ```
  - Unit: single unit, real internal collaborators, mock externals only, very fast
  ```
  に更新されている。

  `design.md` テンプレートは Architect が参照する Testing Strategy 記述の雛形であり、設計者が「Unit テストとは何か」の定義を誤解したまま Testing Strategy を記述する可能性がある。`testing.md` を custom steering として導入したプロジェクトでは一貫するが、`testing.md` を採用していないプロジェクトでは `design.md` テンプレートが唯一の参照になるため、認識のズレが生じる。

  **推奨修正**: `design.md` の Testing Strategy セクションコメントに `"Unit: real internal collaborators, mock externals only"` の一行注記を追加するか、Architect が参照できるよう design.md 内で定義の食い違いを防ぐ。（低優先度だが将来的なドリフトを防ぐ）

- [MEDIUM] **conventions-brief.md テンプレートの Testing Patterns セクションに classical school 言及なし** (`framework/claude/sdd/settings/templates/wave-context/conventions-brief.md:27-29`)

  `conventions-brief.md` テンプレートの Testing Patterns セクション:
  ```
  ## Testing Patterns
  - Placement: {pattern}
  - Assert style: {description}
  - Fixture location: {pattern}
  ```

  ConventionsScanner が生成する conventions brief には、モック境界（external vs internal）の観察パターンが含まれていない。Builder は conventions brief を「testing パターン」として参照するが、既存コードベースがモック多用のコードを持つ場合、brief がそのパターンを記録してしまい、Builder が「既存パターンに従う」として over-mocking を再現するリスクがある。

  新 testing.md と sdd-builder.md では「内部コラボレーターは real instance」を明示しているが、conventions brief がそのシグナルを含まないため、steering が明示的に testing.md を導入していないプロジェクトでは brief 経由で逆のパターンが伝播しうる。

  **推奨修正**: conventions-brief.md テンプレートの Testing Patterns に `- Mock boundary: {external-only | extensive}` などのフィールドを追加し、ConventionsScanner がスキャン時に実際のモック使用パターンを記録できるようにする。

- [LOW] **CPF カテゴリ名の inconsistency**: `"Implementation-coupled test"` vs `"impl-coupled-test"` の表記揺れ**
  (`framework/claude/agents/sdd-inspector-test.md:131` と `:214`)

  本文では:
  ```
  Flag: "Implementation-coupled test" (severity: M) if test asserts on non-public API or internal structure
  ```
  CPF 出力例では:
  ```
  M|impl-coupled-test|...
  ```

  CPF カテゴリ値（パイプ区切り第2フィールド）は機械解析される値であり、他のフラグ (`over-mocking`, `refactor-fragile`, `duplicate-coverage`) がすべて lowercase-hyphen 形式なのに対して、Flag の記述テキスト `"Implementation-coupled test"` は人間向け説明文。CPF 例では `impl-coupled-test` と書かれており実際の出力値は正しいが、本文の `Flag:` 行が `"impl-coupled-test"` ではなく `"Implementation-coupled test"` と書かれているため、CPF を生成する Inspector が混乱する可能性はごく低いものの、他のフラグとの記法の不統一がある。

  他の同カテゴリフラグ:
  - `Flag: "Over-mocking" (severity: M)` → CPF: `M|over-mocking|...` ← 表記に一貫性がある
  - `Flag: "Duplicate coverage" (severity: L)` → CPF: `L|duplicate-coverage|...` ← 表記に一貫性がある
  - `Flag: "Implementation-coupled test" (severity: M)` → CPF: `M|impl-coupled-test|...` ← **非一貫**: Flag名 ≠ CPFカテゴリ

  **推奨修正**: `Flag: "impl-coupled-test" (severity: M)` に統一するか、または CPF 例を `M|implementation-coupled-test|...` に揃える。

---

### Confirmed OK

- **Builder RED ステップの古典派原則追加の整合性**: `sdd-builder.md` の RED ステップに追加された Classical school 原則 (`mock ONLY at external boundaries`) は、`testing.md` テンプレートの Testing School セクションおよび Mocking & Data セクション (`Never mock internal collaborators`) と完全に一致している。

- **Builder GREEN ステップの「余分なテスト禁止」追加**: `Do NOT add extra test cases "just in case"` は `testing.md` の Anti-Patterns「Coverage chasing」と一貫している。矛盾なし。

- **Inspector-Test のセクション E 新設 (Test Duplication)**: 追加された `E. Test Duplication and Bloat` の内容は、`testing.md` の Anti-Patterns セクション (`Duplication`, `Implementation coupling`) と正確に対応している。新カテゴリと steering テンプレートの整合性は取れている。

- **旧 E (AC Marker) → 新 F (AC Marker Coverage) のリナンバー**: セクション番号のみ変更。内容は変更なし。外部ファイルから `E. AC Marker` をセクション番号で参照しているファイルは存在しない（全参照はファイル名・cpf形式経由）。セクション番号シフトによるダングリング参照は確認されない。

- **CPF 出力例の整合性**: 新しいカテゴリ (`over-mocking`, `refactor-fragile`, `impl-coupled-test`, `duplicate-coverage`) は CPF 例に正しく追加されており、既存の CPF 例 (`weak-assertion`, `strategy-gap`) も維持されている。

- **Inspector の6個 (impl) カウントは変更なし**: `sdd-inspector-test` は既存の6 impl Inspectors の一つであり、今回の変更はその内部チェック項目の追加であって、Inspector 自体の追加・削除ではない。`review.md` および `CLAUDE.md` の `6 impl` カウントへの影響なし。

- **testing.md Anti-Patterns セクション追加の影響範囲**: `testing.md` は steering-custom テンプレート (`/sdd-steering custom` 経由でユーザーが採用を選択する)。テンプレートとして `sdd-steering` SKILL.md から参照されており、既存のテンプレート参照に問題なし。Anti-Patterns セクションの内容は `sdd-builder.md` および `sdd-inspector-test.md` の新規追加内容と一貫している。

- **Auditor への影響なし**: `sdd-auditor-impl.md` は Inspector ファイルの CPF を読み込むが、カテゴリ値はInspector固有として扱われ（`cpf-format.md` の規則に従い）、Auditor 側での固定カテゴリ一覧参照はない。新カテゴリ追加は Auditor の読み込み処理に影響しない。

---

### Overall Assessment

変更内容（Classical/Detroit school テスト原則の Builder・Inspector・testing.md への統合）は概念的に一貫しており、3ファイル間の整合性は高い。

**主要リスク1（HIGH）**: `sdd-inspector-test.md` セクション C の `"Do unit tests properly isolate the unit under test?"` という表現が新原則と意味的に矛盾する。Inspector がこの問いを採点基準として使用した場合、classical school 準拠のテストを誤フラグする可能性があり、修正を推奨する。

**主要リスク2（MEDIUM）**: conventions-brief.md テンプレートが新しいモック境界の概念を収録していないため、ConventionsScanner がスキャンした既存コードベースのパターン（over-mocking がある場合）をそのまま brief に記録し、Builder がそのパターンを「慣例」として踏襲するリスクがある。

それ以外の変更（セクションリナンバー、Anti-Patterns 追加、CPF カテゴリ追加、Builder 手順追加）は clean であり、ダングリング参照・プロトコル欠落・テンプレート整合性の問題は確認されない。

**総合判定: CONDITIONAL** — HIGH 1件、MEDIUM 2件の修正推奨。CRITICAL はなし。
