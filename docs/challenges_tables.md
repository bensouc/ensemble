# Tables dans les Challenges

## Vue d'ensemble

Les tableaux peuvent être insérés dans les champs de texte riche (Trix) des Challenges. Cette fonctionnalité permet aux enseignants de créer des exercices avec des tableaux éditables.

## Fonctionnalités

### Création d'un tableau
1. Dans l'éditeur Trix d'un Challenge, cliquer sur le bouton "Table"
2. Un tableau vide (1x1) est inséré
3. Utiliser les boutons de la toolbar pour ajouter des lignes/colonnes

### Toolbar
```
[ − ] [ + ] Ligne     [ − ] [ + ] Colonne
```
- **+ Ligne** : Ajoute une ligne en bas du tableau
- **− Ligne** : Supprime la dernière ligne (désactivé s'il n'y a qu'une ligne)
- **+ Colonne** : Ajoute une colonne à droite
- **− Colonne** : Supprime la dernière colonne (désactivé s'il n'y a qu'une colonne)

### Édition des cellules
- Cliquer sur une cellule pour l'éditer
- Le contenu est sauvegardé automatiquement quand on quitte la cellule (blur)
- Les cellules vides conservent une hauteur uniforme

## Architecture technique

### Modèle
**`app/models/table.rb`**
```ruby
class Table < ApplicationRecord
  include GlobalID::Identification
  include ActionText::Attachable

  # Colonnes: rows (integer), columns (integer), data (jsonb)
end
```

### Contrôleur
**`app/controllers/tables_controller.rb`**

Actions:
- `create` : Crée un nouveau tableau (1x1)
- `update` : Modifie le tableau (addRow, addColumn, removeRow, removeColumn, updateCell)
- `show` : Retourne le JSON de l'attachment

### Vues
- `app/views/tables/_editor.html.erb` : Template pour l'édition (avec toolbar)
- `app/views/tables/_table.html.erb` : Template pour l'affichage (lecture seule)

### JavaScript
**`app/javascript/controllers/table_editor_controller.js`**

Utilise la délégation d'événements pour gérer:
- Clics sur les boutons de la toolbar
- Édition des cellules (contenteditable)
- Protection contre la suppression accidentelle (backspace dans cellule vide)
- Synchronisation avec l'attachment Trix

### Styles
**`app/assets/stylesheets/trix/_index.scss`**

Contient les styles pour:
- Toolbar (`.table-toolbar`)
- Boutons (`.table-btn`, `.table-btn-success`, `.table-btn-danger`)
- Cellules (`.table-cell`, `.table-cell-display`)

### Configuration ActionText
**`config/initializers/action_text.rb`**

Tags HTML autorisés dans les attachments:
- `table`, `thead`, `tbody`, `tfoot`, `tr`, `th`, `td`, `colgroup`, `col`
- `input`, `button`, `strong`, `em`, `b`, `i`

## Limitations connues

1. **Styles bold/italic** : Les styles Trix (gras, italique) s'appliquent à tout le tableau, pas aux cellules individuelles. C'est une limitation de Trix qui traite l'attachment comme une unité.

2. **Pas de fusion de cellules** : La fusion de cellules (rowspan/colspan) n'est pas supportée.

3. **Pas de redimensionnement** : Les colonnes ont une largeur automatique, pas de redimensionnement manuel.

## Flux de données

```
1. Utilisateur clique sur "Table" dans Trix
   ↓
2. POST /tables → crée Table en DB → retourne JSON {sgid, content, contentType}
   ↓
3. Trix insère l'attachment avec le contenu HTML
   ↓
4. Utilisateur édite une cellule
   ↓
5. PATCH /tables/:sgid → met à jour Table.data → retourne nouveau JSON
   ↓
6. JavaScript met à jour:
   - L'état interne Trix (attachment.setAttributes)
   - Le DOM visible (table.innerHTML)
   ↓
7. Utilisateur sauvegarde le Challenge
   ↓
8. Trix envoie le contenu avec l'attachment mis à jour
   ↓
9. ActionText sauvegarde le rich text avec la référence au Table (sgid)
```

## Dépannage

### Le tableau ne se sauvegarde pas
- Vérifier que le JavaScript est chargé (pas d'erreurs console)
- Vérifier que l'AJAX vers `/tables/:sgid` fonctionne (onglet Network)

### Les cellules ne sont pas éditables
- Vérifier que `contenteditable="true"` est ajouté dynamiquement
- Le JS ajoute cet attribut au clic sur la cellule

### Le contenu disparaît au rechargement
- Vérifier que `attachment.setAttributes()` est appelé après chaque modification
- Vérifier les logs serveur pour les erreurs de sauvegarde