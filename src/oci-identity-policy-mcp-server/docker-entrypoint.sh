#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at
# https://oss.oracle.com/licenses/upl.

set -euo pipefail

server_module="oci_policy_analysis.mcp_server"

if [[ "$#" -gt 0 ]]; then
  if [[ "$1" == --* ]]; then
    exec python3.13 -m "${server_module}" "$@"
  fi
  exec "$@"
fi

auth_mode="${MCP_AUTH_MODE:-resource_principal}"
args=()

case "${auth_mode}" in
  resource_principal)
    args+=(--resource-principal)
    ;;
  instance_principal)
    args+=(--instance-principal)
    ;;
  profile)
    args+=(--profile "${OCI_PROFILE:-DEFAULT}")
    ;;
  cache)
    if [[ -z "${MCP_CACHE_NAME:-}" ]]; then
      echo "MCP_CACHE_NAME is required when MCP_AUTH_MODE=cache" >&2
      exit 64
    fi
    args+=(--use-cache "${MCP_CACHE_NAME}")
    ;;
  session_token)
    if [[ -z "${OCI_SESSION_TOKEN:-}" ]]; then
      echo "OCI_SESSION_TOKEN is required when MCP_AUTH_MODE=session_token" >&2
      exit 64
    fi
    args+=(--session-token "${OCI_SESSION_TOKEN}")
    ;;
  *)
    echo "Unsupported MCP_AUTH_MODE: ${auth_mode}" >&2
    exit 64
    ;;
esac

args+=(--transport "${MCP_TRANSPORT:-streamable-http}")
args+=(--host "${MCP_HOST:-0.0.0.0}")
args+=(--port "${MCP_PORT:-8765}")
args+=(--log-level "${MCP_LOG_LEVEL:-INFO}")
args+=(--compartment-domain-search-depth "${MCP_COMPARTMENT_DOMAIN_SEARCH_DEPTH:-2}")

case "${MCP_SAVE_CACHE_AFTER_LOAD:-true}" in
  0|false|FALSE|False|no|NO|No)
    args+=(--dont-save-cache-after-load)
    ;;
esac

exec python3.13 -m "${server_module}" "${args[@]}"
