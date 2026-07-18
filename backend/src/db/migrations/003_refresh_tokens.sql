-- =============================================================================
-- PlanNight — server-side refresh-token records (rotation + revocation).
-- =============================================================================
-- Until now refresh tokens were purely stateless: any correctly-signed,
-- unexpired token could mint new access tokens, so logout couldn't actually
-- invalidate a session and a stolen token stayed usable for its full 30 days.
--
-- Every issued refresh token now has a row here, keyed by the token's `jti`
-- claim. A token is only honoured while its row exists, is not revoked, and is
-- not past expiry. Refresh *rotates*: the presented token is revoked and a new
-- pair is issued. Logout revokes the presented token's row.
--
-- Tokens issued before this migration carry no `jti` and are simply rejected —
-- existing sessions re-login once, which is acceptable at this stage.
-- =============================================================================

CREATE TABLE refresh_tokens (
  -- The token's jti claim. Generated with gen_random_uuid()/randomUUID().
  id          UUID PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Mirrors the JWT's own exp claim so we can purge dead rows without
  -- decoding tokens.
  expires_at  TIMESTAMPTZ NOT NULL,

  -- Set when rotated away or explicitly logged out. A revoked token is dead;
  -- presenting one yields 401 (no "revoke everything" cascade: a mobile client
  -- that lost the rotation response would otherwise nuke its other devices).
  revoked_at  TIMESTAMPTZ,

  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- "Revoke all of a user's sessions" and purge scans.
CREATE INDEX refresh_tokens_user_idx ON refresh_tokens (user_id);
CREATE INDEX refresh_tokens_expires_idx ON refresh_tokens (expires_at);
