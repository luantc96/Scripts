#!/bin/bash

WEBHOOK_URL="https://discord.com/api/webhooks/1389136531381555220/8m5Sy8mjRgZAapUPcQvY1iCyZK2VP_ypS6b_-kh0wljDinRszhwwdUP2l7rQ7EihysHB"
TARGET="8.8.8.8"
THRESHOLD_MS=50
ALERT_THRESHOLD=3
# Get My IP
MY_IP=$(curl -s ifconfig.me)
# Ping 10 pakages
results=$(ping -c 10 -i 0.5 $TARGET | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')

high_latency_count=0
message="My IP = $MY_IP\nPing results to $TARGET:\n"

for latency in $results; do
    message+=" - ${latency}ms\n"
    if (( $(echo "$latency > $THRESHOLD_MS" | bc -l) )); then
        ((high_latency_count++))
    fi
done

if [ "$high_latency_count" -ge "$ALERT_THRESHOLD" ]; then
    escaped_message=$(echo -e "$message" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    payload="{\"content\": \"⚠️ WARNING: High Latency to 8.8.8.8!\\n$escaped_message\"}"
    curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$WEBHOOK_URL" > /dev/null
fi
