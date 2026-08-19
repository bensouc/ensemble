# Éditeur riche (ActionText / Trix)

Refonte du style de l'éditeur. Branche : `feat/actiontext-editor-v2`.
La reprise des **tableaux** est une phase 2 distincte (voir la fin du document).

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

- **Trix 2.x.** C'est le principal levier restant (parsing de collage plus
  robuste, meilleure accessibilité, alignement avec `@rails/actiontext` 7.2 déjà
  installé). Mais la montée touche le comportement des pièces jointes, donc les
  énoncés déjà en base : elle mérite sa propre branche et une passe de
  vérification sur du contenu réel. Actuellement en Trix 1.3.5.
- **Alignement de paragraphe.** Les `blockAttributes` de Trix 1 n'acceptent que
  `tagName` (pas de `className` ni de `style`) : impossible à faire proprement
  sans élément dédié. À reprendre avec Trix 2.
- **Nettoyage des deux sélecteurs globaux** (§3) — changement app-wide.

---

## 6. Phase 2 — tableaux

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
