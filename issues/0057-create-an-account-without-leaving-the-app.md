Title: Créer un compte, without leaving the app
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0010-ex-libris-pre-login-onboarding.md

## What to build

Account creation, end to end and inside the app. Three fields — nom d'utilisateur, adresse e-mail, mot
de passe — a live check on the first two while they are typed, and a success that lands the user in the
app already signed in, where the existing onboarding takes over because their inventory is empty.

This replaces the outbound link to `inventaire.io/signup`.

### The live check is the point

`username` and `email` query their availability endpoint while the user types. "Ce nom est déjà pris"
is by far the most likely failure, and learning it *after* choosing a password is the worst possible
place to learn it.

Those endpoints validate the shape as well as the availability — their description reads "valid **and**
available" — so they carry the server's own naming rules for free, and the client never has to copy or
maintain them.

Model what a field can be while typing — empty, checking, free, taken, invalid — as a **pure type**, on
the pattern of `OnboardingGate`. The view renders a state; it derives none. The type must handle a
check that comes back stale because the user kept typing.

Consequence for the screen: **the error sits under the field it belongs to**, not in one note above the
button. The single note stays on sign-in, whose failure belongs to neither field.

### It must never make the user retype

Sign-up is treated exactly like sign-in: same cookie capture, same Keychain persistence. If the response
carries no session cookies, chain a sign-in with the credentials just used before returning.

Put that decision in a **pure type** too. It is the branch production never produces on demand, and it
would be broken for everyone the day the server changes its behaviour.

### What happens next needs no code

The existing gate already asks for a synced inventory, zero books, and an unanswered welcome. A brand
new account satisfies all three after its first sync — verified end to end against production, where an
empty inventory returns a well-formed, decodable response. So a new user goes: création → tabs → sync →
the existing `C1 · Bienvenue`.

### Autofill

The three fields declare what they hold, including a new password so iOS offers to generate a strong one,
and the email field gets its keyboard.

A caveat to handle rather than avoid: iOS may suggest a password the server rejects, and the user will
not understand why the password *their phone suggested* was refused. The refusal must read as a field
error on the password field.

## Acceptance criteria

- [ ] `Créer un compte` opens a three-field form inside the app; no browser is opened anywhere
- [ ] The screen says the account is being created on inventaire.io
- [ ] A taken username is reported under the username field, while typing, before submission
- [ ] The same for a taken or malformed email address
- [ ] A stale availability response never overwrites the state of a field the user has since changed
- [ ] Submitting with all three fields valid creates the account and lands the user signed in
- [ ] A sign-up whose response carries no session cookies still lands the user signed in
- [ ] A server refusal is shown in French, under the field it concerns where one can be identified
- [ ] A rejected password reads as an error on the password field
- [ ] No server-authored string is ever displayed
- [ ] The three fields carry their content types; the password field offers a generated strong password
- [ ] The email field uses an email keyboard
- [ ] A newly created account reaches `C1 · Bienvenue` after its first sync, with no change to the gate
- [ ] At the largest accessibility text size the form scrolls and the submit button stays reachable
- [ ] Light and dark, no literal colours, no hard-coded font sizes
- [ ] All copy lives in `Localizable.xcstrings`, English source, French translation
- [ ] Test suite on the field-availability type, including the stale-response case
- [ ] Test suite on the post-sign-up session rule: cookies present, cookies absent
- [ ] Test suite on the service against `MockURLProtocol`: sign-up 200 with cookies, 200 **without**
      cookies so the fallback runs, 400, network failure
- [ ] Nothing is added to the integration suite

## Blocked by

- issues/0056-sign-in-from-a-welcome-screen.md
