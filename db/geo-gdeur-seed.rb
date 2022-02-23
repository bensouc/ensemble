# require "open-uri"

# # puts "destroying current data"
# # WorkPlanSkill.destroy_all
# # puts "destroying current WorkPlanSkill"
# # WorkPlanDomain.destroy_all
# # puts "destroying current WorkPlanDomain "
# # Challenge.destroy_all
# # puts "destroying current Challenge "
# # Skill.destroy_all
# # puts "destroying current Skill "
# # WorkPlan.destroy_all
# # Student.destroy_all
# # Classroom.destroy_all
# # User.destroy_all



# # user1 = User.create!(email:'toto@gmail.com', password:'secret', first_name:'toto', last_name: 'titi')
# # file = URI.open('https://cdn0.iconfinder.com/data/icons/basic-50/24/essential_basic_ui_user-512.png')
# # user1.photo.attach(io: file, filename: 'essential_basic_ui_user-512.png', content_type: 'image/png')

# # puts "creating user1"
# # user1 = User.create!(email:'celine@gmail.com', password:'secret', first_name:'Céline', last_name: 'Chevalier')
# # puts "creating user1 OK"

# # puts "creating user2"
# # user2 = User.create!(email:'monna@gmail.com', password:'secret', first_name:'Monna', last_name: 'Lemoine')
# # file2 = URI.open('https://res.cloudinary.com/bensoucdev/image/upload/v1644762709/ydt2oy5frv5n4yhgo1hjy1wv4j9s.jpg')
# # user2.avatar.attach(io: file2, filename: 'ydt2oy5frv5n4yhgo1hjy1wv4j9s.jpg', content_type: 'image/jpg')
# # puts "creating user2 OK"




# # puts "creating Classroom"

# # classroom1 = Classroom.create!(grade: 'CE1', user: user1)
# # classroom2 = Classroom.create!(grade: 'CE1', user: user2)


# # puts "creating Student"

# # # student1 = Student.create!(first_name: 'Adèle', classroom: classroom1)
# # students = %w[Pierre Jade Marame Jeanne Enora Kenji Halil Adèle Ines Hamza Riteje Sam Mila Wisdom Mikele]
# # students.sort!
# # students.each do |student|
# #   Student.create!(first_name: student, classroom: classroom1)
# # end

# # puts "destroy all  geometrie et grandeur"
# # Skill.where(domain: 'Géométrie').destroy_all
# # puts "destroy all  geometrie et grandeur => OK"
# # puts '******************'
# # puts "destroy all  geometrie et grandeur"
# # Skill.where(domain: 'grandeurs et Mesures').destroy_all
# # puts "destroy all  geometrie et grandeur => OK"
# # puts '******************'

# puts "creating Géométrie"

# eskill97 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '◼', name: '1 - Connaître et utiliser le vocabulaire permettant de définir une position')
# eskill98 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '◼', name: '2 - Repérer les cases d’un quadrillage')
# eskill99 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '◼', name: '3 - Coder et décoder des déplacements  sur un quadrillage')
# eskill100 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '◼', name: '4 - Reproduire une figure sur un quadrillage')
# # skill101 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '⬟', name: '5 - Utiliser l’équerre pour tracer un angle droit')
# eskill102 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '⬟', name: '1 - Utiliser la règle pour tracer')
# skill103 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '⬟', name: '2 - Utiliser la règle pour vérifier un alignement')
# skill104 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '⬟', name: '3 - Utiliser le compas pour tracer un cercle')
# skill105 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '⬟', name: '4 - Utiliser l’équerre pour vérifier un angle droit')
# skill106 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '⬥', name: '5 - Utiliser l’équerre pour tracer un angle droit')
# skill107 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '⬥', name: '1 - Reconnaître les figures : carré, rectangle, cercle, triangle')
# skill108 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '⬥', name: '2- Connaître le vocabulaire des figures géométriques : polygone, côté, sommet')
# skill109 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '⬥', name: '3 - Connaître le vocabulaire des figures géométriques : droite, segment, milieu, angle droit')
# skill110 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '⬥', name: '4 - Identifier un carré, un rectangle et marquer les angles droits')
# skill111 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '⬥', name: '5 - Compléter un carré, un rectangle')
# skill112 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '⬥', name: '6 - Connaître le vocabulaire des figures géométriques : cercle, disque, rayon, centre')
# skill113 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '⬥', name: '7 - Construire un cercle en connaissant centre/point ou centre/rayon')
# skill114 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '🞮', name: '1 - Reconnaître si une figure a un axe de symétrie')
# skill115 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '🞮', name: '2 - Tracer la figure symétrique d’une autre par rapport à un axe')
# skill116 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '▲', name: '1 - Reconnaître et nommer les solides : sphère, cube, pavé droit')
# skill117 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '▲', name: '2 - Décrire des solides avec le bon vocabulaire : face, sommet et arrête')
# skill118 = Skill.create!(domain: 'Géométrie', level: 1, symbol: '▲', name: '3 - Reconnaitre un solide à partir de son patron')
# puts "creating new geometrie skill 1 OK"
# puts '***************************'
# puts "creating new 'Grandeurs et Mesures' OK"
# skill119 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '◼', name: '1 - Comparer et classer des objets selon leur longueur')
# skill120 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '◼', name: '2 - Mesurer des segments avec la règle (en cm)')
# skill121 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '◼', name: '3 - Mesurer des longueurs en cm et mm')
# skill122 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '⬟', name: '4 - Résoudre des problèmes de mesure de longueurs')
# skill123 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '⬟', name: '1 - Lire l’heure (heure pile)')
# skill124 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '⬟', name: '2 - Lire l’heure (pile et demie)')
# skill125 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '⬟', name: '3 - Lire l’heure (pile, demie, quart, moins quart)')
# skill126 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '⬟', name: '4 - Lire l’heure')
# skill127 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '⬟', name: '5 - Connaître les relations entre mesures du temps (1 semaine =7 jours; 1 mois =29,30 ou 31 jours, 1 année = 365j ; 1 année =12 mois)')
# skill128 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '⬟', name: '6 - Résoudre des problèmes de durée (heure et minute)')
# skill129 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '⬥', name: '1 - Comparer des masses')
# skill130 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '⬥', name: '2 - Comparer des contenances')
# skill131 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '⬥', name: '3 - Mesurer des masses (g,kg)')
# skill132 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '⬥', name: '4 - Mesurer des contenances (cl,l)')
# skill133 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '▲', name: '1 - Connaître et utiliser la monnaie (sommes jusqu’à 20 avec 1/2/5/10)')
# skill134 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '▲', name: '2 - Connaître et utiliser la monnaie (+centimes)')
# skill135 = Skill.create!(domain: 'Grandeurs et Mesures', level: 1, symbol: '▲', name: '3 - Résoudre des problèmes avec de la monnaie')

# puts "creating new 'Grandeurs et Mesures' "
