# Aeria

Aeria is a Life OS for iPhone — a personal intelligence layer connecting your
time, tasks, commitments, documents, possessions, money, places, people,
routines, and goals into one calm, native Apple experience.

**iPhone**: Today (with real MapKit "leave by" travel time and a Dynamic
Island countdown), Ask Aeria, Life (Inbox with voice capture, Loose Ends,
Promises, Goals, Habits, Moments, People, Places, Decisions, What If),
Vault (document scanning, Assets, Subscriptions), Search, Privacy Center.
**Apple Watch**: a read-only "what's next." **Widgets**: small/medium/large
plus a travel Live Activity. **Share Extension**: send text, links, images,
or PDFs from any app into Aeria. **Siri/Shortcuts**: Check My Life, Ask
Aeria, Add Task, Remember.

Full product/engineering documentation lives in [`docs/`](docs/):

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — module map, the Life Graph, data model
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — MVP → V1.1 → V2 → V3 phasing
- [`SETUP-MAC.md`](SETUP-MAC.md) — one-time Mac setup to build and run Aeria
- [`docs/PRIVACY.md`](docs/PRIVACY.md) — what Aeria stores, where, and why

This repository builds on macOS with Xcode + XcodeGen only. There is no
`.xcodeproj` committed — it's generated from [`project.yml`](project.yml).
