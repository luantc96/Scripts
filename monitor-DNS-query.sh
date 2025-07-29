#!/bin/bash

DOMAIN="baomoi.com"
DNS_SERVERS=("8.8.8.8" "1.1.1.1")
NUM_QUERIES=10
WEBHOOK_URL="https://Your-webhook-URL-here"

send_to_discord() {
    local message="$1"
    ESCAPED=$(echo "$message" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    curl -s -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"$ESCAPED\"}" \
         "$WEBHOOK_URL" > /dev/null
}

FINAL_BLOCK=""
for DNS in "${DNS_SERVERS[@]}"; do
    echo "==== DNS Server: $DNS ===="
    RESULT_BLOCK="**DNS Server: $DNS**"
    for ((i=1; i<=NUM_QUERIES; i++)); do
        RESULT=$(dig +timeout=2 +tries=1 +stats @"$DNS" "$DOMAIN")
        QUERY_TIME=$(echo "$RESULT" | grep "Query time" | awk '{print $4}')
        STATUS="OK"
        if [[ -z "$QUERY_TIME" ]]; then
            STATUS="TIMEOUT"
            QUERY_TIME="-"
        else
            QUERY_TIME="${QUERY_TIME}ms"
        fi
        LINE="[$i] Response: $QUERY_TIME - $STATUS"
        echo "$LINE"
        RESULT_BLOCK+=$'\n'"$LINE"
    done
    echo ""
    FINAL_BLOCK+=$'\n'"$RESULT_BLOCK"$'\n'
done

send_to_discord "$FINAL_BLOCK"
