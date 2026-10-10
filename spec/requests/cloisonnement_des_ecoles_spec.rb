# frozen_string_literal: true

require "rails_helper"

# Spec « cloisonnement » : ouvre chaque page GET pour une enseignante d'une
# école, et échoue dès qu'une page laisse voir quoi que ce soit d'une autre.
#
# Elle existe parce que la frontière entre écoles est tenue à la main, policy
# par policy, et qu'elle a fui cinq fois : les compétences (#505), les
# exercices, les élèves, le référentiel des plans — et, en production le
# 10/10, la banque de Manipule, où un compte admin voyait le CE1 d'une autre
# école au milieu du sien.
#
# Chacune de ces fuites a été corrigée par une spec écrite à la main, pour un
# écran auquel quelqu'un avait pensé. Celle-ci part des ROUTES : une page
# ajoutée est couverte d'office, ou doit être écartée avec sa raison. C'est la
# différence entre une vigilance et un garde-fou.
#
# Elle ne vérifie pas que les pages fonctionnent — c'est le travail de la spec
# de fumée, qui parcourt la même liste. Une page en erreur est ignorée ici.
RSpec.describe "Cloisonnement : aucune page ne montre l'école d'à côté", type: :request do
  include ParcoursDesPages

  # Des noms qu'aucune page ne peut produire par hasard : s'ils apparaissent,
  # ils viennent de la base, donc de l'autre école.
  MARQUEURS = {
    ecole: "AilleursEcole", niveau: "AilleursNiv", domaine: "AilleursDomaine",
    competence: "AilleursCompetence", classe: "AilleursClasse", eleve: "AilleursPrenom",
    exercice: "AilleursExercice", enonce: "AilleursEnonce"
  }.freeze

  # RailsAdmin montre tout, c'est sa raison d'être — et une enseignante non
  # admin n'y entre pas. Les pages de Devise non plus ne portent pas de
  # données d'école.
  def ecartees_ici
    ecartees.keys + %w[/admin /admin/user /admin/challenge /admin/classroom] +
      # La seule page volontairement inter-écoles : elle sert à ouvrir l'option
      # compte par compte, et nomme donc l'école de chacun. Réservée aux admins.
      %w[/manipule/acces]
  end

  # Une école complète : de quoi remplir chaque segment d'adresse, et de quoi
  # se faire voir si une portée fuit.
  def monter_une_ecole(enseignante, marqueurs: {})
    nom = ->(clef, defaut) { marqueurs[clef] || defaut }
    ecole = enseignante.school
    ecole.update!(name: marqueurs[:ecole]) if marqueurs[:ecole]
    niveau = create(:grade, school: ecole, name: nom.call(:niveau, "CE1"), grade_level: "CE1")
    domaine = create(:domain, grade: niveau, name: nom.call(:domaine, "Calcul"), position: 1, special: false)
    competence = create(:skill, domain: domaine, level: 1, school: ecole,
                                name: nom.call(:competence, "Compter jusqu'à dix"))
    exercice = create(:challenge, user: enseignante, skill: competence,
                                  content: "<div>#{nom.call(:exercice, 'Consigne')}</div>")
    classe = create(:classroom, user: enseignante, grade: niveau, name: nom.call(:classe, "Ma classe"))
    eleve = create(:student, classroom: classe, first_name: nom.call(:eleve, "Sam"))
    plan = create(:work_plan, user: enseignante, grade: niveau, student: eleve)
    domaine_du_plan = create(:work_plan_domain, work_plan: plan, domain: domaine, level: 1)
    competence_du_plan = create(:work_plan_skill, work_plan_domain: domaine_du_plan, skill: competence,
                                                  kind: "exercice", challenge: exercice)
    Result.find_or_initialize_by(student: eleve, skill: competence).update!(status: "completed", kind: "ceinture")
    ceinture = Belt.find_by(student: eleve, domain: domaine) || create(:belt, student: eleve, domain: domaine, level: 1)
    probleme = create(:manipule_problem, skill: competence, statement: nom.call(:enonce, "Il y a dix billes."))
    collegue = create(:user, school: ecole, admin: false)
    conversation = Conversation.create!(conversation_type: "classic", name: "Entre nous",
                                        users: [enseignante, collegue])
    create(:message, user: collegue, conversation:)

    { enseignante:, ids: {
      "belts" => ceinture.id, "challenges" => exercice.id, "classrooms" => classe.id,
      "conversations" => conversation.id, "domains" => domaine.id, "grades" => niveau.id,
      "schools" => ecole.id, "skills" => competence.id, "students" => eleve.id,
      "work_plan_domains" => domaine_du_plan.id, "work_plan_skills" => competence_du_plan.id,
      "work_plans" => plan.id, "classroom_id" => classe.id, "student_id" => eleve.id,
      "grade_id" => niveau.id, "work_plan_id" => plan.id, "level" => 1, "skill_id" => competence.id,
      "suivi" => classe.id, "eleve" => eleve.id,
      "token" => Manipule::ClassroomToken.pour!(classe).token, "problemes" => probleme.id
    }.transform_values(&:to_s) }
  end

  it "pour une enseignante ordinaire" do
    monter_une_ecole(create(:user, admin: false, manipule: true), marqueurs: MARQUEURS)
    chez_elle = monter_une_ecole(create(:user, admin: false, manipule: true))

    expect(fuites_vues_par(chez_elle)).to be_empty
  end

  # Le cas qui a mordu en production : `ProblemPolicy::Scope` rendait
  # `scope.all` à un admin, et la banque d'une autre école se mélangeait à la
  # sienne — sans qu'aucun filtre puisse l'atteindre. Un admin reste un
  # enseignant quand il travaille dans SES écrans.
  it "pour un admin, qui travaille lui aussi dans ses propres écrans" do
    monter_une_ecole(create(:user, admin: false, manipule: true), marqueurs: MARQUEURS)
    patronne = monter_une_ecole(create(:user, admin: true, manipule: true))

    expect(fuites_vues_par(patronne)).to be_empty
  end

  private

  def fuites_vues_par(ecole)
    sign_in ecole[:enseignante]
    allow(StripeHelper).to receive(:get_or_create_customer).
      and_return(Stripe::Customer.construct_from(id: "cus_test", email: ecole[:enseignante].email))

    (chemins_get - ecartees_ici).filter_map do |chemin|
      url = remplir(chemin, ecole[:ids])
      # Un savepoint par page : une erreur SQL annulerait la transaction, et
      # toutes les pages suivantes tomberaient avec elle.
      ActiveRecord::Base.transaction(requires_new: true) do
        get url, params: parametres_de(chemin, ecole[:ids])
      end
      vus = MARQUEURS.values.select { |marqueur| response.body.to_s.include?(marqueur) }
      "#{url} laisse voir : #{vus.join(', ')}" if vus.any?
    rescue StandardError
      # Une page qui casse est le sujet de la spec de fumée, pas d'ici.
      nil
    end
  end
end
