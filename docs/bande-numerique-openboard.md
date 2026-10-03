# La bande numérique — widget OpenBoard

Chantier mené **en parallèle de Manipule**, et indépendant de lui.
Document de plan ; la définition de Manipule vit dans `docs/manipule-v1.md`.

**Dépôt public, licence MIT :** <https://github.com/bensouc/ensemble-openboard-extensions>
Le widget y est écrit et poussé ; une copie de travail vit aussi dans
`widgets/bande-numerique.wgt/`.

---

## 1. Pourquoi ce chantier existe

La bande numérique a été écartée de Manipule après l'essai : pour un élève **seul**,
choisir ses sauts suppose d'avoir déjà la stratégie que l'outil est censé soutenir.
L'objection est juste, et elle disparaît complètement quand on change d'utilisateur.

Sur le tableau de la classe, ce n'est plus l'élève qui choisit : **c'est l'enseignante
qui conduit, devant tout le monde.** Elle pose le départ, elle fait le saut, la classe
lit le résultat. Le même artefact échoue en autonomie et réussit en collectif.

D'où un outil séparé, avec son propre public et son propre support : une application
OpenBoard, sur le poste Windows de la classe.

## 2. Ce que fait le widget

- Une bande graduée de 0 à l'échelle choisie.
- **Avancer et reculer** par unité, par dizaine, par centaine. Six boutons.
- **Choisir le point de départ au clic** sur la bande.
- **Changer l'échelle** : 10, 20, 50, 100, 1000. Cela change l'étendue de la bande
  et rien d'autre — les valeurs déjà posées ne bougent pas, on redessine.
- **Annuler le dernier saut.**
- Chaque saut reste dessiné, en arc au-dessus de la bande, avec sa valeur.
- Le point de départ est marqué distinctement du point d'arrivée.

Pas de bandeau « Je suis sur 19, +8 depuis 11 » : le départ est signalé sur la bande,
l'arrivée se lit au bout du dernier arc. Le chiffre écrit ferait le travail de lecture
à la place de la classe.

### Ce que la spécification ne tranche pas encore

Cinq points à décider avant d'écrire le code. Les propositions sont les miennes.

**Un saut de 1 sur une bande de 1000 est invisible** — un millième de la largeur.
*Proposition :* garder les six boutons quelle que soit l'échelle, mais donner à chaque
arc une largeur minimale dessinable. La disproportion est elle-même un contenu :
montrer qu'un pas de 1 ne se voit plus à l'échelle 1000 est une leçon, pas un défaut.

**On ne peut pas dessiner mille graduations.** *Proposition :* la graduation suit
l'échelle — trait à chaque unité tant qu'il reste au moins une douzaine de pixels
entre deux, sinon tous les 5, 10, 50 ou 100, avec les nombres écrits seulement sur
les traits principaux.

**Que devient une valeur hors échelle ?** On est à 450, on passe à l'échelle 100.
*Proposition :* ne jamais perdre une valeur. L'échelle choisie est alors remplacée
par la plus petite qui contienne la position, et le widget le dit.

**Choisir un nouveau départ efface-t-il les sauts ?** *Proposition :* oui, un nouveau
départ est un nouvel exercice. « Annuler le saut » couvre le cas du clic malheureux.

**Pas de négatifs** — l'échelle est positive, la bande part de 0. Un recul qui
passerait sous zéro est refusé : le bouton s'éteint plutôt que de produire un −3.

## 3. Le contour technique

### OpenBoard ne se forke pas

Une « application » OpenBoard est un dossier suffixé `.wgt` contenant du HTML. Rien
à compiler, pas de Qt, pas de C++, aucune modification d'OpenBoard. Le widget est du
contenu chargé par l'application, pas un dérivé lié à son code : la GPL d'OpenBoard
ne s'impose donc pas au nôtre.

```
bande-numerique.wgt/
├── config.xml     métadonnées lues par la bibliothèque d'applications
├── icon.png       la vignette dans la palette de droite
└── index.html     le widget lui-même, CSS et JS inclus
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<widget xmlns="http://www.w3.org/ns/widgets"
        id="ch.vroadstudio.bande-numerique"
        version="0.1"
        width="900" height="340">
  <name>Bande numérique</name>
  <description>Avancer et reculer par unité, dizaine ou centaine.</description>
  <author href="https://vroadstudio.ch">vroad studio</author>
  <content src="index.html"/>
</widget>
```

Un gabarit de départ existe dans le dépôt OpenBoard, sous `resources/widgets/template.wgt`.

### Installation, et pourquoi c'est la bonne nouvelle

Sur Windows, deux emplacements possibles :

| Emplacement | Droits | Survie |
|---|---|---|
| `%localappdata%/OpenBoard/interactive content` | **aucun droit particulier** | conservé |
| `Program Files/OpenBoard/library/applications` | administrateur | effacé à chaque réinstallation d'OpenBoard |

**On vise le premier.** Dans une école où personne n'a les droits administrateur sur
le poste de la classe, un outil qui s'installe en copiant un dossier dans son propre
profil est un outil qui sera réellement installé. Les sous-dossiers y sont permis,
ce qui permet de ranger plusieurs widgets ensemble si d'autres suivent.

### Comment l'enseignante l'appelle

C'est le point qui compte pour elle, et il ne demande rien de particulier : une fois
le dossier copié, la bande numérique devient **une application d'OpenBoard comme les
autres**.

1. Elle ouvre OpenBoard et sa page de cours.
2. Dans la palette de droite, onglet **Applications**, la bande numérique apparaît
   avec son icône, à côté de la calculatrice et des autres outils fournis.
3. Elle la fait glisser sur la page. Le widget s'ouvre à l'endroit déposé.
4. Elle le redimensionne à la taille qu'elle veut ; la bande suit.
5. Elle s'en sert. Sur une autre page, elle la glisse à nouveau.

Aucun compte, aucune connexion, aucun réglage : l'outil est dans sa palette, elle le
prend quand elle en a besoin.

### Le reste de la chaîne

- **Rendu** : SVG avec `viewBox`, en 100 % de la largeur et de la hauteur, pour que
  la bande suive la taille que l'enseignante donne au widget sur le tableau.
- **Entrée** : `pointerdown` plutôt que `click`. Un tableau interactif est tactile,
  et c'est un doigt qui posera le point de départ. Boutons larges, zone de clic de la
  bande généreuse en hauteur.
- **JavaScript conservateur.** Le moteur est celui de Qt embarqué dans la version
  d'OpenBoard installée, pas le navigateur du poste : on ne sait pas d'avance de
  quelle année est son Chromium. Même discipline que pour le prototype de Manipule,
  où une expression régulière trop récente aurait suffi à tout casser en silence.
- **Mémoire** : `window.sankore.setPreference(clé, valeur)` et
  `window.sankore.preference(clé, défaut, rappel)`, en chaînes de caractères, avec
  une variante `window.sankore.async` qui rend des promesses. On y garde l'échelle et
  le point de départ, pour qu'un tableau rouvert retrouve son réglage.
- **Boucle de développement** : poser le dossier `.wgt`, lancer OpenBoard, glisser le
  widget sur le tableau, puis clic droit pour « Recharger » et « Inspecteur web ».
  L'inspecteur est un vrai inspecteur : on développe dedans.

## 4. Les étapes

**Étape 0 — prouver que ça charge.** Sur le poste de sa classe : relever la version
d'OpenBoard, vérifier que `%localappdata%/OpenBoard/interactive content` existe, y
déposer le gabarit vierge et le voir apparaître dans la palette. Tant que ce
dossier-là n'affiche pas un widget, rien d'autre ne compte. *Une demi-journée, et
elle doit être faite en premier.*

**Étape 1 — le widget. ✅ fait.** La bande, les six boutons, le clic sur le départ,
l'annulation, les cinq longueurs, les arcs qui restent. S'y sont ajoutés en cours de
route le réglage du **début de la bande** — elle ne commence pas forcément à zéro —
et l'écriture de **tous les nombres sur les bandes de 10 et 20**. Vérifié en
exécution, pas seulement à la lecture.

**Étape 2 — l'habillage. ✅ fait.** Icône, `config.xml`, mémoire des réglages via
`sankore`, logo Ensemble encodé dans la page, lien vers l'application, et une notice
d'installation pour une enseignante dans le README du dépôt.

**Étape 3 — l'essai en classe**, devant les élèves, elle aux commandes.

## 5. Hors périmètre

- Aucun lien avec Manipule : ni compte, ni données, ni serveur. Le widget est un fichier.
- Pas d'enregistrement dans le document OpenBoard au-delà des préférences du widget.
- Pas de nombres négatifs, pas de décimaux, pas de fractions.
- Pas de multi-touch : un doigt à la fois suffit.
- Pas de version macOS ou Linux tant que l'essai n'a pas eu lieu, même si le format
  est identique et que ce sera gratuit le jour voulu.

## 6. Rapport avec Manipule

Deux produits distincts, et il faut résister à l'envie de les rapprocher.

|  | Manipule | La bande |
|---|---|---|
| Utilisateur | l'élève, seul | l'enseignante, devant la classe |
| Support | navigateur, poste du fond de classe | OpenBoard, tableau |
| Correction | automatique | aucune, c'est la classe qui lit |
| Livraison | une application servie | un dossier à copier |

Le seul point commun est la façon de dessiner une bande en SVG, soit un fichier.
Fabriquer une bibliothèque partagée pour un fichier coûterait plus cher que de
l'écrire deux fois.
