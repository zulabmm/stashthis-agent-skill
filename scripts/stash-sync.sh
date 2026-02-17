#!/bin/bash
# Sync StashThis content as local .md files
# Usage: stash-sync.sh [output-dir] [after-timestamp]
#   stash-sync.sh                          # Full sync to default dir
#   stash-sync.sh ./stash                  # Full sync to custom dir
#   stash-sync.sh ./stash 2026-02-01       # Incremental sync (Plus+)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Find secrets
for candidate in "$SKILL_DIR/.secrets/stash.env" "$SKILL_DIR/../../.secrets/stash.env" "$HOME/.secrets/stash.env"; do
  if [[ -f "$candidate" ]]; then
    source "$candidate"
    break
  fi
done

if [[ -z "${STASH_API_KEY:-}" ]]; then
  echo "Error: STASH_API_KEY not set." >&2
  exit 1
fi

# Default output dir: workspace/stash or current dir/stash
OUTPUT_DIR="${1:-./stash}"
AFTER="${2:-}"

BASE="https://stashthis.app/api/v1"
H=(-H "X-Api-Key: $STASH_API_KEY" -H "Content-Type: application/json")

mkdir -p "$OUTPUT_DIR"

offset=0
total=1
synced=0
skipped=0

echo "Syncing stash to $OUTPUT_DIR..."

while [ "$offset" -lt "$total" ]; do
  url="$BASE/corpus?limit=50&offset=$offset"
  [[ -n "$AFTER" ]] && url="$url&after=${AFTER}T00:00:00Z"
  
  resp=$(curl -s "${H[@]}" "$url")
  total=$(echo "$resp" | jq '.total')
  
  if [[ "$total" == "null" || -z "$total" ]]; then
    echo "Error: Failed to fetch corpus" >&2
    echo "$resp" | jq . 2>/dev/null || echo "$resp"
    exit 1
  fi
  
  echo "$resp" | jq -c '.items[]' 2>/dev/null | while read -r item; do
    filepath=$(echo "$item" | jq -r '.filePath // empty')
    slug=$(echo "$item" | jq -r '.slug // .id')
    source_type=$(echo "$item" | jq -r '.source // "web"')
    content=$(echo "$item" | jq -r '.content // empty')
    title=$(echo "$item" | jq -r '.title // "Untitled"')
    url_val=$(echo "$item" | jq -r '.url // ""')
    stashed_at=$(echo "$item" | jq -r '.stashedAt // ""')
    tags=$(echo "$item" | jq -r '(.tags // []) | join(", ")')
    
    # Use filePath from API if available, otherwise construct one
    if [[ -n "$filepath" ]]; then
      outfile="$OUTPUT_DIR/$filepath"
    else
      dir="$OUTPUT_DIR/$source_type"
      outfile="$dir/$slug.md"
    fi
    
    # Create directory
    mkdir -p "$(dirname "$outfile")"
    
    # Skip if file exists and content hasn't changed
    if [[ -f "$outfile" ]]; then
      skipped=$((skipped + 1))
      continue
    fi
    
    # Write frontmatter + content
    {
      echo "---"
      echo "title: \"$title\""
      echo "url: $url_val"
      echo "source: $source_type"
      echo "stashedAt: $stashed_at"
      [[ -n "$tags" ]] && echo "tags: [$tags]"
      echo "---"
      echo ""
      if [[ -n "$content" ]]; then
        echo "$content"
      else
        echo "# $title"
        echo ""
        echo "Source: $url_val"
      fi
    } > "$outfile"
    
    synced=$((synced + 1))
    echo "  ✓ $filepath"
  done
  
  offset=$((offset + 50))
done

echo ""
echo "Done. Synced: $synced new, Skipped: $skipped existing (Total: $total)"
