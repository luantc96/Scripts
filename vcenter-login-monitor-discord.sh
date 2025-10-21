#!/bin/bash
# vCenter 8.x SSO Login → Discord
# Author: LuanTC

LOG_FILE="/var/log/vmware/sso/websso.log"
STATE_FILE="/tmp/vcenter-last-login-line.txt"
WEBHOOK_URL="https://discord.com/api/webhooks/1430096893869817919/-0Ztx9UlyRed38EUltgEPYMIIUhLJjCWXNKgbEJuY5Iq6R0BI8w0FWc92ZdGsb5ro6ti"
HOSTNAME=$(hostname -f)

# Get newest Login
LATEST_LINE=$(grep "com.vmware.sso.LoginSuccess" "$LOG_FILE" | tail -1)
[ -z "$LATEST_LINE" ] && exit 0

# Check duplicate
[ ! -f "$STATE_FILE" ] && echo "" > "$STATE_FILE"
LAST_SAVED=$(cat "$STATE_FILE")
if [ "$LATEST_LINE" = "$LAST_SAVED" ]; then
    exit 0
fi
echo "$LATEST_LINE" > "$STATE_FILE"

# Clean escape JSON
JSON=$(echo "$LATEST_LINE" | sed 's/^.*auditlogger] //')
CLEAN=$(echo "$JSON" | tr -d '\\')

# Parse
USER=$(echo "$CLEAN" | grep -o '"user":"[^"]*"' | cut -d'"' -f4)
IP=$(echo "$CLEAN" | grep -o '"client":"[^"]*"' | cut -d'"' -f4)
TIME_GMT=$(echo "$CLEAN" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)

# ----Adjust Time (GMT → GMT+7) ----
#Separate Date & Time
DATE_PART=$(echo "$TIME_GMT" | awk '{print $1}')
TIME_PART=$(echo "$TIME_GMT" | awk '{print $2}')

# Add 7 Hour
TIME_LOCAL=$(date -d "$DATE_PART $TIME_PART 7 hour" +"%Y-%m-%d %H:%M:%S")

# Debug
#echo "HOST=$HOSTNAME | USER=$USER | IP=$IP | TIME=$TIME_LOCAL"

# Send Discord
if [ -n "$USER" ] && [ -n "$IP" ]; then
    PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "🔐 vCenter Login Detected",
    "color": 16753920,
    "fields": [
      {"name": "👤 User", "value": "$USER", "inline": true},
      {"name": "🌐 IP", "value": "$IP", "inline": true},
      {"name": "🕒 Time (GMT+7)", "value": "$TIME_LOCAL", "inline": false},
      {"name": "🖥️ Hostname", "value": "$HOSTNAME", "inline": false}
    ]
  }]
}
EOF
)
    /usr/bin/curl -s -H "Content-Type: application/json" \
      -X POST -d "$PAYLOAD" "$WEBHOOK_URL"
fi
