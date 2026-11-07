-- Lists (#74): inventaire.io's listings and their elements, works, authors or publishers a reader gathers and comments.

CREATE TABLE lists (
    id CHAR(32) PRIMARY KEY,
    -- `_rev`'s number: every write to the list itself moves it, not a write to one of its elements.
    version INTEGER NOT NULL DEFAULT 1,
    creator CHAR(32) NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    -- As sent: `{}` the creator alone, `friends`, `groups`, `group:<id>`, `public`.
    visibility TEXT[] NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('work', 'author', 'publisher')),
    -- Epoch milliseconds; `updated` NULL until an attribute is first changed.
    created BIGINT NOT NULL,
    updated BIGINT
);

CREATE INDEX lists_creator ON lists (creator, created);

CREATE TABLE list_elements (
    id CHAR(32) PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    list_id CHAR(32) NOT NULL REFERENCES lists (id) ON DELETE CASCADE,
    -- The canonical URI, as inventaire.io answered it when the element was added or last checked.
    uri TEXT NOT NULL,
    -- inventaire.io's lexicographic ordinal: elements read in its byte order.
    ordinal TEXT NOT NULL,
    comment TEXT,
    -- The URIs an inventaire.io redirect moved the element from, the latest first.
    previous_uris TEXT[],
    created BIGINT NOT NULL,
    updated BIGINT,
    -- When inventaire.io last said where `uri` stands, epoch milliseconds: the nightly job checks those over 7 days.
    uri_checked BIGINT NOT NULL,
    UNIQUE (list_id, uri)
);

CREATE INDEX list_elements_uri ON list_elements (uri);
CREATE INDEX list_elements_uri_checked ON list_elements (uri_checked);
