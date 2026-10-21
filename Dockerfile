# syntax=docker/dockerfile:1

FROM node:20-alpine AS base
WORKDIR /app
ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH
RUN corepack enable
COPY . .

# ── Build stage: install, generate prisma client, typecheck ────────────
FROM base AS deps
RUN pnpm install --frozen-lockfile=false
RUN pnpm --filter @studio/database exec prisma generate
RUN pnpm --filter @studio/database exec prisma db push --skip-generate --accept-data-loss || true

# ── Web ─────────────────────────────────────────────────────────────────
FROM deps AS web
ENV NODE_ENV=production
EXPOSE 3000
CMD ["pnpm", "run", "dev:web"]

# ── Worker ──────────────────────────────────────────────────────────────
FROM deps AS worker
ENV NODE_ENV=production
EXPOSE 8787
CMD ["pnpm", "run", "dev:worker"]
