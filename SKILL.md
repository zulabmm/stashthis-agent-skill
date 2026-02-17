---
name: stashthis-agent
description: "Integrate StashThis (stashthis.app) with your AI agent for proactive stash notifications and management. Use when the user wants to set up StashThis webhooks, manage their stash via API, or get AI commentary on newly stashed items. Also use when the user mentions 'stash,' 'stashthis,' 'bookmark agent,' 'save and summarize,' or wants their agent to react to saved content."
---

# StashThis Agent Integration

Connect your AI agent to [StashThis](https://stashthis.app) so it reacts when you stash content from the web, X, YouTube, or any URL.

## What This Skill Does

1. **API wrapper** — CLI script to manage your stash (save, search, list, delete, etc.)
2. **Webhook setup** — Receive real-time notifications when new items are stashed
3. **Agent commentary** — Automatically summarize and comment on stashed items

## Setup

### Step 1: API Key

1. Get your API key from [stashthis.app/settings](https://stashthis.app/settings)
2. Create the secrets file:

```bash
mkdir -p .secrets
cat > .secrets/stash.env << 'EOF'
STASH_API_KEY=sk-stash-YOUR_KEY_HERE
EOF
```

3. Verify it works:

```bash
scripts/stash.sh usage
```

### Step 2: Webhook (Optional — for proactive notifications)

StashThis can notify your agent when you stash something new. This requires:

1. A **public URL** that routes to your agent's webhook endpoint
2. A **webhook token** for authentication

#### For OpenClaw users

Add a hook mapping to your `openclaw.json`:

```json5
{
  hooks: {
    enabled: true,
    token: "your-webhook-secret",
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

Your webhook URL will be: `https://your-domain/hooks/stash`

Configure this URL in your StashThis webhook settings with the auth header:
```
Authorization: Bearer your-webhook-secret
```

#### For other agents

Point the StashThis webhook to any endpoint your agent can receive. The payload contains the stashed item data. See `references/api.md` for payload format.

#### Reverse proxy (if sharing a single public URL)

If you already use your public URL for another service (e.g., WhatsApp), use a reverse proxy like Caddy or nginx to route by path. Example Caddyfile:

```
:18800 {
    handle /hooks/* {
        reverse_proxy 127.0.0.1:18789
    }
    handle /webhook/other-service* {
        reverse_proxy 127.0.0.1:OTHER_PORT
    }
}
```

## Handling Stash Webhooks

When a webhook fires (new item stashed):

1. Fetch the latest item: `scripts/stash.sh list 1`
2. Get full details: `scripts/stash.sh get <id>`
3. Optionally fetch page content via web if stash content is thin
4. Search for related stashes: `scripts/stash.sh search "<keywords>"`
5. Generate a short comment:
   - Title and source
   - 2-3 line summary
   - Why it's interesting
   - Connections to existing stashes or projects (if any)
6. Deliver the comment to the user's preferred channel

**Tone:** Casual, useful, not annoying. If the stash is clearly just a quick bookmark, keep it to one line.

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

For full API details, see `references/api.md`.
