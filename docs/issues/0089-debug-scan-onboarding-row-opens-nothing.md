Title: La ligne debug « Ouvrir l'onboarding scan » ne présente plus rien
Labels: needs-triage, bug
Type: AFK

## Parent

`ReCIT_iOS/Features/Profile/ProfileDebugSection.swift`
Trouvé le 2026-09-11 en instruisant l'échec de l'étape 05 de `scripts/e2e.sh`.

## Ce qui se passe

Le bouton « Ouvrir l'onboarding scan » de la section Debug du profil met `isPresentingWelcome` à
`true`, et le `fullScreenCover` attaché à la `Section` ne s'ouvre pas. L'écran ne bouge pas.

Sa voisine, « Ouvrir l'onboarding auto-sort », fonctionne — même `Section`, même mécanisme,
même type de `@State`. Ce n'est donc **pas** la présentation depuis une `Section` qui est en
cause.

Mesuré, pas supposé — la frappe vient d'un `tap()` natif sur un élément que l'arbre
d'accessibilité déclare joignable :

```
row exists=true
frame=(16.0, 484.3, 370.0, 52.0) hittable=true  écran=(0.0, 0.0, 402.0, 874.0)
frappe : tap() natif
APRÈS FRAPPE : onboarding.primary exists=false
```

## Pourquoi personne ne l'avait vu

La ligne n'est empruntée que quand l'accueil ne s'affiche pas, c'est-à-dire quand l'inventaire
n'est pas vide. Tant que le compte de test repartait propre, ce chemin n'était jamais joué. Le run
du 2026-09-11 a trouvé quatre livres laissés par un run précédent, a pris le repli pour la
première fois depuis longtemps, et a échoué — emportant les 22 étapes suivantes.

Le scénario ne passe plus par là : l'étape 05 ouvre désormais le scanner depuis
`e2e.shelves.scan`, la barre d'outils de l'inventaire, qui ne dépend d'aucun état. La ligne debug
reste néanmoins le seul moyen pour un testeur de revoir l'accueil sans vider sa bibliothèque.

## Hypothèses, et ce qu'on sait d'elles

- **Deux `fullScreenCover` sur la même vue, le dernier déclaré gagne.** Testée en les unifiant en
  un seul `fullScreenCover(item:)` : sans effet apparent. **Mais ce test ne vaut rien** — il
  s'appuyait sur des coordonnées d'écran calculées à la main, et elles étaient fausses. À rejouer
  avec un instrument fiable avant de l'écarter.
- **`OnboardingWelcomeView` elle-même.** Écartée : en lui substituant un simple `Text`, le cover ne
  s'ouvre toujours pas.

## Comment instruire

Un test sonde sous XCUITest, qui interroge l'arbre d'accessibilité plutôt que de viser des pixels,
est la seule méthode qui a donné une réponse stable. Il en existait un pendant l'enquête ; il a été
retiré parce qu'il s'appuyait sur une session déjà présente dans le trousseau d'une machine
donnée — inutilisable par un collaborateur. En réécrire un doit suivre la convention de
`E2EProbeTests` : se connecter avec `E2E_USERNAME` / `E2E_PASSWORD` depuis l'environnement, comme
le reste du fichier.

Attention : `E2EProbeTests` est dans les `<SkippedTests>` du scheme `ReCIT_iOSE2E`, et
`-only-testing` ne passe pas outre. Il faut retirer l'exclusion le temps du run — un premier essai
a affiché « TEST SUCCEEDED » avec zéro cas exécuté.

## Acceptance criteria

- [ ] La cause est identifiée et écrite ici
- [ ] « Ouvrir l'onboarding scan » ouvre l'accueil, et « Scanner mes livres » ouvre la session
- [ ] La ligne voisine « Ouvrir l'onboarding auto-sort » fonctionne toujours
- [ ] Si la cause est structurelle (deux présentations sur une vue), les autres écrans qui en
      empilent sont vérifiés — `grep -c fullScreenCover` par fichier
- [ ] Si une sonde est écrite, elle se connecte par l'environnement et ne dépend d'aucune machine

## Blocked by

None - can start immediately
