-- Échanges (#75): inventaire.io's transactions, the actions that moved them and the messages exchanged on them.

-- No foreign key to `users` nor to `items`: an Échange outlives the book and the account of either side, readable
-- through its snapshot (#75 decision 7). Deleting an account cancels its open Échanges; it deletes only those the
-- other side's account is gone from too.
CREATE TABLE transactions (
    id CHAR(32) PRIMARY KEY,
    -- `_rev`'s number: a state change, and a message that changes a side's `read`, move it.
    version INTEGER NOT NULL DEFAULT 1,
    item CHAR(32) NOT NULL,
    owner CHAR(32) NOT NULL,
    requester CHAR(32) NOT NULL,
    -- The book's `transaction` when it was asked for: inventaire.io's `transaction` key.
    transaction_mode TEXT NOT NULL CHECK (transaction_mode IN ('giving', 'lending', 'selling')),
    state TEXT NOT NULL
        CHECK (state IN ('requested', 'accepted', 'declined', 'confirmed', 'returned', 'cancelled')),
    -- `false` while that side has something new to read.
    read_owner BOOLEAN NOT NULL,
    read_requester BOOLEAN NOT NULL,
    -- inventaire.io's `snapshot`, copied at request time: the book's entity URI and Commentaire, its title, cover and
    -- authors, and both readers' username and picture.
    snapshot_entity TEXT NOT NULL,
    snapshot_details TEXT,
    snapshot_title TEXT,
    snapshot_image TEXT,
    snapshot_authors TEXT,
    owner_username TEXT NOT NULL,
    owner_picture TEXT,
    requester_username TEXT NOT NULL,
    requester_picture TEXT,
    -- Epoch milliseconds.
    created BIGINT NOT NULL
);

CREATE INDEX transactions_owner ON transactions (owner);
CREATE INDEX transactions_requester ON transactions (requester);
CREATE INDEX transactions_item ON transactions (item);

-- A transaction's `actions`, in the order they happened: `requested` first.
CREATE TABLE transaction_actions (
    transaction_id CHAR(32) NOT NULL REFERENCES transactions (id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    action TEXT NOT NULL
        CHECK (action IN ('requested', 'accepted', 'declined', 'confirmed', 'returned', 'cancelled')),
    -- Epoch milliseconds.
    done_at BIGINT NOT NULL,
    -- Who cancelled: inventaire.io records the side only for `cancelled`, which either may do.
    actor TEXT CHECK (actor IN ('owner', 'requester')),
    PRIMARY KEY (transaction_id, position)
);

-- inventaire.io's transaction `comments`. `user_id` has no foreign key: a deleted reader's messages stay.
CREATE TABLE transaction_messages (
    id CHAR(32) PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    transaction_id CHAR(32) NOT NULL REFERENCES transactions (id) ON DELETE CASCADE,
    user_id CHAR(32) NOT NULL,
    message TEXT NOT NULL,
    created BIGINT NOT NULL
);

CREATE INDEX transaction_messages_transaction ON transaction_messages (transaction_id, created);
