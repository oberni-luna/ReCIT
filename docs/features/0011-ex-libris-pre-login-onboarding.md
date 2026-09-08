# Ex-libris — the pre-login welcome and the native account flow

Shipped on 2026-08-28 from PRD `docs/prd/0010-ex-libris-pre-login-onboarding.md` (deleted — git history).

## What it does

A logged-out launch now opens on a welcome screen that says what the app is for — inventory your books,
keep track of what you lend, borrow from people you know — instead of a form and a sentence telling you
to go and register on a website. From there you sign in, create an account, or ask for a new password,
all inside the app.

The app is called **Ex-libris**.

Once signed in, nothing changed: the existing scan-then-sort onboarding (PRD 0007) takes over on its own
when the inventory turns out to be empty.

## Technical surface

**Screens added** — all under `Features/Authentication/View/`, behind a `NavigationStack` in the
unauthenticated branch of `RootView`:

- `WelcomeView` — the unauthenticated root. The app name, three value rows, `Se connecter`,
  `Créer un compte`.
- `LoginView` — rewritten as the sign-in screen (filename kept; the design library points at it).
- `CreateAccountView` — three fields, with a live availability check on the username and the address.
- `ForgotPasswordView` / `PasswordResetSentView`. *(Le second a été supprimé le 2026-09-07 — voir la
  section « Le mot de passe oublié devient une sheet » plus bas.)*
- `AuthFlowView` + `AuthDestination` — the stack and its destinations. `AuthField`, `WelcomeValueRow`
  are the shared pieces.

**Pure types** — `Model/Authentication/`, no SwiftUI and no networking, tested without a network:

- `AuthFailure` — classifies a server answer *and* owns the sentence the user reads.
- `FieldAvailability` — what a field can be while typing, including dropping a stale answer.
- `PostSignupSession` — whether a sign-up needs a chained sign-in.
- `PasswordResetOutcome` — collapses every server answer except a transport failure onto one
  confirmation.

**Endpoints** (server `https://inventaire.io/api`, verified against the live OpenAPI spec):
`POST /auth/login`, `POST /auth/logout`, `POST /auth/signup`, `POST /auth/reset-password`,
`GET /auth/username-availability`, `GET /auth/email-availability`.

**Also touched**: `AuthModel` is `@Observable`; `Keychain` split out of `AuthService`;
`MockURLProtocol` gained a per-session handler; `OnboardingScreenLayout` and the new
`OnboardingScreenContent` handle Dynamic Type; `SearchResult`'s `Hashable` is written out by hand.

**Tests**: 484 passing, 1 skipped. Suites added — `AuthFailure`, `AuthService`, `FieldAvailability`,
`PostSignupSession`, `PasswordResetOutcome`. Nothing was added to the production-hitting integration
suite.

## Notable decisions

- **The welcome screen is the unauthenticated root, and nothing remembers it was seen.**
  `OnboardingStore` is keyed by user id and defends that on purpose — a first launch belongs to an
  account, not to a phone. Before signing in there is no user id, so "show it once" would need a
  device-wide flag that store explicitly refused. Being logged out *is* the state that needs the pitch.

- **`Créer un compte` replaces the stack rather than pushing onto it.** It exists on both the welcome
  and the sign-in screen; without this the stack could grow
  `welcome → sign-in → sign-up → sign-in → …`. Depth never exceeds one.

- **The availability endpoints hand out a session cookie.** `GET /auth/username-availability` answers
  `200` with `Set-Cookie: inventaire:session` — an anonymous session, under the exact two names
  `AuthService` reads to decide whether someone is signed in. Typing into the username box and
  relaunching opened the app on the tabs of an account that does not exist. The server applies
  `cookie-session` globally, so **every public auth request must set `httpShouldHandleCookies = false`
  and must not call `absorbCookies`** — only `login` and `signUp` may absorb. Two tests hold this;
  do not remove them when adding an endpoint.

- **No server-authored prose ever reaches a screen.** Errors come back as `{ status, message }` in
  English. Classification reads `error_name` first and the sentence only as a fallback token, because a
  *taken* username carries no `error_name` — only prose. A rejected password is never echoed: the server
  writes the password back inside its own message.

- **The reset confirmation is deliberately vague, because the server is not.** Its controller turns a
  failed lookup into `400 "email not found"` and echoes the address. Every answer except a transport
  failure therefore collapses onto one confirmation in `PasswordResetOutcome` — the collapse is the
  whole protection, not a nicety.

- **Sign-up never makes the user retype.** If the response carries no session cookies, a sign-in is
  chained with the credentials just used. That branch is unreachable in production today, which is
  exactly why it is unit-tested.

- **`AuthService.absorbCookies` exists because the injected cookie storage used to be decorative.** The
  service never wrote to it — `URLSession` did, into its own jar. They coincide in production and
  diverge under an ephemeral test session, which would have made the service tests test nothing.

- **`SearchResult`'s `Hashable` is hand-written.** It was synthesised over a SwiftData `@Model`, whose
  conformance the compiler only sees when both files land in the same batch of a batch-mode build.
  Adding unrelated files anywhere in the target broke the build in a file nobody had touched.

- **`ViewThatFits` must not wrap a screen that raises a keyboard.** The three account screens were
  built with it, copying the onboarding layout. Focusing a field raised the keyboard, which shrank
  the available height, which made `ViewThatFits` pick a different branch, which rebuilt the
  `TextField` at a different place in the view tree — SwiftUI read that as a different view and
  dropped the focus. The username field could not be typed into at all. They now use one
  arrangement: a `ScrollView` with the actions pinned by a bottom safe-area inset, which handles
  the accessibility sizes just as well and cannot change identity. `WelcomeView` and the onboarding
  screens keep `ViewThatFits` — nothing on them raises a keyboard.

- **Onboarding uses `ViewThatFits` over three arrangements**, not a pinned bottom inset. C2b's answers
  are a three-sentence reason plus two controls; as an inset that block ate the whole screen at AX5 and
  truncated its own reason. The default-size layout is provably unchanged — captured before and after
  as byte-identical PNGs.

## The forms move onto the green (2026-09-05)

« Se connecter » and « Créer un compte » used to be white forms reached from a wall of covers under a
green veil — three screens of one flow, two of which looked borrowed from another app. They now stand on
the same green (`278:2`, `278:12` in the Figma library).

Nothing was added to the design system to do it; the mechanism is which *mode* each piece is read in:

- `AuthFlowView` pins `.preferredColorScheme(.dark)` over the three green screens — the welcome wall and
  the two forms — and leaves the reset pair alone. It is a list of destinations, not `!path.isEmpty`: a
  light-mode user asking for a new password should not be dragged into the dark on the way. *(Depuis le
  2026-09-07 la liste n'a plus d'exception : la pile n'affiche plus que des écrans verts, et la sheet de
  réinitialisation épingle le sien.)*
- The screens are painted `backgroundTinted`, which in the dark is `green/900` — the veil's own colour.
  The navigation bar is painted the same token rather than left to its default material, which lays a
  grey pane over the top of the screen.
- `AuthField(isOnTinted:)` pins **the input box alone** back to the light appearance, so
  `backgroundSecondary` is white paper again and the text inside it comes back as dark ink without a
  second decision. Not a hard-coded white — the token pair is the design, which is also how Figma states
  it.
- The lead sentence and the field labels lift from `foregroundSecondary` to `foregroundDefault`: on
  `green/900` the secondary grey is `gray/400`, and 4.1:1 is under AA at those sizes.
- The buttons were not touched. In the dark, `backgroundTintedInverse` is `green/200` and its label
  `green/900` — the cream button of the welcome screen, for free.

Three corrections came out of looking at it on a phone:

- **The green is drawn behind every safe area, the keyboard's included.**
  `background(_:ignoresSafeAreaEdges:)` stops at the keyboard inset, so a raised keyboard — which is
  translucent — showed the window's own black through itself, with the fields ghosting in it.
- **The bottom bar's top edge is faded in** (`AuthActionsBackground`): a `xLarge` ramp from the tinted
  ground at zero opacity to the same token opaque, starting `small` above the bar so it lands exactly
  where the first button starts. Painted flat, that edge was a line across the screen that the form
  disappeared behind mid-word — and on a screen where bar and form are the same green, that line was the
  only thing saying there were two surfaces.
- **« Créer un compte » is gone from the sign-in screen.** Both doors are on the welcome screen one step
  back; offering the second one again under the sign-in button made a fork out of the moment the choice
  had already been made, and left two capsules of equal weight for one job. `LoginView` lost its
  `onCreateAccount` with it. The Figma frames still carry the button — a divergence, recorded in the
  library file.

## Still open

- **`logout` has never been exercised against production.** The paths moved off the deprecated
  `?action=` form; `login` was verified by hand, `logout` was not. Required before shipping.
- **Associated domains** (`webcredentials:inventaire.io`) need a file hosted by inventaire.io. It is
  ready, with its notice, in `docs/integrations/`.
- **Sign-out from the app** was never exercised during this work, to avoid ending the owner's session.
- **The disabled primary button reads badly on the green.** `backgroundDisable` is `gray/400` in the dark,
  so « Créer mon compte » opens as a grey slab louder than the cream enabled state — and that is the
  first thing the sign-up screen shows. Fixing it means touching `LargeButtonStyle` or the token, which
  is every other screen's business too, so it is left as a decision rather than taken here.
- **Text typed into a field was never seen on a simulator** during this pass — the simulator refused both
  hardware-keyboard input and paste. The white box proves the mode pin works (it draws
  `backgroundSecondary`'s *light* value); the ink follows from the same environment.
- The string catalogue mixes `login.*` with `signup.*`, `welcome.*` and `auth.error.*`. Deliberate —
  renaming seven translated keys buys nothing — and tracked separately.

## Issues

> The issue files listed here were deleted in the 2026-08-29 docs cleanup, once shipped.
> The paths below are the ones they had then; issues have since moved under `docs/`.
> To read them: `git log --diff-filter=D --oneline -- issues/ docs/issues/` then
> `git show <commit>^:<path>`.

- `issues/0055-authmodel-observable.md` — AuthModel becomes @Observable — commit `9f5b6d8`
- `issues/0056-sign-in-from-a-welcome-screen.md` — sign in from a welcome screen — commit `2cb2836`
- `issues/0057-create-an-account-without-leaving-the-app.md` — create an account — commit `32e0fd7`
- `issues/0058-ask-for-a-new-password.md` — password reset — commit `cfee024`
- `issues/0059-rename-the-app-ex-libris.md` — the app is called Ex-libris — commit `87c6a68`
- `issues/0060-onboarding-survives-a-big-font.md` — onboarding at accessibility sizes — commit `4fc653f`

## Le mot de passe oublié devient une sheet (2026-09-07)

Demander un lien de réinitialisation était deux écrans poussés dans la pile : le formulaire, puis une
confirmation « Vérifiez votre boîte mail » avec son bouton « Retour à la connexion ». C'est maintenant
une **sheet** que « Se connecter » possède, et un **snackbar**.

- **Une sheet pleine hauteur, refermable au pull-down.** Demander un lien est une course, pas une
  destination : ça interrompt la connexion et ça rend la main. Le detent est `.large` — la sheet porte un
  clavier et un bouton épinglé, et un detent qui grandit quand le clavier monte déplace le bouton au
  moment du tap. Un `presentationDragIndicator(.visible)` annonce le geste.
- **Elle est sur le vert**, comme les deux formulaires : `backgroundTinted` derrière toutes les safe
  areas, `AuthField(isOnTinted:)` pour garder la boîte blanche, `AuthActionsBackground` sous le bouton,
  barre de navigation peinte du même token. Le `preferredColorScheme(.dark)` est **répété sur la sheet** :
  une présentation modale sort de la pile, donc l'épinglage d'`AuthFlowView` ne la suit pas.
- **Les deux issues sont dites au snackbar**, jamais dessinées dans le formulaire. Succès : le snackbar
  part, la sheet se ferme. Échec : le snackbar part, la sheet reste — l'adresse est encore saisie et
  réessayer est un tap. Le snackbar vit dans sa propre fenêtre (`LBSnackBar`), donc la confirmation reste
  lisible après la fermeture.
- **La phrase conditionnelle a survécu au déménagement.** Le titre du snackbar est « Vérifiez votre boîte
  mail » et son sous-titre est `PasswordResetOutcome.confirmation(for:)` — « si un compte existe pour
  *adresse*… », adresse comprise. La règle anti-oracle est toujours portée par le type, pas par l'écran.
  L'échec passe par `AuthFailure.message` et non par `SnackBarView.error(_:)`, qui lirait la description
  de l'`Error` : aucune prose d'inventaire.io n'atteint l'écran par cette porte non plus.

**Supprimés** : `PasswordResetSentView`, les cas `forgotPassword` et `passwordResetSent`
d'`AuthDestination`, la clé `reset.sent.button`, et le `isOnGreen` d'`AuthFlowView` — la pile n'ayant
plus que des écrans verts, l'épinglage est devenu inconditionnel.

Au passage, le bouton « Se connecter » est **désactivé tant que l'identifiant est vide**, comme celui de
la création de compte. Un formulaire vide qui presse un bouton actif ne gagne qu'un aller-retour et un
refus — et inventaire.io limite le débit des connexions, donc ce refus n'est pas gratuit.
