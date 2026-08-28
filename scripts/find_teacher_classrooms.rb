# frozen_string_literal: true

# Inventaire des classes d'un professeur OU d'une école : les classes, leurs
# profs (propriétaire et partages), le niveau, et les id de classe et de prof.
#
#   SCHOOL_ID=1 bin/rails runner scripts/find_teacher_classrooms.rb
#   TEACHER_ID=15 bin/rails runner scripts/find_teacher_classrooms.rb
#   NAME="alain fournier" bin/rails runner scripts/find_teacher_classrooms.rb
#   SCHOOL_ID=1 STUDENTS=1 bin/rails runner scripts/find_teacher_classrooms.rb
#   NAME="ofou" VERBOSE=1 bin/rails runner scripts/find_teacher_classrooms.rb
#
# Lecture seule : le script n'écrit rien, il peut tourner en production.
#
# Deux façons de désigner la cible :
#   - par id (SCHOOL_ID / TEACHER_ID), sans ambiguïté ;
#   - par nom (NAME), cherché DEUX FOIS — parmi les users (first_name,
#     last_name, email) et parmi les écoles (name) — parce qu'un patronyme est
#     souvent aussi un nom d'école (« Alain Fournier ») et qu'on ne sait pas
#     lequel est visé. Les deux séries de résultats sont affichées.
#
# La recherche par nom est tolérante aux fautes et à la casse : chaque mot est
# cherché séparément (ILIKE %mot%), et un enregistrement sort s'il matche AU
# MOINS un mot. Un nom mal orthographié ressort donc quand même, au prix de
# quelques homonymes — tous affichés, à vous de reconnaître le bon.
#
# STUDENTS=1 ajoute la liste des élèves. VERBOSE=1 rend les requêtes SQL.

# SCHOOL_ID / TEACHER_ID court-circuitent la recherche par nom : en production
# un patronyme courant sort plusieurs homonymes, l'id ne trompe pas.
SCHOOL_ID = ENV.fetch("SCHOOL_ID", nil)
TEACHER_ID = ENV.fetch("TEACHER_ID", nil)
NAME = ENV.fetch("NAME", "alain fournier")
WITH_STUDENTS = ENV.fetch("STUDENTS", nil) == "1"

# Les logs SQL noient un rapport de 40 lignes ; on les coupe sauf VERBOSE=1.
ActiveRecord::Base.logger = nil unless ENV.fetch("VERBOSE", nil) == "1"

CLASSROOM_INCLUDES = [:grade, :students, { shared_classrooms: :user }].freeze

def label(user)
  return "(prof supprimé)" if user.nil?

  name = [user.first_name, user.last_name&.upcase].compact.reject(&:empty?).join(" ")
  name = user.email if name.empty?
  "##{user.id} #{name} <#{user.email}>"
end

def classroom_name(classroom)
  classroom.name.to_s.empty? ? "(vide)" : classroom.name.inspect
end

def grade_label(grade)
  return "(aucun)" if grade.nil?

  "##{grade.id} #{grade.grade_level} (#{grade.name})"
end

# Le propriétaire, puis chaque partage. C'est là que se lit qui a accès à quoi.
def print_teachers(classroom, pad)
  puts "#{pad}  profs   :"
  puts "#{pad}    propriétaire  #{label(classroom.user)}"
  shares = classroom.shared_classrooms.sort_by(&:id)
  if shares.empty?
    puts "#{pad}    (non partagée)"
  else
    shares.each { |share| puts "#{pad}    partage ##{share.id}  #{label(share.user)}" }
  end
end

def print_students(classroom, pad)
  return if classroom.students.empty?

  # Un élève n'a qu'un prénom en base, pas de nom de famille.
  puts "#{pad}  liste des élèves :"
  classroom.students.sort_by { |s| s.first_name.to_s.downcase }.each do |student|
    puts "#{pad}    ##{student.id} #{student.first_name}"
  end
end

# Une classe et ses profs. Sert pour les deux recherches.
def print_classroom(classroom, indent, with_students: false)
  pad = " " * indent
  grade = classroom.grade

  puts "#{pad}CLASSE ##{classroom.id}  niveau #{grade&.grade_level || '(sans grade)'} " \
       "nom #{classroom_name(classroom)}"
  puts "#{pad}  grade   : #{grade_label(grade)}"
  puts "#{pad}  élèves  : #{classroom.students.size}"
  print_teachers(classroom, pad)
  print_students(classroom, pad) if with_students
  puts
end

def ilike_clause(words, columns)
  clause = words.flat_map { |_w| columns.map { |c| "#{c} ILIKE ?" } }.join(" OR ")
  values = words.flat_map { |w| Array.new(columns.size, "%#{w}%") }
  [clause, *values]
end

if SCHOOL_ID || TEACHER_ID
  schools = SCHOOL_ID ? School.where(id: SCHOOL_ID.to_i) : School.none
  teachers = TEACHER_ID ? User.where(id: TEACHER_ID.to_i) : User.none
  abort "École ##{SCHOOL_ID} introuvable." if SCHOOL_ID && schools.empty?
  abort "Prof ##{TEACHER_ID} introuvable." if TEACHER_ID && teachers.empty?
  cible = [SCHOOL_ID && "school ##{SCHOOL_ID}", TEACHER_ID && "user ##{TEACHER_ID}"].compact
  puts "Recherche par id : #{cible.join(', ')}"
else
  words = NAME.split.map(&:strip).reject(&:empty?)
  abort "NAME est vide : rien à chercher." if words.empty?

  teachers = User.where(*ilike_clause(words, %w[first_name last_name email])).
    sort_by { |u| [u.last_name.to_s, u.first_name.to_s, u.id] }
  schools = School.where(*ilike_clause(words, %w[name])).order(:name)
  puts "Recherche : « #{NAME} »"
end
puts "  #{teachers.size} prof(s) et #{schools.size} école(s) trouvé(s)"
puts

if teachers.empty? && schools.empty?
  puts "Aucun user ni école ne matche. Essayez un seul mot, une partie du nom, ou un id :"
  puts %(  SCHOOL_ID=1 bin/rails runner scripts/find_teacher_classrooms.rb)
  puts %(  NAME="ofou" bin/rails runner scripts/find_teacher_classrooms.rb)
  exit
end

def account_kind(teacher)
  kind = teacher.admin? ? "admin" : "prof"
  teacher.demo? ? "#{kind}, démo" : kind
end

def print_classroom_group(title, classrooms)
  puts "  #{title} : #{classrooms.size}"
  if classrooms.empty?
    puts "    (aucune)"
    puts
    return
  end
  classrooms.sort_by { |c| [c.grade&.grade_level.to_s, c.id] }.
    each { |c| print_classroom(c, 4, with_students: WITH_STUDENTS) }
end

def ids_of(records)
  records.map(&:id).sort.inspect
end

def teacher_ids_of(classrooms)
  ids_of(classrooms.flat_map(&:teachers).compact.uniq)
end

def school_label(school)
  school ? "##{school.id} #{school.name}" : "(aucune école)"
end

def owned_classrooms(teacher)
  teacher.classrooms.includes(CLASSROOM_INCLUDES).to_a
end

def received_classrooms(teacher)
  teacher.shared_classrooms.includes(classroom: CLASSROOM_INCLUDES).map(&:classroom).compact
end

# Le récapitulatif d'ids, à recopier tel quel dans une console ou un ticket.
def print_teacher_recap(teacher, owned, received)
  all = (owned + received).uniq
  puts "  RÉCAPITULATIF"
  puts "    teacher_id      : #{teacher.id}"
  puts "    classroom_ids   : #{ids_of(all)}"
  puts "    possédées       : #{ids_of(owned)}"
  puts "    reçues          : #{ids_of(received)}"
  puts "    profs impliqués : #{teacher_ids_of(all)}"
  puts
end

def print_teacher(teacher)
  puts "=" * 78
  puts "PROF #{label(teacher)}"
  puts "  école  : #{school_label(teacher.school)}"
  puts "  compte : #{account_kind(teacher)}"
  puts

  owned = owned_classrooms(teacher)
  received = received_classrooms(teacher)
  print_classroom_group("CLASSES POSSÉDÉES", owned)
  print_classroom_group("CLASSES REÇUES EN PARTAGE", received)
  print_teacher_recap(teacher, owned, received)
end

teachers.each { |teacher| print_teacher(teacher) }

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
  puts "    classroom_ids : #{ids_of(classrooms)}"
  puts "    teacher_ids   : #{teacher_ids_of(classrooms)}"
  puts "    partagées     : #{classrooms.count { |c| c.shared_classrooms.any? }} / #{classrooms.size}"
  puts
end
