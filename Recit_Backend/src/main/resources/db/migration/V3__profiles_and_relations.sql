-- The profile, the settings and the friendships (#71).

-- What `PUT /api/user` sets. NULL is "never set": inventaire.io leaves the key out of the document then.
ALTER TABLE users
    ADD COLUMN bio TEXT,
    -- `/img/users/<sha1>`, as `/api/images/upload` answered it.
    ADD COLUMN picture TEXT,
    -- Degrees, truncated to five decimals as inventaire.io does; both set or neither.
    ADD COLUMN latitude DOUBLE PRECISION,
    ADD COLUMN longitude DOUBLE PRECISION,
    ADD COLUMN fediversable BOOLEAN,
    ADD COLUMN summary_periodicity INTEGER,
    ADD CONSTRAINT users_position_whole CHECK ((latitude IS NULL) = (longitude IS NULL));

-- The readers search (`/api/search?types=users`): trigrams of the username, without regard to case.
CREATE INDEX users_username_trgm ON users USING gin (lower(username) gin_trgm_ops);

-- One switch of `settings`, named by its path under it: `notifications.global`, `contributions.anonymize`.
-- A switch never set has no row, and the apps read it as inventaire.io does: on.
CREATE TABLE user_settings (
    user_id CHAR(32) NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    enabled BOOLEAN NOT NULL,
    PRIMARY KEY (user_id, name)
);

-- inventaire.io's relation documents: one row per pair of readers, the smaller id first, whatever happened
-- between them last. `a-requested` means `user_a` asked `user_b`; `none` is a request or a friendship undone.
CREATE TABLE relations (
    user_a CHAR(32) NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    user_b CHAR(32) NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('friends', 'a-requested', 'b-requested', 'none')),
    -- Epoch milliseconds.
    created BIGINT NOT NULL,
    updated BIGINT NOT NULL,
    PRIMARY KEY (user_a, user_b),
    CHECK (user_a < user_b)
);

CREATE INDEX relations_user_b ON relations (user_b);
