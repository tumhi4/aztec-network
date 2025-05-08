#!/bin/bash

REMOTE_RPC="https://aztec-rpc.cerberusnode.com"
LOCAL_RPC="http://localhost:8080"

while true; do
  echo "🔍 Checking Aztec node sync status at $(date '+%Y-%m-%d %H:%M:%S')"

  # Check LOCAL node status
  LOCAL_RESPONSE=$(curl -s -m 5 -X POST -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":1}' $LOCAL_RPC)

  if [ -z "$LOCAL_RESPONSE" ] || [[ "$LOCAL_RESPONSE" == *"error"* ]]; then
    echo "❌ Local node not responding or returned an error. Please check if it's running on $LOCAL_RPC"
    LOCAL="N/A"
  else
    LOCAL=$(echo "$LOCAL_RESPONSE" | jq -r ".result.proven.number")
  fi

  # Check REMOTE node status
  REMOTE_RESPONSE=$(curl -s -m 5 -X POST -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":1}' $REMOTE_RPC)

  if [ -z "$REMOTE_RESPONSE" ] || [[ "$REMOTE_RESPONSE" == *"error"* ]]; then
    echo "⚠️ Remote RPC ($REMOTE_RPC) not responding or returned an error."
    REMOTE="N/A"
  else
    REMOTE=$(echo "$REMOTE_RESPONSE" | jq -r ".result.proven.number")
  fi

  echo "🧱 Local block:  $LOCAL"
  echo "🌐 Remote block: $REMOTE"

  if [[ "$LOCAL" == "N/A" ]] || [[ "$REMOTE" == "N/A" ]]; then
    echo "🚫 Cannot determine sync status due to an error in one of the RPC responses."
  elif [ "$LOCAL" = "$REMOTE" ]; then
    echo "✅ Your node is fully synced!"
  else
    echo "⏳ Still syncing... ($LOCAL / $REMOTE)"
  fi

  echo "-------------------------------"
  sleep 10
done
