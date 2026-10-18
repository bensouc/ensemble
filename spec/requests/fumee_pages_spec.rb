# frozen_string_literal: true

require "rails_helper"

# Spec « fumée » : ouvre une fois chaque page GET de l'application, et échoue
# dès qu'une page lève une erreur. La page des résultats d'une classe est
# tombée en 500 sous Rails 7.2 (#492) sans qu'aucune spec ne rougisse : la
# couverture des lignes ne dit pas que chaque page est chargée.
#
# La liste vient des routes : une page ajoutée est couverte d'office, ou doit
# être écartée ci-dessous avec sa raison. Un seul exemple, des données créées
# une fois, toutes les pages à la suite : quelques secondes pour l'ensemble.
RSpec.describe "Fumée : chaque page s'ouvre", type: :request do
  include ParcoursDesPages

  it "sans erreur, pour un enseignant admin avec une classe en cours" do
    enseignant = create(:user, admin: true)
    ecole = enseignant.school
    niveau = create(:grade, school: ecole)
    domaine = create(:domain, grade: niveau, position: 1, special: false)
    competence = create(:skill, domain: domaine, level: 1, school: ecole)
    tableau = Table.create!(columns: 2, rows: 2)
    piece_jointe = %(<action-text-attachment sgid="#{tableau.attachable_sgid}"></action-text-attachment>)
    exercice = create(:challenge, user: enseignant, skill: competence, content: "<div>Consigne</div>#{piece_jointe}")
    classe = create(:classroom, user: enseignant, grade: niveau, belt_sheets: true)
    eleve = create(:student, classroom: classe)
    plan = create(:work_plan, user: enseignant, grade: niveau, student: eleve)
    domaine_du_plan = create(:work_plan_domain, work_plan: plan, domain: domaine, level: 1)
    competence_du_plan = create(:work_plan_skill, work_plan_domain: domaine_du_plan, skill: competence,
                                                  kind: "exercice", challenge: exercice)
    # La compétence du plan a déjà créé le résultat de l'élève : on le complète.
    Result.find_or_initialize_by(student: eleve, skill: competence).update!(status: "completed", kind: "ceinture")
    ceinture = Belt.find_by(student: eleve, domain: domaine) || create(:belt, student: eleve, domain: domaine, level: 1)
    jeton_manipule = Manipule::ClassroomToken.pour!(classe)
    probleme_manipule = create(:manipule_problem, skill: competence)
    collegue = create(:user, school: ecole)
    conversation = Conversation.create!(conversation_type: "classic", name: "Fumée", users: [enseignant, collegue])
    create(:message, user: collegue, conversation:)
    # La conversation de l'école, que la première visite d'un enseignant non
    # admin crée : la messagerie d'un admin s'ouvre dessus.
    Conversation.find_or_create_school_conversation(collegue)
    competence_ceinture = create(:challenge, user: enseignant, skill: competence, for_belt: true)
    fiche = BeltSheet.prepare!(eleve, enseignant)
    ligne_de_fiche = fiche.belt_sheet_domains.first_or_create!(domain: domaine, level: 1).
      belt_sheet_skills.first_or_create!(skill: competence, challenge: competence_ceinture)
    # De quoi remplir l'onglet des fiches non assignées.
    BeltSheet.generer!(niveau, domaine, 1, enseignant)

    # La seule page qui appelle Stripe en GET : pas de réseau dans la suite.
    allow(StripeHelper).to receive(:get_or_create_customer).
      and_return(Stripe::Customer.construct_from(id: "cus_fumee", email: enseignant.email))

    ids = {
      "belts" => ceinture.id, "challenges" => exercice.id, "classrooms" => classe.id,
      "conversations" => conversation.id, "domains" => domaine.id, "grades" => niveau.id,
      "schools" => ecole.id, "skills" => competence.id, "students" => eleve.id,
      "work_plan_domains" => domaine_du_plan.id, "work_plan_skills" => competence_du_plan.id,
      "work_plans" => plan.id, "belt_sheets" => fiche.id, "belt_sheet_id" => fiche.id,
      "belt_sheet_skills" => ligne_de_fiche.id, "classroom_id" => classe.id, "student_id" => eleve.id,
      "grade_id" => niveau.id, "work_plan_id" => plan.id, "level" => 1, "skill_id" => competence.id,
      "domain_id" => domaine.id,
      # `/manipule/suivi/:id` porte une classe : le segment qui précède `:id`
      # nomme la clef, et il ne s'appelle pas « classrooms » ici. Même chose
      # pour `/manipule/suivi/eleve/:id`, qui porte un élève.
      "suivi" => classe.id, "eleve" => eleve.id,
      # Les écrans de Manipule s'ouvrent par une adresse de classe, pas par un
      # identifiant : la substitution de `:id` ne sait rien en faire.
      "token" => jeton_manipule.token,
      # `/manipule/problemes/:id/edition`, l'éditeur.
      "problemes" => probleme_manipule.id
    }.transform_values(&:to_s)

    sign_in enseignant
    echecs = chemins_get.filter_map do |chemin|
      url = remplir(chemin, ids)
      # Un savepoint par page : une erreur SQL annule la transaction, et toutes
      # les pages suivantes tomberaient avec elle.
      ActiveRecord::Base.transaction(requires_new: true) { get url, params: parametres_de(chemin, ids) }
      "#{url} : HTTP #{response.status}" if response.status >= 500
    rescue AbstractController::ActionNotFound => e
      "#{url} : route sans action (#{e.message.lines.first.to_s.strip[0, 120]}), une 404 en production"
    rescue ActionController::ParameterMissing => e
      "#{url} : paramètre de requête attendu (#{e.param})"
    rescue KeyError => e
      "#{chemin} : paramètre sans valeur dans `ids` (#{e.key})"
    rescue StandardError => e
      "#{url} : #{e.class} — #{e.message.lines.first.to_s.strip[0, 160]}"
    end

    expect(echecs).to be_empty, "Pages en erreur :\n#{echecs.join("\n")}"
  end
end
