# claude-stream-progress.jq
# Formats claude -p --output-format stream-json for tmux pane progress display.
# Usage: claude -p ... --output-format stream-json --verbose --include-partial-messages | jq -rjf this-file
#
# Shows:
#   [model] tools:N                     — session init
#   [ToolName] {"arg": "value", ...}    — tool calls with arguments
#   text output                         — assistant text responses
#   >> stop_reason | out:N              — turn boundary
#   !! rate limit NN%                   — rate limit warning
#   --- result | duration | cost        — completion summary
#
# Note: Extended thinking and streaming are mutually exclusive in Claude Agent SDK.
# When thinking is enabled, StreamEvent is not emitted. (ref: Agent SDK Known Limitations)

# Session init: show model and tool count
if .type == "system" and .subtype == "init" then
  "\u001b[35m[\(.model // "unknown")] tools:\(.tools | length)\u001b[0m\n"

# Turn start: show input token usage (cache hit ratio)
elif .type == "stream_event" and .event.type == "message_start" then
  "\u001b[2min:\(.event.message.usage.input_tokens // 0) cache_read:\(.event.message.usage.cache_read_input_tokens // 0) cache_create:\(.event.message.usage.cache_creation_input_tokens // 0)\u001b[0m\n"

# Tool call start: show tool name (cyan)
elif .type == "stream_event" and .event.type == "content_block_start" and .event.content_block.type == "tool_use" then
  "\n\u001b[36m[\(.event.content_block.name)]\u001b[0m "

# Tool arguments: accumulate partial JSON inline
elif .type == "stream_event" and .event.delta.type? == "input_json_delta" then
  .event.delta.partial_json

# Block end: newline
elif .type == "stream_event" and .event.type == "content_block_stop" then
  "\n"

# Assistant text: stream as-is
elif .type == "stream_event" and .event.delta.type? == "text_delta" then
  .event.delta.text

# Turn end: show stop reason and output tokens
elif .type == "stream_event" and .event.type == "message_delta" then
  "\n\u001b[2m>> \(.event.delta.stop_reason // "unknown") | out:\(.event.usage.output_tokens // 0)\u001b[0m\n"

# Rate limit warning
elif .type == "rate_limit_event" then
  "\u001b[33m!! rate limit \((.rate_limit_info.utilization // 0) * 100 | floor)%\u001b[0m\n"

# Result summary: show cost and duration (yellow)
elif .type == "result" then
  "\n\u001b[33m--- \(.result // "done") | \(.duration_ms // 0)ms | $\(.total_cost_usd // 0)\u001b[0m\n"

else
  empty
end
