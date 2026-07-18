// -----------------------------------------------------------------------------
// Express application assembly. Kept separate from server.js so the app can be
// imported in tests without opening a port.
// -----------------------------------------------------------------------------
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import morgan from 'morgan';

import { env, isTest } from './config/env.js';
import { requireAuth } from './middleware/auth.js';
import { notFoundHandler, errorHandler } from './middleware/errorHandler.js';

import authRoutes from './modules/auth/auth.routes.js';
import userRoutes from './modules/users/user.routes.js';
import categoryRoutes from './modules/categories/category.routes.js';
import taskRoutes from './modules/tasks/task.routes.js';
import { templatesRouter, planningRouter } from './modules/recurring/recurring.routes.js';
import statsRoutes from './modules/stats/stats.routes.js';
import syncRoutes from './modules/sync/sync.routes.js';

export function createApp() {
  const app = express();

  // Trust the reverse proxy (Nginx) so rate-limit sees the real client IP and
  // secure-cookie/https detection works when deployed behind it.
  app.set('trust proxy', 1);

  app.use(helmet());

  // CORS: allow all in dev, or a configured allowlist in production.
  const origins = env.CORS_ORIGINS.split(',').map((o) => o.trim());
  app.use(
    cors({
      origin: origins.includes('*') ? true : origins,
    }),
  );

  app.use(express.json({ limit: '1mb' }));
  if (!isTest) app.use(morgan('dev'));

  // Liveness/readiness probe (used by Docker healthcheck & load balancers).
  app.get('/health', (_req, res) => res.json({ status: 'ok', uptime: process.uptime() }));

  // --- Public routes ---
  app.use('/api/auth', authRoutes);

  // --- Authenticated routes ---
  app.use('/api/users', requireAuth, userRoutes);
  app.use('/api/categories', requireAuth, categoryRoutes);
  app.use('/api/tasks', requireAuth, taskRoutes);
  app.use('/api/recurring-templates', requireAuth, templatesRouter);
  app.use('/api/planning', requireAuth, planningRouter);
  app.use('/api/stats', requireAuth, statsRoutes);
  app.use('/api/sync', requireAuth, syncRoutes);

  // 404 + centralised error handling (must be last).
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
