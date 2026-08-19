# Images d'exercices : originaux disparus de Cloudinary

Sur 802 images d'exercices, **176 ont perdu leur original** sur Cloudinary. Leurs
variants ont survécu, elles sont donc récupérables. **Aucune n'est définitivement
perdue.**

---

## 1. Comment les fichiers sont rangés

Dans `config/storage.yml`, la ligne `folder:` est commentée. Le service
Cloudinary fait alors :

```ruby
def public_id(key)
  return key unless @options[:folder]
```

- **l'original** est déposé **à la racine** du compte, sous la `key` du blob —
  une chaîne aléatoire de 28 caractères, sans rien de parlant ;
- **les variants** vont dans `variants/<key>/<sha256(variation)>`.

## 2. Ce qui s'est passé

Un nettoyage manuel de la Media Library a vu, à la racine, des centaines de
fichiers aux noms aléatoires — d'apparence inutile — et un dossier `variants/`
manifestement structuré. Les premiers ont été supprimés, le second épargné.

Ce n'est **pas** l'application : `ActiveStorage::Blob#delete` supprime
l'original **et** `variants/#{key}/`, jamais l'un sans l'autre. Le motif observé
exclut donc formellement une purge Rails.

Répartition des 176, par année de dépôt : 2022 (124), 2023 (12), 2024 (33),
2025 (7).

## 3. Pourquoi l'image casse, alors que le variant existe

C'est le point contre-intuitif. Le partial ne sert jamais l'original :

```erb
<% representation = blob.representation(resize_to_limit: [1024, 768]) %>
```

Et pour savoir si ce variant existe, Rails ne consulte pas Cloudinary mais **sa
propre table** :

```ruby
def processed
  process unless processed?     # processed? → record.present?
end

def process
  transform_blob { ... }        # ← blob.open : télécharge l'original
end
```

| | |
|---|---|
| une ligne existe dans `active_storage_variant_records` | Rails sert le variant, ne touche jamais l'original → l'image s'affiche |
| **aucune ligne** | Rails régénère → télécharge l'original → **404** → image cassée |

Le chiffre qui explique tout : **106 lignes** dans `active_storage_variant_records`
pour **802** images. Pour la quasi-totalité, Rails redemande donc l'original — le
fichier variant a beau dormir sur Cloudinary, rien en base ne le lui signale.

## 4. La récupération

On ré-uploade le **meilleur variant survivant** à la key de l'original.

> ⚠ **Ce qu'on récupère n'est pas l'original.** Un variant est un dérivé borné à
> 1024×768 et ré-encodé : la définition d'origine est perdue pour de bon. On
> échange une image cassée contre une image correcte mais moins définie. Les
> métadonnées du blob sont réalignées sur le fichier réellement déposé, et
> `metadata["recovered_from_variant"]` en garde la trace.

```bash
bin/rails runner scripts/cloudinary_inventory.rb                        # état, lecture seule
bin/rails runner scripts/recover_missing_originals.rb                   # simulation
LIMIT=3 DRY_RUN=0 CONFIRM=3 bin/rails runner scripts/recover_missing_originals.rb
DRY_RUN=0 CONFIRM=<n> bin/rails runner scripts/recover_missing_originals.rb
RESTORE=<fichier> bin/rails runner scripts/recover_missing_originals.rb
```

### Garde-fous

| | |
|---|---|
| Simulation par défaut | il faut `DRY_RUN=0` pour écrire |
| `CONFIRM=<n>` | doit correspondre au périmètre vu en simulation |
| `LIMIT=<n>` | permet un premier lot prudent, à vérifier à l'œil avant la suite |
| Jamais d'écrasement | un original présent fait échouer l'image, sans écriture |
| Vérification | après dépôt, le fichier doit exister sur le service |
| Sauvegarde | métadonnées d'avant + variant employé, avec commande de restauration |

L'opération est **additive** : on écrit là où il n'y a rien. Chaque image est
traitée indépendamment — s'arrêter en cours de route laisse un état cohérent,
simplement partiel. C'est pourquoi, contrairement à
`repair_shared_tables.rb`, il n'y a pas de transaction globale : un échec sur
une image ne doit pas priver les autres de leur récupération.

## 5. Deux pièges d'environnement

- **dev et prod partagent le compte Cloudinary `bensoucdev`.** L'état des
  fichiers est donc réel depuis le dev, mais **toute écriture y touche la prod**.
- **La base de dev est une copie datée.** L'inventaire qui fait foi est celui
  lancé en production.

## 6. Ce qui reste ouvert

Les **186 blobs partagés** mesurés via `active_storage_attachments` ne viennent
**pas** du corps des exercices (0 partage par sgid côté ActionText). Le chemin
qui les produit n'est pas identifié — sujet distinct.
