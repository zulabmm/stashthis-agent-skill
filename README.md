# StashThis Agent Skill

Connect your AI agent to [StashThis](https://stashthis.app) for proactive stash notifications and management.

When you stash something from the web, X, YouTube, or any URL — your agent automatically summarizes it, finds connections to your other stashes, and delivers a short comment to your preferred channel.

## Install

```bash
npx skills add stashthis/stashthis-agent-skill
```

## What's Included

- **API wrapper script** — CLI to manage your stash (save, search, list, delete, etc.)
- **Webhook setup guide** — Receive real-time notifications on new stashes
- **Agent commentary instructions** — How your agent should react to stashed content
- **Full API reference** — All StashThis API endpoints documented

## Quick Start

1. Install the skill
2. Add your API key to `.secrets/stash.env`
3. (Optional) Set up the webhook for real-time notifications
4. Your agent now manages your stash and comments on new items

See [SKILL.md](SKILL.md) for full setup instructions.

## Requirements

- [StashThis](https://stashthis.app) account + API key
- `curl` and `jq` installed
- Any AI agent that supports skills (OpenClaw, Claude Code, Codex, etc.)

## Links

- [StashThis](https://stashthis.app)
- [API Docs](references/api.md)
- [Skills ecosystem](https://skills.sh)
