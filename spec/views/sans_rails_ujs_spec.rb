# frozen_string_literal: true

require "rails_helper"

# rails-ujs est retiré : plus rien n'interprète ses attributs. Un lien
# `method: :delete` partirait en GET ; un `data-confirm` ne demanderait plus
# rien avant une suppression. On lit les sources des vues, car ces oublis ne se
# voient qu'au clic.
RSpec.describe "Vues sans rails-ujs" do
  let(:sources) do
    Dir[Rails.root.join("app/{views,components}/**/*.erb"), Rails.root.join("app/{components,helpers}/**/*.rb")]
  end
  # `\b` ne trouve pas de frontière dans `turbo_confirm:` ni `turbo_method:` :
  # les écritures Turbo ne sont pas visées.
  let(:confirmation_ujs) { /\bconfirm:|data-confirm/ }
  let(:lien_avec_methode) { /<%=\s*link_to\b(?:(?!%>).)*\bmethod:|data-method/m }
  let(:formulaire_remote) { /\bremote:\s*true|data-remote/ }

  # Les commentaires ERB (`<%# … %>`) ne sont jamais rendus : on les retire.
  def fautifs(motif)
    sources.select { |chemin| File.read(chemin).gsub(/<%#.*?%>/m, "").match?(motif) }.
      map { |chemin| Pathname(chemin).relative_path_from(Rails.root).to_s }
  end

  it "ne demandent aucune confirmation par `confirm:`" do
    expect(fautifs(confirmation_ujs)).to be_empty
  end

  it "n'envoient aucun lien par `method:`" do
    expect(fautifs(lien_avec_methode)).to be_empty
  end

  it "ne marquent aucun formulaire `remote`" do
    expect(fautifs(formulaire_remote)).to be_empty
  end

  it "reconnaissent ce qu'elles proscrivent, et seulement cela" do
    expect(sources).to include(Rails.root.join("app/views/shared/_nav_haut.html.erb").to_s)

    expect("<%= link_to x_path,\n  method: :delete do %>").to match(lien_avec_methode)
    expect("<%= link_to x_path, data: { turbo_method: :delete } %>").not_to match(lien_avec_methode)
    expect("<%= button_to x_path, method: :delete %>").not_to match(lien_avec_methode)

    expect("data: { confirm: \"Supprimer ?\" }").to match(confirmation_ujs)
    expect("data: { turbo_confirm: \"Supprimer ?\" }").not_to match(confirmation_ujs)
  end
end
