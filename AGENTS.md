# Agent instructions (Habit Tracker Compose)

This repository is **orchestration only**: Docker Compose, `.env`, and production deploy. It is not the app.

- **Do not** put habit/domain rules, API, or UI code here. Canonical domain law: [habit-tracker-springboot/docs/domain.md](https://github.com/crraay/habit-tracker-springboot/blob/main/docs/domain.md) (sibling: `../habit-tracker-springboot/docs/domain.md`).
- **Do not** commit secrets. Copy `.env.example` → `.env` and edit locally.
- How to run and deploy: [DOCKER.md](DOCKER.md). Keep [README.md](README.md) as the short human entry point.
- App images are built in [habit-tracker-springboot](https://github.com/crraay/habit-tracker-springboot) and [habit-tracker-angular](https://github.com/crraay/habit-tracker-angular), not in this repo.
