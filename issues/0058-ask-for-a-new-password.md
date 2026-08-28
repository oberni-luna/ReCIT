Title: Mot de passe oublié, asked and answered in the app
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0010-ex-libris-pre-login-onboarding.md

## What to build

One screen reached from sign-in: an email field, a button, and a confirmation. It posts to the public
reset endpoint and says an email may be on its way.

The audience this whole PRD is built around — people who already have an inventaire.io account — is the
same audience that has forgotten an inventaire.io password. Today the only way out is to leave the app
and find the website.

### The confirmation must not be an oracle

It reads *"si un compte existe pour cette adresse, un e-mail est parti"*. Never "email sent", never
"unknown address".

Telling the two apart turns the screen into a way of asking "does this account exist?" for any address
someone cares to try. The server should not distinguish them either, but we do not depend on that: the
careful wording is written on our side whatever it answers.

For the same reason a network failure must read as a network failure, and never as a statement about
the address.

## Acceptance criteria

- [ ] Sign-in offers a way to reach the screen
- [ ] Submitting an address posts it to the reset endpoint
- [ ] The confirmation never reveals whether an account exists for the address
- [ ] It is identical whether the address is known or not
- [ ] A network failure is distinguishable from a submitted request, and says nothing about the address
- [ ] No server-authored string is ever displayed
- [ ] The email field carries its content type and keyboard
- [ ] At the largest accessibility text size the screen scrolls and the button stays reachable
- [ ] Light and dark, no literal colours, no hard-coded font sizes
- [ ] All copy lives in `Localizable.xcstrings`, English source, French translation
- [ ] Test suite on the service against `MockURLProtocol`: accepted, refused, network failure
- [ ] Nothing is added to the integration suite

## Blocked by

- issues/0056-sign-in-from-a-welcome-screen.md
