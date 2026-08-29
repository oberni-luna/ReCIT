#!/usr/bin/env python3
"""Empty the end-to-end test account on inventaire.io: every book, étagère and list.

The scenario deletes what it created as its last steps, so this is only needed when a run
died halfway and left things behind. `scripts/e2e.sh` calls it when E2E_RESET_ACCOUNT=1.

Credentials come from the environment (E2E_USERNAME, E2E_PASSWORD) — never from arguments,
so they stay off the process list. Prints what it removed.
"""

import json
import os
import sys
import urllib.error
import urllib.request
from http.cookiejar import CookieJar

BASE = "https://inventaire.io"


def make_opener():
    return urllib.request.build_opener(
        urllib.request.HTTPCookieProcessor(CookieJar())
    )


def call(opener, path, payload=None):
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    request = urllib.request.Request(
        BASE + path,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST" if data is not None else "GET",
    )
    with opener.open(request, timeout=30) as response:
        body = response.read().decode("utf-8")
    return json.loads(body) if body else {}


def main():
    username = os.environ.get("E2E_USERNAME", "")
    password = os.environ.get("E2E_PASSWORD", "")
    if not username or not password:
        print("E2E_USERNAME / E2E_PASSWORD absents.", file=sys.stderr)
        return 2

    opener = make_opener()
    try:
        call(opener, "/api/auth/login", {"username": username, "password": password})
    except urllib.error.HTTPError as error:
        print("Connexion refusée (%s)." % error.code, file=sys.stderr)
        return 1

    user_id = call(opener, "/api/user")["_id"]

    items = call(opener, "/api/items/by-users?users=%s" % user_id).get("items", [])
    if items:
        call(opener, "/api/items/delete", {"ids": [item["_id"] for item in items]})
    print("livres supprimés : %d" % len(items))

    shelves = call(opener, "/api/shelves/by-owners?owners=%s" % user_id).get("shelves", {})
    if shelves:
        call(opener, "/api/shelves/delete", {"ids": list(shelves.keys())})
    print("étagères supprimées : %d" % len(shelves))

    lists = call(opener, "/api/lists/by-creators?users=%s" % user_id).get("lists", [])
    if lists:
        call(opener, "/api/lists/delete", {"ids": [entry["_id"] for entry in lists]})
    print("listes supprimées : %d" % len(lists))

    return 0


if __name__ == "__main__":
    sys.exit(main())
