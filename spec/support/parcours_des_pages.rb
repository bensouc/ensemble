# frozen_string_literal: true

# La liste des pages GET de l'application, et de quoi les atteindre.
#
# Partagée par deux specs qui parcourent les mêmes adresses pour deux raisons
# différentes : la spec de fumée vérifie qu'aucune ne casse, celle du
# cloisonnement qu'aucune ne montre l'école d'à côté. Une page ajoutée est
# couverte par les deux d'office — c'est tout l'intérêt de passer par les
# routes plutôt que par une liste tenue à la main.
module ParcoursDesPages
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
end
