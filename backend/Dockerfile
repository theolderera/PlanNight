# -----------------------------------------------------------------------------
# Backend production image.
# Multi-stage: install prod deps in a builder, copy into a slim runtime image.
# -----------------------------------------------------------------------------
FROM node:20-alpine AS deps
WORKDIR /app
# Only copy manifests first so `npm ci` is cached unless deps change.
COPY package.json package-lock.json* ./
# Use npm ci when a lockfile exists (reproducible), else fall back to install.
RUN if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --omit=dev; fi

FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
# Run as the built-in non-root `node` user for safety.
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src
USER node
EXPOSE 4000
# The compose file runs migrations separately before starting this.
CMD ["node", "src/server.js"]
