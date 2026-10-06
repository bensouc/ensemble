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
  def ecartees
    {
      "/create-customer-portal-session" => "appelle l'API Stripe",
      "/users/invitation/remove" => "supprime une invitation malgré le GET",
      "/users/cancel" => "efface la session d'inscription en cours",
      "/work_plans/:id/export" => "lance Chrome pour le PDF, trop lent ici",
      "/skills/add_skills_from_xls" => "lit le classeur déposé juste avant (spec dédiée)",
      "/manipule/audio/:id" => "sert un binaire, pas une page (spec dédiée)"
    }
  end

  # Les moteurs (rails_admin, Mission Control) n'exposent pas leurs routes ici.
  # /jobs n'y est pas : en test, Mission Control ne sait pas lire l'adaptateur
  # :test (voir jobs_dashboard_spec.rb).
  def ajoutees = %w[/admin /admin/user /admin/challenge /admin/classroom]

  # Les pages qui attendent un paramètre de requête, comme leurs liens le
  # fournissent. Sans lui, elles répondent 400 : rien à voir avec la page.
  def parametres_de(chemin, ids)
    {
      "/classrooms/:id/results_by_domain" => { domain: ids.fetch("domains") },
      "/students/:student_id/new_validated_wps" => { domain: ids.fetch("domains"), level: 1 },
      "/challenges/new" => { skill: ids.fetch("skills") }
    }.fetch(chemin, {})
  end

  def chemins_get
    routes = Rails.application.routes.routes.filter_map do |route|
      controleur = route.defaults[:controller]
      next unless route.verb.include?("GET") && controleur
      next if controleur.start_with?("rails/", "active_storage/", "action_mailbox/", "turbo/", "letter_opener_web")
      next if controleur == "view_components"
      next if route.path.spec.to_s.start_with?("/_") # routes internes de Rails (tests système)

      route.path.spec.to_s.delete_suffix("(.:format)")
    end
    (routes.uniq - ecartees.keys) + ajoutees
  end

  # `/domains/:id` prend l'id du domaine, `/students/:student_id/...` celui de
  # l'élève : le segment qui précède `:id` dit de quel modèle il s'agit.
  def remplir(chemin, ids)
    chemin.gsub(%r{/(\w+)/:id\b}) { "/#{Regexp.last_match(1)}/#{ids.fetch(Regexp.last_match(1))}" }.
      gsub(/:(\w+)/) { ids.fetch(Regexp.last_match(1)) }
  end

  it "sans erreur, pour un enseignant admin avec une classe en cours" do
    enseignant = create(:user, admin: true)
    ecole = enseignant.school
    niveau = create(:grade, school: ecole)
    domaine = create(:domain, grade: niveau, position: 1, special: false)
    competence = create(:skill, domain: domaine, level: 1, school: ecole)
    tableau = Table.create!(columns: 2, rows: 2)
    piece_jointe = %(<action-text-attachment sgid="#{tableau.attachable_sgid}"></action-text-attachment>)
    exercice = create(:challenge, user: enseignant, skill: competence, content: "<div>Consigne</div>#{piece_jointe}")
    classe = create(:classroom, user: enseignant, grade: niveau)
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

    # La seule page qui appelle Stripe en GET : pas de réseau dans la suite.
    allow(StripeHelper).to receive(:get_or_create_customer).
      and_return(Stripe::Customer.construct_from(id: "cus_fumee", email: enseignant.email))

    ids = {
      "belts" => ceinture.id, "challenges" => exercice.id, "classrooms" => classe.id,
      "conversations" => conversation.id, "domains" => domaine.id, "grades" => niveau.id,
      "schools" => ecole.id, "skills" => competence.id, "students" => eleve.id,
      "work_plan_domains" => domaine_du_plan.id, "work_plan_skills" => competence_du_plan.id,
      "work_plans" => plan.id, "classroom_id" => classe.id, "student_id" => eleve.id,
      "grade_id" => niveau.id, "work_plan_id" => plan.id, "level" => 1, "skill_id" => competence.id,
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
