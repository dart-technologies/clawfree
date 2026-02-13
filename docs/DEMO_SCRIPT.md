# ClawFree — 3-Minute Demo Video Script

## Overview
- **Duration**: 3:00
- **Target**: Anthropic "Built with Opus 4.6" Hackathon judges
- **Scoring**: Demo 30% | Impact 25% | Opus 4.6 Use 25% | Depth 20%
- **Devices**: MacBook (macOS), iPhone, iPad, Apple Watch

---

## Scene 1: Opening Hook (0:00 - 0:15)

**Visual**: Dark screen → ClawFree logo fade in → tagline appears

**Voiceover**:
> "What if your AI wasn't trapped behind a keyboard? What if you could talk to it from your watch, your phone, your tablet — and it built the UI for you in real-time?"

**Text on screen**: "ClawFree — Hands-free AI, everywhere you are"

---

## Scene 2: Architecture Overview (0:15 - 0:30)

**Visual**: Animated diagram showing 4 devices → OpenClaw Gateway → Opus 4.6 → genUI Surface

**Voiceover**:
> "ClawFree connects your Apple Watch, iPhone, iPad, and Mac to OpenClaw — your local AI gateway. Every interaction is powered by Opus 4.6, which generates rich, interactive UIs on the fly using our A2UI protocol."

---

## Scene 3: Voice Trip Planning — Watch (0:30 - 1:15)

**Visual**: Apple Watch on wrist / Watch simulator

**Action**:
1. Tap mic on Watch → speak: "Plan a 3-day trip to Tokyo"
2. Watch shows "Sending..." → "Planning..."
3. Cut to iPhone showing genUI Surface rendering:
   - Day-by-day itinerary cards
   - Budget breakdown
   - Map preview
4. TTS plays: "Here's a 3-day Tokyo itinerary..."

**Voiceover**:
> "Start from your watch. Just speak — Opus 4.6 generates a complete travel planner with interactive cards, budget estimates, and daily schedules. No templates. Every UI is generated fresh."

**Key moment**: Show the A2UI JSON briefly → transformed into beautiful UI

---

## Scene 4: Voice Follow-up — iPhone (1:15 - 1:45)

**Visual**: iPhone screen

**Action**:
1. VoiceOrb pulses → user speaks: "Add Osaka on day 2"
2. genUI Surface updates — Osaka card appears in Day 2
3. User speaks: "What's the budget now?"
4. Budget card updates with new total
5. User taps "Book this itinerary" button on genUI surface

**Voiceover**:
> "Continue the conversation hands-free. Ask follow-ups, and the UI evolves. Mix voice and touch — tap to confirm, speak to explore. Opus 4.6 maintains context across turns."

---

## Scene 5: Control Tower — macOS (1:45 - 2:15)

**Visual**: macOS dashboard (TabletLayout)

**Action**:
1. Show full Control Tower: sidebar with agents, telemetry header with health vitals
2. Connected devices showing: iPhone ✅, Watch ✅, iPad ✅
3. Main surface showing the trip plan from iPhone
4. Type or speak: "Create an agent called TripBot specialized in Japan travel"
5. genUI renders agent configuration form
6. Fill settings → Save

**Voiceover**:
> "The Mac is your command center. See every connected device, monitor your AI's health, and manage agents. Here we're creating a specialized travel agent — Opus 4.6 generates the entire configuration UI from a single voice command."

---

## Scene 6: Multi-device Sync — iPad (2:15 - 2:35)

**Visual**: iPad simulator showing TabletLayout

**Action**:
1. iPad shows same trip plan synced from iPhone session
2. Pinch to zoom on map
3. Voice: "Show me hotel options near Shibuya"
4. genUI renders hotel comparison cards

**Voiceover**:
> "Every device stays in sync through OpenClaw. Pick up where you left off on any screen. The iPad's larger display shows the full power of genUI surfaces."

---

## Scene 7: The Vision — Ambient Computing (2:35 - 2:50)

**Visual**: Split screen showing all 4 devices simultaneously

**Voiceover**:
> "This is ambient computing. Your AI is always there — on your wrist for quick commands, in your pocket for deeper interactions, on your desk for full control. No cloud dependency — everything runs on your local network. Today it's powered by Opus 4.6. Tomorrow, it could run on local models for zero-cost, always-on intelligence."

---

## Scene 8: Closing (2:50 - 3:00)

**Visual**: ClawFree logo + tech stack badges + GitHub link

**Text on screen**:
- "Built with Opus 4.6 + genUI v0.9 + OpenClaw"
- "Team genUIne: Mike & Roy"
- GitHub: github.com/dart-technologies/clawfree

**Voiceover**:
> "ClawFree. Your AI, unbound."

---

## Production Notes

### Recording Tips
- Screen record each device separately, composite in editor
- Use QuickTime for Mac/iPad simulator recording
- iPhone: either real device or simulator
- Watch: simulator is fine (hardware not required)
- Add subtle background music (lo-fi / ambient)
- Transitions: cross-dissolve between scenes

### Demo Mode
- Use `DEMO_MODE=true` for cached responses (reliable)
- For Scene 3-4, consider one LIVE Opus 4.6 call to show real generation
- Have backup cached responses ready

### Tools
- **Screen recording**: QuickTime Player / OBS
- **Video editing**: iMovie / DaVinci Resolve (free)
- **Captions**: Add key text overlays for architecture/protocol
- **Music**: freemusicarchive.org or YouTube Audio Library
