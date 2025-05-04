#!/bin/bash

REMOTE_RPC="https://aztec-rpc.cerberusnode.com"
LOCAL_RPC="http://localhost:8080"

while true; do
  LOCAL=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":1}' $LOCAL_RPC | jq -r ".result.proven.number")

  REMOTE=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":1}' $REMOTE_RPC | jq -r ".result.proven.number")

  echo "🧱 Local block:  $LOCAL"
  echo "🌐 Remote block: $REMOTE"

  if [ "$LOCAL" = "$REMOTE" ]; then
    echo "✅ Your node is fully synced!"
  else
    echo "⏳ Still syncing... ($LOCAL / $REMOTE)"
  fi

  echo "-------------------------------"
  sleep 30
done
