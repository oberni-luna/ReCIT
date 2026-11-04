# A list's type, named in words

Shipped on 2026-09-26, from a screenshot of the « Créer une liste » sheet. No PRD and no issues: one slice,
decided in an autopilot run.

## What it does

The « Type » picker of the list form used to offer `work`, `author` and `publisher` — inventaire.io's raw values,
in English, on a French screen. It now offers **Œuvre**, **Auteur·ice** and **Maison d'édition** (Work, Author,
Publisher in English).

## Technical surface

- **`EntityListType.label`** (`Model/UserData/EntityList.swift`) — a `LocalizedStringResource` per case. The raw
  value is unchanged: it is what `/api/lists` stores and what the DTO decodes.
- **`ListFormView`** renders `Text(type.label)` instead of `Text(type.rawValue)`.
- Strings: `list.type.{work,author,publisher}`, fr and en, marked `manual`.
- **`EntityListTypeLabelTests`** — each label resolves to a catalogue entry, and the French words are the three
  asked for.

## Notable decisions

- **Typography over transcription.** The request read « Oeuvre » and « Auteur.ice »; the catalogue carries
  « Œuvre » and the point médian « Auteur·ice », as French typesetting writes them.
- **The label lives on the enum**, not in the view, so any future screen that names a list's type reads the same
  word — as `AuthFailure.message` does for errors.

## Not done

- The transaction form's « Type » picker (`TransactionFormView`) still shows its raw values; out of the request's
  scope.
- Not seen on a device; the change was checked by the unit suite and a simulator build.
