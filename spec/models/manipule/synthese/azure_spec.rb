# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manipule::Synthese::Azure do
  def ssml(texte, **options)
    described_class.new(**options).send(:ssml, texte)
  end

  describe "le SSML envoyé" do
    it "nomme la voix et la langue" do
      expect(ssml("Bonjour")).to include(%(xml:lang="fr-FR")).and include(%(<voice name="fr-FR-DeniseNeural">))
    end

    it "porte le débit demandé" do
      expect(ssml("Bonjour", debit: -20)).to include(%(<prosody rate="-20%">))
    end

    it "se passe de prosodie quand le débit est nominal" do
      expect(ssml("Bonjour", debit: 0)).not_to include("prosody")
    end

    # Un silence après chaque phrase : c'est ce que l'enseignante demande, et ça
    # ne s'obtient pas en baissant le débit.
    it "glisse un silence après chaque fin de phrase" do
      expect(ssml("Il y a 15 pommes. Sam en cueille 7.")).to include(%(15 pommes. <break time="600ms"/> Sam))
    end

    it "ne touche pas à une phrase unique" do
      expect(ssml("Combien reste-t-il de pommes ?")).not_to include("break")
    end
  end

  # L'énoncé vient de l'enseignante. Une esperluette dans « Pierre & Paul »
  # suffirait à produire un XML invalide, et Azure renverrait 400 sans dire
  # pourquoi.
  describe "l'échappement du texte de l'enseignante" do
    it "échappe les caractères réservés du XML" do
      resultat = ssml("Pierre & Paul ont <3 billes")

      expect(resultat).to include("Pierre &amp; Paul ont &lt;3 billes")
    end

    it "laisse intactes les balises de silence qu'il a posées lui-même" do
      resultat = ssml("Pierre & Paul comptent. Puis ils jouent.")

      expect(resultat).to include(%(<break time="600ms"/>))
      expect(resultat).not_to include("&lt;break")
    end
  end

  describe "le garde-fou de la suite de tests" do
    # Une spec distraite ne doit pas pouvoir entamer l'allocation, ni rendre
    # la suite dépendante du réseau.
    it "refuse d'appeler Azure depuis les tests, même configuré" do
      allow(described_class).to receive_messages(cle: "une-cle", region: "francecentral")

      expect { described_class.new.generer("Bonjour") }
        .to raise_error(Manipule::Synthese::Indisponible, /suite de tests/)
    end

    it "ne se déclare jamais disponible en test" do
      allow(described_class).to receive_messages(cle: "une-cle", region: "francecentral")

      expect(described_class).to be_configure
      expect(described_class).not_to be_disponible
    end
  end

  it "dit quoi vérifier quand la clé est refusée" do
    reponse = Net::HTTPUnauthorized.new("1.1", "401", "Unauthorized")

    expect { described_class.send(:traiter, reponse, nil, 1) }
      .to raise_error(Manipule::Synthese::Indisponible, /Place de marché/)
  end
end
