# StashThis API Reference

Base URL: `https://stashthis.app/api/v1`

## Authentication

Include your API key in every request:
```
X-Api-Key: sk-stash-xxxxxxxx
```
or
```
Authorization: Bearer sk-stash-xxxxxxxx
```

## Endpoints

### POST /stash — Save a URL
Content is extracted automatically.

Request:
```json
{ "url": "https://example.com/article", "tags": ["ai", "research"], "force": false }
```

Response (201):
```json
{ "item": { "id": "...", "url": "...", "title": "...", "source": "web", "tags": [...], "stashedAt": "..." }, "duplicate": false }
```

### GET /stash — List items
Query params: `limit=20`, `offset=0`, `source=web`, `tag=ai`

Response (200):
```json
{ "items": [...], "total": 150, "limit": 20, "offset": 0 }
```

### GET /stash/:id — Get single item
Response (200):
```json
{ "item": { "id": "...", "url": "...", "title": "...", "source": "web", "tags": [...] } }
```

### DELETE /stash/:id — Delete item
Response (200):
```json
{ "success": true }
```

### PATCH /stash/:id/tags — Update tags
Request:
```json
{ "tags": ["new-tag"], "replace": false }
```

### POST /search — Search stash
Semantic mode requires Pro plan.

Request:
```json
{ "query": "machine learning", "mode": "text", "limit": 5 }
```

Response (200):
```json
{ "results": [{ "item": {...}, "score": 0.95, "snippet": "..." }], "query": "...", "mode": "text" }
```

### GET /corpus — Full markdown export
Supports incremental sync with `after` parameter (Plus+).

Query params: `limit=20`, `offset=0`, `after=2026-01-01T00:00:00Z`

Response (200):
```json
{ "items": [{ "id": "...", "title": "...", "content": "# Full markdown...", ... }], "total": 150 }
```

### GET /user/usage — Check quota
Response (200):
```json
{ "plan": "free", "stashes": { "used": 75, "limit": 100, "remaining": 25 } }
```

## Webhook Payload

When a webhook fires on new stash, StashThis sends a POST to your configured URL with the item data. Authenticate incoming webhooks by validating the token in the `Authorization` header.

## Error Format
```json
{ "error": "Monthly stash quota exceeded", "code": "QUOTA_EXCEEDED" }
```

Status codes: 400 (bad request), 401 (unauthorized), 403 (plan limit), 404 (not found)
