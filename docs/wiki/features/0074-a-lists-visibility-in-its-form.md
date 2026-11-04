# Who may see a list, chosen in its form

Shipped on 2026-11-01, on iOS and Android. A list's visibility could be read since feature 0073 (« Visible par »
under Présentation) but not changed from the app: every list was created as « Moi seul·e », and the form sent
back whatever keys the store held. No PRD and no issues: one slice, one commit per platform.

## What it does

« Modifier la liste » gains « Visible par », after the name and the description, with five answers — the five
the Présentation tab names: **Moi seul·e**, **Mes amis**, **Mes groupes**, **Mes amis et mes groupes**, **Tout le
monde**. It opens on the list's current answer; « Envoyer » writes it with the rest.

It is asked in the form's three modes: editing, creating a list from the Lists tab, and « Ajouter à une nouvelle
liste » from a book. A new list still starts as « Moi seul·e ».

## Technical surface

- **iOS — `ListVisibility`** (`Features/Lists/`) — the five answers, `init(attributes:)` from inventaire.io's keys
  (`public` wins over the rest, `friends` and `groups` apart or together), `attributes` back to them, `label`.
  `ListVisibilityLabel.label(for:)` now reads through it, so the form and Présentation cannot disagree.
- **iOS — `ListFormView`** — a `Picker("list.info.visibility")` in a section of its own, bound to `list.visibility`
  through `ListVisibility`. The write is unchanged: `ListModel.createOrUpdateList` already sent
  `list.visibility` in its `PUT /api/lists`, and the creations already took a visibility. Accessibility identifier
  `e2e.listForm.visibility`. No new string: the `list.visibility.*` keys of 0073 are reused.
- **Android — `ListVisibility`** (`ui/lists/`) — the same five, with `from(raw)` and `raw`, next to the étagères'
  three-answer `ShelfVisibility`.
- **Android — `ListFormSheet`** — `ListVisibilityPicker`, an exposed dropdown menu like the type picker. The answer
  is `rememberSaveable` and seeded once with the name and description, where the raw keys used to be re-read on
  every launch of the effect. `ListRepository.createListAndAddWork` takes a visibility instead of sending none.
  Strings `list_form_visibility`, `list_visibility_{private,friends,groups,friends_and_groups,public}`.
- **Tests** — `ListVisibilityTests` (iOS) and `ListVisibilityTest` (Android): every combination of keys read as one
  answer, every answer written as keys that read back as itself.

## Notable decisions

- **Five answers, not the étagère's three.** Lists can be shown to groups, and Présentation already names five;
  whatever the form writes reads back in the same words.
- **A menu, not segmented buttons.** Five labels, the longest « Mes amis et mes groupes », do not fit a row.
- **Asked when creating too.** It is one form, and a list made from a book has a visibility as much as any other.
- **Not optimistic.** The form's writes stay server-first, as they were; only the field is new.

## Not done

- **Specific groups.** inventaire.io also accepts one key per group (`group:<id>`). The store drops those keys
  when it decodes a list (`VisibilityAttributes` has no case for them), so a list shown to chosen groups already
  lost them on any save; the form neither offers them nor keeps them.
- Not seen on a simulator or a device, on either platform; nothing saved to inventaire.io. e2e not run.
- Android still has no Présentation tab to read the answer back.
