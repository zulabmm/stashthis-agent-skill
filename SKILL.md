---
name: stashthis-agent
description: "Integrate StashThis (stashthis.app) with your AI agent for proactive stash notifications and management. Use when the user wants to set up StashThis webhooks, manage their stash via API, or get AI commentary on newly stashed items. Also use when the user mentions 'stash,' 'stashthis,' 'bookmark agent,' 'save and summarize,' or wants their agent to react to saved content. Also triggers on the setup prompt: 'I just installed the StashThis agent skill.'"
---

# StashThis Agent Integration

Connect your AI agent to [StashThis](https://stashthis.app) so it reacts when you stash content from the web, X, YouTube, or any URL.

## Guided Setup Flow

When the user pastes the StashThis setup prompt, follow these steps in order:

### Step 1: API Key

Ask the user for their StashThis API key. Save it:

```bash
mkdir -p <workspace>/.secrets
echo 'STASH_API_KEY=<key>' > <workspace>/.secrets/stash.env
```

Verify it works by running: `scripts/stash.sh usage`

If it returns plan info, the key is valid. If unauthorized, ask user to check the key.

### Step 2: Check OpenClaw Hooks Config

Read the OpenClaw config (use `gateway config.get` tool or read `~/.openclaw/openclaw.json`).

Check for:
- `hooks.enabled` — must be `true`
- `hooks.token` — must exist (if missing, generate a secure random hex string)
- `gateway.port` — note the port (default 18789)

If hooks aren't configured, patch the config:

```json5
{
  hooks: {
    enabled: true,
    token: "<generated-secure-token>",
    mappings: [
      {
        match: { path: "stash" },
        action: "agent",
        agentId: "main",
        wakeMode: "now",
        name: "Stash",
        deliver: true,
        channel: "last"
      }
    ]
  }
}
```

If hooks already exist, just add the stash mapping to the existing mappings array.

### Step 3: Determine Public Webhook URL

The user needs a public URL that routes to their OpenClaw gateway. Check in this order:

1. **Running tunnel** — check for ngrok, cloudflared, or similar (`ps aux | grep ngrok` etc.)
2. **Public IP / domain** — if on a VPS, the gateway port may be directly accessible
3. **No public URL** — tell the user they need a tunnel (ngrok, Cloudflare Tunnel, etc.) and help set one up

The webhook URL format is: `https://<public-domain>/hooks/stash`

**Important:** If the gateway port isn't directly exposed (e.g., another service uses the tunnel port), the user may need a reverse proxy (Caddy/nginx) to route `/hooks/*` to the gateway. Help set this up if needed.

### Step 4: Give User the Connection Details

Tell the user exactly what to paste into StashThis settings:

- **Webhook URL:** `https://<their-domain>/hooks/stash`
- **Hooks Token:** the value from `hooks.token`

Format it clearly so they can copy-paste.

### Step 5: Test

Ask the user to stash something (or trigger a test webhook from StashThis settings). Confirm the hook fires and arrives.

## Handling Stash Webhooks

When a `[STASH]` system message arrives (webhook fired):

1. Fetch the latest item: `scripts/stash.sh list 1`
2. Get full details if needed: `scripts/stash.sh get <id>`
3. Optionally fetch page content via web if stash content is thin
4. Search for related stashes: `scripts/stash.sh search "<keywords>"`
5. Generate a short comment and deliver to the user's preferred channel:
   - 🦝 **New stash:** "Title"
   - 2-3 line summary of what it is
   - Why it's interesting or notable
   - Connections to existing stashes or current projects if any
6. Keep it casual, useful, not annoying
7. If clearly just a quick bookmark with no depth, one line is enough

## Local Sync

Sync your stash as `.md` files so your agent can search content locally without API calls.

```bash
scripts/stash-sync.sh [output-dir] [after-date]
```

Examples:
- `scripts/stash-sync.sh` — full sync to `./stash/`
- `scripts/stash-sync.sh ~/stash` — sync to custom dir
- `scripts/stash-sync.sh ./stash 2026-02-01` — incremental sync (Plus+ plans)

Files are saved with YAML frontmatter (title, url, source, tags) and full markdown content. Directory structure mirrors the source:
```
stash/
├── web/     — articles, blogs
├── x/       — tweets/threads
└── youtube/ — videos
```

When handling a `[STASH]` webhook, after commenting, also run sync to keep local files current:
```bash
scripts/stash-sync.sh <workspace>/stash
```

This lets you search stash content locally (grep, semantic search) without hitting the API.

## CLI Reference

The `scripts/stash.sh` wrapper supports all StashThis API operations:

| Command | Description |
|---------|-------------|
| `stash.sh usage` | Check plan and remaining quota |
| `stash.sh list [limit] [offset] [tag]` | List stashed items |
| `stash.sh get <id>` | Get a single item |
| `stash.sh save <url> [tags]` | Stash a URL (comma-separated tags) |
| `stash.sh search <query> [mode]` | Search stash (text or semantic) |
| `stash.sh delete <id>` | Delete an item |
| `stash.sh tags <id> <tags> [replace]` | Add/replace tags |
| `stash.sh corpus [limit] [offset] [after]` | Export full markdown content |
| `stash-sync.sh [dir] [after]` | Sync stash as local `.md` files |

For full API details, see `references/api.md`.
