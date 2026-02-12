# EARS Format Guidelines

## Overview
EARS (Easy Approach to Requirements Syntax) is the standard format for acceptance criteria in spec-driven development.

EARS patterns describe the logical structure of a requirement (condition + subject + response) and are not tied to any particular natural language.  
All acceptance criteria should be written in the target language configured for the specification (for example, `spec.json.language` / `{{LANG_CODE}}`).  
Keep EARS trigger keywords and fixed phrases in English (`When`, `If`, `While`, `Where`, `The system shall`, `The [system] shall`) and localize only the variable parts (`[event]`, `[precondition]`, `[trigger]`, `[feature is included]`, `[response/action]`) into the target language. Do not interleave target-language text inside the trigger or fixed English phrases themselves.

## Primary EARS Patterns

### 1. Event-Driven Requirements
- **Pattern**: When [event], the [system] shall [response/action]
- **Use Case**: Responses to specific events or triggers
- **Examples**:
  - (EN) When user clicks checkout button, the Checkout Service shall validate cart contents
  - (JA) When ユーザーがチェックアウトボタンをクリックする, the 決済サービス shall カート内容を検証する
  - (ZH) When 用户点击结账按钮, the 结账服务 shall 验证购物车内容

### 2. State-Driven Requirements
- **Pattern**: While [precondition], the [system] shall [response/action]
- **Use Case**: Behavior dependent on system state or preconditions
- **Examples**:
  - (EN) While payment is processing, the Checkout Service shall display loading indicator
  - (JA) While 決済処理中, the 決済サービス shall ローディングインジケーターを表示する
  - (ZH) While 支付处理中, the 结账服务 shall 显示加载指示器

### 3. Unwanted Behavior Requirements
- **Pattern**: If [trigger], the [system] shall [response/action]
- **Use Case**: System response to errors, failures, or undesired situations
- **Examples**:
  - (EN) If invalid credit card number is entered, then the website shall display error message
  - (JA) If 無効なクレジットカード番号が入力された場合, then the ウェブサイト shall エラーメッセージを表示する
  - (ZH) If 输入无效的信用卡号, then the 网站 shall 显示错误消息

### 4. Optional Feature Requirements
- **Pattern**: Where [feature is included], the [system] shall [response/action]
- **Use Case**: Requirements for optional or conditional features
- **Examples**:
  - (EN) Where the car has a sunroof, the car shall have a sunroof control panel
  - (JA) Where 車にサンルーフがある場合, the 車 shall サンルーフコントロールパネルを備える
  - (ZH) Where 汽车配备天窗, the 汽车 shall 配备天窗控制面板

### 5. Ubiquitous Requirements
- **Pattern**: The [system] shall [response/action]
- **Use Case**: Always-active requirements and fundamental system properties
- **Examples**:
  - (EN) The mobile phone shall have a mass of less than 100 grams
  - (JA) The モバイルフォン shall 100グラム未満の質量を持つ
  - (ZH) The 手机 shall 质量小于100克

## Combined Patterns
- While [precondition], when [event], the [system] shall [response/action]
- When [event] and [additional condition], the [system] shall [response/action]

**Combined Examples**:
- (EN) While user is logged in, when session expires, the Auth Service shall redirect to login page
- (JA) While ユーザーがログイン中, when セッションが期限切れになる, the 認証サービス shall ログインページにリダイレクトする
- (ZH) While 用户已登录, when 会话过期, the 认证服务 shall 重定向到登录页面

## Subject Selection Guidelines
- **Software Projects**: Use concrete system/service name (e.g., "Checkout Service", "User Auth Module")
- **Process/Workflow**: Use responsible team/role (e.g., "Support Team", "Review Process")
- **Non-Software**: Use appropriate subject (e.g., "Marketing Campaign", "Documentation")

## Quality Criteria
- Requirements must be testable, verifiable, and describe a single behavior.
- Use objective language: "shall" for mandatory behavior, "should" for recommendations; avoid ambiguous terms.
- Follow EARS syntax: [condition], the [system] shall [response/action].

## AC Stability Classification

Each acceptance criterion SHOULD include a stability tag to indicate its change tolerance. Prefix the EARS pattern with the tag in square brackets:

- **`[constraint]`**: Near-immutable invariant. Changing this requires full downstream re-review (design + tasks + implementation).
  - Example: `[constraint] The JWT shall be signed with HS256 algorithm`
  - Typical use: Security algorithms, protocol versions, regulatory compliance
- **`[contract]`**: Interface agreement. Changing this requires design re-generation.
  - Example: `[contract] The JWT payload shall contain sub, email, exp claims`
  - Typical use: API shapes, data schemas, inter-service contracts
- **`[behavior]`**: Implementation behavior. Can be changed with tasks re-generation only.
  - Example: `[behavior] The Cookie shall have HttpOnly=True, SameSite=Lax attributes`
  - Typical use: UI behaviors, configuration defaults, non-critical business rules

**Default**: If no tag is provided, ACs are treated as `[behavior]` (most flexible).

**Impact rules for change**:
- `[constraint]` change → re-run `/sdd-design`, `/sdd-tasks`, `/sdd-impl`
- `[contract]` change → re-run `/sdd-design`, `/sdd-tasks`
- `[behavior]` change → re-run `/sdd-tasks` only

## Incremental Detail Levels

Requirements can be authored at three progressive detail levels. Each level builds on the previous:

- **interface**: Inputs, outputs, and error categories only. No edge cases or detailed flows. Suitable for early-stage exploration when contracts are more important than behavior.
- **normal**: Full happy-path behavior with standard error handling. Default level for most requirements.
- **edge-cases**: Boundary conditions, race conditions, failure recovery, and all error scenarios. Used when comprehensive coverage is needed before implementation.

EARS patterns apply at all levels. The detail level is recorded in the requirements.md header as `## Detail Level: {level}`.
