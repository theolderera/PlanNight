// -----------------------------------------------------------------------------
// Auth HTTP controllers — thin adapters that translate req/res to service calls.
// -----------------------------------------------------------------------------
import * as authService from './auth.service.js';

export async function register(req, res) {
  const { user, tokens } = await authService.register(req.body);
  res.status(201).json({ user, ...tokens });
}

export async function login(req, res) {
  const { user, tokens } = await authService.login(req.body);
  res.json({ user, ...tokens });
}

export async function refresh(req, res) {
  const { tokens } = await authService.refresh(req.body);
  res.json({ ...tokens });
}

export async function logout(req, res) {
  await authService.logout(req.body);
  res.status(204).send();
}
