## Change-Focused Review Report

レビュー対象コミット: `a387b68` (SDK API Drift 対策: T2/T3 Dependency Sync + Discovery フロー反転 + sys.modules 検出)

---

### Issues Found

- [MEDIUM] **design.md Step 3 のクロスリファレンス不整合** — `sdd-architect.md` line 68 では「`design-discovery-full.md Steps 5-6` を参照」と記載しているが、`design-discovery-full.md` は Step 番号を 1-8 に再番号付けされた。新しい正しい参照先は Step 5（Technology Research + Validation）と Step 6（Design Refinement）であり、番号自体は変わっていないが、旧来 Step 3（Technology Research）と Step 4（External Dependencies Investigation）が 2 ステップに分割されて繰り上がっている。Architect が参照する Step 番号は変わらず 5-6 なので、実害は出ないが、**sdd-architect.md の「see design-discovery-full.md Steps 5-6」という記述は旧フローの Step 名（Technology Research）を暗示しており、新フローと見た目上の乖離がある**。文言を `Steps 5-6 (Technology Research + Validation and Design Refinement)` に明記することで将来の混乱を防げる。
  - `framework/claude/agents/sdd-architect.md` line 68

- [MEDIUM] **Simple Addition 時の SDK Source Inspection 適用範囲が不明確** — `sdd-architect.md` では Step 2 の Feature Classification で「Simple Additions: Skip formal discovery, quick pattern check only」と記述しているが、その直後に「SDK Source Inspection（when Lead provides installed SDK source paths in prompt）」という別ブロックが独立して追加されている。この SDK Source Inspection ブロックは、Simple Addition でも Lead が SDK パスを提供した場合に適用されるのかどうかが曖昧。フルディスカバリー・ライトディスカバリーの分岐に続けて配置されているが、構造的に「全モードに共通」なのか「Complex/New と Extension のみ」なのかが読み取りにくい。Simple Addition でも SDK パスが渡される可能性はあるので、適用スコープを明示すべき。
  - `framework/claude/agents/sdd-architect.md` lines 65-70

- [MEDIUM] **design.md Step 2.5 と run.md Dependency Sync の責任範囲重複** — `refs/design.md` Step 2.5（単発 design サブコマンド実行時）と `refs/run.md` Step 2.5 Dependency Sync（マルチスペック run 実行時）は両者とも「SDK の追加・インストール・source path 特定」を行う。一方、`refs/impl.md` Step 2.5 は「impl 時点で design.md に記載された依存が manifest に宣言・インストール済みか確認し、漏れを補う」という後続のフォールバックになっている。この 3 段構造は意図的に見えるが、**design.md Step 2.5 で SDK が追加・インストール済みのはずなのに、impl.md Step 2.5 で再度「not yet in pyproject.toml」かチェックする理由**が明記されていない。ユーザーが直接 `/sdd-roadmap impl` を呼んだ場合（design を別セッションで済ませた場合）の正当なフォールバックとして機能するが、その旨が impl.md Step 2.5 に記載されていない。読者が「なぜ design で追加したのにまた確認するのか」と疑問を持つリスクがある。
  - `framework/claude/skills/sdd-roadmap/refs/impl.md` lines 37-48

- [LOW] **run.md Dependency Sync と design.md Dependency Sync の条件判定文言が微妙に異なる** — `refs/run.md` では「if spec name/description implies new external SDKs」と記述し、`refs/design.md` では「identifiable from spec name, description, user instructions, or existing design.md」と列挙している。run.md は `user instructions` と `existing design.md` の 2 条件が省略されており、若干スコープが狭く見える。マルチスペック実行時に `run` が先に評価するため、この省略が問題になる可能性は低いが、統一すると読者の混乱を減らせる。
  - `framework/claude/skills/sdd-roadmap/refs/run.md` line 62
  - `framework/claude/skills/sdd-roadmap/refs/design.md` line 24

- [LOW] **sdd-steering.md Step 5a の「Python profile selected」条件の判定タイミングが曖昧** — Step 5a は「Python profile selected」の場合に限定されているが、Step 5（ステアリングファイル生成）とどちらが先かが曖昧。Step 5a は Step 5 の後（ファイル生成後）に実行されるが、pyproject.toml の生成をどのタイミングで行うか（ステアリングファイルと同時か、その後か）が不明。また、「Run install command」とあるが、この時点ではまだ `tech.md` が生成されたばかりであり、Common Commands の `# Install:` 行が書き込まれているかどうかに依存する。Install コマンドが空の場合のフォールバックが未定義。
  - `framework/claude/skills/sdd-steering/SKILL.md` lines 49-53

- [LOW] **tech.md テンプレートの `# Install:` コメント更新と既存プロジェクトへの影響** — `framework/claude/sdd/settings/templates/steering/tech.md` の `# Install:` 行が `[command]` から `[command that installs ALL dependencies including extras/optional for dev]` に変更された。これはテンプレートの変更なので、既存の `steering/tech.md` を持つプロジェクトには影響しない。ただし、既存プロジェクトが短い `# Install: uv sync` のみを記述している場合、Lead は「全依存含むコマンド」として期待するが実際には extra が入らない可能性がある。Dependency Sync での依存追加後、`--all-extras` フラグが不足していると import verification が通らない。この点はテンプレートレベルの問題ではなく、既存プロジェクトの `tech.md` 記述品質の問題だが、フレームワーク側でフォールバック（失敗時の `uv sync --all-extras` 試行など）がない点はリスク。
  - `framework/claude/sdd/settings/templates/steering/tech.md` line 39

---

### Confirmed OK

- **Focus Target 1: T2/T3 Dependency Sync — 3 ファイル間の整合性**: `design.md` Step 2.5、`impl.md` Step 2.5、`run.md` Step 2.5（Dependency Sync）はそれぞれ異なるトリガー（単発 design、単発 impl、run パイプライン）をカバーし、機能的に重複・矛盾はない。Lead が pyproject.toml への追記 → インストール → source path 特定 → Architect への伝達という一連を担う責任チェーンが 3 ファイル間で一貫している。

- **Focus Target 2: Discovery フロー反転 — sdd-architect.md と design-discovery-full.md の整合**: `sdd-architect.md` は「SDK Source Inspection → WebSearch（Steps 5-6 参照）」という順序でフローを記述しており、`design-discovery-full.md` の新フロー（Step 3: Source Inspection → Step 4: Design Draft → Step 5: WebSearch → Step 6: Refinement）と整合している。Architect が「まずソースを読み、次に Web 検索で検証する」というガイダンスが一貫している。Source vs WebSearch Priority セクションも research.md 記録ルールも両ファイルで対応している。

- **Focus Target 3: Builder pyproject.toml 編集禁止 — impl.md Lead 管理責任との矛盾確認**: `sdd-builder.md` の「No dependency management」制約は「dependency manifests (`pyproject.toml`, `package.json`, `Cargo.toml`, etc.)` を編集しない」と明示。`impl.md` Step 2.5 は「Lead が manifest に追加して install する」という責任を明示的に Lead に帰属させており、矛盾はない。Lead がやる→Builder はやらない、という役割分担が両ファイルで一貫。

- **Focus Target 4: sys.modules 検出の連携**: `sdd-builder.md` の「No sys.modules manipulation」制約、`sdd-inspector-test.md` の「Module-Level Mock Integrity」チェック (Section F)、`impl.md` の「sys.modules violation scan」の 3 層が互いに整合している。Builder が違反すれば Lead が post-Builder スキャンで検出し再ディスパッチ、Review フェーズで Inspector が CPF に C 判定として記録、という多重防御チェーンが成立している。Builder の説明文（`"Lead scans all output files for sys.modules usage after completion"`）と impl.md の実際のスキャン記述も一致。

- **Focus Target 5: sdd-steering T1 環境構築と tech.md template の整合**: `sdd-steering/SKILL.md` Step 5a は「Run install command to create/update virtual environment」と記述し、`tech.md` テンプレートの `# Install:` 行を参照する形を想定している。Step 5 でステアリングファイル（`tech.md`）が生成され、Step 5a で install コマンドを実行するという順序は論理的に成立している（ただし低優先度 issue として記録済み）。

- **design-discovery-full.md の旧 Step 番号（3, 4, 5, 6）→ 新番号（3-8）リナンバリング**: `design-discovery-light.md` は旧 Step 番号への直接参照を含まず、独立したフローとして記述されているため影響なし。

- **sdd-inspector-test.md の旧 Section F（AC Marker Coverage）→ 新 Section G へのリレタリング**: Section G の内容は変更なく、Section 文字の付け替えのみ。参照先ファイルに外部参照なし。

- **design-discovery-light.md の SDK Source Inspection 追記**: 旧 Step 4 に blockquote 形式で「Lead が SDK ソースパスを提供した場合」の補足が追加されている。フル/ライト両ディスカバリーで同一原則が適用されており一貫性あり。

---

### Overall Assessment

今回のコミットは SDK API Drift 対策として「Source→Design→WebSearch」フローを確立し、sys.modules ハックを多層で封じる変更である。コアとなる 5 つのフォーカスターゲットは概ね整合しており、プロトコルの完全性も維持されている。

**主要リスク**: sdd-architect.md の SDK Source Inspection ブロックが Simple Addition に適用されるか否かの曖昧さ（MEDIUM）と、design→impl をまたぐ Dependency Sync の 3 段構造でフォールバック意図が未記載（MEDIUM）の 2 点が実運用上の混乱源になる可能性がある。いずれも動作上の矛盾ではなくドキュメント上の読み取り難易度の問題。CRITICALまたはHIGH の問題は検出されなかった。

**推奨アクション**:
1. `sdd-architect.md` line 68: `"see design-discovery-full.md Steps 5-6"` → `"see design-discovery-full.md Steps 5-6 (Technology Research + Validation, Design Refinement)"` に明示化
2. `sdd-architect.md` lines 65-66: SDK Source Inspection ブロックのスコープ（全 Feature Type に適用 vs Complex/Extension のみ）を明記
3. `refs/impl.md` Step 2.5: 「design サブコマンドを別セッションで済ませた場合のフォールバック」であることを Rationale に追記
