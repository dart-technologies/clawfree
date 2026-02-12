# clawfree — Submission Summary

**clawfree** is a hands-free AI agent creation tool that lets anyone build, configure, and deploy AI agents using only their voice. Speak a request — Opus 4.6 simultaneously generates a conversational response and a live, interactive configuration UI via the A2UI protocol, rendered in real-time by Flutter genUI. Users refine agents through multi-turn voice dialogue; the UI updates instantly with each instruction. No code, no JSON, no typing required.

**Opus 4.6 usage:** Every interaction is a single Opus 4.6 streaming call that produces both natural language reasoning and structured A2UI JSON for dynamic UI generation. Opus handles intent classification, agent configuration extraction, form generation, multi-turn UI updates, and self-correction on invalid output — all in one pass.

**Impact:** clawfree makes expert-level AI tooling accessible to non-technical users. Anyone with a voice — including via Apple Watch — can create production-ready agents connected to 18+ messaging channels through OpenClaw, eliminating the barrier between powerful AI infrastructure and everyday users.

**Tech stack:** Flutter genUI v0.9, Opus 4.6 via OpenClaw Gateway, Firebase (Auth/Firestore/Storage), platform-native STT/TTS, Apple Watch companion app, A2UI streaming protocol.

Built in under a week by **Team genUIne** (Michael Chow & Roy Lin).
