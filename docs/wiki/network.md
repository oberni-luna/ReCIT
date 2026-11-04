# Réseau, amis, groupes, échanges

Readers linked both ways, inventaire.io groups, a friend's profile with their étagères and lists, and the transactions (give, lend, sell) between them.

## Code

- `Features/Network/` — `NetworkView`
- `Features/Community/` — `UserDetailView`
- `Features/Transactions/` — `TransactionDetailView`
- `Model/Transaction/` — `TransactionStateMachine`

## Features

- [0017 Signaler un membre ou un échange](features/0017-report-user-generated-content.md) — a « … » on a profile and on a transaction opens a pre-filled report mail; the blocking half of guideline 1.2 is still owed
- [0018 Se faire un réseau de lecteurs](features/0018-reader-network.md) — chercher un lecteur, lui demander, répondre à une invitation, retirer un ami ; les quatre états de `/api/relations`
- [0019 Les étagères qu'un ami partage](features/0019-a-friends-shared-shelves.md) — le carrousel du profil d'un ami, posé sur rien, consultable et pas modifiable ; et la portée de suppression qui manquait à `upsert`
- [0028 Un onglet Réseau, et les groupes d'inventaire.io](features/0028-network-tab-and-groups.md) — Amis | Groupes in a tab of their own with a badge; join, answer, leave, invite, run and create groups, every gesture optimistic but creation (groups persisted since 0035)
- [0033 The group the Réseau badge is about](features/0033-group-pending-dot.md) — a red dot after the name of each group with requests to join waiting on me as its admin
- [0035 The Réseau network as a graph](features/0035-network-graph.md) — « Tout » draws me, my groups and friends; pinch, touch, answer; DEBUG only; removed in 0048, its groups-in-store kept
- [0048 The Réseau graph removed, Amis | Groupes as before](features/0048-network-graph-removed.md) — « Tout », the graph and its e2e step deleted; the segmented control back as the list's first row, opening on Amis; groups in the store, sync order and avatar fallback kept
- [0056 Supprimer un groupe, quand on en est le seul admin](features/0056-deleting-a-group.md) — the « … » menu's last entry for the sole admin: inventaire.io has no deletion, so the group is read afresh, each member kicked, then left, and the server drops it; greyed with another admin; server-first, a refusal halfway stops with the kicked members gone; never run against inventaire.io, e2e not run
- [0064 A friend's profile: their picture at the head, their étagères, Inventaire | Listes](features/0064-a-friends-profile-with-tabs.md) — the Contacts card of Messages: a header held under the navigation bar, picture, name and glass tabs, folding as the page scrolls, never half folded; a friend's lists synced as the profile opens, `EntityList.creatorId` keeping them out of mine, opened read-only; never seen running, e2e not run
- [0066 A friend's profile: Inventaire and Listes as pages, changed by a swipe](features/0066-a-friends-profile-tabs-as-pages.md) — each tab its own inset grouped `List` (`UserProfilePage`), side by side in a `UIPageViewController` (`UserProfilePager`) bound to the tab, as the Contacts card of Messages; each page keeps its scroll, the header folds by the page on screen and the capsule follows the finger; seen in a harness and installed on a phone, e2e not run
- [0067 A friend's profile: a Présentation tab, counts in the tabs, étagères under Inventaire](features/0067-a-friends-profile-presentation-tab.md) — a third tab holds the bio; « Inventaire • 540 » and « Listes • 4 » replace the count under the name; capsules at 12 pt, no gap; the étagères under Inventaire only; the fold blended over any number of pages; installed on a phone, e2e not run
- [0071 A request names what it asks for](features/0071-a-request-names-what-it-asks-for.md) — the request sheet loses its « Type » picker, which inventaire.io ignored; title, sentence, button and message hint follow the copy's status (« Emprunter / Acheter / Récupérer »), and so do the menus that open it; not seen on a simulator, e2e not run
