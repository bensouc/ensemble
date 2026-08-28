# frozen_string_literal: true

# Inventaire des classes d'un professeur OU d'une école : les classes, leurs
# profs (propriétaire et partages), le niveau, et les id de classe et de prof.
#
#   bin/rails runner scripts/find_teacher_classrooms.rb
#   NAME="alain fournier" bin/rails runner scripts/find_teacher_classrooms.rb
#   NAME="fournier" STUDENTS=1 bin/rails runner scripts/find_teacher_classrooms.rb
#   NAME="ofou" VERBOSE=1 bin/rails runner scripts/find_teacher_classrooms.rb
#
# Lecture seule : le script n'écrit rien, il peut tourner en production.
#
# NAME est cherché DEUX FOIS, parce qu'un nom de personne est souvent aussi un
# nom d'école (« Alain Fournier ») et qu'on ne sait pas lequel est visé :
#   - parmi les users, dans first_name, last_name et email ;
#   - parmi les écoles, dans name.
# Les deux séries de résultats sont affichées.
#
# La recherche est tolérante aux fautes et à la casse : chaque mot de NAME est
# cherché séparément (ILIKE %mot%), et un enregistrement sort s'il matche AU
# MOINS un mot. Un nom mal orthographié ressort donc quand même, au prix de
# quelques homonymes — tous affichés, à vous de reconnaître le bon.
#
# STUDENTS=1 ajoute la liste des élèves. VERBOSE=1 rend les requêtes SQL.

NAME = ENV.fetch("NAME", "alain fournier")
WITH_STUDENTS = ENV["STUDENTS"] == "1"

# Les logs SQL noient un rapport de 40 lignes ; on les coupe sauf VERBOSE=1.
ActiveRecord::Base.logger = nil unless ENV["VERBOSE"] == "1"

def label(user)
  return "(prof supprimé)" if user.nil?

  name = [user.first_name, user.last_name&.upcase].compact.reject(&:empty?).join(" ")
  name = user.email if name.empty?
  "##{user.id} #{name} <#{user.email}>"
end

# Une classe et ses profs, en 5 lignes. Sert pour les deux recherches.
def print_classroom(classroom, indent, with_students: false)
  pad = " " * indent
  grade = classroom.grade
  shares = classroom.shared_classrooms.to_a

  puts "#{pad}CLASSE ##{classroom.id}  niveau #{grade&.grade_level || '(sans grade)'}" \
       "  nom #{classroom.name.to_s.empty? ? '(vide)' : classroom.name.inspect}"
  puts "#{pad}  grade   : #{grade ? "##{grade.id} #{grade.grade_level} (#{grade.name})" : '(aucun)'}"
  puts "#{pad}  élèves  : #{classroom.students.size}"
  puts "#{pad}  profs   :"
  puts "#{pad}    propriétaire  #{label(classroom.user)}"
  if shares.empty?
    puts "#{pad}    (non partagée)"
  else
    shares.each { |share| puts "#{pad}    partage ##{share.id}  #{label(share.user)}" }
  end

  if with_students && classroom.students.any?
    puts "#{pad}  liste des élèves :"
    classroom.students.sort_by { |s| s.first_name.to_s.downcase }.each do |student|
      puts "#{pad}    ##{student.id} #{student.first_name} #{student.last_name}"
    end
  end
  puts
end

words = NAME.split.map(&:strip).reject(&:empty?)
abort "NAME est vide : rien à chercher." if words.empty?

def ilike_clause(words, columns)
  clause = words.flat_map { |_w| columns.map { |c| "#{c} ILIKE ?" } }.join(" OR ")
  values = words.flat_map { |w| Array.new(columns.size, "%#{w}%") }
  [clause, *values]
end

CLASSROOM_INCLUDES = [:grade, :students, { shared_classrooms: :user }].freeze

teachers = User.where(*ilike_clause(words, %w[first_name last_name email])).
  sort_by { |u| [u.last_name.to_s, u.first_name.to_s, u.id] }
schools = School.where(*ilike_clause(words, %w[name])).order(:name)

puts "Recherche : « #{NAME} »"
puts "  #{teachers.size} prof(s) et #{schools.size} école(s) trouvé(s)"
puts

if teachers.empty? && schools.empty?
  puts "Aucun user ni école ne matche. Essayez un seul mot, ou une partie du nom :"
  puts %(  NAME="ofou" bin/rails runner scripts/find_teacher_classrooms.rb)
  exit
end

teachers.each do |teacher|
  school = teacher.school
  puts "=" * 78
  puts "PROF #{label(teacher)}"
  puts "  école  : #{school ? "##{school.id} #{school.name}" : '(aucune école)'}"
  puts "  compte : #{teacher.admin? ? 'admin' : 'prof'}#{teacher.demo? ? ', démo' : ''}"
  puts

  owned = teacher.classrooms.includes(CLASSROOM_INCLUDES).to_a
  received = teacher.shared_classrooms.includes(classroom: CLASSROOM_INCLUDES).map(&:classroom).compact

  [["CLASSES POSSÉDÉES", owned], ["CLASSES REÇUES EN PARTAGE", received]].each do |title, classrooms|
    puts "  #{title} : #{classrooms.size}"
    if classrooms.empty?
      puts "    (aucune)"
      puts
      next
    end
    classrooms.sort_by { |c| [c.grade&.grade_level.to_s, c.id] }.
      each { |c| print_classroom(c, 4, with_students: WITH_STUDENTS) }
  end

  # Le récapitulatif d'ids, à recopier tel quel dans une console ou un ticket.
  all = (owned + received).uniq
  puts "  RÉCAPITULATIF"
  puts "    teacher_id      : #{teacher.id}"
  puts "    classroom_ids   : #{all.map(&:id).sort.inspect}"
  puts "    possédées       : #{owned.map(&:id).sort.inspect}"
  puts "    reçues          : #{received.map(&:id).sort.inspect}"
  puts "    profs impliqués : #{all.flat_map(&:teachers).compact.uniq.map(&:id).sort.inspect}"
  puts
end

schools.each do |school|
  puts "=" * 78
  puts "ÉCOLE ##{school.id} #{school.name}"

  # On passe par le grade, pas par School#classrooms (`through: :users`) : le
  # grade porte le school_id, alors que le rattachement d'un prof à son école
  # peut manquer — une classe serait invisible.
  classrooms = Classroom.joins(:grade).where(grades: { school_id: school.id }).
    includes(CLASSROOM_INCLUDES).to_a

  puts "  profs rattachés : #{school.users.count}"
  puts "  niveaux         : #{school.grades.map(&:grade_level).uniq.sort.join(', ')}"
  puts "  CLASSES : #{classrooms.size}"
  puts

  classrooms.group_by { |c| c.grade&.grade_level.to_s }.sort.each do |level, group|
    puts "  --- #{level.empty? ? '(sans niveau)' : level} : #{group.size} classe(s)"
    group.sort_by(&:id).each { |c| print_classroom(c, 4, with_students: WITH_STUDENTS) }
  end

  puts "  RÉCAPITULATIF"
  puts "    school_id     : #{school.id}"
  puts "    classroom_ids : #{classrooms.map(&:id).sort.inspect}"
  puts "    teacher_ids   : #{classrooms.flat_map(&:teachers).compact.uniq.map(&:id).sort.inspect}"
  puts "    partagées     : #{classrooms.count { |c| c.shared_classrooms.any? }} / #{classrooms.size}"
  puts
end
