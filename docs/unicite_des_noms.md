# Unicité des noms : domaine, exercice, niveau

Trois noms doivent être uniques dans leur périmètre, et le sont désormais **deux
fois** : par une validation applicative, qui produit le message lu par
l'enseignant, et par un index unique en base, qui rattrape la course que la
validation ne voit pas.

| Modèle | Périmètre | Index |
|---|---|---|
| `Domain#name` | son niveau (`grade_id`) | `index_domains_on_grade_id_and_name` |
| `Challenge#name` | sa compétence (`skill_id`) | `index_challenges_on_skill_id_and_name` |
| `Grade#name` | son école (`school_id`) | `index_grades_on_school_id_and_name` |

Les index sont posés par `db/migrate/20260903120000_indexer_unicite_des_noms.rb`.

---

## 1. Pourquoi les deux

Une validation d'unicité ne voit que sa propre transaction : deux requêtes
simultanées — un double-clic suffit — la passent toutes les deux et insèrent le
doublon. L'index est le seul à pouvoir refuser la seconde.

L'inverse est vrai aussi : un index seul ne sait produire qu'une
`ActiveRecord::RecordNotUnique`, soit un 500. C'est la validation qui donne le
message lisible. Les deux se complètent, aucun ne remplace l'autre.

## 2. Ce que ça vaut à l'enseignant

Ces trois échecs étaient invisibles ou brutaux avant septembre 2026 :

- **domaine** — la création renvoyait un 500 (`create.turbo_stream.erb` rendait
  `_domain` avec un enregistrement sans `id`), le renommage un
  `AbstractController::DoubleRenderError`. Corrigé en PR #455.
- **exercice** — la création faisait `redirect_to … status: :unprocessable_content`,
  soit un 422 au corps vide : Turbo ne suit pas un 422 et n'y trouve rien à
  rendre, donc le clic ne produisait **rien du tout**, sans un mot. Le renommage
  redirigeait vers `edit`, ce qui effaçait l'erreur et le texte saisi. Corrigé en
  PR #456, qui a aussi ajouté l'affichage des erreurs au formulaire — un
  `form_for` nu, qui n'en montrait aucune.
- **niveau** — le message s'affichait déjà, mais fautif.

Les quatre branches d'échec réaffichent maintenant le formulaire dans son
turbo-frame en 422, avec le message sous le champ et la saisie intacte
(garanti par `spec/requests/{domains,challenges,grades}_spec.rb`).

## 3. Les deux requêtes de ce dossier

Elles ne font que lire — aucun `INSERT`, `UPDATE`, `ALTER` ni `DROP`.

**`doublons_noms.sql`** — l'inventaire à passer *avant* de poser ou de resserrer
un index : doublons exacts, noms vides ou `NULL`, quasi-doublons (casse et
espaces ignorés), volumes, et le détail de chaque groupe avec ce qui pend
dessous (compétences, ceintures, plans de travail).

**`verif_index_unicite.sql`** — le contrôle d'*après* déploiement : la migration
est-elle passée, les trois index sont-ils là, uniques et `valid`.

```sh
ssh ubuntu@137.74.112.70 'sudo docker exec -i ce7zx18p6oici2ucx95v5khs psql -U postgres -d postgres' < docs/doublons_noms.sql
```

⚠️ Le nom du conteneur — `ce7zx18p6oici2ucx95v5khs`, le Postgres d'Ensemble.
**Quatre** Postgres tournent sur ce VPS : un `grep -i postgres | head -1`
tomberait sur `coolify-db`, la base de Coolify lui-même. La section 0 de chaque
requête affiche `current_database()` et des compteurs, précisément pour que se
tromper de conteneur soit visible immédiatement.

## 4. Relevé du 03/09/2026, avant la pose des index

| Cible | Doublons exacts | Noms vides ou `NULL` | Volume |
|---|---|---|---|
| `domains (grade_id, name)` | 0 | 0 | 91 |
| `challenges (skill_id, name)` | 0 | 0 | 2921 |
| `grades (school_id, name)` | 0 | 0 | 15 |

Aucun nettoyage n'a été nécessaire. C'est cohérent avec le code : rien ne
contourne les validations — pas un `validate: false`, pas un `insert_all`, pas
un `upsert`, et `Domain` n'est instancié que dans son contrôleur. Un doublon
n'aurait pu venir que de lignes antérieures aux validations, ou d'une course.

Trois groupes de **quasi**-doublons d'exercices subsistent (mêmes noms à la
casse ou aux espaces près). Ils ne gênent pas : l'index est exact, comme la
validation.

## 5. Ce qui reste ouvert

- `name` est `NULL`-able sur les trois tables. Un index unique laisse passer
  plusieurs `NULL` — il n'y en a aucun, et les trois modèles valident
  `presence`. Poser `null: false` serait plus strict.
- `Skill#name` porte la même validation d'unicité, **commentée**, et c'est
  volontaire : deux compétences homonymes dans un domaine sont acceptables. Ne
  pas la réactiver sans décision.
- La factory `:domain` tire son nom au hasard parmi neuf valeurs, et `:grade`
  parmi cinq alors que son nom est unique par école. Deux enregistrements créés
  dans le même périmètre par un spec se télescopent donc une fois sur neuf, ou
  sur cinq — nommer explicitement dès qu'un spec en crée plusieurs.
