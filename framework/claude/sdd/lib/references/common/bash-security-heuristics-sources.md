# Bash Security Heuristics — Test Cases & Verification Procedure

> **Purpose**: Claude Code のセキュリティヒューリスティクスの動作を網羅的にテストし、結果を記録する。
> このファイル自体が再テスト手順書として機能する。新バージョンで再検証する際はこのファイルの手順に従い、結果を更新する。

## Verification Environment

| Item | Value |
|------|-------|
| Claude Code version | 2.1.72 |
| Date | 2026-03-10 |
| Platform | Darwin 23.6.0 (arm64) |

## How to Use This Document

1. `.tmp/heuristics-test/` ディレクトリを作成し、テスト用ファイルを配置する（Setup セクション参照）
2. 各テストケースの Command を Bash ツールで実行する
3. 結果を記録する:
   - **AUTO**: 承認プロンプトなしで実行された（セキュリティヒューリスティクス未検出）
   - **HEURISTIC**: Yes / No の2択で表示された（settings.json で回避不可）
   - **ALLOW**: Yes / Yes, and don't ask again for: / No の3択で表示された（settings.json で回避可能）
   - **ALLOW(反復)**: 3択表示だが settings.json 登録済みでも毎回プロンプトが出る（実質 HEURISTIC）
4. HEURISTIC/ALLOW の場合、表示されたメッセージをそのまま `Message` に記録する
5. **新しいバージョンで新しいコマンドパターンや構文が登場した場合**、既存カテゴリに追加するか新カテゴリを作成してテストケースを追加する。既存ケースの実行だけでなく、環境変化に応じた動的なケース追加が重要
6. テスト結果が Expect と異なる場合、既存リファレンスの誤りの可能性がある。Notes に詳細を記録し、追加テストで切り分ける
7. テスト完了後、結果から bash-security-heuristics.md (リファレンス本体) を更新する
8. `.tmp/heuristics-test/` を削除する

### Prompt Type Identification

| Prompt | Options | Classification | Suppressible |
|--------|---------|---------------|-------------|
| "requires approval for safety" / specific detection | Yes / No (2択) | HEURISTIC | No |
| "This command requires approval" | Yes / Yes, and don't ask again / No (3択) | ALLOW | Yes (settings.json) |
| 3択だが登録済みでも毎回出る | Yes / Yes, allow reading... / No (3択) | ALLOW(反復) | No |

## Setup

```bash
mkdir -p .tmp/heuristics-test
echo "hello world" > .tmp/heuristics-test/sample.txt
echo -e "line1\nline2\nline3" > .tmp/heuristics-test/multi.txt
echo '{"key": "value"}' > .tmp/heuristics-test/data.json
cat > .tmp/heuristics-test/test-script.sh << 'SETUP'
#!/bin/bash
echo "helper script executed"
SETUP
chmod +x .tmp/heuristics-test/test-script.sh
```

## Test Cases

### Legend

- **Expect**: テスト者の予測 (AUTO / HEURISTIC / ALLOW / UNKNOWN)
- **Result**: 実行結果 (AUTO / HEURISTIC / ALLOW / ALLOW(反復)) — テスト実行時に記入
- **Message**: HEURISTIC/ALLOW 時の表示メッセージ — テスト実行時に記入

---

### Category 1: Command Substitution `$()`

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C1-01 | `echo "$(date)"` | HEURISTIC | HEURISTIC | Command contains $() command substitution |
| C1-02 | `echo "$(pwd)"` | HEURISTIC | HEURISTIC | Command contains $() command substitution |
| C1-03 | `echo "$(cat .tmp/heuristics-test/sample.txt)"` | HEURISTIC | HEURISTIC | Command contains $() command substitution |
| C1-04 | `VAR=$(date)` | HEURISTIC | HEURISTIC | Command contains $() command substitution |
| C1-05 | `` echo `date` `` | HEURISTIC | HEURISTIC | Command contains backticks (\`) for command substitution |
| C1-06 | `` VAR=`date` `` | HEURISTIC | HEURISTIC | (backtick, C1-05 と同系統) |
| C1-07 | `echo '$(date)'` (single quote) | AUTO | AUTO | single quote は $() 検出を抑制する |
| C1-08 | `echo "\$(date)"` (escaped) | HEURISTIC | HEURISTIC | Command contains $() command substitution (エスケープ無効) |

**Findings**:
- `$()` は HEURISTIC。エスケープ `\$()` でも検出される
- バッククォートも HEURISTIC（既存リファレンスの「backticks are OK」は**誤り**）
- single quote 内 `'$()'` のみ回避可能
- C1-01 初回テスト時のみ AUTO だったが再テストで HEURISTIC。初回のみの一時的状態と推定

### Category 2: Parameter Substitution `${}`

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C2-01 | `echo "${HOME}"` | HEURISTIC | HEURISTIC | Command contains ${} parameter substitution |
| C2-02 | `echo "${PATH}"` | HEURISTIC | HEURISTIC | Command contains ${} parameter substitution |
| C2-03 | `echo "${VAR:-default}"` | HEURISTIC | HEURISTIC | Command contains ${} parameter substitution |
| C2-04 | `echo "${#HOME}"` (length) | HEURISTIC | HEURISTIC | Command contains ${} parameter substitution |
| C2-05 | `echo "$HOME"` (no braces) | AUTO | AUTO | |
| C2-06 | `echo "$PATH"` (no braces) | AUTO | AUTO | |
| C2-07 | `echo '${HOME}'` (single quote) | AUTO | AUTO | single quote は ${} 検出を抑制する |
| C2-08 | `echo "\${HOME}"` (escaped) | HEURISTIC | HEURISTIC | Command contains ${} parameter substitution (エスケープ無効) |
| C2-09 | `printenv HOME` | AUTO | AUTO | |

**Findings**:
- `${}` は HEURISTIC。`$VAR` (ブレースなし) で回避可能
- エスケープ `\${}` は無効。single quote のみ回避可能
- `printenv` は完全な代替手段

### Category 3: tmux Format Strings `#{}`

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C3-01 | `tmux display-message -p '#{pane_id}'` | ALLOW | ALLOW | (3択: tmux display-message:*) |
| C3-02 | `tmux list-panes -F '#{pane_id}'` | ALLOW | ALLOW | (3択: tmux list-panes:*) |
| C3-03 | `tmux list-panes -F '#{pane_id} #{pane_title}'` | ALLOW | ~~AUTO~~ | 初回 AUTO だが再現不可。一時的状態として除外 |
| C3-04 | `tmux select-pane -T 'title'` (no format) | AUTO | AUTO | |
| C3-05 | `tmux list-panes` (no -F) | AUTO | AUTO | |
| C3-e1 | `tmux display-message -p 'hello'` (no #{}) | AUTO | AUTO | **`#{}` なしなら AUTO** |
| C3-e2 | `tmux display-message -p '#{pane_id}'` (re-test) | ALLOW | ALLOW | (3択: tmux display-message:*) 再テストで ALLOW 確認 |
| C3-e3 | `tmux list-windows -F '#{window_id}'` | ALLOW | ALLOW | (3択: tmux list-windows:*) 未登録サブコマンドでも同様 |

**Findings**:
- `#{}` は `${}` として**誤検出されない** — 既存リファレンスの「`#{}` → `${}` 誤検出」は**誤り**
- **`#{}` が `tmux *` の allow パターンマッチを破壊する**: `#{}` なしの `tmux display-message -p 'hello'` は AUTO (C3-e1)、`#{}` 付きは ALLOW (C3-e2)
- サブコマンド単位 (`tmux display-message:*`, `tmux list-windows:*`) で allow 登録が要求される
- ヘルパースクリプトに隔離する方針が最善の回避策

### Category 4: Process Substitution `<()`

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C4-01 | `diff <(echo a) <(echo b)` | HEURISTIC | HEURISTIC | Command contains process substitution <() |
| C4-02 | `cat <(echo hello)` | HEURISTIC | HEURISTIC | Command contains process substitution <() |
| C4-03 | `echo '<(not real)'` (single quote) | HEURISTIC | HEURISTIC | Process substitution requires manual approval |

**Findings**:
- `<()` は HEURISTIC。**single quote でも回避不可**（`$()` との重要な差異）
- C4-03 のメッセージが C4-01/02 と異なる（"requires manual approval"）

### Category 5: Subshell `()`

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C5-01 | `(echo hello)` | HEURISTIC | HEURISTIC | This command uses shell operators that require approval for safety |
| C5-02 | `(cd .tmp/heuristics-test && ls)` | HEURISTIC | HEURISTIC | This command uses shell operators that require approval for safety |
| C5-03 | `echo "(parentheses in string)"` | AUTO | AUTO | 文字列内 () は検出されない |
| C5-04 | `echo '(parentheses in string)'` | AUTO | AUTO | 同上 |

**Findings**:
- コマンド先頭の `(` が検出トリガー。文字列内は安全

### Category 6: Background `&`

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C6-01 | `sleep 0 &` | HEURISTIC | HEURISTIC | This command uses shell operators that require approval for safety |
| C6-02 | `echo "ampersand &"` (in string) | AUTO | AUTO | 文字列内 & は検出されない |
| C6-03 | `echo hello && echo world` | AUTO | AUTO | && は & とは別扱い |

**Findings**:
- 末尾 `&` は HEURISTIC。`Bash(run_in_background=true)` で代替

### Category 7: Stdin Redirect `<`

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C7-01 | `cat < .tmp/heuristics-test/sample.txt` | HEURISTIC | HEURISTIC | Command contains input redirection (<) which could read sensitive files |
| C7-02 | `wc -l < .tmp/heuristics-test/sample.txt` | HEURISTIC | HEURISTIC | Command contains input redirection (<) which could read sensitive files |
| C7-03 | `echo "3 < 5"` (in string) | AUTO | AUTO | 文字列内 < は検出されない |
| C7-04 | `echo '3 < 5'` (single quote) | AUTO | AUTO | 同上 |

### Category 8: External Path Access (旧: Stderr Redirect)

旧テストケースは `2>` をトリガーと推定していたが、追加調査で**プロジェクト外の絶対パス**が真の検出トリガーと判明。

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C8-01 | `ls /nonexistent 2>/dev/null` | HEURISTIC | HEURISTIC | (メッセージなし、2択のみ) |
| C8-02 | `cat /nonexistent 2>/dev/null` | HEURISTIC | HEURISTIC | (メッセージなし、2択のみ) |
| C8-03 | `echo "2>test"` (in string) | AUTO | AUTO | |
| C8-04 | `echo hello > .tmp/heuristics-test/out.txt` | AUTO | AUTO | stdout redirect OK |
| C8-05 | `echo hello >> .tmp/heuristics-test/out.txt` | AUTO | AUTO | append OK |
| C8-e1 | `echo hello 2>/dev/null` | AUTO | AUTO | echo + 2> はプロジェクト内で OK |
| C8-e2 | `ls /nonexistent 2> /dev/null` (space) | HEURISTIC | HEURISTIC | (メッセージなし、2択) |
| C8-e3 | `ls .tmp/heuristics-test/ 2>/dev/null` | AUTO | AUTO | プロジェクト内パスは OK |
| C8-e4 | `ls /nonexistent 2> .tmp/heuristics-test/err.txt` | HEURISTIC | HEURISTIC | (メッセージなし、2択) |
| C8-e5 | `cat /nonexistent` (no redirect) | HEURISTIC | HEURISTIC | (メッセージなし、2択) |
| C8-e6 | `ls /tmp` | ALLOW | ALLOW | (3択: Yes, allow reading from tmp/) |
| C8-v2-01 | `ls .tmp/nonexistent-dir 2>/dev/null` | AUTO | AUTO | プロジェクト内の存在しないパスでも OK |
| C8-v2-02 | `cat .tmp/nonexistent-file 2>/dev/null` | AUTO | AUTO | 同上 |
| C8-v2-03 | `ls .tmp/nonexistent-dir 2> .tmp/heuristics-test/err.txt` | AUTO | AUTO | 2> + プロジェクト内パスは OK |
| C8-v2-04 | `git log --oneline -1 2>/dev/null` | AUTO | AUTO | |
| C8-v2-05 | `grep "notfound" .tmp/heuristics-test/sample.txt 2>/dev/null` | AUTO | AUTO | |
| C8-v2-06 | `ls /usr/bin/git` | ALLOW | ALLOW | (3択: Yes, allow reading from bin/) |
| C8-v2-07 | `ls /Users/mia/Repositories/sync-sdd/.tmp/heuristics-test/sample.txt` | AUTO | AUTO | プロジェクト内の絶対パスは OK |

**Findings**:
- **`2>` はヒューリスティクスのトリガーではない** — 既存リファレンスの「`2>` は HEURISTIC」は**完全な誤帰属**
- 真のトリガーは**プロジェクト外の絶対パス**:
  - 存在しない外部パス (`/nonexistent`) → HEURISTIC (2択)
  - 存在する外部パス (`/tmp`, `/usr/bin/git`) → ALLOW (3択、ファイルアクセス許可)
  - プロジェクト内パス (相対・絶対どちらでも) → AUTO
- `2>` 自体はプロジェクト内パスなら完全に AUTO (v2 テストで 5/5 確認)
- プロジェクト内の存在しないパスへの `2>` も AUTO (C8-v2-01〜03)
- `/dev/null` はリダイレクト先としては特別扱い (AUTO) だが、コマンド引数としては外部パス扱い (ALLOW) (C8-v3-01 vs C16-05)

### Category 9: Heredoc `<<`

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C9-01 | `cat <<EOF` (unquoted, multiline) | HEURISTIC | HEURISTIC | Command contains newlines that could separate multiple commands |
| C9-02 | `cat <<'EOF'` (single-quoted delimiter) | AUTO | AUTO | |
| C9-03 | `cat <<"EOF"` (double-quoted delimiter) | AUTO | AUTO | |

| C9-e1 | `echo hello\necho world` (改行のみ、heredoc なし) | AUTO | AUTO | 改行だけでは検出されない |
| C9-e2 | `echo hello && echo world\necho third` | AUTO | AUTO | 同上 |
| C9-e3 | `cat <<EOF\n...\nEOF\necho after` (heredoc + 後続コマンド) | ALLOW | ALLOW | (3択: 完全コマンド文字列) |

**Findings**:
- unquoted heredoc のみ HEURISTIC (C9-01)。改行だけでは検出されない (C9-e1, e2)
- quoted delimiter (`<<'EOF'`, `<<"EOF"`) は AUTO
- heredoc + 後続コマンドは ALLOW (C9-e3) — C9-01 (heredoc のみ) の HEURISTIC とは異なる結果
- 既存リファレンスの「`<<'EOF'` は allow パターン未マッチ」は**誤り** — AUTO で通過する

### Category 10: Compound Commands + Quoted Dashes

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C10-01 | `date && echo "---"` | HEURISTIC | HEURISTIC | Command contains quoted characters in flag names |
| C10-02 | `date ; echo "---"` | HEURISTIC | HEURISTIC | Command contains quoted characters in flag names |
| C10-03 | `date && echo "done"` (no dash) | AUTO | AUTO | |
| C10-04 | `date && echo ---` (unquoted dash) | AUTO | AUTO | unquoted ダッシュは検出されない |
| C10-05 | `echo "-" && echo "-"` | HEURISTIC | HEURISTIC | 単一 `-` でも検出 |
| C10-06 | `echo "-flag" && echo "ok"` | HEURISTIC | HEURISTIC | |
| C10-07 | `echo "--verbose" && echo "ok"` | HEURISTIC | HEURISTIC | |
| C10-08 | `false \|\| echo "---"` | HEURISTIC | HEURISTIC | **`\|\|` でも検出 — 既存リファレンス誤り** |
| C10-09 | `echo "-"` (single command) | AUTO | AUTO | 単一コマンドは OK |
| C10-10 | `echo "--flag"` (single command) | AUTO | AUTO | |
| C10-11 | `date && echo '-'` (single quote) | HEURISTIC | HEURISTIC | single quote でも検出 |
| C10-12 | `date ; echo '-flag'` (single quote) | HEURISTIC | HEURISTIC | 同上 |

**Findings**:
- 条件: **複合コマンド (`&&`, `;`, `||`) + クォート (single/double) 内のダッシュ**
- `||` でも検出される — 既存リファレンスの「`||` は影響なし」は**誤り**
- 回避策: unquoted ダッシュ、または並列 Bash tool 呼び出し
- single quote でも回避不可

### Category 11: awk Field References `$N`

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C11-01 | `echo "a b c" \| awk '{print $2}'` | ALLOW(反復) | ALLOW(反復) | (3択、メッセージなし、ファイルアクセス許可) |
| C11-02 | `awk '{print $1}' .tmp/heuristics-test/sample.txt` | ALLOW(反復) | ALLOW(反復) | Shell expansion syntax in paths requires manual approval |
| C11-03 | `awk '{print NR}' .tmp/heuristics-test/sample.txt` | AUTO | AUTO | $ なしは OK |
| C11-04 | `echo "a b c" \| awk '{print NF}'` (no $) | AUTO | AUTO | パイプでも $ なしは OK |
| C11-05 | `echo "a b c" \| cut -d' ' -f2` | AUTO | AUTO | cut 代替は OK |

**Findings**:
- `$N` in awk → ALLOW(反復): 3択表示だが settings.json 登録済み (`Bash(awk *)`) でも毎回プロンプト
- `$` を含まない awk は AUTO
- `cut` は完全な代替手段

### Category 12: Pipe Command Allow Check

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C12-01 | `echo "test" \| grep test` | AUTO | AUTO | |
| C12-02 | `echo "test" \| wc -l` | AUTO | AUTO | |
| C12-03 | `echo "test" \| sort` | AUTO | AUTO | |
| C12-04 | `echo "test" \| uniq` | AUTO | AUTO | |
| C12-05 | `echo "test" \| tr a-z A-Z` | AUTO | AUTO | |
| C12-06 | `echo "test" \| head -1` | AUTO | AUTO | |
| C12-07 | `echo "test" \| tail -1` | AUTO | AUTO | |
| C12-08 | `echo "test" \| xargs echo` | AUTO | AUTO | |
| C12-09 | `echo "test" \| tee .tmp/heuristics-test/tee-out.txt` | AUTO | AUTO | |
| C12-10 | `cat .tmp/heuristics-test/sample.txt \| grep hello` | AUTO | AUTO | |

**Findings**:
- 本プロジェクトの settings.json では主要パイプコマンドが全て登録済みのため全 AUTO
- 未登録環境では後続コマンド個別に ALLOW が出る可能性あり

### Category 13: Control Structures

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C13-01 | `if true; then echo ok; fi` | ALLOW | ALLOW | (3択: don't ask again for: if true; then echo ok; fi) |
| C13-02 | `for i in 1 2 3; do echo $i; done` | ALLOW | ALLOW | (3択: don't ask again for: for i:*) |
| C13-03 | `while false; do echo x; done` | ALLOW | ALLOW | (3択: don't ask again for: while false; do echo x; done) |
| C13-04 | `[[ -f .tmp/heuristics-test/sample.txt ]] && echo exists` | HEURISTIC | HEURISTIC | Command contains ambiguous syntax with command separators that could be misinterpreted |
| C13-05 | `test -f .tmp/heuristics-test/sample.txt && echo exists` | AUTO | AUTO | test コマンドは OK |

**Findings**:
- `if/for/while` → ALLOW (allow パターンが完全コマンド文字列で汎用登録不可)
- `[[ ]]` → HEURISTIC (新メッセージ: ambiguous syntax with command separators)
- `test` コマンドは完全な代替手段

### Category 14: Environment Variable Prefix

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C14-01 | `FOO=bar echo hello` | ALLOW | ALLOW | (3択: don't ask again for: FOO=bar echo hello) |
| C14-02 | `FOO=bar ls .tmp/heuristics-test/` | ALLOW | ALLOW | (3択: don't ask again for: FOO=bar ls .tmp/heuristics-test/) |
| C14-03 | `env FOO=bar echo hello` | AUTO | AUTO | |
| C14-04 | `env FOO=bar ls .tmp/heuristics-test/` | AUTO | AUTO | |

**Findings**:
- `VAR=value command` → ALLOW (allow パターンが完全コマンド文字列)
- `env VAR=value command` → AUTO (`env *` パターンで allow 済み)

### Category 15: Miscellaneous Commands

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C15-01 | `eval echo hello` | ALLOW | ALLOW | (3択: don't ask again for: eval echo:*) |
| C15-02 | `export FOO=bar` | ALLOW | ALLOW | (3択: 完全コマンド文字列) |
| C15-03 | `source /dev/null` | ALLOW | ALLOW | (3択: 完全コマンド文字列) |
| C15-04 | `printf "hello\n"` | AUTO | AUTO | |
| C15-05 | `basename .tmp/heuristics-test/sample.txt` | AUTO | AUTO | |
| C15-06 | `dirname .tmp/heuristics-test/sample.txt` | AUTO | AUTO | |
| C15-07 | `realpath .tmp/heuristics-test/sample.txt` | AUTO | AUTO | |
| C15-08 | `touch .tmp/heuristics-test/touched.txt` | AUTO | AUTO | |
| C15-09 | `stat .tmp/heuristics-test/sample.txt` | AUTO | AUTO | |
| C15-10 | `file .tmp/heuristics-test/sample.txt` | AUTO | AUTO | |
| C15-11 | `wc -l .tmp/heuristics-test/sample.txt` | AUTO | AUTO | |
| C15-12 | `which git` | AUTO | AUTO | |
| C15-13 | `date +%Y-%m-%d` | AUTO | AUTO | |
| C15-14 | `uname -a` | AUTO | AUTO | |
| C15-15 | `whoami` | AUTO | AUTO | |
| C15-16 | `id` | AUTO | AUTO | |
| C15-17 | `pwd` | AUTO | AUTO | |
| C15-18 | `true` | AUTO | AUTO | |
| C15-19 | `false` | AUTO | AUTO | |

**Findings**:
- `eval`, `export`, `source` → ALLOW (shell builtins は allow 登録が必要)
- その他のコマンド (printf, basename, dirname, etc.) → 全て AUTO

### Category 16: Redirect Variations

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C16-01 | `echo hello > .tmp/heuristics-test/redir.txt` | AUTO | AUTO | |
| C16-02 | `echo hello >> .tmp/heuristics-test/redir.txt` | AUTO | AUTO | |
| C16-03 | `echo hello 1> .tmp/heuristics-test/redir.txt` | AUTO | AUTO | |
| C16-04 | `echo hello 2> .tmp/heuristics-test/redir.txt` | AUTO | AUTO | プロジェクト内なら 2> も OK |
| C16-05 | `echo hello > /dev/null` | AUTO | AUTO | |
| C16-06 | `echo hello 2>&1` | AUTO | AUTO | |
| C16-07 | `echo hello &> .tmp/heuristics-test/redir.txt` | HEURISTIC | HEURISTIC | Command contains output redirection (>) which could write to arbitrary files |

| C16-e1 | `echo hello &>/dev/null` | HEURISTIC | HEURISTIC | This command uses shell operators that require approval for safety |
| C16-e2 | `echo hello >& .tmp/heuristics-test/redir.txt` | HEURISTIC | HEURISTIC | Command contains output redirection (>) which could write to arbitrary files |
| C16-e3 | `echo hello > /tmp/heuristics-test-output.txt` | ALLOW | ALLOW | (3択: always allow access to tmp/) 外部パスへの `>` |

**Findings**:
- `>`, `>>`, `1>`, `2>`, `2>&1` → プロジェクト内パスなら全て AUTO
- `&>`, `>&` → HEURISTIC (両方とも検出。メッセージはターゲットにより異なる)
- `> /dev/null` → AUTO (`/dev/null` はリダイレクト先として特別扱い)
- `> /tmp/file` → ALLOW (外部パスへのリダイレクトはファイルアクセスチェック対象)

### Category 17: curl / Network

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C17-01 | `curl -s https://httpbin.org/status/200` | AUTO | AUTO | |
| C17-02 | `curl -s -o /dev/null -w "%{http_code}" https://httpbin.org/status/200` | AUTO | AUTO | %{} は ${} と誤検出されない |
| C17-03 | `curl -s https://httpbin.org/get \| jq .url` | AUTO | AUTO | |

### Category 18: git Variations

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C18-01 | `git status` | AUTO | AUTO | |
| C18-02 | `git log --oneline -3` | AUTO | AUTO | |
| C18-03 | `git diff --name-only HEAD~1` | AUTO | AUTO | |
| C18-04 | `git branch --list` | AUTO | AUTO | |
| C18-05 | `git rev-parse HEAD` | AUTO | AUTO | |
| C18-06 | `git log --format="%H %s" -3` | AUTO | AUTO | %H は問題なし |
| C18-07 | `git stash list` | AUTO | AUTO | |

### Category 19: Complex / Combined Patterns

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C19-01 | `echo hello && echo world` | AUTO | AUTO | |
| C19-02 | `echo hello ; echo world` | AUTO | AUTO | |
| C19-03 | `ls .tmp/heuristics-test/ && wc -l .tmp/heuristics-test/sample.txt` | AUTO | AUTO | |
| C19-04 | `echo "hello" \| grep -c hello && echo "found"` | AUTO | AUTO | |
| C19-05 | `git status && git log --oneline -1` | AUTO | AUTO | |
| C19-06 | `mkdir -p .tmp/heuristics-test/sub && ls .tmp/heuristics-test/sub` | AUTO | AUTO | |

**Findings**:
- 複合コマンドでもクォート内ダッシュ等のトリガーがなければ AUTO

### Category 20: Quoting Edge Cases

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C20-01 | `echo 'single quoted $HOME'` | AUTO | AUTO | |
| C20-02 | `echo "double quoted $HOME"` | AUTO | AUTO | $VAR (ブレースなし) は quote 内でも OK |
| C20-03 | `echo "escaped \$HOME"` | AUTO | AUTO | \$VAR は OK |
| C20-04 | `echo "escaped \$(date)"` | HEURISTIC | HEURISTIC | Command contains $() command substitution (エスケープ無効) |
| C20-05 | `echo 'literal $(date)'` | AUTO | AUTO | single quote は $() を抑制する |
| C20-06 | `` echo "backtick `date`" `` | HEURISTIC | HEURISTIC | Command contains backticks (\`) for command substitution |

**Findings**:
- single quote は `$()` と `${}` を抑制するが `<()` は抑制しない
- エスケープ `\$()` は無効（`\$VAR` は有効 — `$` 直後が `(` か否かで差異）
- `$VAR` (ブレースなし) はどのクォート内でも AUTO

### Category 21: Helper Script Execution

| ID | Command | Expect | Result | Message |
|----|---------|--------|--------|---------|
| C21-01 | `bash .sdd/settings/scripts/orphan-detect.sh` | AUTO | AUTO | `Bash(bash .sdd/settings/scripts/*)` で allow 済み |
| C21-02 | `bash .sdd/settings/scripts/grid-check.sh` | AUTO | AUTO | 同上 |
| C21-03 | `bash .sdd/settings/scripts/window-id.sh` | AUTO | AUTO | 同上 |
| C21-04 | `bash .tmp/heuristics-test/test-script.sh` | ALLOW | ALLOW | `.tmp/` は allow パターン未登録 |

## Cleanup

```bash
rm -rf .tmp/heuristics-test
```

## Results Summary

| Category | Total | AUTO | HEURISTIC | ALLOW | ALLOW(反復) | Notes |
|----------|-------|------|-----------|-------|-------------|-------|
| C1: Command Substitution | 8 | 1 | 7 | 0 | 0 | backtick も HEURISTIC |
| C2: Parameter Substitution | 9 | 5 | 4 | 0 | 0 | $VAR (no braces) で回避 |
| C3: tmux Format Strings | 8 | 3 | 0 | 5 | 0 | #{} が allow パターンマッチを破壊 |
| C4: Process Substitution | 3 | 0 | 3 | 0 | 0 | single quote でも回避不可 |
| C5: Subshell | 4 | 2 | 2 | 0 | 0 | 文字列内 () は OK |
| C6: Background | 3 | 2 | 1 | 0 | 0 | |
| C7: Stdin Redirect | 4 | 2 | 2 | 0 | 0 | |
| C8: External Path Access | 19 | 13 | 5 | 1 | 0 | 2> は無関係、外部パスが原因。v2 追加テスト 8 件 |
| C9: Heredoc | 6 | 4 | 1 | 1 | 0 | quoted delimiter は AUTO。改行だけでは未検出 |
| C10: Compound + Quoted Dash | 12 | 4 | 8 | 0 | 0 | \|\| でも検出 |
| C11: awk Field Refs | 5 | 3 | 0 | 0 | 2 | $N → ALLOW(反復) |
| C12: Pipe Allow Check | 10 | 10 | 0 | 0 | 0 | 全 AUTO (登録済み環境) |
| C13: Control Structures | 5 | 1 | 1 | 3 | 0 | [[ ]] は HEURISTIC |
| C14: Env Var Prefix | 4 | 2 | 0 | 2 | 0 | env prefix で回避 |
| C15: Misc Commands | 19 | 16 | 0 | 3 | 0 | eval/export/source は ALLOW |
| C16: Redirect Variations | 10 | 6 | 3 | 1 | 0 | &>/>&  HEURISTIC, > 外部パス ALLOW |
| C17: curl/Network | 3 | 3 | 0 | 0 | 0 | |
| C18: git Variations | 7 | 7 | 0 | 0 | 0 | |
| C19: Complex/Combined | 6 | 6 | 0 | 0 | 0 | |
| C20: Quoting Edge Cases | 6 | 4 | 2 | 0 | 0 | |
| C21: Helper Scripts | 4 | 3 | 0 | 1 | 0 | |
| **Total** | **163** | **100** | **40** | **21** | **2** | |

## Key Corrections to Existing Reference

テスト結果から判明した既存 bash-security-heuristics.md の誤り:

1. **バッククォートは OK → 誤り**: backtick も HEURISTIC (C1-05, C1-06)
2. **`#{}` は `${}` として誤検出 → 誤り**: ALLOW (サブコマンド単位の allow チェック) であり HEURISTIC ではない (C3-01, C3-02)
3. **`2>` stderr redirect は HEURISTIC → 誤り**: 真のトリガーはプロジェクト外の絶対パス。`2>` 自体はプロジェクト内なら AUTO (C8, C16-04)
4. **`||` は影響なし → 誤り**: `||` + クォート内ダッシュでも HEURISTIC (C10-08)
5. **`<<'EOF'` は allow パターン未マッチ → 誤り**: quoted delimiter は AUTO で通過 (C9-02, C9-03)
6. **unquoted heredoc の検出理由**: `<<EOF` 自体ではなく「改行」が検出トリガー (C9-01)

## New Discoveries

1. **ALLOW(反復)**: 3択表示だが settings.json 登録済みでも毎回プロンプトが出るパターン。`$N` in awk が該当 (C11-01, C11-02)
2. **外部パスアクセス**: プロジェクト外の絶対パスは HEURISTIC (存在しない) または ALLOW (存在する) (C8-e5, C8-e6)
3. **`&>` / `>&` リダイレクト**: 両方とも HEURISTIC (C16-07, C16-e1, C16-e2)
4. **`[[ ]]` 構文**: HEURISTIC — "ambiguous syntax with command separators" (C13-04)
5. **single quote の選択的保護**: `$()` と `${}` は抑制するが `<()` は抑制しない (C1-07 vs C4-03)
6. **エスケープの選択的有効性**: `\$VAR` は有効だが `\$(date)` は無効 — `$` 直後が `(` か否かで判定 (C20-03 vs C20-04)
7. **`#{}` は allow パターンマッチを破壊**: `${}` 誤検出ではなく、`tmux *` のようなワイルドカードパターンが `#{}` 含有時にマッチしなくなる (C3-e1 vs C3-e2)
8. **`/dev/null` の選択的特別扱い**: リダイレクト先 (`> /dev/null`) では AUTO、コマンド引数 (`cat /dev/null`) では外部パス ALLOW (C16-05 vs C8-v3-01)
9. **外部パスへのリダイレクト**: `> /tmp/file` は ALLOW (C16-e3)。`> /dev/null` のみ例外
10. **複合トリガーの優先順位**: 複数の HEURISTIC パターンが同時に存在する場合、1つだけ表示される。観測された優先順位: quoted-dash > $() > subshell/stdin-redirect (C-multi-01〜03)

## Changelog

| Date | CC Version | Tester | Notes |
|------|-----------|--------|-------|
| 2026-03-10 | 2.1.72 | Lead + User | Initial test run: 163 cases, 21 categories. 6 corrections to existing reference, 10 new discoveries. C8 誤帰属確定、C3 #{} 根本原因特定、複合トリガー優先順位、/dev/null 特別扱い確認 |
