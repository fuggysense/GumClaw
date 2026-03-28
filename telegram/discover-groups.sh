#!/bin/bash
# discover-groups.sh — Find Telegram group IDs where the bot has been added.
# Uses the Bot API to check recent updates for group messages.
#
# Usage: bash discover-groups.sh
#
# Before running:
# 1. Add the bot to your Telegram group
# 2. Send a message mentioning @yourbot in the group
# 3. Run this script within ~24 hours

set -euo pipefail

ENV_FILE="$HOME/.claude/channels/telegram/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: No bot token found at $ENV_FILE"
  echo "Run the installer first: bash install.sh"
  exit 1
fi

TOKEN=$(grep "TELEGRAM_BOT_TOKEN=" "$ENV_FILE" | cut -d= -f2)
if [[ -z "$TOKEN" ]]; then
  echo "ERROR: TELEGRAM_BOT_TOKEN is empty in $ENV_FILE"
  exit 1
fi

echo "Checking bot info..."
BOT_INFO=$(curl -s "https://api.telegram.org/bot${TOKEN}/getMe")
BOT_OK=$(echo "$BOT_INFO" | jq -r '.ok')
if [[ "$BOT_OK" != "true" ]]; then
  echo "ERROR: Invalid bot token. Check $ENV_FILE"
  exit 1
fi
BOT_NAME=$(echo "$BOT_INFO" | jq -r '.result.username')
echo "Bot: @$BOT_NAME"
echo ""

echo "Fetching recent updates..."
UPDATES=$(curl -s "https://api.telegram.org/bot${TOKEN}/getUpdates?allowed_updates=[\"message\"]")
UPDATE_OK=$(echo "$UPDATES" | jq -r '.ok')
if [[ "$UPDATE_OK" != "true" ]]; then
  echo "ERROR: Could not fetch updates."
  echo "$UPDATES" | jq '.description'
  exit 1
fi

# Extract unique groups from updates
GROUPS=$(echo "$UPDATES" | jq -r '
  [.result[]
   | select(.message.chat.type == "group" or .message.chat.type == "supergroup")
   | {
       id: (.message.chat.id | tostring),
       title: .message.chat.title,
       type: .message.chat.type
     }
  ] | unique_by(.id) | .[]
  | "\(.id)\t\(.title)\t\(.type)"
')

if [[ -z "$GROUPS" ]]; then
  echo "No groups found in recent updates."
  echo ""
  echo "To discover groups:"
  echo "  1. Add @$BOT_NAME to your Telegram group"
  echo "  2. Send a message mentioning @$BOT_NAME in the group"
  echo "  3. Run this script again"
  exit 0
fi

echo "Groups found:"
echo ""
echo "ID                      | Title                          | Type"
echo "------------------------|--------------------------------|------------"
echo "$GROUPS" | while IFS=$'\t' read -r GID TITLE TYPE; do
  printf "%-24s| %-31s| %s\n" "$GID" "$TITLE" "$TYPE"
done

echo ""
echo "To add a group to auto-pair, edit ~/.claude/channels/telegram/trusted-users.json:"
echo ""
echo '  "groups": ['
echo '    {'
echo '      "id": "<GROUP_ID_FROM_ABOVE>",'
echo '      "name": "My Group",'
echo '      "requireMention": true,'
echo '      "allowFrom": []'
echo '    }'
echo '  ]'
echo ""
echo "requireMention: true = bot must be @mentioned (recommended for groups)"
echo "allowFrom: [] = anyone in group can use it. Add user IDs to restrict."
echo ""
echo "After editing, run: bash ~/.claude/channels/telegram/auto-pair.sh"
