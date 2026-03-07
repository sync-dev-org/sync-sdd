## Change-Focused Review Report

### Issues Found

---

#### [CRITICAL] sdd-conventions-scanner が settings.json の Task 許可リストに未登録

- **ファイル**: `framework/claude/settings.json`
- **状況**: `sdd-conventions-scanner` エージェントが追加されたが、`settings.json` の `permissions.allow` リストに `Task(sdd-conventions-scanner)` が存在しない。
- **影響**: `Task(subagent_type="sdd-conventions-scanner", ...)` による dispatch が権限エラーで失敗する。Wave Context 生成 (run.md Step 2.5)、Pilot Stagger (impl.md Step 3)、revise.md Tier Execution (Step 7) がすべてブロックされる。
- **証拠**:
  - `framework/claude/settings.json` の `permissions.allow` に `"Task(sdd-conventions-scanner)"` が存在しない（全エージェントを確認済み）
  - `run.md:33` に `Task(subagent_type="sdd-conventions-scanner", run_in_background=true)` の dispatch 指示あり
  - `impl.md:62` に `Dispatch sdd-conventions-scanner SubAgent (mode: Supplement)` の指示あり
  - `revise.md:213` に `Dispatch sdd-conventions-scanner (mode: Generate) per run.md Step 2.5` の指示あり

---

#### [HIGH] CLAUDE.md の Knowledge Auto-Accumulation が旧プロトコルを記述したまま

- **ファイル**: `framework/claude/CLAUDE.md:287`
- **状況**: CLAUDE.md §Knowledge Auto-Accumulation に「Lead collects tagged reports from SubAgent **Task results**」とあるが、Builder の新プロトコルではタグは Task result（minimal summary）に直接含まれず、`builder-report-{group}.md` ファイルに書き込まれる。Lead は `Tags: {count}` を受け取った後、ファイルを Grep して収集する（impl.md:75 の「If Tags > 0: Grep builder-report file for [PATTERN]...」）。
- **影響**: CLAUDE.md を読んだ Lead が Task result から直接タグを収集しようとする可能性があり、プロトコルと矛盾した動作を取るリスクがある。
- **差分箇所**:
  - `CLAUDE.md:287`: `Lead collects tagged reports from SubAgent Task results`（旧記述）
  - `impl.md:75`: `If Tags > 0: Grep builder-report file for [PATTERN], [INCIDENT], [REFERENCE] lines`（新プロトコル）

---

#### [HIGH] impl.md Step 4 の auto-draft が dispatch loop コンテキストで呼ばれた場合の矛盾

- **ファイル**: `framework/claude/skills/sdd-roadmap/refs/impl.md:95`
- **状況**: impl.md Step 4 に `Auto-draft {{SDD_DIR}}/handover/session.md` という手順が残っている。run.md Phase Handler では `(Steps 1-3, skip Step 4 auto-draft when called from dispatch loop)` という注釈で回避を指示しているが、impl.md 本体には「dispatch loop から呼ばれた場合はスキップ」という記載がない。
- **影響**: impl.md を単独読込した Lead やサブエージェントが Step 4 を省略すべきかどうかを impl.md 単体で判断できない。run.md 側の注釈に依存しており、整合性が弱い。
- **具体箇所**:
  - `impl.md:93-96` (Step 4): auto-draft 手順が無条件に記述されている
  - `run.md:187`: `skip Step 4 auto-draft when called from dispatch loop` という注釈で外部から制御

---

#### [MEDIUM] CLAUDE.md の SubAgent Failure Handling の記述が Builder ファイルベース化と整合していない

- **ファイル**: `framework/claude/CLAUDE.md:111-113`
- **状況**: §SubAgent Failure Handling に「File-based review protocol makes all SubAgent outputs idempotent」とあり、review SubAgent（Inspector/Auditor）の文脈のみを指して「同じ Task prompt を retry すれば同一フローになる」と述べている。しかし Builder も今やファイルベース出力（`builder-report-{group}.md`）を持つようになった。Builder の retry プロトコル（FAIL-RETRY-2 時の再 dispatch, BUILDER_BLOCKED 時の対処）は impl.md に記述されており、CLAUDE.md の Failure Handling セクションは整合を取る必要がある。
- **影響**: 軽微。CLAUDE.md 単体では「Builder は idempotent ではない」という誤解を生む可能性がある。実用上 impl.md が正しい手順を定義しているため、動作への影響は低い。

---

#### [LOW] CLAUDE.md の Wave Context 説明が「Pilot Stagger seeds conventions from the first Builder group's output」と残存記述

- **ファイル**: `framework/claude/CLAUDE.md:100`（コミット済みの最新版）
- **状況**: Wave Context の bullet が `Pilot Stagger seeds conventions via ConventionsScanner supplement mode` に更新されている（正しい）。未コミットの diff でも同様に正しい記述に変更済み。この点は問題なし。確認OK。

---

#### [LOW] ConventionsScanner の Supplement モードで output path が不明確

- **ファイル**: `framework/claude/agents/sdd-conventions-scanner.md:49`
- **状況**: Supplement モードの Input に `Output path: same as existing brief path (overwrite with supplement)` と記述されているが、dispatch prompt の定義（impl.md:62-66）には `Output path` パラメータが含まれていない。Scanner は `Existing brief path` をそのまま output path と解釈するよう実装されているが（Step 5 の「Write updated brief to output path」が内部的には existing brief path を参照）、dispatch prompt テンプレートとの齟齬が曖昧。
- **影響**: 実害は低い。Scanner 内部の Steps が自明だが、dispatch prompt に output path を明示していないことで混乱する可能性がある。

---

### Confirmed OK

- **ConventionsScanner tier table (CLAUDE.md)**: T3 tier table に `ConventionsScanner` が正しく追加されている（`framework/claude/CLAUDE.md:27`）。
- **ConventionsScanner agent 定義**: `framework/claude/agents/sdd-conventions-scanner.md` が存在し、YAML frontmatter（name, model: sonnet, tools, background: true）が適切。Generate/Supplement モード両方が定義されている。
- **run.md Step 2.5 の ConventionsScanner dispatch**: Lead が直接スキャンする旧記述が削除され、`Task(subagent_type="sdd-conventions-scanner", run_in_background=true)` dispatch に一貫して置き換えられている。
- **revise.md Tier Execution (Step 7)**: `sdd-conventions-scanner (mode: Generate) per run.md Step 2.5` への参照に更新されており、run.md との整合性が取れている。
- **Builder self-select プロトコル (tasks.yaml 間接読み込み)**: `sdd-builder.md:31` に「Read the file at the provided path. Locate your assigned group in the execution_plan section」と明記されており、impl.md Step 3 の「Builder reads its own tasks from tasks.yaml」と整合している。Lead は execution_plan セクションのみ読んでグループ情報を取得（impl.md:37-38）。
- **Builder Completion Report (ファイルベース化)**: `sdd-builder.md` の Step A（Write Full Report → builder-report-{group}.md）と Step B（Output Minimal Summary）が明確に定義されている。impl.md の incremental processing（impl.md:72-81）がこの minimal summary を parse する手順と一致している。
- **Auto-draft 頻度削減の CLAUDE.md 記述**: CLAUDE.md:234 に `Exception — run pipeline dispatch loop` として auto-draft 制限が追加されており、run.md:169 の Phase Handler auto-draft policy と内容が一致している。
- **出力抑制ルール一般化 (CLAUDE.md:37-40)**: Review SubAgents に限定していた旧記述が、Builder（file-based report）と Architect/TaskGenerator（concise format 継続）を含む全 SubAgent の指針に拡張されており、実態と整合している。
- **BUILDER_BLOCKED の inline summary**: `sdd-builder.md:163` に「BLOCKED reports include the blocker summary inline (Lead needs it for immediate routing). No file write required for BLOCKED.」と明記されており、impl.md:80 の「classify cause from inline blocker summary」と整合している。
- **SelfCheck WARN の変更**: WARN の詳細が summary に含まれなくなった（count のみ）ことについて、impl.md:78 に「Read SelfCheck section from builder-report when dispatching impl review」と Auditor への受け渡し手順が定義されている。

---

### Overall Assessment

**主要な問題は1件の CRITICAL と2件の HIGH。**

CRITICAL: `settings.json` への `Task(sdd-conventions-scanner)` 未登録は実行時に即座に失敗するブロッカー。Wave Context 生成 (run.md Step 2.5)、Pilot Stagger (impl.md)、revise.md Tier Execution がすべて影響を受ける。**リリース前に必ず修正が必要。**

HIGH-1: CLAUDE.md §Knowledge Auto-Accumulation の「Task results からタグ収集」という記述が Builder の新ファイルベースプロトコルと矛盾している。impl.md が正しい手順を定義しているため動作上の影響は限定的だが、Lead の読込順次第で誤動作リスクがある。

HIGH-2: impl.md Step 4 の auto-draft スキップ条件が impl.md 本体に未記載で、run.md 側の注釈に依存している。単独実行時（`/sdd-roadmap impl {feature}`）との使い分けが impl.md を読んだだけでは判断できない。

ConventionsScanner 自体の設計（Generate/Supplement モード分離、agent 定義）、Builder ファイルベース化とその incremental processing、tasks.yaml self-select プロトコルはすべて整合が取れており、問題なし。
