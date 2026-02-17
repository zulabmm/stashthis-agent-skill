#!/bin/bash
# StashThis API wrapper
# Usage: stash.sh <command> [args]
#   stash.sh usage
#   stash.sh list [limit] [offset] [tag]
#   stash.sh get <id>
#   stash.sh save <url> [tags comma-separated]
#   stash.sh search <query> [mode: text|semantic]
#   stash.sh delete <id>
#   stash.sh tags <id> <tags comma-separated> [replace: true|false]
#   stash.sh corpus [limit] [offset] [after]

set -euo pipefail

# Find secrets file relative to this script's skill directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Look for .secrets/stash.env in skill dir, workspace, or home
for candidate in "$SKILL_DIR/.secrets/stash.env" "$SKILL_DIR/../../.secrets/stash.env" "$HOME/.secrets/stash.env"; do
  if [[ -f "$candidate" ]]; then
    source "$candidate"
    break
  fi
done

if [[ -z "${STASH_API_KEY:-}" ]]; then
  echo "Error: STASH_API_KEY not set. Create .secrets/stash.env with your API key." >&2
  exit 1
fi

BASE="https://stashthis.app/api/v1"
H=(-H "X-Api-Key: $STASH_API_KEY" -H "Content-Type: application/json")

case "${1:-help}" in
  usage)
    curl -s "${H[@]}" "$BASE/user/usage" | jq .
    ;;
  list)
    limit="${2:-20}"; offset="${3:-0}"; tag="${4:-}"
    url="$BASE/stash?limit=$limit&offset=$offset"
    [[ -n "$tag" ]] && url="$url&tag=$tag"
    curl -s "${H[@]}" "$url" | jq .
    ;;
  get)
    curl -s "${H[@]}" "$BASE/stash/$2" | jq .
    ;;
  save)
    url="$2"; tags="${3:-}"
    if [[ -n "$tags" ]]; then
      tag_json=$(echo "$tags" | tr ',' '\n' | jq -R . | jq -s .)
      curl -s "${H[@]}" -X POST "$BASE/stash" -d "{\"url\":\"$url\",\"tags\":$tag_json}" | jq .
    else
      curl -s "${H[@]}" -X POST "$BASE/stash" -d "{\"url\":\"$url\"}" | jq .
    fi
    ;;
  search)
    query="$2"; mode="${3:-text}"
    curl -s "${H[@]}" -X POST "$BASE/search" -d "{\"query\":\"$query\",\"mode\":\"$mode\",\"limit\":5}" | jq .
    ;;
  delete)
    curl -s "${H[@]}" -X DELETE "$BASE/stash/$2" | jq .
    ;;
  tags)
    id="$2"; tags="$3"; replace="${4:-false}"
    tag_json=$(echo "$tags" | tr ',' '\n' | jq -R . | jq -s .)
    curl -s "${H[@]}" -X PATCH "$BASE/stash/$id/tags" -d "{\"tags\":$tag_json,\"replace\":$replace}" | jq .
    ;;
  corpus)
    limit="${2:-20}"; offset="${3:-0}"; after="${4:-}"
    url="$BASE/corpus?limit=$limit&offset=$offset"
    [[ -n "$after" ]] && url="$url&after=$after"
    curl -s "${H[@]}" "$url" | jq .
    ;;
  *)
    echo "StashThis CLI - https://stashthis.app"
    echo ""
    echo "Usage: stash.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  usage                          Check plan and quota"
    echo "  list [limit] [offset] [tag]    List stashed items"
    echo "  get <id>                       Get a single item"
    echo "  save <url> [tags]              Stash a URL (comma-separated tags)"
    echo "  search <query> [mode]          Search (text or semantic)"
    echo "  delete <id>                    Delete an item"
    echo "  tags <id> <tags> [replace]     Add/replace tags on an item"
    echo "  corpus [limit] [offset] [after] Export full markdown content"
    ;;
esac
