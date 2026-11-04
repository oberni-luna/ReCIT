# Compte, accueil et Profil

Before sign-in: the welcome wall of covers and the native account flow. After: the Profil sheet behind the avatar — editing, account settings, À propos, donations, deletion. Signing out forgets the user, keeps the books.

## Code

- `Features/Authentication/` — `AuthService`, `WelcomeView`
- `Features/Profile/` — `ProfileView`
- `Features/Support/`
- `Model/Authentication/`

## Decisions

- [ADR 0008](adr/0008-session-login-signup-keychain.md)

## Features

- [0011 Ex-libris — pre-login welcome and native account flow](features/0011-ex-libris-pre-login-onboarding.md) — the app says what it is for before asking who you are
- [0013 The welcome screen's wall of covers](features/0013-welcome-cover-wall.md) — the pre-login screen opens on a drifting wall of the books inventaire.io just published, painted jackets underneath, dark in both appearances
- [0017 Supprimer son compte, depuis le bas du Profil](features/0017-deleting-your-account.md) — `DELETE /api/user` behind a screen that counts what it costs and an alert that acts; the local store is wiped whole, and only after the server says `ok`
- [0025 Signing out forgets the user, and keeps the books](features/0025-sign-out-forgets-the-user.md) — every way a session ends empties users, items, étagères, lists and transactions; editions, works and authors stay
- [0026 The Profil says the app is inventaire.io underneath](features/0026-profile-says-it-is-inventaire.md) — a dismissable paper tag under the account, linking inventaire.io and its open data
- [0034 À propos d'inventaire.io, la version, et un café pour Ex-libris](features/0034-profile-about-and-support.md) — a white À propos screen whose étagère carries my three latest books; the version at the foot of the Profil; a dismissable card and a StoreKit 2 donation sheet (3 / 5 / 10 €, half to inventaire.io); the paper tag of 0026 retired; products not yet on App Store Connect
- [0038 The Profil leaves the tab bar, behind my avatar](features/0038-profile-behind-the-avatar.md) — a round button at the top left of Inventaire, Listes and Réseau, the icon in the bar's glass or the account's picture, opens the profile as a sheet; `TabRouter` holds the flag; e2e not run
- [0055 Modifier son profil, son compte et ses notifications](features/0055-profile-editing.md) — « Modifier le profil » (photo, nom vérifié en tapant, bio, position sur une carte arrondie au kilomètre), « Compte et connexion » (adresse, mot de passe, langue, fédivers, anonymat) et « Notifications par e-mail » ; un `PUT /api/user` par attribut, espacés d'une seconde par `RequestPacer` ; jamais vu sur simulateur, e2e not run
