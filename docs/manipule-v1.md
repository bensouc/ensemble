# Manipule — définition de la V1

Document technique, issu du dépouillement des réponses de l'enseignante sur la
[page Notion de cadrage](https://app.notion.com/p/3cf546308549805ba39bd82cfbab6308).
Il a vocation à déménager dans le dépôt de Manipule dès sa création.

État : **proposition**. Trois questions bloquantes sont listées en fin de document ;
tant qu'elles ne sont pas tranchées, le périmètre peut encore bouger.

---

## 1. Ce que fait l'application

Un élève de CP ou CE1, seul devant l'ordinateur du fond de la classe pendant que
l'enseignante est avec un autre groupe, résout des problèmes de mathématiques :
il lit l'énoncé ou se le fait lire à voix haute, choisit sa réponse parmi trois,
sait immédiatement si c'est juste, et enchaîne. Dix problèmes, puis c'est fini.

L'enseignante, elle, alimente une banque de problèmes rangés par compétence et
par ceinture, désigne ce que chaque élève travaille, et consulte après coup ce
qui a été fait.

**Elle ne fait pas** : de plan de travail (il reste dans Ensemble), de correction
de texte libre, de validation de ceinture, de gestion d'écoles ou d'abonnements.

---

## 2. Ce que les réponses tranchent

### La trouvaille de modélisation

Les cinq exemples donnés en Q6 se répartissent ainsi :

| Compétence | Opération | Ceinture |
|---|---|---|
| Recherche d'une partie | soustraction | blanche |
| Recherche d'un tout | addition | blanche |
| Recherche d'un tout avec plusieurs fois le même nombre | multiplication | jaune |
| Recherche de la valeur d'une part | division | orange |
| Recherche du nombre de parts | division | orange |

**Chaque compétence vit à une seule ceinture.** La progression est portée par le
*type* de problème, pas par la taille des nombres. C'est exactement le modèle
d'Ensemble, où `Skill` porte un `level` de 1 à 7 et où les exercices en héritent.

Conséquence directe : `level` est un attribut de la **compétence**, pas du
problème. Un problème n'a pas de niveau propre, il hérite de celui de sa
compétence. Ça supprime une dimension entière du modèle.

*À confirmer : c'est une inférence tirée de cinq exemples, pas une réponse
explicite.*

### Ce qui est figé

- **Public** : CP et CE1, en atelier, sur les ordinateurs du fond de classe.
  Donc souris et clavier, pas de tactile, et des navigateurs qu'on ne choisit pas.
- **Domaine** : résolution de problèmes, uniquement.
- **Répondre** : 3 réponses au choix, une seule juste. Pas de saisie clavier :
  l'élève visé déchiffre mal et ne sait pas forcément écrire.
- **L'erreur** : un seul essai, pas de bonne réponse montrée, on passe au suivant.
- **Bloqué** : il réécoute, ou il passe. Pas d'indice, pas de solution.
- **La voix** : bouton, réécoute sans limite, lente, **une pause entre les
  phrases**, vitesse réglable, déclenchement automatique activable élève par élève.
- **La série** : 10 problèmes tirés au hasard sur une compétence, différents à
  chaque fois, finie quand les 10 sont passés. Tient en 10 à 15 minutes.
- **La banque** : 18 problèmes par ceinture, énoncés tous différents (pas de
  génération de variantes), importés d'un tableur, partagés entre collègues.
- **Le score** : rien de visible pour l'élève. C'est l'enseignante qui veut savoir.
- **L'entrée** : clic sur son prénom, sans mot de passe. Un CP y arrive.
- **Le suivi** : après la séance, jamais en direct. Qui a travaillé et combien de
  temps, qui a réussi, sur quels problèmes ça coince. Exportable.

### Deux simplifications majeures qui en découlent

1. **Pas de texte riche.** Q7 dit « du texte simple ». Donc ni ActionText, ni
   Trix, ni ActiveStorage, ni Cloudinary. Un `text` suffit. C'est la moitié de la
   complexité d'Ensemble qui disparaît.
2. **La tolérance de correction n'existe plus.** Toute la question Q19 — `12` ou
   `12 cm`, la virgule ou le point, les majuscules, les fautes — était la plus
   dangereuse du cahier des charges. Sans saisie clavier, elle est sans objet.

### Le volume de travail que ça représente pour elle

Avec 5 compétences sur 3 ceintures, « 18 problèmes par ceinture » veut dire
**54 problèmes** à écrire. Si c'est 18 *par compétence*, on passe à 90. À son
rythme annoncé (15 à 30 minutes pour 10 problèmes), c'est entre 1 h 30 et 4 h 30.
Il faut lever l'ambiguïté avant qu'elle s'y mette.

S'y ajoutent **deux mauvaises réponses par problème**, soit 108 distracteurs pour
54 problèmes. Personne n'a encore dit qui les écrit.

---

## 3. Contour technique

### La question qui commande : dans Ensemble, ou à part ?

Elle ne se tranche pas sur le confort du développeur. Deux faits la décident.

**Son critère de réussite passe par la ceinture.** Q49 : « si les élèves peuvent
travailler en autonomie *et valider des ceintures de problèmes* ». Une application
cloisonnée ne peut pas valider une ceinture dans l'autre — organiser l'essai ainsi,
c'est organiser un essai qui ne peut pas réussir selon ses propres termes.

**Le code a déjà anticipé la question.** `results.origin` existe : la colonne
distingue qui fait autorité sur une ceinture. Elle a été ajoutée pour autre chose,
mais c'est exactement le crochet dont Manipule a besoin — un résultat qui arrive
avec `origin: "manipule"`, et l'enseignante garde le dernier mot.

<!-- Ce document recommandait d'abord une application séparée. L'arbitrage a changé
     quand ces deux faits sont apparus. -->

### Branche A — dans Ensemble, isolé *(retenue le 2026-10-04)*

Un espace de noms `Manipule::` avec ses propres contrôleurs, ses propres gabarits
et ses propres tables, allumé par un drapeau de fonctionnalité pour la seule école
qui essaie.

**On réutilise** : `User` et Devise, `Classroom`, `Student`, `Grade`, `Skill` — qui
porte déjà son niveau de 1 à 7 —, `Belt`, et `Result` avec sa colonne `origin`.

**On s'interdit** : de modifier un modèle existant, un gabarit partagé, ou
`ApplicationController` au-delà d'un garde inerte tant qu'aucune session élève
n'existe. Toutes les migrations sont additives : aucune table en production n'est
touchée.

| | |
|---|---|
| On gagne | un seul compte, les classes et les élèves déjà saisis, les ceintures à portée, un déploiement qui existe déjà |
| On perd | la propriété « jetable » : en cas d'échec il reste des tables mortes à supprimer |
| On doit traiter | le confinement de la session élève — voir §4, c'est le vrai travail supplémentaire de cette branche |

### Branche B — application dédiée *(écartée)*

Même pile technique, base séparée, domaine séparé. Le choix si **la manipulation
devient le cœur du produit** : jetons déplaçables, échanges, horloge, c'est alors
d'abord un chantier d'interface, avec son rythme et ses outils, et l'embarquer dans
une application Rails de production devient un frein plus qu'un avantage.

Le second compte de l'enseignante se règle par une **connexion déléguée** : Ensemble
émet un lien signé de courte durée qui ouvre sa session dans Manipule. Elle ne crée
ni ne retient de second mot de passe. Côté élève, rien à faire : il n'a aucun compte
dans aucune des deux applications.

| | |
|---|---|
| On gagne | zéro risque pour les écoles en production, une itération rapide, un produit qu'on peut jeter |
| On perd | les ceintures hors de portée, deux déploiements à tenir, les élèves saisis deux fois |
| En moins | aucun confinement à construire : domaines séparés, cookies séparés |

### Le critère de bascule — tranché

Ce document disait que la Q52 départageait les deux branches. **Benoît a retenu
la branche A le 2026-10-04**, une fois la modernisation de la stack terminée. La
Q52 ne décide donc plus de l'architecture : elle dimensionne le chantier des
outils de manipulation, et lui seul.

Le plan de réalisation vit dans `docs/manipule-plan-integration.md`.

### Ce qui ne change pas d'une branche à l'autre

**La pile a changé entre le cadrage et la réalisation.** Au 2026-10-04 :
Ruby 3.4.11, Rails 8.1.4, PostgreSQL, Propshaft, esbuild et Dart Sass, Solid
Queue, Pundit, ViewComponent 4.15, Turbo 8 sans `rails-ujs`. Les conséquences
pour Manipule — Pundit obligatoire, spec de fumée qui énumère les routes, CI
locale signée, points d'entrée multiples déjà en place — sont détaillées dans
`docs/manipule-plan-integration.md`.

Ce qui ne bouge pas : pas d'éditeur de texte enrichi, les énoncés sont du texte
simple ; **aucune ressource distante**, polices servies par nous et audio
pré-généré ; et un JavaScript conservateur, parce que personne ne connaît l'âge
du navigateur sur les postes du fond de la classe.

---

## 4. Accès

### L'enseignante

**Branche A** : sa session Ensemble, rien de plus. Manipule est un onglet de plus
dans l'application qu'elle ouvre déjà.

**Branche B** : un lien signé émis par Ensemble, valable quelques minutes, qui
ouvre sa session dans Manipule. Pas de second mot de passe à créer ni à retenir.

### L'élève

Pas de compte, pas de mot de passe, dans les deux branches. Chaque classe porte un
jeton non devinable ; l'adresse `…/classe/:jeton` affiche la liste des prénoms, un
clic ouvre la séance.

**Le compromis, dit franchement** : quiconque possède l'adresse peut se faire passer
pour n'importe quel élève de la classe. Ce qui est exposé, ce sont des prénoms et
des résultats d'entraînement — pas de noms de famille, rien qui vaille d'être volé.
Pour un essai sur des postes de classe, c'est le bon échange : un code par élève
ferait échouer un CP, et elle a confirmé en Q47 que cliquer son prénom, il sait
faire. Garde-fous : jeton long et aléatoire, prénoms seuls, et un bouton pour
régénérer le jeton d'une classe.

### Confiner la session élève

**C'est le travail supplémentaire qu'impose la branche A**, et il ne se contente pas
d'être une bonne pratique : sans lui, un élève de CE1 se retrouve à deux clics du
tableau de bord de son professeur.

Deux menaces distinctes, et la seconde est la plus sérieuse.

**Un élève qui remonte vers Ensemble.** Les contrôleurs d'Ensemble exigent tous une
session Devise, donc un élève n'a rien à y voir — mais il tomberait sur un écran de
connexion, ce qui est une impasse pour un enfant de six ans.

**Une session d'enseignante restée ouverte sur le poste partagé.** C'est le cas
réel : l'ordinateur du fond de la classe, où elle s'est connectée ce matin. L'élève
n'a alors même pas besoin de contourner quoi que ce soit, il tape l'adresse
d'Ensemble et il *est* son professeur.

Quatre mesures, dont la deuxième est la seule qui traite vraiment le problème.

1. **Un cookie dédié, limité au chemin de Manipule.** L'identité de l'élève ne vit
   pas dans la session Devise mais dans son propre cookie signé, posé sur
   `path: "/manipule"`. Le navigateur ne l'envoie donc jamais aux routes d'Ensemble :
   le cloisonnement est structurel avant d'être du code.

2. **Exclusion mutuelle : entrer en élève déconnecte l'enseignante.** Ouvrir la
   liste des prénoms détruit toute session Devise du navigateur. Une session est
   celle d'une enseignante ou celle d'un élève, jamais les deux. Elle devra se
   reconnecter après la séance — c'est le prix, et sur une machine partagée c'est
   plutôt une bonne nouvelle.

3. **Un gabarit élève sans aucune sortie.** Pas de navigation, pas de pied de page,
   pas de logo cliquable vers Ensemble. Les seuls boutons de l'écran sont ceux de
   l'exercice.

4. **Un garde inerte** dans `ApplicationController` : une requête vers Ensemble qui
   porte une session élève et aucune session d'enseignante repart vers l'écran de
   Manipule, au lieu d'afficher un formulaire de connexion. C'est la seule ligne
   ajoutée à du code partagé, et elle ne s'exécute pas tant qu'aucun élève n'est
   entré.

**Ce que ça ne protège pas**, et qu'il faut assumer : l'adresse de la classe reste
partageable, et un élève qui la connaît peut se faire passer pour un camarade.
C'est accepté plus haut. Le confinement protège Ensemble de l'élève, pas les élèves
les uns des autres.

---

## 5. Les écrans de la V1

**Élève — trois écrans, pas un de plus**

1. `/classe/:token` — la liste des prénoms.
2. L'écran problème — l'énoncé, un bouton Écouter, trois réponses, un bouton
   Passer. Après le choix : juste ou faux, puis le suivant.
3. L'écran de fin — « C'est terminé », sans chiffre ni score.

**Enseignante**

4. Connexion.
5. Classes et élèves : création, jeton de classe, et par élève le déclenchement
   automatique de la voix et sa vitesse.
6. La banque : compétences, problèmes, import d'un tableur, aperçu tel que
   l'élève le verra, mise en circulation.
7. L'affectation : désigner la compétence travaillée, par élève et par classe.
8. Le suivi : par séance, par élève, par problème. Export CSV.

---

## 6. Le modèle

Huit tables. `Practice` est ce que l'interface appelle **une série** — le nom
`Serie` a été écarté : il produit bien la table `series`, mais Rails résout
`has_many :series` vers une classe `Series` qui n'existe pas, et il faudrait un
`class_name:` sur chaque association.

```
User ──< Classroom ──< Student ──< Assignment >── Competence ──< Problem ──< Choice
                            │                          │            │
                            └──────< Practice >─────────┘            │
                                        │                            │
                                        └──────< Attempt >───────────┘
```

```ruby
create_table :users do |t|             # Devise, enseignante
  t.string :email, null: false, index: { unique: true }
  t.string :encrypted_password, null: false
  t.string :first_name
  t.string :last_name
  t.timestamps
end

create_table :classrooms do |t|
  t.references :user, null: false, foreign_key: true
  t.string :name, null: false
  t.string :grade_level, null: false          # "CP" | "CE1"
  t.string :token, null: false, index: { unique: true }
  t.timestamps
end

create_table :students do |t|
  t.references :classroom, null: false, foreign_key: true
  t.string :first_name, null: false
  t.integer :position
  t.boolean :autoplay_voice, null: false, default: false   # Q12
  t.decimal :voice_rate, precision: 3, scale: 2, default: 0.8
  t.timestamps
end

create_table :competences do |t|
  t.string :name, null: false
  t.integer :level, null: false               # 1..7, blanche → noire
  t.integer :position
  t.timestamps
  t.index [:level, :position]
end

create_table :problems do |t|
  t.references :competence, null: false, foreign_key: true
  t.text :statement, null: false              # texte brut, pas de rich text
  t.boolean :published, null: false, default: false        # Q36
  t.integer :position
  t.timestamps
  t.index [:competence_id, :published]
end

create_table :choices do |t|
  t.references :problem, null: false, foreign_key: true
  t.string :label, null: false
  t.boolean :correct, null: false, default: false
  t.integer :position
  t.timestamps
end

create_table :assignments do |t|             # ce que l'enseignante désigne, Q27
  t.references :student, null: false, foreign_key: true
  t.references :competence, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true
  t.boolean :active, null: false, default: true
  t.timestamps
  t.index [:student_id, :active]
end

create_table :practices do |t|               # une série
  t.references :student, null: false, foreign_key: true
  t.references :competence, null: false, foreign_key: true
  t.integer :size, null: false, default: 10
  t.datetime :started_at, null: false
  t.datetime :finished_at
  t.timestamps
  t.index [:student_id, :created_at]
end

create_table :attempts do |t|
  t.references :practice, null: false, foreign_key: true
  t.references :problem, null: false, foreign_key: true
  t.references :choice, foreign_key: true     # nul si passé
  t.string :status, null: false               # "pending" | "correct" | "wrong" | "skipped"
  t.integer :listened_count, null: false, default: 0
  t.integer :elapsed_ms
  t.datetime :answered_at
  t.integer :position, null: false            # rang dans la série
  t.timestamps
  t.index [:practice_id, :position], unique: true
end
```

### Les trois décisions qui comptent dans ce schéma

**`attempts.status` distingue « passé » de « faux ».** Q5 autorise l'élève à passer un
problème. Si « passé » était rangé avec « faux », le suivi de l'enseignante
mentirait : elle verrait un échec là où il y a eu un renoncement, et ce ne sont
pas les mêmes élèves ni la même remédiation.

**`listened_count`.** Personne ne l'a demandé. C'est pourtant la donnée la plus
parlante pour elle : un élève qui réécoute cinq fois chaque énoncé ne bute pas
sur les mathématiques, il bute sur la lecture. La compter ne coûte rien.

**`practices.competence_id` est dupliqué depuis l'affectation.** Une affectation
change ; l'historique, non. Sans cette colonne, changer la compétence d'un élève
réécrirait le sens de toutes ses séances passées.

### Les validations qui tiennent l'ensemble

```ruby
class Problem < ApplicationRecord
  belongs_to :competence
  has_many :choices, -> { order(:position) }, dependent: :destroy
  accepts_nested_attributes_for :choices, allow_destroy: true

  validates :statement, presence: true
  validate  :exactly_one_correct_choice

  scope :published, -> { where(published: true) }

  delegate :level, to: :competence

  private

  # La seule chose qui, dans toute l'application, peut faire voir un rouge
  # injuste à un élève que personne n'est là pour rassurer : un problème sans
  # bonne réponse, ou avec deux. Ça se vérifie à l'enregistrement, pas en classe.
  def exactly_one_correct_choice
    return if choices.reject(&:marked_for_destruction?).count(&:correct?) == 1

    errors.add(:base, "Un problème doit avoir exactement une bonne réponse")
  end
end
```

```ruby
class Competence < ApplicationRecord
  has_many :problems, dependent: :destroy
  validates :level, inclusion: { in: 1..7 }
  validates :name, presence: true, uniqueness: { scope: :level }
end
```

### Le tirage d'une série

```ruby
class Practice < ApplicationRecord
  SIZE = 10

  belongs_to :student
  belongs_to :competence
  has_many :attempts, -> { order(:position) }, dependent: :destroy

  # Tirage simple et sans mémoire : 10 problèmes au hasard parmi les publiés de
  # la compétence. `ORDER BY RANDOM()` est sans conséquence sur 18 lignes.
  #
  # Sans mémoire, donc l'élève peut retomber demain sur les mêmes problèmes.
  # C'est la Q30, restée sans réponse ; le jour où elle sera tranchée, c'est
  # cette méthode, et elle seule, qui changera.
  def self.start!(student, competence)
    problems = competence.problems.published.order("RANDOM()").limit(SIZE)
    raise ArgumentError, "Aucun problème publié" if problems.empty?

    create!(student:, competence:, started_at: Time.current, size: problems.size).tap do |practice|
      problems.each_with_index do |problem, i|
        practice.attempts.create!(problem:, position: i + 1, status: "pending")
      end
    end
  end
end
```

*(Note : `start!` crée les tentatives d'avance, ce qui impose un quatrième statut
`"pending"`. L'alternative — créer la tentative au moment de la réponse — évite
ce statut mais perd la trace d'une série abandonnée en cours de route. Je retiens
la première : savoir qu'un élève s'est arrêté au 4e problème est une information
que l'enseignante veut, puisqu'elle demande en Q43 combien de temps il a travaillé.)*

---

## 7. Volontairement hors V1

Rien de cette liste n'est abandonné ; tout est repoussé.

- La **manipulation** de jetons et de dizaines (Q7 et Q52) — voir plus bas, c'est
  peut-être elle qui fera voler le reste en éclats.
- La saisie au clavier et toute la tolérance de correction.
- Les problèmes en plusieurs questions enchaînées (Q8).
- Le surlignage mot à mot.
- La progression et les ceintures visibles par l'élève (Q41).
- Le blocage sur un niveau non atteint (Q42) : inutile en V1, puisque c'est
  l'enseignante qui désigne la compétence travaillée.
- **Toute écriture dans Ensemble** (Q40, Q55). Une application cloisonnée ne peut
  pas valider une ceinture dans l'autre. En V1, Manipule informe, point.
- Le hors-ligne, la PWA, le multi-école, l'export PDF.
- La **bande numérique** et le **schéma en barres**, essayés en prototype puis mis
  de côté : trop complexes pour un CE1 livré à lui-même. Le premier a trouvé un
  autre public, voir ci-dessous.

### Un chantier voisin : la bande numérique

Écartée de Manipule pour une raison précise : pour un élève **seul**, choisir ses
sauts suppose d'avoir déjà la stratégie que l'outil est censé soutenir. L'objection
tombe dès qu'on change d'utilisateur. Sur le tableau de la classe, c'est
l'enseignante qui conduit, et la classe qui lit.

Elle vit donc comme une extension OpenBoard, dans son propre dépôt :

- Plan : `docs/bande-numerique-openboard.md`
- Code, public et sous licence MIT :
  <https://github.com/bensouc/ensemble-openboard-extensions>

Aucun lien technique avec Manipule — ni compte, ni données, ni serveur commun.
Les deux chantiers avancent en parallèle et ne se croisent pas.

---

## 8. Les risques, par ordre de gravité

**1. Les voix françaises sur les postes de l'école.** `speechSynthesis` ne fournit
que les voix installées sur la machine. Sur un Windows sans paquet linguistique
français, il n'y a aucune voix française, et rien, côté web, ne peut y remédier.
Toute l'accessibilité du produit repose sur ce point, et il est invérifiable à
distance. **Dix minutes sur un poste de la classe, avant d'écrire une ligne.**

**2. Le fichier d'import n'a pas les mauvaises réponses.** Son document existant
contient des énoncés et des solutions. Il manque 108 distracteurs, et le format
de colonnes n'est pas arrêté.

**3. L'ambiguïté 54 ou 90 problèmes.** Du simple au double sur le temps qu'elle
doit y consacrer avant même le premier essai.

---

## 9. Ce que le chantier de la bande numérique a appris

Six leçons tirées d'un outil voisin, écrit et livré en une journée. Elles ne sont
pas des anecdotes : chacune change quelque chose ici.

**On ne livre pas du code qu'on n'a jamais exécuté.** J'ai publié trois versions
du widget en me contentant d'une vérification de syntaxe. C'est un bug signalé par
Benoît qui m'a forcé à le servir en local et à cliquer dedans — où tout
fonctionnait, le problème étant ailleurs. Le prototype d'écrans de Manipule est
dans le même état : jamais exécuté, seulement relu.
→ *Avant toute démonstration à l'enseignante, faire tourner les écrans et cliquer
chaque chemin, y compris les impasses.*

**Aucune ressource distante.** Une salle de classe n'a pas toujours internet, et
quand elle l'a, elle l'a lente. Le widget n'a donc ni police Google, ni CDN, ni
image hébergée ailleurs.
→ *Le prototype de Manipule charge Andika et IBM Plex depuis Google Fonts. Dans
l'application réelle, ces polices doivent être servies par nous — Andika est sous
licence SIL OFL, c'est permis. Et c'est un argument de plus pour l'audio
pré-généré : un fichier qu'on sert vaut mieux qu'une synthèse qui dépend du poste.*

**Le moteur n'est jamais celui qu'on croit.** Dans OpenBoard c'était le Chromium
figé de Qt ; sur les ordinateurs du fond de la classe, ce sera un navigateur dont
personne ne connaît l'âge. J'ai failli livrer une expression régulière trop récente
qui aurait tout cassé en silence.
→ *Écrire du JavaScript conservateur, et prévoir un repli quand une interface
manque — comme `mousedown` à la place des événements de pointeur.*

**Il y a toujours une étape 0, sur la vraie machine, et elle passe avant tout.**
Pour le widget : déposer le dossier et voir l'icône apparaître. Tant que ça
n'arrive pas, écrire le reste ne sert à rien.
→ *Pour Manipule, l'étape 0 est déjà identifiée mais pas encore datée : ouvrir un
navigateur sur un poste du fond de sa classe, écouter une voix française, vérifier
qu'il y a du son. Avant la première ligne de code.*

**Un prototype jouable décide mieux qu'un questionnaire.** Les écrans cliquables
ont produit en un après-midi plus d'arbitrages que les cinquante questions : le
glisser-déposer contre les boutons, la bande mise en réserve, le schéma rempli par
l'élève, le mode de réponse laissé au choix de l'enseignante.
→ *Mettre le prototype devant elle plutôt que de lui poser le deuxième tour de
questions à l'écrit.*

**Un même objet peut échouer avec un public et réussir avec un autre.** La bande
numérique était trop complexe pour un élève seul ; elle est juste pour une
enseignante devant sa classe. On ne l'a pas simplifiée, on a changé d'utilisateur.
→ *Avant d'écarter un écran de Manipule, se demander s'il n'a pas simplement le
mauvais public. Et inversement : chaque écran retenu doit passer l'épreuve de
« personne n'est là pour aider ».*

---

## 10. Ce qui bloque

Trois réponses manquent, et deux d'entre elles peuvent remettre en cause ce
document.

**Q52 — la manipulation.** « Outils pour faire apparaître des unités et des
dizaines. Ou des jetons. » C'est glissé dans un « Autre » de la Q7, et c'est
littéralement le nom de l'application. Si la réponse est « sans manipulation, la
V1 n'a pas de sens », alors l'essentiel du travail n'est pas le QCM mais un
espace de travail avec des objets déplaçables, et tout ce qui précède est à
refaire. Il faut cette réponse en premier.

**Q53 — qui écrit les deux mauvaises réponses**, et sous quelle forme l'élève les
voit : `8`, ou `Il reste 8 pommes` ? Ses cinq exemples formulent les réponses en
phrase, ce qui est charmant à lire et pénible à fabriquer en trois variantes
plausibles.

**Q51 — la liste des compétences** est-elle complète, et ces intitulés
existent-ils dans Ensemble ? De ça dépend le jour où les deux applications se
parleront.
