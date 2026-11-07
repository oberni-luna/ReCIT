-- Groups (#72): inventaire.io's group documents, their five role lists kept as one row per reader.

CREATE TABLE groups (
    id CHAR(32) PRIMARY KEY,
    -- `_rev`'s number: every write moves it.
    version INTEGER NOT NULL DEFAULT 1,
    name TEXT NOT NULL,
    -- `slugify(name)`, then `.1`, `.2`… while another group holds it, as inventaire.io's `addSlug`.
    slug TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    searchable BOOLEAN NOT NULL,
    open BOOLEAN NOT NULL,
    -- `/img/groups/<sha1>`, as `/api/images/upload?container=groups` answered it.
    picture TEXT,
    -- Degrees, truncated to five decimals; both set or neither.
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    -- The reader who created it. No foreign key: inventaire.io keeps the id once the account is gone.
    creator CHAR(32) NOT NULL,
    -- Epoch milliseconds.
    created BIGINT NOT NULL,
    CONSTRAINT groups_position_whole CHECK ((latitude IS NULL) = (longitude IS NULL))
);

-- The groups search (`/api/search?types=groups`): trigrams of the name, without regard to case.
CREATE INDEX groups_name_trgm ON groups USING gin (lower(name) gin_trgm_ops);

-- A reader's place in a group: one of inventaire.io's `admins`, `members`, `invited`, `declined`, `requested`
-- entries, `{user, invitor, timestamp}`. A group without an admin is deleted, its rows with it.
CREATE TABLE group_memberships (
    group_id CHAR(32) NOT NULL REFERENCES groups (id) ON DELETE CASCADE,
    user_id CHAR(32) NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('admin', 'member', 'invited', 'declined', 'requested')),
    -- Who invited them, or NULL for the creator and a request. No foreign key, as `creator`.
    invitor CHAR(32),
    -- When the membership was created, which a move between roles keeps. Epoch milliseconds.
    "timestamp" BIGINT NOT NULL,
    -- When it reached its role: the order inventaire.io's lists grow in, each move appending.
    moved BIGINT NOT NULL,
    PRIMARY KEY (group_id, user_id)
);

CREATE INDEX group_memberships_user ON group_memberships (user_id);
