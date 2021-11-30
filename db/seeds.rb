require "open-uri"

puts "destroying current data"
# WorkPlanSkill.destroy_all
# Challenge.destroy_all
# Skill.destroy_all
# WorkPlanDomain.destroy_all
# WorkPlan.destroy_all
# Student.destroy_all
# Classroom.destroy_all
# User.destroy_all

puts "creating user"

user1 = User.create!(email:'toto@gmail.com', password:'secret', first_name:'toto', last_name: 'titi')
file = URI.open('https://cdn0.iconfinder.com/data/icons/basic-50/24/essential_basic_ui_user-512.png')
user1.photo.attach(io: file, filename: 'essential_basic_ui_user-512.png', content_type: 'image/png')

puts "creating Classroom"

classroom1 = Classroom.create!(grade: 'ce1', user: user1)

puts "creating Student"

student1 = Student.create!(first_name: 'Adèle', classroom: classroom1)

puts "creating WorkPlan"

work_plan1 = WorkPlan.create!(name: 'Mon premier PT avec élève', user: user1, student: student1)
work_plan2 = WorkPlan.create!(name: 'Mon premier PT sans élève', user: user1)

puts "creating WorkPlanDomain"

work_plan_domain1 = WorkPlanDomain.create!(domain: 'Vocabulaire', level: 1, work_plan: work_plan1)
work_plan_domain2 = WorkPlanDomain.create!(domain: 'Grammaire', level: 2, work_plan: work_plan1)

puts "creating all the Skills"
  skill1 = Skill.create!(domain: 'Vocabulaire', level: 1, symbol: '◼', name: 'Classer les lettres dans l’ordre alphabétique')
  skill2 = Skill.create!(domain: 'Vocabulaire', level: 1, symbol: '⬥', name: 'Classer des mots par catégories')
  skill3 = Skill.create!(domain: 'Vocabulaire', level: 2, symbol: '◼', name: 'Classer des mots d’après la 1ère lettre')
  skill4 = Skill.create!(domain: 'Vocabulaire', level: 2, symbol: '⬥', name: 'Trouver le mot étiquette.')
  skill5 = Skill.create!(domain: 'Vocabulaire', level: 3, symbol: '◼', name: 'Classer des mots dans l’ordre alphabétique')
  skill6 = Skill.create!(domain: 'Vocabulaire', level: 3, symbol: '⬥', name: 'Reconnaître et trouver des contraires')
  skill7 = Skill.create!(domain: 'Vocabulaire', level: 4, symbol: '◼', name: 'Trouver un mot repère dans le dictionnaire')
  skill8 = Skill.create!(domain: 'Vocabulaire', level: 4, symbol: '⬥', name: 'Reconnaître et trouver des synonymes')
  skill9 = Skill.create!(domain: 'Vocabulaire', level: 5, symbol: '◼', name: 'Trouver un mot dans le dictionnaire')
  skill10 = Skill.create!(domain: 'Vocabulaire', level: 5, symbol: '⬥', name: 'Trouver les mots de la même famille')
  skill11 = Skill.create!(domain: 'Vocabulaire', level: 6, symbol: '◼', name: 'Comprendre un article de dictionnaire')
  skill12 = Skill.create!(domain: 'Vocabulaire', level: 6, symbol: '⬥', name: 'Regrouper des mots selon leur préfixe ou leur suffix')
  skill13 = Skill.create!(domain: 'Vocabulaire', level: 7, symbol: '◼', name: 'Choisir la bonne définition pour un mot à plusieurs sens')
  skill14 = Skill.create!(domain: 'Vocabulaire', level: 7, symbol: '⬥', name: 'Faire la différence entre sens propre et sens figuré')
  skill15 = Skill.create!(domain: 'Grammaire', level: 1, symbol: '◼', name: 'Reconnaître une phrase et différencier phrase/ligne')
  skill16 = Skill.create!(domain: 'Grammaire', level: 1, symbol: '⬥', name: 'Trouver qui est désigné ou remplacer par il/elle, ils/elles')
  skill17 = Skill.create!(domain: 'Grammaire', level: 1, symbol: '🞮', name: 'Reconnaître les verbes dans une liste de mots')
  skill18 = Skill.create!(domain: 'Grammaire', level: 2, symbol: '◼', name: 'Mettre des mots dans l’ordre pour former une phrase')
  skill19 = Skill.create!(domain: 'Grammaire', level: 2, symbol: '⬥', name: 'Reconnaître le verbe dans une phrase')
  skill20 = Skill.create!(domain: 'Grammaire', level: 2, symbol: '🞮', name: 'Reconnaître passé, présent, futur')
  skill21 = Skill.create!(domain: 'Grammaire', level: 3, symbol: '◼', name: 'Reconnaître phrase affirmative et phrase négative (article) dans un groupe de mots')
  skill22 = Skill.create!(domain: 'Grammaire', level: 3, symbol: '⬥', name: 'Reconnaître le nom (propre et commun) et le déterminant')
  skill23 = Skill.create!(domain: 'Grammaire', level: 3, symbol: '▲', name: 'Différencier masculin/féminin , singulier/pluriel')
  skill24 = Skill.create!(domain: 'Grammaire', level: 3, symbol: '🞮', name: 'Trouver l’infinitif d’un verbe et le différencier du conjugué')
  skill25 = Skill.create!(domain: 'Grammaire', level: 4, symbol: '◼', name: 'Trouver le sujet du verbe et le manipuler (pronoms personnels)')
  skill26 = Skill.create!(domain: 'Grammaire', level: 4, symbol: '⬥', name: 'Reconnaître un adjectif qualificatif, un verbe, un déterminant, un nom dans une phrase.')
  skill27 = Skill.create!(domain: 'Grammaire', level: 4, symbol: '▲', name: 'Accorder les noms aux déterminants')
  skill28 = Skill.create!(domain: 'Grammaire', level: 4, symbol: '🞮', name: 'Conjuguer les verbes en –er , être, avoir et aller au présent')
  skill29 = Skill.create!(domain: 'Grammaire', level: 5, symbol: '◼', name: 'Trouver le sujet du verbe et identifier sa nature (nom, GN, PP)')
  skill30 = Skill.create!(domain: 'Grammaire', level: 5, symbol: '⬥', name: 'Reconnaître un adjectif qualificatif, un verbe, un déterminant, un nom dans un texte.')
  skill31 = Skill.create!(domain: 'Grammaire', level: 5, symbol: '▲', name: 'Marquer les accords dans le groupe nominal (régulier)')
  skill32 = Skill.create!(domain: 'Grammaire', level: 5, symbol: '🞮', name: 'Conjuguer les verbes les plus courants au présent')
  skill33 = Skill.create!(domain: 'Grammaire', level: 6, symbol: '◼', name: 'Construire une phrase négative et maîtriser les formes négatives (ne… plus, ne… rien…, ne … jamais)')
  skill34 = Skill.create!(domain: 'Grammaire', level: 6, symbol: '⬥', name: 'Reconnaître un nom (propre et commun), un déterminant, un pronom personnel, un adjectif, un verbe dans un texte.')
  skill35 = Skill.create!(domain: 'Grammaire', level: 6, symbol: '▲', name: 'Marquer les accords dans le groupe nominal (irrégulier)')
  skill36 = Skill.create!(domain: 'Grammaire', level: 6, symbol: '🞮', name: 'Conjuguer les verbes en –er , être, avoir à l’imparfait')
  skill37 = Skill.create!(domain: 'Grammaire', level: 7, symbol: '◼', name: 'Reconnaître et construire des phrases de différents types et formes.')
  skill38 = Skill.create!(domain: 'Grammaire', level: 7, symbol: '⬥', name: 'Reconnaître un nom (propre et commun), un déterminant, un pronom personnel, un adjectif, un verbe dans un texte. (révisions)')
  skill39 = Skill.create!(domain: 'Grammaire', level: 7, symbol: '▲', name: 'Appliquer les règles simples d’accord dans la phrase (transposition).')
  skill40 = Skill.create!(domain: 'Grammaire', level: 7, symbol: '🞮', name: 'Conjuguer les verbes en –er , être, avoir au futur')
  skill41 = Skill.create!(domain: 'Numération', level: 1, symbol: '◼', name: 'Connaître les nombres (écrire/nommer) jusqu’à 30')
  skill42 = Skill.create!(domain: 'Numération', level: 1, symbol: '⬥', name: 'Comparer, ranger, encadrer et situer sur une ligne graduée les nombres jusqu’à 30')
  skill43 = Skill.create!(domain: 'Numération', level: 1, symbol: '▲', name: 'Ecrire des suites de nombres jusqu’à 30')
  skill44 = Skill.create!(domain: 'Numération', level: 1, symbol: '🞮', name: 'Décomposer et représenter une quantité jusqu’à 30')
  skill45 = Skill.create!(domain: 'Numération', level: 2, symbol: '◼', name: 'Connaître les nombres (écrire/nommer) jusqu’à 60')
  skill46 = Skill.create!(domain: 'Numération', level: 2, symbol: '⬥', name: 'Comparer, ranger, encadrer et situer sur une ligne graduée les nombres jusqu’à 60')
  skill47 = Skill.create!(domain: 'Numération', level: 2, symbol: '▲', name: 'Ecrire des suites de nombres jusqu’à 60')
  skill48 = Skill.create!(domain: 'Numération', level: 2, symbol: '🞮', name: 'Décomposer et représenter une quantité jusqu’à 60')
  skill49 = Skill.create!(domain: 'Numération', level: 3, symbol: '◼', name: 'Connaître les nombres (écrire/nommer) jusqu’à 100')
  skill50 = Skill.create!(domain: 'Numération', level: 3, symbol: '⬥', name: 'Comparer, ranger, encadrer et situer sur une ligne graduée les nombres jusqu’à 100')
  skill51 = Skill.create!(domain: 'Numération', level: 3, symbol: '▲', name: 'Ecrire des suites de nombres jusqu’à 100')
  skill52 = Skill.create!(domain: 'Numération', level: 3, symbol: '🞮', name: 'Décomposer et représenter une quantité jusqu’à 100')
  skill53 = Skill.create!(domain: 'Numération', level: 4, symbol: '◼', name: 'Connaître les nombres (écrire/nommer) jusqu’à 200')
  skill54 = Skill.create!(domain: 'Numération', level: 4, symbol: '⬥', name: 'Comparer, ranger, encadrer et situer sur une ligne graduée les nombres jusqu’à 200')
  skill55 = Skill.create!(domain: 'Numération', level: 4, symbol: '▲', name: 'Ecrire des suites de nombres jusqu’à 200')
  skill56 = Skill.create!(domain: 'Numération', level: 4, symbol: '🞮', name: 'Décomposer et représenter une quantité jusqu’à 200')
  skill57 = Skill.create!(domain: 'Numération', level: 5, symbol: '◼', name: 'Connaître les nombres (écrire/nommer) jusqu’à 600')
  skill58 = Skill.create!(domain: 'Numération', level: 5, symbol: '⬥', name: 'Comparer, ranger, encadrer et situer sur une ligne graduée les nombres jusqu’à 600')
  skill59 = Skill.create!(domain: 'Numération', level: 5, symbol: '▲', name: 'Ecrire des suites de nombres jusqu’à 600')
  skill60 = Skill.create!(domain: 'Numération', level: 5, symbol: '🞮', name: 'Décomposer et représenter une quantité jusqu’à 600')
  skill61 = Skill.create!(domain: 'Numération', level: 6, symbol: '◼', name: 'Connaître les nombres (écrire/nommer) jusqu’à 1 000')
  skill62 = Skill.create!(domain: 'Numération', level: 6, symbol: '⬥', name: 'Comparer, ranger, encadrer et situer sur une ligne graduée les nombres jusqu’à 1 000')
  skill63 = Skill.create!(domain: 'Numération', level: 6, symbol: '▲', name: 'Ecrire des suites de nombres jusqu’à 1 000')
  skill64 = Skill.create!(domain: 'Numération', level: 6, symbol: '🞮', name: 'Décomposer et représenter une quantité jusqu’à 1 000')
  skill65 = Skill.create!(domain: 'Numération', level: 7, symbol: '◼', name: 'Connaître les nombres (écrire/nommer) jusqu’à 10 000')
  skill66 = Skill.create!(domain: 'Numération', level: 7, symbol: '⬥', name: 'Comparer, ranger, encadrer et situer sur une ligne graduée les nombres jusqu’à 10 000')
  skill67 = Skill.create!(domain: 'Numération', level: 7, symbol: '▲', name: 'Ecrire des suites de nombres jusqu’à 10 000')
  skill68 = Skill.create!(domain: 'Numération', level: 7, symbol: '🞮', name: 'Décomposer et représenter une quantité jusqu’à 10 000')
  skill69 = Skill.create!(domain: 'Calcul', level: 1, symbol: '◼', name: 'Ajouter et retirer 1')
  skill70 = Skill.create!(domain: 'Calcul', level: 1, symbol: '⬥', name: 'Mémoriser les tables d’addition <5')
  skill71 = Skill.create!(domain: 'Calcul', level: 1, symbol: '▲', name: 'Connaître les doubles des nombres < 5')
  skill72 = Skill.create!(domain: 'Calcul', level: 1, symbol: '🞮', name: 'Poser et résoudre une addition simple (sans retenue)')
  skill73 = Skill.create!(domain: 'Calcul', level: 2, symbol: '◼', name: 'Ajouter et retirer 2')
  skill74 = Skill.create!(domain: 'Calcul', level: 2, symbol: '⬥', name: 'Mémoriser les tables d’addition <8')
  skill75 = Skill.create!(domain: 'Calcul', level: 2, symbol: '▲', name: 'Connaître les doubles des nombres <10')
  skill76 = Skill.create!(domain: 'Calcul', level: 2, symbol: '🞮', name: 'Poser et résoudre une soustraction simple (sans retenue)')
  skill77 = Skill.create!(domain: 'Calcul', level: 3, symbol: '◼', name: 'Additionner des dizaines entières')
  skill78 = Skill.create!(domain: 'Calcul', level: 3, symbol: '⬥', name: 'Mémoriser les tables d’addition <10')
  skill79 = Skill.create!(domain: 'Calcul', level: 3, symbol: '▲', name: 'Connaître les compléments à 10')
  skill80 = Skill.create!(domain: 'Calcul', level: 3, symbol: '🞮', name: 'Poser et résoudre une addition avec retenue (nbs à 2 chiffres)')
  skill81 = Skill.create!(domain: 'Calcul', level: 4, symbol: '◼', name: 'Ajouter/ retirer 10')
  skill82 = Skill.create!(domain: 'Calcul', level: 4, symbol: '⬥', name: 'Mémoriser les tables de multiplication de 2 et 5')
  skill83 = Skill.create!(domain: 'Calcul', level: 4, symbol: '▲', name: 'Connaître les doubles et moitiés des nombres <10')
  skill84 = Skill.create!(domain: 'Calcul', level: 4, symbol: '🞮', name: 'Poser et résoudre une addition de plus de 2 nombres (nombres à 3 chiffres)')
  skill85 = Skill.create!(domain: 'Calcul', level: 5, symbol: '◼', name: 'Ajouter/ retirer 9 ou 11')
  skill86 = Skill.create!(domain: 'Calcul', level: 5, symbol: '⬥', name: 'Mémoriser les tables de multiplication de 2, 4 et 5')
  skill87 = Skill.create!(domain: 'Calcul', level: 5, symbol: '▲', name: 'Connaître les nombres pairs et impairs')
  skill88 = Skill.create!(domain: 'Calcul', level: 5, symbol: '🞮', name: 'Poser et résoudre une soustraction avec retenue')
  skill89 = Skill.create!(domain: 'Calcul', level: 6, symbol: '◼', name: 'Additionner et soustraire des nombres <20')
  skill90 = Skill.create!(domain: 'Calcul', level: 6, symbol: '⬥', name: 'Mémoriser les tables de multiplication de 2 à 5')
  skill91 = Skill.create!(domain: 'Calcul', level: 6, symbol: '▲', name: 'Connaître les doubles et moitiés les plus courants')
  skill92 = Skill.create!(domain: 'Calcul', level: 6, symbol: '🞮', name: 'Poser et résoudre une multiplication par un nombre à 1 chiffre sans retenue')
  skill93 = Skill.create!(domain: 'Calcul', level: 7, symbol: '◼', name: 'Additionner et soustraire des nombres <30')
  skill94 = Skill.create!(domain: 'Calcul', level: 7, symbol: '⬥', name: 'Mémoriser les tables de multiplication jusqu’à 10')
  skill95 = Skill.create!(domain: 'Calcul', level: 7, symbol: '▲', name: 'Connaître les compléments à 100')
  skill96 = Skill.create!(domain: 'Calcul', level: 7, symbol: '🞮', name: 'Poser et résoudre une multiplication par un nombre à 1 chiffre avec retenue')



puts "creating Challenges"

challenge1 = Challenge.create!(name: "Classer les lettres dans l’ordre alphabétique", skill: skill1, user: user1)
challenge2 = Challenge.create!(name: 'Classer des mots par catégories', skill: skill2, user: user1)
challenge3 = Challenge.create!(name: 'Mettre des mots dans l’ordre pour former une phrase', skill: skill18, user: user1)
challenge4 = Challenge.create!(name: 'Reconnaître le verbe dans une phrase', skill: skill19, user: user1)

puts "creating WorkPlanSkill"

work_plan_skill1 = WorkPlanSkill.create!(work_plan_domain: work_plan_domain1, skill: skill1, kind: 'excercice', challenge: challenge1)
work_plan_skill2 = WorkPlanSkill.create!(work_plan_domain: work_plan_domain1, skill: skill2, kind: 'excercice', challenge: challenge2)
work_plan_skill3 = WorkPlanSkill.create!(work_plan_domain: work_plan_domain2, skill: skill18, kind: 'excercice', challenge: challenge3)
work_plan_skill4 = WorkPlanSkill.create!(work_plan_domain: work_plan_domain2, skill: skill19, kind: 'excercice', challenge: challenge4)
