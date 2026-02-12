# clawfree: Hackathon Sprint Plan

**Hackathon**: [Built with Opus 4.6](https://cerebralvalley.ai/e/claude-code-hackathon) (Cerebral Valley / Anthropic)

**Deadline**: Mon Feb 16, 3:00 PM EST

**Team genUIne**: [Mike](https://cerebralvalley.ai/u/michow) + [Roy](https://cerebralvalley.ai/u/roylin)

**Repo**: [dart-technologies/clawfree](https://github.com/dart-technologies/clawfree)

---

## What We're Building

**clawfree** = a hands-free, voice-enabled Flutter genUI frontend for OpenClaw.

Users speak to create, configure, and interact with AI agents through dynamically generated UIs -- no typing, no JSON editing, no code. Opus 4.6 powers both the conversational reasoning and the real-time UI generation via the A2UI protocol.

**Problem Statement #2** (Break the Barriers) -- Expert AI agent configuration locked behind JSON editing, CLI, and technical knowledge. clawfree puts it in everyone's hands through voice + generative UI.

**Why it wins**:
- **Demo (30%)**: Live voice-driven agent creation on Apple Watch + adaptive UI on iPad
- **Impact (25%)**: Unlocks OpenClaw (165k+ stars) for non-technical users
- **Opus 4.6 Use (25%)**: Opus powers both reasoning (agent config) AND UI generation (A2UI JSON) in a single streaming call
- **Depth (20%)**: Full stack -- gateway A2UI server, Flutter genUI client, multi-device voice pipeline

---

## Team Roles (Async Collaboration)

### Mike (@chownation) -- Flutter genUI + Infrastructure
- Flutter genUI v0.9 integration (SurfaceController, A2uiTransportAdapter, Surface widget)
- Anthropic AI client (Opus 4.6 streaming)
- A2UI system prompt engineering + schema injection
- Local Docker setup for OpenClaw gateway
- Multi-turn conversation, error handling, agent config export
- Adaptive UI layouts (phone, tablet, web)

### Roy (@royguanyu) -- Voice Interactions + OpenClaw
- Speech-to-text / text-to-speech pipeline
- Non-keyboard interaction patterns (Apple Watch voice, iPad touch, hands-free mode)
- OpenClaw gateway configuration and agent management (power user)
- Voice conversation flow design
- Multi-device demo scenarios (Watch -> iPad continuity)
- Demo recording and video production

### Collaboration Model
- **Async by default** -- each dev works independently on their track
- **Daily standup** (scheduled sync) -- share progress, unblock, align on integration
- **Midpoint merge (Thu-Fri)** -- Mike's adaptive genUI + Roy's voice interactions combine into unified demo
- **Shared contract**: A2UI protocol is the interface boundary. Mike produces rendered surfaces from Opus; Roy pipes voice input/output to those surfaces.

---

## Daily Sprints

### Day 0: Tue Feb 10 (PM) -- Foundation
**Standup**: Kick-off sync, confirm roles, agree on integration contract

| Track | Owner | Tasks |
|-------|-------|-------|
| **genUI** | Mike | Scaffold Flutter project, add genUI v0.9 dep, verify SurfaceController renders hardcoded A2UI |
| **genUI** | Mike | Docker Compose for OpenClaw gateway, verify health endpoint |
| **Voice** | Roy | Clone OpenClaw, explore gateway config as power user, identify A2UI integration points |
| **Voice** | Roy | Spike speech_to_text + flutter_tts on iOS, test mic permissions |

**Exit**: Flutter renders a hardcoded surface. Gateway container starts. Voice capture works on device.

---

### Day 1: Wed Feb 11 -- Core Pipelines
**Standup**: AM sync -- confirm both pipelines are alive, agree on prompt format

| Track | Owner | Tasks |
|-------|-------|-------|
| **genUI** | Mike | Build Anthropic AI client (HTTP SSE streaming to Opus 4.6) |
| **genUI** | Mike | Wire chat session: user text -> Opus -> A2uiTransportAdapter -> Surface |
| **genUI** | Mike | Inject A2UI schema into system prompt, verify Opus outputs valid A2UI JSON |
| **Voice** | Roy | Build voice service layer: STT continuous mode, TTS readback |
| **Voice** | Roy | Design voice UX: push-to-talk vs hands-free, wake activation |
| **Voice** | Roy | Test OpenClaw agent creation via CLI/API, document the config shape |

**Exit**: Mike: type text -> see generated UI. Roy: speak -> get transcript + TTS readback.

---

### Day 2: Thu Feb 12 -- Integration Begins (Midpoint)
**Standup**: AM sync -- demo both tracks to each other, plan merge

| Track | Owner | Tasks |
|-------|-------|-------|
| **genUI** | Mike | Agent builder prompt engineering (name, model, tools, channels form) |
| **genUI** | Mike | Multi-turn: Opus refines UI across conversation turns |
| **genUI** | Mike | Adaptive layout: same A2UI renders appropriately on phone vs tablet vs web |
| **Voice** | Roy | Wire voice input -> Mike's chat session (STT text -> sendMessage) |
| **Voice** | Roy | Wire TTS to Opus text responses (voice reads back confirmations) |
| **Voice** | Roy | Apple Watch voice spike: minimal watchOS companion for voice-only interaction |
| **Merge** | Both | End-of-day integration: speak -> see adaptive UI -> hear confirmation |

**Exit**: Speak "Create a Telegram bot" -> form UI appears -> voice confirms.

---

### Day 3: Fri Feb 13 -- Deep Integration + Polish
**Standup**: AM sync -- review merged flow, identify gaps

| Track | Owner | Tasks |
|-------|-------|-------|
| **genUI** | Mike | Error handling: validation retries, text fallback, loading states |
| **genUI** | Mike | Agent config export to OpenClaw JSON, "Test Agent" flow |
| **genUI** | Mike | Theme + branding (OpenClaw colors, clawfree identity) |
| **Voice** | Roy | Continuous voice conversation: speak -> UI updates -> speak again |
| **Voice** | Roy | Apple Watch -> iPad handoff demo (start on Watch, see UI on iPad) |
| **Voice** | Roy | Voice-only mode: entire flow without touching screen |
| **Both** | Both | Rehearse demo scenario end-to-end |

**Exit**: Full voice conversation creating and testing an agent across devices.

---

### Day 4: Sat Feb 14 -- Demo Scenarios + Recording
**Standup**: AM sync -- lock demo script, assign recording roles

| Track | Owner | Tasks |
|-------|-------|-------|
| **Demo** | Both | Scenario 1: Voice agent builder (Watch -> iPad, "Create a GitHub bot") |
| **Demo** | Both | Scenario 2: Dashboard ("Show my agents" -> adaptive grid) |
| **Demo** | Mike | Demo mode with pre-cached Opus responses (network failure backup) |
| **Demo** | Roy | Screen recording of each scenario (backup footage) |
| **Polish** | Mike | Performance: reduce streaming latency, optimize chunk handling |
| **Polish** | Roy | Animations: surface fade-in, voice indicator pulse |

**Exit**: 3 demo scenarios reliable. Backup footage captured.

---

### Day 5: Sun Feb 15 -- Video + Submission Prep
**Standup**: AM sync -- review footage, finalize script

| Track | Owner | Tasks |
|-------|-------|-------|
| **Video** | Both | Write tight 3-min script hitting all judging criteria |
| **Video** | Roy | Record final demo (screen capture + voice) |
| **Video** | Roy | Edit to 3 min, add captions/architecture overlay |
| **Submit** | Mike | Written summary (100-200 words) |
| **Submit** | Mike | Final README, code cleanup, ensure repo builds from clean clone |
| **Submit** | Both | Review all materials together |

**Exit**: Demo video done. Submission materials ready.

---

### Day 6: Mon Feb 16 (AM) -- Submit
**Standup**: Final check

| Track | Owner | Tasks |
|-------|-------|-------|
| **Final** | Both | Run through all demo flows one last time |
| **Final** | Roy | Re-record video if issues found, upload to YouTube |
| **Final** | Mike | Push final code, verify repo is public |
| **Submit** | Mike | Submit on [Cerebral Valley portal](https://cerebralvalley.ai/e/claude-code-hackathon/hackathon/submit) |
| **Submit** | Both | Verify all links accessible |

**Deadline: Mon Feb 16, 3:00 PM EST**

---

## TODO Checklist

### Infrastructure + genUI Core + Architecture (Mike)
- [x] Infrastructure: Flutter + genUI v0.9, CORS proxy, Makefile
- [x] genUI Core: AI client (SSE streaming), chat session, A2UI schema injection, multi-turn, self-correction, demo mode (12 cached responses), agent store, adaptive layout, animations, theming
- [x] Architecture: ChatScreen (5 extracted widgets), ChatSession (InteractionRouter + PromptLibrary extracted), VoiceController + VoiceServiceFactory, centralized assets/icons
- [x] Testing: 350+ tests across 35 files (unit + widget + e2e integration)
- [x] Gateway: GatewayClient (HTTP /health, /agents, /onboard, /sessions), HealthPoller (15s periodic + session polling), connect_gateway action, agent sync on home transition
- [x] Remote Sessions: Live device indicators from `/sessions` endpoint, demo fallback, self-filtering
- [x] Deployment: Docker Compose prod stack (frontend + OpenClaw + Redis), Makefile qa/stop/health targets
- [x] QR Pairing: In-app QR scanner (mobile_scanner v6), gateway /pair redirect, deep link handling (cold + warm start), gateway URL validation
- [x] Watch Sync: WatchSyncService with debounce, MethodChannel bridge, updateApplicationContext, ConnectivityProvider, PulseMonitorView with health-adaptive pulse

### Voice + Interaction (Roy)
- [ ] Swap to real voice: `PlatformSttService` + `PlatformTtsService` in VoiceServiceFactory (auto on native, mock on web/demo)
- [x] Device-level mic permissions (iOS Info.plist, macOS entitlements, Android manifest)
- [ ] Continuous listening / hands-free mode (`VoiceController.continuousMode`)
- [ ] Push-to-talk fallback
- [ ] Voice → chat session integration (STT text → sendMessage)
- [ ] TTS action confirmations
- [ ] Apple Watch voice companion (spike)
- [ ] Watch → iPad handoff flow
- [ ] Voice-only mode (no screen touch needed)

### Remaining Integration (Both)
- [x] Surface interaction → OpenClaw agent API (`GatewayClient.createAgent` + fire-and-forget from router)
- [x] OpenClaw gateway: agent persistence + management endpoints (dual-proxy: /agents, /sessions, /onboard → OpenClaw)

### Demo + Submission
- [ ] Demo scenario 1: Voice agent builder (Watch + iPad)
- [ ] Demo scenario 2: Agent dashboard ("Show my agents")
- [ ] 3-minute demo video
- [ ] 100-200 word written summary
- [ ] Submission on Cerebral Valley portal

---

## Demo Script (3 Minutes)

### Opening (15s)
"clawfree -- hands-free AI agent creation powered by Opus 4.6 and Flutter genUI. Speak to create. No code required."

### Scene 1: Voice Agent Creation (75s)
1. Show Apple Watch -- tap, speak: "Create a Telegram bot that summarizes my GitHub notifications"
2. Cut to iPad -- Opus streams: text explanation + real-time form UI generation
3. Form appears: name field, model picker, tool checkboxes, channel selector
4. Speak: "Change the name to GitDigest and add the browser tool"
5. Multi-turn: Opus updates UI, fields change live
6. Speak: "Save it"
7. Watch + iPad both confirm: "GitDigest saved and connected to Telegram"

### Scene 2: Dashboard (30s)
1. Speak: "Show my agents"
2. Adaptive dashboard UI generates on iPad -- agent cards with status
3. Speak: "Test GitDigest" -- test message sent, response shown

### Scene 3: Under the Hood (30s)
Architecture overlay:
- Voice -> Flutter genUI -> OpenClaw Gateway -> Opus 4.6 -> A2UI -> Flutter
- "One Opus call generates both the reasoning AND the interface"

### Closing (30s)
"clawfree breaks the barrier between expert AI tools and everyone else. Built entirely with Opus 4.6 and Claude Code in under a week by Team genUIne."

---

## Risk Mitigations

| Risk | Mitigation |
|------|------------|
| Opus generates invalid A2UI JSON | Validation + 2 retries with feedback + text fallback |
| Voice recognition accuracy | Push-to-talk fallback, text input always available |
| Apple Watch complexity | Spike early (Day 2); if blocked, demo voice on iPad only |
| SSE connection drops | Reconnect with backoff, demo mode backup |
| genUI v0.9 breaking changes | Pin to specific commit hash |
| Demo network failure | Demo mode with pre-cached Opus responses |
| API credit burn | Monitor usage, cache repeated prompts |

---

## Tech Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| AI Model | Claude Opus 4.6 | claude-opus-4-6 |
| Gateway | clawfree CORS proxy (Node.js) + OpenClaw | lightweight / v2026.2.9 |
| GenUI SDK | flutter/genui | v0.9 (feature/v0.9-migration) |
| Frontend | Flutter | 3.38.9 (stable, darwin-arm64) |
| Protocol | A2UI v0.9 | Prompt First |
| Voice STT | speech_to_text | latest |
| Voice TTS | flutter_tts | latest |
| Container | Docker Compose | v29+ |
| Package mgr | yarn | preferred over npm |
| Dev tool | Claude Code (Opus 4.6) | latest |
