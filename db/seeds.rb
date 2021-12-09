require "open-uri"

puts "destroying current data"
WorkPlanSkill.destroy_all
WorkPlanDomain.destroy_all
Challenge.destroy_all
Skill.destroy_all
WorkPlan.destroy_all
Student.destroy_all
Classroom.destroy_all
User.destroy_all

puts "creating user"

# user1 = User.create!(email:'toto@gmail.com', password:'secret', first_name:'toto', last_name: 'titi')
# file = URI.open('https://cdn0.iconfinder.com/data/icons/basic-50/24/essential_basic_ui_user-512.png')
# user1.photo.attach(io: file, filename: 'essential_basic_ui_user-512.png', content_type: 'image/png')

user1 = User.create!(email:'celine@gmail.com', password:'secret', first_name:'Céline', last_name: 'Chevalier')
file = URI.open('https://res.cloudinary.com/bensoucdev/image/upload/v1638964031/personna-celine_lqgsqd.jpg')
user1.photo.attach(io: file, filename: 'personna-celine_lqgsqd.jpg', content_type: 'image/jpg')

puts "creating Classroom"

classroom1 = Classroom.create!(grade: 'CE1', user: user1)

puts "creating Student"

# student1 = Student.create!(first_name: 'Adèle', classroom: classroom1)
students = %w[Pierre Jade Marame Jeanne Enora Kenji Halil Adèle Ines Hamza Riteje Sam Mila Wisdom Mikele]
students.sort!
students.each do |student|
  Student.create!(first_name: student, classroom: classroom1)
end

puts "creating WorkPlan"

work_plan1 = WorkPlan.create!(name: 'Jules Ferry - CE1 - S48', start_date: '29/11/2021', end_date: '03/12/2021',
                              user: user1, student: Student.second)
work_plan2 = WorkPlan.create!(name: 'Jules Ferry - CE1 - S49', start_date: '06/12/2021', end_date: '10/12/2021',
                              user: user1, student: Student.third)
work_plan3 = WorkPlan.create!(name: 'Jules Ferry - CE1 - S49', start_date: '06/12/2021', end_date: '10/12/2021',
                              user: user1, student: Student.last)
work_plan4 = WorkPlan.create!(name: 'Jules Ferry - CE1 - S50', start_date: '13/12/2021', end_date: '17/12/2021',
                              user: user1, student: Student.first)
work_plan5 = WorkPlan.create!(name: 'Jules Ferry - CE1 - S1', start_date: '03/01/2022', end_date: '07/01/2022',
                              user: user1, student: Student.find_by(first_name: 'Sam'))


puts "creating WorkPlanDomain"

# add domain to work_plan1
work_plan_domain1 = WorkPlanDomain.create!(domain: 'Vocabulaire', level: 1, work_plan: work_plan1)
work_plan_domain2 = WorkPlanDomain.create!(domain: 'Grammaire', level: 2, work_plan: work_plan1)
# add domain to work_plan2
work_plan_domain3 = WorkPlanDomain.create!(domain: 'Grammaire', level: 2, work_plan: work_plan2)
# add domain to work_plan5
work_plan_domain4 = WorkPlanDomain.create!(domain: 'Vocabulaire', level: 1, work_plan: work_plan5)
work_plan_domain5 = WorkPlanDomain.create!(domain: 'Grammaire', level: 2, work_plan: work_plan5)


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

challenge1 = Challenge.create!(name: "Range les lettres dans l’ordre alphabétique", skill: skill1, user: user1)
challenge2 = Challenge.create!(name: 'Barre l’intrus dans chaque liste de mots', skill: skill2, user: user1)
challenge3 = Challenge.create!(name: 'Mets les mots dans l’ordre pour former une phrase puis souligne le verbe', skill: skill18, user: user1)
challenge4 = Challenge.create!(name: 'Souligne le verbe en rouge dans les phrases', skill: skill19, user: user1)

challenge5 = Challenge.create!(name: "Additionner des dizaines entières", skill: skill77, user: user1)
challenge6 = Challenge.create!(name: "Complète la suite en respectant la règle", skill: skill51, user: user1)
challenge7 = Challenge.create!(name: "Calcule", skill: skill73, user: user1)
challenge8 = Challenge.create!(name: "Colorie en vert les phrases au passé, en rouge celles au présent et en jaune celles au futur.", skill: skill20, user: user1)
challenge9 = Challenge.create!(name: "Colorie les phrases correctes.", skill: skill15, user: user1)
challenge10 = Challenge.create!(name: "Colorie le verbe en bleu dans les phrases.", skill: skill19, user: user1)
challenge11 = Challenge.create!(name: "Entoure le verbe en rouge dans les phrases.", skill: skill19, user: user1)


content1 = '<p><span style="font-size:13.999999999999998pt"><span style="font-family:Calibri,sans-serif"><span style="color:#000000"><strong>Range les lettres dans l&rsquo;ordre alphab&eacute;tique&nbsp;:&nbsp;</strong></span></span></span></p>
  <p><span style="font-size:13.999999999999998pt"><span style="font-family:Arial"><span style="color:#000000">A, F , C , G , N&nbsp;: ................................ </span></span></span><span style="font-size:13.999999999999998pt"><span style="font-family:Arial"><span style="color:#000000"> </span></span></span><span style="font-size:13.999999999999998pt"><span style="font-family:Arial"><span style="color:#000000"> </span></span></span><span style="font-size:13.999999999999998pt"><span style="font-family:Arial"><span style="color:#000000">e, i, t , v , g&nbsp;: .....................................</span></span></span></p>
  <p><span style="font-size:13.999999999999998pt"><span style="font-family:Arial"><span style="color:#000000">b, m, d , u , s&nbsp;: .................................</span></span></span><span style="font-size:13.999999999999998pt"><span style="font-family:Arial"><span style="color:#000000"> </span></span></span><span style="font-size:13.999999999999998pt"><span style="font-family:Arial"><span style="color:#000000"> </span></span></span><span style="font-size:13.999999999999998pt"><span style="font-family:Arial"><span style="color:#000000">J, L, H, X, O&nbsp;: .....................................</span></span></span></p>
  <p><span style="font-size:13.999999999999998pt"><span style="font-family:Arial"><span style="color:#000000">B, F , C , P, N&nbsp;: .................................&nbsp; </span></span></span><span style="font-size:13.999999999999998pt"><span style="font-family:Arial"><span style="color:#000000"> </span></span></span><span style="font-size:13.999999999999998pt"><span style="font-family:Arial"><span style="color:#000000"> </span></span></span><span style="font-size:13.999999999999998pt"><span style="font-family:Arial"><span style="color:#000000">f, j , t , v , m&nbsp;: .....................................</span></span></span></p>
  <p>&nbsp;</p>'


challenge1.content.body = content1
challenge1.save



challenge2.content.body = <<~HTML
  <p><span style="font-size:13.999999999999998pt"><span style="font-family:Calibri,sans-serif"><span style="color:#000000"><strong>Barre l&rsquo;intrus dans chaque liste de mots&nbsp;</strong></span></span></span></p>
  <p>&nbsp;</p>
  <p>deux dix&nbsp;treize &eacute;gal&nbsp;huit</p>
  <p><span style="font-weight: 400;">cercle&nbsp;</span><span style="font-weight: 400;">carr&eacute;&nbsp;</span><span style="font-weight: 400;">rectangle&nbsp;</span><span style="font-weight: 400;">triangle&nbsp;</span><span style="font-weight: 400;">stylo</span></p>
  <p><span style="font-weight: 400;">poireau&nbsp;</span><span style="font-weight: 400;">chou-fleur&nbsp;</span><span style="font-weight: 400;">pomme&nbsp;</span><span style="font-weight: 400;">carotte&nbsp;</span><span style="font-weight: 400;">&eacute;pinards</span></p>
  <p><span style="font-weight: 400;">gomme&nbsp;</span><span style="font-weight: 400;">trottinette&nbsp;</span><span style="font-weight: 400;">cahier&nbsp;</span><span style="font-weight: 400;">stylo&nbsp;</span><span style="font-weight: 400;">trousse</span></p>
  <p><span style="font-weight: 400;">marteau&nbsp;</span><span style="font-weight: 400;">tournevis&nbsp;</span><span style="font-weight: 400;">chaise&nbsp;</span><span style="font-weight: 400;">pince&nbsp;</span><span style="font-weight: 400;">perceuse</span></p>
HTML

challenge2.save

challenge3.content.body = <<~HTML
  <p><span style="font-size:13pt"><span style="font-family:Calibri,sans-serif"><span style="color:#000000"><strong>Mets les mots dans l&rsquo;ordre pour former une phrase puis souligne le verbe</strong></span></span></span></p>
  <p>&nbsp;</p>
  <ul>
    <li style="list-style-type:disc"><span style="font-size:13pt"><span style="font-family:'Century Gothic',sans-serif"><span style="color:#000000">le / dans / lion / sa / rugit / cage / vieux</span></span></span></li>
  </ul>
  <p><span style="font-size:13pt"><span style="font-family:'Century Gothic',sans-serif"><span style="color:#000000">&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;...</span></span></span></p>
  <ul>
    <li style="list-style-type:disc"><span style="font-size:13pt"><span style="font-family:'Century Gothic',sans-serif"><span style="color:#000000">soeur / ma / fait / devoirs / ses&nbsp;</span></span></span></li>
  </ul>
  <p><span style="font-size:13pt"><span style="font-family:'Century Gothic',sans-serif"><span style="color:#000000">&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;...</span></span></span></p>
  <ul>
    <li style="list-style-type:disc"><span style="font-size:13pt"><span style="font-family:'Century Gothic',sans-serif"><span style="color:#000000">rigolent / elles / ce / matin / moi / avec</span></span></span></li>
  </ul>
  <p><span style="font-size:13pt"><span style="font-family:'Century Gothic',sans-serif"><span style="color:#000000">&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;..</span></span></span></p>
HTML
challenge3.save

challenge4.content.body = <<~HTML
<p><span style="font-size:13.999999999999998pt"><span style="font-family:Calibri,sans-serif"><span style="color:#000000"><strong>Souligne le verbe en rouge dans les phrases</strong></span></span></span><span style="font-size:12pt"><span style="font-family:'Times New Roman'"><span style="color:#000000">&nbsp;</span></span></span></p>
<p><span style="font-size:12pt"><span style="font-family:'Century Gothic',sans-serif"><span style="color:#000000">Les chevaliers d&eacute;fendaient leur ch&acirc;teau fort.&nbsp;</span></span></span></p>
<p><span style="font-size:12pt"><span style="font-family:'Century Gothic',sans-serif"><span style="color:#000000">Tous les enfants aiment les vacances.&nbsp;</span></span></span></p>
<p><span style="font-size:12pt"><span style="font-family:'Century Gothic',sans-serif"><span style="color:#000000">Dans la classe, le ma&icirc;tre installe des ordinateurs.&nbsp;</span></span></span></p>
<p><span style="font-size:12pt"><span style="font-family:'Century Gothic',sans-serif"><span style="color:#000000">Sur l&rsquo;&eacute;tag&egrave;re il range les livres. </span></span></span></p>
HTML
challenge4.save

# challenge5 vierge
challenge5.content.body = 'A rédiger...'
challenge5.save

challenge6.content.body = <<~HTML
<p style="margin-bottom: 0cm;color: #000000;line-height: 150%;background: transparent;margin-left: -1.2cm;text-indent: 1.2cm;"><u><strong>Compl&egrave;te la suite en respectant la r&egrave;gle :</strong></u></p>
<p style="margin-bottom: 0cm;color: #000000;line-height: 150%;background: transparent;margin-left: -1.2cm;text-indent: 1.2cm;">55 &ndash; 60 &ndash; 65 - &hellip;.. - &hellip;.. - &hellip;... - &hellip;..</p>
<p style="margin-bottom: 0cm;color: #000000;line-height: 150%;background: transparent;margin-left: -1.2cm;text-indent: 1.2cm;">95 &ndash; 94 &ndash; 93 - &hellip;.. - &hellip;.. - &hellip;.. - &hellip;.. - &hellip;..</p>
HTML
challenge6.save

challenge7.content.body = <<~HTML
<p style='margin-bottom: 0cm;color: #000000;line-height: 150%;background: transparent;font-family: "Cambria", serif;font-size:16px;'><u><strong>Calcule</strong></u></p>
<p style='margin-bottom: 0cm;color: #000000;line-height: 150%;background: transparent;font-family: "Cambria", serif;font-size:16px;'><span lang="fr-FR">76 + 2 =</span><span lang="fr-FR">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;60&ndash; 2 =<span id="isPasted" lang="fr-FR">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;</span></span><span lang="fr-FR">52 &ndash; 2 =<span id="isPasted" lang="fr-FR">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;</span></span></p>
<p style='margin-bottom: 0cm;color: #000000;line-height: 150%;background: transparent;font-family: "Cambria", serif;font-size:16px;'>64 &ndash; 2 =<span id="isPasted" lang="fr-FR">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;</span>83 + 2 =<span id="isPasted" lang="fr-FR">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;</span>98 + 2 =&nbsp;</p>
HTML
challenge7.save

challenge8.content.body = <<~HTML
<p style='margin-bottom: 0cm;color: #000000;line-height: 150%;background: transparent;font-family: "Cambria", serif;font-size:16px;margin-right: -1.46cm;'><u><strong>Colorie en vert les phrases au pass&eacute;</strong></u><u><strong>, en rouge celles au pr&eacute;sent et en jaune celles au futur.</strong></u></p>
<p style='margin-bottom: 0cm;color: #000000;line-height: 150%;background: transparent;font-family: "Cambria", serif;font-size:16px;margin-right: -1.46cm;'>Hier, ma maman a pr&eacute;par&eacute; un g&acirc;teau.</p>
<p style='margin-bottom: 0cm;color: #000000;line-height: 150%;background: transparent;font-family: "Cambria", serif;font-size:16px;margin-right: -1.46cm;'>Dans trois semaines on sera en vacances.</p>
<p style='margin-bottom: 0cm;color: #000000;line-height: 150%;background: transparent;font-family: "Cambria", serif;font-size:16px;margin-right: -1.46cm;'>La ma&icirc;tresse est tr&egrave;s en col&egrave;re.</p>
<p style='margin-bottom: 0cm;color: #000000;line-height: 150%;background: transparent;font-family: "Cambria", serif;font-size:16px;margin-right: -1.46cm;'>Il y a deux mois nous allions au cin&eacute;ma.</p>
<p style='margin-bottom: 0cm;color: #000000;line-height: 100%;background: transparent;font-family: "Cambria", serif;font-size:16px;'>Tu seras en retard !</p>
HTML
challenge8.save

challenge9.content.body = <<~HTML
<p style='margin-bottom: 0cm;color: #000000;line-height: 100%;background: transparent;font-family: "Cambria", serif;font-size:16px;'><u><strong>Colorie les phrases correctes</strong></u></p>
<ol>
    <li style='margin-bottom: 0cm;color: #000000;line-height: 200%;background: transparent;font-family: "Cambria", serif;font-size:16px;'>J&rsquo;ai mang&eacute; des c&eacute;r&eacute;ales au petit-d&eacute;jeuner.</li>
    <li style='margin-bottom: 0cm;color: #000000;line-height: 200%;background: transparent;font-family: "Cambria", serif;font-size:16px;'>maman cherche je sortie &eacute;cole</li>
    <li style='margin-bottom: 0cm;color: #000000;line-height: 200%;background: transparent;font-family: "Cambria", serif;font-size:16px;'>Aller cantine moi je.</li>
    <li style='margin-bottom: 0cm;color: #000000;line-height: 200%;background: transparent;font-family: "Cambria", serif;font-size:16px;'>cartable, trousse, stylo</li>
    <li style='margin-bottom: 0.05cm;color: #000000;line-height: 200%;background: transparent;font-family: "Cambria", serif;font-size:16px;'>J&rsquo;aime beaucoup la r&eacute;cr&eacute;ation.</li>
    <li style='margin-bottom: 0.05cm;color: #000000;line-height: 200%;background: transparent;font-family: "Cambria", serif;font-size:16px;'>Bient&ocirc;t, nous ferons une sortie.</li>
    <li style='margin-bottom: 0.05cm;color: #000000;line-height: 200%;background: transparent;font-family: "Cambria", serif;font-size:16px;'>Mes copains adorent jouer au ballon.</li>
    <li style='margin-bottom: 0.05cm;color: #000000;line-height: 200%;background: transparent;font-family: "Cambria", serif;font-size:16px;'>Hier, je suis all&eacute; au rugby.</li>
</ol>
HTML
challenge9.save

challenge10.content.body = <<~HTML
<p style='margin-bottom: 0cm;color: #000000;line-height: 100%;background: transparent;font-family: "Cambria", serif;font-size:16px;'><u><strong>Colorie le verbe en bleu dans les phrases :<br></strong></u></p>
<ol>
    <li style='margin-bottom: 0cm;color: #000000;line-height: 200%;background: transparent;font-family: "Cambria", serif;font-size:16px;'>Je mange des c&eacute;r&eacute;ales au petit-d&eacute;jeuner.</li>
    <li style='margin-bottom: 0cm;color: #000000;line-height: 200%;background: transparent;font-family: "Cambria", serif;font-size:16px;'>Je vais &agrave; la cantine.</li>
    <li style='margin-bottom: 0.05cm;color: #000000;line-height: 200%;background: transparent;font-family: "Cambria", serif;font-size:16px;'>J&rsquo;aime beaucoup la r&eacute;cr&eacute;ation.</li>
    <li style='margin-bottom: 0.05cm;color: #000000;line-height: 200%;background: transparent;font-family: "Cambria", serif;font-size:16px;'>Mes copains adorent le football.</li>
    <li style='margin-bottom: 0.05cm;color: #000000;line-height: 200%;background: transparent;font-family: "Cambria", serif;font-size:16px;'>Je joue au rugby avec mes copains.</li>
</ol>
HTML
challenge10.save

challenge11.content.body = <<~HTML
<p style='margin-bottom: 0cm;color: #000000;line-height: 100%;background: transparent;font-family: "Cambria", serif;font-size:16px;'><u><strong>Entoure le verbe en rouge dans les phrases :<br></strong></u></p>
<p id="isPasted" style="margin-bottom: 0.3cm;color: #000000;line-height: 150%;background: transparent;margin-top: 0.3cm;"><span lang="fr-FR">Le vieux lion rugit dans sa cage.</span></p>
<p id="isPasted" style="margin-bottom: 0.3cm;color: #000000;line-height: 150%;background: transparent;margin-top: 0.3cm;"><span lang="fr-FR">Nous buvons trop de coca.</span></p>
<p id="isPasted" style="margin-bottom: 0.3cm;color: #000000;line-height: 150%;background: transparent;margin-top: 0.3cm;"><span lang="fr-FR">Ils ont 8 ans.</span></p>
HTML
challenge11.save


puts "creating WorkPlanSkill"

# work_plan_skill des WPD1 et 2 (WP1)
work_plan_skill1 = WorkPlanSkill.create!(work_plan_domain: work_plan_domain1, skill: skill1, kind: 'exercice', challenge: challenge1)
work_plan_skill2 = WorkPlanSkill.create!(work_plan_domain: work_plan_domain1, skill: skill2, kind: 'exercice', challenge: challenge2)
work_plan_skill3 = WorkPlanSkill.create!(work_plan_domain: work_plan_domain2, skill: skill18, kind: 'exercice', challenge: challenge3)
work_plan_skill4 = WorkPlanSkill.create!(work_plan_domain: work_plan_domain2, skill: skill19, kind: 'exercice', challenge: challenge4)

# work_plan_skill du WPD3 (WP2)
work_plan_skill5 = WorkPlanSkill.create!(work_plan_domain: work_plan_domain3, skill: skill19, kind: 'exercice', challenge: challenge4)

# work_plan_skill des WPD4 et 5 (WP5)
work_plan_skill6 = WorkPlanSkill.create!(work_plan_domain: work_plan_domain4,
                                        skill: skill1, kind: 'exercice', challenge: challenge1)
work_plan_skill7 = WorkPlanSkill.create!(work_plan_domain: work_plan_domain4,
                                        skill: skill2, kind: 'exercice', challenge: challenge2)
work_plan_skill8 = WorkPlanSkill.create!(work_plan_domain: work_plan_domain5,
                                        skill: skill18, kind: 'exercice', challenge: challenge3)
work_plan_skill9 = WorkPlanSkill.create!(work_plan_domain: work_plan_domain5,
                                        skill: skill19, kind: 'exercice', challenge: challenge4)
