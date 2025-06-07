# Base image with pnpm configured
FROM node:24-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Build stage
FROM base AS build
# Declare Railway-provided service ID for cache mounts
ARG RAILWAY_SERVICE_ID=1e277427-c36c-4c2c-9901-bdc1450511a2

WORKDIR /app
COPY . /app

RUN corepack enable
RUN apk add --no-cache python3 alpine-sdk

# Use BuildKit cache mount for pnpm store
RUN --mount=type=cache,id=s/${RAILWAY_SERVICE_ID}-pnpm-store,target=/pnpm/store \
    pnpm install --prod --frozen-lockfile

RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api

# Final runtime image
FROM base AS api
WORKDIR /app

COPY --from=build --chown=node:node /prod/api /app
# (Optional) If you don't need Git metadata at runtime, you can remove this line:
# COPY --from=build --chown=node:node /app/.git /app/.git

USER node

EXPOSE 9000
CMD ["node", "src/cobalt"]
