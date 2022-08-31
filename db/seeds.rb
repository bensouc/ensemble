# User.create!(email: "bensouc@gmail.com", password: "secret", first_name: "toto", last_name: "titi")

s= Skill.where(grade: "CM1")
c = s.count
puts "Destroy all CM1 Worplan"
wp = WorkPlan.where(grade: "CM1" )
wp.each(&:destroy)
puts "Destroy all CM1 skills & challenges"
s.each {|skill|
  chals = Challenge.where(skill: skill)
  chals.each(&:destroy)
  skill.destroy
}

puts "#{c} skills ont été détruites"

puts "creating all the Skills"
Skill.create!(domain: 'Conjugaison', level: '1', symbol:'◼', name:'Reconnaître passé, présent et futur', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '1', symbol:'⬥', name:'Trouver l’infinitif d’un verbe', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '2', symbol:'◼', name:'Conjuguer les verbes du 1re groupe au présent', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '2', symbol:'⬥', name:'Conjuguer les verbes être et avoir au présent', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '2', symbol:'▲', name:'Conjuguer les verbes faire, dire, aller, venir, pouvoir, voir, vouloir et prendre au présent', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '2', symbol:'🞮', name:'Conjuguer les verbes du 2ème groupe au présent', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '3', symbol:'◼', name:'Conjuguer les verbes du 1re groupe à l’imparfait', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '3', symbol:'⬥', name:'Conjuguer les verbes être et avoir à l’imparfait', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '3', symbol:'▲', name:'Conjuguer les verbes faire, dire, aller, venir, pouvoir, voir, vouloir et prendre à l’imparfait', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '3', symbol:'🞮', name:'Conjuguer les verbes du 2ème groupe à l’imparfait', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '4', symbol:'◼', name:'Conjuguer les verbes du premier groupe au passé composé', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '4', symbol:'⬥', name:'Conjuguer les verbes être et avoir au passé composé', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '4', symbol:'▲', name:'Conjuguer les verbes faire, dire, aller, venir, pouvoir, voir, vouloir et prendre au passé composé', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '4', symbol:'🞮', name:'Conjuguer les verbes du 2ème groupe au passé composé', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '5', symbol:'◼', name:'Conjuguer les verbes du 1re groupe au futur', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '5', symbol:'⬥', name:'Conjuguer les verbes être et avoir au futur', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '5', symbol:'▲', name:'Conjuguer les verbes faire, dire, aller, venir, pouvoir, voir, vouloir et prendre au futur', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '5', symbol:'🞮', name:'Conjuguer les verbes du 2ème groupe au futur', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '6', symbol:'◼', name:'Reconnaître le radical et la terminaison d’un verbe', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '6', symbol:'⬥', name:'Identifier les 3 groupes de verbes', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '6', symbol:'▲', name:'Distinguer temps simples et temps composés', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '6', symbol:'🞮', name:'Savoir distinguer les participes passés en -é et l’infinitif en -er', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '7', symbol:'◼', name:'Connaitre les marques de temps à l’imparfait', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '7', symbol:'⬥', name:'Connaitre les marques de temps au futur', grade: 'CM1')
Skill.create!(domain: 'Conjugaison', level: '7', symbol:'▲', name:'Connaitre les régularités de marques et de personnes au temps simples', grade: 'CM1')


Skill.create!(domain: 'Vocabulaire', level: '1', symbol:'◼', name:'Classer les lettres dans l’ordre alphabétique', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '1', symbol:'⬥', name:'Classer des mots par catégories', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '1', symbol:'▲', name:'Trouver le mot étiquette.', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '2', symbol:'◼', name:'Classer des mots d’après la première lettre', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '2', symbol:'⬥', name:'Identifier les mots de la même famille', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '3', symbol:'◼', name:'Classer des mots dans l’ordre alphabétique (2 lettres identiques)', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '3', symbol:'⬥', name:'Reconnaître et trouver des contraires', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '3', symbol:'▲', name:'Trouver un mot repère dans le dictionnaire', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '4', symbol:'◼', name:'Classer des mots dans l’ordre alphabétique (début identique)', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '4', symbol:'⬥', name:'Reconnaître et trouver des synonymes', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '4', symbol:'▲', name:'Comprendre un article de dictionnaire : retrouver le mot défini et différencier la définition de l’exemple', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '5', symbol:'◼', name:'Trouver un mot dans le dictionnaire', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '5', symbol:'⬥', name:'Comprendre un article de dictionnaire : savoir donner la classe grammaticale, un synonyme et un antonyme du mot recherché', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '5', symbol:'▲', name:'Choisir la bonne définition pour un mot à plusieurs sens', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '6', symbol:'◼', name:'Trouver un mot dans un dictionnaire dans un temps limité (2 min)', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '6', symbol:'⬥', name:'Regrouper des mots selon le sens de leur préfixe et de leur suffixe', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '6', symbol:'▲', name:'Identifier les niveaux de langue (langage familier, courant,
soutenu)', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '6', symbol:'🞮', name:'Trouver l’orthographe d’un mot à l’aide d’un outil (répertoire, dictionnaire, etc.)', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '7', symbol:'◼', name:'Utiliser le dictionnaire pour rechercher le sens d’un homonyme', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '7', symbol:'⬥', name:'Connaître quelques homonymes', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '7', symbol:'▲', name:'Faire la différence entre sens propre et sens figuré', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '7', symbol:'🞮', name:'Dans un texte, à l’oral, relever les mots relevant d’un même champ lexical', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '7', symbol:'⬟', name:'Pour un mot, fournir un ou plusieurs mots de la famille, en vérifier l’orthographe', grade: 'CM1')
Skill.create!(domain: 'Vocabulaire', level: '7', symbol:'♥', name:'Regrouper des mots selon le sens de leur préfixe ou de leur suffixe et connaître ce sens', grade: 'CM1')

Skill.create!(domain: 'Orthographe', level: '1', symbol:'◼', name:'Écrire sans erreur de manière autonome des mots simples en respectant les correspondances entre lettres et sons', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '2', symbol:'◼', name:'Savoir qu’il faut mettre un M devant m, b, p', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '3', symbol:'◼', name:'Connaitre les valeurs de la lettre «g»', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '3', symbol:'⬥', name:'Distinguer «et» «es» «est »', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '4', symbol:'◼', name:'Connaître les valeurs de la lettre « S »', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '4', symbol:'⬥', name:'Connaitre les valeurs de la lettre « C »', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '4', symbol:'▲', name:'Distinguer « a/à »', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '4', symbol:'🞮', name:'Distinguer « à/au/aux »', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '4', symbol:'⬟', name:'Identifier les adverbes en « -ment »', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '5', symbol:'◼', name:'Distinguer ou/où ', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '5', symbol:'▲', name:'Distinguer son/sa/ses', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '5', symbol:'🞮', name:'Distinguer son/sont', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '5', symbol:'⬟', name:'Mettre au pluriel les noms (cas du -s au pluriel)  ', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '5', symbol:'♥', name:'Mettre au pluriel les noms en -al', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '5', symbol:'⬤', name:'Mettre au pluriel que les noms en -s, -x, -z', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '5', symbol:'♣', name:'Mettre au pluriel les noms en –ou', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '6', symbol:'◼', name:'Mettre au pluriel les noms en –au, -eu, -eau', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '6', symbol:'⬥', name:'Mettre au pluriel les noms en –ail', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '6', symbol:'▲', name:'Mettre au féminin les noms', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '6', symbol:'🞮', name:'Mettre au pluriel les adjectifs', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '6', symbol:'⬟', name:'Mettre au féminin les adjectifs', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '6', symbol:'♥', name:'Connaitre les valeurs de la lettre «t»', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '6', symbol:'♣', name:' Ecrire correctement les noms et adjectifs qui se terminent par une lettre muette', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '7', symbol:'◼', name:'Ecrire correctement -é ou -er à la fin d’un verbe', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '7', symbol:'⬥', name:'Distinguer ses/ces/c’est/s’est ; ce/se, c’/s’', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '7', symbol:'▲', name:'Distinguer ce/cette/cet/ces', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '7', symbol:'🞮', name:'Connaitre les valeurs de la lettre «x»', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '7', symbol:'⬟', name:'Savoir marquer tous les accords dans le groupe nominal (féminin et pluriel)', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '7', symbol:'♥', name:'Connaitre les accents', grade: 'CM1')
Skill.create!(domain: 'Orthographe', level: '7', symbol:'♣', name:'Savoir utiliser des préfixes et des suffixes', grade: 'CM1')

Skill.create!(domain: 'Grammaire', level: '1', symbol:'◼', name:'Reconnaître une phrase et différencier phrase/ligne', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '1', symbol:'⬥', name:'Mettre des mots dans l’ordre pour former une phrase', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '1', symbol:'▲', name:'Reconnaitre le verbe dans une phrase', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '1', symbol:'🞮', name:'Savoir remplacer un groupe nominal par un pronom personnel', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '2', symbol:'◼', name:'Trouver le sujet du verbe lorsque c’est un pronom personnel', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '2', symbol:'⬥', name:'Dans un groupe nominal, reconnaître et distinguer le nom (propre et commun) et le déterminant (article)', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '2', symbol:'▲', name:'Distinguer les noms propres et les noms communs', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '2', symbol:'🞮', name:'Donner le genre (masculin/féminin) d’un nom', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '2', symbol:'⬟', name:'Donner le nombre (singulier/pluriel) d’un nom', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '2', symbol:'♥', name:'Reconnaitre et transformer les formes affirmatives et négatives simples', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '3', symbol:'◼', name:'Trouver le sujet du verbe lorsque c’est un groupe nominal', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '3', symbol:'⬥', name:'Dans un groupe nominal, reconnaître et distinguer le nom (propre et commun),le déterminant et l’adjectif qualificatif', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '3', symbol:'▲', name:'Identifier le genre d’un groupe nominal', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '3', symbol:'🞮', name:'Identifier le nombre d’un groupe nominal', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '3', symbol:'⬟', name:'Reconnaître les principaux constituants de la phrase : les compléments', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '3', symbol:'♥', name:'Distinguer l’article défini de l’article indéfini', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '4', symbol:'◼', name:'Identifier la nature du sujet (nom, GN, PP)', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '4', symbol:'⬥', name:'Reconnaître un adjectif qualificatif, un verbe, un déterminant, un nom, un pronom personnel dans une phrase.', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '4', symbol:'▲', name:'Identifier les pronoms et dire ce qu’ils désignent', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '4', symbol:'🞮', name:'Reconnaître et distinguer dans un texte : les phrases déclaratives et les phrases interrogatives', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '4', symbol:'⬟', name:'Reconnaître et distinguer dans un texte : les formes négatives et les formes exclamatives ', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '4', symbol:'♥', name:'Savoir accorder le verbe avec son sujet (pronom personnel et groupe nominal simple)', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '5', symbol:'◼', name:'Trouver le sujet dans une phrase et les compléments d’objet (ce qu’on en dit )', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '5', symbol:'⬥', name:'Reconnaître un nom, un déterminant, un pronom personnel, un adjectif, un verbe dans un texte', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '5', symbol:'▲', name:'Marquer les accords en genre dans le groupe nominal', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '5', symbol:'▲', name:'Marquer les accords en nombre dans le groupe nominal', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '5', symbol:'🞮', name:'Transformer des phrases de différents types et formes : affirmatives/négatives (encore, jamais, toujours, ni…ni, etc.) et déclaratives/interrogatives', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '6', symbol:'◼', name:'Identifier le/les groupes nominaux dans une phrase', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '6', symbol:'⬥', name:'Reconnaître les principaux constituants de la phrase : le sujet (de qui on parle), ce qu’on en dit, les compléments circonstanciels', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '6', symbol:'▲', name:'Appliquer les règles simples d’accord dans la phrase (transposition).', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '6', symbol:'🞮', name:'Distinguer l’article défini de l’article indéfini', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '7', symbol:'◼', name:'Identifier les conjonctions de coordination', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '7', symbol:'⬥', name:'Identifier les adverbes', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '7', symbol:'▲', name:'Reconnaître et identifier le complément du nom dans un groupe nominal', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '7', symbol:'🞮', name:'Savoir accorder le verbe avec son sujet (accord avec le nom noyau)', grade: 'CM1')
Skill.create!(domain: 'Grammaire', level: '7', symbol:'⬟', name:'Reconnaître et distinguer tout type de phrases dans un texte (déclaratives, interrogatives, impératives)', grade: 'CM1')

Skill.create!(domain: 'Géométrie', level: '1', symbol:'◼', name:'1 - Reproduire une figure sur un quadrillage', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'◼', name:'2 - Suivre un itinéraire tracé sur un plan', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'◼', name:'3 - Représenter un itinéraire effectué sur un plan (village/quartier)', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'◼', name:'4 - Réaliser des déplacements sur un logiciel adapté', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'◼', name:'5 - Comprendre et produire un algorithme simple', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬟', name:'1- Utiliser le compas pour tracer un cercle', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬟', name:'2 - Utiliser le compas pour tracer un cercle en connaissant centre/point/rayon/diamètre', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬟', name:'3 - Reporter une longueur avec le compas sur une droite déjà tracée', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬟', name:'4 - Utiliser l’équerre pour tracer un angle droit', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬟', name:'5 - Utiliser une règle graduée, une équerre et un compas pour tracer les figures usuelles', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬟', name:'6 - Utiliser une règle graduée, une équerre et un compas pour tracer les figures usuelles', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬥', name:'1 - Connaître le vocabulaire des figures géométriques : droite, segment, milieu, angle droit, polygone, côté, sommet', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬥', name:'2 - Nommer et décrire : un carré/un rectangle/un triangle', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬥', name:'3 - Compléter un carré', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬥', name:'4 - Compléter un rectangle', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬥', name:'5 -Reconnaitre des droites perpendiculaires', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬥', name:'6 - Tracer des droites perpendiculaires', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬥', name:'7 - Connaître le vocabulaire des figures géométriques : cercle, disque, rayon, centre et diamètre', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬥', name:'8 - Reconnaitre des droites parallèles', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬥', name:'8 - Reconnaitre des droites parallèles', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬥', name:'10 - Reproduire une figure complexe', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'⬥', name:'11 - Construire une figure géométrique sur tout support', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'🞮', name:'1 - Reconnaître si une figure a un axe de symétrie avec du papier calque, des découpages ou des pliages', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'🞮', name:'2 - Repérer le ou les axes de symétrie d’une figure', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'🞮', name:'3 - Tracer la figure symétrique d’une autre par rapport à un axe sur une feuille quadrillée ou pointée', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'▲', name:'1 - Reconnaître et nommer les solides:cube, boule, cône, pyramide, cylindre, pavé droit, prisme droit', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'▲', name:'2 - Décrire des solides avec le bon vocabulaire : face, sommet et arête', grade: 'CM1')
Skill.create!(domain: 'Géométrie', level: '1', symbol:'▲', name:'3 - Construire le patron d’un cube', grade: 'CM1')

Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'◼', name:'1 - Mesurer des segments avec la règle (en cm)', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'◼', name:'2 - Mesurer des segments en cm et mm', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'◼', name:'3 - Mesures des lignes brisées en cm et en mm', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'◼', name:'4 - Connaître les relations entre les différentes unités de longueur : mm, cm, dm, m', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'◼', name:'5 - Connaître les relations entre les différentes unités de longueur : m et km', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'◼', name:'6 - Reproduire des segments en dm, cm et/ou mm en utilisant une règle graduée', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'◼', name:'7 - Mesurer des longueurs avec le mètre ruban', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'◼', name:'8 - Comparer des périmètres avec ou sans avoir recours à la mesure', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'◼', name:'9 - Mesurer des périmètres par rapport d’unité', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'◼', name:'10 - Calculer le périmètre d’un polygone', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'◼', name:'11 - Résoudre des problèmes de mesure de longueurs', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'⬥', name:'1 - Associer un objet à sa contenance', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'⬥', name:'2 - Comparer différentes contenances d’objets en faisant des transvasements', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'⬥', name:'3 - Comparer des contenances en mesurant', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'⬥', name:'4 - Savoir qu’un litre est la contenance d’un cube de 10 cm d’arête', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'⬥', name:'5 - Mesurer des contenances (cL,dL, L)', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'⬥', name:'6 - Connaître les relations entre L,dL et cL', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'⬥', name:'7 - Résoudre des problèmes impliquant des contenances', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'🞮', name:'1 - Indiquer et comparer des angles par superposition, avec du papier calque ou en utilisant un gabarit', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'🞮', name:'2 - Estimer, puis vérifier en utilisant l’équerre, qu’un angle est droit, aigu ou obtus', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'🞮', name:'3 - Construire un angle droit à l’aide de l’équerre', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'▲', name:'1 -Comparer des surfaces selon leur aire par estimation visuelle, par superposition ou découpage et recollement', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'▲', name:'2 - Mesurer des aires avec une unité donnée', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'▲', name:'3 - Construire des surfaces de même aire', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'▲', name:'4 - Construire des surfaces d’aire donnée', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'▲', name:'5 - Différencier aire et périmètre d’une figure', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'⬟', name:'1 - Lire l’heure (heure pile)', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'⬟', name:'2 - Lire l’heure (pile et demie)', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'⬟', name:'3 - Lire l’heure (pile, demie, quart, moins quart)', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'⬟', name:'4 - Lire l’heure du matin et de l’après-midi', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'⬟', name:'5 - Connaître les relations entre mesures du temps (1 semaine =7 jours; 1 mois =29,30 ou 31 jours, 1 année = 365j ; 1 année =12 mois)', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'⬟', name:'6 - Connaître les relations entre mesures du temps (année/siècle/millénaire, jour/heure, heure/minute, minute/seconde)', grade: 'CM1')
Skill.create!(domain: 'Grandeurs et Mesures', level: '1', symbol:'⬟', name:'7 - Résoudre des problèmes de durée (heure et minute)', grade: 'CM1')

Skill.create!(domain: 'Numération', level: '1', symbol:'◼', name:'Connaître les nombres (écrire/nommer) jusqu’à 100', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '1', symbol:'⬥', name:'Comparer, ranger et encadrer les nombres jusqu’à 100', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '1', symbol:'▲', name:'Ecrire des suites de nombres jusqu’à 100', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '1', symbol:'🞮', name:'Décomposer et représenter une quantité jusqu’à 100', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '1', symbol:'⬟', name:'Repérer et placer les nombres jusqu’à 100 sur une droite graduée', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '2', symbol:'◼', name:'Connaître les nombres (écrire/nommer) jusqu’à 1 000', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '2', symbol:'⬥', name:'Comparer, ranger et encadrer les nombres jusqu’à 1 000', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '2', symbol:'▲', name:'Ecrire des suites de nombres jusqu’à 1 000', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '2', symbol:'🞮', name:'Décomposer et représenter une quantité jusqu’à 1 000', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '2', symbol:'⬟', name:'Repérer et placer les nombres jusqu’à 1 000 sur une droite graduée', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '2', symbol:'♥', name:'Connaitre les nombres romains jusqu’à X', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '3', symbol:'◼', name:'Connaître les nombres (écrire/nommer) jusqu’à 10 000', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '3', symbol:'⬥', name:'Comparer, ranger et encadrer les nombres jusqu’à 10 000', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '3', symbol:'▲', name:'Ecrire des suites de nombres jusqu’à 10 000', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '3', symbol:'🞮', name:'Décomposer et représenter une quantité jusqu’à 10 000', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '3', symbol:'⬟', name:'Repérer et placer les nombres jusqu’à 10 000 sur une droite graduée', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '3', symbol:'♥', name:'Connaitre les nombres romains jusqu’à XX', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '4', symbol:'◼', name:'Connaître les nombres (écrire/nommer) jusqu’à 100 000', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '4', symbol:'⬥', name:'Comparer, ranger et encadrer les nombres jusqu’à 100 000', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '4', symbol:'▲', name:'Ecrire des suites de nombres jusqu’à 100 000', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '4', symbol:'🞮', name:'Décomposer et représenter une quantité jusqu’à 100 000', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '4', symbol:'⬟', name:'Repérer et placer les nombres jusqu’à 100 000 sur une droite graduée', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '4', symbol:'♥', name:'Comparer des fractions simples de même dénominateur', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '5', symbol:'◼', name:'Connaître les nombres (écrire/nommer) jusqu’à 1 000 000', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '5', symbol:'⬥', name:'Comparer, ranger et encadrer les nombres jusqu’à 1 000 000', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '5', symbol:'▲', name:'Ecrire des suites de nombres jusqu’à 1 000 000', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '5', symbol:'🞮', name:'Décomposer et représenter une quantité jusqu’à 1 000 000', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '5', symbol:'⬟', name:'Repérer et placer les nombres jusqu’à 1 000 000 sur une droite graduée', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '5', symbol:'♥', name:'Décomposer une fraction avec sa partie entière', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '5', symbol:'♣', name:'Connaître des décompositions additives et multiplicatives des fractions simples', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '5', symbol:'⬤', name:'Encadrer une fraction simple par deux nombres entiers', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '6', symbol:'◼', name:'Connaître les fractions décimales (écrire/nommer)', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '6', symbol:'⬥', name:'Connaître les relations entre unités, dixièmes, centièmes...', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '6', symbol:'▲', name:'Trouver la fraction décimale égale à la somme d’un entier et d’une fraction', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '6', symbol:'🞮', name:'Repérer et placer les fractions décimales sur une droite graduée', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '6', symbol:'⬟', name:'Ajouter des fractions décimales de même numérateur', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '6', symbol:'♥', name:'Encadrer une fraction décimale entre deux entiers consécutifs', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '6', symbol:'♣', name:'Passer d’une écriture décimale à une écriture fractionnaire', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '7', symbol:'◼', name:'Ecrire en chiffres un nombre décimal', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '7', symbol:'⬥', name:'Comparer, ranger et encadrer des nombres décimaux', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '7', symbol:'▲', name:'Décomposer un nombre décimal', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '7', symbol:'🞮', name:'Repérer et placer des nombres décimaux sur une droite graduée', grade: 'CM1')
Skill.create!(domain: 'Numération', level: '7', symbol:'⬟', name:'Connaitre les nombres romains jusqu’à L', grade: 'CM1')

Skill.create!(domain: 'Calcul', level: '1', symbol:'◼', name:'Mémoriser les tables d’addition <10', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '1', symbol:'⬥', name:'Additionner des dizaines entières', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '1', symbol:'▲', name:'Connaître les compléments à 10', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '1', symbol:'🞮', name:'Connaître les doubles et les moitiés des nombres <20', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '1', symbol:'⬟', name:'Poser et résoudre une addition simple (sans retenue)', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '1', symbol:'♥', name:'Poser et résoudre une soustraction simple (sans retenue)', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '2', symbol:'◼', name:'Connaître les tables de multiplication de 2, 5 et 10', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '2', symbol:'⬥', name:'Ajouter et retirer 9 et 11', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '2', symbol:'▲', name:'Connaitre les nombres pairs et impairs', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '2', symbol:'🞮', name:'Connaître les doubles et les moitiés des nombres <50', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '2', symbol:'⬟', name:'Écrire des nombres dictés jusqu’à 1 000', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '2', symbol:'♥', name:'Poser et résoudre une soustraction avec retenue', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '2', symbol:'♣', name:'Poser et résoudre une addition avec retenue', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '3', symbol:'◼', name:'Connaître les tables de multiplication jusqu’à 5', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '3', symbol:'⬥', name:'Multiplier un nombre par 10 et 100', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '3', symbol:'▲', name:'Réaliser des additions sur les 100 premiers nombres', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '3', symbol:'🞮', name:'Connaître le complément à 100 d’un nombre', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '3', symbol:'⬟', name:'Connaître les critères de divisibilité par 2, 5 et 10', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '3', symbol:'♥', name:'Poser et résoudre une addition de plusieurs nombres (nbs à 3 chiffres)', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '3', symbol:'♣', name:'Poser et résoudre une multiplication par un nombre à 1 chiffre', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '4', symbol:'◼', name:'Connaître les tables de multiplication jusqu’à 10', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '4', symbol:'⬥', name:'Connaître le quadruple et le quart des nombres jusqu’à 100', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '4', symbol:'▲', name:'Diviser un nombre par 10 et 100', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '4', symbol:'🞮', name:'Calculer le quotient et le reste d’une division par un nombre à 1 chiffre', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '4', symbol:'⬟', name:'Ecrire des fractions simples', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '4', symbol:'♥', name:'Écrire des nombres dictés jusqu’à 100 000', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '4', symbol:'♣', name:'Poser et résoudre une multiplication par un nombre à 2 chiffres', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '5', symbol:'◼', name:'Multiplier un nombre par 20, 200 ...', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '5', symbol:'⬥', name:'Connaître les compléments à 1 000', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '5', symbol:'▲', name:'Réaliser des soustractions sur les 100 premiers nombres', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '5', symbol:'🞮', name:'Connaître les doubles et moitiés les plus courants', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '5', symbol:'⬟', name:'Ecrire des fractions décimales', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '5', symbol:'♥', name:'Écrire des nombres dictés jusqu’à 1 000 000', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '5', symbol:'♣', name:'Poser et résoudre une division de deux nombres entiers', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '6', symbol:'◼', name:'Encadrer un nombre entier à la dizaine, à la centaine...', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '6', symbol:'⬥', name:'Multiplier par 10 et 100 des nombres décimaux', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '6', symbol:'▲', name:'Ajouter et retirer 19 et 21', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '6', symbol:'🞮', name:'Calculer le quotient et le reste d’une division par 10, 25, 50 et 100', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '6', symbol:'⬟', name:'Estimer des sommes, des différences', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '6', symbol:'♥', name:'Multiplier et diviser par 10 des nombres décimaux', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '6', symbol:'♣', name:'Poser et résoudre une multiplication par un nombre à plusieurs chiffres', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '7', symbol:'◼', name:'Ajouter et retirer 99 et 101', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '7', symbol:'⬥', name:'Connaître les doubles et moitiés des nombres jusqu’à 500', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '7', symbol:'▲', name:'Connaître le complément d’un décimal à lentier supérieur', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '7', symbol:'🞮', name:'Écrire des nombres décimaux dictés', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '7', symbol:'◼', name:'Poser et résoudre une addition de nombres décimaux', grade: 'CM1')
Skill.create!(domain: 'Calcul', level: '7', symbol:'⬥', name:'Poser et résoudre une soustraction de nombres décimaux', grade: 'CM1')
