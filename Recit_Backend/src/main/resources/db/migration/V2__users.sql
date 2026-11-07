-- Accounts, with only what signing in needs (#70). The profile comes with #71.
CREATE TABLE users (
    -- inventaire.io's `_id`: 32 lowercase hexadecimal characters.
    id CHAR(32) PRIMARY KEY,
    -- `_rev` is derived from it, and it moves on every write.
    version INTEGER NOT NULL DEFAULT 1,
    username TEXT NOT NULL,
    email TEXT NOT NULL,
    -- argon2id, as a PHC string.
    password_hash TEXT NOT NULL,
    language TEXT NOT NULL,
    email_validated BOOLEAN NOT NULL DEFAULT FALSE,
    -- Epoch milliseconds, as inventaire.io's `created`.
    created BIGINT NOT NULL
);

-- inventaire.io refuses a username or an address that differs from a taken one by case only.
CREATE UNIQUE INDEX users_username_key ON users (lower(username));
CREATE UNIQUE INDEX users_email_key ON users (lower(email));

-- The links the account e-mails carry. Only the token's hash is kept: the token travels in the e-mail.
CREATE TABLE user_tokens (
    token_hash CHAR(64) PRIMARY KEY,
    user_id CHAR(32) NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    purpose TEXT NOT NULL CHECK (purpose IN ('email_confirmation', 'password_reset')),
    expires_at BIGINT NOT NULL
);

-- One live link per purpose: asking again replaces the previous one.
CREATE UNIQUE INDEX user_tokens_user_purpose_key ON user_tokens (user_id, purpose);
