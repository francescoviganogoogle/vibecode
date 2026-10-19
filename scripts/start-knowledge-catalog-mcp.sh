#!/usr/bin/env bash
# ==============================================================================
# Knowledge Catalog MCP Server Launcher
# ==============================================================================
# Launches Google Cloud GenAI Toolbox configured for Google Cloud Knowledge
# Catalog (Dataplex Catalog) for project lookerdemos.
#
# Usage:
#   # Run in STDIO mode (default, for Antigravity MCP integration):
#   ./scripts/start-knowledge-catalog-mcp.sh --stdio
#
#   # Run as a remote Streamable HTTP MCP server:
#   ./scripts/start-knowledge-catalog-mcp.sh --http --port 5005 --address 0.0.0.0
# ==============================================================================

set -euo pipefail

export DATAPLEX_PROJECT="${DATAPLEX_PROJECT:-lookerdemos}"

TOOLBOX_BIN="${TOOLBOX_BIN:-}"
if [ -z "$TOOLBOX_BIN" ]; then
  for candidate in \
      "/home/vigano/.local/bin/toolbox" \
      "/home/vigano/mcp-toolbox/toolbox" \
      "$(command -v toolbox 2>/dev/null || true)"; do
    if [ -x "$candidate" ]; then
      TOOLBOX_BIN="$candidate"
      break
    fi
  done
fi

if [ -z "$TOOLBOX_BIN" ] || [ ! -x "$TOOLBOX_BIN" ]; then
  echo "Error: toolbox binary not found or not executable." >&2
  echo "Please install Google GenAI Toolbox or set TOOLBOX_BIN." >&2
  exit 1
fi

MODE="${1:---stdio}"

case "$MODE" in
  --stdio)
    exec "$TOOLBOX_BIN" --prebuilt dataplex --stdio
    ;;
  --http|--server)
    shift || true
    PORT="${1:-5005}"
    ADDRESS="${2:-127.0.0.1}"
    echo "Starting Knowledge Catalog MCP Server on ${ADDRESS}:${PORT} for project ${DATAPLEX_PROJECT}..."
    exec "$TOOLBOX_BIN" --prebuilt dataplex --address "$ADDRESS" --port "$PORT"
    ;;
  *)
    exec "$TOOLBOX_BIN" --prebuilt dataplex "$@"
    ;;
esac

