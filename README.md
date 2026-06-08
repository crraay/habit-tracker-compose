# habit-tracker-compose

Production Docker Compose stack for the Habit Tracker app (Postgres + backend + frontend).

- **Images:** built and pushed to Docker Hub from [habit-tracker-springboot](https://github.com/crraay/habit-tracker-springboot) and [habit-tracker-angular](https://github.com/crraay/habit-tracker-angular).
- **Deploy:** manual GitHub Actions workflow in this repo — see [DOCKER.md](DOCKER.md).

```bash
cp .env.example .env   # edit secrets
docker compose pull
docker compose up -d
```

Local builds from source: see `docker-compose.override.example.yml`.
