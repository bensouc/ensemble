# Tableaux dans les exercices

Tableaux éditables insérés dans un champ ActionText, via `ActionText::Attachable`.
Pour l'éditeur riche dans son ensemble, voir [`actiontext_editor.md`](actiontext_editor.md).

---

## 1. Ce que l'enseignant peut faire

Le bouton **Tableau** de la barre d'outils insère une grille 3 × 3. La barre du
tableau se lit en deux blocs :

```
MISE EN PAGE   [En-tête]  Ligne ↑+ ↓+ ✕   Colonne ←+ →+ ✕
CELLULE        B I U      ●●●●●●●● ✕      ▤ ▥ ▧
```

- **Mise en page** — toujours visible. Bascule de la ligne d'en-tête, insertion
  d'une ligne ou d'une colonne **avant ou après la cellule courante**, et
  suppression. Sans cellule active, l'insertion se fait en fin de grille.
- **Cellule** — n'apparaît que lorsqu'une cellule a le focus : ces réglages n'ont
  pas de sens sans elle. Gras / italique / souligné (aussi en `⌘B` `⌘I` `⌘U`),
  couleur du texte, alignement de la colonne. Les réglages déjà posés sur la
  cellule y sont reflétés.

Au clavier dans une cellule : `Tab` / `Maj+Tab` d'une cellule à l'autre, flèches
haut/bas, `Entrée` pour descendre, `Échap` pour sortir vers l'énoncé.

Coller depuis un tableur remplit la grille à partir de la cellule courante et
l'agrandit au besoin.

Tant qu'une cellule a le focus, la barre d'outils principale se met en retrait :
ses réglages agissent sur le document Trix, jamais sur le contenu d'une cellule.

---

## 2. Modèle de données

`app/models/table.rb`, table `tables`. Toutes les grilles sont **creuses** :
une cellule jamais renseignée est absente.

| Colonne | Format |
|---|---|
| `rows`, `columns` | entiers, bornés par `MAX_ROWS` / `MAX_COLUMNS` |
| `data` | `{ "<ligne>-<colonne>" => "texte" }` |
| `header_row` | booléen — la première ligne devient des `<th>` |
| `col_aligns` | `["left", "center", "right", …]`, un élément par colonne |
| `cell_styles` | `{ "1-0" => ["b", "i", "u"] }` |
| `cell_colors` | `{ "1-0" => "#F24150" }`, restreint à `Table::TEXT_COLORS` |

Les quatre dernières sont défautées : un tableau créé avant leur introduction se
rend exactement comme avant.

Les opérations structurelles (`insert_row!`, `delete_column!`…) **décalent
réellement** les clés de `data`, `cell_styles` et `cell_colors`. L'implémentation
précédente ne savait retirer que la dernière ligne et laissait des orphelins.

---

## 3. La contrainte qui explique toute l'architecture

Le balisage du tableau vit **à l'intérieur d'une pièce jointe Trix**, et Trix le
sanitise au rendu (`AttachmentView` → `HTMLSanitizer.setHTML`). Ne survivent que
les attributs `style href src width height class language`, et ceux préfixés
`data-trix`. Mesuré sur le partial d'édition : seul `class` en sort.

Tout en découle :

| Conséquence | Réponse |
|---|---|
| `data-controller` / `data-action` retirés | Le contrôleur Stimulus vit sur le **champ**, hors pièce jointe, et délègue par classe |
| `id` retiré | Le sgid est relu du JSON `data-trix-attachment` du `<figure>` |
| `contenteditable` retiré | Reposé par le JS, paresseusement (au mousedown sur une cellule) |
| `type="button"` retiré → boutons submit | `preventDefault` sur tout clic de la barre |
| `title` retiré | Libellés visibles, pas d'infobulle |
| SVG inutilisable (l'attribut `d` saute) | Glyphes textuels, et icônes d'alignement **dessinées en CSS** |
| `data-*` inutilisable pour transporter une valeur | La teinte est relue sur la pastille (`getComputedStyle`) |

**Toute la mise en forme passe donc par des classes** (`TablesHelper`), sauf la
couleur, qui est une valeur libre : elle voyage en `style` inline. D'où une
**liste blanche** de teintes côté modèle plutôt qu'une validation de format —
aucune valeur arbitraire ne peut atteindre un attribut `style`.

### Trois pièges, tous rencontrés

- **Trix réagit aux mutations qu'on fait dans la pièce jointe.** Poser
  `contenteditable` déclenchait un re-rendu qui détruisait la cellule cliquée.
  Réponse : `data-trix-mutable="true"` sur la racine du tableau — l'observateur
  de Trix ignore alors ce sous-arbre. C'est le mécanisme qu'il utilise pour sa
  propre barre de pièce jointe. Contrepartie : trix.css y pose
  `user-select: none`, rétabli dans la feuille.

- **Une référence de nœud devient obsolète en silence.** Trix remplace le
  balisage à divers moments ; garder un élément en mémoire menait à agir sur un
  arbre détaché, sans erreur ni effet. L'identité est le **sgid**, et le DOM
  vivant est re-résolu à chaque action (`liveRootFor`).

- **Un re-rendu entre `mousedown` et `mouseup` avale le clic.** Le navigateur ne
  dispatche `click` que si les deux atterrissent sur le même élément encore
  présent : le bouton paraissait inerte. `preventDefault` ne suffisait pas, il
  faut aussi `stopPropagation`, sinon l'événement atteint `<trix-editor>` qui
  refocalise.

---

## 4. Enregistrement

Toutes les opérations sont **locales et immédiates**. L'état complet part
ensuite en une requête groupée : `PATCH /tables/:sgid` avec `method=replace`,
debounce de 600 ms à la frappe, immédiat sur opération structurelle et à la
sortie d'une cellule.

La réponse ne remplace **jamais** le DOM en cours d'édition — c'est ce qui
faisait perdre le focus dans l'implémentation précédente, qui envoyait une
requête par cellule quittée et réécrivait l'`innerHTML`.

Elle sert en revanche à resynchroniser l'instantané `content` de la pièce
jointe : Trix la reconstruit depuis cet instantané dès que son cache de vues est
invalidé, sans quoi une colonne ajoutée réapparaîtrait absente. La
resynchronisation n'a lieu qu'aux moments où le focus a quitté le tableau,
puisque `setAttributes` déclenche justement ce re-rendu.

Les anciennes méthodes (`addRow`, `updateCell`…) restent servies, pour les
bundles JS encore en cache navigateur.

---

## 5. Fichiers

```
app/models/table.rb                                  modèle, opérations, liste blanche
app/controllers/tables_controller.rb                 create + replace (+ API historique)
app/helpers/tables_helper.rb                         classes et style d'une cellule
app/views/tables/_editor.html.erb                    rendu dans l'éditeur
app/views/tables/_table.html.erb                     rendu en lecture (et PDF)
app/javascript/controllers/table_editor_controller.js
app/javascript/controllers/rich_text_table_controller.js   bouton d'insertion
app/assets/stylesheets/trix/_tables.scss             partagé éditeur / PDF
app/assets/stylesheets/trix/_tables_editor.scss      barre, états de saisie
```

---

## 6. Vérification

Deux bancs pilotent un vrai Chrome via Ferrum, sur des pages autonomes — ni
serveur, ni authentification, ni base au moment du test.

```bash
bin/rails runner scripts/table_editor_browser_check.rb   # comportement + charge utile
bin/rails runner scripts/table_pdf_parity_check.rb       # rendu éditeur == rendu PDF
bundle exec rspec spec/models/table_spec.rb              # décalage, bornage, liste blanche
```

Ils existent parce que l'essentiel des bugs de cet éditeur vient de son
interaction avec Trix — sanitisation, re-rendu, focus — et qu'aucun ne se voit
dans une spec Ruby. Le diagnostic à l'aveugle a coûté cher : on y a laissé
passer une boucle infinie qui figeait le navigateur.

Le banc contrôle aussi les **styles calculés**, pas seulement les classes posées.
C'est ce qui a révélé deux bugs de spécificité que la vérification par classe
laissait passer : `td:not([align]) { text-align: left }` vaut (0,1,1) — un
`:not()` compte la spécificité de son argument — et l'emportait sur
`.rt-al-center`. Les classes de mise en forme sont donc portées par des
sélecteurs scopés `.rt-table__grid .rt-cell.rt-al-*`.

**Non couvert par les bancs** : l'aller-retour enregistrement / réouverture, et
le rendu d'un PDF réel. À vérifier à la main après toute modification de fond.

---

## 7. Dépannage

| Symptôme | Piste |
|---|---|
| Les cellules ne sont pas éditables | `data-trix-mutable` toujours sur la racine du tableau ? Sans lui, Trix re-rend la pièce jointe et détruit la cellule |
| Un bouton de la barre ne réagit pas | Un re-rendu entre mousedown et mouseup avale le clic : vérifier que `onMousedown` fait bien `stopPropagation` |
| Un réglage s'applique sans effet visible | Spécificité CSS : lancer le banc, qui contrôle le style calculé |
| Le tableau perd des modifications | Regarder la réponse du `PATCH /tables/:sgid` ; l'enregistrement est groupé, pas par cellule |
| Le PDF diverge de l'éditeur | Lancer le contrôle de parité ; `pdf.scss` doit importer `trix/tables` |
