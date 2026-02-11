# OpenClaw Integration Primer

OpenClaw is a self-hosted, local-first AI assistant platform (MIT, TypeScript/Node.js) that
connects AI models (Anthropic, OpenAI, Google, etc.) to 18+ messaging channels via a central
WebSocket gateway. We integrate with it as the backend for clawfree's Flutter genUI frontend.

---

## Gateway Architecture

The gateway is the single entry point for all clients. It listens on **port 18789**.

```
ws://127.0.0.1:18789   (WebSocket control plane)
http://127.0.0.1:18789  (HTTP APIs + Control UI)
```

**What the gateway does:**
- Session management (create, list, compaction)
- Agent runtime (Pi SDK) -- runs tools, manages context
- Channel routing (Telegram, Discord, Slack, WhatsApp, etc.)
- Config/auth/cron management
- Canvas host (A2UI rendering)
- OpenAI-compatible HTTP API (`/v1/chat/completions`)

**RPC over WebSocket:**
Clients connect via WebSocket and call RPC methods for agents, sessions, config, and cron.
The protocol is extensible -- new RPC methods can be added (e.g., `genui.render`,
`genui.interact`) by extending the gateway server handlers.

**Key source paths** (in the openclaw repo):

| Path | Purpose |
|------|---------|
| `src/gateway/` | WebSocket server, RPC handlers, HTTP APIs |
| `src/agents/` | Agent runtime, tool execution, Pi SDK integration |
| `src/channels/` | Channel adapters (core: WhatsApp, Telegram, Discord, Slack, Signal) |
| `src/config/` | JSON5 config system with Zod validation, `$include` directives |
| `src/canvas-host/` | A2UI rendering engine (Canvas) |
| `src/browser/` | Playwright-based browser automation |
| `src/memory/` | SQLite + sqlite-vec hybrid search |
| `src/cron/` | Scheduled task execution |
| `extensions/` | Additional channel plugins (MS Teams, Matrix, LINE, etc.) |
| `ui/` | Web UI (Lit 3.x web components, served at `/`) |

---

## Agent Config Format

Agents are defined in `~/.openclaw/openclaw.json` (JSON5). Minimal structure:

```jsonc
{
  "agents": {
    "my-agent": {
      "model": "claude-opus-4-6",         // or "gpt-5.3-codex", "gemini-2.0", etc.
      "systemPrompt": "You are a helpful assistant.",
      "tools": ["browser", "exec", "file"],
      "channels": {
        "telegram": { "enabled": true },
        "slack": { "enabled": true }
      },
      "skills": ["github-pr-review"],
      "toolPolicy": {
        "allow": ["*"],                   // or specific tool names
        "deny": []
      }
    }
  },
  "gateway": {
    "port": 18789,
    "bind": "127.0.0.1",                 // or "lan" for LAN access
    "auth": {
      "token": "your-shared-secret"       // or password-based (bcrypt)
    }
  },
  "models": {
    "anthropic": { "apiKey": "$ANTHROPIC_API_KEY" },
    "openai": { "apiKey": "$OPENAI_API_KEY" }
  }
}
```

Environment variables are substituted with `$VAR` syntax. Config supports `$include`
directives to split across files.

---

## Canvas / A2UI

Canvas is OpenClaw's agent-driven visual workspace, rendered via **A2UI** (Anthropic UI).

- **Gateway side:** `src/canvas-host/` handles push/reset/eval/snapshot of A2UI content
- **Client side:** Native apps (macOS/iOS/Android) and the web UI each have a canvas renderer
- **For clawfree:** We render A2UI via Flutter's genUI `SurfaceController`, bypassing the
  existing canvas host. The gateway streams Opus 4.6 text + A2UI JSON; our Flutter client
  parses it with `A2uiTransportAdapter` and renders Surface widgets directly.

The existing OpenClaw canvas host is a reference for how A2UI messages flow, but clawfree
replaces the rendering layer with Flutter genUI.

---

## Docker Setup

**docker-compose.yml** (minimal):

```yaml
services:
  openclaw:
    image: openclaw/openclaw:latest
    ports:
      - "18789:18789"
    volumes:
      - ./config:/root/.openclaw
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
```

**Run standalone:**

```bash
docker run -p 18789:18789 -v ~/.openclaw:/root/.openclaw openclaw/openclaw
```

**Verify gateway is up:**

```bash
curl http://127.0.0.1:18789/health
# or connect via WebSocket at ws://127.0.0.1:18789
```

---

## Runtime Requirements

- **Node.js** >= 22.12.0 (if running outside Docker)
- **pnpm** 10.23.0 (package manager for OpenClaw source builds)
- **TypeScript** 5.9.3 (ESM)

For clawfree, we run the gateway via Docker and connect from Flutter over WebSocket.
No need to build OpenClaw from source unless extending gateway RPC methods.
