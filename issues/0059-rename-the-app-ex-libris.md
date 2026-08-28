Title: The app is called Ex-libris
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0010-ex-libris-pre-login-onboarding.md

## What to build

A shop-window rename: the displayed name, the two catalogue strings that name the app, and the icon.

An ex-libris is the mark of ownership pasted inside a book — *this book belongs to…*. It says ownership
and return, which is what an app about owning and lending books is.

"Étagère" was rejected, and not on taste: the word is already a common noun of the product — users
*create étagères*. Naming the app the same makes every sentence of the interface, the documentation and
the support ambiguous. Its accent also costs in store search and on non-French keyboards, and it says
nothing about two thirds of the promise.

### Two things must not be renamed

This is the whole risk of the slice.

1. **`Env.keychainKey`.** The session cookies are stored under it. Changing it silently signs out every
   existing user on their next launch — and they would land on the welcome screen this PRD just built,
   making the feature look like the regression.
2. **`PRODUCT_BUNDLE_IDENTIFIER`.** Changing it creates a new app on the App Store and abandons every
   existing install.

The root type, the folders, the targets and the schemes keep their names. A code rename, if it ever
happens, is its own commit and never mixed into a feature.

### Where the name actually appears

The displayed name is `Recit` today, not "RECITs". The string catalogue names the app in two entries —
the onboarding tally and the camera permission message — in both English and French, four values in all.
Both keep naming the app literally: an app that introduces itself in its own onboarding should say who
it is.

## Acceptance criteria

- [ ] The home screen shows `Ex-libris`
- [ ] The two catalogue strings name the app, in English and in French
- [ ] `Env.keychainKey` is unchanged, and an existing signed-in user stays signed in across the update
- [ ] `PRODUCT_BUNDLE_IDENTIFIER` is unchanged
- [ ] The root type, folders, targets and schemes are unchanged
- [ ] No string in the catalogue still says "RECITs" or "Recit"

## Blocked by

None - can start immediately
