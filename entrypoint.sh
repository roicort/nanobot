#!/bin/bash
set -e

CONFIG_FILE="${CONFIG_FILE:-$HOME/.nanobot/config.json}"

# Initialize config via nanobot onboard if it doesn't exist yet
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Config not found, running nanobot onboard..."
  nanobot onboard
fi

# Helper: update a key in the JSON config using jq
# Usage: set_val '.path.to.key' '"string"' or set_val '.path.to.key' 'number'
set_val() {
  local key="$1"
  local value="$2"
  local tmp
  tmp=$(mktemp)
  jq "$key = $value" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
}

# ── Agents defaults ──────────────────────────────────────────────
[ -n "$NANOBOT_WORKSPACE" ]          && set_val '.agents.defaults.workspace'          "\"$NANOBOT_WORKSPACE\""
[ -n "$NANOBOT_MODEL" ]              && set_val '.agents.defaults.model'              "\"$NANOBOT_MODEL\""
[ -n "$NANOBOT_MAX_TOKENS" ]         && set_val '.agents.defaults.maxTokens'          "$NANOBOT_MAX_TOKENS"
[ -n "$NANOBOT_TEMPERATURE" ]        && set_val '.agents.defaults.temperature'        "$NANOBOT_TEMPERATURE"
[ -n "$NANOBOT_MAX_TOOL_ITERATIONS" ] && set_val '.agents.defaults.maxToolIterations' "$NANOBOT_MAX_TOOL_ITERATIONS"

# ── Channels: WhatsApp ───────────────────────────────────────────
[ -n "$WHATSAPP_ENABLED" ]    && set_val '.channels.whatsapp.enabled'    "$WHATSAPP_ENABLED"
[ -n "$WHATSAPP_BRIDGE_URL" ] && set_val '.channels.whatsapp.bridgeUrl'  "\"$WHATSAPP_BRIDGE_URL\""

# ── Channels: Telegram ───────────────────────────────────────────
[ -n "$TELEGRAM_ENABLED" ] && set_val '.channels.telegram.enabled' "$TELEGRAM_ENABLED"
[ -n "$TELEGRAM_TOKEN" ]   && set_val '.channels.telegram.token'   "\"$TELEGRAM_TOKEN\""
[ -n "$TELEGRAM_PROXY" ]   && set_val '.channels.telegram.proxy'   "\"$TELEGRAM_PROXY\""
[ -n "$TELEGRAM_ALLOW_FROM" ] && {
  json_array=$(echo "$TELEGRAM_ALLOW_FROM" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$"; ""))')
  tmp=$(mktemp)
  jq ".channels.telegram.allowFrom = $json_array" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
}

# ── Channels: Discord ────────────────────────────────────────────
[ -n "$DISCORD_ENABLED" ]     && set_val '.channels.discord.enabled'     "$DISCORD_ENABLED"
[ -n "$DISCORD_TOKEN" ]       && set_val '.channels.discord.token'       "\"$DISCORD_TOKEN\""
[ -n "$DISCORD_GATEWAY_URL" ] && set_val '.channels.discord.gatewayUrl'  "\"$DISCORD_GATEWAY_URL\""
[ -n "$DISCORD_INTENTS" ]     && set_val '.channels.discord.intents'     "$DISCORD_INTENTS"

# ── Channels: Feishu ─────────────────────────────────────────────
[ -n "$FEISHU_ENABLED" ]            && set_val '.channels.feishu.enabled'            "$FEISHU_ENABLED"
[ -n "$FEISHU_APP_ID" ]             && set_val '.channels.feishu.appId'              "\"$FEISHU_APP_ID\""
[ -n "$FEISHU_APP_SECRET" ]         && set_val '.channels.feishu.appSecret'          "\"$FEISHU_APP_SECRET\""
[ -n "$FEISHU_ENCRYPT_KEY" ]        && set_val '.channels.feishu.encryptKey'         "\"$FEISHU_ENCRYPT_KEY\""
[ -n "$FEISHU_VERIFICATION_TOKEN" ] && set_val '.channels.feishu.verificationToken'  "\"$FEISHU_VERIFICATION_TOKEN\""

# ── Providers ─────────────────────────────────────────────────────
PROVIDERS=("anthropic" "openai" "openrouter" "deepseek" "groq" "zhipu" "vllm" "gemini" "moonshot")

for provider in "${PROVIDERS[@]}"; do
  upper=$(echo "$provider" | tr '[:lower:]' '[:upper:]')

  key_var="${upper}_API_KEY"
  base_var="${upper}_API_BASE"

  [ -n "${!key_var}" ]  && set_val ".providers.${provider}.apiKey"  "\"${!key_var}\""
  [ -n "${!base_var}" ] && set_val ".providers.${provider}.apiBase" "\"${!base_var}\""
done

# ── Gateway ───────────────────────────────────────────────────────
[ -n "$GATEWAY_HOST" ] && set_val '.gateway.host' "\"$GATEWAY_HOST\""
[ -n "$GATEWAY_PORT" ] && set_val '.gateway.port' "$GATEWAY_PORT"

# ── Tools ─────────────────────────────────────────────────────────
[ -n "$WEB_SEARCH_API_KEY" ]     && set_val '.tools.web.search.apiKey'      "\"$WEB_SEARCH_API_KEY\""
[ -n "$WEB_SEARCH_MAX_RESULTS" ] && set_val '.tools.web.search.maxResults'  "$WEB_SEARCH_MAX_RESULTS"
[ -n "$EXEC_TIMEOUT" ]           && set_val '.tools.exec.timeout'           "$EXEC_TIMEOUT"
[ -n "$RESTRICT_TO_WORKSPACE" ]  && set_val '.tools.restrictToWorkspace'    "$RESTRICT_TO_WORKSPACE"

echo "✔ Config generated at $CONFIG_FILE"

# Execute the main process (pass remaining args or default command)
exec "$@"
