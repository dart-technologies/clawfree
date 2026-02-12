/// Pre-built demo scenarios for hackathon presentations.
/// Each scenario contains keyword triggers and realistic AI responses.
class DemoScenarios {
  DemoScenarios._();

  // ---------------------------------------------------------------------------
  // Scenario 1 — Voice Agent Builder (multi-turn)
  // ---------------------------------------------------------------------------

  /// Step 1: User asks to create a Telegram bot for GitHub notifications.
  static const agentCreationPrompt =
      'Create a Telegram bot that summarizes my GitHub notifications';

  static const agentCreationResponse = '''Great idea! I'll set up a **GitHub Notification Summarizer** agent for you. Here's the initial configuration:

```json
{
  "agent": {
    "name": "My Agent",
    "description": "Summarizes GitHub notifications and sends daily digests via Telegram",
    "model": "claude-opus-4-6",
    "tools": ["web_search", "api"],
    "channels": ["telegram"],
    "schedule": "every 6 hours",
    "system_prompt": "You are a GitHub notification assistant. Fetch the user's GitHub notifications, categorize them (PRs, issues, releases, mentions), and produce a concise summary with action items."
  }
}
```

**What this agent does:**
1. 🔔 Connects to the GitHub Notifications API via your personal token
2. 📊 Categorizes notifications — PRs, Issues, Releases, Mentions
3. 📝 Generates a concise summary with priority ranking
4. 📤 Sends the digest to your Telegram chat every 6 hours

**Next steps — you can refine:**
- Change the agent name (`"My Agent"` → something memorable)
- Add more tools (e.g. `browser` for reading full PR diffs)
- Adjust the schedule or add more channels

Just tell me what to change! 🚀''';

  /// Step 2: User refines — rename + add tool.
  static const agentRefinementPrompt =
      'Change the name to GitDigest and add the browser tool';

  static const agentRefinementResponse = '''Done! Updated the configuration:

```json
{
  "agent": {
    "name": "GitDigest",
    "description": "Summarizes GitHub notifications and sends daily digests via Telegram",
    "model": "claude-opus-4-6",
    "tools": ["web_search", "api", "browser"],
    "channels": ["telegram"],
    "schedule": "every 6 hours",
    "system_prompt": "You are a GitHub notification assistant. Fetch the user's GitHub notifications, categorize them (PRs, issues, releases, mentions), and produce a concise summary with action items. Use the browser tool to read full PR descriptions and issue threads when needed."
  }
}
```

**Changes applied:**
- ✅ Name → **GitDigest**
- ✅ Added **browser** tool — the agent can now read full PR diffs and issue threads
- ✅ Updated system prompt to leverage the browser capability

Your **GitDigest** agent is ready to deploy. Say "deploy" or "test" when you're set! 🎯''';

  // ---------------------------------------------------------------------------
  // Scenario 2 — Dashboard
  // ---------------------------------------------------------------------------

  static const dashboardResponse = '''Here are your active agents:

| # | Agent | Model | Status | Channels | Last Active |
|---|-------|-------|--------|----------|-------------|
| 1 | **GitDigest** | Claude Opus 4.6 | 🟢 Active | Telegram | 2 min ago |
| 2 | **SalesTracker** | Claude Sonnet 4.5 | 🟢 Active | Slack, Email | 15 min ago |
| 3 | **ContentWriter** | Claude Opus 4.6 | 🟡 Idle | Discord | 3 hours ago |
| 4 | **BugPatrol** | Claude Sonnet 4.5 | 🔴 Paused | GitHub, Telegram | 1 day ago |

**Summary:** 4 agents total — 2 active, 1 idle, 1 paused.

💡 **Quick actions:**
- "Test GitDigest" — run a live test
- "Pause SalesTracker" — temporarily disable
- "Delete BugPatrol" — remove the agent
- "Create a new agent" — start the builder''';

  // ---------------------------------------------------------------------------
  // Scenario 3 — Agent Test
  // ---------------------------------------------------------------------------

  static const agentTestResponse = '''🧪 **Testing GitDigest...**

✅ **Connection:** GitHub API — authenticated (scope: notifications, repo)
✅ **Model:** Claude Opus 4.6 — responding (latency: 320ms)
✅ **Channel:** Telegram — bot token valid, webhook active
✅ **Tools:** web_search ✓ | api ✓ | browser ✓

**Sample output** (based on your latest notifications):

> 📬 **GitDigest Summary — Feb 12, 2026**
>
> **🔴 Action Required (3)**
> - PR #247 `feat: add SSO login` — reviewer requested changes (assigned to you)
> - Issue #189 `Critical: API rate limit exceeded` — tagged @you, 2h ago
> - PR #251 `fix: memory leak in worker` — your PR, CI passed, ready to merge
>
> **🟡 FYI (5)**
> - Release v2.4.0 published on `main`
> - 3 new issues in `chatclaw/core` (triaged, low priority)

All checks passed. **GitDigest is ready for production.** 🚀''';

  // ---------------------------------------------------------------------------
  // Keyword → response mapping for DemoCacheAiClient
  // ---------------------------------------------------------------------------

  static const List<MapEntry<String, String>> allScenarios = [
    // Agent creation (specific prompts first)
    MapEntry('gitdigest', agentRefinementResponse),
    MapEntry('change the name', agentRefinementResponse),
    // Dashboard
    MapEntry('show my agents', dashboardResponse),
    // Test
    MapEntry('test gitdigest', agentTestResponse),
  ];
}
