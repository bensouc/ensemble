# Éditeur riche (ActionText / Trix)

Refonte du style de l'éditeur (§1–5) et montée de Trix 1.3.5 vers 2.1.19 (§6).
Branche : `feat/actiontext-editor-v2`.
La reprise des **tableaux** est une phase 2 distincte (§7).

---

## 1. Diagnostic de l'existant

Ce qui donnait à l'éditeur son aspect daté, et où c'était écrit :

| Constat | Emplacement |
|---|---|
| CSS Trix par défaut utilisé tel quel : boutons gris, bords 1px, rayon 3px, état actif `#cbeefa` | `application.scss` → `@import "trix/dist/trix"` |
| Toolbar complétée par injection de `innerHTML`, avec SVG et styles en ligne, dans des `<div>` — donc **non focusables, sans `aria`, sans raccourci** | `trix_controller.js#addTool` |
| `trix-editor { padding: 0 !important }` : le texte collait à la bordure | `components/_actiontext.scss` |
| `.trix-button-group--text-tools { width: 200px }` : largeur figée pour loger les boutons injectés | idem |
| `.trix-button--icon-link { display: none }` : **aucun lien possible** dans un énoncé | idem |
| `.trix-content` en `Arial` / `font-size: 18.5px` en dur, alors que l'app est en Poppins | idem |
| `.trix-content img { width: 100% }` sans `height: auto` : image **déformée** en affichage dès que Trix écrit un attribut `height` | idem |
| Couleurs hors charte (`#f9fafb`, `#10b981`, `#ef4444`, `#3b82f6`) | `trix/_index.scss` |
| `@jaames/iro` (~45 ko) importé en eager pour deux pastilles de couleur | `application.js` |
| Attributs de texte (`underline`, couleurs) enregistrés dans un `initialize()` Stimulus, donc **en course** avec le parsing du contenu existant | `trix_controller.js#setupTrix` |
| `.cont-challenge { width: 811px !important }` : éditeur tronqué sur tablette/mobile | `work_plans/_challenges.scss` |
| `.challenge-title` : aplat saumon hors charte sur le champ du nom | idem |
| 5 `@import url()` Google Fonts, bloquants et sérialisés | `config/_fonts.scss` |

---

## 2. Architecture après refonte

```
app/assets/stylesheets/trix/
  _index.scss     imports + bloc « legacy » isolé
  _tokens.scss    custom properties dérivées de config/_colors.scss et _fonts.scss
  _toolbar.scss   barre d'outils
  _editor.scss    champ d'édition (padding, focus, placeholder)
  _content.scss   typographie du contenu — édition ET affichage
  _tables.scss    tableaux (reprise à l'identique, cf. phase 2)

app/javascript/plugins/trix-config.js         libellés, attributs, blocs, HTML de la toolbar
app/javascript/controllers/trix_palette_controller.js   nuancier de couleurs
app/javascript/controllers/rt_toolbar_controller.js     accessibilité clavier de la toolbar
```

Supprimés parce que devenus sans appelant : `trix_controller.js` (son seul rôle
était l'injection `innerHTML` + les couleurs) et `color_picker_controller.js`.

### Deux pièges de cascade, documentés dans les fichiers concernés

1. **`trix/dist/trix.css` est importé avant `trix/index`** dans `application.scss`.
   Nos sélecteurs ont la même spécificité que les siens (`trix-toolbar .trix-button`
   = 0,1,1) : c'est donc l'ordre qui tranche, et nous gagnons. Corollaire : toute
   propriété posée par `trix.css` et non redéclarée chez nous **subsiste** — d'où
   les remises à zéro explicites (`float`, `border-left`, `margin-left`…).

2. **Trix injecte du CSS dans le `<head>` à l'exécution**, donc *après* la feuille
   compilée. Pour ces propriétés-là, il faut une spécificité supérieure. Cas
   rencontrés :
   - `trix-editor:empty:not(:focus)::before { color: graytext }` → le placeholder
     est stylé via `trix-editor[placeholder]:empty:not(:focus)::before`.
   - `trix-toolbar { white-space: nowrap }` → neutralisé au niveau du popover,
     qui porte une classe.
   - `trix-editor img { max-width: 100%; height: auto }` → explique pourquoi la
     déformation d'image ne se voyait qu'en **affichage**, pas en édition.

---

## 3. Rétrocompatibilité — pourquoi les énoncés existants ne bougent pas

Vérifié dans `actiontext-7.1.3.4` :

- **Édition** : `ActionText::Content#to_trix_html` appelle
  `render_attachments(&:to_trix_attachment)`, qui régénère le contenu de chaque
  pièce jointe depuis `to_trix_content_attachment_partial_path`. L'attribut
  `content=` stocké en base n'est donc pas rejoué : changer un partial ou du CSS
  n'a aucun effet rétroactif sur les données.
- **Affichage** : `ContentHelper#render_action_text_attachment` passe par
  `to_attachable_partial_path`. Là encore, rendu à partir de l'enregistrement.

Choix explicitement conservatoires :

- `Trix.config.textAttributes.underline` garde `style: { textDecoration: "underline" }`
  et son `parser`. Le passer en `<u>` aurait cassé la relecture des énoncés
  existants, qui portent du style en ligne.
- `heading2` / `heading3` sont **additifs** : le contenu existant n'a que des `<h1>`.
- `.trix-content img` garde `width: 100%`. Beaucoup d'énoncés sont des
  photocopies scannées cadrées sur la colonne. Seul `height: auto` est ajouté —
  c'est un correctif de déformation, pas un changement de cadrage.
- `.attachment--preview .attachment__caption { display: none }` est conservé.
  Trix y écrit par défaut « nom · taille » : réafficher ces légendes ferait
  surgir d'un coup ces libellés sur tout le contenu déjà en base.
- Le sanitizer (`config/initializers/action_text.rb`) n'est **pas** touché.
  À noter pour plus tard : `allowed_tags` étant défini explicitement, il ne
  contient pas `action-text-attachment`, que le sanitizer retire donc du rendu
  (en conservant les enfants). Le réintroduire ferait réapparaître un élément
  enveloppant et réactiverait des règles CSS aujourd'hui inertes — c'est un
  changement d'affichage sur tout l'existant, à traiter séparément.

### Deux fuites globales laissées en place, volontairement

Ces deux sélecteurs d'éléments nus débordent largement de l'éditeur. Les
restreindre est un changement à l'échelle de l'app, qui mérite son propre
passage de vérification. Ils sont conservés tels quels, isolés et commentés :

- `table { table-layout: fixed }` (`trix/_index.scss`) — s'applique à tous les
  `<table>` de l'app : résultats de classe, plans de travail, PDF.
- `button { padding: 10px 10px }` (`work_plans/_challenges.scss`) — s'applique à
  tous les `<button>`. La toolbar y échappe par spécificité.
- `#challenge_content button[type="button"]` (`components/_actiontext.scss`) —
  porte un id, donc bat les règles de classe ; il touche les boutons **dans**
  l'éditeur (toolbar des tableaux, bouton « supprimer » d'une pièce jointe).
  Son nettoyage fait partie de la phase 2.

---

## 4. Ce que l'éditeur gagne

**Style**
- Toolbar en groupes sur fond clair, coins arrondis, ombre légère ; état actif
  en rose de la charte au lieu du bleu Trix.
- Icônes SVG en `currentColor` (18 px) ; B / I / U / S et H1–H3 en glyphes
  typographiques, plus nets que des tracés à la main.
- Champ d'édition : vrai padding, rayon 10 px, anneau de focus rose.
- Contenu en Poppins avec un rythme vertical reconstruit (trix.css met
  `margin: 0` partout), titres hiérarchisés, citation à filet rose, bloc de code
  encadré, listes correctement indentées, liens soulignés.
- Toolbar qui passe à la ligne au lieu de déborder ; `.cont-challenge` gagne un
  `max-width: 100%` (rendu desktop inchangé, plus de coupe sur mobile).
- Champ « nom de l'exercice » (`.challenge-title`) repris sur les mêmes jetons
  que l'éditeur : l'aplat saumon `rgba(250, 128, 114, 0.308)`, qui n'appartenait
  à aucune couleur de la charte et écrasait le texte, laisse place à un champ de
  titre lisible avec le même anneau de focus rose.
- Composeur de message des conversations ajusté : hauteur compacte et coins
  jointifs avec le bouton d'envoi, que le nouveau rayon de 10 px désolidarisait.

**Fonctionnalités**
- **Souligné** en bouton natif Trix (`data-trix-attribute="underline"`) avec
  `⌘U` / `Ctrl+U` — Trix résout les raccourcis via `data-trix-key`.
- **Liens** de nouveau disponibles (le bouton était masqué en CSS), avec sa
  boîte de dialogue restylée et `⌘K`.
- **Sous-titres** H2 et H3 en plus du titre H1.
- **Couleur du texte / surlignage** : 8 pastilles de la palette de l'app en un
  clic, `<input type="color">` pour le reste, et une entrée « retirer la
  couleur » qui manquait.
- **Placeholder** réel. `Challenges#new` pré-remplissait le contenu avec
  « Écrivez votre énoncé ici », que l'enseignant devait sélectionner et
  supprimer ; c'est désormais un placeholder que Trix gère nativement.
- **Toolbar au clavier** : `role="toolbar"` et tabindex glissant (flèches,
  `Home`/`End`). Trix met `tabindex="-1"` sur tous ses boutons, ils étaient donc
  inatteignables. Le HTML reste en `-1` : sans JS, on retombe exactement sur le
  comportement Trix d'origine.
- Libellés et `aria-label` en français, avec le raccourci dans l'infobulle.

**Performance**
- `@jaames/iro` sorti du bundle (vérifié : plus aucune occurrence dans
  `app/assets/builds/application.js`).
- Plus d'injection `innerHTML` de toolbar au `connect()` de chaque éditeur, ni
  de duplication de SVG en ligne par éditeur.
- Attributs Trix enregistrés à l'import du bundle : plus de course avec le
  parsing du contenu.
- Google Fonts : 5 requêtes bloquantes sérialisées → 1 (familles et graisses
  strictement identiques, donc aucun changement visuel).
- Le nuancier ne pose son écouteur `document` que pendant l'ouverture du
  popover, et le retire à la fermeture.

---

## 5. Écarté à ce stade, avec la raison

- **Nettoyage des sélecteurs globaux** (§3) — changement app-wide.
- **Alignement de paragraphe.** Désormais faisable : les `blockAttributes` de
  Trix 2 acceptent `htmlAttributes` (liste blanche d'attributs HTML, avec
  `Block#addHTMLAttribute` et round-trip par le parser), ce qui manquait en 1.x
  où seul `tagName` était accepté. Pas encore implémenté.

---

## 6. Montée en Trix 2

Faite sur cette même branche. `trix` passe de **1.3.5 à 2.1.19**.

### Pourquoi : 1.x n'est plus maintenu

Dernière version 1.x : 1.3.5, décembre 2024. `yarn audit` remontait **7 avis
XSS** sur notre version installée, tous avec `patched_versions: >=2.1.x` — aucun
correctif 1.x n'existe :

| Avis | Sévérité | Corrigé en |
|---|---|---|
| `GHSA-53g2-mvcc-q9x3` Stored XSS via injection d'attribut du HTMLParser au collage | moderate | 2.1.18 |
| `GHSA-53p3-c7vp-4mcc` XSS via bypass de désérialisation JSON en drag-and-drop | low | 2.1.18 |
| `GHSA-qmpg-8xg6-ph5q` Stored XSS via les attributs sérialisés | moderate | 2.1.17 |
| `GHSA-g9jg-w8vm-g96v` Stored XSS via l'attribut d'une pièce jointe | moderate | 2.1.16 |
| `GHSA-mcrw-746g-9q8h` XSS au copier-coller | low | 2.1.15 |
| `GHSA-j386-3444-qgwg` XSS via URL `javascript:` dans un lien | moderate | 2.1.12 |
| `GHSA-qm2q-9f3q-2vcv` XSS au copier-coller | moderate | 2.1.4 |

Après montée : `yarn audit` ne remonte plus aucun avis sur `trix`.

Ce n'était pas un défaut de classification : les deux avis antérieurs
(`GHSA-6vx4-v2jw-qwqh`, `GHSA-qjqp-xr96-cj99`) avaient bien été backportés en
1.3.3 et 1.3.2. Les mainteneurs patchaient 1.x quand ils le jugeaient concerné ;
ils ont arrêté.

À noter : la paire installée était déjà hors contrat.
`@rails/actiontext@7.2.300` déclare `peerDependencies: { trix: "^2.0.0" }`, et le
gem `actiontext-7.1.3.4` embarque lui-même Trix 2.1.1 pour les projets
sprockets/importmap. Seul le côté npm était resté en 1.x.

### Portée réelle du risque avant montée

Vérifié, pour ne pas surestimer : **tous les chemins d'affichage passent par le
sanitizer Rails** (`content.body` → `Content#to_s` → `render_action_text_content`
→ `sanitize_action_text_content`), sans aucun `raw` ni `html_safe` sur du contenu
dans les vues. Le stored XSS à l'affichage était donc couvert côté serveur.

Le chemin non couvert était l'éditeur : `to_trix_html` n'est pas sanitizé, et
ActionText ne sanitize jamais à l'écriture. Du contenu piégé en base arrivait
donc brut dans le parser Trix à l'ouverture de l'éditeur — vecteur
inter-utilisateurs étroit mais réel, vu le partage et le clonage d'exercices.

### Ce qui a cassé, et les correctifs

1. **Ordonnancement de l'initialisation.** Trix 2 définit ses custom elements
   dans un `setTimeout(start, 0)`, alors que Stimulus démarre sur une microtâche
   après `DOMContentLoaded`, donc **avant** ce timer. Au `connect()` de
   `rich_text_table_controller`, `<trix-editor>` n'était pas encore initialisé et
   sa toolbar n'existait pas : `querySelector("[data-trix-button-group=file-tools]")`
   renvoyait `null` et le bouton Tableau disparaissait (avec une TypeError).
   → le contrôleur attend maintenant `trix-initialize` (qui remonte, `createEvent`
   met `bubbles` à `true` par défaut), avec un essai immédiat et une garde
   anti-double-insertion.

2. **Placeholder.** Le CSS injecté est passé de
   `trix-editor:empty:not(:focus)::before` à `trix-editor:empty::before` : il
   reste affiché champ focalisé et vide, comme un input natif. Notre sélecteur ne
   couvrait plus ce cas, où le `color: graytext` de Trix reprenait la main.

3. **`data-trix-validate-href`** (nouveau en 2.x). `ToolbarController#isSafeAttribute`
   ne valide le `href` (via `DOMPurify.isValidAttribute`) que si l'input du
   dialogue porte cet attribut ; sinon il renvoie `true` sans contrôle. Notre
   dialogue maison contournait donc la validation des liens → attribut ajouté.

### Ce qui a été vérifié comme inchangé

Point important : la phase 1 avait remplacé les hacks par les points d'extension
officiels de Trix, et ceux-ci n'ont pas bougé.

- `Trix.config.toolbar.getDefaultHTML` : toujours appelé par
  `TrixToolbarElement#connectedCallback` quand `innerHTML === ""`.
- `Trix.config.textAttributes` / `blockAttributes` / `styleProperty` : inchangés.
- Raccourcis : `applyKeyboardCommand` interroge toujours `[data-trix-key]`.
- État actif : toujours classe `.trix-active` **et** attribut `data-trix-active`.
- `Trix.Attachment` : toujours exposé, via un
  `Object.assign(Trix, models)` explicitement commenté « for compatibility with v1 ».
- `trix-file-accept` : toujours émis (le nom est construit par préfixage, d'où
  l'absence de la chaîne littérale dans le bundle).
- **Sanitisation des pièces jointes : identique.** `AttachmentView` appelle
  `HTMLSanitizer.setHTML(innerElement, attachment.getContent())` dans les deux
  versions, avec la même liste blanche — `style href src width height class`,
  plus `language` en 2.x, donc un élargissement. C'est ce qui explique le
  `makeTableCellsEditable()` de `table_editor_controller.js` : `contenteditable`
  était déjà retiré en 1.x. Aucune régression sur les tableaux.
- `trix.css` : 95 règles dans les deux versions, seules différences cosmétiques
  (`@media (max-device-width: 768px)` → `max-width`, ordre des sélecteurs). Nos
  surcharges visent donc toujours des sélecteurs réels.
- `composition.attachments` et `attachment.attributes.values` fonctionnent encore
  (contrairement à ce que j'avais d'abord conclu). `table_editor_controller.js` a
  quand même été basculé sur l'API publique
  (`getDocument().getAttachments()` + `getAttribute("sgid")`) parce que c'est plus
  robuste, pas parce que c'était cassé.

### Bénéfices obtenus au passage

- **DOMPurify** (2.1.9+), configurable via `Trix.config.dompurify`.
- **Validation native de formulaire** (`ElementInternals`, 2.1.7/2.1.16) —
  pertinent : le formulaire de conversation met `required: true` sur le rich text.
- **Compatibilité morphing** (2.1.13) — l'app est sur Turbo.
- **Corrections iOS 17/18** : déplacement du caret, et dictée qui perdait ou
  mélangeait le contenu existant (2.1.6, 2.1.8) — usage iPad en classe.
- Correction du fusionnement des puces sur Firefox (2.1.17).
- `toolbar.editorElement` (2.1.16) remplace la résolution manuelle de l'éditeur
  dans `trix_palette_controller`.
- Bundle : **1,60 Mo → 1,50 Mo**, DOMPurify inclus (la build ESM minifiée de
  Trix 2 est plus légère que la build non minifiée de 1.3.5).

### Reste à valider à la main

La vérification automatisée ne couvre pas le round-trip sur du contenu réel :
ouvrir des exercices existants **avec images et avec tableaux**, vérifier le
rendu, réenregistrer, et confirmer que rien n'est perdu.

---

## 7. Phase 2 — tableaux

Non inclus ici : les tableaux restent inchangés. Le travail de fond est déjà
commencé et parqué sur **`feat/actiontext-tables-v2`** :

- migration ajoutant `header_row`, `caption`, `col_aligns`, `col_widths`,
  `cell_styles` (toutes défautées, donc rendu identique pour l'existant) ;
- `Table` : insertion/suppression **positionnées** avec décalage réel des
  données — l'implémentation actuelle ne sait que retirer la dernière ligne et
  laisse des orphelins dans `data` ;
- `TablesController` : endpoint groupé `replace` en un seul aller-retour, les
  anciennes méthodes (`addRow`, `updateCell`…) restant servies pour les bundles
  JS encore en cache navigateur.

Les deux problèmes de fond à traiter côté client (cf. `docs/challenges_tables.md`
pour l'état actuel) :

1. **Une requête HTTP par cellule quittée**, dont la réponse remplace
   l'`innerHTML` du tableau — ce qui fait perdre le focus en cours de saisie.
2. **Des écouteurs `document` en phase de capture** posés à l'import du module
   (`click`, `mousedown`, `keydown`, `keyup`, `keypress`, `blur`), qui tournent
   donc sur chaque clic de l'application entière, éditeur ou non.
