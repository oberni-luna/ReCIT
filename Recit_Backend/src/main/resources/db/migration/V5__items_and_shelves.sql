-- Books and étagères (#73): inventaire.io's items and shelves, and the snapshots of the entities the books are of.

-- What inventaire.io says of an entity (an edition, or a work) a book is of: its item `snapshot`, read once from
-- `/api/entities/by-uris`, shared by every book of that entity, refreshed every week and on a `bulk-update`.
CREATE TABLE entity_snapshots (
    -- The canonical URI, as inventaire.io answers it once a redirect is followed: `inv:…`, `wd:Q…`.
    uri TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    subtitle TEXT,
    lang TEXT,
    -- Names joined with `, `, as inventaire.io's `getNames`.
    authors TEXT,
    image TEXT,
    series TEXT,
    ordinal TEXT,
    isbn13 TEXT,
    isbn10 TEXT,
    works_uris TEXT[] NOT NULL,
    authors_uris TEXT[] NOT NULL,
    series_uris TEXT[] NOT NULL,
    -- When it was last read from inventaire.io, epoch milliseconds: the nightly job rereads those over 7 days old.
    refreshed BIGINT NOT NULL
);

CREATE INDEX entity_snapshots_refreshed ON entity_snapshots (refreshed);

-- The works a snapshot names, with the claims `inventory-view` groups them by. NULL is a claim the work lacks:
-- inventaire.io files that work under `unknown`.
CREATE TABLE snapshot_works (
    uri TEXT NOT NULL REFERENCES entity_snapshots (uri) ON DELETE CASCADE,
    work_uri TEXT NOT NULL,
    position INTEGER NOT NULL,
    -- `wdt:P50`, `wdt:P136`, `wdt:P921`.
    authors TEXT[],
    genres TEXT[],
    subjects TEXT[],
    PRIMARY KEY (uri, work_uri)
);

CREATE TABLE items (
    id CHAR(32) PRIMARY KEY,
    -- `_rev`'s number: every write moves it, an étagère gained or lost included.
    version INTEGER NOT NULL DEFAULT 1,
    owner CHAR(32) NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    entity TEXT NOT NULL REFERENCES entity_snapshots (uri),
    transaction_mode TEXT NOT NULL CHECK (transaction_mode IN ('giving', 'lending', 'selling', 'inventorying')),
    -- As sent: `{}` the owner alone, `friends`, `groups`, `group:<id>`, `public`.
    visibility TEXT[] NOT NULL,
    details TEXT,
    notes TEXT,
    -- The URIs an inventaire.io merge moved the book from, the latest first.
    previous_entities TEXT[],
    -- Epoch milliseconds; `updated` NULL until an attribute is first changed.
    created BIGINT NOT NULL,
    updated BIGINT
);

CREATE INDEX items_owner ON items (owner, created);
CREATE INDEX items_entity ON items (entity);

CREATE TABLE shelves (
    id CHAR(32) PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    owner CHAR(32) NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    visibility TEXT[] NOT NULL,
    -- `#rrggbb`, or NULL when never chosen.
    color TEXT,
    created BIGINT NOT NULL,
    updated BIGINT
);

CREATE INDEX shelves_owner ON shelves (owner);

-- An item's `shelves`: deleting a book or an étagère removes the row, never the other side.
CREATE TABLE item_shelves (
    item_id CHAR(32) NOT NULL REFERENCES items (id) ON DELETE CASCADE,
    shelf_id CHAR(32) NOT NULL REFERENCES shelves (id) ON DELETE CASCADE,
    -- The order an item's `shelves` array grew in, epoch milliseconds.
    added BIGINT NOT NULL,
    PRIMARY KEY (item_id, shelf_id)
);

CREATE INDEX item_shelves_shelf ON item_shelves (shelf_id);
