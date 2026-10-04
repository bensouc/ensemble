# Manipule — plan d'intégration dans Ensemble

Plan de réalisation, écrit le 2026-10-04, une fois la modernisation de la stack
terminée. Il fait suite à `docs/manipule-v1.md`, qui garde la définition du
produit et le modèle ; **ce document remplace l'arbitrage d'architecture de sa
section 3** : la branche « application dédiée » est écartée, on construit dans
Ensemble.

---

## 0. Ce qui a changé depuis le cadrage

Le cadrage décrivait la pile de septembre. Elle n'existe plus.

| | Au cadrage | Aujourd'hui |
|---|---|---|
| Ruby / Rails | 3.3.10 / 7.1 | **3.4.11 / 8.1.4** |
| Assets | Sprockets | **Propshaft**, esbuild et Dart Sass |
| Tâches de fond | Sidekiq | **Solid Queue**, avec Mission Control |
| Autorisations | éparses | **Pundit**, en liste blanche vérifiée après chaque action |
| Composants | partials | **ViewComponent 4.15** |
| Front | — | **Turbo 8**, `rails-ujs` retiré |

Quatre conséquences directes sur ce plan, qui n'étaient pas vraies en septembre.

**Pundit est obligatoire.** `ApplicationController` pose
`after_action :verify_authorized` et `verify_policy_scoped` en liste blanche :
seuls Devise, l'admin et `pages` y échappent. Chaque contrôleur de Manipule
devra donc soit autoriser explicitement, soit se retirer de la vérification —
et un retrait se justifie dans le code.

**La spec de fumée couvre les pages toute seule.** `spec/requests/fumee_pages_spec.rb`
énumère les routes GET du routeur et ouvre chacune. Toute page ajoutée est
couverte d'office. **Sauf les routes de l'élève** : la spec remplit les segments
`:id` d'après le modèle qui précède, et ne sait rien faire d'un `:jeton`. Il
faudra lui apprendre, ou les écarter avec leur raison. C'est un vrai petit
chantier, pas une case à cocher.

**La CI est locale et signée.** `bin/ci` enchaîne RuboCop, bundler-audit,
Brakeman, la construction du JS et du CSS, RSpec et les bancs navigateur, puis
`gh signoff`. `main` refuse un merge sans cette signature, et la signature porte
sur le commit poussé : chaque lot, c'est pousser, lancer `bin/ci`, signer,
merger. Le banc `mobile_ux` est déjà rouge et mis de côté sur `main` — ce n'est
pas nous.

**Les points d'entrée multiples sont un chemin déjà tracé.** `esbuild.config.js`
construit `application` et `rails_admin` ; `bin/build-css` compile `application`,
`rails_admin` et `pdf`. Ajouter un couple `manipule` à chacun est une ligne de
plus dans deux fichiers connus, et garde le bundle de l'application inchangé
pour les écoles qui n'utilisent pas Manipule.

---

## 1. La règle du jeu

**Tout est additif.** Aucune table existante modifiée, aucun modèle existant
touché, aucun gabarit partagé. Si Manipule est abandonné, on supprime ses
tables, son dossier et deux lignes de configuration, et il n'en reste rien.

Cela vaut aussi pour le jeton de classe : il vit dans **sa propre table**, pas
dans une colonne de `classrooms`. Une colonne de plus sur une table aussi
sollicitée serait sans danger, mais elle casserait la propriété ci-dessus.

**On copie le précédent `Mobile::`** : un espace de noms avec ses contrôleurs,
ses gabarits, son layout et son dossier de policies. Le chemin est connu, il
fonctionne, et personne n'aura à inventer une convention.

**On copie le précédent `PwaController`** pour la partie sans connexion : il se
retire déjà de `authenticate_user!` et de la vérification Pundit, avec ses
raisons écrites.

**Ce qu'on touche de partagé, et rien d'autre** : deux lignes dans
`esbuild.config.js` et `bin/build-css`, un bloc dans `config/routes.rb`, et un
garde dans `ApplicationController` — inerte tant qu'aucun élève n'est entré.

---

## 2. Les lots

### Lot 0 — l'étape 0, sur un poste de sa classe *(une demi-journée, à faire en premier)*

Ouvrir un navigateur sur l'ordinateur du fond de sa classe, lancer une lecture
vocale, écouter. Relever quelles voix françaises existent, s'il y a du son, et
quel navigateur c'est.

Ce lot ne produit pas de code. Il décide du lot 4, et il est invérifiable à
distance. Tant qu'il n'est pas fait, écrire l'audio, c'est parier.

### Lot 1 — le socle *(2 à 3 jours)*

Les tables et les modèles, rien de visible. Mergeable seul, sans risque.

- Espace de noms `Manipule::` : `Problem`, `Choice`, `Assignment`, `Practice`,
  `Attempt`, et `ClassroomToken`.
- `Manipule::Problem` s'accroche au `Skill` existant, qui porte déjà son niveau
  de 1 à 7 et sa chaîne vers le domaine, le niveau de classe et l'école. Rien à
  redéclarer.
- La validation qui tient tout : **exactement une bonne réponse par problème**,
  vérifiée à l'enregistrement. C'est la seule chose qui, dans l'application,
  peut faire voir un rouge injuste à un élève que personne n'est là pour
  rassurer.
- La colonne structurée (`jsonb`) qui porte les nombres de l'énoncé et les
  réglages de l'outil. Sans elle, aucun outil ne peut s'afficher, et elle ne se
  rattrape pas après coup sans réécrire la banque.
- Les specs de modèle.

### Lot 2 — la tranche jouable en classe *(4 à 5 jours)*

De quoi faire l'essai, sans éditeur. C'est le chemin le plus court vers une
vraie séance.

- **Le côté élève** : la liste des prénoms, l'écran de problème, l'écran de fin.
  QCM à trois choix seulement ; les outils viennent au lot 5.
- **Le confinement de la session élève**, tel que décrit en §4 du cadrage :
  cookie dédié limité au chemin, exclusion mutuelle — entrer en élève déconnecte
  l'enseignante —, gabarit sans aucune sortie, garde inerte.
- **L'import d'un tableur**, qui remplace l'éditeur pour l'essai. C'est ce
  qu'elle a demandé en Q32 : « je les colle depuis un document que j'ai déjà ».
  *Corrigé en cours de route : `roo` n'est plus au Gemfile, il a disparu avec la
  modernisation. On s'en passe — `CSV` de la bibliothèque standard, et
  `simple_xlsx_reader` dont l'application se sert déjà pour les compétences.
  Une dépendance de moins à auditer.*
- **Un écran de résultats minimal** pour elle : qui a travaillé, qui a réussi,
  où ça a coincé.
- La règle de la spec de fumée pour les routes à jeton.

*L'aperçu avant mise en circulation (Q36) est perdu dans ce lot. Le palliatif ne
coûte rien : elle fait la série elle-même avant de la donner aux élèves.*

### Lot 3 — l'éditeur *(3 à 4 jours)*

Le prototype existe et il est jouable : formulaire à gauche, **aperçu élève en
direct** à droite, banque en dessous avec le compteur « 3 sur 18 » et le bouton
dupliquer. Il reste à le brancher sur les modèles et à lui donner ses policies.

Volontairement **après** l'essai : il n'est pas sur le chemin critique, et
l'essai dira peut-être qu'il faut autre chose.

### Lot 4 — l'audio ✅ *(fait, sauf le fournisseur de production)*

Pré-généré et stocké, pas synthétisé à la demande : une voix identique sur tous
les postes, qui ne dépend ni du réseau de l'école ni des voix installées sur la
machine. Un morceau par élément lisible — l'énoncé, la question, chaque réponse
— pour que l'élève puisse revenir sur une seule.

En base plutôt qu'en fichiers : une dizaine de mégaoctets pour une banque
complète, de la donnée dérivée qu'on refabrique à volonté, qui survit aux
redéploiements sans stockage objet. Mesuré : 15 morceaux et 0,6 Mo pour trois
problèmes. La colonne `texte_source` garde ce qui a réellement été dit, pour
qu'un énoncé corrigé n'entretienne pas un audio devenu faux.

**Fournisseur retenu pour la production : Azure Neural.** Le raisonnement tient
à une particularité du projet — on n'a pas besoin d'un service de synthèse, mais
d'une étape de fabrication. La banque est statique, rien n'appelle le
fournisseur quand l'élève écoute. Ça retire tout son intérêt à Piper, dont
l'avantage est l'inférence locale en temps réel, et ne laisse que son défaut :
22 kHz optimisé pour la vitesse, pour un public qui ne peut pas relire ce qu'il
n'a pas compris. Le coût ne départage rien : 11 000 caractères pour la banque
entière, contre 500 000 offerts par mois chez Azure.

Et comme on pré-génère, **le choix est réversible** : l'audio déjà en base
continue de fonctionner quoi qu'il arrive au fournisseur, et en changer ne
touche qu'un moteur, sous `app/models/manipule/synthese/`.

**Attention au nom « Text-to-Speech API » sur la Place de marché Azure.** Le
piège a déjà fonctionné une fois, le 2026-10-04. La Place de marché revend des
SaaS d'éditeurs tiers, et plusieurs s'appellent exactement comme ça. On en a
souscrit un en croyant prendre le service de Microsoft : abonnement mensuel
facturé dès l'activation, clé `ik_live_…` inutilisable ici, et derrière,
Kokoro — dont la seule voix française, `ff_siwis`, est notée B− et entraînée
sur moins de onze heures. C'est le corpus de Piper, celui qu'on venait
d'écarter.

Le vrai service est **Azure AI Speech**, une *ressource* créée depuis « Créer
une ressource → Speech », au niveau tarifaire F0. Pas d'achat, pas de
redirection vers un éditeur. Ses clés sont hexadécimales, son hôte est
`<region>.tts.speech.microsoft.com`, et son allocation de 500 000 caractères
neuronaux par mois est permanente — c'est un palier tarifaire, pas l'offre de
douze mois du compte gratuit, qui est autre chose.

**Les garde-fous de consommation**, puisque les caractères se facturent :

- la régénération reste sélective, et c'est elle qui économise le plus ;
- le moteur espace ses appels de trois secondes, parce que F0 plafonne à vingt
  requêtes par minute et que ce quota-là n'est pas ajustable ;
- `GenerationAudio` compte les caractères avant de les dire et s'arrête à
  50 000 pour une exécution — de quoi stopper une boucle emballée, pas de quoi
  gêner une banque réelle ;
- le moteur Azure refuse de répondre depuis la suite de tests, clé ou pas ;
- `MANIPULE_TTS=systeme` rend la main à `say` pour itérer sur un énoncé sans
  rien consommer.

### Lot 5 — les outils de manipulation *(taille inconnue, dépend de la Q52)*

Jetons, dizaines et unités, partage en boîtes, horloge. Les gestes sont tranchés
et prototypés : glisser-déposer depuis une réserve, échange de dix cubes contre
une barre dans une case qui se remplit sous les yeux de l'élève, zones nommées
d'après l'énoncé.

C'est le lot dont on ne connaît pas la taille, et il porte le risque du projet.
Son JavaScript part dans le point d'entrée `manipule`, pas dans le bundle commun.

### Lot 6 — l'essai en classe

Deux ou trois élèves, elle aux commandes, et la décision qui suit : on continue
ou on arrête.

---

## 3. L'ordre, et pourquoi

```
Lot 0  ──────────────────────────────────┐
                                         ↓
Lot 1 ──→ Lot 2 ──→ Lot 6 (essai)     Lot 4
            │                            ↑
            └──→ Lot 3, Lot 5 ───────────┘
```

Le lot 0 part le premier parce qu'il ne coûte rien et qu'il décide d'un autre
lot. Le lot 1 n'attend personne. Le lot 2 est la tranche la plus courte vers une
séance réelle — d'où l'import à la place de l'éditeur, et le QCM à la place des
outils.

**Un lot, une PR, un passage de `bin/ci`, une signature.**

---

## 4. Ce que les trois questions bloquent maintenant

Elles sont dans la page Notion, partie 3.2. Leur portée a changé.

**Q52, la manipulation.** Elle ne décide plus de l'architecture — c'est tranché,
on construit dans Ensemble. Elle **dimensionne le lot 5**, et lui seul. Si la
réponse est « sans manipulation la V1 n'a pas de sens », le lot 5 passe avant le
lot 6 et le projet change de taille.

**Q51, la liste des compétences.** Ne bloque pas le schéma : les problèmes
s'accrochent aux `Skill` existants. Bloque le **remplissage** — si ses cinq
types de problèmes n'existent pas encore comme compétences dans son école, il
faut les créer, et l'import de compétences par classeur existe déjà.

**Q53, les mauvaises réponses.** Trente-six distracteurs par ceinture. Bloque la
forme de l'import au lot 2 — colonnes à remplir à la main, ou proposées par
l'outil — et rien d'autre.

---

## 5. Hors de ce plan

- La **bande numérique** et son extension OpenBoard : dépôt public séparé,
  `docs/bande-numerique-openboard.md`. Aucun lien technique.
- Le **schéma en barres**, en réserve.
- Toute **écriture de Manipule dans les ceintures d'Ensemble**. La colonne
  `results.origin` existe et dit qui fait autorité ; brancher Manipule dessus se
  décidera après l'essai, pas avant.
